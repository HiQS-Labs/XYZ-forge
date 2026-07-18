#!/usr/bin/env bash
#
# gh177-sandbox-test-guard.sh — PreToolUse guard: never EXECUTE this repo's test
# suite under a sandboxed Claude Code Bash call.
#
# The incident this closes (GH-177, twice): an agent ran an innocuous-looking
# `./validate.sh` under the Bash sandbox; the sandbox silently broke `mktemp -d`
# inside a test script, `cd ""` stayed at the repo root, and the script's
# destructive `rm -rf` EXIT trap wiped the working tree plus parts of `.git`.
# The dangerous command never appeared at the CLI boundary — so a deny-list of
# "rm -rf"-shaped commands cannot catch it. This guard keys on the TRIGGER
# (sandboxed suite execution) instead of the payload.
#
# Wiring (.claude/settings.json):
#   "hooks": { "PreToolUse": [ { "matcher": "Bash",
#     "hooks": [ { "type": "command",
#       "command": "bash relay-automation/hooks/gh177-sandbox-test-guard.sh" } ] } ] }
#
# Contract (reads the PreToolUse JSON event on stdin):
#   - BLOCK (exit 2, message to the model) when a Bash command EXECUTES
#     `validate.sh` or `test/<name>.sh` AND the call is sandboxed
#     (tool_input.dangerouslyDisableSandbox is not true).
#   - Non-executing references stay allowed: `bash -n`, `shellcheck`, `cat`,
#     `grep`, mentions inside strings — only an argv-position script execution
#     trips it, per shell segment (split on && || ; | and newlines).
#   - Passthru wrappers are seen through (GH-233 agy review): `command`, `eval`,
#     `env [VAR=x] ...`, `exec`, `time`, `nohup`, `nice` are stripped so the real
#     argv0 beneath is classified; `.`/`source` count as executing interpreters.
#   - `cd`-into-test is tracked across segments: after `cd test`, a bare `*.sh`
#     in execution position (`cd test && bash hq-hardening.sh`) also blocks.
#   - Unsandboxed calls (dangerouslyDisableSandbox: true) are ALLOWED — mktemp
#     works there; local unsandboxed runs are the operator's normal workflow.
#   - Everything else → exit 0. Fail-open: any parse error allows the call
#     (same convention as relay-xyz-guard.sh).
#   - Known residuals (accepted — accidental-self-inflict threat model, not an
#     adversary): execution nested inside `$(...)`/backticks, and `xargs`/`find
#     -exec` dispatch, are not parsed. The static `test/mktemp-trap-guard.sh` and
#     CI-as-exercise-path are the backstops for those.
set -u

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0

printf '%s' "$payload" | python3 -c '
import json, re, shlex, sys

try:
    ev = json.load(sys.stdin)
except Exception:
    sys.exit(0)  # fail-open

if ev.get("tool_name") != "Bash":
    sys.exit(0)
ti = ev.get("tool_input") or {}
if ti.get("dangerouslyDisableSandbox") is True:
    sys.exit(0)  # unsandboxed: mktemp works, this vector does not exist
cmd = ti.get("command") or ""
if not cmd:
    sys.exit(0)

# A suite script in executable argv position: ./validate.sh, validate.sh,
# test/foo.sh, ./test/foo.sh, or an absolute path ending in /validate.sh.
suite = re.compile(r"^(?:\./)?(?:validate\.sh|test/[^/\s]+\.sh)$|/validate\.sh$")
# When a prior `cd` in the same command line has landed us in the test/ dir, a
# BARE *.sh basename (no test/ prefix) is also a suite execution — `cd test &&
# bash hq-hardening.sh`. Kept separate from `suite` so it only applies in-dir.
bare_sh = re.compile(r"^(?:\./)?[^/\s]+\.sh$")
interpreters = {"bash", "sh", "zsh", "dash", ".", "source"}
# Wrappers that pass their argument through to another command: strip them so
# the real argv0 underneath is what we classify (`command`/`eval`/`env ./validate.sh`).
passthru = {"command", "exec", "time", "nohup", "nice", "eval", "stdbuf", "ionice"}

def strip_wrappers(toks):
    changed = True
    while changed and toks:
        changed = False
        while toks and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", toks[0]):
            toks.pop(0); changed = True  # env assignments
        if toks and toks[0] == "env":
            toks.pop(0); changed = True   # env [-flags] [VAR=val ...] cmd ...
            while toks and (toks[0].startswith("-") or re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", toks[0])):
                toks.pop(0)
        if toks and toks[0] in passthru:
            toks.pop(0); changed = True
    return toks

def cd_target(segment):
    # Return the directory a `cd <dir>` segment moves to, else None.
    try:
        toks = shlex.split(segment)
    except ValueError:
        toks = segment.split()
    toks = [t.lstrip("(") for t in toks if t not in ("(", ")")]
    if len(toks) >= 2 and toks[0] == "cd":
        return toks[1]
    return None

def executes_suite(segment, in_test):
    try:
        toks = shlex.split(segment)
    except ValueError:
        toks = segment.split()
    toks = [t.lstrip("(") for t in toks]  # tolerate subshell `(cd …`
    toks = strip_wrappers([t for t in toks if t])
    if not toks:
        return False
    argv0 = toks[0]
    pat = suite if not in_test else re.compile(suite.pattern + r"|" + bare_sh.pattern)
    if argv0 in interpreters:
        if "-n" in [t for t in toks[1:] if t.startswith("-")]:
            return False  # syntax check only, nothing executes
        rest = [t for t in toks[1:] if not t.startswith("-")]
        return bool(rest) and bool(pat.match(rest[0]))
    return bool(pat.match(argv0))

in_test = False
for seg in re.split(r"&&|\|\||;|\||\n", cmd):
    seg = seg.strip()
    tgt = cd_target(seg)
    if tgt is not None:
        # crude but sufficient: are we now inside a dir literally named "test"?
        in_test = bool(re.search(r"(^|/)test/?$", tgt))
    if executes_suite(seg, in_test):
        sys.stderr.write(
            "GH-177 guard: refusing to run the test suite under a SANDBOXED Bash call.\n"
            "Sandbox-broken mktemp fed the destructive EXIT trap that wiped this repo twice\n"
            "(see PROJECT/3-COMPLETED/GH-177-MKTEMP-TRAP-REPO-WIPE.md). Options:\n"
            "  1. Let CI run it — tier1 runs npm ci + test/acorn-extract.sh (#232 tracks the full suite).\n"
            "  2. If a local run is truly needed, re-run this exact command with\n"
            "     dangerouslyDisableSandbox: true (mktemp works unsandboxed).\n"
        )
        sys.exit(2)
sys.exit(0)
'
rc=$?
[ "$rc" -eq 2 ] && exit 2
exit 0
