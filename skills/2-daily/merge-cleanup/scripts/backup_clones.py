#!/usr/bin/env python3
"""backup_clones.py — Standardized clone backup zipping & integrity verification.

Standardized hierarchy:
  <backup-root>/<repo-name>/<YYYY-MM-DD_HHMMSS>/
    ├── zips/
    │   ├── <clone-name>.zip
    │   └── ...
    ├── metadata/
    │   ├── MANIFEST.tsv
    │   ├── manifest.json
    │   ├── <clone-name>.git-summary.txt
    │   └── ...
    ├── reports/
    │   └── (triage reports / teardown logs)
    └── SUMMARY.md

Features:
- Fast, selective zipping: keeps .git and all code, excludes heavy disposable caches.
- Git metadata protected: .git contents and source directory names are never pruned.
- Automatic integrity gate: testzip() CRC check + SHA256 generation before teardown.
- Collision-proof naming: prevents overwriting existing archives or clobbering same-named clones.
- Self-contained worktree handling: bundles worktree administrative state into archive.
- Directory symlink support: both binary and pure Python fallback preserve directory symlinks.
- Standalone CLI, callable from /merge-cleanup and /merge-cleanup-deep.
"""

import argparse
import datetime
import hashlib
import json
import os
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple

# Working-tree disposable cache directories (excluded only OUTSIDE of .git)
WORKING_TREE_CACHE_DIRS: Set[str] = {
    "node_modules",
    ".venv",
    "venv",
    "__pycache__",
    ".pytest_cache",
    ".mypy_cache",
    ".ruff_cache",
    ".parcel-cache",
    ".cache",
    ".DS_Store",
}

# Top-level disposable build directories (excluded ONLY at the root of the working tree)
TOP_LEVEL_BUILD_DIRS: Set[str] = {
    "target",
    "build",
    "dist",
}


def compute_sha256(file_path: Path) -> str:
    """Compute hex SHA256 of a file in streaming chunks."""
    h = hashlib.sha256()
    with open(file_path, "rb") as f:
        while True:
            chunk = f.read(1024 * 1024)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


def test_zip_integrity(zip_path: Path) -> Tuple[bool, Optional[str]]:
    """Test zip archive integrity using Python's zipfile.testzip()."""
    if not zip_path.is_file() or zip_path.stat().st_size == 0:
        return False, "Archive is missing or 0 bytes"
    try:
        with zipfile.ZipFile(zip_path, "r") as zf:
            bad_file = zf.testzip()
            if bad_file is not None:
                return False, f"Corrupted file in archive: {bad_file}"
        return True, None
    except Exception as exc:
        return False, f"Failed reading archive: {exc}"


