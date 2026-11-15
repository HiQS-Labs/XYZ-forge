# RELAY · GH-1475 Phase 1 final QA (Codex)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 3

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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1475-final-codex): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, `skills/2-daily/merge-cleanup/scripts/batch_record.py`, `utils/py/wave_reconcile.py`, `skills/2-daily/merge-cleanup/SKILL.md`, `CHANGELOG.md` (review the diff from base 5967bde25: git diff 5967bde25..HEAD), the plan `PROJECT/2-WORKING/GH-1475-MERGE-CLEANUP-REMEDIATION.md`, and the evidence `TESTS-RESULTS/2026-11-14+GH-1475/README.md`, `TESTS-RESULTS/2026-11-14+GH-1475/manual-check-run.log`, `TESTS-RESULTS/2026-11-14+GH-1475/existing-suite-summary.txt`, `TESTS-RESULTS/2026-11-14+GH-1475/smoke.log`, `TESTS-RESULTS/2026-11-14+GH-1475/provenance.jsonl` (drivers alongside, named manual-p11.sh.txt … manual-p16.py.txt).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-14
- Definition of Done: each of P1.1–P1.6 in the plan is implemented as approved (plan QA: Codex r2 in
  `relay-system/2026-11-14/gh1475-plan-codex.md`), on the existing owners (no duplicate subsystem or
  writer), with no new test file, suite, `validate.sh` entry or gate machinery (GH-831), and each claim
  is substantiated by the recorded evidence including its red control.

## Review packet (Producer: claude-a, 2026-11-14)

**Operational envelope.** Local operator CLI on one laptop; commensurate complexity; do not ask for
distributed locks, daemons or new tests (XYZ-forge forbids new tests; a new test file or registry entry
in the diff is itself a finding). Review-only: write only this relay file. You may run narrow read-only
probes (`git diff`, `git show`, `python3 -c` imports) with output under `.relay-scratch/`; do not run
`validate.sh` or `test/*.sh` here (they ran in a disposable clone; see the evidence).

Known and recorded: the full gate (`validate.sh`, routed by `utils/ci-route.sh`) runs once on the final
approved commit, by the pre-push hook; it is not in the evidence yet. Smoke found every open PR is
CONFLICTING, so a real-CLI clean dry run was not possible; clean-path removal is witnessed by the
manual P1.3 driver on the real `_land_prs_loop`.

### Questions
1. Is each issue item P1.1–P1.6 satisfied by the diff as planned? Cite file:line.
2. Do the code paths match the plan (e.g. P1.3 only removes after `clean` and with no keep flag and no
   deferred sync; P1.4 writes only after a successful non-dry-run reconcile and push; P1.6 adds no `gh`
   call and no refusal)? Any behaviour change beyond the plan?
3. Did a duplicate subsystem or writer slip in? (`_sync_batch` is an extraction; `batch_record.row_done`
   is shared by `continuable` and `record_sweep`.)
4. Do the checks substantiate the claims — for each item, what stops an unchanged tree from being
   reported delivered, and where is the observed rejection in `manual-check-run.log`?
5. P1.3 deletion safety: is `_remove_own_scratch` containment sound (GH-567, AGENTS.md danger list)?
6. Is the persisted rating (`rated 60/65/50/75`, plan "Rating") consistent with the evidence?
7. Any pre-existing defect in the touched functions that this change makes worse?

Grade each finding, then VERDICT.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: no

Reviewed the plan, prior Codex plan dispositions, retained receipts and manual drivers, and the implementation seams for P1.1–P1.6, including the entire landing loop. This is not a completed whole-file sweep of both large orchestrators; no whole-file or base-diff approval is claimed. The current user prohibits all git commands, including the packet's suggested diff. Graph discovery returned `MCP tool call requires approval, but approval policy is never`; direct reads were the fallback. No git command, suite, executable fixture, or artifact mutation was run. No additional pre-existing defect was established in the inspected functions; the remaining whole-file sweep is outstanding before approval.

