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
# GH-75: the generated invocation self-propagates the swarm harness tag — the operator runs it verbatim
# and the marathon-drive run records harness:"swarm" (not "marathon") in XYZ.json, no extra step.
head -1 "$R/packet/marathon-invocation.txt" | grep -q '^XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=[^ ]* relay-automation/marathon-drive.sh' \
  && pass "T1 marathon-invocation.txt carries XYZ_HARNESS_CONTEXT=swarm + per-run XYZ_SESSION_ID (GH-75)" \
  || fail "T1 invocation missing swarm tag / session id: $(head -1 "$R/packet/marathon-invocation.txt")"
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

# ── T8b/T8c/T8d: GH-30 Phase 2 — dry-run "Would emit to" follows the transcript-root resolver ──
# Unset XYZ_ARCHIVE_ROOT → byte-for-byte the old "$ROOT/relay-system/preflight/…" path.
out8b="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-dryrun.md" --dry-run 2>&1)"
grep -q "Would emit to: $R/relay-system/preflight/" <<<"$out8b" \
  && pass "T8b dry-run, XYZ_ARCHIVE_ROOT unset → \$ROOT/relay-system/preflight/ (regression-safe)" \
  || fail "T8b expected \$R/relay-system/preflight/, got: $(grep 'Would emit' <<<"$out8b")"
# Set XYZ_ARCHIVE_ROOT (a git repo, Model A) → namespaced $archive/relay-system/<repo-slug>/preflight/.
# Fixture repo has no origin remote, so <repo-slug> falls back to its dir basename "dryrun".
ARCH="$WORK/sp-archive"; git init -q "$ARCH"
out8c="$(XYZ_ARCHIVE_ROOT="$ARCH" run "$R" --project-doc "PROJECT/2-WORKING/GH-900-dryrun.md" --dry-run 2>&1)"
grep -q "Would emit to: $ARCH/relay-system/dryrun/preflight/" <<<"$out8c" \
  && pass "T8c dry-run, XYZ_ARCHIVE_ROOT set → \$archive/relay-system/<slug>/preflight/ (namespaced)" \
  || fail "T8c expected \$ARCH/relay-system/dryrun/preflight/, got: $(grep 'Would emit' <<<"$out8c")"
# Explicit --out wins over BOTH the default and the archive redirect.
out8d="$(XYZ_ARCHIVE_ROOT="$ARCH" run "$R" --project-doc "PROJECT/2-WORKING/GH-900-dryrun.md" --out "$R/named" --dry-run 2>&1)"
grep -q "Would emit to: $R/named" <<<"$out8d" \
  && pass "T8d explicit --out wins over the resolver/archive default" \
  || fail "T8d expected \$R/named, got: $(grep 'Would emit' <<<"$out8d")"
# T8e: set-but-invalid XYZ_ARCHIVE_ROOT (no --out) → hard fail, no packet (fail-loud, no silent fallback).
# swarm runs `set -uo` (NO -e), so this proves the explicit `|| exit 1` catches the resolver failure.
out8e="$(XYZ_ARCHIVE_ROOT="$WORK/nope-not-a-dir" run "$R" --project-doc "PROJECT/2-WORKING/GH-900-dryrun.md" 2>&1)"; rc8e=$?
[[ $rc8e -ne 0 ]] && pass "T8e invalid XYZ_ARCHIVE_ROOT → hard fail (rc=$rc8e)" || fail "T8e expected non-zero, got 0 — $out8e"
[[ ! -d "$R/relay-system" ]] && pass "T8e no packet leaked into \$ROOT on invalid archive" || fail "T8e leaked a packet into \$R/relay-system"

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

