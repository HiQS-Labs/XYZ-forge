# Changelog

All notable changes to this repo. Newest first. Dates are PDT.

## 2026-06-15

### relay-automation — `QUICKSTART.md` for fresh-device test
- `relay-automation/QUICKSTART.md`: clone → prereq check (node/codex-authed/git) → `validate.sh` 20/20 → one headless Codex turn behind the shim. Notes `.tick/` is per-device local (single-device test, not cross-machine coordination yet) and the no-push contract.

### relay-automation — Gemini (3rd model) hardened `codex-turn.sh` — 2 Blockers fixed
- Manual `/relay` with **Gemini** as Reviewer over `codex-turn.sh` (`relay-system/2026-06-15/codex-turn-review-gemini.md`) — third model, validates the portable relay generalizes beyond Claude/Codex. It found **two real bypasses neither I nor Codex caught**:
  - **git-commit bypass** — if Codex commits mid-turn, edits leave `git status` clean → allowlist sees nothing. Fixed: capture `before_head`, `reset --hard` + **exit 6** if HEAD moved.
  - **quoted-path bypass** — porcelain quotes paths with spaces; `${line:3}` kept the quotes so revert failed. Fixed: `git status --porcelain -z` (raw paths) + `check_path` helper handling `R`/`C` rename two-field records.
  - **[Should] ignored files** — declined `git clean -Xdf` (would destroy `.tick` coordination state); documented the limit + deferred to the codex sandbox.
- `test/codex-turn.sh` **10 → 16** (commit-bypass + spaced-path guards); `validate.sh` **20/20**; tarball regenerated.

### relay-automation — Phase 5 SHIPPED → PROJECT COMPLETE (Phases 1–5) ✅
- `skill/relay-automation/` — sibling self-contained skill: `SKILL.md` (E3 capability gate + install), `relay-pkg.tar.gz` (the 5 relay scripts + README + 4 tests, regenerable via `make-pkg.sh`), `test/skill-extract.sh` (extract + parse + no-drift). `validate.sh` **20/20**.
- **All proposal phases done:** 1 turn-token, 2 watchdog, 3 verdict-gating, 4 hands-free poll (+ tick-native relay turns, self-expiring loops), 5 packaging — plus cross-model (Claude↔Codex) + Option-A headless turns live-proven. Project DoD met.

### relay-automation — Cross-model relay (Claude↔Codex) SHIPPED ✅ (Option A live)
- Plan Codex-reviewed headlessly (`codex exec`) → Changes requested → disposed into a mandatory safety shim.
- **`codex-turn.sh`**: drives a Codex relay turn via `codex exec` behind a hard path-allowlist — dispatches only for the Codex agent, reverts any off-lane edit + fails, commits file-scoped, **no push** (coordination is shared-local `.tick`). `test/codex-turn.sh` 10/10; `validate.sh` **19/19**.
- **Live X2 proven:** a real `codex exec` turn (no window) reviewed a seeded artifact, wrote a graded block + verdict, released the token; shim committed only `relay.md`, no push. **Cross-model coordination + Option A end-to-end.** (Self-expiring loops `--deadline` also added.)

### relay-automation — Option A (headless CLI) spike PASSED ✅
- Codex CLI installed → ran the deferred headless-auth spike: `codex exec "<prompt>"` is non-interactive, authed, emits a parseable `VERDICT:`, exit 0 (~11k tokens/trivial turn; wire as `codex exec ... < /dev/null`). **Option A unblocked.** Next: wire `codex exec` as the relay turn-taker for a Claude↔Codex cross-model relay (closes item 196 cross-model). Recorded in `PHASE-2-PLAN.md` → Future upgrade.

### relay-automation — Phase-5 plan drafted + FIRST hands-free dogfood ✅
- Drafted `PHASE-5-PLAN.md` (package as sibling skill + real-run metrics).
- **Dogfood: first real end-to-end automated relay** (tick `RELAY-TURN` + `poll.sh`/`/loop`, all-Claude) reviewing the Phase-5 plan → closed **Approved in 2 rounds with 0 turn-advancement nudges**. Claude-B adopted via its `/loop`, Claude-A via cron. Plan review adopted **E3** (detect-or-extract + capability gate) over E1.
- Findings: fixed `poll.sh` empty-`--claude-agents` crash (+ regression); added `.claude/settings.local.json` relay-automation allowlist (permission gate stalled the loop); parked-detector flags *closed* windows (Phase-2 follow-up); claim-before-release ordering; designate one `--watchdog-authority` poller for real runs. Full metrics in `REAL-AGENT-OBSERVATIONS.md`.

### relay-automation — (a) COMPLETE: Codex-approved ✅
- Codex r2 **Approved** (`relay-system/2026-06-15/phase4a-code-review.md`): re-ran validate 18/18, poll-relay 11/11, watchdog-relay 4/4; confirmed the close-agreement fix and no new issues. Decision `relay-turns-tick-native` → **Validated** (expected signal met: watchdog detects a stalled RELAY-TURN). **Only Phase 5 (package as sibling skill) remains.**

### relay-automation — (a) code review (Codex): close-mismatch Blocker fixed
- Codex caught + reproduced: `relay-drive.sh` reported success (exit 0) when the file `STATUS` was terminal even if the `RELAY-TURN` token was still live (Approved-without-`done` → leaked claim). Fix: terminal success now requires **close agreement** (file terminal AND token done/gone); else escalate exit 4. Regression test `approvenodone` added → `poll-relay` 11, `validate.sh` 18/18.

