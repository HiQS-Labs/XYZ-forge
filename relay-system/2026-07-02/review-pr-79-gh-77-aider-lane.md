# RELAY · review PR #79 (GH-77 aider lane)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-02.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(review-pr-79-gh-77-aider-lane): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **pr79.diff** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-02

### Artifact — pr79.diff
```
diff --git a/CHANGELOG.md b/CHANGELOG.md
index 0511a4c..75c696d 100644
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -4,6 +4,19 @@ All notable changes to this repo. Newest first. Dates are PDT.
 
 ## 2026-07-02
 
+### GH-77 SHIPPED — Aider ↔ OpenRouter turn-taker lane (discrete from Codex)
+New `relay-automation/aider-turn.sh` headless turn-taker drives [Aider](https://aider.chat) against [OpenRouter](https://openrouter.ai) — an OpenAI-standard gateway that puts the whole model catalog (Claude/GPT/Gemini/DeepSeek/Qwen/Llama) behind one API key. Built as a lane **discrete from Codex**: it shares no code or env with `codex-turn.sh`, so working on one never risks the other. Same `relay-turn-lib.sh` containment core as codex/agy — off-lane revert, commit-bypass reset, worktree isolation, no-push all inherited.
+
+Two Aider-specific adaptations, because Aider is a file-EDITOR (no mid-turn shell) that auto-commits — everything else is identical to the shared contract:
+1. **The shim performs the tick token ops itself.** Aider won't run `tick`. The shim `claim`s the specific handed-off `RELAY_TASK` (`tick claim <task> --agent <me> --paths <relay+artifacts>`) + `ping`s before the turn; `rtl_enforce` (GH-67) then does the ownership-guarded `release`/`done` after the file-scoped commit. Root-cause caught in testing: `tick take <task>` ignores its task argument and grabs *whatever* task is offered to the agent — so `claim` (which honors the named task) is the correct verb here.
+2. **`--no-auto-commits` is load-bearing.** Aider's default auto-commit would move HEAD and trip `rtl_enforce`'s commit-bypass guard (exit 6) every turn. The harness owns the commit.
+
+OpenRouter needs no base-url plumbing — `--model openrouter/…` + `OPENROUTER_API_KEY` is Aider-native. Config: `AIDER_MODEL` (default `openrouter/anthropic/claude-3.5-sonnet`), `AIDER_BIN`, `AIDER_FLAGS`. A missing key pre-flights to a fast exit 5 (no interactive hang). Additive routing: `marathon-agent.sh` dispatches `AIDER_AGENT`; `marathon-drive.sh` `route_agent` maps `aider*` → builder lane. Codex/agy branches byte-identical (verified: `test/codex-turn.sh` 30/30, `test/agy-turn.sh` 27/27 unchanged). New `test/aider-turn.sh` (28 checks: defer, good turn + token handoff to peer, Approved→`tick done`, off-lane/commit-bypass/spaced-path revert exit 6, empty-output exit 5, missing-key exit 5, ambient WIP untouched, worktree-isolation copy-back, relay-dispatch). `validate.sh` green.
+
+**Available across all harness surfaces, not just marathon.** The `aider*` routing lives in the shared `marathon-agent.sh` dispatcher that `relay-drive.sh` uses as its `--agent-cmd`, so a driven `/relay` with `RELAY_AGENT=aider` fires the lane exactly like Codex/agy (regression: `test/aider-turn.sh` case 11 drives the real dispatcher end-to-end). And `consult.sh` gains an `aider` advisor (`--models …,aider`) — the cross-model second-opinion tool behind `relay-drive.sh --consult-verify` — run advisory-only (no `--file`, `--no-auto-commits`) with the same `OPENROUTER_API_KEY` pre-flight; `test/consult.sh` +2 checks (answers + no-key remedy).
+
+**Bet:** driving Aider as a pure file-editor with the shim owning the token protocol (rather than expecting Aider to speak the tick protocol) is the durable seam — it keeps the Aider lane behind the *same* containment kernel as every other lane instead of forking a second trust boundary. Reversibility: Easy — one new shim + additive routing branches, no kernel/schema change; delete the shim and the two `aider*` case arms to remove. Non-goals (deferred): no cost.tokens capture (Aider `--message` emits no usage JSON on stdout), not yet in the vendored `relay-pkg` tarball, Aider stays a builder lane (reviewers remain codex/gemini/agy).
+
 ### GH-75 SHIPPED — XYZ.json final-completion telemetry at every harness session end
 All three harnesses (relay, marathon, swarm) now append a durable, newest-first completion record to a gitignored `XYZ.json` at the harness repo root — the live per-session signal GH-24's on-demand batch extractor never provided. Schema extends GH-24's `{health, title, description, updatedAt}` with `{harness, sessionId}`.
 
diff --git a/PROJECT/1-INBOX/GH-77-AIDER-OPENROUTER-LANE.md b/PROJECT/1-INBOX/GH-77-AIDER-OPENROUTER-LANE.md
new file mode 100644
index 0000000..ad3b661
--- /dev/null
+++ b/PROJECT/1-INBOX/GH-77-AIDER-OPENROUTER-LANE.md
@@ -0,0 +1,52 @@
+---
+gh_issue: 77
+source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/77
+title: Aider ↔ OpenRouter turn-taker lane (OpenAI-standard, discrete from Codex)
+status: Shipped
+created: 2026-07-02
+updated: 2026-07-02
+owner: noel
+doc_type: feature
+complexity: 2
+risk: 2
+effort: 2
+roadmap_exempt: false
+related:
+  - relay-automation/aider-turn.sh
+  - relay-automation/marathon-agent.sh
+  - relay-automation/marathon-drive.sh
+  - relay-automation/relay-turn-lib.sh
+non_goals:
+  - No cost.tokens capture — Aider `--message` mode emits no machine-readable usage JSON on stdout (same cost-floor partial as the Codex/agy lanes)
+  - Not added to the vendored relay-pkg tarball yet — main-clone use first; packaging is a follow-on
+  - Aider stays a BUILDER lane; reviewer lanes remain codex/gemini/agy
+---
+
+# GH-77 · Aider ↔ OpenRouter turn-taker lane
+
+## Status
+
+| Most recently completed | What's next |
+|---|---|
+| **✅ SHIPPED 2026-07-02 — marathon + relay + consult.** New `relay-automation/aider-turn.sh` headless turn-taker drives Aider against OpenRouter (OpenAI-standard) behind the shared `relay-turn-lib.sh` containment core — **discrete from Codex** (no shared code/env). Two Aider-specific adaptations: the SHIM performs the tick token ops (`claim <task> --paths` + `ping`; `rtl_enforce` GH-67 does the release/done) since Aider can't run shell mid-turn, and it runs Aider with `--no-auto-commits` so the harness owns the commit (else the commit-bypass guard trips). Additive routing in `marathon-agent.sh` + `marathon-drive.sh` (`aider*` builder lane; Codex paths byte-identical) — the same dispatcher `relay-drive.sh` uses, so Aider is a first-class **relay** turn-taker too. **Also wired into `consult.sh`** (`--models …,aider`) — the cross-model advisor behind `relay-drive.sh --consult-verify`. `OPENROUTER_API_KEY` pre-flight fails fast. `test/aider-turn.sh` (28 checks, incl. relay-dispatch) + `test/consult.sh` (+2 aider checks) in `validate.sh` — green. | Optional follow-ons: add `aider-turn.sh` to the vendored `relay-pkg` (make-pkg) if a consumer needs it; live E2E against a real OpenRouter key. |
+
+## Problem
+
+The harness has headless lanes for Codex (`codex-turn.sh`) and agy (`agy-turn.sh`) but none for Aider ↔ OpenRouter. OpenRouter is an OpenAI-standard gateway to the whole model catalog behind one key, so an Aider lane adds broad build-model diversity with no new provider integration. The lane must be **discrete from Codex** so working on one never risks the other.
+
+## Design
+
+`relay-automation/aider-turn.sh` — thin dispatch wrapper over `relay-turn-lib.sh`, same containment contract as codex/agy. Two differences, because Aider is a file-EDITOR (no mid-turn shell) that auto-commits:
+
+1. **Shim-owned token ops.** Aider won't run `tick`. The shim `claim`s the specific `RELAY_TASK` — `tick claim <task> --agent <me> --paths <relay+artifacts>`, NOT `tick take` (which grabs *whatever* task is offered to the agent, not the named one — the root-cause bug caught in testing) — then `ping`s. After the turn, `rtl_enforce` (GH-67) does the authoritative `release --to <peer>` / `done` from the relay file's STATUS; it's ownership-guarded, so it only works because the shim made this agent the claimer.
+2. **`--no-auto-commits`.** Aider auto-commits by default; the moved HEAD would trip `rtl_enforce`'s commit-bypass guard (exit 6) every turn. The harness owns the file-scoped commit.
+
+OpenRouter needs no base-url flag — `--model openrouter/…` + `OPENROUTER_API_KEY` is Aider-native. Config: `AIDER_MODEL` (default `openrouter/anthropic/claude-3.5-sonnet`), `AIDER_BIN`, `AIDER_FLAGS`, `AIDER_TURN_ROOT`, `AIDER_LOG`; honors `ALLOW_PATHS`, `RELAY_PEER`, `RELAY_WORKTREE_ISOLATION`, `RELAY_TURN_TIMEOUT_S`. Files added to the chat via `--file` (relay file + each `ALLOW_PATHS` artifact) as ROOT-relative paths so worktree isolation copy-back works. Exit contract mirrors agy: 0 · 5 (failed/no-key/empty) · 6 (off-lane) · 7 (timeout) · 2 (usage).
+
+Routing: `marathon-agent.sh` dispatches `AIDER_AGENT`; `marathon-drive.sh` `route_agent` maps `aider*` → `AIDER_AGENT` (builder lane). Both additive; Codex/agy branches unchanged.
+
+## QA gate
+
+- [x] `test/aider-turn.sh` (26 checks): defer, good turn + token handoff to peer, Approved → `tick done`, off-lane/commit-bypass/spaced-path revert (exit 6), empty-output (exit 5), missing `OPENROUTER_API_KEY` (exit 5), ambient WIP untouched, worktree isolation copy-back
+- [x] Codex/agy/marathon tests unchanged and green (routing is additive)
+- [x] `validate.sh` green with the new test
diff --git a/ROADMAP-DASHBOARD.md b/ROADMAP-DASHBOARD.md
index 7d79c27..173411e 100644
--- a/ROADMAP-DASHBOARD.md
+++ b/ROADMAP-DASHBOARD.md
@@ -39,10 +39,11 @@ Summary: 3 items | Tally: 🟢 0 · 🟡 1 · ⏸️ 0 · ⛔ 0 · ✅ 1 · 🔮
 
 ## Completed
 
-Summary: 47 items | Tally: 🟢 0 · 🟡 0 · ⏸️ 0 · ⛔ 0 · ✅ 47 · 🔮 0 · 🔲 0
+Summary: 48 items | Tally: 🟢 0 · 🟡 0 · ⏸️ 0 · ⛔ 0 · ✅ 48 · 🔮 0 · 🔲 0
 
 | Item | Status | Links |
 | --- | --- | --- |
+| GH-77 · Aider ↔ OpenRouter turn-taker lane | ✅ | [GH-77-AIDER-OPENROUTER-LANE.md](PROJECT/1-INBOX/GH-77-AIDER-OPENROUTER-LANE.md) · [#77](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/77) |
 | GH-75 · XYZ.json — final completion telemetry at relay/swarm/marathon session end | ✅ | [GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md](PROJECT/1-INBOX/GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md) · [#75](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/75) |
 | GH-69 · Marathon branch suggestion + agent confirmation prompt | ✅ | [GH-69-MARATHON-BRANCH-PROMPT.md](PROJECT/1-INBOX/GH-69-MARATHON-BRANCH-PROMPT.md) · [#69](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/69) |
 | GH-71 · Code Structure & Implementation Upgrade | ✅ | [GH-71-UPGRADE-CODE-STRUCTURE.md](PROJECT/1-INBOX/GH-71-UPGRADE-CODE-STRUCTURE.md) · [#71](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/71) |
diff --git a/ROADMAP.md b/ROADMAP.md
index d17c42a..0e7f561 100644
--- a/ROADMAP.md
+++ b/ROADMAP.md
@@ -91,6 +91,7 @@ Mechanical / pattern-following work → **Sonnet High**; trust-critical kernel-c
 - **Tooling · relay-to-issue skill** 🟡 — **shipped 2026-06-22**: a post-relay skill that distills a closed `/relay` thread into ONE checklist-style GitHub issue, filed in the repo the relay was *about* (cross-repo aware; dedup-stamped; auto-posts via `gh`). `skills/relay-to-issue/` (SKILL + `relay-to-issue.sh` + `install.sh`); `resolve` smoke-tested green. Remaining: operator `install.sh` + one un-sandboxed live `gh issue create` to confirm posting E2E. → [RELAY-TO-ISSUE-SKILL.md](PROJECT/2-WORKING/RELAY-TO-ISSUE-SKILL.md)
 
 ### Completed
+- **GH-77 · Aider ↔ OpenRouter turn-taker lane** ✅ **SHIPPED 2026-07-02** — new `relay-automation/aider-turn.sh` headless turn-taker drives Aider against OpenRouter (OpenAI-standard; the whole model catalog behind one key) behind the shared `relay-turn-lib.sh` containment core — **discrete from Codex** (no shared code/env, so working on one never risks the other). Two Aider-specific adaptations, everything else identical to the codex/agy contract: (1) the SHIM performs the tick token ops (`tick claim <task> --paths` — NOT `take`, which grabs any offered task — + `ping`; `rtl_enforce` GH-67 does the ownership-guarded `release`/`done` after the file-scoped commit) since Aider can't run shell mid-turn; (2) it runs Aider `--no-auto-commits` so the harness owns the commit, else the commit-bypass guard trips (exit 6) every turn. Additive routing in `marathon-agent.sh` + `marathon-drive.sh` `route_agent` (`aider*` builder lane; Codex/agy paths byte-identical). `OPENROUTER_API_KEY` pre-flight fails fast (exit 5). Config: `AIDER_MODEL` (default `openrouter/anthropic/claude-3.5-sonnet`), `AIDER_BIN`, `AIDER_FLAGS`. Available across **all** surfaces — the `aider*` routing is in the shared `marathon-agent.sh` dispatcher `relay-drive.sh` uses as `--agent-cmd`, so a driven `/relay` (`RELAY_AGENT=aider`) fires it like Codex/agy; and `consult.sh` gains an `aider` advisor (`--models …,aider`, the tool behind `--consult-verify`). `test/aider-turn.sh` (28 checks incl. relay-dispatch) + `test/consult.sh` (+2 aider checks) in `validate.sh`. → [GH-77-AIDER-OPENROUTER-LANE.md](PROJECT/1-INBOX/GH-77-AIDER-OPENROUTER-LANE.md) · [#77](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/77)
 - **GH-75 · XYZ.json — final completion telemetry at relay/swarm/marathon session end** ✅ **SHIPPED 2026-07-02** — every relay/marathon/swarm harness now appends a durable, newest-first completion record to a gitignored `XYZ.json` at the harness repo root (schema: `{harness, sessionId, health, title, description, updatedAt}`). Shared `utils/telemetry/health-lib.sh` factors GH-24's STATUS/VERDICT→health mapping out of `extract-relay-telemetry.sh` (extractor output byte-identical — no GH-24 regression); shared `utils/telemetry/append-xyz-completion.sh` does a locked (GH-72 `mkdir` advisory lock — no lost update) + atomic (temp-file + `os.replace` — no corruption/partial write) read-modify-write-prepend. Wired into `relay-drive.sh`'s terminal exits (green / orange×2 / red), `marathon-drive.sh`'s own per-run hook (gated by `XYZ_HARNESS_CONTEXT`; `harness:"swarm"` when swarm-preflight's generated invocation self-propagates the tag, else `"marathon"`; silent under `marathon-phase`), and `marathon.sh`'s single whole-run record — so a `marathon.sh` N-phase run emits exactly one record, never N/N+1. New `test/xyz-completion.sh` (writer + 16-way concurrency + corrupt-file self-heal + health-lib table) and `test/xyz-harness-hooks.sh` (all harness terminal paths + nesting), plus a swarm-tag assertion in `test/swarm-preflight.sh`. `validate.sh` green. → [GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md](PROJECT/1-INBOX/GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md) · [#75](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/75)
 - **GH-69 · Marathon branch suggestion + agent confirmation prompt** ✅ **SHIPPED 2026-07-01** — marathon builds commit several times (build → gate → review) but the pipeline had no branch-cutting step; partial/failed work landed on whatever was checked out. Three-stage fix: (1) `marathon-plan.sh` emits a deterministic `suggested_branch: marathon/<slug>-<date>` per active wave lane (read-only, no git writes); (2) `swarm-preflight.sh` checks real branch existence via `git show-ref` and emits `branch_ready`/`skip_branch_prompt` in the packet (JSON + `packet.md` + text report); (3) the orchestrating-agent contract ("ask the operator before proceeding when `branch_ready: false`, unless the carve-out applies") is documented inline in `swarm-preflight.sh`'s header and self-stated in every packet's "Suggested branch" line — a driving agent doesn't need to recompute it. Carve-out (`risk: 1` + independent-zone artifacts) verified to skip the prompt; kernel-zone artifacts and non-risk-1 items correctly do NOT skip it. No branch is ever auto-created. `test/marathon-plan.sh` 34/34, `test/swarm-preflight.sh` 44/44, `validate.sh` 77/77. → [GH-69-MARATHON-BRANCH-PROMPT.md](PROJECT/1-INBOX/GH-69-MARATHON-BRANCH-PROMPT.md) · [#69](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/69)
 - **GH-71 · Code Structure & Implementation Upgrade** ✅ **Phases 1–2 SHIPPED 2026-07-01 (`6a7b6ea`, `fa37c58`)** — plan to upgrade codebase maturity, re-scoped into two safe/reversible initial phases + two deferred rewrites. **Phase 1 (root-dir cleanup):** moved `4X4.md`, `FRONTDOOR.md`, `snapshot.md`, `CODEX.md`, `BACKLOG.md` into `PROJECT/4-MISC/`; canonical front door (`README.md`/`ROUTER.md`/`AGENTS.md`/`ROADMAP.md`/`CHANGELOG.md`/`CLAUDE.md`/`LICENSE.md`) untouched at root; fixed the moved files' now-two-levels-deep internal links + the two live ROADMAP.md cross-references; left historical/archival references (`CHANGELOG.md`, `relay-system/**`, `AUDIT/**`, `decisions/**`, `PROJECT/3-COMPLETED/**`) untouched as point-in-time records. **Phase 2 (JS kernel API boundaries):** JSDoc `@param`/`@returns`/`@throws` on every exported function across the 12 `src/*.js` files (the event-log↔projection API surface) + `utils/checkjs.sh` wiring up the exact Tier 1 lint GH-61 proposed (`node --check`, dependency-free — no `tsc`/TypeScript added) plus a deterministic JSDoc-coverage gate so the annotations stay enforced, not a one-time pass. `test/checkjs.sh` (6 checks) in `validate.sh`. **Deferred (unchanged, still behind a concrete trigger — not a letter grade):** Phase 3 `poll.sh`→Node + Phase 4 `relay-drive.sh`→Node; hold until an actual maintenance incident or a specific Bash-caused bug class justifies rewriting the most safety-critical, best-dogfooded components. `validate.sh` 77/77; `pdda.sh run` clean. → [GH-71-UPGRADE-CODE-STRUCTURE.md](PROJECT/1-INBOX/GH-71-UPGRADE-CODE-STRUCTURE.md) · [#71](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/71)
diff --git a/ROUTER.md b/ROUTER.md
index b13c204..a847536 100644
--- a/ROUTER.md
+++ b/ROUTER.md
@@ -68,6 +68,7 @@ utils/pdda/pdda.sh doc-ready        # LLM readiness review — set PDDA_LLM_BIN
 - If the task is about document quality, active-doc lifecycle, roadmap sprawl, or automation policy, start in `PROJECT/PDDA.md`.
 - If the task is about the CHANGELOG, provenance, or end-of-iteration logging, the governance is in `PROJECT/PDDA.md` (the "CHANGELOG.md — end-of-iteration record" contract).
 - If the task is about the `tick` runtime, event projection, or multi-agent coordination kernel, start in `README.md`, then `bin/`, `src/`, `test/`, and the active project doc.
+- If the task is about the **Aider ↔ OpenRouter** turn-taker lane (`relay-automation/aider-turn.sh` — an OpenAI-standard build lane discrete from Codex; `AIDER_MODEL`/`OPENROUTER_API_KEY`, `--builder aider`), start in `PROJECT/1-INBOX/GH-77-AIDER-OPENROUTER-LANE.md`. The shim owns the tick token ops (Aider can't run shell mid-turn) and runs Aider `--no-auto-commits` (the harness commits).
 - If the task is about running, driving, or reviewing via the relay (`relay-automation/` — `relay-drive.sh`, `poll.sh`, the turn shims, `marathon*.sh`), **invoke the `relay-xyz` skill first — do not improvise the handoff or hand-roll a harness from `ls relay-automation/`.** The skill owns the locator, sandbox rules, exit codes, and the safety boundary; a `PreToolUse` guard (`relay-automation/hooks/relay-xyz-guard.sh`) blocks driving a harness driver before the skill is loaded. For the two live-Claude-windows, same-machine duel recipe (Reporter↔Maintainer with a human go-gate), the copy-paste form is [relay-automation/DUELING-CLAUDES.md](relay-automation/DUELING-CLAUDES.md).
 - If the task is about relay session telemetry, the `focus5float` health feed, or extraction scripts under `utils/telemetry/`, start in `PROJECT/1-INBOX/GH-24-RELAY-TELEMETRY-EXTRACTOR.md`.
 - If the task is about live per-session completion telemetry — the `XYZ.json` log every relay/marathon/swarm session appends to at the harness repo root (schema: `harness`/`sessionId`/`health`/`title`/`description`/`updatedAt`), the shared writer `utils/telemetry/append-xyz-completion.sh`, or the shared health mapping `utils/telemetry/health-lib.sh` — start in `PROJECT/1-INBOX/GH-75-XYZ-JSON-COMPLETION-TELEMETRY.md`. `XYZ.json` is local + gitignored (machine-specific).
diff --git a/relay-automation/README.md b/relay-automation/README.md
index ab29465..b039fe1 100644
--- a/relay-automation/README.md
+++ b/relay-automation/README.md
@@ -26,7 +26,8 @@ the loop still degrades to the existing manual nudge. For the current headless p
 | `codex-turn.sh` | **Option-A** headless turn-taker for the **Codex** agent (`codex exec`); thin dispatch wrapper over `relay-turn-lib.sh`. |
 | `gemini-turn.sh` | **DEPRECATED 2026-06-19** — Gemini CLI retired; use `agy-turn.sh` instead. Kept as historical reference. |
 | `agy-turn.sh` | **Option-A** headless turn-taker for the **agy** (Antigravity CLI) agent (`agy -p`); thin dispatch wrapper over `relay-turn-lib.sh`. Permanent replacement for `gemini-turn.sh`; live-validated 2026-06-18. |
-| `consult.sh` | Parallel read-only consult: asks the same question to Codex and agy, captures both transcripts, and leaves synthesis to the caller. Advisory-only; not part of the relay loop. |
+| `aider-turn.sh` | Headless turn-taker for **Aider ↔ OpenRouter** (`aider --model openrouter/… --message`) — an OpenAI-standard lane discrete from Codex. Same `relay-turn-lib.sh` containment; because Aider is a file-editor (no mid-turn shell), the SHIM performs the tick token ops itself and runs Aider with `--no-auto-commits` (the harness owns the commit). Set `OPENROUTER_API_KEY` + `AIDER_MODEL` (e.g. `openrouter/anthropic/claude-3.5-sonnet`, `openrouter/openai/gpt-4o`, `openrouter/deepseek/deepseek-chat`). Works in **both** a marathon `--builder aider` lane AND a plain `/relay` — it routes through the shared `marathon-agent.sh` dispatcher (`relay-drive.sh`'s `--agent-cmd`), so a driven relay with `RELAY_AGENT=aider` fires it just like Codex/agy. |
+| `consult.sh` | Parallel read-only consult: asks the same question to **Codex, agy, and (opt-in) Aider↔OpenRouter** (`--models codex,agy,aider`), captures each transcript, and leaves synthesis to the caller. Advisory-only; also the engine behind `relay-drive.sh --consult-verify`. |
 
 ## Recipes & docs (not scripts)
 | Doc | What it gives you |
diff --git a/relay-automation/aider-turn.sh b/relay-automation/aider-turn.sh
new file mode 100755
index 0000000..31be407
--- /dev/null
+++ b/relay-automation/aider-turn.sh
@@ -0,0 +1,173 @@
+#!/usr/bin/env bash
+set -euo pipefail
+#
+# aider-turn.sh — headless turn-taker for AIDER (https://aider.chat) driving any model via OPENROUTER
+# (an OpenAI-standard gateway). Thin dispatch wrapper over the shared safety core (relay-turn-lib.sh) —
+# the SAME containment contract as codex-turn.sh / agy-turn.sh, proving the boundary is model-agnostic.
+# This lane is DISCRETE from the Codex lane: it shares no code or env with codex-turn.sh, so working on
+# one never risks the other.
+#
+# WHY A SEPARATE SHIM: Aider is a file-EDITOR, not a shell-loop agent. Unlike codex/agy it does not run
+# arbitrary shell (`tick`) mid-turn, and it AUTO-COMMITS by default. So this shim differs from the
+# others in exactly two places, everything else is identical to the shared contract:
+#   1. It performs the tick token ops ITSELF (take + ping before the turn); rtl_enforce (GH-67) then
+#      closes/hands off the token after the file-scoped commit. Aider only edits files.
+#   2. It runs aider with --no-auto-commits so Aider never git-commits — otherwise rtl_enforce's
+#      commit-bypass guard (a moved HEAD) would fail every turn (exit 6). The harness owns the commit.
+#
+# Invoked by relay-drive.sh / marathon-agent.sh as --agent-cmd, with env:
+#   RELAY_FILE  — relay thread file (always allowlisted)
+#   RELAY_TASK  — tick turn-token (default RELAY-TURN)
+#   RELAY_AGENT — current actor (the token's claimer/handoff_to)
+# Shim config:
+#   AIDER_AGENT     — the agent id this shim drives; NO-OPS unless RELAY_AGENT==AIDER_AGENT
+#   ALLOW_PATHS     — comma-separated extra git paths the turn may change (the artifact(s))
+#   RELAY_PEER      — the other agent's id, so rtl_enforce hands off "--to <peer>" when non-terminal
+#   OPENROUTER_API_KEY — REQUIRED. Aider reads it natively; this shim pre-flights it so a missing key
+#                        fails fast (exit 5) instead of Aider hanging on an interactive prompt.
+#   AIDER_BIN       — aider binary (default: aider); tests inject a stub
+#   AIDER_MODEL     — OpenRouter model id (default: openrouter/anthropic/claude-3.5-sonnet). Set it to
+#                     any OpenRouter model, e.g. openrouter/openai/gpt-4o, openrouter/deepseek/deepseek-chat.
+#   AIDER_FLAGS     — optional extra flags appended to the aider invocation (advanced/override)
+#   AIDER_TURN_ROOT — git root to guard (default: this repo); tests point at a fixture
+#   AIDER_LOG       — where to write the aider transcript (default: a $TMPDIR file)
+#   RELAY_WORKTREE_ISOLATION — 1 = run the turn in a THROWAWAY git worktree of ROOT@HEAD (airtight
+#                     containment; off-lane in the worktree → exit 6). Default OFF.
+#   RELAY_TURN_TIMEOUT_S — per-turn wall-clock ceiling in seconds (default: 300). A hung/runaway aider
+#                          is killed after this many seconds; the turn exits 7.
+#
+# Headless contract:
+#   --message "<prompt>"   — run one instruction non-interactively, then exit
+#   --yes-always           — auto-approve every confirmation (no interactive gate)
+#   --no-auto-commits      — Aider must NOT git-commit (see WHY #2 above); the harness commits
+#   --no-gitignore --no-check-update --no-analytics --no-show-model-warnings --no-stream --map-tokens 0
+#   --file <path>          — one per allowlisted file (the relay file + each ALLOW_PATHS artifact), so
+#                            Aider edits exactly the on-lane surface
+#   OpenRouter needs no base-url flag — `--model openrouter/...` + OPENROUTER_API_KEY is Aider-native.
+#
+# Exit: 0 acted/deferred · 5 aider failed / no OPENROUTER_API_KEY / empty output · 6 off-allowlist edit
+#       (reverted) · 7 timeout-killed · 2 usage.
+
+HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
+# shellcheck source=relay-turn-lib.sh
+source "$HERE/relay-turn-lib.sh"
+
+ROOT="${AIDER_TURN_ROOT:-"$(cd "$HERE/.." && pwd)"}"
+AIDER_BIN="${AIDER_BIN:-aider}"
+AIDER_MODEL="${AIDER_MODEL:-openrouter/anthropic/claude-3.5-sonnet}"
+die() { printf 'aider-turn: %s\n' "$*" >&2; exit 2; }
+
+me="${RELAY_AGENT:-}"; f="${RELAY_FILE:-}"; t="${RELAY_TASK:-RELAY-TURN}"
+aider_agent="${AIDER_AGENT:-}"
+[[ -n "$me" ]] || die "RELAY_AGENT required"
+[[ -n "$f" ]] || die "RELAY_FILE required"
+[[ -n "$aider_agent" ]] || die "AIDER_AGENT required"
+
+# Dispatch only for the aider agent; defer otherwise (that window drives its own turn).
+if [[ "$me" != "$aider_agent" ]]; then
+  printf 'aider-turn: actor %s is not the aider agent (%s) — deferring (window-driven)\n' "$me" "$aider_agent" >&2
+  exit 0
+fi
+
+# Auth pre-flight: OpenRouter is pure API-key. A missing key would make aider prompt interactively and
+# deadlock the headless turn, so fail fast with the remedy (mirrors agy's `agy login` pre-flight).
+if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
+  printf 'aider-turn: OPENROUTER_API_KEY is not set — Aider cannot reach OpenRouter. Export it (your OpenRouter key) then retry.\n' >&2
+  exit 5
+fi
+
+rtl_init "$ROOT" "$f" "${ALLOW_PATHS:-}"
+
+prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"
+# GH-68 warn-only: prepend any UNREAD cross-agent dependency-drift heads-up to the turn brief.
+drift_brief="$(rtl_drift_brief "$me" "${TICK_REPO_ROOT:-$ROOT}")"
+[[ -n "$drift_brief" ]] && prompt="${drift_brief}"$'\n'"${prompt}"
+# Aider can't run shell mid-turn, and this shim owns the token ops — tell the model so, so it spends the
+# turn on the file edit(s) instead of emitting tick commands it can't run.
+prompt="${prompt}"$'\n\n'"NOTE (Aider harness): do NOT run any tick commands — the harness has already claimed the token and will release/close it for you after your edit. Spend this turn ONLY editing the file(s) added to the chat: append your block to the relay file and set its STATUS, and edit the artifact(s) if this is a build turn."
+
+# --file targets: the relay file + each ALLOW_PATHS artifact, as ROOT-RELATIVE paths so they resolve
+# against the turn's CWD (ROOT normally; the throwaway worktree under isolation). Passing relative paths
+# is what makes worktree isolation work — Aider edits the worktree copy, which rtl_worktree_end then
+# copies back (an absolute ROOT path would bypass the worktree and defeat containment).
+rel_relay="${f#"$ROOT"/}"
+file_args=(--file "$rel_relay")
+claim_paths="$rel_relay"
+if [[ -n "${ALLOW_PATHS:-}" ]]; then
+  IFS=',' read -ra _aps <<<"${ALLOW_PATHS}"
+  for _ap in "${_aps[@]}"; do _ap="${_ap#"${_ap%%[![:space:]]*}"}"; _ap="${_ap%"${_ap##*[![:space:]]}"}"; [[ -n "$_ap" ]] && { file_args+=(--file "$_ap"); claim_paths="$claim_paths,$_ap"; }; done
+fi
+
+# The shim performs the token ops Aider can't (claim THIS handed-off task + ping). rtl_enforce (GH-67)
+# does the authoritative release/done AFTER the file-scoped commit, but it is ownership-guarded — it
+# only works if THIS agent is the token's claimer. Use `claim <task> --paths` (NOT `take`, which grabs
+# whatever task is offered to the agent, not the specific RELAY_TASK). Best-effort — never fatal.
+_tickroot="${TICK_REPO_ROOT:-$ROOT}"; _tickbin="$_tickroot/bin/tick"
+if [[ -x "$_tickbin" ]]; then
+  TICK_REPO_ROOT="$_tickroot" "$_tickbin" claim "$t" --agent "$me" --paths "$claim_paths" >/dev/null 2>&1 || true
+  TICK_REPO_ROOT="$_tickroot" "$_tickbin" ping "$t" --agent "$me" >/dev/null 2>&1 || true
+fi
+
+AIDER_LOG="${AIDER_LOG:-${TMPDIR:-/tmp}/aider-turn-$$.log}"
+
+# Build the aider invocation. --no-auto-commits is LOAD-BEARING (see WHY #2). AIDER_FLAGS is an escape
+# hatch for version-specific flag differences.
+turn_timeout="${RELAY_TURN_TIMEOUT_S:-300}"
+aider_args=(--model "$AIDER_MODEL" --yes-always --no-auto-commits --no-gitignore
+            --no-check-update --no-analytics --no-show-model-warnings --no-stream --map-tokens 0
+            "${file_args[@]}")
+read -ra _xflags <<<"${AIDER_FLAGS:-}"
+[[ "${#_xflags[@]}" -gt 0 ]] && aider_args+=("${_xflags[@]}")
+
+rtl_before
+bounded_rc=0
+
+# Worktree isolation (opt-in; same wiring as agy-turn.sh / claude-turn.sh). CWD = a throwaway worktree
+# of ROOT@HEAD; .tick coordination state stays SHARED via TICK_REPO_ROOT=ROOT. Default OFF → the in-ROOT
+# run is byte-for-byte the prior behaviour.
+wt=""; cwd_wrap=(bash -c 'cd "$1" || exit 127; shift; exec "$@"' bash "$ROOT")
+if [[ "${RELAY_WORKTREE_ISOLATION:-0}" == "1" ]]; then
+  if wt="$(rtl_worktree_begin)"; then
+    export TICK_REPO_ROOT="$_tickroot"
+    cwd_wrap=(bash -c 'cd "$1" || exit 127; shift; exec "$@"' bash "$wt")
+    printf 'aider-turn: worktree isolation ON (%s)\n' "$wt" >&2
+  else
+    printf 'aider-turn: worktree isolation requested but `git worktree add` failed — failing turn\n' >&2
+    exit 5
+  fi
+fi
+
+# Run aider headless (edits the files added to the chat; NO git — --no-auto-commits), then enforce the
+# boundary. CWD is pinned to ROOT (or the worktree) so aider operates on the right git tree.
+rtl_run_bounded "$turn_timeout" "${cwd_wrap[@]}" "$AIDER_BIN" "${aider_args[@]}" --message "$prompt" \
+  < /dev/null > "$AIDER_LOG" 2>&1 || bounded_rc=$?
+
+# Worktree teardown FIRST (regardless of rc): copies the allowlist back to ROOT unless an off-lane
+# change was detected → exit 6 (containment takes precedence over timeout 7 / failure 5).
+if [[ -n "$wt" ]]; then
+  rtl_worktree_end "$wt"
+  if [[ "${RTL_WT_OFFLANE:-0}" == "1" ]]; then
+    printf 'aider-turn: aider made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)\n' >&2
+    exit 6
+  fi
+fi
+
+if [[ "$bounded_rc" -eq 7 ]]; then
+  printf 'aider-turn: aider exceeded %ss wall-clock cap — killed\n' "$turn_timeout" >&2
+elif [[ "$bounded_rc" -ne 0 ]]; then
+  printf 'aider-turn: aider failed (exit %s) — see %s\n' "$bounded_rc" "$AIDER_LOG" >&2; exit 5
+fi
+# Empty-output guard (mirrors agy): a clean exit with NO transcript is a phantom turn (e.g. a blocked
+# backend) — treat it as a failure, not a silent no-op that would advance the relay on false success.
+if [[ "$bounded_rc" -eq 0 && ! -s "$AIDER_LOG" ]]; then
+  printf 'aider-turn: aider exited 0 but produced NO output — likely a blocked/misconfigured backend. Failing the turn.\n' >&2
+  exit 5
+fi
+# Always enforce containment even after a timeout-kill; rtl_enforce may exit 6 (precedence over 7) and
+# performs the authoritative token release/done (GH-67) now that this agent is the token's claimer.
+rtl_enforce "$t" "$me" "$AIDER_LOG" "aider"
+if [[ "$bounded_rc" -eq 7 ]]; then exit 7; fi
+
+# NOTE: OpenRouter returns a usage block in its API response, but Aider does not surface a machine
+# -readable token JSON on stdout in --message mode, so there is no cost.tokens capture here (this lane
+# is a cost floor, same Phase-1 partial as the Codex/agy lanes).
diff --git a/relay-automation/consult.sh b/relay-automation/consult.sh
index 2df5141..77ebcca 100755
--- a/relay-automation/consult.sh
+++ b/relay-automation/consult.sh
@@ -23,12 +23,15 @@ set -euo pipefail
 #   --prompt TEXT     Inline question (mutually exclusive with --prompt-file).
 #   --out DIR         Parent dir for the run (default: relay-system/<today>/). Each run gets its own
 #                     timestamped subdir <label>-<HHMMSS>/ so same-day consults never clobber.
-#   --models CSV      Which advisors to run (default: codex,agy). Legacy `gemini` remains accepted
+#   --models CSV      Which advisors to run (default: codex,agy). Also: `aider` (Aider↔OpenRouter,
+#                     OpenAI-standard — needs OPENROUTER_API_KEY). Legacy `gemini` remains accepted
 #                     as an explicit alias for older tests/callers.
 #   --label SLUG      Run-subdir + transcript stem (default: consult).
 #
 # Env config:
 #   CODEX_BIN / AGY_BIN        binaries (default: codex / agy); tests inject stubs
+#   AIDER_BIN / AIDER_MODEL    Aider binary + OpenRouter model (default: aider / openrouter/anthropic/
+#                              claude-3.5-sonnet) for `--models ...,aider`; reads OPENROUTER_API_KEY.
 #   GEMINI_BIN                 legacy alias for AGY_BIN when `--models ...gemini` is used explicitly
 #   CODEX_FLAGS                codex sandbox flags (default: -s read-only)
 #   AGY_AUTH_TIMEOUT_S         short wall-clock cap for the agy auth probe (`agy whoami`); default 5.
@@ -51,6 +54,7 @@ ROOT="${CONSULT_ROOT:-"$(cd "$HERE/.." && pwd)"}"
 CODEX_BIN="${CODEX_BIN:-codex}"
 AGY_BIN="${AGY_BIN:-${GEMINI_BIN:-agy}}"
 GEMINI_BIN="${GEMINI_BIN:-$AGY_BIN}"
+AIDER_BIN="${AIDER_BIN:-aider}"   # --models ...,aider → advisory via Aider↔OpenRouter (needs OPENROUTER_API_KEY)
 die()  { printf 'consult: %s\n' "$*" >&2; exit 2; }
 warn() { printf 'consult: %s\n' "$*" >&2; }
 
@@ -167,6 +171,21 @@ run_gemini() {
     _guarded "$out" "$GEMINI_BIN" --yolo --skip-trust -p "$FULL_PROMPT"
   fi
 }
+run_aider() {
+  local out="$1"
+  # OpenRouter is pure API-key; a missing key would make Aider prompt interactively (deadlock under the
+  # cap). Skip fast with the remedy — this advisor is counted [FAIL], the others still answer.
+  if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
+    printf 'consult: OPENROUTER_API_KEY not set — Aider cannot reach OpenRouter. Export it (your OpenRouter key), then retry.\n' > "$out"
+    return 5
+  fi
+  # ADVISORY only: pass NO --file (Aider edits nothing) + --no-auto-commits; it answers to stdout, which
+  # is exactly what a consult captures. `--model openrouter/…` + OPENROUTER_API_KEY is Aider-native.
+  local model="${AIDER_MODEL:-openrouter/anthropic/claude-3.5-sonnet}"
+  _guarded "$out" "$AIDER_BIN" --model "$model" --message "$FULL_PROMPT" \
+    --yes-always --no-auto-commits --no-gitignore --no-check-update --no-analytics \
+    --no-show-model-warnings --no-stream --map-tokens 0
+}
 
 # --- fan out in parallel (indexed arrays — macOS bash 3.2 has no `declare -A`) --------------------
 PIDS=(); PMODELS=(); POUTS=()
@@ -184,6 +203,9 @@ for m in "${_models[@]}"; do
       ext="md"; [[ "${CONSULT_GEMINI_JSON:-0}" == "1" ]] && ext="json"
       f="$RUN_DIR/${LABEL}.gemini.$ext"
       run_gemini "$f" & PIDS+=("$!"); PMODELS+=("gemini"); POUTS+=("$f") ;;
+    aider)
+      f="$RUN_DIR/${LABEL}.aider.md"
+      run_aider "$f" & PIDS+=("$!"); PMODELS+=("aider"); POUTS+=("$f") ;;
     *) warn "unknown model '$m' — skipping" ;;
   esac
 done
diff --git a/relay-automation/marathon-agent.sh b/relay-automation/marathon-agent.sh
index 9ef440a..39b515e 100755
--- a/relay-automation/marathon-agent.sh
+++ b/relay-automation/marathon-agent.sh
@@ -14,6 +14,7 @@ set -euo pipefail
 #   CODEX_AGENT       — agent id that routes to codex-turn.sh
 #   GEMINI_AGENT      — agent id that routes to gemini-turn.sh
 #   AGY_AGENT         — agent id that routes to agy-turn.sh (Antigravity CLI; permanent cross-model lane)
+#   AIDER_AGENT       — agent id that routes to aider-turn.sh (Aider via OpenRouter; OpenAI-standard lane)
 # Peer threading (set by marathon-drive.sh — prevents "release to literal role-string" failure):
 #   MARATHON_BUILDER  — builder agent id; when RELAY_AGENT matches this, RELAY_PEER = MARATHON_REVIEWER
 #   MARATHON_REVIEWER — reviewer agent id; when RELAY_AGENT is the reviewer, RELAY_PEER = MARATHON_BUILDER
@@ -31,6 +32,7 @@ me="${RELAY_AGENT:-}"
 claude_agent="${CLAUDE_AGENT:-}"
 codex_agent="${CODEX_AGENT:-}"
 agy_agent="${AGY_AGENT:-}"
+aider_agent="${AIDER_AGENT:-}"
 
 # RELAY_PEER threading: builder's peer is the reviewer; reviewer's peer is the builder.
 # A live turn that lacks an explicit peer can release to a literal role-string (Gemini 2026-06-15).
@@ -55,7 +57,11 @@ case "$me" in
     [[ -n "$agy_agent" ]] || die "RELAY_AGENT='$me' matched an empty AGY_AGENT — set AGY_AGENT"
     exec "$HERE/agy-turn.sh"
     ;;
+  "$aider_agent")
+    [[ -n "$aider_agent" ]] || die "RELAY_AGENT='$me' matched an empty AIDER_AGENT — set AIDER_AGENT"
+    exec "$HERE/aider-turn.sh"
+    ;;
   *)
-    die "unknown agent '$me'; set CLAUDE_AGENT/CODEX_AGENT/AGY_AGENT to map it to a shim"
+    die "unknown agent '$me'; set CLAUDE_AGENT/CODEX_AGENT/AGY_AGENT/AIDER_AGENT to map it to a shim"
     ;;
 esac
diff --git a/relay-automation/marathon-drive.sh b/relay-automation/marathon-drive.sh
index de3468a..f96a720 100755
--- a/relay-automation/marathon-drive.sh
+++ b/relay-automation/marathon-drive.sh
@@ -170,14 +170,15 @@ RELAY_TASK="${RELAY_TASK:-"MARATHON-$(printf '%s' "$PHASE_ID" | tr '[:lower:]' '
 # (e.g. agy) — not just Claude. Builder defaults to claude for back-compat.
 export MARATHON_BUILDER="$BUILDER"
 export MARATHON_REVIEWER="$REVIEWER"
-export CLAUDE_AGENT="" CODEX_AGENT="" AGY_AGENT="" GEMINI_AGENT=""
+export CLAUDE_AGENT="" CODEX_AGENT="" AGY_AGENT="" GEMINI_AGENT="" AIDER_AGENT=""
 route_agent() {  # <agent-id> → export the matching *_AGENT var marathon-agent.sh routes on
   case "$1" in
     claude*) export CLAUDE_AGENT="$1" ;;
     codex*)  export CODEX_AGENT="$1" ;;
     agy*)    export AGY_AGENT="$1" ;;
     gemini*) export GEMINI_AGENT="$1" ;;
-    *)       die "agent '$1' not recognized — must start with claude/codex/agy/gemini" ;;
+    aider*)  export AIDER_AGENT="$1" ;;
+    *)       die "agent '$1' not recognized — must start with claude/codex/agy/gemini/aider" ;;
   esac
 }
 [[ "$BUILDER" == "$REVIEWER" ]] && die "builder and reviewer must be different agent ids (got '$BUILDER' for both)"
diff --git a/test/aider-turn.sh b/test/aider-turn.sh
new file mode 100755
index 0000000..9559191
--- /dev/null
+++ b/test/aider-turn.sh
@@ -0,0 +1,176 @@
+#!/usr/bin/env bash
+# aider-turn.sh test: the Aider↔OpenRouter turn-taker drives a relay turn behind the SHARED safety
+# core (relay-turn-lib.sh) — same containment as codex-turn.sh / agy-turn.sh, via a STUB `aider` that
+# models Aider's behaviour (edits the files added to the chat; does NOT run tick; does NOT commit).
+# Proves the two Aider-specific things: (a) the SHIM performs the token ops (take + rtl_enforce
+# handoff) since Aider can't, and (b) the OPENROUTER_API_KEY pre-flight fails fast when the key is
+# absent. Also proves the model-agnostic containment (off-lane revert, commit-bypass reset, isolation).
+source "$(dirname "$0")/_setup.sh" aider-turn
+export TICK_BIN="$TICK"
+SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/aider-turn.sh"
+tick_a init >/dev/null
+
+# The shim + rtl_enforce resolve tick as "$TICK_REPO_ROOT/bin/tick" (CWD-independent, exactly as a real
+# harness clone ships it). Provide it in the fixture root so the shim's `tick take` and rtl_enforce's
+# authoritative handoff actually run; gitignore bin/ so the symlink never trips containment.
+mkdir -p "$A/bin"; ln -sf "$TICK" "$A/bin/tick"
+printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
+printf '.tick/\nbin/\n' >"$A/.gitignore"
+git -C "$A" add relay.md .gitignore >/dev/null 2>&1; git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1
+
+# Stub `aider`: parses --file targets + --message (ignores every other flag), then models Aider —
+# edits the FIRST --file (the relay file, CWD-relative) and prints a transcript line. It NEVER runs
+# tick and NEVER commits (that's the whole point: the shim owns the token, --no-auto-commits owns git).
+# STUB_MODE: approve=set STATUS Approved; bad=off-allowlist file; commitbypass=git-commit off-lane;
+# spacefile=off-lane path with a space; empty=exit 0 with NO output + NO edit (blocked-backend phantom).
+# A throwaway non-secret value for the OPENROUTER_API_KEY pre-flight (assigned via a var, not a literal,
+# so the security-scan credential-literal rule's variable-value exclusion applies).
+FAKE_ORKEY="not-a-real-key"
+
+STUB="$WORK/aider"
+cat >"$STUB" <<'STUB_EOF'
+#!/usr/bin/env bash
+set -u
+files=(); while (($#)); do
+  case "$1" in
+    --file)    files+=("$2"); shift 2 ;;
+    --message) shift 2 ;;
+    *)         shift ;;
+  esac
+done
+[ "${STUB_MODE:-good}" = empty ] && exit 0           # blocked backend: exit 0, no output, no edit
+printf 'aider-stub: edited for %s\n' "${RELAY_AGENT:-?}"   # stdout -> non-empty transcript
+relay="${files[0]:-relay.md}"
+if [ "${STUB_MODE:-good}" = approve ]; then
+  tmp="$(mktemp)"; sed 's/^STATUS:.*/STATUS: Approved/' "$relay" > "$tmp" && mv "$tmp" "$relay"
+  printf '\n### Round 1 · Builder · aider-stub\n**Verdict:** Approved\n' >>"$relay"
+else
+  printf '\n### Round 1 · Builder · aider-stub\nDid the work.\n' >>"$relay"
+fi
+[ "${STUB_MODE:-good}" = bad ] && printf 'off\n' >>offlane.md
+[ "${STUB_MODE:-good}" = spacefile ] && printf 'off\n' >>"off lane.md"
+if [ "${STUB_MODE:-good}" = commitbypass ]; then
+  printf 'sneaky\n' >>sneaky.md; git add sneaky.md >/dev/null 2>&1; git commit -q -m "aider sneaked" >/dev/null 2>&1
+fi
+exit 0
+STUB_EOF
+chmod +x "$STUB"
+
+# seed the token open→aider (as relay-drive would after handing off to the builder)
+seed_token(){ tick_a log task.created "$1" --agent boss >/dev/null; tick_a claim "$1" --agent boss --paths "z/**" >/dev/null; tick_a release "$1" --agent boss --to aider >/dev/null; }
+
+tok_field(){ tick_a info "$1" 2>/dev/null | sed -n "s/^$2:[[:space:]]*//p" | head -1; }
+
+run_shim(){ # <relay-task> <agent> <stub-mode> [extra env assignments...]
+  local task="$1" agent="$2" mode="$3"; shift 3
+  local log="$WORK/aider-out.$$.log"; : >"$log"
+  env RELAY_AGENT="$agent" RELAY_FILE="$A/relay.md" RELAY_TASK="$task" AIDER_AGENT=aider RELAY_PEER=claude-a \
+    AIDER_BIN="$STUB" AIDER_TURN_ROOT="$A" AIDER_LOG="$log" STUB_MODE="$mode" \
+    OPENROUTER_API_KEY="$FAKE_ORKEY" TICK_REPO_ROOT="$A" "$@" \
+    bash "$SHIM" >/dev/null 2>&1
+}
+
+# --- (1) defer: non-aider actor -> no-op, no commit -----------------------
+seed_token RELAY-TURN-defer
+before="$(git -C "$A" rev-parse HEAD)"
+run_shim RELAY-TURN-defer claude-a good; rc=$?
+[ "$rc" -eq 0 ] && [ "$(git -C "$A" rev-parse HEAD)" = "$before" ] \
+  && pass "non-aider actor -> shim defers, no commit" || fail "should defer with no commit (rc=$rc)"
+
+# --- (2) good turn: shim takes the token, aider edits, rtl_enforce commits + hands off to peer ---
+seed_token RELAY-TURN-good
+before="$(git -C "$A" rev-parse HEAD)"
+run_shim RELAY-TURN-good aider good; rc=$?
+[ "$rc" -eq 0 ] && pass "aider turn (good) exits 0" || fail "good turn rc=$rc"
+[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "aider turn committed (file-scoped)" || fail "expected a commit"
+git -C "$A" show --stat HEAD | grep -q "relay.md" && pass "commit touched the relay file" || fail "commit should include relay.md"
+git -C "$A" log -1 --format='%s' | grep -q "aider headless" && pass "commit message names the aider tool" || fail "commit msg should say aider"
+[ "$(tok_field RELAY-TURN-good status)" = "open" ] && [ "$(tok_field RELAY-TURN-good handoff-to)" = "claude-a" ] \
+  && pass "shim handed the token to the peer (rtl_enforce GH-67, non-terminal STATUS)" \
+  || fail "token not handed to peer: status=$(tok_field RELAY-TURN-good status) handoff=$(tok_field RELAY-TURN-good handoff-to)"
+
+# --- (3) approved turn: STATUS Approved -> rtl_enforce closes the token (tick done) -------
+seed_token RELAY-TURN-appr
+run_shim RELAY-TURN-appr aider approve; rc=$?
+[ "$rc" -eq 0 ] && pass "aider turn (approve) exits 0" || fail "approve turn rc=$rc"
+grep -q "STATUS: Approved" "$A/relay.md" && pass "aider set STATUS Approved in the relay file" || fail "STATUS not Approved"
+[ "$(tok_field RELAY-TURN-appr status)" = "done" ] && pass "terminal STATUS -> token closed (tick done)" || fail "token not done: status=$(tok_field RELAY-TURN-appr status)"
+# reset the relay file STATUS for later cases
+git -C "$A" checkout -- relay.md 2>/dev/null || true; printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
+git -C "$A" add relay.md >/dev/null 2>&1; git -C "$A" commit -q -m "reset relay STATUS" >/dev/null 2>&1
+
+# --- (4) off-lane edit -> reverted + fail (exit 6), shared guard ----------
+seed_token RELAY-TURN-bad
+before="$(git -C "$A" rev-parse HEAD)"
+run_shim RELAY-TURN-bad aider bad; rc=$?
+[ "$rc" -eq 6 ] && pass "off-allowlist edit -> shim fails (exit 6)" || fail "expected exit 6, got $rc"
+[ ! -f "$A/offlane.md" ] && pass "off-lane file was reverted/removed" || fail "off-lane file should be gone"
+[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "no commit on a violating turn" || fail "should not commit on violation"
+
+# --- (5) commit-bypass: aider committing off-lane -> reset + fail (proves --no-auto-commits matters) ---
+seed_token RELAY-TURN-bypass
+before="$(git -C "$A" rev-parse HEAD)"
+run_shim RELAY-TURN-bypass aider commitbypass; rc=$?
+[ "$rc" -eq 6 ] && pass "aider commit during turn -> shim fails (exit 6)" || fail "commit-bypass should exit 6, got $rc"
+[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "sneaked commit reset to BEFORE_HEAD" || fail "HEAD should reset"
+[ ! -f "$A/sneaky.md" ] && pass "off-lane committed file removed by reset" || fail "sneaky.md should be gone"
+
+# --- (6) quoted path: off-lane file with a space -> reverted + fail -------
+seed_token RELAY-TURN-space
+before="$(git -C "$A" rev-parse HEAD)"
+run_shim RELAY-TURN-space aider spacefile; rc=$?
+[ "$rc" -eq 6 ] && pass "off-lane path with space -> shim fails (exit 6)" || fail "spacefile should exit 6, got $rc"
+[ ! -f "$A/off lane.md" ] && pass "spaced off-lane file reverted (-z parsing)" || fail "'off lane.md' should be removed"
+
+# --- (7) empty output on clean exit -> fail (exit 5) ----------------------
+seed_token RELAY-TURN-empty
+before="$(git -C "$A" rev-parse HEAD)"
+run_shim RELAY-TURN-empty aider empty; rc=$?
+[ "$rc" -eq 5 ] && pass "empty-output-on-exit-0 -> shim fails (exit 5)" || fail "empty output should exit 5, got $rc"
+[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "no commit on a phantom/empty turn" || fail "empty turn must not commit"
+
+# --- (8) AIDER-SPECIFIC: missing OPENROUTER_API_KEY -> fail fast (exit 5) before any mutation ---
+seed_token RELAY-TURN-nokey
+before="$(git -C "$A" rev-parse HEAD)"
+log="$WORK/aider-nokey.$$.log"; : >"$log"
+env -u OPENROUTER_API_KEY RELAY_AGENT=aider RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-nokey AIDER_AGENT=aider \
+  RELAY_PEER=claude-a AIDER_BIN="$STUB" AIDER_TURN_ROOT="$A" AIDER_LOG="$log" STUB_MODE=good TICK_REPO_ROOT="$A" \
+  bash "$SHIM" >/dev/null 2>&1; rc=$?
+[ "$rc" -eq 5 ] && pass "missing OPENROUTER_API_KEY -> shim exits 5 before the turn" || fail "no-key should exit 5, got $rc"
+[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "no commit / no mutation when the key is missing" || fail "no-key must not mutate"
+
+# --- (9) pre-existing dirty file is NOT reverted; turn still succeeds ------
+seed_token RELAY-TURN-ambient
+printf 'unrelated WIP\n' > "$A/ambient.md"
+run_shim RELAY-TURN-ambient aider good; rc=$?
+[ "$rc" -eq 0 ] && pass "pre-existing dirty file -> turn still succeeds" || fail "ambient WIP must not fail the turn (rc=$rc)"
+[ -f "$A/ambient.md" ] && pass "pre-existing ambient WIP left untouched (not reverted)" || fail "ambient.md was destroyed (regression!)"
+rm -f "$A/ambient.md"
+
+# --- (10) worktree isolation: aider's relay edit must survive the copy-back (GH-22 shared path) ---
+printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
+git -C "$A" add relay.md >/dev/null 2>&1; git -C "$A" commit -q -m "reseed relay for wt-iso" >/dev/null 2>&1
+seed_token RELAY-TURN-wt
+before="$(git -C "$A" rev-parse HEAD)"
+run_shim RELAY-TURN-wt aider good RELAY_WORKTREE_ISOLATION=1; rc=$?
+[ "$rc" -eq 0 ] && pass "wt-iso: turn exits 0" || fail "wt-iso good turn rc=$rc"
+grep -q "aider-stub" "$A/relay.md" && pass "wt-iso: aider's relay block PRESERVED (copy-back)" || fail "wt-iso: aider's output LOST"
+[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "wt-iso: turn committed (output not dropped)" || fail "wt-iso: no commit — output discarded"
+
+# --- (11) RELAY dispatch: the shared marathon-agent.sh (relay-drive's --agent-cmd) routes aider ----
+# This is the same dispatcher a driven /relay run uses, so it proves Aider is reachable as a relay
+# turn-taker, not just marathon. AIDER_AGENT=aider + RELAY_AGENT=aider -> execs aider-turn.sh.
+DISPATCH="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/marathon-agent.sh"
+printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
+git -C "$A" add relay.md >/dev/null 2>&1; git -C "$A" commit -q -m "reseed relay for dispatch" >/dev/null 2>&1
+seed_token RELAY-TURN-disp
+before="$(git -C "$A" rev-parse HEAD)"
+env RELAY_AGENT=aider RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-disp AIDER_AGENT=aider RELAY_PEER=claude-a \
+  MARATHON_BUILDER=aider MARATHON_REVIEWER=claude-a AIDER_BIN="$STUB" AIDER_TURN_ROOT="$A" \
+  AIDER_LOG="$WORK/disp.log" STUB_MODE=good OPENROUTER_API_KEY="$FAKE_ORKEY" TICK_REPO_ROOT="$A" \
+  bash "$DISPATCH" >/dev/null 2>&1; rc=$?
+[ "$rc" -eq 0 ] && pass "marathon-agent.sh dispatches RELAY_AGENT=aider -> aider-turn.sh (exit 0)" || fail "dispatch exit=$rc"
+[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "dispatched aider relay turn committed (reachable via relay --agent-cmd)" || fail "dispatched turn did not commit"
+
+echo "  $TEST_NAME: $PASS pass, $FAIL fail"
+exit 0
diff --git a/test/consult.sh b/test/consult.sh
index 2c9fbcf..36a7308 100644
--- a/test/consult.sh
+++ b/test/consult.sh
@@ -92,5 +92,33 @@ elapsed=$(( $(date +%s) - start ))
 [ "$elapsed" -lt 20 ] && pass "timeout actually fired (${elapsed}s < 20s, not the 30s sleep)" \
   || fail "timeout did not fire: waited ${elapsed}s"
 
+# --- (7) AIDER advisor: answers via a stub, transcript captured (Aider↔OpenRouter lane) ----------
+# Non-secret key via a var (not a literal) so the security-scan credential rule's variable exclusion applies.
+FAKE_ORK="orkey-not-real"
+AIDER_STUB="$WORK/aider-stub"
+cat >"$AIDER_STUB" <<'EOF'
+#!/usr/bin/env bash
+set -u
+# Aider advisory stub: prints an answer to stdout (consult captures it). Ignores flags; never edits.
+printf 'ANSWER from aider stub\n[Pass] looks fine\nRECOMMENDATION: ship\n'
+exit "${AIDER_RC:-0}"
+EOF
+chmod +x "$AIDER_STUB"
+rm -rf "$OUT"
+out="$(CONSULT_ROOT="$A" AIDER_BIN="$AIDER_STUB" OPENROUTER_API_KEY="$FAKE_ORK" \
+  bash "$CONSULT" --prompt "review please" --out "$OUT" --label t --models aider 2>&1)"; rc=$?
+[ "$rc" -eq 0 ] && pass "aider advisor answers (exit 0)" || fail "aider exit=$rc ($out)"
+afile="$(ls "$OUT"/t-*/t.aider.md 2>/dev/null | head -1)"
+{ [ -s "$afile" ] && grep -q "ANSWER from aider" "$afile"; } && pass "aider transcript captured" || fail "no aider transcript"
+printf '%s' "$out" | grep -q "1 answered, 0 failed" && pass "aider counted as an answered advisor" || fail "aider not counted answered: $out"
+
+# --- (8) AIDER no OPENROUTER_API_KEY -> that advisor fails fast (all-fail exit 5, with the remedy) --
+rm -rf "$OUT"
+out="$(env -u OPENROUTER_API_KEY CONSULT_ROOT="$A" AIDER_BIN="$AIDER_STUB" \
+  bash "$CONSULT" --prompt "x" --out "$OUT" --label t --models aider 2>&1)"; rc=$?
+[ "$rc" -eq 5 ] && pass "aider with no OPENROUTER_API_KEY -> all-fail exit 5" || fail "no-key aider exit=$rc (expected 5)"
+afile="$(ls "$OUT"/t-*/t.aider.md 2>/dev/null | head -1)"
+grep -q "OPENROUTER_API_KEY not set" "$afile" 2>/dev/null && pass "aider no-key transcript states the remedy" || fail "no-key remedy missing from transcript"
+
 echo "  consult: $PASS passed, $FAIL failed"
 exit 0
diff --git a/validate.sh b/validate.sh
index 52eb98f..139e89e 100755
--- a/validate.sh
+++ b/validate.sh
@@ -35,6 +35,7 @@ TESTS=(
   "codex-turn.sh"
   "gemini-turn.sh"
   "agy-turn.sh"
+  "aider-turn.sh"
   "claude-turn.sh"
   "worktree-isolation.sh"
   "shim-worktree.sh"
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer · codex · 2026-07-02
**Verdict:** Changes requested

**Findings & proposals:**
- **[Blocker] `aider-turn.sh` can report a successful turn after failing to become the token owner.** In the new shim, the pre-turn `tick claim ... --paths ...` is explicitly best-effort (`|| true`), and the prompt then tells Aider not to run any tick commands because the harness already owns that protocol. If the claim misses for any reason, `rtl_enforce` later only warns on failed `tick release` / `tick done` ownership checks and the shim still exits 0 after committing the relay/artifact change. That leaves a committed turn with the relay token still open under the old owner, which deadlocks the lane. Fix: make the shim prove ownership before launching Aider: require `claim` to succeed (or verify via `tick info` that `claimer: $me` after the claim) and fail the turn if ownership was not established.
- **[Should] The new GH-77 execution doc is parked in `PROJECT/1-INBOX`, but its content is already a shipped project doc.** `PROJECT/PDDA.md` says a `GH-*` file in `1-INBOX` is the capture only: it stays in proposed/intake form and does not carry the active-doc `## Status` table until promotion. This diff adds `PROJECT/1-INBOX/GH-77-AIDER-OPENROUTER-LANE.md` with `status: Shipped`, a near-top status table, design/QA sections, and ROADMAP/ROUTER links to it as the canonical completed doc. That is the right content for `2-WORKING`/`3-COMPLETED`, not `1-INBOX`. Fix: move the doc to the lifecycle bucket that matches reality (`PROJECT/3-COMPLETED` if this lane is actually shipped, otherwise `PROJECT/2-WORKING`), and update the ROADMAP/ROUTER links to that location.
- **[Nit] The verification counts drift across the new GH-77 prose.** The new project doc's QA gate says `test/aider-turn.sh` has **26 checks**, while the changelog and ROADMAP entry say **28 checks**. A verification claim should have one fresh number or none; right now the docs disagree about what was actually run. Fix: normalize the count everywhere from the same observed source, or drop the brittle per-test count and keep the concrete named coverage plus `validate.sh` result.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
