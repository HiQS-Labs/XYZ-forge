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


def test_r3_1_git_refs_and_source_preservation(base_dir: Path):
    print("--- Falsifier 1: Git Refs & 100% Source Preservation (R3-1) ---")
    clone = base_dir / "clone1"
    clone.mkdir()
    subprocess.run(["git", "init", "-b", "main", str(clone)], check=True, capture_output=True)
    subprocess.run(["git", "-C", str(clone), "config", "user.name", "Test"], check=True)
    subprocess.run(["git", "-C", str(clone), "config", "user.email", "test@example.com"], check=True)
    (clone / "README.md").write_text("ok\n", encoding="utf-8")
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

    # Source code in root build/dist/target directories
    (clone / "build").mkdir()
    (clone / "build" / "release.py").write_text("# release tool\n", encoding="utf-8")
    (clone / "dist").mkdir()
    (clone / "dist" / "source.py").write_text("# dist source\n", encoding="utf-8")
    (clone / "target").mkdir()
    (clone / "target" / "config.py").write_text("# target config\n", encoding="utf-8")

    # Nested source code
    src_env = clone / "src" / "env"
    src_env.mkdir(parents=True, exist_ok=True)
    (src_env / "config.py").write_text("ENV = 'prod'\n", encoding="utf-8")

    # Disposable cache under node_modules
    nm = clone / "node_modules" / "pkg"
    nm.mkdir(parents=True, exist_ok=True)
    (nm / "index.js").write_text("console.log(1);\n", encoding="utf-8")

    backup_root = base_dir / "_backups"
    res = build_backup_layout([clone], backup_root=backup_root, repo_name="XYZ-forge", timestamp="r3_1_run")
    zip_path = Path(res["clones"][0]["zip_path"])

    preserved_files = [
        ("build/release.py", (clone / "build" / "release.py").read_bytes()),
        ("dist/source.py", (clone / "dist" / "source.py").read_bytes()),
        ("target/config.py", (clone / "target" / "config.py").read_bytes()),
        ("src/env/config.py", (clone / "src" / "env" / "config.py").read_bytes()),
        (".git/refs/heads/node_modules/topic", (clone / ".git" / "refs" / "heads" / "node_modules" / "topic").read_bytes()),
        (".git/refs/heads/venv/topic", (clone / ".git" / "refs" / "heads" / "venv" / "topic").read_bytes()),
        (".git/refs/heads/build/topic", (clone / ".git" / "refs" / "heads" / "build" / "topic").read_bytes()),
    ]

    with zipfile.ZipFile(zip_path, "r") as zf:
        nl = set(zf.namelist())
        for rel_path, expected_bytes in preserved_files:
            zip_entry = f"clone1/{rel_path}"
            assert zip_entry in nl, f"Expected {zip_entry} to be preserved in archive!"
            actual_bytes = zf.read(zip_entry)
            assert actual_bytes == expected_bytes, f"Byte mismatch on {zip_entry}!"
        assert "clone1/node_modules/pkg/index.js" not in nl, "Working tree node_modules was not excluded!"

    # Verify exclusion policy metadata
    manifest_file = Path(res["metadata_dir"]) / "manifest.json"
    manifest_data = json.loads(manifest_file.read_text(encoding="utf-8"))
    assert manifest_data["exclusion_policy"]["git_metadata_exempt"] is True

    print("PASS: Byte-for-byte read equality verified for all source (build/, dist/, target/, src/env/) and loose .git refs")
    print("PASS: Working-tree node_modules excluded from archive")
    print("PASS: manifest.json records git_metadata_exempt=True")


def test_r3_2_zip_integrity_detection(base_dir: Path):
    print("--- Falsifier 2: Zip Integrity Check & Corrupt Archive Detection (R3-2) ---")
    corrupt_file = base_dir / "corrupted_archive.zip"
    corrupt_file.write_bytes(b"PK\x03\x04\x00\x00\x00\x00not_a_valid_zip_payload_crc_failure")

    valid, err = test_zip_integrity(corrupt_file)
    assert valid is False, "test_zip_integrity failed to detect corrupt archive!"
    assert err is not None
    print(f"PASS: test_zip_integrity() detected corrupt archive: {err}")


def test_r3_3_linked_worktree_fail_closed(base_dir: Path):
    print("--- Falsifier 3: Linked Worktree Fail-Closed Refusal (R2-2) ---")
    parent = base_dir / "wt_parent"
    parent.mkdir()
    subprocess.run(["git", "init", "-b", "main", str(parent)], check=True, capture_output=True)
    subprocess.run(["git", "-C", str(parent), "config", "user.name", "Test"], check=True)
    subprocess.run(["git", "-C", str(parent), "config", "user.email", "test@example.com"], check=True)
    (parent / "README.md").write_text("parent\n", encoding="utf-8")
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


def test_r3_4_exclusive_run_allocation(base_dir: Path):
    print("--- Falsifier 4: Exclusive Run Allocation & Suffixing (R2-4) ---")
    p_a = base_dir / "parentA" / "repo"
    p_b = base_dir / "parentB" / "repo"
    p_a.mkdir(parents=True, exist_ok=True)
    p_b.mkdir(parents=True, exist_ok=True)
    subprocess.run(["git", "init", "-b", "main", str(p_a)], check=True, capture_output=True)
    subprocess.run(["git", "init", "-b", "main", str(p_b)], check=True, capture_output=True)
    (p_a / "a.txt").write_text("A\n", encoding="utf-8")
    (p_b / "b.txt").write_text("B\n", encoding="utf-8")

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


