# Harness & Models Registry (Generated View)

<!-- Auto-generated from harnesses.db by utils/py/harness_app.py — DO NOT HAND-EDIT -->

## 1. Operating Harnesses & Policy Lanes

| Harness | Execution Engine | Policy Role | Operating Constraint |
|---|---|---|---|
| **Antigravity CLI** (`agy`) | `native_cli` | Cost-blind cross-model builder/reviewer | Sandbox-off required; check empty exit-0. |
| **Aider** (`aider`) | `python_litellm` | Builder only | Force AIDER_FLAGS=--edit-format diff; reviewer seam Intermittent. |
| **Claude Code** (`claude`) | `native_cli` | Orchestrator and final reviewer | Do not use as default headless builder. |
| **Codex CLI** (`codex`) | `native_cli` | Cost-blind default builder and reviewer | Subscription authenticated. |
| **Command Code** (`commandcode`) | `node_langbase` | Builder & Systems Reviewer | Requires worktree isolation and timeout bounding. |
| **DeepSeek Harness** (`dsh`) | `node_cordis` | Autonomous Headless Builder | Evaluated across 4 repository bugs with zero intervention. |
| **Pi Agent** (`pi`) | `node_multi` | Builder only | Explicit PI_MODEL required. |

## 2. Frontier Models & Reasoning Catalog

| Lab | Model | Context | Reasoning Levels | Pricing ($/1M in / out / cache) |
|---|---|:---:|:---:|:---:|
| **Alibaba** | `Qwen 3.7-Flash` | 1,000,000 | `none` | $0.03 / $0.13 / $0.0060 |
| **Alibaba** | `Qwen 3.8-Max` | 1,000,000 | `low, medium, xhigh` | $2.00 / $6.00 / $0.2500 |
| **Auto** | `deepseek/deepseek-v4-pro` | 1,000,000 | `none` | $0.00 / $0.00 / $0.0000 |
| **DeepSeek** | `DeepSeek V3` | 1,000,000 | `none` | $0.27 / $1.10 / $0.0028 |
| **DeepSeek** | `DeepSeek V4 Pro` | 1,000,000 | `low, medium, high, max` | $0.43 / $0.87 / $0.0036 |
| **Google** | `Gemma 4 31B QAT` | 32,768 | `none` | $0.00 / $0.00 / $0.0000 |
| **Stealth** | `Stealth Ox-Alpha` | 1,000,000 | `high, max` | $1.50 / $4.50 / $0.2000 |
| **Z.ai** | `GLM 5.3 High` | 1,000,000 | `low, high, max` | $1.40 / $4.40 / $0.2600 |

## 3. Empirical Evaluation History & Qualitative Work Logs

### `Qwen/Qwen3.8-Max` on `commandcode` — Grade **A-**
**Evaluated by:** `stealth/ox-alpha` (Systems Reviewer) | **Date:** 2026-08-24 17:16:48
**Reasoning Effort:** `xhigh`

Qwen 3.8-Max executed thorough systems refactoring with extra high reasoning effort.

### `Qwen/Qwen3.8-Max` on `commandcode` — Grade **A-**
**Evaluated by:** `stealth/ox-alpha` (Systems Reviewer) | **Date:** 2026-08-24 16:44:12
**Reasoning Effort:** `xhigh`

Qwen 3.8-Max executed thorough systems refactoring with extra high reasoning effort.

### `Qwen/Qwen3.8-Max` on `commandcode` — Grade **A-**
**Evaluated by:** `stealth/ox-alpha` (Systems Reviewer) | **Date:** 2026-08-24 16:36:12
**Reasoning Effort:** `xhigh`

Qwen 3.8-Max executed thorough systems refactoring with extra high reasoning effort.

### `Qwen/Qwen3.8-Max` on `commandcode` — Grade **A-**
**Evaluated by:** `stealth/ox-alpha` (Systems Reviewer) | **Date:** 2026-08-24 16:19:17
**Reasoning Effort:** `xhigh`

Qwen 3.8-Max executed thorough systems refactoring with extra high reasoning effort.

### `Qwen/Qwen3.8-Max` on `commandcode` — Grade **A-**
**Evaluated by:** `stealth/ox-alpha` (Systems Reviewer) | **Date:** 2026-08-24 16:12:19
**Reasoning Effort:** `xhigh`

