#!/usr/bin/env bash
# test/swarm-preflight.sh — regression lock for utils/swarm-preflight.sh (GH-25).
#
# Standalone (does not source _setup.sh; the planner needs no tick/relay harness).
# Builds throwaway git repos with preflight contracts and asserts the verdict + exit
# code for the happy path and every failure mode: stale, not-ready, blocked, ambiguous,
# contract-missing, missing GH capture, plus dry-run and the JSON shape parity check.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SP="$ROOT/utils/swarm-preflight.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/swarm-preflight.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }

echo "== test: swarm-preflight =="
echo "  workdir: $WORK"

# Pin time so provenance is deterministic; never call the real clock in tests.
export SWARM_PREFLIGHT_NOW="2026-06-25T00:00:00Z" SWARM_PREFLIGHT_TODAY="2026-06-25"

# make_repo <name> <contract-json> [extra-doc-body] → echoes the repo root
make_repo() {
  local name="$1" contract="$2" extra="${3:-}"
  local r="$WORK/$name"
  mkdir -p "$r/PROJECT/2-WORKING"
  {
    printf -- '---\ntitle: %s\n---\n# %s\n%s\n## Swarm Preflight Contract\n```json\n%s\n```\n' \
      "$name" "$name" "$extra" "$contract"
  } >"$r/PROJECT/2-WORKING/GH-900-$name.md"
  # GH-39 (A2): seed the artifact paths the fixtures declare so a happy-path candidate's artifacts[]
  # actually exist at the ref (preflight now blocks missing artifact paths). Covers src/a.js,
  # test/a.test.js, and the single-letter fixtures a/b. Extra files are harmless (only declared
  # artifacts are checked; no fix_probe in these fixtures targets these paths).
  mkdir -p "$r/src" "$r/test"
  : >"$r/src/a.js"; : >"$r/test/a.test.js"; : >"$r/a"; : >"$r/b"
  git -C "$r" init -q -b main 2>/dev/null || { git -C "$r" init -q; git -C "$r" symbolic-ref HEAD refs/heads/main; }
  git -C "$r" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
  git -C "$r" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
  printf '%s' "$r"
}

run() { SWARM_PREFLIGHT_ROOT="$1" bash "$SP" --target-root "$1" "${@:2}"; }

DOC="PROJECT/2-WORKING/GH-900"   # glob prefix used below via the actual filename

# ── T1: happy path → ready, exit 0, packet emitted ───────────────────────────
R="$(make_repo happy '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
  "artifacts": [ "src/a.js", "test/a.test.js" ],
  "remediation": { "source": "self#phases", "criteria": "Phase 1" }
}' '## Phase 1
- [ ] build it')"
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-happy.md" --out "$R/packet" 2>&1)"; rc=$?
[[ $rc -eq 0 ]] && pass "T1 happy path exit 0" || fail "T1 expected exit 0, got $rc — $out"
grep -q "verdict     : ready" <<<"$out" && pass "T1 verdict ready" || fail "T1 verdict not ready: $out"
[[ -f "$R/packet/run-candidate.json" && -f "$R/packet/lane-plan.json" && -f "$R/packet/packet.md" \
   && -f "$R/packet/freshness.json" && -f "$R/packet/readiness.json" && -f "$R/packet/marathon-invocation.txt" ]] \
  && pass "T1 packet is self-contained (6 files)" || fail "T1 packet incomplete: $(ls "$R/packet" 2>&1)"
node -e 'JSON.parse(require("fs").readFileSync(process.argv[1]))' "$R/packet/run-candidate.json" \
  && pass "T1 run-candidate.json is valid JSON" || fail "T1 run-candidate.json invalid JSON"
