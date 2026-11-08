# Plan draft: #346 Speed up harness -> gateway -> model resolution with a real cache

> draft; preflight and independent plan QA outstanding

- Request: `gh-346-c85e94c3b598` (tick `slot_016`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 78/72/60/48
- Capture doc: PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md (sha256 0f0822f17b3ba7f673ae05194b8a0181447ff868655ed85b51de3a686ca0f7cc)
- Issue sha256: c85e94c3b5986987ec3b0b2c773ac2fabaed6e189aeac4dbf6a195a83b8ffa5c (updated 2026-09-05T17:44:01Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L263 (Parked (not in scope until Phase 0-3 ship))_

- [ ] **P.1** `--turn-shape review|build` emitting per-gateway turn defaults
- [ ] **P.2** Per-gateway key-seam export + verification (`OPENROUTER_API_KEY` and friends)

Both are real ideas from the comment thread with only one reproduction each, and none of the
confirmed bugs above needed them to be found.

_Source: PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L28 (frontmatter goal)_

Adding or selecting a gateway stops being ten independent hand-maintained allowlists and three re-derived per-session lookups, and `harnesses.db` stops recording a model that did not run. Phase 0-2 fix confirmed bugs; Phase 3 is gated behind a measured ROI checkpoint.

## Acceptance criteria

_missing_

## Open questions

_missing_

## Write set

- `utils/py/commandcode-turn.py` (issue#346:L15)
- `relay-automation/openrouter-model-aliases.yml` (issue#346:L18)
- `relay-automation/resolve-model-alias.sh` (issue#346:L18)
- `utils/py/device_config.py` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L23)
- `PROJECT/PDDA.md` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L38)
- `relay-automation/deepseek-turn.sh` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L45)
- `utils/py/deepseek-turn.py` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L57)
- `relay-automation/marathon-agent.sh` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L69)
- `utils/py/harness_app.py` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L74)
- `utils/py/claude-turn.py` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L84)
- `utils/py/aider-turn.py` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L86)
- `bin/marathon-yaml` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L93)
- `src/marathon-yaml.js` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L94)
- `relay-system/2026-08-31/gh346-phase0-2-qa.md` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L99)
- `utils/py/codex-turn.py` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L103)
- `test/gh346-telemetry-row-written.sh` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L128)
- `utils/py/agy-turn.py` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L145)
- `utils/py/pi-turn.py` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L148)
- `utils/py/harness_turn_logger.py` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L151)
- `relay-automation/marathon-drive.sh` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L162)
- `utils/py/marathon_drive.py` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L163)
- `utils/py/gate_env.py` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L169)
- `test/gh441-gate-env-contract.sh` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L169)
- `validate.sh` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L203)
- `test/model-alias.sh` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L213)
- `utils/py/review_xyz.py` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L214)

## Unresolved file names

- `find-harness.sh` (issue#346:L5; 2 tracked files share this name)
- `agy-turn.sh` (issue#346:L15; 2 tracked files share this name)
- `codex-turn.sh` (issue#346:L15; 2 tracked files share this name)
- `aider-turn.sh` (issue#346:L15; 2 tracked files share this name)
- `marathon-drive.sh` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L26; 2 tracked files share this name)
- `SKILL.md` (PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md:L230; 77 tracked files share this name)

## Contract probes

- none
