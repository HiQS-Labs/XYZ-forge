#!/usr/bin/env bash
# utils/swarm-preflight.sh — one durable intake planner for marathon runs (GH-25).
#
# Turns EITHER a single project doc OR an explicit bundle of GitHub issues into a
# marathon-ready run packet: it normalizes both inputs into one shape, checks branch
# freshness, proves the fix is still required, gates remediation readiness, assigns
# Codex/agy lanes, and emits a self-contained packet the orchestrator hands to
# relay-automation/marathon-drive.sh. It is the PRODUCER of the packet, never the
# executor of the marathon (GUIDING-PRINCIPLES.md §8 — the operator decides).
#
# The planner reads the EXECUTION SURFACE OF RECORD, never a raw issue thread
# (GUIDING-PRINCIPLES.md §11): every --gh-issue must already have an in-repo GH-* capture
# doc, and that doc must carry a machine-readable preflight contract. The contract is a
# single fenced ```json block under a heading matching /preflight contract/i, e.g.:
#
#     ## Swarm Preflight Contract
#     ```json
#     {
#       "target":      { "repo": ".", "ref": "main" },
#       "gate":        "bash validate.sh",
#       "fix_probes":  [ { "type": "path_absent", "path": "utils/swarm-preflight.sh" } ],
#       "artifacts":   [ "utils/swarm-preflight.sh", "test/swarm-preflight.sh" ],
#       "remediation": { "source": "self#phases", "criteria": "Phases 1-7 of GH-25" },
#       "lanes":       { "agy_safe": [], "orchestrator_only": [ "bin/", ".tick/" ] }
#     }
#     ```
#
# Usage:
#   utils/swarm-preflight.sh --project-doc PROJECT/2-WORKING/GH-25-*.md
#   utils/swarm-preflight.sh --gh-issue 25 --gh-issue 26 [--target-root REPO]
#   utils/swarm-preflight.sh --project-doc DOC --dry-run        # checks only, no packet written
#
# Exit: 0 ready (packet emitted) · 2 usage · 3 contract missing/invalid ·
#       4 stale/already-landed (fix not required) · 5 not marathon-ready ·
#       6 blocked/missing-target · 7 ambiguous.
#
# Branch prompt (GH-69) — orchestrating-agent contract: a ready packet's provenance carries
# `suggested_branch` (deterministic: marathon/<slug>-<run-date>) and `branch_ready` (does it already
# exist?). If `branch_ready: false` and `skip_branch_prompt: false`, ASK THE OPERATOR before invoking
# marathon-drive.sh — "This lane will commit to <branch>. Suggested branch: <suggested_branch>. Cut it
# now? [yes / no / custom name]" (never auto-cut — GUIDING-PRINCIPLES.md §8). `skip_branch_prompt: true`
# (risk==1 in the doc frontmatter AND an independent-zone artifact set — no kernel/shim path) means
# proceed on the current branch without asking. packet.md/packet.json both carry these fields inline,
# and the packet.md "Suggested branch" line already states which of the two applies — a driving agent
# reading the packet doesn't need to recompute it.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Vendored install: HERE is <target>/.xyz/utils → parent is .xyz → target root is grandparent.
_here_parent="$(cd "$HERE/.." && pwd)"
if [ "$(basename "$_here_parent")" = ".xyz" ]; then
  ROOT="${SWARM_PREFLIGHT_ROOT:-"$(cd "$_here_parent/.." && pwd)"}"
  _DRIVE_CMD=".xyz/relay-automation/marathon-drive.sh"
else
  ROOT="${SWARM_PREFLIGHT_ROOT:-"$_here_parent"}"
  _DRIVE_CMD="relay-automation/marathon-drive.sh"
fi
# GH-30 Phase 2: transcript-root resolver (rtl_transcript_root) — redirects relay-system/ to
# $XYZ_ARCHIVE_ROOT when set, else byte-for-byte "$ROOT/relay-system". relay-turn-lib.sh is a sibling
# dir of utils/ (both under the harness root, or both under .xyz/ in a vendored install).
source "$HERE/../relay-automation/relay-turn-lib.sh"
NOW="${SWARM_PREFLIGHT_NOW:-"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}"
TODAY="${SWARM_PREFLIGHT_TODAY:-"$(date -u +%Y-%m-%d)"}"

die()  { printf 'swarm-preflight: %s\n' "$*" >&2; exit 2; }
log()  { printf 'swarm-preflight: %s\n' "$*" >&2; }
emit() { printf '%s\n' "$*"; }   # stdout: operator-facing report lines

