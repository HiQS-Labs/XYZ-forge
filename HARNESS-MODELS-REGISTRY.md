# Harness & Models Registry

Canonical evidence ledger for agent harnesses and model routes considered by XYZ. The evaluation SOP is
[`PROJECT/1-INBOX/GH-17-SOP-HARNESS-MODEL-EVAL.md`](PROJECT/1-INBOX/GH-17-SOP-HARNESS-MODEL-EVAL.md).

**Scope and evidence boundary (reviewed 2026-08-16).** This registry distinguishes a standing
operating-policy choice from an evaluated harness–model route. Historical results came from the
preceding `xyz-3-agents-swarm` checkout and its GitHub issues; they demonstrate the recorded versions,
providers, and harness configuration only. They do not automatically qualify a renamed model, a new
provider endpoint, or a new harness version.

## Grading rubric

| Grade | Classification | Evidence required |
|:---:|:---|:---|
| **A** | Production-ready | At least three verified end-to-end runs of the exact route, clean scoped diffs, and a passing qualifying gate. The evidence must be reviewable and the final PR/commit state known. |
| **B** | Functional with caveats | A working route whose safe use depends on explicit flags, timeouts, role limits, or supervision; also the holding grade for otherwise-promising runs awaiting final integration/review. |
| **C** | Problematic | Reproducible severe failure mode that prevents unattended use. |
| **N/A** | Untested / insufficient evidence | Cataloged or trialed, but not enough evidence to recommend it. |

Policy designations are deliberately **not grades**. A default lane can be operationally chosen while
its exact current model release awaits the same evidence required of every other route.

## 1. Standing operating lanes (policy, not a model grade)

