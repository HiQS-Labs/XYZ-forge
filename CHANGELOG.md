# Changelog

All notable changes to this repo. Newest first. Dates are PDT.

## 2026-06-16

### Cost observability — Phase 3 shipped (dogfood + xyz-vs-relay comparison)
- **`parseGeminiStats` preamble-skip fix** (`src/cost.js`): `gemini -o json` prefixes its JSON with warning/status lines (color notices, YOLO messages). The parser now finds the first `{` and slices from there — so token capture works on real headless turns. (Previously returned `null`; now correctly parses.) `cost.sh` **23→24** (new preamble-prefix test).
- **Live `-o json` relay turn validated end-to-end** (`relay-system/2026-06-16/p3-dogfood-relay.md`): a real headless Gemini turn editing a relay file under `-o json` mode worked correctly. Tokens captured: in=33 128, out=76 880, total=110 008. The deferred item from Phase 1 is now closed.
- **Transcript copy confirmed deterministic:** `$TMPDIR/p3-gemini-turn.json` → `relay-system/2026-06-16/p3-dogfood-relay.gemini-transcript.md` via a scripted shell step (not a prompt instruction). File exists and is committed.
- **xyz synthetic fixture** (`$TMPDIR/p3-xyz`): 4 tasks, 2 agents (alpha=Gemini lane, beta=Codex lane), token counts sampled from real session turns. `tick analyze` → `tokens_total=58920`, coverage `4/4`, `run_type=symmetric`.
- **Relay real run** (`$TMPDIR/p3-relay`): P3-RELAY task, 1 done-task, Gemini reviewer. `tick analyze` → `tokens_total=110008`, coverage `1/1`, `run_type=asymmetric`.
- **`COST-COMPARISON.md`** written to `PROJECT/2-WORKING/COST-COMPARISON.md` — comparison table with `tokens/done` (xyz=14730 vs relay=110008), `run_type`, coverage; every cell from `tick analyze --format json`. Data-provenance + apples-to-apples caveats included.
- **`FEEDBACK-2026-06-15.md` point 5 closed:** "Cross-system takeaway" now includes real cost-per-unit figures; the cost measurement gap documented in the original feedback is resolved.
- Full suite **22/22**; `cost.sh` **24/24**.

### Cost observability — Phase 2 shipped (analyzer computes cost)
- **`tick analyze` now emits a `cost` section** (human + md + json), additive to the coordination metrics: tokens total + `by_agent`, per-task/per-agent wall-clock (from closed claim windows), `human_minutes_total`, and **cost-per-done-task** (`tokens_per_done`, `walltime_per_done_ms`; `null`→`n/a` on zero done, no divide-by-zero). New pure `computeCost` in `src/analyze.js`.
- **`run_type` flag** (`symmetric|asymmetric`) — operator-set via `TICK_RUN_TYPE`; invalid/unset → `unspecified`. We never auto-guess whether a comparison is fair (Gemini r1 [Nit]).
- **Loud-partial floor** (Gemini r1 [Should]): coverage is measured against **distinct done-tasks** (Gemini Q2 — hardest unit to game); when incomplete, totals render as `≥N` with `coverage: X/Y done-tasks` and an explicit "lower bound" note, so a floor never reads as an exact sum.
- **No regression:** coordination subset of `analyze --format json` is byte-identical before/after cost events; `computeCost` is pure (no clock/LLM/pricing). `cost.sh` **14→23**; full suite **22/22**. Plan: Phase 2 ✅; Phase 3 (dogfood + xyz-vs-relay comparison) next. Added a consolidated **Deferred/backlog** section to the plan so the Codex/Claude token gaps aren't buried.

