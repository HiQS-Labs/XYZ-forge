#!/usr/bin/env bash
# utils/hq/marathon-scan.sh — read-only cross-repo marathon aggregation + preflight (GH-158).
#
# Enumerates PDDA-known repos via hq-lib.sh, finds marathon docs under PROJECT/2-WORKING/, parses
# each doc's frontmatter status + active wave lanes, and runs EACH TARGET REPO'S OWN
# utils/swarm-preflight.sh in --dry-run mode per active lane. Output is one aggregated
# HQ-MARATHON-<date>.md written in the hub repo (or a caller-specified path). Target repos are
# never written; the only write is the aggregate doc itself.
#
# Usage:
#   utils/hq/marathon-scan.sh
#   utils/hq/marathon-scan.sh --out PROJECT/2-WORKING/HQ-MARATHON-2026-07-06.md
#
# Test seams:
#   HQ_MARATHON_SCAN_TODAY   pin the report date (YYYY-MM-DD)
#   HQ_MARATHON_SCAN_NOW     pin the generated-at timestamp

set -uo pipefail
# strict-mode: -e exempt — analysis tool with expected-nonzero probes (repo resolution/preflight); errors handled explicitly. See GUIDING-PRINCIPLES.md#strict-mode-policy.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
# shellcheck source=utils/hq/hq-lib.sh
. "$HERE/hq-lib.sh"

TODAY="${HQ_MARATHON_SCAN_TODAY:-"$(date -u +%Y-%m-%d)"}"
NOW="${HQ_MARATHON_SCAN_NOW:-"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}"
OUT=""

usage() {
  cat <<'EOF'
Usage: utils/hq/marathon-scan.sh [--out FILE]

Enumerate PDDA-known repos, scan their PROJECT/2-WORKING/*marathon*.md docs, preflight every
active-wave lane with that repo's own utils/swarm-preflight.sh --dry-run, and write one aggregate
HQ-MARATHON-<date>.md report in the hub repo.
EOF
}

while (($# > 0)); do
  case "$1" in
    --out) OUT="${2:-}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; echo "hq marathon-scan: unknown argument: $1" >&2; exit 2 ;;
  esac
done

command -v node >/dev/null 2>&1 || { echo "hq marathon-scan: node is required" >&2; exit 2; }

OUT="${OUT:-$ROOT/PROJECT/2-WORKING/HQ-MARATHON-$TODAY.md}"
[[ "$OUT" = /* ]] || OUT="$ROOT/$OUT"
mkdir -p "$(dirname "$OUT")"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/hq-marathon-scan.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

HELPER="$TMP/helper.mjs"
cat >"$HELPER" <<'NODE'
import fs from "node:fs";
import path from "node:path";

const cmd = process.argv[2];
const arg1 = process.argv[3];
const arg2 = process.argv[4];

const norm = (s) => String(s || "").toLowerCase().replace(/[^a-z0-9]+/g, "");
const stripMd = (v) => String(v || "")
  .replace(/`([^`]+)`/g, "$1")
  .replace(/\*\*([^*]+)\*\*/g, "$1")
  .replace(/\*([^*]+)\*/g, "$1")
  .replace(/\[([^\]]+)\]\(([^)]+)\)/g, "$1")
  .trim();

function readFileSafe(p) {
  try { return fs.readFileSync(p, "utf8"); }
  catch { return null; }
}

function frontmatter(raw) {
  const lines = raw.replace(/^\ufeff/, "").split(/\r?\n/);
  let i = 0;
  while (i < lines.length && lines[i].trim() === "") i += 1;
  if (!/^---\s*$/.test(lines[i] || "")) return {};
  const fm = {};
  for (i += 1; i < lines.length; i += 1) {
    if (/^---\s*$/.test(lines[i])) break;
    const m = lines[i].match(/^([A-Za-z0-9_]+):\s*(.*)$/);
    if (m) fm[m[1]] = m[2].trim();
  }
  return fm;
}

