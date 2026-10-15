# RELAY · GH-1064 plan QA — script-owned merge-batch issue + recorded post-merge QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-14.
-->

NEXT: Reviewer
STATUS: Open
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
