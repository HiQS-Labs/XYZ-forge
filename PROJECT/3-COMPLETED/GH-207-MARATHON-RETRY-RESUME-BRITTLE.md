---
gh_issue: 207
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/207
title: "Marathon retry/resume is brittle against pre-existing lane state: cross-marathon lane-id collision + no-progress HALT on an already-complete lane"
status: Closed — built 2026-07-15 on marathon branch (agy-reviewed, Approved, gate green)
created: 2026-07-15
updated: 2026-07-15
owner: noel
doc_type: bug
complexity: 4
risk: 3
effort: 4
phases: 1
ratings_provisional: true
non_goals:
  - Not removing the attempt-cap (GH-45 queue-commitment) — only namespacing its key so caps apply per marathon, not per bare lane id.
  - Not building generic checkpoint/resume; only the three observed brittleness modes.
related:
  - relay-automation/marathon-drive.sh
  - relay-automation/marathon.sh
  - relay-automation/relay-drive.sh
  - relay-automation/relay-turn-lib.sh
goal: >
  Make marathon retry/resume tolerate pre-existing lane state: namespace per-lane attempt/render
  state by marathon name so plan-local ids (p1, p2) never collide across marathons, and treat
  "artifact already present + gate green + reviewer approves" as lane-satisfied instead of
  no-progress escalation, so depends_on chains can advance past already-done lanes.
---

## Status

| What was just completed | What's next |
|---|---|
| Lane `gh207-retry-resume` BUILT 2026-07-15 on the marathon branch: `MARATHON_LANE_NS` namespacing (bare-id fallback kept), idempotent re-render commit, gated `no-progress` recovery (artifact present + green gate + builder-stalled → one reviewer round, complete on approval), `LANE_ATTEMPT_COUNTED` leak cleared. agy r1 first tripped the #183 isolation-breach false-positive (clean on retry), then caught a real same-second `save_transcript` `set -e` crash; codex fixed, agy r2 Approved; gate 162 assertions green. | Merge via the marathon branch PR. The run itself hit #207 mode 1 live before the fix: a stray `phases/p1` render from another invocation landed mid-marathon (see [#209](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/209)). |

## Problem (confirmed in code + observed live)

Three retry/resume brittleness modes, all rooted in the harness assuming a lane starts from empty
state (sleuth-app 2-lane marathon, 2026-07-15, vendored `.xyz/` at `4e12133`):

1. **Cross-marathon lane-id collision.** `marathon-drive.sh:77` keys attempt state as
   `.tick/attempts/<lane-key>` from the bare plan-local id (`p1`), a per-repo shared namespace; the
   committed `phases/<id>/RELAY.md` render is keyed the same way. A new marathon's `p1` inherited a
   stale attempt fire from a different marathon 9 days earlier and PARKED at the attempt-cap (exit
   8) before its builder ever ran. `--retry --force` then HALTed on an empty commit: the re-render
   was byte-identical to the parked attempt's committed render → `nothing to commit` → exit 1. Only
   renaming lanes to globally-unique ids worked around it.
2. **No-progress HALT on an already-complete lane.** With the artifact already built, committed, and
   gate-green (from an earlier capped attempt), the builder correctly produced no diff and
   `relay-drive.sh` escalated `no-progress` (exit 3). There is no way to advance a lane whose work
   already exists, so a `depends_on` chain can never reach later lanes.
3. **(Minor) spurious `dependency.drift`** — 0-line "changes" reported on the harness's own files
   (`relay-turn-lib.sh`, `src/project.js`, `src/events.js`) every builder turn, from worktree-diff
   noise. Cosmetic but misleading.

## Ask / Definition of done

- [ ] Namespace lane state by marathon: attempt files and phase renders keyed by
      `<marathon-name>--<lane-id>` (introduce a `MARATHON_LANE_NS` key in `marathon-drive.sh`;
      `marathon.sh` passes the plan name through). Same-named lanes in different plans never share
      attempts/renders.
- [ ] Make the relay-render commit idempotent: a byte-identical re-render skips the commit instead
      of erroring the retry.
- [ ] Add an already-satisfied path: when the lane's artifact exists and the pre-advance gate passes,
      a no-diff builder turn routes to the reviewer; on approval the lane is marked satisfied
      (`lane_already_satisfied`) and the chain advances to dependents — no `no-progress` escalation.
- [ ] Suppress `dependency.drift` events for 0-line diffs on harness-owned files in driven worktrees.
- [ ] `test/marathon-drive.sh` covers: two plans sharing a lane id don't share attempt state;
      identical re-render doesn't HALT; pre-built gate-green lane reaches "satisfied" and unblocks
      its dependent.

## Reversibility & blast radius

Medium-high. Touches the attempt-cap keying (GH-45 surface) and the no-progress escalation path in
the drive loop — regressions here can mask genuinely stalled lanes, so the already-satisfied path
must still require a green gate **and** reviewer approval. Namespacing is additive (old bare-key
files simply stop matching); revertible per-commit.

## Provenance

Filed from a live sleuth-app marathon run (2026-07-15) alongside #205 (300s cap) and #206 (vendored
root split); bundled with both for one marathon. Attempt-cap origin: GH-45 queue-commitment
contract; debug-mantra peek: GH-162.

## Swarm Preflight Contract

```json
{"target":{"repo":".","ref":"main"},"gate":"bash validate.sh","fix_probes":[{"type":"grep_absent","path":"relay-automation/marathon-drive.sh","pattern":"MARATHON_LANE_NS"},{"type":"grep_absent","path":"relay-automation/marathon-drive.sh","pattern":"lane_already_satisfied"}],"artifacts":["relay-automation/marathon-drive.sh","relay-automation/marathon.sh","relay-automation/relay-drive.sh","test/marathon-drive.sh","test/marathon.sh"],"remediation":{"source":"self#ask--definition-of-done","criteria":"Marathon-namespaced lane state; idempotent re-render; already-satisfied lane advances its depends_on chain after green gate + reviewer approval; bash validate.sh green."},"lanes":{"orchestrator_only":["relay-automation/relay-turn-lib.sh","bin/",".tick/"]}}
```
