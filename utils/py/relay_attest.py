"""relay-drive/attest@1 — the one record that says a relay reviewer approved (GH-505 / GH-509).

The driver (relay_drive.py) is the only process in a relay the party under review does not run.
It is the ONLY writer of the approval fields, and it writes it only after watching a reviewer-role turn
append review text to a relay file whose reviewed revision the driver pinned before dispatch.

Marathon extends a validated approval with optional phase-completion metadata after its
success checks. Consumers, including jog's merge, read the approval only against
trusted expectations (task, expected reviewer, relay file, target repo). Existence proves nothing:
`load()` validates the reviewer, the terminal status (record == file == trailer), and the exact
byte range the reviewer added; `candidate_ok()` validates that a merge candidate is the reviewed
revision plus transcript-only commits.

The record lives under <git-common-dir>/relay-attest/. A worktree-isolated Codex turn cannot reach
it and containment never copies back into .git. An unsandboxed same-user host process can write
it — that is the stated non-goal (GH-505 plan); the driver's own exit code never depends on the
record, only on its in-process memory.
"""
import hashlib
import json
import os
import re
import subprocess
import tempfile

SCHEMA = "relay-drive/attest@1"
TRAILER_HEAD = "### Attestation · relay-drive"
TERMINAL = ("Approved", "Closed")
# Paths a commit may touch between the reviewed revision and a merge candidate without
# invalidating the review: the transcript tree, plus the relay file itself when it is tracked
# inside the target repo.
TRANSCRIPT_DIR = "relay-system"
# The only files marathon-drive writes beside a phase's RELAY.md (harness records, never source).
PHASE_RECORDS = ("ESCALATION.md", "PHASE-INTERRUPTED.md")

_HEADER_KEYS = (b"STATUS:", b"NEXT:", b"ROUND:")
_NEXT_TURN_MARKER = ("<!-- \u2193\u2193\u2193 NEXT TURN goes here "
                     "(append above nothing \u2014 this marker stays last) "
                     "\u2193\u2193\u2193 -->").encode("utf-8")

# The ONE other edit the harness itself makes to pre-existing relay lines: rtl_check_uncited_findings
# (relay-turn-lib.sh, GH-173 B3) downgrades an uncited [Pass]/"verified" claim in place after a
# reviewer turn. It is idempotent, so applying the same transform to BOTH snapshots makes the
# comparison see only what the reviewer added. Kept byte-for-byte in step with the awk: the claim
# words, the citation shapes, the inclusive window, and the two rewrite forms.
_CLAIM_RE = re.compile(rb"(^|[^A-Za-z])([Vv]erified|[Cc]onfirmed|LGTM|[Ll]ooks [Gg]ood|[Cc]hecks [Oo]ut|[Aa]ll [Gg]ood|[Ww]orks [Aa]s [Ee]xpected|[Nn]o issues( found)?)([^A-Za-z]|$)")
_CITE_RE = re.compile(rb'"[^"]+"|`[^`]+`|[A-Za-z0-9_./-]+:[0-9]+')
_UNCITED = "[Unverified — no citation]".encode("utf-8")


def _window():
    """`${RTL_CITATION_WINDOW:-3}`, then the SUPPORTED contract for the value: a non-negative integer.
    Unset/empty → 3; otherwise the leading integer prefix, else 0. This is not general awk numeric
    coercion (`1e1`, `-0.5` and friends differ between awk and this port) — those values are outside
    the contract on both sides; set a plain integer."""
    raw = os.environ.get("RTL_CITATION_WINDOW", "")
    if raw == "":
        return 3
    m = re.match(r"\s*([+-]?\d+)", raw)
    return int(m.group(1)) if m else 0


def _split_lines(raw):
    """awk semantics: records are split on LF only (a CR stays in $0) and every printed record ends
    with exactly one LF — so a missing final LF is added and CRLF is preserved inside the record."""
    if not raw:
        return []
    lines = raw.split(b"\n")
    if lines[-1] == b"":
        lines.pop()
    return [l + b"\n" for l in lines]