- [Should] **P1.3's keep-flag safety gate lacks a discriminating negative control.** `manual-p13.py.txt:11,19-20` supplies an empty queue and an initial PR-read error. The latter returns before setting `keep_workdir`; it is not the planned forced-keep case. The smoke's B1 stop (`smoke.log:19`) sets keep but returns before `clean = True` (`merge_cleanup.py:2130`). Thus all retained scenarios would still pass if `not keep_workdir` were deleted from `:2136`. Add a recorded manual scenario in the disposable full clone that reaches the normal clean return with keep true (e.g. draft refusal after a B1 repair), observes retained contents, and witnesses the same scenario fail with only the keep guard removed. Retain the command, exit status, decisive output and provenance using the existing manual-evidence approach; no new suite or gate. Also record rejection inputs for the new containment predicate (symlink, outside temp root, wrong prefix) with a non-destructive observer for the removal call, since the current empty-directory success does not exercise those refusals.
  Observed input: manual P1.3 `run("clean", [], False)` and `run("deferred", [{"number": 9001, ...}], True)`; smoke B1 early return. These cover `(clean, keep) = (True, False), (False, False), (False, True)`, never `(True, True)`.
  Affected scope: evidence for the new scratch-deletion decision gate, not a request to change the production retention policy.
  Falsifier: an existing retained receipt reaches `(True, True)` and fails when only `not keep_workdir` is removed; cite it instead of adding another check.
  Probe: `PYTHONDONTWRITEBYTECODE=1 python3 -` parsed `_land_prs_loop` with `ast.parse`, printed its cleanup predicate, and compared `clean and not keep` with `clean` for the four pairs above; exit 0. Decisive output: `manual clean: original_delete=True without_keep_guard_delete=True`; `manual error: original_delete=False without_keep_guard_delete=False`; `smoke B1 early return: original_delete=False without_keep_guard_delete=False`; `missing retained-clean case: original_delete=False without_keep_guard_delete=True`. This is predicate analysis, not an executed clone scenario. Full execution remains **[Unverified — needs clone run]**.

- [Pass] **P1.1/P1.2 match the approved local changes.** `wave_reconcile.py:302-320` bounds ref-lock retries to three fetch/remote-ref-merge attempts and dies on other errors. `merge_cleanup.py:128-132` extends the existing transient classifier; `:2203-2206` enables line buffering. `manual-check-run.log` reports two retries then matching HEAD, base `ReconcileError`, non-lock code 2, and a live sleeping process with 25 versus 0 buffered lines. These are retained observations, not reruns here.
- [Pass] **P1.3's inspected production predicate matches the plan.** `merge_cleanup.py:218-232` checks prefix, non-symlink directory and resolved parent before removal; `:2130-2139` gates it on clean, no keep flag and no deferred sync, with retention otherwise. No production defect is asserted by the evidence finding above.
- [Pass] **P1.4 reuses the existing owners.** `merge_cleanup.py:1645-1676` extracts the existing finalize/update tail into `_sync_batch`; `:2446-2454` updates the found batch only after non-dry-run reconcile/publication success. `batch_record.py:250-258` shares terminal-row semantics with `record_sweep` (`merge_cleanup.py:2872-2887`). The retained P1.4 output reports merged/ok plus issue edit on success, unchanged rows for dry run and reconcile/push failures, and distinct reconcile/resume hints. No duplicate writer was found in these paths.
- [Pass] **P1.5/P1.6 have the planned bounded surface.** SKILL.md's “Exit codes for wrapper scripts” gives all six exits and its “Trigger & threshold” corrects the single-PR claim. `merge_cleanup.py:1112-1145` uses timeout-bounded local advisory probes, and `:2524-2525` prints warnings at the dry-run pin seam. The landing loop's existing required-check answer supplies the once-only F6 warning. `manual-check-run.log` records one versus zero F6 warnings with zero gh calls, four forced environment warnings and a silent clean environment. The inspected additions add no new gh query or refusal.
- [Pass] **Receipt integrity is intact.** Read-only probe `python3 -` loaded each provenance row and compared `hashlib.sha256((evidence_dir / name).read_bytes()).hexdigest()` with its recorded digest; exit 0. All eight named logs/drivers were nonempty and printed `hash matches: True` (manual log 3525 bytes; suite summary 498; smoke 2425). `existing-suite-summary.txt` records 227 tests OK and all listed suites rc=0. The final full gate is explicitly pending in the review packet; these receipts do not qualify the final commit.
- [Pass] **Rating rationale remains appropriately limited.** The plan's “Rating” says `rated 60/65/50/75`, ties severity to recoverable hours of disruption, and labels recurrence/trend unknown. That is consistent with the one-batch incident account. Persisted database rating was not independently queried here.

