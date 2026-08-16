#!/usr/bin/env bash
# resolve-model-alias.sh (GH-120) — fuzzy lookup of a colloquial OpenRouter model name against
# the local alias table (openrouter-model-aliases.yml), returning the canonical
# `provider/slug[:variant]` id without a live query against
# https://openrouter.ai/api/v1/models.
#
# Usage:
#   resolve-model-alias.sh "<name>"
#   -> prints the canonical slug on stdout and exits 0 on a match; exits 1 (no output on
#      stdout) if nothing in the table matches; exits 2 on a usage error.
#
# Matching is tiered, most-exact first, first match in file order wins each tier:
#   1. normalized exact match      (case/punctuation/hyphen/whitespace-insensitive)
#   2. squashed exact match        (also whitespace-insensitive: "GLM5.2" == "glm-5.2")
#   3. sorted-token exact match    (order-insensitive: "Nemotron 3 Ultra" == "nemotron ultra 3")
#   4. squashed substring fallback (last resort, either direction contains the other)
#
# bash 3.2-portable (stock macOS): no `declare -A` (parallel indexed arrays instead), no
# `readlink -f`.
set -euo pipefail

# Resolve this script's real directory (bash 3.2 / macOS safe — no readlink -f).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
ALIASES_FILE="${MODEL_ALIASES_FILE:-$SCRIPT_DIR/openrouter-model-aliases.yml}"

# normalize <string>: lowercase, collapse every run of non-alphanumeric chars to one space,
# trim leading/trailing space.
normalize() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/ /g; s/^ +//; s/ +$//'
}

# squash <string>: normalize, then drop all remaining spaces (order-sensitive concat match —
# catches "nemotron-ultra3" vs the "nemotron ultra 3" key).
squash() {
  normalize "$1" | tr -d ' '
}

# sorted_tokens <string>: normalize, split into whitespace tokens, sort them, rejoin with a
# single space (order-insensitive token-set match — catches "Nemotron 3 Ultra" reordering).
sorted_tokens() {
  normalize "$1" | tr ' ' '\n' | sort | tr '\n' ' ' | sed -E 's/ +$//'
}

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  echo "usage: resolve-model-alias.sh <model-name>" >&2
  exit 2
fi

if [[ ! -f "$ALIASES_FILE" ]]; then
  echo "resolve-model-alias.sh: alias table not found: $ALIASES_FILE" >&2
  exit 2
fi

query="$1"
q_norm="$(normalize "$query")"
q_squash="$(squash "$query")"
q_tokens="$(sorted_tokens "$query")"

aliases=()
canonicals=()

while IFS= read -r line || [[ -n "$line" ]]; do
  case "$line" in
    ''|'#'*) continue ;;
  esac
  alias_part="${line%%:*}"
  rest="${line#*:}"
  alias_part="$(printf '%s' "$alias_part" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  rest="$(printf '%s' "$rest" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  [[ -z "$alias_part" || -z "$rest" ]] && continue
  aliases+=("$alias_part")
  canonicals+=("$rest")
done < "$ALIASES_FILE"

n=${#aliases[@]}

# Tier 1: exact normalized match.
i=0
while [[ $i -lt $n ]]; do
  if [[ "$(normalize "${aliases[$i]}")" == "$q_norm" ]]; then
    printf '%s\n' "${canonicals[$i]}"
    exit 0
  fi
  i=$((i + 1))
done

# Tier 2: squashed exact match.
i=0
while [[ $i -lt $n ]]; do
  if [[ "$(squash "${aliases[$i]}")" == "$q_squash" ]]; then
    printf '%s\n' "${canonicals[$i]}"
    exit 0
  fi
  i=$((i + 1))
done

# Tier 3: order-independent sorted-token match.
i=0
while [[ $i -lt $n ]]; do
  if [[ "$(sorted_tokens "${aliases[$i]}")" == "$q_tokens" ]]; then
    printf '%s\n' "${canonicals[$i]}"
    exit 0
  fi
  i=$((i + 1))
done

# Tier 4: last-resort squashed substring fallback (either direction contains the other).
i=0
while [[ $i -lt $n ]]; do
  k_squash="$(squash "${aliases[$i]}")"
  if [[ "$k_squash" == *"$q_squash"* || "$q_squash" == *"$k_squash"* ]]; then
    printf '%s\n' "${canonicals[$i]}"
    exit 0
  fi
  i=$((i + 1))
done

exit 1
