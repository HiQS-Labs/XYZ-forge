#!/usr/bin/env bash
# FROZEN (GH-308): Python is authoritative — do not make behavior changes here.
# Historical Bash fallback only; update utils/py/marathon_plan.py instead. See issue #308.
# (The native engine behind that entry point is utils/py/_marathon_plan.py.)
#
# Frozen later than the other 11 — the exception was retired by GH-362.
#
# This file was GH-308's ONE documented exception: its Bash body stayed authoritative and
# dual-maintained because the Python "port" shelled out to a copied, drifted node engine. GH-340
# removed that reason — the copy is deleted, utils/py/_marathon_plan.py is a native stdlib engine,
# and the Python lane needs no Node. `test/marathon-plan.sh` Scenario T still compares the two lanes
# byte-for-byte (GH-348), so accidental drift is caught; the FIRST deliberate Python-only change to
# the planner will fail it, and that failure is the signal to retire the assertion on purpose rather
# than to quietly widen it.

# GH-112 opt-in Python mode: XYZ_PYTHON=1 reroutes this entry point to the Python port in
# utils/py/ (same CLI contract + exit codes). Default (unset/0) runs the canonical Bash
# implementation below — Bash stays the supported default until the port is promoted.
if [[ "${XYZ_PYTHON-1}" == "1" ]]; then
  # UPGRADE.md §4 Phase-2 hardening (GH-255): (2a) `-` not `:-` so an explicit empty XYZ_PYTHON reads
  # as not-1 → Bash (load-bearing once the default flips to 1); (2b) require python3 >=3.8 and fall
  # back to Bash if missing/too-old. This site KEEPS its GH-154 --zones-config translation inside the
  # guarded branch — do NOT collapse it to the generic shim (that would drop the zones-config block).
  if command -v python3 >/dev/null 2>&1 \
     && python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,8) else 1)' 2>/dev/null; then
    _xyz_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    export XYZ_ROOT="$_xyz_root"
    export PYTHONPATH="$_xyz_root/utils/py${PYTHONPATH:+:$PYTHONPATH}"
    _py_args=()
    while (($# > 0)); do
      case "$1" in
        --zones-config)
          [[ $# -ge 2 ]] || { printf 'marathon-plan: missing argument for --zones-config\n' >&2; exit 2; }
          export QUEUE_PLAN_ZONES_FILE="$2"
          shift 2
          ;;
        *)
          _py_args+=("$1")
          shift
          ;;
      esac
    done
    exec python3 "$_xyz_root/utils/py/marathon_plan.py" "${_py_args[@]}"
  else
    echo "xyz: XYZ_PYTHON=1 but python3 missing or < 3.8 — falling back to Bash" >&2
  fi
fi

# utils/marathon-plan.sh — deterministic "pre-pre-flight" queue planner.
#
# Reads the canonical ROADMAP.md ledger (a queue of work: GitHub issues + PROJECT/**.md docs),
# validates each item is still real (not already fixed / silently half-done), factors in the PDDA
# complexity/risk/effort ratings, and emits TWO artifacts:
#
#   1. a VALIDATION / DRIFT REPORT on stdout — deterministic signals, each a FLAG for a human,
#      never an auto-fix (already-closed / already-landed / undocumented-partial / drift / unrated);
#   2. a SEQUENCED marathon-plan doc  PROJECT/2-WORKING/MARATHON-PLAN-YYYY-MM-DD.md — ratings-ranked, collision-lane
#      aware, reproducing the shape of the hand-authored QUEUE-2026-06-27.md.
#
# It is the stage BEFORE utils/swarm-preflight.sh (which is per-item readiness). Overlap is intended:
# this planner REUSES swarm-preflight's contract shape + probe semantics, and can DELEGATE to it
# per-item with --deep. The planner is a PRODUCER of a plan; it never executes a marathon
# (GUIDING-PRINCIPLES.md §8 — the operator decides).
#
# Determinism: the score for every item is printed alongside its inputs so any ordering is
# reproducible by hand. Same ledger + same ratings + same NOW/TODAY ⇒ byte-identical output
# (which is what makes the manual --check drift comparison below meaningful).
#
# Usage:
#   utils/marathon-plan.sh                         # report on stdout + write today's marathon-plan doc
#   utils/marathon-plan.sh --dry-run               # report only; write nothing
#   utils/marathon-plan.sh --check                 # exit non-zero if today's marathon-plan doc is out of sync
#   utils/marathon-plan.sh --policy derisk-first   # high-risk work sorts earlier (default: quick-wins)
#   utils/marathon-plan.sh --deep                  # also delegate to swarm-preflight --dry-run per item
#   utils/marathon-plan.sh --format json           # findings as JSON lines (pdda finding shape)
#   utils/marathon-plan.sh --zones-config FILE     # explicit zone-rules override
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
#   QUEUE_PLAN_ZONES_FILE      planner zone-rules override (2nd-precedence tier; see --zones-config)

set -uo pipefail
# strict-mode: -e exempt — analysis tool with expected-nonzero probes (git/gh/grep); errors handled explicitly. See GUIDING-PRINCIPLES.md#strict-mode-policy.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Vendored install: HERE is <target>/.xyz/utils → parent is .xyz → target root is grandparent.
_here_parent="$(cd "$HERE/.." && pwd)"
if [ "$(basename "$_here_parent")" = ".xyz" ]; then
  ROOT="${QUEUE_PLAN_ROOT:-"$(cd "$_here_parent/.." && pwd)"}"
  _SP_CMD=".xyz/utils/swarm-preflight.sh"
  _MD_CMD=".xyz/relay-automation/marathon-drive.sh"
  _MP_CMD=".xyz/utils/marathon-plan.sh"
else
  ROOT="${QUEUE_PLAN_ROOT:-"$_here_parent"}"
  _SP_CMD="utils/swarm-preflight.sh"
  _MD_CMD="relay-automation/marathon-drive.sh"
  _MP_CMD="utils/marathon-plan.sh"
fi
ROADMAP="${QUEUE_PLAN_ROADMAP:-"$ROOT/ROADMAP.md"}"
QUEUE_DIR="${QUEUE_PLAN_QUEUE_DIR:-"$ROOT/PROJECT/2-WORKING"}"
NOW="${QUEUE_PLAN_NOW:-"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}"
TODAY="${QUEUE_PLAN_TODAY:-"$(date -u +%Y-%m-%d)"}"

die()  { printf 'marathon-plan: %s\n' "$*" >&2; exit 2; }
emit() { printf '%s\n' "$*" >&2; }

usage() {
  cat <<'EOF'
Usage: utils/marathon-plan.sh [--dry-run | --check] [--policy quick-wins|derisk-first]
                           [--deep] [--require-gh] [--format text|json]
                           [--zones-config <file>]

  (default)        Print the validation report and write PROJECT/2-WORKING/MARATHON-PLAN-<today>.md.
  --dry-run        Print the report; write no marathon-plan doc.
  --check          Re-render and compare against today's marathon-plan doc; non-zero on drift. Writes nothing.
  --policy P       quick-wins (default; momentum, low-cost first) | derisk-first (high-risk first).
  --deep           Additionally delegate to utils/swarm-preflight.sh --dry-run per ready item
                   (authoritative ref-based freshness/probe verdict; slower, needs network).
  --require-gh     Treat an unavailable/offline `gh` as a hard error (exit 6) instead of degrading.
  --format F       text (default) | json (findings as one JSON object per line).
  --zones-config   Explicit planner zone-rules override. Relative paths resolve from the caller CWD.

Exit: 0 clean · 2 usage · 3 ROADMAP unparseable · 4 drift present · 5 items held · 6 gh required-but-absent.
EOF
}

POLICY="quick-wins"
FORMAT="text"
RUN_MODE="write"     # write | dry-run | check
DEEP=0
REQUIRE_GH=0
ZONES_CONFIG=""

while (($# > 0)); do
  case "$1" in
    --dry-run)    RUN_MODE="dry-run"; shift ;;
    --check)      RUN_MODE="check"; shift ;;
    --policy)     POLICY="${2:-}"; shift 2 ;;
    --deep)       DEEP=1; shift ;;
    --require-gh) REQUIRE_GH=1; shift ;;
    --format)     FORMAT="${2:-}"; shift 2 ;;
    --zones-config) ZONES_CONFIG="${2:-}"; shift 2 ;;
    --help|-h)    usage; exit 0 ;;
    *)            usage; die "unknown argument: $1" ;;
  esac
