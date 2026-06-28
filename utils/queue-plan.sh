#!/usr/bin/env bash
# utils/queue-plan.sh — deterministic "pre-pre-flight" queue planner.
#
# Reads the canonical ROADMAP.md ledger (a queue of work: GitHub issues + PROJECT/**.md docs),
# validates each item is still real (not already fixed / silently half-done), factors in the PDDA
# complexity/risk/effort ratings, and emits TWO artifacts:
#
#   1. a VALIDATION / DRIFT REPORT on stdout — deterministic signals, each a FLAG for a human,
#      never an auto-fix (already-closed / already-landed / undocumented-partial / drift / unrated);
#   2. a SEQUENCED QUEUE doc  PROJECT/2-WORKING/QUEUE-YYYY-MM-DD.md — ratings-ranked, collision-lane
#      aware, reproducing the shape of the hand-authored QUEUE-2026-06-27.md.
#
# It is the stage BEFORE utils/swarm-preflight.sh (which is per-item readiness). Overlap is intended:
# this planner REUSES swarm-preflight's contract shape + probe semantics, and can DELEGATE to it
# per-item with --deep. The planner is a PRODUCER of a plan; it never executes a marathon
# (GUIDING-PRINCIPLES.md §8 — the operator decides).
#
# Determinism: the score for every item is printed alongside its inputs so any ordering is
# reproducible by hand. Same ledger + same ratings + same NOW/TODAY ⇒ byte-identical output
# (so --check works as a drift guard in validate.sh, mirroring roadmap-dashboard.sh --check).
#
# Usage:
#   utils/queue-plan.sh                         # report on stdout + write today's QUEUE doc
#   utils/queue-plan.sh --dry-run               # report only; write nothing
#   utils/queue-plan.sh --check                 # exit non-zero if today's QUEUE doc is out of sync
#   utils/queue-plan.sh --policy derisk-first   # high-risk work sorts earlier (default: quick-wins)
#   utils/queue-plan.sh --deep                  # also delegate to swarm-preflight --dry-run per item
#   utils/queue-plan.sh --format json           # findings as JSON lines (pdda finding shape)
#
# Exit: 0 clean · 2 usage · 3 ROADMAP missing/unparseable ·
#       4 emitted, drift present (already-landed/closed — reconcile the ledger) ·
#       5 emitted, items held out of sequencing (unrated / note-only / not-ready) ·
#       6 gh required but unavailable (--require-gh only).
#
# Test seam (all optional; unset in production):
#   QUEUE_PLAN_ROOT / QUEUE_PLAN_ROADMAP / QUEUE_PLAN_QUEUE_DIR / QUEUE_PLAN_NOW / QUEUE_PLAN_TODAY
#   QUEUE_PLAN_GH_STATE_FILE   JSON map {"24":"CLOSED",...} used instead of calling `gh` (hermetic)
#   QUEUE_PLAN_BRANCHES_FILE   newline list of branch names used instead of calling `git branch`
#   QUEUE_PLAN_GH              force gh mode: off|stub (off ⇒ gh-unverified; stub needs *_STATE_FILE)

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${QUEUE_PLAN_ROOT:-"$(cd "$HERE/.." && pwd)"}"
ROADMAP="${QUEUE_PLAN_ROADMAP:-"$ROOT/ROADMAP.md"}"
QUEUE_DIR="${QUEUE_PLAN_QUEUE_DIR:-"$ROOT/PROJECT/2-WORKING"}"
NOW="${QUEUE_PLAN_NOW:-"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}"
TODAY="${QUEUE_PLAN_TODAY:-"$(date -u +%Y-%m-%d)"}"

die()  { printf 'queue-plan: %s\n' "$*" >&2; exit 2; }
emit() { printf '%s\n' "$*" >&2; }

usage() {
  cat <<'EOF'
Usage: utils/queue-plan.sh [--dry-run | --check] [--policy quick-wins|derisk-first]
                           [--deep] [--require-gh] [--format text|json]

  (default)        Print the validation report and write PROJECT/2-WORKING/QUEUE-<today>.md.
  --dry-run        Print the report; write no QUEUE doc.
  --check          Re-render and compare against today's QUEUE doc; non-zero on drift. Writes nothing.
  --policy P       quick-wins (default; momentum, low-cost first) | derisk-first (high-risk first).
  --deep           Additionally delegate to utils/swarm-preflight.sh --dry-run per ready item
                   (authoritative ref-based freshness/probe verdict; slower, needs network).
  --require-gh     Treat an unavailable/offline `gh` as a hard error (exit 6) instead of degrading.
  --format F       text (default) | json (findings as one JSON object per line).

Exit: 0 clean · 2 usage · 3 ROADMAP unparseable · 4 drift present · 5 items held · 6 gh required-but-absent.
EOF
}

POLICY="quick-wins"
FORMAT="text"
RUN_MODE="write"     # write | dry-run | check
DEEP=0
REQUIRE_GH=0

while (($# > 0)); do
  case "$1" in
    --dry-run)    RUN_MODE="dry-run"; shift ;;
    --check)      RUN_MODE="check"; shift ;;
    --policy)     POLICY="${2:-}"; shift 2 ;;
    --deep)       DEEP=1; shift ;;
    --require-gh) REQUIRE_GH=1; shift ;;
    --format)     FORMAT="${2:-}"; shift 2 ;;
    --help|-h)    usage; exit 0 ;;
    *)            usage; die "unknown argument: $1" ;;
  esac
