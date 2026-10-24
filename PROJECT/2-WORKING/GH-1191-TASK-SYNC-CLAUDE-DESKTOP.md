---
title: "task-sync: Claude Desktop sidebar titles (native planner)"
status: In progress
created: 2026-10-24
updated: 2026-10-24
owner: claude
gh_issue: 1191
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1191
doc_type: feature
complexity: 2
risk: 2
effort: 2
phases: 1
non_goals:
  - "#1191 step 4 (scheduler change to one Desktop scheduled task per device) and step 5 (rollout)"
  - Cloud, Codex, ZCode or Antigravity changes, or the default --ide set
  - Changing the --ide claude transcript adapter
  - Summaries for untitled sessions (Desktop auto-titles every session)
  - Add test/ suites (AGENTS.md, GH-831)
related:
  - GH-1105
  - GH-901
  - GH-896
goal: >
  Stamp Claude Desktop sidebar session titles with each session's own
  last-activity mm-dd through a read-only planner plus the app's native
  set_session_title tool, verified live on one device.
---

# GH-1191 - task-sync: Claude Desktop sidebar titles (native planner)

## Status

| What was just completed | What's next |
|---|---|
| Built; probes 17/17 (Python 3.9 and 3.14) with red control; live smoke passed on one device | Route-selected gate, final Codex QA, PR |

## Key concepts

- Desktop owns its sidebar title in its own session record; the CLI transcript only holds a copy.
- Read-only planner over a native `list_sessions` snapshot (the GH-901 / GH-1105 claude-cloud pattern); `set_session_title` owns every write.
- Unattended runs cannot rename a user-set title (the tool declines); that is a skip, never an error.

## Scope

