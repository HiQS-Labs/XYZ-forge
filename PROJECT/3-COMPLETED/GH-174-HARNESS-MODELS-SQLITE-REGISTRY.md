---
gh_issue: 174
source: https://github.com/HiQS-Labs/XYZ-forge/issues/174
title: "Harness & Models Registry SQLite Migration: Per-Device Config, Reasoning Effort Tracking, AI Grading Hooks & Blog Generator"
status: 3-COMPLETED (shipped)
created: 2026-08-22
updated: 2026-08-22
owner: noelsaw1
doc_type: plan
effort: 3
complexity: 3
risk: 2
phases: 5
rating: "pri/sev/appeal/effort 85/75/95/45 · calc 300"
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/17
  - https://github.com/HiQS-Labs/XYZ-forge/issues/18
  - https://github.com/HiQS-Labs/XYZ-forge/issues/32
  - https://github.com/HiQS-Labs/XYZ-forge/issues/68
  - https://github.com/HiQS-Labs/XYZ-forge/issues/103
  - https://github.com/HiQS-Labs/XYZ-forge/issues/148
  - https://github.com/HiQS-Labs/XYZ-forge/issues/156
  - https://github.com/HiQS-Labs/XYZ-forge/issues/165
goal: >
  Migrate static HARNESS-MODELS-REGISTRY.md into an active SQLite ledger (harnesses.db)
  with unified per-device config resolution, model reasoning effort tracking, deterministic post-turn
  AI grading hooks, and automated blog/experience story synthesis.
---

# GH-174: Harness & Models Registry SQLite Migration

## Status

| What was just completed | What's next |
|---|---|
| Phase 1-5 implemented: `harnesses.db` schema, CLI `harness_app.py`, 3-tier config `device_config.py`, telemetry `harness_turn_logger.py`, AI grading hooks, blog generator, and 6/6 test assertions passing in `test/gh174-harness-registry.sh`. | Full validation gate run and pull request merge. |

## 1. Architectural Motivation & Problem Statement

`HARNESS-MODELS-REGISTRY.md` is currently a static 206-line markdown file. While comprehensive, static tables suffer from:
1. **Manual Maintenance & Schema Drift:** Adding new evaluated runs, pricing changes, or model aliases requires hand-editing markdown tables.
2. **Missing Local Telemetry:** Turns across diverse harnesses (`dsh`, `commandcode`, `codex`, `agy`, `claude`, `aider`, `pi`) do not capture local device hardware specs, reasoning levels, or exact token costs in queryable format.
3. **No Automated AI Grading Loop:** Post-turn evaluations rely on ad-hoc human notes rather than a deterministic grading hook scoring runs against objective invariants (gate pass, diff cleanliness, native delivery).
4. **Untapped Empirical Publishing:** The repository generates unique real-world benchmarks on 1M context reasoning models, but lacks an automated pipeline to synthesize experience blog posts and comparative articles.

## 2. Core Architectural Invariants

1. **DRY Per-Device Configuration:** Reuses the existing `~/.xyz/` config hierarchy (`~/.xyz/device_config.json` falling back to environment variables `XYZ_HARNESS`, `XYZ_MODEL`, `XYZ_REASONING_EFFORT`).
2. **Reasoning Level & Model Variant Tracking:** Captures explicit reasoning levels (`low`, `medium`, `high`, `max`, `xhigh`) and thinking token budgets per invocation.
3. **Dual Storage & Reversibility:** SQLite `harnesses.db` paired with human-readable, lossless `harnesses.sql` dump and generated `HARNESS-MODELS-REGISTRY.generated.md`.
4. **Deterministic Post-Turn Grading Hook:** Automated callback prompting the AI orchestrator or reviewer to assign grades (`A`, `B`, `C`, `N/A`) with structured qualitative descriptions (1–3 paragraphs).
5. **Blog & Case Study Synthesis:** Subcommand `harness blog gen` querying evaluation history to produce publishable Markdown articles.

## 3. SQLite Relational Schema (`harnesses.sql`)

