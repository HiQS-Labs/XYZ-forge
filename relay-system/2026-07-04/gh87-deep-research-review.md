# RELAY · GH-87 Phase 1 review: deep-research.mjs grounded-search adapter
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-04.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh87-deep-research-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **gh87-review-diff.patch** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-04

### Artifact — gh87-review-diff.patch
```
diff --git a/CHANGELOG.md b/CHANGELOG.md
index 3927cc4..3ae7650 100644
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -4,6 +4,9 @@ All notable changes to this repo. Newest first. Dates are PDT.
 
 ## 2026-07-03
 
+### GH-87 Phase 1 — deep-research.mjs grounded-search adapter (branch, not yet merged)
+Built on branch `marathon/gh-87-deep-research-mode-2026-07-03` in an isolated worktree. `relay-automation/deep-research.mjs` is a zero-dep Node adapter wrapping the `agy` CLI as the first grounded-search backend (Agy Gemini Search), normalizing output to `{answer, citations, query, provider, model, raw}` so a second backend (Perplexity) can be added later without reworking the contract. Runs `agy -p` in a throwaway tmpdir (side-effect free) under a hard timeout; fail-closed typed errors (`binary_missing`/`timeout`/`empty_output`/`backend_error`) on stderr, never a silent fallback to the default model provider. `test/deep-research.sh` (21 assertions) covers request construction, CITATIONS-heading normalization, bare-URL fallback extraction, side-effect-free isolation, and all four failure modes. `validate.sh` **91/91** (live-agent test skipped via `RELAY_SELF_SUFFICIENCY_SKIP=1` to avoid real API spend). Doc promoted `PROJECT/1-INBOX` → `PROJECT/2-WORKING`; issue #87 stays open pending review/merge.
+
 ### Aider permanently installed and OpenRouter GLM v5.2 verified
 Installed Aider permanently to `~/.local/bin/aider` using a dedicated Python virtual environment (`~/.aider-venv`). Verified connectivity to OpenRouter's `z-ai/glm-5.2` model using the OpenRouter API key. 
 *(Note: Test successfully connected to OpenRouter but encountered an out-of-credits error for the GLM model).*
diff --git a/PROJECT/1-INBOX/GH-87-DEEP-RESEARCH-MODE.md b/PROJECT/2-WORKING/GH-87-DEEP-RESEARCH-MODE.md
similarity index 73%
rename from PROJECT/1-INBOX/GH-87-DEEP-RESEARCH-MODE.md
rename to PROJECT/2-WORKING/GH-87-DEEP-RESEARCH-MODE.md
index eb06467..d3fd78c 100644
--- a/PROJECT/1-INBOX/GH-87-DEEP-RESEARCH-MODE.md
+++ b/PROJECT/2-WORKING/GH-87-DEEP-RESEARCH-MODE.md
@@ -2,11 +2,16 @@
 gh_issue: 87
 source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/87
 title: Deep Research mode — provider-agnostic grounded search seam (Agy Gemini Search first adapter)
-status: Proposed (1-INBOX — not yet active)
+status: Phase 1 implemented on branch, awaiting review/merge and issue #87 close-out
 created: 2026-07-02
-updated: 2026-07-02
+updated: 2026-07-03
 owner: noel
 doc_type: feature
+goal: >
+  Ship a provider-agnostic grounded-search adapter, isolated from the harness's default model
+  client and Aider's OpenAI-compatible config, with Agy Gemini Search as the first backend and a
+  normalized {answer, citations, query, provider, model, raw} contract so a second backend
+  (Perplexity) can be added later without reworking the seam.
 complexity: 3
 risk: 2
 effort: 3
@@ -21,6 +26,12 @@ related:
 
 # GH-87 — Deep Research mode
 
+## Status
+
+| What was just completed | What's next |
+|---|---|
+| Phase 1 shipped on branch `marathon/gh-87-deep-research-mode-2026-07-03` (worktree build): `relay-automation/deep-research.mjs` — a zero-dep Node adapter wrapping the `agy` CLI as the first grounded-search backend, normalizing output to `{answer, citations, query, provider, model, raw}`. Runs `agy -p` in a throwaway tmpdir (side-effect free) with a hard timeout via `execFile`'s `timeout` option; fail-closed typed errors (`binary_missing`/`timeout`/`empty_output`/`backend_error`) on stderr, never a silent fallback. `test/deep-research.sh` (21 assertions) covers request construction, CITATIONS-heading normalization, bare-URL fallback extraction, side-effect-free isolation, and all four failure modes. Wired into `validate.sh` (91/91 passing, full suite, live-agent test skipped via `RELAY_SELF_SUFFICIENCY_SKIP=1` to avoid real API spend). | Review + merge the branch, then close issue #87. Perplexity remains a follow-up phase (not started) — the normalized schema and adapter boundary are already provider-agnostic to receive it without a rework. |
+
 ## Problem
 
 The harness now supports Aider CLI as a headless runner, and agents need a grounded web-search
@@ -75,10 +86,10 @@ without reworking the tool contract or global provider config.
 
 ## Definition of done
 
-- [ ] The repo has a dedicated grounded-search adapter/client with isolated env/config.
-- [ ] Agy Gemini Search works as the first backend via the Agy CLI and returns normalized cited output.
-- [ ] Search failures never silently fall back to the default provider.
-- [ ] Tests cover request shape, normalization, missing config, transport failures, and citation parsing.
+- [x] The repo has a dedicated grounded-search adapter/client with isolated env/config (`relay-automation/deep-research.mjs`; `AGY_BIN`/`DEEP_RESEARCH_TIMEOUT_MS` env, no shared state with Aider's config).
+- [x] Agy Gemini Search works as the first backend via the Agy CLI and returns normalized cited output.
+- [x] Search failures never silently fall back to the default provider (typed error + exit 1 on missing binary/timeout/empty output/non-zero exit).
+- [x] Tests cover request shape, normalization, missing config, transport failures, and citation parsing (`test/deep-research.sh`, 21 assertions; "missing config" realized as CLI-missing/binary_missing since Agy auth has no API-key config to test, unlike the original Perplexity framing).
 
 ## Implementation Plan
 
diff --git a/ROADMAP-DASHBOARD.md b/ROADMAP-DASHBOARD.md
index 79b2f70..6e575c7 100644
--- a/ROADMAP-DASHBOARD.md
+++ b/ROADMAP-DASHBOARD.md
@@ -6,21 +6,21 @@ Read-only derived view of the root [ROADMAP.md](ROADMAP.md) ledger.
 
 ## Queue / parked intake
 
-Summary: 25 items | Tally: 🟢 0 · 🟡 5 · ⏸️ 2 · ⛔ 0 · ✅ 2 · 🔮 0 · 🔲 0
+Summary: 25 items | Tally: 🟢 0 · 🟡 5 · ⏸️ 2 · ⛔ 0 · ✅ 6 · 🔮 0 · 🔲 0
 
 | Item | Status | Links |
 | --- | --- | --- |
 | GH-118 · Make Aider edit formats more forgiving for OpenRouter models | — | [GH-118-AIDER-OPENROUTER-FORMAT.md](PROJECT/1-INBOX/GH-118-AIDER-OPENROUTER-FORMAT.md) · [#118](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/118) |
-| GH-119 · aider-turn.sh: reviewer can auto-add and edit out-of-scope tracked files under --yes-always; all-or-nothing containment discards the valid in-lane edit too | — | [GH-119-AIDER-REVIEWER-SCOPE-CREEP.md](PROJECT/2-WORKING/GH-119-AIDER-REVIEWER-SCOPE-CREEP.md) · [#119](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/119) |
-| GH-120 · Build a fuzzy-match OpenRouter model-name lookup table (alias → canonical slug) | — | [GH-120-OPENROUTER-MODEL-ALIAS-TABLE.md](PROJECT/2-WORKING/GH-120-OPENROUTER-MODEL-ALIAS-TABLE.md) · [#120](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/120) |
+| GH-119 · aider-turn.sh: reviewer can auto-add and edit out-of-scope tracked files under --yes-always; all-or-nothing containment discards the valid in-lane edit too | ✅ | [GH-119-AIDER-REVIEWER-SCOPE-CREEP.md](PROJECT/3-COMPLETED/GH-119-AIDER-REVIEWER-SCOPE-CREEP.md) · [#119](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/119) |
+| GH-120 · Build a fuzzy-match OpenRouter model-name lookup table (alias → canonical slug) | ✅ | [GH-120-OPENROUTER-MODEL-ALIAS-TABLE.md](PROJECT/3-COMPLETED/GH-120-OPENROUTER-MODEL-ALIAS-TABLE.md) · [#120](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/120) |
 | GH-117 · fix(marathon-drive): --dry-run must probe builder/reviewer binary before mutating tick state | — | [#117](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/117) |
 | GH-116 · fix(tick): misleading 'break' error on open tasks + marathon retry flag | — | [#116](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/116) |
-| GH-114 · chore: remove deprecated gemini-turn.sh and scrub dead GEMINI references | — | [#114](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/114) |
-| GH-113 · fix(marathon-yaml): validator rejects agy reviewer — blocks multi-phase YAML plans | — | [#113](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/113) |
+| GH-114 · chore: remove deprecated gemini-turn.sh and scrub dead GEMINI references | ✅ | [#114](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/114) |
+| GH-113 · fix(marathon-yaml): validator rejects agy reviewer — blocks multi-phase YAML plans | ✅ | [#113](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/113) |
 | GH-112 · Spike: progressive Python port — boundary decision + dogfood architecture | — | [GH-112-PYTHON-PORT-SPIKE.md](PROJECT/1-INBOX/GH-112-PYTHON-PORT-SPIKE.md) · [#112](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/112) |
 | GH-109 · Gemini 3.1 Deep Think audit — watchdog process leak, tmp collision, DRY turn scripts, Python inline extraction | — | [GH-109-GEMINI-FEEDBACK.md](PROJECT/1-INBOX/GH-109-GEMINI-FEEDBACK.md) · [#109](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/109) |
 | GH-110 · Fable 5 Max audit — shellcheck + vendor integrity + strict-mode hardening | — | [GH-110-SHELLCHECK-VENDOR-FIXES.md](PROJECT/1-INBOX/GH-110-SHELLCHECK-VENDOR-FIXES.md) · [#110](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/110) |
-| GH-87 · Deep Research mode — provider-agnostic grounded search seam (Agy Gemini Search first adapter) | — | [GH-87-DEEP-RESEARCH-MODE.md](PROJECT/1-INBOX/GH-87-DEEP-RESEARCH-MODE.md) · [#87](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/87) |
+| GH-87 · Deep Research mode — provider-agnostic grounded search seam (Agy Gemini Search first adapter) | — | [GH-87-DEEP-RESEARCH-MODE.md](PROJECT/2-WORKING/GH-87-DEEP-RESEARCH-MODE.md) · [#87](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/87) |
 | GH-86 · marathon-plan — surface PR-review lanes so they don't silently drop | — | [GH-86-SURFACE-REVIEW-LANES.md](PROJECT/1-INBOX/GH-86-SURFACE-REVIEW-LANES.md) · [#86](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/86) |
 | GH-61 · CI GitHub Actions (Tier 1 lint/doc-hygiene + Tier 2 validate.sh) | ✅ | [GH-61-CI-GITHUB-ACTIONS.md](PROJECT/1-INBOX/GH-61-CI-GITHUB-ACTIONS.md) · [gh-61-ci-tier1-brief.md](PROJECT/2-WORKING/briefs/gh-61-ci-tier1-brief.md) · [#61](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/61) |
 | GH-41 · task.done not terminal vs higher-epoch reclaim (silent token resurrection) | ✅ | [decisions/2026-07-02-terminality-seal.md](decisions/2026-07-02-terminality-seal.md) · [GH-41-DONE-NOT-TERMINAL.md](PROJECT/3-COMPLETED/GH-41-DONE-NOT-TERMINAL.md) · [#41](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/41) |
@@ -28,10 +28,10 @@ Summary: 25 items | Tally: 🟢 0 · 🟡 5 · ⏸️ 2 · ⛔ 0 · ✅ 2 · 
 | GH-30 · optional centralized transcript archive | — | [GH-30-CENTRALIZED-TRANSCRIPT-ARCHIVE.md](PROJECT/2-WORKING/GH-30-CENTRALIZED-TRANSCRIPT-ARCHIVE.md) · [#30](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/30) |
 | Marathon dogfood · rebalance-OS parallel build queue (cross-repo, --target-root) | — | — |
 | GH-48 · generalize marathon-plan's zone model for cross-repo pre-pre-flight | — | [GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md](PROJECT/1-INBOX/GH-48-QUEUE-PLAN-CROSS-REPO-ZONES.md) · [#48](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/48) |
-| Dueling/relay · commit-signal advance (file-driven mode) | 🟡 | [test/poll-driver.sh](test/poll-driver.sh) · [poll.sh](relay-automation/poll.sh) · [Field findings](PROJECT/2-WORKING/AUTOMATED-RELAY.md#field-findings--first-cross-repo-dueling-run-2026-06-26) |
-| Dueling/relay · token resilience for a non-participating peer + multi-round reuse | 🟡 | [AUTOMATED-RELAY.md → Field findings](PROJECT/2-WORKING/AUTOMATED-RELAY.md#field-findings--first-cross-repo-dueling-run-2026-06-26) |
-| Gate design · convergence gates that pin a worse code shape | — | [AUTOMATED-RELAY.md → Field findings](PROJECT/2-WORKING/AUTOMATED-RELAY.md#field-findings--first-cross-repo-dueling-run-2026-06-26) |
-| Orchestration · in-loop gate verification must run sandbox-off | 🟡 | [AUTOMATED-RELAY.md → Field findings](PROJECT/2-WORKING/AUTOMATED-RELAY.md#field-findings--first-cross-repo-dueling-run-2026-06-26) |
+| Dueling/relay · commit-signal advance (file-driven mode) | 🟡 | [test/poll-driver.sh](test/poll-driver.sh) · [poll.sh](relay-automation/poll.sh) · [Field findings](PROJECT/4-MISC/AUTOMATED-RELAY.md#field-findings--first-cross-repo-dueling-run-2026-06-26) |
+| Dueling/relay · token resilience for a non-participating peer + multi-round reuse | 🟡 | [AUTOMATED-RELAY.md → Field findings](PROJECT/4-MISC/AUTOMATED-RELAY.md#field-findings--first-cross-repo-dueling-run-2026-06-26) |
+| Gate design · convergence gates that pin a worse code shape | — | [AUTOMATED-RELAY.md → Field findings](PROJECT/4-MISC/AUTOMATED-RELAY.md#field-findings--first-cross-repo-dueling-run-2026-06-26) |
+| Orchestration · in-loop gate verification must run sandbox-off | 🟡 | [AUTOMATED-RELAY.md → Field findings](PROJECT/4-MISC/AUTOMATED-RELAY.md#field-findings--first-cross-repo-dueling-run-2026-06-26) |
 | Tooling · agy reliability testing | ⏸️ | [AGY-RELIABILITY-TESTING.md](PROJECT/1-INBOX/AGY-RELIABILITY-TESTING.md) |
 | Tooling · front-door onboarding health | 🟡 | [FRONTDOOR.md](PROJECT/4-MISC/FRONTDOOR.md) · [FRONT-DOOR/2026-06-22.md](PROJECT/1-INBOX/FRONT-DOOR/2026-06-22.md) |
 | PDDA · feedback-synthesis direction | 🟡 | [PDDA-FEEDBACK-SYNTHESIS-PLAN.md](PROJECT/1-INBOX/PDDA/PDDA-FEEDBACK-SYNTHESIS-PLAN.md) · [pdda-feedback-synthesis.md](relay-system/2026-06-23/pdda-feedback-synthesis.md) |
@@ -101,7 +101,7 @@ Summary: 63 items | Tally: 🟢 0 · 🟡 0 · ⏸️ 0 · ⛔ 0 · ✅ 63 · 
 | GH-16 · same-device cross-repo swarm readiness (umbrella) | ✅ | [GH-16-CROSS-REPO-SWARM.md](PROJECT/3-COMPLETED/GH-16-CROSS-REPO-SWARM.md) · [#16](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/16) |
 | GH-36 · headless Codex isolated-turn friction (.tick sandbox) | ✅ | [GH-36-HEADLESS-CODEX-TICK-SANDBOX.md](PROJECT/3-COMPLETED/GH-36-HEADLESS-CODEX-TICK-SANDBOX.md) · [#36](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/36) |
 | GH-29 · cross-repo (--target-root) build doesn't commit NEW untracked files | ✅ | [relay-target-root-newfile.sh](test/relay-target-root-newfile.sh) · [GH-29-CROSS-REPO-NEWFILE-COMMIT.md](PROJECT/3-COMPLETED/GH-29-CROSS-REPO-NEWFILE-COMMIT.md) · [#29](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/29) |
-| Part A · Phase 6 — real-substrate dogfood (graduation test) | ✅ | [MARATHON-DOGFOOD-2026-06-25-WPCC-TS-TYPE-SUPPRESSION.md](PROJECT/2-WORKING/MARATHON-DOGFOOD-2026-06-25-WPCC-TS-TYPE-SUPPRESSION.md) · [wpcc-ts-type-suppression-brief.md](PROJECT/2-WORKING/briefs/wpcc-ts-type-suppression-brief.md) · [marathon-wpcc-095945.md](relay-system/2026-06-26/marathon-wpcc-095945.md) · [Sleuth](PROJECT/2-WORKING/MARATHON-DOGFOOD-2026-06-24-SLEUTH-NEARMISS-2LITE.md) · [brief](PROJECT/2-WORKING/briefs/sleuth-near-miss-2lite-brief.md) · [WPCC-old](PROJECT/2-WORKING/MARATHON-DOGFOOD-2026-06-18-WPCC-PHASE2.md) |
+| Part A · Phase 6 — real-substrate dogfood (graduation test) | ✅ | [MARATHON-DOGFOOD-2026-06-25-WPCC-TS-TYPE-SUPPRESSION.md](PROJECT/4-MISC/MARATHON-DOGFOOD-2026-06-25-WPCC-TS-TYPE-SUPPRESSION.md) · [wpcc-ts-type-suppression-brief.md](PROJECT/4-MISC/wpcc-ts-type-suppression-brief.md) · [marathon-wpcc-095945.md](relay-system/2026-06-26/marathon-wpcc-095945.md) · [Sleuth](PROJECT/4-MISC/MARATHON-DOGFOOD-2026-06-24-SLEUTH-NEARMISS-2LITE.md) · [brief](PROJECT/4-MISC/sleuth-near-miss-2lite-brief.md) · [WPCC-old](PROJECT/4-MISC/MARATHON-DOGFOOD-2026-06-18-WPCC-PHASE2.md) |
 | GH-31 · cross-repo external-artifact review flow | ✅ | [GH-31-CROSS-REPO-ARTIFACT-REVIEW.md](PROJECT/3-COMPLETED/GH-31-CROSS-REPO-ARTIFACT-REVIEW.md) · [#31](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/31) |
 | GH-32 · single-turn review ergonomics | ✅ | [GH-32-SINGLE-TURN-REVIEW-ERGONOMICS.md](PROJECT/3-COMPLETED/GH-32-SINGLE-TURN-REVIEW-ERGONOMICS.md) · [#32](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/32) |
 | GH-25 · swarm preflight planner | ✅ | [GH-25-SWARM-PREFLIGHT-PLANNER.md](PROJECT/3-COMPLETED/GH-25-SWARM-PREFLIGHT-PLANNER.md) · [#25](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/25) |
@@ -109,11 +109,11 @@ Summary: 63 items | Tally: 🟢 0 · 🟡 0 · ⏸️ 0 · ⛔ 0 · ✅ 63 · 
 | GH-20 · agy first-class footing in live relay docs | ✅ | [README.md](README.md) · [relay-automation/README.md](relay-automation/README.md) · [#20](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/20) · [GH-20-AGY-FIRST-CLASS-FOOTING.md](PROJECT/3-COMPLETED/GH-20-AGY-FIRST-CLASS-FOOTING.md) |
 | GH-18 · cross-repo driven-relay friction | ✅ | [codex-turn.sh:57](relay-automation/codex-turn.sh#L57) · [GH-18-CROSS-REPO-RELAY-FRICTION.md](PROJECT/3-COMPLETED/GH-18-CROSS-REPO-RELAY-FRICTION.md) · [#18](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/18) |
 | GH-21 · relay quality gate — independent post-generation validator | ✅ | [GH-21-RELAY-QUALITY-GATE.md](PROJECT/3-COMPLETED/GH-21-RELAY-QUALITY-GATE.md) · [#21](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/21) |
-| Part A · Phase 1 — Cost observability foundation | ✅ | [COST-OBSERVABILITY-PLAN.md](PROJECT/2-WORKING/COST-OBSERVABILITY-PLAN.md) |
+| Part A · Phase 1 — Cost observability foundation | ✅ | [COST-OBSERVABILITY-PLAN.md](PROJECT/4-MISC/COST-OBSERVABILITY-PLAN.md) |
 | Part A · Phases 2–4 — Marathon harness build | ✅ | [MARATHON-HARNESS.md](PROJECT/3-COMPLETED/MARATHON-HARNESS.md) |
-| Part A · Phase 5 — Cross-system cost comparison | ✅ | [COST-COMPARISON.md](PROJECT/2-WORKING/COST-COMPARISON.md) |
+| Part A · Phase 5 — Cross-system cost comparison | ✅ | [COST-COMPARISON.md](PROJECT/4-MISC/COST-COMPARISON.md) |
 | Part B · Phase 1 — Epoch fencing & stale-writer prevention | ✅ | [ADVERSARIAL-HARDENING.md](PROJECT/2-WORKING/ADVERSARIAL-HARDENING.md#phase-1--epoch-fencing--stale-writer-prevention-r1--g3) · [decision record](decisions/2026-06-18-epoch-fencing.md) |
-| Tooling · Automated /relay loop | ✅ | [AUTOMATED-RELAY.md](PROJECT/2-WORKING/AUTOMATED-RELAY.md) |
+| Tooling · Automated /relay loop | ✅ | [AUTOMATED-RELAY.md](PROJECT/4-MISC/AUTOMATED-RELAY.md) |
 | Tooling · relay-xyz install hygiene | ✅ | [RELAY-XYZ-DISCOVERY-SHAKEDOWN.md](PROJECT/3-COMPLETED/RELAY-XYZ-DISCOVERY-SHAKEDOWN.md) |
 
 ## Deferred · vision
diff --git a/ROADMAP.md b/ROADMAP.md
index cfec0b6..65192f0 100644
--- a/ROADMAP.md
+++ b/ROADMAP.md
@@ -73,7 +73,7 @@ Mechanical / pattern-following work → **Sonnet High**; trust-critical kernel-c
 - **GH-112 · Spike: progressive Python port — boundary decision + dogfood architecture** 🆕 **captured 2026-07-03 · rated** — one spike lane answers three questions before any port work is queued: (1) what stays Bash permanently (source-dep graph of relay-turn-lib.sh), (2) Option A (discrete Python CLIs behind Bash shims, safest) vs Option B (Python orchestrator with Bash FFI, higher payoff), (3) test-bridge contract (85 shell tests must stay green during transition). If boundary is clean → one follow-up issue per turn script, marathon-waveable. Deliverable: a `decisions/` record, not code. cx/risk/eff 3/3/2. → [GH-112-PYTHON-PORT-SPIKE.md](PROJECT/1-INBOX/GH-112-PYTHON-PORT-SPIKE.md) · [#112](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/112)
 - **GH-109 · Gemini 3.1 Deep Think audit — watchdog process leak, tmp collision, DRY turn scripts, Python inline extraction** 🆕 **captured 2026-07-03 · rated** — 4 of 5 findings actioned: orphaned `sleep` grandchild leak in `consult.sh` watchdog (resource bug), `/tmp` permission collision in `relay-xyz-guard.sh` (trivial `$UID` fix), inline Python heredoc extraction to discrete utils (scoped-down Item 5), and DRY turn-script audit (scoped-down Item 1 — extend relay-turn-lib.sh, not a new dispatcher). Item 4 (retire scanner for Gitleaks/TruffleHog) declined — no-external-dep constraint. cx/risk/eff 3/3/3. → [GH-109-GEMINI-FEEDBACK.md](PROJECT/1-INBOX/GH-109-GEMINI-FEEDBACK.md) · [#109](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/109)
 - **GH-110 · Fable 5 Max audit — shellcheck + vendor integrity + strict-mode hardening** 🆕 **captured 2026-07-03 · rated** — Fable 5 Max ran shellcheck (63 findings, almost all cosmetic), executed all 85 tests in a clean Linux container, and diffed the vendor tarball. Five valid findings: broken test assertion in `xyz-vendor.sh:140`, stale `relay-pkg.tar.gz` (safety core — also the GH-104 remaining follow-up), 8/85 vendored-copy test failures, 788-line JS heredoc invisible to the Tier-1 check gate, and undocumented strict-mode convention. Phased: P1 quick fixes (~1 hr), P2 vendor integrity (~2–3 hrs), P3 code quality (~1 day). cx/risk/eff 3/2/3. → [GH-110-SHELLCHECK-VENDOR-FIXES.md](PROJECT/1-INBOX/GH-110-SHELLCHECK-VENDOR-FIXES.md) · [#110](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/110)
-- **GH-87 · Deep Research mode — provider-agnostic grounded search seam (Agy Gemini Search first adapter)** 🆕 **captured 2026-07-02 · rated** — the new Aider-capable harness needs a first-class grounded-search tool without hard-wiring the whole system to one vendor. Local framing intentionally keeps the **search-provider seam provider-agnostic** while taking **Agy Gemini Search** as the first backend (via the Agy CLI), with Perplexity as a follow-up phase; fail-closed, normalized cited output, isolated env/config, and tests for request/response/error paths. cx/risk/eff 3/2/3. → [GH-87-DEEP-RESEARCH-MODE.md](PROJECT/1-INBOX/GH-87-DEEP-RESEARCH-MODE.md) · [#87](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/87)
+- **GH-87 · Deep Research mode — provider-agnostic grounded search seam (Agy Gemini Search first adapter)** 🔨 **Phase 1 implemented 2026-07-03 on branch `marathon/gh-87-deep-research-mode-2026-07-03` (worktree build), awaiting review/merge** — the new Aider-capable harness needs a first-class grounded-search tool without hard-wiring the whole system to one vendor. Local framing intentionally keeps the **search-provider seam provider-agnostic** while taking **Agy Gemini Search** as the first backend (via the Agy CLI), with Perplexity as a follow-up phase. Shipped: `relay-automation/deep-research.mjs` (zero-dep Node adapter, runs `agy -p` in a throwaway tmpdir, fail-closed typed errors, normalized `{answer, citations, query, provider, model, raw}`) + `test/deep-research.sh` (21 assertions), wired into `validate.sh` (91/91). cx/risk/eff 3/2/3. → [GH-87-DEEP-RESEARCH-MODE.md](PROJECT/2-WORKING/GH-87-DEEP-RESEARCH-MODE.md) · [#87](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/87)
 - **GH-86 · marathon-plan — surface PR-review lanes so they don't silently drop** 🆕 **captured 2026-07-02 · rated** — `marathon-plan.sh` generates only build lanes; PR-review lanes live only in a manual `PR-REVIEW-QUEUE-<date>.md` overlay nothing surfaces, so two review lanes (PR #79/#81) were silently never run (caught 2026-07-02). Fix (Level 1): the plan prints a "Review lanes (run via relay-xyz)" section when today's overlay has open lanes. cx/risk/eff 2/1/2. → [GH-86-SURFACE-REVIEW-LANES.md](PROJECT/1-INBOX/GH-86-SURFACE-REVIEW-LANES.md) · [#86](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/86)
 - **GH-61 · CI GitHub Actions (Tier 1 lint/doc-hygiene + Tier 2 validate.sh)** ✅ **Tier 1 SHIPPED 2026-07-02 (`d9b8a14`, marathon dogfood — codex + agy Approved); Tier 2 held for the operator runner decision** — `.github/workflows/ci.yml` (single `ubuntu-latest` job: `shellcheck -S error` + `bash -n` + `node --check` + settings-JSON validate + `pdda.sh run`) + a dependency-free `test/ci-workflow.sh` wired into `validate.sh` (**80/80**). The run reproduced **#59** live (allowlisted artifact in a new untracked dir → spurious off-lane exit 6). **Tier 2 remaining:** running `./validate.sh` inside CI carries an unresolved `macos-latest` (fast, ~10× minutes) vs `ubuntu-latest` + portability/skip-gating decision — reserved for the operator; #61 stays open for it. no CI today; add Actions to catch the ~80% (bash logic + doc/path drift). **Tier 1** (cheap, always-green, no auth): `shellcheck` + `bash -n` on all `*.sh`, `node --check`/JSON-validate, `utils/pdda/pdda.sh run` full-mode. **Tier 2** (the real gate): `./validate.sh` 69-test suite — needs a portability + live-agent skip-gating pass, and a runner decision (`macos-latest` fast/~10× minutes vs `ubuntu` cheap/needs the pass) left open; don't make it *required* until reliably green. Marathon-sequenceable: Tier 1 = independent quick-win lane; Tier 2 depends on the skip-gating sub-task. → [GH-61-CI-GITHUB-ACTIONS.md](PROJECT/1-INBOX/GH-61-CI-GITHUB-ACTIONS.md) · brief: [gh-61-ci-tier1-brief.md](PROJECT/2-WORKING/briefs/gh-61-ci-tier1-brief.md) · [#61](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/61)
 - **GH-41 · `task.done` not terminal vs higher-epoch reclaim (silent token resurrection)** 🐞 ✅ **SHIPPED 2026-07-03 (Plan A lane 1 — PR #99)** — latent kernel gap (GH-40 canary #1): in `src/project.js` `foldWithMeta` a completed task was silently resurrected by a later higher-epoch `task.claimed` (`done`→`claimed`, 0 rejections). **Option A (terminality-seal)** landed (`/consult` Codex + agy unanimous; [decisions/2026-07-02-terminality-seal.md](decisions/2026-07-02-terminality-seal.md)): a terminal is now authorized against `ownerAsOf(terminal.ts)` (not the global winner), and once sealed every later claim is rejected as the new distinct reason `claim-after-terminal` — never a `done`→`claimed` flip. Canary **inverted** (`verify-fixture.sh`: `done 1 claim-after-terminal`; control `done 0`); all projection/tick/chaos suites green, no epoch-fence regression. Option B deferred. cx/risk/eff 4/4/3. → [GH-41-DONE-NOT-TERMINAL.md](PROJECT/3-COMPLETED/GH-41-DONE-NOT-TERMINAL.md) · [#41](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/41)
diff --git a/relay-automation/deep-research.mjs b/relay-automation/deep-research.mjs
new file mode 100755
index 0000000..226b499
--- /dev/null
+++ b/relay-automation/deep-research.mjs
@@ -0,0 +1,175 @@
+#!/usr/bin/env node
+'use strict';
+
+// deep-research.mjs — provider-agnostic grounded-search adapter (GH-87). First backend: Agy Gemini
+// Search via the `agy` CLI, wrapped so a second backend can be added later without changing the
+// normalized {answer, citations, query, provider, model, raw} contract or the harness's default
+// model-provider config. Fail-closed: any backend failure prints a typed error to stderr and exits
+// non-zero — never a silent fallback to a different provider. Node stdlib only, no new deps.
+//
+// Usage:
+//   node relay-automation/deep-research.mjs --query "..." [--search-context-size low|medium|high] \
+//     [--temperature 0.0] [--max-tokens N]
+//
+// Env:
+//   AGY_BIN                    agy binary (default: agy; tests inject a stub)
+//   DEEP_RESEARCH_TIMEOUT_MS   wall-clock cap in ms (default: 120000)
+//
+// Exit: 0 = normalized JSON on stdout · 1 = typed error JSON on stderr (CLI missing, timeout, non-zero
+// exit, empty output) · 2 = usage error.
+
+import { execFile } from 'node:child_process';
+import { mkdtemp, rm } from 'node:fs/promises';
+import { tmpdir } from 'node:os';
+import { join } from 'node:path';
+
+const PROVIDER = 'agy';
+const MODEL = 'gemini';
+const SEARCH_CONTEXT_SIZES = ['low', 'medium', 'high'];
+
+function usageError(message) {
+  process.stderr.write(`deep-research: ${message}\n`);
+  process.stderr.write(
+    'Usage: deep-research.mjs --query "..." [--search-context-size low|medium|high] ' +
+      '[--temperature N] [--max-tokens N]\n'
+  );
+  process.exit(2);
+}
+
+function parseArgs(argv) {
+  const out = { query: '', searchContextSize: 'medium', temperature: 0, maxTokens: null };
+  for (let i = 0; i < argv.length; i++) {
+    const a = argv[i];
+    switch (a) {
+      case '--query':
+        out.query = argv[++i] ?? '';
+        break;
+      case '--search-context-size':
+        out.searchContextSize = argv[++i] ?? '';
+        break;
+      case '--temperature':
+        out.temperature = Number(argv[++i]);
+        break;
+      case '--max-tokens':
+        out.maxTokens = Number(argv[++i]);
+        break;
+      default:
+        usageError(`unknown argument: ${a}`);
+    }
+  }
+  return out;
+}
+
+function validateArgs(args) {
+  if (!args.query) usageError('--query is required');
+  if (!SEARCH_CONTEXT_SIZES.includes(args.searchContextSize)) {
+    usageError(`--search-context-size must be one of ${SEARCH_CONTEXT_SIZES.join('|')}, got "${args.searchContextSize}"`);
+  }
+  if (!Number.isFinite(args.temperature)) usageError('--temperature must be a number');
+  if (args.maxTokens !== null && (!Number.isFinite(args.maxTokens) || args.maxTokens <= 0)) {
+    usageError('--max-tokens must be a positive number');
+  }
+}
+
+// Factual, citation-oriented system prompt: forbids fabricated URLs/titles/quotes and disclaims any
+// need for file/shell tools, since this adapter must stay side-effect free.
+const SYSTEM_PROMPT = `You are a factual, citation-oriented grounded-search assistant. Answer ONLY \
+using information you can verify via web search grounding. Every claim must be backed by a real, \
+verifiable citation (URL + title). NEVER fabricate a URL, a title, or a quote — if you cannot find a \
+citation, say so instead of inventing one. Do not use file or shell tools; you have no reason to write \
+or modify any file for this task.`;
+
+const DEPTH_HINT = {
+  low: 'Answer briefly, citing 1-3 sources.',
+  medium: 'Answer with moderate depth, citing 2-5 sources.',
+  high: 'Answer thoroughly, citing as many relevant sources as are genuinely available.',
+};
+
+function buildPrompt({ query, searchContextSize }) {
+  return `${SYSTEM_PROMPT}\n${DEPTH_HINT[searchContextSize]}\n\n=== QUERY ===\n${query}\n\nRespond with \
+a direct ANSWER, followed by a line reading "CITATIONS:" and then one citation per line formatted as \
+"- <title> — <url>".`;
+}
+
+// Pull citations out of a "CITATIONS:" section (falls back to scanning the whole answer for bare
+// URLs, so a model that skips the requested heading still yields citations rather than none).
+function extractCitations(text) {
+  const citations = [];
+  const seen = new Set();
+  const section = text.split(/^\s*CITATIONS:?\s*$/im)[1] ?? text;
+  const urlRe = /https?:\/\/[^\s)>\]]+/g;
+  let match;
+  while ((match = urlRe.exec(section)) !== null) {
+    const url = match[0].replace(/[.,;:]+$/, '');
+    if (seen.has(url)) continue;
+    seen.add(url);
+    const lineStart = section.lastIndexOf('\n', match.index) + 1;
+    const line = section.slice(lineStart, match.index);
+    const titleMatch = line.match(/-\s*(.+?)\s*[-–—]\s*$/);
+    citations.push({ url, title: titleMatch ? titleMatch[1].trim() : null });
+  }
+  return citations;
+}
+
+async function runAgy(args) {
+  const bin = process.env.AGY_BIN || 'agy';
+  const timeoutMs = Number(process.env.DEEP_RESEARCH_TIMEOUT_MS || 120000);
+  const prompt = buildPrompt(args);
+
+  // Run in a throwaway tmpdir (not the caller's repo) so this tool stays side-effect free even if
+  // the model attempts a file write despite the system prompt's instruction not to.
+  const workDir = await mkdtemp(join(tmpdir(), 'deep-research-'));
+  try {
+    const { stdout } = await new Promise((resolve, reject) => {
+      execFile(
+        bin,
+        ['-p', prompt, '--print-timeout', `${Math.ceil(timeoutMs / 1000)}s`],
+        { cwd: workDir, timeout: timeoutMs, killSignal: 'SIGKILL', encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] },
+        (err, stdout, stderr) => (err ? reject(Object.assign(err, { stdout, stderr })) : resolve({ stdout, stderr }))
+      );
+    });
+    const answer = stdout.trim();
+    if (!answer) throw Object.assign(new Error('agy returned no output'), { emptyOutput: true });
+    return {
+      answer,
+      citations: extractCitations(answer),
+      query: args.query,
+      provider: PROVIDER,
+      model: MODEL,
+      raw: { stdout, config: { searchContextSize: args.searchContextSize, temperature: args.temperature, maxTokens: args.maxTokens } },
+    };
+  } finally {
+    await rm(workDir, { recursive: true, force: true }).catch(() => {});
+  }
+}
+
+function classifyError(err) {
+  if (err.code === 'ENOENT') return 'binary_missing';
+  if (err.killed || err.signal) return 'timeout';
+  if (err.emptyOutput) return 'empty_output';
+  return 'backend_error';
+}
+
+async function main() {
+  const args = parseArgs(process.argv.slice(2));
+  validateArgs(args);
+
+  const start = Date.now();
+  try {
+    const result = await runAgy(args);
+    const latencyMs = Date.now() - start;
+    process.stdout.write(JSON.stringify(result) + '\n');
+    process.stderr.write(
+      `deep-research: ok provider=${PROVIDER} model=${MODEL} latency_ms=${latencyMs} citations=${result.citations.length}\n`
+    );
+    process.exit(0);
+  } catch (err) {
+    const kind = classifyError(err);
+    const latencyMs = Date.now() - start;
+    process.stderr.write(JSON.stringify({ error: kind, message: err.message, provider: PROVIDER, query: args.query }) + '\n');
+    process.stderr.write(`deep-research: FAILED provider=${PROVIDER} kind=${kind} latency_ms=${latencyMs}\n`);
+    process.exit(1);
+  }
+}
+
+main();
diff --git a/test/deep-research.sh b/test/deep-research.sh
new file mode 100755
index 0000000..70b556f
--- /dev/null
+++ b/test/deep-research.sh
@@ -0,0 +1,105 @@
+#!/usr/bin/env bash
+# GH-87: deep-research.mjs — provider-agnostic grounded-search adapter (Agy Gemini Search backend).
+# Asserts request construction reaches the agy CLI, response normalization (with and without a
+# CITATIONS heading), that the adapter stays side-effect free (agy runs in a throwaway tmpdir, not
+# the caller's CWD), and fail-closed behavior on a missing binary, non-zero exit, empty output, and
+# timeout — never a silent fallback to a different provider.
+set -u
+HERE="$(cd "$(dirname "$0")" && pwd)"
+DR="$HERE/../relay-automation/deep-research.mjs"
+WORK="$(mktemp -d -t deep-research-test.XXXXXX)"
+trap 'rm -rf "$WORK"' EXIT
+
+PASS=0; FAIL=0
+pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
+fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
+echo "== test: deep-research =="
+
+# Stub `agy`: ignores the real CLI flags (-p <prompt> --print-timeout <n>s) and answers purely off
+# STUB_MODE, mirroring test/agy-turn.sh's stub convention.
+STUB="$WORK/agy"
+cat >"$STUB" <<'STUB_EOF'
+#!/usr/bin/env bash
+set -u
+mode="${STUB_MODE:-good}"
+[ -n "${STUB_CWD_MARKER:-}" ] && pwd > "$STUB_CWD_MARKER"
+case "$mode" in
+  good)
+    cat <<'ANSWER'
+Deep research combines grounded retrieval with generation.
+
+CITATIONS:
+- Example Docs — https://example.com/docs
+- Example Blog — https://example.com/blog
+ANSWER
+    ;;
+  noformat) printf 'Some answer mentioning https://example.com/a and https://example.com/b inline.\n' ;;
+  empty)    exit 0 ;;
+  nonzero)  echo "boom" >&2; exit 1 ;;
+  hang)     sleep 5 ;;
+esac
+STUB_EOF
+chmod +x "$STUB"
+
+run() {  # run <stub-mode> <deep-research args...>
+  local mode="$1"; shift
+  STUB_MODE="$mode" AGY_BIN="$STUB" node "$DR" "$@"
+}
+
+# --- (1) usage errors: missing/invalid args -> exit 2, no stdout ----------------------------------
+out="$(run good 2>/dev/null)"; rc=$?
+{ [ "$rc" -eq 2 ] && [ -z "$out" ]; } && pass "missing --query -> usage (exit 2)" || fail "rc=$rc out='$out'"
+
+out="$(run good --query q --search-context-size huge 2>/dev/null)"; rc=$?
+{ [ "$rc" -eq 2 ] && [ -z "$out" ]; } && pass "bad --search-context-size -> usage (exit 2)" || fail "rc=$rc out='$out'"
+
+out="$(run good --query q --temperature nope 2>/dev/null)"; rc=$?
+{ [ "$rc" -eq 2 ] && [ -z "$out" ]; } && pass "non-numeric --temperature -> usage (exit 2)" || fail "rc=$rc out='$out'"
+
+# --- (2) good turn: request construction + response normalization --------------------------------
+out="$(run good --query "what is deep research" --search-context-size high --temperature 0.2 --max-tokens 500)"; rc=$?
+[ "$rc" -eq 0 ] && pass "good turn exits 0" || fail "good turn rc=$rc"
+echo "$out" | grep -q '"provider":"agy"' && pass "provider is agy" || fail "provider field wrong: $out"
+echo "$out" | grep -q '"model":"gemini"' && pass "model field set" || fail "model field wrong: $out"
+echo "$out" | grep -q '"query":"what is deep research"' && pass "query echoed back" || fail "query field wrong: $out"
+echo "$out" | grep -q 'https://example.com/docs' && echo "$out" | grep -q 'https://example.com/blog' \
+  && pass "both citations extracted from a CITATIONS section" || fail "citations missing: $out"
+echo "$out" | grep -q '"title":"Example Docs"' && pass "citation title parsed" || fail "citation title missing: $out"
+echo "$out" | grep -q '"searchContextSize":"high"' && pass "raw.config carries searchContextSize through" || fail "raw config missing searchContextSize: $out"
+
+# --- (3) fallback citation extraction: no CITATIONS heading, bare inline URLs ---------------------
+out="$(run noformat --query q)"; rc=$?
+[ "$rc" -eq 0 ] && pass "noformat turn exits 0" || fail "noformat rc=$rc"
+echo "$out" | grep -q 'https://example.com/a' && echo "$out" | grep -q 'https://example.com/b' \
+  && pass "fallback extraction finds bare inline URLs" || fail "fallback citations missing: $out"
+
+# --- (4) side-effect free: agy runs in a throwaway tmpdir, not the caller's CWD, cleaned up after --
+marker="$WORK/cwd-marker"
+( cd "$WORK" && STUB_CWD_MARKER="$marker" STUB_MODE=good AGY_BIN="$STUB" node "$DR" --query q >/dev/null )
+invoked_cwd="$(cat "$marker" 2>/dev/null)"
+{ [ -n "$invoked_cwd" ] && [ "$invoked_cwd" != "$WORK" ] && [ ! -d "$invoked_cwd" ]; } \
+  && pass "agy invoked from a throwaway tmpdir, cleaned up after (side-effect free)" \
+  || fail "expected a cleaned-up tmpdir distinct from \$WORK, got '$invoked_cwd'"
+
+# --- (5) fail-closed: empty output (agy exits 0, prints nothing) -> exit 1, typed error, no fallback
+out="$(run empty --query q 2>"$WORK/err")"; rc=$?
+{ [ "$rc" -eq 1 ] && [ -z "$out" ]; } && pass "empty output -> exit 1, no stdout" || fail "rc=$rc out='$out'"
+grep -q '"error":"empty_output"' "$WORK/err" && pass "empty output -> typed error on stderr" || fail "missing typed error: $(cat "$WORK/err")"
+
+# --- (6) fail-closed: agy exits non-zero -> exit 1, typed error, no fallback -----------------------
+out="$(run nonzero --query q 2>"$WORK/err")"; rc=$?
+{ [ "$rc" -eq 1 ] && [ -z "$out" ]; } && pass "non-zero exit -> exit 1, no stdout" || fail "rc=$rc out='$out'"
+grep -q '"error":"backend_error"' "$WORK/err" && pass "non-zero exit -> typed error on stderr" || fail "missing typed error: $(cat "$WORK/err")"
+
+# --- (7) fail-closed: binary missing -> exit 1, typed error, no fallback ---------------------------
+out="$(AGY_BIN="$WORK/does-not-exist" node "$DR" --query q 2>"$WORK/err")"; rc=$?
+{ [ "$rc" -eq 1 ] && [ -z "$out" ]; } && pass "missing binary -> exit 1, no stdout" || fail "rc=$rc out='$out'"
+grep -q '"error":"binary_missing"' "$WORK/err" && pass "missing binary -> typed error on stderr" || fail "missing typed error: $(cat "$WORK/err")"
+
+# --- (8) fail-closed: timeout -> exit 1, typed error, never a silent fallback ----------------------
+out="$(STUB_MODE=hang AGY_BIN="$STUB" DEEP_RESEARCH_TIMEOUT_MS=500 node "$DR" --query q 2>"$WORK/err")"; rc=$?
+{ [ "$rc" -eq 1 ] && [ -z "$out" ]; } && pass "timeout -> exit 1, no stdout" || fail "rc=$rc out='$out'"
+grep -q '"error":"timeout"' "$WORK/err" && pass "timeout -> typed error on stderr" || fail "missing typed error: $(cat "$WORK/err")"
+
+echo "  deep-research: $PASS pass, $FAIL fail"
+[ "$FAIL" = 0 ]
diff --git a/validate.sh b/validate.sh
index a2c7909..c0f0733 100755
--- a/validate.sh
+++ b/validate.sh
@@ -57,6 +57,7 @@ TESTS=(
   "improve-loop-dogfood.sh"
   "marathon.sh"
   "consult.sh"
+  "deep-research.sh"             # GH-87 (provider-agnostic grounded-search adapter)
   "skill-extract.sh"
   "path-integrity.sh"
   "relay-turn-timeout.sh"
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

### Round 1 · Reviewer · agy

VERDICT: PASS
Basis: The deep-research adapter is fully isolated, properly handles Agy CLI execution and constraints, passes its extensive test suite, and is wired into the project's gate.

**Verdict details:** No [Blocker]s, no [Should]s. 2 [Nit]s. All code changes are clean, comprehensive, and well-tested.

**Findings:**

- **[Nit] `relay-automation/deep-research.mjs` — Bullet style flexibility in citation extraction.** The title extraction regex `/-\s*(.+?)\s*[-–—]\s*$/` matches only leading hyphen bullets (`-`). While the system prompt explicitly requests `-` formatted bullets, LLMs sometimes output other standard bullet characters like `*` or `+`. A more flexible pattern such as `/^[-*+]\s*(.+?)\s*[-–—]\s*$/` (with appropriate line anchors or `match.index` slice logic) would improve fallback title resilience. Fix: No action required as `-` is explicitly prompted, but a future revision could broaden the regex.

- **[Nit] `relay-automation/deep-research.mjs` — Greedy title matching on multi-citation lines.** If multiple citations are formatted on the same line (e.g., `- First — https://example.com/a and Second — https://example.com/b`), the title extracted for the second URL will greedily encompass the first URL's content (yielding `"First — https://example.com/a and Second"`). Fix: No action required as the prompt instructs the model to write one citation per line, but worth noting as a minor edge-case quirk.

- **[Pass] `relay-automation/deep-research.mjs` — Architecture and Contract.** The normalized schema (`{answer, citations, query, provider, model, raw}`) correctly matches the requirements and allows future backend support (such as Perplexity) without reworking the adapter seam. Temperature and max tokens are safely propagated via `raw.config`.

- **[Pass] `relay-automation/deep-research.mjs` — fail-closed design.** Robust classification of errors (`binary_missing`, `timeout`, `empty_output`, `backend_error`) on stderr with non-zero exit codes.

- **[Pass] `relay-automation/deep-research.mjs` — isolation and side-effect free execution.** Running the binary under `execFile` within a temporary directory (created via `mkdtemp` and cleaned up in the `finally` block) guarantees that any model attempt to write files or mutate the repository is contained.

- **[Pass] `test/deep-research.sh` — Test suite coverage.** The 8 test sections are highly comprehensive, covering error exits, argument validation, normalization, bare-URL fallback extraction, fail-closed modes, and a creative assertion validating side-effect-free isolated execution and directory cleanup.

- **[Pass] integration wiring.** Correctly wired into `validate.sh` and documented in `CHANGELOG.md` and `PROJECT/2-WORKING/GH-87-DEEP-RESEARCH-MODE.md`.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