def _downgrade_uncited(lines, context=None):
    """rtl_check_uncited_findings, ported. `context` is the line list the citation look-ahead reads —
    normally `lines` itself; for a PRE-turn snapshot it is the POST-turn lines, because the awk runs
    once, after the turn, and sees the reviewer's appended lines when it judges the last lines of the
    old body (a citation appended right after an old uncited claim keeps that claim un-stamped)."""
    win = _window()
    ctx = [l[:-1] for l in (context if context is not None else lines)]
    out = []
    for i, line in enumerate(lines):
        body = line[:-1]
        if _UNCITED in body:
            out.append(line)
            continue
        if not (b"[Pass]" in body or _CLAIM_RE.search(body)):
            out.append(line)
            continue
        if any(_CITE_RE.search(ctx[j]) for j in range(i, min(len(ctx), i + win + 1))):
            out.append(line)
            continue
        body = body.replace(b"[Pass]", _UNCITED) if b"[Pass]" in body else body + b"  " + _UNCITED
        out.append(body + b"\n")
    return out


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def _normalise_headers(lines):
    seen = set()
    out = []
    for line in lines:
        for key in _HEADER_KEYS:
            if key not in seen and line.startswith(key):
                seen.add(key)
                line = key + b"\n"
                break
        out.append(line)
    return out


def _without_next_turn_marker(lines):
    """Drop the scaffold's position-only sentinel from append-only attestation.

    Reviewers are instructed to insert their block directly above this exact line, so the
    sentinel moves without its bytes changing.  Only the exact scaffold line is structural;
    near-matches and every other pre-existing byte remain covered by the prefix check.
    """
    return [line for line in lines if line.rstrip(b"\r\n") != _NEXT_TURN_MARKER]


def canonical_bytes(raw, context_raw=None):
    """The relay bytes with (a) the FIRST STATUS:/NEXT:/ROUND: lines reduced to bare keys and (b) the
    harness's own uncited-claim downgrade applied — with the look-ahead reading `context_raw` when
    given (the post-turn file, for a pre-turn snapshot).

    Those header lines are the only edits a turn is permitted to make above its own appended block,
    and the downgrade is the only edit the harness makes there — so normalising both makes
    "append-only" checkable whatever the file's leading format (marathon's and jog's title-first
    renders, frontmatter threads, bare KEY: lines) and whatever the harness stamped after the turn.
    """
    lines = _without_next_turn_marker(_normalise_headers(_split_lines(raw)))
    ctx = (_without_next_turn_marker(_normalise_headers(_split_lines(context_raw)))
           if context_raw is not None else None)
    return b"".join(_downgrade_uncited(lines, ctx))


def canonical(path):
    with open(path, "rb") as f:
        return canonical_bytes(f.read())


def canonical_prefix(pre_raw, post_raw):
    """The pre-turn snapshot as the post-turn file will carry it: header keys normalised and the
    uncited-claim downgrade judged with the post-turn lines as look-ahead context."""
    return canonical_bytes(pre_raw, context_raw=post_raw)


def separator_prefix_end(pre_raw, post_raw):
    """Return the ordinary canonical post offset for separator-only history drift.

    Canonical bytes and persisted records retain their original interpretation. Only
    empty LF lines outside fenced/indented literal content are optional. Whitespace-only
    lines, blockquotes and HTML/literal-looking contexts remain exact. Ambiguity refuses.
    """
    def protected_lines(raw):
        lines = _split_lines(raw)
        fence = None
        literal = None
        offset = 0
        result = []
        for i, line in enumerate(lines):
            body = line[:-1]
            match = re.match(rb" {0,3}(`{3,}|~{3,})(.*)$", body)
            protected = fence is not None or literal
            if match:
                run, rest = match.groups()
                if fence is None:
                    fence = (run[:1], len(run))
                elif run[:1] == fence[0] and len(run) >= fence[1] and not rest.strip():
                    fence = None
                protected = True
            # Conservatively retain blank lines adjacent to indented/quoted/HTML
            # content, and all blanks after an HTML opener (no Markdown parser here).
            stripped = body.lstrip()
            if literal == b"-->":
                if b"-->" in body:
                    literal = None
            elif literal == b"html":
                pass  # An inner comment cannot end an enclosing literal block.
            elif stripped.startswith(b"<!--"):
                literal = None if b"-->" in stripped else b"-->"
            elif stripped.startswith(b"<"):
                literal = b"html"
            left, right = i - 1, i + 1
            while left >= 0 and lines[left] == b"\n":
                left -= 1
            while right < len(lines) and lines[right] == b"\n":
                right += 1
            neighbors = ([lines[left]] if left >= 0 else []) + ([lines[right]] if right < len(lines) else [])
            adjacent_literal = any(n.startswith((b"    ", b"\t", b">", b"<")) for n in neighbors)
            optional = line == b"\n" and not protected and not literal and not adjacent_literal
            offset += len(line)
            if not optional:
                result.append((line, offset))
        return result

    # Separator edits invalidate positional POST look-ahead for PRE. Judge each
    # history at its own actual line positions in this fallback; append-sensitive
    # ambiguous citation changes refuse rather than inventing a mapped citation.
    pre = canonical_bytes(pre_raw)
    post = canonical_bytes(post_raw)
    before, after = protected_lines(pre), protected_lines(post)
    if not before or len(after) < len(before):
        return None
    if any(a[0] != b[0] for a, b in zip(before, after)):
        return None
    return after[len(before)-1][1]


