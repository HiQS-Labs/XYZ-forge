# Focused check receipts

Checks run in a separate disposable full clone at `38980817452bcb35db78d7150b9323b70b755702`; this is the unchanged skill revision reviewed in both relay rounds. Output below retains each PDDA check summary; warnings concern existing issue/doc state, governance and marathon QA. Full local output is retained in the task clone's ignored `temp/unstuck-task/checks.md`.

```text
SUMMARY [pdda-check-frontmatter] errors=0 warns=0 info=0
SUMMARY [pdda-check-status-table] errors=0 warns=0 info=0
SUMMARY [pdda-check-hardcoded-paths] errors=0 warns=0 info=0
SUMMARY [pdda-check-roadmap] errors=0 warns=0 info=1
SUMMARY [pdda-check-roadmap-coverage] errors=0 warns=0 info=72
SUMMARY [pdda-check-changelog] errors=0 warns=0 info=0
SUMMARY [pdda-stale-working-docs] errors=0 warns=0 info=0
SUMMARY [pdda-check-issue-doc-sync] errors=0 warns=341 info=0
SUMMARY [pdda-check-releases] errors=0 warns=0 info=1
SUMMARY [pdda-check-governance] errors=0 warns=18 info=1
SUMMARY [pdda-check-marathon-qa] errors=0 warns=9 info=0
SUMMARY [pdda-doc-ready] errors=0 warns=0 info=1
PDDA run complete: no errors, 368 warning(s) to review — pdda-check-issue-doc-sync pdda-check-governance pdda-check-marathon-qa
Clone identity unchanged (local configuration and HEAD).
```

## Provenance (Markdown-only scope)

```jsonl
{"command": "bash utils/pdda/pdda.sh run", "rc": 0, "result": "PASS", "commit": "38980817452bcb35db78d7150b9323b70b755702", "timestamp": "2026-09-28T00:32:09.663469+00:00", "host": "Darwin arm64"}
{"command": "python3 <skill-creator>/scripts/quick_validate.py skills/1-hourly/unstuck", "rc": 1, "result": "FAIL", "commit": "38980817452bcb35db78d7150b9323b70b755702", "timestamp": "2026-09-28T00:32:09.723658+00:00", "host": "Darwin arm64"}
{"command": "<existing-test-venv>/bin/python3 <skill-creator>/scripts/quick_validate.py skills/1-hourly/unstuck", "rc": 0, "result": "Skill is valid!", "commit": "38980817452bcb35db78d7150b9323b70b755702", "timestamp": "2026-09-28T00:33:03.167610+00:00", "host": "Darwin arm64"}
```

The first skill-validator attempt failed before validation: default Python lacked PyYAML (`ModuleNotFoundError: yaml`). Re-running with the existing test virtualenv passed; no dependencies were installed. The task-clone two local skill links also resolve. Router output for all changed paths: `route=docs`, `tier=1`. No full gate or runtime suite run is claimed.