# GH-39 B6 + #43-1: the packet bakes a scope-locked brief — inlined acceptance criteria, an explicit
# scope-lock (incl. "don't run the full gate"), and a size-based turn-budget recommendation.
grep -q "Scope lock" "$R/packet/packet.md" && pass "T1b packet has a scope-lock block" || fail "T1b packet missing scope-lock"
grep -q "do not run the full gate\|Do NOT run the full gate" "$R/packet/packet.md" && pass "T1b scope-lock forbids self-running the gate" || fail "T1b scope-lock missing no-gate rule"
grep -q "build it" "$R/packet/packet.md" && pass "T1b acceptance criteria inlined from the capture doc" || fail "T1b acceptance not inlined"
grep -q "RELAY_TURN_TIMEOUT_S=" "$R/packet/packet.md" && pass "T1b packet recommends a turn budget" || fail "T1b missing turn-budget recommendation"
# GH-51 [1]: a SAME-REPO lane (root==target, as T1 is) must NOT emit --target-root — it routes relay-file
# path normalization through the cross-repo code path, flagging the legitimately edited relay file as
# off-lane (exit 6) and discarding the build (the GH-37 dogfood's root-cause blocker).
grep -q -- '--target-root' "$R/packet/marathon-invocation.txt" \
  && fail "T1c same-repo invocation must OMIT --target-root (GH-51 off-lane fix)" \
  || pass "T1c same-repo invocation omits --target-root (GH-51 off-lane fix)"
# GH-51 [4]: the small happy fixture (2 artifacts, 0 LOC) keeps the 300s default budget.
grep -q "RELAY_TURN_TIMEOUT_S=300" "$R/packet/packet.md" \
  && pass "T1d small build keeps the 300s budget" || fail "T1d expected 300s budget for the small fixture: $(grep RELAY_TURN_TIMEOUT_S "$R/packet/packet.md")"

# ── T16 (GH-51 [1]+[4]): foreign target emits --target-root; 4-artifact build scales budget to 900s ──
R16="$(make_repo budgetscale '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
  "artifacts": [ "src/a.js", "test/a.test.js", "a", "b" ],
  "remediation": { "source": "self#phases", "criteria": "Phase 1" }
}' '## Phase 1
- [ ] build it')"
out="$(run "$R16" --project-doc "PROJECT/2-WORKING/GH-900-budgetscale.md" --out "$R16/packet" 2>&1)"; rc=$?
grep -q "RELAY_TURN_TIMEOUT_S=900" "$R16/packet/packet.md" \
  && pass "T16 GH-51[4]: 4-artifact build scales the budget to 900s" \
  || fail "T16 expected 900s budget for 4 artifacts: $(grep RELAY_TURN_TIMEOUT_S "$R16/packet/packet.md")"
# Foreign target (root != target) MUST still emit --target-root (cross-repo build needs it).
fout="$(SWARM_PREFLIGHT_ROOT="$ROOT" bash "$SP" --target-root "$R16" --project-doc "$R16/PROJECT/2-WORKING/GH-900-budgetscale.md" --out "$R16/packet-foreign" 2>&1)"; frc=$?
if [[ -f "$R16/packet-foreign/marathon-invocation.txt" ]]; then
  # emitted path is the symlink-resolved git toplevel, so assert flag PRESENCE (not the raw $R16 path).
  grep -q -- '--target-root ' "$R16/packet-foreign/marathon-invocation.txt" \
    && pass "T16b foreign target emits --target-root <repo>" \
    || fail "T16b foreign target must emit --target-root: $(cat "$R16/packet-foreign/marathon-invocation.txt")"
else
  fail "T16b foreign-target packet not written (rc=$frc): $fout"
fi

# ── T2: stale (fix already landed) → exit 4, no packet ───────────────────────
R="$(make_repo stale '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "PROJECT/2-WORKING/GH-900-stale.md" } ],
  "artifacts": [ "src/a.js" ],
  "remediation": { "criteria": "x" }
}' '## Phase 1')"
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-stale.md" --out "$R/packet" 2>&1)"; rc=$?
[[ $rc -eq 4 ]] && pass "T2 stale → exit 4" || fail "T2 expected exit 4, got $rc — $out"
[[ ! -d "$R/packet" ]] && pass "T2 no packet written for stale" || fail "T2 packet should not exist"

