---
name: xyz
description: >-
  Coordinate two (or more) AI coding agents working CONCURRENTLY on
  non-overlapping, path-scoped lanes of ONE shared repo, via the `tick` CLI —
  for parallel builds and parallel codebase recon, with collision-free claims,
  liveness heartbeats, and an honest concurrency metric. Use when the user wants
  to "run two agents in parallel", "split this build across agents", "have
  agents recon/profile the codebase concurrently", or "coordinate Codex +
  Gemini on the same repo". NOT for work that touches shared files, needs
  constant cross-agent handoff, or runs across separate clones / async sessions.
---

# xyz — multi-agent coordination via `tick`

> **Concise skill entry point.** The exhaustive manual — the self-extracting
> runtime installer, the full embedded test suite, and the complete use-case
> prompts/templates — lives in [`MANUAL.md`](./MANUAL.md) in this directory.
> This file keeps the triggers, scope, rails, and routing; anything long-form
> is a link away, not duplicated here.

## When to use this skill

Triggers (echoing the frontmatter): "run two agents in parallel", "split this
build across agents", "have agents recon/profile the codebase concurrently",
"coordinate Codex + Gemini on the same repo".

Use `xyz` only when ALL of these hold:

- **Partitionable into non-overlapping path globs.** Each task owns a lane
  (e.g. `src/http/**` vs `src/store/**`); agents never touch each other's lane.
- **Shared working tree, single session.** Both agents operate on ONE checkout
  with ONE `.tick/` directory, at the same time.
- **Balanced lanes** of comparable effort, each with its own acceptance check
  (a test, a build, a lint). No shared mutable files (single lockfile, etc.).

NOT for: same-file edits; separate clones / distributed / async or overnight
work (the soft-mutex reopens and the metric becomes uninterpretable);
tightly-coupled work needing constant handoff; >2 agents (unvalidated at
scale). If the work doesn't partition into clean lanes, this is the wrong tool.

## What `tick` is

A tiny, dependency-free Node CLI backed by an append-only event log in
`.tick/events/` (one JSON object per `.jsonl` file). Agents coordinate by
**claiming** path-scoped lanes before editing, **heartbeating** while working,
and marking **done**. No server, no git transport — just a shared local
directory both agents can read and append.

Core verbs: `take` (atomic claim of the next available lane), `ping` (liveness
heartbeat), `done` / `release` / `break` / `scope`, `analyze` (metrics +
parked-claim detection), `project` / `info` (read state).

## Install — routing

The runtime and the test suite ship as two **self-extracting** installer
blocks, embedded verbatim in the manual:

1. **Runtime (CLI + engine):** [`MANUAL.md` §4](./MANUAL.md) — copy the fenced
   block into `install.sh`, run `bash install.sh [DIR]` (default `DIR=xyz-tick`).
2. **Test suite (`validate.sh` + `test/`):** [`MANUAL.md` §4b](./MANUAL.md) —
   extract into the SAME `DIR`, then `bash validate.sh` → **12/12** confirms
   the extract is byte-exact.

Point `tick` at the repo you're coordinating via `TICK_REPO_ROOT` (or run it
from inside that repo — it uses `git rev-parse --show-toplevel`).

**Extraction rail (GH-94):** write the raw fenced content to a file, then run
`bash install.sh`. The heredoc delimiters are single-quoted, so a byte-exact
file write reproduces every `!`/`!==` intact. Do NOT route the block through a
`bash -c "…"` wrapper or any history-expansion / double-quote escaping layer —
that corrupts the extracted JS before the (quoted) heredoc ever sees it.

## The xyz mantra (anti-assumption discipline)

