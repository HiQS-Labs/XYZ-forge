#!/usr/bin/env bash
#
# gh527-destructive-git-guard.sh — PreToolUse guard: before a git command that
# overwrites the working tree from a committed state runs, snapshot the tracked
# files it is about to destroy so a peer's uncommitted work is recoverable.
#
# The incident this closes (GH-527, three times in ONE session on 2026-08-12): a
# git HISTORY command was used to undo a WORKING-TREE experiment.
#   1. `git stash` tree-wide took four other sessions' files, then timed out
#      BEFORE its pop.
#   2. `git checkout -- <path>` restored HEAD rather than the pre-mutation state
#      and ate ~60 lines of the author's own new tests.
#   3. `git reset --hard origin/development` took four sessions' tracked
#      modifications plus .claude/settings.json, which never came back.
#
# Blast radius was REPRODUCED in a fixture rather than inferred: TRACKED
# modifications are destroyed; untracked files survive. That is why this guard
# keys on tracked dirt only — the dangerous case is exactly the one a peer agent
# produces most often (editing a file that already exists), and snapshotting
# untracked files too would be noise that hides the signal.
#
# SHAPE: snapshot-then-allow, NOT refuse-when-dirty. This is the shape the repo
# already chose for this same problem — rtl_check copies an off-allowlist edit
# into .tick/orphan-backups/ before reverting it (GH-141), precisely so a
# wrongly-caught edit stays recoverable. Refusing instead would fire on every
# legitimate solo-session cleanup and train an override reflex, and an override
# that is always used is not a guard.
#
# WHY A HOOK AND NOT A DOC RAIL: GH-527 falsified the doc-rail proposal against
# the session's own ledger — every mechanical guard (frozen-twin, path-integrity,
# the SIGPIPE detector) caught the author; neither written warning did. The rail
# in AGENTS.md is the explanation; this is the fix.
#
# ALWAYS EXITS 0. This guard snapshots, it does not block — the destructive
# command still runs. Set XYZ_NO_GIT_SNAPSHOT=1 to disable.
#
# Known limits, stated rather than implied: command text is matched with regexes
# over shell-separated segments, so execution nested inside $(...) or dispatched
# via xargs is not seen; and a snapshot only covers files, not staged index state.

[ "${XYZ_NO_GIT_SNAPSHOT:-0}" = "1" ] && exit 0

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0

printf '%s' "$payload" | python3 -c '
import json, os, re, subprocess, sys, time

try:
    ev = json.load(sys.stdin)
except Exception:
    sys.exit(0)

if ev.get("tool_name") != "Bash":
    sys.exit(0)

cmd = (ev.get("tool_input") or {}).get("command") or ""
if not cmd:
    sys.exit(0)

# The three shapes GH-527 Part A names, plus clean and the modern restore/switch spellings.
#
# MATCH BROADLY ON PURPOSE. An agy review of the first draft found that
# `git checkout <path>` — no `--` — slipped a narrower regex entirely, and that is the
# single most likely spelling an agent reaches for to revert a file. Verified: it misses,
# and it destroys (a peer edit went back to HEAD). `git restore <path>` slipped too and was
# not in the review either; it is the modern spelling of the same operation.
#
# Over-matching is CHEAP here and that is a property of the chosen shape, not an accident:
# this guard snapshots and always allows, so a false positive costs one directory copy of
# already-dirty files and nothing else. A false NEGATIVE costs a peer their uncommitted work.
# The clean-tree early exit below keeps the noise at zero for the common safe case, so the
# broad match never fires on a tidy tree.
SHAPES = [
    ("reset --hard", re.compile(r"\bgit\b.*\breset\b.*--hard\b")),
    ("checkout",     re.compile(r"\bgit\b.*\bcheckout\b")),
    ("restore",      re.compile(r"\bgit\b.*\brestore\b")),
    ("switch",       re.compile(r"\bgit\b.*\bswitch\b.*(-f\b|--force|--discard-changes)")),
    ("stash",        re.compile(r"\bgit\b\s+stash\b(?!\s+(list|show|apply|pop|drop|branch))")),
    ("clean",        re.compile(r"\bgit\b.*\bclean\b.*(-[a-zA-Z]*f|--force)")),
]

shape = None
for seg in re.split(r"&&|\|\||;|\|", cmd):
    seg = seg.strip()
    if not seg:
        continue
    for name, rx in SHAPES:
        if rx.search(seg):
            shape = name
            break
    if shape:
        break

if not shape:
    sys.exit(0)


def git(args, cwd):
    try:
        p = subprocess.run(["git"] + args, cwd=cwd, capture_output=True,
                           text=True, timeout=15)
        return p.returncode, p.stdout
    except Exception:
        return 1, ""


cwd = ev.get("cwd") or os.getcwd()
rc, top = git(["rev-parse", "--show-toplevel"], cwd)
if rc != 0 or not top.strip():
    sys.exit(0)
