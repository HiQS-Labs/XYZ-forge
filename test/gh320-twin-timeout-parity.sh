#!/usr/bin/env bash
# GH-320: every turn-taker's Python twin must default RELAY_TURN_TIMEOUT_S to the same value as its
# Bash twin — which is the value that twin's header documents to the operator.
#
# Found live: utils/py/agy-turn.py defaulted to 300 while relay-automation/agy-turn.sh defaulted to
# 900 and its header said "default: 900". Python is the executing lane (XYZ_PYTHON unset → Python
# since GH-264), so an agy review turn was killed at 300s — "agy -p exceeded 300s wall-clock cap" —
# on a budget documented as 900. codex-turn had the same 900↔300 split; claude-turn was 600↔300.
#
# GH-308 freezes the Bash twins so Python can be authoritative, but a freeze only prevents the twins
# from drifting FORWARD. This pins the numeric defaults that had ALREADY drifted, and does it by
# reading both files rather than restating either value here — a hardcoded expectation would just be
# a third copy to drift.
source "$(dirname "$0")/_setup.sh" gh320-twin-timeout-parity
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

TWINS=(
  agy-turn:relay-automation/agy-turn.sh:utils/py/agy-turn.py
  codex-turn:relay-automation/codex-turn.sh:utils/py/codex-turn.py
  claude-turn:relay-automation/claude-turn.sh:utils/py/claude-turn.py
  aider-turn:relay-automation/aider-turn.sh:utils/py/aider-turn.py
  pi-turn:relay-automation/pi-turn.sh:utils/py/pi-turn.py
)

for entry in "${TWINS[@]}"; do
  name="${entry%%:*}"; rest="${entry#*:}"
  sh_rel="${rest%%:*}"; py_rel="${rest#*:}"
  sh_path="$ROOT/$sh_rel"; py_path="$ROOT/$py_rel"

  [ -f "$sh_path" ] || { fail "$name: missing $sh_rel"; continue; }
  [ -f "$py_path" ] || { fail "$name: missing $py_rel"; continue; }

  # The assignment, not the header comment — the comment is what misled, so it is checked separately.
  sh_default="$(grep -oE 'turn_timeout="\$\{RELAY_TURN_TIMEOUT_S:-[0-9]+\}"' "$sh_path" \
    | head -1 | grep -oE '[0-9]+')"
  py_default="$(grep -oE 'RELAY_TURN_TIMEOUT_S", *[0-9]+' "$py_path" \
    | head -1 | grep -oE '[0-9]+$')"

  if [ -z "$sh_default" ]; then fail "$name: no turn_timeout default found in $sh_rel"; continue; fi
  if [ -z "$py_default" ]; then fail "$name: no turn_timeout default found in $py_rel"; continue; fi

  if [ "$sh_default" = "$py_default" ]; then
    pass "$name: Bash and Python both default to ${sh_default}s"
  else
    fail "$name: Bash defaults to ${sh_default}s but Python defaults to ${py_default}s — Python is the executing lane, so ${py_default}s is what actually applies"
  fi

  # The Bash header is the operator-facing contract ("default: N"). If it disagrees with the code,
  # the documentation is the thing that lies, which is how this went unnoticed.
  doc_default="$(grep -oE 'RELAY_TURN_TIMEOUT_S — per-turn wall-clock ceiling in seconds \(default: [0-9]+' "$sh_path" \
    | head -1 | grep -oE '[0-9]+$')"
  if [ -z "$doc_default" ]; then
    fail "$name: $sh_rel header does not document a RELAY_TURN_TIMEOUT_S default"
  elif [ "$doc_default" = "$sh_default" ]; then
    pass "$name: header documents ${doc_default}s, matching the code"
  else
    fail "$name: header documents ${doc_default}s but the code defaults to ${sh_default}s"
  fi
done

echo "  gh320-twin-timeout-parity: $PASS pass, $FAIL fail"
exit 0
