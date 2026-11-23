TITLE: intake: "complete-looking" issues fail preflight (stale contracts) and delivered issues stay open — admission needs a live preflight + delivered-open detector

## Observed (GH-1175 Phase 0 step 1, 2026-10-26, development a3450a2c)
Of 280 open issues, the 5 with row + doc + contract + real rating + plan heuristically present all failed to qualify: #423/#141/#275 `swarm-preflight --dry-run` STALE (exit 4), #1098 AMBIGUOUS (exit 7, no issue Acceptance section), #418 already has PR #1211. #345 is open but its fix landed (test/agent-chorus.sh:617-624); #416 had 2 of 4 items already true and a contract probe already satisfied.

## Proposed remedy (for review)
Feed #522/#1022: the admission scan runs `swarm-preflight --dry-run` per candidate and reports STALE/AMBIGUOUS/delivered-but-open as named holds (`NEEDS-CONTRACT-REFRESH`, `POSSIBLY-DELIVERED`), never writes. No new suites.
