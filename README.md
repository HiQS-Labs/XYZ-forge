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
- `utils/hq/` — **HQ**, the multi-repo command center (`hq.sh` + `hq-lib.sh`); driven by the user-level `/hq` skill in `skills/hq/`. See [HQ — multi-repo command center](#hq--multi-repo-command-center) below.

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

## HQ — multi-repo command center

Where `tick` and the relay coordinate agents **inside one repo**, **HQ** is the operator front door
**across every repo on this device**. It turns a single utterance — *"for project Acme, do X"* — into
governance-aware action: resolve a fuzzy project name to a real repo, report its state, and land the
request on that repo's own PDDA rails. It ships as `utils/hq/hq.sh` and the user-level `/hq` skill.

**Read paths are safe; every write path previews by default and acts only with `--create`.** HQ never
drives a marathon itself — `fire` stops at a gated hand-off you run.

### Install once, then it works from any repo

Claude Code only scans `~/.claude/skills/`, so symlink the skill in once per clone (idempotent):

```bash
bash skills/hq/install.sh      # symlinks this clone's skills/hq into ~/.claude/skills/
bash skills/hq/find-hq.sh --check   # one-glance readiness: hq root, sqlite3, rebalance registry
```

After that, `/hq …` works from a session opened in **any** repo. Standing in this harness clone you
can also call `bash utils/hq/hq.sh …` directly (the forms below use that short form).

### Command surface

| Command | What it does |
|---|---|
| `hq.sh status <project>` | **Project card** — resolved repo + path, capability tier (A/B/C), Rebalance priority, PDDA mode + startup docs, active-doc count, open marathon plan, XYZ install/drift stamps. |
| `hq.sh resolve <project>` | Machine-readable `KEY=value` resolution (`RESOLVED_VIA=exact\|fuzzy`; an ambiguous name returns rc=2 with `CANDIDATES`). |
| `hq.sh registries` | Introspection — what each registry knows and its coverage. |
| `hq.sh next [--limit N]` | **Priority board** — projects ranked by Rebalance `priority_tier` with each one's HQ capability tier. Read-only. |
| `hq.sh park [--create] [--title T] <project> <req…>` | **Issue-first intake** in the target repo: GH issue → `PROJECT/1-INBOX/` capture → ROADMAP parking. Previews unless `--create`. |
| `hq.sh promote [--create] --gh-issue N <project>` | **PDDA `1-INBOX → 2-WORKING`** (GH-138): `git mv GH-N-*.md` + scaffold the moved doc so it satisfies the enforced 2-WORKING contract (leaves ratings/QA gates as operator TODOs). Previews unless `--create`. |
| `hq.sh queue [--create] [--gh-issue N] <project> <req…>` | Append an **HQ-queued lane** to the target's newest `MARATHON-*.md` plan (non-destructive). Previews unless `--create`. |
| `hq.sh fire --gh-issue N [--risk 1-5] <project>` | **Gated prepare-and-hand-off** — resolves, gates (Tier A, `risk < 3`), and emits the `swarm-preflight` command for the operator to run. Never drives the harness (GUIDING-PRINCIPLES §8). |

The intake-to-dispatch pipeline is **`park → promote → queue → fire`** — capture on the rails, promote
into active work, queue a marathon lane, then hand off. Each step previews first.

### How a name becomes a repo (resolution ladder)

1. **Rebalance `project_registry`** (`rebalance-OS/rebalance.db`) — semantic catalog: NAME → repos + priority. No path.
2. **XYZ install registry** (`~/.config/xyz/registry.tsv`) — repo → absolute path + drift stamps (the path resolver).
3. **Git Pulse PDDA registry** (`~/git-pulse-sync/pdda/registry-<device>.tsv`) — repo → PDDA mode + startup docs, cross-device.
4. **Filesystem `find`** — fallback when no registry knows the path.

**Capability tiers:** **A** = PDDA + XYZ install → dispatch-eligible · **B** = PDDA only → intake only ·
**C** = bare repo → plain issue only (offer a PDDA install). Test/non-default overrides:
`HQ_PDDA_REGISTRY_DIR`, `HQ_XYZ_REGISTRY`, `HQ_REBALANCE_DB`, `HQ_SEARCH_ROOTS` (see `utils/hq/hq-lib.sh`).

Full agent-facing detail — invocation flow, guardrails, and the locator contract — lives in the skill:
[skills/hq/SKILL.md](skills/hq/SKILL.md). Tracks [GH-128](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/128).

---

For observed real-agent behavior and decision history, see
[REAL-AGENT-OBSERVATIONS.md](PROJECT/4-MISC/REAL-AGENT-OBSERVATIONS.md) and
[CHANGELOG.md](CHANGELOG.md) — the running end-of-iteration log. (`RECAP.md` is retired in `PROJECT/4-MISC/`.)
