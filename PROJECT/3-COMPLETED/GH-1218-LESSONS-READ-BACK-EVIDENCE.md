---
gh_issue: 1218
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1218
title: "Lessons read-back: evidence-gated LESSONS-LEARNED.md entries via rtl_turn_prompt + defect-campaign writer (#1214 P1+6a)"
status: Complete
created: 2026-10-25
updated: 2026-10-26
owner: marathon-gh-1214
doc_type: feedback
complexity: 3
risk: 2
effort: 3
phases: 1
ratings_provisional: false   # rated 2026-10-25 at marathon prep: one shared prompt-builder change + doc/skill text; warn-only, silent when absent
non_goals:
  - Any lint, check, guard or gate on lessons entries (AGENTS.md:156, GH-831 D7)
  - Backfilling the existing completed-doc Lessons Learned sections (#1214 Phase 0, option B)
  - Relevance filtering by area (newest-5 only until volume justifies it)
  - debug.log / harvest-findings / proposals-sink (out of scope by operator decision)
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1214 (umbrella, Phase 1 + Phase 6a; Phase 0 decisions)
  - GH-591 (the existing LESSONS-LEARNED.md entry), GH-693 (sections advisory)
goal: >
  Every relay/marathon turn prompt carries a capped, warn-only pointer list of the newest five
  non-superseded lessons from LESSONS-LEARNED.md; lessons are written only through evidence-gated
  writer prompts in /start-task, /marathon-cleanup and defect-campaign; the file uses one structured
  entry format with public evidence.
---

# GH-1218 — Lessons read-back: evidence-gated entries via `rtl_turn_prompt`

## Status

| What was just completed | What's next |
|---|---|
| 2026-10-25: promoted to 2-WORKING as phase p4 of marathon #1214; Phase 0 decided (single home `LESSONS-LEARNED.md`; doc sections → writer input; no backfill); Kimi K3.1 QA dispositions folded in | Marathon phase p4 (agy builder, codex reviewer): entry format + #591 conversion, reader in `rtl_turn_prompt`, writer text in three skills, pkg regen, manual check, gate green |

Umbrella: #1214 · Phase p4 · `depends_on: p3`.

## Ground truth (`origin/development` 395e9d64)

- `relay-automation/relay-turn-lib.sh:995` defines `rtl_turn_prompt`. Every Python turn shim reaches it through `utils/py/rtl.py:849-852`, and every Bash shim calls it directly, `relay-automation/smallcode-turn.sh:28` included. That makes it the single place to inject the list.
- The style precedent is `rtl_drift_brief` (`relay-turn-lib.sh:1679-1719`): warn-only, at most 5 items, plus a "+N omitted" line.
- `relay-turn-lib.sh` is packaged into `skills/1-hourly/relay-automation/relay-pkg.tar.gz` (`make-pkg.sh:18`), so regenerate with `bash skills/1-hourly/relay-automation/make-pkg.sh` after the edit, or `test/relay-pkg-freshness.sh` goes red.
- `LESSONS-LEARNED.md` holds one free-form lesson, from #591.
- Writer insertion points:
  - `skills/1-hourly/start-task/SKILL.md` step 9, PR handoff (~288-305), plus one reader line in step 1 (~63-75)
  - `skills/3-weekly/marathon-cleanup/SKILL.md`, evidence review (~12-25)
  - `skills/4-occasional/defect-campaign/SKILL.md`, disposition step (~91-107)
- The repo is **public**. `harnesses.db` `evaluations` rows carry a free-form `work_description_narrative` (`utils/py/harness_app.py:253-265`).

## Plan (one phase)

1. **Entry format** at the top of `LESSONS-LEARNED.md`, under a short header that explains the format and the rules. Each entry is a `## <short title>` heading followed by field lines:
   - `- **cue**:` the kind of situation, not this task's facts
   - `- **lesson**:` an operation that can be checked, naming the component
   - `- **evidence**:` public links only
   - `- **confidence**:` high/medium/low, with the reason
   - `- **area**:` relay | marathon | pdda | gate | skills | releases
   - `- **source**:` the issue/PR
   - `- **date**:`
   - optional `- **superseded-by**:`

   Convert the existing #591 lesson into this format, keeping its substance. The narrative body may stay under the fields.
2. **Rules, stated in the header and repeated in every writer prompt.** Prompt text only; no tooling.
   - **Admission:** refuse an entry whose `cue`, `lesson` or `evidence` is empty. Adoption or a merge alone is not evidence. Writing `NO_ENTRY` is a valid outcome.
   - **Edit verdicts:** before drafting, write one row per changed component: helped / hurt / no observed effect / confounded. Use `confounded` when several things changed at once or a single run is the only support. A lesson resting only on `confounded` rows is refused.
   - **Public evidence:** use repo-relative paths to committed `TESTS-RESULTS/` receipts, stable IDs, or public issue/PR/commit links. Never paste DB narratives, transcripts, credentials, hostnames or absolute paths.
   - **ATE/fuzz evidence (Phase 6a):** it counts only after semantic replay, and the cited record must show the predicate and the clean/failing controls. A raw cluster, or a replay matched only by digest or exit code, is `confounded`.
3. **Reader, in `rtl_turn_prompt`.** Resolve `LESSONS-LEARNED.md` at the turn's repo root (`RTL_ROOT` when set, else the git toplevel). If the file exists, append a short block, warn-only and informational, in the drift-brief style:
   - one heading line, then the heading and `cue` of the **newest 5 non-superseded entries**, never their bodies
   - the file path
   - a `+N earlier lesson(s) omitted` line when more exist

   If the file is absent or unreadable, emit nothing. Tag the code `GH-1218`. Make no per-shim edits and leave the frozen twins alone. Regenerate `relay-pkg.tar.gz`.
4. **Writers (prompt text).**
   - `start-task` step 9: before handoff, read the task doc's own `## Lessons Learned` section, if present, as the candidate. Apply the rules, then append one entry to `LESSONS-LEARNED.md` in the PR, or state `NO_ENTRY`.
   - `start-task` step 1: one line telling the agent to read relevant `LESSONS-LEARNED.md` entries.
   - `marathon-cleanup` evidence review: the same writer step, per member doc.
   - `defect-campaign` disposition step: optional; for `new defect` / `faulty oracle` with a semantic replay, draft an entry with `cue` = the shape of the cluster (target + violated invariant), `evidence` = the replay result + the `TESTS-RESULTS/` path, and `area` = the target's subsystem. It stays inside that skill's approval boundary.
5. **Manual check** under `TESTS-RESULTS/2026-10-25+GH-1218/`:
   - capture the `rtl_turn_prompt` output with a fixture lessons file in a throwaway repo under `$TMPDIR`: 7 entries, one of them superseded
   - show that 5 pointers plus the "+N omitted" line appear, that the superseded entry is skipped, and that the output is identical through the Python path (`rtl.py`), the Bash fallback (`XYZ_PYTHON=0`) and SmallCode
   - show silence when the file is absent
   - show the writer rule refusing an empty-evidence entry and accepting a cited one, as a worked example in `manual-check.md`

   Write `manual-check.md` plus `provenance.jsonl`.

Rules: shortest diff; no new script (inventory ratchet), no new suite or registry entry, no new guard (GH-831 D7, `AGENTS.md:154-157`). Edit an existing suite only if a pinned prompt assertion becomes untrue. Design credit: add a one-line comment near the reader, "Design adapted from Harness² (google-research/harness2, Apache-2.0)". No code is copied.

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
      "path": "relay-automation/relay-turn-lib.sh",
      "pattern": "GH-1218"
    },
    {
      "type": "grep_absent",
      "path": "LESSONS-LEARNED.md",
      "pattern": "\\*\\*cue\\*\\*"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-25+GH-1218/manual-check.md"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-25+GH-1218/provenance.jsonl"
    }
  ],
  "artifacts": [
    "relay-automation/relay-turn-lib.sh",
    "skills/1-hourly/relay-automation/relay-pkg.tar.gz",
    "LESSONS-LEARNED.md",
    "skills/1-hourly/start-task/SKILL.md",
    "skills/3-weekly/marathon-cleanup/SKILL.md",
    "skills/4-occasional/defect-campaign/SKILL.md",
    "TESTS-RESULTS/2026-10-25+GH-1218/manual-check.md",
    "TESTS-RESULTS/2026-10-25+GH-1218/provenance.jsonl"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-10-25+GH-1218/manual-check.md",
    "TESTS-RESULTS/2026-10-25+GH-1218/provenance.jsonl"
  ],
  "remediation": {
    "source": "issue#1218",
    "criteria": "rtl_turn_prompt (tagged GH-1218) appends a warn-only block listing heading+cue of the newest five non-superseded LESSONS-LEARNED.md entries plus path and +N omitted, silent when the file is absent, identical via Python, Bash fallback and SmallCode; relay-pkg.tar.gz regenerated; LESSONS-LEARNED.md uses the structured format with the #591 entry converted and the admission/verdict/public-evidence/ATE rules stated; writer text in start-task step 9 (+reader line in step 1), marathon-cleanup and defect-campaign; manual check recorded; no new suite, script or guard."
  },
  "lanes": {
    "agy_safe": [
      "relay-automation/relay-turn-lib.sh",
      "skills/1-hourly/relay-automation/relay-pkg.tar.gz",
      "LESSONS-LEARNED.md",
      "skills/1-hourly/start-task/SKILL.md",
      "skills/3-weekly/marathon-cleanup/SKILL.md",
      "skills/4-occasional/defect-campaign/SKILL.md",
      "TESTS-RESULTS/2026-10-25+GH-1218/manual-check.md",
      "TESTS-RESULTS/2026-10-25+GH-1218/provenance.jsonl"
    ],
    "orchestrator_only": []
  }
}
```

## Acceptance

- Manual check: 5 pointers plus the omitted count, superseded entry skipped, silent when absent, identical across Python, Bash fallback and SmallCode.
- `LESSONS-LEARNED.md` uses the format, with #591 converted and the rules stated.
- Writer and reader text present in all three skills.
- `test/relay-pkg-freshness.sh`, the prompt-pinning suites (`gh397-reviewer-turn-role.sh`, `gh681-reviewer-probe-rules.sh`, `relay-self-sufficiency.sh`, …) and the full `bash validate.sh` are green.

## Lessons Learned (For Future Agents)

- (filled at closeout)
