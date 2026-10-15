# RELAY · GH-1064 plan QA — script-owned merge-batch issue + recorded post-merge QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-14.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 3 / 3

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
6. **Commit only the relay file** (`relay(gh1064-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1064-MERGE-BATCH-ISSUE-QA.md`, the **plan** (no code written yet).
- Requirements: GitHub issue #1064 body, **as scoped by the operator decisions in the plan** (script
  records, agent runs the suite; exit 4 = landed, QA pending; threshold 2+).
- Read the source the plan cites, not just the plan:
  - `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (`main`, `land_prs`, `execute_pr_merge`)
  - `skills/2-daily/merge-cleanup/scripts/toposort_prs.py`, `attempt_record.py`, `scan_clones.py` (`_gh`, `post_issue_marker`)
  - `skills/2-daily/merge-cleanup/SKILL.md` ("Batch issue protocol (GH-944)", "Done rule", "Capability table", Drive loop)
  - `test/gh534_phase_b_tests.py` (`GH_STUB`), `test/gh534_phase_c_tests.py` (parity guard, `TestGh623DriveLoopDocContract`)
  - `utils/py/wave_reconcile.py` `select_qualification_gate`
  - `AGENTS.md` "No new tests (GH-831)"
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-14
- **Operational envelope:** a local, operator-driven CLI that lands a handful of PRs per run in one repo.
  Grade against the stated requirements and commensurate complexity. Do **not** ask for enterprise
  fail-safes, distributed locking, new suites, guards or runners (GH-831 forbids the last three).
- **Definition of Done — answer each question with file:line evidence:**
  1. Are the plan's recon claims (line numbers, data available at each hook point, what `toposort_prs` keeps, what `execute_pr_merge` returns) accurate against the code?
  2. Is the "before the first merge" hook point right, so the issue exists before any `gh pr merge`, including on `--resume` and when the first PR is skipped or deferred?
  3. Does the plan extend existing writers and helpers (`attempt_record` lock/save, `scan_clones._gh`, `select_qualification_gate`) rather than creating a parallel subsystem? Is a new `batch_record.py` justified, or should it live in an existing module?
  4. Is the exit code 4 precedence (2 > 3 > 4 > 0) and the `--record-sweep` standalone mode sound? Any caller or doc-contract test that breaks?
  5. Does the plan stay inside GH-831, given that adding test methods to the existing gh534 files is argued as required by the parity guard? Is the red-control plan falsifiable?
  6. Is anything in #1064's operator-scoped requirements missing, or anything built that is not required?
  7. Pre-existing defects in the touched code paths that would make this plan wrong.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The basic ownership split is sound, but the plan needs corrections for resume, Phase 6, outcome persistence, and caller-written issue content before implementation. These are bounded CLI/record changes, not grounds for new runners or coordination machinery.
swept file: yes

Scope/evidence: Read the entire plan, `merge_cleanup.py`, `toposort_prs.py`, `attempt_record.py`, SKILL.md, and both gh534 test files; inspected the cited scanner, tool-resolution, qualification, routing, and orchestration-test paths. Verify-tier graph discovery found no matching symbols; coverage generation `2026-09-01T15:54:30Z` belongs to another checkout and reports these script paths `not_tracked`, so the findings below use this worktree's source. No git commands, suites, executable fixtures, or artifact edits were run. Source/AST observations are evidence about the plan, not implementation test results. In citations below, `scripts/` means `skills/2-daily/merge-cleanup/scripts/`, and `plan` means `PROJECT/1-INBOX/GH-1064-MERGE-BATCH-ISSUE-QA.md`.

- [Should] **R1 — Correct the helper owner and avoid a circular import (DoD 1/3).** `plan:62` and `plan:103` specify `scan_clones._gh`, which does not exist. `_gh` and `post_issue_marker` are in `scripts/merge_cleanup.py:70` and `:315`; the scanner has only `_gh_bin` (`scripts/scan_clones.py:373`). Fix the recon and reuse the real `_gh` through an injected callable (or keep orchestration of gh calls in its existing owner); do not have `batch_record` import the CLI driver that imports it.
  Observed input: the proposed attribute `scan_clones._gh` at `plan:103`. Narrow probe (exit 0; decisive output `scan_clones []` and `merge_cleanup [('_gh', 70), ('post_issue_marker', 315)]`):
  ```sh
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  python3 -B - <<'PY'
  import ast
  from pathlib import Path
  base = Path("skills/2-daily/merge-cleanup/scripts")
  for module in ("scan_clones", "merge_cleanup"):
      tree = ast.parse((base / (module + ".py")).read_text())
      print(module, [(n.name,n.lineno) for n in tree.body if isinstance(n, ast.FunctionDef) and n.name in ("_gh","post_issue_marker")])
  PY
  ```
  Affected scope: the new module's GitHub calls, including label bootstrap and issue create/edit.
  Falsifier: the same symbol probe finding an actual scanner `_gh` definition would remove the ownership objection; an import-only check in the gate clone must load the final CLI/module without circular-import errors.

- [Should] **R2 — Resume the original batch before applying the new-batch threshold (DoD 2/6).** `plan:119` calls `open_or_resume` only for queues of at least two. Discovery returns only OPEN PRs (`scripts/toposort_prs.py:34`), so an original two-PR batch with one landed and one handed off resumes as one PR and bypasses the batch entirely. An empty queue also bypasses `land_prs` (`scripts/merge_cleanup.py:1443`). Separate lookup/continuation from fresh-batch creation, retain earlier outcomes and sweep inputs, and make an outstanding batch's QA status visible even after discovery shrinks to zero. Also do not use `verdict is unset` as the sole definition of an unfinished merge batch: a sweep recorded for the landed subset must not force a new issue when its remaining PR resumes; new landings need a fresh verdict.
  Observed input: the existing two-PR handoff scenario at `test/gh534_phase_b_tests.py:543` leaves PR 1 MERGED and PR 2 OPEN (`:552-553`); the proposed `len(ordered_prs) >= 2` predicate rejects its next queue `[2]`. `plan:107-108` also excludes any earlier batch whose partial sweep has been recorded.
  Affected scope: `--resume` of an originally qualifying batch, including a one-PR remainder and QA-only continuation; fresh one-PR runs remain unchanged.
  Falsifier: continue that existing scenario after repairing PR 2; expect the same issue, both landing OIDs retained, no second create, and QA pending for the final combined batch. A fresh one-PR run must still create no issue. Record a partial sweep before continuation as the countercase to verdict-based batch identity.

- [Should] **R3 — Carry exit 4 through `main` without skipping normal cleanup (DoD 4/5).** Returning 4 from `land_prs` as written reaches `main`'s existing `if rc != 0: return rc` (`scripts/merge_cleanup.py:1448`), so a successful batch skips all Phase 6 work. This contradicts `plan:94` (no teardown change) and cannot honor 2 > 4 if Phase 6 would fail. Let the driver retain the pending-QA result, run ordinary Phase 6 after successful landings, then return 4 unless a harder result occurred. Dispatch standalone `--record-sweep` after primary-path resolution and before Phase 0/discovery, and document how the drive loop reaches actual cleanup completion after recording the verdict.
  Observed input: proposed Phase-5 `rc=4` (`plan:131-133`) entering the exact nonzero dispatch at `scripts/merge_cleanup.py:1448-1450`. Existing two-PR coverage explicitly expects both exit 0 and pruning (`test/gh534_phase_b_tests.py:379`, `:388`), and `test/gh534_phase_c_tests.py:282` also pins exit 0 for two successful landings. The plan only adds new methods and misses these existing contract updates.
  Affected scope: successful qualifying executions, their normal teardown, final exit precedence, and existing two-PR assertions.
  Falsifier: in the disposable clone, a successful two-PR run must still reach Phase 6 but finish 4; a Phase-6 failure must finish 2. Update affected existing expectations while retaining their landing/durability/pruning assertions. Standalone recording must invoke no discovery, merge, or teardown.

- [Should] **R4 — Record remote landing and every terminal/skip outcome at the actual branches (DoD 1/2/7).** The proposed hooks (`plan:121-123`) do not specify hard-stop persistence, and `failed` is not a complete outcome map. A remote merge can succeed and then return 2 during fetch, fast-forward, reconciliation, or durability (`scripts/merge_cleanup.py:1162-1188`), before an after-loop hook. Hold-label and non-OPEN skips never enter `failed` (`:973-979`), while drafts are removed from it (`:1197`). Specify immediate remote-merge recording before reconciliation, distinct reconcile/durability status, named skipped/stopped outcomes, and sweep-input finalization on early exit after a landing. Keep exit 2/3 and existing merge eligibility unchanged.
  Observed input: `test/gh534_phase_b_tests.py:510-518` deliberately makes reconciliation fail after PR 1 is MERGED, leaving PR 2 OPEN; `:491-498` supplies a `do-not-merge` PR whose skip never enters `failed`. These are existing path shapes the new record must represent.
  Affected scope: batch reporting across current early returns and skips, not a redesign of repair or merge policy.
  Falsifier: reuse the failed-reconcile case and expect PR 1 recorded as remotely merged with reconcile failure, PR 2 unattempted, and exit 2. The held-PR case must name the hold skip. A clean run must retain its successful reconciliation status.

- [Should] **R5 — Preserve the caller-owned sections when updating the issue (DoD 3/6).** `plan:104-116` stores script data and renders the other sections as placeholders, then replaces the entire body with `gh issue edit --body-file`. On resume or verdict recording this can replace the agent's findings, pivots, and carry-overs with placeholders. Bound updates to a marked script-owned block, or explicitly read/preserve the caller sections; a body renderer must not silently own both writers' data.
  Observed input: `plan:115` expressly leaves sections "as placeholders for the agent", while the shipped contract requires verbatim attributed unchecked carry-overs in the issue (`skills/2-daily/merge-cleanup/SKILL.md:352-355`). Those caller-written bytes have no field in the proposed record (`plan:104-106`) from which full-body rendering could restore them.
  Affected scope: updates to an existing batch issue after the agent has filled any caller-owned section.
  Falsifier: place `- [ ] #PR: operator verification` in Post-deployment carry-overs before a resume/verdict update; expect that exact line and the existing Findings/Problems text to survive while the script's outcome/verdict changes. Initial creation may still render placeholders.

