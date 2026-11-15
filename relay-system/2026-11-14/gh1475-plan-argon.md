# RELAY · GH-1475 merge-cleanup remediation plan QA (Gemini 4 Argon High)
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
6. **Commit only the relay file** (`relay(gh1475-plan-argon): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **gh1475-plan-r0.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-11-14

### Artifact — gh1475-plan-r0.md
```
## Ask
Make `/merge-cleanup` batches fast enough and robust enough to run unattended, in three phases. Each failure mode from a real 13-PR batch maps to a fix below, or is marked out of scope for the script.

**Evidence:** a downstream consumer repo's 13-PR batch on 2026-11-14 took about 9.5 hours. About 6.5 hours of that is per-PR overhead even when nothing fails (dry-run pin, CI, full reconcile); failures added about 3–5 hours. Full post-mortem: https://github.com/BinoidCBD/LTVera-Pandas/issues/1095#issuecomment-6889598174 · batch record notes: BinoidCBD/LTVera-Pandas#1102 · stacked-lane test: BinoidCBD/LTVera-Pandas#1106.

Anchors are at `development` `e1085ff4+`: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, `scripts/batch_record.py`, `scripts/ledger_merge.py`, `utils/py/wave_reconcile.py`, `skills/2-daily/merge-cleanup/SKILL.md`.

## Phase 1 — quick wins (one PR)
Small, local and reversible. No change to merge or gate behaviour, except replacing the git pull.
- [ ] **P1.1 Fetch, then fast-forward, instead of `git pull` (F5).** At `wave_reconcile.py:304`, replace `git pull --ff-only origin <branch>` with `git fetch origin <branch>` followed by `git merge --ff-only FETCH_HEAD`. On a ref-lock or "multiple branches" error, retry with a short bounded backoff. `merge_cleanup.py` already uses fetch + `merge --ff-only`; reuse that pattern. *Check:* a concurrent `git fetch` in the primary no longer fails the reconcile. Red control: the old code fails under the same race.
- [ ] **P1.2 Flushed output (F12).** `merge_cleanup.py` sets line-buffered stdout and stderr at start-up, so a log file shows progress live. *Check:* `tail -f` on a redirected dry run shows Phase 0 within seconds.
- [ ] **P1.3 Delete the landing workdir on success (F1).** On a clean exit, remove the `merge-cleanup-*` workdir (`merge_cleanup.py:1629`, kept at `:2067`) and the `merge-check-*` clones (`:219`). Keep them on any non-zero exit, as now. *Check:* after a clean single-PR run, no new `merge-cleanup-*` folder remains; after a failed run, it does.
- [ ] **P1.4 `--reconcile-pr` updates the batch record (F8).** After a successful `--reconcile-pr N`, find the unfinished batch containing N (`batch_record.find_unfinished`) and record reconcile `ok` with `set_outcome`. `--record-sweep` should only suggest `--resume --execute` when a planned PR is still open. *Check:* recover a PR whose reconcile failed, and the batch no longer reports "Planned PRs remain".
- [ ] **P1.5 Exit-code contract in SKILL.md (F7).** Fix `SKILL.md:476`: a single-PR `--resume` run that attaches to an existing batch can exit 4. Add one table of exit codes for wrapper scripts: 0 done; 4 landed, QA pending (treat as landed); 3 deferred or handed off (retry or work the ladder); 5 landing-plan decision needed; 2 stop and diagnose.
- [ ] **P1.6 Read-only pre-flight warnings in the dry run (F1, F2, F6, F10).** One `PRE-FLIGHT` block:
  - free disk below a threshold (default 20 GB);
  - running on battery (`pmset -g batt` on macOS; silent elsewhere);
  - `TMPDIR` under a known per-turn harness directory;
  - no required status checks on the integration branch ("the script will not wait for CI");
  - another `merge_cleanup.py --execute` already running on this machine.

  Warnings only; nothing refuses. *Check:* each warning fires under its condition and stays silent otherwise.

## Phase 2 — next easiest wins
Behaviour changes with clear guards. Each can be its own PR.
- [ ] **P2.1 Re-pin after a B1 repair (F13).** When this run's own B1 repair produced the new head, its required or declared checks pass, and nothing else moved the head, re-pin and continue in the same run. This removes the second dry run and execute for every hub PR.
- [ ] **P2.2 Opt-in CI wait without branch protection (F6).** Add `.merge-cleanup.json` `qualification.wait_for_checks: ["<check name>", ...]`. The existing pending, poll and defer logic then applies to those named checks even when GitHub reports no required checks.
- [ ] **P2.3 Retained-clone pruning policy (F1).** Keep at most the last N failed-run workdirs (default 3) and prune older `merge-cleanup-*` and `merge-check-*` folders that belong to this tool and have no open handles.
- [ ] **P2.4 Heartbeat during long steps (F12, F10).** One line per 60 s during the reconcile, CI wait and forecast, so watchers and harness timeouts can tell slow from stuck.
- [ ] **P2.5 Stacked-lane detection at landing time (F4).** After landing a PR, list open members whose head contains the landed PR's original commits. Print a refresh instruction for each (merge the integration branch into it, then CI and a re-pin). If GitHub refuses one, classify it as "stacked-lane refusal", not a generic merge failure.
- [ ] **P2.6 Forecast: all members are ledger-only hubs means one PR per pass (#1470 follow-up).** Recommend `direct`, one PR per pass, not `group`, when every conflict is B1-repairable.
- [ ] **P2.7 Base-aware post-batch integrity check (unanticipated, #13).** Optional `--verify-landed`: for each landed PR, compare its own change (merge-base to head) with its squash commit by changed lines, and report a test count from the sweep, not an exit code alone.

## Phase 3 — riskier or more extensive (may be deferred)
- [ ] **P3.1 Reconcile stops appending to docs carried by open PRs (F4 root cause).** Only after the BinoidCBD/LTVera-Pandas#1106 test confirms the cause. Write merge evidence elsewhere, or after the doc moves to its completed folder.
- [ ] **P3.2 Automatic stacked-lane refresh (F4).** Merge the integration branch into the next stacked lane and push it, guarded by the same-repo, fast-forward-only and attempt-record rules. This writes to contributor branches, hence Phase 3.
- [ ] **P3.3 Changelog entries written at reconcile from the PR body (#1473).** Ledger writes only at landing (#1458). Together these remove most hub conflicts.
- [ ] **P3.4 Durable driver state file (F11).** One `.tick/merge-cleanup/<slug>/driver-state.md`, appended by the script, recording pins, decisions, recoveries and open hypotheses. A resuming session reads it first.
- [ ] **P3.5 Harness-safe launch (F10).** A `--detach` mode that re-executes under `nohup` with `TMPDIR=/tmp` and unbuffered output, writes its log path, and returns at once. This avoids harness command limits.
- [ ] **P3.6 Per-machine landing lock (unanticipated, #10).** Turn the P1.6 concurrency warning into a refusal, with an explicit override.

## Not fixable in the script (environment, policy or agent behaviour)
- **F2, power and sleep:** wall power and `caffeinate`. P1.6 warns.
- **F6, required checks:** repo branch protection is the consumer's decision. P1.6 warns and P2.2 offers an opt-in.
- **F9, model usage cap and session switches:** agent orchestration. Check quota before starting; no sub-agents during landing.
- **F14, unverified figures relayed:** agent discipline.
- **Out-of-tool state changes by agents:** agent discipline. P3.4 makes them visible.

## Failure-mode map
F1 → P1.3, P1.6, P2.3 · F2 → P1.6 · F3 → done (#1472), P2.6 · F4 → P2.5, P3.1, P3.2 · F5 → P1.1 · F6 → P1.6, P2.2 · F7 → P1.5 · F8 → P1.4 · F9 → out of scope · F10 → P1.6, P2.4, P3.5 · F11 → P3.4 · F12 → P1.2, P2.4 · F13 → P2.1 · F14 → out of scope

Relay QA of this plan (agy, Gemini 4 Argon High) follows in a comment.
```
- Definition of Done: the plan above is approvable when (a) every failure mode F1–F14 maps to a fix
  or to a justified "not script-fixable"; (b) Phase 1 is genuinely small, low-risk, local and
  independent of Phases 2–3; (c) each item sits in the right phase; (d) each acceptance check is
  falsifiable, with a red control (what an unchanged/unfixed tree shows); (e) nothing material is
  missing and nothing is over-engineered.

## Review packet (Producer: claude-a, 2026-11-14)

**Operational envelope.** `/merge-cleanup` is a local operator CLI (one Python driver plus helper
modules) run by one person or agent on one laptop to land a batch of PRs. Grade against that envelope
and commensurate complexity: no distributed locks, daemons, journaling layers or enterprise
fail-safes unless a cited failure needs them. XYZ-forge forbids new test suites (AGENTS.md *No new
tests*, GH-831); verification is existing suites plus manual checks recorded under `TESTS-RESULTS/`.
Do not ask for new tests. This turn is review-only: write only this relay file.

### Step 1 — paraphrase first (before reading anything below this line or any source file)
Using only the embedded artifact above, write under your review heading:
- **What this proposes** (2–5 sentences)
- **How the existing system works, per this document** (2–5 sentences)
- **What it's not** (short; distinguish excluded, deferred, unresolved and later-authorization items;
  label inference as inference)
State the input boundary you used ("artifact only").

### Step 2 — source-backed validation
Now read the evidence and validate. Label this part **Source-backed assessment**.
- Post-mortem (the failure modes F1–F14, verbatim source of the plan):
  https://github.com/BinoidCBD/LTVera-Pandas/issues/1095#issuecomment-6889598174 — if you cannot reach
  it, the plan's own F-list and this summary stand in: F1 disk filled (all landing/check clones kept);
  F2 laptop slept/lost power; F3 forecast over-advised `group` (fixed by #1472); F4 GitHub refused
  stacked lanes after squash (hypothesis pending); F5 `git pull --ff-only` raced a concurrent fetch in
  the primary (`cannot lock ref`, "Cannot fast-forward to multiple branches"); F6 no required checks,
  so the script never waits for CI; F7 wrapper stopped on exit 4, and SKILL.md says single-PR runs
  never exit 4; F8 `--reconcile-pr` recoveries do not update the batch record so `--record-sweep`
  says "Planned PRs remain"; F9 model usage cap; F10 harness killed runs / deleted per-turn TMPDIR;
  F11 no durable driver state; F12 buffered logs looked like a hang; F13 B1 repair invalidates its
  own pin so hub PRs take two cycles; F14 unverified figures relayed.
- Source files (repo-relative, at `origin/development` 5967bde25):
  - `utils/py/wave_reconcile.py:302-307` `pull_upstream` (`git pull --ff-only origin <branch>`), called
    once at `:2456`. This module is also vendored into consumer repos under `.xyz/`.
  - `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`: `_net_git`/`_retry_call` `:138-170`;
    `run_isolated_check` `:217-230` (creates `merge-check-*`, "retained"); landing workdir `:1629`
    with a `keep_workdir` flag set at `:1630` and to True on several failure paths (`:1744`…`:1879`)
    but never read — the `finally` at `:2063-2067` always logs "retained"; `--reconcile-pr` branch
    `:2348-2370` (no batch-record write); `record_sweep` `:2765-2787` ("Planned PRs remain" when
    `batch_record.continuable`); exit codes: 0, 2, 3, 4, `EXIT_LANDING_PLAN_REQUIRED = 5` (`:79`).
  - `skills/2-daily/merge-cleanup/scripts/batch_record.py`: `continuable` `:250-257` (a PR counts done
    only when `status == "merged"` and `reconcile == "ok"`, or closed); `find_unfinished` `:260-270`;
    `set_outcome` `:291-307`.
  - `skills/2-daily/merge-cleanup/SKILL.md:476` ("Single-PR runs are unchanged: no issue, no exit 4").

### Questions (answer each, cite file:line or the plan's own text)
1. Does every failure mode F1–F14 map to a fix or to a justified "not script-fixable"? Any F-row whose
   mapping is wrong, missing, or claims more than the item delivers?
2. Is Phase 1 genuinely small, low-risk and independent of Phases 2–3? Name any P1 item that hides a
   design decision or a behaviour change bigger than stated (e.g. P1.3 deleting folders; P1.4 writing
   batch state; P1.6's five probes — `gh` API call for required checks, process scan, `pmset`).
3. Are phase placements right? Anything in Phase 2/3 that is actually a quick win, or vice versa?
4. Are the acceptance checks falsifiable, each with a red control that the unchanged tree fails? Which
   checks are not observable as written (e.g. "a concurrent fetch no longer fails" — how is the race
   reproduced deterministically)?
5. What is missing, and what is over-engineered (apply YAGNI: is each P1.6 probe worth its code)?

Grade each finding `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]` per the turn rules, then a VERDICT.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer · agy

swept file: yes

#### Step 1 — Paraphrase (input boundary: artifact only, `gh1475-plan-r0.md` lines 60–113)
- **What this proposes:** A three-phase remediation plan for `/merge-cleanup` so multi-PR batches can run faster and unattended, mapping every failure mode (`F1`–`F14`, plus unanticipated items `#10` and `#13`) from a 9.5-hour 13-PR batch either to a phased fix or to an explicit out-of-scope category. Phase 1 bundles six local, reversible quick wins into one PR (`fetch` + `merge --ff-only` in `wave_reconcile.py`, line-buffered stdout/stderr, deleting `merge-cleanup-*` and `merge-check-*` folders on clean exit, updating the batch record after `--reconcile-pr`, fixing the exit-code contract in `SKILL.md`, and adding five non-blocking pre-flight dry-run warnings). Phase 2 introduces seven guarded behavioral improvements (each its own PR: in-run re-pin after B1 repair, opt-in `qualification.wait_for_checks`, retained-clone pruning keeping the last N=3 failed workdirs, 60s heartbeats, stacked-lane detection/classification, recommending `direct` one PR per pass instead of `group` when all members are B1-repairable ledger hubs, and optional `--verify-landed` post-batch integrity checks), while Phase 3 groups six riskier or more extensive changes that may be deferred.
- **How the existing system works, per this document:** `/merge-cleanup` is driven by `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` with `scripts/batch_record.py`, `scripts/ledger_merge.py`, `utils/py/wave_reconcile.py`, and `skills/2-daily/merge-cleanup/SKILL.md`, spending ~6.5h on per-PR overhead (dry-run pin, CI, full reconcile) and ~3–5h on failures in a 13-PR batch. Currently, `wave_reconcile.py:304` runs `git pull --ff-only origin <branch>` (whereas `merge_cleanup.py` already uses `fetch` + `merge --ff-only`), redirected output is buffered, and `merge_cleanup.py` retains `merge-cleanup-*` (`:1629`, `:2067`) and `merge-check-*` (`:219`) folders even on clean exits. In addition, `--reconcile-pr N` does not update the unfinished batch record (`batch_record.find_unfinished` / `set_outcome`), leaving `--record-sweep` reporting "Planned PRs remain", while `SKILL.md:476` misstates whether a single-PR `--resume` run attaching to an existing batch can exit 4. Finally, B1 repairs invalidate the dry-run pin (requiring a second dry-run and execute per hub PR), the script does not wait for CI when the integration branch has no required checks, and reconcile currently appends merge evidence to docs carried by open PRs and writes changelog/ledger updates that cause hub conflicts.
- **What it's not:**
  - *Excluded (not fixable in the script — environment, policy, or agent discipline):* `F2` power/sleep (`caffeinate` / wall power, beyond P1.6's warning), `F6` consumer branch-protection policy (beyond P1.6's warning and P2.2's opt-in), `F9` model usage caps and session switches / sub-agent orchestration, `F14` relaying unverified figures, and out-of-tool state changes by agents (beyond P3.4 visibility).
  - *Deferred (Phase 3 — explicitly marked "may be deferred"):* `P3.1`–`P3.6` (stopping reconcile appends to open-PR docs, automatic stacked-lane refresh pushing to contributor branches, writing changelog entries at reconcile from PR bodies paired with landing-only ledger writes, durable `.tick/merge-cleanup/<slug>/driver-state.md`, `--detach` under `nohup`, and turning the concurrency warning into a per-machine lock refusal).
  - *Unresolved (gated on external test evidence):* `P3.1` explicitly waits on `BinoidCBD/LTVera-Pandas#1106` confirming the root cause of `F4`.
  - *Later-authorization / separate-PR items (inference from phase headers "one PR" vs "Each can be its own PR" and "may be deferred", plus P3.2's note on writing to contributor branches):* Phase 2 (`P2.1`–`P2.7`) and Phase 3 (`P3.1`–`P3.6`) are separate PRs outside the Phase 1 PR, and `P3.2` is held for Phase 3 because it pushes to contributor branches.

#### Source-backed assessment

**Answers to the 5 review questions:**
1. **F1–F14 mapping completeness and accuracy:** Every failure mode `F1`–`F14` (plus `#10` and `#13`) maps to a plan item or a justified out-of-scope note (`gh1475-plan-r0.md:102-110`), and `F3` (`#1472`) is already landed in `skills/2-daily/merge-cleanup/scripts/ledger_merge.py:777-809, 905-936`. However, three mappings over-claim what the specified item actually delivers:
   - `F1 → P1.3` (`gh1475-plan-r0.md:72`): deleting `merge-check-*` (`merge_cleanup.py:219`) breaks existing pinned tests (`test/gh436-merge-cleanup.py:1084-1109`) and `SKILL.md:80`, while deleting `merge-cleanup-*` (`:1629`) only on a clean whole-run exit (`rc == 0`) leaves every landed PR's 2–3 clones (`pr-<N>-*` at `:789, 1864` and `verify-<sha>` at `:820`) on disk whenever *any* later PR in the batch defers (including every B1-repaired PR in Phase 1, which exits `3` at `:1888, 2061`) or on the first conflicting PR in a dry run (`:1808-1813`).
   - `F5 → P1.1` (`gh1475-plan-r0.md:70`): `git merge --ff-only FETCH_HEAD` still reads `.git/FETCH_HEAD`, which is overwritten with multiple branch lines by any concurrent `git fetch` in the primary checkout (the exact cause of `"Cannot fast-forward to multiple branches"`). `merge_cleanup.py:1227, 1966` merges `origin/<branch>`, not `FETCH_HEAD`. Moreover, `merge_cleanup.py`'s own primary-repo fetches (`:1294, 1308` not wrapped in `_retry_call`; `:125-129` `TRANSIENT_RE` omitting `cannot lock ref`) remain exposed to the same `F5` ref-lock race.
   - `F7 → P1.5` (`gh1475-plan-r0.md:74`) and `F8 → P1.4` (`gh1475-plan-r0.md:73`): `merge_cleanup.py:2634-2643` can exit `4` on *any* `--execute` run (even a single-PR run *without* `--resume`) when a prior batch on the same repo/integration branch still has `qa_pending == True`; and in `P1.4`, calling `set_outcome(batch, N, reconcile="ok")` without `status="merged", merge_oid=merge_oid`, `finalize_sweep_inputs`, and `batch_record.update` leaves interrupted merges `continuable` (`batch_record.py:250-257`) and leaves the GitHub issue table stale.
2. **Phase 1 size, risk, and hidden decisions:**
   - **P1.3** (`gh1475-plan-r0.md:72`) breaks `test/gh436-merge-cleanup.py:1084-1109` (`test_takeover_sweep_keeps_guard_and_has_no_cleanup_trap` and `test_takeover_sweep_real_clone_retains_sentinel_and_independent_objects`) if `run_isolated_check` (`merge_cleanup.py:219`) deletes `merge-check-*` on `rc == 0`.
   - **P1.4** (`gh1475-plan-r0.md:73`) mutates batch state on `--reconcile-pr N` (`merge_cleanup.py:2348-2370`), which runs in dry-run mode when `--execute` is omitted; it must guard writes under `if not dry_run:` and update both local JSON and the GitHub `merge-batch` issue (`merge_cleanup.py:1605-1614`).
   - **P1.6** (`gh1475-plan-r0.md:75-82`) hides a new `gh` API call for branch protection and a process scan. Neither is needed: `required_checks_state` (`merge_cleanup.py:732-745`) is already called in dry-run (`:1893`) and returns `("ok", "no required checks")` (`:745`), whereas an extra `gh` call in `main()` breaks mock-pinned tests (`test/gh436-merge-cleanup.py:445-463`). Likewise, a non-blocking `fcntl.flock` on `<primary>/.tick/merge-cleanup/<owner>-<repo>/execute.lock` replaces `ps` scanning and makes P3.6 a one-line refusal toggle.
3. **Phase placements:** Placements are sound with two adjustments: (a) keep `merge-check-*` (`:219`) retention in Phase 1 (bound it in `P2.3`'s pruner instead) while making `P1.3` clean up per-PR `pr-<N>-*` / `verify-<sha>` subdirectories inside `workdir` as each PR finishes cleanly; (b) if `P1.6` uses an `fcntl.flock` lockfile for its concurrency probe, `P3.6` (`gh1475-plan-r0.md:100`) is trivial enough to fold into Phase 1/2 or stay a tiny toggle.
4. **Falsifiability and red controls:** Only `P1.1` (`gh1475-plan-r0.md:70`) states an explicit `Red control:`; `P1.2`–`P1.6` omit `Red control:` lines, and `P2.1`–`P2.7` / `P3.1`–`P3.6` omit both `*Check:*` and `Red control:` (violating Definition of Done `(d)` at `gh1475-plan-r0.md:116-117`). For `P1.1`, "a concurrent `git fetch` in the primary" is nondeterministic unless the check deterministically simulates the two git failure states: (1) holding `refs/remotes/origin/<branch>.lock` for ~1s during `fetch`, and (2) writing a multi-branch `.git/FETCH_HEAD` before `merge --ff-only`.
5. **What is missing and what is over-engineered (YAGNI + full-file sweep):**
   - *Missing (pre-existing bug found in full-file sweep):* In `_land_prs_loop` (`merge_cleanup.py:1808-1813`), during a dry run (`dry_run=True`), `resolve_ledger_conflict(clone, execute=False)` (`ledger_merge.py:581-583`) returns `resolved=False, handoff=False`, causing `:1808-1813` to set `keep_workdir = True` and `return 0` early on the first conflicting PR instead of continuing the dry-run across the remaining PRs.
   - *Missing in P2.1:* `merge_cleanup.py:1943-1944` notes that a newly pushed B1 head's checks may not be registered yet on GitHub; in-run re-pinning needs check verification bound to `b1["commit"]` (with a short registration grace window when checks are expected) and must update `test/gh534_phase_b_tests.py:417-425` (`self.assertEqual(rc, 3)` at `:423`).
   - *Over-engineered in P1.6:* Separate `gh api` branch-protection queries and `ps` table parsing fail YAGNI when `required_checks_state` (`:745`) and `fcntl.flock` already cover those two probes cleanly.

---

#### Graded Findings

- **[Blocker] B1 — P1.3 deleting `merge-check-*` (`merge_cleanup.py:219`) on clean exit breaks existing pinned tests (`test/gh436-merge-cleanup.py:1084-1109`) and `SKILL.md:80`, while whole-workdir-only deletion (`:1629, 2067`) fails to prevent `F1` in multi-PR or B1-deferring runs (`gh1475-plan-r0.md:72`).**
  - `test/gh436-merge-cleanup.py:1084-1095` (`test_takeover_sweep_keeps_guard_and_has_no_cleanup_trap`) and `:1097-1109` (`test_takeover_sweep_real_clone_retains_sentinel_and_independent_objects`) call `merge_cleanup.run_auto_sweep` (which calls `run_isolated_check` at `merge_cleanup.py:217-230`) with `rc == 0` and assert `Path(kwargs["cwd"]).is_dir()` (`:1095`), `(clone / "takeover-sentinel").read_text()` (`:1106`), and `(clone / ".git").is_dir()` (`:1107`). `SKILL.md:80` also requires: `"Canary and automatic local sweep commands run in retained independent full clones, never primary."`
  - Meanwhile, inside `_land_prs_loop` (`merge_cleanup.py:1629-2067`), each PR creates up to three full clones under one shared `workdir` (`pr-<N>-<sha>-*` at `:789, 1864` and `verify-<sha>` at `:820`). In Phase 1 (before P2.1), every B1-repaired PR sets `failed[p_num] = "deferred: head is not the dry-run pin"` (`:1888`) and causes `_land_prs_loop` to return exit `3` (`:2061`), which is non-zero — so a whole-run `rc == 0` check retains every preceding landed PR's clones too. And in dry-run, `merge_cleanup.py:1808-1813` sets `keep_workdir = True` and returns `0` early on the first conflicting PR because `resolve_ledger_conflict(clone, execute=False)` (`ledger_merge.py:581-583`) returns `resolved=False`.
  - Observed input: `run_auto_sweep(self.primary, batch, "printf checked > takeover-sentinel")` returning `0` in `test/gh436-merge-cleanup.py:1102-1108`, and a multi-PR `_land_prs_loop` batch (`merge_cleanup.py:1629-2067`) where PR 1 lands cleanly and PR 2 undergoes B1 repair and defers at `:1884-1889` (`return 3` at `:2061`) or runs in dry-run over a conflicting PR (`:1808-1813`).
  - Affected scope: `run_isolated_check` (`merge_cleanup.py:217-230`) and `_land_prs_loop` (`merge_cleanup.py:1629-2068`) temporary clone lifecycle.
  - Falsifier: Run `python3 test/gh436-merge-cleanup.py TestGh1383BatchExecutionEnhancements.test_takeover_sweep_real_clone_retains_sentinel_and_independent_objects` with `run_isolated_check` deleting `holder` on `rc == 0` -> fails with `FileNotFoundError` at `test/gh436-merge-cleanup.py:1106`.
  - **Fix:** Leave `merge-check-*` (`merge_cleanup.py:219`) retained on exit `0` per `test/gh436-merge-cleanup.py:1084-1109` and `SKILL.md:80` (prune old `merge-check-*` folders in `P2.3` instead). In `P1.3`, delete each per-PR `pr-<N>-*` and `verify-<sha>` clone inside `workdir` as soon as that PR's step finishes without a per-PR failure (including after a clean merge, a clean dry-run check, or a B1 repair that pushed cleanly before deferring at `:1888`), fix `:1808-1813` so `if dry_run:` logs the B1 preview and `continue`s without setting `keep_workdir = True`, and remove `workdir` in `finally` when no retained per-PR clone remains (validating path containment under `Path(tempfile.gettempdir()).resolve()` per `AGENTS.md` GH-567).

- **[Blocker] B2 — P1.1 specifies `git merge --ff-only FETCH_HEAD` (`gh1475-plan-r0.md:70`), which still races a concurrent `git fetch` in the primary checkout and contradicts `merge_cleanup.py`'s `origin/<branch>` pattern.**
  - `merge_cleanup.py:1223-1228` and `:1961-1966` run `git fetch origin <branch>` followed by `git merge --ff-only origin/<branch>`, never `FETCH_HEAD`.
  - In `wave_reconcile.py:304`, `git pull --ff-only origin <branch>` failed in `F5` with `"Cannot fast-forward to multiple branches"` because `.git/FETCH_HEAD` is a single shared file rewritten with multiple branch lines when any concurrent `git fetch` runs in the primary repo. Running `git fetch origin <branch>` then `git merge --ff-only FETCH_HEAD` across two subprocesses still reads `.git/FETCH_HEAD` and fails under the same race.
  - Furthermore, `merge_cleanup.py`'s own primary-repo fetches at `:1294` and `:1308` are not wrapped in `_retry_call`, and `TRANSIENT_RE` (`:125-129`, used by `_net_git` at `:1961, 2528`) does not match local ref-lock contention (`cannot lock ref` / `Unable to create '... .lock'`).
  - Observed input: A concurrent `git fetch origin` in `repo_root` writing multiple branch entries to `.git/FETCH_HEAD` between `git fetch origin development` and `git merge --ff-only FETCH_HEAD`, or holding `refs/remotes/origin/development.lock` during `wave_reconcile.py:304` / `merge_cleanup.py:1294, 1308, 1961, 2528`.
  - Affected scope: `utils/py/wave_reconcile.py:302-307` (`pull_upstream`) and `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:125-129, 1294, 1308`.
  - Falsifier: Overwriting `.git/FETCH_HEAD` with two branch lines (as `git fetch origin` does on a repo with 2+ branches) immediately after `git fetch origin development` causes `git merge --ff-only FETCH_HEAD` to fail with `fatal: Cannot fast-forward to multiple branches`, whereas `git merge --ff-only origin/development` exits `0`.
  - **Fix:** Change `P1.1` to run `git fetch origin <branch>` (retrying on transient network or ref-lock errors) followed by `git merge --ff-only origin/<branch>` in `wave_reconcile.py:302-307`, and add `cannot lock ref|unable to create .*\.lock` to retryable git errors for primary-repo fetches in `merge_cleanup.py:125-129, 1294, 1308`. Make `P1.1`'s check + red control deterministic by simulating both a 1s `refs/remotes/origin/<branch>.lock` file during `fetch` and a multi-line `.git/FETCH_HEAD` before `merge --ff-only`.

- **[Should] S1 — P1.4 (`--reconcile-pr` batch update and `--record-sweep` hint, `gh1475-plan-r0.md:73`) omits `status="merged"`/`merge_oid`, `finalize_sweep_inputs` + `batch_record.update`, `not dry_run` gating, and unreconciled-PR guidance in `record_sweep`.**
  - `batch_record.py:250-257` (`continuable`) requires `o.get("status") == "merged" and o.get("reconcile") == "ok"`. If a run was killed during/after merge before recording `status="merged"`, calling `set_outcome(batch, N, reconcile="ok")` alone leaves `status` as `"unattempted"` or `"stopped: ..."`, so `continuable(batch)` stays `True`. `--reconcile-pr` (`merge_cleanup.py:2357-2360`) already verifies `info.get("state") == "MERGED"` and extracts `merge_oid`.
  - Unlike `_record_batch_outcomes` (`merge_cleanup.py:1605-1614`), `set_outcome` (`batch_record.py:291-307`) only saves the local JSON file; it does not call `batch_record.finalize_sweep_inputs` or `batch_record.update(batch, _gh, primary_repo)` to update the `merge-batch` GitHub issue. Also, `--reconcile-pr` (`:2348-2370`) supports dry-run when `--execute` is omitted, so batch writes must only happen under `if not dry_run:` after `commit_and_push_phase5_writes` succeeds (`:2367-2369`).
  - Finally, in `record_sweep` (`merge_cleanup.py:2785-2786`), only warning "when a planned PR is still open" would stay silent when a PR is already `MERGED` (closed) but its `reconcile` is still `"failed: ..."`.
  - Observed input: A batch record where PR `#N` has `{"status": "stopped: ...", "reconcile": "failed: ..."}` (or `{"status": "merged", "reconcile": "failed: ..."}`) recovered via `merge_cleanup.py --primary <p> --reconcile-pr N --execute`, or inspected by `--record-sweep` before `--reconcile-pr N` runs.
  - Affected scope: `merge_cleanup.py:2348-2370` (`--reconcile-pr`) and `merge_cleanup.py:2765-2787` (`record_sweep`) / `batch_record.py:250-257`.
  - Falsifier: Calling `batch_record.set_outcome(batch, N, reconcile="ok")` on a record with `outcomes[str(N)] = {"status": "stopped: merge timeout"}` still returns `batch_record.continuable(batch) == True` (`batch_record.py:250-257`).
  - **Fix:** In `P1.4`, specify that under `if not dry_run:` after `commit_and_push_phase5_writes` succeeds (`merge_cleanup.py:2367-2369`), `--reconcile-pr N` calls `batch_record.set_outcome(batch, N, status="merged", merge_oid=merge_oid, reconcile="ok")`, `batch_record.finalize_sweep_inputs(...)`, and `batch_record.update(batch, _gh, primary_repo)`. In `record_sweep` (`:2785-2786`), suggest `--resume --execute` when unmerged open PRs remain and `--reconcile-pr <N> --execute` when a merged PR still has `reconcile != "ok"`.

- **[Should] S2 — P1.5 (`SKILL.md:476` exit-code contract, `gh1475-plan-r0.md:74`) understates when exit 4 occurs and omits exit 1.**
  - `merge_cleanup.py:2634-2643` checks `batch_record.find_unfinished(primary_repo, origin_url(primary_repo) or "", args.integration_branch, [], need_qa=True)` on **every** `args.execute` invocation — including a single-PR `--execute` *without* `--resume` and `--teardown-only --execute` — and exits `4` (`:2663`) if any earlier batch on that repo + integration branch still has `qa_pending(batch) == True` (when auto-sweep is deferred, fails, or `--no-auto-sweep` is passed).
  - `merge_cleanup.py:2127` also returns exit code `1` (`--retire-published-pr`).
  - Note also that `test/gh534_phase_c_tests.py:896-994` (`TestGh623DriveLoopDocContract`, `TestParityGuard`) pins exact substrings in `SKILL.md` (`## Drive loop`, `Done rule`, `Capability table`, and `SKILL.md:460` "exit 4 is never Done").
  - Observed input: Running `merge_cleanup.py --primary <p> --prs 99 --execute` (single PR, no `--resume`) when an earlier batch on the same repo/integration branch has `qa_pending == True` and `sweep_inputs.deferred == True` (`merge_cleanup.py:2634-2663`).
  - Affected scope: `skills/2-daily/merge-cleanup/SKILL.md:475-481, 506-515`.
  - Falsifier: `merge_cleanup.py:2634-2663` returns `4` on a single-PR `--execute` without `--resume` whenever `find_unfinished(..., [], need_qa=True)` returns an earlier QA-pending batch whose auto-sweep was deferred or skipped.
  - **Fix:** Update `P1.5` so `SKILL.md:476` states that a single-PR run opens no new batch of its own, but *any* `--execute` run (with or without `--resume`) can exit `4` if it attaches to an unfinished batch or if an earlier batch on the same repo + integration branch still has `qa_pending`; phrase exit `4` in the table as "merges/teardown landed, QA sweep still pending (`--record-sweep` required before Done)" and include exit `1` (`--retire-published-pr` failure at `:2127`).

- **[Should] S3 — P1.6 (`gh1475-plan-r0.md:75-82`) should reuse `required_checks_state` (`merge_cleanup.py:745`) and an `fcntl.flock` lockfile instead of adding a new `gh` API call and process-table scan.**
  - `merge_cleanup.py:732-745` (`required_checks_state`, already called during dry-run at `:1893`) already detects `"no required checks reported"` and returns `("ok", "no required checks")`. Adding a separate pre-flight `gh` call is redundant, fails on repos using GitHub Rulesets without classic branch-protection read access, and breaks `merge_cleanup.main()` tests (`test/gh436-merge-cleanup.py:445-463`, `test/gh534_phase_a_tests.py:573-587`, `test/gh534_phase_b_tests.py:255-264`) that mock exact `_gh` call sequences.
  - For probe #5 ("another `merge_cleanup.py --execute` already running") and `P3.6` ("Per-machine landing lock"), holding a non-blocking `fcntl.flock` on `<primary>/.tick/merge-cleanup/<owner>-<repo>/execute.lock` during `--execute` and probing it in dry-run avoids fragile `ps` parsing and unifies `P1.6` probe #5 with `P3.6`. For probe #3, state the exact path check (`".relay-scratch"` or `"rtl-wt."` in `Path(tempfile.gettempdir()).resolve().parts`, or `TMPDIR` inside a git worktree).
  - Observed input: Running `merge_cleanup.main()` under `test/gh436-merge-cleanup.py:445-463` (where `_gh` is mocked only for expected PR calls) or when `required_checks_state` (`merge_cleanup.py:744-745`) already returns `("ok", "no required checks")`.
  - Affected scope: `merge_cleanup.py` dry-run pre-flight warning probes (`P1.6`) and `--execute` concurrency lock (`P1.6` / `P3.6`).
  - Falsifier: `required_checks_state(pr_num, primary_repo)` at `merge_cleanup.py:732-745` already returns `("ok", "no required checks")` during the dry-run loop (`:1893`) with zero additional `gh` invocations.
  - **Fix:** Specify in `P1.6` that the F6 warning triggers off `required_checks_state` returning `"no required checks"` (`:745`) (no new `gh` call), the concurrency warning probes an `fcntl.flock` lockfile held by `--execute`, the disk check uses `shutil.disk_usage(tempfile.gettempdir())`, and the `TMPDIR` warning checks for `.relay-scratch` / `rtl-wt.` / git-worktree containment.

- **[Should] S4 — P2.1 (Re-pin after a B1 repair, `gh1475-plan-r0.md:86`) must account for check-suite registration latency after pushing `b1["commit"]` (`merge_cleanup.py:1943-1944`) and update the pinned test (`test/gh534_phase_b_tests.py:423`).**
  - `merge_cleanup.py:1943-1944` explicitly documents why B1 repairs were deferred: `"A B1 repair pushed a new head whose checks may not even be registered yet: defer it to a fresh dry run."` Querying `gh pr checks` milliseconds after `push_resolved_head` (`:1821`) can observe stale/empty check state before GitHub registers workflows on `b1["commit"]`.
  - In addition, `test/gh534_phase_b_tests.py:417-425` (`test_two_prs_second_conflicts_after_first_lands_and_b1_resolves_it`) currently asserts `self.assertEqual(rc, 3)` (`:423`) after a B1 repair before calling `self.land_repaired(2)`.
  - Observed input: `push_resolved_head` pushing `b1["commit"]` at `merge_cleanup.py:1821` followed immediately by `required_checks_state` at `:1893`, and `test/gh534_phase_b_tests.py:417-425` expecting `rc == 3`.
  - Affected scope: `merge_cleanup.py:1821-1948` (`_land_prs_loop` B1 re-pin path) and `test/gh534_phase_b_tests.py:417-425`.
  - Falsifier: Running `test/gh534_phase_b_tests.py` after enabling in-run B1 re-pin fails `self.assertEqual(rc, 3)` at `test/gh534_phase_b_tests.py:423` unless that test is updated to assert in-run landing plus a red control where an external push (`head != b1["commit"]`) still exits `3`.
  - **Fix:** State in `P2.1` that re-pinning updates `args._pins[p_num]`, `selection-<integration>.json`, and `batch_record.set_allowlist` to `b1["commit"]`, verifies check runs bound to `b1["commit"]` (with a registration grace poll when required or `wait_for_checks` checks are configured), and updates `test/gh534_phase_b_tests.py:417-425` (retaining a red control where `head != b1["commit"]` exits `3`).

- **[Nit] N1 — Missing explicit `*Check:*` and `Red control:` lines on `P1.2`–`P1.6` and `P2.1`–`P2.7` (`gh1475-plan-r0.md:71-93`, Definition of Done `(d)` at `:116-117`).**
  - Definition of Done `(d)` requires that *"each acceptance check is falsifiable, with a red control (what an unchanged/unfixed tree shows)"*. Currently only `P1.1` includes a `Red control:` sentence.
  - **Fix:** Add a one-line `Red control:` to `P1.2`–`P1.6` and brief `*Check:* ... Red control: ...` lines to `P2.1`–`P2.7` (and `P3.1`–`P3.6` or mark Phase 3 checks gated on phase entry).

- **[Pass] P1 — Post-mortem coverage (`F1`–`F14` + `#10`, `#13`) and `F3` follow-up boundary (`gh1475-plan-r0.md:91, 102-110`).**
  - Confirmed against `skills/2-daily/merge-cleanup/scripts/ledger_merge.py:777-809` (`_conflict_hubs`) and `:905-936` (`passes`, specifically `:927-936` where `all_ledger_hubs` still emits `mode: "group"` when `len(group) > 1`) that `#1472` (`F3`) is already in the tree and `P2.6` (`gh1475-plan-r0.md:91`) accurately targets the exact remaining case where every conflicting member is a B1-repairable ledger hub.

**VERDICT:** FAIL
**Basis:** Two blockers in Phase 1 (`B1`: `P1.3` deleting `merge-check-*` on clean exit breaks `test/gh436-merge-cleanup.py:1084-1109` and `SKILL.md:80`, while whole-workdir-only cleanup leaves per-PR clones behind whenever any PR in a batch defers or conflicts in dry-run at `merge_cleanup.py:1808-1813`; `B2`: `P1.1` merging `FETCH_HEAD` instead of `origin/<branch>` still races concurrent primary fetches via `.git/FETCH_HEAD`), plus four should-fix gaps (`S1`–`S4`) and missing red controls (`N1`).

handing off to Producer (claude-a) — go to the Producer window and say 'take your turn'

### Producer · Round 1 · claude-a

Every citation was checked against `5967bde25` before disposition. Adjudicated with `/ponytail`
(Phase 1 stays small, local and read-only where possible; new machinery moves to Phase 2/3).

**Paraphrase check:** the reviewer's artifact-only paraphrase matches the plan's intent; no
explanation gap found. One inference corrected: Phase 2 items are not "later authorization", they
are separate PRs not yet scheduled.

**Dispositions**
- **B1 [Blocker] P1.3 deletes `merge-check-*` against pinned tests; whole-workdir cleanup misses
  rc 3.** Verified: `test/gh436-merge-cleanup.py` takeover tests assert the sweep clone and its
  sentinel survive a 0 return; `keep_workdir` is assigned on failure paths but never read.
  **Disposition: Modified.** `merge-check-*` stays retained in Phase 1 (moved to P2.3). P1.3 narrows
  to honoring the existing `keep_workdir` flag: remove the `merge-cleanup-*` workdir only on loop
  return 0 with no keep flag. Per-PR release inside a workdir kept for a later deferral is a
  retention-policy decision → **P2.3** (Rejected for Phase 1, Ponytail). The dry-run early return at
  the "B1 stopped" branch is real (`ledger_merge.py` returns `resolved=False` with `execute=False`)
  but pre-existing and outside every F-row → recorded as **P2.8**, not fixed in Phase 1.
- **B2 [Blocker] `merge --ff-only FETCH_HEAD` still races.** Verified: `merge_cleanup.py` merges
  `origin/<branch>`; `FETCH_HEAD` is shared and rewritten by any fetch. **Disposition: Implemented.**
  P1.1 now uses `origin/<branch>`, retries the fetch+merge pair on ref-lock errors, and adds the
  ref-lock patterns to `TRANSIENT_RE`. Wrapping `merge_cleanup.py:1294/1308` in `_retry_call` →
  **Declined** for Phase 1 (no observed failure at those sites; F5 named `wave_reconcile.py`). The
  deterministic check (two-branch `FETCH_HEAD` + held `.lock`) is adopted as P1.1's manual check.
- **S1 [Should] P1.4 omits status/merge_oid, issue refresh, dry-run guard, hint split.**
  **Disposition: Implemented** as specified (non-dry-run only, after the Phase 5 push; `set_outcome`
  with `status="merged"`, `merge_oid`, `reconcile="ok"`; `finalize_sweep_inputs` + `update` as in
  `_record_batch_outcomes`; hint names `--reconcile-pr N --execute` vs `--resume --execute`).
- **S2 [Should] Exit 4 fires on any `--execute` with QA debt; exit 1 missing.** Verified at
  `merge_cleanup.py:2634-2663` and `:2127`. **Disposition: Implemented** in P1.5's wording and table.
- **S3 [Should] P1.6 should reuse `required_checks_state`, use flock, specify probes.**
  **Disposition: Modified.** F6 warning reuses `required_checks_state` (no new `gh` call) —
  Implemented. Disk uses `shutil.disk_usage(tempfile.gettempdir())`; TMPDIR rule specified —
  Implemented. `fcntl.flock` → **Rejected for Phase 1 (Out of Scope / Ponytail):** it makes
  `--execute` create and hold a lockfile, a behaviour change in the execute path; Phase 1's probe stays
  a read-only `pgrep -f`, and flock is noted as the likely shape of P3.6.
- **S4 [Should] P2.1 needs check-registration grace and a pinned-test update.**
  **Disposition: Implemented** in P2.1's text (plan only; Phase 2 is not in this PR).
- **N1 [Nit] Red controls missing.** **Disposition: Modified.** Every P1 item now has a check and a
  red control. Phase 2/3 items define theirs in their own `/start-task` plans when picked up
  (stated in each phase header); writing them now for unscheduled work is Rejected (Ponytail).
- **P1 [Unverified — no citation]** noted.

Revised plan (r1) — this replaces the embedded artifact for Round 2:

````markdown
## Ask
Make `/merge-cleanup` batches fast enough and robust enough to run unattended, in three phases. Each failure mode from a real 13-PR batch maps to a fix below, or is marked out of scope for the script.

**Evidence:** a downstream consumer repo's 13-PR batch on 2026-11-14 took about 9.5 hours. About 6.5 hours of that is per-PR overhead even when nothing fails (dry-run pin, CI, full reconcile); failures added about 3–5 hours. Full post-mortem: https://github.com/BinoidCBD/LTVera-Pandas/issues/1095#issuecomment-6889598174 · batch record notes: BinoidCBD/LTVera-Pandas#1102 · stacked-lane test: BinoidCBD/LTVera-Pandas#1106.

Anchors are at `development` `5967bde25`: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, `scripts/batch_record.py`, `scripts/ledger_merge.py`, `utils/py/wave_reconcile.py`, `skills/2-daily/merge-cleanup/SKILL.md`.

XYZ-forge forbids new test suites (GH-831). Every check below is an existing suite or a manual check recorded under `TESTS-RESULTS/`; each names its red control (what the unchanged tree shows).

## Phase 1 — quick wins (one PR)
Small, local and reversible. No change to merge or gate behaviour, except replacing the git pull.
- [ ] **P1.1 Fetch, then fast-forward to the remote-tracking ref (F5).** In `wave_reconcile.py` `pull_upstream`, replace `git pull --ff-only origin <branch>` with `git fetch origin <branch>` then `git merge --ff-only origin/<branch>` (the pattern `merge_cleanup.py` already uses; not `FETCH_HEAD`, which a concurrent fetch rewrites). Retry the pair a few times with a short backoff when git reports a ref lock (`cannot lock ref`, `Unable to create '….lock'`). Add the same ref-lock patterns to `merge_cleanup.py` `TRANSIENT_RE` so its existing `_retry_call` sites retry them too. *Check (manual, deterministic):* in a scratch clone, (a) write a two-branch `.git/FETCH_HEAD` and hold `refs/remotes/origin/<branch>.lock` for ~1 s, then run `pull_upstream`: it succeeds after the lock clears. *Red control:* the old `git pull --ff-only` path fails under (a).
- [ ] **P1.2 Flushed output (F12).** `merge_cleanup.py` sets line-buffered stdout and stderr at start-up. *Check:* `tail -f` on a redirected dry run shows Phase 0 within seconds. *Red control:* without the change the redirected log stays empty until exit or buffer fill.
- [ ] **P1.3 Delete the landing workdir on success (F1).** Honor the existing, never-read `keep_workdir` flag: when the landing loop returns 0 and nothing set `keep_workdir`, remove the `merge-cleanup-*` workdir in the `finally` (path checked to be a `merge-cleanup-` directory under the temp root). Keep it on any non-zero exit or when `keep_workdir` is set, as now. `merge-check-*` clones stay retained (pinned by `test/gh436-merge-cleanup.py` takeover tests and `SKILL.md` "retained independent full clones"); pruning them moves to P2.3. *Check:* existing `test/gh436-merge-cleanup.py` and `test/gh534_phase_*` stay green; manual: a clean single-PR landing leaves no new `merge-cleanup-*` folder, a failed run keeps it. *Red control:* the unchanged tree logs "retained" and leaves the folder after a clean run.
- [ ] **P1.4 `--reconcile-pr` updates the batch record (F8).** After a successful, non-dry-run `--reconcile-pr N` (after `commit_and_push_phase5_writes` succeeds), find the unfinished batch containing N (`batch_record.find_unfinished`) and record `status="merged"`, `merge_oid`, `reconcile="ok"` with `set_outcome`, then refresh sweep inputs and the batch issue the way `_record_batch_outcomes` does (`finalize_sweep_inputs`, `batch_record.update`). No batch → no write. `--record-sweep`'s hint names the right recovery per remaining PR: `--reconcile-pr N --execute` for a merged PR whose reconcile is not `ok`, `--resume --execute` only while a planned PR is still open. *Check (manual, scratch record):* a batch whose only unfinished row is merged-but-reconcile-failed stops reporting "Planned PRs remain" after the recovery. *Red control:* on the unchanged tree `continuable()` stays true and the hint says `--resume --execute`.
- [ ] **P1.5 Exit-code contract in SKILL.md (F7).** Fix `SKILL.md:476`: a single-PR run opens no batch of its own, but any `--execute` run (with or without `--resume`) can exit 4 when it attaches to, or finds, a batch whose QA is still pending. Add one table of exit codes for wrapper scripts: 0 done; 4 landed, QA pending (treat as landed; record the sweep before Done); 3 deferred or handed off (retry or work the ladder); 5 landing-plan decision needed; 2 stop and diagnose; 1 `--retire-published-pr` could not retire a checkout. *Check:* existing `test/gh534_phase_c_tests.py` doc-contract tests stay green; each row cites the `return` it documents.
- [ ] **P1.6 Read-only pre-flight warnings in the dry run (F1, F2, F6, F10).** One `PRE-FLIGHT` block, warnings only, nothing refuses, no new `gh` call:
  - free disk under the temp root (`shutil.disk_usage(tempfile.gettempdir())`) below 20 GB;
  - running on battery (`pmset -g batt` on macOS; silent elsewhere or on any error);
  - `TMPDIR` set to a path other than `/tmp` or the OS default (a harness may delete a per-turn temp dir mid-run);
  - another `merge_cleanup.py --execute` running on this machine (read-only `pgrep -f`; silent if `pgrep` is missing);
  - no required checks: reuse the existing per-PR `required_checks_state` result and print the warning once when it reports "no required checks" ("the script will not wait for CI").

  *Check (manual):* each warning fires under its forced condition (env override or stubbed probe) and stays silent otherwise. *Red control:* the unchanged dry run prints none of them.

## Phase 2 — next easiest wins
Behaviour changes with clear guards. Each can be its own PR, and each defines its check and red control in its own `/start-task` plan.
- [ ] **P2.1 Re-pin after a B1 repair (F13).** When this run's own B1 repair produced the new head, its required or declared checks pass on that exact commit (allow a short registration grace poll after the push, per the note at `merge_cleanup.py` "checks may not even be registered yet"), and nothing else moved the head, re-pin (`args._pins`, the selection file, `batch_record.set_allowlist`) and continue in the same run. Updates the pinned expectation in `test/gh534_phase_b_tests.py` (rc 3 after a B1 repair) and keeps a red control where an external push still defers.
- [ ] **P2.2 Opt-in CI wait without branch protection (F6).** Add `.merge-cleanup.json` `qualification.wait_for_checks: ["<check name>", ...]`. The existing pending, poll and defer logic then applies to those named checks even when GitHub reports no required checks.
- [ ] **P2.3 Retained-clone pruning policy (F1).** Keep at most the last N failed-run workdirs (default 3) and prune older `merge-cleanup-*` and `merge-check-*` folders that belong to this tool and have no open handles. Also release each landed PR's clones inside a workdir that is kept only because a later PR deferred (exit 3).
- [ ] **P2.4 Heartbeat during long steps (F12, F10).** One line per 60 s during the reconcile, CI wait and forecast, so watchers and harness timeouts can tell slow from stuck.
- [ ] **P2.5 Stacked-lane detection at landing time (F4).** After landing a PR, list open members whose head contains the landed PR's original commits. Print a refresh instruction for each (merge the integration branch into it, then CI and a re-pin). If GitHub refuses one, classify it as "stacked-lane refusal", not a generic merge failure.
- [ ] **P2.6 Forecast: all members are ledger-only hubs means one PR per pass (#1470 follow-up).** Recommend `direct`, one PR per pass, not `group`, when every conflict is B1-repairable.
- [ ] **P2.7 Base-aware post-batch integrity check (unanticipated, #13).** Optional `--verify-landed`: for each landed PR, compare its own change (merge-base to head) with its squash commit by changed lines, and report a test count from the sweep, not an exit code alone.
- [ ] **P2.8 Dry run stops at the first ledger-hub conflict (found in plan QA).** In a dry run, `resolve_ledger_conflict(execute=False)` returns `resolved=False`, so the loop logs "B1 stopped", sets `keep_workdir` and returns 0 at the first B1-repairable PR (`merge_cleanup.py` "B1 stopped" branch), leaving later PRs unpreviewed. Confirm, then let the dry run log the B1 preview and continue.

## Phase 3 — riskier or more extensive (may be deferred)
Each defines its check and red control in its own plan when picked up.
- [ ] **P3.1 Reconcile stops appending to docs carried by open PRs (F4 root cause).** Only after the BinoidCBD/LTVera-Pandas#1106 test confirms the cause. Write merge evidence elsewhere, or after the doc moves to its completed folder.
- [ ] **P3.2 Automatic stacked-lane refresh (F4).** Merge the integration branch into the next stacked lane and push it, guarded by the same-repo, fast-forward-only and attempt-record rules. This writes to contributor branches, hence Phase 3.
- [ ] **P3.3 Changelog entries written at reconcile from the PR body (#1473).** Ledger writes only at landing (#1458). Together these remove most hub conflicts.
- [ ] **P3.4 Durable driver state file (F11).** One `.tick/merge-cleanup/<slug>/driver-state.md`, appended by the script, recording pins, decisions, recoveries and open hypotheses. A resuming session reads it first.
- [ ] **P3.5 Harness-safe launch (F10).** A `--detach` mode that re-executes under `nohup` with `TMPDIR=/tmp` and unbuffered output, writes its log path, and returns at once. This avoids harness command limits.
- [ ] **P3.6 Per-machine landing lock (unanticipated, #10).** Turn the P1.6 concurrency warning into a refusal, with an explicit override (an `fcntl.flock` lockfile held by `--execute` is the likely shape).

## Not fixable in the script (environment, policy or agent behaviour)
- **F2, power and sleep:** wall power and `caffeinate`. P1.6 warns.
- **F6, required checks:** repo branch protection is the consumer's decision. P1.6 warns and P2.2 offers an opt-in.
- **F9, model usage cap and session switches:** agent orchestration. Check quota before starting; no sub-agents during landing.
- **F14, unverified figures relayed:** agent discipline.
- **Out-of-tool state changes by agents:** agent discipline. P3.4 makes them visible.

## Failure-mode map
F1 → P1.3, P1.6, P2.3 · F2 → P1.6 · F3 → done (#1472), P2.6 · F4 → P2.5, P3.1, P3.2 · F5 → P1.1 · F6 → P1.6, P2.2 · F7 → P1.5 · F8 → P1.4 · F9 → out of scope · F10 → P1.6, P2.4, P3.5 · F11 → P3.4 · F12 → P1.2, P2.4 · F13 → P2.1 · F14 → out of scope

Relay QA of this plan (agy, Gemini 4 Argon High) is summarized in a comment.
````

Questions for Round 2: are B1/B2/S1–S3 resolved as dispositioned; is any rejection wrong on the evidence; is Phase 1 still small, low-risk and independent?

handing off to Reviewer (agy) — take your turn.

### Round 2 · Reviewer · agy

swept file: yes

- **[Pass] P1 — B1 and B2 are cleanly resolved in `r1` (`relay-system/2026-11-14/gh1475-plan-argon.md:344, 346, 362, 367`), and the Phase 1 / Phase 2 Ponytail split is sound on the evidence.**
  - `P1.3` (`relay-system/2026-11-14/gh1475-plan-argon.md:346`) honors `keep_workdir` (`skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:1630, 2067`) by removing the `merge-cleanup-*` workdir (`:1629`) only when `_land_prs_loop` returns `0` and `not keep_workdir` (with temp-root path containment), while keeping `merge-check-*` clones (`:219`) retained as pinned by `test/gh436-merge-cleanup.py:1084-1109` and `skills/2-daily/merge-cleanup/SKILL.md:80` (`"retained independent full clones, never primary"`). Deferring `merge-check-*` pruning and per-PR clone release on exit `3` to `P2.3` (`relay-system/2026-11-14/gh1475-plan-argon.md:362`) and capturing the pre-existing dry-run early exit (`merge_cleanup.py:1808-1813`) as `P2.8` (`relay-system/2026-11-14/gh1475-plan-argon.md:367`) keeps Phase 1 local and low-risk.
  - `P1.1` (`relay-system/2026-11-14/gh1475-plan-argon.md:344`) replaces `git pull --ff-only origin <branch>` in `utils/py/wave_reconcile.py:302-307` (`pull_upstream`) with `git fetch origin <branch>` then `git merge --ff-only origin/<branch>` (matching `merge_cleanup.py:1227, 1966`), retries the pair on ref-lock errors (`cannot lock ref`, `Unable to create '….lock'`), adds those patterns to `TRANSIENT_RE` (`merge_cleanup.py:125-129`), and defines a deterministic manual check and red control. Declining new `_retry_call` wrappers at `merge_cleanup.py:1294, 1308` is justified because `F5` occurred in `wave_reconcile.py:304` and expanding `TRANSIENT_RE` already covers `_net_git` retry sites (`:1961, 2528`).

- **[Pass] P2 — S1, S2, S3, S4, and N1 are resolved with falsifiable checks and red controls (`relay-system/2026-11-14/gh1475-plan-argon.md:340-360, 370, 376`).**
  - `P1.4` (`relay-system/2026-11-14/gh1475-plan-argon.md:347`) gates batch writes on `not dry_run` after `commit_and_push_phase5_writes` (`merge_cleanup.py:2367-2369`), calls `batch_record.set_outcome` (`skills/2-daily/merge-cleanup/scripts/batch_record.py:291-307`) with `status="merged"`, `merge_oid`, and `reconcile="ok"`, refreshes sweep inputs and the issue via `finalize_sweep_inputs` + `batch_record.update` (`merge_cleanup.py:1605-1614`), and splits `record_sweep`'s recovery hint (`merge_cleanup.py:2785-2786`) between `--reconcile-pr N --execute` and `--resume --execute`.
  - `P1.5` (`relay-system/2026-11-14/gh1475-plan-argon.md:348`) corrects `skills/2-daily/merge-cleanup/SKILL.md:476` for single-PR `--execute` runs encountering QA debt (`merge_cleanup.py:2634-2663`) and documents all exit codes (`0`, `4`, `3`, `5` at `merge_cleanup.py:79`, `2`, and `1` at `:2127`) while preserving `test/gh534_phase_c_tests.py:896-994`.
  - `P1.6` (`relay-system/2026-11-14/gh1475-plan-argon.md:349-356`) reuses `required_checks_state` (`merge_cleanup.py:732-745, 1893`) with no extra `gh` call, specifies `shutil.disk_usage(tempfile.gettempdir())` and `TMPDIR` rules, and keeps the concurrency probe strictly read-only (`pgrep -f`) in Phase 1 while placing the `fcntl.flock` lockfile in `P3.6` (`relay-system/2026-11-14/gh1475-plan-argon.md:376`) so Phase 1 introduces no new state in `--execute`.
  - `P2.1` (`relay-system/2026-11-14/gh1475-plan-argon.md:360`) includes the check-registration grace poll on `b1["commit"]` (`merge_cleanup.py:1943-1944`), pin updates (`args._pins`, selection file, `batch_record.set_allowlist`), and the `test/gh534_phase_b_tests.py:423` update + red control; every Phase 1 item (`:344-356`) carries an explicit check and red control, and Phases 2–3 (`:359, 370`) bind theirs to each item's `/start-task` plan.

**VERDICT:** PASS
**Basis:** All Round 1 blockers (`B1`, `B2`), should-fix items (`S1`–`S4`), and red-control requirements (`N1`) are resolved in `r1` (`relay-system/2026-11-14/gh1475-plan-argon.md:332-389`). Phase 1 (`P1.1`–`P1.6`) is small, local, reversible, and independent of Phases 2–3, and every scope boundary deferred to Phases 2–3 (`P2.3`, `P2.8`, `P3.6`) is justified by the code evidence.

relay closed (Approved), no further turn needed

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
