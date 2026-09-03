#!/usr/bin/env bash
# gate-env.sh — GH-441 Phase 2. SOURCE this at the top of any `--pre-advance-cmd`.
#
#   . "$(dirname "$0")/relay-automation/gate-env.sh"      # or an absolute path
#
# It clears the variables a live marathon exports that would otherwise flip a suite's verdict, so the
# gate reports on the change under review rather than on its parent.
#
# WHY A HELPER AND NOT A COPIED PROLOGUE
# `validate.sh` used to carry its own hardcoded `unset` line. That worked only for validate.sh: any
# custom gate that did not copy it was silently wrong, and one did — a hand-written gate on
# 2026-08-07 reproduced test/oracle-guard.sh's failure because it inherited ALLOW_PATHS (ambient →
# 10 pass/1 fail; unset → 11/0). It cost two marathon rounds and three clean standalone re-runs
# before the variable was found. A gate cannot be expected to remember a list it does not own.
#
# SINGLE SOURCE OF TRUTH
# The list comes from utils/py/gate_env.py, the same registry `marathon_drive._gate_env()` uses, so
# the shell side and the driver side cannot drift. Do not inline the names here — a second copy of
# the list is the defect this replaces. `test/gh441-gate-env-contract.sh` asserts the two agree.
#
# NOT SCRUBBED: RELAY_DRIVER_LOCKED. Nested drivers need it SET; suites asserting real lock
# acquisition need it UNSET; no global value is correct. Scrubbing it was landed and reverted
# (2026-08-07). The two suites that need it clear do so themselves — GH-441 Phase 1.

# Resolve the harness root from this script's own location, following symlinks, so sourcing works
# from any CWD and from a vendored .xyz/ install. No machine path is ever hardcoded.
_hp_lib="$(dirname "${BASH_SOURCE[0]:-$0}")/harness-paths.sh"
if [ -f "$_hp_lib" ]; then
  # shellcheck source=relay-automation/harness-paths.sh
  . "$_hp_lib"
fi
_ge_dir="$(xyz_resolve_self_dir "${BASH_SOURCE[0]:-$0}")"
_ge_root="$(cd -P "$_ge_dir/.." && pwd)"
_ge_py="$_ge_root/utils/py/gate_env.py"

if [ -r "$_ge_py" ]; then
  # One name per line from the registry, applied by an explicit loop.
  #
  # The first draft of this file instead shell-evaluated a generated `unset A B C` line. The GH-64
  # security gate rejected it as `eval-unsanitized` and was right to: nothing should hand generated
  # text to the shell for interpretation when a loop does the same job. This form has no shell
  # evaluation at all, and validates each name against a strict pattern before acting on it.
  #
  # (The rewrite of this very comment was also a finding: the scanner matches the four-letter
  # builtin anywhere in the file, comments included, so the earlier wording tripped it while the
  # code beneath was already clean.)
  # Read one name per line. A `for _ge_n in $_ge_names` loop would be a bug in any shell that does
  # NOT word-split unquoted parameters — zsh does not, so it would pass the whole newline-joined blob
  # as a single name and fail with `invalid parameter name` (observed 2026-08-07). A heredoc-fed
  # `while read` behaves identically in bash and zsh, and unlike a pipe it keeps the loop in the
  # CURRENT shell so the unsets survive.
  _ge_names="$(python3 "$_ge_py" --list-scrubbed 2>/dev/null || true)"
  if [ -n "$_ge_names" ]; then
    while IFS= read -r _ge_n; do
      [ -n "$_ge_n" ] || continue
      case "$_ge_n" in
        [A-Z_][A-Z_0-9]*) unset "$_ge_n" ;;
        *) printf 'gate-env.sh: refusing to unset malformed name from the registry: %s\n' "$_ge_n" >&2 ;;
      esac
    done <<GATE_ENV_NAMES
$_ge_names
GATE_ENV_NAMES
  else
    # Fail LOUDLY rather than leaving the gate contaminated and looking clean. A gate that silently
    # skips its own scrub is the exact shape GH-441 is about: a check reporting a verdict on a
    # question it never asked.
    printf 'gate-env.sh: could not read the scrub list from %s — refusing to run a gate with an ungoverned environment.\n' "$_ge_py" >&2
    printf 'gate-env.sh: (this guard exists because a silently-unscrubbed gate reports its PARENT'\''s failures as the change'\''s own — see GH-441.)\n' >&2
    return 1 2>/dev/null || exit 1
  fi
else
  printf 'gate-env.sh: %s not found — refusing to run a gate with an ungoverned environment (GH-441).\n' "$_ge_py" >&2
  return 1 2>/dev/null || exit 1
fi

unset _ge_src _ge_dir _ge_root _ge_py _ge_names _ge_n