- [Should] **R6 — Make the sweep range include the first landing (DoD 6).** `plan:124` says `first..last merge oid`; as a Git range this omits the first commit, and a qualifying queue with one landing produces an empty range. Record the first landing's first parent through the last landing (`first^..last`), or an equivalent explicit pre-batch base, and derive the range from all retained batch landings on resume. The qualification helper already uses each landing's parent (`utils/py/wave_reconcile.py:603`), so keep that inclusive interpretation consistent.
  Observed input: the one-landed/one-handed-off scenario at `test/gh534_phase_b_tests.py:552-553` gives `first == last`, making the proposed range `M..M` empty despite a real landing.
  Affected scope: the printed/stored merged-range input for the agent's regression review.
  Falsifier: for that scenario, the recorded range must include PR 1's diff; for two distinct landings it must include both. A zero-landed run should report no sweep range, not fabricate one.

- [Nit] **Recon wording:** `plan:55-56` says overlap filenames survive in warnings and `main` discards warnings. The warning contains only the overlap **count** (`scripts/toposort_prs.py:147-148`) and `main` prints it (`scripts/merge_cleanup.py:1388-1391`). Fix those two claims; adding `_soft_reasons` remains justified because actual filenames currently require recomputing the intersection.

- [Pass] **DoD 1/2, bounded positive:** the cited `main`, `land_prs`, sorting and merge-call line numbers are accurate (`scripts/merge_cleanup.py:1230`, `:902`, `:1378`, `:1162`); `execute_pr_merge` returns bool (`:191`, `:225-227`). Creating a fresh qualifying issue before the `land_prs` loop (`:928`) precedes every merge even when the first PR defers/skips. Resume qualification is the R2 exception.
- [Pass] **DoD 3:** a small `batch_record.py` has a distinct responsibility worth separating from the per-PR repair budget. `attempt_record.load` deliberately requires `pr` and `attempts` (`scripts/attempt_record.py:112`), so do not feed batch JSON into that loader. Reusing its `RecordLock` and schema-neutral atomic `save` (`:61`, `:117-122`) avoids a second persistence mechanism; correct the GitHub helper wiring per R1. `select_qualification_gate` returns `(gate, expected, reason)`, not an integer tier (`utils/py/wave_reconcile.py:596-597`, `:614-618`); use that existing return contract with full fallback.
- [Pass] **DoD 4/5, design only:** 2 > 3 > 4 > 0 is reasonable once R3 covers the whole driver. Adding text preserves the existing Drive-loop phrase checks (`test/gh534_phase_c_tests.py:897-905`). GH-831 forbids new suites/registry/gate machinery and permits keeping an existing suite truthful (`AGENTS.md:154-162`); the existing parity guard requires callable methods for script-owned rows (`test/gh534_phase_c_tests.py:592-596`). Limited additions to these same files are consistent with that contract, but update existing expectations too. The threshold and empty-body red controls are falsifiable (`plan:160-161`); retain their commands, outcomes and committed `provenance.jsonl` with the stated evidence destination. The full route is supported by `utils/ci-route.sh:333-337`.
- [Unverified — needs clone run] No suite or red control was executed here, as required by this review envelope. Final evidence must come from the disposable full clone, including the changed two-PR expectations and R2–R6 countercases; reuse existing methods or retained manual checks rather than adding suites or gates.
- [Unverified — source unavailable] **DoD 6:** the three operator decisions and non-goals are explicit (`plan:24-30`, `:89-95`), and the findings above cover their gaps against the shipped GH-944 contract. Live issue-body comparison was unavailable: `gh issue view 1064 --repo HiQS-Labs/XYZ-forge --json body,title` exited 1 with `error connecting to api.github.com`; opening `https://github.com/HiQS-Labs/XYZ-forge/issues/1064` also returned `Failed to fetch ... Cache miss`. Do not treat this as confirmation of the unseen live body.
- [Pass] **DoD 7:** the sweep found the pre-existing incomplete outcome bookkeeping relevant to this plan (R4) and the nonzero Phase-5 dispatch that makes a direct exit-4 insertion wrong (R3), both with exact source citations above. No additional pre-existing defect was identified in the other inspected paths that changes this plan's design.

