#!/usr/bin/env bash
set -euo pipefail
#
# gh396-find-harness-roots.sh — GH-396 Phase 0: pin the two-roots contract of find-harness.sh.
#
# Written to arrive RED. It pins three defects that have never had a test:
#   #395 — an exported XYZ_HARNESS pointing at a vendored .xyz/ collapses TICK_REPO_ROOT onto the
#          harness dir instead of the consumer repo (find-harness.sh:137-138). Five topologies.
#   #394 — the same override branch skips the staleness warning (find-harness.sh:141 gates it on
#          VENDORED=1), and the remedy it prints is not runnable as printed (:170).
#   --quiet — does not exist yet; every resolution will announce itself on stderr after Phase 1,
#          so the silencer must exist and must silence only the announcement.
#
# The oracle for every #395 case is the SAME fixture resolved WITHOUT the override. Whatever
# auto-discovery says TICK_REPO_ROOT is, the override run must agree. That makes the test immune
# to being "fixed" by changing what the right answer is — it only passes when both paths agree.
#
# Idiom notes (the repo's guards enforce these on new test code):
#   - ok/bad take a decided verdict, never a command string to eval (GH-64 gate).
#   - capture-then-match: grep -q PAT <<<"$var", never a pipe into grep (GH-139 ban).
#   - $WORK is proven a real dir before any trap can rm -rf it (GH-177).

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd -P)"
FH="$REPO/skills/relay-xyz/find-harness.sh"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh396-roots.XXXXXX")"
. "$HERE/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$WORK"       # GH-10: pin the sandbox root
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "  FAIL: mktemp -d produced no usable dir" >&2 && exit 1; }
WORK="$(cd "$WORK" && pwd -P)"
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "  FAIL: could not resolve \$WORK" >&2 && exit 1; }
export WORK
. "$HERE/lib/vendored-fixture.sh"
cleanup() { remove_vendored_fixture 2>/dev/null || true; rm -rf "$WORK"; }
trap cleanup EXIT
pass=0; fail=0
ok()  { echo "  PASS: $1"; pass=$((pass + 1)); }
bad() { echo "  FAIL: $1" >&2; fail=$((fail + 1)); }

# Run the locator from <cwd> with an optional override, return the value of one exported name.
env_value() {  # env_value <cwd> <name> [override-path]
  _cwd="$1"; _name="$2"; _ov="${3:-}"
  if [ -n "$_ov" ]; then
    _out="$(cd "$_cwd" && XYZ_HARNESS="$_ov" XYZ_REPO_ROOT= bash "$FH" --env 2>/dev/null || true)"
  else
    _out="$(cd "$_cwd" && env -u XYZ_HARNESS -u XYZ_REPO_ROOT bash "$FH" --env 2>/dev/null || true)"
  fi
  _line="$(grep -E "^export ${_name}=" <<<"$_out" || true)"
  _v="${_line#export ${_name}=}"
  # --env prints %q-quoted values; strip the two quoting forms it produces.
  _v="${_v#\'}"; _v="${_v%\'}"
  printf '%s' "$_v" | sed 's/\\ / /g'
}

# One #395 assertion: override-run TICK_REPO_ROOT == auto-run TICK_REPO_ROOT == expected repo.
assert_roots_agree() {  # assert_roots_agree <label> <cwd> <override> <expected-repo-root>
  _label="$1"; _cwd="$2"; _ov="$3"; _want="$(cd -P "$4" && pwd)"
  _auto="$(env_value "$_cwd" TICK_REPO_ROOT)"
  _over="$(env_value "$_cwd" TICK_REPO_ROOT "$_ov")"
  _auto_p="$(cd -P "$_auto" 2>/dev/null && pwd || printf '%s' "$_auto")"
  _over_p="$(cd -P "$_over" 2>/dev/null && pwd || printf '%s' "$_over")"
  if [ "$_auto_p" = "$_want" ]; then ok "$_label: auto-discovery resolves TICK_REPO_ROOT to the consumer repo"
  else bad "$_label: auto-discovery resolves TICK_REPO_ROOT to the consumer repo (got $_auto)"; fi
  if [ "$_over_p" = "$_auto_p" ]; then ok "$_label: XYZ_HARNESS override agrees with auto-discovery (#395)"
  else bad "$_label: XYZ_HARNESS override agrees with auto-discovery (#395) — override=$_over auto=$_auto"; fi
  _h_over="$(env_value "$_cwd" HARNESS "$_ov")"
  _h_over_p="$(cd -P "$_h_over" 2>/dev/null && pwd || printf '%s' "$_h_over")"
  _ov_p="$(cd -P "$_ov" 2>/dev/null && pwd || printf '%s' "$_ov")"
  if [ "$_h_over_p" = "$_ov_p" ]; then ok "$_label: override still selects the harness it names"
  else bad "$_label: override still selects the harness it names (got $_h_over)"; fi
}

