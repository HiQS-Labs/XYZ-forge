# RELAY · GH-259 Jog Serial Immediate-Queue Implementation QA

NEXT: deepseek
STATUS: Open
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

NEXT: deepseek