def test_r3_5_production_phase6_teardown_gate(base_dir: Path):
    print("--- Falsifier 5: Production Phase 6 Teardown Gate Execution (R2-3 / R3-2) ---")
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
    (primary / "README.md").write_text("primary\n", encoding="utf-8")
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

    orig_argv = sys.argv

    try:
        # Negative Control 1: linked worktree refused under backup-first
        wt_clone = prod_root / "wt_clone"
        subprocess.run(["git", "-C", str(primary), "worktree", "add", "-b", "feat/wt2", str(wt_clone)], check=True, capture_output=True)

        sys.argv = [
            "merge_cleanup.py",
            "--primary", str(primary),
            "--root", str(prod_root),
            "--teardown-only",
            "--allow-unready-primary",
            "--execute",
            "--backup-first",
        ]

        exit_code_wt = merge_cleanup.main()
        assert exit_code_wt == 2, f"Expected production merge_cleanup.main() to return 2 on refused worktree, got {exit_code_wt}"
        assert wt_clone.exists(), "Refused linked worktree must be preserved from teardown!"
        print("PASS: Production merge_cleanup.main() returned exit code 2 and preserved unverified worktree")

        # Clean up wt_clone manually for subsequent controls
        subprocess.run(["git", "-C", str(primary), "worktree", "remove", str(wt_clone)], check=True, capture_output=True)

        # Negative Control 2: corrupt archive detected -> teardown refused, clone preserved
        corrupt_clone = prod_root / "corrupt_clone"
        subprocess.run(["git", "clone", "-b", "development", str(bare_origin), str(corrupt_clone)], check=True, capture_output=True)
        subprocess.run(["git", "-C", str(corrupt_clone), "config", "user.name", "Test"], check=True)
        subprocess.run(["git", "-C", str(corrupt_clone), "config", "user.email", "test@example.com"], check=True)

        orig_test_zip = backup_clones.test_zip_integrity
        try:
            # Simulate CRC failure on corrupt_clone
            backup_clones.test_zip_integrity = lambda p: (False, "Simulated CRC failure") if "corrupt_clone" in str(p) else orig_test_zip(p)
            sys.argv = [
                "merge_cleanup.py",
                "--primary", str(primary),
                "--root", str(prod_root),
                "--teardown-only",
                "--allow-unready-primary",
                "--execute",
                "--backup-first",
            ]
            exit_code_corrupt = merge_cleanup.main()
            assert exit_code_corrupt == 2, f"Expected exit code 2 on corrupt archive, got {exit_code_corrupt}"
            assert corrupt_clone.exists(), "Corrupt candidate must be preserved from teardown!"
            print("PASS: Production merge_cleanup.main() rejected corrupt archive, withheld candidate, and exited 2")
        finally:
            backup_clones.test_zip_integrity = orig_test_zip

        # Witnessed Red Control: mutating the safeguard (bypassing Phase 6 verified_paths filter) destroys the candidate
        stale_record = {
            "path": str(corrupt_clone),
            "checkout_type": "standalone_clone",
            "disposition": "SAFE_REMOVE_CLONE",
            "scan_disposition": "SAFE_REMOVE_CLONE",
        }
        teardown_ok = teardown_checkout(stale_record, dry_run=False)
        assert teardown_ok is True
        assert not corrupt_clone.exists(), "Direct un-guarded teardown must delete the candidate!"
        print("PASS: Red control witnessed: without the Phase 6 verification gate, teardown proceeds and deletes candidate")

        # Positive Control: clean standalone clone backed up, verified, and torn down
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

        # Direct contract assertion: stale scan record refused
        stale_fake = {"path": str(prod_root / "fake"), "checkout_type": "standalone_clone", "disposition": "SAFE_REMOVE_CLONE"}
        assert teardown_checkout(stale_fake) is False, "teardown_checkout must refuse non-fresh Phase 6 records"
        print("PASS: Production teardown_checkout() correctly refused stale record")

    finally:
        scan_clones.DEFAULT_SAFE_ROOTS = orig_safe_roots
        merge_cleanup.fetch_open_prs_with_retry = orig_fetch_prs
        if orig_home:
            os.environ["HOME"] = orig_home
        sys.argv = orig_argv

    print("=== ALL PRODUCTION FALSIFIER CONTROLS PASSED ===")


def main():
    print("=== GH-839 Production Verification & Falsifiers (Codex R3 Review) ===")
    print(f'Timestamp: "{datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")}"')

    base_dir = REPO_ROOT / "temp" / "gh839-prod-falsifiers"
    if base_dir.exists():
        shutil.rmtree(base_dir)
    base_dir.mkdir(parents=True, exist_ok=True)

    test_r3_1_git_refs_and_source_preservation(base_dir)
    test_r3_2_zip_integrity_detection(base_dir)
    test_r3_3_linked_worktree_fail_closed(base_dir)
    test_r3_4_exclusive_run_allocation(base_dir)
    test_r3_5_production_phase6_teardown_gate(base_dir)


if __name__ == "__main__":
    main()
