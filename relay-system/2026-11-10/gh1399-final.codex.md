# RELAY · GH1399 final implementation QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-10.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 5 / 6

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
6. **Commit only the relay file** (`relay(gh1399-final-implementation-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup

Review the full diff origin/development...HEAD for issue1399, its active task/recon docs, and committed TESTS-RESULTS/2026-11-10+GH-1399 evidence. First paraphrase the operator contract: fail-closed entry using existing accounting, preserved consumed rounds and admin behavior, no new suites/framework. Read all changed runtime files, not only hunks. Production controls run in disposable full clones; do not execute test/validate from your reviewer worktree. Read-only probes allowed. Scope limits: native explicit bypass and operator local-file tampering are not a security boundary; a reservation covers one caller-owned repair episode, not automatic inference of every raw shell command. Frozen Bash fallbacks unchanged; default Python producers integrated. Source skill instruction changes only, no deployment. Final full pre-push and hosted checks will run after approval; do not claim them yet. Missing runtime behavior with a concrete failing input is a finding. Do not prescribe new suites or gate frameworks.

- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: codex-parent
- Started: 2026-11-10
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The inherited merge-repair accounting path can enter a counted relay but cannot complete its approval path. Full-file review coverage also remains incomplete; this is not final sign-off.
swept file: no

Operator contract: fail closed at existing qualification boundaries using existing accounting, preserve consumed rounds and administrative behavior, and add no suites/framework. Native bypasses and deliberate local-file tampering remain outside the boundary; one reservation covers one caller-owned repair episode.

- [Should] **Do not send a merge-repair reservation to the lane-only writer on approval.** `utils/py/relay_drive.py:259` accepts a nested counted reservation with state `in_progress`; `utils/py/gate_receipt.py:133` explicitly supports `kind=merge-repair`. With that context in `XYZ_ATTEMPT_CONTEXT`, `relay_drive.py:766` attaches it to the approval, then `relay_drive.py:776` unconditionally invokes `lane_attempt_finish`. That writer rejects every canonical merge-cleanup record path before doing any IO (`utils/py/rtl.py:148`), so the enclosing catch returns `attest-publish-failed` after the reviewer already approved and the trailer/approval were written. This conflicts with parent-context reuse in `skills/1-hourly/start-task/SKILL.md:252`.
  Observed input: `{"kind":"merge-repair","record":"/primary/.tick/merge-cleanup/HiQS-Labs-XYZ-forge/pr-1399.json","index":0}` passed to `lane_attempt_finish(context, "active", "a"*40, attestation="/primary/.git/approval.json")` raises `ValueError: archived attempt bytes are immutable`. The path follows the canonical shape in `skills/2-daily/merge-cleanup/scripts/attempt_record.py:49`; rejection precedes checking record contents.
  Affected scope: non-review-once relay approvals inheriting an explicitly supplied, valid merge-repair `XYZ_ATTEMPT_CONTEXT`, with `LANE_ATTEMPT_COUNTED=1`. The admission branch already permits this state; this is not a request to admit failed/resolved reservations as active builders.
  Falsifier: in a disposable full clone, run an approving nested relay under a valid in-progress canonical merge-repair context. It must finish without `attest-publish-failed`, preserve the parent's repair count and lifecycle ownership, and avoid allocating a lane budget. If it already does, this finding is wrong.
  Probe: `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'` with `sys.path.insert(0, "utils/py"); from rtl import lane_attempt_finish` and the exact call above, catching/printing `ValueError`. Exit status **0** (exception caught); decisive output **`ValueError: archived attempt bytes are immutable`**. No Git invocation, lock, record read or write occurred. This establishes the callee mismatch; end-to-end reproduction remains **[Unverified — needs clone run]**.
  Fix: dispatch approval binding according to reservation kind and retain merge-repair ownership with its existing writer/caller. Do not invoke the lane JSONL writer for a merge-repair JSON record or book a replacement lane merely to make approval pass. Verify with a retained manual clone control, not a new suite.

- [Pass] Admission precedes docs routing and full-receipt reuse in `githooks/pre-push:90`, and legacy green recording in `utils/gate-record.sh:81`. This is source inspection, not an independently executed gate.
- [Pass] Legacy timestamp lines still consume count in `utils/py/rtl.py:86`, and archive preservation uses rename in `utils/py/rtl.py:215`. Recorded managed controls include transcript-only acceptance, unrelated-candidate refusal and two retained lines in `TESTS-RESULTS/2026-11-10+GH-1399/implementation/gate/managed-results.json`. These are producer receipts, not a fresh reviewer execution.
- [Unverified — needs clone run] Full pre-push/hosted qualification remains outstanding as Setup explicitly permits. No validate, test suite, pytest, executable fixture or Git command was run in this turn.
- [Unverified — review coverage] Reconstructed the base-to-HEAD changed-path list and diff by reading Git object bytes without invoking Git; reviewed the task/recon docs, admission module, lane accounting changes, relay driver, boundary integrations and retained evidence. The complete pre-existing bodies of marathon_drive, merge_cleanup, scan_clones and every changed gate/test/skill have not all been swept. No claim of absence of pre-existing defects is made. Complete that sweep before final approval.

Handing off to Producer (codex-parent) — correct/disposition the lifecycle mismatch, retain its clone evidence, and return for the remaining full-file review; go to the Producer window and say 'take your turn'.

### Producer · Round 2

Implemented the observed lifecycle mismatch: only a managed lane context receives the lane approval binding. Inherited manual/merge-repair contexts remain owned by their parent; the relay neither finishes nor archives them. Retained real driver + real isolated shim controls under implementation/final-controls use a stub reviewer, explicitly synthetic. Replaying the old condition fails approval; the fixed version exits0 with exactly one still-in-progress parent repair and no lane budget. Administrative normal push passed in74s; completed proof passed from a separate full clone. These final manual receipts are retained with provenance. Full qualification/hosted checks remain pending approval. Please complete the remaining whole-file sweep and review this fix; no suites may run in the review worktree.

Handing off to Reviewer (codex) for round2.

### Reviewer · Round 2

VERDICT: PARKED
Basis: Round-one lifecycle finding is addressed in source and supported by retained red/green controls. Final approval is withheld because the mandatory whole-file review remains incomplete; this is a review-coverage limitation, not a newly observed runtime failure.
swept file: no

Operator contract: fail closed at qualification entry through the existing accounting authorities, retain consumed rounds and administrative behavior, and introduce no new suites/framework. Explicit bypasses and deliberate local-file tampering remain outside the boundary; the reservation covers one caller-owned repair episode.

- [Pass] **Round-one finding closed.** In `utils/py/relay_drive.py:767`, approval binding now requires `json.loads(raw_context).get("kind") == "lane"`; `utils/py/relay_drive.py:776` calls the lane writer only when that binding was installed. Thus this approval path no longer passes the inherited merge-repair JSON record to the lane JSONL writer. The retained `implementation/final-controls/parent-control.sh` asserts the parent remains in progress with one attempt and that the approval has no parent-owned attempt context. Its red counterpart restores the old condition. These scripts were read, not executed here.
- [Pass] **Retained control integrity.** Read-only probe: `PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'`, loading `TESTS-RESULTS/2026-11-10+GH-1399/implementation/final-controls/provenance.jsonl`, computing SHA-256 for every listed file, and decompressing the two parent-approval logs. Exit **0**; decisive output: **`provenance files: 10 hash mismatches: []`**. Red log: **`relay-drive: attestation record write FAILED: archived attempt bytes are immutable`**. Green log: **`relay-drive: relay terminated (STATUS: Approved, token done, attested by rev) after 1 turn(s)`**. These are authenticated retained producer controls using a synthetic reviewer, not an independently rerun driver.
- [Unverified — review coverage] This turn inspected the task/recon documents, the full admission predicate and lane writer, the approval fix and nested/reset paths, the pre-push hook, and retained final-control scripts/results/provenance. It did not complete the full pre-existing bodies of `utils/py/marathon_drive.py`, `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, `scan_clones.py`, or every changed gate/test/skill. No assertion of absence of pre-existing defects is made. Whole-file coverage remains necessary before approval; this finding requests review work, not a speculative behavior change or new gate.
- [Unverified — needs clone run] Final full pre-push qualification and hosted checks remain pending as permitted by Setup. No Git command, validate/test/pytest invocation, or executable fixture was run here.

Handing off to Producer (codex-parent) — retain the round-one fix and evidence, and arrange completion of the outstanding whole-file review before final sign-off; go to the Producer window and say 'take your turn'.

### Producer · Round 3

Round2 reports no new code defect and closes the sole observed finding. No production changes since that review. Complete the outstanding review now, focusing on the files you explicitly have not swept: utils/py/marathon_drive.py; skills/2-daily/merge-cleanup/scripts/merge_cleanup.py and scan_clones.py; githooks/install.sh; validate.sh; ci-local.sh; utils/gate-record.sh; utils/py/gate_env.py; changed fixture setup in test/gh544-pre-push-gate.sh, test/gh35-test-tiers.sh, test/synthetic/gh124-closeout-suite.sh; source start-task/workhorse skill edits. Read their full bodies in bounded chunks, review integration seams against the already-inspected predicate, and finish the remaining coverage before returning. Read-only git diff/show/status and ordinary read tools are authorized; there is no prohibition on Git inspection. Do not execute mutation-heavy suites in a linked worktree. Do not spend this turn re-reading already-completed admission/rtl coverage while leaving the outstanding files unread. No new speculative controls, suites or frameworks are requested. If there is a concrete defect, report it with its failing input. Otherwise finish the sweep and issue the truthful verdict. This is the third/final review round, not a new review or a reset.

Handing off to Reviewer (codex) to complete the remaining whole-file sweep and final verdict.

### Reviewer · Round 3

VERDICT: FAIL
Basis: The remaining scan_clones sweep exposed a concrete pre-existing lock-reader mismatch in a touched runtime file. The mandatory whole-file contract includes that defect. This is not a claim that GH-1399 introduced it, or that teardown was observed. The maximum round has been reached, so escalation is explicit.
swept file: no

Operator contract: fail closed at qualification entry using existing accounting; preserve consumed rounds and administrative behavior; introduce no new suites/framework. Explicit bypass and deliberate local-file tampering remain outside the boundary. One reservation covers one caller-owned repair episode.

- [Should] **Recognize the canonical driver lock directory before considering cleanup safe.** `skills/2-daily/merge-cleanup/scripts/scan_clones.py:211-236` only considers `lock.is_file()`. The actual writer uses `os.mkdir(lock_dir)` and writes its PID into `lock_dir/pid` (`utils/py/marathon_drive.py:1355`, `:1387`). Consequently the reader returns `locked=False` for the writer's normal lock shape. `inspect_checkout` relies on `driver_lock.locked` and `alive` for its early `ACTIVE_LOCKED` preservation branch (`scan_clones.py:1126`). Tick claims and open handles are additional checks; this finding does not assert that they were bypassed or that a checkout was removed.
  Observed input: existing `/Users/noelsaw/Documents/GitHub/XYZ-forge-gh1399-attempt-entry-gate-2026-11-10/.git/relay-driver.lock` is a directory, with readable `pid` containing `17464`; `inspect_driver_lock` on that full-clone path returned `{'locked': False}`. No synthetic lock or repository state was created.
  Affected scope: cleanup inspection of ordinary full clones containing the canonical directory-form driver lock (and the same resolved lock shape for linked worktrees). Preserve support for the legacy file form. This is a pre-existing defect in a changed file, not a new accounting requirement.
  Falsifier: in a disposable full clone with a canonical directory-form lock owned by a known live process, the existing reader must return `locked=True`, identify that PID, and the checkout inspection must preserve it as active. A stale directory lock must retain the existing stale/idle semantics; a legacy file-form lock must remain readable. If the current reader already recognizes that directory input, this finding is wrong.
  Probe command (exit **0**; no Git subprocess):
  ```python
  import sys, os
  from pathlib import Path
  sys.path.insert(0, 'skills/2-daily/merge-cleanup/scripts')
  from scan_clones import inspect_driver_lock
  p = Path('/Users/noelsaw/Documents/GitHub/XYZ-forge-gh1399-attempt-entry-gate-2026-11-10')
  f = p / '.git/relay-driver.lock'
  print('lock is directory:', f.is_dir())
  if f.is_dir():
      pid = (f / 'pid').read_text().strip()
      print('pid:', pid)
      try:
          os.kill(int(pid), 0)
          print('pid alive: yes')
      except OSError as e:
          print('pid check:', type(e).__name__)
  print('reader:', inspect_driver_lock(p))
  ```
  Executed via `PYTHONDONTWRITEBYTECODE=1 python3 -`; decisive output: **`lock is directory: True`**, **`pid: 17464`**, **`pid check: PermissionError`**, **`reader: {'locked': False}`**. A separate `ps -p 17464 -o pid=,comm=` was refused by the sandbox (`operation not permitted`); PID liveness and end-to-end teardown remain **[Unverified — needs clone run]**. The directory-shape rejection itself is directly observed and independent of liveness.
  Root cause: cleanup's reader assumes a regular-file lock while the canonical driver writes a directory; Fix site: existing `inspect_driver_lock`; Why not upstream/downstream: the driver lock format is already established, and the reader must understand its existing producer rather than add another safety framework. Read the directory's `pid` using the existing reader's conservative error handling, keeping the legacy file branch. Verify through retained manual clone controls or existing coverage, with no new suite.

- [Pass] The inherited approval correction remains lane-specific: `utils/py/relay_drive.py:767` requires `kind == "lane"` before `lane_attempt_finish` at `:776`. No additional production change was reported since round2; the prior red/green retained controls remain the evidence for this fix.
- [Pass] Source inspection of the merge-repair publication seam found explicit canonical context propagation: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:668` supplies `kind=merge-repair` and the coordinator's `attempt_record.record_path` to the push environment; `scan_clones.py:137-142` forwards the supplied environment into its bounded subprocess. These are source claims, not rerun publication controls.
- [Unverified — review coverage] This turn read the remaining scan_clones body, the installer, ci-local, gate-record and gate-env bodies, and substantial bounded portions of marathon_drive and merge_cleanup including accounting/qualification seams. Some large command outputs were truncated; complete coverage of those two large drivers, validate's full body, all changed fixture bodies and both source skills is still not established. Therefore no absence-of-pre-existing-defects claim or full-file approval is made. The lock mismatch above is a concrete finding, not a substitute claim of completed coverage.
- [Unverified — needs clone run] Final full pre-push and hosted qualification remain outstanding as Setup permits. No Git command, validate/test/pytest invocation, executable fixture, source edit, or artifact edit was performed. Only this relay file is changed.

Handing off to Producer (codex-parent) — disposition the observed directory-lock reader defect and arrange completion of the remaining coverage under the escalation; go to the Producer window and say 'take your turn'. This relay is Escalated, not Approved; do not treat this receipt as permission to publish a ready PR.

### Producer · Round 4 — operator extension

The operator explicitly authorized three additional QA rounds on2026-11-11: total budget6, already consumed3, now round4. Preserve all historical verdicts and counters. The existing final relay/token continues.

Round3's concrete directory-lock reader defect is fixed in6f081242c: inspect_driver_lock accepts canonical lock directories and reads pid, while preserving legacy files and conservative malformed-lock handling. Committed lock-reader/result.json records old-reader RED and fixed live/stale/missing-pid/legacy controls; checkout-result.json records real ACTIVE_LOCKED preservation, with provenance. Review this two-line fix independently. No other runtime changes since round3.

Finish the remaining whole-file review. Previous coverage explicitly lacked complete utils/py/marathon_drive.py, merge_cleanup.py, validate.sh, changed fixture bodies and source start-task/workhorse skills. Read those bodies in bounded chunks that avoid output truncation; ordinary read-only git commands are permitted. Review prior inspected files by their existing receipts and actual two-line change. Do not repeatedly spend this turn on already-completed admission/rtl coverage while leaving those outstanding files unread. Do not return merely because coverage is unfinished: complete the available review before deciding. No mutation-heavy suites in the reviewer worktree, no new suites or gate frameworks. Final full publication qualification and hosted checks follow independent approval; they remain unclaimed.

Handing off to Reviewer(codex) for round4 of6.

### Reviewer · Round 4

VERDICT: FAIL
Basis: Completed the outstanding whole-file sweep. The directory-lock finding is closed; one concrete pre-existing run-log lookup defect remains in the touched marathon driver. This verdict does not claim GH-1399 introduced it.
swept file: yes

Operator contract: fail closed at qualification entry through existing accounting, preserve consumed rounds and administrative behavior, and add no suites/framework. Explicit bypasses and deliberate local-file tampering remain outside the boundary; a reservation covers one caller-owned repair episode.

- [Should] **Do not select a quoting discussion comment as the run log to overwrite.** `utils/py/marathon_drive.py:415` accepts the marker anywhere in a comment body. The selected ID flows directly to the body-replacing PATCH at `:1783-1787`; the writer already places its own marker first (`:1768-1770`). An earlier discussion comment quoting the marker therefore wins over the actual run log. If that discussion comment belongs to the authenticated operator, the update can replace their discussion text. This is the exact class described in `LESSONS-LEARNED.md:151-159`, not a new security boundary or speculative framework requirement. No live GitHub write was attempted or observed.
  Observed input: marker `<!-- xyz-marathon-run-log:1399:p1 -->`; ordered comments `[{"id":101,"body":"Please preserve this example:\n```\n<!-- xyz-marathon-run-log:1399:p1 -->\n```"},{"id":202,"body":"<!-- xyz-marathon-run-log:1399:p1 -->\n### Marathon run log"}]`. The actual reader returns `101`; the intended run-log ID is `202`. With only the quoting comment it also returns `101` instead of no match.
  Affected scope: opt-in `--log-github` runs whose issue discussion contains the exact marker later in a comment body, before the real run log (or with no real log yet). Flat and paginated payloads share this predicate. No claim is made about comments lacking the exact marker or arbitrary local-file tampering.
  Falsifier: with those same two rows the reader must select `202`; with the quoting row alone it must return an empty ID; with the genuine row alone it must still select `202`. If current code satisfies all three, this finding is wrong.
  Probe command, exit **0** (pure function extracted unchanged from the source AST; no module startup, Git subprocess or fixture execution):
  ```python
  import ast, json
  from pathlib import Path
  p = Path('utils/py/marathon_drive.py')
  tree = ast.parse(p.read_text())
  f = next(n for n in tree.body if isinstance(n, ast.FunctionDef)
           and n.name == 'runlog_find_comment_id')
  ns = {'json': json}
  exec(compile(ast.Module(body=[f], type_ignores=[]), str(p), 'exec'), ns)
  marker = '<!-- xyz-marathon-run-log:1399:p1 -->'
  quoted = {'id': 101, 'body': 'Please preserve this example:\n```\n' + marker + '\n```'}
  owned = {'id': 202, 'body': marker + '\n### Marathon run log'}
  for label, rows in [('owned-only', [owned]), ('quoted-only', [quoted]),
                      ('quoted-before-owned', [quoted, owned])]:
      print(label, 'selected=', repr(ns['runlog_find_comment_id'](json.dumps(rows), marker)))
  ```
  Executed using `PYTHONDONTWRITEBYTECODE=1 python3 -`. Decisive output: **`owned-only selected= '202'`**, **`quoted-only selected= '101'`**, **`quoted-before-owned selected= '101'`**. The genuine-only control rules out a generally broken parser; the quoting cases isolate the substring predicate. Root cause: comment identity uses substring presence; Fix site: existing `runlog_find_comment_id`; Why not upstream/downstream: ordinary discussion may quote examples, while PATCH correctly updates the ID it is given. Match the existing first-line marker rather than adding another writer or framework. Verify with an existing check or retained manual control, no new suite. Relevance/sanity check: this can replace operator-authored discussion, and the relay explicitly includes pre-existing defects in touched files; a narrow predicate correction is proportionate.

- [Pass] **Round-three directory-lock finding closed.** `skills/2-daily/merge-cleanup/scripts/scan_clones.py:212-214` now accepts directories and reads `pid`; the file-form branch remains, and unreadable locks retain `locked=True, alive=True` at `:233-234`. Retained `TESTS-RESULTS/2026-11-10+GH-1399/lock-reader/result.json` contains old-reader `locked:false`, fixed live/stale/missing-pid/legacy cases; `checkout-result.json` records `ACTIVE_LOCKED`. A read-only SHA-256 check against `lock-reader/provenance.jsonl` exited **0**, output **`lock receipt hash mismatches: []`**. These are intact producer controls, not independently rerun clone controls.
- [Pass] **Prior lifecycle correction retained.** `utils/py/relay_drive.py:767-777` still binds and finishes approval accounting only for `kind == "lane"`; parent-owned merge-repair records do not reach the lane writer. Round-two retained red/green control review remains applicable.
- [Pass] **Outstanding source coverage completed.** Read the complete bodies of `utils/py/marathon_drive.py` and `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` in bounded chunks, filling truncated spans separately; read `validate.sh` including its complete registry/executable body, `githooks/install.sh`, `ci-local.sh`, `utils/gate-record.sh`, `utils/py/gate_env.py`, all three named changed fixture bodies, and the source start-task/workhorse skills. Combined with rounds 1–3's recorded admission/rtl/relay/scan_clones/task/recon/evidence coverage, the previously declared sweep gaps are closed. Integration references include `validate.sh:1073-1078` (admit before tier dispatch and scrub child context), `merge_cleanup.py:668-673` (repair push context), and `skills/1-hourly/start-task/SKILL.md:245-263` (reuse parent accounting and preserve lifecycle ownership). No additional concrete pre-existing defect was established beyond the run-log finding above; source coverage is not a claim of exhaustive runtime correctness.
- [Unverified — needs clone run] Final full pre-push qualification and hosted checks remain pending as Setup permits. No Git command, validate/test/pytest invocation, executable fixture, source edit or artifact edit occurred in this turn. Only this relay file is changed.

Handing off to Producer (codex-parent) — disposition the concrete run-log finding, retain the completed coverage and prior fixes, and return within the existing round budget; go to the Producer window and say 'take your turn'.

### Producer · Round 5

Implemented the run-log identity finding in5f9647d6f: match the exact first line, preserving flat/paginated parsing. Retained manual old/fixed real-function controls cover genuine, quoted-only, quoted-before-owned, paginated, prefix collision, CRLF and empty inputs; old quoting cases reproduce RED and all fixed cases pass. Existing gh322 suite initially failed because its three genuine fixtures placed body text on the marker line; updated only those fixture strings to the real writer's marker-newline-body contract, no new assertions or suite. Existing gh322 now29 pass,0 fail. Evidence and provenance committed in TESTS-RESULTS/2026-11-10+GH-1399/runlog. Read the newly touched gh322 test's full body as appropriate. No other runtime changes since round4. Round4 completed the outstanding whole-file sweep and closed prior findings; preserve that coverage. Verify the one-line predicate and three existing fixture changes, then issue final verdict. Final publication qualification/hosted checks remain pending approval.

Handing off to Reviewer(codex) for round5 of6.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
