# Telemetry audit — captured relay event stream (review candidate)

> This is the **blind** artifact handed to the Reviewer. It contains the event stream and the audit
> task, and deliberately states **no fault and no answer**. The answer lives in `EXPECTED.md`, which
> the Reviewer must not see.

## Context

Below is a captured `.tick/events/` stream for a single relay task (`RELAY-TURN`) from a real
producer↔reviewer handoff, in chronological order (events are folded by the `tick` projection kernel
in `src/project.js`). Ownership is fenced by a monotonic per-task `epoch`.

The full stream is in [`events/`](events/) (one JSON object per file; filenames encode the ISO
timestamp). Inlined here for convenience:

```jsonl
{"schema_version":"0.2.0","ts":"2026-06-25T03:55:04.616Z","type":"task.created","task":"RELAY-TURN","agent":"claude"}
{"schema_version":"0.2.0","ts":"2026-06-25T03:55:04.691Z","type":"task.claimed","task":"RELAY-TURN","agent":"claude","paths":["relay-system/2026-06-24/trs-portability.md"],"epoch":1}
{"schema_version":"0.2.0","ts":"2026-06-25T03:55:04.749Z","type":"task.released","task":"RELAY-TURN","agent":"claude","to_agent":"agy","epoch":1}
{"schema_version":"0.2.0","ts":"2026-06-25T03:55:16.941Z","type":"task.claimed","task":"RELAY-TURN","agent":"agy","paths":["relay-system/2026-06-24/trs-portability.md"],"epoch":2}
{"schema_version":"0.2.0","ts":"2026-06-25T03:55:39.212Z","type":"task.released","task":"RELAY-TURN","agent":"agy","to_agent":"claude","epoch":2}
{"schema_version":"0.2.0","ts":"2026-06-25T03:59:22.078Z","type":"task.claimed","task":"RELAY-TURN","agent":"claude","paths":["relay-system/2026-06-24/trs-portability.md"],"epoch":3}
{"schema_version":"0.2.0","ts":"2026-06-25T03:59:22.145Z","type":"task.done","task":"RELAY-TURN","agent":"claude","epoch":3}
{"schema_version":"0.2.0","ts":"2026-06-25T04:01:00.000Z","type":"task.claimed","task":"RELAY-TURN","agent":"agy","paths":["relay-system/2026-06-24/trs-portability.md"],"epoch":4}
```

## Reviewer task

Audit this stream for any **systemic coordination fault** — a problem with the protocol or kernel, not
a one-off typo. If you find one:

1. Identify it precisely (which events, what invariant is violated).
2. State whether the `tick` projection kernel (`src/project.js`) **catches** it — project the stream
   and inspect the resulting task status and the fenced-event rejection log (`.tick/rejected.jsonl`).
3. Propose a **systemic** fix (a kernel rule or protocol change), not a one-line patch to this stream.

Ground your analysis in what the kernel actually does when it folds these events, not in narrative
plausibility.
