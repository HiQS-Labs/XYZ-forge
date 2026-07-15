---
gh_issue: 205
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/205
title: "Marathon: 300s per-turn wall-clock cap (RELAY_TURN_TIMEOUT_S) too short for real code+test builds → false HALT"
status: built 2026-07-15 on marathon branch (agy-reviewed, Approved, gate green) — PR pending
created: 2026-07-15
updated: 2026-07-15
owner: noel
doc_type: bug
complexity: 3
risk: 3
effort: 3
phases: 1
ratings_provisional: true
non_goals:
  - Not removing the wall-clock cap entirely — a true hang must still be killed (exit 7).
  - Not redesigning the review loop; only the timeout default, per-lane override, and the halt classification change.
related:
  - relay-automation/codex-turn.sh
  - relay-automation/marathon.sh
  - bin/marathon-yaml
  - relay-automation/README.md
goal: >
  Stop a successful builder turn from HALTing the whole marathon just because the CLI's wall-clock
  exceeded the 300s default cap — raise/parameterize the cap per lane and treat
  "killed but artifact present + gate green" as complete-pending-review, not failure.
---

## Status

| What was just completed | What's next |
|---|---|
| Lane `gh205-turn-timeout` BUILT 2026-07-15 on the marathon branch — and the lane itself live-reproduced this bug (codex blew even the 900s cap mid-lane, work committed `37fd333`, chain HALTed unreviewed; recovered by manually driving the lost agy review). agy r1 caught a real `relay_exit` reset bug in the recovery path, codex fixed, agy r2 Approved; gate 144/144. Landed: 900s shim defaults, per-lane `turn_timeout_s:` plumbed through `bin/marathon-yaml`+`marathon.sh`, exit-7-with-artifact+green-gate → reviewer round (`recover_timeout_exit`), README/example docs. | Merge via the marathon branch PR. Note for review: the first escalation written by the new recovery code mislabeled its reason (`turn-timeout-or-hang` vs "pre-advance gate failed" message) — verify the classification matrix in the PR. |

## Problem (confirmed in code, not assumed)

- `relay-automation/codex-turn.sh:131` — `turn_timeout="${RELAY_TURN_TIMEOUT_S:-300}"`; a turn that
  exceeds it is killed and classified exit 7, which `relay-drive.sh` surfaces as an unexpected code
  and `marathon.sh` turns into a chain HALT.
- Observed live (sleuth-app GH-367 marathon, 2026-07-15, vendored `.xyz/` at `4e12133`): codex had
  already written + committed the module and its test, the pre-advance gate was green
  (78 suites / 1314 tests), yet the lane HALTed on the cap and the reviewer round never ran — the
  artifact shipped unreviewed.
- `MARATHON.yaml` has no per-lane timeout field (`grep turn_timeout bin/marathon-yaml
  relay-automation/marathon.sh` → 0 hits) and `relay-automation/README.md` never documents
  `RELAY_TURN_TIMEOUT_S` (0 hits) — operators discover the env var by reading shim source.

## Ask / Definition of done

- [ ] Raise the default `RELAY_TURN_TIMEOUT_S` in the turn shims to a realistic code+test budget
      (600–900s), keeping the env override.
- [ ] Add per-lane `turn_timeout_s:` to `MARATHON.yaml` (parsed by `bin/marathon-yaml`, plumbed by
      `relay-automation/marathon.sh` into the drive env as `RELAY_TURN_TIMEOUT_S`).
- [ ] On a timeout kill (exit 7), distinguish outcomes: if the lane's artifact exists and the
      pre-advance gate passes, proceed to the reviewer round instead of HALT (a true hang — no
      artifact or red gate — still HALTs).
- [ ] Document `RELAY_TURN_TIMEOUT_S` + `turn_timeout_s:` in `relay-automation/README.md` and
      `relay-automation/MARATHON.example.yaml`.
- [ ] Tests in `test/marathon.sh` / `test/codex-turn.sh` cover: per-lane override reaches the shim,
      and exit-7-with-green-gate advances to review.

## Reversibility & blast radius

Medium. Touches the shim default and the marathon halt classification — the containment boundary
(allowlist, no-push) is untouched. Fully revertible; the old behavior is one env var away
(`RELAY_TURN_TIMEOUT_S=300`).

## Provenance

Filed from a live sleuth-app marathon run (2026-07-15) alongside #206 (vendored root split) and
#207 (retry/resume brittleness); bundled with both for one marathon.

## Swarm Preflight Contract

```json
{"target":{"repo":".","ref":"main"},"gate":"bash validate.sh","fix_probes":[{"type":"grep_present","path":"relay-automation/codex-turn.sh","pattern":"RELAY_TURN_TIMEOUT_S:-300"},{"type":"grep_absent","path":"relay-automation/marathon.sh","pattern":"turn_timeout_s"},{"type":"grep_absent","path":"relay-automation/README.md","pattern":"RELAY_TURN_TIMEOUT_S"}],"artifacts":["relay-automation/codex-turn.sh","relay-automation/agy-turn.sh","relay-automation/marathon.sh","relay-automation/marathon-drive.sh","bin/marathon-yaml","relay-automation/README.md","relay-automation/MARATHON.example.yaml","test/marathon.sh","test/codex-turn.sh","test/marathon-yaml.sh"],"remediation":{"source":"self#ask--definition-of-done","criteria":"Per-lane turn_timeout_s plumbed end-to-end; exit-7 with artifact present + gate green advances to review instead of HALT; README/example documented; bash validate.sh green."},"lanes":{"orchestrator_only":["relay-automation/relay-turn-lib.sh","bin/",".tick/"]}}
```
