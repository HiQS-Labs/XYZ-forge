---
title: claude-turn $0.50 / 12-turn default cuts off Claude builder turns; exit reason discarded, turn log lost
status: Proposed (1-INBOX — not yet active)
created: 2026-11-11
owner: Noel Saw
gh_issue: 1427
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1427
doc_type: bugfix
complexity: 2
risk: 4
effort: 2
phases: 1
ratings_provisional: true
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

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

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

## Merge evidence

- PR #1433 merged 2026-11-12 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
