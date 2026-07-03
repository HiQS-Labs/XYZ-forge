---
gh_issue: 88
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/88
title: Cross-repo marathon monitor v1.0 — read-only fzf TUI over existing primitives
status: Queued
created: 2026-07-02
updated: 2026-07-02
owner: noel
doc_type: enhancement
complexity: 2
risk: 1
effort: 2
roadmap_exempt: false
non_goals:
  - Cross-repo launching — stays `cd repo && marathon.sh`; candidate for v1.1, not v1.0
  - Between-phase lock-blink smoothing — last tick event disambiguates; noted, not fixed
  - Cross-machine aggregation — single machine, single registry
related:
  - relay-automation/marathon-drive.sh
  - relay-automation/xyz-sync.sh
  - utils/marathon-plan.sh
---

# GH-88 — cross-repo marathon monitor v1.0

## Problem

No way to see, machine-wide, which marathon/relay sessions are running across repos. Discovery is
manual (`git log relay-system/`, poking `phases/*/RELAY.md`). With the per-repo vendor system
(`.xyz/` installs tracked in `~/.config/xyz/registry.tsv`), marathons run in many repos at once —
the operator is blind on cross-repo activity.

## Approach (ponytail — read-only viewer, reuse everything)

A durable, stateless cross-repo **monitor**. Writes **no new state** — it is a join over primitives
that already exist. Launching stays manual (deferred to v1.1).

Reused primitives:

- **Discovery** — `~/.config/xyz/registry.tsv` col 5 (`coordinated_repo`) lists every repo with the
  harness; prepend the hub repo.
- **Liveness** — `.git/relay-driver.lock` (clone) or `.relay-driver.lock` (vendored `.xyz/`): a dir
  holding a `pid` file with GH-42 stale semantics. `kill -0 $pid` ⇒ LIVE/STALE.
- **Status detail** — newest `.tick/events/*marathon*.jsonl` event + `phases/<id>/RELAY.md`
  `STATUS:`/`NEXT:`.

## Deliverable — three read-only scripts in `relay-automation/` + one dep

1. `marathon-ls.sh` — engine: `[hub] + registry col5` → resolve lock path → `kill -0 pid` → tail
   newest marathon tick event → one TSV row/repo.
2. `marathon-detail.sh <repo>` — preview: `STATUS:`/`NEXT:` + last ~10 tick events for that repo.
3. `marathon-tui.sh` — fzf shell: `marathon-ls.sh` → fzf 2s `reload-sync` + `--preview marathon-detail.sh {1}`.

Dependency: `brew install fzf` (one-time; interactive TUI chosen over zero-dep table).

Row states (derived, never stored): `LIVE` · `STALE` · `IDLE` · `GONE`.

Lock-path branch: `$repo/.git/relay-driver.lock` for clones, `$repo/.relay-driver.lock` for
vendored `.xyz/` dirs without `.git/`.

## Zone / lane

Independent leaf-util zone (new `relay-automation/marathon-*.sh` viewer scripts + a test). Read-only,
touches no kernel drive scripts — agy-safe, parallel-safe.

## Definition of done

- `marathon-tui.sh` shows every registered repo's marathon state live, LIVE/STALE/IDLE/GONE correct.
- Selecting a row previews that session's live RELAY.md status + recent tick events.
- The monitor writes no new files to any monitored repo.