Root cause: the plan treats a single loop invocation and its `failed` map as the complete batch lifecycle; fix site: batch hooks plus the existing driver dispatch/body-update boundaries; why not elsewhere: sequencing, repair eligibility, suites, and teardown policy already have owners and need no parallel mechanism.

Handing off to Producer (claude-a) — disposition R1–R6 and the recon nit, revise the plan, then request the next Reviewer turn.

### Producer · Round 2 · claude-a

Each finding was checked against the cited source. All of them hold and are in scope.

- **R1 — Implemented.** The recon now names `merge_cleanup._gh` (:70) and `scan_clones._gh_bin`.
  `batch_record` takes an injected `gh` callable and never imports the driver (plan step 2).
- **R2 — Implemented.** In `main`, `--resume` looks up the unfinished batch before any size test, so
  a queue of 1 or 0 continues the original batch. "Unfinished" now means non-terminal planned PRs,
  **or** a landed set that differs from `verdict.covers`, so a partial verdict no longer ends the
  batch. Fresh single-PR runs are unchanged. Test (b) is the falsifier, extending the existing
  :543 handoff scenario.
- **R3 — Implemented.** `land_prs` keeps returning 0/2/3. `main` keeps its early return for 2/3,
  runs Phase 6, and only then returns 4 when the only thing missing is a verdict; a Phase 6 failure
  still wins as 2. `--record-sweep` is dispatched after primary resolution, before Phase 0. The
  existing exit-0 expectations at phase_b:379/388 and phase_c:282 move to 4 and keep their pruning
  assertions. The QA-only continuation and the drive loop after a verdict are documented.
