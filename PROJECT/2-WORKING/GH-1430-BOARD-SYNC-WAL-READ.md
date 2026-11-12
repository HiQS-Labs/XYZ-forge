---
gh_issue: 1430
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1430
title: "board_sync: Rebalance WAL DB read fails under Apple SQLite mode=ro; open mode=rw with query_only"
status: Active (2-WORKING — PR ready; awaiting merge)
created: 2026-11-11
updated: 2026-11-11
owner: claude (start-task)
doc_type: feedback
complexity: 1
risk: 2
effort: 1
phases: 1
non_goals:
  - other Forge mode=ro readers (DELETE-journal DBs such as releases.db)
  - rebalanceOS db_connection_readonly (its callers run the venv Python)
  - Rebalance's journal mode, copying the DB, persisting any device config
related:
  - "#1421"
  - "#1429"
  - noelsaw1/noels-cross-project-tasks#87
goal: >
  board_sync's Rebalance repos_source reader opens the live WAL DB under the system Python
  (/usr/bin/python3, Apple SQLite) even when no other connection holds the -wal/-shm side files,
  without ever changing the DB's content, so #1421's include_agent_sessions reader takes effect.
---

## Status

| What was just completed | What's next |
|---|---|
| Plan QA Approved (Codex round 1, `relay-system/2026-11-11/gh1430-plan.codex.md`), `--accepted-start` recorded, implemented (`37676605d`), matrix 10/10 and live smoke recorded (`TESTS-RESULTS/2026-11-11+GH-1430/SUMMARY.md`), final QA Approved (Codex round 1, `relay-system/2026-11-11/gh1430-final.codex.md`). | Routed full gate, ready PR, awaiting merge. Outstanding: the live agent-only on/off check (no live repo is agent-only yet); re-run `smoke.sh` once one exists. |

## Key concepts

- `_rebalance_active_repos` (`utils/py/board_sync.py:135`) is the only reader of Rebalance's DB in Forge.
  It opens the DB with `?mode=ro` (line 159), `timeout=2`. Any open or query failure warns and returns `[]`,
  so the policy falls back to its pinned repos.
- `board_sync.py` runs under `#!/usr/bin/env python3`. On this Mac that is `/usr/bin/python3` 3.9.6
  with Apple SQLite 3.54.0. Rebalance's own jobs run its venv Python (3.13, SQLite 3.53.1).
- Apple's SQLite will not create the WAL `-shm`/`-wal` side files under `mode=ro`. When Rebalance has no
  connection open and its last close removed them, the read fails with "unable to open database file".

## Observed (recon, 2026-11-11, base 0f21b761a)