# ── T23 (GH-69, agy relay QA r2 [Nit]): a NESTED subdirectory under relay-automation/ must NOT
# classify as shim — bash case globs match `/` (unlike marathon-plan.sh's SHIM_RE, whose
# [a-z0-9-]+ class can't cross a path separator), so relay-automation/subdir/foo+turn.sh must be
# independent, not shim. At risk=1 that makes it independent-zone → skip_branch_prompt=TRUE (the
# opposite of T22, which is a direct, non-nested shim and should NOT skip).
R="$(make_repo_risk shimnested 1 '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
  "artifacts": [ "relay-automation/subdir/foo+turn.sh" ],
  "remediation": { "criteria": "x" }
}')"
mkdir -p "$R/relay-automation/subdir"
: >"$R/relay-automation/subdir/foo+turn.sh"
git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$R" -c user.email=t@t -c user.name=t commit -qm "add nested foo+turn.sh" >/dev/null 2>&1
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-shimnested.md" 2>&1)"
grep -q "skip_branch_prompt=true" <<<"$out" \
  && pass "T23a nested-subdirectory shim-shaped path is independent zone, not shim (risk=1 skips)" \
  || fail "T23a: $out"

# ── T24 (GH-89 baseline): an unmarked new-file artifact still fails GH-39 A2 exactly as before —
# strict-by-default is unchanged. This is the "previously read NOT-READY" half of T25's regression.
R="$(make_repo greenbaseline '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "src/new-thing.js" } ],
  "artifacts": [ "src/new-thing.js" ],
  "remediation": { "criteria": "x" }
}' '## Phase 1')"
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-greenbaseline.md" 2>&1)"; rc=$?
[[ $rc -eq 5 ]] && pass "T24 GH-89 baseline: unmarked new-file artifact still NOT-READY (exit 5) — strict-by-default unchanged" || fail "T24 expected exit 5, got $rc — $out"
grep -q "artifact path not found" <<<"$out" && pass "T24 names the missing artifact path" || fail "T24 missing message: $out"

# ── T25 (GH-89): the SAME contract, plus artifacts_new + a matching fix_probes path_absent entry,
# now reads READY (exit 0) — the whole point of a greenfield lane.
R="$(make_repo greenfield '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "src/new-thing.js" } ],
  "artifacts": [ "src/new-thing.js" ],
  "artifacts_new": [ "src/new-thing.js" ],
  "remediation": { "criteria": "x" }
}' '## Phase 1')"
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-greenfield.md" --out "$R/packet" 2>&1)"; rc=$?
[[ $rc -eq 0 ]] && pass "T25 GH-89: greenfield contract (artifacts_new + matching path_absent probe) reads READY where T24's unmarked twin reads NOT-READY" || fail "T25 expected exit 0, got $rc — $out"
grep -q "verdict     : ready" <<<"$out" && pass "T25 verdict ready" || fail "T25 verdict not ready: $out"
[[ -f "$R/packet/run-candidate.json" ]] && pass "T25 packet written for the greenfield lane" || fail "T25 packet not written: $(ls "$R/packet" 2>&1)"

# ── T26 (GH-89): an artifacts_new entry with NO matching fix_probes path_absent entry on the same
# path is a contract error (exit 3), never a silent pass — the exemption must not become a way to
# dodge the check on a path that should already exist.
R="$(make_repo greennoprobe '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "OTHER_FILE.txt" } ],
  "artifacts": [ "src/new-thing2.js" ],
  "artifacts_new": [ "src/new-thing2.js" ],
  "remediation": { "criteria": "x" }
}' '## Phase 1')"
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-greennoprobe.md" 2>&1)"; rc=$?
[[ $rc -eq 3 ]] && pass "T26 GH-89: artifacts_new entry with no matching path_absent probe → contract error (exit 3)" || fail "T26 expected exit 3, got $rc — $out"
grep -q "no matching fix_probes entry of type path_absent" <<<"$out" && pass "T26 names the pairing violation" || fail "T26 missing message: $out"

# ── T27 (GH-89): an artifacts_new entry that isn't ALSO in artifacts[] is a contract error (exit 3) —
# artifacts_new is a subset marker, not a separate path list.
R="$(make_repo greennotinarts '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "src/stray.js" } ],
  "artifacts": [ "src/a.js" ],
  "artifacts_new": [ "src/stray.js" ],
  "remediation": { "criteria": "x" }
}' '## Phase 1')"
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-greennotinarts.md" 2>&1)"; rc=$?
[[ $rc -eq 3 ]] && pass "T27 GH-89: artifacts_new entry not present in artifacts[] → contract error (exit 3)" || fail "T27 expected exit 3, got $rc — $out"
grep -q 'not present in artifacts\[\]' <<<"$out" && pass "T27 names the subset violation" || fail "T27 missing message: $out"

