#!/usr/bin/env python3
"""harness_paths.py (GH-396 Phase 2) — single resolver for harness_home, repo_root, is_vendored, and harness_tool.

Provides:
- harness_home(path=None, anchor_file=None): directory containing relay-automation/ + utils/ (repo root, or <repo>/.xyz)
- is_vendored(path=None): boolean check for vendored (.xyz) layout
- repo_root(path=None, anchor_file=None): consumer repo root (dirname of .xyz if vendored, else harness_home)
- resolve_tool(repo_root, rel_path, prefer_repo=True): resolves tool file with repo-first mock shadow preference

Two resolution questions live here and they are deliberately separate:
1. Install / layout resolution (harness_home, repo_root, is_vendored) determines whether
   the execution is standing in a canonical checkout or a vendored leaf, preserving symlinks.
2. Tool resolution (resolve_tool(repo_root, rel, prefer_repo=True)) selects which copy of a tool
   file inside that install — repo-first so a canonical checkout and test mocks shadow the harness
   copy (test/gh358-…:128-131), harness-home fallback. Their orderings differ by design and are never
   merged into one ladder.

Shadow risk is exposed, not hidden: resolve_tool(rel, prefer_repo=True) is the existing
contract for the five harness tools wave_reconcile runs. A consumer repo carrying its own
same-named utils/… file would win silently under repo-first. New consumers pass
prefer_repo=False; the docstring names the risk and the flag.
"""

import os
import re
import subprocess
import sys


def harness_home(path=None, anchor_file=None):
    """Dir containing relay-automation/ + utils/: repo root, or <repo>/.xyz when vendored.

    Derived from THIS file's location (or anchor_file if provided), or XYZ_HARNESS environment variable.
    Never uses os.path.realpath so symlinked .xyz directories preserve their .xyz identity.
    """
    if path is not None:
        if os.path.isfile(path):
            return os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(path)), "..", ".."))
        return os.path.abspath(path)
    if anchor_file is not None:
        if os.path.isfile(anchor_file):
            return os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(anchor_file)), "..", ".."))
        return os.path.abspath(anchor_file)
    if os.environ.get("XYZ_HARNESS") and os.path.isdir(os.environ["XYZ_HARNESS"]):
        return os.path.abspath(os.environ["XYZ_HARNESS"])
    # If the main running script is under .xyz/, use its location to preserve symlinked .xyz
    main_mod = sys.modules.get("__main__")
    main_file = getattr(main_mod, "__file__", None)
    if main_file and os.path.isfile(main_file):
        main_abs = os.path.abspath(main_file)
        if "/.xyz/" in main_abs or main_abs.endswith("/.xyz"):
            parts = main_abs.split(os.sep)
            if ".xyz" in parts:
                idx = parts.index(".xyz")
                return os.sep.join(parts[:idx + 1])
    return os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))


def is_vendored(path=None):
    """Check if the harness is installed in a vendored (.xyz) layout."""
    if path is None:
        if os.environ.get("XYZ_VENDORED") in ("1", "true", "True"):
            return True
        if os.environ.get("XYZ_VENDORED") in ("0", "false", "False"):
            return False
        if os.environ.get("XYZ_HARNESS"):
            p = os.path.abspath(os.environ["XYZ_HARNESS"])
            if os.path.basename(p.rstrip("/\\")) == ".xyz":
                return True
    p = harness_home() if path is None else (
        os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(path)), "..", ".."))
        if os.path.isfile(path) else os.path.abspath(path)
    )
    return os.path.basename(p.rstrip("/\\")) == ".xyz"


def repo_root(path=None, anchor_file=None):
    """Return the consumer repo root (dirname(harness_home) if vendored, else harness_home). Raises on failure."""
    h = harness_home(path, anchor_file=anchor_file)
    if is_vendored(h):
        if path is None and anchor_file is None:
            caller = os.environ.get("XYZ_CALLER_ROOT")
            if caller and os.path.isdir(caller):
                return os.path.abspath(caller)
        return os.path.dirname(h.rstrip("/\\"))
    return h


def resolve_tool(repo_root, rel_path, prefer_repo=True):
    """Resolve a HARNESS tool (releases_app, the dashboard/plan/timeline scripts) for a run
    whose cwd is `repo_root`.

    The target repo wins when it carries the tool itself (`prefer_repo=True`, the existing
    contract: every wave-reconcile test suite installs its mocks at `$REPO/utils/...` and
    relies on them shadowing the real thing, and a canonical checkout is its own harness home,
    so repo-first is a no-op there).

    Only when the target repo does NOT carry the tool do we fall back to the harness home —
    the vendored (Tier 2) case, where these files exist solely under `<repo>/.xyz/`.

    When `prefer_repo=False`, the harness-home copy wins if present, avoiding shadow risk.

    Returns a path relative to `repo_root` when the repo owns the tool, else an absolute path
    into the harness home. Both are correct as argv[1] for a subprocess run with cwd=repo_root.
    """
    if not rel_path:
        raise ValueError("rel_path is required")
    if prefer_repo:
        if os.path.exists(os.path.join(repo_root, rel_path)):
            return rel_path
        vendored = os.path.join(harness_home(), rel_path)
        if os.path.exists(vendored):
            return vendored
        # Neither location has it: return the repo-relative path so the failure names the tool the
        # caller asked for, exactly as it did before this helper existed.
        return rel_path
    else:
        h = os.path.join(harness_home(), rel_path)
        if os.path.exists(h):
            return h
        if os.path.exists(os.path.join(repo_root, rel_path)):
            return rel_path
        return rel_path


# Backward compatibility alias for wave_reconcile
harness_tool = resolve_tool


def github_slug_from_origin(root):
    """Best-effort '<org>/<repo>' from a github.com origin remote; None when unresolved.

    GH-429: extracted here (the module every harness tool already imports) so wave_reconcile can
    recognise `Closes https://github.com/<org>/<repo>/issues/N` for THIS repo only; the Tier 2
    twin `releases_app._github_slug_from_origin` keeps its own copy — releases_app is not vendored
    on a Tier 1 install, so it cannot be the import.
    """
    try:
        out = subprocess.check_output(["git", "-C", root, "remote", "get-url", "origin"],
                                      stderr=subprocess.DEVNULL).decode().strip()
    except Exception:
        return None
    m = re.search(r"github\.com[/:]([\w.\-]+/[\w.\-]+?)(?:\.git)?$", out)
    return m.group(1) if m else None

