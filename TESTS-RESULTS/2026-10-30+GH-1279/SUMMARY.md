# GH-1279 Stage A: Codex plan-draft decision adapter

- **Date:** 2026-10-30 (`codex-cli 0.166.0`, model `gpt-6.1-sol`, Python 3.14.7, macOS 15.6.1 arm64)
- **Code under test:** `fc93c890a6fb64d86a144480c5250a5fd2da079e`, built by an agy (Gemini 3.8 Flash) lane from the Codex-approved plan; two reviewer nits (`res.rc`, prompt title) were applied by the orchestrator afterwards.
- **Scope:** Stage A only. No Stage B window ran. Nothing here is evidence about eight hours of operation or about plan quality.

## Results

| Check | Result |
|---|---|
| 24 stub-CODEX_BIN controls (`controls-run.txt`, `controls.json`) | 24/24 pass |
| Exact-argv tool probe (`live/exact-argv-probe.*`) | 0 tool items, answer `NO TOOL`; the same request on default flags ran 2 shell commands (`containment-probe/`) |
| Two-arm live smoke (`live/two-arm-smoke.json`) | input digests equal; both arms chose the same two requests; Codex cost held as `unknown`; canaries intact; 2 live calls |
| QA r1 validator crash | old `_validate` raises `TypeError` on 3 shapes; new one rejects them with existing reasons |
| 90-call boundary | 90 held-unknown reservations then `PAUSE`; slot 91 paused with no 91st stub call |
| Empty inbox | zero invocations, `agent_called=False`, reservation released at 0.0 |

## What this does and does not show

- `plan_draft` is a deterministic planner (`_marathon_plan.Engine`). The Codex arm only chooses which eligible request to draft, or idles, so on this backlog it matched oldest-first. The adapter is the safe way to put a model in that seat; it is not evidence a model plans better.
- Token usage is not recorded; cost stays `unknown`, latency is visible only in the driver's tick timing.
- The adapter turns any `item.*` event other than `agent_message`/`reasoning` into `adapter-error`. That fails closed, but a future CLI that adds a benign item type would show up as errors; re-run the exact-argv probe when the CLI version changes.
- The prompt is the positional `codex exec` argument, so it is visible in the local process list for the call's duration.

Provenance: `provenance.jsonl` (five rows: containment probe, agy smoke, controls, exact-argv probe, two-arm smoke) plus the gate row added with the gate log.