usage() {
  cat <<'EOF'
Usage: utils/swarm-preflight.sh (--project-doc DOC | --gh-issue N [--gh-issue N ...]) [options]

  --project-doc DOC     One PROJECT/**.md doc to plan from (mutually exclusive with --gh-issue).
  --gh-issue N          A GitHub issue number; repeatable for an explicit bundle. Each issue must
                        have an in-repo GH-<N>-*.md capture doc carrying a preflight contract.
  --target-root REPO    Repo the marathon would act on (default: this repo root).
  --out DIR             Packet output directory (default: relay-system/preflight/<date>/<slug>).
  --format text|json    Report format on stdout (default: text). JSON emits the normalized object.
  --dry-run             Run all checks and print the verdict, but do NOT write the packet directory.
  --help                Show this help.

Exit: 0 ready · 2 usage · 3 contract missing/invalid · 4 stale/already-landed ·
      5 not marathon-ready · 6 blocked/missing-target · 7 ambiguous.
EOF
}

# ── arg parsing ──────────────────────────────────────────────────────────────
PROJECT_DOC=""
GH_ISSUES=()
TARGET_ROOT=""
OUT_DIR=""
FORMAT="text"
DRY_RUN=0

while (($# > 0)); do
  case "$1" in
    --project-doc) PROJECT_DOC="${2:-}"; shift 2 ;;
    --gh-issue)    GH_ISSUES+=("${2:-}"); shift 2 ;;
    --target-root) TARGET_ROOT="${2:-}"; shift 2 ;;
    --out)         OUT_DIR="${2:-}"; shift 2 ;;
    --format)      FORMAT="${2:-}"; shift 2 ;;
    --dry-run)     DRY_RUN=1; shift ;;
    --help)        usage; exit 0 ;;
    *)             usage; die "unknown argument: $1" ;;
  esac
done

# ── mode resolution: exactly one input mode (Phase 1) ────────────────────────
if [[ -n "$PROJECT_DOC" && ${#GH_ISSUES[@]} -gt 0 ]]; then
  usage; die "--project-doc and --gh-issue are mutually exclusive; pick one input mode"
fi
if [[ -z "$PROJECT_DOC" && ${#GH_ISSUES[@]} -eq 0 ]]; then
  usage; die "one input mode required: --project-doc DOC or --gh-issue N"
fi
case "$FORMAT" in text|json) ;; *) die "--format must be 'text' or 'json'" ;; esac

command -v node >/dev/null 2>&1 || die "node is required (Node stdlib only; no deps) but not found in PATH"

# A throwaway workdir for the node programs + intermediate JSON; the packet dir is written at the end.
TMP="$(mktemp -d "${TMPDIR:-/tmp}/swarm-preflight.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# ── node helper programs (written once, run with `VAR=val node file.mjs`) ─────
# Writing to files (not heredoc-in-$()) avoids macOS bash 3.2 mis-parsing template
# literals, and keeps env vars on the real `node` binary so process.env is populated.

cat >"$TMP/extract-contract.mjs" <<'JS'
import { readFileSync } from "node:fs";
const doc = process.env.SP_DOC;
const lines = readFileSync(doc, "utf8").split(/\r?\n/);
const i = lines.findIndex(l => /^#{1,6}\s+.*preflight\s+contract/i.test(l));
if (i < 0) { process.stderr.write(`no '## ... Preflight Contract' heading in ${doc}\n`); process.exit(3); }
let start = -1;
for (let j = i + 1; j < lines.length; j++) {
  if (/^```json\s*$/i.test(lines[j])) { start = j + 1; break; }
  if (/^#{1,6}\s+/.test(lines[j])) break;
}
if (start < 0) { process.stderr.write(`no fenced json block under the contract heading in ${doc}\n`); process.exit(3); }
let end = -1;
for (let j = start; j < lines.length; j++) { if (/^```\s*$/.test(lines[j])) { end = j; break; } }
if (end < 0) { process.stderr.write(`unterminated json block in ${doc}\n`); process.exit(3); }
let obj;
try { obj = JSON.parse(lines.slice(start, end).join("\n")); }
catch (e) { process.stderr.write(`invalid JSON contract in ${doc}: ${e.message}\n`); process.exit(3); }
const get = (p) => p.split(".").reduce((o, k) => (o == null ? o : o[k]), obj);
for (const [p, t] of [["target","object"],["target.repo","string"],["target.ref","string"],["gate","string"]]) {
  const v = get(p);
  if (v == null || (t === "string" && typeof v !== "string") || (t === "object" && typeof v !== "object")) {
    process.stderr.write(`contract in ${doc} missing required field: ${p}\n`); process.exit(3);
  }
}
if (!Array.isArray(obj.fix_probes) || obj.fix_probes.length === 0) {
  process.stderr.write(`contract in ${doc} needs at least one fix_probes entry\n`); process.exit(3);
}
if (!Array.isArray(obj.artifacts) || obj.artifacts.length === 0) {
  process.stderr.write(`contract in ${doc} needs at least one artifacts path\n`); process.exit(3);
}
// GH-89: artifacts_new is an OPTIONAL subset marker — every path in it must also appear in
// artifacts[] (it is not a separate path list). A typo'd or stray entry is a contract error
// (exit 3), same severity as a missing required field, not a silent no-op.
if (obj.artifacts_new !== undefined) {
  if (!Array.isArray(obj.artifacts_new)) {
    process.stderr.write(`contract in ${doc}: artifacts_new must be an array of strings\n`); process.exit(3);
  }
  for (const a of obj.artifacts_new) {
    if (!obj.artifacts.includes(a)) {
      process.stderr.write(`contract in ${doc}: artifacts_new entry not present in artifacts[]: ${a}\n`); process.exit(3);
    }
  }
}
process.stdout.write(JSON.stringify(obj));
JS

cat >"$TMP/merge-contracts.mjs" <<'JS'
import { readFileSync } from "node:fs";
const rows = readFileSync(process.env.SP_CONTRACTS, "utf8").trim().split(/\n/).map(s => JSON.parse(s));
const base = rows[0];
const out = {
  target: { repo: base.target.repo, ref: base.target.ref },
  gate: base.gate,
  fix_probes: [...(base.fix_probes || [])],
  artifacts: [...(base.artifacts || [])],
  artifacts_new: [...(base.artifacts_new || [])],
  remediation: base.remediation || null,
  lanes: {
    agy_safe: [...((base.lanes || {}).agy_safe || [])],
    orchestrator_only: [...((base.lanes || {}).orchestrator_only || [])],
  },
};
for (const c of rows.slice(1)) {
  if (c.target.repo !== out.target.repo || c.target.ref !== out.target.ref) {
    process.stderr.write(`bundle disagreement: targets differ (${out.target.repo}@${out.target.ref} vs ${c.target.repo}@${c.target.ref})\n`);
    process.exit(7);
  }
  if (c.gate !== out.gate) { process.stderr.write(`bundle disagreement: gate commands differ\n`); process.exit(7); }
  out.fix_probes.push(...(c.fix_probes || []));
  for (const a of c.artifacts || []) if (!out.artifacts.includes(a)) out.artifacts.push(a);
  for (const a of c.artifacts_new || []) if (!out.artifacts_new.includes(a)) out.artifacts_new.push(a);
  for (const a of (c.lanes || {}).agy_safe || []) if (!out.lanes.agy_safe.includes(a)) out.lanes.agy_safe.push(a);
  for (const a of (c.lanes || {}).orchestrator_only || []) if (!out.lanes.orchestrator_only.includes(a)) out.lanes.orchestrator_only.push(a);
}
process.stdout.write(JSON.stringify(out));
JS

# GH-89: the greenfield safety check. artifacts_new is an exemption from the GH-39 A2 existence
# check (below), so it must not become a way to dodge that check on a path that should already
# exist. Every artifacts_new entry needs a fix_probes entry of type path_absent on the EXACT same
# path — proof, in a form the harness can check, that the lane author is asserting the path is
# genuinely unbuilt. Run against the MERGED contract (not per-doc) so a multi-issue bundle's
# artifacts_new and its matching path_absent probe are allowed to live in different docs of the
# same bundle, same as fix_probes/artifacts themselves are unioned above.
cat >"$TMP/check-artifacts-new.mjs" <<'JS'
import { readFileSync } from "node:fs";
const c = JSON.parse(readFileSync(process.env.SP_CONTRACT, "utf8"));
const artsNew = Array.isArray(c.artifacts_new) ? c.artifacts_new : [];
const probes = Array.isArray(c.fix_probes) ? c.fix_probes : [];
for (const a of artsNew) {
  const has = probes.some(p => p && p.type === "path_absent" && p.path === a);
  if (!has) {
    process.stderr.write(`contract error: artifacts_new entry '${a}' has no matching fix_probes entry of type path_absent on the same path\n`);
    process.exit(3);
  }
}
JS

cat >"$TMP/eval-probes.mjs" <<'JS'
import { readFileSync, existsSync, writeFileSync } from "node:fs";
import { execSync } from "node:child_process";
import { join } from "node:path";
const root = process.env.SP_ROOT;
const c = JSON.parse(readFileSync(process.env.SP_CONTRACT, "utf8"));
const at = (p) => join(root, p || "");
const probes = [], counts = { landed: 0, unfixed: 0, blocked: 0 };
for (const p of c.fix_probes) {
  let verdict = "unfixed"; // unfixed = fix still required (good); landed = already fixed; blocked = can't tell
  try {
    switch (p.type) {
      case "path_absent":  if (existsSync(at(p.path))) verdict = "landed"; break;
      case "path_present": if (!existsSync(at(p.path))) verdict = "blocked"; break;
      case "grep_present":
        if (!existsSync(at(p.path))) { verdict = "blocked"; break; }
        if (!new RegExp(p.pattern).test(readFileSync(at(p.path), "utf8"))) verdict = "landed";
        break;
      case "grep_absent":
        if (existsSync(at(p.path)) && new RegExp(p.pattern).test(readFileSync(at(p.path), "utf8"))) verdict = "landed";
        break;
      case "command": {
        let rc = 0;
        try { execSync(p.cmd, { cwd: root, stdio: "ignore" }); } catch { rc = 1; }
        if (p.expect_nonzero ? rc === 0 : rc !== 0) verdict = "landed";
        break;
      }
      default: verdict = "blocked";
    }
  } catch { verdict = "blocked"; }
  counts[verdict]++;
  probes.push({ type: p.type, path: p.path || null, verdict });
}
writeFileSync(process.env.SP_OUT, JSON.stringify(probes));
const stale = counts.landed > 0 ? 1 : 0;
const blocked = counts.blocked > 0 ? 1 : 0;
const ambig = stale && counts.unfixed > 0 ? 1 : 0;
process.stdout.write(`${stale} ${blocked} ${ambig}`);
JS

cat >"$TMP/expand-artifacts.mjs" <<'JS'
import { existsSync, readFileSync, readdirSync } from "node:fs";
import path from "node:path";

const root = process.env.SP_TARGET_ROOT;
const contract = JSON.parse(readFileSync(process.env.SP_CONTRACT, "utf8"));
const declared = Array.isArray(contract.artifacts) ? contract.artifacts : [];
const included = [];
const inferredTests = [];
const inferredHelpers = [];
const testRoot = path.join(root, "test");

const add = (list, p) => {
  if (!p || included.includes(p)) return false;
  included.push(p);
  if (list && !list.includes(p)) list.push(p);
  return true;
};
const read = (rel) => {
  try { return readFileSync(path.join(root, rel), "utf8"); }
  catch { return ""; }
};
const walk = (dir) => {
  const out = [];
  let ents = [];
  try { ents = readdirSync(dir, { withFileTypes: true }); } catch { return out; }
  for (const ent of ents) {
    const abs = path.join(dir, ent.name);
    if (ent.isDirectory()) out.push(...walk(abs));
    else out.push(abs);
  }
  return out;
};
const normalize = (rel) => rel.replace(/\\/g, "/");
const helperRefs = (raw) => {
  const refs = [];
  const pats = [
    /\$\(dirname "\$0"\)\/([^"' )]+)/g,
    /\$\(dirname "\$\{BASH_SOURCE\[0\]\}"\)\/([^"' )]+)/g,
    /\btest\/(_[A-Za-z0-9._-]+(?:\/[A-Za-z0-9._-]+)*)/g,
  ];
  for (const re of pats) {
    let m;
    while ((m = re.exec(raw)) !== null) {
      const rel = m[0].startsWith("test/") ? m[0] : `test/${m[1]}`;
      refs.push(normalize(rel));
    }
  }
  return refs;
};
const isFsTouching = (raw) => /(mktemp|git(?:\s+-C\s+\S+)?\s+(?:worktree|init)|mkdir\s|touch\s|rm\s+-|cat\s+>|printf\s+.*>|>>|writeFileSync|appendFileSync|mkdtempSync)/s.test(raw);

for (const rel of declared) add(null, rel);
if (existsSync(testRoot)) {
  for (const abs of walk(testRoot)) {
    const rel = normalize(path.relative(root, abs));
    if (!/^test\/.+/.test(rel)) continue;
    const raw = read(rel);
    if (declared.some((artifact) => raw.includes(artifact))) add(inferredTests, rel);
  }
}

const queue = [...inferredTests, ...declared.filter((p) => /^test\/.+/.test(p))];
const seenHelpers = new Set(queue);
while (queue.length) {
  const rel = queue.shift();
  for (const helper of helperRefs(read(rel))) {
    if (!helper.startsWith("test/")) continue;
    if (!existsSync(path.join(root, helper)) || seenHelpers.has(helper)) continue;
    seenHelpers.add(helper);
    add(inferredHelpers, helper);
    queue.push(helper);
  }
}

const fsTouching = included.filter((rel) => /^test\/.+\.sh$/.test(rel) && isFsTouching(read(rel)));
process.stdout.write(JSON.stringify({
  artifacts: included,
  inferred_tests: inferredTests,
  inferred_helpers: inferredHelpers,
  fs_touching_tests: fsTouching,
}));
JS

cat >"$TMP/lane-plan.mjs" <<'JS'
import { readFileSync } from "node:fs";
const c = JSON.parse(readFileSync(process.env.SP_CONTRACT, "utf8"));
const effective = JSON.parse(readFileSync(process.env.SP_EFFECTIVE_ARTIFACTS, "utf8"));
const arts = Array.isArray(effective.artifacts) ? effective.artifacts : (c.artifacts || []);
const orchOnly = (c.lanes && c.lanes.orchestrator_only) || ["bin/", ".tick/", "relay-automation/relay-turn-lib.sh"];
const agySafe = (c.lanes && c.lanes.agy_safe) || [];
const isOrch = (p) => orchOnly.some(o => p === o || p.startsWith(o));
const orchestrator = [], codex = [], agy = [];
for (const a of arts) {
  if (isOrch(a)) orchestrator.push(a);          // trust-critical kernel paths → orchestrator-only
  else if (agySafe.includes(a)) agy.push(a);    // explicitly cleared for an agy builder slot
  else codex.push(a);                            // default trusted code-writing lane
}
const topDir = (p) => p.split("/")[0];
const coupled = arts.length > 1 && new Set(arts.map(topDir)).size === 1;
const buildable = [...codex, ...agy];
process.stdout.write(JSON.stringify({
  orchestrator_owned: orchestrator,
  codex_lane: codex,
  agy_lane: agy,
  effective_artifacts: arts,
  inferred_test_artifacts: effective.inferred_tests || [],
  inferred_test_helpers: effective.inferred_helpers || [],
  fs_touching_tests: effective.fs_touching_tests || [],
  agy_review_default: true,                       // agy's sanctioned role is reviewer-first (Phase 5)
  coupling_warning: coupled ? "all artifacts share one top-level dir; treat as coupled" : null,
  parallelizable: !coupled && buildable.length >= 2,
  single_lane_only: coupled || buildable.length < 2,
}));
JS

cat >"$TMP/normalize.mjs" <<'JS'
import { readFileSync } from "node:fs";
const e = process.env;
const contract = JSON.parse(readFileSync(e.SP_CONTRACT, "utf8"));
const probes = JSON.parse(readFileSync(e.SP_PROBES, "utf8"));
const lanes = JSON.parse(readFileSync(e.SP_LANES, "utf8"));
const docs = e.SP_DOCS.trim().split(/\n/).filter(Boolean);
process.stdout.write(JSON.stringify({
  schema: "swarm-preflight/run-candidate@1",
  generated_at: e.SP_NOW,
  mode: e.SP_MODE,
  candidate: { slug: e.SP_SLUG },
  provenance: {
    source_docs: docs,
    issues: e.SP_ISSUES ? e.SP_ISSUES.split(",").filter(Boolean) : [],
    target_root: e.SP_ROOT,
    branch: e.SP_BRANCH,
    commit: e.SP_COMMIT,
    suggested_branch: e.SP_SUGGESTED_BRANCH,
    branch_ready: e.SP_BRANCH_READY === "1",
    skip_branch_prompt: e.SP_SKIP_BRANCH_PROMPT === "1",
  },
  contract,
  allow_paths: lanes.effective_artifacts || [],
  freshness: {
    fetch_ok: e.SP_FETCH === "1",
    upstream: e.SP_UP || null,
    ahead: Number(e.SP_AHEAD || 0),
    behind: Number(e.SP_BEHIND || 0),
    dirty: e.SP_DIRTY === "1",
    evaluated_ref: e.SP_REF || null,
    evaluated_ref_commit: e.SP_REF_COMMIT || null,
    checkout_matches_ref: e.SP_CHECKOUT_MATCHES_REF === "1",
    head_behind_ref: Number(e.SP_HEAD_BEHIND_REF || 0),
    candidate_state: e.SP_STATE,
    probes,
  },
  readiness: { ready: e.SP_READY === "1", next_action: e.SP_NEXT || null },
  lane_plan: lanes,
}, null, 2));
JS

# field <file> <dot.path> — read one value out of a JSON file (empty string if absent).
field() { SP_F="$1" SP_P="$2" node "$TMP/field.mjs"; }
cat >"$TMP/field.mjs" <<'JS'
import { readFileSync } from "node:fs";
const o = JSON.parse(readFileSync(process.env.SP_F, "utf8"));
const v = process.env.SP_P.split(".").reduce((a, k) => (a == null ? a : a[k]), o);
process.stdout.write(Array.isArray(v) ? v.join(",") : (v == null ? "" : String(v)));
JS

# ── resolve target root (Phase 3 repo-presence) ──────────────────────────────
TARGET_ROOT="${TARGET_ROOT:-$ROOT}"
TARGET_TOPLEVEL="$(git -C "$TARGET_ROOT" rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$TARGET_TOPLEVEL" ]]; then
  emit "BLOCKED: --target-root is not a git repo: $TARGET_ROOT"
  exit 6
fi
TARGET_ROOT="$TARGET_TOPLEVEL"

# ── collect source capture docs (Phase 2 source resolution) ──────────────────
# Both modes resolve to a list of capture-doc paths; the planner reads those docs,
# never a raw issue thread (GUIDING-PRINCIPLES.md §11).
SOURCE_DOCS=()
SOURCE_ISSUES=()
MODE=""

resolve_path() { local p="$1"; [[ "$p" = /* ]] && printf '%s' "$p" || printf '%s' "$ROOT/$p"; }

if [[ -n "$PROJECT_DOC" ]]; then
  MODE="project-doc"
  doc="$(resolve_path "$PROJECT_DOC")"
  [[ -f "$doc" ]] || { emit "BLOCKED: project doc not found: $PROJECT_DOC"; exit 6; }
  SOURCE_DOCS+=("$doc")
else
  MODE="gh-bundle"
  for n in "${GH_ISSUES[@]}"; do
    [[ "$n" =~ ^[0-9]+$ ]] || die "--gh-issue expects a number, got: $n"
    cap="$(ls "$ROOT"/PROJECT/2-WORKING/GH-"$n"-*.md 2>/dev/null | head -1 || true)"
    if [[ -z "$cap" ]]; then
      emit "BLOCKED: issue #$n has no in-repo GH-$n-*.md capture doc under PROJECT/2-WORKING/."
      emit "  Per GUIDING-PRINCIPLES.md §11 the planner reads the capture doc, not the issue thread."
      emit "  Remediation: promote issue #$n to a GH-$n capture doc with a preflight contract first."
      exit 6
    fi
    SOURCE_DOCS+=("$cap")
    SOURCE_ISSUES+=("$n")
  done
fi

# ── extract + merge the preflight contract(s) (Phase 1 / Phase 2 merge) ───────
: >"$TMP/contracts.jsonl"
for doc in "${SOURCE_DOCS[@]}"; do
  # Capture rc directly — `if ! VAR=$(...)` would clobber $? to 0 via the `!` negation.
  one="$(SP_DOC="$doc" node "$TMP/extract-contract.mjs")"; rc=$?
  if [[ $rc -ne 0 ]]; then
    emit "CONTRACT ERROR ($doc): see message above. The planner fails loud rather than guessing from prose."
    exit "$rc"
  fi
  printf '%s\n' "$one" >>"$TMP/contracts.jsonl"
done

MERGED="$(SP_CONTRACTS="$TMP/contracts.jsonl" node "$TMP/merge-contracts.mjs")"; rc=$?
if [[ $rc -ne 0 ]]; then
  emit "AMBIGUOUS: the issue bundle's contracts disagree (see message above). Split the bundle or align the contracts."
  exit "$rc"
fi
printf '%s' "$MERGED" >"$TMP/contract.json"

# GH-89: validate the artifacts_new / fix_probes(path_absent) pairing on the MERGED contract before
# it's ever used to exempt anything from the GH-39 A2 existence check below. A contract error here
# (exit 3) is the same severity as a missing required field — never a silent pass.
SP_CONTRACT="$TMP/contract.json" node "$TMP/check-artifacts-new.mjs"; rc=$?
if [[ $rc -ne 0 ]]; then
  emit "CONTRACT ERROR: see message above."
  exit "$rc"
fi

# GH-55: keep contract artifacts[] canonical for freshness/readiness, but derive the EFFECTIVE
# builder allowlist from them by auto-including covering tests under target-root/test that
# explicitly reference those artifacts, plus any sourced local test helpers (e.g. test/_setup.sh).
SP_TARGET_ROOT="$TARGET_ROOT" SP_CONTRACT="$TMP/contract.json" node "$TMP/expand-artifacts.mjs" >"$TMP/effective-artifacts.json"

# ── slug + provenance (Phase 2) ──────────────────────────────────────────────
PRIMARY_DOC="${SOURCE_DOCS[0]}"
SLUG="$(basename "$PRIMARY_DOC" .md | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed 's/--*/-/g; s/^-//; s/-$//')"
[[ -n "$SLUG" ]] || SLUG="preflight"
BRANCH="$(git -C "$TARGET_ROOT" symbolic-ref --quiet --short HEAD 2>/dev/null || echo "(detached)")"
COMMIT="$(git -C "$TARGET_ROOT" rev-parse HEAD 2>/dev/null || echo "(none)")"

# GH-69: deterministic branch suggestion for this lane (same slug+date convention as
# marathon-plan.sh's suggested_branch), and whether it already exists — the orchestrator prompts
# the operator to cut it only when branch_ready=false (GUIDING-PRINCIPLES §8: never auto-cut).
SUGGESTED_BRANCH="marathon/${SLUG}-${TODAY}"
BRANCH_READY=0
if git -C "$TARGET_ROOT" show-ref --verify --quiet "refs/heads/$SUGGESTED_BRANCH" \
   || git -C "$TARGET_ROOT" show-ref --verify --quiet "refs/remotes/origin/$SUGGESTED_BRANCH"; then
  BRANCH_READY=1
fi

# ── Phase 3: freshness ───────────────────────────────────────────────────────
FETCH_OK=1
git -C "$TARGET_ROOT" fetch --prune --quiet 2>/dev/null || FETCH_OK=0
UPSTREAM="$(git -C "$TARGET_ROOT" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo "")"
AHEAD=0; BEHIND=0
if [[ -n "$UPSTREAM" ]]; then
  read -r BEHIND AHEAD < <(git -C "$TARGET_ROOT" rev-list --left-right --count "${UPSTREAM}...HEAD" 2>/dev/null || echo "0 0")
fi
DIRTY=0
[[ -n "$(git -C "$TARGET_ROOT" status --porcelain 2>/dev/null)" ]] && DIRTY=1
FRESH_BLOCKED=0
[[ "$FETCH_OK" -eq 0 ]] && FRESH_BLOCKED=1   # offline / fetch failed is a visible blocked state, not silent

# ── Phase 3: resolve the declared target.ref and evaluate probes AGAINST IT ───
# The contract's target.ref is the committish the marathon will branch from — NOT whatever
# the target repo happens to have checked out. Probing the live working tree (a possibly
# 30-commits-stale `main`) is the exact starvation trap GH-25 exists to kill: a fix already
# shipped on origin/development reads as "still required" on a stale checkout, and the planner
# green-lights building something that already exists. So resolve the ref and probe a throwaway
# worktree OF THAT REF — path/grep/command probes then all see the ref's content, not the
# (possibly stale or dirty) working tree.
REF="$(field "$TMP/contract.json" target.ref)"
REF_COMMIT="$(git -C "$TARGET_ROOT" rev-parse --verify --quiet "${REF}^{commit}" 2>/dev/null || true)"
if [[ -z "$REF_COMMIT" ]]; then
  emit "BLOCKED: contract target.ref '$REF' does not resolve in $TARGET_ROOT (fetch_ok=$FETCH_OK)."
  emit "  The marathon would branch from this ref; if it can't be resolved the preflight is blind."
  emit "  Remediation: push/fetch the ref, or correct target.ref in the contract."
  exit 6
fi
HEAD_BEHIND_REF="$(git -C "$TARGET_ROOT" rev-list --count "HEAD..${REF_COMMIT}" 2>/dev/null || echo 0)"
CHECKOUT_MATCHES_REF=0; [[ "$COMMIT" == "$REF_COMMIT" ]] && CHECKOUT_MATCHES_REF=1
REF_WT="$(mktemp -d "${TMPDIR:-/tmp}/swarm-preflight-ref.XXXXXX")"; rm -rf "$REF_WT"
if ! git -C "$TARGET_ROOT" worktree add --detach --quiet "$REF_WT" "$REF_COMMIT" 2>/dev/null; then
  emit "BLOCKED: could not create a worktree at target.ref '$REF' ($REF_COMMIT) in $TARGET_ROOT."
  exit 6
fi
PROBE_SUMMARY="$(SP_ROOT="$REF_WT" SP_CONTRACT="$TMP/contract.json" SP_OUT="$TMP/probes.json" node "$TMP/eval-probes.mjs")"
read -r STALE BLOCKED AMBIG <<<"$PROBE_SUMMARY"
# GH-39 (A2): verify every declared artifact path exists at the evaluated ref. A "ready" packet whose
# artifacts[] is missing/mistyped would fail the marathon at the first edit (the GH-29-adjacent failure
# class). Checked in REF_WT — the ref's content — BEFORE the worktree is removed below.
# GH-89: an artifacts[] entry also listed in artifacts_new is an intentionally net-new (greenfield)
# path, already proven safe by the artifacts_new/fix_probes(path_absent) pairing check above — skip
# the existence check for those entries only. Everything not marked artifacts_new keeps today's
# strict-by-default existence check exactly.
GH39_ART_MISSING=""
_gh39_art_csv="$(field "$TMP/contract.json" artifacts)"
_gh39_new_csv="$(field "$TMP/contract.json" artifacts_new)"
_gh39_new_set=","
if [[ -n "$_gh39_new_csv" ]]; then
  IFS=',' read -ra _gh39_news <<<"$_gh39_new_csv"
  for _gh39_n in "${_gh39_news[@]}"; do
    read -r _gh39_n <<<"$_gh39_n"
    [[ -z "$_gh39_n" ]] && continue
    _gh39_new_set="${_gh39_new_set}${_gh39_n},"
  done
fi
if [[ -n "$_gh39_art_csv" ]]; then
  IFS=',' read -ra _gh39_arts <<<"$_gh39_art_csv"
  for _gh39_a in "${_gh39_arts[@]}"; do
    read -r _gh39_a <<<"$_gh39_a"               # trim leading/trailing whitespace
    [[ -z "$_gh39_a" ]] && continue
    [[ "$_gh39_new_set" == *",${_gh39_a},"* ]] && continue   # GH-89: declared net-new — skip
    [[ -e "$REF_WT/$_gh39_a" ]] || { GH39_ART_MISSING="$_gh39_a"; break; }
  done
fi
git -C "$TARGET_ROOT" worktree remove --force "$REF_WT" >/dev/null 2>&1 || rm -rf "$REF_WT"
git -C "$TARGET_ROOT" worktree prune >/dev/null 2>&1 || true

CAND_STATE="ready"
if   [[ "$BLOCKED" -eq 1 || "$FRESH_BLOCKED" -eq 1 ]]; then CAND_STATE="blocked"
elif [[ "$AMBIG" -eq 1 ]]; then CAND_STATE="ambiguous"
elif [[ "$STALE" -eq 1 ]]; then CAND_STATE="stale"
fi

# ── Phase 4: remediation readiness gate ──────────────────────────────────────
READY=1; READY_NEXT=""
GATE_CMD="$(field "$TMP/contract.json" gate)"
ART_CSV="$(field "$TMP/effective-artifacts.json" artifacts)"
FS_TOUCHING_TESTS_CSV="$(field "$TMP/effective-artifacts.json" fs_touching_tests)"
GH55_INFERRED_TESTS_CSV="$(field "$TMP/effective-artifacts.json" inferred_tests)"
GH55_INFERRED_HELPERS_CSV="$(field "$TMP/effective-artifacts.json" inferred_helpers)"
ART_COUNT=0; [[ -n "$ART_CSV" ]] && ART_COUNT="$(awk -F, '{print NF}' <<<"$ART_CSV")"

# GH-69 carve-out: a doc-only/trivial lane (risk==1, zone==independent) skips the branch-cut prompt
# and proceeds on the current branch — ratings make this deterministic. Mirrors marathon-plan.sh's
# KERNEL_PATHS/SHIM_RE zone heuristic (deliberately re-derived here, not imported, so the packet stays
# self-contained without a marathon-plan.sh dependency).
#
# Match semantics MUST mirror marathon-plan.sh exactly, or the two planners can disagree on a lane's
# zone: marathon-plan.sh's KERNEL_PATHS check is a PREFIX match (`a === k || a.startsWith(k)`), not
# exact — an exact-match `case` here would classify e.g. `bin/tick+helper.sh` as `independent` (wrongly
# skipping the branch prompt on a kernel-adjacent lane) while marathon-plan.sh classifies it `kernel`.
# Likewise SHIM_RE is case-insensitive (`/i`); an unqualified case-sensitive match here could let a
# differently-cased shim path (`relay-automation/Codex-turn.sh`) slip through as `independent`.
# (agy relay QA, 2026-07-01, [Should] + [Nit].)
FM_RISK="$(grep -m1 -E '^risk:[[:space:]]*[0-9]+' "$PRIMARY_DOC" 2>/dev/null | grep -oE '[0-9]+' || true)"
ZONE_KERNEL_PATHS=(relay-automation/relay-turn-lib.sh bin/tick relay-automation/relay-drive.sh)
ZONE="independent"
if [[ -n "$ART_CSV" ]]; then
  IFS=',' read -ra _z_arts <<<"$ART_CSV"
  for _z_a in "${_z_arts[@]}"; do
    read -r _z_a <<<"$_z_a"
    for _z_k in "${ZONE_KERNEL_PATHS[@]}"; do
      [[ "$_z_a" == "$_z_k" || "$_z_a" == "$_z_k"* ]] && { ZONE="kernel"; break; }
    done
    [[ "$ZONE" == "kernel" ]] && break
  done
  if [[ "$ZONE" != "kernel" ]]; then
    for _z_a in "${_z_arts[@]}"; do
      read -r _z_a <<<"$_z_a"
      # Case-insensitive shim match: lowercase the path, mirroring SHIM_RE's `/i`. `tr`, not bash-4
      # `${x,,}` — stock macOS bash is 3.2 (this repo's scripts stay 3.2-portable; see relay-turn-lib.sh).
      _z_a_lc="$(printf '%s' "$_z_a" | tr '[:upper:]' '[:lower:]')"
      case "$_z_a_lc" in
        relay-automation/*-turn.sh|relay-automation/consult.sh)
          # Bash case globs match `/` too (unlike marathon-plan.sh's SHIM_RE, whose [a-z0-9-]+ class
          # can't cross a path separator) — reject a nested subdirectory explicitly, or
          # relay-automation/subdir/foo+turn.sh would wrongly classify as shim (agy relay QA r2, [Nit]).
          _z_rest="${_z_a_lc#relay-automation/}"
          case "$_z_rest" in
            */*) ;;
            *) ZONE="shim" ;;
          esac
          ;;
      esac
      [[ "$ZONE" == "shim" ]] && break
    done
  fi