### Cost observability — Phase 1 shipped (deterministic cost signals)
- **New event types** `cost.tokens` + `cost.human` (`src/events.js`) — additive; `appendEvent` stamps cost fields only when present, so non-cost events stay byte-identical.
- **`tick cost` verb** (`bin/tick`): `--human-minutes <n>` (self-reported operator attention), `--tokens-in/--tokens-out [--tokens-total] [--tool]`, and `--from-gemini-json <file>` (parse + log in one step).
- **`src/cost.js` `parseGeminiStats`** — pure, deterministic; sums `stats.models.*.tokens` from `gemini -o json` verbatim (Q1 resolved — the CLI report is the source of truth, no wrapper). `tokens_out = total − input` (captures reasoning "thoughts"). Returns `null` on non-json/no-stats so the caller emits a loud-partial signal, never a fake zero.
- **Headless token capture wired** into `gemini-turn.sh`: runs `gemini -o json`, then best-effort `tick cost --from-gemini-json` after the boundary holds — **never fails the turn**.
- **Transcript fix (the headless-mode gap):** `GEMINI_LOG`/`CODEX_LOG` now default to a `$TMPDIR` path, not the repo tree — the guard at `relay-turn-lib.sh:64-65` deletes any in-tree log, which is why headless transcripts kept vanishing. The persisted json transcript doubles as the token source.
- **No regression:** `analyze.js` explicitly excludes `cost.*` from coordination math (`:158`) — every concurrency/parked/count number stays identical. New `test/cost.sh` **14/14** (incl. a byte-identical `analyze --format json` before/after cost events). Full suite **22/22**. Skill package regenerated (bundles the two changed turn-takers); `skill-extract` confirms not-stale.
- **Deferred, honestly:** Codex token parsing (format un-probed) and Claude-orchestrator tokens (no shell-visible per-turn count) — both noted in the plan, not faked. Plan: `PROJECT/2-WORKING/COST-OBSERVABILITY-PLAN.md` (Phase 1 ✅; Phase 2 = analyzer cost math next).

## 2026-06-15

### Cost-observability plan drafted + approved via live Gemini relay
- New plan `PROJECT/2-WORKING/COST-OBSERVABILITY-PLAN.md` — closes point 5 of `FEEDBACK-2026-06-15.md`: the deterministic analyzer (`src/analyze.js`) measures coordination but **no cost**, so xyz vs relay can't be compared on cost-per-unit. Plan adds 3 cost signals (tokens, wall-clock, human-minutes) to the same no-LLM analyzer, in 3 phases each with observable checklists + QA gates.
- **Drove a live `gemini -p` cross-model review** of the plan (`relay-drive.sh` + `gemini-turn.sh`, token `RELAY-COST`). Verdict **[Pass]**; 2 findings disposed: **[Should]** render incomplete token coverage as a *floor* (`≥N (partial 2/3)`), **[Nit]** add `run_type: symmetric|asymmetric` to json so downstream can't blind-compare asymmetric runs. Gemini answered all 4 open questions (CLI tokens verbatim; `tasks done` denominator; self-report human-min OK; **fresh symmetric fixture** for the comparison).
- **Transcript-guard finding:** the in-tree log guard (`relay-turn-lib.sh:64-65`) `rm`s any transcript that lands in the tracked tree — so headless transcripts must be written to `$TMPDIR` then copied out. Did exactly that: `relay-system/2026-06-15/cost-observability-plan-review.gemini-transcript.md`. Baked the deterministic copy step into the plan (Phase 3) so it's a scripted step, not an agent reminder.
- Relay thread: `relay-system/2026-06-15/cost-observability-plan-review.md` (Approved/closed). Committed locally; **not pushed**.

### Live Gemini CLI review of portability fixes + ROADMAP → 1 more bug fixed
- Drove a **live `gemini -p` review turn** (via `gemini-turn.sh`) over `relay-turn-lib.sh`, `codex-turn.sh`, and `ROADMAP.md`. **2nd live containment win:** Gemini also tried to edit `ROADMAP.md` (off-allowlist) → the shared guard reverted it + failed the turn (exit 6); the review (allowlisted relay file) survived.
- **[Should] rename-hijack fixed:** Gemini found that the [1] pre-existing-dirty skip matched only a rename's *destination* field — a staged rename could hide a clean file's move. Fixed: a rename is pre-existing only if **both** dest+src were dirty pre-turn, else both paths are enforced. Regression added (`test/codex-turn.sh` case 9). `codex-turn` 23→**24**.
- **[Nit] R5** (resource/quota limits for runaway agents) added to ROADMAP. `validate.sh` 21/21.
- Relay thread: `relay-system/2026-06-15/portability-roadmap-gemini-review.md` (Approved/closed).