- **R4 — Implemented.** The remote merge is recorded immediately after `execute_pr_merge` returns
  true, before fetch/ff/reconcile, with reconcile status recorded separately. Hold-label, not-open
  and draft skips get named statuses. A `try/finally` finalizes the sweep inputs and updates the
  issue on any return. Test (c) reuses the :510 and :491 scenarios.
- **R5 — Implemented.** The script owns only a marked block. `update` reads the live body and
  replaces just that block. A failed read or missing markers means no edit, and `issue_error` is
  recorded. Test (d) is your falsifier, plus a red control for whole-body overwrite.
- **R6 — Implemented.** The range is `<first landing>^1..<last landing>`, taken over all retained
  landings; there is no range when nothing landed. Test (b) asserts the one-landed-then-resumed case.
- **Nit — Implemented.** The recon now says the warning carries only the overlap count, which
  `main` prints.
- **Pass notes taken:** batch JSON never goes through `attempt_record.load`, and the
  `(gate, expected, reason)` contract from `select_qualification_gate` is used with a full-gate fallback.

Handing off to Reviewer (codex) for round 2: please re-check R1–R6 against the revised plan steps 2–5.

### Reviewer · Round 2

VERDICT: FAIL
Basis: R1, R5 and R6 are addressed at plan level. R2–R4 still have concrete lifecycle gaps, and the resumed sweep needs retained file metadata. Correct these bounded plan contracts before implementation; no new runner or guard is needed.
swept file: yes

