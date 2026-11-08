# Plan draft: #406 External review (Russ K.): eight findings on guards that cover a narrower path than the doc claims — all reproduce at HEAD

> draft; preflight and independent plan QA outstanding

- Request: `gh-406-baf38e71532a` (tick `slot_042`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 52/62/50/30
- Capture doc: PROJECT/1-INBOX/GH-406-RUSS-EXTERNAL-REVIEW.md (sha256 55244ace0c81e9b7cf4fd0f4fe123768eb0b7149eb66abd392ffb3de8b6f93ae)
- Issue sha256: baf38e71532a2cfa4f041f3facaae1665103b32a8a884acfbd2f3aa0d4fa11bd (updated 2026-10-24T02:49:10Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-406-RUSS-EXTERNAL-REVIEW.md:L22 (frontmatter goal)_

Close the class of defect where a document states a guarantee and the mechanism covers a narrower path than the sentence implies. Five of the eight external findings are that same §13 anti-pattern — a check that cannot falsify its claim because it never runs on the path it is supposed to govern. Land R1-R6 each with a witnessed red control.

## Acceptance criteria

_missing_

## Open questions

_missing_

## Write set

- `bin/tick` (issue#406:L20)
- `utils/build-launch-artifact.sh` (issue#406:L42)
- `bin/validate-relay-block` (issue#406:L54)
- `utils/py/rtl.py` (issue#406:L58)
- `relay-automation/relay-turn-lib.sh` (issue#406:L58)
- `utils/py/relay_drive.py` (issue#406:L58)
- `utils/py/marathon_drive.py` (issue#406:L58)
- `src/events.js` (issue#406:L70)
- `relay-automation/hooks/relay-xyz-guard.sh` (issue#406:L84)
- `relay-automation/relay-drive.sh` (issue#406:L86)
- `relay-automation/poll.sh` (issue#406:L86)
- `relay-automation/deepseek-turn.sh` (issue#406:L88)
- `relay-automation/smallcode-turn.sh` (issue#406:L88)
- `relay-automation/runner.sh` (issue#406:L88)
- `utils/py/poll.py` (issue#406:L88)
- `AGENTS.md` (issue#406:L88)
- `decisions/2026-06-18-epoch-fencing.md` (issue#406:L98)
- `src/project.js` (issue#406:L98)
- `decisions/2026-07-01-cross-agent-dep-conflict.md` (issue#406:L98)
- `decisions/2026-08-10-marathon-gate-baseline-strategy.md` (issue#406:L98)
- `src/lock.js` (issue#406:L124)
- `utils/py/codex-turn.py` (issue#406:L130)
- `utils/pdda/pdda.sh` (issue#406:L144)
- `relay-automation/marathon-recover.sh` (issue#406:L150)
- `PROJECT/DO-NOT-BUILD.md` (issue#406:L150)
- `PROJECT/1-INBOX/RUSS-TRIAGE.md` (PROJECT/1-INBOX/GH-406-RUSS-EXTERNAL-REVIEW.md:L41)
- `test/gh408-tick-failure-visibility.sh` (PROJECT/1-INBOX/GH-406-RUSS-EXTERNAL-REVIEW.md:L52)
- `test/baselines/GH-408-negative-control.md` (PROJECT/1-INBOX/GH-406-RUSS-EXTERNAL-REVIEW.md:L53)
- `docs/ROADMAP-UPSTREAM-ARCHIVE.md` (PROJECT/1-INBOX/GH-406-RUSS-EXTERNAL-REVIEW.md:L87)
- `ROUTER.md` (PROJECT/1-INBOX/GH-406-RUSS-EXTERNAL-REVIEW.md:L88)

## Unresolved file names

- `marathon-drive.sh` (issue#406:L86; 2 tracked files share this name)
- `marathon.sh` (issue#406:L86; 2 tracked files share this name)
- `codex-turn.sh` (issue#406:L86; 2 tracked files share this name)
- `agy-turn.sh` (issue#406:L86; 2 tracked files share this name)
- `claude-turn.sh` (issue#406:L88; 2 tracked files share this name)
- `aider-turn.sh` (issue#406:L88; 2 tracked files share this name)
- `pi-turn.sh` (issue#406:L88; 2 tracked files share this name)
- `commandcode-turn.sh` (issue#406:L88; 2 tracked files share this name)
- `relay-loop.sh` (issue#406:L88; 2 tracked files share this name)
- `consult.sh` (issue#406:L88; 2 tracked files share this name)
- `package.json` (issue#406:L106; 3 tracked files share this name)
- `package-lock.json` (issue#406:L106; 2 tracked files share this name)
- `ESCALATION.md` (issue#406:L150; 44 tracked files share this name)

## Contract probes

- none
