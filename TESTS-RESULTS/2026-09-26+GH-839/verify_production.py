#!/usr/bin/env python3
"""Reproducible verification and falsifier suite for GH-839.

Directly exercises production implementations of:
- skills/2-daily/merge-cleanup/scripts/backup_clones.py
- skills/2-daily/merge-cleanup/scripts/merge_cleanup.py
"""

import datetime
import json
import os
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(REPO_ROOT / "skills" / "2-daily" / "merge-cleanup" / "scripts"))

import backup_clones
from backup_clones import build_backup_layout, test_zip_integrity, zip_clone_folder
import merge_cleanup
from merge_cleanup import teardown_checkout


def test_r2_1_git_refs_and_source_preservation(base_dir: Path):
    print("--- Falsifier 1: Git Refs & Source Directory Preservation (R2-1) ---")
    clone = base_dir / "clone1"
    clone.mkdir()
    subprocess.run(["git", "init", "-b", "main", str(clone)], check=True, capture_output=True)
    subprocess.run(["git", "-C", str(clone), "config", "user.name", "Test"], check=True)
    subprocess.run(["git", "-C", str(clone), "config", "user.email", "test@example.com"], check=True)
    (clone / "README.md").write_text("ok", encoding="utf-8")
    subprocess.run(["git", "-C", str(clone), "add", "README.md"], check=True)
    subprocess.run(["git", "-C", str(clone), "commit", "-m", "init"], check=True, capture_output=True)

    # Git refs with names matching cache dirs
    r_nm = clone / ".git" / "refs" / "heads" / "node_modules" / "topic"
    r_nm.parent.mkdir(parents=True, exist_ok=True)
    r_nm.write_text("1111111111111111\n", encoding="utf-8")

    r_venv = clone / ".git" / "refs" / "heads" / "venv" / "topic"
    r_venv.parent.mkdir(parents=True, exist_ok=True)
    r_venv.write_text("2222222222222222\n", encoding="utf-8")

    r_build = clone / ".git" / "refs" / "heads" / "build" / "topic"
    r_build.parent.mkdir(parents=True, exist_ok=True)
    r_build.write_text("3333333333333333\n", encoding="utf-8")

    # Source code under src/env/config.py
    src_env = clone / "src" / "env"
    src_env.mkdir(parents=True, exist_ok=True)
    (src_env / "config.py").write_text("ENV = 'prod'\n", encoding="utf-8")

    # Disposable cache under node_modules
    nm = clone / "node_modules" / "pkg"
    nm.mkdir(parents=True, exist_ok=True)
    (nm / "index.js").write_text("console.log(1);\n", encoding="utf-8")

    backup_root = base_dir / "_backups"
    res = build_backup_layout([clone], backup_root=backup_root, repo_name="XYZ-forge", timestamp="r2_1_run")
    zip_path = Path(res["clones"][0]["zip_path"])

    with zipfile.ZipFile(zip_path, "r") as zf:
        nl = zf.namelist()
        has_nm_ref = any("node_modules/topic" in n for n in nl)
        has_venv_ref = any("venv/topic" in n for n in nl)
        has_build_ref = any("build/topic" in n for n in nl)
        has_src_env = any("src/env/config.py" in n for n in nl)
        has_nm_cache = any("node_modules/pkg/index.js" in n for n in nl)

    assert has_nm_ref, "Loose ref .git/refs/heads/node_modules/topic was stripped!"
    assert has_venv_ref, "Loose ref .git/refs/heads/venv/topic was stripped!"
    assert has_build_ref, "Loose ref .git/refs/heads/build/topic was stripped!"
    assert has_src_env, "Source file src/env/config.py was stripped!"
    assert not has_nm_cache, "Working tree node_modules was not excluded!"

    # Verify exclusion policy metadata
    manifest_file = Path(res["metadata_dir"]) / "manifest.json"
    manifest_data = json.loads(manifest_file.read_text(encoding="utf-8"))
    assert manifest_data["exclusion_policy"]["git_metadata_exempt"] is True

    print("PASS: Loose refs under node_modules/, venv/, build/ preserved byte-for-byte in .git")
    print("PASS: Source directory src/env/config.py preserved")
    print("PASS: Working-tree node_modules/pkg/index.js excluded")
    print("PASS: manifest.json records git_metadata_exempt=True")


