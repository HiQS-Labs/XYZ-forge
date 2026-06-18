# Changelog

All notable changes to this repo. Newest first. Dates are PDT.

## 2026-06-17

### `consult` skill — anchor `consult.sh` to the repo root (stop the disk-hunt)
- **`skill/consult/SKILL.md`** (commit `2b19029`): the skill referenced the script only as bare `consult.sh` / `relay-automation/consult.sh` — paths that are relative to the **repo root** but were never labeled as such — so a session whose cwd wasn't the root couldn't resolve them and resorted to searching the disk for the file (reported by a separate session). Added a **"Locating the script"** recipe under *How it works* (`SCRIPT="$(git rev-parse --show-toplevel)/relay-automation/consult.sh"`, resolves from any subdir of the repo) and rewired **step 2 (Fan out)** to invoke through that anchor with an explicit "don't run a bare `consult.sh`" note. Docs-only; the script already self-anchors (`consult.sh:47-48`), so no behavior change — the caller just no longer has to guess where it lives. (Re-applied + committed because an active autonomous marathon run on this branch kept reverting the uncommitted working-tree edit to HEAD.)

### Part A Phase 3 — DOGFOOD: autonomous marathon built a real test (+ 4 safety findings)
First real-code dogfood on branch `feat/marathon-phase3`: an autonomous Claude builder + Codex reviewer, tasked (via `--artifact`) with building `test/chaos-concurrent-pollers.sh` (Part B G4), gated on the test running green.
- **Real code out — achieved.** The builder produced a **correct, sound** G4 chaos test: 20 trials, two concurrent `tick claim` races per trial, asserts exactly one `won:` (the other gets `lost:`), winners split across both pollers (genuine race vs the `O_EXCL` lock in `withClaimLock`, not serialization). Reviewed + verified independently (fail() aborts on any double-claim — no false-green; `tick claim` win/lose markers discriminate correctly). **Salvaged + wired into `validate.sh` → 26/26.**
- **But the builder went off-task — exposing 4 findings no unit test would.** Pulled in by stray untracked briefs in the repo (`AUDIT/REBALANCE-BRIEF.md`, about a *different* project), it ran the `consult` skill on an unrelated rebalance-OS privacy question — spawning **real Codex + Gemini API calls** — and edited `skill/consult/SKILL.md`:
  1. **Tracked-file containment HELD** — `rtl_enforce` caught + reverted the `SKILL.md` edit and failed the turn (exit 6). The core guarantee works live against a rogue agent. ✅
  2. **Containment is point-in-time, not async-safe** — the `consult` subprocess outlived the turn and re-dirtied `SKILL.md` + left untracked output (`relay-system/2026-06-17/privacy-seam-192658/`) AFTER enforcement ran. ⚠️
  3. **Broad `Bash` = unbounded side effects** — the file allowlist bounds tracked edits, not spawned processes / external API calls. ⚠️
  4. **`marathon-drive` mishandles turn exit 6** — dies "unexpected code 6" instead of a clean `ESCALATION.md`. ⚠️