Scope/evidence: Re-read the entire revised plan and the complete driver, sorter, attempt-record module and gh534 Phase B/C files; inspected the scanner helper ownership, SKILL.md contracts, harness-tool lookup, qualification selector and orchestration callers. Graph tools (including project/generation and coverage tools) are unavailable in this turn's tool inventory, so this is source-based verification, with no new graph/freshness claim. No git commands, suites, executable fixtures or artifact edits were run. `plan` means `PROJECT/1-INBOX/GH-1064-MERGE-BATCH-ISSUE-QA.md`; `scripts/` means `skills/2-daily/merge-cleanup/scripts/`.

- [Should] **R2 follow-up — Specify empty-queue lookup and the no-record fallback (DoD 2/4/6).** `plan:123-124` still requires overlap with `prs`, while `plan:142-145,171-172` promises continuation with zero discovered PRs. No record overlaps an empty set. Also the exclusive `with --resume ... otherwise ... create` branches omit creation when resume finds no batch: `--resume` already works from per-PR attempt records that predate any batch record. Specify lookup by repo/integration when the discovered queue is empty, and apply the fresh 2+ threshold when no matching batch exists. Keep an actual continuation on its original issue.
  Observed input: OPEN-only discovery (`scripts/toposort_prs.py:34`) after the two successful landings at `test/gh534_phase_b_tests.py:381` yields `prs=[]`, so the overlap predicate cannot select the QA-pending record. Separately, `test/gh534_phase_c_tests.py:793-805` starts with two OPEN PRs, an existing per-PR repair record and `--resume`, but no batch record; both land. Under the proposed exclusive branches that run creates no issue.
  Affected scope: QA-only resume of a completed landing set, and executing 2+ PR resume runs without a prior batch record; ordinary fresh one-PR runs remain exempt.
  Falsifier: in the existing suite or a retained manual clone check, finish two landings, resume with an empty discovery result and expect the same issue plus exit 4 until a verdict is recorded. Run the existing `:793` case without a batch record and expect one issue before either merge, then exit 4. A one-PR no-record resume must create none.

- [Should] **R3 follow-up — QA pending must not require every planned PR to be terminal (DoD 4/5/6).** `plan:168` returns 4 only when a verdict is the *only* unfinished condition, but held and draft PRs remain non-terminal under `plan:120-121`, and those skips deliberately leave `land_prs` returning 0. A landed subset can therefore still report 0 without QA. After the existing 2/3 and Phase-6 failure handling, return 4 whenever the batch has landings not covered by its verdict, independently of whether other planned PRs remain open. Keep the separate non-terminal predicate for continuation. Update all affected existing expectations, not only the three references listed in the plan.
  Observed input: `test/gh534_phase_b_tests.py:491-498` supplies two PRs, holds PR 1 and lands PR 2, expecting 0 today. The hold branch never adds a failure (`scripts/merge_cleanup.py:973-976`), so Phase 5 returns 0, but the planned batch remains unfinished for both the held PR and the missing verdict. Drafts have the same shape (`:1194-1207`). Additional two-landing exit-0 assertions exist at `test/gh534_phase_b_tests.py:693` and `test/gh534_phase_c_tests.py:451,803`.
  Affected scope: qualifying batches with at least one landing and no covering verdict, including expected skips; exit 2/3 precedence and zero-landing behavior stay unchanged.
  Falsifier: reuse the held-PR case, assert Phase 6 still runs, the hold outcome remains recorded and the final result is 4. Record a verdict for that landed subset: QA is covered, but the held PR remains available for later continuation. A new landing must invalidate coverage again. A Phase-6 failure must still return 2.

