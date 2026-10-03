#!/usr/bin/env python3
"""xyz_mini_sync.py — copy the embedded manifest of XYZ-forge files into a local checkout of
HiQS-Labs/XYZ-mini, commit with the source SHA, optionally push. (GH-589)

The manifest lives in this file so a publication is a function of (source revision, this file).
Preview by default; --apply writes and commits; --push also pushes and reads origin/main back.

The source revision is whatever the forge checkout holds at run time, on any branch — publishing
from a feature branch is the sanctioned exception path (mini/ADAPTATIONS.md). The tool records
source_repo/source_sha/source_branch in the child's .xyz-forge-revision and warns on stderr when
the branch is not development; re-publish from development once the branch lands to re-baseline.

Modes:
  * managed — byte-identical contract: replaced every run, deleted from the child when dropped
  * seed    — copied only when absent; never replaced, never deleted (child-owned, e.g. TODO.md)
  * adapted — the child owns the entry: the forge files seed it once (when the child has never
              been published that entry), after which nothing under it is replaced, added, or
              deleted from the forge side. Whatever the child tracks under the entry (including
              child-only files such as a mini install.sh) is carried forward and recorded.
              Dropping the whole entry from this manifest deletes those paths deliberately. The
              forge source must stay tracked (upstream of record), and every adapted entry needs an
              exact row in the target's origin registry (mini/ORIGIN.md, read from the committed
              source SHA), or the run refuses

Guards (deliberately few):
  * every manifest source must exist and be tracked, or nothing is written (exit 2)
  * an existing destination file at an output path that the previous publication did not write is
    never overwritten (exit 2) — the one ownership guard
  * an adapted entry already published to the child is never written from the forge side again:
    the child's own additions and deletions under it are recorded, never undone; an entry the
    child has never been published (fresh child, newly added or re-added entry) is seeded once
  * the origin registry must carry an exact row of kind `adapted` per adapted entry, must not
    still mark a non-adapted entry adapted, and must be committed (no --allow-dirty edits to it)
  * retired targets (skills-army-mini, #882) refuse unless XYZ_ALLOW_RETIRED_TARGET=1
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
#   adapted: mini owns the entry — seeded once from forge bytes, then never replaced, added to, or
#            pruned from the forge side; deleted only when the whole entry is dropped. The forge
#            source stays tracked as the upstream of record and the entry needs an exact row in
#            mini/ORIGIN.md (see mini/ADAPTATIONS.md)
# A directory entry ships every TRACKED file beneath it.
MANIFEST = (
    ("skills/1-hourly/relay", "skills/relay", "managed"),
    ("skills/1-hourly/ponytail", "skills/ponytail", "managed"),
    ("skills/3-weekly/honest", "skills/honest", "managed"),
    ("skills/1-hourly/debug-mantra", "skills/debug-mantra", "managed"),
    ("skills/1-hourly/unstuck", "skills/unstuck", "managed"),
    ("skills/2-daily/review-code", "skills/review-code", "managed"),
    # adapted: mini-flat layout + child-side hardening (GH-889 QA); upstream of record stays here
    ("skills/3-weekly/weekly-planner", "skills/weekly-planner", "adapted"),
    ("skills/2-daily/daily-planner", "skills/daily-planner", "adapted"),
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
    ("mini/ORIGIN.md", "ORIGIN.md", "managed"),
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
        "origin": "mini/ORIGIN.md",
    },
    "skills-army-mini": {
        "manifest": SKILLS_ARMY_MANIFEST,
        "env": "XYZ_SKILLS_ARMY_MINI_REPO",
        "sibling": "XYZ-skills-army-mini",
        "log": "skills-army-mini-sync",
    },
}
# GH-882: XYZ-skills-army-mini is the Skills Army HQ upstream; publishing into it from the forge would
# overwrite it. The target stays only so its suite can run until the 2026-10-08 audit removes both.
RETIRED_TARGETS = {
    "skills-army-mini": "HiQS-Labs/XYZ-skills-army-mini is the Skills Army HQ upstream since 2026-10-01 "
                        "(#882; decision XYZ-skills-army-mini#2) — make changes there, not from the forge",
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
    cp = subprocess.run(["git", "-C", repo, *args], capture_output=True, encoding="utf-8", errors="replace")
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


ORIGIN_ROW_RX = re.compile(r"^\s*\|\s*`?([^`|]+?)`?\s*\|\s*`?([^`|]*?)`?\s*\|")


def origin_rows(doc):
    """{destination: kind} from the origin registry's table rows: first column = the destination,
    second = its kind. A path mentioned in a Notes column, or a parent directory, documents nothing."""
    return {m.group(1).strip().rstrip("/"): m.group(2).strip().lower()
            for m in map(ORIGIN_ROW_RX.match, doc.splitlines()) if m}


def under(path, root):
    return path == root or path.startswith(root + "/")


def destination_ready(source, dest, files, tracked, revision, message):
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
        wanted_manifest = "".join(path + "\n" for path in tracked)
        if (parent.returncode == subject.returncode == old_manifest.returncode == old_revision.returncode == 0
                and parent.stdout.strip() == remote and subject.stdout.strip() == message
                and old_manifest.stdout == wanted_manifest and old_revision.stdout == revision):
            previous = set(remote_manifest.stdout.splitlines()) if remote_manifest.returncode == 0 else set()
            seeds = {dst for _, dst, mode in files if mode == "seed"}
            allowed = set(tracked) | previous | seeds | {MANIFEST_FILE, REVISION_FILE}
            changed_paths = set(changed.stdout.splitlines()) if changed.returncode == 0 else {"<unreadable>"}
            payload_matches = all(not os.path.lexists(os.path.join(dest, old))
                                  for old in previous - set(tracked))
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
        if a.target in RETIRED_TARGETS and os.environ.get("XYZ_ALLOW_RETIRED_TARGET") != "1":
            raise Refuse(f"target {a.target!r} is retired: {RETIRED_TARGETS[a.target]}")
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
        adapted_roots = sorted({d.rstrip("/") for _, d, m in profile["manifest"] if m == "adapted"})
        if adapted_roots:
            origin_rel = profile.get("origin")
            if not origin_rel:
                raise Refuse(f"target {a.target!r} has adapted entries but no origin registry")
            origin_cp = git(source, "show", f"{sha}:{origin_rel}", check=False)
            if origin_cp.returncode != 0:
                raise Refuse(f"adapted manifest entries require {origin_rel} committed at {sha[:12]}")
            if dirty and git(source, "diff", "--quiet", "HEAD", "--", origin_rel, check=False).returncode != 0:
                raise Refuse(f"{origin_rel} has uncommitted edits — the registry that ships must be the one checked")
            rows = origin_rows(origin_cp.stdout)
            undocumented = [r for r in adapted_roots if rows.get(r) != "adapted"]
            if undocumented:
                raise Refuse(f"adapted entries without an exact row (kind adapted) in {origin_rel} at {sha[:12]}: "
                             + " ".join(undocumented))
            stale = sorted(d.rstrip("/") for _, d, m in profile["manifest"]
                           if m != "adapted" and rows.get(d.rstrip("/")) == "adapted")
            if stale:
                raise Refuse(f"{origin_rel} still marks these adapted, but the manifest no longer does "
                             "(publishing would overwrite or prune mini-owned bytes): " + " ".join(stale))
        prev_path = os.path.join(dest, MANIFEST_FILE)
        with open(prev_path, encoding="utf-8") if os.path.isfile(prev_path) else open(os.devnull) as fh:
            prev = set(fh.read().split())
        # ownership is per adapted entry: an entry already published to the child keeps whatever the
        # child tracks under it (its own additions and deletions included); a never-published entry
        # is seeded from forge bytes once
        established = sorted(r for r in adapted_roots if any(under(p, r) for p in prev))
        carried = sorted(f for f in git(dest, "ls-files", "-z", "--", *established).stdout.split("\0") if f) if established else []
        seeded = sorted({d for _, d, m in files if m == "adapted" and not any(under(d, r) for r in established)})
        tracked = sorted(set(managed) | set(carried) | set(seeded))
        revision = expected_revision(sha, branch, dirty)
        message = f"sync: XYZ-forge@{sha[:12]} ({branch}){' [dirty source]' if dirty else ''}"
        if branch != "development":
            log(f"note: publishing from {branch!r}, not development — the branch is recorded in "
                f"the child's {REVISION_FILE}", profile["log"])
        destination_ready(source, dest, files, tracked, revision, message)
        owned = prev | {MANIFEST_FILE, REVISION_FILE}

        # the one ownership guard: never overwrite something the last publication did not write
        for _, d, m in files:
            writes = m == "managed" or (m == "adapted" and d in seeded)
            if writes and d not in owned and os.path.lexists(os.path.join(dest, d)):
                raise Refuse(f"{d} exists in the destination but was not published by this tool — refusing to overwrite")
        removed = sorted(p for p in prev if any(under(p, r) for r in established) and p not in carried)
        if removed:
            log("child removed adapted paths (recorded, never re-created from forge bytes): "
                + " ".join(removed), profile["log"])
        if seeded:
            log("adapted entries seeded from forge bytes — re-adapt per the child's ORIGIN.md: "
                + " ".join(sorted(r for r in adapted_roots if r not in established)), profile["log"])
        deletions = sorted(d for d in prev - set(tracked) if os.path.lexists(os.path.join(dest, d)))
        copies = [(s, d) for s, d, m in files
                  if m == "managed" or (m == "adapted" and d in seeded)
                  or (m == "seed" and not os.path.exists(os.path.join(dest, d)))]

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
            fh.write("".join(p + "\n" for p in tracked))
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