def get_git_info(clone_path: Path) -> Dict[str, Any]:
    """Extract branch, head commit, unpushed count, and dirty files from clone."""
    info: Dict[str, Any] = {
        "branch": "UNKNOWN",
        "head": "UNKNOWN",
        "is_linked_worktree": False,
        "gitdir_target": None,
        "dirty_files_count": 0,
        "dirty_files": [],
        "unpushed_count": 0,
        "recent_commits": [],
        "remote_urls": [],
        "summary_text": "",
    }
    git_entry = clone_path / ".git"
    if not git_entry.exists():
        info["summary_text"] = f"Warning: {clone_path} is not a valid git repository (no .git found)."
        return info

    if git_entry.is_file():
        info["is_linked_worktree"] = True
        try:
            content = git_entry.read_text(encoding="utf-8").strip()
            if content.startswith("gitdir:"):
                info["gitdir_target"] = content.split(":", 1)[1].strip()
        except Exception:
            pass

    def _run_git(args: List[str]) -> Tuple[int, str]:
        try:
            res = subprocess.run(
                ["git", "-C", str(clone_path)] + args,
                capture_output=True,
                text=True,
                check=False,
                timeout=30,
            )
            return res.returncode, res.stdout.strip()
        except Exception as exc:
            return 1, str(exc)

    # Branch
    rc, out = _run_git(["rev-parse", "--abbrev-ref", "HEAD"])
    if rc == 0 and out:
        info["branch"] = out

    # HEAD SHA
    rc, out = _run_git(["rev-parse", "HEAD"])
    if rc == 0 and out:
        info["head"] = out[:10]

    # Remotes
    rc, out = _run_git(["remote", "-v"])
    if rc == 0 and out:
        info["remote_urls"] = out.splitlines()

    # Dirty status
    rc, out = _run_git(["status", "--porcelain=v1", "--untracked-files=all"])
    if rc == 0 and out:
        lines = [line.strip() for line in out.splitlines() if line.strip()]
        info["dirty_files"] = lines
        info["dirty_files_count"] = len(lines)

    # Recent commits (last 10)
    rc, out = _run_git(["log", "-n", "10", "--oneline"])
    if rc == 0 and out:
        info["recent_commits"] = out.splitlines()

    # Unpushed commits against tracking branch or origin/development
    unpushed_target = f"origin/{info['branch']}"
    rc, out = _run_git(["rev-parse", "--verify", unpushed_target])
    if rc != 0:
        unpushed_target = "origin/development"
        rc, out = _run_git(["rev-parse", "--verify", unpushed_target])

    if rc == 0:
        rc, out = _run_git(["log", f"{unpushed_target}..HEAD", "--oneline"])
        if rc == 0 and out:
            info["unpushed_count"] = len([l for l in out.splitlines() if l.strip()])

    # Build summary text
    type_str = "Linked Worktree" if info["is_linked_worktree"] else "Standalone Clone"
    summary_lines = [
        f"Clone: {clone_path.name}",
        f"Path: {clone_path.resolve()}",
        f"Type: {type_str}",
    ]
    if info["gitdir_target"]:
        summary_lines.append(f"Linked Gitdir: {info['gitdir_target']}")
    summary_lines.extend([
        f"Branch: {info['branch']}",
        f"HEAD: {info['head']}",
        f"Dirty Files ({info['dirty_files_count']}):",
    ])
    for d in info["dirty_files"][:50]:
        summary_lines.append(f"  {d}")
    if len(info["dirty_files"]) > 50:
        summary_lines.append(f"  ... and {len(info['dirty_files']) - 50} more")

    summary_lines.append("\nRecent Commits (last 10):")
    for c in info["recent_commits"]:
        summary_lines.append(f"  {c}")

    summary_lines.append("\nRemotes:")
    for r in info["remote_urls"]:
        summary_lines.append(f"  {r}")

    info["summary_text"] = "\n".join(summary_lines)
    return info


