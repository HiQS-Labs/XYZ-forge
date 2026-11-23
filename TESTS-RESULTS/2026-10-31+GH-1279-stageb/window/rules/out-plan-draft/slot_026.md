# Plan draft: #256 No preflight checks the builder can reach a phase's artifact paths — the phase burns its full round cap writing nothing

> draft; preflight and independent plan QA outstanding

- Request: `gh-256-0e2251ddd357` (tick `slot_026`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 58/62/50/55
- Capture doc: PROJECT/1-INBOX/GH-256-ARTIFACT-REACHABILITY-PREFLIGHT.md (sha256 dffc659841636126de7f3b2c5591967361eabc3502a3702a7157a8fdec756509)
- Issue sha256: 0e2251ddd357778dc111db8bf49c45af593948a9f0556df7f65bca0d9d440cf9 (updated 2026-10-24T02:48:58Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-256-ARTIFACT-REACHABILITY-PREFLIGHT.md:L22 (frontmatter goal)_

A phase whose artifact paths are unreachable from the builder's resolved working directory is refused before dispatch with a named path and directory, instead of dispatching four no-op builder turns and escalating as cap-stalled after 29 minutes.

## Acceptance criteria

_Source: issue#256:L51 (Acceptance criteria)_

- [ ] A phase whose artifact paths are unreachable from the builder's resolved working directory is refused before dispatch, exit 2, naming the path and the directory.
- [ ] A test covers the `--target-root` + `--phases-dir` topology specifically, since that is the one that dispatched and then failed silently.
- [ ] Two consecutive no-op builder turns escalate without running to the round cap.
- [ ] `ESCALATION.md` records the number of builder blocks appended.
- [ ] Each preflight check reports under a distinct name in the run log.

## Open questions

_missing_

## Write set

- `relay-automation/relay-turn-lib.sh` (issue#256:L15)
- `src/project.js` (issue#256:L16)
- `src/events.js` (issue#256:L17)
- `PROJECT/PDDA.md` (PROJECT/1-INBOX/GH-256-ARTIFACT-REACHABILITY-PREFLIGHT.md:L32)
- `relay-automation/relay-drive.sh` (PROJECT/1-INBOX/GH-256-ARTIFACT-REACHABILITY-PREFLIGHT.md:L47)
- `utils/py/agy-turn.py` (PROJECT/1-INBOX/GH-256-ARTIFACT-REACHABILITY-PREFLIGHT.md:L53)
- `relay-automation/CONSUMING.md` (PROJECT/1-INBOX/GH-256-ARTIFACT-REACHABILITY-PREFLIGHT.md:L54)
- `relay-system/2026-08-26/gh256-plan-qa.md` (PROJECT/1-INBOX/GH-256-ARTIFACT-REACHABILITY-PREFLIGHT.md:L71)

## Unresolved file names

- `marathon-drive.sh` (issue#256:L32; 2 tracked files share this name)
- `ESCALATION.md` (issue#256:L48; 44 tracked files share this name)

## Contract probes

- none