# ── T28 (GH-89 live regression): a contract shaped like GH-87's actual historical one
# (relay-automation/deep-research.mjs + test/deep-research.sh, a pure new-file build) — extended
# with artifacts_new + the second path_absent probe GH-89 requires — now reads READY. Pre-GH-89 this
# returned NOT-READY (exit 5) purely because the artifacts didn't exist yet.
R="$(make_repo gh87mirror '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [
    { "type": "path_absent", "path": "relay-automation/deep-research.mjs" },
    { "type": "path_absent", "path": "test/deep-research.sh" }
  ],
  "artifacts": [
    "relay-automation/deep-research.mjs",
    "test/deep-research.sh"
  ],
  "artifacts_new": [
    "relay-automation/deep-research.mjs",
    "test/deep-research.sh"
  ],
  "remediation": { "criteria": "x" }
}' '## Phase 1')"
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-gh87mirror.md" --out "$R/packet" 2>&1)"; rc=$?
[[ $rc -eq 0 ]] && pass "T28 GH-89 regression: GH-87-shaped contract (deep-research.mjs) now reads READY" || fail "T28 expected exit 0, got $rc — $out"

# ── T29 (GH-89 live regression): a contract shaped like GH-88's actual historical one (3 marathon
# viewer scripts + test/marathon-monitor.sh, a pure new-file build) — extended with artifacts_new +
# the two additional path_absent probes GH-89 requires — now reads READY.
R="$(make_repo gh88mirror '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [
    { "type": "path_absent", "path": "relay-automation/marathon-ls.sh" },
    { "type": "path_absent", "path": "relay-automation/marathon-detail.sh" },
    { "type": "path_absent", "path": "relay-automation/marathon-tui.sh" },
    { "type": "path_absent", "path": "test/marathon-monitor.sh" }
  ],
  "artifacts": [
    "relay-automation/marathon-ls.sh",
    "relay-automation/marathon-detail.sh",
    "relay-automation/marathon-tui.sh",
    "test/marathon-monitor.sh"
  ],
  "artifacts_new": [
    "relay-automation/marathon-ls.sh",
    "relay-automation/marathon-detail.sh",
    "relay-automation/marathon-tui.sh",
    "test/marathon-monitor.sh"
  ],
  "remediation": { "criteria": "x" }
}' '## Phase 1')"
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-gh88mirror.md" --out "$R/packet" 2>&1)"; rc=$?
[[ $rc -eq 0 ]] && pass "T29 GH-89 regression: GH-88-shaped contract (3 viewer scripts + test) now reads READY" || fail "T29 expected exit 0, got $rc — $out"

# ── T30 (GH-89 bundle merge): artifacts_new declared in ONE bundle doc, its matching fix_probes
# path_absent entry declared in a SIBLING doc of the same --gh-issue bundle. merge-contracts.mjs
# unions both fields across the bundle (same as artifacts/lanes already do), so the pairing check
# (run on the MERGED contract) is satisfied and the bundle reads READY.
R="$WORK/bundle89"; mkdir -p "$R/PROJECT/2-WORKING" "$R/src"
: >"$R/src/a.js"
mkcap bundlenew '{ "target": { "repo": ".", "ref": "main" }, "gate": "true", "fix_probes": [ { "type": "path_absent", "path": "x" } ], "artifacts": [ "src/bundle-new.js" ], "artifacts_new": [ "src/bundle-new.js" ], "remediation": { "criteria": "x" } }' 15
mkcap bundleprobe '{ "target": { "repo": ".", "ref": "main" }, "gate": "true", "fix_probes": [ { "type": "path_absent", "path": "src/bundle-new.js" } ], "artifacts": [ "src/a.js" ] }' 16
git -C "$R" init -q -b main 2>/dev/null || { git -C "$R" init -q; git -C "$R" symbolic-ref HEAD refs/heads/main; }
git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$R" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
out="$(run "$R" --gh-issue 15 --gh-issue 16 --out "$R/packet" 2>&1)"; rc=$?
[[ $rc -eq 0 ]] && pass "T30 GH-89: artifacts_new in one bundle doc + matching path_absent probe in a sibling doc → bundle merge satisfies the pairing, reads READY" || fail "T30 expected exit 0, got $rc — $out"

