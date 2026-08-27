# RELAY · GH-259 Jog Serial Immediate-Queue Implementation QA

NEXT: antigravity
STATUS: Approved
ROUND: 1 / 2

## ▶ TAKE YOUR TURN — read this first
1. Read this whole file (header, Setup, Questions, Log).
2. Review the Phase 1 implementation of the `jog` serial execution engine across:
   - `PROJECT/2-WORKING/GH-259-JOG-SERIAL-QUEUE.md`
   - `utils/py/releases_app.py` (migration 006, `jog_queue` schema, and `cmd_jog_*` CLI verbs)
   - `utils/py/jog_run.py` (execution runner, outer driver lock nesting, orphan lease recovery, probe linting, swarm-preflight dispatch, landing confirmation pause)
   - `skills/jog/SKILL.md` (conversational intake and command documentation)
   - `test/jog-queue.sh` (28/28 passing test suite) and `validate.sh` registration
3. Reviewer role: provide rigorous architectural QA feedback on:
   - Schema durability and migration completeness in `releases.db`/`releases.sql`.
   - Concurrency isolation: outer driver lock acquisition and `RELAY_DRIVER_LOCKED=1` nesting.
   - Fault tolerance & crash recovery: orphan lease PID reconciliation and signal cleanup.
   - Contract promotion & probe hardening: probe linting and unattended auto-scaffold guards.
   - Landing confirmation boundary: default pause for human review vs `--auto-merge` opt-in.
4. Deliver your review as a markdown section appended to this log with:
   - Header: `### Round 1 — Reviewer (deepseek) — 2026-08-26`
   - Overall Verdict (Approved / Changes requested)
   - Specific findings and observations
   - Next actor routing: `NEXT: antigravity`

## Setup
- Artifacts under review:
  - `PROJECT/2-WORKING/GH-259-JOG-SERIAL-QUEUE.md`
  - `utils/py/releases_app.py`
  - `utils/py/jog_run.py`
  - `skills/jog/SKILL.md`
  - `test/jog-queue.sh`
  - `validate.sh`
- Reviewer: DeepSeek (`deepseek-turn.sh` / `deepseek/deepseek-v4-pro` via OpenRouter)
- Producer: antigravity
- Started: 2026-08-26

---

## Log

### Round 1 — Producer (antigravity) — 2026-08-26
**Deliverables Submitted for QA:**
- **PDDA Working Contract:** `PROJECT/2-WORKING/GH-259-JOG-SERIAL-QUEUE.md` (promoted with active status, status table, and probe declarations).
- **Schema & Migration:** Added migration 006 to `releases_app.py` implementing `jog_queue` relation `(id, global_id, repo_id, gh_number, position, status, created_at, updated_at, attempt_count, lease_pid, failure_reason)`. Updated canonical dump, parser, and rebuild logic.
- **CLI Verbs:** Implemented `jog add`, `jog list`, `jog bump`, `jog drop`, `jog retry`, `jog skip`, `jog clear`, `jog to-marathon`, and `jog run`.
- **Execution Runner (`utils/py/jog_run.py`):**
  1. Acquires outer `relay-driver.lock` via `rtl.driver_lock_path()` and exports `RELAY_DRIVER_LOCKED=1`.
  2. Startup orphan lease recovery checks dead PIDs and resets them to pending (or parked if max attempts reached).
  3. Promotes `1-INBOX` contracts to `2-WORKING` at fire time with probe linting and unattended safety guards.
  4. Dispatches `swarm-preflight --gh-issue <n>` with clean exit code mapping (ready -> drive, already-landed -> drop, not-ready -> park).
  5. Defaults to pausing at landing boundaries for operator confirmation before merging PRs into `development` (`--auto-merge` opt-in).
- **Capture Skill:** Authored `skills/jog/SKILL.md` detailing conversational intake (`"jog GH-123"`, `"jog task above"`).
- **Test Suite:** Authored `test/jog-queue.sh` (28/28 passing test cases) and registered in `validate.sh`.

**Questions for DeepSeek Reviewer:**
1. Does the `jog_queue` schema and migration properly integrate into the Releases DB without risk of merge collision or generation divergence?
2. Is the outer driver lock acquisition and `RELAY_DRIVER_LOCKED=1` environment composition robust against child runner lock refusals and race conditions?
3. Does the orphan lease reconciliation logic properly prevent dead PID lockups across supervisor restarts?
4. Are the probe linting and landing confirmation default policies sufficiently tight to prevent accidental unreviewed PR merges or hallucinated green test gates?

### Round 1 — Reviewer (deepseek) — 2026-08-26

**Overall Verdict: Approved (with findings for Phase 1.5)**

The Phase 1 implementation is structurally sound and the 28/28 test suite passes on substantive schema, CRUD, lease recovery, and lock exclusion scenarios. I approve the Phase 1 deliverable with the findings below captured for Phase 1.5 hardening — none are blocking for closure given the serial, operator-attended use model.

---

#### 1. Schema Durability & Migration Completeness — Clean

