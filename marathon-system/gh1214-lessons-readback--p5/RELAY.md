# Marathon Phase p5
STATUS: Open
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-P5-TURN builder=agy reviewer=codex round-cap=7 -->

## Phase Brief

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
- **Bind the field into the trailer (plan-review blocker, Codex, 2026-10-25).** `relay_attest.trailer_text` (`utils/py/relay_attest.py:203-210`) currently emits only task, reviewer, status, head, added-range and digest. Two records differing only in `config_sha256` produce identical trailers (Codex probe printed `True`), so a tampered value would still load.
  - When the record carries `config_sha256`, `trailer_text` must include it.
  - `load()` must validate it as a non-empty string when present.
  - A record whose stored field no longer matches its trailer must be refused.
  - Legacy records and trailers without the field still load unchanged.
  - `SCHEMA` stays `relay-drive/attest@1`, and `jog` accepts records with or without the field.

## Plan (one phase)

1. `relay_drive.py`: add the optional field from `MARATHON_CONFIG_SHA256` (tag `GH-1220`).
2. `marathon_drive.py`: compute and export the value for the relay-drive child, and apply the comparison and legacy-warning logic in `satisfied_lane_terminal` (tag `GH-1220`).
3. `relay_attest.py`: include `config_sha256` in `trailer_text` when present, validate it as a non-empty string when present, and keep legacy records accepted. Tag the change `GH-1220`.
4. Manual check under `TESTS-RESULTS/2026-10-25+GH-1220/`, using the existing attestation stub (`test/lib/attest-stub.sh`) and a throwaway repo in `$TMPDIR`. Show:
   - (a) a legacy record without the field is reused with a warning, in both marathon resume and a `relay_attest.load` call like `jog`'s
   - (b) a matching record is reused
   - (c) changing the brief file, the builder, or `AGY_MODEL` rebuilds with the one-line reason
   - (d) `jog`'s loader accepts a record that has the field
   - (e) changing only the stored `config_sha256` in a record makes `relay_attest.load()` refuse it, because the reconstructed trailer no longer matches, while a legacy record without the field still loads

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
    "criteria": "marathon_drive computes config_sha256 (brief content + builder + reviewer + their resolved *_MODEL or 'default') and passes it to its relay-drive child via MARATHON_CONFIG_SHA256; relay_drive writes it as an optional attest@1 field that relay_attest binds into trailer_text and validates when present (no schema bump, no frozen-twin edit; a tampered field is refused); satisfied_lane_terminal rebuilds with a one-line reason on mismatch, reuses on match, and reuses legacy records with a warning; jog's loader accepts both; tagged GH-1220; manual check recorded; existing attestation suites green."
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

- Manual check cases (a)–(e) behave as stated, including (e): changing only the stored `config_sha256` makes `relay_attest.load()` refuse the record, while a legacy record without the field still loads.
- `test/gh505-relay-attest.sh`, `test/gh385-retry-token-satisfied.sh`, `test/gh371-interrupt-snapshot.sh`, `test/gh372-escalation-log-tail.sh` and the full `bash validate.sh` are green.
- `SCHEMA` is still `relay-drive/attest@1`; neither frozen Bash twin is changed.

## Lessons Learned (For Future Agents)

- (filled at closeout)


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): utils/py/marathon_drive.py, utils/py/relay_drive.py, utils/py/relay_attest.py, TESTS-RESULTS/2026-10-25+GH-1220/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1220/provenance.jsonl
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick
   - /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick claim MARATHON-P5-TURN --agent agy --paths "marathon-system/gh1214-lessons-readback--p5/RELAY.md,utils/py/marathon_drive.py, utils/py/relay_drive.py, utils/py/relay_attest.py, TESTS-RESULTS/2026-10-25+GH-1220/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1220/provenance.jsonl"
   - /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick ping MARATHON-P5-TURN --agent agy
   - /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick release MARATHON-P5-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh1214-lessons-readback--p5/RELAY.md and utils/py/marathon_drive.py, utils/py/relay_drive.py, utils/py/relay_attest.py, TESTS-RESULTS/2026-10-25+GH-1220/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1220/provenance.jsonl. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/marathon_drive.py, utils/py/relay_drive.py, utils/py/relay_attest.py, TESTS-RESULTS/2026-10-25+GH-1220/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1220/provenance.jsonl. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick release MARATHON-P5-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick done MARATHON-P5-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick
   Edit ONLY marathon-system/gh1214-lessons-readback--p5/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
