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

## Manual experimental harness

This harness is intentionally absent from `validate.sh`, CI workflows, and the
CI route registry. Run it only when debugging Flightdeck:

```bash
python3 -m src.flightdeck.manual_harness --check
python3 -m src.flightdeck.manual_harness
```

The second command serves the real UI at <http://127.0.0.1:8770/flightdeck/>
using temporary fixtures for all five connectors. Python 3 and Node.js are required;
there are no npm dependencies. Checks use a fixed clock and exercise the real HTTP
snapshot and production JavaScript selector. Cases cover continuous sessions older
than two hours, interleaved prompts, issue/PR URLs, multiple issues, topic changes,
stale/future timestamps, closed issues, open PRs carried across days, duplicate
commit evidence, two checkouts, and a milestone. Source-isolated assertions and
negative controls prevent fresh issue records from masking broken attribution.
Fixture bytes must stay unchanged after consumer reads. Interactive preview dates
are reset to the current time after the checks. Press Ctrl-C to remove the fixtures.

Issue cards retain today's observed context (browser local calendar day) and issues
linked to cached open PRs. Each card labels the basis and age; its timeline still
shows only the last hour. Issue titles/closing links associate PR review sessions;
PR title associations are inferred. Known closed issues are excluded. Prompt
follow-ups retain references when consecutive prompts are no more than two hours
apart; explicit new references replace the old topic. These are observed contexts,
not proof an agent process is still running. Existing snapshot limits and partial
source coverage still apply.

Known upstream gap: CLIO's installed Codex tailer can miss the first prompt when
it first discovers a rollout at EOF. Flightdeck does not read raw private rollouts
or backfill missing prompts. See the [visibility Recon Map](../../PROJECT/2-WORKING/recon-flightdeck-issue-visibility.md)
for the evidence and the bounded producer repair still needed.