### Portability hardening from MBP16 cross-repo field report (shared core)
- **[1] Pre-existing dirty-state safety (high):** `relay-turn-lib.sh` now snapshots the dirty set *before* the turn (`rtl_before` → `RTL_BEFORE`) and only enforces/reverts paths the agent *newly* changed — never pre-existing ambient WIP. Fixes a real data-loss bug (the old guard `rm`/`checkout`'d unrelated dirty files + failed the turn). Applies to **both** Codex and Gemini (shared core).
- **[2] `.tick/` portability (high = ROADMAP G5):** `.tick/` paths are now exempt from allowlist enforcement *intrinsically*, independent of the host repo's `.gitignore` — so a relay can run in a repo that doesn't ignore `.tick`.
- **[3] Codex autonomy flags:** `codex-turn.sh` passes `CODEX_FLAGS` (default `-s workspace-write`) to `codex exec`, so a fresh device can actually write the relay file; overridable for tighter/looser policy. QUICKSTART autonomy check updated to one that truly writes.
- Tests: `test/codex-turn.sh` **16 → 23**, `test/gemini-turn.sh` **13 → 17** (pre-existing-WIP preserved, `.tick` exemption, flag plumbing). `validate.sh` **21/21**; package regenerated. Field report archived at `PROJECT/1-INBOX/EXP-AUTOMATION/FEEDBACK-MBP16.md`. ([4] cross-repo ergonomics deferred.)

### `ROADMAP.md` — commercial-viability gaps (adversarial proof)
- New `ROADMAP.md`: maturity ladder (mechanically proven → adversarially proven → commercially viable) + the 5 deliberate-failure proofs a buyer needs: G1 mid-turn termination, G2 duplicate/ambiguous token, **G3 stale-writer fencing (missing mechanism — needs epoch fencing tokens)**, G4 concurrent pollers, G5 cross-repo/model diversity. Each maps to the existing mechanism with honest status; implied hardening items R1–R4. G3 flagged as the credibility keystone (today's `tick` has ownership checks but no epoch fence).

### Gemini CLI integrated → `gemini-turn.sh` SHIPPED + live-validated; safety core shared
- **Installed + authed Gemini CLI** (`brew install gemini-cli`, 0.46.0) — GCA personal-login auth (`GOOGLE_GENAI_USE_GCA=true`, no API key); headless = `gemini --yolo --skip-trust -p`.
- **Shared-core refactor (the "improved architecture"):** extracted the model-agnostic containment contract into `relay-automation/relay-turn-lib.sh` (sourced). `codex-turn.sh` is now a thin dispatch wrapper over it; **`gemini-turn.sh`** is the Gemini wrapper. The boundary (allowlist + commit-bypass + no-push) lives in **one** place — no reimplementation.
- **Reconciled the two Gemini drafts.** Gemini independently committed a standalone `gemini-turn.sh` (`fe0bd61`) — same boundary logic, but copied Codex's `codex exec` pattern: it called **`gemini exec`**, which the Gemini CLI does not have (headless is `-p`), and lacked GCA/`--yolo`/`--skip-trust`, so it would not run live. Converged on **one** `gemini-turn.sh` = Gemini's name/convention + the shared-core architecture + the corrected, live-validated invocation. (My parallel `gemini-drive.sh` was removed — I'd missed Gemini's file and duplicated it.)
- **Live-validated end-to-end:** a real `gemini -p` turn reviewed a seeded `sample.sh` (found 3 correct graded findings + verdict), edited **only** the relay file, committed file-scoped, **no push**; the artifact was never touched (containment held). Isolated temp repo, `bin/tick` passthrough.
- **Prompt fix from the live run:** Gemini released the token to the literal role "Producer" (peer was unnamed) → added optional `RELAY_PEER` to name the handoff target explicitly.
- `test/gemini-turn.sh` **13/13** (mirrors the codex guard suite); `validate.sh` **21/21**; package regenerated (13 files).

### decision recorded + `gemini-drive.sh` in flight
- `decisions/2026-06-15-unattended-agent-containment.md` — **Decided**: path-allowlist + commit-bypass guard + no-push is sufficient containment for an unattended committing agent. 3-model validated; revisit on the first real unattended Option-A run. Linked from RECAP, 4X4, CROSSMODEL-OPTIONA-PLAN.
- **In flight (built by Gemini):** `gemini-drive.sh` — a sibling turn-taker for Gemini itself (same role as `codex-turn.sh`), expected to adopt the 3 containment invariants. Extends Option A to a 3rd model.

### relay-automation — `QUICKSTART.md` for fresh-device test
- `relay-automation/QUICKSTART.md`: clone → prereq check (node/codex-authed/git) → `validate.sh` 20/20 → one headless Codex turn behind the shim. Notes `.tick/` is per-device local (single-device test, not cross-machine coordination yet) and the no-push contract.

### relay-automation — Gemini (3rd model) hardened `codex-turn.sh` — 2 Blockers fixed → **Approved/closed**
- Manual `/relay` with **Gemini** as Reviewer over `codex-turn.sh` (`relay-system/2026-06-15/codex-turn-review-gemini.md`) — third model, validates the portable relay generalizes beyond Claude/Codex. **r3: Gemini re-reviewed the fixes and Approved — relay closed.** The shim's safety boundary is now **3-model validated** (Claude authored → Codex added allowlist/no-push → Gemini found+cleared 2 bypasses through it). It found **two real bypasses neither I nor Codex caught**:
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