| Probe | Result |
|---|---|
| WAL fixture written and closed by the venv Python (side files removed). `/usr/bin/python3`, `mode=ro`, `select 1` | `unable to open database file` |
| Same fixture, `/usr/bin/python3`, `mode=rw` + `PRAGMA query_only=ON`, `select * from t` | `[(1,)]` |
| Same, `INSERT` on that connection | `attempt to write a readonly database` |
| A crash-left WAL (writer `os._exit` with `wal_autocheckpoint=0`, frames uncheckpointed), then `mode=rw` + `query_only`, read, close | Read OK, write refused. **Close checkpointed the committed frames into the main file** (4096 → 8192 bytes, sha changed, `-wal` truncated to 0). Logical content unchanged; see Risks |
| `repos_source` via `XYZ_GITHUB_BOARD_POLICY_REPOS_SOURCE` env | Not expressible: `resolve_device_block` env tier yields a string for a `None` default, and the resolver requires an object (`board_sync.py:205`). Affects the smoke only |
| Other `mode=ro` readers in Forge | Open DELETE-journal DBs (`releases.db`). Not affected (#87 §2) |

## Plan

Extend the existing reader `_rebalance_active_repos`. No new module, writer, env var, subcommand or test.

1. **Open.** Replace `?mode=ro` with `?mode=rw`, keep `uri=True, timeout=2`, and run
   `conn.execute("PRAGMA query_only=ON")` as the first statement inside the existing `try`, before any
   query. `mode=rw` never creates a missing file (unlike the default `rwc`), and the existing
   `is_file()` guard stays. Update the trailing `SQLITE-GATEWAY-OK` comment to say why: read-only by
   `query_only`, not by `mode=ro`, because Apple's SQLite cannot open a WAL DB with no side files under `mode=ro`.
2. **Hint wording.** The GH-1421 hint for "unable to open database file" with no side files described the
   `mode=ro` failure this removes. Under `mode=rw` that error with no side files still happens when the
   directory is not writable (SQLite cannot create `-shm`). Reword the hint to "this may be the WAL DB with
   no -shm sidecar in a directory SQLite cannot write (GH-1430)". The branch logic is unchanged.
3. **Docstring.** Replace "no `immutable` (the DB has a live writer)" with one sentence: opened `mode=rw` +
   `query_only` (GH-1430); `immutable` stays out because Rebalance writes live.
4. **CHANGELOG.** One entry.

`immutable=1` stays rejected. #1421's plan QA rejected it twice because it disables locking and change
detection and can return stale or torn reads while Rebalance writes.

### Preflight bet check

- *Outcome sought:* #1421's opt-in reader works on the device it was built for.
- *Smallest viable bet:* one connect-string change, one pragma, two wording updates.
  Not built: no DB copy, no journal-mode change, no Rebalance-side change, no retry.
- *Alternatives rejected:* `immutable=1` (stale or torn reads, rejected in #1421). Pinning board_sync to
  a newer Python (moves an interpreter dependency onto every device; out of scope). rebalanceOS keeping
  WAL side files persistently (cross-repo change for a one-reader problem). Copying the DB (needs a
  consistent snapshot, which needs the same open).
- *Rollback:* revert the one commit; behaviour returns to warn-and-fall-back.

### Risks

- **Checkpoint on close.** If Rebalance crashed and left committed frames in `-wal`, and board_sync is the
  last connection, closing our connection checkpoints those committed frames into the main file. That is a
  byte change but not a content change: it is the same checkpoint Rebalance's own next connection runs.
  `query_only` stops data changes, not checkpoints. Python 3.9's `sqlite3` cannot set
  `SQLITE_DBCONFIG_NO_CKPT_ON_CLOSE`. While Rebalance holds a connection, we are not the last connection and
  no checkpoint happens. Accepted and disclosed; the acceptance "bytes unchanged" claim is scoped to a
  cleanly closed DB.
- **Side files.** The open creates `-shm`/`-wal` when absent, as any Rebalance connection does. #1421's
  non-goal "no `mode=rw`, which would create sidecars" is superseded here by the operator's #87 decision.
- **Read-only directory.** Fails in both modes, warns and falls back (accepted, not this device's case).
- **Timeout.** `timeout=2` also covers the `query_only` pragma; a busy WAL reader does not block on writers.

## Acceptance (with verification)

All run under `/usr/bin/python3`. Evidence: `TESTS-RESULTS/2026-11-11+GH-1430/`. No new tests (AGENTS.md,
GH-831); a manual check matrix only.

- [x] **Red control:** a WAL fixture with no side files, read through `board_sync._rebalance_active_repos`
      (`REBALANCE_DB` pointed at the fixture): base commit `0f21b761a` warns and returns `[]`; the new
      code returns the fixture repos. The fixture must be non-empty (`github_activity` and
      `agent_session_activity` rows), so an empty result cannot pass.
- [x] **Write refusal:** with the same connect sequence, an `INSERT` fails with
      `attempt to write a readonly database`. The cleanly closed fixture's sha256 and mtime are unchanged
      after the reader runs.
- [x] **Missing file:** `REBALANCE_DB` pointing at a nonexistent path warns "not found" and returns `[]`;
      the path still does not exist afterwards.
- [ ] **Live smoke (#87 step 7), read-only** (partial: read path, `config` and `policy-preview` pass on the live DB, bytes unchanged; agent-only on/off outstanding because no live repo is agent-only): against the live Rebalance DB, resolve the policy with
      `project_owner`/`project_number`/`repos` from `XYZ_GITHUB_BOARD_POLICY_*` env and `repos_source`
      (`rebalance_active`, `include_agent_sessions` on) from a scratch file via `XYZ_DEVICE_CONFIG_PATH`,
      because the env tier cannot express an object (see Observed). Read path: `board_sync.py config`,
      which resolves the policy and makes no network call. `policy-preview` performs GitHub reads only and
      writes its `--out` file; run it too with `--out` in a scratch dir if `releases.db` work evidence is
      ready, otherwise record why not. An agent-only repo (in `agent_session_activity`, absent from
      `github_activity` in the window) appears in the resolved repos with the key on and is gone with it off.
      No write to `~/.xyz/device_config.json` or to the board. Record the live DB's sha256 and mtime
      before and after, and say whether Rebalance held it open.
- [ ] Routed gate at push passes.

## Rating rationale (2026-11-11)

`rated 60/55/50/95`. Severity 55: no data loss or crash, but #1421's merged feature does nothing on its
target device, and the only signal is a warning line. Priority 60: it blocks #87 steps 7 and 8.
Appeal 50 (neutral; no operator value). Effort 95: a one-line connect change. Recurrence (last 14 days
vs. the 14 before): one incident, first seen in #1421's recon on 2026-11-11; no earlier reports. Trend unknown.

## Dependencies

#1421 / PR #1429 (merged, `1ca887750`). No open prerequisite.

## Phase 1 — Implement and verify

Ordered list as in Plan 1–4, then the Acceptance matrix, then the live smoke.

## Lessons Learned

NO_ENTRY. Edit verdicts: `mode=rw` + `query_only` connect, helped (matrix red control); hint/docstring wording, no observed effect. The one candidate lesson ("system Python and venv Python differ in SQLite build, so probe under the shebang's interpreter") is already recorded in #87 §2 and rests on a single incident.