- [Should] **R4 follow-up — Record pre-merge stops as stops (DoD 1/6/7).** The remote-merge/reconcile split is now correct, but `plan:147-156` enumerates skip branches and `failed[N]` entries without covering hard returns before a merge. `finally` persists the record; it cannot infer which unrecorded PR was attempted and stopped. Name the stopping PR and diagnostic at these returns, leaving later PRs unattempted. This is the outcome hook requested in R4, not a repair-policy change.
  Observed input: `test/gh534_phase_b_tests.py:674` injects `green=False, failures=["releases check: FAIL: rule=synthetic"]`. `scripts/merge_cleanup.py:1137-1142` returns 2 without writing `failed[p_num]`; the new hooks as enumerated record neither a skip nor a merge nor that failure. The same shape exists for unknown mergeability at `:997-999`.
  Affected scope: existing exit-2 branches reached while processing a planned PR before remote merge; subsequent planned PRs retain an unattempted status.
  Falsifier: reuse that existing gate-red case in a qualifying two-PR queue; expect the first PR's stopped status and exact gate reason in the local/issue record, the second PR unattempted, no merge and exit 2. An ordinary handoff remains exit 3 with its existing outcome.

- [Should] **R7 — Retain the file lists needed by resumed sweep inputs (DoD 1/3/6).** `plan:160` computes cross-PR shared files from planned PR file lists, but the durable `planned` schema at `plan:117-119` retains only hard dependencies and soft-edge reasons, not those lists. Soft reasons are insufficient for explicitly dependent PRs: the sorter deliberately adds no soft edge where a direct dependency already exists (`scripts/toposort_prs.py:126-129`). Persist normalized per-PR file lists (or explicitly fetch missing merged-PR lists on continuation) so finalization over all retained landings has its stated inputs.
  Observed input: the sorter accepts PR 1 with `files=[{"path":"shared.txt"}]` and PR 2 with the same files plus `body="Depends on #1"` (`scripts/toposort_prs.py:52-70,101-104,126-129`; the same file/dependency input shapes are used at `test/gh534_phase_c_tests.py:646-648`). The resulting hard edge has no soft reason. Once PR 1 lands and PR 2 hands off, OPEN-only rediscovery supplies only PR 2; the proposed record has lost PR 1's file list. Its partial sweep contained only one landing and therefore no shared-file result to preserve.
  Affected scope: sweep recomputation after a batch continues across processes, especially shared files on hard dependency pairs; ordering and merge eligibility are unchanged.
  Falsifier: retain that pair through a one-landed/one-handoff run and a later successful resume; expect `shared.txt` in the final sweep inputs with both PRs attributed. A file touched by only one landed PR must not appear as cross-PR overlap. Use existing suite coverage or retained manual evidence.