fi
SKIP_BRANCH_PROMPT=0
[[ "$FM_RISK" == "1" && "$ZONE" == "independent" ]] && SKIP_BRANCH_PROMPT=1

REMED_SRC="$(field "$TMP/contract.json" remediation.source)"
REMED_CRIT="$(field "$TMP/contract.json" remediation.criteria)"
DOC_HAS_PHASES=0
grep -Eq '^##+ .*[Pp]hase|^- \[[ xX]\]' "$PRIMARY_DOC" 2>/dev/null && DOC_HAS_PHASES=1

if [[ -z "$GATE_CMD" ]];     then READY=0; READY_NEXT="add a runnable gate command to the contract"; fi
if [[ "$ART_COUNT" -eq 0 ]]; then READY=0; READY_NEXT="add a bounded artifact / ALLOW_PATHS set to the contract"; fi
if [[ -z "$REMED_SRC$REMED_CRIT" && "$DOC_HAS_PHASES" -eq 0 ]]; then
  READY=0; READY_NEXT="research more: no phase plan or acceptance criteria — source is not runnable unattended"
fi
# GH-39 (A2): an artifact path that doesn't exist at the ref (detected in Phase 3) → not ready.
# Guarded on READY==1 so the FIRST failure's reason wins (don't clobber an earlier next-action).
if [[ "$READY" -eq 1 && -n "${GH39_ART_MISSING:-}" ]]; then
  READY=0; READY_NEXT="artifact path not found at target.ref: $GH39_ART_MISSING — fix the contract artifacts[] or push the file"