| Harness | Current policy role | Operating constraint | Policy source |
|---|---|---|---|
| Command Code & Codex CLI | Builder evaluation for GH-57 (2026-08-19) | Non-interactive `cmd --print` on complex synthesis stalled across Muse Spark (4.5 min cap), Qwen 3.8-Max, and GLM-5.2 due to stdout buffering / missing interactive turn cycle. Codex CLI fallback succeeded, producing the 42-assertion `test/gh57-releases-fuzz.sh` suite and updating `utils/fuzzing/fuzz-loop.sh` (42/42 pass). | [#57](https://github.com/HiQS-Suite/XYZ-forge/issues/57) |
| Claude Code | Orchestrator and final reviewer | Do not use as a default headless builder; an API-billed Claude builder is operator-selected only. | GH-221 / [`AGENTS.md`](AGENTS.md) |
| Codex CLI | Cost-blind default builder and reviewer | Use the subscription-authenticated CLI lane; exact model release must be evaluated separately. | GH-212 / [`AGENTS.md`](AGENTS.md) |
| Antigravity (`agy`) | Cost-blind cross-model builder/reviewer lane | Run sandbox-off; an empty exit-0 response is a known failure mode and its print mode is cost-blind. | GH-178 / [`AGENTS.md`](AGENTS.md) |

## 2. Evaluated compatibility matrix

| Harness | Model / route evaluated | Type | Safe role | Grade | Required flags / limits | Evidence |
|---|---|:---:|---|:---:|---|---|
| DeepSeek Harness (`dsh`) | `openrouter/deepseek/deepseek-v4-pro` | Cloud | Autonomous Headless Builder & Task Solver | **A** | `DSH_PERMISSION_MODE=danger-full-access node .../apps/cli/lib/bin.js --profile headless --patch <overlay.cordis.yml> "<task>"`. Evaluated across 4 real repository bugs in isolated full clone. | [GH-148 umbrella tracking](https://github.com/HiQS-Suite/XYZ-forge/issues/148); [PR #150](https://github.com/HiQS-Suite/XYZ-forge/pull/150), [PR #157](https://github.com/HiQS-Suite/XYZ-forge/pull/157). Successfully resolved GH-142 (`compile_issue.py` missing import and error exit code propagation), GH-68 (`HARNESS-MODELS-REGISTRY.md` Table 1 schema alignment), GH-65 (`test/` portable 3-tier artifact hashing), and GH-156 (turn shims usage `--help`/`-h` flags across all 7 shims) with zero human intervention and 15–40s wall-clock latency per task. |
| Command Code | `Qwen/Qwen3.8-Max` | Cloud | Builder & Formal Code Reviewer (`/review-xyz`) | **A-** | `cmd -p --tools-all --yolo -t` for builder runs; `python3 utils/py/review_xyz.py --model Qwen/Qwen3.8-Max` for code review in throwaway worktree isolation. | [GH-18 capture](PROJECT/1-INBOX/GH-18-COMMANDCODE-EVAL.md); [PR #19](https://github.com/HiQS-Suite/XYZ-forge/pull/19), [#20](https://github.com/HiQS-Suite/XYZ-forge/pull/20), [#21](https://github.com/HiQS-Suite/XYZ-forge/pull/21); GH-132 dogfood review of `/review-xyz` engine identifying 5 actionable edge-case improvements with 0 hallucinated findings. |
| Command Code | `qwen/qwen3.7-flash` | Cloud | Builder and advisory review | **B** | Four recorded evaluations: a ~23 s SOP review plus three autonomous builder runs. The builder run-count threshold is met, but retain B pending final PR integration: AEGIS PR #61 and rebalanceOS PR #21 are open, and the rebalanceOS run needed supervisor remediation of three subtle defects. | [GH-18 capture](PROJECT/1-INBOX/GH-18-COMMANDCODE-EVAL.md); [AEGIS #58](https://github.com/HiQS-Suite/AEGIS-Sleuth-Slackbot/issues/58#issuecomment-5310915230) (7 files; 1,940 tests and CI reported green); [AEGIS #60](https://github.com/HiQS-Suite/AEGIS-Sleuth-Slackbot/issues/60#issuecomment-5311414037) ([PR #61](https://github.com/HiQS-Suite/AEGIS-Sleuth-Slackbot/pull/61), open); [rebalanceOS #16](https://github.com/HiQS-Suite/rebalanceOS/issues/16#issuecomment-5311691591) ([PR #21](https://github.com/HiQS-Suite/rebalanceOS/pull/21), open) |
| Command Code | `meta/muse-spark-1.2-contributor` | Cloud | Bounded builder and review turn | **B** | Use only through `commandcode-turn.sh` with its Python `rtl` containment, durable log, timeout, and worktree isolation. Require Codex-owned completion and final QA; do not use unattended for safety-critical changes. | [#41](https://github.com/HiQS-Suite/XYZ-forge/issues/41) (two runs plus live relay); [#42](https://github.com/HiQS-Suite/XYZ-forge/issues/42); [PR #44](https://github.com/HiQS-Suite/XYZ-forge/pull/44), open. |
| Command Code | `laguna-s-2.1-free` | Cloud | None pending a successful bounded evaluation | **N/A** | One worktree-isolated, review-only relay against #48/#49 reached a 300 s cap with zero usable output and `timeout-idle-no-progress`. The free tier is not evidence of a safe unattended lane; retry only under an explicit cap with retained output. | [Command Code pricing](https://commandcode.ai/docs/resources/pricing-limits#laguna-s-2.1-free); [#48](https://github.com/HiQS-Suite/XYZ-forge/issues/48); [#49](https://github.com/HiQS-Suite/XYZ-forge/issues/49); [PR #44](https://github.com/HiQS-Suite/XYZ-forge/pull/44). |
| OpenRouter / Aider | `openrouter/stealth/ox-alpha` | Cloud | Adversarial Code Review & Technical Audit (`/review-xyz`) | **A-** | Direct `/review-xyz --model stealth/ox-alpha` or `AIDER_AGENT=aider ALLOW_PATHS="" RELAY_WORKTREE_ISOLATION=1 RELAY_TURN_TIMEOUT_S=900`. High-rigor adversarial reasoning; budget 300–600s for large multi-file diffs. Five clean evaluations. | [rebalanceOS #107-#110](https://github.com/HiQS-Suite/rebalanceOS/tree/fix/gh107-110-consolidated-fixes) (v0.75.3, `gh107-110-review.md`, Approved); [rebalanceOS #103](https://github.com/HiQS-Suite/rebalanceOS/issues/103) (`gh103-doctor-critical-path-audit.md`, Approved); [XYZ-forge #119](https://github.com/HiQS-Suite/XYZ-forge/pull/119) (`gh119-linux-evidence-qa.md`, 10 detailed findings R-1..R-10 on `repro.sh`); [XYZ-forge #124](https://github.com/HiQS-Suite/XYZ-forge/issues/124) (`gh124-closeout-auto-pr-review.md`, agent2agent #658731, `gh124-closeout-implementation-qa.md`, Approved); [PR #133 review](https://github.com/HiQS-Suite/XYZ-forge/pull/133) (uncovered 2 Blockers B1/B2 and 8 Nits on `/review-xyz` engine, all verified and resolved). |
| Aider + OpenRouter | `openrouter/z-ai/glm-5.2` | Cloud | Builder only | **B** | Force `AIDER_FLAGS=--edit-format diff`; Aider reviewer turns can produce a review without persisting it, so route reviews to another harness. | Legacy [#118](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/118), [#251](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/251) |
| Aider + OpenRouter | `openrouter/qwen/qwen3.8-max` | Cloud | Advisory review **under supervision only** — never unattended; builder untested on this exact route | **C** | **The model's review content was the strongest recorded this day; the Aider reviewer SEAM is what fails.** Turn 1 landed a correct, fully-cited 7-blocker review with zero false positives. Turn 2 on the same thread produced no findings at all — the model entered a meta-loop about its own output format (whether to edit the `NEXT:` line, how to nest triple-backtick fences when echoing a file containing them) — and `aider-turn.sh`'s GH-251 salvage then appended ~1,200 lines of raw chain-of-thought into the relay file as if it were review content. Budget a human to read and truncate after **every** turn. The shim's qwen brevity instruction (`aider-turn.sh:145-147`, "under 50 words") does not hold on review-only turns. **SECOND USAGE 2026-08-20 (GH-111 + GH-108 code QA) — same split, sharper.** One `--review-once` turn against a 1,944-line diff: 13m 44s wall clock, verdict *Changes requested*, 0 Blockers, 2 `[Should]`, 3 `[Nit]`, 16 `[Pass]` each carrying a file/symbol citation, plus an honest `swept file: yes`. **Every finding was reproduced by the operator before acceptance and every one held** — two real regex false positives that refused a correctly scored entry, one under-graded correctness gap (baseline provenance was mutable; upgraded to Should and shipped as migration 005), one cosmetic bug. Zero hallucinated findings. **The seam failed the same way again:** the model did not append to the relay file; GH-251 salvage recovered the review from the transcript. New datum — the salvage output was **usable this time** (~1,200 lines of thinking with a correctly graded review at the end), so the salvage is not purely a noise amplifier; but 1 of 3 review turns has now landed natively, which is why this stays **C** and not a promotion. | [#111](https://github.com/HiQS-Suite/XYZ-forge/issues/111), [#108](https://github.com/HiQS-Suite/XYZ-forge/issues/108); relays `relay-system/2026-08-20/gh111-dialed-in-qa.md` (usage 1) and `relay-system/2026-08-20/gh111-gh108-qa.md` (usage 2, with the operator's finding-by-finding adjudication) |
| Aider + direct Alibaba MaaS | `qwen3.8-max-preview` | Cloud | Builder only | **B** | Force `AIDER_FLAGS=--edit-format diff`; 900 s was borderline on large-context turns, and multi-file whole-format turns are unsafe. | Legacy [#278](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/278), [#280](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/280) |
| Aider + OpenRouter | `openrouter/anthropic/claude-sonnet-5` | Cloud | Builder only | **B** | The historical model string was unlisted in Aider and auto-selected `whole`; explicitly force `diff` until re-evaluated against the current catalog/version. | Legacy [#280](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/280) |
| Aider + OpenRouter | `nvidia/nemotron-3-ultra` / historical “Nemotron Ultra 3” | Cloud | None recommended | **N/A** | Needs explicit edit format if retried; the recorded reviewer trial did not engage meaningfully, not a builder qualification. | Legacy [#118](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/118), [#119](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/119) |
| Pi | OpenRouter `openai/gpt-mini-latest`; direct Alibaba `qwen3.8-max-preview` | Multi-provider | Builder only | **B** | Set `PI_MODEL` explicitly; Python-default routing was proven, but Pi reviewer support remains rejected/unqualified. | Legacy [#295](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/295), [#414](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/414), [#451](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/451) |
| ATE variation runner + Aider | LM Studio / OpenAI-compatible local endpoint | Local | Variation-test harness, not a production builder | **B** | Opt-in endpoint seam; the runner was Aider-specific and its generalization remained open. Do not read the variation count as a model-quality grade. | Legacy [PR #195](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/195), [#191](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/191) |
| ATE variation runner (`run_variations.py`) | `google/gemma-4-31b-qat` (LM Studio) | Local | Automated test triage classifier only | **B** | Dedicated to structured test variation triage in `run_variations.py`; not a builder or relay turn-taker. | `TESTS-RESULTS/2026-08-20+GH-94/` (438 runs across 3 hours with 0 schema failures); Section 3.2. |
| SmallCode + LM Studio | `qwen/qwen2.5-coder-32b` | Local | Experiment only | **C** | Not safe unattended: repeated successful `tick claim` calls and repeated file reads loop until timeout. | Legacy [#522](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/522) |
| Command Code | `zai-org/GLM-5.3` (GLM 5.3 High) | Cloud | Autonomous Marathon Driver, Builder, and PR Orchestration | **A-** | `cmd -p --tools-all --yolo -t` with isolated workspace clones; verified across two multi-phase marathons (5 phases total). Zero test regressions; clean PRs, branch push verification, and workspace teardown. | [rebalanceOS PR #117](https://github.com/HiQS-Suite/rebalanceOS/pull/117) (Build 0.76.0, 2/2 phases approved, 2,018 tests passed); [rebalanceOS PR #118](https://github.com/HiQS-Suite/rebalanceOS/pull/118) (Build 0.77.0, 3/3 phases approved, 2,026 tests passed) |
| Command Code | `deepseek/deepseek-v4-pro`, `x-ai/grok-4.6`, `moonshotai/kimi-k3`, `minimaxai/minimax-m3` | Cloud | None | **N/A** | Catalog candidates only; no recorded isolated evaluation. | [GH-18](https://github.com/HiQS-Suite/XYZ-forge/issues/18) |

### Frontier Chinese Lab Models Catalog (Command Code Native)

All canonical IDs are exact for use with `cmd -p "<prompt>" -m <id> --tools-all --yolo -t`.

| Lab / Family | Exact Model ID | Context | Reasoning Effort | Pricing ($/1M in / out) | Cache Read ($/1M) | Best For |
|:---|:---|:---:|:---:|:---:|:---:|:---|
| **DeepSeek** | `deepseek/deepseek-v4-pro` | **1,000,000 (1M)** | `high`, `max` | **$0.435 / $0.87** | $0.0036 | Hybrid-attention long-context reasoning |
| **DeepSeek** | `deepseek/deepseek-v4-flash` | **1,000,000 (1M)** | `high`, `max` | **$0.14 / $0.28** | $0.0028 | Ultra-fast hybrid-attention reasoning |
| **Qwen (Alibaba)** | `Qwen/Qwen3.8-Max` | **1,000,000 (1M)** | `low`, `medium`, `xhigh` | **$2.00 / $6.00** | $0.25 | Flagship autonomous coding & professional work |
| **Qwen (Alibaba)** | `Qwen/Qwen3.7-Max` | **1,000,000 (1M)** | — | **$2.50 / $7.50** | $0.50 | Frontier coding & long-horizon agent execution |
| **Qwen (Alibaba)** | `Qwen/Qwen3.7-Plus` | **1,000,000 (1M)** | — | **$0.40 / $1.60** | $0.08 | Agentic coding & reasoning at lower cost |
| **Qwen (Alibaba)** | `Qwen/Qwen3.7-Flash` | **1,000,000 (1M)** | — | **$0.03 / $0.13** | $0.006 | Fast low-cost agentic coding & review audits |
| **Z.ai (Zhipu)** | `zai-org/GLM-5.3` | **1,000,000 (1M)** | `low`, `high`, `max` | **$1.40 / $4.40** | $0.26 | Brand-new flagship with cyber & thinking capabilities |
| **Z.ai (Zhipu)** | `zai-org/GLM-5.2` | **1,000,000 (1M)** | `high`, `max` | **$1.40 / $4.40** | $0.26 | 1M context long-horizon multi-file coding |
| **Z.ai (Zhipu)** | `zai-org/GLM-5.2-Fast` | **1,000,000 (1M)** | — | **$3.00 / $10.25** | $0.50 | High-throughput GLM-5.2 with 1M context |
| **Moonshot AI (Kimi)** | `moonshotai/Kimi-K3` | **1,000,000 (1M)** | — | **$3.00 / $15.00** | $0.30 | 1M context deep knowledge & whole-repo reasoning |
| **Moonshot AI (Kimi)** | `moonshotai/Kimi-K2.7-Code` | **256,000 (256K)** | — | **$0.95 / $4.00** | $0.19 | Long-horizon coding with vision |
| **Moonshot AI (Kimi)** | `moonshotai/Kimi-K2.7-Code-Highspeed` | **262,000 (262K)** | — | **$1.90 / $8.00** | $0.38 | High-speed coding with vision |
| **MiniMax** | `MiniMaxAI/MiniMax-M3` | **1,000,000 (1M)** | — | **$0.30 / $1.20** | $0.06 | Frontier coding, agents & native multimodality |
| **MiniMax** | `MiniMaxAI/MiniMax-M2.7` | — | — | **$0.30 / $1.20** | $0.06 | End-to-end software engineering agent |
| **Xiaomi (MiMo)** | `xiaomi/mimo-v2.5-pro` | **1,000,000 (1M)** | — | **$0.435 / $0.87** | $0.0036 | High-capability long-context agentic coding |
| **Xiaomi (MiMo)** | `xiaomi/mimo-v2.5` | **1,000,000 (1M)** | — | **$0.14 / $0.28** | $0.0028 | Efficient long-context agentic coding |
| **StepFun** | `stepfun/Step-3.7-Flash` | **256,000 (256K)** | — | **$0.20 / $1.15** | $0.04 | Multimodal sparse-MoE reasoning |
| **StepFun** | `stepfun/Step-3.5-Flash` | **1,000,000 (1M)** | — | **$0.10 / $0.30** | $0.02 | Fast sparse-MoE agentic reasoning |
| **Tencent (Hunyuan)** | `tencent/hy3-paid` | **262,000 (262K)** | — | **$0.14 / $0.58** | $0.035 | Sparse-MoE reasoning & agentic tool use |

### Aider-wide constraints

- The Aider turn-taker itself was live-proven as a contained OpenRouter builder lane, but its own
  history/chat files must be redirected outside the repository and it must use `--no-auto-commits`.
  See legacy [#77](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/77).
- For model IDs absent from Aider's model settings, `whole` format can silently discard a valid unified
  diff and leave zero-byte pre-created files. Treat `AIDER_FLAGS=--edit-format diff` as mandatory until
  an exact route earns separate evidence.
- The legacy OpenRouter/Aider reviewer seam was not reliable: it could retain a correct review in its
  transcript while failing to append it to the relay file. Aider is therefore listed as builder-only.
- **Re-confirmed 2026-08-20 (GH-111), with a second, worse failure shape.** The builder-only listing
  above is not stale advice — it was violated by choosing this lane for a review and the documented
  failure recurred on the second turn. Two lessons beyond the original finding:
  1. **The seam is intermittent, not uniformly broken.** Turn 1 appended a genuinely excellent review;
     turn 2 on the same thread appended nothing usable. One good reviewer turn is therefore *not*
     evidence the seam is fixed, and must not be cited to promote Aider out of builder-only.
  2. **GH-251 salvage amplifies a bad turn.** When the model produces reasoning instead of a review,
     the salvage path faithfully preserves that reasoning *as relay content* — here ~1,200 lines.
     The mechanism is correct (it exists to rescue reviews that don't land) but it cannot tell a
     rescued review from rescued noise. Anyone running an Aider review turn should expect to inspect
     and truncate the relay file afterwards, and containment (`ALLOW_PATHS=""`) is what keeps the
     damage confined to that one file — it held, and the reviewed artifact was never at risk.
- **Third review turn, 2026-08-20 (GH-111 + GH-108 code QA) — the split is now a stable pattern, not
  a one-off.** Across three recorded review turns on this route the model's CONTENT has been strong
  twice and useless once, while the DELIVERY has landed natively once out of three. Two further
  lessons:
  3. **Judge the route on content-quality and delivery separately, and grade on the worse one.** The
     second usage produced the most precisely cited review this repo has taken from any harness —
     every finding reproduced on first attempt, none hallucinated — and still did not append to the
     relay file. A reviewer that is right and cannot deliver is a reviewer you must supervise.
  4. **`--review-once` is the right driver mode for this lane.** It classifies a non-approval
     handback as exit 5 (a successful single review) rather than letting the multi-round loop run on
     a seam that may not append. Combined with `ALLOW_PATHS=""`, one turn is inspected and the lane
     closes; the failure modes above cannot compound across rounds.
- **Check this section before choosing a review lane.** The builder-only constraint predates and
  predicted the GH-111 failure; consulting it first would have routed that review to Codex.

## 3. Harness operational profile

| Harness | Execution engine | Billing / observability | Headless contract | Notes |
|---|---|---|---|---|
| Claude Code | Native Anthropic CLI | API-metered; structured usage available | `claude -p` | Orchestrator/reviewer policy lane; explicit-cost builder only. |
| Codex CLI | Native OpenAI CLI | Subscription default; token capture historically partial | `codex exec` | Builder/reviewer policy lane. |
| Antigravity | Antigravity CLI | Subscription/cost-blind print mode | `agy -p` | Sandbox-off; empty exit-0 must be detected. |
| Command Code | Node.js / Langbase | Subscription and/or credits | `cmd -p` or `cmd --print --model <id>` | The supported relay route is `commandcode-turn.sh`; current evidence remains pending PR integration. |
| Aider | Python / LiteLLM | API-metered; no reliable stdout usage record in `--message` mode | `aider --message` | Builder-only, with model-specific edit-format constraints. |
| Pi | Node.js multi-provider agent | JSON mode exposes usage/cost events | `pi -p --mode json` | Builder-only evidence; no silent default model. |
| SmallCode | Node.js / local LM Studio | Local inference | `smallcode.js -P` | Experiment only; repeat-loop failure. |
| ATE | Python variation runner | Depends on configured endpoint | `run_variations.py` | Test infrastructure, now instrumented with structured telemetry (GH-94). |

### 3.1 Programmatic Tool Calling & Code-Mode Architecture (GH-94 / GH-101)

- **The "26 Tool" Hypothesis:** Based on PwC's research ("The Bitter Lesson of Tool Calling"), when agent systems scale beyond $\approx 25$ distinct tools or require multi-step chained operations, programmatic script-mode execution (generating and running Python scripts via `utils/py/script_runner.py`) provides an architectural alternative to verbose JSON schema context flooding.
- **Production Qualification & Empirical Evidence (GH-101):** Programmatic tool mode (`--tool-mode programmatic`) is fully qualified and supported across both `consult.py` and `relay_drive.py` (defaulting off to `standard`). Verified via:
  1. *Test 1:* Architectural review and fail-closed threat-model scoping (PRD signed off).
  2. *Test 2:* `consult.py` dogfooding with throwaway worktree isolation, pre-created `.relay-scratch/`, and a 1,935-trial paired density benchmark committed in `TESTS-RESULTS/2026-08-20+GH-101/`.
  3. *Test 3:* Relay-drive integration with fail-closed sandbox checks (`sandbox-exec`/`bwrap`), PGID process-group lifecycle cleanup, and synthetic verification in `test/synthetic/gh101-relay-programmatic-stress.sh` (10/10 synthetic tests PASS).
- **Containment Invariant:** Programmatic execution in `utils/py/script_runner.py` requires process-group isolation (`setsid` + `SIGTERM`/`SIGKILL` cleanup), AST serialization normalization, and OS-level write sandboxing (`sandbox-exec`/`bwrap`) when `--containment-root` is provided (verified by `test/synthetic/gh94-containment-invariants.sh` and `test/synthetic/gh101-relay-programmatic-stress.sh`).

### 3.2 Automated Triage Evaluation: Local Gemma 4 in ATE (GH-94 / GH-141)

Local Gemma 4 (`google/gemma-4-31b-qat` via LM Studio) was evaluated as the automated triage judge in `utils/ate/scripts/run_variations.py` across two multi-hour campaigns: the 438-iteration GH-94 campaign and the 143-iteration GH-141 1-hour soak campaign (`TESTS-RESULTS/2026-08-22+GH-141/`). It performed reliably with zero JSON schema failures and 100% parseable structured triage classifications. Because `run_variations.py` is an experimental testing script rather than a core XYZ runtime shim, this evaluation qualifies Gemma 4 specifically for offline test triage ($0 operational token cost) rather than production coding or relay turn execution.

### 3.3 DeepSeek Harness (dsh) & DeepSeek V4 Pro (GH-148 / GH-156)

DeepSeek Harness (`dsh`) driving OpenRouter `deepseek/deepseek-v4-pro` in headless profile mode (`--profile headless --patch <overlay.cordis.yml>`) was evaluated across 4 real repository issues in isolated full-clone environments (GH-564):
1. **GH-142:** Fixed `compile_issue.py` missing `import sys` and error exit code propagation (11/11 tests PASS).
2. **GH-68:** Realigned `HARNESS-MODELS-REGISTRY.md` Table 1 schema.
3. **GH-65:** Modernized `test/` artifacts with portable 3-tier SHA-256 hashing.
4. **GH-156:** Added clean `--help` / `-h` top-level usage handling across all 7 Python turn twins (`utils/py/agy-turn.py`, `codex-turn.py`, `claude-turn.py`, `aider-turn.py`, `pi-turn.py`, `commandcode-turn.py`, `deepseek-turn.py`) in ~110s with 14/14 regression tests passing.

DeepSeek V4 Pro demonstrated 100% success across all 4 tasks with zero human intervention, 15–40s wall clock latency on focused edits, and clean minimal diffs. Promoted to **Grade A** (Production-Ready Autonomous Headless Builder).

## 4. Promotion and re-evaluation rules

1. Create a dedicated tracking issue and isolated full-clone evaluation per the GH-17 SOP.
2. Record the exact harness version, provider endpoint, model slug, flags, task shape, run artifact,
   and gate result. A model rename or provider change starts a new evidence trail.
3. Promote to **A** only after three reviewable, end-to-end successes meet the rubric above. Open PRs,
   self-reported results without retained evidence, or a policy designation are not an A promotion.
4. Any B/C entry must name the mechanism and its safe operating limit. A regression, provider change,
   or harness upgrade reopens the evaluation.

## 5. Running changelog

| Date | Target / subject | Action | Evidence-based result |
|---|---|---|---|
| **2026-08-22** | Aider + OpenRouter + `stealth/ox-alpha`, **reviewer role** | Added **C** | First use of this route, driven via `relay-drive.sh --review-once`, `ALLOW_PATHS=""`, worktree isolation ON, against `skills/ci-doctor/benchmark-runners.sh` (GH-161, PR #162). **R1: Blocked, correctly.** The turn-taker's `--artifact-file` seeding hadn't landed in the reviewer's context yet; the model declared `swept file: no` and refused to fabricate `[Pass]` findings against code it hadn't read — the honest failure mode, not a hallucination. **R2 (re-run after the artifact was seeded): the strongest first-attempt content seen from a new route.** Full 162-line static read, `swept file: yes`, verdict *Changes requested* with 2 `[Blocker]`, 4 `[Should]`, 5 `[Nit]`, 5 cited `[Pass]`. **Every finding verified true** against the real file before the operator acted: a `sed`-vs-literal mismatch that could silently commit a byte-identical no-op benchmark (undermining the tool's entire premise — GH-161's own header claims this exact failure mode impossible), and an unfiltered `gh run list --branch` pickup that could grab a wrong (push-triggered fast-lane, or cancelled) run instead of the dispatched one. Both confirmed by direct code inspection plus a targeted smoke test reproducing the reviewer's exact repro case (`runs-on: [self-hosted, linux]`) before fixing. Zero hallucinated findings; zero uncited Passes. **Delivery — mixed, root cause identified, not a model defect.** R1→R2 required a manual re-seed (environment/tooling gap). The R3 re-sweep (verifying the Producer's fixes) **timed out at the 900s wall-clock cap** (`aider-turn` exit 7) — but the turn's own log shows the model generated a full, well-formed second review in one clean LLM call (8.4k sent / 29k received, no retries) before the kill. Root cause: `aider-turn` ran `openrouter/stealth/ox-alpha` under Aider's default `whole` edit format (not in Aider's `model-settings.yml`), and the model wrote its response in diff-style (`+`-prefixed) lines, which `whole` format cannot parse as a file replacement — no error, no reflection, the turn simply idled with a correct response already sitting unused in the log until the wall-clock kill. This is the pre-existing, already-documented GH-118 edit-format quirk (see `skills/open-router/SKILL.md` and `relay-automation/README.md`, now updated with this model), not a reasoning or reliability failure of the model itself — the fix is `AIDER_FLAGS=--edit-format diff`, applied proactively for any new/unlisted OpenRouter model going forward. **Net: content quality is the strongest first-attempt showing of any route in this registry (2 real Blockers, zero hallucination, zero uncited Passes, twice); the one incomplete turn was a known, fixed harness-configuration gap, not the model.** Fixes verified independently (`bash -n`, `shellcheck -S error`, targeted smoke tests) rather than by the stalled R3 turn; a re-run with the corrected flag is queued to get a real completed R3 verdict. [#161](https://github.com/HiQS-Suite/XYZ-forge/issues/161), [#162](https://github.com/HiQS-Suite/XYZ-forge/pull/162); relay `relay-system/2026-08-22/ci-doctor-qa-gh-161-pr-162.md`. |
| **2026-08-22** | DeepSeek Harness (`dsh`) + `deepseek/deepseek-v4-pro` | Promoted to **Production-Ready (A)** | Evaluated across 4 real repository issues in isolated full clones: GH-142 (exit code propagation), GH-68 (markdown schema alignment), GH-65 (portable artifact hashing), and GH-156 (turn shims `--help`/`-h` usage across all 7 shims). Zero human intervention; clean scoped diffs; verified against 11/11 `gh148-deepseek-turn` and 14/14 `gh156-turn-shims-help` regression suites; PR #150 merged into `development`, PR #157 opened. |
| **2026-08-22** | ATE 1-Hour Fuzz Campaign (GH-141 soak) | Policy & benchmark baseline recorded | Executed 60.0-minute automated testing campaign across all 7 turn shims with local Gemma 4 31B triage on LM Studio. Completed 143 full execution-and-classification cycles with zero crashes, hangs, or memory leaks; telemetry receipts archived to `TESTS-RESULTS/2026-08-22+GH-141/error_log.jsonl`. |
| **2026-08-20** | Aider + OpenRouter + Qwen 3.8-Max, **reviewer role — 2nd reported usage** | **C confirmed, not promoted** | Second review turn on this route, against CODE this time (the 1,944-line GH-111 + GH-108 diff) rather than a plan doc. `--review-once`, `ALLOW_PATHS=""`, worktree isolation ON, 13m 44s. **Content: the strongest signal-to-noise yet.** Verdict *Changes requested* with 0 Blockers, 2 `[Should]`, 3 `[Nit]`, 16 cited `[Pass]`, and a declared `swept file: yes`. The operator reproduced every finding before acting: both `[Should]`s were live regex false positives that refused a correctly scored ROADMAP entry, and one `[Nit]` was under-graded — `baseline_source` was mutable, letting a `backfilled` baseline be quietly relabelled `observed`, which is a correctness gap in the metric and shipped as migration 005. **Zero hallucinated findings; zero uncited Passes.** **Delivery: failed identically to usage 1** — no relay-file append, GH-251 salvage recovered the review from the transcript. The salvage output was *usable* this time, which is new, but native delivery now stands at 1 of 3 turns. **Net: the grade holds at C for exactly the reason the registry already states — one good turn is not evidence the seam is fixed, and two good turns out of three still means a human reads every one.** [#111](https://github.com/HiQS-Suite/XYZ-forge/issues/111), [#108](https://github.com/HiQS-Suite/XYZ-forge/issues/108); relay `relay-system/2026-08-20/gh111-gh108-qa.md`. |
| **2026-08-20** | Programmatic Tool Execution (`script_runner.py`, GH-101) | Promoted to **Production-Ready (A)** | Completed 3-stage qualification ladder: Test 1 architectural fail-closed scoping; Test 2 `consult.py` throwaway worktree isolation with 1,935-trial paired density benchmark (`TESTS-RESULTS/2026-08-20+GH-101/`); Test 3 `relay_drive.py` / `relay-turn-lib.sh` integration with fail-closed sandbox verification, `.relay-scratch/` isolation, PGID cleanup, and synthetic stress verification (`test/synthetic/gh101-relay-programmatic-stress.sh`, 10/10 synthetic fuzz pass). |
| **2026-08-20** | Aider + OpenRouter + Qwen 3.8-Max, **reviewer role** | Added **C** | Both halves recorded deliberately, because they point opposite ways. **Positive — the review content was excellent, arguably the best of the day across three harnesses.** One turn against a plan doc produced seven blocking findings, each citing file and line, and **every one verified true against the live schema before acceptance**: SQLite cannot ALTER a CHECK constraint in place (the migration as drafted was unimplementable); an existing `UNIQUE (release_id, issue_ref_id)` made the drafted state machine impossible; an entire table the plan ignored (`manifest_state_events`, with its own old-vocabulary CHECKs, append-only triggers, and a `NOT NULL` reason column that the proposed `manifest ship` verb had no value for); and a backfill that named `releases.created_at`, **a column that does not exist**. It also returned explicit verdicts on all five of the plan's open questions. Zero false positives. **Negative — the seam failed on the very next turn, twice.** The model produced no findings, instead looping on its own output format; GH-251 salvage then appended ~1,200 lines of chain-of-thought into the relay file as review content. `ALLOW_PATHS=""` containment held and the reviewed artifact was untouched. Lane abandoned by operator instruction after one retry; verification rerouted. **Net: use this route for advisory review only with a human reading every turn — the intelligence is real, the delivery is not.** [#111](https://github.com/HiQS-Suite/XYZ-forge/issues/111); relay `relay-system/2026-08-20/gh111-dialed-in-qa.md`. |
| **2026-08-20** | Programmatic Tool Calling (GH-94) | Policy & benchmark baseline recorded | Integrated `utils/py/script_runner.py` with PGID timeout containment and macOS seatbelt sandboxing; instrumented `utils/ate/scripts/run_variations.py` with structured telemetry (schema 1.0); completed 438-iteration harness stability campaign under local Gemma triage (retained in `TESTS-RESULTS/2026-08-20+GH-94/`); verified synthetic suites `gh94-script-serialization.sh` and `gh94-containment-invariants.sh` (7/7 PASS). |
| **2026-08-18** | Command Code + Laguna S 2.1 Free | Added **N/A** | The provider lists this route as free while capacity lasts. One real worktree-isolated review-only relay had no output or worktree progress and was killed at its 300 s cap (`timeout-idle-no-progress`); containment handed the token back. This is insufficient evidence for C but does not qualify any safe relay role. [#48](https://github.com/HiQS-Suite/XYZ-forge/issues/48), [#49](https://github.com/HiQS-Suite/XYZ-forge/issues/49), [PR #44](https://github.com/HiQS-Suite/XYZ-forge/pull/44). |
| **2026-08-18** | Command Code + Muse Spark 1.2 Contributor | Added **B** | Two bounded build attempts and a real worktree-isolated relay review are recorded. The first build produced no code; the second produced the initial adapter but reached its turn cap. The live review found two real containment gaps, fixed by Codex with focused regressions; the full gate reached 215/216 before a separately repaired generated-dashboard drift. Keep the route B pending PR #44 review/integration and more independent successful runs. [#41](https://github.com/HiQS-Suite/XYZ-forge/issues/41), [#42](https://github.com/HiQS-Suite/XYZ-forge/issues/42), [PR #44](https://github.com/HiQS-Suite/XYZ-forge/pull/44). |
| **2026-08-16** | Registry audit | Refined | Reconciled the legacy Swarm checkout and both repositories’ issues/PR state. Split policy lanes from grades; Aider is builder-only with explicit-format constraints; Pi is builder-only; SmallCode remains C. |
| **2026-08-16** | Command Code + Qwen 3.8-Max | Regraded **A → B** | Three successful builds are documented, but PRs #19–#21 remain open; this does not yet satisfy the registry’s final-state/review evidence requirement. |
| **2026-08-16** | Command Code + Qwen 3.7-Flash | B retained; evidence expanded | The registry now records three autonomous builder runs plus the SOP review. AEGIS #58 reports a 7-file build with 1,940 tests and CI green; AEGIS #60 reports a 30+-file refactor with 1,915 Jest tests and 116 Node subtests green; rebalanceOS #16 reports lint, formatting, mypy, and test suites green after supervisor remediation of three subtle defects. The two linked PRs are open, so the route remains B pending final review/integration rather than A. [#58](https://github.com/HiQS-Suite/AEGIS-Sleuth-Slackbot/issues/58#issuecomment-5310915230), [#60](https://github.com/HiQS-Suite/AEGIS-Sleuth-Slackbot/issues/60#issuecomment-5311414037), [#16](https://github.com/HiQS-Suite/rebalanceOS/issues/16#issuecomment-5311691591) |
| **2026-07-23** | Aider + Qwen 3.8-Max | Conditional builder route recorded | Production-scale evidence attributed the major failure to Aider’s unlisted-model `whole` format; `--edit-format diff` restored substantive edits, while timeout sensitivity remained. [#280](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/280) |
| **2026-07-23–24** | Pi | Builder route recorded | Real isolated end-to-end turns were recorded via OpenRouter and direct Alibaba; later routing work did not qualify Pi as a reviewer. [#295](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/295), [#414](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/414) |
| **2026-08-12–13** | SmallCode + Qwen 2.5 Coder 32B | Retained **C** | Four-run experiment made a real fix but repeatedly entered tool-call/read loops; unattended use is unsafe. [#522](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/522) |

## 6. Resources

External tools useful when operating or debugging the harnesses above. Listed for reference — not
graded, not evaluated lanes; an entry here is a pointer, not an endorsement of unattended use.

- **[Agent-Devtools](https://github.com/Jacopos311/Agent-Devtools)** — local-first debugger for AI
  agents ("why did my agent behave this way?"): visual replay, behavior diff, and full visibility
  into prompts, context, memory, retrieval, and tool calls. Python/FastAPI/SQLite, open source,
  LangChain/LangGraph integration. Added 2026-08-20, untested against this repo's harnesses.