done

case "$POLICY" in quick-wins|derisk-first) ;; *) die "--policy must be 'quick-wins' or 'derisk-first'" ;; esac
case "$FORMAT" in text|json) ;; *) die "--format must be 'text' or 'json'" ;; esac
[[ -f "$ROADMAP" ]] || { emit "ROADMAP not found: $ROADMAP"; exit 3; }
command -v node >/dev/null 2>&1 || die "node is required (Node stdlib only; no deps) but not found in PATH"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/queue-plan.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
RENDER_OUT="$TMP/QUEUE-$TODAY.md"
QUEUE_DOC="$QUEUE_DIR/QUEUE-$TODAY.md"

# Resolve the swarm-preflight path for --deep delegation (skipped silently if absent).
SWARM_PREFLIGHT="$HERE/swarm-preflight.sh"
[[ "$DEEP" -eq 1 && -x "$SWARM_PREFLIGHT" ]] || SWARM_PREFLIGHT=""

# One embedded Node program does the compute (parse ledger → resolve items → signals → score →
# wave-pack → render). It prints the report to stdout, writes the rendered QUEUE doc to QP_RENDER_OUT,
# and exits with the flag-derived code. git/gh are reached via execSync, but the test seam env files
# short-circuit them so the suite stays hermetic. CommonJS (node - <<'NODE') like roadmap-dashboard.sh.
QP_ROOT="$ROOT" QP_ROADMAP="$ROADMAP" QP_QUEUE_DIR="$QUEUE_DIR" \
QP_TODAY="$TODAY" QP_NOW="$NOW" QP_POLICY="$POLICY" QP_FORMAT="$FORMAT" \
QP_DEEP="$DEEP" QP_REQUIRE_GH="$REQUIRE_GH" QP_SWARM_PREFLIGHT="$SWARM_PREFLIGHT" \
QP_RENDER_OUT="$RENDER_OUT" \
QP_GH_STATE_FILE="${QUEUE_PLAN_GH_STATE_FILE:-}" QP_BRANCHES_FILE="${QUEUE_PLAN_BRANCHES_FILE:-}" \
QP_GH_FORCE="${QUEUE_PLAN_GH:-}" \
node - <<'NODE'
"use strict";
const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

const E = process.env;
const ROOT = E.QP_ROOT;
const TODAY = E.QP_TODAY;
const NOW = E.QP_NOW;
const POLICY = E.QP_POLICY;
const FORMAT = E.QP_FORMAT;
const DEEP = E.QP_DEEP === "1";
const REQUIRE_GH = E.QP_REQUIRE_GH === "1";
const SWARM_PREFLIGHT = E.QP_SWARM_PREFLIGHT || "";

// ── kernel write-set: the serialization bottleneck (QUEUE-2026-06-27 "the one safety rule") ──
const KERNEL_PATHS = [
  "relay-automation/relay-turn-lib.sh",
  "bin/tick",
  "relay-automation/relay-drive.sh",
];
const SHIM_RE = /relay-automation\/[a-z0-9-]+-turn\.sh$|relay-automation\/consult\.sh$/i;

// Ledger sections we sequence from vs. only reference.
const SECTIONS = ["Queue / parked intake", "In progress", "Completed", "Deferred · vision"];
const KNOWN_EMOJI = ["🟢", "🟡", "⏸️", "⛔", "✅", "🔮", "🔲", "⚠️", "🆕", "🐞", "🔴"];

// ── tiny readers ─────────────────────────────────────────────────────────────
function readFileSafe(p) { try { return fs.readFileSync(p, "utf8"); } catch { return null; } }
function existsAt(rel, base) { try { return fs.existsSync(path.resolve(base || ROOT, rel)); } catch { return false; } }

// Frontmatter line reader — same simple `key: value` contract pdda-lib.sh enforces.
function frontmatter(doc) {
  const raw = readFileSafe(doc);
  if (raw == null) return {};
  const lines = raw.replace(/^﻿/, "").split(/\r?\n/);
  let i = 0;
  while (i < lines.length && lines[i].trim() === "") i++;
  if (lines[i] == null || !/^---\s*$/.test(lines[i])) return {};
  const fm = {};
  for (i++; i < lines.length; i++) {
    if (/^---\s*$/.test(lines[i])) break;
    const m = lines[i].match(/^([A-Za-z0-9_]+):\s*(.*)$/);
    if (m) fm[m[1]] = m[2].trim();
  }
  return fm;
}