def append_before_marker(path, text):
    """Append harness-owned text while keeping the scaffold sentinel as the final line."""
    payload = text.encode("utf-8")
    with open(path, "rb") as f:
        raw = f.read()
    lines = raw.splitlines(keepends=True)
    marker_at = next((i for i in range(len(lines) - 1, -1, -1)
                      if lines[i].rstrip(b"\r\n") == _NEXT_TURN_MARKER), None)
    if marker_at is None:
        updated = raw + payload
    else:
        updated = b"".join(lines[:marker_at]) + payload + b"".join(lines[marker_at:])
    directory = os.path.dirname(os.path.abspath(path))
    fd, tmp = tempfile.mkstemp(prefix=".relay-append.", dir=directory)
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(updated)
        os.replace(tmp, path)
    except BaseException:
        try:
            os.remove(tmp)
        except OSError:
            pass
        raise


def file_status(path):
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            for line in f:
                if line.startswith("STATUS:"):
                    return line.split(":", 1)[1].strip()
    except OSError:
        pass
    return ""


def git_common_dir(repo):
    out = subprocess.run(["git", "-C", repo, "rev-parse", "--git-common-dir"],
                         capture_output=True, text=True)
    if out.returncode != 0:
        raise RuntimeError(f"not a git repo: {repo}")
    gcd = out.stdout.strip()
    return gcd if os.path.isabs(gcd) else os.path.join(repo, gcd)


def path_for(task, target_repo):
    safe = re.sub(r"[^A-Za-z0-9._-]", "_", task)
    return os.path.join(git_common_dir(target_repo), "relay-attest", safe + ".json")


def trailer_text(record):
    # GH-1220: bind config_sha256 into the trailer when present so a tampered value is refused at
    # load() while legacy records without the field continue to match their legacy trailers.
    cfg = record.get("config_sha256")
    cfg_line = f"config-sha256: {cfg}\n" if cfg else ""
    return (f"\n{TRAILER_HEAD} — {record['attested_at']}\n"
            f"task: {record['task']}\n"
            f"reviewer: {record['reviewer']}\n"
            f"status: {record['status']}\n"
            f"reviewed-head: {record['reviewed_head']}\n"
            f"added-range: {record['added_start']}+{record['added_len']}\n"
            f"added-sha256: {record['added_sha256']}\n"
            f"{cfg_line}")


def write(record):
    """Atomic publish: temp file in the same dir + os.replace. Raises on failure; leaves nothing."""
    path = path_for(record["task"], record["target_repo"])
    os.makedirs(os.path.dirname(path), exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=".attest.", dir=os.path.dirname(path))
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(record, f, indent=2, sort_keys=True)
            f.write("\n")
        os.replace(tmp, path)
    except BaseException:
        try:
            os.remove(tmp)
        except OSError:
            pass
        raise
    return path


def load(task, *, expected_reviewer, relay_file, target_repo, path=None, any_reviewer=False):
    """Validated read. Returns (record, None) or (None, reason). Never trusts existence, never raises
    on a malformed record — a consumer parks or escalates on the reason instead of crashing."""
    try:
        return _load(task, expected_reviewer=expected_reviewer, relay_file=relay_file, target_repo=target_repo,
                     path=path, any_reviewer=any_reviewer)
    except Exception as e:  # noqa: BLE001 — any malformed record is a refusal, not a crash
        return None, f"attestation record malformed ({e.__class__.__name__}: {e})"