```sql
-- Devices & Local Configurations
CREATE TABLE IF NOT EXISTS devices (
    device_id TEXT PRIMARY KEY,
    user_name TEXT NOT NULL,
    os_version TEXT NOT NULL,
    cpu_cores INTEGER NOT NULL,
    ram_gb INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_configs (
    config_id TEXT PRIMARY KEY,
    device_id TEXT NOT NULL REFERENCES devices(device_id),
    default_harness TEXT NOT NULL,
    default_gateway TEXT NOT NULL,
    default_model TEXT NOT NULL,
    default_reasoning_effort TEXT,
    is_active INTEGER DEFAULT 1,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Harnesses & Models Catalog
CREATE TABLE IF NOT EXISTS harnesses (
    harness_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    execution_engine TEXT NOT NULL,
    supports_programmatic INTEGER DEFAULT 0,
    supports_reasoning_effort INTEGER DEFAULT 1,
    headless_command_template TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS models (
    model_id TEXT PRIMARY KEY,
    lab TEXT NOT NULL,
    canonical_name TEXT NOT NULL,
    gateway TEXT NOT NULL,
    context_window INTEGER NOT NULL,
    prompt_price_per_m REAL,
    completion_price_per_m REAL,
    cache_read_price_per_m REAL,
    supported_reasoning_levels TEXT
);

-- Invocations & Telemetry
CREATE TABLE IF NOT EXISTS invocation_logs (
    invocation_id TEXT PRIMARY KEY,
    device_id TEXT NOT NULL REFERENCES devices(device_id),
    harness_id TEXT NOT NULL REFERENCES harnesses(harness_id),
    model_id TEXT NOT NULL REFERENCES models(model_id),
    gateway TEXT NOT NULL,
    reasoning_effort TEXT,
    entry_point_shim TEXT NOT NULL,
    cli_flags TEXT NOT NULL,
    task_scope TEXT NOT NULL,
    wall_clock_seconds REAL,
    exit_code INTEGER NOT NULL,
    total_tokens INTEGER,
    prompt_tokens INTEGER,
    completion_tokens INTEGER,
    estimated_cost_usd REAL,
    repo_diff_stat TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Evaluations & Narrative Work Descriptions
CREATE TABLE IF NOT EXISTS evaluations (
    evaluation_id TEXT PRIMARY KEY,
    invocation_id TEXT UNIQUE NOT NULL REFERENCES invocation_logs(invocation_id),
    evaluated_by TEXT NOT NULL,
    evaluation_role TEXT NOT NULL,
    grade TEXT NOT NULL CHECK(grade IN ('A', 'A-', 'B+', 'B', 'B-', 'C', 'N/A')),
    qualifying_gate_passed INTEGER NOT NULL,
    diff_cleanliness_score INTEGER,
    seam_reliability_score INTEGER,
    work_description_narrative TEXT NOT NULL,
    failure_mode_tag TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Generated Blog Stories & Case Studies
CREATE TABLE IF NOT EXISTS blog_stories (
    story_id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    theme TEXT NOT NULL,
    source_evaluations TEXT NOT NULL,
    markdown_content TEXT NOT NULL,
    published_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## 4. 5-Phase Implementation Plan

- **Phase 1 (Core Schema & CLI Engine):** Implement `utils/py/harness_app.py`, `harnesses.db`, `harnesses.sql`, and `harness check` integrity tests.
- **Phase 2 (DRY Per-Device Config & Turn Interceptor):** Auto-logging interceptor integrated into Python turn twins recording harness, model, and reasoning level.
- **Phase 3 (Deterministic Post-Turn Grading Hook):** Structured evaluation hook prompting orchestrator / reviewer with the 4-tier rubric.
- **Phase 4 (Blog & Experience Story Synthesizer):** `harness blog gen` generating publishable markdown case studies.
- **Phase 5 (Full Gate Qualification & Adoption):** `test/gh174-harness-registry.sh` registered in `validate.sh` (suite #258).

## Lessons Learned (For Future Agents)

1. **Foreign Key Grace on Dynamic Telemetry:** When logging telemetry across diverse test harnesses, dynamic model strings or newly deployed device hosts can fail strict foreign key checks if not pre-registered. Use `INSERT OR IGNORE INTO devices` and `models` inside the logging transaction to guarantee fail-safe recording.
2. **3-Tier Config Resolution Avoids Repetition:** Resolving per-device settings through local JSON (`~/.xyz/device_config.json`) with environment variable overrides (`XYZ_*`) and sensible global defaults keeps turn shims clean, portable, and completely DRY.
3. **Falsifiable Downstream Story Generation:** Grounding blog post synthesis directly on relational SQLite queries against committed `invocation_logs` and `evaluations` ensures that published performance metrics, reasoning comparisons, and failure mode case studies are 100% verifiable by machine.
