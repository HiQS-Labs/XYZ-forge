#!/usr/bin/env bash
# GH-518: muse-turn.py's model policy must FAIL CLOSED.
#
# Why this suite exists. Meta ships Muse Spark 1.3 at two tiers that differ only in terms:
# muse-spark-1.3 carries no data clause, and muse-spark-1.3-contributor is discounted ~12x because
# "your content, including inter-session messages, may be used for product improvement". A relay
# turn ships repository content to whichever tier is dispatched, and content sent under that clause
# cannot be recalled. The operator's rule is that the discounted tier is for open-source
# repositories only.
#
# That rule is only worth anything if the UNCERTAIN cases land on the safe tier. The dangerous
# direction here is the cheap one, which is the opposite of most fail-closed guards and easy to
# get backwards while refactoring. So every path that cannot positively establish "this repo is
# public" -- gh absent, gh unauthenticated, gh timing out, a non-GitHub remote, an unparseable
# answer, an org-INTERNAL repo -- is asserted to resolve to the clause-free model.
#
# The negative control at the end mutates the fallback to return the contributor model on an
# unknown repo and requires this suite to go RED. A guard that cannot fail is not a guard.
#
# gh is stubbed on PATH; nothing here makes a network call or reads the real repo's visibility.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh518-muse-policy.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

SAFE="muse-spark-1.3"
CONTRIB="muse-spark-1.3-contributor"

pass=0; fail=0
ok()   { printf 'ok   %s\n' "$1"; pass=$((pass+1)); }
bad()  { printf 'FAIL %s\n     %s\n' "$1" "$2"; fail=$((fail+1)); }

# Build a fake `gh` whose behavior is driven by GH_STUB_MODE.
mkdir -p "$WORK/bin"
cat >"$WORK/bin/gh" <<'STUB'
#!/usr/bin/env bash
case "${GH_STUB_MODE:-}" in
  public)   echo "PUBLIC" ;;
  private)  echo "PRIVATE" ;;
  internal) echo "INTERNAL" ;;
  garbage)  echo "banana" ;;
  empty)    printf '' ;;
  fail)     echo "gh: could not determine repository" >&2; exit 1 ;;
  hang)     sleep 60 ;;
  *)        echo "unconfigured stub" >&2; exit 2 ;;
esac
STUB
chmod +x "$WORK/bin/gh"

mkdir -p "$WORK/empty-bin"

# python3 is invoked by ABSOLUTE path. The PATH we hand the child exists solely to control
# whether `gh` is findable, and an earlier revision of this suite emptied PATH to simulate a
# missing gh -- which also hid python3, so the "gh not installed" case failed for the wrong
# reason and told us nothing about the policy.
PY3="$(command -v python3)"
[ -n "$PY3" ] || { echo "python3 not found" >&2; exit 2; }

MODULE="$REPO_ROOT/utils/py/muse-turn.py"

# Ask the real module for its decision. The module path is a parameter so the negative control
# can point this at a mutated copy.
#
# NOTE: no subshells anywhere in the assertion path. A previous revision wrapped each case in
# ( ... ), so ok()/bad() incremented counters in a child shell and the parent always reported
# "0 failed" -- a visible FAIL line with a green exit code. Env is passed per-invocation via
# `env` instead, which keeps the counters in this shell where they can actually fail the run.
resolve() {  # resolve <module_path> <gh_mode|-> <no-gh|with-gh> [VAR=VAL ...]
  local module="$1" gh_mode="$2" gh_present="$3"; shift 3
  local pathspec="$WORK/bin:$PATH"
  [ "$gh_present" = "no-gh" ] && pathspec="$WORK/empty-bin"
  env -i \
    HOME="$HOME" \
    PATH="$pathspec" \
    PYTHONPATH="$REPO_ROOT/utils/py" \
    GH_STUB_MODE="$gh_mode" \
    "$@" \
    "$PY3" - "$module" <<'PY' 2>/dev/null
import importlib.util, sys
spec = importlib.util.spec_from_file_location("muse_turn", sys.argv[1])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
model, reason = mod.resolve_model(".")
print(model)
PY
}

