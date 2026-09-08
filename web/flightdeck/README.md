# Flightdeck HTML app

Run from the repository root:

```bash
python3 -m src.flightdeck.server
```

Open <http://127.0.0.1:8768/flightdeck/>. The server binds to loopback only and
refreshes no source. The browser reads a new passive snapshot every 150 seconds.

The static registry contains five independent connectors: `rebalance`, `clio`,
`git_pulse`, `topology`, and `continuity`. Defaults discover the canonical local
Rebalance database, `~/.claude/prompt-log.jsonl`, and `~/git-pulse-sync`. Topology
and continuity stay unavailable until their existing producers persist versioned
JSON and the paths are configured.

Optional environment variables:

| Variable | Meaning |
|---|---|
| `FLIGHTDECK_PORT` | Loopback port; default `8768` |
| `FLIGHTDECK_CONNECTORS` | Comma-separated enabled connector IDs; empty means none |
| `FLIGHTDECK_REBALANCE_DB` | Rebalance SQLite path |
| `FLIGHTDECK_CLIO_JSONL` | CLIO-compatible prompt JSONL path |
| `FLIGHTDECK_GIT_PULSE_DIR` | Git Pulse sync root |
| `FLIGHTDECK_TOPOLOGY_JSON` | Existing scanner's versioned topology snapshot |
| `FLIGHTDECK_CONTINUITY_JSON` | Existing producer's versioned milestone/handoff snapshot |
| `FLIGHTDECK_CONFIG` | Optional JSON file containing the same lowercase path keys and `connectors` array |

The connector protocol is intentionally static: add one module reader and one
`REGISTRY` entry. Connectors parse and attribute; aggregation owns identity,
deduplication, progress, coverage, and PR readiness.

Regenerate or verify design tokens:

```bash
python3 -m src.flightdeck.tokens
python3 -m src.flightdeck.tokens --check
```

The production app supports overview (A), repository focus (B), issue focus (C),
spotlight dimming, Escape one-level navigation, swipe/drag, a copyable handoff,
6 PM wrap-up countdown, and system/dark/light appearance. Reference mockups under
`docs/mockups/flight-dashboard/` remain unchanged.
