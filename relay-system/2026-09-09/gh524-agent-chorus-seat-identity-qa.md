# RELAY — GH-524 AgentChorus seat identity (lab / model / effort)

STATUS: In progress
NEXT: codex
ROUND: 1

## Body

### Context

AgentChorus transcripts attributed every turn to a seat label and a timestamp:

```
### Turn 4 — agent2 — 2026-09-09T17:26:46+00:00
```

Nowhere in the durable record did it say which lab, which model, or what reasoning-effort level
was behind `agent2`. `join --model` existed but passed the value to `emit_telemetry("seat_joined")`
only. Telemetry is metadata-only, lives outside the coordinated repository by design
(`TELEMETRY.md`), and `telemetry purge` deletes it — so the one fact a later reader needs was
stored exclusively in the layer built to be discardable. `SKILL.md` said as much: recorded "so
telemetry records which model holds this seat; nothing else uses it."

These discussions are cited as evidence in QA relays and plan reviews (this thread included), so
the gap propagates into governance records. Effort level matters as much as model: the same model
at `low` and at `max` are different reviewers.

The change under review is commit `810bd3e2` on `fix/merge-cleanup-primary-first`, closing #524.

### What changed

1. `skills/agent-chorus/scripts/agent_chorus.py`
   - New helpers: `_seat_scrub`, `parse_seats`, `render_seats`, `seat_stamp`, `record_seat`, plus
     `SEAT_SEP` / `SEAT_PART_SEP` / `SEAT_UNKNOWN`.
   - `join_discussion` takes `lab`/`model`/`effort` and upserts a `SEATS:` header field after
     `AGENTS:` — `SEATS: agent2=Anthropic|claude-opus-5|high; agent3=OpenAI|gpt-5-codex|-`.
     It writes only when an identity is supplied, and never when `STATUS: Closed`.
   - The turn writer prepends `seat_stamp(content, member)` to every turn body.
   - `join` CLI gains `--lab` and `--effort`; the `--model` help no longer says telemetry-only.
     `join` echoes the resulting stamp.
   - The generated Protocol block tells participants to identify themselves.

2. `skills/agent-chorus/SKILL.md` — new "Say who you are" section under Join, with the rendered
   shape and why telemetry is not a substitute.

3. `test/agent-chorus.sh` — 13 cases (196 pass, 0 fail).

### Design choices to challenge

- **Stamped by the helper, not asked of the participant.** An identity that depends on a model
  remembering to type it goes missing exactly when the transcript matters.
- **Free text, not a validated registry.** Labs and model ids change faster than any list.
- **`|` as the part separator, `;` between seats.** Model ids legitimately contain `/` and `:`
  (`zai-org/glm-5.3`, `us.anthropic.claude-…`), so those must survive; `|`, `;` and `=` are
  scrubbed out of values.
- **Effort optional.** Many harnesses expose none; the stamp then names lab and model only.

### Evidence

`test/agent-chorus.sh`: 196 pass, 0 fail. Siblings unaffected: `agent-chorus-bridge.sh` 43 pass,
`gh233-agent-chorus-concurrency.sh` 16 pass.

Red controls, all four observed:

| Mutation | Result |
|---|---|
| turn stamp removed | FAIL: turn 2 / turn 3 not attributed |
| seat never persisted to the transcript | FAIL: join echo, SEATS header, turn attribution |
| separators not scrubbed | FAIL: parsed as `Evil\|agent9=Fake\|m` — truncated and cross-contaminated |
| closed discussions rewritten | FAIL: a join mutated a closed discussion |

Disclosed weakness, already corrected: the separator control initially passed either way.
Unscrubbed separators do **not** forge an extra seat — the parser still yields exactly two — so
the roster assertion was decorative. It now asserts the affected seat's own parsed round-trip.

### Questions for the reviewer

Read the files on disk, not this summary.

1. **Does `join` writing to the transcript break an invariant?** It was previously read-only and
   `SKILL.md` said so. Is guarding on `STATUS: Closed` sufficient, or are there other states
   (superseded, legacy `relay-system/` discussions, a concurrent turn in flight) where this write
   is unsafe? Note `gh233-agent-chorus-concurrency.sh` covers concurrent access.

2. **Is the `SEATS:` field safe against every value a participant can pass?** `_seat_scrub`
   handles `|`, `;`, `=` and whitespace/newlines. What input still corrupts the header, forges a
   seat, or survives into another seat's fields?

3. **`parse_seats` must never raise** — it runs on every turn. Does any header content make it
   throw, or silently mis-attribute a turn to the wrong seat?

4. **Turn-body stamping vs. the parsers.** The stamp is inside the turn body, not the heading, to
   avoid disturbing `TURN_HEADING_RE`, `PASTED_HEADING_RE` and the turn-splitting regex. Does the
   inserted line break `strip_pasted_turn_heading`, citation verification, close-report counting,
   or any consumer that reads turn bodies (e.g. `message_bytes` / `line_count` telemetry)?

5. **Is the stamp actually load-bearing?** Would a reader six months on be able to attribute a
   turn from what is written, and does the `identity unrecorded` path push toward fixing it rather
   than being ignored?

6. **Scope discipline.** Anything here a second system rather than an extension of the existing
   header/turn seam? Anything out of scope for #524?

---

## ▶ TAKE YOUR TURN

You are the **reviewer**. Read `skills/agent-chorus/scripts/agent_chorus.py`,
`skills/agent-chorus/SKILL.md` and the new block in `test/agent-chorus.sh` at HEAD. Cite file:line
for every finding. Rank each Blocking / Should-fix / Low. Append your review, set STATUS, hand back.

Please also state your own lab, model and effort level at the top of your review — that is the
capability under test, and this thread should demonstrate it.