fi
# GH-39 (A1): the gate command must be RUNNABLE — its program resolves. (Whether the gate currently
# FAILS, proving the fix is still required, is already covered by fix_probes above; we deliberately do
# NOT execute the full gate here — that is heavy and side-effectful, e.g. a suite that spawns worktrees.)
# A `bash`/`sh <script>` gate must have its script; any other leading program must be on PATH.
if [[ "$READY" -eq 1 && -n "$GATE_CMD" ]]; then
  read -r -a _gh39_gw <<<"$GATE_CMD"
  _gh39_g0="${_gh39_gw[0]}"
  if [[ "$_gh39_g0" == "bash" || "$_gh39_g0" == "sh" ]]; then
    # First NON-FLAG token after the interpreter is the script — so `bash -x script.sh` resolves
    # `script.sh`, not `-x` (agy GH-39 review Nit).
    _gh39_script=""
    for _gh39_t in ${_gh39_gw[@]+"${_gh39_gw[@]:1}"}; do
      [[ "$_gh39_t" == -* ]] && continue
      _gh39_script="$_gh39_t"; break
    done
    [[ -n "$_gh39_script" && -f "$TARGET_ROOT/$_gh39_script" ]] || { READY=0; READY_NEXT="gate script not found at target.ref: ${_gh39_script:-<none>}"; }
  elif ! command -v "$_gh39_g0" >/dev/null 2>&1; then
    READY=0; READY_NEXT="gate program not on PATH: $_gh39_g0"
  fi
