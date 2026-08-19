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
| Claude Code | Orchestrator and final reviewer | Do not use as a default headless builder; an API-billed Claude builder is operator-selected only. | GH-221 / [`AGENTS.md`](AGENTS.md) |
| Codex CLI | Cost-blind default builder and reviewer | Use the subscription-authenticated CLI lane; exact model release must be evaluated separately. | GH-212 / [`AGENTS.md`](AGENTS.md) |
| Antigravity (`agy`) | Cost-blind cross-model builder/reviewer lane | Run sandbox-off; an empty exit-0 response is a known failure mode and its print mode is cost-blind. | GH-178 / [`AGENTS.md`](AGENTS.md) |

## 2. Evaluated compatibility matrix

| Harness | Model / route evaluated | Type | Safe role | Grade | Required flags / limits | Evidence |
|---|---|:---:|---|:---:|---|---|
| Command Code | `qwen/qwen3.8-max` | Cloud | Builder and advisory review | **B** | `cmd -p --tools-all --yolo -t`; promotion held until its three open PRs are independently reviewed/merged and qualifying evidence is retained. | [GH-18 capture](PROJECT/1-INBOX/GH-18-COMMANDCODE-EVAL.md); [PR #19](https://github.com/HiQS-Suite/XYZ-forge/pull/19), [#20](https://github.com/HiQS-Suite/XYZ-forge/pull/20), [#21](https://github.com/HiQS-Suite/XYZ-forge/pull/21) are open as of this review. |
| Command Code | `qwen/qwen3.7-flash` | Cloud | Builder and advisory review | **B** | Four recorded evaluations: a ~23 s SOP review plus three autonomous builder runs. The builder run-count threshold is met, but retain B pending final PR integration: AEGIS PR #61 and rebalanceOS PR #21 are open, and the rebalanceOS run needed supervisor remediation of three subtle defects. | [GH-18 capture](PROJECT/1-INBOX/GH-18-COMMANDCODE-EVAL.md); [AEGIS #58](https://github.com/HiQS-Suite/AEGIS-Sleuth-Slackbot/issues/58#issuecomment-5310915230) (7 files; 1,940 tests and CI reported green); [AEGIS #60](https://github.com/HiQS-Suite/AEGIS-Sleuth-Slackbot/issues/60#issuecomment-5311414037) ([PR #61](https://github.com/HiQS-Suite/AEGIS-Sleuth-Slackbot/pull/61), open); [rebalanceOS #16](https://github.com/HiQS-Suite/rebalanceOS/issues/16#issuecomment-5311691591) ([PR #21](https://github.com/HiQS-Suite/rebalanceOS/pull/21), open) |
| Command Code | `meta/muse-spark-1.2-contributor` | Cloud | Bounded builder and review turn | **B** | Use only through `commandcode-turn.sh` with its Python `rtl` containment, durable log, timeout, and worktree isolation. Require Codex-owned completion and final QA; do not use unattended for safety-critical changes. | [#41](https://github.com/HiQS-Suite/XYZ-forge/issues/41) (two runs plus live relay); [#42](https://github.com/HiQS-Suite/XYZ-forge/issues/42); [PR #44](https://github.com/HiQS-Suite/XYZ-forge/pull/44), open. |
| Command Code | `laguna-s-2.1-free` | Cloud | None pending a successful bounded evaluation | **N/A** | One worktree-isolated, review-only relay against #48/#49 reached a 300 s cap with zero usable output and `timeout-idle-no-progress`. The free tier is not evidence of a safe unattended lane; retry only under an explicit cap with retained output. | [Command Code pricing](https://commandcode.ai/docs/resources/pricing-limits#laguna-s-2.1-free); [#48](https://github.com/HiQS-Suite/XYZ-forge/issues/48); [#49](https://github.com/HiQS-Suite/XYZ-forge/issues/49); [PR #44](https://github.com/HiQS-Suite/XYZ-forge/pull/44). |
| Aider + OpenRouter | `openrouter/z-ai/glm-5.2` | Cloud | Builder only | **B** | Force `AIDER_FLAGS=--edit-format diff`; Aider reviewer turns can produce a review without persisting it, so route reviews to another harness. | Legacy [#118](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/118), [#251](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/251) |
| Aider + direct Alibaba MaaS | `qwen3.8-max-preview` | Cloud | Builder only | **B** | Force `AIDER_FLAGS=--edit-format diff`; 900 s was borderline on large-context turns, and multi-file whole-format turns are unsafe. | Legacy [#278](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/278), [#280](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/280) |
| Aider + OpenRouter | `openrouter/anthropic/claude-sonnet-5` | Cloud | Builder only | **B** | The historical model string was unlisted in Aider and auto-selected `whole`; explicitly force `diff` until re-evaluated against the current catalog/version. | Legacy [#280](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/280) |
| Aider + OpenRouter | `nvidia/nemotron-3-ultra` / historical “Nemotron Ultra 3” | Cloud | None recommended | **N/A** | Needs explicit edit format if retried; the recorded reviewer trial did not engage meaningfully, not a builder qualification. | Legacy [#118](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/118), [#119](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/119) |
| Pi | OpenRouter `openai/gpt-mini-latest`; direct Alibaba `qwen3.8-max-preview` | Multi-provider | Builder only | **B** | Set `PI_MODEL` explicitly; Python-default routing was proven, but Pi reviewer support remains rejected/unqualified. | Legacy [#295](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/295), [#414](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/414), [#451](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/451) |
| ATE variation runner + Aider | LM Studio / OpenAI-compatible local endpoint | Local | Variation-test harness, not a production builder | **B** | Opt-in endpoint seam; the runner was Aider-specific and its generalization remained open. Do not read the variation count as a model-quality grade. | Legacy [PR #195](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/195), [#191](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/191) |
| SmallCode + LM Studio | `qwen/qwen2.5-coder-32b` | Local | Experiment only | **C** | Not safe unattended: repeated successful `tick claim` calls and repeated file reads loop until timeout. | Legacy [#522](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/522) |
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
| ATE | Python variation runner | Depends on configured endpoint | `run_variations.py` | Test infrastructure, not an autonomous production lane. |

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
| **2026-08-18** | Command Code + Laguna S 2.1 Free | Added **N/A** | The provider lists this route as free while capacity lasts. One real worktree-isolated review-only relay had no output or worktree progress and was killed at its 300 s cap (`timeout-idle-no-progress`); containment handed the token back. This is insufficient evidence for C but does not qualify any safe relay role. [#48](https://github.com/HiQS-Suite/XYZ-forge/issues/48), [#49](https://github.com/HiQS-Suite/XYZ-forge/issues/49), [PR #44](https://github.com/HiQS-Suite/XYZ-forge/pull/44). |
| **2026-08-18** | Command Code + Muse Spark 1.2 Contributor | Added **B** | Two bounded build attempts and a real worktree-isolated relay review are recorded. The first build produced no code; the second produced the initial adapter but reached its turn cap. The live review found two real containment gaps, fixed by Codex with focused regressions; the full gate reached 215/216 before a separately repaired generated-dashboard drift. Keep the route B pending PR #44 review/integration and more independent successful runs. [#41](https://github.com/HiQS-Suite/XYZ-forge/issues/41), [#42](https://github.com/HiQS-Suite/XYZ-forge/issues/42), [PR #44](https://github.com/HiQS-Suite/XYZ-forge/pull/44). |
| **2026-08-16** | Registry audit | Refined | Reconciled the legacy Swarm checkout and both repositories’ issues/PR state. Split policy lanes from grades; Aider is builder-only with explicit-format constraints; Pi is builder-only; SmallCode remains C. |
| **2026-08-16** | Command Code + Qwen 3.8-Max | Regraded **A → B** | Three successful builds are documented, but PRs #19–#21 remain open; this does not yet satisfy the registry’s final-state/review evidence requirement. |
| **2026-08-16** | Command Code + Qwen 3.7-Flash | B retained; evidence expanded | The registry now records three autonomous builder runs plus the SOP review. AEGIS #58 reports a 7-file build with 1,940 tests and CI green; AEGIS #60 reports a 30+-file refactor with 1,915 Jest tests and 116 Node subtests green; rebalanceOS #16 reports lint, formatting, mypy, and test suites green after supervisor remediation of three subtle defects. The two linked PRs are open, so the route remains B pending final review/integration rather than A. [#58](https://github.com/HiQS-Suite/AEGIS-Sleuth-Slackbot/issues/58#issuecomment-5310915230), [#60](https://github.com/HiQS-Suite/AEGIS-Sleuth-Slackbot/issues/60#issuecomment-5311414037), [#16](https://github.com/HiQS-Suite/rebalanceOS/issues/16#issuecomment-5311691591) |
| **2026-07-23** | Aider + Qwen 3.8-Max | Conditional builder route recorded | Production-scale evidence attributed the major failure to Aider’s unlisted-model `whole` format; `--edit-format diff` restored substantive edits, while timeout sensitivity remained. [#280](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/280) |
| **2026-07-23–24** | Pi | Builder route recorded | Real isolated end-to-end turns were recorded via OpenRouter and direct Alibaba; later routing work did not qualify Pi as a reviewer. [#295](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/295), [#414](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/414) |
| **2026-08-12–13** | SmallCode + Qwen 2.5 Coder 32B | Retained **C** | Four-run experiment made a real fix but repeatedly entered tool-call/read loops; unattended use is unsafe. [#522](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/522) |
