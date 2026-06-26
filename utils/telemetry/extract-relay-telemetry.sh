#!/usr/bin/env bash
set -euo pipefail
# extract-relay-telemetry.sh — one-shot ETL from relay-system/<date>/*.md to focus5float health feed JSON.
#
# For each relay thread in the given date range, derives health (green/orange/red) from the
# STATUS: header and last VERDICT: in the ## Log section, then emits one record per file.
# Schema matches relay-system/focus5float-demo.json: [{ health, title, description, updatedAt }]
#
# Health mapping:
#   green  — STATUS: Approved or Closed
#   orange — STATUS: Escalated | Changes requested | In Progress (with at least one VERDICT)
#   red    — no VERDICT in log, empty log section, or VERDICT: FAIL under non-terminal STATUS

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RELAY_SYSTEM="$ROOT_DIR/relay-system"

FROM_DATE="$(date -v-7d '+%Y-%m-%d' 2>/dev/null || date -d '7 days ago' '+%Y-%m-%d')"
TO_DATE="$(date '+%Y-%m-%d')"
OUT_PATH=""

usage() {
  cat <<'EOF'
Usage: utils/telemetry/extract-relay-telemetry.sh [options]

  --from YYYY-MM-DD   Start of date range (inclusive). Default: 7 days ago.
  --to YYYY-MM-DD     End of date range (inclusive). Default: today.
  --out PATH          Output file path.
                      Default: relay-system/combined/aggregated-FROM-to-TO.json
  --help
EOF
}

die() { printf 'extract-relay-telemetry: %s\n' "$*" >&2; exit 1; }

while (($# > 0)); do
  case "$1" in
    --from) FROM_DATE="${2:-}"; shift 2 ;;
    --to)   TO_DATE="${2:-}";   shift 2 ;;
    --out)  OUT_PATH="${2:-}";  shift 2 ;;
    --help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ "$FROM_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || die "--from must be YYYY-MM-DD, got: $FROM_DATE"
[[ "$TO_DATE"   =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || die "--to must be YYYY-MM-DD, got: $TO_DATE"
[[ ! "$FROM_DATE" > "$TO_DATE" ]] || die "--from ($FROM_DATE) must be <= --to ($TO_DATE)"

[[ -z "$OUT_PATH" ]] && OUT_PATH="$RELAY_SYSTEM/combined/aggregated-${FROM_DATE}-to-${TO_DATE}.json"

mkdir -p "$(dirname "$OUT_PATH")"

tmp_tsv="$(mktemp -t relay-telemetry.XXXXXX)"
trap 'rm -f "$tmp_tsv"' EXIT

count=0

for date_dir in "$RELAY_SYSTEM"/*/; do
  date_name="$(basename "$date_dir")"
  [[ "$date_name" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || continue
  [[ ! "$date_name" < "$FROM_DATE" && ! "$date_name" > "$TO_DATE" ]] || continue

  for relay_file in "$date_dir"*.md; do
    [[ -f "$relay_file" ]] || continue

    # Title: first heading line (strip "# " prefix)
    title="$(grep -m1 '^# ' "$relay_file" | sed 's/^#[[:space:]]*//' | sed 's/[[:space:]]*$//')" || true
    [[ -z "$title" ]] && title="$(basename "$relay_file" .md)"

    # STATUS from header block (lines before first "## " section heading)
    status="$(sed -n '/^##[[:space:]]/q; s/^STATUS:[[:space:]]*//p' "$relay_file" | head -1 | sed 's/[[:space:]]*$//')"

    # ROUND from header block
    round_field="$(sed -n '/^##[[:space:]]/q; s/^ROUND:[[:space:]]*//p' "$relay_file" | head -1 | sed 's/[[:space:]]*$//')"

    # Last VERDICT in the ## Log section (grep exits 1 when no match — || true prevents pipefail)
    verdict="$(sed -n '/^## Log/,$p' "$relay_file" | grep '^VERDICT: ' | tail -1 | sed 's/^VERDICT: //' | sed 's/[[:space:]]*$//')" || true

    # Whether the ## Log section has any non-blank content beyond the header line
    if sed -n '/^## Log/,$p' "$relay_file" | tail -n +2 | grep -q '[^[:space:]]' 2>/dev/null; then
      log_content=1
    else
      log_content=0
    fi

    # updatedAt: file mtime as UTC ISO-8601 (macOS: stat -f %m + date -r; Linux: stat -c %Y + date -d @)
    mtime_epoch="$(stat -f %m "$relay_file" 2>/dev/null || stat -c %Y "$relay_file" 2>/dev/null || echo 0)"
    updated_at="$(date -r "$mtime_epoch" -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
      || date -d "@$mtime_epoch" -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
      || echo "${date_name}T00:00:00Z")"

    # --- health mapping ---
    case "$status" in
      Approved|Closed)
        health="green"
        ;;
      Escalated|"Changes requested")
        health="orange"
        ;;
      "In Progress"|"")
        if [[ "$log_content" -eq 0 || -z "$verdict" ]]; then
          health="red"
        else
          health="orange"
        fi
        ;;
      *)
        health="orange"
        ;;
    esac
    # VERDICT: FAIL under a non-terminal STATUS overrides to red
    if [[ "$health" != "green" && "$verdict" == "FAIL" ]]; then
      health="red"
    fi

    # --- description ---
    rounds_str=""
    [[ -n "$round_field" ]] && rounds_str=" (round ${round_field})"
    case "$health" in
      green)
        desc="Relay completed: STATUS ${status}${verdict:+, VERDICT: $verdict}${rounds_str}."
        ;;
      orange)
        desc="Relay in progress or stalled: STATUS ${status:-unknown}${verdict:+, last VERDICT: $verdict}${rounds_str}."
        ;;
      red)
        if [[ -z "$verdict" ]]; then
          desc="Relay has no VERDICT in log: STATUS ${status:-unknown}${rounds_str}. Possibly abandoned."
        else
          desc="Relay failed: STATUS ${status:-unknown}, VERDICT: ${verdict}${rounds_str}."
        fi
        ;;
    esac

    printf '%s\t%s\t%s\t%s\n' "$health" "$title" "$desc" "$updated_at" >> "$tmp_tsv"
    count=$((count + 1))
  done
done

if [[ "$count" -eq 0 ]]; then
  printf '[]\n' > "$OUT_PATH"
  printf 'extract-relay-telemetry: 0 relay files found for %s..%s — wrote empty array to %s\n' \
    "$FROM_DATE" "$TO_DATE" "$OUT_PATH" >&2
  exit 0
fi

python3 - "$tmp_tsv" "$OUT_PATH" <<'PYEOF'
import sys, json

tsv_path, out_path = sys.argv[1], sys.argv[2]
records = []
with open(tsv_path) as f:
    for line in f:
        line = line.rstrip('\n')
        if not line:
            continue
        parts = line.split('\t', 3)
        if len(parts) < 4:
            continue
        health, title, description, updated_at = parts
        records.append({
            "health": health,
            "title": title,
            "description": description,
            "updatedAt": updated_at,
        })

with open(out_path, 'w') as f:
    json.dump(records, f, indent='\t')
    f.write('\n')
PYEOF

printf 'extract-relay-telemetry: %d records → %s\n' "$count" "$OUT_PATH" >&2
