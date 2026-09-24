#!/usr/bin/env python3
"""xyz_mini_sync.py — copy the embedded manifest of XYZ-forge files into a local checkout of
HiQS-Labs/XYZ-mini, commit with the source SHA, optionally push. (GH-589)

The manifest lives in this file so a publication is a function of (source revision, this file).
Preview by default; --apply writes and commits; --push also pushes and reads origin/main back.

Guards (deliberately few):
  * every manifest source must exist and be tracked, or nothing is written (exit 2)
  * an existing destination file at an output path that the previous publication did not write is
    never overwritten (exit 2) — the one ownership guard
  * the files about to ship are regex-scanned for secrets before anything is written (exit 4)

Usage: utils/py/xyz_mini_sync.py [--dest PATH] [--apply] [--push] [--allow-dirty] [--print-manifest]
Exit:  0 ok · 2 refused · 3 commit/push failed · 4 secret found
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys

# (source path in XYZ-forge, destination path in XYZ mini, mode)
#   managed: replaced every run, deleted from mini when dropped from this list
#   seed:    copied only when absent in mini; never replaced, never deleted
# A directory entry ships every TRACKED file beneath it.
MANIFEST = (
    ("skills/1-hourly/relay", "skills/relay", "managed"),
    ("skills/1-hourly/ponytail", "skills/ponytail", "managed"),
    ("skills/3-weekly/honest", "skills/honest", "managed"),
    ("skills/1-hourly/debug-mantra", "skills/debug-mantra", "managed"),
    ("skills/1-hourly/unstuck", "skills/unstuck", "managed"),
    # agent-chorus runtime only (its standalone publish pipeline stays behind)
    ("skills/2-daily/agent-chorus/SKILL.md", "skills/agent-chorus/SKILL.md", "managed"),
    ("skills/2-daily/agent-chorus/README.md", "skills/agent-chorus/README.md", "managed"),
    ("skills/2-daily/agent-chorus/TELEMETRY.md", "skills/agent-chorus/TELEMETRY.md", "managed"),
    ("skills/2-daily/agent-chorus/EXPERIMENTS.md", "skills/agent-chorus/EXPERIMENTS.md", "managed"),
    ("skills/2-daily/agent-chorus/install.sh", "skills/agent-chorus/install.sh", "managed"),
    ("skills/2-daily/agent-chorus/agents", "skills/agent-chorus/agents", "managed"),
    ("skills/2-daily/agent-chorus/scripts", "skills/agent-chorus/scripts", "managed"),
    # consult: skill + shim + full bash lib + its closed Python import set (layout preserved)
    ("skills/1-hourly/consult", "skills/consult", "managed"),
    ("relay-automation/consult.sh", "relay-automation/consult.sh", "managed"),
    ("relay-automation/relay-turn-lib.sh", "relay-automation/relay-turn-lib.sh", "managed"),
    ("utils/py/consult.py", "utils/py/consult.py", "managed"),
    ("utils/py/rtl.py", "utils/py/rtl.py", "managed"),
    ("utils/py/turn_diagnostics.py", "utils/py/turn_diagnostics.py", "managed"),
    ("utils/py/claude_cli.py", "utils/py/claude_cli.py", "managed"),
    ("utils/py/proc_group.py", "utils/py/proc_group.py", "managed"),
    # mini-only sources authored in forge under mini/
    ("mini/skills/skill-viewer", "skills/skill-viewer", "managed"),
    ("mini/README.md", "README.md", "managed"),
    ("mini/gitignore", ".gitignore", "managed"),
    ("mini/TODO.md", "TODO.md", "seed"),
    ("LICENSE", "LICENSE", "managed"),
    ("LICENSE-COMMERCIAL.md", "LICENSE-COMMERCIAL.md", "managed"),
)
SKILLS_ARMY_MANIFEST = (
    # This child repository is the package: project the canonical folder onto its root.
    ("skills/3-weekly/skills-army-hq", "", "managed"),
    ("mini/skills-army-gitignore", ".gitignore", "managed"),
    ("LICENSE", "LICENSE", "managed"),
    ("LICENSE-COMMERCIAL.md", "LICENSE-COMMERCIAL.md", "managed"),
)
TARGETS = {
    "xyz-mini": {
        "manifest": MANIFEST,
        "env": "XYZ_MINI_REPO",
        "sibling": "XYZ-mini",
        "log": "xyz-mini-sync",
    },
    "skills-army-mini": {
        "manifest": SKILLS_ARMY_MANIFEST,
        "env": "XYZ_SKILLS_ARMY_MINI_REPO",
        "sibling": "XYZ-skills-army-mini",
        "log": "skills-army-mini-sync",
    },
}
MANIFEST_FILE = "MANIFEST.txt"        # managed paths of the last publication (drives deletions)
REVISION_FILE = ".xyz-forge-revision"  # source SHA of the last publication
SECRET_PATTERNS = (
    ("aws-access-key", re.compile(rb"(?<![A-Z0-9])(AKIA|ASIA)[A-Z0-9]{16}(?![A-Z0-9])")),
    ("github-token", re.compile(rb"\b(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36,}\b")),
    ("github-pat", re.compile(rb"\bgithub_pat_[A-Za-z0-9_]{80,}\b")),
    ("openai-key", re.compile(rb"\bsk-(proj-|ant-)?[A-Za-z0-9_-]{32,}\b")),
    ("google-api-key", re.compile(rb"\bAIza[0-9A-Za-z_-]{35}\b")),
    ("slack-token", re.compile(rb"\bxox[bpas]-[A-Za-z0-9-]{10,}\b")),
    ("private-key-pem", re.compile(rb"-----BEGIN (RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY( BLOCK)?-----")),
)


class Refuse(Exception):
    def __init__(self, msg, code=2):
        super().__init__(msg)
        self.code = code


def log(msg, prefix="xyz-mini-sync"):
    print(f"{prefix}: {msg}", file=sys.stderr)


def git(repo, *args, check=True):
    cp = subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True)
    if check and cp.returncode != 0:
        raise Refuse(f"git {' '.join(args)} failed in {repo}: {cp.stderr.strip()}")
    return cp


def expand(source, manifest=MANIFEST):
    """(src_file, dest_file, mode) for every tracked file the manifest names."""
    out = []
    for src, dest, mode in manifest:
        files = [f for f in git(source, "ls-files", "-z", "--", src).stdout.split("\0") if f]
        if not files:
            raise Refuse(f"manifest source missing or untracked: {src}")
        for f in files:
            suffix = f[len(src):].lstrip("/")
            target = dest if f == src else os.path.join(dest, suffix) if dest else suffix
            if not target or os.path.isabs(target) or target == ".." or target.startswith("../"):
                raise Refuse(f"manifest destination escapes child root: {src} -> {target or '<empty>'}")
            out.append((f, target, mode))
    return out


def scan(root, rels):
    for rel in rels:
        with open(os.path.join(root, rel), "rb") as fh:
            data = fh.read()
        for name, rx in SECRET_PATTERNS:
            if rx.search(data):
                raise Refuse(f"secret pattern '{name}' in {rel}", code=4)


def expected_revision(sha, branch, dirty):
    return f"source_repo=XYZ-forge\nsource_sha={sha}\nsource_branch={branch}\nsource_dirty={int(dirty)}\n"


def destination_ready(source, dest, files, managed, revision, message):
    """Refuse stale or unrelated history before writing; permit an exact failed-push retry."""
    current_branch = git(dest, "symbolic-ref", "--quiet", "--short", "HEAD", check=False)
    if current_branch.returncode != 0 or current_branch.stdout.strip() != "main":
        raise Refuse("destination must be on branch main")
    remote_cp = git(dest, "ls-remote", "origin", "refs/heads/main", check=False)
    if remote_cp.returncode != 0:
        raise Refuse(f"cannot read origin/main: {remote_cp.stderr.strip() or 'git ls-remote failed'}")
    remote_fields = remote_cp.stdout.split()
    remote = remote_fields[0] if remote_fields else ""
    head_cp = git(dest, "rev-parse", "--verify", "HEAD", check=False)
    head = head_cp.stdout.strip() if head_cp.returncode == 0 else ""
    if (not remote and not head) or head == remote:
        return
    if remote and head:
        parent = git(dest, "rev-parse", f"{head}^", check=False)
        subject = git(dest, "show", "-s", "--format=%s", head, check=False)
        old_manifest = git(dest, "show", f"{head}:{MANIFEST_FILE}", check=False)
        old_revision = git(dest, "show", f"{head}:{REVISION_FILE}", check=False)
        remote_manifest = git(dest, "show", f"{remote}:{MANIFEST_FILE}", check=False)
        changed = git(dest, "diff", "--name-only", remote, head, check=False)
        wanted_manifest = "".join(path + "\n" for path in managed)
        if (parent.returncode == subject.returncode == old_manifest.returncode == old_revision.returncode == 0
                and parent.stdout.strip() == remote and subject.stdout.strip() == message
                and old_manifest.stdout == wanted_manifest and old_revision.stdout == revision):
            previous = set(remote_manifest.stdout.splitlines()) if remote_manifest.returncode == 0 else set()
            seeds = {dst for _, dst, mode in files if mode == "seed"}
            allowed = set(managed) | previous | seeds | {MANIFEST_FILE, REVISION_FILE}
            changed_paths = set(changed.stdout.splitlines()) if changed.returncode == 0 else {"<unreadable>"}
            payload_matches = all(not os.path.lexists(os.path.join(dest, old))
                                  for old in previous - set(managed))
            for src, dst, mode in files:
                if mode == "seed":
                    remote_seed = git(dest, "cat-file", "-e", f"{remote}:{dst}", check=False).returncode == 0
                    if remote_seed:
                        if dst in changed_paths:
                            payload_matches = False
                        continue
                    if dst not in changed_paths:
                        payload_matches = False
                        continue
                elif mode != "managed":
                    continue
                elif dst not in previous and git(dest, "cat-file", "-e", f"{remote}:{dst}", check=False).returncode == 0:
                    payload_matches = False
                    continue
                source_path, dest_path = os.path.join(source, src), os.path.join(dest, dst)
                if os.path.islink(dest_path) or not os.path.isfile(dest_path):
                    payload_matches = False
                    break
                with open(source_path, "rb") as source_file, open(dest_path, "rb") as dest_file:
                    if source_file.read() != dest_file.read():
                        payload_matches = False
                        break
                if bool(os.stat(source_path).st_mode & 0o111) != bool(os.stat(dest_path).st_mode & 0o111):
                    payload_matches = False
                    break
            if changed_paths <= allowed and payload_matches:
                return
    raise Refuse("destination main is ahead, behind, or divergent from origin/main")


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--dest")
    ap.add_argument("--target", choices=sorted(TARGETS), default="xyz-mini")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--push", action="store_true")
    ap.add_argument("--allow-dirty", action="store_true")
    ap.add_argument("--print-manifest", action="store_true")
    a = ap.parse_args(argv)
    if a.print_manifest:
        print(json.dumps([list(e) for e in TARGETS[a.target]["manifest"]]))
        return 0
    apply = a.apply or a.push
    try:
        source = git(os.path.dirname(os.path.abspath(__file__)), "rev-parse", "--show-toplevel").stdout.strip()
        profile = TARGETS[a.target]
        configured_dest = a.dest or os.environ.get(profile["env"])
        dest = os.path.realpath(configured_dest or os.path.join(source, os.pardir, profile["sibling"]))
        if not os.path.isdir(os.path.join(dest, ".git")):
            raise Refuse(f"destination is not a git checkout: {dest}")
        sha = git(source, "rev-parse", "HEAD").stdout.strip()
        branch = git(source, "rev-parse", "--abbrev-ref", "HEAD").stdout.strip()
        dirty = bool(git(source, "status", "--porcelain").stdout.strip())
        if dirty and not a.allow_dirty:
            raise Refuse("source has uncommitted changes (commit them or pass --allow-dirty)")
        if git(dest, "status", "--porcelain").stdout.strip():
            raise Refuse("destination has uncommitted changes")

        files = expand(source, profile["manifest"])
        managed = sorted({d for _, d, m in files if m == "managed"})
        revision = expected_revision(sha, branch, dirty)
        message = f"sync: XYZ-forge@{sha[:12]} ({branch}){' [dirty source]' if dirty else ''}"
        destination_ready(source, dest, files, managed, revision, message)
        prev_path = os.path.join(dest, MANIFEST_FILE)
        prev = set(open(prev_path).read().split()) if os.path.isfile(prev_path) else set()
        owned = prev | {MANIFEST_FILE, REVISION_FILE}

        # the one ownership guard: never overwrite something the last publication did not write
        for _, d, m in files:
            if m != "seed" and d not in owned and os.path.lexists(os.path.join(dest, d)):
                raise Refuse(f"{d} exists in the destination but was not published by this tool — refusing to overwrite")
        deletions = sorted(d for d in prev - set(managed) if os.path.lexists(os.path.join(dest, d)))
        copies = [(s, d) for s, d, m in files if m == "managed" or not os.path.exists(os.path.join(dest, d))]

        scan(source, [s for s, _ in copies])
        log(f"source {sha[:12]} ({branch}{', dirty' if dirty else ''}) → {dest}", profile["log"])
        log(f"plan: copy {len(copies)} files, delete {len(deletions)}" + (": " + " ".join(deletions) if deletions else ""), profile["log"])
        if not apply:
            log("preview only — pass --apply to write, --push to publish", profile["log"])
            return 0

        for d in deletions:
            git(dest, "rm", "-q", "--", d)
        for s, d in copies:
            dp = os.path.join(dest, d)
            os.makedirs(os.path.dirname(dp), exist_ok=True)
            shutil.copy(os.path.join(source, s), dp)  # copy() keeps the executable bit
            git(dest, "add", "--", d)
        with open(prev_path, "w") as fh:
            fh.write("".join(p + "\n" for p in managed))
        with open(os.path.join(dest, REVISION_FILE), "w") as fh:
            fh.write(revision)
        git(dest, "add", "--", MANIFEST_FILE, REVISION_FILE)

        if git(dest, "diff", "--cached", "--quiet", check=False).returncode == 0:
            log("no changes — no commit created", profile["log"])
        else:
            cp = git(dest, "-c", "user.name=xyz-mini-sync", "-c", "user.email=xyz-mini-sync@users.noreply.github.com",
                     "commit", "-q", "-m", message, check=False)
            if cp.returncode != 0:
                log(f"commit failed: {cp.stderr.strip()}", profile["log"])
                return 3
            log(f"committed {git(dest, 'rev-parse', '--short', 'HEAD').stdout.strip()}: {message}", profile["log"])
        if a.push:
            cp = git(dest, "push", "origin", "HEAD:main", check=False)
            if cp.returncode != 0:
                log(f"push failed (commit retained, rerun to retry): {cp.stderr.strip()}", profile["log"])
                return 3
            head = git(dest, "rev-parse", "HEAD").stdout.strip()
            remote_cp = git(dest, "ls-remote", "origin", "refs/heads/main", check=False)
            if remote_cp.returncode != 0:
                log(f"push read-back failed: {remote_cp.stderr.strip() or 'git ls-remote failed'}", profile["log"])
                return 3
            remote = remote_cp.stdout.split()
            if not remote or remote[0] != head:
                log(f"push read-back mismatch: remote {remote[:1]} != {head}", profile["log"])
                return 3
            log(f"pushed and verified origin/main == {head[:12]}", profile["log"])
        return 0
    except Refuse as e:
        prefix = TARGETS.get(getattr(a, "target", "xyz-mini"), TARGETS["xyz-mini"])["log"]
        log(f"refused: {e}", prefix)
        return e.code


if __name__ == "__main__":
    sys.exit(main())