# ── T31 (GH-55): a declared artifact auto-pulls its explicit covering test and sourced helper into
# the generated builder allowlist / packet, without rewriting the contract itself.
R="$WORK/gh55-covering"; mkdir -p "$R/PROJECT/2-WORKING" "$R/relay-automation" "$R/test"
cat >"$R/PROJECT/2-WORKING/GH-900-gh55-covering.md" <<'EOF'
---
title: gh55-covering
---
# gh55-covering
## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "MISS_GH55" } ],
  "artifacts": [ "relay-automation/consult.sh" ],
  "remediation": { "criteria": "x" }
}
```
EOF
printf '#!/usr/bin/env bash\n' >"$R/relay-automation/consult.sh"
printf '# helper\n' >"$R/test/_setup.sh"
cat >"$R/test/consult.sh" <<'EOF'
#!/usr/bin/env bash
source "$(dirname "$0")/_setup.sh"
CONSULT="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/consult.sh"
EOF
git -C "$R" init -q -b main 2>/dev/null || { git -C "$R" init -q; git -C "$R" symbolic-ref HEAD refs/heads/main; }
git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$R" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-gh55-covering.md" --out "$R/packet" 2>&1)"; rc=$?
[[ $rc -eq 0 ]] && pass "T31 GH-55: covering-test fixture reads READY" || fail "T31 expected exit 0, got $rc — $out"
grep -q 'Auto-included covering tests/helpers: test/consult.sh,test/_setup.sh' "$R/packet/packet.md" \
  && pass "T31 GH-55: packet names the auto-included covering test + helper" \
  || fail "T31 packet missing auto-included test/helper note: $(grep 'Auto-included' "$R/packet/packet.md" 2>/dev/null)"
grep -q 'Artifacts: relay-automation/consult.sh,test/consult.sh,test/_setup.sh' "$R/packet/packet.md" \
  && pass "T31 GH-55: effective artifact list includes declared artifact + test + helper" \
  || fail "T31 wrong effective artifact list: $(grep '^- Artifacts:' "$R/packet/packet.md")"
grep -q -- '--artifact relay-automation/consult.sh,test/consult.sh,test/_setup.sh' "$R/packet/marathon-invocation.txt" \
  && pass "T31 GH-55: marathon invocation uses the expanded allowlist" \
  || fail "T31 invocation missing expanded allowlist: $(cat "$R/packet/marathon-invocation.txt")"

# ── T32 (GH-55): if the covering test is already declared in artifacts[], it is not duplicated in the
# effective builder allowlist.
R="$WORK/gh55-dedupe"; mkdir -p "$R/PROJECT/2-WORKING" "$R/relay-automation" "$R/test"
cat >"$R/PROJECT/2-WORKING/GH-900-gh55-dedupe.md" <<'EOF'
---
title: gh55-dedupe
---
# gh55-dedupe
## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "MISS_GH55D" } ],
  "artifacts": [ "relay-automation/consult.sh", "test/consult.sh" ],
  "remediation": { "criteria": "x" }
}
```
EOF
printf '#!/usr/bin/env bash\n' >"$R/relay-automation/consult.sh"
printf '# helper\n' >"$R/test/_setup.sh"
cat >"$R/test/consult.sh" <<'EOF'
#!/usr/bin/env bash
source "$(dirname "$0")/_setup.sh"
CONSULT="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/consult.sh"
EOF
git -C "$R" init -q -b main 2>/dev/null || { git -C "$R" init -q; git -C "$R" symbolic-ref HEAD refs/heads/main; }
git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$R" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-gh55-dedupe.md" --out "$R/packet" 2>&1)"; rc=$?
[[ $rc -eq 0 ]] && pass "T32 GH-55: dedupe fixture reads READY" || fail "T32 expected exit 0, got $rc — $out"
[[ "$(grep -o 'test/consult.sh' "$R/packet/marathon-invocation.txt" | wc -l | tr -d ' ')" -eq 1 ]] \
  && pass "T32 GH-55: already-declared covering test is not duplicated in the invocation" \
  || fail "T32 duplicate covering test in invocation: $(cat "$R/packet/marathon-invocation.txt")"

