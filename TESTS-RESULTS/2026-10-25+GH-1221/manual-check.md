# GH-1221 Manual Check — `improve-loop.sh` pre/post-build snapshot, content manifest, and off-ALLOW restore

## Summary

Verified in throwaway git repositories under `$TMPDIR` with scripted `--build-cmd` invocations (never running the loop against this repository's tree with a live agent) across all required cases, both before the fix (**red control**) and after the fix (**green control**):

1. **Case (a) — Clean iteration with default settings**: running `improve-loop.sh` without `--state-dir` or `--allow` (default `ALLOW=$ARTIFACT`, default `STATE_DIR=$HERE/state/improve-loop.$$`) where `--build-cmd` only modifies `artifact.txt` (`50 -> 60`) is **accepted** (`CHAMPION 60`), not rejected by the loop's own state writes.
2. **Case (b) — Tracked file outside `ALLOW` changed**:
   - **Clean tracked file (`case_b_tracked_outside_allow`)**: `--build-cmd` modifies `artifact.txt` (`50 -> 60`) and alters `tracked_other.txt` (`clean-initial` mode `0644` -> `Tampered` mode `0755`).
     - **Red control (pre-fix)**: iteration accepted (`CHAMPION 60`), leaving `tracked_other.txt` dirty (`Tampered`, mode `0755`).
     - **Green control (post-fix)**: violation logged (`off-ALLOW write violation (tracked_other.txt) — restored snapshot`), iteration rejected (`CHAMPION 50`), `artifact.txt` rolled back to `50`, and `tracked_other.txt` restored to `HEAD` content (`clean-initial`) and mode (`0644`).
   - **Pre-existing dirty tracked file with distinct `HEAD`, index, and worktree state (`case_b2_pre_dirty_tracked_index_and_wt`)**: `tracked_other.txt` has `clean-initial` in `HEAD`, `staged-v2` in the Git index, and `worktree-v3` in the worktree before the build; `--build-cmd` overwrites and stages `builder-v4` (`git add tracked_other.txt`).
     - **Red control (pre-fix)**: iteration accepted (`CHAMPION 60`), leaving `builder-v4` in both the index and worktree.
     - **Green control (post-fix)**: violation detected (`off-ALLOW write violation (tracked_other.txt) — restored snapshot`), iteration rejected (`CHAMPION 50`), and both the Git index (`git diff --cached -- tracked_other.txt`) and worktree (`git diff -- tracked_other.txt`) are restored to their exact pre-build state (`staged-v2` staged, `worktree-v3` on disk).
3. **Case (c) — Untracked file created outside `ALLOW`**: `--build-cmd` creates `stray_untracked.txt`.
   - **Red control (pre-fix)**: iteration accepted (`CHAMPION 60`) and `stray_untracked.txt` survives in the tree.
   - **Green control (post-fix)**: violation logged (`off-ALLOW write violation (stray_untracked.txt) — restored snapshot`), iteration rejected (`CHAMPION 50`), `artifact.txt` rolled back to `50`, and `stray_untracked.txt` removed.
4. **Case (d) — Ignored paths (`cache/` in `.gitignore`)**:
   - **In-place mutation of pre-existing `cache/x`**: `cache/x` pre-exists with bytes `known-bytes-v1\n` and mode `0750`. `--build-cmd` overwrites `cache/x` in place (`mutated-in-place\n`, mode `0600`) with no new path created.
     - **Red control (pre-fix)**: iteration accepted (`CHAMPION 60`) and `cache/x` stays mutated (`mutated-in-place\n`, mode `0600`).
     - **Green control (post-fix)**: content/mode manifest detects the in-place modification to `cache/x`, logs `off-ALLOW write violation (cache/x) — restored snapshot`, rejects the iteration (`CHAMPION 50`), rolls `artifact.txt` back to `50`, and restores `cache/x` to its exact pre-build bytes (`known-bytes-v1\n`) and mode (`0750`).
   - **Newly created ignored sibling `cache/y`**: `cache/x` pre-exists (`known-bytes-v1\n`, mode `0750`) and `--build-cmd` creates a new ignored sibling `cache/y`.
     - **Red control (pre-fix)**: iteration accepted (`CHAMPION 60`) and `cache/y` remains on disk.
     - **Green control (post-fix)**: violation logged (`off-ALLOW write violation (cache/y) — restored snapshot`), iteration rejected (`CHAMPION 50`), `cache/y` is removed, and pre-existing `cache/x` is preserved untouched (`known-bytes-v1\n`, mode `0750`).

## Commands & Output

### 1. Throwaway Git Repo Red/Green Check (`$TMPDIR`)

Command:

```bash
python3 - <<'PYEOF'
import os, subprocess, tempfile, shutil, json

repo_root = os.getcwd()
old_il_bytes = subprocess.check_output(["git", "show", "e7e0c628ebf4424c082c4d6ab12de9e2e6f7ff54:relay-automation/improve-loop.sh"])

def run_cases(use_old=False):
    results = {}
    with tempfile.TemporaryDirectory(prefix="gh1221-probe-") as tmp:
        ra_src = os.path.join(repo_root, "relay-automation")
        ra_dst = os.path.join(tmp, "relay-automation")
        os.makedirs(ra_dst)
        for fn in ("improve-loop.sh", "measure.sh", "oracle-guard.sh", "champion.sh",
                   "loop-stop.sh", "heldout-check.sh", "loop-cost.sh"):
            shutil.copy2(os.path.join(ra_src, fn), os.path.join(ra_dst, fn))
        if use_old:
            with open(os.path.join(ra_dst, "improve-loop.sh"), "wb") as f:
                f.write(old_il_bytes)

        def init_repo(sub):
            d = os.path.join(tmp, sub)
            os.makedirs(d)
            shutil.copytree(ra_dst, os.path.join(d, "relay-automation"))
            subprocess.run(["git", "-C", d, "init", "-q", "-b", "main"], check=True)
            subprocess.run(["git", "-C", d, "config", "user.email", "test@invalid"], check=True)
            subprocess.run(["git", "-C", d, "config", "user.name", "test"], check=True)
            with open(os.path.join(d, ".gitignore"), "w") as f:
                f.write("cache/\n")
            with open(os.path.join(d, "artifact.txt"), "w") as f:
                f.write("50\n")
            with open(os.path.join(d, "tracked_other.txt"), "w") as f:
                f.write("clean-initial\n")
            os.chmod(os.path.join(d, "tracked_other.txt"), 0o644)
            subprocess.run(["git", "-C", d, "add", ".gitignore", "artifact.txt",
                            "tracked_other.txt", "relay-automation"], check=True)
            subprocess.run(["git", "-C", d, "commit", "-qm", "init"], check=True)
            return d

        # (a) clean iteration with default settings
        da = init_repo("case_a")
        p = subprocess.run(
            ["bash", "relay-automation/improve-loop.sh", "--artifact", "artifact.txt",
             "--measure-cmd", "cat artifact.txt", "--oracle-cmd", "true",
             "--build-cmd", "echo 60 > artifact.txt", "--goal", "max", "--max-iterations", "1"],
            cwd=da, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True
        )
        results["case_a_clean_default"] = {
            "rc": p.returncode,
            "accepted": "ACCEPT metric=60" in p.stdout and "CHAMPION 60" in p.stdout,
            "artifact_after": open(os.path.join(da, "artifact.txt")).read().strip(),
        }

        # (b) tracked file outside ALLOW changed -> detected, rejected, restored
        db = init_repo("case_b")
        p = subprocess.run(
            ["bash", "relay-automation/improve-loop.sh", "--artifact", "artifact.txt",
             "--measure-cmd", "cat artifact.txt", "--oracle-cmd", "true",
             "--build-cmd", "echo 60 > artifact.txt; echo Tampered > tracked_other.txt; chmod 755 tracked_other.txt",
             "--goal", "max", "--max-iterations", "1", "--state-dir", "state_b"],
            cwd=db, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True
        )
        st_b = os.lstat(os.path.join(db, "tracked_other.txt")).st_mode & 0o7777
        results["case_b_tracked_outside_allow"] = {
            "rc": p.returncode,
            "rejected": "CHAMPION 50" in p.stdout,
            "violation_logged": "off-ALLOW write" in p.stdout and "tracked_other.txt" in p.stdout,
            "tracked_other_content": open(os.path.join(db, "tracked_other.txt")).read().strip(),
            "tracked_other_mode": oct(st_b),
            "artifact_after": open(os.path.join(db, "artifact.txt")).read().strip(),
        }

        # (b2) pre-existing dirty tracked file (distinct HEAD, staged index, and worktree bytes) staged by build
        db2 = init_repo("case_b2")
        with open(os.path.join(db2, "tracked_other.txt"), "w") as f:
            f.write("staged-v2\n")
        subprocess.run(["git", "-C", db2, "add", "tracked_other.txt"], check=True)
        with open(os.path.join(db2, "tracked_other.txt"), "w") as f:
            f.write("worktree-v3\n")
        pre_cached = subprocess.check_output(["git", "-C", db2, "diff", "--cached", "--", "tracked_other.txt"], text=True)
        pre_wt = subprocess.check_output(["git", "-C", db2, "diff", "--", "tracked_other.txt"], text=True)
        p = subprocess.run(
            ["bash", "relay-automation/improve-loop.sh", "--artifact", "artifact.txt",
             "--measure-cmd", "cat artifact.txt", "--oracle-cmd", "true",
             "--build-cmd", "echo 60 > artifact.txt; printf 'builder-v4\\n' > tracked_other.txt; git add tracked_other.txt",
             "--goal", "max", "--max-iterations", "1", "--state-dir", "state_b2"],
            cwd=db2, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True
        )
        post_cached = subprocess.check_output(["git", "-C", db2, "diff", "--cached", "--", "tracked_other.txt"], text=True)
        post_wt = subprocess.check_output(["git", "-C", db2, "diff", "--", "tracked_other.txt"], text=True)
        results["case_b2_pre_dirty_tracked_index_and_wt"] = {
            "rc": p.returncode,
            "rejected": "CHAMPION 50" in p.stdout,
            "violation_logged": "off-ALLOW write" in p.stdout and "tracked_other.txt" in p.stdout,
            "tracked_other_content": open(os.path.join(db2, "tracked_other.txt")).read().strip(),
            "cached_diff_matches_pre": post_cached == pre_cached,
            "worktree_diff_matches_pre": post_wt == pre_wt,
            "artifact_after": open(os.path.join(db2, "artifact.txt")).read().strip(),
        }

        # (c) untracked file created -> detected, rejected, removed
        dc = init_repo("case_c")
        p = subprocess.run(
            ["bash", "relay-automation/improve-loop.sh", "--artifact", "artifact.txt",
             "--measure-cmd", "cat artifact.txt", "--oracle-cmd", "true",
             "--build-cmd", "echo 60 > artifact.txt; echo stray > stray_untracked.txt",
             "--goal", "max", "--max-iterations", "1", "--state-dir", "state_c"],
            cwd=dc, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True
        )
        results["case_c_untracked_created"] = {
            "rc": p.returncode,
            "rejected": "CHAMPION 50" in p.stdout,
            "violation_logged": "off-ALLOW write" in p.stdout and "stray_untracked.txt" in p.stdout,
            "stray_exists_after": os.path.exists(os.path.join(dc, "stray_untracked.txt")),
            "artifact_after": open(os.path.join(dc, "artifact.txt")).read().strip(),
        }

        # (d1) pre-existing ignored cache/x mutated in place -> detected, rejected, restored
        dd1 = init_repo("case_d1")
        os.makedirs(os.path.join(dd1, "cache"), exist_ok=True)
        cx1 = os.path.join(dd1, "cache", "x")
        with open(cx1, "wb") as f:
            f.write(b"known-bytes-v1\n")
        os.chmod(cx1, 0o750)
        p = subprocess.run(
            ["bash", "relay-automation/improve-loop.sh", "--artifact", "artifact.txt",
             "--measure-cmd", "cat artifact.txt", "--oracle-cmd", "true",
             "--build-cmd", "echo 60 > artifact.txt; printf 'mutated-in-place\\n' > cache/x; chmod 600 cache/x",
             "--goal", "max", "--max-iterations", "1", "--state-dir", "state_d1"],
            cwd=dd1, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True
        )
        st_d1 = os.lstat(cx1).st_mode & 0o7777
        results["case_d1_ignored_inplace"] = {
            "rc": p.returncode,
            "rejected": "CHAMPION 50" in p.stdout,
            "violation_logged": "off-ALLOW write" in p.stdout and "cache/x" in p.stdout,
            "cache_x_bytes": open(cx1, "rb").read().decode("utf-8"),
            "cache_x_mode": oct(st_d1),
            "artifact_after": open(os.path.join(dd1, "artifact.txt")).read().strip(),
        }

        # (d2) newly created ignored sibling cache/y -> detected, rejected, removed while cache/x stays intact
        dd2 = init_repo("case_d2")
        os.makedirs(os.path.join(dd2, "cache"), exist_ok=True)
        cx2 = os.path.join(dd2, "cache", "x")
        cy2 = os.path.join(dd2, "cache", "y")
        with open(cx2, "wb") as f:
            f.write(b"known-bytes-v1\n")
        os.chmod(cx2, 0o750)
        p = subprocess.run(
            ["bash", "relay-automation/improve-loop.sh", "--artifact", "artifact.txt",
             "--measure-cmd", "cat artifact.txt", "--oracle-cmd", "true",
             "--build-cmd", "echo 60 > artifact.txt; printf 'new-ignored-sibling\\n' > cache/y",
             "--goal", "max", "--max-iterations", "1", "--state-dir", "state_d2"],
            cwd=dd2, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True
        )
        st_d2 = os.lstat(cx2).st_mode & 0o7777
        results["case_d2_ignored_new_sibling"] = {
            "rc": p.returncode,
            "rejected": "CHAMPION 50" in p.stdout,
            "violation_logged": "off-ALLOW write" in p.stdout and "cache/y" in p.stdout,
            "cache_y_exists_after": os.path.exists(cy2),
            "cache_x_bytes": open(cx2, "rb").read().decode("utf-8"),
            "cache_x_mode": oct(st_d2),
            "artifact_after": open(os.path.join(dd2, "artifact.txt")).read().strip(),
        }
    return results

print("=== RED (pre-fix e7e0c628) ===")
print(json.dumps(run_cases(use_old=True), indent=2))
print("=== GREEN (post-fix) ===")
print(json.dumps(run_cases(use_old=False), indent=2))
PYEOF
```

Output:

```json
=== RED (pre-fix e7e0c628) ===
{
  "case_a_clean_default": {
    "rc": 0,
    "accepted": true,
    "artifact_after": "60"
  },
  "case_b_tracked_outside_allow": {
    "rc": 0,
    "rejected": false,
    "violation_logged": false,
    "tracked_other_content": "Tampered",
    "tracked_other_mode": "0o755",
    "artifact_after": "60"
  },
  "case_b2_pre_dirty_tracked_index_and_wt": {
    "rc": 0,
    "rejected": false,
    "violation_logged": false,
    "tracked_other_content": "builder-v4",
    "cached_diff_matches_pre": false,
    "worktree_diff_matches_pre": false,
    "artifact_after": "60"
  },
  "case_c_untracked_created": {
    "rc": 0,
    "rejected": false,
    "violation_logged": false,
    "stray_exists_after": true,
    "artifact_after": "60"
  },
  "case_d1_ignored_inplace": {
    "rc": 0,
    "rejected": false,
    "violation_logged": false,
    "cache_x_bytes": "mutated-in-place\n",
    "cache_x_mode": "0o600",
    "artifact_after": "60"
  },
  "case_d2_ignored_new_sibling": {
    "rc": 0,
    "rejected": false,
    "violation_logged": false,
    "cache_y_exists_after": true,
    "cache_x_bytes": "known-bytes-v1\n",
    "cache_x_mode": "0o750",
    "artifact_after": "60"
  }
}
=== GREEN (post-fix) ===
{
  "case_a_clean_default": {
    "rc": 0,
    "accepted": true,
    "artifact_after": "60"
  },
  "case_b_tracked_outside_allow": {
    "rc": 0,
    "rejected": true,
    "violation_logged": true,
    "tracked_other_content": "clean-initial",
    "tracked_other_mode": "0o644",
    "artifact_after": "50"
  },
  "case_b2_pre_dirty_tracked_index_and_wt": {
    "rc": 0,
    "rejected": true,
    "violation_logged": true,
    "tracked_other_content": "worktree-v3",
    "cached_diff_matches_pre": true,
    "worktree_diff_matches_pre": true,
    "artifact_after": "50"
  },
  "case_c_untracked_created": {
    "rc": 0,
    "rejected": true,
    "violation_logged": true,
    "stray_exists_after": false,
    "artifact_after": "50"
  },
  "case_d1_ignored_inplace": {
    "rc": 0,
    "rejected": true,
    "violation_logged": true,
    "cache_x_bytes": "known-bytes-v1\n",
    "cache_x_mode": "0o750",
    "artifact_after": "50"
  },
  "case_d2_ignored_new_sibling": {
    "rc": 0,
    "rejected": true,
    "violation_logged": true,
    "cache_y_exists_after": false,
    "cache_x_bytes": "known-bytes-v1\n",
    "cache_x_mode": "0o750",
    "artifact_after": "50"
  }
}
```

### 2. Existing Suites

```text
$ bash test/improve-loop.sh && bash test/improve-loop-qa.sh && bash test/improve-loop-dogfood.sh && bash test/champion.sh && bash test/gh430-state-dir-tracked-default.sh
== test: improve-loop ==
  improve-loop: 11 pass, 0 fail
== test: improve-loop-qa ==
  improve-loop-qa: 11 pass, 0 fail
== test: improve-loop-dogfood ==
  improve-loop-dogfood: 7 pass, 0 fail
== test: champion ==
  champion: 13 pass, 0 fail
== test: gh430-state-dir-tracked-default ==
  gh430-state-dir-tracked-default: 8 pass, 0 fail
```


## PR #1223 review follow-up (CodeRabbit, 2026-10-25)

Findings 4370486837 / 4370486839 / 4370486842 on `relay-automation/improve-loop.sh`. Probe: a throwaway repo per case, `--max-iterations 1`, run against `HEAD` (`cb1e2d50`, red) and the fixed tree (green).

| Case | Red (`cb1e2d50`) | Green (fix) |
|---|---|---|
| F1: loop run from **outside Git**; build edits off-ALLOW `other.txt` | no violation reported; `other.txt` stays `HACK` | `off-ALLOW write violation (other.txt)`; restored to `keep` |
| F2: allowed `out/result.txt` in a **new** dir; build creates only it | `off-ALLOW write violation (out)`; allowed file **deleted** | no violation (clean iteration accepted); file kept |
| F3: build **stages** allowed `allowed2.txt` and edits off-ALLOW `other.txt` | violation caught, but the allowed staged blob is **lost** (whole-index restore) | violation caught, `other.txt` restored; staged `allowed2.txt` kept |

Fixes:
- `REPO_ROOT` falls back to the artifact's repository.
- Structural parent directories of allowed paths are walked but not recorded (`is_allow_ancestor`), and new-directory cleanup removes only non-exempt files.
- Index restore uses `git update-index -z --index-info` for off-ALLOW paths only, replacing the whole-index copy.

Existing suites green after the fix: `improve-loop` 11/0, `improve-loop-qa` 11/0, `improve-loop-dogfood` 7/0, `champion` 13/0, `gh430-state-dir-tracked-default` 8/0, `security-scan` 35/0.


## PR #1223 review follow-up, round 2 (CodeRabbit, 2026-10-25)

Findings 4371191672 (glob ancestors) and 4371191676 (snapshot location). Red is `44e451ab`, green is the fix.

| Case | Red | Green |
|---|---|---|
| G1: allowed `out/*/result.txt`; build creates `out/a/result.txt` | `off-ALLOW write violation (out/a)` (false positive) | no violation; result kept |
| G2: pre-existing ancestor `out/` (allowed `out/result.txt`); build `chmod 700 out` | no violation; mode stays 700 | `off-ALLOW write violation (out)`; mode restored to 755 |
| G3: build wipes `STATE_DIR`, then edits off-ALLOW `other.txt` | `violation (snapshot-missing)`; `other.txt` stays `HACK` (no restore) | `violation (other.txt)`; restored to `keep` |

Fixes:
- Ancestors are now matched per path segment (`fnmatch`, `**`-aware).
- Ancestor directories keep their metadata in the manifest. Only *new* ancestors are structural.
- The guard snapshot moved to a private `mktemp -d` outside the repo and `STATE_DIR`, removed on exit. If `mktemp` fails, every iteration is rejected (fail closed).

Suites green: `improve-loop` 11/0, `improve-loop-qa` 11/0, `improve-loop-dogfood` 7/0, `champion` 13/0, `gh430` 8/0, `security-scan` 35/0.