echo "gh396 find-harness two-roots contract:"
[ -x "$FH" ] || { echo "  FAIL: locator not executable at $FH"; exit 1; }

# ── #395 (a): plain vendored .xyz/ ─────────────────────────────────────────────────────────────
make_vendored_fixture "$WORK/a-plain" --stub
assert_roots_agree "plain .xyz" "$VF_REPO" "$VF_HARNESS" "$VF_REPO"
remove_vendored_fixture

# ── #395 (b): override names the MAIN checkout's .xyz while CWD is a LINKED WORKTREE ───────────
# The override selects which harness. It must not move the repo root off the worktree the
# operator is standing in — that is where their relay task and event log live.
make_vendored_fixture "$WORK/b-main" --stub --worktree "$WORK/b-linked"
assert_roots_agree "linked worktree, override=main .xyz" "$VF_WORKTREE" "$VF_HARNESS" "$VF_WORKTREE"
remove_vendored_fixture

# ── #395 (c): .xyz is a symlink to a directory INSIDE the repo ─────────────────────────────────
make_vendored_fixture "$WORK/c-inside" --stub --symlink-inside
assert_roots_agree "symlink inside repo" "$VF_REPO" "$VF_LINK" "$VF_REPO"
remove_vendored_fixture

# ── #395 (d): .xyz is a symlink to a directory OUTSIDE the repo ────────────────────────────────
# Orchestrator correction A on the plan: here `git -C <link> rev-parse --show-toplevel` returns
# `fatal: not a git repository`, so the resolver's dirname FALLBACK is what must answer — and it
# must use LOGICAL pwd (dirname of the link's parent), not `pwd -P` (which lands outside the repo).
make_vendored_fixture "$WORK/d-outside" --stub --symlink-outside
assert_roots_agree "symlink outside repo" "$VF_REPO" "$VF_LINK" "$VF_REPO"
_git_top="$(git -C "$VF_LINK" rev-parse --show-toplevel 2>&1 || true)"
if grep -q 'not a git repository' <<<"$_git_top"; then
  ok "symlink outside repo: control — git cannot resolve the link target, so the fallback is load-bearing"
else
  bad "symlink outside repo: control — expected git to fail on the link target, got: $_git_top"
fi
remove_vendored_fixture

# ── #395 (e): precedence table — one assertion per documented step (find-harness.sh:18-24) ─────
# Step 1: a VALID override beats a local .xyz.
make_vendored_fixture "$WORK/e-consumer" --stub
_other="$WORK/e-other-harness"; mkdir -p "$_other"; _vf_stub_harness "$_other"
_h="$(env_value "$VF_REPO" HARNESS "$_other")"
if [ "$(cd -P "$_h" 2>/dev/null && pwd)" = "$(cd -P "$_other" && pwd)" ]; then ok "precedence step 1: valid XYZ_HARNESS override wins over local .xyz"
else bad "precedence step 1: valid XYZ_HARNESS override wins over local .xyz (got $_h)"; fi
# Step 1 (negative): an INVALID override is ignored, not obeyed.
_h="$(env_value "$VF_REPO" HARNESS "$WORK/does-not-exist")"
if [ "$(cd -P "$_h" 2>/dev/null && pwd)" = "$(cd -P "$VF_HARNESS" && pwd)" ]; then ok "precedence step 1: invalid override falls through to local .xyz"
else bad "precedence step 1: invalid override falls through to local .xyz (got $_h)"; fi
# Step 2: no override → local .xyz.
_h="$(env_value "$VF_REPO" HARNESS)"
if [ "$(cd -P "$_h" 2>/dev/null && pwd)" = "$(cd -P "$VF_HARNESS" && pwd)" ]; then ok "precedence step 2: local .xyz selected with no override"
else bad "precedence step 2: local .xyz selected with no override (got $_h)"; fi
remove_vendored_fixture
# Step 3 is pinned by test/gh292-worktree-vendored-discovery.sh (linked worktree → main .xyz).
ok "precedence step 3: delegated to gh292-worktree-vendored-discovery.sh (linked worktree, no override)"
# Step 4: standing in the harness clone itself → itself.
_h="$(env_value "$REPO" HARNESS)"
if [ "$(cd -P "$_h" 2>/dev/null && pwd)" = "$REPO" ]; then ok "precedence step 4: harness clone resolves to itself"
else bad "precedence step 4: harness clone resolves to itself (got $_h)"; fi
# Step 5: a foreign repo with no .xyz and no override → the script's own harness.
_foreign="$WORK/e-foreign"; mkdir -p "$_foreign"; _vf_init_repo "$_foreign"
_h="$(env_value "$_foreign" HARNESS)"
if [ "$(cd -P "$_h" 2>/dev/null && pwd)" = "$REPO" ]; then ok "precedence step 5: foreign repo falls back to the script's own harness"
else bad "precedence step 5: foreign repo falls back to the script's own harness (got $_h)"; fi
rm -rf "$_foreign"

