---
gh_issue: 1220
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1220
title: "marathon resume reuses a phase built under a different config — optional config_sha256 in attest@1 (#1214 P3)"
status: Active (2-WORKING — marathon GH-1214 phase p5)
created: 2026-10-25
updated: 2026-10-25
owner: marathon-gh-1214
doc_type: feedback
complexity: 3
risk: 3
effort: 3
phases: 1
ratings_provisional: false   # rated 2026-10-25 at marathon prep: risk 3 — attestation is the trust boundary jog's auto-merge reads; operator-selected into the marathon (planner would hold risk>2 from AUTOMATIC selection); mitigated by backward-compatible optional field, no schema bump, legacy-accept default
non_goals:
  - Bumping relay-drive/attest@1 to a new schema version
  - Hashing skill files (builder turns load no skill)
  - Changing GH-505/GH-509 attestation semantics for reviewer, HEAD or review digest
  - Editing the frozen Bash twins (relay-drive.sh, marathon-drive.sh)
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1214 (umbrella, Phase 3)
  - GH-505, GH-509 (attestation), GH-385, GH-491 (satisfied-lane reuse)
goal: >
  A marathon resume reuses a finished phase only when the phase brief, builder, reviewer and their
  resolved models match what produced it; on mismatch it rebuilds with a one-line reason; records
  written before this change still load (with a warning) in both marathon resume and jog.
---

# GH-1220 — marathon resume reuses a phase built under a different config

## Status

| What was just completed | What's next |
|---|---|
| 2026-10-25: promoted to 2-WORKING as phase p5 (last) of marathon #1214; identity-source design gap closed at prep (env var from marathon_drive, no frozen-twin edit, no schema bump) | Marathon phase p5 (agy builder, codex reviewer): write and compare `config_sha256`, legacy-accept, manual check, gate green |

Umbrella: #1214 · Phase p5 · `depends_on: p4`. Ordered **last** because it edits the attestation and resume code that the marathon driver itself runs. A regression here can only halt this phase, never an earlier one.

## Ground truth (`origin/development` 395e9d64)

- `utils/py/marathon_drive.py:2861-2896` `satisfied_lane_terminal()` reuses a phase when it finds a terminal status, a done token and a valid attestation record (`attested_terminal`). It never compares the brief, builder, reviewer or models.
- `utils/py/relay_drive.py:734-750` builds the record: schema, task, relay file, target repo, reviewer, status, reviewed_head, artifact_sha256, added_* digest, attested_at and driver_pid. It has no config identity.
- `utils/py/relay_attest.py:26,241-258`: `SCHEMA = "relay-drive/attest@1"` with an **exact** schema comparison. `utils/py/jog_run.py:405-414` loads the same records at auto-merge time.
- `marathon_drive` invokes relay-drive through `MARATHON_RELAY_DRIVE` (default `relay-automation/relay-drive.sh`, a FROZEN Bash twin; `marathon_drive.py:1126`). `relay_drive.py` rejects unknown flags (GH-322), so a new CLI flag would also mean editing the frozen twin.

## Decided design

- **Transport is an environment variable, not a CLI flag.** `marathon_drive` computes the value and exports `MARATHON_CONFIG_SHA256` into the environment of its relay-drive child. `relay_drive.py` writes `"config_sha256": <value>` into the record when the variable is set and non-empty. This touches neither frozen twin.
- **Identity:** `config_sha256` = sha256 over a canonical, newline-joined string of:
  - the phase brief **file content**
  - the builder id and the reviewer id
  - each one's resolved model environment value (the shims' `*_MODEL` variable for that agent, e.g. `AGY_MODEL` or `COMMANDCODE_MODEL`), or the literal `default` when unset

  Keep the computation in one small function in `marathon_drive.py`.
- **Comparison in `satisfied_lane_terminal`:**
  - The record carries `config_sha256` and it differs from the current value: log one line naming the phase and saying the config changed (do not print the brief), then return `False`, so the phase rebuilds through the existing fresh-token path.
  - The record has no `config_sha256`: log a warning ("legacy attestation without config identity — reusing") and reuse as today.
  - The values match: reuse as today.
