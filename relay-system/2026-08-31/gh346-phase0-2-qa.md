---
Goal: QA GH-346 Phase 0-2 — model-telemetry honesty, resolver fallback, and the agent-id allowlists
Date: 2026-08-31
Reviewer: commandcode (Command Code -> zai-org/glm-5.3, effort max)
NEXT: Reviewer
STATUS: Open
---

# Context

Adjudicate the Phase 0–2 implementation of GH-346 against the plan agreed in
[issue comment 5481741819](https://github.com/HiQS-Labs/XYZ-forge/issues/346#issuecomment-5481741819).
The plan and the local capture doc are the specification; the code at HEAD of branch
`gh346-model-resolution` is the implementation. Phase 3 is deliberately NOT implemented — it is
gated behind an ROI checkpoint and must not be reviewed as missing work.

**This is a REVIEW turn. Do not edit any file except this relay thread.** Report findings with
`file:line` citations. Read before you judge; several decisions below deliberately depart from the
plan's letter and the review needs to say whether each departure was right.

## Read these

Plan and intent:
- `PROJECT/1-INBOX/GH-346-HARNESS-GATEWAY-MODEL-RESOLUTION.md` — the capture doc with the phase checklists

Phase 0 (telemetry honesty):
- `utils/py/claude-turn.py` (~line 97 dispatch, ~273 telemetry)
- `utils/py/commandcode-turn.py` (~58 dispatch, ~130 telemetry)
- `utils/py/aider-turn.py` (~62/64 dispatch, ~273 telemetry)
- `utils/py/agy-turn.py` (~383 dispatch, ~621 telemetry)
- `utils/py/codex-turn.py` (~143 telemetry)
- `utils/py/pi-turn.py` (~71 dispatch, ~198 telemetry)
- `utils/py/harness_turn_logger.py` — how a `None` model_id is resolved
- `test/gh346-model-telemetry-honesty.sh`

Phase 1 (resolver fallback):
- `utils/py/model_alias.py` — the new shared helper
- `utils/py/deepseek-turn.py` (~136) and `utils/py/review_xyz.py` (~82)
- `relay-automation/resolve-model-alias.sh`, `test/model-alias.sh:43-46`
- `test/gh346-resolver-fallback.sh`

Phase 2 (allowlists):
- `relay-automation/marathon-agent.sh` — allowlist #3, the functional blocker
- `utils/py/marathon_drive.py` — `route_agent` (#2), `_probe_agent_bin` + `_probe_bin_or_file` (#4),
  the `*_TURN_ROOT` tuple (#5), the reviewer gate (#6)
- `bin/marathon-yaml` and `src/marathon-yaml.js` — two copies of the reviewer gate
- `relay-automation/marathon-drive.sh` (~777) — the FROZEN twin, deliberately untouched
- `skills/relay-xyz/find-harness.sh`, `skills/relay-xyz/SKILL.md`
- `test/gh346-gateway-allowlists.sh`

## Questions

1. **Phase 0 scope was expanded from 3 shims to 6.** The plan named claude/commandcode/aider. The
   implementation also changed `agy-turn.py`, `codex-turn.py` and `pi-turn.py`, on the claim that
   they have the *same* bug: `agy-turn.py:383` passes `--model` only when `AGY_MODEL` is set, and
   `codex-turn.py` never passes a model at all, yet both logged a hardcoded slug. Verify that claim
   at the cited lines. Was expanding scope correct, or should the extra three have been filed
   separately?

2. **`agy`/`codex` now pass `model_id=os.environ.get("X_MODEL") or None`.** `harness_turn_logger.py`
   turns `None` into `device_config`'s resolved default. Is that genuinely more honest than the old
   hardcoded literal, or has it just moved the fabrication one layer down — and is
   `harnesses.db` now recording a model that still did not run? If it is no better, say so plainly.

3. **`aider-turn.py`'s `gateway` default was also changed** (to `openai-compatible` when
   `AIDER_OPENAI_API_BASE` is set). That went beyond the plan, which named only `model_id`. Is the
   change correct, and does anything consume `gateway` with a fixed vocabulary that this breaks?
   (`harnesses.db` declares it `TEXT NOT NULL` with no CHECK — confirm.)

4. **`_probe_bin_or_file` mirrors two shims' default binary paths inside `marathon_drive.py`**
   (`SMALLCODE_DEFAULT_BIN`, `DEEPSEEK_DEFAULT_BIN`). This was done because `_probe_bin` is a pure
   `shutil.which()` PATH lookup and both lanes dispatch a script by absolute path through an
   interpreter — a PATH probe would have rejected lanes that run fine. But it creates *another*
   copy of a value that already lives in the shim. Is the drift test in
   `test/gh346-gateway-allowlists.sh` sufficient to keep the copies honest, or is this a net
   regression that should have been solved by importing the shim's own resolver instead?

5. **The reviewer gate lost `gemini` and gained nothing.** Confirm no `gemini-turn.*` shim exists
   anywhere, and that `route_agent` (which runs *before* the gate) had no gemini branch — i.e. that
   the entry was genuinely unreachable and removing it lost no capability. Separately: was
   *deferring* commandcode/deepseek reviewer eligibility to the ROI checkpoint the right call, or
   does shipping them as builders-but-not-reviewers leave the harness in an inconsistent state?

6. **The recon map said six allowlists. The real count is TEN.** Beyond the six, this work found:
   - #7 `src/marathon-yaml.js:114` — a second copy of the reviewer gate, found by reading
   - #8 `utils/py/gate_env.py` — the `HARNESS_ENV` scrub registry
   - #9 `utils/py/marathon_drive.py` ~1830 — the `*_AGENT` reset block that stops a stale
     parent-shell var routing a turn
   - #10 `utils/py/marathon_drive.py` `GATE_SCRUBBED_ENV` — a literal that must equal #8 exactly

   **#8–#10 were found by `test/gh441-gate-env-contract.sh` failing, not by review.** Three of ten
   sites were invisible to a careful manual pass.

   **So: search for an eleventh.** Any other place that enumerates agent ids, gateway names, model
   env-var names, or reviewer eligibility that Phase 2 did not update — including docs that claim a
   list is complete. This is the highest-value question in this review: the whole issue exists
   because a careful pass missed one, and this session has now missed three.

7. **The frozen Bash twin was left alone.** `relay-automation/marathon-drive.sh:777-785` still
   accepts only claude/codex/agy/aider. The divergence from the Python router is now three ids wide.
   Is leaving it frozen correct under GH-308, and is the divergence documented well enough that the
   next person will not trip over it?

8. **Test quality.** Each of the three new tests was checked against pre-fix code and failed there
   (9/9, 11/11, 45/45 passing post-fix; 11 and 15 failures pre-fix respectively). Are they testing
   behavior or merely restating the implementation? Name any assertion that would pass even if the
   fix were reverted. Note specifically the `2.10` tick-mutation check, which observed `0 events`
   both before and after — is that a real assertion or a vacuous one?

9. **Anything wrong, missing, over- or under-engineered** in Phase 0–2 as delivered. Do NOT flag
   Phase 3 work as missing — it is intentionally gated.

Be concrete and cite `file:line` where you disagree with a specific claim. Write your verdict below
and change `STATUS` to `Approved` if it passes, or leave it `Open` with findings if it does not.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (commandcode)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