# ── T3: not-ready (no gate) → exit 5 with one explicit next action ────────────
R="$(make_repo notready '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "",
  "fix_probes": [ { "type": "path_absent", "path": "NEW.txt" } ],
  "artifacts": [ "src/a.js" ],
  "remediation": { "criteria": "x" }
}' '## Phase 1')"
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-notready.md" 2>&1)"; rc=$?
[[ $rc -eq 5 ]] && pass "T3 not-ready → exit 5" || fail "T3 expected exit 5, got $rc — $out"
grep -q "next: add a runnable gate" <<<"$out" && pass "T3 names one concrete next action" || fail "T3 missing next action: $out"

# ── T4: blocked — target not a git repo → exit 6 ─────────────────────────────
out="$(SWARM_PREFLIGHT_ROOT="$WORK" bash "$SP" --project-doc x.md --target-root "$WORK/not-a-repo" 2>&1)"; rc=$?
[[ $rc -eq 6 ]] && pass "T4 non-git target → exit 6" || fail "T4 expected exit 6, got $rc — $out"

# ── T5: blocked — gh-issue with no local capture doc → exit 6 ─────────────────
R="$(make_repo nocap '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "x" } ],
  "artifacts": [ "a" ]
}')"
out="$(run "$R" --gh-issue 4242 2>&1)"; rc=$?
[[ $rc -eq 6 ]] && pass "T5 missing GH capture → exit 6" || fail "T5 expected exit 6, got $rc — $out"
grep -q "GUIDING-PRINCIPLES.md" <<<"$out" && pass "T5 cites the §11 rationale" || fail "T5 missing rationale: $out"

# ── T6: contract missing → exit 3 (fail loud, no guessing) ────────────────────
R="$WORK/nocontract"; mkdir -p "$R/PROJECT/2-WORKING"
printf -- '---\ntitle: x\n---\n# x\nno contract here\n' >"$R/PROJECT/2-WORKING/GH-900-nocontract.md"
git -C "$R" init -q && git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null && git -C "$R" -c user.email=t@t -c user.name=t commit -qm init >/dev/null
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-nocontract.md" 2>&1)"; rc=$?
[[ $rc -eq 3 ]] && pass "T6 missing contract → exit 3" || fail "T6 expected exit 3, got $rc — $out"

# ── T7: ambiguous bundle (gate mismatch across two issues) → exit 7 ──────────
R="$WORK/bundle"; mkdir -p "$R/PROJECT/2-WORKING"
mkcap() { printf -- '---\ntitle: %s\n---\n# %s\n## Swarm Preflight Contract\n```json\n%s\n```\n' "$1" "$1" "$2" >"$R/PROJECT/2-WORKING/GH-$3-$1.md"; }
mkcap one '{ "target": { "repo": ".", "ref": "main" }, "gate": "true", "fix_probes": [ { "type": "path_absent", "path": "a" } ], "artifacts": [ "a" ] }' 11
mkcap two '{ "target": { "repo": ".", "ref": "main" }, "gate": "false", "fix_probes": [ { "type": "path_absent", "path": "b" } ], "artifacts": [ "b" ] }' 12
git -C "$R" init -q && git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null && git -C "$R" -c user.email=t@t -c user.name=t commit -qm init >/dev/null
out="$(run "$R" --gh-issue 11 --gh-issue 12 2>&1)"; rc=$?
[[ $rc -eq 7 ]] && pass "T7 disagreeing bundle → exit 7" || fail "T7 expected exit 7, got $rc — $out"

# ── T8: dry-run on a ready candidate → exit 0, NO packet ─────────────────────
R="$(make_repo dryrun '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW.txt" } ],
  "artifacts": [ "src/a.js" ],
  "remediation": { "criteria": "x" }
}' '## Phase 1')"
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-dryrun.md" --out "$R/packet" --dry-run 2>&1)"; rc=$?
[[ $rc -eq 0 ]] && pass "T8 dry-run exit 0" || fail "T8 expected exit 0, got $rc — $out"
[[ ! -d "$R/packet" ]] && pass "T8 dry-run writes no packet" || fail "T8 dry-run must not write packet"