**VERDICT: FAIL**
**Basis:** The implementation seams inspected follow the approved plan, but a newly introduced deletion safety gate has no discriminating retained negative control. Supply that evidence before approval; the required whole-file sweep and final harness gate also remain outstanding. No source edits requested on speculation.

Handing off to Producer (claude-a) — address the P1.3 evidence finding in a disposable full clone, then return for the next reviewer turn.

### Producer · Round 1 · claude-a

- **[Should] P1.3 keep-flag gate lacks a discriminating negative control.** **Implemented** (evidence
  only; no production change). `TESTS-RESULTS/2026-11-14+GH-1475/manual-p13b.py.txt` drives the real
  `_land_prs_loop` in execute mode to the `(clean=True, keep=True)` case: B1 resolves, the
  repaired-head push meets `DRAFT_REFUSAL` (`merge_cleanup.py` "SKIPPED (draft before repaired-head
  push…)" sets `keep_workdir` and `continue`s), the run returns 0. Result (`manual-check-run.log`, last
  section, run twice with the same outcome): tested code → `rc=0 workdir_left=1 B1-RESULT kept=True`;
  mutant with only `not keep_workdir` removed → `rc=0 workdir_left=0 B1-RESULT kept=False`.
  Containment refusals with `rmtree` replaced by an observer: symlink, a `merge-cleanup-*` dir
  outside the temp root, and a wrong prefix each return False with `rmtree_called=False`; a valid
  dir returns True. Provenance row added. Note: like the other manual drivers, it imports the
  committed scripts read-only and mutates only a scratch primary and a scratch `TMPDIR`, not a
  valued checkout. The driver deletes the scratch primary's PR #1 attempt record first so the
  repair budget is fresh each run (a second run otherwise parks with rc 3).
- **swept file: no / git blocked.** To make the whole-diff review possible without git, the complete
  code diff `5967bde25..HEAD` for the three Python files is embedded below.