fi
# GH-39 (A3): build-lane CLI presence — ADVISORY only (never blocks: keeps preflight portable in
# keyless/CI environments where codex/agy aren't installed). Surfaced on the report below.
GH39_LANE_NOTE="codex=$(command -v codex >/dev/null 2>&1 && echo present || echo absent) agy=$(command -v agy >/dev/null 2>&1 && echo present || echo absent)"

# ── Phase 5: lane assignment ─────────────────────────────────────────────────
SP_CONTRACT="$TMP/contract.json" SP_EFFECTIVE_ARTIFACTS="$TMP/effective-artifacts.json" node "$TMP/lane-plan.mjs" >"$TMP/lane-plan.json"

# ── assemble the normalized run-candidate object (Phase 2 output shape) ───────
ISSUES_CSV="$(IFS=,; printf '%s' "${SOURCE_ISSUES[*]:-}")"
printf '%s\n' "${SOURCE_DOCS[@]}" >"$TMP/docs.txt"
SP_CONTRACT="$TMP/contract.json" SP_PROBES="$TMP/probes.json" SP_LANES="$TMP/lane-plan.json" \
  SP_DOCS="$(cat "$TMP/docs.txt")" SP_ISSUES="$ISSUES_CSV" SP_MODE="$MODE" SP_SLUG="$SLUG" \
  SP_BRANCH="$BRANCH" SP_COMMIT="$COMMIT" SP_SUGGESTED_BRANCH="$SUGGESTED_BRANCH" SP_BRANCH_READY="$BRANCH_READY" \
  SP_SKIP_BRANCH_PROMPT="$SKIP_BRANCH_PROMPT" \
  SP_ROOT="$TARGET_ROOT" SP_NOW="$NOW" SP_STATE="$CAND_STATE" \
  SP_FETCH="$FETCH_OK" SP_UP="$UPSTREAM" SP_AHEAD="$AHEAD" SP_BEHIND="$BEHIND" SP_DIRTY="$DIRTY" \
  SP_REF="$REF" SP_REF_COMMIT="$REF_COMMIT" SP_HEAD_BEHIND_REF="$HEAD_BEHIND_REF" \
  SP_CHECKOUT_MATCHES_REF="$CHECKOUT_MATCHES_REF" \
  SP_READY="$READY" SP_NEXT="$READY_NEXT" \
  node "$TMP/normalize.mjs" >"$TMP/run-candidate.json"