# ── T33 (GH-54): filesystem-touching allowlisted tests trigger the stronger packet rule — do NOT run
# any test or gate yourself; read the tests as specs and rely on the outer harness gate.
R="$WORK/gh54-fstouch"; mkdir -p "$R/PROJECT/2-WORKING" "$R/relay-automation" "$R/test"
cat >"$R/PROJECT/2-WORKING/GH-900-gh54-fstouch.md" <<'EOF'
---
title: gh54-fstouch
---
# gh54-fstouch
## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash validate.sh",
  "fix_probes": [ { "type": "path_absent", "path": "MISS_GH54" } ],
  "artifacts": [ "relay-automation/agy-turn.sh" ],
  "remediation": { "criteria": "x" }
}
```
EOF
printf '#!/usr/bin/env bash\n' >"$R/relay-automation/agy-turn.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"$R/validate.sh"
cat >"$R/test/agy-turn.sh" <<'EOF'
#!/usr/bin/env bash
TMP="$(mktemp -d)"
printf 'x\n' >"$TMP/out"
AGY_SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/agy-turn.sh"
EOF
cat >"$R/test/shim-worktree.sh" <<'EOF'
#!/usr/bin/env bash
git init tmp-fixture >/dev/null 2>&1
SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/agy-turn.sh"
EOF
git -C "$R" init -q -b main 2>/dev/null || { git -C "$R" init -q; git -C "$R" symbolic-ref HEAD refs/heads/main; }
git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$R" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-gh54-fstouch.md" --out "$R/packet" 2>&1)"; rc=$?
[[ $rc -eq 0 ]] && pass "T33 GH-54: fs-touching fixture reads READY" || fail "T33 expected exit 0, got $rc — $out"
grep -q 'Do NOT run ANY test or gate yourself' "$R/packet/packet.md" \
  && pass "T33 GH-54: packet escalates to the stronger no-test rule" \
  || fail "T33 missing stronger no-test rule: $(grep 'Do NOT run' "$R/packet/packet.md")"
grep -q 'test/agy-turn.sh,test/shim-worktree.sh' "$R/packet/packet.md" \
  && pass "T33 GH-54: packet names the fs-touching tests it is forbidding in-turn" \
  || fail "T33 missing named fs-touching tests: $(grep 'Do NOT run ANY test' "$R/packet/packet.md")"
! grep -q 'Verify with ONLY the specific test' "$R/packet/packet.md" \
  && pass "T33 GH-54: generic self-verify instruction is suppressed for fs-touching tests" \
  || fail "T33 generic self-verify rule should be suppressed for fs-touching tests"

# ── T34 (GH-108): a GATE_CMD that heuristically LOOKS like a filtered-runner invocation (a test-looking
# command followed by ' -- ') gets an explicit scoping caveat in the generated packet — a Level-1
# documented-caveat, no cross-runner auto-detection. An already-plain gate is unaffected.
R="$WORK/gh108-caveat"; mkdir -p "$R/PROJECT/2-WORKING" "$R/src"
cat >"$R/PROJECT/2-WORKING/GH-900-gh108-caveat.md" <<'EOF'
---
title: gh108-caveat
---
# gh108-caveat
## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "echo test -- fooTestName",
  "fix_probes": [ { "type": "path_absent", "path": "MISS_GH108" } ],
  "artifacts": [ "src/a.js" ],
  "remediation": { "criteria": "x" }
}
```
EOF
: >"$R/src/a.js"
git -C "$R" init -q -b main 2>/dev/null || { git -C "$R" init -q; git -C "$R" symbolic-ref HEAD refs/heads/main; }
git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$R" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-gh108-caveat.md" --out "$R/packet" 2>&1)"; rc=$?
[[ $rc -eq 0 ]] && pass "T34 GH-108: filtered-looking gate fixture reads READY" || fail "T34 expected exit 0, got $rc — $out"
grep -q 'Gate-scoping caveat (GH-108)' "$R/packet/packet.md" \
  && pass "T34 GH-108: packet emits the gate-scoping caveat for a ' -- ' filtered-looking gate" \
  || fail "T34 missing gate-scoping caveat: $(grep -i 'gate' "$R/packet/packet.md")"

