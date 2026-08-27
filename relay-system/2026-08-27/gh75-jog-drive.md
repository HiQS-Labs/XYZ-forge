# RELAY · GH-75 Jog Serial Drive

NEXT: jog
STATUS: Open
ROUND: 1 / 2

## Setup
- Issue: GH-75
- Builder: agy
- Started: 2026-08-27

## Log

### Round 1 — Producer (jog) — 2026-08-27
Dispatched task GH-75 for execution.

NEXT: agy
### Round 1 — Implementation (agy) — 2026-08-27
Implemented `dashboard` command in `releases_app.py` directly generating a standalone HTML dashboard with BOTH panels (releases and roadmap items) and the trust header including staleness checking.
Created `test/gh75-dashboard.sh` testing read-only invariants and empty state.
Registered test in `validate.sh`.

NEXT: jog
