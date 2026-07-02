# XYZ — Multi-Agent Coordination Beta

XYZ lets several AI coding agents — Claude Code, Codex, and agy (Google's Antigravity CLI) —
work on the **same repo at the same time without overwriting each other's work**. It's built in
two layers:

- **`tick`** — the kernel: a tiny local event-log CLI that hands out collision-free, path-scoped
  work claims, so two agents never edit the same thing at once. No server, no API keys, no remote.
- **`relay-automation/`** — the product on top of `tick`: it runs agents in **turns** (one builds,
  another reviews) headlessly, so you can hand a task to Codex or agy and let them iterate toward
  done without babysitting the handoff.

It's a working beta, not a polished product — but the kernel is test-covered and the relay stack
is the main active surface.

## Quickstart — prove it works (no accounts needed)

Requires **Node 18+** and **git** (the `tick` kernel runs on Node). No accounts or API keys.

```bash
./validate.sh
```

That runs the full kernel + coordination test suite green in about a minute, with **no accounts
or API keys required** — the fastest proof the coordination kernel actually works. The suite
prints its own pass count; if it's green, you're good.

## Then pick your path

- **Run a live relay** — hand a real task to Codex/agy and let them build→review it →
  start at **[relay-automation/README.md](relay-automation/README.md)**. Live turns need each CLI
  authenticated first: see **[Headless bring-up (Codex + agy)](relay-automation/README.md#headless-bring-up-codex--agy)**.
  For phase/status context, the project hub is
  [PROJECT/2-WORKING/AUTOMATED-RELAY.md](PROJECT/2-WORKING/AUTOMATED-RELAY.md).
- **Here for the kernel** — how the `tick` coordination primitive works →
  read [What `tick` is](#what-tick-is), then the source in [bin/tick](bin/tick), [src/](src), [test/](test).
- **Install `tick` into another repo** → see [Install into another repo](#install-into-another-repo).

> **Editing this repo as an agent?** Read [ROUTER.md](ROUTER.md) for the startup order and canonical
> entry points. It's the map for *working on* the repo, not for *using* it — a human landing here
> should start with the Quickstart above.

## Glossary — the four terms you'll hit first

- **`tick`** — the coordination kernel: a shared local event log (`.tick/events/`) that agents
  claim work through, serialized by an `O_EXCL` lock.
- **relay** — a turn-based loop where one agent builds and another reviews, handing off through
  files instead of a human copy-pasting between windows.
- **Marathon** (`relay-automation/marathon.sh`) — chains several relay build→review phases from a
  `MARATHON.yaml`, in `depends_on` order. The multi-agent coordinator built on the relay loop.
- **agy** — the Antigravity CLI (Google), one of the agents XYZ coordinates alongside Claude Code
  and Codex.

## Repo map

- `relay-automation/` — scripts and operator docs for poll-driven relays, watchdogs, headless turn-takers, and consult.
- `skills/` — packaged skill surfaces, including `relay-xyz`, `relay-automation`, `xyz`, and consult helpers.
- `relay-system/` — relay transcripts, reviews, and dogfood runs.
- `PROJECT/2-WORKING/` — active project docs and working plans.
- `bin/tick`, `src/`, `test/` — the `tick` coordination kernel and its test suite.
- `utils/swarm-preflight.sh` — marathon intake planner: turns a project doc or a GH-issue bundle into a marathon-ready run packet (freshness + fix-still-required checks, readiness gate, Codex/agy lane plan). Run `utils/swarm-preflight.sh --help`; see [GH-25-SWARM-PREFLIGHT-PLANNER.md](PROJECT/3-COMPLETED/GH-25-SWARM-PREFLIGHT-PLANNER.md).
- `install.sh` — materializes the `tick` runtime (`bin/tick` + `src/*.js`) into an external repo and records the install in a per-user, machine-local registry (`~/.config/xyz/registry.tsv`). See "Install into another repo" below.

## What `tick` is

`tick` coordinates agents through a shared local event log under `.tick/events/`.
Claims are serialized by an `O_EXCL` lock, and projection folds events into
`.tick/STATE.md`. Coordination is local-transport only: no per-event push/fetch,
no remote dependency, one shared `.tick/` directory per active run.

If you are here for the kernel rather than the relay layer, the implementation
lives in [bin/tick](bin/tick), [src/](src), and [test/](test). Run the full suite with
`./validate.sh`.

## Install into another repo

`install.sh` copies the `tick` runtime into any target directory and records the install:

```bash
./install.sh [target-dir] [--repo <coordinated-repo-path>]
# Example:
./install.sh ../sleuth-app/xyz-tick --repo ../sleuth-app
```

This creates `<target-dir>/bin/tick` and `<target-dir>/src/*.js`, then appends a row to the per-user,
machine-local registry at `~/.config/xyz/registry.tsv` (override with `XYZ_REGISTRY`). The registry
tracks where each copy lives and which source commit it was built from — so a future `tick` version can
be pushed to copies that are behind.

The registry is **never committed** (machine-local only). If [git-pulse](https://github.com/anthropics/git-pulse)
is configured, a path-normalized projection (no absolute paths) is published to its sync repo so install
status rolls up across devices automatically.

Options:
- `--repo <path>` — record the coordinated repo (where `.tick/` lives) in the registry entry.
- `--no-register` — skip the registry write entirely (also skips git-pulse projection).

---

For observed real-agent behavior and decision history, see
[REAL-AGENT-OBSERVATIONS.md](PROJECT/4-MISC/REAL-AGENT-OBSERVATIONS.md) and
[CHANGELOG.md](CHANGELOG.md) — the running end-of-iteration log. (`RECAP.md` is retired in `PROJECT/4-MISC/`.)