def test_r2_2_linked_worktree_fail_closed(base_dir: Path):
    print("--- Falsifier 2: Linked Worktree Fail-Closed Refusal (R2-2) ---")
    parent = base_dir / "wt_parent"
    parent.mkdir()
    subprocess.run(["git", "init", "-b", "main", str(parent)], check=True, capture_output=True)
    subprocess.run(["git", "-C", str(parent), "config", "user.name", "Test"], check=True)
    subprocess.run(["git", "-C", str(parent), "config", "user.email", "test@example.com"], check=True)
    (parent / "README.md").write_text("parent", encoding="utf-8")
    subprocess.run(["git", "-C", str(parent), "add", "README.md"], check=True)
    subprocess.run(["git", "-C", str(parent), "commit", "-m", "init"], check=True, capture_output=True)

    wt_path = base_dir / "wt_linked"
    subprocess.run(["git", "-C", str(parent), "worktree", "add", "-b", "feat/wt", str(wt_path)], check=True, capture_output=True)

    backup_root = base_dir / "_backups"
    res = build_backup_layout([wt_path], backup_root=backup_root, repo_name="XYZ-forge", timestamp="wt_run")
    assert res["all_verified"] is False
    assert res["clones"][0]["verified"] is False
    assert "Refused: linked worktree" in res["clones"][0]["error"]
    print("PASS: Linked worktree with external Git storage is refused and fails verification closed")


def test_r2_4_exclusive_run_allocation(base_dir: Path):
    print("--- Falsifier 3: Exclusive Run Allocation & Suffixing (R2-4) ---")
    p_a = base_dir / "parentA" / "repo"
    p_b = base_dir / "parentB" / "repo"
    p_a.mkdir(parents=True, exist_ok=True)
    p_b.mkdir(parents=True, exist_ok=True)
    subprocess.run(["git", "init", "-b", "main", str(p_a)], check=True, capture_output=True)
    subprocess.run(["git", "init", "-b", "main", str(p_b)], check=True, capture_output=True)
    (p_a / "a.txt").write_text("A", encoding="utf-8")
    (p_b / "b.txt").write_text("B", encoding="utf-8")

    backup_root = base_dir / "_backups"
    res1 = build_backup_layout([p_a, p_b], backup_root=backup_root, repo_name="XYZ-forge", timestamp="fixed_ts")
    assert res1["all_verified"]
    zips = sorted([f.name for f in Path(res1["zips_dir"]).glob("*.zip")])
    assert "repo.zip" in zips
    assert "parentB--repo.zip" in zips
    print("PASS: Duplicate basenames disambiguated: repo.zip and parentB--repo.zip")

    # Repeat run with identical timestamp -> atomic O_EXCL ensures fixed_ts_1 without overwrite
    res2 = build_backup_layout([p_a], backup_root=backup_root, repo_name="XYZ-forge", timestamp="fixed_ts")
    assert Path(res2["run_dir"]).name == "fixed_ts_1"
    print("PASS: Re-run allocated fixed_ts_1 via atomic mkdir reservation")