# ── #394: staleness must still warn under an override, and the remedy must be runnable ────────
# A vendored copy stamped with an ancestor commit is "behind". The live harness is $REPO.
_ancestor="$(git -C "$REPO" rev-list --max-parents=0 HEAD | tail -1)"
make_vendored_fixture "$WORK/f-stale" --stub --stale "$_ancestor"
_err_auto="$(cd "$VF_REPO" && env -u XYZ_HARNESS -u XYZ_REPO_ROOT XYZ_LIVE_HARNESS= bash "$FH" --env 2>&1 >/dev/null || true)"
if grep -q 'behind the live harness' <<<"$_err_auto"; then ok "#394: auto-discovery warns that the vendored copy is behind"
else bad "#394: auto-discovery warns that the vendored copy is behind (stderr: ${_err_auto:-<empty>})"; fi
_err_over="$(cd "$VF_REPO" && XYZ_HARNESS="$VF_HARNESS" XYZ_REPO_ROOT= bash "$FH" --env 2>&1 >/dev/null || true)"
if grep -q 'behind the live harness' <<<"$_err_over"; then ok "#394: the warning still fires when XYZ_HARNESS points at the stale .xyz"
else bad "#394: the warning still fires when XYZ_HARNESS points at the stale .xyz (stderr: ${_err_over:-<empty>})"; fi
_remedy="$(grep -E '^[[:space:]]*remedy:' <<<"$_err_auto" | sed -E 's/^[[:space:]]*remedy:[[:space:]]*//' || true)"
if [ -n "$_remedy" ]; then
  _cmd="${_remedy%% *}"
  if [ -x "$_cmd" ] || command -v "$_cmd" >/dev/null 2>&1 || { [ "$_cmd" = bash ] && [ -f "$(cut -d' ' -f2 <<<"$_remedy")" ]; }; then
    ok "#394: the printed remedy is runnable as printed ($_remedy)"
  else
    bad "#394: the printed remedy is runnable as printed — '$_cmd' is not on PATH and not a file ($_remedy)"
  fi
else
  bad "#394: a remedy line is printed with the warning"
fi
remove_vendored_fixture

# ── --quiet: exists, silences the announcement, changes nothing else ──────────────────────────
make_vendored_fixture "$WORK/g-quiet" --stub
_rc=0; _q_err="$(cd "$VF_REPO" && env -u XYZ_HARNESS -u XYZ_REPO_ROOT bash "$FH" --quiet --env 2>&1 >/dev/null)" || _rc=$?
if [ "$_rc" -eq 0 ]; then ok "--quiet: accepted (exit 0)"; else bad "--quiet: accepted (exit $_rc: ${_q_err:-<no stderr>})"; fi
_q_lines="$(grep -c '^find-harness:' <<<"${_q_err:-}" || true)"
if [ "${_q_lines:-0}" -eq 0 ]; then ok "--quiet: no find-harness: announcement on stderr"
else bad "--quiet: no find-harness: announcement on stderr (got $_q_lines line(s))"; fi
_loud="$(cd "$VF_REPO" && env -u XYZ_HARNESS -u XYZ_REPO_ROOT bash "$FH" --env 2>/dev/null | sort || true)"
_quiet="$(cd "$VF_REPO" && env -u XYZ_HARNESS -u XYZ_REPO_ROOT bash "$FH" --quiet --env 2>/dev/null | sort || true)"
if [ -n "$_quiet" ] && [ "$_loud" = "$_quiet" ]; then ok "--quiet: exported names and values are identical to the loud form"
else bad "--quiet: exported names and values are identical to the loud form"; fi
remove_vendored_fixture

echo "  gh396-find-harness-roots: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