- `relay_attest.py`: keep `SCHEMA` unchanged. The optional field must not fail validation. Update the docstring or field list only if one exists that enumerates fields. `jog` must accept records with or without the field.

## Plan (one phase)

1. `relay_drive.py`: add the optional field from `MARATHON_CONFIG_SHA256` (tag `GH-1220`).
2. `marathon_drive.py`: compute and export the value for the relay-drive child, and apply the comparison and legacy-warning logic in `satisfied_lane_terminal` (tag `GH-1220`).
3. `relay_attest.py`: no change unless validation rejects unknown keys; if it does, allow `config_sha256` as an optional string.
4. Manual check under `TESTS-RESULTS/2026-10-25+GH-1220/`, using the existing attestation stub (`test/lib/attest-stub.sh`) and a throwaway repo in `$TMPDIR`. Show:
   - (a) a legacy record without the field is reused with a warning, in both marathon resume and a `relay_attest.load` call like `jog`'s
   - (b) a matching record is reused
   - (c) changing the brief file, the builder, or `AGY_MODEL` rebuilds with the one-line reason
   - (d) `jog`'s loader accepts a record that has the field

   Write `manual-check.md` plus `provenance.jsonl`.

Rules: Python only; shortest diff; no new suite or registry entry (GH-831 D7). Edit existing suites (`test/gh505-relay-attest.sh`, `test/gh385-retry-token-satisfied.sh`, `test/lib/attest-stub.sh`) only if a pinned assertion becomes untrue. Credit: one-line comment, "idea adapted from Harness² core/runmark.py (google-research/harness2, Apache-2.0)". No code is copied.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh",
  "fix_probes": [
    {
      "type": "grep_absent",
      "path": "utils/py/marathon_drive.py",
      "pattern": "GH-1220"
    },
    {
      "type": "grep_absent",
      "path": "utils/py/relay_drive.py",
      "pattern": "config_sha256"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-25+GH-1220/manual-check.md"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-25+GH-1220/provenance.jsonl"
    }
  ],
  "artifacts": [
    "utils/py/marathon_drive.py",
    "utils/py/relay_drive.py",
    "utils/py/relay_attest.py",
    "TESTS-RESULTS/2026-10-25+GH-1220/manual-check.md",
    "TESTS-RESULTS/2026-10-25+GH-1220/provenance.jsonl"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-10-25+GH-1220/manual-check.md",
    "TESTS-RESULTS/2026-10-25+GH-1220/provenance.jsonl"
  ],
  "remediation": {
    "source": "issue#1220",
    "criteria": "marathon_drive computes config_sha256 (brief content + builder + reviewer + their resolved *_MODEL or 'default') and passes it to its relay-drive child via MARATHON_CONFIG_SHA256; relay_drive writes it as an optional attest@1 field (no schema bump, no frozen-twin edit); satisfied_lane_terminal rebuilds with a one-line reason on mismatch, reuses on match, and reuses legacy records with a warning; jog's loader accepts both; tagged GH-1220; manual check recorded; existing attestation suites green."
  },
  "lanes": {
    "agy_safe": [
      "utils/py/marathon_drive.py",
      "utils/py/relay_drive.py",
      "utils/py/relay_attest.py",
      "TESTS-RESULTS/2026-10-25+GH-1220/manual-check.md",
      "TESTS-RESULTS/2026-10-25+GH-1220/provenance.jsonl"
    ],
    "orchestrator_only": []
  }
}
```

## Acceptance

- Manual check cases (a)–(d) behave as stated.
- `test/gh505-relay-attest.sh`, `test/gh385-retry-token-satisfied.sh`, `test/gh371-interrupt-snapshot.sh`, `test/gh372-escalation-log-tail.sh` and the full `bash validate.sh` are green.
- `SCHEMA` is still `relay-drive/attest@1`; neither frozen Bash twin is changed.

## Lessons Learned (For Future Agents)

- (filled at closeout)
