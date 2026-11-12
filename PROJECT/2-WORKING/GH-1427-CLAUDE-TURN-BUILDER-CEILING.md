---
title: claude-turn $0.50 / 12-turn default cuts off Claude builder turns; exit reason discarded, turn log lost
status: Active (2-WORKING — start-task)
created: 2026-11-11
updated: 2026-11-11
owner: Noel Saw
gh_issue: 1427
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1427
doc_type: bugfix
complexity: 2
risk: 4
effort: 2
phases: 1
ratings_provisional: false
reported_from: LTVera-Pandas
harness_commit: 046b41538
non_goals:
  - Choosing the default Claude model or pricing
  - Changing Codex/agy turn shims
related:
  - "#1418"
  - "#1420"
  - "#1426"
goal: >
  A Claude builder turn under Marathon/Jog gets an implementation-sized, overridable ceiling; a
  nonzero claude -p exit prints its JSON subtype/errors into the console and ESCALATION.md; the
  stdout turn log survives a failed turn.
---

# GH-1427 — claude-turn default ceiling cuts off Claude builder turns

## Status

| What was just completed | What's next |
|---|---|
| Promoted from 1-INBOX; recon traced the log loss to `rtl_enforce`'s transcript sweep; plan written (below) | Codex plan QA via relay-xyz, then implementation |

## Table of contents

