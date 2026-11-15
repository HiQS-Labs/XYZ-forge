# RELAY · GH-1475 merge-cleanup remediation plan QA (Gemini 4 Argon High)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
-->

NEXT: Reviewer
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
