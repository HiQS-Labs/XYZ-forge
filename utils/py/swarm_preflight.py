import argparse
import os
import sys
import subprocess
import time
import re
import json
import shutil
import datetime

def compute_default_root(this_file):
    # GH-267: this_file lives one directory deeper than its Bash sibling (utils/py/ vs
    # utils/), so it needs two ".." to reach the same anchor (repo root, or vendored .xyz/).
    here = os.path.dirname(os.path.abspath(this_file))
    here_parent = os.path.abspath(os.path.join(here, "..", ".."))
    if os.path.basename(here_parent) == ".xyz":
        return os.path.abspath(os.path.join(here_parent, "..")), ".xyz/relay-automation/marathon-drive.sh"
    return here_parent, "relay-automation/marathon-drive.sh"

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def get_env(key, default=None):
    return os.environ.get(key, default)

def die(msg):
    eprint(f"swarm-preflight: {msg}")
    sys.exit(2)

def log(msg):
    eprint(f"swarm-preflight: {msg}")

def emit(msg):
    print(msg)

def extract_contract(doc_path):
    with open(doc_path, 'r') as f:
        lines = f.read().splitlines()
    
    i = -1
    for idx, l in enumerate(lines):
        if re.match(r'^#{1,6}\s+.*preflight\s+contract', l, re.IGNORECASE):
            i = idx
            break
            
    if i < 0:
        eprint(f"no '## ... Preflight Contract' heading in {doc_path}")
        sys.exit(3)
        
    start = -1
    for j in range(i+1, len(lines)):
        if re.match(r'^```json\s*$', lines[j], re.IGNORECASE):
            start = j + 1
            break
        if re.match(r'^#{1,6}\s+', lines[j]):
            break
            
    if start < 0:
        eprint(f"no fenced json block under the contract heading in {doc_path}")
        sys.exit(3)
        
    end = -1
    for j in range(start, len(lines)):
        if re.match(r'^```\s*$', lines[j]):
            end = j
            break
            
    if end < 0:
        eprint(f"unterminated json block in {doc_path}")
        sys.exit(3)
        
    try:
        obj = json.loads("\n".join(lines[start:end]))
    except Exception as e:
        eprint(f"invalid JSON contract in {doc_path}: {e}")
        sys.exit(3)
        
    def get(p, o):
        for k in p.split('.'):
            if o is None: return None
            o = o.get(k)
        return o

    for p, t in [("target", dict), ("target.repo", str), ("target.ref", str), ("gate", str)]:
        v = get(p, obj)
        if v is None or not isinstance(v, t):
            eprint(f"contract in {doc_path} missing required field: {p}")
            sys.exit(3)
            
    if not isinstance(obj.get('fix_probes'), list) or len(obj['fix_probes']) == 0:
        eprint(f"contract in {doc_path} needs at least one fix_probes entry")
        sys.exit(3)
        
    if not isinstance(obj.get('artifacts'), list) or len(obj['artifacts']) == 0:
        eprint(f"contract in {doc_path} needs at least one artifacts path")
        sys.exit(3)

    # GH-89: artifacts_new is an OPTIONAL subset marker — every path in it must also
    # appear in artifacts[] (it is not a separate path list). A typo'd or stray entry
    # is a contract error (exit 3), same severity as a missing required field.
    if obj.get('artifacts_new') is not None:
        if not isinstance(obj['artifacts_new'], list):
            eprint(f"contract in {doc_path}: artifacts_new must be an array of strings")
            sys.exit(3)
        for a in obj['artifacts_new']:
            if a not in obj['artifacts']:
                eprint(f"contract in {doc_path}: artifacts_new entry not present in artifacts[]: {a}")
                sys.exit(3)

    return obj

def merge_contracts(contracts):
    base = contracts[0]
    out = {
        "target": {"repo": base["target"]["repo"], "ref": base["target"]["ref"]},
        "gate": base["gate"],
        "fix_probes": list(base.get("fix_probes", [])),
        "artifacts": list(base.get("artifacts", [])),
        "artifacts_new": list(base.get("artifacts_new", [])),
        "remediation": base.get("remediation"),
        "lanes": {
            "agy_safe": list((base.get("lanes", {}) or {}).get("agy_safe", [])),
            "orchestrator_only": list((base.get("lanes", {}) or {}).get("orchestrator_only", []))
        }
    }
    
    for c in contracts[1:]:
        if c["target"]["repo"] != out["target"]["repo"] or c["target"]["ref"] != out["target"]["ref"]:
            eprint(f"bundle disagreement: targets differ ({out['target']['repo']}@{out['target']['ref']} vs {c['target']['repo']}@{c['target']['ref']})")
            sys.exit(7)
        if c["gate"] != out["gate"]:
            eprint(f"bundle disagreement: gate commands differ")
            sys.exit(7)
            
        out["fix_probes"].extend(c.get("fix_probes", []))
        for a in c.get("artifacts", []):
            if a not in out["artifacts"]: out["artifacts"].append(a)
        for a in c.get("artifacts_new", []):
            if a not in out["artifacts_new"]: out["artifacts_new"].append(a)
        for a in (c.get("lanes", {}) or {}).get("agy_safe", []):
            if a not in out["lanes"]["agy_safe"]: out["lanes"]["agy_safe"].append(a)
        for a in (c.get("lanes", {}) or {}).get("orchestrator_only", []):
            if a not in out["lanes"]["orchestrator_only"]: out["lanes"]["orchestrator_only"].append(a)
            
    return out