def _load(task, *, expected_reviewer, relay_file, target_repo, path=None, any_reviewer=False):
    try:
        path = path or path_for(task, target_repo)
    except RuntimeError as e:
        return None, str(e)
    try:
        with open(path, "r") as f:
            rec = json.load(f)
    except FileNotFoundError:
        return None, f"no attestation record for {task} at {path}"
    except (OSError, ValueError) as e:
        return None, f"attestation record unreadable/malformed: {e}"
    if not isinstance(rec, dict) or rec.get("schema") != SCHEMA:
        return None, "attestation record has the wrong schema"
    for k in ("task", "reviewer", "status", "reviewed_head", "added_start", "added_len",
              "added_sha256", "trailer_sha256", "relay_file", "target_repo", "isolated", "attested_at"):
        if k not in rec:
            return None, f"attestation record missing field {k}"
    for k in ("task", "reviewer", "status", "reviewed_head", "added_sha256", "trailer_sha256",
              "relay_file", "target_repo", "attested_at"):
        if not isinstance(rec[k], str) or not rec[k]:
            return None, f"attestation record field {k} is not a non-empty string"
    if not isinstance(rec["added_start"], int) or not isinstance(rec["added_len"], int) or isinstance(rec["added_start"], bool):
        return None, "attestation record added-range is not integral"
    # fields candidate_ok() consumes — declared shapes, checked here so a malformed record is a
    # refusal at load time rather than an exception at the merge boundary
    if not isinstance(rec["isolated"], bool):
        return None, "attestation record field isolated is not a boolean"
    for k in ("relay_file_rel", "artifact_sha256", "transcript_repo"):
        v = rec.get(k)
        if v is not None and (not isinstance(v, str) or not v):
            return None, f"attestation record field {k} is neither null nor a non-empty string"
    if "config_sha256" in rec:
        # GH-1220: optional config identity; when present it must be a non-empty string.
        if not isinstance(rec["config_sha256"], str) or not rec["config_sha256"]:
            return None, "attestation record field config_sha256 is not a non-empty string"
    if rec["task"] != task:
        return None, f"attestation record is for task {rec['task']}, not {task}"
    if relay_file is None:
        # Caller resolved the record through a harness-written receipt (marathon result@1
        # `attest_path`) and has no independent relay-file path; the record names the file, and
        # every content check below still runs against that file.
        relay_file = rec["relay_file"]
    if os.path.realpath(rec["relay_file"]) != os.path.realpath(relay_file):
        return None, f"attestation record is for relay file {rec['relay_file']}, not {relay_file}"
    if os.path.realpath(rec["target_repo"]) != os.path.realpath(target_repo):
        return None, f"attestation record is for repo {rec['target_repo']}, not {target_repo}"
    # GH-1220: any_reviewer validates a historical record without binding it to this run's reviewer,
    # so a reviewer swap reads as a config change (rebuild), never as an approval to reuse.
    if not any_reviewer and (not expected_reviewer or rec["reviewer"] != expected_reviewer):
        return None, f"attestation reviewer is {rec['reviewer']}, expected {expected_reviewer or '(none)'}"
    if rec["status"] not in TERMINAL:
        return None, f"attestation status {rec['status']} is not terminal"
    current = file_status(relay_file)
    if current != rec["status"]:
        return None, f"relay file STATUS is now {current or '(none)'}, attestation says {rec['status']}"
    try:
        canon = canonical(relay_file)
    except OSError as e:
        return None, f"relay file unreadable: {e}"
    start, length = int(rec["added_start"]), int(rec["added_len"])
    if start < 0 or length <= 0 or start + length > len(canon):
        return None, "attestation added-range is out of bounds for the current relay file"
    added = canon[start:start + length]
    if sha256(added) != rec["added_sha256"]:
        return None, "review text no longer matches the attested digest"
    trailer = trailer_text(rec).encode("utf-8")
    if sha256(trailer) != rec["trailer_sha256"]:
        return None, "attestation record does not match its own trailer"
    if canon[start + length:start + length + len(trailer)] != trailer:
        return None, "attestation trailer is not where the record says it is"
    return rec, None


def candidate_ok(record, candidate_sha, target_repo):
    """Is `candidate_sha` the reviewed revision plus transcript-only commits? -> (bool, reason).
    Never raises: a malformed record or a git failure is a refusal.
    """
    try:
        return _candidate_ok(record, candidate_sha, target_repo)
    except Exception as e:  # noqa: BLE001
        return False, f"candidate check failed ({e.__class__.__name__}: {e})"


