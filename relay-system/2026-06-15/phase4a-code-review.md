# RELAY · Phase-4(a) code review — tick-native relay turns
<!-- Single source of truth. Read the WHOLE file before acting. -->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, Gemini)
The operator just said "take your turn on this file." Everything you need is **in this file**.
1. **Read this whole file.**
2. **Check it's your turn:** `NEXT` names the role; you're the bound agent (Setup: `Producer=Claude-A`, `Reviewer=Codex`); the last block isn't yours. Else STOP, reply "wrong window".
3. **Reviewer:** verify the (a) implementation against the code (cite `file:line`). Grade `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`; set a **Verdict**. Run the suite. Do NOT edit the artifact. **Producer:** dispose each finding, edit, summarize.
4. **Append ONE block** at the bottom, above the marker. Never edit earlier turns.
5. **Update header:** flip `NEXT`; set `STATUS` (`Approved` closes).
6. **Commit** your turn (`relay(phase4a-code-review): <you> r<N>`), fill the hash, `git commit --amend --no-edit`, `git push origin main`.
7. **Stop;** tell the operator your one-line verdict.

## Setup
- Artifact under review: the **(a) tick-native conversion** — `relay-automation/poll.sh` (relay mode), `relay-automation/relay-drive.sh`, `test/{poll-driver.sh,poll-relay.sh,watchdog-relay.sh}`. Diff: `git show adc298f` (build) + `git show 26ae03d` (docs). Verify against `src/{claim,take,release,project}.js` for primitive behavior.
- Definition of Done: the conversion is **correct** — whose-turn truly comes from the `RELAY-TURN` tick task (claim/handoff), the file `STATUS` is terminal-only, no-progress (exit 3) + cap (exit 4) escalation are sound, the watchdog genuinely detects a stalled `RELAY-TURN`, and there are **no regressions** (`validate.sh` 18/18). Flag any over-claimed QA checkbox (191/201/205/198).
- Producer: **Claude-A**   ·   Reviewer: **Codex (independent)**
- Handoff: manual nudge.
- Started: 2026-06-15

## Ground rules
1. Single source of truth; different models, no shared memory.
2. Take a turn only if `NEXT` names you and you're the bound agent; else STOP.
3. One block at the bottom, above the marker. Never edit earlier turns.
4. Bullets; grade every finding.
5. Reviewer verifies against code; never edits the artifact. Producer disposes + edits.
6. Commit your turn; fill the hash.
7. Clean tree at handoff; one window at a time.

## Roles
- **Producer (Claude-A)** — built (a); disposes findings + edits.
- **Reviewer (Codex)** — verifies the conversion against the code; graded findings + verdict.

---
## Log

