# AgentChorus telemetry (Gen 2 Phase 1)

Metadata-only observability for discussions. Two artifacts, one guarantee:

> **Structural no-content guarantee.** `emit_telemetry` serializes only fields present in
> `TELEMETRY_EVENT_FIELDS[event]` — any other field is dropped *before* serialization. No call
> path can write message bodies, subjects, or conversation text into telemetry, because the
> writer physically cannot name a field that carries them. `telemetry audit` independently
> verifies this per discussion (the comparator negative control).

## Artifacts

- **Per-discussion sidecar** — `<discussion>/runtime/telemetry.jsonl`, one JSON object per line,
  beside the doorbell markers, never inside `conversation.md` (same reasoning as the watch
  sidecars: observability must not bloat the artifact it observes).
- **Store-level index** — `<store>/telemetry_index.db` (SQLite): one row per discussion plus an
  append-only `outcomes_log`. This is what cross-discussion analysis queries; the JSONL is the
  raw log. Created lazily on first indexed event.
- **Close report** — `<discussion>/runtime/close_report.json` on every substantive close:
  counts and flags only (decision *bytes*, dissent presence, falsifier/action counts).

## Events and allowed fields

| Event | Allowed fields (exhaustive) |
|---|---|
| `discussion_started` | `schema, agents, timed_watch, store, created_at, subject_sha256` |
| `turn_written` | `turn, agent, next_agent, message_bytes, line_count, citation_count, unique_citation_count, contains_falsifier_section, contains_dissent_section` |
| `close_written` | `close_type, decision_bytes, dissent_present, falsifier_count, recommended_actions_count, turn_count` |
| `extension_added` | `extension_number, question_bytes, done_condition_bytes` |
| `watch_transition` | `agent, transition, rearm_count` |
| `outcome_recorded` | `result, note_bytes, agents_json` |
| `seat_joined` | `agent, decision, model` |

Subjects are stored only as truncated SHA-256. Decisions only as byte counts. Timestamps,
paths, and enum strings are the permitted coincidental-metadata classes (`telemetry audit`
exempts exactly those shapes from its substring check).

## Enablement and data policy

- **Default-ON pilot window**: `2026-08-24 .. 2026-09-08` (declared in `EXPERIMENTS.md`; after
  the window, telemetry reverts to opt-in via `AGENT2AGENT_TELEMETRY=1`).
- **Hard override, either direction**: `AGENT2AGENT_TELEMETRY=0` disables even inside the
  window; `=1` enables even outside it. The override beats the window, always.
- **Revocation**: `agent_chorus.py telemetry purge` deletes every sidecar, close report, and
  the index under the configured store. `telemetry status` shows the current mode, window,
  override state, and index location.
- **Retention**: sidecar and index live only under the store (itself mode-0700 private); purge
  is complete and immediate; nothing is copied into any repository.

## Commands

```
agent_chorus.py telemetry status                 # mode, window, override, index path
agent_chorus.py telemetry aggregate              # cross-discussion summary from the index
agent_chorus.py telemetry audit --id N           # comparator: zero transcript content, or exit 1
agent_chorus.py telemetry purge                  # delete all telemetry under the store
agent_chorus.py outcome --id N --result R [--note S] [--agent SEAT=MODEL ...]
#   R ∈ implemented | partial | not_implemented | superseded (closed discussions only)
```

`seat_joined` is emitted on every `join` (including repeat joins and `DECISION: wait`), so time
from invitation to first response and per-seat participation can be reconstructed; `model` is the
operator-supplied `join --model` value or absent.

`outcome` never touches `conversation.md` and never changes `STATUS`. `--agent SEAT=MODEL`
records per-seat model attribution so decision-durability can be analyzed per participating
model — the HARNESS-MODELS-REGISTRY evidence grade applied to discussions.

Schema version: **1** (recorded in every event and in `TELEMETRY_SCHEMA_VERSION`).
