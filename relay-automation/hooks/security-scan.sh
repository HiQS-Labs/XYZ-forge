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
#   bash relay-automation/hooks/security-scan.sh [--no-baseline] [--baseline FILE] [--tsv] [<path>...]
#
# --tsv prints each finding as `<file>\t<rule>\t<line text>` on stdout instead of the human-readable
# "SECURITY: ..." line — paste a row straight into the baseline file's tab-separated columns after
# confirming by hand it's a false positive / an accepted pattern (never generated automatically).
#
# With no path arguments, scans the paths listed in DEFAULT_SCAN_PATHS below.
# Each path argument may be a file or a directory (scanned recursively for *.sh files).
#
# Baseline (GH-64): a known-legitimate finding (a reviewed dispatcher `eval`, a test fixture, a doc
# comment matching a pattern in prose) is pre-approved by an exact `<file>\t<rule>\t<line text>` entry
# in the baseline file (default: relay-automation/hooks/security-scan-baseline.txt, next to this
# script). A baselined finding is STILL PRINTED (labeled "SECURITY (baselined)") — nothing is hidden,
# per GUIDING-PRINCIPLES.md #8 (no masked failure) — it just doesn't count toward the exit code, so the
# scan can be a real BLOCKING gate without hand-suppressing every existing legitimate pattern. Matching
# is by exact line TEXT, not line number, so it survives the file growing/shrinking elsewhere but a
# reformatted flagged line drops out of the baseline and must be re-reviewed (deliberate: no silent
# staleness). The baseline is hand-maintained, never auto-written — that keeps "add to baseline" a
# conscious, reviewed act, same spirit as "never auto-fixes" below. Use --no-baseline for a raw scan
# (e.g. auditing what's currently baselined, or a from-scratch review).
#
# Exit codes:
#   0  — clean: no findings, or every finding is baselined
#   1  — one or more NON-baselined security findings detected
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
readonly HOOKS_DIR_CONST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT_CONST="$(cd "$HOOKS_DIR_CONST/../.." && pwd)"

# Default targets when called with no arguments (relative to repo root).
# Callers that supply explicit paths override this entirely.
DEFAULT_SCAN_PATHS=(
  relay-automation
  bin
  test
)

USE_BASELINE=1
BASELINE_FILE="$HOOKS_DIR_CONST/security-scan-baseline.txt"
TSV_OUT=0

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
BASELINED=0

# baseline_hit <file> <rule> <line-text> — true (exit 0) iff this exact triple is pre-approved.
# Reads $BASELINE_FILE fresh each call (small file, called rarely enough that caching isn't worth
# the complexity). Format: <file>\t<rule>\t<line text>; '#'-prefixed and blank lines are comments.
baseline_hit() {
  local file="$1" rule="$2" text="$3"
  [[ "$USE_BASELINE" -eq 1 && -f "$BASELINE_FILE" ]] || return 1
  local bfile brule btext
  while IFS=$'\t' read -r bfile brule btext; do
    [[ -z "$bfile" || "$bfile" == \#* ]] && continue
    if [[ "$bfile" == "$file" && "$brule" == "$rule" && "$btext" == "$text" ]]; then
      return 0
    fi
  done < "$BASELINE_FILE"
  return 1
}

# scan_file <path>
# Runs each pattern against the file and prints findings to stderr.
scan_file() {
  local f="$1"
  # Baseline entries store the file path relative to the repo root (portable across clones/CI),
  # matching how they were authored — resolve once per file.
  local f_rel="${f#"$REPO_ROOT_CONST"/}"

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
        local text="${line#*:}"
        local baselined=0
        baseline_hit "$f_rel" "$label" "$text" && baselined=1
        if [[ "$TSV_OUT" -eq 1 ]]; then
          # Machine-parseable form for authoring/reviewing baseline entries: paste a line straight
          # into $BASELINE_FILE (already tab-separated in the right column order) after confirming
          # by hand it's a false positive / accepted pattern, never automatically.
          printf '%s\t%s\t%s\n' "$f_rel" "$label" "$text"
        elif [[ "$baselined" -eq 1 ]]; then
          echo "SECURITY (baselined): $f:$line  [$label]" >&2
        else
          echo "SECURITY: $f:$line  [$label]" >&2
        fi
        if [[ "$baselined" -eq 1 ]]; then
          BASELINED=$((BASELINED + 1))
        else
          FINDINGS=$((FINDINGS + 1))
        fi
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
  local REPO_ROOT="$REPO_ROOT_CONST"

  # ── flag parsing (baseline options only; everything else is a scan path) ──
  local -a path_args=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-baseline) USE_BASELINE=0; shift ;;
      --baseline)    BASELINE_FILE="${2:?--baseline requires a FILE argument}"; shift 2 ;;
      --tsv)         TSV_OUT=1; shift ;;
      *)             path_args+=("$1"); shift ;;
    esac
  done

  # Resolve scan targets.
  local -a targets
  if [[ "${#path_args[@]}" -gt 0 ]]; then
    targets=("${path_args[@]}")
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

  local baseline_note=""
  [[ "$BASELINED" -gt 0 ]] && baseline_note=" ($BASELINED baselined, see $BASELINE_FILE)"

  if [[ "$FINDINGS" -gt 0 ]]; then
    echo "$SCRIPT_NAME: $FINDINGS finding(s) in $scanned file(s) — SCAN FAILED$baseline_note" >&2
    exit 1
  else
    echo "$SCRIPT_NAME: clean — $scanned file(s) scanned, 0 non-baselined findings$baseline_note"
    exit 0
  fi
}

main "$@"