def _candidate_ok(record, candidate_sha, target_repo):
    """

    Contract (GH-505 plan, round 2 Q9): reviewed_head must be an ancestor of the candidate AND the
    endpoint tree diff must be empty outside relay-system/, the relay file's own tracked path, and
    marathon's two named phase records beside it (ESCALATION.md, PHASE-INTERRUPTED.md).
    Any git error refuses. Non-isolated turns and seeded-artifact reviews are never merge-eligible:
    the reviewed input was not the pinned target tree.
    """
    if not record.get("isolated"):
        return False, "review ran without worktree isolation; its input was not a pinned revision"
    if record.get("artifact_sha256"):
        return False, "review was of a seeded artifact, not the target tree; transcript-only attestation"
    reviewed = record["reviewed_head"]
    if not candidate_sha:
        return False, "no candidate revision"
    anc = subprocess.run(["git", "-C", target_repo, "merge-base", "--is-ancestor", reviewed, candidate_sha],
                         capture_output=True, text=True)
    if anc.returncode == 1:
        return False, f"reviewed head {reviewed[:12]} is not an ancestor of candidate {candidate_sha[:12]}"
    if anc.returncode != 0:
        return False, f"git merge-base failed: {anc.stderr.strip()}"
    spec = ["--", f":(top,exclude){TRANSCRIPT_DIR}"]
    rel = record.get("relay_file_rel")
    if rel:
        spec.append(f":(top,literal,exclude){rel}")
        # marathon keeps exactly two other harness-owned records beside its RELAY.md — name them,
        # never the directory (a user-selected relay may sit beside source files).
        d = os.path.dirname(rel)
        for name in PHASE_RECORDS:
            spec.append(f":(top,literal,exclude){os.path.join(d, name) if d else name}")
    diff = subprocess.run(["git", "-C", target_repo, "diff", "--quiet", reviewed, candidate_sha] + spec,
                          capture_output=True, text=True)
    if diff.returncode == 1:
        return False, f"candidate {candidate_sha[:12]} changes non-transcript content after reviewed head {reviewed[:12]}"
    if diff.returncode != 0:
        return False, f"git diff failed: {diff.stderr.strip()}"
    return True, None


def record_phase_completion(record, *, phase, lane, candidate, target_repo):
    """Marathon's success writer: extend this approval with its validated completion.

    Kept under the existing protected attestation boundary, not a workspace receipt.
    Fresh relay approval replaces this record and therefore discards any older completion.
    """
    ok, why = candidate_ok(record, candidate, target_repo)
    if not ok:
        raise ValueError(f"cannot record phase completion: {why}")
    updated = dict(record)
    updated["phase_completion"] = {
        "phase": phase, "lane": lane, "candidate": candidate,
        "reviewed_head": record["reviewed_head"], "added_sha256": record["added_sha256"],
    }
    write(updated)


def phase_completion_candidate(record, *, phase, lane, head, target_repo):
    """Validate optional historical completion -> (candidate or None, refusal or None).

    Missing metadata is a legacy record: callers retain strict current-HEAD validation.
    Malformed or mismatched metadata refuses; it never falls back to an older approval.
    This is historical satisfaction only, never current-head merge authorization.
    """
    if "phase_completion" not in record:
        return None, None
    try:
        completion = record["phase_completion"]
        if not isinstance(completion, dict):
            return None, "phase completion is not an object"
        expected = {"phase": phase, "lane": lane, "reviewed_head": record["reviewed_head"],
                    "added_sha256": record["added_sha256"]}
        if any(completion.get(k) != v for k, v in expected.items()):
            return None, "phase completion does not match this phase, lane or approval"
        candidate = completion.get("candidate")
        if not isinstance(candidate, str) or not re.fullmatch(r"[0-9a-f]{40,64}", candidate):
            return None, "phase completion has no full candidate revision"
        ok, why = candidate_ok(record, candidate, target_repo)
        if not ok:
            return None, f"phase completion candidate invalid: {why}"
        if not head:
            return None, "no current revision for phase completion"
        ancestor = subprocess.run(
            ["git", "-C", target_repo, "merge-base", "--is-ancestor", candidate, head],
            capture_output=True, text=True)
        if ancestor.returncode != 0:
            return None, "phase completion is not an ancestor of current HEAD or ancestry check failed"
        return candidate, None
    except Exception as exc:
        return None, f"phase completion check failed ({exc.__class__.__name__}: {exc})"


def rev_parse(repo, ref="HEAD"):
    out = subprocess.run(["git", "-C", repo, "rev-parse", ref], capture_output=True, text=True)
    return out.stdout.strip() if out.returncode == 0 else ""


def repo_relative(path, repo):
    """Repo-relative path when `path` is a TRACKED file inside `repo`; else None."""
    try:
        rel = os.path.relpath(os.path.realpath(path), os.path.realpath(repo))
    except ValueError:
        return None
    if rel.startswith(".."):
        return None
    out = subprocess.run(["git", "-C", repo, "ls-files", "--error-unmatch", "--", rel],
                         capture_output=True, text=True)
    return rel if out.returncode == 0 else None