# ── final verdict + exit code ────────────────────────────────────────────────
VERDICT="ready"; CODE=0
case "$CAND_STATE" in
  blocked)   VERDICT="BLOCKED";   CODE=6 ;;
  ambiguous) VERDICT="AMBIGUOUS"; CODE=7 ;;
  stale)     VERDICT="STALE";     CODE=4 ;;
  ready)     [[ "$READY" -eq 0 ]] && { VERDICT="NOT-READY"; CODE=5; } ;;
esac

# GH-51 [1]: emit --target-root ONLY for a FOREIGN target. For a same-repo lane it is redundant AND
# routes relay-file path normalization through the cross-repo code path, which flags the legitimately
# edited relay file (it lives in the thread repo, not the target) as off-lane → exit 6, discarding the
# build. Omit the flag when the target IS this repo so same-repo lanes take the default (correct) path.
TARGET_ROOT_LINE=""
# Compare CANONICAL paths: TARGET_ROOT is the symlink-resolved git toplevel, but ROOT may be a raw
# SWARM_PREFLIGHT_ROOT / a /var→/private/var symlink, so a bare string compare misfires (and would
# wrongly emit --target-root for a same-repo lane). Resolve both with `pwd -P` before comparing.
_root_canon="$(cd "$ROOT" 2>/dev/null && pwd -P || printf '%s' "$ROOT")"
_target_canon="$(cd "$TARGET_ROOT" 2>/dev/null && pwd -P || printf '%s' "$TARGET_ROOT")"
[[ "$_target_canon" != "$_root_canon" ]] && TARGET_ROOT_LINE=$'\n'"  --target-root $TARGET_ROOT \\"
INVOCATION="XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=$SLUG $_DRIVE_CMD \\
  --phase-brief <packet>/packet.md \\
  --reviewer agy \\
  --builder codex \\
  --artifact $ART_CSV \\$TARGET_ROOT_LINE
  --pre-advance-cmd '$GATE_CMD' \\
  --require-clean"