done

case "$POLICY" in quick-wins|derisk-first) ;; *) die "--policy must be 'quick-wins' or 'derisk-first'" ;; esac
case "$FORMAT" in text|json) ;; *) die "--format must be 'text' or 'json'" ;; esac
[[ -f "$ROADMAP" ]] || { emit "ROADMAP not found: $ROADMAP"; exit 3; }
command -v node >/dev/null 2>&1 || die "node is required (Node stdlib only; no deps) but not found in PATH"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/marathon-plan.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
RENDER_OUT="$TMP/MARATHON-PLAN-$TODAY.md"
QUEUE_DOC="$QUEUE_DIR/MARATHON-PLAN-$TODAY.md"

# Resolve the swarm-preflight path for --deep delegation (skipped silently if absent).
SWARM_PREFLIGHT="$HERE/swarm-preflight.sh"
[[ "$DEEP" -eq 1 && -x "$SWARM_PREFLIGHT" ]] || SWARM_PREFLIGHT=""

# One embedded Node program does the compute (parse ledger → resolve items → signals → score →
# wave-pack → render). It prints the report to stdout, writes the rendered marathon-plan doc to QP_RENDER_OUT,
# and exits with the flag-derived code. git/gh are reached via execSync, but the test seam env files
# short-circuit them so the suite stays hermetic. CommonJS (node - <<'NODE') like roadmap-dashboard.sh.
QP_ROOT="$ROOT" QP_ROADMAP="$ROADMAP" QP_QUEUE_DIR="$QUEUE_DIR" \
QP_TODAY="$TODAY" QP_NOW="$NOW" QP_POLICY="$POLICY" QP_FORMAT="$FORMAT" \
QP_DEEP="$DEEP" QP_REQUIRE_GH="$REQUIRE_GH" QP_SWARM_PREFLIGHT="$SWARM_PREFLIGHT" \
QP_SP_CMD="$_SP_CMD" QP_MD_CMD="$_MD_CMD" QP_MP_CMD="$_MP_CMD" \
QP_RENDER_OUT="$RENDER_OUT" QP_UTILS_DIR="$HERE" QP_ZONES_CONFIG="$ZONES_CONFIG" \
QP_GH_STATE_FILE="${QUEUE_PLAN_GH_STATE_FILE:-}" QP_BRANCHES_FILE="${QUEUE_PLAN_BRANCHES_FILE:-}" \
QP_GH_FORCE="${QUEUE_PLAN_GH:-}" QP_BASE_FILES_FILE="${QUEUE_PLAN_BASE_FILES_FILE:-}" \
QP_BRANCH="${QUEUE_PLAN_BRANCH:-}" \
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
const SP_CMD = E.QP_SP_CMD || "utils/swarm-preflight.sh";
const MD_CMD = E.QP_MD_CMD || "relay-automation/marathon-drive.sh";
const MP_CMD = E.QP_MP_CMD || "utils/marathon-plan.sh";
const BASE_FILES_FILE = E.QP_BASE_FILES_FILE || "";
const UTILS_DIR = E.QP_UTILS_DIR || process.cwd();