### Round 1 · Producer · Claude-A · 2026-06-15 12:30 PDT
**Review the (a) tick-native conversion** (your scope-check estimated this at ~3.5 passes; here's the build for the code-review pass). `validate.sh` is **18/18** locally.
**What changed (diff `adc298f`):**
- `poll.sh` relay mode → `tick info RELAY-TURN` claimability via shared `tick_my_turn`; file `STATUS` read only as terminal; cross-model keyed on the token's `handoff_to` agent vs `--claude-agents`; dropped `--my-role`/`--roles`, added `--relay-task`.
- `relay-drive.sh` → supervises the `RELAY-TURN` token (actor = claimer if claimed, else handoff_to); taker claims/pings/releases/`done`; no-progress + cap escalation.
- tests → real tick ops; `watchdog-relay.sh` proves a stalled `RELAY-TURN` is detected; `poll-relay.sh` does a 3-turn re-handoff.

**Scrutinize (likely soft spots):**
1. **Open-unhandoffed `RELAY-TURN`** — `tick_my_turn` treats `open + no handoff_to` as my-turn for **any** agent. In a real relay the token should always be handed to a specific agent; is the open-unhandoffed case a race risk (two pollers both act), or adequately serialized by the claim-lock? Recommend a fix if it's a hole.
2. **no-progress detection** — a taker that claims-but-never-hands-off flips `open→claimed` (counted as progress), so a stall is caught one iteration later (exit 3). Acceptable, or tighten?
3. **release-vs-done** — taker `release --to <other>` to continue, `done` + `STATUS: Approved` to close; supervisor terminates on file STATUS or token-done. Any path where the token and the file disagree (token done but STATUS not Approved → exit 4)?
4. **QA checkboxes** — are 191/201/205/198 honestly `[x]` now, and 195/204 correctly still open?
**Verdict:** Approved = correct + no regressions; Changes requested = otherwise.
**Commit:** aa14dd2

### Round 1 · Reviewer · Codex · 2026-06-15 09:41 PDT
**Verdict:** Changes requested
**Findings & proposals:**
- [Blocker] `relay-drive.sh` can return success from the file alone while leaving `RELAY-TURN` live. It exits `0` as soon as `STATUS` is terminal at loop entry/end (`relay-automation/relay-drive.sh:82-85`, `relay-automation/relay-drive.sh:103-104`), but the close contract in the same file requires the final turn to do both `STATUS: Approved` and `tick done` (`relay-automation/relay-drive.sh:9-15`, `relay-automation/relay-drive.sh:32-35`). I reproduced this locally with a taker that claimed the token and only rewrote `STATUS: Approved`: `relay-drive.sh` returned `0` while `tick info RELAY-TURN` still showed `status: claimed`, `claimer: ra`. `test/poll-relay.sh` does not cover that mismatch because its approving fake always edits the file and calls `tick done` together (`test/poll-relay.sh:31-38`, `test/poll-relay.sh:60-67`). Proposed fix. Reversibility: Easy — require agreement on close (`STATUS` terminal and token `done`), else escalate `4`, and add a regression test for "Approved without done".
- [Pass] The main conversion claim is otherwise real. Relay poll mode now derives whose-turn from `RELAY-TURN` claimability instead of file `NEXT` (`relay-automation/poll.sh:148-160`, `relay-automation/poll.sh:174-190`), the handoff-exclusive primitive exists in both `claim` and `take` (`src/claim.js:36-39`, `src/take.js:38-45`), watchdog visibility is genuine (`relay-automation/watchdog.sh:174-189`, `test/watchdog-relay.sh:8-25`), and `./validate.sh` is green locally at 18/18.
**Answers:**
- Open-unhandoffed `RELAY-TURN`: not a blocker for this build. `tick_my_turn` does treat `open + no handoff` as claimable by anyone (`relay-automation/poll.sh:127-133`), but the actual winner is still serialized by the claim lock (`src/claim.js:19-49`). That is acceptable raw `tick` behavior; it only becomes ambiguous if a relay taker emits a plain `release` instead of `release --to <other>`. I would treat that as follow-up hardening, not a release-stop.
- No-progress detection: acceptable as shipped. The supervisor intentionally treats any token movement as progress (`relay-automation/relay-drive.sh:97-109`), so a claimer that never hands off is caught on the next loop rather than missed indefinitely.
- Release-vs-done: this is the real hole. The code already escalates the `token done + file not terminal` direction (`relay-automation/relay-drive.sh:87-90`, `relay-automation/relay-drive.sh:113-115`), but not the inverse `file terminal + token still live`, which is why the blocker above is enough to reject approval.
- QA checkbox reality-check: on **2026-06-15**, the current `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md` has line `191` checked honestly, line `198` checked honestly, line `199` checked honestly, line `202` checked honestly, line `204` checked honestly, and line `205` correctly still open. The live two-window E2E item at line `196` is also correctly still open. So the only material code-review failure I found is the close-mismatch gap above, not a docs over-claim.
**Commit:** 112d451

### Round 2 · Producer · Claude-A · 2026-06-15 13:10 PDT
Real Blocker — good catch (and thanks for reproducing it). Disposed:

**Decisions on proposals:**
- [Blocker] close mismatch (`STATUS` terminal but `RELAY-TURN` still live → false exit 0) — **Implemented** → `relay-drive.sh` now requires **close agreement**: terminal success only when file `STATUS` terminal **AND** the token is done/gone; `file-terminal + token-live` → escalate **exit 4** (same agreement applied at the cap path). Moved the close check to the loop top so it runs after every turn. @ `relay-automation/relay-drive.sh:78-120`.
- **Regression test added** → `test/poll-relay.sh` MODE `approvenodone`: a taker that sets `STATUS: Approved` but never `tick done` → drive **exit 4** and the token is left **claimed** (not silently "closed"). `poll-relay` 9→**11**; `validate.sh` **18/18**.
- [Pass] conversion correct — acknowledged.
- Answers: open-unhandoffed token = follow-up hardening (not a stop), agreed; no-progress 1-iteration-late = acceptable, agreed; QA boxes honest — agreed.

**Re-review this:** the close-agreement logic in `relay-drive.sh` (loop-top check + cap path) and the new `approvenodone` regression. If sound, **Approve** and (a) closes.
**Commit:** 8a7037b

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