### relay-automation — (a) relay turns are now tick-native ✅
- `poll.sh` relay mode: whose-turn from `tick info RELAY-TURN` claimability (shared with xyz); the relay file's `STATUS` is the terminal signal only; cross-model keyed on the token's handoff agent; dropped `--my-role`/`--roles`, added `--relay-task`.
- `relay-drive.sh`: supervises the `RELAY-TURN` token (actor = claimer/handoff); turn-taker claims/pings/releases/`done`; no-progress (exit 3) + cap (exit 4) escalation.
- Tests converted to **real tick ops**; **+`test/watchdog-relay.sh`** (a stalled `RELAY-TURN` is detected + escalated — the payoff (a) buys) and a **3-turn re-handoff** proof in `poll-relay.sh`. `validate.sh` 17 → **18**.
- Phase-4 QA checkboxes: 191 (guard), 201 (DRY), 205 (no-deadlock), 198 (cache-warmth note) now `[x]` → **10/12** (open: live two-window E2E, race hammer-test).
- Docs: README relay usage + cache-warmth note; PHASE-4-PLAN banner; project hub + proposal status. **Next: Codex code-review relay for (a).**
- Operator refocus: standalone project hub `PROJECT/2-WORKING/AUTOMATED-RELAY.md`; XYZ-swarm progress deferred (relay is higher daily-use).


### relay-automation — Phase 4 complete (hands-free poll, Option B: baton + poll)
- **4a** `relay-automation/poll.sh` — per-tick poll driver: two modes (xyz/relay), split guard→dispatch (runner: my-turn+clean · watchdog: parked+designated-authority → no double-escalate), artifact-scoped clean-tree check, cross-model nudge, `--dry-run` + guarded live dispatch. `test/poll-driver.sh` 12/12.
- **4b** `relay-automation/relay-drive.sh` — relay-turn supervisor: loops a `/relay` Producer↔Reviewer thread to termination via the turn-taker (`--agent-cmd` seam), round cap + no-progress escalation (exit 3) + cap escalation (exit 4). `test/poll-relay.sh` 8/8.
- **4c** `relay-automation/README.md` — operator docs: `/loop` invocations, designated-watchdog poller, single-process supervision, cross-model one-line baton nudge, all-Claude boundary.
- `validate.sh`: 15 → **17 tests** (`poll-driver.sh`, `poll-relay.sh` added).
- Execution contract decided **Option B** (headless-CLI spike found no agent CLI present); Option A (unattended) documented as a future upgrade in `PHASE-2-PLAN.md`.
- Phase-4 plan relay-reviewed by Codex (2 Blockers + 1 Should applied): split guard, artifact-scoped clean check, two-mode poll, solo-lane build.

### Process
- Embedded a self-contained `▶ TAKE YOUR TURN` block into relay docs **and** the parent `/relay` skill (giant-brains repo) so cross-model relays are a one-line nudge.
- Graduate-to-Phase-2 decision recorded, then **Decided** after operator accepted the 39% concurrency datapoint (start-skew, not load imbalance — de-gated).
- Added this CHANGELOG; began keeping it + `RECAP.md` current per change.
- **Phase 4 QA checkboxes reviewed in the proposal:** 8/12 initially marked done (guard, graceful degradation, operating-model note, DRY, SOLID, observability, anti-goal, remote-deploy=No). Left open honestly: live two-window end-to-end run, race hammer-test, no-deadlock E2E (all need a live two-window run), and the cache-warmth interval note (doc TODO).
- **Phase-4 QA-gate relay (Codex) — Approved (r2).** Codex found 2 over-claims → reverted items 191 (guard) + 201 (DRY) to `[ ]`: the relay driver shipped on the baton file's `NEXT`/`STATUS`, not a tick-native `RELAY-TURN` task, so Phase-1 handoff-exclusive enforcement isn't used by the relay path (only xyz build turns). Codex then confirmed all marks honest → **6/12 checked, 6 open**.
- **Decided: relay turns go tick-native (Option a)** — `decisions/2026-06-15-relay-turns-tick-native.md`. Convert the relay turn-token to a `RELAY-TURN` tick task so the relay path uses the Phase-1 rule + is watchdog-visible (self-healing). Resolves the fork. Next: revise Phase-4 plan → build → Codex review.
- **(a) scope reality-checked (Codex single-round-trip relay):** my ~2.5-pass estimate was rosy → revised to **~3.5 passes / ~4–5h** (`relay-automation/PHASE-4A-SCOPE.md`). Conversion work, no new core; cost is the relay poll/supervisor/**test** rewrite off `NEXT`/`sed` onto a real `RELAY-TURN`. Operator deciding timing.

## 2026-06-14

### Run 5 — Phase-2 build (watchdog ‖ runner), 2-Codex swarm
- `watchdog.sh` real structured JSON escalation; `runner.sh` verdict-gated turn loop with injectable `--agent-cmd`. Both lanes done, `validate.sh` 13 → 15.
- Work-bounded concurrency **39%** (start-skew, not load imbalance); recorded as a valid datapoint.

### Run 4 — meta-exercise (swarm builds relay-automation Phase 1)
- Handoff-exclusive `tick` rule (`src/claim.js`, `src/take.js`) + `test/handoff-exclusive.sh`; `runner.sh`/`watchdog.sh` skeletons. `validate.sh` 12 → 13.
- Work-bounded concurrency **72.2%** (cleared ≥50% bar); both acceptances green.
- Agent feedback folded in: build-prompt "initiative bound" (xyz skill), test-harness `TICK_REPO_ROOT=$A` default.

_Earlier history: see `RECAP.md` (Runs 1–3) and `REAL-AGENT-OBSERVATIONS.md`._
