#!/usr/bin/env bash
# utils/hq/rollup.sh — Roll up cross-repo ROADMAP activity into a daily Obsidian summary.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=utils/hq/hq-lib.sh
. "$HERE/hq-lib.sh"

command -v node >/dev/null 2>&1 || { echo "hq rollup: node is required" >&2; exit 2; }
command -v agy >/dev/null 2>&1 || { echo "hq rollup: agy (Antigravity CLI) is required" >&2; exit 2; }

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

if [ ! -s "$RAW_FILE" ]; then
  echo "HQ Rollup: No parked or active items found in any ROADMAP.md."
  exit 0
fi

echo "HQ Rollup: Synthesizing with agy into $OUT_FILE..."

PROMPT="Synthesize the following cross-repo parked and marathon items into a clean daily summary for an Obsidian dashboard.
Format it beautifully using GitHub flavored markdown. 
Group the information into logical sections such as 'Active / Next Up' and 'Parked / Queued'.
Mention which repo each item belongs to.
Do not hallucinate any information.
Keep it concise but detailed enough so I remember context without context switching.

RAW DATA:
$(cat "$RAW_FILE")
"

agy -p "$PROMPT" --dangerously-skip-permissions < /dev/null > "$OUT_FILE"

echo "HQ Rollup: ✓ wrote $OUT_FILE"
