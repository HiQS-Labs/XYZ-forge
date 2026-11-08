# Plan draft: #1254 Outer loop (#1248): borrow declared supervision and cache-warmth dispatch from clodex

> draft; preflight and independent plan QA outstanding

- Request: `gh-1254-75df3b36eedb` (tick `slot_060`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: 75df3b36eedb334ee6e9cb6dce1960372ade244bbbdd6dedb5f71dfd9ff8cec2 (updated 2026-10-29T21:26:33Z)
- Dependencies: none

## Scope

_Source: codex-authored (codex-authored)_

Verify the current outer-loop tick, watchdog, launchd configuration, adapter telemetry, and dispatch behavior before planning changes.

_Source: codex-authored (codex-authored)_

Plan declared supervision and cache-warmth-aware dispatch without adding a Clodex dependency or changing Jog or Marathon dispatch.

## Acceptance criteria

_Source: codex-authored (codex-authored)_

Self-restart requires an explicit supervision declaration; an undeclared restart is refused with a visible reason in the receipt.

_Source: codex-authored (codex-authored)_

Generated launchd configurations declare supervision, and their restart policy and declaration are checked together.

_Source: codex-authored (codex-authored)_

Adapter telemetry records cache-read and cache-creation tokens, using explicit null when unavailable; the run manifest records the cache TTL.

_Source: codex-authored (codex-authored)_

Cold non-urgent items are logged as deferred and run by their deadline; urgent items run immediately.

_Source: codex-authored (codex-authored)_

The soak report compares cost with and without deferral for the same scenario, and manual checks are recorded under TESTS-RESULTS without a new suite.

## Open questions

_Source: codex-authored (codex-authored)_

What are the current implementation and status of issue #1248 and its dependencies?

_Source: codex-authored (codex-authored)_

What cache TTL and maximum deferral slots should be used, and how will comparable costs be calculated when token data is unavailable?

## Write set

- `utils/py/harness.py` (issue#1254:L7)

## Unresolved file names

- none

## Contract probes

- none