# ── T9: project-doc and gh-bundle normalize to the same shape (keys parity) ──
R="$(make_repo parity '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW.txt" } ],
  "artifacts": [ "src/a.js" ],
  "remediation": { "criteria": "x" }
}' '## Phase 1')"
# rename so the same doc is reachable as GH-55 capture for the bundle path
cp "$R/PROJECT/2-WORKING/GH-900-parity.md" "$R/PROJECT/2-WORKING/GH-55-parity.md"
git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null && git -C "$R" -c user.email=t@t -c user.name=t commit -qm add >/dev/null
pj="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-parity.md" --format json 2>/dev/null)"
gj="$(run "$R" --gh-issue 55 --format json 2>/dev/null)"
kp="$(node -e 'const o=JSON.parse(require("fs").readFileSync(0,"utf8"));process.stdout.write(Object.keys(o).concat(Object.keys(o.freshness)).sort().join(","))' <<<"$pj")"
kg="$(node -e 'const o=JSON.parse(require("fs").readFileSync(0,"utf8"));process.stdout.write(Object.keys(o).concat(Object.keys(o.freshness)).sort().join(","))' <<<"$gj")"
[[ -n "$kp" && "$kp" == "$kg" ]] && pass "T9 both modes produce structurally identical shape" || fail "T9 shape mismatch: [$kp] vs [$kg]"

# ── T10: usage errors → exit 2 ───────────────────────────────────────────────
bash "$SP" >/dev/null 2>&1; [[ $? -eq 2 ]] && pass "T10a no input mode → exit 2" || fail "T10a expected exit 2"
bash "$SP" --project-doc x --gh-issue 1 >/dev/null 2>&1; [[ $? -eq 2 ]] && pass "T10b mutually exclusive → exit 2" || fail "T10b expected exit 2"

# ── T11: ref-honoring — a fix landed on a NON-checked-out ref is detected ─────
# Regression lock for the starvation trap (the bug this fix closes): probes MUST evaluate
# target.ref, not the current checkout. Build a repo on main WITHOUT the file, add it on
# branch `feat`, leave main checked out, and declare ref: feat. Pre-fix this read "ready"
# (absent on the main working tree); post-fix it must read "stale" (present on feat).
R="$(make_repo reffix '{
  "target": { "repo": ".", "ref": "feat" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "LANDED_ON_FEAT.txt" } ],
  "artifacts": [ "src/a.js" ],
  "remediation": { "criteria": "x" }
}' '## Phase 1')"
git -C "$R" -c user.email=t@t -c user.name=t checkout -q -b feat
echo x >"$R/LANDED_ON_FEAT.txt"
git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null && git -C "$R" -c user.email=t@t -c user.name=t commit -qm landed >/dev/null
git -C "$R" -c user.email=t@t -c user.name=t checkout -q main   # STALE checkout: main lacks the file feat has
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-reffix.md" 2>&1)"; rc=$?
[[ $rc -eq 4 ]] && pass "T11 ref-honoring: fix on non-checked-out ref → stale (exit 4)" || fail "T11 expected exit 4 (probe must read target.ref=feat, not main), got $rc — $out"
grep -q "behind the evaluated ref" <<<"$out" && pass "T11 report surfaces stale checkout vs evaluated ref" || fail "T11 missing staleness signal: $out"

# ── T12: unresolvable target.ref → blocked, exit 6 (fail loud, not blind) ─────
R="$(make_repo badref '{
  "target": { "repo": ".", "ref": "origin/does-not-exist" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW.txt" } ],
  "artifacts": [ "src/a.js" ],
  "remediation": { "criteria": "x" }
}' '## Phase 1')"
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-badref.md" 2>&1)"; rc=$?
[[ $rc -eq 6 ]] && pass "T12 unresolvable target.ref → exit 6" || fail "T12 expected exit 6, got $rc — $out"
grep -q "does not resolve" <<<"$out" && pass "T12 names the unresolvable ref" || fail "T12 missing message: $out"

# ── T13: GH-39 (A2) — a declared artifact path that doesn't exist at the ref → not-ready (exit 5) ──
R="$(make_repo artmiss '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEVER.txt" } ],
  "artifacts": [ "src/does-not-exist.js" ],
  "remediation": { "criteria": "x" }
}' '## Phase 1')"
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-artmiss.md" 2>&1)"; rc=$?
[[ $rc -eq 5 ]] && pass "T13 GH-39: missing artifact path → not-ready (exit 5)" || fail "T13 expected exit 5, got $rc — $out"
grep -q "artifact path not found" <<<"$out" && pass "T13 names the missing artifact path" || fail "T13 missing message: $out"

