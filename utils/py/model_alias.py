#!/usr/bin/env python3
"""model_alias.py (GH-346 Phase 1) — one fault-tolerant wrapper around resolve-model-alias.sh.

Why this exists as a shared module rather than a per-caller snippet:

`relay-automation/resolve-model-alias.sh` is a *fuzzy alias table*, not a validator. On a miss it
exits 1 and prints nothing (pinned by `test/model-alias.sh`), and it has no canonical-slug
passthrough — feeding it an already-canonical id like `deepseek/deepseek-v4-pro` is a MISS, not an
identity. So a caller that swaps `os.environ.get("X_MODEL", "<literal>")` for a bare resolver call
turns every canonical model id into an empty string and breaks the turn.

The safe shape was already in `utils/py/review_xyz.py`: run the resolver, and on any non-zero exit,
empty output, missing script, or exception, hand back the caller's input unchanged. This module is
that pattern lifted verbatim (plus a timeout, since turn shims call it on the critical path and a
wedged subprocess costs a whole turn), so the next caller inherits it instead of re-deriving it.

Contract: `resolve_model_slug` NEVER raises and NEVER returns empty for non-empty input. The
resolver is an enhancement; the caller's literal remains the floor.
"""

import os
import subprocess

# Generous: the resolver is a local bash script over a static YAML table, so anything approaching
# this bound means it is wedged, not slow. A turn is worth more than a fuzzy alias lookup.
RESOLVE_TIMEOUT_S = 10


def resolver_path(xyz_root):
    """Absolute path to resolve-model-alias.sh under a harness root (not checked for existence)."""
    return os.path.join(xyz_root, "relay-automation", "resolve-model-alias.sh")


def resolve_model_slug(model_name, xyz_root, timeout_s=RESOLVE_TIMEOUT_S):
    """Resolve a colloquial model name to its canonical slug, or return it unchanged.

    Falls back to `model_name` on every failure mode the resolver has: alias miss (exit 1, no
    stdout), a canonical slug it has no row for, a missing or non-executable script, a timeout, or
    any exception. Never raises.
    """
    if not model_name:
        return model_name

    script = resolver_path(xyz_root)
    if not os.path.isfile(script):
        return model_name

    try:
        r = subprocess.run(
            ["bash", script, model_name],
            capture_output=True,
            text=True,
            check=False,
            timeout=timeout_s,
        )
    except Exception:
        return model_name

    if r.returncode == 0 and r.stdout.strip():
        return r.stdout.strip()
    return model_name
