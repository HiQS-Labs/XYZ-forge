#!/usr/bin/env python3
"""harness_paths.py (GH-396 Phase 2) — single resolver for harness_home, repo_root, is_vendored, and harness_tool.

Two resolution questions live here and they are deliberately separate.
`resolve_harness()` selects which clone/install to use — env override -> caller `.xyz` ->
worktree `.xyz` -> git root -> self. `resolve_tool(repo_root, rel, prefer_repo=True)` selects
which copy of a tool file inside that install — repo-first so a canonical checkout and test
mocks shadow the harness copy (`test/gh358-…:128-131`), harness-home fallback. Their orderings
differ by design and are never merged into one ladder.

Shadow risk is exposed, not hidden: `resolve_tool(rel, prefer_repo=True)` is the existing
contract for the five harness tools `wave_reconcile` runs. A consumer repo carrying its own
same-named `utils/…` file would win silently under repo-first. New consumers pass
`prefer_repo=False`; the docstring names the risk and the flag.
"""

import os
import sys


def harness_home(path=None):
    """Dir containing relay-automation/ + utils/: repo root, or <repo>/.xyz when vendored.

    Derived from THIS file's location, never from the caller's cwd or an assumed repository
    root — the same rule jog_run.harness_home() states and marathon_plan.py already follows.
    """
    if path is not None:
        return os.path.abspath(path)
    return os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))


def is_vendored(path=None):
    """Check if the harness is installed in a vendored (.xyz) layout."""
    p = harness_home() if path is None else os.path.abspath(path)
    return os.path.basename(os.path.realpath(p)) == ".xyz"


def repo_root(path=None):
    """Return the consumer repo root (dirname(harness_home) if vendored, else harness_home). Raises on failure."""
    h = harness_home(path)
    if is_vendored(h):
        return os.path.dirname(h)
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


harness_tool = resolve_tool