// GH-346: the rendered plan's `branch:` front-matter used to be the string literal "main". It is the
// repo's TRUNK, not the branch the generator happens to be standing on — deriving the current branch
// would make `--check` report drift merely because someone switched to a feature branch. Resolution
// order, mirrored byte-for-byte in utils/py/_marathon_plan.py (the two engines must agree):
//   1. QUEUE_PLAN_BRANCH  — explicit override; also the hermetic test seam, since the suite's fixture
//                           roots are plain directories, not git repos
//   2. origin/HEAD        — the trunk as the remote declares it (same source release-lanes.sh uses)
//   3. HEAD's branch      — a repo with no origin/HEAD still has an answer worth printing
//   4. "unknown"          — honest. The old literal "main" was wrong for every repo whose trunk is
//                           not main, and PDDA does not require this key (pdda.sh:39), so a lie here
//                           buys nothing.
function resolveBranch() {
  if (E.QP_BRANCH) return E.QP_BRANCH;
  const tryGit = (cmd) => {
    try {
      const out = execSync(cmd, { cwd: ROOT, stdio: ["ignore", "pipe", "ignore"] }).toString().trim();
      return out || null;
    } catch { return null; }
  };
  const remote = tryGit("git symbolic-ref --short refs/remotes/origin/HEAD");
  if (remote) return remote.replace(/^origin\//, "");
  const head = tryGit("git rev-parse --abbrev-ref HEAD");
  if (head && head !== "HEAD") return head;
  return "unknown";
}
const BRANCH = resolveBranch();
const EXPLICIT_ZONES_CONFIG = E.QP_ZONES_CONFIG || "";

// Ledger sections we sequence from vs. only reference.
const SECTIONS = ["Queue / parked intake", "In progress", "Completed", "Deferred · vision"];
const KNOWN_EMOJI = ["🟢", "🟡", "⏸️", "⛔", "✅", "🔮", "🔲", "⚠️", "🆕", "🐞", "🔴"];

// ── tiny readers ─────────────────────────────────────────────────────────────
function readFileSafe(p) { try { return fs.readFileSync(p, "utf8"); } catch { return null; } }
function existsAt(rel, base) { try { return fs.existsSync(path.resolve(base || ROOT, rel)); } catch { return false; } }
function readJsonOrThrow(absPath, label) {
  let raw;
  try { raw = fs.readFileSync(absPath, "utf8"); }
  catch (e) { throw new Error(`${label}: cannot read ${absPath}: ${e.message}`); }
  try { return JSON.parse(raw); }
  catch (e) { throw new Error(`${label}: invalid JSON in ${absPath}: ${e.message}`); }
}
function compileZoneConfig(raw, sourcePath) {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    throw new Error(`zones config must be an object (${sourcePath})`);
  }
  if (!Array.isArray(raw.zones)) {
    throw new Error(`zones config missing zones[] (${sourcePath})`);
  }
  if (!raw.defaultZone || typeof raw.defaultZone !== "object" || Array.isArray(raw.defaultZone) || typeof raw.defaultZone.name !== "string" || raw.defaultZone.name.trim() === "") {
    throw new Error(`zones config missing defaultZone.name (${sourcePath})`);
  }
  const names = new Set();
  const zones = raw.zones.map((zone, idx) => {
    if (!zone || typeof zone !== "object" || Array.isArray(zone)) {
      throw new Error(`zones[${idx}] must be an object (${sourcePath})`);
    }
    if (typeof zone.name !== "string" || zone.name.trim() === "") {
      throw new Error(`zones[${idx}] missing name (${sourcePath})`);
    }
    if (names.has(zone.name)) {
      throw new Error(`duplicate zone name '${zone.name}' (${sourcePath})`);
    }
    names.add(zone.name);
    let pathRegex = null;
    let inferKeywordRegex = null;
    if (zone.pathRegex != null) {
      try { pathRegex = new RegExp(zone.pathRegex, zone.pathRegexCaseInsensitive ? "i" : ""); }
      catch (e) { throw new Error(`zones[${idx}] invalid pathRegex '${zone.pathRegex}' (${sourcePath}): ${e.message}`); }
    }
    if (zone.inferKeywordRegex != null) {
      try { inferKeywordRegex = new RegExp(zone.inferKeywordRegex); }
      catch (e) { throw new Error(`zones[${idx}] invalid inferKeywordRegex '${zone.inferKeywordRegex}' (${sourcePath}): ${e.message}`); }
    }
    return {
      name: zone.name,
      pathPrefixes: Array.isArray(zone.pathPrefixes) ? zone.pathPrefixes.slice() : [],
      pathRegex,
      inferKeywordRegex,
      maxPerWave: Number.isInteger(zone.maxPerWave) ? zone.maxPerWave : null,
      penalty: Number.isFinite(Number(zone.penalty)) ? Number(zone.penalty) : 0,
      conservativeWhenInferred: zone.conservativeWhenInferred === true,
      escalateOrchestratorOnly: zone.escalateOrchestratorOnly === true,
    };
  });
  if (names.has(raw.defaultZone.name)) {
    throw new Error(`defaultZone.name '${raw.defaultZone.name}' duplicates a named zone (${sourcePath})`);
  }
  return {
    sourcePath,
    zones,
    defaultZone: {
      name: raw.defaultZone.name,
      penalty: Number.isFinite(Number(raw.defaultZone.penalty)) ? Number(raw.defaultZone.penalty) : 0,
      maxPerWave: Number.isInteger(raw.defaultZone.maxPerWave) ? raw.defaultZone.maxPerWave : null,
      conservativeWhenInferred: raw.defaultZone.conservativeWhenInferred === true,
      escalateOrchestratorOnly: raw.defaultZone.escalateOrchestratorOnly === true,
      pathPrefixes: [],
      pathRegex: null,
      inferKeywordRegex: null,
    },
  };
}
function resolveZoneConfig() {
  const explicit = EXPLICIT_ZONES_CONFIG ? path.resolve(process.cwd(), EXPLICIT_ZONES_CONFIG) : "";
  if (explicit) return compileZoneConfig(readJsonOrThrow(explicit, "--zones-config"), explicit);
  if (process.env.QUEUE_PLAN_ZONES_FILE) {
    const envPath = path.resolve(process.cwd(), process.env.QUEUE_PLAN_ZONES_FILE);
    return compileZoneConfig(readJsonOrThrow(envPath, "QUEUE_PLAN_ZONES_FILE"), envPath);
  }
  const rootLocal = path.join(ROOT, ".marathon-plan-zones.json");
  if (fs.existsSync(rootLocal)) return compileZoneConfig(readJsonOrThrow(rootLocal, rootLocal), rootLocal);
  const builtin = path.join(UTILS_DIR, "marathon-plan-zones.default.json");
  return compileZoneConfig(readJsonOrThrow(builtin, "built-in zones config"), builtin);
}
function zoneByName(cfg, name) {
  return cfg.zones.find((z) => z.name === name) || (cfg.defaultZone.name === name ? cfg.defaultZone : null);
}
function zoneRank(cfg, name) {
  const idx = cfg.zones.findIndex((z) => z.name === name);
  return idx >= 0 ? idx : cfg.zones.length;
}
function zoneMatchesPath(zone, artifactPath) {
  if (zone.pathPrefixes.some((prefix) => artifactPath === prefix || artifactPath.startsWith(prefix))) return true;
  if (zone.pathRegex && zone.pathRegex.test(artifactPath)) return true;
  return false;
}
let ZONES;
try { ZONES = resolveZoneConfig(); }
catch (e) {
  process.stderr.write(`marathon-plan: ${e.message}\n`);
  process.exit(3);
}