// Extract a swarm-preflight contract (heading /preflight contract/i + fenced ```json) — same shape
// utils/swarm-preflight.sh reads. Returns the parsed object or null (planner degrades, never dies).
function extractContract(doc) {
  const raw = readFileSafe(doc);
  if (raw == null) return null;
  const lines = raw.split(/\r?\n/);
  const h = lines.findIndex((l) => /^#{1,6}\s+.*preflight\s+contract/i.test(l));
  if (h < 0) return null;
  let start = -1;
  for (let j = h + 1; j < lines.length; j++) {
    if (/^```json\s*$/i.test(lines[j])) { start = j + 1; break; }
    if (/^#{1,6}\s+/.test(lines[j])) break;
  }
  if (start < 0) return null;
  let end = -1;
  for (let j = start; j < lines.length; j++) { if (/^```\s*$/.test(lines[j])) { end = j; break; } }
  if (end < 0) return null;
  try { return JSON.parse(lines.slice(start, end).join("\n")); } catch { return null; }
}

// Probe evaluator — same verdict semantics as swarm-preflight's eval-probes.mjs, run LOCALLY against
// ROOT (cheap, offline). landed = already fixed; unfixed = fix still required; blocked = can't tell.
function evalProbe(p) {
  const at = (rel) => path.resolve(ROOT, rel || "");
  try {
    switch (p.type) {
      case "path_absent":  return fs.existsSync(at(p.path)) ? "landed" : "unfixed";
      case "path_present": return !fs.existsSync(at(p.path)) ? "blocked" : "unfixed";
      case "grep_present":
        if (!fs.existsSync(at(p.path))) return "blocked";
        return new RegExp(p.pattern).test(fs.readFileSync(at(p.path), "utf8")) ? "unfixed" : "landed";
      case "grep_absent":
        return (fs.existsSync(at(p.path)) && new RegExp(p.pattern).test(fs.readFileSync(at(p.path), "utf8")))
          ? "landed" : "unfixed";
      default: return "blocked";
    }
  } catch { return "blocked"; }
}

// ── git / gh, with a hermetic test seam ──────────────────────────────────────
let BRANCHES = null;
function branches() {
  if (BRANCHES) return BRANCHES;
  if (E.QP_BRANCHES_FILE) {
    BRANCHES = (readFileSafe(E.QP_BRANCHES_FILE) || "").split(/\r?\n/).map((s) => s.trim()).filter(Boolean);
    return BRANCHES;
  }
  try {
    BRANCHES = execSync("git branch -a --format='%(refname:short)'", { cwd: ROOT, stdio: ["ignore", "pipe", "ignore"] })
      .toString().split(/\r?\n/).map((s) => s.trim()).filter(Boolean);
  } catch { BRANCHES = []; }
  return BRANCHES;
}
function branchMatchesSlug(slug) {
  if (!slug) return false;
  return branches().some((b) => b.toLowerCase().includes(slug.toLowerCase()));
}

// gh mode: live (real gh) | stub (state file) | off (unverified). Resolved once.
let GH_MODE = "live", GH_STATE = null;
(function resolveGh() {
  if (E.QP_GH_FORCE === "off") { GH_MODE = "off"; return; }
  if (E.QP_GH_STATE_FILE) {
    try { GH_STATE = JSON.parse(readFileSafe(E.QP_GH_STATE_FILE) || "{}"); GH_MODE = "stub"; return; } catch { GH_MODE = "off"; return; }
  }
  try { execSync("command -v gh", { stdio: "ignore" }); } catch { GH_MODE = "off"; return; }
  try { execSync("gh auth status", { stdio: "ignore" }); } catch { GH_MODE = "off"; return; }
})();
function ghState(n) {
  if (n == null) return null;
  if (GH_MODE === "off") return null;
  if (GH_MODE === "stub") return (GH_STATE && GH_STATE[String(n)]) || null;
  try {
    return execSync(`gh issue view ${n} --json state -q .state`, { cwd: ROOT, stdio: ["ignore", "pipe", "ignore"] })
      .toString().trim().toUpperCase() || null;
  } catch { return null; }
}

// ── ledger parse (the parser lifted + extended from roadmap-dashboard.sh) ──────
function stripMd(v) {
  return v.replace(/`([^`]+)`/g, "$1").replace(/\*\*([^*]+)\*\*/g, "$1")
    .replace(/\*([^*]+)\*/g, "$1").replace(/\[([^\]]+)\]\(([^)]+)\)/g, "$1").trim();
}
function parseBullet(block, section) {
  const text = block.map((l) => l.trim()).join(" ").replace(/\s+/g, " ").trim();
  const titleMatch = text.match(/^- \*\*(.+?)\*\*/);
  const title = titleMatch ? stripMd(titleMatch[1]) : stripMd(text.replace(/^- /, ""));
  let status = "—";
  for (const e of KNOWN_EMOJI) { if (text.includes(e)) { status = e; break; } }
  const links = [];
  const re = /\[([^\]]+)\]\(([^)]+)\)/g;
  let m;
  while ((m = re.exec(text)) !== null) links.push({ label: m[1], target: m[2] });
  return { title, status, links, raw: text, section };
}
function parseLedger(raw) {
  const lines = raw.split(/\r?\n/);
  const out = [];
  let inLedger = false, current = null;
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!inLedger) { if (/^##\s+Ledger\s*$/.test(line.trim())) inLedger = true; continue; }
    if (/^##\s+/.test(line) && !/^##\s+Ledger\s*$/.test(line.trim())) break;
    const sm = line.match(/^###\s+(.+?)\s*$/);
    if (sm) { current = SECTIONS.includes(sm[1].trim()) ? sm[1].trim() : null; continue; }
    if (!current || !/^- \*\*/.test(line)) continue;
    const block = [line];
    while (i + 1 < lines.length) {
      const nx = lines[i + 1];
      if (/^###\s+/.test(nx) || /^##\s+/.test(nx) || /^- \*\*/.test(nx)) break;
      block.push(nx); i += 1;
    }
    out.push(parseBullet(block, current));
  }
  return out;
}

// ── item resolution ──────────────────────────────────────────────────────────
function ghIssueOf(item) {
  for (const l of item.links) {
    const m = l.target.match(/github\.com\/[^\s)]+\/issues\/(\d+)/);
    if (m) return Number(m[1]);
  }
  const t = item.title.match(/\bGH-(\d+)\b/);
  return t ? Number(t[1]) : null;
}
function docOf(item) {
  const mds = item.links.map((l) => l.target).filter((t) => /\.md($|#)/.test(t) && /PROJECT\//.test(t) && !/relay-system\//.test(t));
  if (mds.length === 0) return null;
  const pick = mds.find((t) => /2-WORKING\/GH-\d+-/i.test(t)) || mds.find((t) => /2-WORKING\//.test(t)) || mds[0];
  return pick.replace(/#.*$/, "");
}
function slugOf(docRel, title) {
  const base = docRel ? path.basename(docRel, ".md") : title;
  return base.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "") || "item";
}
function zoneOf(contract, item) {
  // Proven zone from the contract write-set; else keyword-inferred (flagged zone-inferred).
  if (contract && Array.isArray(contract.artifacts)) {
    const arts = contract.artifacts;
    const orchOnly = (contract.lanes && contract.lanes.orchestrator_only) || [];
    // Zone is derived from the WRITE-SET (artifacts) only. orchestrator_only is a guardrail — paths the
    // lane must NOT touch — so it never adds to the write-set; it only reclassifies an artifact that
    // falls UNDER an orchestrator_only prefix as kernel-owned. (Unioning it in wrongly serialized any
    // shim whose contract merely names relay-turn-lib.sh as off-limits.)
    const touchesKernel = arts.some(
      (a) => KERNEL_PATHS.some((k) => a === k || a.startsWith(k)) ||
             orchOnly.some((o) => a === o || a.startsWith(o))
    );
    if (touchesKernel) return { zone: "kernel", inferred: false, writeset: arts };
    if (arts.some((a) => SHIM_RE.test(a))) return { zone: "shim", inferred: false, writeset: arts };
    return { zone: "independent", inferred: false, writeset: arts };
  }
  const hay = (item.title + " " + item.raw).toLowerCase();
  if (/relay-turn-lib|containment kernel|bin\/tick|relay-drive|commit semantics|epoch fenc/.test(hay))
    return { zone: "kernel", inferred: true, writeset: [] };
  if (/-turn\.sh|consult\.sh|\bshim\b/.test(hay))
    return { zone: "shim", inferred: true, writeset: [] };
  return { zone: "independent", inferred: true, writeset: [] };
}
function depsOf(item) {
  const deps = new Set();
  const re = /(?:after|once|depends on|gated on|blocked by)\s+(?:[^.]*?)\b(?:GH-|#)(\d+)/gi;
  let m;
  while ((m = re.exec(item.raw)) !== null) deps.add(Number(m[1]));
  return [...deps];
}
function isGoGated(item) {
  return /gated on operator go|gated on (a |an )?operator|operator go\b|awaiting go\b/i.test(item.raw);
}

const L = (x) => ({ low: 1, medium: 2, med: 2, high: 3 }[String(x || "").toLowerCase()] || null);

// ── findings (the pdda finding shape) ────────────────────────────────────────
const findings = [];
function flag(severity, type, rec, message, action) {
  findings.push({ severity, type, item: rec ? rec.title : "(run)", file: rec ? rec.docRel : "", message, action });
}

// ── build records ────────────────────────────────────────────────────────────
const raw = readFileSafe(E.QP_ROADMAP);
if (raw == null) { process.stderr.write("queue-plan: cannot read ROADMAP\n"); process.exit(3); }
const ledger = parseLedger(raw);
if (ledger.length === 0) { process.stderr.write("queue-plan: no ledger items parsed (is '## Ledger' present?)\n"); process.exit(3); }

const records = [];
for (const item of ledger) {
  const gh = ghIssueOf(item);
  const docRel = docOf(item);
  const docAbs = docRel ? path.resolve(ROOT, docRel) : null;
  const docExists = docRel ? existsAt(docRel) : false;
  const slug = slugOf(docRel, item.title);
  const fm = docExists ? frontmatter(docAbs) : {};
  const ratings = { complexity: L(fm.complexity), risk: L(fm.risk), effort: L(fm.effort) };
  const rated = ratings.complexity != null && ratings.risk != null && ratings.effort != null;
  const ratingsExempt = String(fm.ratings_exempt || "").toLowerCase() === "true";
  const contract = docExists ? extractContract(docAbs) : null;
  const z = zoneOf(contract, item);
  const rec = {
    title: item.title, section: item.section, emoji: item.status, raw: item.raw,
    gh, docRel, docExists, slug, ratings, rated, ratingsExempt, contract,
    zone: z.zone, zoneInferred: z.inferred, writeset: z.writeset,
    deps: depsOf(item), goGated: isGoGated(item),
    flags: [], signals: [], state: null, score: null, wave: null, ghState: null,
  };
  records.push(rec);
}

// Dedup identical (gh, docRel) pairs (e.g. an umbrella epic re-listing a child) — keep the first.
const seen = new Set();
const deduped = [];
for (const r of records) {
  const key = `${r.gh || ""}|${r.docRel || ""}|${r.title}`;
  if (seen.has(key)) continue;
  seen.add(key); deduped.push(r);
}

// ── per-item validation signals (deterministic; each a flag, never a fix) ─────
let ghUnverified = 0;
for (const r of deduped) {
  // note-only: no issue AND no doc → nothing to build.
  if (r.gh == null && !r.docRel) { r.state = "note-only"; flag("info", "note-only", r, "ledger note with no issue and no project doc — nothing to sequence", "human: action or drop the note"); continue; }

  // dead pointer
  if (r.docRel && !r.docExists) flag("warn", "drift", r, `project doc pointer does not exist on disk: ${r.docRel}`, "fix or drop the ledger link");

  // gh state
  if (r.gh != null) {
    const st = ghState(r.gh);
    r.ghState = st;
    if (st == null && GH_MODE === "off") { ghUnverified++; r.flags.push("gh-unverified"); }
    if (st === "CLOSED" && (r.section === "Queue / parked intake" || r.section === "In progress")) {
      r.state = "already-closed";
      flag("warn", "already-closed", r, `issue #${r.gh} is CLOSED but the ledger lists it under "${r.section}"`, "close the ledger: move to Completed or drop the pointer");
    }
    if (st === "OPEN" && r.section === "Completed") {
      flag("warn", "drift", r, `ledger marks this Completed but issue #${r.gh} is still OPEN`, "reopen the ledger entry or close the issue");
    }
  }

  // already-landed: the purpose-built fix_probes ALL report "landed" (the fix is already present).
  // Artifact existence is deliberately NOT a trigger here — a fix that MODIFIES an existing file always
  // has its artifacts present before the fix lands (e.g. GH-37 edits an existing consult.sh). fix_probes
  // are the authority swarm-preflight already trusts; artifact existence is only a partial-signal below.
  if (r.state == null && r.contract && Array.isArray(r.contract.fix_probes) && r.contract.fix_probes.length) {
    const verdicts = r.contract.fix_probes.map(evalProbe);
    if (verdicts.every((v) => v === "landed")) {
      r.state = "already-landed";
      flag("warn", "already-landed", r, "all fix_probes report 'landed' — the fix is already present", "verify-and-close, not a build lane");
    }
  }

  // undocumented partial completion: ≥2 independent signals, ledger status not done.
  if (r.state == null) {
    const sig = [];
    if (r.contract && Array.isArray(r.contract.artifacts)) {
      const arts = r.contract.artifacts;
      const some = arts.some((a) => existsAt(a)), all = arts.length > 0 && arts.every((a) => existsAt(a));
      if (some && !all) sig.push("some-artifacts-exist");
    }
    if (branchMatchesSlug(r.slug)) sig.push("branch-matches-slug");
    try { if (fs.readdirSync(path.join(ROOT, "test")).some((f) => f.toLowerCase().includes(r.slug))) sig.push("tests-reference-slug"); } catch {}
    const cl = readFileSafe(path.join(ROOT, "CHANGELOG.md"));
    if (cl && (r.gh != null && new RegExp(`#${r.gh}\\b`).test(cl) || (r.slug.length > 6 && cl.toLowerCase().includes(r.slug)))) sig.push("changelog-mentions-it");
    if (r.emoji === "🟢" && r.section !== "Completed") sig.push("built-not-closed-emoji");
    r.signals = sig;
    if (sig.length >= 2) {
      r.state = "partial";
      flag("warn", "undocumented-partial-completion", r, `${sig.length} signals of work not reflected in ledger status: ${sig.join(", ")}`, "human: reconcile — confirm scope done vs remaining, update ledger status");
    }
  }

  // (unrated is emitted in the readiness loop below, gated to sequenceable sections — Completed and
  // Deferred items never need ratings, so flagging them here would be pure noise.)
}