```diff
diff --git a/skills/2-daily/merge-cleanup/scripts/batch_record.py b/skills/2-daily/merge-cleanup/scripts/batch_record.py
index 1295d08e2..c91b0be90 100644
--- a/skills/2-daily/merge-cleanup/scripts/batch_record.py
+++ b/skills/2-daily/merge-cleanup/scripts/batch_record.py
@@ -247,14 +247,14 @@ def qa_pending(rec: Dict[str, Any]) -> bool:
     return bool(got) and got != set((rec.get("verdict") or {}).get("covers") or [])
 
 
+def row_done(o: Dict[str, Any]) -> bool:
+    """A planned PR is finished when it closed, or merged and reconciled."""
+    status = o.get("status") or ""
+    return status == "closed" or status.startswith("closed:") or (status == "merged" and o.get("reconcile") == "ok")
+
+
 def continuable(rec: Dict[str, Any]) -> bool:
-    for row in rec["planned"]:
-        o = rec["outcomes"].get(str(row["pr"]), {})
-        status = o.get("status") or ""
-        if status == "closed" or status.startswith("closed:") or (status == "merged" and o.get("reconcile") == "ok"):
-            continue
-        return True
-    return False
+    return any(not row_done(rec["outcomes"].get(str(row["pr"]), {})) for row in rec["planned"])
 
 
 def find_unfinished(primary: Path, origin: str, integration: str, prs: List[int],
diff --git a/skills/2-daily/merge-cleanup/scripts/merge_cleanup.py b/skills/2-daily/merge-cleanup/scripts/merge_cleanup.py
index 41883373e..18cacba97 100644
--- a/skills/2-daily/merge-cleanup/scripts/merge_cleanup.py
+++ b/skills/2-daily/merge-cleanup/scripts/merge_cleanup.py
@@ -124,7 +124,8 @@ def _off_pin(info: Dict[str, Any], match_head: Optional[str]) -> bool:
 
 TRANSIENT_RE = re.compile(
     r"could not resolve host|connection refused|connection timed out|timed out|TLS|SSL|rate limit"
-    r"|operation too slow|connection reset",
+    r"|operation too slow|connection reset"
+    r"|cannot lock ref|unable to create .*\.lock",  # GH-1475 (F5): a concurrent fetch's ref lock
     re.I,
 )
 
@@ -214,6 +215,23 @@ def run_command_in_session(cmd: str, cwd: Path, timeout: Optional[int] = None) -
         return p.returncode, stdout, stderr
 
 
+def _remove_own_scratch(path: Path, prefix: str) -> bool:
+    """GH-1475 (F1): delete a scratch directory this run created with mkdtemp. Proven first
+    (GH-567): a real, non-symlink directory directly under the resolved temp root, named with
+    `prefix`. Anything else, or any error, keeps it and returns False."""
+    try:
+        root = Path(tempfile.gettempdir()).resolve()
+        if (not path.name.startswith(prefix) or path.is_symlink() or not path.is_dir()
+                or path.resolve().parent != root):
+            log_warn(f"Not removing {path}: not a {prefix}* directory under {root}")
+            return False
+        shutil.rmtree(path)
+        return True
+    except OSError as exc:
+        log_warn(f"Could not remove {path}: {exc}")
+        return False
+
+
 def run_isolated_check(primary_repo: Path, command: str, timeout: int) -> Tuple[int, str, str]:
     """Run a bounded check in a retained independent full clone, never in primary."""
     raw = tempfile.mkdtemp(prefix="merge-check-")
@@ -1088,6 +1106,45 @@ def jog_issues_for(pr: Dict[str, Any]) -> Set[int]:
     return issues
 
 
+PREFLIGHT_MIN_FREE_GB = 20
+
+
+def _probe_text(cmd: List[str]) -> str:
+    """Advisory probe output: text from a zero exit, else "" (missing tool, error or timeout)."""
+    try:
+        res = subprocess.run(cmd, capture_output=True, text=True, timeout=5, check=False)
+    except (OSError, subprocess.SubprocessError, ValueError):
+        return ""
+    return res.stdout if res.returncode == 0 and isinstance(res.stdout, str) else ""
+
+
+def preflight_warnings() -> List[str]:
+    """GH-1475 (F1, F2, F10): read-only hazards for an unattended batch. Warnings only; a probe
+    that cannot answer stays silent."""
+    out = []
+    try:
+        free_gb = shutil.disk_usage(tempfile.gettempdir()).free / 1e9
+        if free_gb < PREFLIGHT_MIN_FREE_GB:
+            out.append(f"{free_gb:.1f} GB free under {tempfile.gettempdir()} (below {PREFLIGHT_MIN_FREE_GB} GB); "
+                       "landing and check clones may fill the disk")
+    except OSError:
+        pass
+    if sys.platform == "darwin" and "'Battery Power'" in _probe_text(["pmset", "-g", "batt"]):
+        out.append("running on battery; use wall power and caffeinate for an unattended batch")
+    tmp = os.environ.get("TMPDIR")
+    if tmp:
+        real = os.path.realpath(tmp)
+        if real.rstrip("/") != os.path.realpath("/tmp") and not real.startswith(
+                (os.path.realpath("/var/folders") + "/", "/var/folders/")):
+            out.append(f"TMPDIR is {tmp}; a harness may delete a per-turn temp dir mid-run. Prefer TMPDIR=/tmp")
+    others = [pid for pid in _probe_text(["pgrep", "-f", r"merge_cleanup\.py.*--execute"]).split()
+              if pid.isdigit() and int(pid) != os.getpid()]
+    if others:
+        out.append(f"another merge_cleanup.py --execute is running (pid {', '.join(others)}); "
+                   "run one landing batch per machine")
+    return out
+
+
 def jog_primary_precondition(primary_repo: Path, listed: List[Dict[str, Any]]) -> Optional[str]:
     """GH-1470: read-only dry-run check of the Jog primary pin that the post-merge Jog step needs.
     Returns a warning when a listed PR maps to an open Jog row and the primary is not pinned (or
@@ -1602,6 +1659,11 @@ def _record_batch_outcomes(batch, ordered_prs, track, rc, primary_repo) -> None:
             batch_record.set_outcome(batch, n, status=track["skips"][n])
         elif n == track["current"] and rc == 2:
             batch_record.set_outcome(batch, n, status=f"stopped: {stopped}")
+    _sync_batch(batch, primary_repo)
+
+
+def _sync_batch(batch, primary_repo) -> None:
+    """Refresh the batch's sweep inputs and its issue after outcomes changed."""
     origin = origin_url(primary_repo) or ""
     try:  # GH-1159: a policy that broke mid-run still gets its batch issue, minus any command
         qualification = resolve_merge_policy(primary_repo)["qualification"]
@@ -1641,6 +1703,8 @@ def _land_prs_loop(ordered_prs: List[Dict[str, Any]], primary_repo: Path, args,
     failed: Dict[int, str] = {}
     deferred_sync_pending = False
     deferred_sync_prs: Set[int] = set()
+    clean = False  # GH-1475 (F1): set only on the single clean return below
+    no_checks_warned = False
     if track is not None:
         track["failed"] = failed
     pending = {pr["number"] for pr in ordered_prs}
@@ -1891,6 +1955,10 @@ def _land_prs_loop(ordered_prs: List[Dict[str, Any]], primary_repo: Path, args,
             # pending or unreadable defers (exit 3; re-run once CI settles), failing is not merged;
             # neither stops the queue.
             checks, detail = required_checks_state(p_num, primary_repo)
+            if dry_run and detail == "no required checks" and not no_checks_warned:
+                no_checks_warned = True  # GH-1475 (F6): once per run
+                log_warn("PRE-FLIGHT: no required status checks are reported for this repository's PRs; "
+                         "the script will not wait for CI")
             if checks == "pending" and not dry_run:
                 wait = _seconds_from_env(CHECKS_WAIT_ENV, 1800.0)
                 poll = max(_seconds_from_env(CHECKS_POLL_ENV, 30.0), 1.0)
@@ -2059,12 +2127,16 @@ def _land_prs_loop(ordered_prs: List[Dict[str, Any]], primary_repo: Path, args,
                     f"{other} handed off or parked): "
                     + ", ".join(f"#{n} ({w})" for n, w in failed.items()))
             return 3
+        clean = True
         return 0
     finally:
         if deferred_sync_pending:
             log_err("Deferred issue/doc sync remains unfinished; affected landings are not reconciled. "
                     "Recover with the existing --reconcile-pr path before continuing.")
-        log(f"Landing clones retained for inspection under {workdir}")
+        if clean and not keep_workdir and not deferred_sync_pending and _remove_own_scratch(workdir, "merge-cleanup-"):
+            log(f"Landing clones removed after a clean run ({workdir})")
+        else:
+            log(f"Landing clones retained for inspection under {workdir}")
 
 
 def prepare_primary_landing(primary_repo: Path, args) -> Dict[str, Any]:
@@ -2128,6 +2200,10 @@ def retire_published_checkouts(primary: Path, paths: List[str], number: int,
 
 
 def main():
+    # GH-1475 (F12): a redirected log shows progress live instead of after a buffer fills.
+    for stream in (sys.stdout, sys.stderr):
+        if hasattr(stream, "reconfigure"):
+            stream.reconfigure(line_buffering=True)
     # GH-852: every child git (including the pre-push hook's and releases_app's) aborts an HTTP
     # transfer stalled below 1000 B/s for 120 s instead of waiting on a dead socket after a
     # wake. An operator's own values win.
@@ -2367,6 +2443,15 @@ def main():
         if not dry_run and not commit_and_push_phase5_writes(
                 args.reconcile_pr, primary_repo, args.integration_branch):
             return 2
+        if not dry_run:
+            # GH-1475 (F8): a recovered PR counts as landed and reconciled in its unfinished batch.
+            batch = batch_record.find_unfinished(primary_repo, origin_url(primary_repo) or "",
+                                                 args.integration_branch, [args.reconcile_pr])
+            if batch is not None:
+                batch_record.set_outcome(batch, args.reconcile_pr, status="merged",
+                                         merge_oid=merge_oid, reconcile="ok")
+                _sync_batch(batch, primary_repo)
+                log(f"PR #{args.reconcile_pr}: recorded reconcile ok in batch {batch.get('issue_url') or batch['path']}")
         return 0
 
     # Phase 1..3: Scan & Audit checkouts
@@ -2436,6 +2521,8 @@ def main():
         jog_warning = jog_primary_precondition(primary_repo, [p for p in prs if int(p.get("number", 0)) in args.prs])
         if jog_warning:
             log_warn(jog_warning)
+        for warning in preflight_warnings():
+            log_warn(f"PRE-FLIGHT: {warning}")
     if prs and not args.prs:
         log("Preview of every open PR: a merging --execute lands only the PRs named with --prs (GH-1226).")
     # GH-1226: sequence every open PR (dependency edges need them all), then keep only the allowlist.
@@ -2782,7 +2869,19 @@ def record_sweep(primary_repo: Path, integration: str, verdict_file: Path) -> in
     log(msg + (f" ({batch['issue_url']})" if batch.get("issue_url") else ""))
     if batch.get("issue_error"):
         log_warn(f"merge-batch issue: {batch['issue_error']}")
-    if batch_record.continuable(batch):
+    # GH-1475 (F8): name the right recovery per remaining PR; a merged PR is reconciled, not re-run.
+    unreconciled, open_rows = [], 0
+    for row in batch["planned"]:
+        o = batch["outcomes"].get(str(row["pr"]), {})
+        if batch_record.row_done(o):
+            continue
+        if o.get("status") == "merged":
+            unreconciled.append(row["pr"])
+        else:
+            open_rows += 1
+    for n in unreconciled:
+        log(f"PR #{n} landed but is not reconciled: recover with --reconcile-pr {n} --execute.")
+    if open_rows:
         log("Planned PRs remain: continue with --resume --execute.")
     return 0
 
diff --git a/utils/py/wave_reconcile.py b/utils/py/wave_reconcile.py
index fb6586d15..513eb5697 100755
--- a/utils/py/wave_reconcile.py
+++ b/utils/py/wave_reconcile.py
@@ -299,12 +299,25 @@ def check_current_branch(repo_root, expected_branch="development", skip_branch_c
         )
 
 
+_REF_LOCK_RE = re.compile(r"cannot lock ref|unable to create .*\.lock|unable to update local ref", re.I)
+
+
 def pull_upstream(repo_root, branch="development"):
-    """Fast-forward pull from origin."""
-    cmd = ["git", "-C", repo_root, "pull", "--ff-only", "origin", branch]
-    r = subprocess.run(cmd, capture_output=True, text=True, check=False)
-    if r.returncode != 0:
-        die(f"git pull --ff-only failed: {r.stderr}")
+    """Fast-forward from origin. GH-1475 (F5): fetch, then merge the remote-tracking ref, not
+    `git pull` (which merges the shared FETCH_HEAD a concurrent fetch can rewrite). A ref lock held
+    by a concurrent fetch in the primary is retried briefly; any other error stops as before."""
+    for attempt, wait in enumerate((1, 2, None)):
+        r = subprocess.run(["git", "-C", repo_root, "fetch", "origin", branch],
+                           capture_output=True, text=True, check=False)
+        if r.returncode == 0:
+            r = subprocess.run(["git", "-C", repo_root, "merge", "--ff-only", f"origin/{branch}"],
+                               capture_output=True, text=True, check=False)
+            if r.returncode == 0:
+                return
+        if wait is None or not _REF_LOCK_RE.search(r.stderr or ""):
+            die(f"git fetch + merge --ff-only origin/{branch} failed: {r.stderr}")
+        log(f"git ref lock held by another process; retry {attempt + 2}/3 in {wait}s")
+        time.sleep(wait)
 
 
 def fetch_issue_state(repo_root, issue_num, offline_manifest=None):
```