// Check if file existed at a given ref (to identify net-new artifacts).
// Hermetic test seam: if BASE_FILES_FILE is set, read it as a list of existing base paths.
let BASE_FILES = null;
function fileExistedAtBaseRef(relPath, ref) {
  let normalized = relPath;
  if (normalized.startsWith("./")) normalized = normalized.slice(2);
  if (BASE_FILES_FILE) {
    if (!BASE_FILES) {
      try {
        BASE_FILES = new Set(
          fs.readFileSync(BASE_FILES_FILE, "utf8")
            .split(/\r?\n/)
            .map((s) => s.trim())
            .filter(Boolean)
        );
      } catch {
        BASE_FILES = new Set();
      }
    }
    return BASE_FILES.has(normalized);
  }
  try {
    // Check if the file existed at the base ref using git
    execSync(`git cat-file -e "${ref}:${normalized}"`, { cwd: ROOT, stdio: ["ignore", "pipe", "ignore"] });
    return true;
  } catch {
    return false;
  }
}

// Frontmatter line reader — same simple `key: value` contract pdda-lib.sh enforces.
function frontmatter(doc) {
  const raw = readFileSafe(doc);
  if (raw == null) return {};
  const lines = raw.replace(/^\ufeff/, "").split(/\r?\n/);  // strip a leading UTF-8 BOM if present
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

// GH-86: parse a "## Lanes" markdown table from the manual PR-review-queue overlay doc
// (PROJECT/2-WORKING/PR-REVIEW-QUEUE-<date>.md) — a different shape from the ROADMAP ledger: each row
// reviews an existing PR diff rather than remediating a ledger item, so it doesn't fit parseBullet's
// `- **title**` bullet shape. Generalized instead by column NAME (Lane/PR/Reviewer), so header-cell
// wording (e.g. "Artifact (read-only)") doesn't need to match exactly. Degrades to [] on any
// malformed shape — never throws (same "flag, don't die" contract as the rest of this planner).
function parseLanesTable(raw) {
  const lines = raw.split(/\r?\n/);
  const h = lines.findIndex((l) => /^##\s+Lanes\s*$/.test(l.trim()));
  if (h < 0) return [];
  const splitRow = (l) => l.trim().replace(/^\|/, "").replace(/\|$/, "").split("|").map((c) => stripMd(c.trim()));
  let i = h + 1;
  while (i < lines.length && !/^\s*\|/.test(lines[i]) && !/^#{1,6}\s+/.test(lines[i])) i++;
  if (i >= lines.length || !/^\s*\|/.test(lines[i])) return []; // no table before the next heading
  const header = splitRow(lines[i]); i++;
  if (i < lines.length && /^\s*\|?\s*-{2,}/.test(lines[i])) i++; // separator row (|---|---|...)
  const col = (name) => header.findIndex((c) => c.toLowerCase() === name.toLowerCase());
  const laneIdx = col("Lane"), prIdx = col("PR"), revIdx = col("Reviewer");
  const rows = [];
  for (; i < lines.length && /^\s*\|/.test(lines[i]); i++) {
    const cells = splitRow(lines[i]);
    rows.push({
      lane: laneIdx >= 0 ? (cells[laneIdx] || "") : (cells[0] || ""),
      pr: prIdx >= 0 ? (cells[prIdx] || "") : "",
      reviewer: revIdx >= 0 ? (cells[revIdx] || "") : "",
    });
  }
  return rows;
}

// ── item resolution ──────────────────────────────────────────────────────────
function ghIssueOf(item) {
  // The canonical issue is the leading "GH-NN ·" in the TITLE. An in-prose issues/ link (e.g. GH-16's
  // body cites #17/#11/…) is a reference, not the item's identity — so the title WINS over links; only
  // fall back to the first issue link when the title carries no GH-NN (agy QA r4 [Blocker]).
  const t = item.title.match(/\bGH-(\d+)\b/);
  if (t) return Number(t[1]);
  for (const l of item.links) {
    const m = l.target.match(/github\.com\/[^\s)]+\/issues\/(\d+)/);
    if (m) return Number(m[1]);
  }
  return null;
}
function docOf(item, gh = null) {
  const mds = item.links.map((l) => l.target).filter((t) => /\.md($|#)/.test(t) && /PROJECT\//.test(t) && !/relay-system\//.test(t));
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
function slugOf(docRel, title) {
  const base = docRel ? path.basename(docRel, ".md") : title;
  return base.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "") || "item";
}
function zoneOf(contract, item) {
  // Proven zone from the contract write-set; else keyword-inferred (flagged zone-inferred).
  if (contract && Array.isArray(contract.artifacts)) {
    const arts = contract.artifacts;
    const orchOnly = (contract.lanes && contract.lanes.orchestrator_only) || [];
    for (const zone of ZONES.zones) {
      if (!zone.escalateOrchestratorOnly) continue;
      const touchesOrchOnly = arts.some((a) => orchOnly.some((o) => a === o || a.startsWith(o)));
      if (touchesOrchOnly) return { zone: zone.name, inferred: false, writeset: arts, zoneRule: zone };
    }
    for (const zone of ZONES.zones) {
      if (arts.some((a) => zoneMatchesPath(zone, a))) return { zone: zone.name, inferred: false, writeset: arts, zoneRule: zone };
    }
    return { zone: ZONES.defaultZone.name, inferred: false, writeset: arts, zoneRule: ZONES.defaultZone };
  }
  const hay = (item.title + " " + item.raw).toLowerCase();
  for (const zone of ZONES.zones) {
    if (zone.inferKeywordRegex && zone.inferKeywordRegex.test(hay)) {
      return { zone: zone.name, inferred: true, writeset: [], zoneRule: zone };
    }
  }
  return { zone: ZONES.defaultZone.name, inferred: true, writeset: [], zoneRule: ZONES.defaultZone };
}
function depsOf(item) {
  const deps = new Set();
  // Match a dependency keyword followed by a LIST of issue refs (comma/and/&/slash separated), so
  // "after GH-29, GH-30 and #31" yields all three. The list stops at the first non-issue token, so
  // "after GH-29 the fix landed" still yields only 29 (no over-capture).
  // Separator between refs is a RUN of comma/&//conjunction tokens (zero-or-more), so a compound
  // separator like ", and" / ", & " / "and/or" is consumed and the following ref is still captured
  // ("GH-100, GH-101, and GH-102" ⇒ all three). Each token consumes ≥1 char, so the `*` can't loop.
  const re = /(?:after|once|depends on|gated on|blocked by)\s+((?:(?:GH-|#)\d+(?:\s*(?:,|&|\/|and|or)\s*)*)+)/gi;
  let m;
  while ((m = re.exec(item.raw)) !== null) {
    let n; const num = /(?:GH-|#)(\d+)/g;
    while ((n = num.exec(m[1])) !== null) deps.add(Number(n[1]));
  }
  return [...deps];
}
function isGoGated(item) {
  return /gated on operator go|gated on (a |an )?operator|operator go\b|awaiting go\b/i.test(item.raw);
}

// GH-5: a "contract seam" is a directory two lanes SHARE (deeper than a top-level dir) even though
// their exact write-sets are disjoint — a strong hint they depend on a common not-yet-built module or
// schema. The wave-packer only defers on EXACT path collision, so such lanes co-wave and look
// independent; in practice the consumer stalls on the producer's handoff unless the operator pins a
// shared contract first. This detects the seam so the plan can say "pin a CONTRACT.md" up front.
function dirPrefixes(p) {
  const s = String(p);
  const endsDir = /\/$/.test(s); // a trailing slash means the artifact IS a directory — keep its last segment
  const parts = s.split("/").filter(Boolean);
  // Drop the last segment only when it's a FILE or glob leaf (e.g. a.js, **, *.js); a trailing-slash
  // directory keeps all of its segments (PR #103 review: `src/schema/` must yield `src/schema`).
  if (!endsDir && parts.length) parts.pop();
  const out = []; let acc = "";
  for (const seg of parts) { acc = acc ? acc + "/" + seg : seg; out.push(acc); }
  return out; // "src/schema/a.js" -> ["src", "src/schema"] ; "src/schema/" -> ["src", "src/schema"]
}
function sharedSpine(wsA, wsB) {
  // Deepest directory of >= 2 segments (contains a "/") shared by any path in A and any in B.
  // Top-level-only sharing (both under "src/" or "test/") is intentionally NOT a seam — too coarse.
  // "Deepest" = most path SEGMENTS (PR #103 review: string length is not depth — `src/long-name`
  // must not beat `src/a/b/c`); ties break lexically so the choice is canonical + deterministic.
  const depth = (x) => x.split("/").length;
  let best = null;
  for (const pa of wsA) {
    const pref = dirPrefixes(pa);
    for (const pb of wsB) {
      const setB = new Set(dirPrefixes(pb));
      for (const d of pref) {
        if (!d.includes("/") || !setB.has(d)) continue;
        if (!best || depth(d) > depth(best) || (depth(d) === depth(best) && d < best)) best = d;
      }
    }
  }
  return best;
}

// PDDA triage ratings are integers 1 (low) .. 5 (highest) — see PROJECT/PDDA.md "Triage ratings".
// Anything outside 1–5 (or absent) is treated as unrated (null) so the doc is held out of sequencing.
const L = (x) => { const n = parseInt(String(x == null ? "" : x).trim(), 10); return n >= 1 && n <= 5 ? n : null; };

// ── findings (the pdda finding shape) ────────────────────────────────────────
const findings = [];
function flag(severity, type, rec, message, action) {
  findings.push({ severity, type, item: rec ? rec.title : "(run)", file: rec ? rec.docRel : "", message, action });
}

// ── build records ────────────────────────────────────────────────────────────
const raw = readFileSafe(E.QP_ROADMAP);
if (raw == null) { process.stderr.write("marathon-plan: cannot read ROADMAP\n"); process.exit(3); }
const ledger = parseLedger(raw);
if (ledger.length === 0) { process.stderr.write("marathon-plan: no ledger items parsed (is '## Ledger' present?)\n"); process.exit(3); }

const records = [];
for (const item of ledger) {
  const gh = ghIssueOf(item);
  const docRel = docOf(item, gh);
  const docAbs = docRel ? path.resolve(ROOT, docRel) : null;
  const docExists = docRel ? existsAt(docRel) : false;
  const slug = slugOf(docRel, item.title);
  const fm = docExists ? frontmatter(docAbs) : {};
  const ratings = { complexity: L(fm.complexity), risk: L(fm.risk), effort: L(fm.effort) };
  const rated = ratings.complexity != null && ratings.risk != null && ratings.effort != null;
  const ratingsExempt = String(fm.ratings_exempt || "").toLowerCase() === "true";
  const contract = docExists ? extractContract(docAbs) : null;
  const z = zoneOf(contract, item);
  // GH-69: deterministic branch suggestion for this lane — from slug + run date, no git writes.
  // swarm-preflight (stage 2) checks it against `git branch -a`; the orchestrator (stage 3) prompts
  // the operator before cutting it. Carve-out (low-risk, independent zone) is applied by the
  // orchestrator, not here — this planner emits the same deterministic name for every item.
  const suggestedBranch = `marathon/${slug}-${TODAY}`;
  const rec = {
    title: item.title, section: item.section, emoji: item.status, raw: item.raw,
    gh, docRel, docExists, slug, ratings, rated, ratingsExempt, contract,
    zone: z.zone, zoneInferred: z.inferred, writeset: z.writeset, zoneRule: z.zoneRule,
    deps: depsOf(item), goGated: isGoGated(item), suggestedBranch,
    flags: [], signals: [], state: null, score: null, wave: null, ghState: null,
  };
  records.push(rec);
}

// Dedup identical (gh, docRel) pairs (e.g. an umbrella epic re-listing a child) — keep the first.
const seen = new Set();
const deduped = [];
for (const r of records) {
  // Dedup same-issue-different-title by gh when present (one issue = one canonical item); fall back to
  // docRel+title for issue-less notes so distinct field-findings that share one doc anchor stay separate.
  const key = r.gh != null ? `gh:${r.gh}` : `doc:${r.docRel || ""}|title:${r.title}`;
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
    if (r.section !== "Completed" && r.section !== "Deferred · vision") {
      const verdicts = r.contract.fix_probes.map(evalProbe);
      if (verdicts.every((v) => v === "landed")) {
        r.state = "already-landed";
        flag("warn", "already-landed", r, "all fix_probes report 'landed' — the fix is already present", "verify-and-close, not a build lane");
      }
    }
  }

  // undocumented partial completion: ≥2 independent signals, ledger status not done.
  // GH-85: stop marathon-plan undocumented-partial-completion false-positives on edit-existing-file lanes
  if (r.state == null) {
    const sig = [];
    if (r.contract && Array.isArray(r.contract.artifacts)) {
      const ref = (r.contract.target && r.contract.target.ref) || "HEAD";
      const hasNewArtifact = r.contract.artifacts.some((a) => existsAt(a) && !fileExistedAtBaseRef(a, ref));
      if (hasNewArtifact) sig.push("some-artifacts-exist");
    }
    if (branchMatchesSlug(r.slug)) sig.push("branch-matches-slug");
    try { if (fs.readdirSync(path.join(ROOT, "test")).some((f) => f.toLowerCase().includes(r.slug))) sig.push("tests-reference-slug"); } catch {}
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

// run-level drift: a 2-WORKING doc with no ledger pointer (coverage rule, like pdda-check-roadmap-coverage).
// Walk RECURSIVELY (incl. briefs/ etc.) to match pdda_list_working_docs' `find`, skipping blank.md.
function listMdRecursive(dir) {
  const out = [];
  let ents = [];
  try { ents = fs.readdirSync(dir, { withFileTypes: true }); } catch { return out; }
  for (const e of ents) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) out.push(...listMdRecursive(full));
    else if (e.name.endsWith(".md") && e.name !== "blank.md") out.push(full);
  }
  return out;
}
(function coverageDrift() {
  // "Pointed" = referenced by ANY ledger link (primary doc OR a secondary link like `brief: [...]`),
  // matching pdda-check-roadmap-coverage.sh which greps the whole ROADMAP — not just each item's primary doc.
  const pointed = new Set();
  for (const it of ledger) for (const l of it.links) {
    const t = l.target.replace(/#.*$/, "");
    if (t.endsWith(".md")) pointed.add(path.basename(t));
  }
  for (const full of listMdRecursive(E.QP_QUEUE_DIR)) {
    const base = path.basename(full);
    if (/^(MARATHON-PLAN|QUEUE)-\d{4}-\d\d-\d\d\.md$/.test(base)) continue;  // generated plan docs don't need a pointer (MARATHON-PLAN- new; QUEUE- historical)
    if (pointed.has(base)) continue;
    const fm = frontmatter(full);                            // honor roadmap_exempt (align with the coverage check)
    if (String(fm.roadmap_exempt || "").toLowerCase() === "true") continue;
    findings.push({ severity: "info", type: "drift", item: base, file: path.relative(ROOT, full), message: "2-WORKING doc has no ROADMAP ledger pointer", action: "add a ledger pointer or set roadmap_exempt: true" });
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

// ── dependency resolution (before scoring/packing) ───────────────────────────
// A dependency in one of these states is "resolved" — done or deliberately out of the active plan —
// so it never blocks its dependent. Anything else (ready/unrated/needs-*/gated/...) must be built first.
const DEP_RESOLVED = new Set(["completed-ref", "already-landed", "already-closed", "deferred", "exempt", "note-only"]);

// Warn on a dependency that names an issue absent from the ledger (likely a typo / missing pointer).
for (const r of deduped) for (const d of r.deps) {
  if (!deduped.some((x) => x.gh === d)) flag("info", "dep-not-found", r, `lists a dependency on #${d}, which is not in the ledger`, "fix the issue number or add a ledger pointer");
}

// Exclude (don't merely defer) a ready item whose dependency can NEVER be built — a dep that is held/
// unbuildable (unrated / needs-doc / needs-contract / gated / not-ready / blocked) and not itself ready.
// Marking it blocked-dep keeps it OUT of the active waves instead of flushing it into a trailing wave
// (agy QA r3 [Should]). Iterate to a fixpoint so the block propagates transitively (A→B→held).
let depChanged = true;
while (depChanged) {
  depChanged = false;
  for (const r of deduped) {
    if (r.state !== "ready") continue;
    const blockedBy = r.deps.filter((d) => {
      const dep = deduped.find((x) => x.gh === d);
      if (!dep || DEP_RESOLVED.has(dep.state) || dep.state === "ready") return false;
      return true;                                   // dep is held / blocked-dep ⇒ unbuildable
    });
    if (blockedBy.length) {
      r.state = "blocked-dep"; depChanged = true;
      flag("info", "blocked-dep", r, `depends on a held/unbuildable item (${blockedBy.map((d) => "#" + d).join(", ")}) — excluded from active waves until the dependency is sequenceable`, "rate/unblock the dependency first");
    }
  }
}

// ── scoring (printed per item; deterministic) ─────────────────────────────────
const W = { eff: 2, cx: 1, risk: 2, dep: 3, zone: 1 };
const RISK_SIGN = POLICY === "derisk-first" ? -1 : 1;
const RISK_W = POLICY === "derisk-first" ? 4 : W.risk;
function scoreOf(r) {
  // Held-but-scored (gated) items get the GO penalty so they sort after active work but keep a
  // sensible relative order. Only items with full ratings are scored; others are held out.
  if (!r.rated) return null;
  let s = W.eff * r.ratings.effort + W.cx * r.ratings.complexity + RISK_SIGN * RISK_W * r.ratings.risk;
  const zonePenalty = r.zoneRule && Number.isFinite(r.zoneRule.penalty) ? r.zoneRule.penalty : 0;
  s += W.dep * r.deps.length + W.zone * zonePenalty;
  if (r.state === "gated") s += 100;
  return s;
}
for (const r of deduped) r.score = scoreOf(r);

// ── wave packing (collision-safe; ≤1 kernel item per wave; deps push later) ───
const active = deduped.filter((r) => r.state === "ready").sort((a, b) => {
  if (a.score !== b.score) return a.score - b.score;
  if (a.deps.length !== b.deps.length) return a.deps.length - b.deps.length;
  const za = zoneRank(ZONES, a.zone), zb = zoneRank(ZONES, b.zone);
  if (za !== zb) return za - zb;
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
  const waveZoneCounts = new Map();
  const deferred = [];
  for (const r of pending) {
    // dependency: a dep is satisfied only if it is genuinely resolved (done/landed/closed/out-of-scope)
    // OR already placed in an earlier wave. A dep that is merely HELD (unrated/needs-contract/gated) is
    // NOT in `active` but is also not built — so it must still block its dependent (agy QA [Blocker]).
    const depUnmet = r.deps.some((d) => {
      const dep = deduped.find((x) => x.gh === d);
      if (!dep || DEP_RESOLVED.has(dep.state)) return false;
      return !placedIssue.has(d);
    });
    const collides = r.writeset.some((p) => waveWriteset.has(p));
    const cap = r.zoneRule && Number.isInteger(r.zoneRule.maxPerWave) ? r.zoneRule.maxPerWave : null;
    const zoneCapClash = cap != null && (waveZoneCounts.get(r.zone) || 0) >= cap;
    const inferredZoneClash = !!(r.zoneRule && r.zoneRule.conservativeWhenInferred && r.zoneInferred && wave.some((w) => w.zone === r.zone));
    if (depUnmet || collides || zoneCapClash || inferredZoneClash) { deferred.push(r); continue; }
    wave.push(r);
    r.writeset.forEach((p) => waveWriteset.add(p));
    waveZoneCounts.set(r.zone, (waveZoneCounts.get(r.zone) || 0) + 1);
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

// GH-5: within each wave, flag pairs of write-disjoint lanes that share a directory spine — they
// likely share a contract seam. Advisory (never re-waves them): the fix is to pin a contract, after
// which they run parallel safely. Only lanes with a PROVEN write-set (from a contract) are judged.
const contractSeams = [];
for (const w of waves) {
  for (let i = 0; i < w.length; i++) {
    for (let j = i + 1; j < w.length; j++) {
      const a = w[i], b = w[j];
      if (!a.writeset.length || !b.writeset.length) continue;
      const spine = sharedSpine(a.writeset, b.writeset);
      if (spine) {
        contractSeams.push({ wave: a.wave, a, b, spine });
        flag("warn", "coupled-lanes", a,
          `same-wave lane shares the \`${spine}/\` spine with ${b.gh ? "#" + b.gh : b.slug} — write-disjoint but likely a shared contract seam`,
          `pin a CONTRACT.md for the ${spine}/ interface and point both lane prompts at it before launching`);
      }
    }
  }
}

// ── exit code from flags ─────────────────────────────────────────────────────
const hasDrift = deduped.some((r) => r.state === "already-landed" || r.state === "already-closed");
const held = deduped.filter((r) => ["unrated", "needs-doc", "needs-contract", "note-only", "not-ready", "blocked", "blocked-dep"].includes(r.state));
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
  for (const f of findings) process.stdout.write(JSON.stringify({ timestamp: NOW, severity: f.severity, check: `marathon-plan/${f.type}`, file: f.file || "", message: f.message, action: f.action }) + "\n");
  process.stdout.write(JSON.stringify({ timestamp: NOW, severity: exitCode ? "warn" : "info", check: "marathon-plan/summary", file: "", message: `items=${deduped.length} active=${active.length} waves=${waves.length} drift=${hasDrift} held=${held.length} gh=${GH_MODE}`, action: "summary" }) + "\n");
} else {
  const out = [];
  out.push(`marathon-plan · ${TODAY} · policy=${POLICY} · weights{${weightStr}} · gh=${GH_MODE}`);
  out.push(`  ledger items : ${deduped.length}  (queue ${counts.queue} · in-progress ${counts.inprog})`);
  out.push(`  active lanes : ${active.length} across ${waves.length} wave(s)   held: ${held.length}` + (ghUnverified ? `   gh-unverified: ${ghUnverified}` : ""));
  if (GH_MODE === "off") out.push(`  NOTE gh ${E.QP_GH_FORCE === "off" ? "disabled" : "unavailable"}: open/closed state not verified — relying on ledger section only`);
  out.push("");
  out.push("FLAGS (deterministic signals — never auto-resolved)");
  const order = { warn: 0, info: 1 };
  const sorted = findings.slice().sort((a, b) => (order[a.severity] - order[b.severity]) || (a.type < b.type ? -1 : a.type > b.type ? 1 : 0));
  if (sorted.length === 0) out.push("  (none)");
  for (const f of sorted) {
    out.push(`  ${f.severity.toUpperCase().padEnd(4)} [${f.type}]  ${f.item}`);
    out.push(`        ${f.message}`);
    out.push(`        → ${f.action}`);
  }
  out.push("");
  out.push(`SUMMARY [marathon-plan] items=${deduped.length} active=${active.length} waves=${waves.length} drift=${hasDrift} held=${held.length} (exit ${exitCode})`);
  process.stdout.write(out.join("\n") + "\n");
}

// ── render the sequenced marathon-plan doc ───────────────────────────────────────────
function cell(v) { return String(v == null ? "—" : v); }
// Ratings are integers 1 (low) .. 5 (highest); render the number, or — when unrated.
const ratingNum = (n) => (n >= 1 && n <= 5 ? String(n) : "—");
function renderQueueDoc() {
  const zoneRows = [...ZONES.zones, ZONES.defaultZone];
  const cappedZones = zoneRows.filter((z) => Number.isInteger(z.maxPerWave));
  const capSummary = cappedZones.length ? cappedZones.map((z) => `${z.name}≤${z.maxPerWave}/wave`).join(", ") : "none";
  const o = [];
  o.push("---");
  o.push("title: Marathon Plan — ranked, freshness-validated, collision-aware queue");
  o.push("status: Active (2-WORKING)");
  o.push(`created: ${TODAY}`);
  o.push(`updated: ${TODAY}`);
  o.push("owner: noel");
  o.push(`branch: ${BRANCH}`);   // GH-346: derived trunk, was the literal "main"
  o.push("doc_type: project");
  o.push("source: ../../ROADMAP.md (open ledger entries)");
  o.push(`generated_by: ${MP_CMD}`);
  o.push("roadmap_exempt: true");
  o.push("goal: >");
  o.push("  A sequenced concurrency plan derived from ROADMAP.md: ranks surviving work by PDDA");
  o.push("  complexity/risk/effort, validates each item is still real, and batches collision-safe");
  o.push("  lanes into waves. Generated — edit the ledger, not this file.");
  o.push("---");
  o.push("");
  o.push("<!-- GENERATED by utils/marathon-plan.sh from ROADMAP.md — re-run to refresh; edit the ledger, not this file. -->");
  o.push("");
  o.push(`# Marathon Plan ${TODAY} — pre-pre-flight sequenced queue`);
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
  o.push(`| Generated by \`utils/marathon-plan.sh\` on ${TODAY} from the live ROADMAP ledger (${deduped.length} items; ${active.length} active across ${waves.length} wave(s); ${held.length} held). Drift present: ${hasDrift ? "yes — see Held/Flagged" : "no"}. | **Wave 1:** ${firstWave}. Fire each lane via \`swarm-preflight → marathon-drive\`, scoped by \`ALLOW_PATHS\`. Re-run this script when the ledger changes. |`);
  o.push("");
  o.push("## The one safety rule");
  o.push("");
  o.push("Two lanes are safe to run concurrently **iff their write-sets are disjoint** and their zone");
  o.push(`caps are respected. Current caps: ${capSummary}.`);
  o.push("");
  o.push("## Collision map");
  o.push("");
  o.push("| Zone | Parallel-safe? | Active items here |");
  o.push("|---|---|---|");
  for (const zone of zoneRows) {
    const items = active.filter((r) => r.zone === zone.name).map((r) => r.gh ? `#${r.gh}` : r.slug);
    let safe = "✅ one lane per file";
    if (Number.isInteger(zone.maxPerWave)) {
      safe = zone.maxPerWave === 1 ? "❌ serialize — one at a time" : `❌ cap ${zone.maxPerWave} per wave`;
    } else if (zone.conservativeWhenInferred) {
      safe = "✅ one lane per file (serialize when inferred)";
    }
    o.push(`| ${zone.name} | ${safe} | ${items.length ? items.join(", ") : "—"} |`);
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
    o.push(`| ${cell(id)} | ${ratingNum(r.ratings.complexity)} | ${ratingNum(r.ratings.risk)} | ${ratingNum(r.ratings.effort)} | ${r.zone}${r.zoneInferred ? "*" : ""} | ${r.deps.length ? r.deps.map((d) => "#" + d).join(",") : "—"} | ${cell(r.score)} | ${cell(r.wave)} |`);
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
    // GH-69: suggested_branch per lane, on its own line so the "**Wave N:** #a ‖ #b" line above
    // stays single-line and grep-stable (test/marathon-plan.sh's wave_of() greps that exact line).
    for (const r of w) {
      const id = r.gh ? `#${r.gh}` : r.slug;
      o.push(`- ${id} → suggested_branch: \`${r.suggestedBranch}\``);
    }
    if (w.length) o.push("");
  });
  // GH-5: contract seams — coupled lanes that need a pinned contract before they can truly parallelize.
  o.push("## Contract seams — pin a contract before launching (GH-5)");
  o.push("");
  if (contractSeams.length === 0) {
    o.push("_None — no two same-wave lanes share a directory spine (deeper than a top-level dir)._");
    o.push("");
  } else {
    o.push("These same-wave lanes are **write-disjoint but share a directory spine**, so they likely share");
    o.push("an interface (a not-yet-built module/schema). xyz is not for tightly-coupled work: pin a short");
    o.push("`CONTRACT.md` for the seam and point **each** lane's prompt at it (code TO the contract, not to");
    o.push("the other lane's source), or the split can stall when the consumer waits on the producer's handoff.");
    o.push("");
    for (const s of contractSeams) {
      const an = s.a.gh ? `#${s.a.gh}` : s.a.slug, bn = s.b.gh ? `#${s.b.gh}` : s.b.slug;
      o.push(`- **Wave ${s.wave}:** ${an} ‖ ${bn} share \`${s.spine}/\` → pin a contract for that seam.`);
    }
    o.push("");
  }
  o.push("## Held / flagged — excluded from active waves");
  o.push("");
  const buckets = [
    ["✅ Likely done — verify-and-close, not a build lane", ["already-landed", "already-closed"]],
    ["🔧 Reconcile — undocumented partial completion", ["partial"]],
    ["⏸️ Gated on operator GO", ["gated"]],
    ["⚠️ Not yet sequenceable — rate / add doc / add contract", ["unrated", "needs-doc", "needs-contract", "not-ready", "blocked"]],
    ["⛔ Blocked on a held dependency", ["blocked-dep"]],
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

  // GH-86: surface the manual PR-review-lane overlay (PROJECT/2-WORKING/PR-REVIEW-QUEUE-<date>.md) —
  // a different shape from a ROADMAP build lane (reviewing an existing PR diff, not remediating a
  // ledger item) — so its existence isn't silently invisible next to the generated plan. This is how
  // two real review lanes went unrun until the operator noticed by hand (2026-07-02). Level 1
  // (surface) only: no per-lane run/verdict tracking (Level 2), no auto-generation from `gh pr list`
  // (Level 3) — see PROJECT/2-WORKING/GH-86-SURFACE-REVIEW-LANES.md's non-goals. File absent ⇒ push
  // nothing at all (zero output diff from before this fix, the common case).
  const reviewQueueRel = `PR-REVIEW-QUEUE-${TODAY}.md`;
  const reviewQueueRaw = readFileSafe(path.join(E.QP_QUEUE_DIR, reviewQueueRel));
  if (reviewQueueRaw != null) {
    const reviewLanes = parseLanesTable(reviewQueueRaw);
    o.push("## Review lanes (manual overlay — run via relay-xyz)");
    o.push("");
    o.push(`A separate manual overlay — [${reviewQueueRel}](${reviewQueueRel}) — is not derived from`);
    o.push("ROADMAP.md and does not appear in the waves above (a review lane evaluates an existing PR");
    o.push("diff; it doesn't remediate a ledger item). Fire each via `relay-xyz`, per the overlay doc.");
    o.push("");
    if (reviewLanes.length) {
      o.push("| Lane | PR | Reviewer |");
      o.push("|---|---|---|");
      for (const l of reviewLanes) o.push(`| ${cell(l.lane)} | ${cell(l.pr)} | ${cell(l.reviewer)} |`);
    } else {
      o.push(`_${reviewQueueRel} exists but its \`## Lanes\` table could not be parsed._`);
    }
    o.push("");
  }

  o.push("## How to fire a lane");
  o.push("");
  o.push("Per lane, the existing pipeline applies — no new control plane:");
  o.push("");
  o.push("```");
  o.push(`${SP_CMD} --project-doc <PROJECT/**/doc.md>   # or --gh-issue N`);
  o.push("   → ready packet (candidate/freshness/fix-still-required + lane assignment)");
  o.push(`${MD_CMD} ...   # build→gate→review, contained`);
  o.push("```");
  o.push("");
  o.push("- **Lane scoping:** give each lane an `ALLOW_PATHS` matching only its zone above.");
  o.push("- If the lane's allowlist includes filesystem-touching `test/*.sh`, treat those tests as read-only specs in-turn; the outer harness gate verifies them after the turn, outside the isolated worktree.");
  o.push("");
  o.push("---");
  o.push("");
  o.push(`*Generated from [ROADMAP.md](../../ROADMAP.md) (source of truth). Re-run \`${MP_CMD}\` after editing the ledger.*`);
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

# --check: compare the freshly-rendered doc against today's committed marathon-plan doc.
if [[ "$RUN_MODE" == "check" ]]; then
  if [[ ! -f "$QUEUE_DOC" ]]; then
    emit "check: missing artifact: ${QUEUE_DOC#$ROOT/}"
    exit 1
  fi
  if cmp -s "$RENDER_OUT" "$QUEUE_DOC"; then
    emit "check: MARATHON-PLAN-$TODAY.md is in sync"
    exit 0
  fi
  emit "check: drift detected in MARATHON-PLAN-$TODAY.md"
  diff -u "$QUEUE_DOC" "$RENDER_OUT" >&2 || true
  exit 1
fi

# --dry-run: report already printed; write nothing.
if [[ "$RUN_MODE" == "dry-run" ]]; then
  exit "$RC"
fi

# default: write today's marathon-plan doc.
mkdir -p "$QUEUE_DIR"
cp "$RENDER_OUT" "$QUEUE_DOC"
emit "wrote ${QUEUE_DOC#$ROOT/}"
exit "$RC"
