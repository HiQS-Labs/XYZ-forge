---
title: "GH-524: AgentChorus transcripts do not record the lab, model, or effort level behind a seat"
status: Parked
created: 2026-09-09
updated: 2026-09-09
owner: unassigned
goal: record lab, model and reasoning-effort per seat in the transcript itself and stamp every turn with it, so a discussion can be attributed without the purgeable telemetry layer
gh_issue: 524
source: https://github.com/HiQS-Labs/XYZ-forge/issues/524
doc_type: defect
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/523
  - https://github.com/HiQS-Labs/XYZ-forge/issues/327
context_tags: [agent-chorus, attribution, transcript, telemetry, evidence-quality]
non_goals:
  - Validating lab/model names against any registry (free text by design)
  - Changing the telemetry schema or the pilot window
  - Auto-detecting the model from the running harness
effort: 3
complexity: 2
risk: 2
---

# GH-524 — a turn attributed to "agent2" and nothing else

## Status

| What was just completed | What's next |
|---|---|
| Fixed on `fix/merge-cleanup-primary-first`: `SEATS:` header + per-turn stamp; 13 cases, four red controls observed | Codex QA, then land with the GH-523 PR |

## Observed

Turn headings carry a seat label and a timestamp only. The lab, model and effort behind that seat
appear nowhere in the durable record. `join --model` existed but fed `emit_telemetry` alone, and
telemetry is metadata-only, stored outside the coordinated repository, and removed by
`telemetry purge`. `SKILL.md` said as much: recorded "so telemetry records which model holds this
seat; nothing else uses it."

These discussions are cited as evidence in QA relays and plan reviews, so the gap propagates into
governance records. Effort level matters as much as model: the same model at `low` and at `max`
are different reviewers.

## Fix

`join` takes `--lab` / `--model` / `--effort` and writes a `SEATS:` header; the helper stamps every
turn from it (`**Seat:** agent2 · Anthropic · claude-opus-5 · effort high`). Stamped rather than
requested, because an identity that depends on a participant remembering is the one that goes
missing when it matters. Unrecorded seats say so and name the flags. Effort is optional and never
invented. Only the field's own separators are scrubbed, so `zai-org/glm-5.3` round-trips. Partial
re-join updates only what it supplies; a closed discussion is never rewritten.

## Red controls (observed)

| Mutation | Result |
|---|---|
| turn stamp removed | FAIL: turn 2 / turn 3 not attributed |
| seat never persisted | FAIL: join echo, SEATS header, turn attribution |
| separators not scrubbed | FAIL: parsed as `Evil\|agent9=Fake\|m` — values truncated |
| closed discussions rewritten | FAIL: a join mutated a closed discussion |

The third control initially passed either way: unscrubbed separators do not forge a seat, so the
roster assertion was decorative. It now asserts the affected seat's own parsed fields.

## Rating rationale — 2026-09-09

`rated 60/55/50/85`

- **Severity 55.** No data loss and nothing breaks; the cost is evidential. Discussions used as
  QA evidence cannot be attributed once telemetry is purged, which degrades governance records
  rather than corrupting them.
- **Priority 60.** Cheap and compounding — every discussion held before the fix is permanently
  unattributable, so the value of fixing it decays with delay.
- **Appeal 50.** Neutral; the operator asked for the capability but stated no desirability score.
- **Effort/cheapness 85.** One helper, one skill doc, one test block; one sitting.
- **Recurrence.** Window 2026-08-26 → 2026-09-09 versus the preceding 14 days: no prior report of
  an attribution gap. Observed once, by the operator, on 2026-09-09. Unknown trend.
