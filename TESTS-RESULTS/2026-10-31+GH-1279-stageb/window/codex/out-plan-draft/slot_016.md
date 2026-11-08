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

_Source: codex-authored (codex-authored)_

Verify the current issue status and existing resolution paths, then identify the remaining confirmed work in phases 0–2.

_Source: codex-authored (codex-authored)_

Plan a discoverable harness, gateway, and model resolution path that reduces repeated lookup while preserving existing turn-taker execution and safety logic.

_Source: codex-authored (codex-authored)_

Evaluate phase 3 only after a measured return-on-investment checkpoint; give resolver unification a separate design pass.

## Acceptance criteria

_Source: codex-authored (codex-authored)_

The plan identifies the source of truth for gateway discovery and avoids maintaining another independent gateway list.

_Source: codex-authored (codex-authored)_

Any resolution cache has explicit invalidation and does not return stale harness or model selections.

_Source: codex-authored (codex-authored)_

The recorded model matches the model that actually ran.

_Source: codex-authored (codex-authored)_

Existing turn-taker safety and execution behavior remains intact.

## Open questions

_Source: codex-authored (codex-authored)_

What did the linked plan comment specify for phases 0–2, and what has already landed?

_Source: codex-authored (codex-authored)_

How is the model that actually ran determined and recorded today?

_Source: codex-authored (codex-authored)_

Which resolution inputs and changes must invalidate cached results, and how will the latency benefit be measured?

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
