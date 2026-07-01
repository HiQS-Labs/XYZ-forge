#!/usr/bin/env bash
#
# security-scan.sh — static security scanner for shell scripts (GH-64)
#
# Implements fail-loud detection per GUIDING-PRINCIPLES.md #8 (no masked failure):
# every finding is printed to stderr as SECURITY: <file>:<line> <reason>, and the
# script exits NON-ZERO if any finding is emitted.  It never auto-fixes, never
# silently suppresses.  No network access required.
#
# Usage:
#   bash relay-automation/hooks/security-scan.sh [<path>...]
#
# With no arguments, scans the paths listed in DEFAULT_SCAN_PATHS below.
# Each argument may be a file or a directory (scanned recursively for *.sh files).
#
# Exit codes:
#   0  — clean, no findings
#   1  — one or more security findings detected
#
# Detection rules (grep-nE based):
#   R1  eval of variable / unsanitized input     eval "$foo" / eval $foo
#   R2  piped remote execution                   curl/wget ... | sh/bash
#   R3  AWS access key                           AKIA[0-9A-Z]{16}
#   R4  PEM private key header                   -----BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY-----
#   R5  GitHub personal access token             ghp_[A-Za-z0-9]{36}
#   R6  Slack token                              xox[baprs]-
#   R7  Literal credential assignment            password=/secret=/api_key= with a value
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Default targets when called with no arguments (relative to repo root).
# Callers that supply explicit paths override this entirely.
DEFAULT_SCAN_PATHS=(
  relay-automation
  bin
  test
)

# ---------------------------------------------------------------------------
# Pattern definitions  (POSIX ERE, passed to grep -nE)
# ---------------------------------------------------------------------------

# R1: eval applied to a variable or subshell (not a quoted string literal)
# Matches: eval "$foo", eval $foo, eval "$(…)", eval $(…)
# Does NOT match: eval "literal string" (false-positive rate too high for review scripts)
PATTERN_EVAL='eval[[:space:]]+(\$[^"'"'"' ]|\$\{|\$\(|"[[:space:]]*\$)'

# R2: curl or wget piped to a shell interpreter
PATTERN_PIPE_SHELL='(curl|wget)[^|]*\|[[:space:]]*(ba)?sh'

# R3: AWS access key ID
PATTERN_AWS_KEY='AKIA[0-9A-Z]{16}'

# R4: PEM private key block start
# Note: pattern starts with '-', so must be passed via -e flag to grep (not as positional arg)
PATTERN_PEM_KEY='-----BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY-----'

# R5: GitHub personal access token (classic format, 40 chars total = ghp_ + 36 alphanum)
# Use + quantifier: BSD grep on macOS has known issues with exact {n} counts in some versions
PATTERN_GH_PAT='ghp_[A-Za-z0-9]{36,}'

# R6: Slack token prefixes
PATTERN_SLACK='xox[baprs]-[A-Za-z0-9]'

# R7: Generic credential assignment with a literal value (not a variable reference).
# Step 1 (PATTERN_CRED_ASSIGN): match any credential key assignment with a value of 4+ chars.
# Step 2 (PATTERN_CRED_EXCLUDE): exclude lines where the value immediately after = starts
#   with $, (, or { — those are variable/subshell references, not literal secrets.
# Two-pass approach: grep for matches, then filter out the exclusions.
PATTERN_CRED_ASSIGN='(password|secret|api_key|API_KEY|SECRET|PASSWORD)[[:space:]]*=.{4,}'
PATTERN_CRED_EXCLUDE='(password|secret|api_key|API_KEY|SECRET|PASSWORD)[[:space:]]*=[[:space:]]*[$({]|(password|secret|api_key|API_KEY|SECRET|PASSWORD)[[:space:]]*=[[:space:]]*"[$({]|(password|secret|api_key|API_KEY|SECRET|PASSWORD)[[:space:]]*=[[:space:]]*'"'"'[$({]'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

FINDINGS=0

# scan_file <path>
# Runs each pattern against the file and prints findings to stderr.
scan_file() {
  local f="$1"

  # _check <label> <include-pattern> [<exclude-pattern>]
  # Greps for include-pattern; if exclude-pattern given, filters those lines out.
  # Use -e <pattern> so patterns that start with '-' (e.g. PEM key headers) are
  # not misinterpreted as grep flags.  grep exits 1 with no matches — expected.
  _check() {
    local label="$1" pattern="$2" exclude="${3:-}"
    local hits
    hits="$(/usr/bin/grep -nE -e "$pattern" "$f" 2>/dev/null || true)"
    if [[ -n "$exclude" && -n "$hits" ]]; then
      hits="$(printf '%s\n' "$hits" | /usr/bin/grep -vE -e "$exclude" 2>/dev/null || true)"
    fi
    if [[ -n "$hits" ]]; then
      while IFS= read -r line; do
        echo "SECURITY: $f:$line  [$label]" >&2
        FINDINGS=$((FINDINGS + 1))
      done <<< "$hits"
    fi
  }

  _check "eval-unsanitized"   "$PATTERN_EVAL"
  _check "pipe-remote-shell"  "$PATTERN_PIPE_SHELL"
  _check "aws-access-key"     "$PATTERN_AWS_KEY"
  _check "pem-private-key"    "$PATTERN_PEM_KEY"
  _check "github-pat"         "$PATTERN_GH_PAT"
  _check "slack-token"        "$PATTERN_SLACK"
  _check "credential-literal" "$PATTERN_CRED_ASSIGN" "$PATTERN_CRED_EXCLUDE"
}

# collect_files <path>...
# Prints the list of .sh files to scan to stdout.
collect_files() {
  for p in "$@"; do
    if [[ -f "$p" ]]; then
      echo "$p"
    elif [[ -d "$p" ]]; then
      find "$p" -type f -name '*.sh' | sort
    else
      echo "$SCRIPT_NAME: warning: path not found: $p" >&2
    fi
  done
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  # Determine repo root (two levels up from this script's directory).
  local HOOKS_DIR
  HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local REPO_ROOT
  REPO_ROOT="$(cd "$HOOKS_DIR/../.." && pwd)"

  # Resolve scan targets.
  local -a targets
  if [[ $# -gt 0 ]]; then
    targets=("$@")
  else
    # Make default paths absolute relative to repo root.
    targets=()
    for p in "${DEFAULT_SCAN_PATHS[@]}"; do
      targets+=("$REPO_ROOT/$p")
    done
  fi

  # Collect files to scan and process them directly (bash 3.2 compatible — no mapfile).
  local scanned=0
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    scan_file "$f"
    scanned=$((scanned + 1))
  done < <(collect_files "${targets[@]}")

  if [[ "$scanned" -eq 0 ]]; then
    echo "$SCRIPT_NAME: no .sh files found in specified paths" >&2
    exit 0
  fi

  if [[ "$FINDINGS" -gt 0 ]]; then
    echo "$SCRIPT_NAME: $FINDINGS finding(s) in $scanned file(s) — SCAN FAILED" >&2
    exit 1
  else
    echo "$SCRIPT_NAME: clean — $scanned file(s) scanned, 0 findings"
    exit 0
  fi
}

main "$@"