# ── emit report (stdout) ─────────────────────────────────────────────────────
if [[ "$FORMAT" == "json" ]]; then
  cat "$TMP/run-candidate.json"
else
  if [[ "$CHECKOUT_MATCHES_REF" -eq 1 ]]; then
    REF_NOTE="checkout matches"
  else
    REF_NOTE="checkout HEAD is $HEAD_BEHIND_REF commit(s) behind the evaluated ref — probes read the ref, not your checkout"
  fi
  emit "swarm-preflight · $MODE · slug=$SLUG"
  emit "  target-root : $TARGET_ROOT ($BRANCH @ ${COMMIT:0:9})"
  emit "  branch      : suggested=$SUGGESTED_BRANCH branch_ready=$([[ "$BRANCH_READY" -eq 1 ]] && echo true || echo false) skip_branch_prompt=$([[ "$SKIP_BRANCH_PROMPT" -eq 1 ]] && echo true || echo false)"
  emit "  freshness   : fetch_ok=$FETCH_OK upstream=${UPSTREAM:-none} ahead=$AHEAD behind=$BEHIND dirty=$DIRTY"
  emit "  ref-probed  : $REF @ ${REF_COMMIT:0:9} ($REF_NOTE)"
  emit "  candidate   : $CAND_STATE"
  emit "  readiness   : ready=$READY${READY_NEXT:+ — next: $READY_NEXT}"
  emit "  lane-cli    : ${GH39_LANE_NOTE:-unknown} (advisory)"
  emit "  verdict     : $VERDICT (exit $CODE)"
fi

if [[ "$CODE" -ne 0 ]]; then
  [[ "$FORMAT" == "json" ]] || { emit ""; emit "No packet written — candidate is not preflight-ready ($VERDICT)."; }
  exit "$CODE"
fi

