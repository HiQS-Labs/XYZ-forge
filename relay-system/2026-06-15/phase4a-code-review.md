# RELAY · Phase-4(a) code review — tick-native relay turns
<!-- Single source of truth. Read the WHOLE file before acting. -->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

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

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
