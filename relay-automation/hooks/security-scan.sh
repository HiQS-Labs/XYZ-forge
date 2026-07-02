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
# PATTERN_CRED_ASSIGN's value is bounded to a single whitespace/semicolon-free token (not `.{4,}`,
# which used to run to end-of-line) so `grep -noE` yields ONE match PER key=value occurrence, even
# when several sit on the same line. PATTERN_CRED_EXCLUDE is then tested against each individual
# matched SNIPPET (not the whole line) in _check_credential() below — exclude when the value
# immediately after = starts with $, (, or { (a variable/subshell reference), optionally behind a
# quote. Matching+excluding per-occurrence (not per-line) closes a real bypass: a line combining a
# legitimate reference with a hardcoded secret (`password=$REF; api_key=realsecret`, or a trailing
# `# password=$VAR` comment on the same line as a real secret) used to have the WHOLE line dropped
# by the old line-level exclude filter, hiding the real secret (agy relay QA, 2026-07-01, [Blocker]).
PATTERN_CRED_ASSIGN='(password|secret|api_key|API_KEY|SECRET|PASSWORD)[[:space:]]*=[[:space:]]*[^[:space:];]{4,}'
PATTERN_CRED_EXCLUDE='(password|secret|api_key|API_KEY|SECRET|PASSWORD)[[:space:]]*=[[:space:]]*"?[$({]'

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
  # Every rule re-greps the same file, so an unreadable/errored file would otherwise report the
  # identical scan-error once per rule (7x). One report per file is enough to fail loud without the
  # noise; reset per scan_file() call.
  local _scan_error_reported=0

  # _report <label> <lineno> <text> — shared by _check() and _check_credential(): baseline lookup,
  # TSV/human output, and the FINDINGS/BASELINED tally.
  _report() {
    local label="$1" lineno="$2" text="$3"
    local baselined=0
    baseline_hit "$f_rel" "$label" "$text" && baselined=1
    if [[ "$TSV_OUT" -eq 1 ]]; then
      # Machine-parseable form for authoring/reviewing baseline entries: paste a line straight
      # into $BASELINE_FILE (already tab-separated in the right column order) after confirming
      # by hand it's a false positive / accepted pattern, never automatically.
      printf '%s\t%s\t%s\n' "$f_rel" "$label" "$text"
    elif [[ "$baselined" -eq 1 ]]; then
      echo "SECURITY (baselined): $f:$lineno:$text  [$label]" >&2
    else
      echo "SECURITY: $f:$lineno:$text  [$label]" >&2
    fi
    if [[ "$baselined" -eq 1 ]]; then
      BASELINED=$((BASELINED + 1))
    else
      FINDINGS=$((FINDINGS + 1))
    fi
  }

  # _grep_or_fail_loud <grep-args...> — runs grep, leaving stdout in $_GREP_OUT (bash-3.2-safe: no
  # `local -n` nameref, which stock macOS bash doesn't support — see relay-turn-lib.sh). grep exit 1
  # (no match — the overwhelmingly common case) is silently treated as "no hits", but any OTHER
  # nonzero exit (2+: bad pattern, unreadable file, etc.) is a real scan error and must NOT read as
  # "file is clean" — that would be exactly the masked failure GUIDING-PRINCIPLES.md #8 forbids.
  # Reports a `[scan-error]` finding (counts toward FINDINGS, fails the scan) instead. Returns 1 if
  # the caller should stop processing this pattern (real error), 0 otherwise (matches or none).
  local _GREP_OUT=""
  _grep_or_fail_loud() {
    local rc=0
    _GREP_OUT="$(/usr/bin/grep "$@" 2>/dev/null)" || rc=$?
    if [[ "$rc" -gt 1 ]]; then
      if [[ "$_scan_error_reported" -eq 0 ]]; then
        _scan_error_reported=1
        _report "scan-error" "-" "grep exited $rc scanning $f — treating as a finding, not silently clean"
      fi
      return 1
    fi
    return 0
  }

  # _check <label> <pattern> — greps for pattern, one finding per matching LINE (whole-line text).
  # Use -e <pattern> so patterns that start with '-' (e.g. PEM key headers) are not misinterpreted
  # as grep flags.
  _check() {
    local label="$1" pattern="$2"
    local hits
    _grep_or_fail_loud -nE -e "$pattern" "$f" || return 0
    hits="$_GREP_OUT"
    [[ -z "$hits" ]] && return
    while IFS= read -r line; do
      _report "$label" "${line%%:*}" "${line#*:}"
    done <<< "$hits"
  }

  # _check_credential <label> <pattern> <exclude> — R7 only. Unlike _check(), matches and excludes
  # PER OCCURRENCE (via `grep -noE`, one row per key=value token) instead of per whole line, so a
  # line combining a real secret with an excluded variable reference (`password=$REF;
  # api_key=realsecret`, or a trailing `# password=$VAR` comment next to a real assignment) can't
  # hide the real one behind the excluded one — the old whole-line exclude dropped the entire line
  # when ANY part of it matched the exclude pattern (agy relay QA, 2026-07-01, [Blocker]).
  _check_credential() {
    local label="$1" pattern="$2" exclude="$3"
    local hits
    _grep_or_fail_loud -noE -e "$pattern" "$f" || return 0
    hits="$_GREP_OUT"
    [[ -z "$hits" ]] && return
    while IFS= read -r hit; do
      local lineno="${hit%%:*}" snippet="${hit#*:}"
      /usr/bin/grep -qE -e "$exclude" <<< "$snippet" 2>/dev/null && continue
      _report "$label" "$lineno" "$snippet"
    done <<< "$hits"
  }

  _check "eval-unsanitized"   "$PATTERN_EVAL"
  _check "pipe-remote-shell"  "$PATTERN_PIPE_SHELL"
  _check "aws-access-key"     "$PATTERN_AWS_KEY"
  _check "pem-private-key"    "$PATTERN_PEM_KEY"
  _check "github-pat"         "$PATTERN_GH_PAT"
  _check "slack-token"        "$PATTERN_SLACK"
  _check_credential "credential-literal" "$PATTERN_CRED_ASSIGN" "$PATTERN_CRED_EXCLUDE"
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
