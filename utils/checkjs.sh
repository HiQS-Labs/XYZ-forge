#!/usr/bin/env bash
#
# checkjs.sh — Tier 1 JS boundary check for src/*.js (GH-71 Phase 2 / GH-61 Tier 1)
#
# Two deterministic, no-network checks over the tick projection kernel's public API surface:
#   1. `node --check` on every src/*.js — the exact Tier 1 lint GH-61 proposed for CI.
#   2. JSDoc coverage: every function named in a file's `module.exports = { ... }` must have a
#      `/** ... */` block immediately preceding its `function` declaration. This is what makes
#      "the API surface between the event log and the projection" (GH-71 Phase 2's stated goal)
#      an enforced boundary rather than a one-time annotation pass that silently rots.
#
# Not a type checker (no `tsc --checkJs` — this repo stays dependency-free per GUIDING-PRINCIPLES.md
# and the Phase 3/4 "dependency-free" precedent); JSDoc presence is the deterministic proxy for
# "the API surface is documented," matching this repo's existing pdda-check-* style (grep-based
# structural checks, not real language parsing).
#
# Usage:
#   bash utils/checkjs.sh [<dir>]      # default: src/
#
# Exit codes:
#   0 — clean, no findings
#   1 — one or more findings (syntax error or an undocumented exported function)
#
set -euo pipefail

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
SRC_DIR="${1:-$REPO_ROOT/src}"

FINDINGS=0

if [[ ! -d "$SRC_DIR" ]]; then
  echo "$SCRIPT_NAME: no such directory: $SRC_DIR" >&2
  exit 1
fi

# Extract the exported function names from a file's `module.exports = { ... }` block.
# Deliberately simple (grep/sed, bash 3.2-safe): matches bare identifiers and `foo: bar` /
# `foo,`-style entries; skips non-identifier entries (string literals, computed keys) since
# this repo's module.exports blocks are always plain identifier lists.
exported_names() {
  local f="$1"
  awk '
    /module\.exports[[:space:]]*=/ { inblock = 1 }
    inblock { print }
    inblock && /}/ { exit }
  ' "$f" \
    | tr ',' '\n' \
    | sed -E 's/module\.exports[[:space:]]*=[[:space:]]*\{//; s/\}.*//' \
    | sed -E 's/^[[:space:]]+|[[:space:]]+$//g' \
    | sed -E 's/:.*$//' \
    | grep -E '^[A-Za-z_$][A-Za-z0-9_$]*$' \
    || true
}

check_file() {
  local f="$1"
  local rel="${f#"$REPO_ROOT"/}"

  # --- Check 1: node --check (syntax gate, GH-61 Tier 1) ---
  local node_err
  if ! node_err="$(node --check "$f" 2>&1)"; then
    echo "CHECKJS: $rel  [node-check] $node_err" >&2
    FINDINGS=$((FINDINGS + 1))
    return # a file that doesn't parse can't be usefully doc-scanned either
  fi

  # --- Check 2: JSDoc coverage on the exported API surface ---
  local name
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue

    # Locate the function's declaration line: `function <name>(`. The pipeline's `|| true` matters:
    # under `set -e`+pipefail, a non-matching grep (an exported constant, not a function) would
    # otherwise abort the whole script instead of just skipping this one name.
    local decl_line
    decl_line="$(grep -nE "^function[[:space:]]+${name}[[:space:]]*\(" "$f" | head -1 | cut -d: -f1 || true)"
    [[ -z "$decl_line" ]] && continue # exported non-function (a constant/Set) — not in scope for JSDoc

    # A documented function has a line ending `*/` in the 20 lines immediately above the
    # declaration, with no intervening blank line right before it (i.e. the comment is
    # directly attached, not a stray earlier block separated by whitespace).
    local start=$((decl_line - 20))
    [[ "$start" -lt 1 ]] && start=1
    local prev_line=$((decl_line - 1))
    local prev_content
    prev_content="$(sed -n "${prev_line}p" "$f")"
    if [[ "$prev_content" =~ \*/[[:space:]]*$ ]]; then
      continue # documented
    fi

    echo "CHECKJS: $rel:$decl_line  [missing-jsdoc] exported function '$name' has no attached /** */ block" >&2
    FINDINGS=$((FINDINGS + 1))
  done < <(exported_names "$f")
}

scanned=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  check_file "$f"
  scanned=$((scanned + 1))
done < <(find "$SRC_DIR" -maxdepth 1 -type f -name '*.js' | sort)

if [[ "$scanned" -eq 0 ]]; then
  echo "$SCRIPT_NAME: no .js files found in $SRC_DIR" >&2
  exit 0
fi

if [[ "$FINDINGS" -gt 0 ]]; then
  echo "$SCRIPT_NAME: $FINDINGS finding(s) in $scanned file(s) — CHECK FAILED" >&2
  exit 1
else
  echo "$SCRIPT_NAME: clean — $scanned file(s), node --check + JSDoc coverage both pass"
  exit 0
fi
