# GH-1235 manual smoke: a Jog-hook `jog land` refusal still makes the reconcile writes durable

- **Date:** 2026-10-29
- **Platform:** macOS (Darwin arm64), Python 3
- **Base commit:** `510700a69dabaffffbb5c785a1487c7cef0de354`
- **Target surface:** `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (`run_post_merge_reconcile`)
- **Fixture:** Disposable temporary Git repository (`primary`) backed by a local bare remote (`origin.git` on `development`), with `run_local_wave_reconcile` stubbed to write `LEADERBOARD.md` (`reconciled PR #1225`) and `run_jog_post_merge_land` stubbed to log a refusal and return `False`.
- **No new test suite added** (GH-831).

## Case 1 — Fix (`run_post_merge_reconcile` via `--reconcile-pr 1225 --execute`)

 When `ok` is `True` after local reconciliation, `releases check`, and `pdda issue-doc-sync`, and `run_jog_post_merge_land` returns `False`, `run_post_merge_reconcile` invokes `commit_and_push_phase5_writes(pr_num, repo_path, integration_branch)`, logs the durability + Jog refusal diagnostic, and returns `False`.

```
=== CASE 1: FIX (Jog-hook refusal after good reconcile via --reconcile-pr) ===
caller exit code: 2
primary clean: True (status='')
level with origin/development: True (0a54361fcc == 0a54361fcc, advanced from 862722d49b: True)
head commit subject: 'chore: reconcile after PR #1225'
LEADERBOARD.md committed in HEAD: 'reconciled PR #1225'
stderr lines:
  merge-cleanup: ERROR — Jog landing GH-1235 / PR #1225 refused: simulated jog land refusal
  merge-cleanup: ERROR — Reconcile writes for PR #1225 were made durable; Jog completion failed (see the error above) — Jog rows are left exactly as they are; rerun releases jog land after fixing the cause.
```

- Reconcile writes (`LEADERBOARD.md`) are committed (`chore: reconcile after PR #1225`) and pushed to `origin/development`.
- Primary is clean (`git status --porcelain --untracked-files=all` is empty) and level with `origin/development`.
- `run_post_merge_reconcile` returns `False`, and the `--reconcile-pr` caller exits `2` without running a second commit.

## Case 2 — Base Red Control (pre-fix `return ok and run_jog_post_merge_land(...)`)

Running the same fixture against the pre-fix return statement (`return ok and run_jog_post_merge_land(pr_num, repo_path)`):

```
=== CASE 2: BASE RED CONTROL (pre-fix return ok and run_jog_post_merge_land) ===
run_post_merge_reconcile return: False
primary clean: False (status='?? LEADERBOARD.md')
head advanced from 862722d49b: False
```

- `run_post_merge_reconcile` returns `False` before `commit_and_push_phase5_writes` can run, leaving `LEADERBOARD.md` uncommitted in the primary working tree and `HEAD` unadvanced.

## Case 3 — Adjacent Guards

### 3A: Failing `releases check` stub
```
=== CASE 3A: ADJACENT (failing releases check stub) ===
run_post_merge_reconcile return: False
jog hook called: False
head advanced from 074110f326: False (uncommitted status='?? LEADERBOARD.md\n?? utils/py/releases_app.py')
```
- When `releases_app.py check` exits non-zero (`ok = False`), `run_post_merge_reconcile` returns `False` immediately without calling `run_jog_post_merge_land` or committing writes.

### 3B: Failing `pdda.sh issue-doc-sync` stub
```
=== CASE 3B: ADJACENT (failing pdda issue-doc-sync stub) ===
run_post_merge_reconcile return: False
jog hook called: False
head advanced from 074110f326: False (uncommitted status='?? LEADERBOARD.md\n?? utils/pdda/pdda.sh')
```
- When `pdda.sh issue-doc-sync` exits non-zero (`ok = False`), `run_post_merge_reconcile` returns `False` immediately without calling `run_jog_post_merge_land` or committing writes.

### 3C: Jog refusal + durable push failure
```
=== CASE 3C: ADJACENT (Jog refusal + durable push failure) ===
run_post_merge_reconcile return: False
claims durable: False
push error stands: True
```
- When `commit_and_push_phase5_writes` itself returns `False`, its own error stands and the `"were made durable"` line is not logged.

## Verdict

PASS.
