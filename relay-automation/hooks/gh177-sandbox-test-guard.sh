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
#   - Unsandboxed calls (dangerouslyDisableSandbox: true) are ALLOWED — mktemp
#     works there; local unsandboxed runs are the operator's normal workflow.
#   - Everything else → exit 0. Fail-open: any parse error allows the call
#     (same convention as relay-xyz-guard.sh).
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
interpreters = {"bash", "sh", "zsh", "dash"}

def executes_suite(segment):
    try:
        toks = shlex.split(segment)
    except ValueError:
        toks = segment.split()
    while toks and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", toks[0]):
        toks.pop(0)  # skip leading env assignments
    if not toks:
        return False
    argv0 = toks[0]
    if argv0 in interpreters:
        flags = [t for t in toks[1:] if t.startswith("-")]
        if "-n" in flags:
            return False  # syntax check only, nothing executes
        rest = [t for t in toks[1:] if not t.startswith("-")]
        return bool(rest) and bool(suite.match(rest[0]))
    return bool(suite.match(argv0))

for seg in re.split(r"&&|\|\||;|\||\n", cmd):
    if executes_suite(seg.strip()):
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
