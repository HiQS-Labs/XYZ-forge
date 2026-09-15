#!/usr/bin/env python3
"""xyz-init-clone — one command for the validated consumer-marathon clone layout (GH-642).

The foreign-repo marathon SOP (skills/relay-xyz, #621 run reports) needs a very specific
checkout before any lane fires, and every step of it was manual — and every manual step was
once a failed fire:

  1. a FULL clone from the canonical remote, deterministically named
     `marathon-gh-<umbrella>-<slug>` (never a linked worktree, never the primary checkout);
  2. the harness vendored INTO the clone, Tier 2 (`--with-releases`) so the ledger overlay and
     releases_app.py ride along — a marathon drives from inside the clone;
  3. the vendor's ignore rules landing in the clone's repo-local exclude (xyz-vendor.sh owns
     that since GH-642; the target .gitignore is never touched);
  4. the clone's own git hooks installed when the cloned repo ships them;
  5. printed next steps: bootstrap hint and the drive-invocation shape.

Usage:
  xyz-init-clone.py <repo-url> --umbrella N [--slug s] [--dir D]

`--umbrella` is required: per skills/marathon-triage, a marathon without a named umbrella issue
is not ready to start, and the clone name keys off it. `--slug` defaults to the repo basename
lowercased; it must be <=3 hyphen-separated lowercase words. The destination defaults to
`~/marathon-clones/marathon-gh-<umbrella>-<slug>`; an occupied derived name retries with the
documented `-r2` suffix, and an explicitly passed `--dir` that already exists is a refusal —
this tool never merges into an existing checkout.

Exit: 0 cloned+vendored · 2 usage · 1 clone/vendor failure.
"""

import argparse
import os
import re
import subprocess
import sys

VENDOR_REL = os.path.join("relay-automation", "xyz-vendor.sh")
SLUG_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
DEFAULT_PARENT = os.path.join(os.path.expanduser("~"), "marathon-clones")


def die(msg):
    print(f"xyz-init-clone: {msg}", file=sys.stderr)
    sys.exit(1)


def validate_slug(slug):
    words = [w for w in slug.split("-") if w]
    if len(words) > 3 or not SLUG_RE.match(slug):
        die(f"slug {slug!r} must be <=3 hyphen-separated lowercase words (got {len(words)})")
    return slug


def next_destination(parent, name):
    """The derived name, retried with the documented -r2 suffix when occupied (marathon-triage:
    'a second attempt at the same arc reuses the name with a -r2 suffix')."""
    candidate = os.path.join(parent, name)
    k = 2
    while os.path.exists(candidate):
        candidate = os.path.join(parent, f"{name}-r{k}")
        k += 1
    return candidate


def run(cmd, cwd=None):
    print(f"+ {' '.join(cmd)}" + (f"  (cwd={cwd})" if cwd else ""))
    try:
        subprocess.run(cmd, cwd=cwd, check=True)
    except subprocess.CalledProcessError as error:
        die(f"{' '.join(cmd)} failed with exit {error.returncode}")


def main():
    parser = argparse.ArgumentParser(
        prog="xyz-init-clone",
        description="Clone a consumer repo with the validated marathon layout: deterministic "
        "full clone, vendored harness (Tier 2), repo-local excludes, hooks.",
    )
    parser.add_argument("repo_url", help="canonical remote URL to clone (full clone, not a worktree)")
    parser.add_argument("--umbrella", type=int, required=True,
                        help="umbrella tracking issue number; keys the clone name (required)")
    parser.add_argument("--slug", default=None,
                        help="<=3 lowercase hyphen-separated words (default: repo basename)")
    parser.add_argument("--dir", default=None,
                        help="parent directory for the clone (default: ~/marathon-clones); "
                        "must not already contain the derived name")
    args = parser.parse_args()

    harness_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    vendor = os.path.join(harness_root, VENDOR_REL)
    if not os.path.isfile(vendor):
        die(f"vendor script not found next to this tool: {vendor}")

    repo_name = os.path.basename(args.repo_url.rstrip("/"))
    if repo_name.endswith(".git"):
        repo_name = repo_name[: -len(".git")]
    slug = validate_slug(args.slug or re.sub(r"[^a-z0-9]+", "-", repo_name.lower()).strip("-"))

    parent = os.path.abspath(args.dir or DEFAULT_PARENT)
    if os.path.exists(os.path.join(parent, f"marathon-gh-{args.umbrella}-{slug}")) and args.dir:
        die(f"--dir {parent} already contains marathon-gh-{args.umbrella}-{slug}; refusing to merge into an existing checkout")

    dest = next_destination(parent, f"marathon-gh-{args.umbrella}-{slug}")
    os.makedirs(parent, exist_ok=True)

    run(["git", "clone", args.repo_url, dest])
    run(["bash", vendor, dest, "--with-releases"])

    hooks = os.path.join(dest, "githooks", "install.sh")
    if os.path.isfile(hooks):
        run(["bash", hooks], cwd=dest)
    else:
        print("xyz-init-clone: cloned repo ships no githooks/install.sh — skipping hook install")

    print(
        "\nNext steps:\n"
        f"  cd {dest}\n"
        "  bootstrap the clone if it needs one (e.g. `npm ci`) — the pre-advance gate runs here\n"
        "  generate packets:  .xyz/utils/swarm-preflight.sh --gh-issue <N>   # capture doc required\n"
        "  cut the lane branch, then fire:\n"
        "    XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=<slug> .xyz/relay-automation/marathon-drive.sh \\\n"
        "      --phase-brief <packet>/packet.md --reviewer agy --builder codex \\\n"
        "      --artifact <files> --pre-advance-cmd '<gate>' \\\n"
        "      --phases-dir marathon-system/gh-"
        f"{args.umbrella}-{slug} --phase-id p1 --require-clean\n"
    )


if __name__ == "__main__":
    main()