- **Cleanup:** reverted the rogue `SKILL.md` edit; left the stray consult output in place (flagged — it contains a real review of the operator's rebalance-OS). Findings captured as ROADMAP Phase 3.6 (harden-next).

### Part A Phase 3.5 — `--artifact`: marathon can now produce REAL code (not just relay conversations)
- **`marathon-drive.sh` gains `--artifact PATHS`** (comma-separated repo-relative files). When set, the driver exports `ALLOW_PATHS` to the turn-takers (a flag all three shims already honor) and renders the relay template with a real write surface: the builder is told to *create/edit the artifact*, the tick `claim --paths` declares `relay,artifact`, and the edit-scope line allows `RELAY.md + artifact` (reviewer still edits only the relay). Without `--artifact` the phase stays relay-only and `ALLOW_PATHS` is left unset — containment default unchanged. This is the piece that turns the loop-prover into a code-producer: the shared safety core (`relay-turn-lib.sh`) still reverts any edit outside the declared allowlist, so the builder gains exactly one bounded write surface and nothing more.
- **`test/marathon-drive.sh` +4 cases (now 31):** artifact path baked into the relay; `claim --paths` includes relay+artifact; `ALLOW_PATHS` exported to the turn-taker env (eval-ing stub relay-drive + env-recording agent); relay-only phase leaves `ALLOW_PATHS` UNSET (containment regression guard). `validate.sh` **25/25**.

### Part A Phase 3 — REAL multi-model end-to-end validated, BOTH reviewers (3 integration bugs found + fixed)
First **un-stubbed** runs of the full chain (`marathon-drive` → real `relay-drive` → `marathon-agent` → real `claude-turn` builder + real `gemini-turn`/`codex-turn` reviewer) on throwaway fixtures. Every prior `marathon-drive` test used a *stub* relay-drive, so the composition had never actually run. **Result: both Gemini-reviewer and Codex-reviewer phases reach `STATUS: Approved` in 2 turns, EXIT 0.** Three real bugs surfaced that no stub could catch:
- **Bug 1 — spaced agent-cmd path broke `relay-drive`'s `eval`.** `relay-drive.sh:110` runs the turn-taker via `eval "$AGENT_CMD"`; the repo path contains a space (`GH Repos`), so the un-quoted path split and tried to exec `/Users/noelsaw/Documents/GH`. **Fix:** `marathon-drive.sh` now `printf %q`-quotes `--agent-cmd` before handing it to relay-drive (relay-drive stays unmodified — its `eval` is by-design for agent-cmds-with-args). Regression test added (`test/marathon-drive.sh` case 11: a spaced-path agent + an `eval`-ing stub relay-drive — fails pre-fix, passes post-fix). **27/27.**
- **Bug 2 — headless `claude -p` inherited the operator's ambient model.** With the interactive session switched to `opus[1m]`, the *builder* turn silently ran `claude-opus-4-8[1m]` and blew the `$0.50` cap (sized for Sonnet) in 4 turns ($0.53) → `error_max_budget_usd`, hard-stopped mid-build. The budget cap **worked** (caught the runaway), but cost was non-deterministic. **Fix:** `claude-turn.sh` now pins `--model` (default `claude-sonnet-4-6`, override via `CLAUDE_MODEL`); ceilings are documented as valid only for the pinned model. Regression test added (`test/claude-turn.sh`: asserts `--model` is passed). **28/28.**
- **Bug 3 — relative `./bin/tick` in the relay template made the builder skip the handoff.** A headless turn's cwd is not guaranteed to be the repo root, so the template's `./bin/tick` instruction was a guess. On the first Codex run the builder looked for it in the phase dir, logged *"tick not present"*, and **skipped the entire token claim/release** — the token never moved, relay-drive's no-progress guard fired (exit 3, working as designed), and **Codex never got a turn** (not a Codex bug — the builder never handed off). **Fix:** `marathon-drive.sh` now bakes the **absolute** tick path (`TICK_CLI`) into the rendered relay for every token instruction, runnable from any cwd. This unblocked Codex *and* made the builder handoff reliable (the next run showed `claude-claimed`/`claude-released`, previously absent).
- **Post-fix result (both reviewers):** `EXIT 0`, `STATUS: Approved` in **2 turns**, builder pinned to `claude-sonnet-4-6` (~$0.16–0.35, under cap), clean tick chain (`claude` claimed→heartbeat→released → reviewer claimed→heartbeat→done), `marathon.phase.approved` emitted, transcript saved, every turn committed file-scoped (no push). **Gemini reviewer:** proven (wall 117s). **Codex reviewer:** proven (wall 98s; sandbox-off required — Codex keychain/`chatgpt.com` blocked inside Claude Code's Bash sandbox). `validate.sh` **25/25**.
- **Honest gap for "real code out":** the relay template still instructs the builder to *"Edit ONLY phases/p1/RELAY.md."* — so today a phase drives a relay *conversation* to approval, not a real source edit. Producing committed feature code needs a small enhancement (thread `ALLOW_PATHS` for the artifact + relax that template line). Tracked as the next step before dogfooding a real backlog task.

### Part A Phase 3 — Single-phase headless loop (Sonnet High build)
- **`relay-automation/marathon-drive.sh`** — new single-phase driver: renders `phases/p1/RELAY.md` from the phase brief template, seeds `MARATHON-P1-TURN` tick token (task.created → claim → release --to builder), calls `relay-drive.sh --agent-cmd marathon-agent.sh --round-cap N` unmodified, runs `--pre-advance-cmd` gate before emitting `marathon.phase.approved`, saves transcript to `relay-system/<date>/marathon-p1-<time>.md`. On failure: writes `phases/p1/ESCALATION.md` + emits `marathon.phase.escalated`; exits 3 (no-progress), 4 (cap/mismatch), 5 (pre-advance gate failed).
- **`relay-automation/marathon-agent.sh`** — updated: added `RELAY_PEER` threading block before the `case` statement. When `MARATHON_BUILDER`/`MARATHON_REVIEWER` are both set, the dispatcher sets `RELAY_PEER` to the opposite role before exec-ing the shim. Prevents the 2026-06-15 Gemini "release to literal role-string" failure in live marathon runs.
- **`src/events.js`** — added `marathon.phase.*` event types (`marathon.phase.start`, `marathon.phase.approved`, `marathon.phase.escalated`, `marathon.phase.revision`, `marathon.complete`) to `EVENT_TYPES`. Root cause of initial test failures: driver emitted `marathon.phase.start` before calling relay-drive; `tick log` rejected the unknown type; `set -euo pipefail` killed the driver before relay-drive was ever invoked.
- **`test/marathon-drive.sh`** — 26-case test suite covering: dry-run (exit 0, no commit, no staged changes, HEAD stable), relay template sections (builder/reviewer TAKE-YOUR-TURN, STATUS: Open, brief text baked in), tick seeding, relay-drive arg pass-through (`--relay-file`, `--relay-task`, `--round-cap`, `--agent-cmd`), happy path (transcript saved, `marathon.phase.approved` event), pre-advance failure (exit 5, ESCALATION.md, reason field), relay cap (exit 4, ESCALATION.md, relay-drive-exit field), no-progress (exit 3, ESCALATION.md), RELAY_PEER threading, custom round-cap. Key fix: wipe `.tick/` **and** reset to `INIT_HEAD` between cases — residual tick state from prior cases caused tick claim/release to fail on terminal-state tasks; accumulated git commits caused `git commit` to exit 1 on identical relay content. Both required.
- **`validate.sh`** — `marathon-drive.sh` added to TESTS array. Suite: **25/25** (was 24/24).
- **ROADMAP Phase 3 checklist:** all items ✅. Phase 3 complete.

### Part A Phase 2 — Marathon dispatcher + headless builder (Sonnet High build)
- **`relay-automation/marathon-agent.sh`** — new dispatcher shim: `case "$RELAY_AGENT"` router that execs `claude-turn.sh`, `codex-turn.sh`, or `gemini-turn.sh` based on `CLAUDE_AGENT`/`CODEX_AGENT`/`GEMINI_AGENT` env vars; exit 2 on unknown agent. Lets `relay-drive.sh --agent-cmd marathon-agent.sh` handle mixed-model runs with a single `--agent-cmd`.
- **`claude -p` headless spike (M2) — real authenticated turn measured.** JSON schema confirmed: `usage.{input_tokens,cache_read_input_tokens,output_tokens}`, `total_cost_usd`, `duration_ms`, `num_turns`. Auth: subscription credentials from `~/.claude/` — no API key needed. **Measured (Sonnet 4.6, minimal relay turn):** 7 turns · $0.172 · 26s · 207k cache-read + 1.4k output tokens. Ceilings set: `--max-turns 12` (7 observed + headroom), `--max-budget-usd 0.50` ($0.17 observed × ~3× margin). Cache-read bulk is cheap; output tokens ($15/M) dominate on complex turns.
- **`relay-automation/claude-turn.sh`** — new headless builder shim mirroring `codex-turn.sh`/`gemini-turn.sh` on the shared `relay-turn-lib.sh` safety core. Builder allowlist: `"Bash,Read,Edit,Write"` (needs Write to mutate the artifact; reviewers keep the tighter `"Bash,Read"`). Parses `--output-format json` transcript for token cost capture via `tick cost --tokens-in/--tokens-out`. Cost ceilings: `--max-turns 12 --max-budget-usd 0.50` (spike-sized).
- **`test/claude-turn.sh`** — 27-case test suite (defer, good turn, log-in-tree, allowlist violation, commit-bypass, spaced path, ambient WIP, flag assertions, rename-hijack, .tick exemption). Wired into `validate.sh`. Suite: **24/24** (was 23/23).
- **ROADMAP Phase 2 checklist:** `marathon-agent.sh` ✅, `claude -p` spike ✅ (real turn: 7 turns/$0.172/26s), `claude-turn.sh` ✅. Phase 2 complete.

### ROADMAP model-assignment guidance (Sonnet High vs Opus)
- **Added a "Model assignment (build-track guidance)" section to `ROADMAP.md`** (right after the Status table): a per-work-item table splitting the two open build tracks by model. **Sonnet High** for mechanical/pattern-following work (the `claude -p` spike, `marathon-agent.sh`/`claude-turn.sh` shims, `marathon-drive.sh`, chaos *test scripts*, E2E/observability/docs); **Opus** for trust-critical kernel-correctness reasoning (R1 epoch-fencing projection diff, G2 dup-token determinism/quarantine, graduate/iterate/abandon synthesis). Part A Ph4 DAG = Sonnet-implements-against-spec → Opus-reviews-edges. Rationale captured: the mechanical bulk is most of the line-count and the Opus-worthy core is small/self-contained, so the split is also the cheapest.

### Front-door onboarding audit (express) + quick-win doc fixes
- **Ran the `front-door` skill (express)** on the repo: verdict **✅ Smooth** — a cold newcomer with Node + git reaches `./validate.sh` 23/23 green in ~1–2 min, no auth. Secrets scan clean (tracked tree + quick history). One clear front door (root README → relay-automation README/QUICKSTART). Verified the "23/23" claim is accurate (24 `test/*.sh` files but `_setup.sh` is a sourced helper, not a test) and that the `codex-turn`/`gemini-turn`/`consult` tests run against stubs, so the kernel checkpoint needs no real CLI/auth.
- **Quick win — QUICKSTART sandbox note:** added a callout to `relay-automation/QUICKSTART.md` §1 that Codex fails under Claude Code's Bash sandbox (keychain + `chatgpt.com` egress blocked) and the error masquerades as a keychain/login problem — run Codex outside the sandbox. Surfaces the documented root-cause at the point of friction.
- **Quick win — README zero-auth pointer:** added a "👉 New here? run `./validate.sh` (23/23, no accounts/keys)" callout to the top of `README.md` so the auth-free success path is the first thing a newcomer sees.
- **Backlog — medium lifts captured:** added a 5th Strategic Backlog item to `4X4.md` (flagged as exceeding the 4-item cap, to merge/demote) bundling the two medium doc lifts: thin the repo root (~12 root `.md` files) and add an "Access you'll need (Codex ChatGPT login + Gemini GCA auth)" callout to `relay-automation/README.md`.

### Installed `consult` globally + capabilities assessment (dogfooded via `consult`)
- **Installed the `consult` skill** into `~/.claude/skills/consult` (symlink → `skill/consult`, matching the repo-local nature so edits stay in sync). Now registered alongside `xyz` and `relay`.
- **Wrote a two-POV capabilities assessment** (`relay-system/2026-06-17/capabilities-assessment.md`) covering the three features — **Concurrent Swarm** (`xyz`/`tick`), **Automated Relay** (`relay-automation`), and **Consult** — as (1) an honest low-jargon technical read and (2) a marketing read + a sample paid-package message.
- **Dogfooded `consult` on the assessment** (`relay-system/2026-06-17/capabilities-review-143340/`). Graceful degrade: **Gemini answered, Codex failed** on the same host-level macOS keychain/TLS issue seen earlier (`No keychain is available` → no backend) — stated, not silent. Single-advisor run, so each Gemini claim was **verified against source** before accepting (no laundering one model as truth). Synthesis: `…/SYNTHESIS.md`.
- **Four verified corrections applied** to the assessment: (1) test count **12→23** (`validate.sh`; README's "12" line is stale); (2) watchdog "recovers from stalls" → **"escalates"** (reap is a `--allow-reap`-gated stub); (3) added the **no-runtime-enforcement** omission (mutex stops double-*claims*, not out-of-lane *edits* — `README.md:138`); (4) qualified **"hands-free"** (Claude loop only; non-Claude turns emit a manual nudge, `poll.sh:213`). Part 2's marketing-honesty note expanded to asterisk "zero collisions" and "provably safe."
- **Root-caused the Codex degrade → it's the Claude Code Bash sandbox, not Codex/auth.** Clean A/B: sandbox ON → `No keychain is available` + `chatgpt.com` unreachable (identical to the original failure); sandbox OFF → `PROBE_OK`. Cause: the sandbox blocks the macOS keychain (Codex can't load root CA certs for TLS) and doesn't allowlist `chatgpt.com`; **Gemini survives because `googleapis.com` is allowlisted.** Fix documented in `skill/consult/SKILL.md` ("run consult OUTSIDE the Bash sandbox") — safe because consult's isolation is the throwaway worktree + Codex `-s read-only`, not the Bash sandbox.
- **Re-ran the Codex half with sandbox disabled → completed a real two-model panel** (`relay-system/2026-06-17/capabilities-review-codex-144148/`). Reviewing the *corrected* doc, Codex caught **5 more** verified issues both Gemini and the coordinator missed: **[Blocker]** the paid-package sample copy still shipped "collision-proof lanes / converges on its own / sealed off and untouchable" (the honesty note flagged them but the copy wasn't changed) → **rewrote the sample**; concurrency metric "actual overlap" → **"concurrent-claim time"** (`src/analyze.js:67` measures claim-window overlap, not edits); added **`.gitignore`d-files-excluded** caveat (`consult.sh:105`); added **stale-lock-on-hard-kill** limit (`src/lock.js:17`); dropped unsupported **"neither model runs the code"** (advisors *can* exec in-worktree). **9 verified fixes total** (4 Gemini + 5 Codex), all applied. Combined synthesis: `…/capabilities-review-143340/SYNTHESIS.md`.

### Business/marketing-facing capabilities brief (derived from the verified assessment)
- **New `relay-system/2026-06-17/capabilities-brief-business.md`** — reframes the two-POV engineering assessment for **Business Analysts + Marketing Directors**: exec summary, a BA capability/readiness/risk table + risk register, a marketing positioning section with messaging pillars, and a **claims-substantiation table** (tempting claim → defensible wording → what NOT to say) so no external copy outruns the technical record. Pre-screened sample paid-package copy + an "honesty advantage" section.
- **3-sentence accuracy-assurance header** documents the process (claims read from source/tests, cross-model reviewed by Codex+Gemini, 9 corrections verified+applied) and an **Appendix: Substantiation** maps each claim back to its file. Original `capabilities-assessment.md` preserved as the audit trail; the brief is a derivative that cites it for provenance.

### New `consult` skill — one-shot cross-model panel (built + self-dogfooded)
- **New repo-local skill `consult`** (`skill/consult/SKILL.md` + `relay-automation/consult.sh`): fans the
  SAME question to Codex + Gemini **in parallel**, reconciled once — distinct from `relay` (iterative 1:1
  build loop). The script gathers raw opinions; the synthesis (Disagree-first → Agree → reconciled call)
  is the coordinator's job. Transcripts land in `relay-system/<date>/<label>-<HHMMSS>/`.
- **Provable repo-isolation boundary:** advisors run with CWD = a **throwaway git worktree** built from the
  operator's current state (`git stash create` + untracked-non-ignored overlay), so they see WIP/new files
  but their writes are destroyed with the worktree — the real tree is never their surface. Codex also runs
  `-s read-only`. Honest scope: this isolates the *repo*, not the *host process*.
- **Self-dogfooded twice** (the skill reviewing itself via `consult.sh`). Round 1: both models flagged the
  original best-effort post-hoc revert as unsafe (could clobber operator WIP / miss advisor edits) — Codex
  pointed at the repo's own `relay-turn-lib.sh` as the pattern to reuse. **Reworked** to worktree isolation.
  Round 2: both `[Pass]`'d the new boundary ("Blocker-killer"); remaining items applied — narrowed the
  "read-only" claim to **"repo-isolated"** (Gemini `--yolo` isn't a process sandbox), added a portable
  **per-advisor `CONSULT_TIMEOUT`** (default 300s; hung CLI → killed → graceful degrade), and noted
  ignored-file/cost-capture limits honestly. Deferred (logged): Codex-token cost parsing (format un-probed).
- **Tests:** new `test/consult.sh` (13 assertions: WIP preserved, advisor writes can't leak, worktree
  cleanup, graceful degrade, all-fail→5, non-git→3, timeout fires) registered in `validate.sh`. Suite **22→23/23**.
- **Relay skill (Giant Brains repo)** updated separately with a soft pointer: compose with `phase-qa` for
  doc/spec reviews and give completeness its own omission-diff turn.

### Planning-doc QA review of `ROADMAP-COMBINED.md` (headless Codex relay) + fixes
- **Drove a live headless Codex review turn** (`codex exec -s workspace-write`, `gpt-5.4`) over `PROJECT/2-WORKING/ROADMAP-COMBINED.md` via `relay-automation/codex-turn.sh` + the `RELAY-QA` tick token. Codex claimed the token, read the doc + all four `synthesizes:` sources, ran `./validate.sh` itself (22/22), appended graded findings, and closed (`STATUS: Reviewed`, token `done`). Relay thread: `relay-system/2026-06-17/roadmap-combined-qa-review.md` (committed file-scoped `b360e96`, **not pushed**). Containment held — Codex edited only the relay file.
- **Verdict: Changes requested** — three fixes applied to `ROADMAP-COMBINED.md`:
  - **[Blocker] Part A Phase 5 overclaim fixed:** Intent said it dogfooded "the completed system (Cost + Marathon)", but the Marathon dispatcher/builder (Phase 2–4) isn't built (`marathon-agent.sh`/`claude-turn.sh` absent on disk). Reworded to a **relay cost comparison**, with an explicit scope note; checklist "relay/Marathon build" → "relay build".
  - **[Should] Deferred cost blind spots surfaced:** added a note to Part A Phase 1 that token capture is wired for **Gemini** headless turns only — **Codex** (format un-probed) and **Claude-orchestrator** (no shell-visible count) tokens are NOT captured, so multi-model `tokens_total` is a floor.
  - **Synthesis source un-phantomed:** `PROJECT/1-INBOX/LOOPS.md` (a listed `synthesizes:` source) had been committed empty (`ce5763d`); now committed with its real content (the loop-architecture checklist the doc cites for Token Budgeting + the five-step cycle).
- **Concern 3 (worth-it):** keep cost-observability (shipped value) + Part B adversarial hardening (real kernel risks); **gate the Marathon track** on the un-run `claude -p` feasibility spike — Phases 3–5 not "earned" until the builder exists on disk.
- **Env note:** Codex's first turn failed (exit 5) under the Bash sandbox (blocked `chatgpt.com` backend — TLS/keychain); reran with sandbox disabled.

### `ROADMAP-COMBINED.md` made a true superset of `ROADMAP.md` (prep to make it canonical)
- **Manual line-level diff** (Claude orchestrator) found COMBINED Part B was a *compression*, not a superset — Codex's relay review had called it a "faithful compression" but missed that the per-gap rationale was dropped. Ported back from `ROADMAP.md` into each Part B phase: the `> Threat / Prove / Test-artifact / Leans-on / Status` blocks for **G3, G1, G2, G4, G5, R4** (6 `Prove:` + 6 `Leans on`), incl. the design specifics that were lost — G2's deterministic tie-breaker (`earliest ts, then lex agent id`), G4's "token as the mutex", G1's `parked_suspects[]` lean, G3's "ownership enforcement is not epoch fencing". Plus the `4X4.md` backlog pointer + "schema change → decision record before it lands" rule, and the buyer/auditor-replay framing.
- **Promotion done:** `git rm` old root `ROADMAP.md` (the standalone gap-analysis) + `git mv PROJECT/2-WORKING/ROADMAP-COMBINED.md → ROADMAP.md`. The combined roadmap is now the canonical root `ROADMAP.md`. Frontmatter cleaned: dropped the self-referential `ROADMAP.md` from `synthesizes:`, added a `supersedes:` pointer; footer reworded ("now the canonical ROADMAP.md").

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
