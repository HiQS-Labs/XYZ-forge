#!/usr/bin/env bash
# utils/hq/rollup.sh — Roll up cross-repo ROADMAP activity + marathon preflight readiness
# (GH-158's marathon-scan.sh) into one daily Obsidian summary (GH-192).

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils/hq/hq-lib.sh
. "$HERE/hq-lib.sh"

AGY_BIN="${AGY_BIN:-agy}"                                    # test seam — same convention as relay-automation/consult.sh
MARATHON_SCAN_BIN="${MARATHON_SCAN_BIN:-$HERE/marathon-scan.sh}"   # test seam for the failure path
MARATHON_LIVE_BIN="${MARATHON_LIVE_BIN:-$HERE/marathon-live.sh}"   # GH-218 test seam (cross-repo live status)

# node is required unconditionally: both the ROADMAP-scan loop below and marathon-scan.sh itself
# need it regardless of ROADMAP content. agy is NOT checked here — it's only needed when the
# ROADMAP scrape actually has something to synthesize (checked lazily below), so a machine without
# agy installed at all still gets the marathon-readiness section written.
command -v node >/dev/null 2>&1 || { echo "hq rollup: node is required" >&2; exit 2; }

mkdir -p "$HQ_OBSIDIAN_VAULT"
OUT_FILE="$HQ_OBSIDIAN_VAULT/HQ-Daily-Rollup.md"
RAW_FILE="${TMPDIR:-/tmp}/hq-raw-rollup.txt"
> "$RAW_FILE"

echo "HQ Rollup: scanning repos for ROADMAP activity..."

# hq_known_repos outputs one per line
while IFS= read -r repo; do
  [ -z "$repo" ] && continue
  
  fields="$(hq_repo_resolve "$repo")"
  path="$(printf '%s\n' "$fields" | sed -n 's/^REPO_PATH=//p' | head -1)"
  
  if [ -n "$path" ] && [ -f "$path/ROADMAP.md" ]; then
    echo "  scanning $repo ($path)..."
    
    node - "$path/ROADMAP.md" "$repo" >> "$RAW_FILE" <<'NODE'
const fs = require("fs");
const sourcePath = process.argv[2];
const repoName = process.argv[3];
const raw = fs.readFileSync(sourcePath, "utf8");
const lines = raw.split(/\r?\n/);

const sections = new Map();
let currentSection = null;