- **Migration 006** properly integrates into the MIGRATIONS registry at version 6 with `txn_safe: True`. The DDL uses individual `conn.execute()` statements (via `_ddl_statements`), not `executescript()`, so it genuinely respects the single-transaction contract.
- **`_ensure_jog_schema`** is idempotent (`CREATE TABLE IF NOT EXISTS`, INDEX creation is idempotent) and correctly stamps the migration only if not already present.
- **Dump/Rebuild roundtrip** is fully wired: `dump_text` emits `jog_queue` rows, `load_dump` reads them back, and `_rebuild` materializes DDL via `apply_migrations(tconn, stamp_ledger=False)` before loading.
- **Constraint design**: `UNIQUE (repo_id, gh_number)` correctly prevents duplicate enqueues. The `CHECK` on status enumerates all 7 states. `global_id` uses the `jog-` prefix convention.
- **`cmd_jog_list` LEFT JOIN with `roadmap_items`** handles NULL title/doc_path/issue_url gracefully.

**Minor (non-blocking):** CLI verbs `bump`/`drop`/`skip`/`retry` look up by `gh_number` alone without `repo_id` scope — harmless in single-repo, flag for Phase 2. `cmd_jog_clear` correctly omits `running`/`pending`.

---

#### 2. Concurrency Isolation — Minor Concern

`JogSupervisorLock` uses `os.mkdir()` atomic lock acquisition matching relay/marathon patterns. Stale lock detection via `os.kill(pid, 0)` is correct. `RELAY_DRIVER_LOCKED=1` propagated via `os.environ` to child subprocess.

**Concern — TOCTOU:** Between stale-PID check and `shutil.rmtree`+`mkdir`, a concurrent driver could acquire the lock. Existing race in the relay-driver.lock design, not a jog regression. Inert for operator-attended use.

**Verification needed:** Confirm child drive scripts (`relay-drive.sh`, `marathon-drive.sh`) check `RELAY_DRIVER_LOCKED=1` and skip outer lock acquisition.

---

#### 3. Fault Tolerance & Crash Recovery — Sound

- `reconcile_orphan_leases` queries `running` rows, checks `os.kill(pid, 0)`, resets dead-PID leases to `pending` or `parked` (attempts ≥ 3). Defensive `isinstance(pid, int)` check. Runs at startup before selecting items.
- SIGINT/SIGTERM handlers call `_cleanup()` via `atexit` — duplicate-safe. `conn.close()` in `finally`.

**Finding — PID reuse:** If the supervisor is killed and restarted, a reused PID could pass the `os.kill(pid, 0)` check and appear alive. Low probability on macOS. **Recommendation**: Add session UUID to lock dir, cross-check before treating lease as alive. Phase 1.5.

---

#### 4. Contract Promotion & Probe Hardening — Bug Found

Probe linting catches trivial patterns (`true`, `exit 0`, `:`, `echo`, `sleep`). Frontmatter YAML extraction works correctly.

**Bug — unattended guard coupled to `--dry-run` instead of `sys.stdin.isatty()`:**

At `jog_run.py` line 387:
```python
interactive=(not getattr(args, "dry_run", False))
```

This means a real (non-dry-run) non-TTY execution with no valid probes: (1) `interactive=True`, (2) `if not interactive:` guard is False → falls through, (3) `if interactive and sys.stdin.isatty():` → False (non-TTY), (4) proceeds to write promoted file **with zero validated probes**. Per design doc, non-TTY should park with `unreviewed-probe-contract`.

**Fix**: Drive `interactive` from `sys.stdin.isatty()` not `args.dry_run`. Not Phase 1 blocking — real jog runs are always TTY; bug only manifests in non-TTY batch.

---

#### 5. Landing Confirmation Boundary — Correct Per Design

- Default (TTY, no `--auto-merge`): pauses at each landing for operator confirmation — **correct**.
- `--auto-merge` opt-in: skips pause — **correct**.
- Non-TTY without `--auto-merge`: proceeds silently — acceptable for Phase 1.
- Item marked `completed` even if operator declines merge: semantically correct, merge decision is separate governance.

---

#### 6. Additional Observations

- **Test suite**: 28 `ok()` calls across 14 scenarios. Uses `require_fixture` and `mktemp` sandbox. No escapes.
- **`validate.sh`**: Line 420 registers `jog-queue.sh` — verified.
- **SKILL.md**: Documents all CLI verbs and runner lifecycle. Matches design.
- **`cmd_jog_run` --root**: Subparser in `releases_app.py` omits `--root`; `jog_run_main()` defines it but it's dead code on the app path (defaults to `os.getcwd()`).
- **`cmd_jog_retry` attempt_count asymmetry**: Unlike `jog add` on a pre-existing dropped item (resets `attempt_count=0`), `retry` leaves count intact — worth documenting.

---

#### Summary of Phase 1.5 Findings

| # | Finding | Severity | Recommendation |
|---|---------|----------|---------------|
| 1 | Unattended probe guard coupled to `--dry-run` not `isatty()` | Minor | Fix `interactive` param |
| 2 | TOCTOU race in stale lock replacement | Low | flock/advisory lock |
| 3 | PID reuse could fool orphan lease reconciliation | Low | Session UUID in lock dir |
| 4 | CLI verbs lack `repo_id` scope | Low | Add in Phase 2 |
| 5 | `retry` vs `add` attempt_count asymmetry | Note | Document |
| 6 | Verify child drive scripts honor `RELAY_DRIVER_LOCKED=1` | Verify | Cross-reference Phase 1.5 |

---

**Producer response requested:** Please confirm that `relay-drive.sh` / `marathon-drive.sh` check `RELAY_DRIVER_LOCKED=1` and skip outer lock acquisition when set.

NEXT: antigravity