# ── T34b (GH-108): a plain gate with no ' -- ' passthrough is unaffected — no caveat emitted.
R="$WORK/gh108-plain"; mkdir -p "$R/PROJECT/2-WORKING" "$R/src"
cat >"$R/PROJECT/2-WORKING/GH-900-gh108-plain.md" <<'EOF'
---
title: gh108-plain
---
# gh108-plain
## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "MISS_GH108B" } ],
  "artifacts": [ "src/a.js" ],
  "remediation": { "criteria": "x" }
}
```
EOF
: >"$R/src/a.js"
git -C "$R" init -q -b main 2>/dev/null || { git -C "$R" init -q; git -C "$R" symbolic-ref HEAD refs/heads/main; }
git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$R" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-gh108-plain.md" --out "$R/packet" 2>&1)"; rc=$?
[[ $rc -eq 0 ]] && pass "T34b GH-108: plain gate fixture reads READY" || fail "T34b expected exit 0, got $rc — $out"
! grep -q 'Gate-scoping caveat' "$R/packet/packet.md" \
  && pass "T34b GH-108: an already-plain gate (no ' -- ') is unaffected — no caveat emitted" \
  || fail "T34b unexpected gate-scoping caveat for a plain gate: $(grep -i 'gate-scoping' "$R/packet/packet.md")"

# ── T35 (GH-126): covering-test inference now requires a genuine reference — immediately preceded by
# a path separator (the `$(cd .. && pwd)/<artifact>` idiom, per T31/T32) or a source/bash/node keyword
# or require( — not a bare substring anywhere in the file's text (a comment, an unrelated mention).
R="$WORK/gh126-tighten"; mkdir -p "$R/PROJECT/2-WORKING" "$R/src" "$R/test"
cat >"$R/PROJECT/2-WORKING/GH-900-gh126-tighten.md" <<'EOF'
---
title: gh126-tighten
---
# gh126-tighten
## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "MISS_GH126" } ],
  "artifacts": [ "src/target.js" ],
  "remediation": { "criteria": "x" }
}
```
EOF
: >"$R/src/target.js"
cat >"$R/test/target.test.js" <<'EOF'
const target = require('src/target.js');
EOF
cat >"$R/test/comment-only.sh" <<'EOF'
#!/usr/bin/env bash
# See src/target.js for the implementation notes -- not a real reference.
echo "not a covering test"
EOF
git -C "$R" init -q -b main 2>/dev/null || { git -C "$R" init -q; git -C "$R" symbolic-ref HEAD refs/heads/main; }
git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$R" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-gh126-tighten.md" --out "$R/packet" 2>&1)"; rc=$?
[[ $rc -eq 0 ]] && pass "T35 GH-126: tightened covering-test fixture reads READY" || fail "T35 expected exit 0, got $rc — $out"
grep -q 'Auto-included covering tests/helpers:.*test/target.test.js' "$R/packet/packet.md" \
  && pass "T35 GH-126: a genuine require()-adjacent reference is still auto-included" \
  || fail "T35 missing genuine covering-test inclusion: $(grep 'Auto-included' "$R/packet/packet.md" 2>/dev/null)"
! grep -q 'comment-only.sh' "$R/packet/packet.md" \
  && pass "T35 GH-126: a bare substring mention (comment) is NOT auto-included" \
  || fail "T35 bare substring mention wrongly auto-included: $(grep -E 'Auto-included|Artifacts:' "$R/packet/packet.md")"

