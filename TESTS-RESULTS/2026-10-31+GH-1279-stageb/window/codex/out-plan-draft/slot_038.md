# Plan draft: #443 marathon-triage: verify PRS ratings, then compute, preflight, and dry-run the marathon before it fires

> draft; preflight and independent plan QA outstanding

- Request: `gh-443-c58c8579b1d5` (tick `slot_038`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 60/40/50/55
- Capture doc: PROJECT/1-INBOX/GH-443-MARATHON-RATING-PASS.md (sha256 756b1927435151a94ebea612b891ab340dfb5a04e5c9a7349a0502f361c56bfa)
- Issue sha256: c58c8579b1d5dba33babd223913dfcf53c06e6a10e89ccb8f536d02800603d25 (updated 2026-10-22T13:48:50Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-443-MARATHON-RATING-PASS.md:L16 (frontmatter goal)_

Before any marathon is fired, four deterministic passes run in order — PRS rating verification against the RELEASES DB, planner compute on the verified rank, per-candidate swarm preflight, and a no-dispatch marathon-drive dry run — each with an exit code and a written artifact.

_Source: codex-authored (codex-authored)_

Verify issue #443 and the work delivered by merged PRs #726 and #1176 before identifying remaining requirements.

_Source: codex-authored (codex-authored)_

Plan four ordered passes: PRS verification, ranking and compute, per-candidate preflight, and a no-dispatch marathon dry run; include the shared jog first-run intake.

_Source: codex-authored (codex-authored)_

Preserve operator overrides and require confirmation before writing proposed ratings through roadmap rate.

## Acceptance criteria

_Source: issue#443:L19 (Acceptance)_

- [ ] A candidate with no PRS row is reported `UNRATED` and cannot reach `READY`.
- [ ] A candidate whose PRS rating predates its last issue update is reported `STALE` with both timestamps.
- [ ] `marathon_plan.py` ranks by PRS rank (four-axis sum or `ovr`) when present; PDDA trio only as the gate.
- [ ] `marathon-drive.sh --dry-run` exists, dispatches nothing, and exits with the real driver's codes.
- [ ] Negative control: a planted bad rating (e.g. `sev` 5 on a crash) is flagged `DISAGREES`.
- [ ] `test/gh<N>-marathon-rating-pass.sh` pins the four passes with positive and negative controls; registered in `validate.sh`.

_Source: codex-authored (codex-authored)_

Missing, stale, and contradictory ratings are reported, and an unrated candidate cannot reach READY.

_Source: codex-authored (codex-authored)_

The planner ranks on the verified four-axis sum or override while retaining the PDDA risk gate.

_Source: codex-authored (codex-authored)_

The driver dry run dispatches nothing, preserves the real driver's exit codes, and does not create a plan file.

_Source: codex-authored (codex-authored)_

Each pass produces a verdict, exit code, and written artifact; READY requires all four passes to succeed.

_Source: codex-authored (codex-authored)_

Positive and negative controls cover the four passes and are registered in validation.

## Open questions

_Source: codex-authored (codex-authored)_

Which requirements remain after PRs #726 and #1176, including the existing driver dry-run capability?

_Source: codex-authored (codex-authored)_

What reliable timestamps and evidence define stale ratings and disagreements between PRS bands and PDDA values?

_Source: codex-authored (codex-authored)_

How should written pass artifacts be produced without the planner dry run creating a plan file?

## Write set

- `utils/py/_marathon_plan.py` (issue#443:L5)
- `utils/py/releases_app.py` (issue#443:L12)
- `utils/py/marathon_plan.py` (issue#443:L13)
- `validate.sh` (issue#443:L26)

## Unresolved file names

- `swarm-preflight.sh` (issue#443:L3; 2 tracked files share this name)
- `marathon-drive.sh` (issue#443:L15; 2 tracked files share this name)

## Contract probes

- none
