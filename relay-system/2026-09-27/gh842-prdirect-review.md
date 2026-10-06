# RELAY · PR #direct review — GH-842 into development (#854 direct path)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-27.
-->

NEXT: Producer
STATUS: Escalated
ROUND: 1 / 1

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(pr-direct-review-gh-842-into-development-854-direct-path): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the diff from origin/development to HEAD on this branch (PR #direct, GH-842). Key files: `utils/py/wave_reconcile.py`, `TESTS-RESULTS/2026-09-27+GH-842/SUMMARY.md`. Read in place; do NOT edit.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-27
- Definition of Done: see *Review packet*. One round (operator: minimum ceremony). PASS means safe to merge into development.

## Review packet

**The question:** is PR #direct (GH-842) correct, and safe to merge into `development`? Read issue GH-842's intent from `TESTS-RESULTS/*+GH-842/SUMMARY.md`. You cannot run git, so the PR's exact scope and code patch are embedded below; they were taken at the PR head before this thread was added.

**Scope** (`git diff --name-status origin/development...HEAD`):
```
A	TESTS-RESULTS/2026-09-27+GH-842/SUMMARY.md
A	TESTS-RESULTS/2026-09-27+GH-842/base-control.log
A	TESTS-RESULTS/2026-09-27+GH-842/focused-gh421-auto-wave-reconcile.log
A	TESTS-RESULTS/2026-09-27+GH-842/focused-gh425-gate-provenance-pr.log
A	TESTS-RESULTS/2026-09-27+GH-842/focused-gh740-hosted-lane-publish.log
A	TESTS-RESULTS/2026-09-27+GH-842/provenance.jsonl
A	TESTS-RESULTS/2026-09-27+GH-842/witness-express.log
A	TESTS-RESULTS/2026-09-27+GH-842/witness-head.log
A	TESTS-RESULTS/2026-09-27+GH-842/witness.py.txt
M	utils/py/wave_reconcile.py
```

**Code patch** (everything except `TESTS-RESULTS/` and `relay-system/`):
```diff
diff --git a/utils/py/wave_reconcile.py b/utils/py/wave_reconcile.py
index 300488c9..b0d525ea 100755
--- a/utils/py/wave_reconcile.py
+++ b/utils/py/wave_reconcile.py
@@ -1322,6 +1322,65 @@ def unreconciled_prs(repo_root, repo_slug, metadata):
     return pending
 
 
+# GH-842: direct pushes to development after this commit are hosted-qualified by catch-up. Forward
+# only (#854: "a direct push then gets a qualifying hosted run"); the pre-cutover backlog is not
+# replayed. Bot commits and express landings (already gated by `--commit --gate`) are excluded.
+DIRECT_COMMIT_CUTOVER = "41db436717513327626f12da450e907a628ebc85"
+BOT_AUTHOR_EMAIL = "41898282+github-actions[bot]@users.noreply.github.com"
+EXPRESS_RECEIPT = r"TESTS-RESULTS/[0-9]{4}-[0-9]{2}-[0-9]{2}\+GH-[0-9]+-express/provenance\.jsonl"
+
+
+def express_landings(repo_root):
+    """Commits with a committed, passing express receipt (utils/py/express.py write_receipt)."""
+    found = set()
+    paths = subprocess.check_output(["git", "ls-tree", "-r", "--name-only", "HEAD", "--", "TESTS-RESULTS/"],
+                                    cwd=repo_root, text=True).splitlines()
+    for path in paths:
+        if not re.fullmatch(EXPRESS_RECEIPT, path):
+            continue
+        raw = subprocess.check_output(["git", "show", f"HEAD:{path}"], cwd=repo_root, text=True)
+        for line in raw.splitlines():
+            try:
+                entry = json.loads(line)
+            except ValueError:
+                continue
+            if (isinstance(entry, dict) and entry.get("case") == "express-landing" and entry.get("rc") == 0
+                    and isinstance(entry.get("commit"), str)):
+                found.add(entry["commit"])
+    return found
+
+
+def unreconciled_commits(repo_root, metadata):
+    """GH-842: first-parent direct commits since the cutover with no PR, bot or express landing.
+
+    PR landings are the merge commits unreconciled_prs already recorded in `metadata`; each pending
+    commit is added to `metadata` as ("commit", sha), where main() picks it up as a landing.
+    """
+    merged_shas = {(meta.get("mergeCommit") or {}).get("oid") for (kind, _), meta in metadata.items() if kind == "pr"}
+    if subprocess.run(["git", "cat-file", "-e", f"{DIRECT_COMMIT_CUTOVER}^{{commit}}"],
+                      cwd=repo_root, capture_output=True, check=False).returncode:
+        log("Direct-commit recovery inactive: cutover not in this history")
+        return []
+    listed = subprocess.run(["git", "log", "--first-parent", "--format=%H %ae",
+                             f"{DIRECT_COMMIT_CUTOVER}..HEAD"],
+                            cwd=repo_root, capture_output=True, text=True, check=False)
+    if listed.returncode:
+        die(f"Direct-commit recovery failed: {listed.stderr}", code=6)
+    express = express_landings(repo_root)
+    previous = committed_qualifications(repo_root)
+    pending = []
+    for line in reversed(listed.stdout.splitlines()):
+        sha, _, author = line.partition(" ")
+        if sha in merged_shas or sha in express or author == BOT_AUTHOR_EMAIL:
+            continue
+        meta = fetch_commit_metadata(repo_root, sha)
+        if not any(qualification_receipt_matches(repo_root, entry, meta) for entry in previous):
+            metadata[("commit", sha)] = meta
+            pending.append(sha)
+    log(f"Receipt recovery found {len(pending)} pending direct commit(s) since {DIRECT_COMMIT_CUTOVER[:12]}")
+    return pending
+
+
 def catch_up_prs(repo_root, repo_slug, offline_manifest=None, qualification_metadata=None):
     """Derive drift from committed state; no PR watermark or auxiliary ledger.
 
@@ -1343,6 +1402,8 @@ def catch_up_prs(repo_root, repo_slug, offline_manifest=None, qualification_meta
             if match:
                 issues.add(int(match[1]))
     found = set(unreconciled_prs(repo_root, repo_slug, qualification_metadata)) if qualification_metadata is not None else set()
+    if qualification_metadata is not None:
+        unreconciled_commits(repo_root, qualification_metadata)
     for issue in sorted(issues):
         if fetch_issue_state(repo_root, issue, offline_manifest) != "CLOSED":
             continue
@@ -2113,6 +2174,8 @@ def main():
             if args.catch_up:
                 landing_items.extend(("pr", str(n)) for n in catch_up_prs(
                     repo_root, repo_slug, offline_manifest, qualification_metadata=metadata if args.qualify else None))
+                # GH-842: catch-up records pending direct commits in `metadata` alongside the PRs.
+                landing_items.extend(key for key in metadata if key[0] == "commit")
             landing_items = list(dict.fromkeys((kind, str(value)) for kind, value in landing_items))
             if args.qualify and landing_items:
                 for kind, value in landing_items:
```

**Definition of Done (PASS when all hold):**
- (a) **The fix addresses the stated root cause** at the cited lines. It is minimal: no unrelated edits, and no weakened or deleted assertion that hides a failure.
- (b) **The evidence is real.** `base-control.log` shows the base has no commit discovery; `witness-head.log` and `witness-express.log` classify real history (PR merge / bot / express / QUALIFY) and match the code; the focused suite logs exist and match `provenance.jsonl`.
- (c) **Behaviour is safe on the hosted lane.** Discovered commits flow through the existing `--commit` qualifier, tier selection and receipt matcher without breaking the `--only-receipted` retry, the newest-owner lifecycle rule or idempotency (a receipted commit is not re-qualified). Nothing already qualified is dropped.
- (d) **Scope.** Only `utils/py/wave_reconcile.py` plus evidence; no new test file or registry entry (AGENTS.md *No new tests*); no ledger/PROJECT change.

**Operating envelope.** A single-operator developer tool. Grade against these checks and commensurate complexity. Do not ask for new tests, new infrastructure or multi-tenant threat models.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: The discovery path is minimal and the supplied focused logs agree with their receipts, but DoD (c)'s newest-owner preservation is not met for an already-qualified direct closer. One source-level finding; runtime reproduction remains outstanding under this turn's constraints.
swept file: yes

- [Should] **Retain already-qualified direct commits as lifecycle-owner metadata, separately from pending qualification work.** At `utils/py/wave_reconcile.py:1377`, both metadata insertion and pending insertion are inside the no-matching-receipt branch. In contrast, PR metadata is retained before that branch at `:1316`. Consequently the owner loop at `:2209` cannot see a receipted direct closer on a later catch-up, and an older PR can own the lifecycle writes at `:2256`. This also leaves no direct-commit recovery path after receipts were published but the bounded recompute failed: `catch_up_prs` recovers lifecycle drift only through PR candidates (`:1422`).
  Observed input: the seeded source branch at `utils/py/wave_reconcile.py:1377–1379`: when `qualification_receipt_matches(...)` is true for a direct commit, its metadata is omitted. Concrete reproduction input derived from the existing direct-commit case (`test/gh421-auto-wave-reconcile.sh:145`): SHA `bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb`, message `Closes #421`, plus a matching committed qualification receipt; pair it with an older PR closing #421 and leave lifecycle drift to reconcile. This is a proposed clone reproduction, not a claim that this historical failure was observed live.
  Affected scope: eligible post-cutover direct closers with valid qualification receipts, absent from explicit `--commit` targets, when catch-up must choose the newest closer or recover an interrupted closeout.
  Falsifier: in a disposable full clone, the newer receipted direct closer must remain the lifecycle owner over an older PR; catch-up must finish its outstanding lifecycle work without another qualification run, and a completed repeat must write nothing. Also retain the existing explicit `--commit` publish-retry case. A passing run on the current implementation would disprove the finding.
  Fix: separate the complete direct-commit metadata set from pending work, as PR recovery already does; consume only pending commits for qualification while recovering outstanding direct lifecycle work. Do not merely move `metadata[...] = meta` outside the condition: `:2178` currently turns every commit metadata key into work. No new suite or registry entry is requested.
  Root cause: qualification eligibility also controls lifecycle visibility; Fix site: direct discovery and its catch-up handoff; Why not downstream: the owner selector cannot recover metadata that discovery discarded.
  [Unverified — needs clone run] The end-to-end reproduction above was not executed. Static inspection establishes the conditional metadata loss. The immediate successful publisher retry is **not** claimed broken: `hosted_lane_publish.py:221` names its freshly receipted commits explicitly, and `wave_reconcile.py:2183` fetches those targets again.

- [Pass] **Basic discovery and qualification reuse match the intended scope.** `wave_reconcile.py:1364` uses the forward-only first-parent range; `:1374` excludes PR merges, express receipts and the configured bot; `:2203` calls the existing qualifier, whose `select_qualification_gate` uses the landing diff (`:602`). The embedded patch changes no test registry or assertion. No additional pre-existing defects were identified in the whole-file sweep.

- [Pass] **Recorded focused results are internally consistent.** All three nonempty `focused-*.log` files end in `OK` (36 / 23 / 6 cases), matching the three `rc: 0` rows in `TESTS-RESULTS/2026-09-27+GH-842/provenance.jsonl`. `base-control.log` records zero discovery matches; `witness-head.log` ends `pending: 5`; `witness-express.log` classifies `1370765938 express` and its two closeout commits as `QUALIFY`. These are supplied execution records, not reviewer reruns. They do not measure the receipted-direct-owner case above.

Read-only probe command (exit 0; no application function or fixture executed):
```python
# Invoked as: export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 - <<'PY'
import ast, json
from pathlib import Path
p=Path('utils/py/wave_reconcile.py')
t=ast.parse(p.read_text())
for name in ('unreconciled_prs','unreconciled_commits'):
    f=next(n for n in t.body if isinstance(n,ast.FunctionDef) and n.name==name)
    for n in ast.walk(f):
        if isinstance(n,ast.If) and 'qualification_receipt_matches' in ast.unparse(n.test):
            print(f'{name}:{n.lineno}: '+ast.unparse(n))
d=Path('TESTS-RESULTS/2026-09-27+GH-842')
rows=[json.loads(s) for s in (d/'provenance.jsonl').read_text().splitlines()]
assert rows
for r in rows:
    p=d/('focused-'+Path(r['command'].split()[-1]).stem+'.log')
    body=p.read_text()
    assert body.strip()
    print(p.name, 'receipt_rc='+str(r['rc']), 'ends_OK='+str(body.rstrip().endswith('OK')))
# PY
```
Decisive output:
```text
unreconciled_prs:1317: if not any((qualification_receipt_matches(repo_root, entry, meta) for entry in previous)):
    pending.append(str(pr['number']))
unreconciled_commits:1377: if not any((qualification_receipt_matches(repo_root, entry, meta) for entry in previous)):
    metadata['commit', sha] = meta
    pending.append(sha)
focused-gh421-auto-wave-reconcile.log receipt_rc=0 ends_OK=True
focused-gh425-gate-provenance-pr.log receipt_rc=0 ends_OK=True
focused-gh740-hosted-lane-publish.log receipt_rc=0 ends_OK=True
```

No git commands, suites, pytest or executable fixtures were run. Only this relay file was edited. The one-round cap is exhausted, so STATUS is Escalated. Handing off to Producer (claude-a) — disposition the finding and obtain the disposable-clone evidence before merge; go to the Producer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