function markdownTitle(raw) {
  const m = raw.match(/^#\s+(.+)$/m);
  return m ? stripMd(m[1]) : "";
}

function parseLedger(raw) {
  const lines = raw.split(/\r?\n/);
  const items = [];
  let inLedger = false;
  let section = null;
  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    if (!inLedger) {
      if (/^##\s+Ledger\s*$/.test(line.trim())) inLedger = true;
      continue;
    }
    if (/^##\s+/.test(line) && !/^##\s+Ledger\s*$/.test(line.trim())) break;
    const sm = line.match(/^###\s+(.+?)\s*$/);
    if (sm) { section = sm[1].trim(); continue; }
    if (!section || !/^- \*\*/.test(line)) continue;
    const block = [line];
    while (i + 1 < lines.length) {
      const next = lines[i + 1];
      if (/^###\s+/.test(next) || /^##\s+/.test(next) || /^- \*\*/.test(next)) break;
      block.push(next);
      i += 1;
    }
    const text = block.map((l) => l.trim()).join(" ").replace(/\s+/g, " ").trim();
    const links = [];
    let lm;
    const re = /\[([^\]]+)\]\(([^)]+)\)/g;
    while ((lm = re.exec(text)) !== null) links.push({ label: lm[1], target: lm[2] });
    items.push({
      section,
      title: stripMd((text.match(/^- \*\*(.+?)\*\*/) || [null, text.replace(/^- /, "")])[1]),
      raw: text,
      links,
    });
  }
  return items;
}

function ghIssueOf(item) {
  const t = item.title.match(/\bGH-(\d+)\b/);
  if (t) return Number(t[1]);
  for (const link of item.links) {
    const m = String(link.target).match(/issues\/(\d+)/);
    if (m) return Number(m[1]);
  }
  return null;
}

function docOf(item, gh = null) {
  const mds = item.links
    .map((l) => l.target)
    .filter((t) => /\.md($|#)/.test(t) && /PROJECT\//.test(t) && !/relay-system\//.test(t));
  if (mds.length === 0) return null;
  const issue = gh ?? ghIssueOf(item);
  const ownDoc = issue == null ? null : new RegExp(`(^|/)GH-${issue}-[^/]+\\.md($|#)`, "i");
  const pick =
    mds.find((t) => ownDoc && /2-WORKING\//.test(t) && ownDoc.test(t)) ||
    mds.find((t) => ownDoc && ownDoc.test(t)) ||
    mds.find((t) => /2-WORKING\//.test(t)) ||
    mds[0];
  return pick.replace(/#.*$/, "");
}

function parseMarathon(docPath) {
  const raw = readFileSafe(docPath);
  if (raw == null) throw new Error(`cannot read ${docPath}`);
  const fm = frontmatter(raw);
  const lines = raw.split(/\r?\n/);
  const waves = [];
  for (const line of lines) {
    const m = line.match(/^\*\*Wave [^*]*:\*\*\s*(.+?)\s*$/);
    if (!m) continue;
    const tokens = m[1]
      .split("‖")
      .map((part) => stripMd(part).replace(/^[*-]\s*/, "").trim())
      .filter((part) => part && part !== "(none)");
    if (tokens.length) waves.push(tokens);
  }
  process.stdout.write(JSON.stringify({
    path: docPath,
    title: String(fm.title || markdownTitle(raw) || path.basename(docPath)),
    status: String(fm.status || ""),
    waves,
  }));
}

function resolveLane(repoRoot, token) {
  const trimmed = String(token || "").trim();
  const hashIssue = trimmed.match(/^#(\d+)$/);
  if (hashIssue) {
    process.stdout.write(JSON.stringify({ kind: "gh-issue", issue: Number(hashIssue[1]), display: `#${hashIssue[1]}` }));
    return;
  }
  const ghIssue = trimmed.match(/^GH-(\d+)$/i);
  if (ghIssue) {
    process.stdout.write(JSON.stringify({ kind: "gh-issue", issue: Number(ghIssue[1]), display: `#${ghIssue[1]}` }));
    return;
  }

  const tokenNorm = norm(trimmed);
  const projectRoot = path.join(repoRoot, "PROJECT");
  const docs = [];
  (function walk(dir) {
    let ents = [];
    try { ents = fs.readdirSync(dir, { withFileTypes: true }); }
    catch { return; }
    for (const ent of ents) {
      const abs = path.join(dir, ent.name);
      if (ent.isDirectory()) walk(abs);
      else if (ent.isFile() && ent.name.endsWith(".md")) docs.push(abs);
    }
  })(projectRoot);

  const relDocs = docs.map((abs) => {
    const raw = readFileSafe(abs) || "";
    const rel = path.relative(repoRoot, abs).replace(/\\/g, "/");
    const base = path.basename(abs, ".md");
    return {
      abs,
      rel,
      baseNorm: norm(base),
      titleNorm: norm(String(frontmatter(raw).title || markdownTitle(raw) || base)),
      inWorking: /\/2-WORKING\//.test(`/${rel}`),
    };
  });

  const candidates = [];
  const addCandidate = (rel, score, source) => {
    const meta = relDocs.find((d) => d.rel === rel);
    candidates.push({
      rel,
      exists: !!meta,
      inWorking: meta ? meta.inWorking : /\/2-WORKING\//.test(`/${rel}`),
      score,
      source,
    });
  };

  const roadmap = readFileSafe(path.join(repoRoot, "ROADMAP.md"));
  if (roadmap != null) {
    for (const item of parseLedger(roadmap)) {
      const titleNorm = norm(item.title);
      if (!titleNorm) continue;
      const matches =
        titleNorm === tokenNorm ||
        titleNorm.includes(tokenNorm) ||
        tokenNorm.includes(titleNorm) ||
        norm(item.raw).includes(tokenNorm);
      if (!matches) continue;
      const rel = docOf(item);
      if (rel) addCandidate(rel, titleNorm === tokenNorm ? 0 : 1, "roadmap");
    }
  }

  for (const meta of relDocs) {
    if (meta.baseNorm === tokenNorm) addCandidate(meta.rel, 0, "basename");
    else if (meta.titleNorm === tokenNorm) addCandidate(meta.rel, 1, "title");
    else if (meta.baseNorm.includes(tokenNorm) || tokenNorm.includes(meta.baseNorm)) addCandidate(meta.rel, 2, "basename-fuzzy");
    else if (meta.titleNorm.includes(tokenNorm) || tokenNorm.includes(meta.titleNorm)) addCandidate(meta.rel, 3, "title-fuzzy");
  }

  if (candidates.length === 0) {
    process.stdout.write(JSON.stringify({ kind: "unresolved", token: trimmed }));
    return;
  }

  const dedup = new Map();
  for (const cand of candidates) {
    const key = cand.rel;
    const prev = dedup.get(key);
    if (!prev || cand.score < prev.score || (cand.score === prev.score && cand.exists && !prev.exists)) {
      dedup.set(key, cand);
    }
  }

  const ordered = [...dedup.values()].sort((a, b) =>
    (a.exists ? 0 : 1) - (b.exists ? 0 : 1) ||
    a.score - b.score ||
    (a.inWorking ? 0 : 1) - (b.inWorking ? 0 : 1) ||
    a.rel.localeCompare(b.rel)
  );
  const best = ordered[0];
  const tied = ordered.filter((c) =>
    (c.exists ? 0 : 1) === (best.exists ? 0 : 1) &&
    c.score === best.score &&
    (c.inWorking ? 0 : 1) === (best.inWorking ? 0 : 1)
  );
  if (tied.length > 1) {
    process.stdout.write(JSON.stringify({
      kind: "ambiguous",
      token: trimmed,
      candidates: tied.map((c) => c.rel),
    }));
    return;
  }

  process.stdout.write(JSON.stringify({
    kind: "project-doc",
    project_doc: best.rel,
    display: best.rel,
  }));
}

if (cmd === "parse-marathon") parseMarathon(arg1);
else if (cmd === "resolve-lane") resolveLane(arg1, arg2);
else throw new Error(`unknown helper command: ${cmd}`);
NODE

STATUS_TSV="$TMP/status.tsv"
LANE_TSV="$TMP/lanes.tsv"
: >"$STATUS_TSV"
: >"$LANE_TSV"

tsv_escape() {
  printf '%s' "$1" | tr '\t\r\n' '   '
}

parse_marathon_doc() {
  node "$HELPER" parse-marathon "$1"
}

resolve_lane() {
  node "$HELPER" resolve-lane "$1" "$2"
}

classify_blocked() {
  local repo="$1" kind="$2" issue="$3" project_doc="$4"
  if [[ "$kind" == "gh-issue" && "$issue" =~ ^[0-9]+$ ]]; then
    local inbox working
    inbox="$(find "$repo/PROJECT/1-INBOX" -maxdepth 1 -type f -name "GH-$issue-*.md" 2>/dev/null | head -1 || true)"
    working="$(find "$repo/PROJECT/2-WORKING" -maxdepth 1 -type f -name "GH-$issue-*.md" 2>/dev/null | head -1 || true)"
    [[ -n "$inbox" && -z "$working" ]] && { printf 'blocked-not-promoted'; return; }
  fi
  if [[ "$kind" == "project-doc" && "$project_doc" == PROJECT/1-INBOX/* ]]; then
    printf 'blocked-not-promoted'
    return
  fi
  printf 'blocked-other'
}

fireable_ready=0
blocked_not_promoted=0
blocked_other=0
stale_already_landed=0
ambiguous_count=0
held_docs=0
active_lanes=0

while IFS= read -r repo; do
  [[ -n "$repo" ]] || continue
  fields="$(hq_repo_resolve "$repo")"
  repo_path="$(printf '%s\n' "$fields" | sed -n 's/^REPO_PATH=//p' | head -1)"
  [[ -n "$repo_path" && -d "$repo_path/PROJECT/2-WORKING" ]] || continue

  while IFS= read -r doc; do
    [[ -n "$doc" ]] || continue
    meta="$(parse_marathon_doc "$doc")" || continue
    doc_rel="${doc#$repo_path/}"
    title="$(printf '%s' "$meta" | node -e 'const o=JSON.parse(require("fs").readFileSync(0,"utf8"));process.stdout.write(o.title||"")')"
    status="$(printf '%s' "$meta" | node -e 'const o=JSON.parse(require("fs").readFileSync(0,"utf8"));process.stdout.write(o.status||"")')"
    waves_flat="$(printf '%s' "$meta" | node -e 'const o=JSON.parse(require("fs").readFileSync(0,"utf8"));for (const wave of (o.waves||[])) { for (const lane of wave) console.log(lane); }')"
    status_kind="other"
    case "$(printf '%s' "$status" | tr '[:upper:]' '[:lower:]')" in
      active*) status_kind="active" ;;
      held*) status_kind="held" ;;
      completed*|shipped*) status_kind="closed" ;;
    esac
    in_scope="closed"
    [[ "$status_kind" == "active" ]] && in_scope="active"
    [[ "$status_kind" == "held" ]] && { in_scope="held"; held_docs=$((held_docs + 1)); }
    printf '%s\t%s\t%s\t%s\t%s\n' \
      "$(tsv_escape "$repo")" \
      "$(tsv_escape "$doc_rel")" \
      "$(tsv_escape "$title")" \
      "$(tsv_escape "$status")" \
      "$in_scope" >>"$STATUS_TSV"

    [[ "$status_kind" == "active" ]] || continue
    while IFS= read -r lane; do
      [[ -n "$lane" ]] || continue
      active_lanes=$((active_lanes + 1))
      resolution="$(resolve_lane "$repo_path" "$lane")"
      kind="$(printf '%s' "$resolution" | node -e 'const o=JSON.parse(require("fs").readFileSync(0,"utf8"));process.stdout.write(o.kind||"")')"
      issue="$(printf '%s' "$resolution" | node -e 'const o=JSON.parse(require("fs").readFileSync(0,"utf8"));process.stdout.write(o.issue==null?"":String(o.issue))')"
      project_doc="$(printf '%s' "$resolution" | node -e 'const o=JSON.parse(require("fs").readFileSync(0,"utf8"));process.stdout.write(o.project_doc||"")')"
      resolution_display="$kind"
      preflight_exit=""
      classification=""
      if [[ "$kind" == "gh-issue" ]]; then
        resolution_display="gh-issue #$issue"
      elif [[ "$kind" == "project-doc" ]]; then
        resolution_display="$project_doc"
      elif [[ "$kind" == "ambiguous" ]]; then
        resolution_display="$(printf '%s' "$resolution" | node -e 'const o=JSON.parse(require("fs").readFileSync(0,"utf8"));process.stdout.write((o.candidates||[]).join(", "))')"
      fi

      if [[ "$kind" == "ambiguous" || "$kind" == "unresolved" ]]; then
        classification="ambiguous"
        preflight_exit="7"
        ambiguous_count=$((ambiguous_count + 1))
      elif [[ ! -x "$repo_path/utils/swarm-preflight.sh" && ! -f "$repo_path/utils/swarm-preflight.sh" ]]; then
        classification="blocked-other"
        preflight_exit="6"
        blocked_other=$((blocked_other + 1))
      else
        cmd=(bash "$repo_path/utils/swarm-preflight.sh" --target-root "$repo_path" --dry-run --format json)
        if [[ "$kind" == "gh-issue" ]]; then
          cmd+=(--gh-issue "$issue")
        else
          cmd+=(--project-doc "$project_doc")
        fi
        if "${cmd[@]}" >/dev/null 2>"$TMP/preflight.err"; then
          preflight_exit="0"
        else
          preflight_exit="$?"
        fi
        case "$preflight_exit" in
          0) classification="ready"; fireable_ready=$((fireable_ready + 1)) ;;
          4) classification="stale-already-landed"; stale_already_landed=$((stale_already_landed + 1)) ;;
          7) classification="ambiguous"; ambiguous_count=$((ambiguous_count + 1)) ;;
          *)
            classification="$(classify_blocked "$repo_path" "$kind" "$issue" "$project_doc")"
            if [[ "$classification" == "blocked-not-promoted" ]]; then
              blocked_not_promoted=$((blocked_not_promoted + 1))
            else
              blocked_other=$((blocked_other + 1))
            fi
            ;;
        esac
      fi
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$(tsv_escape "$repo")" \
        "$(tsv_escape "$doc_rel")" \
        "$(tsv_escape "$lane")" \
        "$(tsv_escape "$resolution_display")" \
        "$preflight_exit" \
        "$classification" \
        "$kind" >>"$LANE_TSV"
    done <<<"$waves_flat"
  done < <(find "$repo_path/PROJECT/2-WORKING" -maxdepth 1 -type f \( -iname '*marathon*.md' \) ! -name 'GH-*' ! -name 'HQ-MARATHON-*' | sort)
done < <(hq_known_repos)

repos_total="$(cut -f1 "$STATUS_TSV" 2>/dev/null | sort -u | sed '/^$/d' | wc -l | tr -d ' ')"
docs_total="$(wc -l <"$STATUS_TSV" | tr -d ' ')"

{
  cat <<EOF
---
title: HQ MARATHON — $TODAY (cross-repo rollup, orchestrated from xyz-3-agents-swarm)
status: Active
created: $TODAY
updated: $TODAY
owner: noel@neochro.me
scope: >
  Repos with marathon docs under PROJECT/2-WORKING/, enumerated from the HQ PDDA registry and
  resolved via hq-lib.sh. Active docs are preflighted lane-by-lane with each repo's own
  utils/swarm-preflight.sh --dry-run; Held docs are surfaced but never counted as fireable.
roadmap_exempt: true
generated_by: utils/hq/marathon-scan.sh
---

# HQ MARATHON — $TODAY

## Source registry

\`hq_known_repos\` + \`hq_repo_resolve\` from \`utils/hq/hq-lib.sh\`.

| Repo | Marathon file | Status | In scope? |
|---|---|---|---|
EOF

  while IFS=$'\t' read -r repo doc_rel title status in_scope; do
    scope_label="❌ closed"
    [[ "$in_scope" == "active" ]] && scope_label="✅ active"
    [[ "$in_scope" == "held" ]] && scope_label="🟡 held, not counted"
    printf '| %s | `%s` | %s | %s |\n' "$repo" "$doc_rel" "$status" "$scope_label"
  done <"$STATUS_TSV"

  current_repo=""
  while IFS=$'\t' read -r repo doc_rel lane resolution_display preflight_exit classification kind; do
    if [[ "$repo" != "$current_repo" ]]; then
      [[ -n "$current_repo" ]] && printf '\n'
      printf '## %s\n\n' "$repo"
      printf '| Lane | Source marathon | Resolution | Verdict |\n'
      printf '|---|---|---|---|\n'
      current_repo="$repo"
    fi
    verdict="$classification"
    case "$classification" in
      ready) verdict="✅ ready (exit 0)" ;;
      blocked-not-promoted) verdict="⚠️ blocked-not-promoted (exit $preflight_exit)" ;;
      blocked-other) verdict="⛔ blocked-other (exit $preflight_exit)" ;;
      stale-already-landed) verdict="⚠️ stale-already-landed (exit 4)" ;;
      ambiguous) verdict="❓ ambiguous (exit $preflight_exit)" ;;
    esac
    printf '| %s | `%s` | `%s` | %s |\n' "$lane" "$doc_rel" "$resolution_display" "$verdict"
  done <"$LANE_TSV"

  cat <<EOF

## Net result

- Repos scanned: $repos_total
- Marathon docs found: $docs_total
- Active lanes scanned: $active_lanes
- Ready: $fireable_ready
- Blocked-not-promoted: $blocked_not_promoted
- Blocked-other: $blocked_other
- Stale-already-landed: $stale_already_landed
- Ambiguous: $ambiguous_count
- Held marathons surfaced, not counted: $held_docs

## Notes

- The scanner is read-only over target repos. It writes only this aggregate doc.
- Each active lane is preflighted with that repo's own \`utils/swarm-preflight.sh --dry-run\`.
- Held marathons are surfaced for operator awareness but excluded from the fireable count by design.
EOF
} >"$OUT"

printf 'hq marathon-scan: wrote %s\n' "$OUT"