Parallel agents fail in two ways: they **collide** (edit outside their lane)
or they **hallucinate** (assert things about code they didn't verify). Both
are assumption failures. Every agent prompt opens with this block, recited
verbatim before acting:

```
XYZ MANTRA — recite before every action
1. VERIFY, DON'T ASSUME.  Run `tick info <TASK-ID>` to confirm your lane's
   exact paths. Never infer paths, file locations, or task scope from memory.
2. TRACE THE REAL PATH.  Every claim about the code cites file:line you have
   actually read. Filenames and intuition are not evidence.
3. FALSIFY YOUR HYPOTHESIS.  State each assumption and try to DISPROVE it
   against the source before recording it as fact. Default to "unverified".
4. STAY IN YOUR LANE / CODE TO THE CONTRACT.  Never read the other agent's
   source to guess an interface — code against the declared contract. If
   evidence conflicts, FLAG it; do not paper over it.
```

The coordinator enforces it: any finding without a `file:line` citation, or any
edit outside a claimed lane, is rejected in the wrap-up.

## Use-case A — Parallel build (routing)

Coordinator: `tick init` (add `.tick/` to `.gitignore`), seed one task per
lane with `tick log task.created <ID> --agent dispatcher --priority N
--paths "<glob>,<glob>"` (non-overlapping, balanced), confirm prerequisites
green, paste the agent prompt into each agent's window.

Agent loop (after the mantra): `tick take --agent <you>` → work ONLY inside
the claimed paths → `tick ping <TASK-ID>` every few minutes → run the task's
acceptance check → commit your exact files → `tick done <TASK-ID>` → repeat.

**Initiative bound:** implement the *thinnest* change that makes the stated
acceptance pass; no behavior beyond the acceptance unless the task says so.

Full setup steps, agent prompt, and wrap-up: [`MANUAL.md` §5](./MANUAL.md).

## Use-case B — Research & recon (routing)

Profile a codebase in parallel: each agent owns a different area, reads it
**read-only**, and writes a structured profile into its own lane (lane = the
area's source PLUS its own output file, so no two agents write the same
profile). Naturally balanced — a better fit for the ≥50% bar than build.

Full lane-seeding example, recon agent prompt, and the profile template:
[`MANUAL.md` §6](./MANUAL.md).

## Coordinator workflow (rails)

**Monitor, don't micromanage:** `tick project` / `tick analyze`. Default to NOT
intervening. Intervene only on: a file collision (inspect `git diff` by hand —
`tick analyze` does NOT detect collisions), an agent silent >15 min while
holding a claim (`tick reap <agent> --by coordinator`), or drift outside a lane.

**Wrap-up gates** (full procedure: [`MANUAL.md` §7](./MANUAL.md)):

1. **Parked-claim check:** `tick analyze` → any `parked-claim suspect`
   **disqualifies** the run.
2. **Concurrent-claim metric (work-bounded):** recompute over **first
   `task.claimed` → last `task.done`** (the printed % uses the wrong window).
   **Pass = ≥50%**, AND each agent ≥2 done.
3. **Serial double-claim check:** no agent held two overlapping-path claims at
   once (verify the log even though `take` prevents it).
4. **Cross-check:** confirm via `git diff` / passing tests that overlapping
   claim windows = overlapping REAL edits. The metric is necessary, not
   sufficient.
5. Record results + an honest **graduate / iterate / abandon** call.

## Success metric & honest caveats

- **Pass:** work-bounded concurrent-claim ≥50%, both agents ≥2 done, zero
  parked suspects, zero serial double-claims, cross-check confirms real overlap.
- **50% is a stress bar, not a proof bar** — it shows the protocol *can*
  sustain parallelism in this setup, not that it's production-ready.
- **Parked-claim is an OPERATIONAL CONTRACT, not inference.** It relies on
  agents calling `tick ping`; a missing heartbeat is indistinguishable from a
  parked claim → **fail/retry the run, never silently treat it as a pass.**
- **`take` atomicity is shared-lock/shared-tree specific** — do not generalize
  to separate clones or non-shared transports.

## Limits (carried from Runs 1–3)

- Sustained parallelism needs **balanced lanes** (no work-stealing across
  lanes; an imbalanced split idles the fast agent and sinks the metric).
- Coarse, path-scoped lanes only — per-file drift within a lane is not detected.
- ≤2 agents validated; same-session, shared tree only.
- No drift/collision auto-detection — the coordinator inspects `git diff` by hand.

## Where everything lives

| Topic | Location |
| --- | --- |
| Self-extracting runtime installer | [`MANUAL.md` §4](./MANUAL.md) |
| Embedded test suite installer (12 acceptance tests) | [`MANUAL.md` §4b](./MANUAL.md) |
| Use-case A — full parallel-build setup + agent prompt | [`MANUAL.md` §5](./MANUAL.md) |
| Use-case B — full recon workflow + profile template | [`MANUAL.md` §6](./MANUAL.md) |
| Coordinator wrap-up, step by step | [`MANUAL.md` §7](./MANUAL.md) |
| Metric details, caveats, limits | [`MANUAL.md` §8–§9](./MANUAL.md) |
| Provenance (Trinity Runs 1–3, review threads) | [`MANUAL.md` §10](./MANUAL.md) |

Built from the Trinity experiment (Runs 1–3). Both installer blocks are
embedded verbatim in the manual; extract both into the same `DIR` and run
`bash validate.sh` → **12/12** to confirm the extract is byte-exact.
