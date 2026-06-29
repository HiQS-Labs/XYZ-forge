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

echo ""
echo "  swarm-preflight: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] || exit 1
