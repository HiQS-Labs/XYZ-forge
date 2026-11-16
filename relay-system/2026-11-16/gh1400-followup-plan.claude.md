# RELAY · GH1400 follow-up plan QA (task-local failure continuation)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-16.
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
6. **Commit only the relay file** (`relay(gh1400-follow-up-plan-qa-task-local-failure-continuation): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1400-SUPERVISION-COMPOSITION.md`, section
  "Follow-up — task-local failure continuation (2026-11-16)" (the plan; no code changed yet).
- Reviewer: claude   ·   Producer: claude-a
- Started: 2026-11-16
- Definition of Done: the plan, if built as written, satisfies the five operator acceptance items
  below with falsifiable controls on the real `releases_app.py jog run` entrypoint, extends the
  existing owner without new machinery, and states unproven scope truthfully.

## Review packet — read in this order

First read only the follow-up section of the plan doc. Before reading source or the requirements
below, write 2–5 sentences each under **What this proposes** and **How the existing system works,
per this document**, plus a short **What it's not**. Record that input boundary; label inference.
Then validate against source: `utils/py/jog_run.py` (`run_marathon_phase` ~603-736,
`jog_project_marathon_outcome` ~393-444, `JogSupervisorLock` ~1524, `JogCheckpoint` ~2130-2450,
`_jog_align_target` ~2518, `_jog_supervise_recover` ~2554, `jog_run_main` ~2609-2972),
`MACHINE-CONTRACTS.md` Contract B (closed outcome vocabulary), `utils/py/marathon_drive.py`
(`write_terminal_result` ~204), `TESTS-RESULTS/2026-11-15+GH-1400/check.py` (fixture reused),
`AGENTS.md` (*No new tests*, GH-831; disposable full clone rule).

Operator acceptance (verbatim intent): (1) a provably task-local known terminal failure persists
reason/receipts/budgets, no auto-retry/re-entry, and an independent READY B dispatches in the same
invocation without parent restart; (2) dependent/held tasks not selected, and max-tasks/deadline
counts not reset; (3) saved valid approved result then supervisor interrupted BEFORE
ack/checkpoint publication: restart validates/adopts exactly once without builder, budgets
retained; inconsistent/missing receipt HOLDS rather than rebuild; (4) a shared unsafe condition
(live or SIGSTOPped ownership conflict, checkpoint contradiction) stops all dispatch, B stays
undispatched; safe classification fails closed; a task failure never licenses skipping global
unsafe state; (5) red controls prove the unfixed baseline fails local continuation and
corrupt/missing receipt/refused ownership cannot look like a pass; synthetic workers only; no
duplicate workers, no unknown-outcome retry, immutable runtime identity per control. Readiness may
not rest on direct function calls that bypass the entrypoint. Scope is supervised real Marathon;
legacy drive behaviour must not be blindly broadened.

Evidence: dogfood wake 1 stopped at GH-1023 whose receipt (local, not in repo) was
`outcome: escalated, reason: pre-advance-failed, exit_code: 5, gate.result: red, pr: null`.

Questions:
1. Is the task-local classification grounded in the actual `failed` paths of `run_marathon_phase`
   and the closed outcome set, and is it fail-closed? Name any `failed` path that would wrongly
   continue, or a task-local one wrongly stopped that the operator's item (1) requires.
2. After a task-local continuation, does every shared-safety check still run before B's dispatch
   (lock/SIGSTOP owner, tracked dirt, detached HEAD, worktrees, ledger change)? Cite lines.
3. Are max-tasks and deadline truly not reset, and is the failed row never reselected/retried?
4. Do the planned controls detect the real defect (baseline red) and would each fail on an unfixed
   or wrongly-fixed candidate (e.g. a blanket `break`→`continue`)? Which control catches that?
5. Is the restart control (worker SIGKILLs the supervisor after writing its receipt) a faithful
   "interrupted before acknowledgement/checkpoint publication" case on the existing recovery path?
6. Is the scope commensurate (one helper + one branch, docs, manual receipts; no new suite)?

Do not run suites or modify source. Only this relay file is writable. Grade the bounded local
operator-CLI envelope; no enterprise fault model or speculative tests. A behaviour-change finding
needs `Observed input:`, `Affected scope:`, `Falsifier:`. Approval is plan approval, not runtime proof.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

**What this proposes** (from the follow-up section only, read before source or the packet's acceptance list): one new helper plus one branch in the supervised loop of `jog_run_main`, so that when a Marathon run ends `failed` AND durable state proves the failure was this task's own (newest execution `projected-failed`, receipt valid and identity-matched, outcome `escalated`, gate `red`), the wake prints the retained failure and continues to the next pending row instead of `break`. Every other failure shape still stops. Seven manual controls under `TESTS-RESULTS/2026-11-16+GH-1400/` drive the real `releases_app.py jog run` entrypoint; docs and CHANGELOG are updated.

**How the existing system works, per this document**: `run_marathon_phase` returns `failed` in three situations (valid non-approved receipt, no valid receipt, clone ledger changed). `jog_set_status` persists the failed row plus reason and receipt path before the loop decides anything, so the row is never reselected. `tasks_processed` is counted at lease and the deadline is checked at the top of each iteration, so neither budget resets. The next iteration re-runs `_jog_align_target` (conservative lock, tracked dirt, detached HEAD, worktrees) and `_validate_execution_target` (ledger changes). Restart and global-stop reuse `_jog_supervise_recover`, `JogCheckpoint.begin(recover=…)` and `JogSupervisorLock`, with no new code unless a control fails.

**What it's not**: no new ledger/status/flag/queue/daemon/retry/suite, no change to legacy drive, recovery, checkpoint publication, preflight or Marathon, and no claim about real providers, gate-environment classification, power loss, or PID reuse. Input boundary: everything above came from lines 266-355 of the plan doc; the validation below is from source and is labelled where it is inference.

swept file: yes. Scope of the sweep: `run_marathon_phase`, `jog_project_marathon_outcome`, `JogSupervisorLock`, `JogCheckpoint`, `_jog_align_target`, `_jog_supervise_recover` and the whole supervised branch of `jog_run_main`, plus the producer side (`marathon_drive.py` `_result_outcome`, `escalate`, the gate runners). I read those regions in full, not all ~2,980 lines. Pre-existing defects found in them: none that this plan makes worse. One behaviour is worth pinning in a control (finding 5).

Findings:

- **[Blocker] The classifier treats a resource-guard kill (`gate-killed`) as task-local.** The plan's rule is outcome `escalated` + gate `red` + valid matching receipt. A guard-killed gate meets all of it. `marathon_drive.py:2510/2526` set `rc = GATE_GUARD_KILL_EXIT` (108). `:2458` and `:2572` then record `gate_result = "red"` for any `rc != 0`. `:2816-2819` calls `escalate("gate-killed", 0)` and `sys.exit(5)`. `:2318` stores the reason. So the receipt is `outcome: escalated, reason: gate-killed, exit_code: 5, gate.result: red`. The code's own comment at `:2812-2815` says a guard-killed gate "is a different event from a gate that ran and found a defect." The guard caps host RSS, wall time and CPU, which is the shared-machine condition operator item (4) says a task failure must never license skipping. The plan calls this "provably task-local", and its Limit paragraph concedes only an environment defect that cannot be told apart from a task defect. Here a distinguishing token exists, so the plan is not fail-closed for this input. The GH-1023 evidence receipt (`pre-advance-failed`, exit 5, gate red) is the shape the operator asked to continue.
  Observed input: receipt `{outcome: escalated, reason: gate-killed, exit_code: 5, gate: {result: red, exit: 108}}`, produced by the path cited above.
  Affected scope: receipts with outcome `escalated`, gate `red`, and `reason != "pre-advance-failed"`.
  Falsifier: add the `reason == "pre-advance-failed"` condition (`exit_code == 5` optional). Run the `gate-killed` fixture and expect a stop with B undispatched. Run the GH-1023-shaped fixture and expect continuation with B dispatched once. If `gate-killed` can be shown never to occur on this path, the extra clause is harmless and the finding is withdrawn.
  Fix: add the clause to the classification text and the helper. Add `gate-killed` to control 4's fail-closed red list. This is a narrowing of the plan, so it adds no machinery.

- **[Should] Control 4's red list would not catch an over-broad classifier that keys on gate `red` alone.** A blanket `break`→`continue` is caught, since every listed case must stop and B must stay undispatched. A classifier keyed on `red` only is not caught, because the only red-but-stop case is the missing `gate-killed` one. The list also omits `post-approve-failed` (`approval_preserved: true`, exit 9), `refused` (exit 2), `interrupted`, a missing receipt (`no-valid-result`) and `clone-ledger-changed`. Each of these is `failed` under `run_marathon_phase` (`:703-715`) or `jog_project_marathon_outcome` (`:441-444`), and a table-driven loop over receipts costs little in the existing fixture.
  Observed input: control 4 text, "receipts `lock-contention`, `crashed`, escalation with gate not red, corrupt receipt and mismatched execution id".
  Affected scope: the control list only. No code behaviour changes.
  Falsifier: a candidate classifier that continues on `red` alone, or on `post-approve-failed`, passes the current list and fails the extended one.

- **[Should] "Immutable runtime identity per control" is only partly bound.** Operator item (5) asks for it, and the plan says "each record carries the source HEAD" (`:329`). A HEAD alone does not say the code run was that commit's `jog_run.py`. Each control should record `git status --porcelain` for tracked files in the runtime tree (expected empty) and re-check HEAD at the end. `baseline-red` needs the same for the `1d9658c3c` tree. `check.py:7` already requires a `-verify` clone name, which fits this.
  Observed input: plan line 329 only.
  Affected scope: the control records.
  Falsifier: a control run with an uncommitted edit to `jog_run.py` should refuse. Under the current text it would record a HEAD and pass.

- **[Should] Control 2 does not say how the preflight-refused dependent D is reached.** With `--max-tasks 2`, A and B consume the budget before D is ever selected. If D sits ahead of B, preflight refusal parks D and the wake halts (`:2870-2893`, unchanged), so B is not dispatched and the "A and B dispatched" assertion cannot hold in the same wake. Say whether D is a second wake or a position after B, and state the expected rows.
  Observed input: plan control 2 as written.
  Affected scope: control design only.
  Falsifier: run the fixture with D at position 2. B is undispatched and the stated assertion fails.

- **[Should] Pin B's expected behaviour in `restart-missing` and `restart-corrupt`.** After `_jog_supervise_recover` parks A (`:2602-2604`, "supervision held") it returns normally, so the main loop at `:2780` goes on to lease the next pending row. B will therefore be dispatched in that same invocation. That matches the operator's "HOLDS rather than rebuild" for A, but the plan says only "hold A, never rebuild". State the expectation (A parked, zero builder starts for A, B dispatched once, or the opposite if you intend a stop), so the control cannot pass vacuously.
  Observed input: `jog_run.py:2602-2604` plus the loop at `:2780`.
  Affected scope: the two variants.
  Falsifier: run the variant and compare B's start count with the stated expectation.

- **[Nit] Restart control hygiene.** (a) The worker SIGKILLs its parent, so the worker can outlive the supervisor. The control should wait for it to exit before restarting and assert no orphan process, otherwise "no duplicate worker" is confounded. (b) The stop-owner exit goes through `sys.exit(4)` in `JogSupervisorLock.acquire` (`jog_run.py:1563`), which skips `checkpoint.finish()`. A's failed row then sits unpublished with the journal at phase `running`; the next wake's `begin()` publishes it through recovery. Assert that, or a "stopped" wake can leave a failure unpublished unnoticed. (c) `baseline-red` should assert it is red for the right reason: A `failed`, B still `pending`, and the output line `stopping queue execution on task failure` (`:2888`).

- **[Should] State what clone state the failed lane leaves, and test one dirty variant.** The next iteration calls `_jog_align_target`, which refuses tracked changes and a detached HEAD (`:2524-2529`) with a `ContractError`. If a real gate-red escalation commonly leaves uncommitted tracked edits, item (1) will usually end in a hold, not a dispatch, and a synthetic worker that leaves the clone tidy will not show it. This is not a defect: it fails closed. The plan should say which state control 1 leaves, add one variant with tracked dirt (expect hold with B undispatched and a clear message), and add "clone state after a real red gate" to its Unproven list.
  Observed input: none from a real run. The wake-1 receipt is local and not in the repo, so this cannot be shown as failing today.
  Affected scope: `_jog_align_target` after a failed lane.
  Falsifier: the dirty variant stops as stated. If real escalations always leave the clone clean, the variant is a documentation-only control.

- **[Pass] Q1, classification groundedness.** `run_marathon_phase` sets `record["status"]="no-valid-result"` at `jog_run.py:708` and `"clone-ledger-changed"` at `:713` before returning `failed`, and neither sets `record["outcome"]` (only the terminal path does, at `:725-727`). So a `projected-failed` status AND an `escalated` outcome can only come from a valid terminal receipt. That excludes categories (b) and (c) structurally. `jog_project_marathon_outcome` returns `failed` for every non-approved, non-parked outcome (`:441-444`), and the closed set is in `MACHINE-CONTRACTS.md:75-82`. The plan's exclusion list (lock-contention, refused, crashed, interrupted, post-approve-failed) matches `_result_outcome` at `marathon_drive.py:106-124` and the crashed override at `:274`. Gap: only the blocker above.

- **[Pass] Q2, shared checks before B.** With `continue`, the loop returns to `:2780`. Deadline and max-tasks are checked first (`:2781-2786`), then the pending query (`:2793-2799`), then `_jog_align_target(target)` and `_validate_execution_target(root, target)` before `jog_acquire_lease` (`:2808-2810`, `:2829`). `_jog_align_target` takes the conservative lock (`:2519`). `JogSupervisorLock.acquire` exits 4 on a live or stopped holder and raises on an unknown one (`:1533-1563`, with `os.kill(pid, 0)` true for a stopped pid). B is never leased on a stop. Checkpoint contradiction is caught at `begin()`, before any dispatch (`:2211-2232`). It is not re-checked between A and B. That is the same as the existing parked-published continuation at `:2870-2886`, and `finish()` catches it afterwards (`:2245-2266`), so I treat this as pre-existing and unchanged. It is not a finding, but the plan should not read as if mid-wake checkpoint contradiction is covered.

- **[Pass] Q3, budgets and no retry.** `tasks_processed += 1` at lease (`jog_run.py:2830-2831`), and the loop never decrements it. The next-row query is `status = 'pending'` only (`:2796`). `jog_set_status(root, gh_num, action, failure_reason=reason)` runs at `:2865` before any classification, so a helper placed after it reads a row already persisted as `failed`. Unsupervised and checkpoint-only runs keep the existing `break`. The plan's `--max-tasks 2` expectation (A and B run, C not) matches the arithmetic.

- **[Pass] Q5, restart control faithfulness.** A worker that writes an approved receipt and then SIGKILLs its parent leaves the exact state `_jog_supervise_recover` handles: a `running` row with a dead lease pid, an execution record still `dispatched` with `result_path` persisted pre-dispatch (`:683-686`), and the journal at phase `running`. Restart takes the stale supervisor lock (`:1566-1575`), `begin()` calls `recover()` (`:2211-2232`), the receipt validates, and `jog_resume` runs with "without a new builder or attempt" (`:2594-2601`). No builder starts in that path. This is a faithful "before ack/checkpoint publication" case on the existing recovery path. The missing and corrupt variants reach the hold at `:2602-2604`. Subject to the nit on orphan workers and the should on B's expectation.

- **[Pass] Q6, scope.** One helper and one branch in `jog_run.py`, docs and CHANGELOG, manual controls under `TESTS-RESULTS/`, and the existing integration suite. That fits AGENTS.md *No new tests* (`AGENTS.md:162-168`). I found no existing test that pins the halting message or the supervised failure path (`rg` for the message returns only `jog_run.py:2888/2937`; `test/gh280-jog-marathon-adapter.sh` K1/G5 run unsupervised). The fixture reuse (`check.py`, "-verify" clone) is proportionate.

- **[Pass] Evidence and honesty.** The plan states what it did not prove (providers, gate-environment classification, power loss, context continuity, external exactly-once, PID reuse). Add the dirty-clone item from the Should above.

VERDICT: FAIL
Basis: the plan's central safety claim, that this classification is provably task-local and fail-closed, is wrong for one reachable receipt (`gate-killed`, gate `red`, exit 5). A one-clause narrowing (`reason == "pre-advance-failed"`) plus a table of extra fail-closed controls fixes it with no new machinery. Everything else is sound: the classification reads durable state, the shared checks do run before B, the budgets hold, and the restart control is faithful. The Should items tighten controls and add no code. After the Producer applies the narrowing and the control edits, I expect to approve in round 2. This is plan review only. Nothing was run, and runtime behaviour is unproven by design.

Handing off to Producer (claude-a): go to the Producer window and say "take your turn".

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
