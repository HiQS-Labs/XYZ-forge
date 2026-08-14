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

# The three shapes GH-527 Part A names, plus clean -f. The common factor is not
# obvious from any single spelling, which is why all of them are listed here.
SHAPES = [
    ("reset --hard",       re.compile(r"\bgit\b.*\breset\b.*--hard\b")),
    ("checkout -- <path>", re.compile(r"\bgit\b.*\bcheckout\b.*(--\s|\s\.\s*$)")),
    ("stash",              re.compile(r"\bgit\b\s+stash\b(?!\s+(list|show|apply|pop|drop|branch))")),
    ("clean -f",           re.compile(r"\bgit\b.*\bclean\b.*-[a-zA-Z]*f")),
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

rc, status = git(["status", "--porcelain", "--untracked-files=no"], root)
if rc != 0:
    sys.exit(0)

paths = []
for line in status.splitlines():
    if len(line) > 3:
        p = line[3:].strip()
        if " -> " in p:
            p = p.split(" -> ", 1)[1]
        paths.append(p.strip(chr(34)))

# Clean tree: nothing to lose. The guard MUST stay silent here — a guard that
# fires on the safe case is a blanket, and GH-527 asks for a control proving it
# does not fire on a clean tree for exactly that reason.
if not paths:
    sys.exit(0)

stamp = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
dest = os.path.join(root, ".tick", "orphan-backups",
                    "%s-gh527-%d" % (stamp, os.getpid()))

saved = 0
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
    except Exception:
        continue

if saved:
    where = os.path.relpath(dest, root)
    sys.stderr.write(
        "gh527-guard: %s is about to overwrite %d tracked file(s) from a committed state.\n"
        % (shape, saved))
    sys.stderr.write("gh527-guard: snapshot saved -> %s\n" % where)
    sys.stderr.write("gh527-guard: recover with: cp -R %s/. .\n" % where)

sys.exit(0)
'
exit 0