// run-level drift: a 2-WORKING doc with no ledger pointer (coverage rule, like pdda-check-roadmap-coverage)
(function coverageDrift() {
  let docs = [];
  try { docs = fs.readdirSync(E.QP_QUEUE_DIR).filter((f) => f.endsWith(".md")); } catch { return; }
  const pointed = new Set(deduped.map((r) => r.docRel && path.basename(r.docRel)).filter(Boolean));
  for (const f of docs) {
    if (/^QUEUE-\d{4}-\d\d-\d\d\.md$/.test(f)) continue; // generated queue docs don't need a pointer
    if (!pointed.has(f)) findings.push({ severity: "info", type: "drift", item: f, file: `PROJECT/2-WORKING/${f}`, message: "2-WORKING doc has no ROADMAP ledger pointer", action: "add a ledger pointer or set roadmap_exempt: true" });
  }
})();

// ── readiness classification ─────────────────────────────────────────────────
// Held buckets are never placed in an active wave. "ready" items are scored + waved.
for (const r of deduped) {
  if (r.state) continue;                                  // note-only / already-closed / already-landed / partial
  if (r.section === "Completed") { r.state = "completed-ref"; continue; }
  if (r.section === "Deferred · vision") { r.state = "deferred"; continue; }
  if (r.ratingsExempt) { r.state = "exempt"; continue; }  // deliberately not rated (completed/hub/superseded)
  if (r.gh != null && !r.docRel) { r.state = "needs-doc"; flag("info", "needs-doc", r, `issue #${r.gh} has no PROJECT capture doc linked in the ledger`, "promote to a 2-WORKING capture doc with a preflight contract"); continue; }
  if (r.docExists && !r.rated) {
    r.state = "unrated";
    const missing = ["complexity", "risk", "effort"].filter((k) => r.ratings[k] == null);
    flag("info", "unrated", r, `project doc missing rating key(s): ${missing.join(", ")}`, "add complexity/risk/effort frontmatter (see PDDA.md)");
    continue;
  }
  if (r.docExists && !r.contract) { r.state = "needs-contract"; flag("info", "needs-contract", r, "rated, but no preflight contract — not marathon-ready", "add a ## Swarm Preflight Contract json block"); continue; }
  if (r.goGated) { r.state = "gated"; continue; }         // scored for visibility, parked from active waves
  r.state = "ready";
}

