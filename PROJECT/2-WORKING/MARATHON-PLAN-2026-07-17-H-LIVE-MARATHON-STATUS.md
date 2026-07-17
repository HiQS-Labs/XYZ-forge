---
title: Marathon Plan H (2026-07-17) — cross-repo live marathon status query (GH-218)
status: Both phases fireable, contract verified ready via --dry-run
created: 2026-07-17
updated: 2026-07-17
owner: noel
branch: development
doc_type: project
source: captured via /idea 2026-07-17 in response to an operator question mid-session ("can you
  read all marathons happening now, in realtime?")
generated_by: hand-authored (single feature, 2 sequential phases, same-day)
lanes: [218]
execution: sequential (Phase 2 embeds Phase 1's output) — a codex/agy relay via marathon-drive.sh
  or a single Sonnet subagent, one invocation per phase
roadmap_exempt: true
goal: >
  One new read-only script (utils/hq/marathon-live.sh) plus a small rollup.sh hook, both composing
  entirely existing primitives (hq_known_repos/registry.tsv, tick project's own derived STATE.md,
  rollup.sh's embed mechanism) — no per-repo MCP servers, no new Obsidian writer, no new discovery
  mechanism. See GH-218's own doc for the full ponytail-lens rationale.
---

# Marathon Plan H — 2026-07-17 · cross-repo live marathon status query

> Single feature (GH-218), 2 sequential phases — Phase 2 depends on Phase 1's script existing to
> embed its report. Both phases are read-only over every OTHER known repo; the only write in
> either phase is to this hub repo's own `utils/hq/*.sh` and `test/*.sh`.

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-07-17 via `/idea` (GH-218), promoted to `2-WORKING`, 2-phase `MARATHON.yaml` + briefs built under `MARATHON-2026-07-17-GH218-LIVE-STATUS/`. Contract verified ready via `swarm-preflight.sh --gh-issue 218 --dry-run`. | Fire the marathon: Phase 1 (`marathon-live.sh`), then Phase 2 (`rollup.sh` hook). |

## Why this shape, why now

The operator asked mid-session whether marathons running on the machine could be read in realtime.
Answering required 4 manual, ad-hoc checks (`ps aux`, `git worktree list`, a driver-lock peek,
`marathon-scan.sh`'s doc-status scan) — and even then the doc-status scan couldn't see an actively
running marathon in sibling worktrees, since it only reads `MARATHON-PLAN-*.md` frontmatter, not
live process/tick state. This plan closes that gap with the smallest addition that composes with
what already exists, per `/ponytail`: `tick project` already derives exactly the live state needed
(`.tick/STATE.md`'s `## Claimed` section) from each repo's own local event log — nothing to build
there. The only real gap is enumerating + querying + formatting across repos, which is what
Phase 1 does.

## Collision map

| Zone (shared file) | Parallel-safe? | Phase |
|---|---|---|
| `utils/hq/marathon-live.sh` (new) + `test/hq-marathon-live.sh` (new) | ✅ only this phase touches these (new files) | Phase 1 |
| `utils/hq/rollup.sh` + `test/hq-rollup.sh` | ✅ only this phase touches these, and only after Phase 1 lands | Phase 2 |

No collision with any other active marathon plan (Plan F, Plan G) — different files entirely.

## Per-phase summary

| # | Deliverable | File(s) | cx/risk/eff | Fireable? |
|---|---|---|---|---|
| 1 | `marathon-live.sh`: enumerate known repos, query each's `tick project` state, cross-check driver lock + worktree activity, emit one table | `utils/hq/marathon-live.sh`, `test/hq-marathon-live.sh` | 3/1/2 | ✅ ready |
| 2 | `rollup.sh` hook: embed Phase 1's report as a new Obsidian section | `utils/hq/rollup.sh`, `test/hq-rollup.sh` | 1/1/1 | ✅ ready (after Phase 1) |

Full scope, rationale, and the explicit "why not an MCP server" reasoning lives in
[GH-218's doc](GH-218-CROSS-REPO-LIVE-MARATHON-STATUS.md) — read it before starting either phase.

## Execution contract

- **Path:** each phase runs as a worktree-isolated Sonnet subagent or a codex/agy relay via
  `marathon-drive.sh`, scoped via `ALLOW_PATHS`/artifact allowlist to its own files.
- **Phase 1** — reuse `hq_known_repos`/`hq_repo_resolve` verbatim (no new discovery code); reuse
  `tick project`'s existing derived state (no new event-log parsing); do not build a server, a
  daemon, or an MCP interface of any kind — this is explicitly out of scope (see GH-218 Non-goals).
- **Phase 2** — reuse `rollup.sh`'s existing embed-verbatim mechanism (the same one that already
  embeds `marathon-scan.sh`'s report per GH-192); do not write a second Obsidian I/O path.

## How to fire

```
utils/swarm-preflight.sh --gh-issue 218 --dry-run   # ready (exit 0)
relay-automation/marathon.sh --plan PROJECT/2-WORKING/MARATHON-2026-07-17-GH218-LIVE-STATUS/MARATHON.yaml
```

After both phases land: run the new `marathon-live.sh` against this machine's real registry and
confirm it correctly reports the state of any marathon actually running at the time (cross-check
by hand once, same discipline as every other marathon in this repo), then full `bash validate.sh`.