# ── T35b (GH-137): inferred covering-test/helper paths are sanitized before they widen ALLOW_PATHS:
# a real sibling covering test + helper still land, while `test/..` and `__pycache__/*.pyc` are dropped.
R="$WORK/gh137-sanitize"; mkdir -p "$R/PROJECT/2-WORKING" "$R/relay-automation" "$R/test/__pycache__"
cat >"$R/PROJECT/2-WORKING/GH-900-gh137-sanitize.md" <<'EOF'
---
title: gh137-sanitize
---
# gh137-sanitize
## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "MISS_GH137" } ],
  "artifacts": [ "relay-automation/consult.sh" ],
  "remediation": { "criteria": "x" }
}
```
EOF
printf '#!/usr/bin/env bash\n' >"$R/relay-automation/consult.sh"
printf '# helper\n' >"$R/test/_setup.sh"
printf 'compiled\n' >"$R/test/__pycache__/generated.pyc"
cat >"$R/test/consult.sh" <<'EOF'
#!/usr/bin/env bash
source "$(dirname "$0")/_setup.sh"
ESCAPE_REF="$(dirname "$0")/.."
PYCACHE_REF="$(dirname "$0")/__pycache__/generated.pyc"
CONSULT="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/consult.sh"
EOF
git -C "$R" init -q -b main 2>/dev/null || { git -C "$R" init -q; git -C "$R" symbolic-ref HEAD refs/heads/main; }
git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$R" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-gh137-sanitize.md" --out "$R/packet" 2>&1)"; rc=$?
[[ $rc -eq 0 ]] && pass "T35b GH-137: sanitized inference fixture reads READY" || fail "T35b expected exit 0, got $rc — $out"
node -e '
  const j = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
  const arts = j.effective_artifacts || [];
  const tests = j.inferred_test_artifacts || [];
  const helpers = j.inferred_test_helpers || [];
  const exact = ["relay-automation/consult.sh", "test/consult.sh", "test/_setup.sh"];
  const clean = [...arts, ...tests, ...helpers].every((p) => !p.includes("..") && !p.includes("__pycache__") && !p.endsWith(".pyc"));
  process.exit(
    arts.length === exact.length &&
    exact.every((p, i) => arts[i] === p) &&
    tests.includes("test/consult.sh") &&
    helpers.includes("test/_setup.sh") &&
    clean ? 0 : 1
  );
' "$R/packet/lane-plan.json" \
  && pass "T35b GH-137: effective artifacts keep the declared artifact + real covering test/helper only" \
  || fail "T35b wrong effective artifacts/helpers: $(cat "$R/packet/lane-plan.json")"

# ── T36 (GH-127): isFsTouching also catches a bare '>' redirect (not just cat>/>>/ mktemp/etc.), while
# NOT misclassifying '2>&1' (fd dup, no fs write), '->' (arrow), or '>=' (comparison) as fs-touching.
R="$WORK/gh127-redirect"; mkdir -p "$R/PROJECT/2-WORKING" "$R/test"
cat >"$R/PROJECT/2-WORKING/GH-900-gh127-redirect.md" <<'EOF'
---
title: gh127-redirect
---
# gh127-redirect
## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash validate.sh",
  "fix_probes": [ { "type": "path_absent", "path": "MISS_GH127" } ],
  "artifacts": [ "test/bare-redirect.sh", "test/no-touch.sh" ],
  "remediation": { "criteria": "x" }
}
```
EOF
printf '#!/usr/bin/env bash\nexit 0\n' >"$R/validate.sh"
cat >"$R/test/bare-redirect.sh" <<'EOF'
#!/usr/bin/env bash
echo hello > "$TMP/out"
EOF
cat >"$R/test/no-touch.sh" <<'EOF'
#!/usr/bin/env bash
some_cmd 2>&1
echo "1 -> 2 is an arrow, not a redirect"
echo "a >= b is a comparison, not a redirect"
EOF
git -C "$R" init -q -b main 2>/dev/null || { git -C "$R" init -q; git -C "$R" symbolic-ref HEAD refs/heads/main; }
git -C "$R" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$R" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-gh127-redirect.md" --out "$R/packet" 2>&1)"; rc=$?
[[ $rc -eq 0 ]] && pass "T36 GH-127: bare-redirect fixture reads READY" || fail "T36 expected exit 0, got $rc — $out"
grep -q 'Do NOT run ANY test or gate yourself' "$R/packet/packet.md" \
  && pass "T36 GH-127: bare-redirect artifact escalates the packet to the stronger no-test rule" \
  || fail "T36 missing stronger no-test rule: $(grep 'Do NOT run' "$R/packet/packet.md")"