// Optional deep delegation: per ready item with a doc, run swarm-preflight --dry-run and downgrade.
if (DEEP && SWARM_PREFLIGHT) {
  for (const r of deduped) {
    if (r.state !== "ready" || !r.docRel) continue;
    let code = 0;
    try { execSync(`bash ${JSON.stringify(SWARM_PREFLIGHT)} --project-doc ${JSON.stringify(r.docRel)} --dry-run`, { cwd: ROOT, stdio: "ignore" }); }
    catch (e) { code = e.status || 1; }
    if (code === 4) { r.state = "already-landed"; flag("warn", "already-landed", r, "swarm-preflight --dry-run → stale (exit 4)", "verify-and-close, not a build lane"); }
    else if (code === 5) { r.state = "not-ready"; flag("info", "not-ready", r, "swarm-preflight --dry-run → not marathon-ready (exit 5)", "see swarm-preflight next-action"); }
    else if (code === 6 || code === 7) { r.state = "blocked"; flag("info", "blocked", r, `swarm-preflight --dry-run → ${code === 6 ? "blocked" : "ambiguous"} (exit ${code})`, "resolve target/contract before sequencing"); }
  }
}

// ── scoring (printed per item; deterministic) ─────────────────────────────────
const W = { eff: 2, cx: 1, risk: 2, dep: 3, zone: 1 };
const RISK_SIGN = POLICY === "derisk-first" ? -1 : 1;
const RISK_W = POLICY === "derisk-first" ? 4 : W.risk;
const ZONE_PEN = { independent: 0, shim: 1, kernel: 2 };
function scoreOf(r) {
  // Held-but-scored (gated) items get the GO penalty so they sort after active work but keep a
  // sensible relative order. Only items with full ratings are scored; others are held out.
  if (!r.rated) return null;
  let s = W.eff * r.ratings.effort + W.cx * r.ratings.complexity + RISK_SIGN * RISK_W * r.ratings.risk;
  s += W.dep * r.deps.length + W.zone * ZONE_PEN[r.zone];
  if (r.state === "gated") s += 100;
  return s;
}
for (const r of deduped) r.score = scoreOf(r);