Qwen 3.8-Max executed thorough systems refactoring with extra high reasoning effort.

### `Qwen/Qwen3.8-Max` on `commandcode` — Grade **A-**
**Evaluated by:** `stealth/ox-alpha` (Systems Reviewer) | **Date:** 2026-08-24 15:57:16
**Reasoning Effort:** `xhigh`

Qwen 3.8-Max executed thorough systems refactoring with extra high reasoning effort.

### `Qwen/Qwen3.8-Max` on `commandcode` — Grade **A-**
**Evaluated by:** `stealth/ox-alpha` (Systems Reviewer) | **Date:** 2026-08-24 15:50:51
**Reasoning Effort:** `xhigh`

Qwen 3.8-Max executed thorough systems refactoring with extra high reasoning effort.

### `Qwen/Qwen3.8-Max` on `commandcode` — Grade **A-**
**Evaluated by:** `stealth/ox-alpha` (Systems Reviewer) | **Date:** 2026-08-24 03:33:50
**Reasoning Effort:** `xhigh`

Qwen 3.8-Max executed thorough systems refactoring with extra high reasoning effort.

### `Qwen/Qwen3.8-Max` on `commandcode` — Grade **A-**
**Evaluated by:** `stealth/ox-alpha` (Systems Reviewer) | **Date:** 2026-08-24 03:28:51
**Reasoning Effort:** `xhigh`

Qwen 3.8-Max executed thorough systems refactoring with extra high reasoning effort.

### `Qwen/Qwen3.8-Max` on `commandcode` — Grade **A-**
**Evaluated by:** `stealth/ox-alpha` (Systems Reviewer) | **Date:** 2026-08-24 03:23:47
**Reasoning Effort:** `xhigh`

Qwen 3.8-Max executed thorough systems refactoring with extra high reasoning effort.

### `Qwen/Qwen3.8-Max` on `commandcode` — Grade **A-**
**Evaluated by:** `stealth/ox-alpha` (Systems Reviewer) | **Date:** 2026-08-23 16:06:40
**Reasoning Effort:** `xhigh`

Qwen 3.8-Max executed thorough systems refactoring with extra high reasoning effort.

### `Qwen/Qwen3.8-Max` on `commandcode` — Grade **A-**
**Evaluated by:** `stealth/ox-alpha` (Systems Reviewer) | **Date:** 2026-08-23 06:10:47
**Reasoning Effort:** `xhigh`

Qwen 3.8-Max executed thorough systems refactoring with extra high reasoning effort.

### `Qwen/Qwen3.8-Max` on `commandcode` — Grade **A-**
**Evaluated by:** `stealth/ox-alpha` (Systems Reviewer) | **Date:** 2026-08-23 06:00:29
**Reasoning Effort:** `xhigh`

Qwen 3.8-Max executed thorough systems refactoring with extra high reasoning effort.

### `Qwen/Qwen3.8-Max` on `commandcode` — Grade **A-**
**Evaluated by:** `stealth/ox-alpha` (Systems Reviewer) | **Date:** 2026-08-23 05:27:35
**Reasoning Effort:** `xhigh`

Qwen 3.8-Max executed thorough systems refactoring with extra high reasoning effort.

### `Qwen/Qwen3.8-Max` on `commandcode` — Grade **A-**
**Evaluated by:** `stealth/ox-alpha` (Systems Reviewer) | **Date:** 2026-08-23 05:19:38
**Reasoning Effort:** `xhigh`

Qwen 3.8-Max executed thorough systems refactoring with extra high reasoning effort.

### `Qwen/Qwen3.8-Max` on `commandcode` — Grade **A-**
**Evaluated by:** `stealth/ox-alpha` (Systems Reviewer) | **Date:** 2026-08-23 05:14:53
**Reasoning Effort:** `xhigh`

Qwen 3.8-Max executed thorough systems refactoring with extra high reasoning effort.

### `deepseek/deepseek-v4-pro` on `dsh` — Grade **A**
**Evaluated by:** `claude-orchestrator` (Autonomous Builder) | **Date:** 2026-08-23 05:14:35
**Reasoning Effort:** `high`

DeepSeek V4 Pro resolved the test task with high reasoning effort and zero diff regressions. Model demonstrated strong architectural adherence and minimal token consumption.