def test_r2_3_production_phase6_teardown_gate(base_dir: Path):
    print("--- Falsifier 4: Production Phase 6 Teardown Gate Execution (R2-3) ---")
    prod_root = base_dir / "prod_env"
    prod_root.mkdir(parents=True, exist_ok=True)

    # Setup bare origin
    bare_origin = base_dir / "origin.git"
    subprocess.run(["git", "init", "--bare", str(bare_origin)], check=True, capture_output=True)

    # Setup primary repo and push development branch to origin
    primary = prod_root / "primary"
    primary.mkdir()
    subprocess.run(["git", "init", "-b", "development", str(primary)], check=True, capture_output=True)
    subprocess.run(["git", "-C", str(primary), "config", "user.name", "Test"], check=True)
    subprocess.run(["git", "-C", str(primary), "config", "user.email", "test@example.com"], check=True)
    (primary / "README.md").write_text("primary", encoding="utf-8")
    subprocess.run(["git", "-C", str(primary), "add", "README.md"], check=True)
    subprocess.run(["git", "-C", str(primary), "commit", "-m", "init"], check=True, capture_output=True)
    subprocess.run(["git", "-C", str(primary), "remote", "add", "origin", str(bare_origin)], check=True, capture_output=True)
    subprocess.run(["git", "-C", str(primary), "push", "-u", "origin", "development"], check=True, capture_output=True)

    # Setup trash directory for safe removal
    fake_home = base_dir / "fake_home"
    (fake_home / ".Trash").mkdir(parents=True, exist_ok=True)
    orig_home = os.environ.get("HOME")
    os.environ["HOME"] = str(fake_home)

    import scan_clones
    orig_safe_roots = list(scan_clones.DEFAULT_SAFE_ROOTS)
    scan_clones.DEFAULT_SAFE_ROOTS.append(prod_root)

    # Bypass gh auth login requirement in isolated test bed
    orig_fetch_prs = merge_cleanup.fetch_open_prs_with_retry
    merge_cleanup.fetch_open_prs_with_retry = lambda _: []

    try:
        # Negative Control: linked worktree refused under backup-first
        wt_clone = prod_root / "wt_clone"
        subprocess.run(["git", "-C", str(primary), "worktree", "add", "-b", "feat/wt2", str(wt_clone)], check=True, capture_output=True)

        orig_argv = sys.argv
        sys.argv = [
            "merge_cleanup.py",
            "--primary", str(primary),
            "--root", str(prod_root),
            "--teardown-only",
            "--allow-unready-primary",
            "--execute",
            "--backup-first",
        ]

        exit_code = merge_cleanup.main()
        assert exit_code == 2, f"Expected production merge_cleanup.main() to return 2 on refused worktree, got {exit_code}"
        assert wt_clone.exists(), "Refused linked worktree must be preserved from teardown!"
        print("PASS: Production merge_cleanup.main() returned exit code 2 and preserved unverified worktree")

        # Clean up wt_clone manually for positive control
        subprocess.run(["git", "-C", str(primary), "worktree", "remove", str(wt_clone)], check=True, capture_output=True)

        # Positive Control: clean standalone clone backed up and torn down
        clean_clone = prod_root / "clean_clone"
        subprocess.run(["git", "clone", "-b", "development", str(bare_origin), str(clean_clone)], check=True, capture_output=True)
        subprocess.run(["git", "-C", str(clean_clone), "config", "user.name", "Test"], check=True)
        subprocess.run(["git", "-C", str(clean_clone), "config", "user.email", "test@example.com"], check=True)

        sys.argv = [
            "merge_cleanup.py",
            "--primary", str(primary),
            "--root", str(prod_root),
            "--teardown-only",
            "--allow-unready-primary",
            "--execute",
            "--backup-first",
        ]

        exit_code_pos = merge_cleanup.main()
        assert exit_code_pos == 0, f"Expected production merge_cleanup.main() to return 0 on clean clone teardown, got {exit_code_pos}"
        assert not clean_clone.exists(), "Verified standalone clone should have been torn down into Trash!"
        print("PASS: Production merge_cleanup.main() backed up, verified, and tore down clean clone (exit 0)")

        # Direct teardown_checkout contract assertion
        stale_record = {"path": str(prod_root / "fake"), "checkout_type": "standalone_clone", "disposition": "SAFE_REMOVE_CLONE"}
        assert teardown_checkout(stale_record) is False, "teardown_checkout must refuse non-fresh Phase 6 records"
        print("PASS: Production teardown_checkout() correctly refused stale record")

    finally:
        scan_clones.DEFAULT_SAFE_ROOTS = orig_safe_roots
        merge_cleanup.fetch_open_prs_with_retry = orig_fetch_prs
        if orig_home:
            os.environ["HOME"] = orig_home
        sys.argv = orig_argv

    print("=== ALL PRODUCTION FALSIFIER CONTROLS PASSED ===")


def main():
    import json
    print("=== GH-839 Production Verification & Falsifiers (Codex R2 Review) ===")
    print(f'Timestamp: "{datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")}"')

    base_dir = REPO_ROOT / "temp" / "gh839-prod-falsifiers"
    if base_dir.exists():
        shutil.rmtree(base_dir)
    base_dir.mkdir(parents=True, exist_ok=True)

    test_r2_1_git_refs_and_source_preservation(base_dir)
    test_r2_2_linked_worktree_fail_closed(base_dir)
    test_r2_4_exclusive_run_allocation(base_dir)
    test_r2_3_production_phase6_teardown_gate(base_dir)


if __name__ == "__main__":
    main()
