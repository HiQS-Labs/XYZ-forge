# RELAY · GH-165 Post-Merge Wave Reconciler — Implementation QA Review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded on 2026-08-22.
-->

NEXT: antigravity
STATUS: Open
ROUND: 1 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy, DeepSeek)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole implementation, not just the summary.**
     Declare it: every review block must contain a literal `swept file: yes` or `swept file: no` line.
     Any `[Pass]` or "verified"/"confirmed" finding MUST carry a quoted span or a `file:line` citation.
     Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh165-reconcile-impl-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first**. End your turn by naming who acts
   next and what they should do.

## Setup
- Artifact under review: **GH-165 Implementation** (`utils/py/wave_reconcile.py`, `test/wave-reconcile.sh`, `test/gh165-governance-canonical-paths-guard.sh`).
- Reviewer: deepseek   ·   Producer: antigravity
- Started: 2026-08-22

### Definition of Done for GH-165 Implementation
1. **Canonical Engine (`utils/py/wave_reconcile.py`):** Direct Python executable (no wrapper `.sh` shim per GH-551) acting as the sole post-merge lifecycle transition bridge.
2. **Merged PR Authority:** Moves active docs to `3-COMPLETED/` and derives badges strictly from merged PR metadata (`number`, `mergedAt`) on `development`. Asserts presence of `## Lessons Learned (For Future Agents)`. Routes unmerged/declined docs to `4-MISC/`.
3. **Hermetic Non-Mutating Dry-Run:** `--dry-run` performs zero network calls, cache writes, DB writes, or generated-file writes, proving byte-identical working tree state upon exit.
4. **Fail-Closed & Atomic Rollback:** Rejects dirty working trees (`git status --porcelain`) and rolls back all modifications via snapshot journal on any failure.
5. **Anti-Sprawl Static Guard:** `test/gh165-governance-canonical-paths-guard.sh` verifies in CI that no script outside `wave_reconcile.py` mutates docs, ROADMAP, or releases.
6. **Test Coverage:** All 9 assertions in `test/wave-reconcile.sh` and 4 assertions in `test/gh165-governance-canonical-paths-guard.sh` pass cleanly.

---

## Log

### Turn 2 — Reviewer (deepseek) — r1

**Review scope:** `utils/py/wave_reconcile.py` (533 lines), `test/wave-reconcile.sh` (230 lines, 9 assertions), `test/gh165-governance-canonical-paths-guard.sh` (74 lines, 4 assertions), `PROJECT/1-INBOX/GH-165-POST-MERGE-WAVE-RECONCILER.md` (66 lines).

**Verdict: Changes requested** — 2 blockers, 2 should-fix items, 1 nit. Resolve the blockers before approval.

---

#### 1. `[Blocker]` — `die()` bypasses rollback journal because `sys.exit()` raises `SystemExit`, not `Exception` (`wave_reconcile.py:30-33`)

The `die()` function calls `sys.exit(code)` which raises `SystemExit` (extends `BaseException`, not `Exception`). The main try/except at line 526 catches `Exception` only, so any `die()` call that fires *after* a mutation has been journaled will silently skip the rollback:

- **Real scenario:** In `update_roadmap_entry` (line 319), `die("Could not find '### Completed' section in ROADMAP.md")` fires after `validate_and_update_doc` has already moved the doc from `2-WORKING/` to `3-COMPLETED/` and removed the original. The journal has the backup, but rollback never runs — the working tree is left in a partially mutated state.
- **Also:** `die()` calls inside `run_subprocesses()` (line 366) and `run_validation_gate()` (line 381) after doc mutations have already been committed.

**Fix:** Change `except Exception as exc:` at line 526 to `except (Exception, SystemExit) as exc:`, or use `atexit.register` / `sys.excepthook` to guarantee rollback on any abnormal exit. Also consider wrapping `die()` to raise a custom `ReconcileError(Exception)` instead of calling `sys.exit` directly, so it's caught by the existing handler.

---

#### 2. `[Blocker]` — DoD item 2 requires routing unmerged/declined PR docs to `4-MISC/`; code rejects non-`MERGED` PRs with `die()` instead (`wave_reconcile.py:477-480`)

Definition of Done item 2: "Routes unmerged/declined docs to `4-MISC/`."

Current code at line 477-480:
```python
if state != "MERGED":
    die(f"PR #{pr_id} state is '{state}', not 'MERGED'. Only merged PRs can be reconciled.", code=4)
```

This hard-fails on any PR whose `state` is not `MERGED` (including `DECLINED`, `DRAFT`, `OPEN`). The DoD explicitly requires routing the associated active doc to `4-MISC/` instead. There is no `4-MISC` write path anywhere in the codebase for this tool (`grep -r "4-MISC" utils/py/` returns empty).

**Fix:** When PR state ≠ `MERGED`, move the matching active doc from `PROJECT/2-WORKING/` to `PROJECT/4-MISC/` (with frontmatter update to `status: Declined` or `status: Archived`) and log the outcome rather than dying. Add a test case for this path.

