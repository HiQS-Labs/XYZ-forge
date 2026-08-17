# HARNESS-MODELS-REGISTRY.md

Canonical compatibility ledger for AI agent harnesses and supported frontier/local models. Governed by the Harness Evaluation SOP ([`PROJECT/1-INBOX/GH-17-SOP-HARNESS-MODEL-EVAL.md`](PROJECT/1-INBOX/GH-17-SOP-HARNESS-MODEL-EVAL.md)).

## Grading Rubric

| Grade | Classification | Criteria |
|:---:|:---|:---|
| **A** | **Production-Ready** | $\ge 3$ verified end-to-end runs; clean diffs, zero tool loops, passes full `./validate.sh` gate. |
| **B** | **Functional w/ Caveats** | Works reliably only with forced flags (e.g., `--edit-format diff`), elevated timeouts, or supervisor oversight. |
| **C** | **Problematic** | Known severe failure modes (infinite tool loops, silent 0-byte drops, unhandled rate limits). |
| **N/A** | **Untested / Queued** | Supported by harness catalog; queued for isolated evaluation. |

---

## 1. Harness & Model Compatibility Matrix

| Harness | Model / Slug | Type | Role | Grade | Required Flags / Caveats | Provenance / Evidence |
|:---|:---|:---:|:---:|:---:|:---|:---|
| **Claude Code** | `claude-sonnet-5` | Frontier Cloud | Orchestrator / Reviewer | **A** | Default orchestrator & reviewer lane. | Standing default (GH-221) |
| **Claude Code** | `claude-opus-5` | Frontier Cloud | Kernel Reasoning | **A** | Used for high-risk kernel fencing & consensus. | Canonical |
| **Claude Code** | `claude-haiku-4.5` | Frontier Cloud | Fast Triage | **A** | Fast doc hygiene & triage. | Canonical |
| **Codex CLI** | `gpt-5.3-codex` / `gpt-5.4` | Frontier Cloud | Default Builder / Reviewer | **A** | Cost-blind subscription default builder. | Standing default (GH-212) |
| **Antigravity** | `gemini-3.7-flash` | Frontier Cloud | Default Builder / Reviewer | **A** | Run sandbox-OFF (`dangerouslyDisableSandbox`). | Standing default (GH-178) |
| **Antigravity** | `gemini-3.5-flash` | Frontier Cloud | Subagent Worker | **A** | Fast, high-throughput subagent tasks. | Standing default |
| **Command Code** | `qwen/qwen3.8-max` | Frontier / Open | Builder / Refactorer | **A** | 3/3 autonomous passes on refactor, concurrency, & kernel atomic append. | PR #19, PR #20, PR #21 (#18) |
| **Command Code** | `qwen/qwen3.7-flash` | Open Weight Cloud | Reviewer / Agentic | **A** | Fast (~23s), sharp repo rail & doc awareness. | Issue #18 review benchmark |
| **Aider** | `openrouter/anthropic/claude-sonnet-5` | Frontier Cloud | Builder Lane | **A-** | OpenAI standard build lane; requires API key. | GH-77 |
| **Aider** | `qwen/qwen3.8-max-preview` | Open Weight Cloud | Builder Lane | **B** | Fails under default `whole` edit format (6/7); MUST force `AIDER_FLAGS=--edit-format diff`. | GH-280 |
| **Aider** | `z-ai/glm-5.2` | Open Weight Cloud | Builder Lane | **B** | Must force `AIDER_FLAGS=--edit-format diff`. | GH-118, GH-77 |
| **Aider** | `nvidia/nemotron-3-ultra` | Open Weight Cloud | Builder Lane | **B-** | High latency; requires diff edit format. | GH-118 |
| **Pi** | `qwen` / `claude` / `openai` | Multi-Provider | Experimental Builder | **B** | Requires Python dispatch & alias mapping. | GH-451, GH-414 |
| **ATE Runner** | `google/gemma-4-31b` (Local LM Studio) | Local Open | Variation Worker | **B** | Local variation worker; needs periodic Claude supervisor check-in to prevent drift. | `utils/ate/` (PR #195) |
| **SmallCode** | `qwen/qwen2.5-coder-32b` (Local LM Studio) | Local Open | Autonomous Builder | **C** | Implements edits but wedges in recursive tool-call repetition loops (`tick claim`). | GH-522, GH-523 |
| **Command Code** | `deepseek/deepseek-v4-pro` | Frontier / Open | Builder | **N/A** | Queued for testing. | Catalog |
| **Command Code** | `x-ai/grok-4.6` | Frontier Cloud | Builder / Reasoning | **N/A** | Queued for testing. | Catalog |
| **Command Code** | `moonshotai/kimi-k3` | Frontier / Open | 1M Context Builder | **N/A** | Queued for testing. | Catalog |
| **Command Code** | `minimaxai/minimax-m3` | Frontier / Open | Fullstack Builder | **N/A** | Queued for testing. | Catalog |

---

## 2. Harness Operational Profile

| Harness | Execution Engine | Primary Billing Mode | Headless CLI Contract | Autonomy / Bypass Flag |
|:---|:---|:---|:---|:---|
| **Claude Code** | Native Anthropic CLI | API Metered | `claude -p` / hooks | `-p` |
| **Codex CLI** | Native OpenAI CLI | Subscription (Cost-blind) | `codex exec` | `-s workspace-write` |
| **Antigravity** | Google Antigravity CLI | Subscription (Cost-blind) | `agy -p` | Sandbox-OFF |
| **Command Code** | Node.js / Langbase Engine | Subscription + Credits | `cmd -p` | `--tools-all --yolo -t` |
| **Aider** | Python CLI / LiteLLM | OpenRouter API / Metered | `aider --message` | `--yes-always --no-auto-commits` |
| **SmallCode** | Node.js / OpenAI SDK | Local Inference (LM Studio) | `smallcode.js -P` | `--non-interactive` |

---

## 3. Onboarding & Promotion Policy

1. **Intake**: Follow the SOP in `PROJECT/1-INBOX/GH-17-SOP-HARNESS-MODEL-EVAL.md`.
2. **Promotion to Grade A**: Requires $\ge 3$ consecutive verified runs on real repository tasks with clean PRs and green validation gates.
3. **Failure Logging**: Any grade **B** or **C** entry must document the exact failure mechanism (e.g. edit format, infinite tool loop) in a dedicated tracking issue.

---

## 4. Running Changelog

| Date | Target / Subject | Action | Details / Notes | Issue / PR |
|:---|:---|:---:|:---|:---:|
| **2026-08-16** | **Command Code (`cmd`)** | **Graded A** | Promoted `cmd` + `qwen/qwen3.8-max` to Grade A after 3/3 autonomous passes: PR #19 (tree diet refactor), PR #20 (concurrency retry fix), and PR #21 (atomic event append). | [#18](https://github.com/HiQS-Suite/XYZ-forge/issues/18) |
| **2026-08-16** | **`qwen/qwen3.7-flash`** | **Graded A** | Fast agentic tier evaluated on SOP advisory review (~23s, clean repository rail discovery). | [#18](https://github.com/HiQS-Suite/XYZ-forge/issues/18) |
| **2026-08-16** | **HARNESS-MODELS-REGISTRY** | **Created** | Initial establishment of canonical compatibility ledger, grading rubric (A/B/C/N/A), operational profiles, and historical benchmarks. | [#17](https://github.com/HiQS-Suite/XYZ-forge/issues/17) |
| **2026-08-14** | **SmallCode + Qwen 2.5 32B** | **Graded C** | Fuzzer experiments revealed infinite tool-call repetition loops on token claiming (`tick claim`); wedged without repeat limits. | [#522](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/522) |
| **2026-08-12** | **Aider + Qwen 3.8 Preview** | **Graded B** | Identified failure under default `whole` edit format (6/7 failed); resolved only when forcing `AIDER_FLAGS=--edit-format diff` (15/15 passed). | [#280](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/280) |
| **2026-07-10** | **ATE + Local Gemma (LM Studio)** | **Graded B** | Multi-hour unattended variation test harness established; requires Claude supervisor check-in to prevent drift. | PR #195 |
| **2026-07-06** | **Aider + GLM 5.2 / Nemotron** | **Graded B** | OpenRouter integration verified; required forced diff format to prevent parse errors. | [#77](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/77), [#118](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/118) |
| **2026-07-01** | **Claude / Codex / Antigravity** | **Graded A** | Standing Tier-A default harnesses for orchestrator, builder, and review lanes. | GH-212, GH-221 |

