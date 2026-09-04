#!/usr/bin/env bash
#
# relay-xyz-guard.sh — PreToolUse guard that stops a session from driving the relay
# harness before it has actually loaded the relay-xyz skill.
#
# The recurring failure this closes: a session runs `ls relay-automation/`, assumes it
# understands the handoff, and improvises its own harness instead of invoking the
# relay-xyz skill. The skill's content can't fix that, because the agent never opens it.
# A hook can — the harness executes it, not the model, so a confident agent can't skip it.
#
# Wiring (.claude/settings.json):
#   "hooks": { "PreToolUse": [ { "matcher": "Bash|Skill",
#     "hooks": [ { "type": "command",
#       "command": "bash relay-automation/hooks/relay-xyz-guard.sh" } ] } ] }
#
# Contract (reads the PreToolUse JSON event on stdin):
#   - PROOF-OF-LOAD signals → record this session as "skill loaded", then allow:
#       * Skill tool invoked with skill == relay-xyz
#       * Bash command that runs the skill's own locator (find-harness.sh)
#   - BLOCK (exit 2, message to the model) when a Bash command EXECUTES a harness entrypoint
#       derived from AGENTS.md's Tier-A inventory, or any relay-automation/*-turn.sh shim,
#       AND this session has not loaded the skill.
#       Exit 2 feeds stderr back to the model and cancels the tool call.
#   - Everything else → exit 0 (allow). Fail-open: any parse error allows the call.
#
# Precision notes:
#   - The command is parsed to identify programs in execution position. A read, echo, grep, or
#     other command that only mentions an entrypoint path is exempt.
#   - KNOWN RESIDUALS (fail-open by design, recorded so it stays a decision): eval '…', `source`/`.`,
#     `… | bash`, combined short-flag forms like `bash -ec '…'` (only the exact `-c` token is
#     recognised), subshell parens, and `bash -nv` combined with other short flags being read as
#     execution. Closing these is future work, not a silent gap.
#   - Session-scoped via the event's session_id, so a marker from one session never
#     suppresses the guard in another.
set -u

input="$(cat)"