- [Pass] **DoD 1/2, bounded recon:** the corrected helper ownership and warning wording match `scripts/merge_cleanup.py:70,315,1388-1391`, `scripts/scan_clones.py:373` and `scripts/toposort_prs.py:147-148`. `execute_pr_merge` still returns bool after observing MERGED plus an OID (`scripts/merge_cleanup.py:215-227`). Fresh-batch creation before the loop precedes skipped/deferred entries as well as the first merge (`:928,962-979,1162`); R2 above covers the remaining selection gap.
- [Pass] **DoD 3 / R1:** injection avoids importing the driver into its own dependency (`plan:113-116`); batch records have a distinct responsibility from `attempt_record.load`'s required `pr/attempts` keys (`scripts/attempt_record.py:112`). Reusing `RecordLock` and atomic `save` (`:61-89,117-122`) is appropriate. The existing tool resolver supports both native and vendored paths (`scripts/ledger_merge.py:263-273`), and the selector's `(gate, expected, reason)` plus full fallback is accurately specified (`utils/py/wave_reconcile.py:593-618`). No parallel persistence, gh wrapper or gate runner is required.
- [Pass] **R3/R5/R6, addressed portions:** keeping Phase-5 rc at 0/2/3 lets ordinary successful cleanup reach Phase 6 before computing exit 4 (`plan:166-170`; `scripts/merge_cleanup.py:1443-1459,1492-1497`). Standalone verdict dispatch before Phase 0 avoids merge/teardown (`plan:173-179`). Marked-block replacement with no edit on failed reads/missing markers protects caller sections (`plan:128-137,212-215`), and `<first>^1..<last>` includes a one-landing batch (`plan:159`; compare `utils/py/wave_reconcile.py:603`). These are plan-level conclusions, not runtime passes.
- [Pass] **DoD 5:** the bounded existing-file verification and three explicit red controls (`plan:193-221`) fit `AGENTS.md:154-162`. The parity guard requires an actual callable in the Phase C module's globals (`test/gh534_phase_c_tests.py:592-596`); ensure any Phase B class named by a script row is also imported there, following the existing import pattern at `:34`. Adding exit-4 prose can preserve the pinned phrases at `:897-905`. No new suite, registry entry or gate machinery is planned.
- [Unverified — needs clone run] **DoD 4/5:** no suite or red control was executed in this reviewer worktree. The final clone run must cover the four findings and existing affected callers/assertions; source inspection does not establish runtime success. Retain commands, exit statuses, decisive output and committed provenance as specified at `plan:217-223`.
- [Unverified — source unavailable] **DoD 6:** the operator-scoped ownership split, exit 4 and threshold 2 are explicit at `plan:24-30`, and carry-overs remain caller-owned (`plan:103-104,185-192`; SKILL.md:352-357). The live issue body remains unavailable: `gh issue view 1064 --repo HiQS-Labs/XYZ-forge --json body,title` exited 1 with `error connecting to api.github.com`; opening `https://github.com/HiQS-Labs/XYZ-forge/issues/1064` returned `Failed to fetch ... Cache miss`. No claim of full comparison with unseen issue text is made.
- [Unverified — no citation] **DoD 7, bounded sweep:** the relevant pre-existing behaviors remain the non-failure hold/draft skips, early hard-stop returns and OPEN-only discovery, cited above. They make the proposed batch predicates/hooks incomplete. No additional pre-existing defect requiring a different architecture was identified in the other inspected paths. The four corrections extend the proposed batch lifecycle and existing orchestration rather than changing ordering, eligibility or teardown policy.

Handing off to Producer (claude-a) — disposition the R2–R4 follow-ups and R7, revise the plan, then request Reviewer round 3. The harness owns the relay-file commit; no git command was run by this reviewer.

### Producer · Round 3 · claude-a

All four findings hold against the cited source and are in scope. All are implemented in plan steps 2, 3 and 5.

- **R2 follow-up — Implemented.** With an empty queue, `find_unfinished` matches on repo +
  integration; with a non-empty queue it requires overlap. Selection no longer stops at the
  `--resume` branch: when no batch is found and an executing queue has 2+ PRs, `create` runs. That
  covers the :793-805 resume with no batch record. Single-PR runs with no record stay exempt. Test (e)
  and step 4 of test (b) are the falsifiers.
- **R3 follow-up — Implemented.** The two predicates are now separate. `qa_pending` (landings ≠
  `verdict.covers`) alone decides exit 4, whatever the state of held, draft, handed-off or
  unattempted rows; `continuable` only drives resume. The held-PR case (:491) now expects 4. Every
  existing 2+ queue, 1+ landing exit-0 assertion moves to 4, keeping its pruning asserts: the sites
  you listed (phase_b :379/388/:491/:693, phase_c :282/:451/:803) plus a grep sweep of both files
  during implementation. A Phase 6 failure stays 2.
- **R4 follow-up — Implemented.** Every in-loop `return 2` records `stopped: <diagnostic>` through a
  local `_stop` first: unknown mergeability :997-999, gate red :1137-1142, plus the other in-loop
  returns, confirmed by grep. Planned rows default to `unattempted`. Test (c) uses the :674
  gate-red injection in a 2-PR queue and expects the exact reason, PR 2 unattempted, no merge,
  exit 2; an ordinary handoff stays 3.
- **R7 — Implemented.** Each planned row keeps its normalized `files` list, and shared files are
  computed from the stored lists of all retained landings, attributed per PR. Test (b) is your
  hard-dependency `shared.txt` pair through a handoff and a resume; a file touched by only one PR is
  never listed as shared.
- **Parity note taken:** `TestBatchIssue` is imported into phase_c's globals following the :34 pattern.

This is round 3 of 3. Handing off to Reviewer (codex) for the final plan review.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