Please re-review (whole diff above plus SKILL.md as read). handing off to Reviewer (codex) — take your turn.

### Reviewer · Round 2

swept file: yes

**Ship, subject to the separately required final harness gate.** Read all three Python artifacts, the skill, plan and retained evidence; assessed the supplied base-to-head Python diff and the GH-1475 changelog entry. No additional pre-existing code defect was established in the whole-file sweep, including the existing landing/reconcile, batch persistence, teardown and rollback paths. No duplicate subsystem or writer found. Graph discovery again returned `MCP tool call requires approval, but approval policy is never`; direct reads were the fallback. No git command, suite, executable fixture or production mutation was run. Only this relay file was edited.

- [Pass] **Round 1 evidence finding resolved.** `manual-p13b.py.txt` drives the real landing loop through repaired-head `DRAFT_REFUSAL`, rather than returning before the clean endpoint. `manual-check-run.log` now records `new clean+keep ... rc=0 workdir_left=1 B1-RESULT kept=True` versus `mutant clean+keep ... rc=0 workdir_left=0 B1-RESULT kept=False`. The mutation removes only the keep guard. Its containment observations record `returned=False rmtree_called=False` for symlink, outside-temp-root and wrong-prefix inputs, and `returned=True rmtree_called=True` for the valid input. This meets the requested discriminating control without a production change or new suite. These are inspected retained clone observations, not reruns here.
- [Pass] **P1.1/P1.2 delivered as planned.** `wave_reconcile.py:302-320` fetches and merges the tracking ref, retries only the stated lock diagnostics, and stops after three attempts; `merge_cleanup.py:128-132` extends the existing transient classifier. `manual-check-run.log` records retries 2/3 and 3/3 followed by matching HEAD, base `ReconcileError`, and non-lock failure code 2. `merge_cleanup.py:2203-2206` line-buffers supported streams; the same receipt records the sleeping process alive at five seconds with 25 lines versus base zero. No broader retry policy or logging subsystem was added.
- [Pass] **P1.3 deletion is bounded to owned landing scratch.** `merge_cleanup.py:218-232` requires the expected prefix, a non-symlink directory and resolved parent equal to the temp root before `rmtree`; errors warn and return False. The only caller, `:2136`, additionally requires clean completion, no keep flag and no deferred sync. Workdir originates in this invocation's `mkdtemp` (`:1688` vicinity); repair handoffs, failures and exit 3 retain it. `run_isolated_check` remains a retained, separate full-clone path. The new retained negative controls above supplement the earlier clean/base and error observations. No observed deletion-safety defect remains.
- [Pass] **P1.4 extends existing ownership and guards recovery writes.** `merge_cleanup.py:1663-1676` shares the prior sweep-finalize/issue-refresh tail as `_sync_batch`; `:2446-2454` updates the overlapping unfinished batch only after successful reconciliation and publication, only outside dry run. `batch_record.py:250-258` shares the original terminal-row rule with `record_sweep` (`merge_cleanup.py:2872-2887`). `manual-p14.py.txt` exercises `main()` and reloads persisted state; its log records execute `merged/ok`, `continuable=False`, `issue_edit=True`, while dry run and reconcile/push failures leave the row failed. Base execute leaves it failed. Mixed-row hints discriminate reconcile from resume and exclude the closed row. No second persistence or issue writer was introduced.
- [Pass] **P1.5/P1.6 remain bounded.** SKILL.md's “Exit codes for wrapper scripts” lists 0–5 and its “Trigger & threshold” corrects the single-PR exit-4 claim. `merge_cleanup.py:1112-1145` uses local advisory probes with five-second subprocess timeouts and silent unsuccessful probes; `:2524-2525` prints them at the dry-run pin seam. `:1958-1963` reuses the existing required-check answer once per dry run. `manual-check-run.log` records one versus zero F6 warnings, zero gh calls in both cases, four forced environment warnings, clean-env silence and absent warnings on base. The supplied diff adds no new test/suite/registry entry, gh query, refusal or lock mechanism.
- [Pass] **Evidence integrity rechecked.** Command: `PYTHONDONTWRITEBYTECODE=1 python3 -` loaded all four provenance rows, required each referenced log/driver to be nonempty, compared SHA-256 digests, and parsed the three Python artifacts with `ast.parse`; exit 0. Decisive output: `manual scenarios: nonempty hashes match`, `existing suites: nonempty hashes match`, `smoke: nonempty hashes match`, `manual scenario (final-QA r1): nonempty hashes match`, and three `AST OK` lines. `existing-suite-summary.txt` records all five suites rc=0 and `Ran 227 tests ... OK`. `smoke.log` honestly reports conflicting-PR retention rather than claiming real clean-path deletion. No full final-commit gate result is claimed: it remains **[Unverified — needs clone run]**, assigned to the harness after this turn.
- [Pass] **Rating remains a provisional judgment consistent with the recorded incident.** Plan “Rating” retains `rated 60/65/50/75`, recoverable hours of disruption and explicitly unknown recurrence trend; this does not overclaim measured frequency. Stored database values were not queried, so persisted-rating equality is not independently verified by this turn.
- [Nit] **Qualify the cleanup summary's exit-0 shorthand.** SKILL.md says “A clean landing loop (exit 0 from Phase 5) removes its own ... workdir”; CHANGELOG.md:5 similarly says a clean loop removes it. The new receipt itself witnesses exit 0 with retained B1 work. Optionally say “clean completion with no keep flag or deferred sync” to mirror `merge_cleanup.py:2136`. This is a wording improvement, not a request to alter retention behavior or a blocker.

**VERDICT: PASS**
**Basis:** P1.1–P1.6 match the approved Phase 1 plan through existing owners. The only required prior finding is resolved by discriminating retained evidence, and the whole-file sweep found no additional blocking defect. Approval is implementation review approval; final-commit full-gate qualification remains outstanding with the harness.

relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