# GH-30 Phase 2: resolve the packet output dir ONCE (honors XYZ_ARCHIVE_ROOT), so the dry-run preview
# and the real emit agree. An explicit --out (OUT_DIR set) wins and skips the resolver entirely, so an
# invalid XYZ_ARCHIVE_ROOT can't override a named --out. Resolver hard-errors loudly on set-but-invalid.
if [[ -z "$OUT_DIR" ]]; then
  _sp_ts_base="$(rtl_transcript_root "$ROOT")" || exit 1
  OUT_DIR="$_sp_ts_base/preflight/$TODAY/$SLUG"
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  [[ "$FORMAT" == "json" ]] || {
    emit ""; emit "DRY-RUN: ready, but packet not written. Would emit to: $OUT_DIR"
    emit "Would suggest:"; emit "$INVOCATION"
  }
  exit 0
fi

# ── Phase 6: emit the packet ─────────────────────────────────────────────────
mkdir -p "$OUT_DIR"
cp "$TMP/run-candidate.json" "$OUT_DIR/run-candidate.json"
cp "$TMP/lane-plan.json" "$OUT_DIR/lane-plan.json"
SP_F="$TMP/run-candidate.json" SP_K=freshness node -e 'import("node:fs").then(fs=>process.stdout.write(JSON.stringify(JSON.parse(fs.readFileSync(process.env.SP_F,"utf8"))[process.env.SP_K],null,2)))' >"$OUT_DIR/freshness.json"
SP_F="$TMP/run-candidate.json" SP_K=readiness node -e 'import("node:fs").then(fs=>process.stdout.write(JSON.stringify(JSON.parse(fs.readFileSync(process.env.SP_F,"utf8"))[process.env.SP_K],null,2)))' >"$OUT_DIR/readiness.json"
printf '%s\n' "$INVOCATION" >"$OUT_DIR/marathon-invocation.txt"

# GH-39 B6 + #43-1: bake a SCOPE-LOCKED brief so the builder beelines (no doc-chasing, no wander) and
# size the turn budget to the artifacts. Acceptance criteria are inlined from the capture doc's checklist
# so the builder doesn't have to go read it (the thin-brief gap that made GH-36 v1 wander ~38k tokens).
GH39_ACC="$(grep -E '^[[:space:]]*- \[[ xX]\]' "$PRIMARY_DOC" 2>/dev/null | head -25)"
[[ -n "$GH39_ACC" ]] || GH39_ACC="(no '- [ ]' checklist found in $PRIMARY_DOC — add an Acceptance criteria list)"
GH39_ART_LOC=0
IFS=',' read -ra _b6arts <<<"$ART_CSV"
for _b6a in "${_b6arts[@]}"; do
  read -r _b6a <<<"$_b6a"; [[ -z "$_b6a" ]] && continue
  [[ -f "$TARGET_ROOT/$_b6a" ]] && GH39_ART_LOC=$((GH39_ART_LOC + $(wc -l <"$TARGET_ROOT/$_b6a" 2>/dev/null || echo 0)))
done
# GH-51 [4]: the old single >400-LOC step left mid-size, multi-file builds (e.g. GH-37: 335 LOC across
# 4 shims+tests) on the 300s default — below the note's own warning — and the builder was killed
# mid-turn. Scale by BOTH size and artifact count (each extra file adds build+verify coordination cost).
GH39_ART_N="${#_b6arts[@]}"
GH39_TIMEOUT=300
{ [[ "$GH39_ART_LOC" -gt 200 ]] || [[ "$GH39_ART_N" -ge 3 ]]; } && GH39_TIMEOUT=600
{ [[ "$GH39_ART_LOC" -gt 400 ]] || [[ "$GH39_ART_N" -ge 4 ]]; } && GH39_TIMEOUT=900
GH55_AUTO_CSV="$GH55_INFERRED_TESTS_CSV"
[[ -n "$GH55_INFERRED_HELPERS_CSV" ]] && GH55_AUTO_CSV="${GH55_AUTO_CSV}${GH55_AUTO_CSV:+,}$GH55_INFERRED_HELPERS_CSV"
GH55_AUTO_LINE=""
[[ -n "$GH55_AUTO_CSV" ]] && GH55_AUTO_LINE="- Auto-included covering tests/helpers: $GH55_AUTO_CSV"
if [[ -n "$FS_TOUCHING_TESTS_CSV" ]]; then
  GH54_VERIFY_RULE="- Do NOT run ANY test or gate yourself — not \`$GATE_CMD\`, and NOT \`$FS_TOUCHING_TESTS_CSV\` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree."
else
  GH54_VERIFY_RULE="- Do NOT run the full gate (\`$GATE_CMD\`) yourself — it can create files that trip containment and discard your turn. Verify with ONLY the specific test for the file(s) you changed; the harness runs the gate after your turn."
fi

cat >"$OUT_DIR/packet.md" <<EOF
# Marathon preflight packet — $SLUG

- Generated: $NOW
- Mode: $MODE
- Sources: $(printf '%s ' "${SOURCE_DOCS[@]}")
- Target root: $TARGET_ROOT ($BRANCH @ ${COMMIT:0:9})
- Suggested branch: \`$SUGGESTED_BRANCH\` (branch_ready=$([[ "$BRANCH_READY" -eq 1 ]] && echo true || echo false)$([[ "$BRANCH_READY" -eq 0 && "$SKIP_BRANCH_PROMPT" -eq 0 ]] && echo " — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8")$([[ "$SKIP_BRANCH_PROMPT" -eq 1 ]] && echo " — carve-out: risk=1/independent zone, proceed on the current branch without asking"))
- Verdict: $VERDICT
- Gate: \`$GATE_CMD\`
- Artifacts: $ART_CSV
$GH55_AUTO_LINE
- Suggested turn budget: \`RELAY_TURN_TIMEOUT_S=$GH39_TIMEOUT\` (sized to ≈ $GH39_ART_LOC LOC across $GH39_ART_N artifact(s); a build that also edits tests needs headroom over the 300s default)

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold (inlined from the capture doc)
$GH39_ACC

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: \`$ART_CSV\` (plus the relay file). Any other edit is reverted and FAILS the turn.
$GH54_VERIFY_RULE
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

\`\`\`bash
$INVOCATION
\`\`\`

## Files in this packet
- \`run-candidate.json\` — normalized run candidate (provenance + contract + checks)
- \`freshness.json\` — branch state + fix-still-required probes
- \`readiness.json\` — remediation readiness verdict
- \`lane-plan.json\` — Codex / agy / orchestrator lane assignment
- \`marathon-invocation.txt\` — the invocation hint above
EOF

# In --format json mode, stdout must hold only the JSON object — route the status to stderr.
if [[ "$FORMAT" == json ]]; then
  log "packet written: $OUT_DIR"
else
  emit ""; emit "Packet written: $OUT_DIR"
fi
exit 0