# ── T14: GH-39 (A1) — a `bash <script>` gate whose script doesn't exist → not-ready (exit 5) ──
R="$(make_repo gatemiss '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash no-such-gate.sh",
  "fix_probes": [ { "type": "path_absent", "path": "NEVER.txt" } ],
  "artifacts": [ "src/a.js" ],
  "remediation": { "criteria": "x" }
}' '## Phase 1')"
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-gatemiss.md" 2>&1)"; rc=$?
[[ $rc -eq 5 ]] && pass "T14 GH-39: unrunnable gate (missing script) → not-ready (exit 5)" || fail "T14 expected exit 5, got $rc — $out"
grep -q "gate script not found" <<<"$out" && pass "T14 names the missing gate script" || fail "T14 missing message: $out"

# ── T15: GH-39 (A1) — a gate WITH FLAGS (`bash -x <script>`) resolves the SCRIPT, not the flag ──
R="$(make_repo gateflag '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash -x src/a.js",
  "fix_probes": [ { "type": "path_absent", "path": "NEVER.txt" } ],
  "artifacts": [ "src/a.js" ],
  "remediation": { "criteria": "x" }
}' '## Phase 1')"
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-gateflag.md" 2>&1)"; rc=$?
[[ $rc -eq 0 ]] && pass "T15 GH-39: gate with flags resolves the script, not the flag (ready)" || fail "T15 expected exit 0, got $rc — $out"

# make_repo_risk <name> <risk> <contract-json> [extra-doc-body] → echoes the repo root
# Same as make_repo but injects a `risk:` frontmatter field (GH-69 carve-out reads this).
make_repo_risk() {
  local name="$1" risk="$2" contract="$3" extra="${4:-}"
  local r="$WORK/$name"
  mkdir -p "$r/PROJECT/2-WORKING"
  {
    printf -- '---\ntitle: %s\nrisk: %s\n---\n# %s\n%s\n## Swarm Preflight Contract\n```json\n%s\n```\n' \
      "$name" "$risk" "$name" "$extra" "$contract"
  } >"$r/PROJECT/2-WORKING/GH-900-$name.md"
  mkdir -p "$r/src" "$r/test" "$r/relay-automation" "$r/bin"
  : >"$r/src/a.js"; : >"$r/test/a.test.js"; : >"$r/a"; : >"$r/b"
  : >"$r/relay-automation/relay-turn-lib.sh"; : >"$r/bin/tick"; : >"$r/relay-automation/relay-drive.sh"
  git -C "$r" init -q -b main 2>/dev/null || { git -C "$r" init -q; git -C "$r" symbolic-ref HEAD refs/heads/main; }
  git -C "$r" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
  git -C "$r" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
  printf '%s' "$r"
}

# ── T17 (GH-69): branch_ready reflects real branch existence; suggested_branch is slug+date ──
R="$(make_repo_risk branchready 2 '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
  "artifacts": [ "src/a.js" ],
  "remediation": { "criteria": "x" }
}')"
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-branchready.md" --out "$R/packet" 2>&1)"
grep -q "suggested=marathon/gh-900-branchready-2026-06-25" <<<"$out" \
  && pass "T17a suggested_branch is slug+run-date" || fail "T17a wrong suggested_branch: $out"
grep -q "branch_ready=false" <<<"$out" \
  && pass "T17b branch_ready=false when the branch doesn't exist yet" || fail "T17b: $out"
node -e 'const j=JSON.parse(require("fs").readFileSync(process.argv[1]));process.exit(j.provenance.suggested_branch==="marathon/gh-900-branchready-2026-06-25"&&j.provenance.branch_ready===false?0:1)' \
  "$R/packet/run-candidate.json" \
  && pass "T17c run-candidate.json.provenance carries suggested_branch + branch_ready=false" \
  || fail "T17c packet JSON shape wrong: $(cat "$R/packet/run-candidate.json")"
grep -q "ask the operator before proceeding" "$R/packet/packet.md" \
  && pass "T17d packet.md tells the orchestrator to ask before proceeding" || fail "T17d missing ask-operator note"