def zip_clone_folder(
    clone_path: Path,
    dest_zip_path: Path,
    exclude_caches: bool = True,
    dry_run: bool = False,
) -> Tuple[bool, Optional[str]]:
    """Create a zip archive of a clone folder, preserving Git metadata and code.

    Excludes heavy disposable caches outside .git, preserves directory symlinks,
    and bundles linked worktree administration if applicable.
    """
    if dry_run:
        return True, None

    dest_zip_path.parent.mkdir(parents=True, exist_ok=True)
    if dest_zip_path.exists():
        return False, f"Destination archive already exists: {dest_zip_path}"

    parent_dir = clone_path.parent
    clone_name = clone_path.name

    git_entry = clone_path / ".git"
    linked_gitdir: Optional[Path] = None
    if git_entry.is_file():
        try:
            content = git_entry.read_text(encoding="utf-8").strip()
            if content.startswith("gitdir:"):
                raw_gd = content.split(":", 1)[1].strip()
                p_gd = Path(raw_gd)
                if not p_gd.is_absolute():
                    p_gd = (clone_path / p_gd).resolve()
                if p_gd.exists() and p_gd.is_dir():
                    linked_gitdir = p_gd
        except Exception:
            pass

    zip_bin = shutil.which("zip")
    if zip_bin:
        cmd = [zip_bin, "-ryq", str(dest_zip_path.resolve()), clone_name]
        if exclude_caches:
            # Explicitly exclude caches outside .git
            for exc in sorted(WORKING_TREE_CACHE_DIRS):
                cmd.extend(["-x", f"*/{exc}/*", f"*/{exc}"])
            # Root-level only build directories
            for b_dir in sorted(TOP_LEVEL_BUILD_DIRS):
                cmd.extend(["-x", f"{clone_name}/{b_dir}/*", f"{clone_name}/{b_dir}"])
        try:
            res = subprocess.run(cmd, cwd=str(parent_dir), capture_output=True, text=True, check=False)
            if res.returncode != 0:
                return False, f"zip binary exited with code {res.returncode}: {res.stderr.strip()}"

            # If linked worktree, append the worktree administrative state to make it self-contained
            if linked_gitdir and linked_gitdir.is_dir():
                with zipfile.ZipFile(dest_zip_path, "a", compression=zipfile.ZIP_DEFLATED) as zf:
                    for root, dirs, files in os.walk(linked_gitdir):
                        for file in files:
                            full_f = Path(root) / file
                            rel_admin = Path(clone_name) / ".git_admin" / full_f.relative_to(linked_gitdir)
                            if full_f.is_file():
                                zf.write(full_f, str(rel_admin))
            return True, None
        except Exception as exc:
            return False, f"Failed running zip command: {exc}"

    # Pure Python zipfile fallback
    try:
        with zipfile.ZipFile(dest_zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
            for root, dirs, files in os.walk(clone_path):
                rel_from_clone = Path(root).relative_to(clone_path)
                in_git = len(rel_from_clone.parts) > 0 and rel_from_clone.parts[0] == ".git"

                # Check for directory symlinks in dirs to avoid dropping them
                dirs_to_remove = []
                for d in list(dirs):
                    full_d = Path(root) / d
                    if full_d.is_symlink():
                        dirs_to_remove.append(d)
                        rel_d = Path(clone_name) / rel_from_clone / d
                        zi = zipfile.ZipInfo(str(rel_d))
                        zi.create_system = 3  # Unix
                        zi.external_attr = 0o120777 << 16  # symlink
                        zf.writestr(zi, os.readlink(full_d))
                    elif exclude_caches and not in_git:
                        if d in WORKING_TREE_CACHE_DIRS:
                            dirs_to_remove.append(d)
                        elif len(rel_from_clone.parts) == 0 and d in TOP_LEVEL_BUILD_DIRS:
                            dirs_to_remove.append(d)

                for d in dirs_to_remove:
                    dirs.remove(d)

                for file in files:
                    if exclude_caches and not in_git:
                        if file in WORKING_TREE_CACHE_DIRS:
                            continue
                    full_p = Path(root) / file
                    rel_p = Path(clone_name) / rel_from_clone / file
                    if full_p.is_symlink():
                        zi = zipfile.ZipInfo(str(rel_p))
                        zi.create_system = 3
                        zi.external_attr = 0o120777 << 16
                        zf.writestr(zi, os.readlink(full_p))
                    elif full_p.is_file():
                        zf.write(full_p, str(rel_p))

            if linked_gitdir and linked_gitdir.is_dir():
                for root, dirs, files in os.walk(linked_gitdir):
                    for file in files:
                        full_f = Path(root) / file
                        rel_admin = Path(clone_name) / ".git_admin" / full_f.relative_to(linked_gitdir)
                        if full_f.is_file():
                            zf.write(full_f, str(rel_admin))

        return True, None
    except Exception as exc:
        return False, f"Pure Python zipping failed: {exc}"


def build_backup_layout(
    clones: List[Path],
    backup_root: Path,
    repo_name: str,
    timestamp: Optional[str] = None,
    exclude_caches: bool = True,
    dry_run: bool = False,
) -> Dict[str, Any]:
    """Execute clone backups and assemble the standardized directory hierarchy."""
    if not timestamp:
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H%M%S")

    run_dir = backup_root / repo_name / timestamp
    # Ensure run_dir is unique and does not overwrite existing run
    if not dry_run and run_dir.exists() and any(run_dir.iterdir()):
        counter = 1
        while (backup_root / repo_name / f"{timestamp}_{counter}").exists():
            counter += 1
        timestamp = f"{timestamp}_{counter}"
        run_dir = backup_root / repo_name / timestamp

    zips_dir = run_dir / "zips"
    meta_dir = run_dir / "metadata"
    reports_dir = run_dir / "reports"

    result: Dict[str, Any] = {
        "status": "OK",
        "run_dir": str(run_dir),
        "zips_dir": str(zips_dir),
        "metadata_dir": str(meta_dir),
        "reports_dir": str(reports_dir),
        "timestamp": timestamp,
        "repo_name": repo_name,
        "clones": [],
        "all_verified": True,
        "total_bytes": 0,
    }

    if not dry_run:
        zips_dir.mkdir(parents=True, exist_ok=True)
        meta_dir.mkdir(parents=True, exist_ok=True)
        reports_dir.mkdir(parents=True, exist_ok=True)

    manifest_rows: List[Dict[str, Any]] = []
    seen_zip_names: Set[str] = set()

    for clone_path in clones:
        clone_name = clone_path.name
        # Collision prevention: disambiguate duplicate basenames
        zip_base_name = clone_name
        if zip_base_name in seen_zip_names:
            parent_slug = clone_path.parent.name
            zip_base_name = f"{parent_slug}--{clone_name}"
            if zip_base_name in seen_zip_names:
                suffix_idx = 1
                while f"{zip_base_name}_{suffix_idx}" in seen_zip_names:
                    suffix_idx += 1
                zip_base_name = f"{zip_base_name}_{suffix_idx}"
        seen_zip_names.add(zip_base_name)

        clone_info = get_git_info(clone_path)
        dest_zip = zips_dir / f"{zip_base_name}.zip"

        clone_record: Dict[str, Any] = {
            "clone": clone_name,
            "path": str(clone_path),
            "archive_name": f"{zip_base_name}.zip",
            "branch": clone_info["branch"],
            "head": clone_info["head"],
            "is_linked_worktree": clone_info["is_linked_worktree"],
            "dirty_files": clone_info["dirty_files_count"],
            "unpushed_commits": clone_info["unpushed_count"],
            "zip_path": str(dest_zip),
            "zip_bytes": 0,
            "zip_sha256": "",
            "verified": False,
            "error": None,
        }

        if dry_run:
            clone_record["verified"] = True
            manifest_rows.append(clone_record)
            result["clones"].append(clone_record)
            continue

        # 1. Write per-clone git summary metadata
        summary_file = meta_dir / f"{zip_base_name}.git-summary.txt"
        summary_file.write_text(clone_info["summary_text"], encoding="utf-8")

        # 2. Perform zipping
        ok, err = zip_clone_folder(clone_path, dest_zip, exclude_caches=exclude_caches, dry_run=False)
        if not ok:
            clone_record["error"] = err
            result["all_verified"] = False
            manifest_rows.append(clone_record)
            result["clones"].append(clone_record)
            continue

        # 3. Verify zip integrity
        valid, ver_err = test_zip_integrity(dest_zip)
        if not valid:
            clone_record["error"] = ver_err
            result["all_verified"] = False
            manifest_rows.append(clone_record)
            result["clones"].append(clone_record)
            continue

        # 4. Measure bytes & compute SHA256
        sha = compute_sha256(dest_zip)
        size = dest_zip.stat().st_size
        clone_record["zip_bytes"] = size
        clone_record["zip_sha256"] = sha
        clone_record["verified"] = True
        result["total_bytes"] += size

        manifest_rows.append(clone_record)
        result["clones"].append(clone_record)

    if not dry_run:
        # Write MANIFEST.tsv
        tsv_path = meta_dir / "MANIFEST.tsv"
        with open(tsv_path, "w", encoding="utf-8") as f:
            f.write("clone\tbranch\thead\tdirty_files\tunpushed_commits\tzip_sha256\tzip_bytes\tverified\n")
            for r in manifest_rows:
                ver_str = "PASS" if r["verified"] else "FAIL"
                f.write(
                    f"{r['clone']}\t{r['branch']}\t{r['head']}\t{r['dirty_files']}\t"
                    f"{r['unpushed_commits']}\t{r['zip_sha256']}\t{r['zip_bytes']}\t{ver_str}\n"
                )

        # Write manifest.json
        json_path = meta_dir / "manifest.json"
        json_path.write_text(json.dumps(result, indent=2), encoding="utf-8")

        # Write SUMMARY.md
        summary_md_path = run_dir / "SUMMARY.md"
        total_mb = result["total_bytes"] / (1024 * 1024)
        md_lines = [
            f"# Clone Backup Run — {repo_name} ({timestamp})",
            "",
            f"- **Date**: {datetime.datetime.now().isoformat()}",
            f"- **Total Clones Backed Up**: {len(manifest_rows)}",
            f"- **Total Archive Size**: {total_mb:.2f} MB ({result['total_bytes']} bytes)",
            f"- **Integrity Verification**: {'ALL VERIFIED PASS' if result['all_verified'] else 'FAILURES DETECTED'}",
            "",
            "## Backup Inventory",
            "",
            "| Clone | Branch | HEAD | Type | Dirty | Unpushed | Size (MB) | SHA256 (first 12) | Status |",
            "|---|---|---|---|---|---|---|---|---|",
        ]
        for r in manifest_rows:
            mb = r["zip_bytes"] / (1024 * 1024)
            sha12 = r["zip_sha256"][:12] if r["zip_sha256"] else "-"
            st = "✅ PASS" if r["verified"] else f"❌ FAIL ({r['error']})"
            ctype = "Worktree" if r["is_linked_worktree"] else "Clone"
            md_lines.append(
                f"| `{r['clone']}` | `{r['branch']}` | `{r['head']}` | {ctype} | {r['dirty_files']} | {r['unpushed_commits']} | {mb:.2f} | `{sha12}` | {st} |"
            )
        summary_md_path.write_text("\n".join(md_lines) + "\n", encoding="utf-8")

    if not result["all_verified"]:
        result["status"] = "ERROR"

    return result


def resolve_primary_and_root(
    primary_arg: Optional[str] = None,
    root_arg: Optional[str] = None,
) -> Tuple[Path, Path]:
    """Determine primary checkout and top-level root directory."""
    if primary_arg:
        primary = Path(primary_arg).resolve()
    else:
        try:
            out = subprocess.check_output(
                ["git", "rev-parse", "--show-toplevel"],
                stderr=subprocess.DEVNULL,
                text=True,
            ).strip()
            primary = Path(out).resolve()
        except Exception:
            primary = Path.cwd().resolve()

    if root_arg:
        root = Path(root_arg).resolve()
    else:
        root = primary.parent

    return primary, root


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Standardized clone backup zipping and integrity verification."
    )
    parser.add_argument("--primary", type=str, help="Path to primary repository checkout.")
    parser.add_argument("--root", type=str, help="Top-level parent directory containing sibling clones.")
    parser.add_argument("--clones", nargs="*", help="Specific clone directory paths or names to back up.")
    parser.add_argument("--candidates-json", type=str, help="Path to JSON file containing clone candidates.")
    parser.add_argument(
        "--backup-root",
        type=str,
        help="Top-level backup directory (defaults to <top_level_folder>/_backups).",
    )
    parser.add_argument("--repo-name", type=str, help="Repository name (defaults to primary checkout name).")
    parser.add_argument("--timestamp", type=str, help="Custom timestamp string for run directory name.")
    parser.add_argument(
        "--no-cache-exclude",
        action="store_true",
        help="Do not exclude cache directories (include node_modules, .venv, etc.).",
    )
    parser.add_argument("--dry-run", action="store_true", help="Preview planned operations without writing zips.")
    parser.add_argument("--json", action="store_true", help="Print result as JSON.")

    args = parser.parse_args()

    primary, root = resolve_primary_and_root(args.primary, args.root)
    repo_name = args.repo_name or primary.name

    if args.backup_root:
        backup_root = Path(args.backup_root).resolve()
    else:
        backup_root = root / "_backups"

    clone_paths: List[Path] = []

    if args.clones:
        for c in args.clones:
            p = Path(c)
            if not p.is_absolute():
                if p.exists():
                    p = p.resolve()
                else:
                    p = (root / c).resolve()
            if p.exists() and p.is_dir():
                clone_paths.append(p.resolve())
            else:
                sys.stderr.write(f"Warning: clone path does not exist: {p}\n")

    elif args.candidates_json:
        cj_path = Path(args.candidates_json)
        if cj_path.exists():
            data = json.loads(cj_path.read_text(encoding="utf-8"))
            for item in data:
                p_str = item.get("path") if isinstance(item, dict) else item
                if p_str:
                    p = Path(p_str)
                    if not p.is_absolute():
                        p = (root / p).resolve()
                    if p.exists() and p.is_dir():
                        clone_paths.append(p.resolve())
        else:
            sys.stderr.write(f"Error: candidates file not found: {cj_path}\n")
            return 1

    if not clone_paths:
        sys.stderr.write("No valid clone directories provided to back up.\n")
        return 1

    result = build_backup_layout(
        clones=clone_paths,
        backup_root=backup_root,
        repo_name=repo_name,
        timestamp=args.timestamp,
        exclude_caches=not args.no_cache_exclude,
        dry_run=args.dry_run,
    )

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        mode_str = " (DRY RUN)" if args.dry_run else ""
        print(f"Backup run complete{mode_str}:")
        print(f"  Target directory: {result['run_dir']}")
        print(f"  Clones processed: {len(result['clones'])}")
        print(f"  Status: {result['status']}")
        for c in result["clones"]:
            ver_text = "PASS" if c["verified"] else f"FAIL: {c['error']}"
            size_mb = c["zip_bytes"] / (1024 * 1024)
            print(f"    - {c['clone']}: {ver_text} ({size_mb:.2f} MB, {c['zip_sha256'][:10]})")

    return 0 if result["all_verified"] else 2


if __name__ == "__main__":
    sys.exit(main())