Steps 1–3 of [#1191](https://github.com/HiQS-Labs/XYZ-forge/issues/1191) only. Operator, 2026-10-24: "build Claude desktop app only adapter for now. Let's get Claude desktop working before tackling anything else."

| # | Requirement (from #1191) | Acceptance check |
|---|---|---|
| R1 | `--ide claude-desktop` read-only planner over a `list_sessions` snapshot | Probe battery (below) |
| R2 | Native sweep procedure in `SKILL.md` | Read from the consumer entry point; followed verbatim in the live smoke |
| R3 | Live verification on one device | Smoke receipt: sidebar title changed, rerun no-op, undo restored |

## Recon (base `45eb73a7`)

| Seam | Location | Finding |
|---|---|---|
| CLI wiring | `skills/3-weekly/task-sync/scripts/task_sync.py:37–60, 223–234` | `ADAPTERS`, `PLAN_ONLY`, `_build_adapter` module map and the `snapshots` table are the only registration points. Plan-only adapters already refuse `--apply`/`--set-title`/`--unpin-days`/`--group` and require a snapshot + `--exclude-thread`. |
| Pattern to mirror | `adapters/claude.py:276–354` `ClaudeCloudAdapter` | Snapshot load with 300 s freshness, ID/title validation, candidate filter, `core.clean_base(..., max_length=None)` + `core.local_stamp`, proposals only. |
| Shared helpers | `adapters/claude.py:37` `_iso_to_local`; `core.py` `clean_base`, `local_stamp`, `new_ide_report` | Reused unchanged. |
| Desktop store (observed on one device) | `~/Library/Application Support/Claude/claude-code-sessions/<account>/<org>/local_<id>.json` | Holds `title`, `titleSource` (`auto` here), `cliSessionId`, `lastActivityAt` (equal to `lastTurnEdgeAt`, i.e. turn activity). Read-only evidence; the adapter never reads this file. |
| Native tools | `list_sessions` (excludes the caller; `include_archived`, `limit`), `get_session`, `set_session_title(session_id, title)` | Rows carry `sessionId`, `title`, `isArchived`, `isRunning`, `lastActivityAt`. `set_session_title` replaces app-generated titles; a user-set title needs the operator's approval and is declined in unattended sessions. |
| Why `--ide claude` misses | GH-1105 local adapter appends `custom-title` to the transcript | Desktop wrote the transcript copy from its record; no evidence it reads appended lines back. |
| Coverage | No `test/` suite references task-sync; GH-1105 verified with `TESTS-RESULTS/2026-10-17+GH-1105/probes.py` | Same manual-probe route here. |

Untraced: whether `set_session_title` changes `lastActivityAt` or flips `titleSource` to user-set. Both are checked in the live smoke because they decide whether hourly re-stamping works unattended.

## Plan

1. **`ClaudeDesktopAdapter` in `adapters/claude.py`** beside `ClaudeCloudAdapter` (same module, same helpers, no new module):
   - Snapshot `{"captured_at": <Unix s>, "sessions": [<list_sessions rows>]}`, at most 300 s old; rows need a non-empty unique string `sessionId` and a string `title`. `--apply` refused.
   - Activity is the row's own `lastActivityAt`. There's no separate activity map, because Desktop already reports turn activity. Missing, unparseable or future (more than 60 s past `captured_at`) values on a candidate abort the sweep.
   - Skip `isArchived`, `isRunning`, the `--exclude-thread` session, and activity older than `--hours`.
   - Proposal `{task_id, old, new, activity_at}` where `new = mm-dd + clean_base(title, max_length=None)`; an already-stamped title proposes nothing.
   - An empty `sessions` list is a valid zero-candidate inventory, not a refusal: `list_sessions` excludes the caller, so a device whose only session is the sweeper legitimately returns none. The planner writes nothing, so empty can't trigger a destructive write. This differs from claude-cloud on purpose.
   -> expect the probe battery green.
2. **Wire it in `task_sync.py`:** add `claude-desktop` to `ADAPTERS` and `PLAN_ONLY`, map it to `adapters.claude`, add `--desktop-snapshot` and a `snapshots` entry, and update the help and docstring adapter lists. -> expect `--help` to list it and the existing modes to stay unchanged.
3. **`SKILL.md` "Claude Desktop (GH-1191)" section:** the native sweep procedure.
   1. `list_sessions(limit=100)` and require success.
   2. Write the snapshot to workspace `temp/`.
   3. Run the planner with `--exclude-thread <own id>` and require exit 0 and a null error.
   4. Before each target, `get_session` and require every candidate predicate to still hold: same title, not archived, not running, not the sweeping session, and the same `lastActivityAt`. Any change or missing field is a skip for this tick and a replan on the next.
   5. `set_session_title`; a decline (user-set title, unattended) is a skip.
   6. Re-read with `get_session` to confirm.
   7. Append `{at, session_id, old, new}` to the private undo receipt `~/.cache/task-sync/claude-desktop-renames.jsonl`.
   8. Stay quiet when unchanged.

   Also update the frontmatter description, the ideas list and the Claude Code section's pointer. -> expect the section to be followed verbatim in the smoke.
4. **Probes** `TESTS-RESULTS/2026-10-24+GH-1191/probes.py`, fixture snapshots only:
   - happy path;
   - archived, running, self and old rows skipped;
   - already stamped → no proposal (idempotent);
   - stale or invalid snapshot, missing or future activity, and duplicate ID refused;
   - `--apply`/`--set-title` and a missing `--exclude-thread` refused;
   - empty inventory → zero;
   - a claude-cloud snapshot probe and `--ide claude --doctor` unchanged.

   Red control: drop the `isRunning` skip in a copy and watch the running-row probe fail. -> expect all PASS, with the red control witnessed FAIL.
5. **Live smoke (R3) on this device:** start one throwaway Desktop session and let it go idle, then follow the SKILL procedure.
   - Main path: rename it and confirm the title through `get_session` and the sidebar.
   - Adjacent path: rerun, expecting no proposal, and check `lastActivityAt` (from `get_session`) after the rename. `titleSource` isn't returned by any native tool, so read it read-only from the throwaway's own Desktop record (`claude-code-sessions/<account>/<org>/local_<id>.json`, the Recon path) before and after the rename, and capture both values in the receipt. Then undo from the receipt and archive the throwaway.

   -> receipt and `provenance.jsonl` under `TESTS-RESULTS/2026-10-24+GH-1191/`.
6. **Gate:** route via `utils/ci-route.sh` on the final diff and run what it selects once; add a CHANGELOG entry.

## Bet check

- **Outcome sought:** the operator sees each Desktop session's last-activity date in the sidebar.
- **Smallest viable bet:** one planner class (about 60 lines), CLI wiring and one SKILL section. No scheduler change, no store reads, no new module.
- **Alternatives rejected:**
  - Writing `title` into Desktop's session JSON: an undocumented app store with no supported write path, and the app may overwrite it.
  - Reusing `--ide claude` transcript appends: shown not to reach the sidebar.
  - Folding into `claude-cloud`: different row shape and different candidates (`environment_kind`).
- **Rollback:** revert the PR. Live renames are listed in the undo receipt and reversible with `set_session_title`.

## Risks

- **A rename may mark the title as user-set.** Unattended hourly runs would then be declined from the second stamp on, so stamps would freeze. The smoke checks `titleSource`; if it flips, record that and bring the scheduler design (step 4) back to the operator before rollout.
- **A rename may bump `lastActivityAt`.** The stamp would then still be correct (the same day), but the recheck step must use the post-rename value. The smoke checks this.
- **Concurrent manual rename between recheck and write:** no compare-and-swap. The recheck narrows this but doesn't eliminate it (same caveat as Codex).

## Verification (no new test/ suites)

Manual probes and the live smoke, recorded under `TESTS-RESULTS/2026-10-24+GH-1191/` with `provenance.jsonl`.

Results (2026-10-24):
- **Probes:** 17/17 on Python 3.9.6 and 3.14.7. The red control (the `isRunning` skip removed in a scratch copy) went 15/17, failing the running-row and missing-flag probes.
- **Live smoke** (`live-smoke.md`): the full SKILL procedure renamed one idle Desktop session, and a rerun proposed nothing.
  - `lastActivityAt` is unchanged by a rename.
  - `titleSource` goes `auto` → `tool`, not user-set.
  - Undo from the receipt restored the title, and the stamp was re-applied.
- **Not witnessed:** whether an unattended (scheduled) run can re-stamp a `tool` title without approval. This session ran in bypass mode, where the tool never asks. Carry it to #1191 step 4.

## Plan QA

Codex relay `relay-system/2026-10-24/gh1191-plan-qa.md`, Approved in round 2 of 3.
- Round 1 returned FAIL with two `[Should]` findings, both implemented. First, the pre-write recheck now covers every candidate predicate (not archived, not the sweeping session). Second, `titleSource` is read from the throwaway's local record, because `get_session` doesn't return it.
- Round 2: PASS.

## Rating rationale (2026-10-24)

`rated 60/25/50/75`.
- `sev` 25: titles are cosmetic, with no data at risk, but the session list is hard to navigate across three Macs.
- `pri` 60: the operator put it ahead of everything else while travelling.
- `appeal` 50: neutral; no operator score given.
- `effort` 75: one planner class plus docs, reusing existing helpers.
- Recurrence: not applicable (feature); no same-class defects in the last 28 days beyond #1105's scope.
