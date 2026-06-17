# XYZ - Multi-Agent Coordination Beta

This repo is a coordination spike for running Claude Code, Codex, and Gemini on
the same codebase without colliding. The core primitive is `tick`, a tiny local
event-log CLI; the main product surface built on top of it is
`relay-automation/`.

## Current status

- `validate.sh` is green at **23 / 23**.
- The relay automation stack is the main active surface in this repo.
- The repo is still a working beta, not a polished product.

## Start here

If you care about the automated relay system, start in `relay-automation/`:

1. [relay-automation/README.md](relay-automation/README.md) — canonical operator contract and current behavior.
2. [relay-automation/QUICKSTART.md](relay-automation/QUICKSTART.md) — fresh-device bring-up for the current headless Codex path.
3. [PROJECT/2-WORKING/AUTOMATED-RELAY.md](PROJECT/2-WORKING/AUTOMATED-RELAY.md) — project hub and current status across phases.
4. [PROJECT/2-WORKING/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md](PROJECT/2-WORKING/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md) — canonical phase plan and QA checklists.

## Repo map

- `relay-automation/` — scripts and operator docs for poll-driven relays, watchdogs, headless turn-takers, and consult.
- `skill/relay-automation/` — packaged sibling skill surface.
- `relay-system/` — relay transcripts, reviews, and dogfood runs.
- `PROJECT/2-WORKING/` — active project docs and working plans.
- `bin/tick`, `src/`, `test/` — the `tick` coordination kernel and its test suite.

## What `tick` is

`tick` coordinates agents through a shared local event log under `.tick/events/`.
Claims are serialized by an `O_EXCL` lock, and projection folds events into
`.tick/STATE.md`. Coordination is local-transport only: no per-event push/fetch,
no remote dependency, one shared `.tick/` directory per active run.

If you are here for the kernel rather than the relay layer, the implementation
lives in [bin/tick](bin/tick), [src/](src), and [test/](test).

## Run the suite

```bash
./validate.sh
```

For observed real-agent behavior and decision history, see
[REAL-AGENT-OBSERVATIONS.md](REAL-AGENT-OBSERVATIONS.md),
[RECAP.md](RECAP.md), and [CHANGELOG.md](CHANGELOG.md).