expect() {  # expect <label> <wanted> <gh_mode> <gh_present> [VAR=VAL ...]
  local label="$1" want="$2" gh_mode="$3" gh_present="$4"; shift 4
  local got
  got="$(resolve "$MODULE" "$gh_mode" "$gh_present" "$@")"
  if [ "$got" = "$want" ]; then ok "$label"; else bad "$label" "wanted '$want', got '$got'"; fi
}

echo "--- positive path: only a confirmed-public repo reaches the discounted tier ---"
expect "public repo -> contributor tier" "$CONTRIB" public with-gh

echo "--- fail-closed paths: every uncertainty lands on the clause-free tier ---"
expect "private repo -> safe tier"           "$SAFE" private  with-gh
expect "org-internal repo -> safe tier"      "$SAFE" internal with-gh
expect "gh exits nonzero -> safe tier"       "$SAFE" fail     with-gh
expect "unparseable visibility -> safe tier" "$SAFE" garbage  with-gh
expect "empty visibility -> safe tier"       "$SAFE" empty    with-gh
expect "gh not installed -> safe tier"       "$SAFE" -        no-gh

echo "--- timeout must not silently upgrade the tier (bounded, ~15s) ---"
expect "gh hangs -> safe tier"               "$SAFE" hang     with-gh

echo "--- operator overrides ---"
expect "MUSE_ALLOW_CONTRIBUTOR=0 pins safe tier even on a public repo" \
       "$SAFE" public with-gh MUSE_ALLOW_CONTRIBUTOR=0
expect "explicit MUSE_MODEL wins (informed operator choice)" \
       "$CONTRIB" private with-gh MUSE_MODEL=muse-spark-1.3-contributor

echo "--- colloquial MUSE_MODEL resolves through the catalog's NATIVE aliases ---"
# resolve-model-alias.sh cannot serve these: render_openrouter.py filters the alias table to
# target == "openrouter", and this suite's sibling gh450 asserts that scoping as a contract. So a
# native model resolves against the vendored catalog.json instead (model_alias.resolve_native_alias).
# XYZ_ROOT is what that lookup reads, so it must be set for these cases.
expect "MUSE_MODEL=muse resolves to the clause-free tier" \
       "$SAFE" private with-gh MUSE_MODEL=muse XYZ_ROOT="$REPO_ROOT"
expect "MUSE_MODEL=meta resolves to the clause-free tier" \
       "$SAFE" private with-gh MUSE_MODEL=meta XYZ_ROOT="$REPO_ROOT"
# The operator's original phrasing, verbatim, must reach the tier they named.
expect "MUSE_MODEL='Muse Spark 1.3 Contributor' resolves to the contributor tier" \
       "$CONTRIB" private with-gh MUSE_MODEL="Muse Spark 1.3 Contributor" XYZ_ROOT="$REPO_ROOT"
# An unknown string is passed through untouched, to be rejected by the CLI rather than silently
# rewritten into some nearby model here.
expect "an unknown MUSE_MODEL passes through unchanged" \
       "definitely-not-a-model" private with-gh MUSE_MODEL=definitely-not-a-model XYZ_ROOT="$REPO_ROOT"

echo "--- NEGATIVE CONTROL: a fallback that upgrades on uncertainty must be caught ---"
mutant="$WORK/muse-turn-mutant.py"
sed 's|return SAFE_MODEL, "not established as public|return CONTRIBUTOR_MODEL, "not established as public|' \
    "$MODULE" >"$mutant"
if ! grep -q 'return CONTRIBUTOR_MODEL, "not established as public' "$mutant"; then
  bad "negative control" "mutation did not apply — the guard proves nothing"
else
  got="$(resolve "$mutant" private with-gh)"
  if [ "$got" = "$CONTRIB" ]; then
    ok "negative control: mutated fallback leaks to contributor, and this suite detects it"
  else
    bad "negative control" "mutant returned '$got'; suite cannot detect a reversed fallback"
  fi
fi

echo
echo "gh518-muse-model-policy: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