4c. A finding that asks for a behaviour change is a generalization unless you can paste the concrete
   input — a row, a value, a `file:line` — that fails under the current code (GH-681). Every
   `[Blocker]` or `[Should]` requesting a behaviour change MUST carry `Observed input:`,
   `Affected scope:` and `Falsifier:` lines; a `[Blocker]` must cite an observed failure. The Builder
   may disposition a request lacking these as `Declined — unproven generalization`.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to agy —
   agy, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.


### Round 1 · Builder · agy

Implemented GH-1220 optional `config_sha256` attestation and resume check across `utils/py/relay_attest.py`, `utils/py/relay_drive.py`, and `utils/py/marathon_drive.py`, with verification receipts in `TESTS-RESULTS/2026-10-25+GH-1220/`.

#### Files Touched & Key Decisions

1. **`utils/py/relay_attest.py`**:
   - Kept `SCHEMA = "relay-drive/attest@1"` unchanged.
   - In `trailer_text(record)` (lines 203–215), when `record.get("config_sha256")` is present and truthy, appended `config-sha256: <value>\n` to the trailer text so `trailer_sha256` and the relay file trailer bind `config_sha256`. Legacy records without `config_sha256` omit the line and match their legacy trailers unchanged.
   - In `_load()` (lines 278–281), validated that when `"config_sha256" in rec`, it is a non-empty `str` (`"attestation record field config_sha256 is not a non-empty string"`), and because `trailer_text(rec)` is hashed against `rec["trailer_sha256"]` and compared against the relay file trailer bytes, any tampering with a stored `config_sha256` is refused with `"attestation record does not match its own trailer"`.
2. **`utils/py/relay_drive.py`**:
   - In `judge_terminal()` (lines 752–755), read `MARATHON_CONFIG_SHA256` via `get_env("MARATHON_CONFIG_SHA256", "")`; when non-empty, set `record["config_sha256"] = cfg_sha` before computing `relay_attest.trailer_text(record)` and `record["trailer_sha256"]`.
3. **`utils/py/marathon_drive.py`**:
   - Added `compute_config_sha256(brief_file, builder, reviewer, env=None)` (lines 487–498) with the required credit comment (`# GH-1220: idea adapted from Harness² core/runmark.py (google-research/harness2, Apache-2.0).`), hashing newline-joined `[brief_text, builder, reviewer, _model_val(builder), _model_val(reviewer)]` via `relay_attest.sha256`.
   - Passed `MARATHON_CONFIG_SHA256` in `_run_relay_drive()` on the child environment `env2` (line 3416) so `os.environ` is not mutated (keeping `test/gh441-gate-env-contract.sh` C1 green without touching `gate_env.py`).
   - In `satisfied_lane_terminal()` (lines 2908–2915): if `config_sha256` is absent/empty on the attested record, logged `marathon-drive: phase <id>: legacy attestation without config identity — reusing (GH-1220)` and reused; if `rec.get("config_sha256") != config_sha256`, logged `marathon-drive: phase <id>: phase config changed since attestation — rebuilding (GH-1220)`, marked `config_mismatch_rebuild[0] = True`, and returned `False`.
   - Passed `force=bool(args.force or config_mismatch_rebuild[0])` to `resolve_force_relay_task(...)` (line 2944) so a config-mismatch rebuild on a spent `done` base token allocates a fresh `-R2` (`-R3`, …) retry token rather than failing at `tick claim`.
4. **`TESTS-RESULTS/2026-10-25+GH-1220/manual-check.md` & `TESTS-RESULTS/2026-10-25+GH-1220/provenance.jsonl`**:
   - Recorded red/green control verification in throwaway git repos under `$TMPDIR` covering all cases (a)–(e) plus existing regression suites (`test/gh505-relay-attest.sh`, `test/gh385-retry-token-satisfied.sh`, `test/gh371-interrupt-snapshot.sh`, `test/gh372-escalation-log-tail.sh`, `test/gh441-gate-env-contract.sh`, `test/gh308-frozen-twin-guard.sh`).
