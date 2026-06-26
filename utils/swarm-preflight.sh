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

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${SWARM_PREFLIGHT_ROOT:-"$(cd "$HERE/.." && pwd)"}"
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
  for (const a of (c.lanes || {}).agy_safe || []) if (!out.lanes.agy_safe.includes(a)) out.lanes.agy_safe.push(a);
  for (const a of (c.lanes || {}).orchestrator_only || []) if (!out.lanes.orchestrator_only.includes(a)) out.lanes.orchestrator_only.push(a);
}
process.stdout.write(JSON.stringify(out));
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

cat >"$TMP/lane-plan.mjs" <<'JS'
import { readFileSync } from "node:fs";
const c = JSON.parse(readFileSync(process.env.SP_CONTRACT, "utf8"));
const arts = c.artifacts || [];
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
  },
  contract,
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

# ── slug + provenance (Phase 2) ──────────────────────────────────────────────
PRIMARY_DOC="${SOURCE_DOCS[0]}"
SLUG="$(basename "$PRIMARY_DOC" .md | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed 's/--*/-/g; s/^-//; s/-$//')"
[[ -n "$SLUG" ]] || SLUG="preflight"
BRANCH="$(git -C "$TARGET_ROOT" symbolic-ref --quiet --short HEAD 2>/dev/null || echo "(detached)")"
COMMIT="$(git -C "$TARGET_ROOT" rev-parse HEAD 2>/dev/null || echo "(none)")"

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
ART_CSV="$(field "$TMP/contract.json" artifacts)"
ART_COUNT=0; [[ -n "$ART_CSV" ]] && ART_COUNT="$(awk -F, '{print NF}' <<<"$ART_CSV")"
REMED_SRC="$(field "$TMP/contract.json" remediation.source)"
REMED_CRIT="$(field "$TMP/contract.json" remediation.criteria)"
DOC_HAS_PHASES=0
grep -Eq '^##+ .*[Pp]hase|^- \[[ xX]\]' "$PRIMARY_DOC" 2>/dev/null && DOC_HAS_PHASES=1

if [[ -z "$GATE_CMD" ]];     then READY=0; READY_NEXT="add a runnable gate command to the contract"; fi
if [[ "$ART_COUNT" -eq 0 ]]; then READY=0; READY_NEXT="add a bounded artifact / ALLOW_PATHS set to the contract"; fi
if [[ -z "$REMED_SRC$REMED_CRIT" && "$DOC_HAS_PHASES" -eq 0 ]]; then
  READY=0; READY_NEXT="research more: no phase plan or acceptance criteria — source is not runnable unattended"
fi

# ── Phase 5: lane assignment ─────────────────────────────────────────────────
SP_CONTRACT="$TMP/contract.json" node "$TMP/lane-plan.mjs" >"$TMP/lane-plan.json"

# ── assemble the normalized run-candidate object (Phase 2 output shape) ───────
ISSUES_CSV="$(IFS=,; printf '%s' "${SOURCE_ISSUES[*]:-}")"
printf '%s\n' "${SOURCE_DOCS[@]}" >"$TMP/docs.txt"
SP_CONTRACT="$TMP/contract.json" SP_PROBES="$TMP/probes.json" SP_LANES="$TMP/lane-plan.json" \
  SP_DOCS="$(cat "$TMP/docs.txt")" SP_ISSUES="$ISSUES_CSV" SP_MODE="$MODE" SP_SLUG="$SLUG" \
  SP_BRANCH="$BRANCH" SP_COMMIT="$COMMIT" SP_ROOT="$TARGET_ROOT" SP_NOW="$NOW" SP_STATE="$CAND_STATE" \
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

REL_TARGET="$TARGET_ROOT"; [[ "$TARGET_ROOT" == "$ROOT" ]] && REL_TARGET="."
INVOCATION="relay-automation/marathon-drive.sh \\
  --phase-brief <packet>/packet.md \\
  --reviewer agy \\
  --builder codex \\
  --artifact $ART_CSV \\
  --target-root $REL_TARGET \\
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
  emit "  freshness   : fetch_ok=$FETCH_OK upstream=${UPSTREAM:-none} ahead=$AHEAD behind=$BEHIND dirty=$DIRTY"
  emit "  ref-probed  : $REF @ ${REF_COMMIT:0:9} ($REF_NOTE)"
  emit "  candidate   : $CAND_STATE"
  emit "  readiness   : ready=$READY${READY_NEXT:+ — next: $READY_NEXT}"
  emit "  verdict     : $VERDICT (exit $CODE)"
fi

if [[ "$CODE" -ne 0 ]]; then
  [[ "$FORMAT" == "json" ]] || { emit ""; emit "No packet written — candidate is not preflight-ready ($VERDICT)."; }
  exit "$CODE"
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  [[ "$FORMAT" == "json" ]] || {
    emit ""; emit "DRY-RUN: ready, but packet not written. Would emit to: ${OUT_DIR:-relay-system/preflight/$TODAY/$SLUG}"
    emit "Would suggest:"; emit "$INVOCATION"
  }
  exit 0
fi

# ── Phase 6: emit the packet ─────────────────────────────────────────────────
OUT_DIR="${OUT_DIR:-"$ROOT/relay-system/preflight/$TODAY/$SLUG"}"
mkdir -p "$OUT_DIR"
cp "$TMP/run-candidate.json" "$OUT_DIR/run-candidate.json"
cp "$TMP/lane-plan.json" "$OUT_DIR/lane-plan.json"
SP_F="$TMP/run-candidate.json" SP_K=freshness node -e 'import("node:fs").then(fs=>process.stdout.write(JSON.stringify(JSON.parse(fs.readFileSync(process.env.SP_F,"utf8"))[process.env.SP_K],null,2)))' >"$OUT_DIR/freshness.json"
SP_F="$TMP/run-candidate.json" SP_K=readiness node -e 'import("node:fs").then(fs=>process.stdout.write(JSON.stringify(JSON.parse(fs.readFileSync(process.env.SP_F,"utf8"))[process.env.SP_K],null,2)))' >"$OUT_DIR/readiness.json"
printf '%s\n' "$INVOCATION" >"$OUT_DIR/marathon-invocation.txt"

cat >"$OUT_DIR/packet.md" <<EOF
# Marathon preflight packet — $SLUG

- Generated: $NOW
- Mode: $MODE
- Sources: $(printf '%s ' "${SOURCE_DOCS[@]}")
- Target root: $TARGET_ROOT ($BRANCH @ ${COMMIT:0:9})
- Verdict: $VERDICT
- Gate: \`$GATE_CMD\`
- Artifacts: $ART_CSV

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

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