def eval_probes(root, c):
    probes_res = []
    counts = {"landed": 0, "unfixed": 0, "blocked": 0}
    
    for p in c["fix_probes"]:
        verdict = "unfixed"
        ptype = p.get("type")
        path = p.get("path")
        
        target_path = os.path.join(root, path) if path else root
        
        try:
            if ptype == "path_absent":
                if os.path.exists(target_path): verdict = "landed"
            elif ptype == "path_present":
                if not os.path.exists(target_path): verdict = "blocked"
            elif ptype == "grep_present":
                if not os.path.exists(target_path):
                    verdict = "blocked"
                else:
                    with open(target_path, 'r') as f:
                        if not re.search(p.get("pattern", ""), f.read()):
                            verdict = "landed"
            elif ptype == "grep_absent":
                if os.path.exists(target_path):
                    with open(target_path, 'r') as f:
                        if re.search(p.get("pattern", ""), f.read()):
                            verdict = "landed"
            elif ptype == "command":
                cmd = p.get("cmd")
                rc = 0
                try:
                    subprocess.run(cmd, shell=True, cwd=root, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
                except subprocess.CalledProcessError:
                    rc = 1
                
                expect_nonzero = p.get("expect_nonzero", False)
                if (rc == 0) if expect_nonzero else (rc != 0):
                    verdict = "landed"
            else:
                verdict = "blocked"
        except Exception:
            verdict = "blocked"
            
        counts[verdict] += 1
        probes_res.append({"type": ptype, "path": path, "verdict": verdict})
        
    stale = 1 if counts["landed"] > 0 else 0
    blocked = 1 if counts["blocked"] > 0 else 0
    ambig = 1 if stale and counts["unfixed"] > 0 else 0
    return probes_res, stale, blocked, ambig

def lane_plan(c, effective=None):
    effective = effective or {}
    if isinstance(effective.get("artifacts"), list):
        arts = effective["artifacts"]
    else:
        arts = c.get("artifacts", [])
    orch_only = (c.get("lanes", {}) or {}).get("orchestrator_only")
    if not orch_only: orch_only = ["bin/", ".tick/", "relay-automation/relay-turn-lib.sh"]
    agy_safe = (c.get("lanes", {}) or {}).get("agy_safe", [])

    def is_orch(p):
        for o in orch_only:
            if p == o or p.startswith(o): return True
        return False

    orchestrator, codex, agy = [], [], []
    for a in arts:
        if is_orch(a): orchestrator.append(a)
        elif a in agy_safe: agy.append(a)
        else: codex.append(a)

    def top_dir(p): return p.split("/")[0]
    coupled = len(arts) > 1 and len(set(top_dir(a) for a in arts)) == 1
    buildable = codex + agy

    return {
        "orchestrator_owned": orchestrator,
        "codex_lane": codex,
        "agy_lane": agy,
        "effective_artifacts": arts,
        "inferred_test_artifacts": effective.get("inferred_tests", []),
        "inferred_test_helpers": effective.get("inferred_helpers", []),
        "fs_touching_tests": effective.get("fs_touching_tests", []),
        "agy_review_default": True,
        "coupling_warning": "all artifacts share one top-level dir; treat as coupled" if coupled else None,
        "parallelizable": not coupled and len(buildable) >= 2,
        "single_lane_only": coupled or len(buildable) < 2
    }

def normalize(e):
    c = e["SP_CONTRACT"]
    probes = e["SP_PROBES"]
    lanes = e["SP_LANES"]
    docs = [d for d in e["SP_DOCS"].strip().split("\n") if d]
    
    return {
        "schema": "swarm-preflight/run-candidate@1",
        "generated_at": e["SP_NOW"],
        "mode": e["SP_MODE"],
        "candidate": {"slug": e["SP_SLUG"]},
        "provenance": {
            "source_docs": docs,
            "issues": [i for i in e.get("SP_ISSUES", "").split(",") if i] if e.get("SP_ISSUES") else [],
            "target_root": e["SP_ROOT"],
            "branch": e["SP_BRANCH"],
            "commit": e["SP_COMMIT"],
            "suggested_branch": e["SP_SUGGESTED_BRANCH"],
            "branch_ready": e.get("SP_BRANCH_READY") == "1",
            "skip_branch_prompt": e.get("SP_SKIP_BRANCH_PROMPT") == "1"
        },
        "contract": c,
        "freshness": {
            "fetch_ok": e.get("SP_FETCH") == "1",
            "upstream": e.get("SP_UP") or None,
            "ahead": int(e.get("SP_AHEAD", 0) or 0),
            "behind": int(e.get("SP_BEHIND", 0) or 0),
            "dirty": e.get("SP_DIRTY") == "1",
            "stale_index_lock": e.get("SP_STALE_INDEX_LOCK") == "1",
            "stale_index_lock_path": e.get("SP_STALE_INDEX_LOCK_PATH") or None,
            "stale_index_lock_warning": e.get("SP_STALE_INDEX_LOCK_WARNING") or None,
            "evaluated_ref": e.get("SP_REF") or None,
            "evaluated_ref_commit": e.get("SP_REF_COMMIT") or None,
            "checkout_matches_ref": e.get("SP_CHECKOUT_MATCHES_REF") == "1",
            "head_behind_ref": int(e.get("SP_HEAD_BEHIND_REF", 0) or 0),
            "candidate_state": e["SP_STATE"],
            "probes": probes
        },
        "readiness": {
            "ready": e.get("SP_READY") == "1",
            "next_action": e.get("SP_NEXT") or None,
            # GH-400: recorded on every run, including "unknown" — a fidelity claim the packet cannot
            # substantiate must be visibly absent rather than quietly assumed.
            "acceptance_fidelity": e.get("SP_ACC_FIDELITY") or {"status": "unknown", "detail": "not evaluated"},
            # GH-400 criterion 2: recorded on every run so "the doc cited its issue" is auditable
            # after the fact rather than assumed from a green verdict.
            "source_url": e.get("SP_SRC_URL") or {"status": "unknown", "detail": "not evaluated"},
            # GH-399: what the packet's checklist actually contains, so a lossy or capped copy is
            # auditable after the fact rather than only visible to whoever read the packet.
            "acceptance_inline": e.get("SP_ACC_INLINE") or {"criteria": 0, "scope": "whole-document",
                                                            "over_cap": 0, "lossless": True}
        },
        "lane_plan": lanes
    }

def normalize_path(rel_path):
    return rel_path.replace("\\", "/")

def helper_refs(raw):
    refs = []
    patterns = [
        r'\$\(dirname "\$0"\)/([^"\' )]+)',
        r'\$\(dirname "\$\{BASH_SOURCE\[0\]\}"\)/([^"\' )]+)',
        r'\btest/(_[A-Za-z0-9._-]+(?:/[A-Za-z0-9._-]+)*)',
    ]
    for pattern in patterns:
        for match in re.finditer(pattern, raw):
            rel_path = match.group(0) if match.group(0).startswith("test/") else f"test/{match.group(1)}"
            refs.append(normalize_path(rel_path))
    return refs

def is_fs_touching(raw):
    # GH-127: bare `>` redirections touch files too; keep arrows/redirect operators
    # like `->`, `>=`, `>>`, and `2>&1` out of the containment-sensitive bucket.
    pattern = r'(mktemp|git(?:\s+-C\s+\S+)?\s+(?:worktree|init)|mkdir\s|touch\s|rm\s+-|cat\s+>|printf\s+.*>|>>|writeFileSync|appendFileSync|mkdtempSync|(?<!-)>(?![=>&]))'
    return re.search(pattern, raw, flags=re.S) is not None

def is_genuine_ref(raw, artifact):
    # GH-126: a mere substring mention is not enough; require the artifact to look
    # like a real command/path reference in the covering test.
    escaped = re.escape(artifact)
    pattern = rf'(?:/|\b(?:source|bash|node)\b\s*["\'`]?|require\(\s*["\'`]?)' + escaped
    return re.search(pattern, raw) is not None

def is_generated_inferred_path(rel_path):
    return re.search(r'(?:^|/)__pycache__(?:/|$)|\.pyc$', rel_path, flags=re.IGNORECASE) is not None

def sanitize_inferred_path(root, test_root, rel_path):
    # GH-137 (Python parity, GH-146-follow-up relay review): only INFERRED additions are
    # sanitized here — declared artifacts stay authoritative. An inferred covering test or
    # helper must stay inside repo test/ and must not widen ALLOW_PATHS via a `test/..`
    # escape or a generated/gitignored entry like `__pycache__/x.pyc`. Mirrors
    # utils/swarm-preflight.sh's sanitizeInferredPath exactly (same containment boundary,
    # same rejection order) so XYZ_PYTHON=1 mode can't reopen the bug GH-137 closed in Bash.
    candidate = normalize_path(str(rel_path or ""))
    candidate = re.sub(r'^(?:\./)+', '', candidate)
    if not candidate.startswith("test/"):
        return None
    if ".." in candidate.split("/"):
        return None
    if is_generated_inferred_path(candidate):
        return None
    resolved = os.path.abspath(os.path.join(root, candidate))
    under_test = normalize_path(os.path.relpath(resolved, test_root))
    if not under_test or under_test == ".." or under_test.startswith("../") or os.path.isabs(under_test):
        return None
    return normalize_path(os.path.relpath(resolved, root))

def expand_effective_artifacts(root, contract):
    declared = contract.get("artifacts", [])
    included = []
    inferred_tests = []
    inferred_helpers = []
    test_root = os.path.join(root, "test")

    def add(bucket, rel_path):
        if not rel_path or rel_path in included:
            return
        included.append(rel_path)
        if bucket is not None and rel_path not in bucket:
            bucket.append(rel_path)

    def read(rel_path):
        try:
            with open(os.path.join(root, rel_path), "r") as f:
                return f.read()
        except OSError:
            return ""

    for rel_path in declared:
        add(None, rel_path)

    if os.path.isdir(test_root):
        for dirpath, dirnames, filenames in os.walk(test_root):
            dirnames.sort()  # deterministic descent (readdir order differs macOS vs Linux — GH-264)
            for filename in sorted(filenames):
                abs_path = os.path.join(dirpath, filename)
                rel_path = normalize_path(os.path.relpath(abs_path, root))
                rel_path = sanitize_inferred_path(root, test_root, rel_path)
                if not rel_path:
                    continue
                raw = read(rel_path)
                if any(is_genuine_ref(raw, artifact) for artifact in declared):
                    add(inferred_tests, rel_path)

    queue = list(inferred_tests) + [p for p in declared if p.startswith("test/")]
    seen_helpers = set(queue)
    while queue:
        rel_path = queue.pop(0)
        for raw_helper in helper_refs(read(rel_path)):
            helper = sanitize_inferred_path(root, test_root, raw_helper)
            if not helper:
                continue
            if not os.path.exists(os.path.join(root, helper)) or helper in seen_helpers:
                continue
            seen_helpers.add(helper)
            add(inferred_helpers, helper)
            queue.append(helper)

    fs_touching = [
        rel_path for rel_path in included
        if rel_path.startswith("test/") and rel_path.endswith(".sh") and is_fs_touching(read(rel_path))
    ]
    return {
        "artifacts": included,
        "inferred_tests": inferred_tests,
        "inferred_helpers": inferred_helpers,
        "fs_touching_tests": fs_touching,
    }

def gate_scoping_caveat(gate_cmd):
    # GH-108: a ` -- ` passthrough only scopes if the target repo's own runner honors it.
    if " -- " not in gate_cmd:
        return ""
    pre = gate_cmd.split(" -- ", 1)[0]
    if re.search(r'\btest\b', pre, re.IGNORECASE):
        return (
            f"- Gate-scoping caveat (GH-108): `{gate_cmd}` is passed through verbatim; whether "
            "the `-- ...` passthrough actually filters to a single test depends on the target "
            "repo's own test-runner configuration (a runner script can ignore or misroute "
            "passthrough args). Pre-green the full suite, or independently verify the filter "
            "genuinely scopes, before firing this lane."
        )
    return ""

# ── GH-400: acceptance fidelity ───────────────────────────────────────────────────────────────────
# A capture doc is authored by a model summarising a GitHub issue, and preflight then inlines that
# summary into the packet as the definition of done. Summarisation drops and reframes by nature, so
# the doc silently becomes a contract that no downstream role can compare against anything: builder
# and reviewer both read the packet, and the issue text is in neither context window. Measured case
# (rebalance-OS #202): the issue required a malformed row be "never silently dropped", the capture
# doc required asserting "the actual current behavior (drop the row)", and two independent marathon
# runs delivered a test named `malformed_source_row_is_dropped`. Every gate was green.
#
# The rule: acceptance is COPIED, not restated. Any genuine deviation is declared in a reviewable
# "## Acceptance — deviations from the issue" section that must reconcile the two lists exactly.

# A trailing colon or a parenthetical qualifier ("## Acceptance:", "## Acceptance Criteria (draft)")
# is the same heading. Anchoring hard on `$` made those read as "no acceptance section", which is an
# `unknown` verdict — i.e. a silent bypass of the gate, not a visible failure (agy review, 2026-08-03).
# Deliberately NOT `.*`: that would swallow prose headings like "## Acceptance is not required here".
ACC_HEADING_RE = re.compile(
    r'^(#{2,6})\s*(?:suggested\s+)?acceptance(?:\s+criteria)?\s*:?\s*(?:\([^)]*\))?\s*$', re.IGNORECASE)
ACC_DEVIATIONS_HEADING_RE = re.compile(r'^(#{2,6})\s*acceptance\s*[-—–]{1,2}\s*deviations\b', re.IGNORECASE)
ACC_BULLET_RE = re.compile(r'^([ \t]*)[-*]\s*\[[ xX]\]\s*(.*)$')
ACC_HR_RE = re.compile(r'^\s*([-*_])\s*(\1\s*){2,}$')
ANY_HEADING_RE = re.compile(r'^(#{1,6})\s')

def normalize_criterion(text):
    """Fold hard-wrap and incidental whitespace so a re-wrapped copy still counts as verbatim.

    Capture docs are hard-wrapped at ~80 columns and GitHub issues are not, so a byte-for-byte
    comparison would flag every faithful copy. Wrapping is a formatting choice; wording is the
    contract. Nothing else is normalized — punctuation, quoting and emphasis all stay significant.
    """
    return re.sub(r'\s+', ' ', (text or "")).strip()

def extract_acceptance_criteria(text):
    """Criteria under the first Acceptance heading, or None when the document has no such section.

    Continuation-aware: a hard-wrapped criterion continues on an INDENTED follow-on line. The
    indent requirement is load-bearing — without it, the trailing `---` and the italic footer that
    close a GitHub issue body get folded into the last criterion and every comparison diverges
    (observed while dogfooding this check against issue #400 itself).

    Returns None (no section) rather than [] (section present but empty) — the caller treats those
    two cases differently, and collapsing them would let a doc dodge the gate by emptying its list.
    """
    if not text:
        return None
    lines = text.splitlines()
    start = level = None
    for i, line in enumerate(lines):
        if ACC_DEVIATIONS_HEADING_RE.match(line):
            continue
        m = ACC_HEADING_RE.match(line)
        if m:
            start, level = i + 1, len(m.group(1))
            break
    if start is None:
        return None

    criteria, indents = [], []
    for line in lines[start:]:
        heading = ANY_HEADING_RE.match(line)
        if heading and len(heading.group(1)) <= level:
            break
        if ACC_HR_RE.match(line):
            break
        bullet = ACC_BULLET_RE.match(line)
        if bullet:
            criteria.append(bullet.group(2).strip())
            indents.append(len(bullet.group(1).expandtabs(4)))
        elif criteria and line.strip() and not heading:
            if len(line) - len(line.lstrip()) > indents[-1]:
                criteria[-1] += " " + line.strip()
            # An UNindented line is prose between criteria, not a continuation. Skip it and keep
            # scanning: `break`ing here dropped every criterion after an explanatory paragraph, and
            # made this disagree with collect_inline_checklist about the same document — the packet
            # would inline three criteria while the fidelity check compared two (agy review).
    return [normalize_criterion(c) for c in criteria if c.strip()]

DEVIATION_RE = re.compile(
    r'^[ \t]*[-*]\s*\[(dropped|changed|added)\]\s*(.*)$', re.IGNORECASE)

def extract_declared_deviations(text):
    """Parse the '## Acceptance — deviations from the issue' section.

    Machine-checkable by construction, so "explained" is a fact rather than a judgement call:

        - [dropped] <verbatim issue criterion> — reason: <why>
        - [changed] <verbatim issue criterion> -> <replacement> — reason: <why>
        - [added]   <new criterion> — reason: <why>
    """
    out = {"dropped": [], "added": [], "changed": [], "malformed": []}
    if not text:
        return out
    lines = text.splitlines()
    start = level = None
    for i, line in enumerate(lines):
        m = ACC_DEVIATIONS_HEADING_RE.match(line)
        if m:
            start, level = i + 1, len(m.group(1))
            break
    if start is None:
        return out

    buf = []
    for line in lines[start:]:
        heading = ANY_HEADING_RE.match(line)
        if heading and len(heading.group(1)) <= level:
            break
        if DEVIATION_RE.match(line):
            buf.append(line.rstrip())
        elif buf and line.strip() and not heading and not ACC_HR_RE.match(line):
            buf[-1] += " " + line.strip()

    for raw in buf:
        m = DEVIATION_RE.match(raw)
        kind, body = m.group(1).lower(), m.group(2)
        reason = ""
        # LAST occurrence, not the first: a criterion may legitimately quote "— reason:" in its own
        # text, and splitting there would silently truncate the criterion being declared (agy review).
        rm = None
        for rm in re.finditer(r'(?:—|--|-)\s*reason:\s*(.+)$', body, re.IGNORECASE):
            pass
        if rm:
            reason = rm.group(1).strip()
            body = body[:rm.start()]
        if not reason:
            out["malformed"].append(f"[{kind}] entry has no '— reason: …': {normalize_criterion(raw)[:120]}")
            continue
        if kind == "changed":
            # The ` -> ` separator is genuinely ambiguous when a criterion contains an arrow of its
            # own ("Map A -> B during import. -> Map A -> B during export."). Neither the first nor
            # the last arrow is right in general, so don't guess: offer EVERY split as a candidate
            # and let reconciliation pick the one that matches the actual diff. Data decides.
            seps = list(re.finditer(r'\s(?:->|→)\s', body))
            if not seps:
                out["malformed"].append(f"[changed] entry needs '<issue text> -> <replacement>': {normalize_criterion(raw)[:120]}")
                continue
            cands = [(normalize_criterion(body[:m.start()]), normalize_criterion(body[m.end():]))
                     for m in seps]
            out["changed"].append((cands, reason))
        else:
            out[kind].append((normalize_criterion(body), reason))
    return out

def fetch_issue_body(issue_number, cwd):
    """Issue body via `gh`, or None when it cannot be reached.

    Preflight has otherwise been local-transport only, so this is the first body-fetch on the path
    and it degrades rather than blocking: an unreachable network is not evidence of drift.
    """
    if not shutil.which("gh"):
        return None
    try:
        r = subprocess.run(["gh", "issue", "view", str(issue_number), "--json", "body", "-q", ".body"],
                           cwd=cwd, capture_output=True, text=True, timeout=45)
    except Exception:
        return None
    if r.returncode != 0:
        return None
    return r.stdout

# ── GH-399: the packet's acceptance block must be a LOSSLESS copy of the capture doc's ────────────
# The packet is the only statement of the job the builder reads, and the reviewer reads the same
# packet. Inlining the checklist with a line-oriented match keeps only the line each `- [ ]` starts
# on, so every hard-wrapped criterion arrives as a half-sentence — measured at 10 of 10 lanes in one
# marathon. GH-201's "raises a clear error instead / of silently resolving to the canonical DB" lost
# the clause naming the defect; GH-139 lost the clause defining what "stable" had to survive.
#
# Continuations are INDENT-GATED for the same reason as GH-400's extractor: without it, a trailing
# horizontal rule or a following paragraph gets swallowed into the last criterion.

def collect_inline_checklist(text, cap=25):
    """Checklist items for the packet, each as its full set of source lines.

    Returns (items, mode, dropped) where items is a list of (normalized_text, [raw_lines]).

    `mode` is 'acceptance-section' when the doc has an `## Acceptance` heading and
    'whole-document' otherwise. GH-399 asks for extraction bounded to that section; bounding
    unconditionally would empty the acceptance block of nearly every capture doc in this repo (32 of
    33 active docs keep their checkboxes under `## Phase N` instead), so the bound applies where the
    section exists and the packet states which of the two it used. See the capture doc's declared
    deviation.
    """
    if not text:
        return [], "whole-document", 0
    lines = text.splitlines()

    start, end, mode = 0, len(lines), "whole-document"
    for i, line in enumerate(lines):
        if ACC_DEVIATIONS_HEADING_RE.match(line):
            continue
        m = ACC_HEADING_RE.match(line)
        if m:
            level = len(m.group(1))
            start, mode = i + 1, "acceptance-section"
            end = len(lines)
            for j in range(start, len(lines)):
                h = ANY_HEADING_RE.match(lines[j])
                if (h and len(h.group(1)) <= level) or ACC_HR_RE.match(lines[j]):
                    end = j
                    break
            break

    items, indents = [], []
    for line in lines[start:end]:
        bullet = ACC_BULLET_RE.match(line)
        if bullet:
            items.append([bullet.group(2).strip(), [line.rstrip()]])
            indents.append(len(bullet.group(1).expandtabs(4)))
            continue
        if not items:
            continue
        if not line.strip() or ANY_HEADING_RE.match(line) or ACC_HR_RE.match(line):
            continue
        if len(line) - len(line.lstrip()) > indents[-1]:
            items[-1][0] += " " + line.strip()
            items[-1][1].append(line.rstrip())

    dropped = max(0, len(items) - cap)
    kept = [(normalize_criterion(t), raw) for t, raw in items[:cap]]
    return kept, mode, dropped

def render_inline_checklist(items, dropped, doc_path, cap=25):
    """The packet's acceptance block. A cap that fires SAYS SO — a silent truncation is the same
    failure as a silent drop, one item coarser."""
    block = "\n".join("\n".join(raw) for _text, raw in items)
    if dropped > 0:
        block += (f"\n\n> **{dropped} further criterion(a) not shown** — this packet caps the inlined "
                  f"checklist at {cap} items. Read the remainder in `{doc_path}` before treating this "
                  "list as complete.")
    return block

def verify_inlined_acceptance(block_text, expected):
    """Re-parse the rendered block and report any criterion that did not survive the copy.

    GH-399 asks preflight to fail rather than warn on a lossy inline. The check is deliberately run
    against the RENDERED text rather than trusting the builder of it, so a future change to the
    rendering (a cap, a filter, a reflow) is caught by this instead of by a builder months later.
    """
    reparsed, _mode, _dropped = collect_inline_checklist(block_text, cap=len(expected) or 1)
    got = [t for t, _raw in reparsed]
    return [t for t, _raw in expected if t not in got]

def repo_slug_for(cwd):
    """`owner/name` from the origin remote, or None — used only to build a clickable issue URL."""
    try:
        url = subprocess.check_output(["git", "-C", cwd, "remote", "get-url", "origin"],
                                      stderr=subprocess.DEVNULL).decode('utf-8').strip()
    except Exception:
        return None
    m = re.search(r'(?:github\.com[:/])([^/]+/[^/]+?)(?:\.git)?$', url)
    return m.group(1) if m else None

def check_acceptance_fidelity(doc_path, issue_number, cwd):
    """Compare a capture doc's acceptance block against its source issue's.

    status:
      match    — identical, or every difference is declared and reconciles exactly
      diverged — the doc's definition of done is not the issue's, and nothing explains the gap
      unknown  — cannot be determined (no issue, gh missing/unauthenticated/offline, no section)
    Only `diverged` blocks. `unknown` is reported loudly and never masked as a pass.
    """
    res = {"status": "unknown", "detail": "", "issue": issue_number,
           "dropped": [], "added": [], "declared": 0}
    if not issue_number:
        res["detail"] = "capture doc has no gh_issue — nothing to compare against"
        return res
    try:
        with open(doc_path, 'r', encoding='utf-8') as f:
            doc_text = f.read()
    except Exception:
        res["detail"] = f"capture doc unreadable: {doc_path}"
        return res

    body = fetch_issue_body(issue_number, cwd)
    if body is None:
        res["detail"] = (f"could not fetch issue #{issue_number} (gh missing, unauthenticated, or "
                         "offline) — acceptance fidelity NOT verified")
        return res

    issue_acc = extract_acceptance_criteria(body)
    doc_acc = extract_acceptance_criteria(doc_text)

    if issue_acc is None:
        res["detail"] = f"issue #{issue_number} has no '## Acceptance' section — nothing to copy from"
        return res
    # An acceptance section that exists but lists nothing is NOT the same as no section. Collapsing
    # the two let a doc invent arbitrary criteria under its own heading and still read `unknown`
    # (agy review). An empty issue list is a real list: everything the doc adds is an addition, and
    # additions have to be declared like any other deviation.
    if doc_acc is None:
        res["status"] = "diverged"
        res["dropped"] = list(issue_acc)
        res["detail"] = (f"issue #{issue_number} states {len(issue_acc)} acceptance criteria and the "
                         "capture doc has no '## Acceptance' section at all")
        return res

    dropped = [c for c in issue_acc if c not in doc_acc]
    added = [c for c in doc_acc if c not in issue_acc]
    dev = extract_declared_deviations(doc_text)
    if not dropped and not added:
        # A deviations section with nothing to reconcile is not harmless: it tells a reader the
        # criteria were narrowed when the list above says they were not. Reconciliation therefore
        # runs whenever the section exists, not only when the lists disagree.
        stale = len(dev["dropped"]) + len(dev["added"]) + len(dev["changed"]) + len(dev["malformed"])
        if stale:
            res["status"] = "diverged"
            res["declared"] = stale
            res["problems"] = ([f"declares {stale} deviation(s) while the doc's acceptance block matches "
                                "the issue exactly — remove them, or make the list say what the lane "
                                "actually delivers"] + dev["malformed"])
            res["detail"] = "deviations are declared but the two lists do not differ"
            return res
        res["status"] = "match"
        res["detail"] = f"{len(issue_acc)}/{len(issue_acc)} criteria copied verbatim from issue #{issue_number}"
        return res

    res["declared"] = len(dev["dropped"]) + len(dev["added"]) + len(dev["changed"])
    unresolved_dropped, unresolved_added = list(dropped), list(added)
    problems = list(dev["malformed"])

    for cands, _reason in dev["changed"]:
        for old, new in cands:
            if old in unresolved_dropped and new in unresolved_added:
                unresolved_dropped.remove(old)
                unresolved_added.remove(new)
                break
        else:
            problems.append("[changed] declares a rewrite that does not match the actual diff: "
                            f"{cands[0][0][:90]}")
    for text_, _reason in dev["dropped"]:
        if text_ in unresolved_dropped:
            unresolved_dropped.remove(text_)
        else:
            problems.append(f"[dropped] names a criterion the issue does not state (or that the doc still carries): {text_[:90]}")
    for text_, _reason in dev["added"]:
        if text_ in unresolved_added:
            unresolved_added.remove(text_)
        else:
            problems.append(f"[added] names a criterion the doc does not carry: {text_[:90]}")

    res["dropped"], res["added"] = unresolved_dropped, unresolved_added
    if not unresolved_dropped and not unresolved_added and not problems:
        res["status"] = "match"
        res["detail"] = (f"{len(issue_acc)} issue criteria reconciled: {res['declared']} deviation(s) "
                         "declared and accounted for")
        return res

    res["status"] = "diverged"
    bits = []
    if unresolved_dropped:
        bits.append(f"{len(unresolved_dropped)} issue criterion(a) missing from the doc with no declared deviation")
    if unresolved_added:
        bits.append(f"{len(unresolved_added)} doc criterion(a) absent from the issue with no declared deviation")
    if problems:
        bits.append(f"{len(problems)} malformed/unmatched deviation entry(ies)")
    res["detail"] = "; ".join(bits)
    res["problems"] = problems
    return res

def acceptance_fidelity_report(res):
    """Multi-line operator-facing explanation of a divergence."""
    out = []
    for c in res.get("dropped", []):
        out.append(f"    MISSING FROM DOC (issue says): {c}")
    for c in res.get("added", []):
        out.append(f"    NOT IN ISSUE  (doc says)     : {c}")
    for p in res.get("problems", []):
        out.append(f"    DEVIATION PROBLEM            : {p}")
    return out

def doc_frontmatter(doc_path):
    """A capture doc's YAML frontmatter block as text, or None.

    Frontmatter only — never the body. A `source:` line inside a fenced example in the prose is
    documentation, not provenance, and must not be mistaken for the real field.
    """
    try:
        with open(doc_path, 'r', encoding='utf-8') as f:
            text = f.read()
    except Exception:
        return None
    m = re.match(r'^---\n(.*?)\n---', text, re.DOTALL)
    return m.group(1) if m else None

def doc_frontmatter_issue(doc_path):
    """`gh_issue:` from a capture doc's YAML frontmatter, or None."""
    fm = doc_frontmatter(doc_path)
    if fm is None:
        return None
    m2 = re.search(r'^gh_issue:\s*"?(\d+)"?\s*$', fm, re.MULTILINE)
    return m2.group(1) if m2 else None

ISSUE_URL_RE = re.compile(r'https?://github\.com/([^/\s]+/[^/\s]+?)/issues/(\d+)')

def check_source_url(doc_path, issue_number):
    """GH-400 criterion 2: a capture doc naming a `gh_issue` must carry that issue's URL.

    Until now this was an instruction in `skills/10days/SKILL.md` and nothing more — the field was
    never read by any gate, so `source: issue#400`, or no `source` at all, passed everything. That
    is the same "trust the model's output as though it were verified" shape GH-400 exists to close,
    reproduced inside GH-400's own fix.

    Purely local: it reads frontmatter, never the network, so unlike the acceptance-fidelity check
    it has no offline-degradation case. The only pass-through is having no `gh_issue` to point at.

    status:
      ok             — a GitHub issue URL whose number matches `gh_issue`
      missing        — no `source:`, or one carrying no GitHub issue URL
      mismatch       — a GitHub issue URL pointing at a DIFFERENT issue than `gh_issue`
      not-applicable — the doc names no `gh_issue`, so there is nothing to point at
      unknown        — the doc could not be read
    Only `ok` and `not-applicable` pass.
    """
    res = {"status": "unknown", "detail": "", "issue": issue_number, "url": None, "slug": None}
    if not issue_number:
        res["status"] = "not-applicable"
        res["detail"] = "capture doc names no gh_issue — no source URL is required"
        return res
    fm = doc_frontmatter(doc_path)
    if fm is None:
        res["detail"] = f"capture doc has no YAML frontmatter to read a source: from: {doc_path}"
        return res

    m = re.search(r'^source:\s*(.+?)\s*$', fm, re.MULTILINE)
    if not m:
        res["status"] = "missing"
        res["detail"] = (f"frontmatter names gh_issue: {issue_number} but carries no 'source:' field — "
                         "a reader cannot get from this doc to the issue it claims to implement")
        return res

    raw = m.group(1).strip().strip('"\'')
    u = ISSUE_URL_RE.search(raw)
    if not u:
        res["status"] = "missing"
        res["detail"] = (f"source: is not a GitHub issue URL (got \"{raw[:70]}\") — a bare reference "
                         f"like 'issue#{issue_number}' is not diffable against anything")
        return res

    res["slug"], res["url"] = u.group(1), u.group(0)
    if u.group(2) != str(issue_number):
        res["status"] = "mismatch"
        res["detail"] = (f"source: points at issue #{u.group(2)} but frontmatter declares "
                         f"gh_issue: {issue_number} — the doc cites provenance it does not have")
        return res

    res["status"] = "ok"
    res["detail"] = f"source: resolves to issue #{issue_number} ({res['url']})"
    return res

def main():
    parser = argparse.ArgumentParser(description="swarm-preflight", add_help=False)
    parser.add_argument("--project-doc", dest="project_doc")
    parser.add_argument("--gh-issue", dest="gh_issues", action="append", default=[])
    parser.add_argument("--target-root", dest="target_root")
    parser.add_argument("--out", dest="out_dir")
    parser.add_argument("--format", dest="format", default="text", choices=["text", "json"])
    parser.add_argument("--dry-run", dest="dry_run", action="store_true")
    parser.add_argument("--help", action="store_true")

    args, unknown = parser.parse_known_args()
    if args.help:
        print("Usage: utils/swarm-preflight.sh (--project-doc DOC | --gh-issue N [--gh-issue N ...]) [options]")
        sys.exit(0)

    # GH-322: `unknown` was captured and never read, so ANY unrecognised flag was silently
    # discarded. Because Python is the executing lane (GH-264), that made `--log-github` — the
    # headline feature of GH-284 Phase 2, which exists only in the Bash twin — a no-op: the marathon
    # ran, exited 0, reported success, and never posted a run log. All three Bash twins `die
    # "unknown argument: $1"`; this restores that contract byte-for-byte (same prefix, same exit 2).
    # Checked AFTER --help so `--help` still works alongside a bad flag.
    if unknown:
        # This twin's Bash `*)` case is `usage; die "unknown argument: $1"`, so print usage first.
        # sys.stdout.flush() is load-bearing: usage goes to stdout and die() to stderr, and without
        # the flush the two arrive out of order under a `2>&1` capture — the diagnostic would appear
        # ABOVE the usage it is supposed to follow.
        # The usage TEXT still differs from the Bash twin's full block (a pre-existing `--help`
        # divergence, not introduced here); test/gh322-unknown-arg-rejection.sh therefore pins the
        # `unknown argument:` line across both lanes rather than whole-output equality.
        print("Usage: utils/swarm-preflight.sh (--project-doc DOC | --gh-issue N [--gh-issue N ...]) [options]")
        sys.stdout.flush()
        die(f"unknown argument: {unknown[0]}")

    if args.project_doc and args.gh_issues:
        die("--project-doc and --gh-issue are mutually exclusive; pick one input mode")
    if not args.project_doc and not args.gh_issues:
        die("one input mode required: --project-doc DOC or --gh-issue N")

    default_root, drive_cmd = compute_default_root(__file__)
    # here_parent below is one level up from this file's dir (utils/, or .xyz/utils/ when
    # vendored) — the anchor the relay-turn-lib.sh lookup further down needs; distinct from
    # (one level shallower than) compute_default_root's own two-levels-up anchor.
    here_parent = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    root = get_env("SWARM_PREFLIGHT_ROOT", default_root)
    
    now = get_env("SWARM_PREFLIGHT_NOW", datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))
    today = get_env("SWARM_PREFLIGHT_TODAY", datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d"))

    target_root = args.target_root or root
    try:
        target_toplevel = subprocess.check_output(["git", "-C", target_root, "rev-parse", "--show-toplevel"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
    except subprocess.CalledProcessError:
        emit(f"BLOCKED: --target-root is not a git repo: {target_root}")
        sys.exit(6)
    target_root = target_toplevel

    source_docs = []
    source_issues = []
    
    def resolve_path(p):
        return p if os.path.isabs(p) else os.path.join(root, p)

    if args.project_doc:
        mode = "project-doc"
        doc = resolve_path(args.project_doc)
        if not os.path.isfile(doc):
            emit(f"BLOCKED: project doc not found: {args.project_doc}")
            sys.exit(6)
        source_docs.append(doc)
    else:
        mode = "gh-bundle"
        import glob
        for n in args.gh_issues:
            if not n.isdigit():
                die(f"--gh-issue expects a number, got: {n}")
            pattern = os.path.join(root, "PROJECT", "2-WORKING", f"GH-{n}-*.md")
            matches = glob.glob(pattern)
            if not matches:
                emit(f"BLOCKED: issue #{n} has no in-repo GH-{n}-*.md capture doc under PROJECT/2-WORKING/.")
                emit(f"  Per GUIDING-PRINCIPLES.md §11 the planner reads the capture doc, not the issue thread.")
                emit(f"  Remediation: promote issue #{n} to a GH-{n} capture doc with a preflight contract first.")
                sys.exit(6)
            source_docs.append(matches[0])
            source_issues.append(n)

    contracts = []
    for doc in source_docs:
        try:
            c = extract_contract(doc)
            contracts.append(c)
        except SystemExit as e:
            emit(f"CONTRACT ERROR ({doc}): see message above. The planner fails loud rather than guessing from prose.")
            if e.code == 3:
                emit("")
                emit(f"  To fix, add a minimal valid contract in {doc}")
                emit("  (copy relay-automation/CONTRACT.example.md for a detailed example):")
                emit("")
                emit("  ## Swarm Preflight Contract")
                emit("  ```json")
                emit("  {")
                emit('    "target":      { "repo": ".", "ref": "main" },')
                emit('    "gate":        "bash validate.sh",')
                emit('    "fix_probes":  [ { "type": "path_absent", "path": "new-file.txt" } ],')
                emit('    "artifacts":   [ "new-file.txt" ]')
                emit("  }")
                emit("  ```")
            sys.exit(e.code)
            
    try:
        merged = merge_contracts(contracts)
    except SystemExit as e:
        emit("AMBIGUOUS: the issue bundle's contracts disagree (see message above). Split the bundle or align the contracts.")
        sys.exit(e.code)

    effective_artifacts = expand_effective_artifacts(target_root, merged)

    primary_doc = source_docs[0]
    slug = re.sub(r'[^a-z0-9]', '-', os.path.splitext(os.path.basename(primary_doc))[0].lower())
    slug = re.sub(r'-+', '-', slug).strip('-')
    if not slug: slug = "preflight"
    
    try: branch = subprocess.check_output(["git", "-C", target_root, "symbolic-ref", "--quiet", "--short", "HEAD"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
    except: branch = "(detached)"
    
    try: commit = subprocess.check_output(["git", "-C", target_root, "rev-parse", "HEAD"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
    except: commit = "(none)"

    suggested_branch = f"marathon/{slug}-{today}"
    branch_ready = 0
    try:
        subprocess.check_call(["git", "-C", target_root, "show-ref", "--verify", "--quiet", f"refs/heads/{suggested_branch}"])
        branch_ready = 1
    except subprocess.CalledProcessError:
        try:
            subprocess.check_call(["git", "-C", target_root, "show-ref", "--verify", "--quiet", f"refs/remotes/origin/{suggested_branch}"])
            branch_ready = 1
        except subprocess.CalledProcessError:
            pass

    fetch_ok = 1
    try: subprocess.check_call(["git", "-C", target_root, "fetch", "--prune", "--quiet"], stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError: fetch_ok = 0
    
    try: upstream = subprocess.check_output(["git", "-C", target_root, "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
    except: upstream = ""
    
    ahead, behind = 0, 0
    if upstream:
        try:
            counts = subprocess.check_output(["git", "-C", target_root, "rev-list", "--left-right", "--count", f"{upstream}...HEAD"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
            behind, ahead = counts.split()
        except: pass
        
    dirty = 0
    try:
        if subprocess.check_output(["git", "-C", target_root, "status", "--porcelain"], stderr=subprocess.DEVNULL).decode('utf-8').strip():
            dirty = 1
    except: pass

    # GH-203: an advisory-only stale .git/index.lock. Use lsof on the exact lock path so a
    # live git command holding the lock does NOT read as "stale". If lsof is unavailable, stay
    # silent rather than guess. Never changes the ready verdict.
    stale_index_lock = 0
    stale_index_lock_path = ""
    stale_index_lock_warning = ""
    index_lock_path = os.path.join(target_root, ".git", "index.lock")
    if os.path.exists(index_lock_path) and shutil.which("lsof"):
        rc_lsof = subprocess.call(["lsof", "-t", "--", index_lock_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if rc_lsof != 0:
            stale_index_lock = 1
            stale_index_lock_path = index_lock_path
            stale_index_lock_warning = f"stale git index lock detected at {index_lock_path} - verify no live git process (pgrep -fl git), then rm .git/index.lock"

    for a in merged.get("artifacts_new", []):
        has_probe = any(p and p.get("type") == "path_absent" and p.get("path") == a for p in merged.get("fix_probes", []))
        if not has_probe:
            emit(f"CONTRACT ERROR: artifacts_new entry '{a}' has no matching fix_probes entry of type path_absent on the same path")
            sys.exit(3)
            
    fresh_blocked = 1 if fetch_ok == 0 else 0
    
    ref = merged["target"]["ref"]
    try: ref_commit = subprocess.check_output(["git", "-C", target_root, "rev-parse", "--verify", "--quiet", f"{ref}^{{commit}}"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
    except: ref_commit = ""
    
    if not ref_commit:
        emit(f"BLOCKED: contract target.ref '{ref}' does not resolve in {target_root} (fetch_ok={fetch_ok}).")
        emit(f"  The marathon would branch from this ref; if it can't be resolved the preflight is blind.")
        emit(f"  Remediation: push/fetch the ref, or correct target.ref in the contract.")
        sys.exit(6)
        
    try: head_behind_ref = subprocess.check_output(["git", "-C", target_root, "rev-list", "--count", f"HEAD..{ref_commit}"], stderr=subprocess.DEVNULL).decode('utf-8').strip()
    except: head_behind_ref = "0"
    
    checkout_matches_ref = 1 if commit == ref_commit else 0
    
    import tempfile
    ref_wt = tempfile.mkdtemp(prefix="swarm-preflight-ref-")
    shutil.rmtree(ref_wt)
    try:
        subprocess.check_call(["git", "-C", target_root, "worktree", "add", "--detach", "--quiet", ref_wt, ref_commit], stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        emit(f"BLOCKED: could not create a worktree at target.ref '{ref}' ({ref_commit}) in {target_root}.")
        sys.exit(6)
        
    probes_res, stale, blocked, ambig = eval_probes(ref_wt, merged)
    
    gh39_art_missing = ""
    for a in merged.get("artifacts", []):
        a = a.strip()
        if not a: continue
        if a in merged.get("artifacts_new", []): continue
        if not os.path.exists(os.path.join(ref_wt, a)):
            gh39_art_missing = a
            break
            
    try: subprocess.check_call(["git", "-C", target_root, "worktree", "remove", "--force", ref_wt], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except: shutil.rmtree(ref_wt, ignore_errors=True)
    try: subprocess.check_call(["git", "-C", target_root, "worktree", "prune"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except: pass
    
    cand_state = "ready"
    if blocked == 1 or fresh_blocked == 1: cand_state = "blocked"
    elif ambig == 1: cand_state = "ambiguous"
    elif stale == 1: cand_state = "stale"
    
    ready = 1
    ready_next = ""
    gate_cmd = merged.get("gate", "")
    all_artifacts = effective_artifacts["artifacts"]
    art_csv = ",".join(all_artifacts)
    art_count = len(all_artifacts)
    gh55_auto_csv = ",".join(effective_artifacts["inferred_tests"] + effective_artifacts["inferred_helpers"])
    gh55_auto_line = f"- Auto-included covering tests/helpers: {gh55_auto_csv}" if gh55_auto_csv else ""
    fs_touching_tests_csv = ",".join(effective_artifacts["fs_touching_tests"])
    if fs_touching_tests_csv:
        gh54_verify_rule = (
            f"- Do NOT run ANY test or gate yourself — not `{gate_cmd}`, and NOT `{fs_touching_tests_csv}` "
            "either. Those tests create temporary git fixtures/files inside your isolated worktree, which "
            "containment treats as off-lane edits and can discard your whole turn. Read them as specs "
            "instead; the harness runs the real gate after your turn, outside the worktree."
        )
    else:
        gh54_verify_rule = (
            f"- Do NOT run the full gate (`{gate_cmd}`) yourself — it can create files that trip containment "
            "and discard your turn. Verify with ONLY the specific test for the file(s) you changed; the "
            "harness runs the gate after your turn."
        )
    gh108_gate_caveat = gate_scoping_caveat(gate_cmd)
    
    fm_risk = ""
    try:
        with open(primary_doc, 'r') as f:
            for line in f:
                m = re.match(r'^risk:\s*(\d+)', line)
                if m:
                    fm_risk = m.group(1)
                    break
    except: pass
    
    zone_kernel_paths = ["relay-automation/relay-turn-lib.sh", "bin/tick", "relay-automation/relay-drive.sh"]
    zone = "independent"
    for a in all_artifacts:
        a = a.strip()
        for k in zone_kernel_paths:
            if a == k or a.startswith(k):
                zone = "kernel"
                break
        if zone == "kernel": break
        
    if zone != "kernel":
        for a in all_artifacts:
            a_lc = a.strip().lower()
            if a_lc.startswith("relay-automation/") and (a_lc.endswith("-turn.sh") or a_lc.endswith("consult.sh")):
                rest = a_lc[len("relay-automation/"):]
                if "/" not in rest:
                    zone = "shim"
            if zone == "shim": break

    skip_branch_prompt = 1 if fm_risk == "1" and zone == "independent" else 0
    
    remed_src = merged.get("remediation", {}).get("source") if merged.get("remediation") else ""
    remed_crit = merged.get("remediation", {}).get("criteria") if merged.get("remediation") else ""
    
    doc_has_phases = 0
    try:
        with open(primary_doc, 'r') as f:
            for line in f:
                if re.match(r'^##+ .*[Pp]hase', line) or re.match(r'^- \[[ xX]\]', line):
                    doc_has_phases = 1
                    break
    except: pass
    
    if not gate_cmd: ready, ready_next = 0, "add a runnable gate command to the contract"
    if art_count == 0: ready, ready_next = 0, "add a bounded artifact / ALLOW_PATHS set to the contract"
    if not remed_src and not remed_crit and doc_has_phases == 0:
        ready, ready_next = 0, "research more: no phase plan or acceptance criteria — source is not runnable unattended"
        
    if ready == 1 and gh39_art_missing:
        ready, ready_next = 0, f"artifact path not found at target.ref: {gh39_art_missing} — fix the contract artifacts[] or push the file"

    # GH-400: the packet's definition of done is the capture doc's checklist, which a model wrote by
    # summarising the issue. Refuse to emit one whose acceptance criteria have drifted from the
    # source of truth without a declared reason — nothing downstream can catch it, because neither
    # the builder nor the reviewer ever sees the issue.
    acc_issue = source_issues[0] if source_issues else doc_frontmatter_issue(primary_doc)
    acc_fidelity = check_acceptance_fidelity(primary_doc, acc_issue, target_root)

    # GH-400 criterion 2: the doc must carry the URL of the issue it claims to implement, so the
    # two can be diffed in one step. Shipped as prose in the skill and enforced nowhere, which left
    # GH-400's own fix resting on an unverified model output — the exact shape GH-400 is about.
    src_url = check_source_url(primary_doc, doc_frontmatter_issue(primary_doc) or acc_issue)

    # GH-399: build the packet's checklist HERE, before the verdict, so a lossy copy blocks the run
    # instead of being discovered by whoever reads the packet. Rendering still happens below.
    try:
        with open(primary_doc, 'r', encoding='utf-8') as f:
            _acc_doc_text = f.read()
    except Exception:
        _acc_doc_text = ""
    acc_items, acc_mode, acc_dropped = collect_inline_checklist(_acc_doc_text)
    acc_lost = verify_inlined_acceptance(render_inline_checklist(acc_items, acc_dropped, primary_doc), acc_items)
    if ready == 1 and acc_lost:
        ready, ready_next = 0, (
            f"the packet's acceptance block would not be a lossless copy of {primary_doc} — "
            f"{len(acc_lost)} criterion(a) did not survive inlining, first: \"{acc_lost[0][:90]}\". "
            "This is a preflight bug, not a contract error; do not work around it by editing the doc.")
    if ready == 1 and acc_fidelity["status"] == "diverged":
        ready, ready_next = 0, (
            f"acceptance criteria diverge from issue #{acc_fidelity['issue']} — {acc_fidelity['detail']}. "
            "Copy the issue's '## Acceptance' block verbatim, or declare each deviation under "
            "'## Acceptance — deviations from the issue' as `- [dropped|changed|added] <text> — reason: <why>'")
    if ready == 1 and src_url["status"] in ("missing", "mismatch"):
        ready, ready_next = 0, (
            f"capture doc source URL {src_url['status']} — {src_url['detail']}. "
            # GH-422: resolve owner/repo from the TARGET's origin rather than printing a placeholder.
            # The harness knows this value; making an operator look it up once per doc is how a
            # one-line fix turns into an afternoon in a repo with a dozen affected capture docs.
            f"Set `source: https://github.com/{repo_slug_for(target_root) or '<owner>/<repo>'}"
            f"/issues/{src_url['issue']}` in the doc's frontmatter (GH-400), or run "
            f"`python3 utils/py/backfill_source_url.py --apply` to fix every affected doc at once. "
            "This is local-only: it never needs the network, so there is no "
            "offline case in which it is safe to skip.")
        
    if ready == 1 and gate_cmd:
        gate_parts = gate_cmd.split()
        if gate_parts:
            g0 = gate_parts[0]
            if g0 in ["bash", "sh"]:
                script = ""
                for t in gate_parts[1:]:
                    if not t.startswith("-"):
                        script = t
                        break
                if not script or not os.path.isfile(os.path.join(target_root, script)):
                    ready, ready_next = 0, f"gate script not found at target.ref: {script or '<none>'}"
            # GH-308 port: any non-bash/sh gate program must resolve on PATH (swarm-preflight.sh:774).
            # Python exempted node/npm/python3, so a contract whose gate runner (e.g. `npm test`) is NOT
            # installed was emitted as marathon-ready (exit 0) instead of refused NOT-READY (exit 5) on
            # the live lane. `elif` mirrors the Bash structure (a bash/sh gate is not also PATH-checked).
            elif not shutil.which(g0):
                ready, ready_next = 0, f"command '{g0}' not found in PATH"
                    
    has_codex = "present" if shutil.which("codex") else "missing"
    has_agy = "present" if shutil.which("agy") else "missing"
    gh39_lane_note = f"codex={has_codex} agy={has_agy}"
    
    lane_plan_res = lane_plan(merged, effective_artifacts)
    
    e = {
        "SP_CONTRACT": merged,
        "SP_PROBES": probes_res,
        "SP_LANES": lane_plan_res,
        "SP_DOCS": "\n".join(source_docs),
        "SP_ISSUES": ",".join(source_issues),
        "SP_MODE": mode,
        "SP_SLUG": slug,
        "SP_BRANCH": branch,
        "SP_COMMIT": commit,
        "SP_SUGGESTED_BRANCH": suggested_branch,
        "SP_BRANCH_READY": "1" if branch_ready else "0",
        "SP_SKIP_BRANCH_PROMPT": "1" if skip_branch_prompt else "0",
        "SP_ROOT": target_root,
        "SP_NOW": now,
        "SP_STATE": cand_state,
        "SP_FETCH": "1" if fetch_ok else "0",
        "SP_UP": upstream,
        "SP_AHEAD": str(ahead),
        "SP_BEHIND": str(behind),
        "SP_DIRTY": "1" if dirty else "0",
        "SP_STALE_INDEX_LOCK": "1" if stale_index_lock else "0",
        "SP_STALE_INDEX_LOCK_PATH": stale_index_lock_path,
        "SP_STALE_INDEX_LOCK_WARNING": stale_index_lock_warning,
        "SP_REF": ref,
        "SP_REF_COMMIT": ref_commit,
        "SP_HEAD_BEHIND_REF": str(head_behind_ref),
        "SP_CHECKOUT_MATCHES_REF": "1" if checkout_matches_ref else "0",
        "SP_READY": "1" if ready else "0",
        "SP_NEXT": ready_next,
        "SP_ACC_FIDELITY": acc_fidelity,
        "SP_SRC_URL": src_url,
        "SP_ACC_INLINE": {"criteria": len(acc_items), "scope": acc_mode,
                          "over_cap": acc_dropped, "lossless": not acc_lost}
    }
    
    rc_obj = normalize(e)
    
    verdict = "ready"
    code = 0
    if cand_state == "blocked": verdict, code = "BLOCKED", 6
    elif cand_state == "ambiguous": verdict, code = "AMBIGUOUS", 7
    elif cand_state == "stale": verdict, code = "STALE", 4
    elif cand_state == "ready" and ready == 0: verdict, code = "NOT-READY", 5
    
    target_root_line = ""
    if os.path.realpath(target_root) != os.path.realpath(root):
        target_root_line = f"\n  --target-root {target_root} \\"
        
    invocation = f"""XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID={slug} RELAY_WORKTREE_ISOLATION=1 {drive_cmd} \\
  --phase-brief <packet>/packet.md \\
  --reviewer agy \\
  --builder codex \\
  --artifact {art_csv} \\{target_root_line}
  --pre-advance-cmd '{gate_cmd}' \\
  --require-clean"""

    if args.format == "json":
        print(json.dumps(rc_obj, indent=2))
    else:
        if checkout_matches_ref: ref_note = "checkout matches"
        else: ref_note = f"checkout HEAD is {head_behind_ref} commit(s) behind the evaluated ref — probes read the ref, not your checkout"
        
        emit(f"swarm-preflight · {mode} · slug={slug}")
        emit(f"  target-root : {target_root} ({branch} @ {commit[:9]})")
        emit(f"  branch      : suggested={suggested_branch} branch_ready={'true' if branch_ready else 'false'} skip_branch_prompt={'true' if skip_branch_prompt else 'false'}")
        emit(f"  freshness   : fetch_ok={fetch_ok} upstream={upstream or 'none'} ahead={ahead} behind={behind} dirty={dirty}")
        if stale_index_lock == 1:
            emit(f"  warning     : {stale_index_lock_warning}")
        emit(f"  ref-probed  : {ref} @ {ref_commit[:9]} ({ref_note})")
        emit(f"  candidate   : {cand_state}")
        emit(f"  inlined-acc : {len(acc_items)} criterion(a) from the {acc_mode}"
             f"{f', {acc_dropped} over the 25-item cap (reported in the packet)' if acc_dropped else ''}")
        emit(f"  source-url  : {src_url['status']} — {src_url['detail']}")
        emit(f"  acceptance  : {acc_fidelity['status']} — {acc_fidelity['detail']}")
        for line in acceptance_fidelity_report(acc_fidelity):
            emit(line)
        emit(f"  readiness   : ready={ready}{f' — next: {ready_next}' if ready_next else ''}")
        emit(f"  lane-cli    : {gh39_lane_note} (advisory)")
        emit(f"  verdict     : {verdict} (exit {code})")
        
    if code != 0:
        if args.format != "json":
            emit("")
            emit(f"No packet written — candidate is not preflight-ready ({verdict}).")
        sys.exit(code)
        
    out_dir = args.out_dir
    if not out_dir:
        try:
            ts_base = subprocess.check_output(f"source \"{os.path.join(here_parent, '..', 'relay-automation', 'relay-turn-lib.sh')}\" && rtl_transcript_root \"{root}\"", shell=True, executable="/bin/bash").decode('utf-8').strip()
        except subprocess.CalledProcessError: 
            sys.exit(1)
        out_dir = os.path.join(ts_base, "preflight", today, slug)
        
    if args.dry_run:
        if args.format != "json":
            emit("")
            emit(f"DRY-RUN: ready, but packet not written. Would emit to: {out_dir}")
            emit("Would suggest:")
            emit(invocation)
        sys.exit(0)
        
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "run-candidate.json"), "w") as f: json.dump(rc_obj, f, indent=2)
    with open(os.path.join(out_dir, "lane-plan.json"), "w") as f: json.dump(lane_plan_res, f, indent=2)
    with open(os.path.join(out_dir, "freshness.json"), "w") as f: json.dump(rc_obj["freshness"], f, indent=2)
    with open(os.path.join(out_dir, "readiness.json"), "w") as f: json.dump(rc_obj["readiness"], f, indent=2)
    with open(os.path.join(out_dir, "marathon-invocation.txt"), "w") as f: f.write(invocation + "\n")
    
    # GH-399: inline the checklist with its hard-wrapped continuation lines intact. The previous
    # line-oriented match kept only each bullet's first line, so a wrapped criterion reached the
    # builder as a half-sentence — and the reviewer graded against the same damaged copy.
    gh39_acc = render_inline_checklist(acc_items, acc_dropped, primary_doc)
    if not gh39_acc:
        gh39_acc = f"(no '- [ ]' checklist found in {primary_doc} — add an Acceptance criteria list)"
    if acc_mode == "acceptance-section":
        acc_scope_note = f"its `## Acceptance` section, {len(acc_items)} criterion(a)"
    else:
        acc_scope_note = (f"{len(acc_items)} checkbox(es) found across the WHOLE document — the doc has "
                          "no `## Acceptance` section, so this list may include phase checklists")

    # GH-400: state where this checklist came from and whether it was checked against that source.
    # The builder and reviewer never see the issue, so an unverified list must SAY it is unverified
    # instead of arriving under a bare "inlined from the capture doc" heading that reads as provenance.
    if acc_fidelity["status"] == "match":
        _slug = repo_slug_for(target_root)
        _ref = (f"[issue #{acc_fidelity['issue']}](https://github.com/{_slug}/issues/{acc_fidelity['issue']})"
                if _slug else f"issue #{acc_fidelity['issue']}")
        acc_provenance_line = f"*Verified against {_ref} — {acc_fidelity['detail']}.*"
    else:
        acc_provenance_line = (f"*NOT verified against the source issue — {acc_fidelity['detail']}. "
                               "Treat this list as a summary, not a contract: if anything here is "
                               "ambiguous, read the issue before building.*")
    
    gh39_art_loc = 0
    for a in merged.get("artifacts", []):
        a = a.strip()
        if not a: continue
        target_a = os.path.join(target_root, a)
        if os.path.isfile(target_a):
            try:
                with open(target_a, 'r') as f:
                    gh39_art_loc += len(f.readlines())
            except: pass
            
    gh39_art_n = len([a for a in all_artifacts if a.strip()])
    gh39_timeout = 300
    if gh39_art_loc > 200 or gh39_art_n >= 3: gh39_timeout = 600
    if gh39_art_loc > 400 or gh39_art_n >= 4: gh39_timeout = 900
    
    br_ready_str = 'true' if branch_ready else 'false'
    if branch_ready == 0 and skip_branch_prompt == 0: br_prompt_str = " — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8"
    elif skip_branch_prompt == 1: br_prompt_str = " — carve-out: risk=1/independent zone, proceed on the current branch without asking"
    else: br_prompt_str = ""
    
    packet_md = f"""# Marathon preflight packet — {slug}

- Generated: {now}
- Mode: {mode}
- Sources: {" ".join(source_docs)} 
- Target root: {target_root} ({branch} @ {commit[:9]})
- Suggested branch: `{suggested_branch}` (branch_ready={br_ready_str}{br_prompt_str})
- Verdict: {verdict}
- Gate: `{gate_cmd}`
{gh108_gate_caveat}
- Artifacts: {art_csv}
- Suggested turn budget: `RELAY_TURN_TIMEOUT_S={gh39_timeout}` (sized to ≈ {gh39_art_loc} LOC across {gh39_art_n} artifact(s); a build that also edits tests needs headroom over the 300s default)
{gh55_auto_line}

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `{primary_doc}` ({acc_scope_note}). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
{acc_provenance_line}
{gh39_acc}

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `{art_csv}` (plus the relay file). Any other edit is reverted and FAILS the turn.
{gh54_verify_rule}
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
{invocation}
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
"""

    with open(os.path.join(out_dir, "packet.md"), "w") as f:
        f.write(packet_md)

    if args.format == "json":
        log(f"packet written: {out_dir}")
    else:
        emit(f"\nPacket written: {out_dir}")
        
    sys.exit(0)

if __name__ == "__main__":
    main()