# Extract (session_id, tool_name, field) as one tab-delimited line.
# field = the Skill name for Skill events, else the Bash command. Tabs/newlines stripped
# from field so the tab-delimited read below stays single-line; session_id is first
# and tool second so the variable-length field can safely land last.
#
# Fast path is jq — a small, fast binary, so no per-tool-call interpreter cold start.
# python3 stays as a fallback for the rare host without jq, keeping parsing robust
# everywhere. Either extractor prints nothing on malformed input, so the guard fails
# open below (empty parse → exit 0).
if command -v jq >/dev/null 2>&1; then
  parsed="$(printf '%s' "$input" | jq -r '
    [ (.session_id // "nosession"),
      (.tool_name  // ""),
      ( (if (.tool_name // "") == "Skill"
           then (.tool_input.skill // .tool_input.name // "")
           else (.tool_input.command // "")
         end) | tostring | gsub("[\t\n\r]"; " ") )
    ] | join("\t")
  ' 2>/dev/null)"
else
  parsed="$(RELAY_GUARD_EVENT="$input" python3 <<'PY' 2>/dev/null
import os, json
try:
    d = json.loads(os.environ.get("RELAY_GUARD_EVENT", ""))
except Exception:
    raise SystemExit(0)
tool = d.get("tool_name", "") or ""
ti = d.get("tool_input", {}) or {}
if tool == "Skill":
    field = ti.get("skill", "") or ti.get("name", "")
else:
    field = ti.get("command", "")
sess = d.get("session_id", "") or "nosession"
field = str(field).replace("\t", " ").replace("\n", " ").replace("\r", " ")
print("%s\t%s\t%s" % (sess, tool, field))
PY
)"
fi

# Parse error or empty → fail open.
[ -n "$parsed" ] || exit 0
IFS=$'\t' read -r SESSION TOOL FIELD <<EOF
$parsed
EOF

STATE_DIR="${TMPDIR:-/tmp}/relay-xyz-guard-${UID}"
mkdir -p "$STATE_DIR" 2>/dev/null || true
MARKER="$STATE_DIR/${SESSION//[^A-Za-z0-9_-]/_}"

# --- proof-of-load: the skill was actually invoked this session ---
if [ "$TOOL" = "Skill" ]; then
  case "$FIELD" in *relay-xyz*) : > "$MARKER" 2>/dev/null || true ;; esac
  exit 0
fi

[ "$TOOL" = "Bash" ] || exit 0

# Running the skill's own locator is the Preconditions step the skill mandates —
# treat it as proof the skill is being followed.
case "$FIELD" in
  *find-harness.sh*) : > "$MARKER" 2>/dev/null || true; exit 0 ;;
esac

# --- harness entrypoints: derive the surface; do not maintain a second hand-written list ---
#
# AGENTS.md is the authoritative Tier-A inventory (GH-308). New model shims are intentionally
# included by the tree glob as well: a new *-turn.sh must not wait for somebody to remember this
# hook. Python names are included because calling the authoritative Python twin directly drives the
# same harness just as much as invoking its historical Bash shim.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
is_harness_entrypoint() {
  RELAY_GUARD_ROOT="$ROOT" RELAY_GUARD_COMMAND="$FIELD" python3 - <<'PY' 2>/dev/null
import glob
import os
import re
import shlex
import sys

root = os.environ["RELAY_GUARD_ROOT"]
command = os.environ["RELAY_GUARD_COMMAND"]
agents = os.path.join(root, "AGENTS.md")

try:
    text = open(agents, encoding="utf-8").read()
    m = re.search(r"Tier-A[\s\S]*?entry points\s*\(([^)]+)\)", text)
    if not m:
        raise SystemExit(1)
    names = set(re.findall(r"`([^`]+)`", m.group(1)))
except (OSError, ValueError):
    raise SystemExit(1)  # Fail open when the source inventory cannot be read.

entrypoints = set()
for name in names:
    for base in ("relay-automation", "utils"):
        candidate = os.path.join(root, base, name + ".sh")
        if os.path.isfile(candidate):
            entrypoints.add(os.path.realpath(candidate))
    python_name = name.replace("-", "_") + ".py"
    candidate = os.path.join(root, "utils", "py", python_name)
    if os.path.isfile(candidate):
        entrypoints.add(os.path.realpath(candidate))

for candidate in glob.glob(os.path.join(root, "relay-automation", "*-turn.sh")):
    if os.path.isfile(candidate):
        entrypoints.add(os.path.realpath(candidate))

def is_entrypoint(value):
    if not value or value.startswith("-"):
        return False
    candidate = value if os.path.isabs(value) else os.path.join(root, value)
    return os.path.realpath(candidate) in entrypoints

def segments(source):
    try:
        lexer = shlex.shlex(source, posix=True, punctuation_chars=";&|")
        lexer.whitespace_split = True
        tokens = list(lexer)
    except ValueError:
        return []
    result, current = [], []
    for token in tokens:
        if token and set(token) <= set(";&|"):
            if current:
                result.append(current)
                current = []
        else:
            current.append(token)
    if current:
        result.append(current)
    return result

def executes(argv):
    index = 0
    while index < len(argv) and re.match(r"[A-Za-z_][A-Za-z0-9_]*=", argv[index]):
        index += 1
    if index >= len(argv):
        return False
    if os.path.basename(argv[index]) == "env":
        index += 1
        while index < len(argv) and (argv[index].startswith("-") or re.match(r"[A-Za-z_][A-Za-z0-9_]*=", argv[index])):
            index += 1
    while index < len(argv) and os.path.basename(argv[index]) in {"command", "exec", "sudo"}:
        index += 1
        while index < len(argv) and argv[index].startswith("-"):
            index += 1
    if index >= len(argv):
        return False

    program = os.path.basename(argv[index])
    if program in {"bash", "sh", "zsh"}:
        options = argv[index + 1:]
        if "-n" in options or "--noexec" in options:
            return False
        if "-c" in options:
            command_index = options.index("-c") + 1
            return any(executes(part) for part in segments(options[command_index])) if command_index < len(options) else False
        script = next((arg for arg in options if not arg.startswith("-")), "")
        return is_entrypoint(script)
    if program in {"python", "python3"}:
        script = next((arg for arg in argv[index + 1:] if not arg.startswith("-")), "")
        return is_entrypoint(script)
    return is_entrypoint(argv[index])

raise SystemExit(0 if any(executes(part) for part in segments(command)) else 1)
PY
}

if is_harness_entrypoint; then
  if [ ! -f "$MARKER" ]; then
    cat >&2 <<'MSG'
relay-xyz guard — STOP. You are about to drive the relay harness, but the relay-xyz
skill has not been loaded in this session.

Invoke the relay-xyz skill FIRST (Skill tool → relay-xyz). Do not hand-roll the handoff
or build your own harness from `ls relay-automation/`. The skill owns:
  • the device-agnostic locator (find-harness.sh) — never hardcode a path
  • the Bash-sandbox rules for the codex/agy subprocess
  • the exit codes and the containment / safety boundary (path-allowlist, no push)

If you have already read it, run the skill's Preconditions block (find-harness.sh) and retry.
MSG
    exit 2
  fi
fi

exit 0
