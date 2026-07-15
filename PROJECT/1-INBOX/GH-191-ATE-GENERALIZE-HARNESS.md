---
gh_issue: 191
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/191
title: "ATE: generalize harness runner beyond Aider (pluggable command/flags/classifier)"
status: captured 2026-07-09, rated — not urgent, deferred backlog
created: 2026-07-09
updated: 2026-07-09
owner: noel
doc_type: enhancement
complexity: 3
risk: 2
effort: 3
phases: 2
ratings_provisional: true
non_goals:
  - Not adding actual config/support for a second harness in this issue — just making the plumbing pluggable. Aider stays the default/reference config.
  - Not touching checkin.py or compile_issue.py's severity/rollup model — that logic is already harness-agnostic (it only reads error_log.jsonl records).
related:
  - utils/ate/scripts/run_variations.py
  - utils/ate/scripts/compile_issue.py
  - utils/ate/install.sh
  - utils/ate/SKILL.md
  - utils/ate/variations.example.yaml
goal: >
  Generalize utils/ate's variation-test runner so it can fuzz-test other AI coding harnesses, not
  just Aider — right now the skill is described generically but the implementation is hardcoded to
  one specific pipeline.
---

## Problem (confirmed in code, not assumed)

`utils/ate/` (the ATE — Automated Testing Environment — skill) is described generically ("drive
long-running unattended variation-test suites"), but the implementation underneath is hardcoded to
Aider specifically. It cannot currently be pointed at a different AI coding CLI/harness without
editing code. Confirmed in `utils/ate/scripts/run_variations.py`:

- `run_aider()` — the binary name `"aider"` is a literal string in the subprocess command, not a
  parameter.
- The flags built around it are Aider's own CLI surface: `--edit-format`, `--map-tokens`,
  `--no-auto-commits`, `--yes`, `--no-stream`, `--message`.
- `build_variations()` hardcodes the grid schema to Aider concepts: `edit_formats`, `map_tokens`,
  `auto_commits`. A different harness with a different flag surface (or no flags at all) can't
  express its variation space through this grid.
- `CLASSIFY_PROMPT` literally frames the classifier as triaging "an Aider -> OpenRouter -> GLM 5.2
  coding pipeline" — the prompt itself, not just the command it runs, is pipeline-specific.
- `utils/ate/install.sh` checks for the `aider` CLI on `PATH` as a hard dependency.

## Ask / Definition of done

- [ ] `run_aider()` replaced with a generic `run_harness(cmd_template, variation, timeout)` that
      builds argv from a `variations.yaml`-declared command template instead of hardcoded flags.
      Needs a safe templating scheme (argv-list substitution, not a shell string, to avoid injection).
- [ ] `build_variations()` grid keys become whatever `variations.yaml` declares, not the fixed three
      (`edit_formats`/`map_tokens`/`auto_commits`).
- [ ] `CLASSIFY_PROMPT` takes a parameterized pipeline name/description instead of hardcoding
      "Aider -> OpenRouter -> GLM 5.2".
- [ ] `install.sh`'s `aider` PATH check dropped or made conditional on the configured harness.
- [ ] `variations.example.yaml` and `SKILL.md` updated to show the templated form; the existing
      Aider config still works as the default/reference example (no regression for the current use
      case).

## Reversibility & blast radius

Low. Contained entirely to `utils/ate/` (a dev-tooling skill, not the relay/harness kernel);
existing Aider behavior is the reference config being preserved, not replaced. Easy to revert.

## Provenance

Surfaced 2026-07-09 while hardening the ATE skill (chained Aider -> capture -> document -> GitHub
issue cycle, `ATE - [test-name] yyyy-mm-dd` title format) when asked directly whether other
harnesses could be tested with it. Not urgent — captured for the backlog, not queued into an active
marathon plan.
