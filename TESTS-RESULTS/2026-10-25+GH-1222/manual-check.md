# GH-1222 Manual Check — `_live_manifest_count` and migration-004 backfill `COUNT(DISTINCT issue_ref_id)`

## Summary

Verified on a throwaway SQLite ledger under `$TMPDIR` (never touching the repository's `releases.db`) that:

1. **Red control (pre-fix `COUNT(*)`)**: when an issue is dialed into a release (`dialed_in`), shipped (`shipped`), and redialed (`dialed_in`), `manifest_items` holds two live rows for the same `issue_ref_id` (`state='shipped'` and `state='dialed_in'`). The pre-fix `SELECT COUNT(*) FROM manifest_items WHERE release_id = ? AND state IN ('dialed_in','shipped')` returns `2` (double-counting the single issue).
2. **Green control (post-fix `COUNT(DISTINCT issue_ref_id)`)**: `_live_manifest_count` and the migration-004 backfill query (`utils/py/releases_app.py:828-830,2522-2524`) return `1` for that shipped+redialed issue.
3. **Second distinct issue**: dialing a second distinct issue (`issues/2`) into the same release raises `_live_manifest_count` (and the captured `baseline_count` on `draft -> active`) to `2`.
4. **Existing suites**: `bash test/gh32-releases-app.sh` (145/145 passed) and `bash test/gh351-manifest-unship.sh` (13/13 passed) pass cleanly.

## Commands & Output

### 1. Throwaway DB Red/Green Check (`$TMPDIR`)

Command:

```bash
python3 - <<'PYEOF'
import tempfile, os, subprocess, importlib.util, json

app_path = os.path.abspath("utils/py/releases_app.py")
spec = importlib.util.spec_from_file_location("releases_app", app_path)
ra = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ra)

with tempfile.TemporaryDirectory(prefix="gh1222-live-") as tmp:
    subprocess.run(["git", "-C", tmp, "init", "-q", "-b", "main"], check=True)
    subprocess.run(["git", "-C", tmp, "config", "user.email", "test@invalid"], check=True)
    subprocess.run(["git", "-C", tmp, "config", "user.name", "test"], check=True)
    subprocess.run(["python3", app_path, "--root", tmp, "init", "--slug", "gh1222-test"],
                   check=True, stdout=subprocess.DEVNULL)
    out = subprocess.check_output([
        "python3", app_path, "--root", tmp, "add",
        "--version", "1.0.0", "--status", "draft",
        "--tracking-issue", "https://github.com/Org/Repo/issues/100",
        "--description", "v1.0.0"
    ], text=True)
    rel_gid = [w for w in out.split() if w.startswith("rel-")][0]

    # Dial issue #1, ship it, then redial it in the same release
    subprocess.run(["python3", app_path, "--root", tmp, "manifest", "dial-in",
                    "--gid", rel_gid, "https://github.com/Org/Repo/issues/1",
                    "--reason", "first dial"], check=True, stdout=subprocess.DEVNULL)
    subprocess.run(["python3", app_path, "--root", tmp, "manifest", "ship",
                    "--gid", rel_gid, "https://github.com/Org/Repo/issues/1",
                    "--evidence", "https://github.com/Org/Repo/pull/2"],
                   check=True, stdout=subprocess.DEVNULL)
    subprocess.run(["python3", app_path, "--root", tmp, "manifest", "dial-in",
                    "--gid", rel_gid, "https://github.com/Org/Repo/issues/1",
                    "--reason", "redial after ship"], check=True, stdout=subprocess.DEVNULL)

    conn = ra.connect(os.path.join(tmp, "releases.db"))
    rel_id = conn.execute("SELECT id FROM releases WHERE global_id = ?", (rel_gid,)).fetchone()[0]
    rows_state = [dict(r) for r in conn.execute(
        "SELECT issue_ref_id, state FROM manifest_items WHERE release_id = ? ORDER BY id",
        (rel_id,)).fetchall()]
    red_count_star = conn.execute(
        "SELECT COUNT(*) FROM manifest_items WHERE release_id = ? AND state IN ('dialed_in','shipped')",
        (rel_id,)).fetchone()[0]
    green_distinct_1 = ra._live_manifest_count(conn, rel_id)
    backfill_distinct_1 = conn.execute(
        "SELECT COUNT(DISTINCT issue_ref_id) FROM manifest_items WHERE release_id = ? AND state IN ('dialed_in','shipped')",
        (rel_id,)).fetchone()[0]
    conn.close()

    # Dial a second distinct issue (#2)
    subprocess.run(["python3", app_path, "--root", tmp, "manifest", "dial-in",
                    "--gid", rel_gid, "https://github.com/Org/Repo/issues/2",
                    "--reason", "second distinct issue"], check=True, stdout=subprocess.DEVNULL)
    conn = ra.connect(os.path.join(tmp, "releases.db"))
    green_distinct_2 = ra._live_manifest_count(conn, rel_id)
    conn.close()

    # Activate release -> captures write-once baseline_count via _live_manifest_count
    subprocess.run(["python3", app_path, "--root", tmp, "update",
                    "--gid", rel_gid, "--status", "active"], check=True, stdout=subprocess.DEVNULL)
    conn = ra.connect(os.path.join(tmp, "releases.db"))
    b_row = dict(conn.execute(
        "SELECT baseline_count, baseline_source FROM releases WHERE id = ?",
        (rel_id,)).fetchone())
    conn.close()

print(json.dumps({
    "rows_for_issue_1": rows_state,
    "red_control_count_star_1_issue": red_count_star,
    "green_live_manifest_count_1_issue": green_distinct_1,
    "green_migration_004_backfill_1_issue": backfill_distinct_1,
    "green_live_manifest_count_2_issues": green_distinct_2,
    "captured_baseline_on_activate": b_row,
}, indent=2))
PYEOF
```

Output:

```json
{
  "rows_for_issue_1": [
    {
      "issue_ref_id": 2,
      "state": "shipped"
    },
    {
      "issue_ref_id": 2,
      "state": "dialed_in"
    }
  ],
  "red_control_count_star_1_issue": 2,
  "green_live_manifest_count_1_issue": 1,
  "green_migration_004_backfill_1_issue": 1,
  "green_live_manifest_count_2_issues": 2,
  "captured_baseline_on_activate": {
    "baseline_count": 2,
    "baseline_source": "observed"
  }
}
```

### 2. Existing Releases Suites

```text
$ bash test/gh32-releases-app.sh
...
== gh32-releases-app: 145 passed, 0 failed ==

$ bash test/gh351-manifest-unship.sh
...
gh351: 13 passed, 0 failed
```
