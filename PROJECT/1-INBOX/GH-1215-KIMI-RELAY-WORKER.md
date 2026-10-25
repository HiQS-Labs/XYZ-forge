---
title: "Add a native kimi relay worker (Kimi Code CLI) to the relay harness"
status: Planned (plan QA pending)
created: 2026-10-24
updated: 2026-10-24
owner: claude
gh_issue: 1215
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1215
doc_type: feature
complexity: 2
risk: 2
effort: 2
phases: 1
non_goals:
  - Kimi as a marathon REVIEWER (the codex/agy reviewer gates, allowlists #6/#7, stay as they are)
  - Teaching the frozen Bash twin marathon-drive.sh (GH-308) about kimi
  - A consult.py kimi panelist, harnesses.db / HARNESS-MODELS-REGISTRY rows, or a grade
  - Model-catalog alias work for kimi-code/* ids
  - New test/ suites or validate.sh entries (AGENTS.md, GH-831)
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1189
  - https://github.com/HiQS-Labs/XYZ-CLIO/pull/12
  - GH-518
  - GH-346
goal: >
  Let relay-drive dispatch Kimi K3.1 through the native Kimi Code CLI, with the same
  containment as every other worker, instead of through Aider and OpenRouter.
---

# GH-1215 - Add a native kimi relay worker (Kimi Code CLI)

## Status

| What was just completed | What's next |
|---|---|
| Recon and plan written | Codex plan QA via relay-xyz |

## Key concepts

- A thin Bash entry point over a Python adapter (GH-148). Containment stays in `RelayTurnLib`.
- `kimi -p` is the headless mode. It edits files and runs shell commands with no approval prompt.
  `--auto` and `--yolo` are refused alongside `-p`.
- Lanes are derived from `route_agent()`, so adding `kimi` there is what makes profiles route it,
  and it obliges every other agent-id allowlist to learn it (GH-346).

## Scope

Requested by the parent session on 2026-10-24 (tracker `noelsaw1/noels-cross-project-tasks#46`).

| # | Requirement | Acceptance check |
|---|---|---|
| R1 | `relay-automation/kimi-turn.sh` + `utils/py/kimi-turn.py`; `KIMI_AGENT` gates dispatch; `KIMI_BIN`, `KIMI_MODEL` (default `kimi-code/k3.1-pro`), `KIMI_FLAGS`, `KIMI_LOG` | Smoke: actor mismatch defers with exit 0; a live turn runs |
| R2 | Containment, allowlist, commit guard and no-push come from `RelayTurnLib` | Live review turn passes `rtl.enforce`; worktree isolation on |
| R3 | Empty model output is a failed turn (exit 5) | Smoke with a stub `KIMI_BIN` that prints only meta events, exit 0 → shim exit 5 |
| R4 | `RELAY_HAS_KIMI` in `find-harness.sh --env`, `kimi CLI` line in `--check` | Run both; red control with `KIMI_BIN=/nope` and no `~/.kimi-code/bin/kimi` fallback → `--` / `0` |
| R5 | `resolve-profile.sh` routes a `kimi` harness | `resolve-profile.sh --list` shows `kimi`; a `kimi` profile `--env` exports `KIMI_AGENT`/`KIMI_MODEL` |
| R6 | relay-xyz `SKILL.md` worker and model tables list kimi | Read back |
| R7 | Done: one-turn review relay with `--agent-cmd relay-automation/kimi-turn.sh --reviewer kimi` lands a valid review block | `relay-drive.sh` exit 0, review block appended, receipt under `TESTS-RESULTS/2026-10-24+GH-1215/` |

## Recon (base `395e9d64`)

| Seam | Location | Finding |
|---|---|---|
| Shim template | `utils/py/muse-turn.py` (GH-518) | Newest native-CLI shim: `resolve_turn_root`, `claim_task_or_exit`, `rtl.before`, worktree isolation, `apply_reviewer_turn_env`, `rtl_run_bounded` (exit 7), banner-aware empty-output guard (exit 5), `rtl.enforce`, `HarnessTurnLogger`. |
| Kimi CLI | `kimi` 2.3.1, live probes in a scratch repo | `-p` edits a file and runs Bash headless with no mode flag. `--yolo`/`--auto` with `-p` exit 1 ("Cannot combine"). No prompt-file or stdin mode (`-p -` treats `-` as the prompt). `--output-format stream-json` prints one JSON object per line: `role:meta` version and resume-hint events, `role:assistant` with `content` or `tool_calls`, `role:tool` results. Text mode prints a `kimi version` banner and a resume line. |
| Profile routing | `utils/py/profile_resolve.py:152` `lanes()` | Lanes come from a regex over `route_agent()` in `marathon_drive.py`. Gateway var is read from the shim's telemetry call; CLI from `<PREFIX>_BIN` default or `shutil.which("…")`. No change needed in `profile_resolve.py`. |
| Agent-id allowlists | `test/gh346-gateway-allowlists.sh` header | Ten copies. A lane added to `route_agent()` fails that suite until #3 dispatcher, #4 probe, #5 `*_TURN_ROOT`, and the #2 rejection message know it. #8/#9/#10 (gate scrub registry, reset block, `GATE_SCRUBBED_ENV`) are pinned per lane by `test/gh441-gate-env-contract.sh`. #1 (frozen Bash twin) and #6/#7 (reviewer gates) deliberately stay unchanged. |
| Relay driver | `utils/py/relay_drive.py:145` `prepare_turn_log` | Prefix table that resolves each shim's log for incident hand-off (GH-372). `--reviewer` is not restricted to codex/agy here, only in the marathon driver. |
| Detection | `skills/1-hourly/relay-xyz/find-harness.sh:349-458` | Advisory `RELAY_HAS_*` flags and `mark` lines; agy has a `~/.local/bin` fallback that kimi mirrors with `~/.kimi-code/bin/kimi` (the installer's PATH edit is in `~/.zshrc`, so a non-interactive shell does not see it). |

Untraced: `consult.py` panel routing and the HiQS catalog's `moonshotai/kimi-code` entry (both non-goals).

## Plan

1. **`utils/py/kimi-turn.py`** (new; mirrors `muse-turn.py` minus its model-tier policy).
   - `KIMI_BIN` → `shutil.which("kimi")` → `~/.kimi-code/bin/kimi`; `--print-bin` prints the result
     so `find-harness.sh` uses the shim's own rule (the GH-393 parity lesson).
   - Command: `kimi -p <prompt> -m <KIMI_MODEL> --output-format stream-json [shlex.split(KIMI_FLAGS)]`,
     cwd = turn root or isolation worktree, under `rtl_run_bounded(RELAY_TURN_TIMEOUT_S)`.
   - Empty-output guard: exit 0 but no `role:assistant` line with non-empty `content` or `tool_calls`
     → exit 5. Meta events and non-JSON chatter do not count.
   - `rtl.enforce(t, me, log, "kimi")`; telemetry `harness_id="kimi"`, `model_id` = dispatched model,
     `gateway=os.environ.get("KIMI_GATEWAY", "moonshot")`.
   - Exit mapping identical to muse (6 containment, 7 timeout, 5 launch/empty).
2. **`relay-automation/kimi-turn.sh`** (new): the 14-line GH-148 entry point.
3. **Allowlists** (one line each): `marathon_drive.py` `route_agent` + its rejection message (#2),
   `_probe_agent_bin` via `_probe_bin_or_file([KIMI_BIN, "kimi", KIMI_DEFAULT_BIN])` (#4),
   `*_TURN_ROOT` tuple (#5), `KIMI_AGENT` reset (#9) and `GATE_SCRUBBED_ENV` (#10);
   `gate_env.py` registry (#8); `marathon-agent.sh` dispatcher case (#3); `relay_drive.py`
   `prepare_turn_log` table.
4. **`find-harness.sh`**: `KIMI_PATH` from `kimi-turn.py --print-bin`, `export KIMI_BIN`,
   `RELAY_HAS_KIMI`, and `mark "$KIMI_PATH" "kimi CLI  (Path A worker, Kimi Code)"`.
5. **Docs**: relay-xyz `SKILL.md` worker table, model table, and the `--env` / `--check` comment
   lines; `CHANGELOG.md`.
6. **Verify** (below), then the live one-turn review relay (R7).

## Bet check

- *Outcome sought:* Kimi K3.1 reviews land as valid relay blocks without hand transcription, paid
  from the Kimi plan.
- *Smallest viable bet:* one shim plus the one-line allowlist entries the existing suites require.
  Not built: reviewer eligibility in the marathon driver, consult panelist, registry grade.
- *Alternative rejected:* keep `aider-turn.sh` + OpenRouter. It works but its whole-file edit
  format broke relay-block validation (CLIO#12, exit 8) and spends OpenRouter credit.
- *Rollback:* revert the PR. No state, schema or ledger format changes; `KIMI_AGENT` unset means
  no turn ever reaches the shim.

## Risks

- Prompt travels in argv (no file/stdin mode): visible in the process table and bounded by
  `ARG_MAX` (1 MB on macOS). Relay prompts are a few KB; an `E2BIG` launch failure maps to exit 5.
- Kimi's own workspace bounds are untested beyond cwd; containment does not rely on them (path
  allowlist, commit guard and worktree isolation do).
- No reasoning-effort flag exists on the CLI; `KIMI_REASONING_EFFORT` from a profile is ignored.

## Verification (no new test/ suites)

- Existing suites: `test/gh346-gateway-allowlists.sh` (derives lanes from `route_agent`, so it
  checks kimi in #2–#5), `test/gh441-gate-env-contract.sh` (#8/#10 lockstep),
  `test/find-harness.sh`, `test/relay-xyz-skill-guard.sh`, `test/marathon-drive.sh`; then the
  route the classifier picks for the final diff.
- Red control: run `gh346-gateway-allowlists.sh` after step 3's `route_agent` line but before the
  dispatcher case → it must fail on `#3 dispatcher did NOT route 'kimi'`.
- Manual checks under `TESTS-RESULTS/2026-10-24+GH-1215/` with `provenance.jsonl`: R1 deferral,
  R3 empty-output stub, R4 detection + red control, R5 profile, and the R7 live relay (main path)
  plus a second invocation on the already-reviewed thread (adjacent path).

## Plan QA

Pending.

## Final QA

Pending.

## Rating rationale (2026-10-24)

`rated 55/30/50/70`. Severity 30: no data loss or crash; the cost of not having it is a hand-
transcribed review block per failure and OpenRouter spend. Priority 55: the operator is actively
evaluating Kimi (#1189, tracker #46) and this is the gating step. Appeal 50: neutral, no operator
value given. Effort 70: one shim on an established template plus single-line allowlist edits.
Recurrence (2026-10-10..24 vs 2026-09-26..10-09): 1 incident (CLIO#12 exit 8) vs 0, but the
Aider-Kimi route only started in the recent window, so the trend is unknown.