// ── wave packing (collision-safe; ≤1 kernel item per wave; deps push later) ───
const active = deduped.filter((r) => r.state === "ready").sort((a, b) => {
  if (a.score !== b.score) return a.score - b.score;
  if (a.deps.length !== b.deps.length) return a.deps.length - b.deps.length;
  const zr = { independent: 0, shim: 1, kernel: 2 };
  if (zr[a.zone] !== zr[b.zone]) return zr[a.zone] - zr[b.zone];
  if ((a.gh || 1e9) !== (b.gh || 1e9)) return (a.gh || 1e9) - (b.gh || 1e9);
  return a.slug < b.slug ? -1 : a.slug > b.slug ? 1 : 0;
});

const waves = [];
const placedIssue = new Map(); // gh issue → wave index it landed in (for dep ordering)
const pending = active.slice();
let guard = 0;
while (pending.length && guard++ < 100) {
  const wave = [];
  const waveWriteset = new Set();
  let kernelTaken = false;
  const deferred = [];
  for (const r of pending) {
    // dependency: a dep issue still active and not yet placed in an earlier wave ⇒ defer.
    const depUnmet = r.deps.some((d) => active.some((x) => x.gh === d) && !placedIssue.has(d));
    const collides = r.writeset.some((p) => waveWriteset.has(p));
    const kernelClash = r.zone === "kernel" && kernelTaken;
    // zone-inferred shim items (no proven write-set) conservatively can't share a wave with another shim.
    const inferredShimClash = r.zone === "shim" && r.zoneInferred && wave.some((w) => w.zone === "shim");
    if (depUnmet || collides || kernelClash || inferredShimClash) { deferred.push(r); continue; }
    wave.push(r);
    r.writeset.forEach((p) => waveWriteset.add(p));
    if (r.zone === "kernel") kernelTaken = true;
  }
  if (wave.length === 0) { // unbreakable dep cycle / all deferred — flush remainder to its own wave
    waves.push(deferred); deferred.forEach((r) => { if (r.gh != null) placedIssue.set(r.gh, waves.length - 1); });
    break;
  }
  waves.push(wave);
  wave.forEach((r) => { if (r.gh != null) placedIssue.set(r.gh, waves.length - 1); });
  pending.length = 0; pending.push(...deferred);
}
waves.forEach((w, i) => w.forEach((r) => (r.wave = i + 1)));

// ── exit code from flags ─────────────────────────────────────────────────────
const hasDrift = deduped.some((r) => r.state === "already-landed" || r.state === "already-closed");
const held = deduped.filter((r) => ["unrated", "needs-doc", "needs-contract", "note-only", "not-ready", "blocked"].includes(r.state));
let exitCode = 0;
if (hasDrift) exitCode = 4;
else if (held.length) exitCode = 5;
if (GH_MODE === "off" && REQUIRE_GH) exitCode = 6;