for (let i = 0; i < lines.length; i++) {
  const line = lines[i];

  const sectionMatch = line.match(/^###\s+(.+?)\s*$/);
  if (sectionMatch) {
    const heading = sectionMatch[1].trim().toLowerCase();
    if (heading.includes("queue") || heading.includes("parked") || heading.includes("in progress") || heading.includes("next-up")) {
      currentSection = sectionMatch[1].trim();
      if (!sections.has(currentSection)) sections.set(currentSection, []);
    } else {
      currentSection = null;
    }
    continue;
  }

  if (!currentSection) continue;
  
  // Bullets usually start with `- **` or `<number>. **`
  if (!/^(-\s+|\d+\.\s+)\*\*/.test(line)) continue;

  const block = [line];
  while (i + 1 < lines.length) {
    const next = lines[i + 1];
    if (/^###\s+/.test(next) || /^##\s+/.test(next) || /^(-\s+|\d+\.\s+)\*\*/.test(next)) break;
    block.push(next);
    i += 1;
  }
  sections.get(currentSection).push(block.join(" ").replace(/\s+/g, " "));
}

let hasData = false;
let out = `\n=== REPO: ${repoName} ===\n`;
for (const [heading, items] of sections.entries()) {
  if (items && items.length > 0) {
    hasData = true;
    out += `\nSection: ${heading}\n`;
    items.forEach(item => out += `${item}\n`);
  }
}

if (hasData) {
  process.stdout.write(out);
}
NODE

  fi
done < <(hq_known_repos)

if [ -s "$RAW_FILE" ]; then
  command -v "$AGY_BIN" >/dev/null 2>&1 || { echo "hq rollup: agy (Antigravity CLI) is required to synthesize the ROADMAP scrape" >&2; exit 2; }
  echo "HQ Rollup: Synthesizing with agy..."

  PROMPT="Synthesize the following cross-repo parked and marathon items into a clean daily summary for an Obsidian dashboard.
Format it beautifully using GitHub flavored markdown.
Group the information into logical sections such as 'Active / Next Up' and 'Parked / Queued'.
Mention which repo each item belongs to.
Do not hallucinate any information.
Keep it concise but detailed enough so I remember context without context switching.

RAW DATA:
$(cat "$RAW_FILE")
"

  roadmap_section="$("$AGY_BIN" -p "$PROMPT" --dangerously-skip-permissions < /dev/null)"
else
  echo "HQ Rollup: No parked or active items found in any ROADMAP.md."
  roadmap_section="_No parked or active items found in any ROADMAP.md._"
fi

# GH-192: fold in GH-158's cross-repo marathon-preflight aggregator. Appended verbatim, never
# passed through agy — the ready/blocked/stale/ambiguous verdicts are the one deterministic,
# structured signal in this pipeline, and an LLM synthesis pass risks paraphrasing one wrong.
# Strip a report's own leading YAML frontmatter (redundant once embedded under a heading here), and
# demote every heading by 2 levels (# -> ###, ## -> ####) so the report's own H1 title nests properly
# under this section's H2. Shared by the marathon-scan (GH-192) and marathon-live (GH-218) embeds.
demote_embed() {
  awk '
    NR==1 && $0=="---" { infm=1; next }
    infm && $0=="---" { infm=0; next }
    infm { next }
    /^```/ { infence = !infence; print; next }
    !infence && match($0, /^#+ /) { print "##" $0; next }
    { print }
  ' "$1"
}

echo "HQ Rollup: running marathon-scan.sh for preflight readiness..."
MARATHON_TMP="$(mktemp "${TMPDIR:-/tmp}/hq-rollup-marathon.XXXXXX")"
MARATHON_LIVE_TMP="$(mktemp "${TMPDIR:-/tmp}/hq-rollup-marathon-live.XXXXXX")"
trap 'rm -f "$MARATHON_TMP" "$MARATHON_LIVE_TMP"' EXIT
marathon_rc=0
marathon_log="$(bash "$MARATHON_SCAN_BIN" --out "$MARATHON_TMP" 2>&1)" || marathon_rc=$?

if [ "$marathon_rc" -eq 0 ] && [ -s "$MARATHON_TMP" ]; then
  marathon_section="$(demote_embed "$MARATHON_TMP")"
else
  marathon_section="_marathon scan failed (exit ${marathon_rc}): ${marathon_log}_"
fi

# GH-218: fold in the cross-repo LIVE marathon status the same way — a second call into the existing
# embed mechanism, not a new Obsidian-writing path. Same verbatim rationale: the live/claimed/idle
# verdicts are deterministic and must not be paraphrased by the synthesis pass.
echo "HQ Rollup: running marathon-live.sh for live cross-repo status..."
marathon_live_rc=0
marathon_live_log="$(bash "$MARATHON_LIVE_BIN" --out "$MARATHON_LIVE_TMP" 2>&1)" || marathon_live_rc=$?

if [ "$marathon_live_rc" -eq 0 ] && [ -s "$MARATHON_LIVE_TMP" ]; then
  marathon_live_section="$(demote_embed "$MARATHON_LIVE_TMP")"
else
  marathon_live_section="_marathon live-status failed (exit ${marathon_live_rc}): ${marathon_live_log}_"
fi

{
  printf '%s\n' "$roadmap_section"
  printf '\n---\n\n## Marathon Readiness (cross-repo preflight)\n\n'
  printf '%s\n' "$marathon_section"
  printf '\n---\n\n## Live Marathons (cross-repo, right now)\n\n'
  printf '%s\n' "$marathon_live_section"
} > "$OUT_FILE"

echo "HQ Rollup: ✓ wrote $OUT_FILE"