node -e '
  const j = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
  const fs = j.fs_touching_tests || [];
  process.exit((fs.includes("test/bare-redirect.sh") && !fs.includes("test/no-touch.sh")) ? 0 : 1);
' "$R/packet/lane-plan.json" \
  && pass "T36 GH-127: bare '>' redirect classified fs-touching; '2>&1'/'->'/'>=' usage is not" \
  || fail "T36 fs_touching_tests wrong: $(cat "$R/packet/lane-plan.json")"

# ── T37/T38/T39 (GH-203): a stale, unheld .git/index.lock is advisory only — warn in both text and
# JSON, but never change an otherwise-ready verdict; a clean repo stays silent.
R="$(make_repo stalelock '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
  "artifacts": [ "src/a.js" ],
  "remediation": { "criteria": "x" }
}' '## Phase 1')"
R_CANON="$(cd "$R" && pwd -P)"
: >"$R/.git/index.lock"
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-stalelock.md" 2>&1)"; rc=$?
[[ $rc -eq 0 ]] && pass "T37a GH-203: stale index.lock warning stays fail-open (exit 0)" || fail "T37a expected exit 0, got $rc — $out"
grep -q "verdict     : ready" <<<"$out" && pass "T37b GH-203: stale index.lock does not change the ready verdict" || fail "T37b verdict changed: $out"
grep -q "stale git index lock detected at $R_CANON/.git/index.lock" <<<"$out" \
  && pass "T37c GH-203: text report warns on a stale, unheld index.lock" \
  || fail "T37c missing stale-lock warning: $out"
sj="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-stalelock.md" --format json 2>/dev/null)"
node -e '
  const j = JSON.parse(require("fs").readFileSync(0, "utf8"));
  process.exit(
    j.freshness &&
    j.freshness.stale_index_lock === true &&
    j.freshness.stale_index_lock_path === process.argv[1] &&
    typeof j.freshness.stale_index_lock_warning === "string" &&
    j.freshness.stale_index_lock_warning.includes("pgrep -fl git") &&
    j.freshness.stale_index_lock_warning.includes("rm .git/index.lock") &&
    j.freshness.candidate_state === "ready" ? 0 : 1
  );
' "$R_CANON/.git/index.lock" <<<"$sj" \
  && pass "T38 GH-203: JSON report carries the stale-lock warning/path without changing candidate_state" \
  || fail "T38 JSON stale-lock warning/path missing or wrong: $sj"

R="$(make_repo nolock '{
  "target": { "repo": ".", "ref": "main" },
  "gate": "true",
  "fix_probes": [ { "type": "path_absent", "path": "NEW_FILE.txt" } ],
  "artifacts": [ "src/a.js" ],
  "remediation": { "criteria": "x" }
}' '## Phase 1')"
out="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-nolock.md" 2>&1)"; rc=$?
[[ $rc -eq 0 ]] && pass "T39a GH-203: clean repo with no index.lock stays ready" || fail "T39a expected exit 0, got $rc — $out"
! grep -q "stale git index lock detected" <<<"$out" \
  && pass "T39b GH-203: clean text report omits the stale-lock warning" \
  || fail "T39b unexpected stale-lock warning in clean repo: $out"
sj="$(run "$R" --project-doc "PROJECT/2-WORKING/GH-900-nolock.md" --format json 2>/dev/null)"
node -e '
  const j = JSON.parse(require("fs").readFileSync(0, "utf8"));
  process.exit(
    j.freshness &&
    j.freshness.stale_index_lock === false &&
    j.freshness.stale_index_lock_path === null &&
    j.freshness.stale_index_lock_warning === null ? 0 : 1
  );
' <<<"$sj" \
  && pass "T39c GH-203: clean JSON report omits the stale-lock warning fields" \
  || fail "T39c clean JSON should not carry stale-lock warning fields: $sj"

echo ""
echo "  swarm-preflight: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] || exit 1
