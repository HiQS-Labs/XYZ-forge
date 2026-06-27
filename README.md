# XYZ - Multi-Agent Coordination Beta

This repo is a coordination spike for running Claude Code, Codex, and agy (Antigravity CLI) on
the same codebase without colliding. The core primitive is `tick`, a tiny local
event-log CLI; the main product surface built on top of it is
`relay-automation/`.

> 👉 **New here?** Read [ROUTER.md](ROUTER.md) for the repo's startup order, then run `./validate.sh` — it should print **47 / 47**
> green in a minute, no accounts or API keys required. That's the fastest proof the kernel
> works. The live relay product (Codex/agy turns) needs per-CLI auth — see "Start here" below.

## Current status

- `validate.sh` is green at **47 / 47**.
- The relay automation stack is the main active surface in this repo.
- **Marathon** (`relay-automation/marathon.sh`) chains multiple headless build→review phases from a
  `MARATHON.yaml`, in `depends_on` order — the multi-agent coordinator built on top of the relay loop.
- The repo is still a working beta, not a polished product.

## Start here

If you care about the automated relay system, start with the repo router, then go into `relay-automation/`:

1. [ROUTER.md](ROUTER.md) — repo startup order, canonical entry points, and command rails.
2. [relay-automation/README.md](relay-automation/README.md) — canonical operator contract, including the headless bring-up paths for Codex and agy.
3. [PROJECT/2-WORKING/AUTOMATED-RELAY.md](PROJECT/2-WORKING/AUTOMATED-RELAY.md) — project hub and current status across phases.
4. [PROJECT/2-WORKING/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md](PROJECT/2-WORKING/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md) — canonical phase plan and QA checklists.

## Repo map

- `relay-automation/` — scripts and operator docs for poll-driven relays, watchdogs, headless turn-takers, and consult.
- `skills/` — packaged skill surfaces, including `relay-xyz`, `relay-automation`, `xyz`, and consult helpers.
- `relay-system/` — relay transcripts, reviews, and dogfood runs.
- `PROJECT/2-WORKING/` — active project docs and working plans.
- `bin/tick`, `src/`, `test/` — the `tick` coordination kernel and its test suite.
- `utils/swarm-preflight.sh` — marathon intake planner: turns a project doc or a GH-issue bundle into a marathon-ready run packet (freshness + fix-still-required checks, readiness gate, Codex/agy lane plan). Run `utils/swarm-preflight.sh --help`; see [GH-25-SWARM-PREFLIGHT-PLANNER.md](PROJECT/2-WORKING/GH-25-SWARM-PREFLIGHT-PLANNER.md).

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
[REAL-AGENT-OBSERVATIONS.md](REAL-AGENT-OBSERVATIONS.md) and
[CHANGELOG.md](CHANGELOG.md) — the running end-of-iteration log. (`RECAP.md` is retired in `PROJECT/4-MISC/`.)