# Now actually cut the suggested branch and re-run — branch_ready must flip to true.
git -C "$R" branch marathon/gh-900-branchready-2026-06-25 >/dev/null 2>&1
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-branchready.md" --out "$R/packet2" 2>&1)"
grep -q "branch_ready=true" <<<"$out" \
  && pass "T17e branch_ready=true once the suggested branch exists" || fail "T17e: $out"

# ── T18 (GH-69): skip_branch_prompt carve-out — risk=1 + independent zone ──
R="$(make_repo_risk lowrisk 1 '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
  "artifacts": [ "src/a.js" ],
  "remediation": { "criteria": "x" }
}')"
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-lowrisk.md" --out "$R/packet" 2>&1)"
grep -q "skip_branch_prompt=true" <<<"$out" \
  && pass "T18a risk=1 + independent artifacts → skip_branch_prompt=true" || fail "T18a: $out"
grep -q "carve-out: risk=1/independent zone" "$R/packet/packet.md" \
  && pass "T18b packet.md documents the carve-out instead of the ask-operator note" || fail "T18b: $(cat "$R/packet/packet.md" | grep 'Suggested branch')"

# ── T19 (GH-69): carve-out does NOT apply when risk != 1 ──
R="$(make_repo_risk midrisk 2 '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
  "artifacts": [ "src/a.js" ],
  "remediation": { "criteria": "x" }
}')"
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-midrisk.md" 2>&1)"
grep -q "skip_branch_prompt=false" <<<"$out" \
  && pass "T19a risk=2 → skip_branch_prompt=false (carve-out needs risk==1)" || fail "T19a: $out"

# ── T20 (GH-69): carve-out does NOT apply when the zone is kernel, even at risk=1 ──
R="$(make_repo_risk kernelrisk1 1 '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
  "artifacts": [ "bin/tick" ],
  "remediation": { "criteria": "x" }
}')"
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-kernelrisk1.md" 2>&1)"
grep -q "skip_branch_prompt=false" <<<"$out" \
  && pass "T20a risk=1 but kernel-zone artifact → skip_branch_prompt=false" || fail "T20a: $out"

# ── T21 (GH-69, agy relay QA [Should]): kernel-path match is a PREFIX match, mirroring
# marathon-plan.sh's `a === k || a.startsWith(k)` — a kernel-ADJACENT artifact (bin/tick+helper.sh,
# which startsWith "bin/tick" but isn't an exact match) must still classify as kernel, not
# independent, or the two planners disagree and the carve-out wrongly fires on a kernel-adjacent lane.
R="$(make_repo_risk kernelprefix 1 '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
  "artifacts": [ "bin/tick+helper.sh" ],
  "remediation": { "criteria": "x" }
}')"
: >"$R/bin/tick+helper.sh"
git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$R" -c user.email=t@t -c user.name=t commit -qm "add tick-helper" >/dev/null 2>&1
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-kernelprefix.md" 2>&1)"
grep -q "skip_branch_prompt=false" <<<"$out" \
  && pass "T21a risk=1 but kernel-ADJACENT artifact (bin/tick+helper.sh) → skip_branch_prompt=false" \
  || fail "T21a: $out"

# ── T22 (GH-69, agy relay QA [Nit]): shim match is case-INSENSITIVE, mirroring SHIM_RE's `/i` — a
# differently-cased shim path must still classify as shim (not independent), same as marathon-plan.sh.
R="$(make_repo_risk shimcase 1 '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
  "artifacts": [ "relay-automation/Codex-turn.sh" ],
  "remediation": { "criteria": "x" }
}')"
: >"$R/relay-automation/Codex-turn.sh"
git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$R" -c user.email=t@t -c user.name=t commit -qm "add Codex-turn.sh" >/dev/null 2>&1
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-shimcase.md" 2>&1)"
grep -q "skip_branch_prompt=false" <<<"$out" \
  && pass "T22a differently-cased shim path (Codex-turn.sh) still classifies as shim, not independent" \
  || fail "T22a: $out"

echo ""
echo "  swarm-preflight: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] || exit 1