---

#### 3. `[Should]` — `--dry-run` without `--offline` still performs network call (`wave_reconcile.py:163-177`, line 473-475)

Definition of Done item 3 requires `--dry-run` to perform "zero network calls, cache writes, DB writes, or generated-file writes." Currently `fetch_pr_metadata()` on line 475 calls `gh pr view` (a network call to GitHub API) regardless of `--dry-run`, unless `--offline` is also passed. The dry-run test in `test/wave-reconcile.sh` passes only because it always pairs `--dry-run` with `--offline`, masking the gap.

**Fix:** Skip `fetch_pr_metadata()` in dry-run mode when `--offline` is not set, or automatically require `--offline` when `--dry-run` is active (and error with a helpful message otherwise). Alternatively, inject minimal synthetic PR metadata during dry-run.

---

#### 4. `[Should]` — `--gate`/`--require-receipts` flag is defined but never used (`wave_reconcile.py:429-435`, `args.require_receipts`)

The `--gate` / `--require-receipts` flag is parsed at line 429-435 with `dest="require_receipts"`, but the variable `args.require_receipts` is never read anywhere in `main()`. It is a dead flag — setting it has zero effect on behaviour.

**Fix:** Either implement the provenance-receipts enforcement logic and reference `args.require_receipts`, or remove the flag to avoid user confusion.

---

#### 5. `[Nit]` — Subprocess orchestration effects are not journaled (`wave_reconcile.py:334-366`)

`run_subprocesses()` calls `releases_app.py roadmap sync` which writes to `releases.db`, and `marathon-plan.sh` which may generate files. These effects are not covered by `RollbackJournal`. If a subprocess fails midway through the orchestration chain (e.g. `releases roadmap sync` succeeds but `export_timeline.py` fails), the journal restores file-level changes (doc moves, ROADMAP edits) but does not revert the DB or generated-file writes.

**Fix:** Either document this as a known limitation (the DB writes are re-runnable/idempotent) or add DB-specific snapshot/restore to the journal (e.g. `cp releases.db` before sync). Suggest documenting as a known limitation since the DoD already rolls back via the journal + subsequent `releases roadmap sync` is idempotent.

---

#### `[Pass]` items (verified against DoD)

- **DoD 1 — Canonical Engine:** Direct Python executable, no `.sh` wrapper (`utils/wave-reconcile.sh` absent — confirmed `ls` returns `No such file or directory`). `file:utils/py/wave_reconcile.py` — shebang line 1.
- **DoD 3 — Dry-run (to completion with `--offline`):** `bash test/wave-reconcile.sh` — test 3 ("Hermetic dry-run proves zero mutation") passes. `byte-state assertion: "Dry-run preserves exact byte-state of repo" → PASS`.
- **DoD 4 — Dirty-tree rejection:** `bash test/wave-reconcile.sh` — test 2 ("Dirty working tree is rejected (exit 3)") passes. `assert_eq: "Dirty working tree is rejected (exit 3)" → PASS`.
- **DoD 5 — Anti-sprawl guard:** `bash test/gh165-governance-canonical-paths-guard.sh` — all 4 assertions pass. Invariant 4 confirms "No new .sh wrapper in utils/ (GH-551 invariant preserved)".
- **DoD 6 — Test coverage:** 9/9 + 4/4 assertions pass = 13/13. Full output confirms zero failures.
- Frontmatter update: `grep -q "status: Complete" "$REPO/PROJECT/3-COMPLETED/GH-999-TEST.md"` — PASS.
- ROADMAP multiline entry preservation and SHIPPED badge: `grep -q "GH-999.*SHIPPED 2026-08-22 (PR #1001)" "$REPO/ROADMAP.md"` — PASS.
- `## Lessons Learned (For Future Agents)` assertion: test 4 ("Missing lessons learned is rejected (exit 5)") — PASS.
- `ReconcilerLock` prevents concurrent runs: `fcntl.flock` with `LOCK_EX | LOCK_NB` at line 45 — correct pattern.
- `pull_upstream()` correctly skipped in dry-run / offline / skip-pull modes (line 448).
- Active doc matched by issue number regex (lines 200-206): handles `GH-999` and `999` filename patterns.

**swept file: yes** — I have read and inspected all four artifacts in their entirety (533-line Python engine, 230-line test suite, 74-line guard script, 66-line capture doc). Every `[Pass]` above carries a concrete `file:line` or test-output citation.

---

**Hand-off:** antigravity to resolve the 2 blockers and 2 should-fix items above. Summary:
1. Fix rollback gap from `die()` → `SystemExit` not caught
2. Implement `4-MISC/` routing for unmerged/declined PRs (DoD item 2)
3. Make `--dry-run` hermetic without requiring `--offline`
4. Implement or remove dead `--gate` / `--require-receipts` flag

After resolution, bump to round 2 for re-review.

<!-- NEXT TURN APPENDS ABOVE THIS LINE -->