// ── report (stdout) ──────────────────────────────────────────────────────────
const counts = {
  queue: deduped.filter((r) => r.section === "Queue / parked intake").length,
  inprog: deduped.filter((r) => r.section === "In progress").length,
  active: active.length,
};
const weightStr = `eff:${W.eff},cx:${W.cx},risk:${RISK_W}${RISK_SIGN < 0 ? "(−)" : ""},dep:${W.dep},zone:${W.zone}`;

if (FORMAT === "json") {
  for (const f of findings) process.stdout.write(JSON.stringify({ timestamp: NOW, severity: f.severity, check: `queue-plan/${f.type}`, file: f.file || "", message: f.message, action: f.action }) + "\n");
  process.stdout.write(JSON.stringify({ timestamp: NOW, severity: exitCode ? "warn" : "info", check: "queue-plan/summary", file: "", message: `items=${deduped.length} active=${active.length} waves=${waves.length} drift=${hasDrift} held=${held.length} gh=${GH_MODE}`, action: "summary" }) + "\n");
} else {
  const out = [];
  out.push(`queue-plan · ${TODAY} · policy=${POLICY} · weights{${weightStr}} · gh=${GH_MODE}`);
  out.push(`  ledger items : ${deduped.length}  (queue ${counts.queue} · in-progress ${counts.inprog})`);
  out.push(`  active lanes : ${active.length} across ${waves.length} wave(s)   held: ${held.length}` + (ghUnverified ? `   gh-unverified: ${ghUnverified}` : ""));
  if (GH_MODE === "off") out.push(`  NOTE gh ${E.QP_GH_FORCE === "off" ? "disabled" : "unavailable"}: open/closed state not verified — relying on ledger section only`);
  out.push("");
  out.push("FLAGS (deterministic signals — never auto-resolved)");
  const order = { warn: 0, info: 1 };
  const sorted = findings.slice().sort((a, b) => (order[a.severity] - order[b.severity]) || (a.type < b.type ? -1 : 1));
  if (sorted.length === 0) out.push("  (none)");
  for (const f of sorted) {
    out.push(`  ${f.severity.toUpperCase().padEnd(4)} [${f.type}]  ${f.item}`);
    out.push(`        ${f.message}`);
    out.push(`        → ${f.action}`);
  }
  out.push("");
  out.push(`SUMMARY [queue-plan] items=${deduped.length} active=${active.length} waves=${waves.length} drift=${hasDrift} held=${held.length} (exit ${exitCode})`);
  process.stdout.write(out.join("\n") + "\n");
}

