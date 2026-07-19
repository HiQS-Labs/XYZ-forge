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
#   - BLOCK (exit 2, message to the model) when a Bash command EXECUTES a harness driver
#       entrypoint under relay-automation/ AND this session has not loaded the skill.
#       Exit 2 feeds stderr back to the model and cancels the tool call.
#   - Everything else → exit 0 (allow). Fail-open: any parse error allows the call.
#
# Precision notes:
#   - Only relay-automation/<driver>.sh paths block — test/<driver>.sh and reads are exempt,
#     so `validate.sh` and the shim tests never trip it.
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

# Inspection (read-only) of a harness file is not "driving" — never block it.
first="${FIELD%% *}"
case "$first" in
  cat|head|tail|less|more|wc|grep|rg|ls|bat|file|stat|chmod|git|find|awk|sed) exit 0 ;;
esac
case "$FIELD" in *"bash -n "*) exit 0 ;; esac

# --- driver entrypoints: executing these IS driving the harness ---
case "$FIELD" in
  *relay-automation/relay-drive.sh*|\
  *relay-automation/marathon-drive.sh*|\
  *relay-automation/marathon.sh*|\
  *relay-automation/poll.sh*|\
  *relay-automation/codex-turn.sh*|\
  *relay-automation/agy-turn.sh*)
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
    ;;
esac

exit 0
