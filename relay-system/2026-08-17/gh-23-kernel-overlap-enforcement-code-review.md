# RELAY · GH-23 kernel overlap enforcement — code review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-17.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-23-kernel-overlap-enforcement-code-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `src/claim.js`, `src/scope.js`, `src/events.js`, `bin/tick`,
  `test/gh23-path-overlap-enforcement.sh` — the full diff of branch
  `fix/gh-23-kernel-overlap-enforcement` against `main` (open as PR #24), which enforces
  collision-free path claims at the kernel boundary (issue #23).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-08-17
- Definition of Done: the Reviewer grades against:
  1. **Correctness** — `setsOverlap` overlap detection in `claim.js`/`scope.js` is race-free under
     `withClaimLock` (no TOCTOU window), `--force` provenance is recorded accurately in
     `src/events.js`, and no existing kernel invariant (epoch fencing, terminal-status checks,
     per-agent claim limits) is weakened by the new code path.
  2. **Completeness vs issue #23** — all 7 acceptance criteria in
     `PROJECT/2-WORKING/GH-23-KERNEL-OVERLAP-ENFORCEMENT.md` are actually met, not just claimed.
  3. **Test integrity** — `test/gh23-path-overlap-enforcement.sh`'s 13 assertions are discriminating
     (would actually fail pre-fix, not just pass post-fix); no gap in coverage for the acceptance
     criteria above.
  4. **Standing rule** — this repo's convention (not yet applied to this PR): every fix ships a
     recorded negative control under `test/baselines/` showing the check failing when the fix is
     reverted. **This PR currently has none — flag it as a finding**, don't just note its absence.
  5. **Pre-existing defects** — full sweep of every touched file per the Ground rules above,
     including `bin/tick`'s wiring of `--force` and the incidental changes to
     `test/gh385-retry-token-satisfied.sh`, `test/poll-driver.sh`, `test/poll-relay.sh`,
     `test/runner-loop.sh` bundled into the same commit (are they actually related to GH-23, or
     scope creep?).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Review (agy)

swept file: yes

- **[Blocker]** Missing negative control baseline: This repo requires a negative control under `test/baselines/` showing the check failing when the fix is reverted. GH-23 PRD explicitly mentions this is missing. Please add the negative control baseline.
- **[Pass]** Correctness (`src/claim.js:33,64`, `src/scope.js:50,53`): `setsOverlap` overlap detection in `claim.js`/`scope.js` is safely enclosed within `withClaimLock(repoRoot, () => { ... })`, making it race-free.
- **[Pass]** Completeness (`src/events.js:153-154`, `bin/tick:173,236`): `--force` provenance is recorded accurately (`if (force !== undefined) event.force = force;`) and correctly exposed in `bin/tick`.
- **[Pass]** Test integrity (`test/gh23-path-overlap-enforcement.sh:21-44,65-88`): The 13 assertions correctly test direct claim and scope overlap rejection (exit 1) and `--force` overrides (exit 0).
- **[Pass]** Pre-existing defects sweep: The incidental changes to `test/gh385-retry-token-satisfied.sh`, `test/poll-driver.sh`, `test/poll-relay.sh`, and `test/runner-loop.sh` simply adjust mock tasks (e.g. `paths "z/$1/**"`) or append `--force`/`tick done` to avoid tripping the newly-enforced path overlap check. This is necessary test maintenance, not scope creep.
- **[Nit]** Inefficiency (`src/scope.js:51-55`): Inside `withClaimLock`, `assertOwnership(repoRoot, task, agent)` calls `readAllEvents` and `fold`. Immediately after, `if (!force)` does another `readAllEvents(repoRoot)` and `fold(events)`. This is safe due to the lock, but you could pass the folded tasks from `assertOwnership` to avoid parsing the event log twice.

**Verdict**: Changes requested.
handing off to Producer — go to the claude-a window and say 'take your turn'

### Producer (claude-a) — round 1

- **[Blocker] Missing negative control** — Implemented. `test/baselines/GH-23-negative-control.md`:
  mutated both `src/claim.js:64` and `src/scope.js:57` (`if (!force)` → `if (false && !force)`,
  disabling the overlap check) in a disposable scratch clone, observed the regression test catch it
  (Bob's claim on `TASK-102` succeeds despite overlapping Alice's active claim — exactly the
  collision the fix exists to prevent), restored, confirmed 13/13 green again.
- **[Pass] items** — Implemented no changes (nothing requested).
- **[Nit] scope.js double fold** — Implemented. `assertOwnership` now accepts an optional
  pre-folded `tasks` map (backward-compatible — the other 4 callers pass nothing and it falls back
  to its own `fold(readAllEvents(...))`); `scope()` folds once and passes that map through,
  eliminating the second read+fold. Re-ran `test/gh23-path-overlap-enforcement.sh`: still 13/13.

Full `bash validate.sh` re-run after both changes: 215/215 green. No new frozen-twin
violations (`test/gh308-frozen-twin-guard.sh --check` clean).

handing off to Reviewer — go to the agy window and say 'take your turn', or treat this as closed
by the orchestrator's own verification if a second agy round is not available.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