root = top.strip()

# WHICH SET IS AT RISK DEPENDS ON THE SHAPE, and getting this wrong makes the guard useless
# for one of them. `reset --hard`, `checkout`, `restore` and `stash` destroy TRACKED
# modifications and leave untracked files alone — reproduced in GH-527s own fixture, which is
# why the default is tracked-only.
#
# `git clean` is the exact inverse: it deletes UNTRACKED files and does not touch tracked
# modifications. The first draft matched `clean` but still snapshotted only tracked files, so
# it announced a snapshot that contained nothing the command was about to delete — worse than
# not matching at all, because the message implied cover that did not exist. Caught by an agy
# review. For `clean` the untracked set IS the at-risk set.
include_untracked = (shape == "clean")
rc, status = git(["status", "--porcelain",
                  "--untracked-files=" + ("normal" if include_untracked else "no")], root)
if rc != 0:
    sys.exit(0)

paths = []
for line in status.splitlines():
    if len(line) > 3:
        code = line[:2]
        p = line[3:].strip()
        if " -> " in p:
            p = p.split(" -> ", 1)[1]
        # For clean, only the untracked entries are at risk; for everything else, only the
        # tracked ones. Mixing them would snapshot files the command will not touch.
        is_untracked = code == "??"
        if include_untracked != is_untracked:
            continue
        paths.append(p.strip(chr(34)))

# Clean tree: nothing to lose. The guard MUST stay silent here — a guard that
# fires on the safe case is a blanket, and GH-527 asks for a control proving it
# does not fire on a clean tree for exactly that reason.
if not paths:
    sys.exit(0)

stamp = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
leaf = "%s-gh527-%d" % (stamp, os.getpid())

# WHERE the snapshot goes depends on the shape, because for `clean` the obvious location is
# self-defeating. `.tick/orphan-backups/` is the GH-141 precedent and is correct for
# reset/checkout/restore/stash, none of which touch ignored or untracked directories.
#
# `git clean` does. Observed directly while testing recovery rather than assuming it: the guard
# snapshotted the doomed untracked file into `.tick/`, then `git clean -fd` deleted `.tick/` as
# well, and the recovery step found nothing. In this repo `.tick/` is gitignored so a plain
# `-fd` spares it — but `git clean -fdx` removes ignored files too, and a guard that only works
# against some flags of the command it names is not a guard.
#
# So `clean` snapshots OUTSIDE the repo entirely. Less discoverable, which is why the path is
# printed; correct under every flag combination, which matters more.
if include_untracked:
    base = os.environ.get("TMPDIR") or "/tmp"
    dest = os.path.join(base, "gh527-clean-snapshots", leaf)
else:
    dest = os.path.join(root, ".tick", "orphan-backups", leaf)

saved = 0
failed = []
for rel in paths:
    src = os.path.join(root, rel)
    if not os.path.isfile(src):
        continue
    dst = os.path.join(dest, rel)
    try:
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        fh = open(src, "rb")
        data = fh.read()
        fh.close()
        out = open(dst, "wb")
        out.write(data)
        out.close()
        saved += 1
    except Exception as exc:
        # A swallowed copy failure was the worst defect in the first draft, found by an agy
        # review: a full disk or a permission error left the guard exiting 0 in silence, so
        # the operator got no snapshot AND no warning, while the destructive command ran
        # anyway. A guard that fails quietly is worse than no guard, because the absence of a
        # message is read as "nothing was at risk".
        failed.append((rel, exc.__class__.__name__))

# An absolute path for the out-of-repo clean snapshot; a repo-relative one otherwise, which is
# what a reader of .tick/orphan-backups/ expects to see.
where = dest if include_untracked else os.path.relpath(dest, root)
kind = "untracked" if include_untracked else "tracked"

if saved:
    sys.stderr.write(
        "gh527-guard: %s is about to destroy %d %s file(s).\n" % (shape, saved, kind))
    sys.stderr.write("gh527-guard: snapshot saved -> %s\n" % where)
    sys.stderr.write("gh527-guard: recover with: cp -R \"%s\"/. .\n" % where)
    if include_untracked:
        sys.stderr.write(
            "gh527-guard: (kept OUTSIDE the repo — git clean -x would have deleted an "
            "in-repo snapshot)\n")

if failed:
    # Loud, and it names what is unprotected rather than only that something went wrong.
    sys.stderr.write(
        "gh527-guard: WARNING — %d file(s) could NOT be snapshotted and are UNPROTECTED:\n"
        % len(failed))
    for rel, err in failed[:10]:
        sys.stderr.write("gh527-guard:   %s (%s)\n" % (rel, err))
    sys.stderr.write(
        "gh527-guard: the command was NOT blocked (this guard never blocks) — if you need "
        "those files, copy them by hand before continuing.\n")

sys.exit(0)
'
exit 0
