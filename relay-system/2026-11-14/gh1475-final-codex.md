# RELAY · GH-1475 Phase 1 final QA (Codex)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 3

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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