// ── render the sequenced QUEUE doc ───────────────────────────────────────────
function cell(v) { return String(v == null ? "—" : v); }
const ratingWord = (n) => ({ 1: "low", 2: "med", 3: "high" }[n] || "—");
function renderQueueDoc() {
  const o = [];
  o.push("---");
  o.push("title: Sequenced Automation Queue — ranked, freshness-validated, collision-aware");
  o.push("status: Active (2-WORKING)");
  o.push(`created: ${TODAY}`);
  o.push(`updated: ${TODAY}`);
  o.push("owner: noel");
  o.push("branch: main");
  o.push("doc_type: project");
  o.push("source: ../../ROADMAP.md (open ledger entries)");
  o.push("generated_by: utils/queue-plan.sh");
  o.push("roadmap_exempt: true");
  o.push("goal: >");
  o.push("  A sequenced concurrency plan derived from ROADMAP.md: ranks surviving work by PDDA");
  o.push("  complexity/risk/effort, validates each item is still real, and batches collision-safe");
  o.push("  lanes into waves. Generated — edit the ledger, not this file.");
  o.push("---");
  o.push("");
  o.push("<!-- GENERATED by utils/queue-plan.sh from ROADMAP.md — re-run to refresh; edit the ledger, not this file. -->");
  o.push("");
  o.push(`# Sequenced Queue ${TODAY} — Pre-pre-flight Plan`);
  o.push("");
  o.push(`> Derived from [ROADMAP.md](../../ROADMAP.md) · policy \`${POLICY}\` · weights {${weightStr}} · gh=${GH_MODE}.`);
  o.push("> The roadmap says **what/why**; this says **what is still real and in what order**. Execution");
  o.push("> detail still lives in each `PROJECT/**` doc — this is a scheduling overlay.");
  o.push("");
  o.push("## Status");
  o.push("");
  o.push("| What was just completed | What's next |");
  o.push("|---|---|");
  const firstWave = waves[0] ? waves[0].map((r) => r.gh ? `#${r.gh}` : r.slug).join(" ‖ ") : "(none)";
  o.push(`| Generated by \`utils/queue-plan.sh\` on ${TODAY} from the live ROADMAP ledger (${deduped.length} items; ${active.length} active across ${waves.length} wave(s); ${held.length} held). Drift present: ${hasDrift ? "yes — see Held/Flagged" : "no"}. | **Wave 1:** ${firstWave}. Fire each lane via \`swarm-preflight → marathon-drive\`, scoped by \`ALLOW_PATHS\`. Re-run this script when the ledger changes. |`);
  o.push("");
  o.push("## The one safety rule");
  o.push("");
  o.push("Two lanes are safe to run concurrently **iff their write-sets are disjoint**. The kernel");
  o.push("(`relay-automation/relay-turn-lib.sh`, `bin/tick`, `relay-automation/relay-drive.sh`) is the");
  o.push("serialization bottleneck: **at most one kernel lane per wave**, even in separate worktrees.");
  o.push("");
  o.push("## Collision map");
  o.push("");
  o.push("| Zone | Parallel-safe? | Active items here |");
  o.push("|---|---|---|");
  for (const zone of ["kernel", "shim", "independent"]) {
    const items = active.filter((r) => r.zone === zone).map((r) => r.gh ? `#${r.gh}` : r.slug);
    const safe = zone === "kernel" ? "❌ serialize — one at a time" : "✅ one lane per file";
    o.push(`| ${zone} | ${safe} | ${items.length ? items.join(", ") : "—"} |`);
  }
  o.push("");
  o.push("## Per-item scoring");
  o.push("");
  o.push("Every input is shown so the ordering is verifiable by hand (lower score = earlier).");
  o.push("");
  o.push("| Item | cx | risk | eff | zone | deps | score | wave |");
  o.push("|---|---|---|---|---|---|---|---|");
  for (const r of active) {
    const id = r.gh ? `[#${r.gh}] ${r.title}` : r.title;
    o.push(`| ${cell(id)} | ${ratingWord(r.ratings.complexity)} | ${ratingWord(r.ratings.risk)} | ${ratingWord(r.ratings.effort)} | ${r.zone}${r.zoneInferred ? "*" : ""} | ${r.deps.length ? r.deps.map((d) => "#" + d).join(",") : "—"} | ${cell(r.score)} | ${cell(r.wave)} |`);
  }
  if (active.length === 0) o.push("| (no active, ready, rated items) | — | — | — | — | — | — | — |");
  o.push("");
  o.push("`*` = zone inferred from keywords (no preflight contract write-set to prove it).");
  o.push("");
  o.push("## Recommended waves");
  o.push("");
  if (waves.length === 0) o.push("_No active lanes — every item is held or flagged (see below)._");
  waves.forEach((w, i) => {
    const lanes = w.map((r) => r.gh ? `#${r.gh}` : r.slug).join(" ‖ ");
    o.push(`**Wave ${i + 1}:** ${lanes || "(empty)"}`);
    o.push("");
  });
  o.push("## Held / flagged — excluded from active waves");
  o.push("");
  const buckets = [
    ["✅ Likely done — verify-and-close, not a build lane", ["already-landed", "already-closed"]],
    ["🔧 Reconcile — undocumented partial completion", ["partial"]],
    ["⏸️ Gated on operator GO", ["gated"]],
    ["⚠️ Not yet sequenceable — rate / add doc / add contract", ["unrated", "needs-doc", "needs-contract", "not-ready", "blocked"]],
    ["🚫 Rating-exempt (completed / hub / superseded)", ["exempt"]],
    ["🗒️ Notes (no issue, no doc)", ["note-only"]],
  ];
  for (const [label, states] of buckets) {
    const items = deduped.filter((r) => states.includes(r.state));
    if (items.length === 0) continue;
    o.push(`### ${label}`);
    for (const r of items) {
      const id = r.gh ? `#${r.gh} ` : "";
      const why = r.state === "gated" && r.score != null ? ` (would score ${r.score})` : "";
      o.push(`- ${id}${r.title} — \`${r.state}\`${why}`);
    }
    o.push("");
  }
  o.push("## How to fire a lane");
  o.push("");
  o.push("Per lane, the existing pipeline applies — no new control plane:");
  o.push("");
  o.push("```");
  o.push("utils/swarm-preflight.sh --project-doc <PROJECT/**/doc.md>   # or --gh-issue N");
  o.push("   → ready packet (candidate/freshness/fix-still-required + lane assignment)");
  o.push("relay-automation/marathon-drive.sh ...   # build→gate→review, contained");
  o.push("```");
  o.push("");
  o.push("- **Lane scoping:** give each lane an `ALLOW_PATHS` matching only its zone above.");
  o.push("- **Never** run two kernel lanes at once, even in separate worktrees.");
  o.push("");
  o.push("---");
  o.push("");
  o.push(`*Generated from [ROADMAP.md](../../ROADMAP.md) (source of truth). Re-run \`utils/queue-plan.sh\` after editing the ledger.*`);
  return o.join("\n") + "\n";
}

fs.writeFileSync(E.QP_RENDER_OUT, renderQueueDoc());
process.exit(exitCode);
NODE
RC=$?

# Node failed hard (parse error / exit 3) — pass the code straight through.
if [[ "$RC" -eq 3 || "$RC" -eq 2 ]]; then
  exit "$RC"
fi

# --check: compare the freshly-rendered doc against today's committed QUEUE doc.
if [[ "$RUN_MODE" == "check" ]]; then
  if [[ ! -f "$QUEUE_DOC" ]]; then
    emit "check: missing artifact: ${QUEUE_DOC#$ROOT/}"
    exit 1
  fi
  if cmp -s "$RENDER_OUT" "$QUEUE_DOC"; then
    emit "check: QUEUE-$TODAY.md is in sync"
    exit 0
  fi
  emit "check: drift detected in QUEUE-$TODAY.md"
  diff -u "$QUEUE_DOC" "$RENDER_OUT" >&2 || true
  exit 1
fi

# --dry-run: report already printed; write nothing.
if [[ "$RUN_MODE" == "dry-run" ]]; then
  exit "$RC"
fi

# default: write today's QUEUE doc.
mkdir -p "$QUEUE_DIR"
cp "$RENDER_OUT" "$QUEUE_DOC"
emit "wrote ${QUEUE_DOC#$ROOT/}"
exit "$RC"