- [Phase 0 — Diagnose & scope](#phase-0--diagnose--scope)
- [Phase 1 — Plan (start-task)](#phase-1--plan-start-task)

## Environment
- **Observed from:** `LTVera-Pandas` (vendored `.xyz/`)
- **Harness commit:** `046b41538`
- **Worker/CLI:** claude 2.1.322, model claude-sonnet-4-6 (default pin)
- **Runtime:** Python (default)
- **Sandbox:** off

## Symptom

In an all-Claude Jog run (`--builder claude-builder --reviewer claude-reviewer`), the Marathon builder turn for a small feature (GH-993 in LTVera-Pandas: footer reminder, 4 allowlisted files) died with `claude-turn: claude -p failed (exit 1)` after 85 s. Marathon escalated `relay-failed-before-gate` and Jog stopped the queue. Nothing in the console, the `.stderr` diagnostics file (0 bytes), or ESCALATION.md says why. The turn's stdout log, the only place `claude -p --output-format json` reports the error, was not on disk afterwards (`turn-log: … (missing — no turn log was created)`).

## Observed

| Claim | Command | Observed |
|---|---|---|
| Builder turn cut off by the default spend cap | builder session transcript `~/.claude/projects/<rtl-wt dir>/<session>.jsonl`, `cost-state` row | `totalCostUSD: 0.5103871` vs default `--max-budget-usd 0.50`; 12 distinct model turns vs default `--max-turns 12`; last action was a `Write` (18 tool calls, 158 lines added, so real progress was in flight) |
| Defaults | `utils/py/claude-turn.py:110-112` | `CLAUDE_MODEL=claude-sonnet-4-6`, `CLAUDE_MAX_TURNS=12`, `CLAUDE_MAX_BUDGET=0.50` |
| Defaults were calibrated for a different turn shape | `relay-automation/claude-turn.sh:177-178` comments | "observed $0.17", "observed 7" (relay-sized turns), not a Marathon builder implementing a feature |
| Same flags work on a cheap prompt | `claude -p "Reply with the single word ok." --model claude-sonnet-4-6 --allowedTools Bash,Read,Edit,Write --permission-mode acceptEdits --output-format json --max-turns 12 --max-budget-usd 0.50` | exit 0, `$0.062` (system-prompt caching alone) |
| A budget overrun looks exactly like the observed failure | same with `--max-budget-usd 0.01` | exit 1, stderr empty, stdout JSON `subtype: error_max_budget_usd`, `errors: ["Reached maximum budget ($0.01)"]` |
| The reason is discarded | `utils/py/claude-turn.py:222-231,254-255` | `check=True` raises `CalledProcessError` before `read_result`; prints only `failed (exit N)` |
| Cost summary misreports | marathon end-of-run summary | `tokens: 0 total` (parsed from the missing stdout log) while the session spent $0.51 |

Frequency: deterministic for any builder turn that needs more than ~$0.50 / 12 model turns on Sonnet 4.6, which is most feature builds in a repo with a sizeable CLAUDE.md/AGENTS.md. This is the second occurrence: #1420's bounded live Claude turn failed with the same `exit 1` signature and was recorded as "provider budget".

## Root cause

Root cause: `claude-turn` applies one relay-sized spend/turn ceiling ($0.50 / 12) to every Claude role, and Jog/Marathon pass no role-specific ceiling, so a Claude **builder** is cut off mid-implementation. Fix site: ceiling selection in `claude-turn.py` (or the Marathon/Jog role binding that invokes it), plus error surfacing on nonzero exit. Why not just raise the global default: the cap exists to bound spend, so a role-aware default with an explicit override keeps reviewers cheap.

## Acceptance

- [ ] A Claude builder turn under Marathon/Jog gets a ceiling sized for implementation work (role-aware default, or Jog/Marathon pass `CLAUDE_MAX_BUDGET` / `CLAUDE_MAX_TURNS` per role), still overridable by env. Red control: a GH-993-sized builder turn on the current defaults ends `exit 1` at about $0.51 / 12 turns.
- [ ] On nonzero `claude -p` exit, claude-turn reads the stdout JSON and prints `subtype` and `errors` (e.g. `error_max_budget_usd: Reached maximum budget ($0.50)`), and Marathon carries it into ESCALATION.md `reason`. Red control: today's bare `claude -p failed (exit 1)`.
- [ ] The stdout turn log survives a failed turn at the path ESCALATION.md names (or ESCALATION.md names where it went). Red control: `turn-log: … (missing — no turn log was created)` while the `.stderr` sibling exists.
- [ ] End-of-run cost summary takes tokens/cost from the session result even on a failed turn (not `0 total`).
- [ ] Existing claude-turn / gh432 / worktree-isolation suites still pass; evidence under `TESTS-RESULTS/` (no new suites, GH-831).

## Open question for reviewers

Where the stdout log went is untraced. GH-432's post-failure path (commit, containment, "transcript archive", handoff) runs after the failure. It may move or drop the log, or the log may never have been created under the rtl default path. This is a Phase 0 item, deliberately not chased while filing.

## Preflight Contract

```json
{
  "target": "utils/py/claude-turn.py",
  "gate": "existing claude-turn, gh432-failed-turn-persist, worktree-isolation suites",
  "fix_probes": [
    {"type": "grep", "path": "utils/py/claude-turn.py", "pattern": "CLAUDE_MAX_BUDGET\", \"0.50\""}
  ],
  "artifacts": ["utils/py/claude-turn.py", "utils/py/marathon_drive.py"]
}
```

## PRS proposal

pri 75: blocks every Claude-builder Jog/Marathon run, which is the explicit goal of #1418; it has now failed twice.
sev 60: no data loss (GH-432 persists the partial turn), but money is spent on a turn that can't finish, the queue halts, and the cause is invisible without digging through session transcripts.
appeal 60: makes the newly enabled Claude routes (#1420) usable in practice.
effort 60: ceiling plumbing plus error surfacing in one or two files; log-loss trace is the unknown.

## Non-goals

- Choosing the default model (`claude-sonnet-4-6`) or provider pricing.
- Changing Codex/agy turn shims.

## Phase 0 — Diagnose & scope

### Checklist
- [ ] Reproduce in the intake repo: a builder-sized Claude turn on default ceilings ends exit 1 at ~$0.50 / 12 turns
- [ ] Trace where the stdout turn log goes after a failed turn (GH-432 path)
- [ ] Decide role-aware default vs Jog/Marathon passing per-role env; reuse existing env knobs (`/ponytail`)
- [ ] Set real ratings; clear `ratings_provisional`

### QA checklist — Phase 0
- [ ] Repro confirmed from the report, not assumed
- [ ] Existing suite or recorded manual check covers the failure path before the fix lands (GH-831)
- [ ] Fix composes with the existing harness rather than adding a parallel path

### Phase 0 findings (recon, 2026-11-11, base `0f21b761a`)

| # | Claim | Evidence | Verdict |
|---|---|---|---|
| F1 | Defaults are still $0.50 / 12 for every role | `utils/py/claude-turn.py:110-112`; `consult.py:800-801` has its own copy | confirmed |
| F2 | Python is the executing lane; `relay-automation/claude-turn.sh` is a frozen twin (GH-308) | `AGENTS.md` "Frozen Bash twins" | twin not edited |
| F3 | The role is known to the shim under a driver: relay-drive exports `RELAY_ROLE=builder|reviewer` per turn, and `rtl.is_reviewer_turn()` (`rtl_is_reviewer_turn`) already resolves it (GH-505/509). claude-turn already calls it via `apply_reviewer_turn_env` | `utils/py/relay_drive.py:856-859`, `utils/py/rtl.py:871-883`, `relay-turn-lib.sh:63` | reuse, no new knob needed in Jog/Marathon |
| F4 | `check=True` → `CalledProcessError` → only `failed (exit N)` printed; the exit-0-but-error path (`read_result` ValueError) also prints no subtype | `claude-turn.py:222-233,254-255`, `claude_cli.py:60-72` | confirmed |
| F5 | **Log loss (the open question).** relay-drive passes the exact `rtl_default_log` path to the shim via `CLAUDE_LOG` (GH-372) and records it in `last-turn-incident.json`. claude-turn writes it (`open(claude_log,"w")`). Then `rtl_enforce` (run on failure too, GH-432) **deletes it**: its GH-161 leftover sweep runs `git status --porcelain -- "$RTL_LOG_REL"` and `rm -f`s the file whenever the path is not gitignored. The harness repo ignores `relay-system/logs/` (`.gitignore:27`), but a host repo with a vendored `.xyz/` need not. LTVera-Pandas does not (`git check-ignore relay-system/logs/x.log` → rc 1). The `.stderr` sibling is not `RTL_LOG_REL`, so it survives. That is exactly the observed signature | `relay-turn-lib.sh:1309-1310` (in-loop `rtl_check` exact match), `:1734-1760` (final sweep); scratch probe: `git status --porcelain -- relay-system/logs/d/x.log` lists the file itself in an un-ignoring repo | **root cause found** |
| F6 | GH-379 already copies `is_error/subtype/terminal_reason/total_cost_usd` from the JSON log into ESCALATION.md `builder-diagnostic:`, but it found nothing because of F5. It omits `errors` | `marathon_drive.py:2198-2221,2262-2263` | extend the existing writer |
| F7 | "tokens: 0 total" = `tick analyze` over `tick cost` rows; claude-turn records `tick cost` only after the success exits (`sys.exit(5)` at :281 precedes the cost block at :283) | `claude-turn.py:278-304`, `marathon_drive.py:1850-1876` | confirmed |

## Phase 1 — Plan (start-task)

### Ratings (dated 2026-11-11, written through `roadmap pickup`)

`rated 80/80/50/60` (pri/sev/appeal/effort). **sev 80:** this blocks work. Every Claude-builder Marathon/Jog turn
larger than ~$0.50 halts the queue, and the only evidence (the JSON transcript) is deleted, so it is
undiagnosable. It is recoverable (GH-432 persists partial edits), so it sits at the bottom of the high band.
**pri 80:** severity-led; it blocks #1418's Claude-only proving goal. **appeal 50:** neutral. The issue's 60 was
an author proposal, not an operator value. **effort 60:** three small code sites plus docs. **Recurrence:**
2 incidents in the last 14 days (#1420's live turn and the LTVera-Pandas GH-993 run, which are distinct runs).
The preceding 14 days had none found, but this is a newly enabled route (#1420), so the trend is unknown.

### Bet check

- *Outcome:* a Claude builder can finish an implementation-sized turn. When any Claude turn fails, the
  operator sees why in the console and in ESCALATION.md, the transcript is still on disk, and the spend is counted.
- *Smallest bet:* (1) role-aware defaults in the existing ceiling selection, (2) surface the JSON subtype/errors
  the CLI already writes, (3) stop the kernel deleting a transcript under the durable transcript root,
  (4) record cost before the failure exit, (5) add `errors` to the existing GH-379 diagnostic.
- *Not built:* no new env knob, no Jog/Marathon per-role plumbing (F3 makes it unnecessary), no change to
  `consult.py` (a reviewer-shaped consult keeps $0.50), no Bash-twin edit, no auto-retry with a bigger budget,
  no host `.gitignore` installer.
- *Alternatives rejected:* (a) raising the global default makes reviewers expensive too, and the issue rejects it;
  (b) having Jog/Marathon export `CLAUDE_MAX_*` per role adds a second ceiling owner, while the shim already knows its role;
  (c) having the vendored install add `relay-system/logs/` to the host `.gitignore` would not fix existing hosts or
  `CLAUDE_LOG` overrides, and the deletion would stay silent.
- *Rollback:* revert the single PR. Every change is additive or a default; an operator can pin the old
  behaviour now with `CLAUDE_MAX_BUDGET=0.50 CLAUDE_MAX_TURNS=12`.

### Design decision — defaults

| Role (as resolved by `rtl.is_reviewer_turn`) | `--max-budget-usd` | `--max-turns` |
|---|---|---|
| reviewer | 0.50 (unchanged) | 12 (unchanged) |
| builder / producer (everything else) | **3.00** | **40** |

An explicit `CLAUDE_MAX_BUDGET` / `CLAUDE_MAX_TURNS` overrides both roles, as it does today. The builder values are the
operator's proven override from the LTVera-Pandas run. The failed builder turn reached $0.51 at 12 turns while still
mid-Write, so roughly 6x headroom covers a small-to-medium feature. The 900s wall cap and the GH-492 idle bound
still bound a runaway turn. For Max-subscription operators the budget is notional list-price usage; for API users
it is billed, which is why reviewers stay cheap. `warn_opus_budget` keeps firing for an Opus reviewer on $0.50.

### Implementation (ordered, verification inline)

1. `utils/py/claude_cli.py`: add `result_error_summary(path) -> str`. It best-effort reads the JSON result and
   returns `"<subtype>: <errors joined by '; '>"` (or the subtype alone), or `""` when the file is missing or
   unparseable. This is a read-only helper beside `read_result`, the existing JSON reader. *Check:* a python -c
   probe on an `error_max_budget_usd` sample and on an empty file.
2. `utils/py/claude-turn.py`:
   a. Select the ceiling: `reviewer = rtl.is_reviewer_turn(me)`. The defaults are `("0.50","12")` for a reviewer
      and `("3.00","40")` otherwise, and env overrides win. Keep the line `warn_opus_budget(model, max_budget)`
      byte-identical (pinned by `test/gh642-consumer-fruit.sh`).
   b. Failure message: for the `CalledProcessError` and `read_result` ValueError branches, append
      `result_error_summary(claude_log)` when it is non-empty. The output becomes
      `claude-turn: claude -p failed (exit 1): error_max_budget_usd: Reached maximum budget ($3.00)`.
      Exit codes are unchanged (5/6/7).
   c. Move the existing token-capture block into a local `record_cost()` and call it on both the failure path
      (after `rtl.enforce`, before `sys.exit(5|7)`) and the success path. The block is unchanged otherwise.
   *Check:* existing `test/claude-turn.sh`, `test/gh432-failed-turn-persist.sh`, `test/gh642-consumer-fruit.sh`,
   `test/gh380-claude-trust.sh`, `test/gh610-claude-subscription.sh`.
3. `relay-automation/relay-turn-lib.sh` (shared kernel, called by every shim): in the two places that delete the
   shim's own log (the `rtl_check` exact match and the final GH-161 leftover sweep), keep the file when
   `RTL_LOG_REL` lies under the durable transcript root's `logs/` directory (`rtl_transcript_root`, i.e.
   `relay-system/logs/…` by default). The existing GH-261 rule already exempts that directory from containment.
   Strays outside it (a custom in-repo `CLAUDE_LOG`) are still removed as before. It is a single helper used by both
   sites. *Check:* `test/worktree-isolation.sh`, `test/relay-turn-trace.sh`, `test/gh91-relay-scratch.sh`,
   `test/gh113-headless-scratch.sh`, `test/gh2-orphan-backup-repro.sh`, `test/rtl-orphan-backup.sh`.
4. `utils/py/marathon_drive.py`: add `errors` to the GH-379 `builder_diag` key list, so the existing
   `builder-diagnostic:` line in ESCALATION.md carries `subtype=error_max_budget_usd, errors=[...]`. `reason:` stays
   the category token (`relay-failed-before-gate`), because Jog and the escalation consumers key on it. The cause
   travels in the adjacent existing field, which also fixes the "turn-log missing" line through step 3.
   *Check:* `test/gh379-claude-builder-diagnosis.sh`, `test/gh372-escalation-log-tail.sh`.
5. Docs: update `README.md:125-126`, `relay-automation/README.md:123-124`, `HOW-TO-USE.md:79`, and the
   `MARATHON.example.yaml:21-22` comment to state the role-aware defaults. Add a `CHANGELOG.md` entry. The frozen
   twin's header (`claude-turn.sh:50-51`, pinned by gh379) stays accurate for the twin it describes.

### Verification (no new suites, GH-831)

- Focused: the suites named in steps 2–4 plus `bash test/gh308-frozen-twin-guard.sh --check --staged`.
- Final gate: whichever tier `utils/ci-route.sh` picks for the changed paths (expected: full), run once in a disposable
  `-gate` clone.
- Manual checks recorded under `TESTS-RESULTS/2026-11-11+GH-1427/`:
  - **M1 (red/green, fake CLI):** a fixture host repo that does *not* ignore `relay-system/logs/`, with a fake `claude`
    that writes an `error_max_budget_usd` JSON result and exits 1, driven through `utils/py/claude-turn.py`.
    Assertions: the console names `error_max_budget_usd: Reached maximum budget`; the JSON log exists after the
    turn at the `CLAUDE_LOG` path; a `tick cost` row is recorded. **Red control:** the same script on base
    `0f21b761a` shows a bare `failed (exit 1)` and the log is deleted.
  - **M2 (role defaults):** the fake CLI echoes its argv. Under `RELAY_DRIVER_LOCKED=1`, `RELAY_ROLE=builder` →
    `--max-budget-usd 3.00 --max-turns 40`; `RELAY_ROLE=reviewer` → `0.50 / 12`; `CLAUDE_MAX_BUDGET=1.25` wins for both.
  - **Smoke (GH-1088), main path:** one bounded live `claude -p` turn through claude-turn.py with `CLAUDE_MAX_BUDGET=0.01`.
    Expect exit 5, the console subtype `error_max_budget_usd`, and the log surviving. **Adjacent path:** a rerun of the
    same turn with the default builder ceiling on a trivial relay prompt, which exits 0 (spend ≈ $0.06).
  - **ESCALATION check:** M1's log fed through the GH-379 `builder_diag` parse, showing `errors=` present.

### Risks

- The kernel change touches every shim's log handling. It is scoped to paths under the transcript root, which GH-161
  and GH-388 already define as durable, and the files are still untracked, so they never ride into a commit
  (the commit step is allowlist-scoped). A host that previously had no `?? relay-system/logs/` dirt now does: that is
  the persistent record GH-161 promised, and `rtl_before` treats it as ambient on the next turn.
- **Overlap:** #1428 (parallel) may touch `claude-turn.py` / `marathon_drive.py`. This diff touches a few lines in each,
  so rebase conflicts should be trivial.

### Acceptance map

| Issue acceptance | Plan step | Witness |
|---|---|---|
| Builder ceiling sized for implementation, env-overridable | 2a | M2 |
| Nonzero exit prints subtype/errors; carried into ESCALATION.md | 1, 2b, 4 | M1, ESCALATION check, smoke |
| Turn log survives at the named path | 3 | M1 red/green, smoke |
| Cost recorded on a failed turn | 2c | M1 `tick cost` row |
| Existing suites pass, evidence under TESTS-RESULTS | — | focused suites + gate receipt |
