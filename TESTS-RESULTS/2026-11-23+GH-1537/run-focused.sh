#!/usr/bin/env bash
# GH-1537: run the EXISTING suites that pin pre-push in a disposable full clone and record one provenance row per suite.
# Usage (from the disposable clone, at the committed head under test):
#   PATH="$HOME/.cache/xyz-forge-test-venv/bin:$PATH" bash TESTS-RESULTS/2026-11-23+GH-1537/run-focused.sh <out-dir>
set -u
OUT="${1:?out dir}"; mkdir -p "$OUT"
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT" || exit 2
ident() {  # repository identity (WORKTREE-SAFETY.md bracket): HEAD, origin URL, bare flag
  printf '{"head":"%s","origin":"%s","bare":"%s"}' "$(git rev-parse HEAD)" "$(git remote get-url origin 2>/dev/null)" \
    "$(git rev-parse --is-bare-repository)"
}
PROV="$OUT/suites-provenance.jsonl"; LOG="$OUT/focused-suites.log"; : > "$PROV"; : > "$LOG"
PRE="$(ident)"
HOOK="$(shasum -a 256 githooks/pre-push | cut -c1-16)"
PY="$(python3 --version 2>&1)"; MYPY="$(python3 -c 'import mypy.version as v; print(v.__version__)' 2>&1)"; BASHV="$(bash --version | head -1)"
unset XYZ_HARNESS TICK_REPO_ROOT
for s in gh544-pre-push-gate gh591-prepush-commit-boundary gh35-test-tiers gh4-ungated-clone-warning ci-route ci-workflow; do
  echo "=== $s" >> "$LOG"
  bash "test/$s.sh" >> "$LOG" 2>&1; rc=$?
  printf '{"suite":"%s","command":"bash test/%s.sh","tested_commit":"%s","hook_sha256":"%s","exit":%s,"python":"%s","mypy":"%s","bash":"%s","log":"focused-suites.log"}\n' \
    "$s" "$s" "$(git rev-parse HEAD)" "$HOOK" "$rc" "$PY" "$MYPY" "$BASHV" >> "$PROV"
  echo "rc=$rc $s" >> "$LOG"
done
POST="$(ident)"
printf '{"clone_identity_before":%s,"clone_identity_after":%s,"unchanged":"%s"}\n' "$PRE" "$POST" "$([ "$PRE" = "$POST" ] && echo yes || echo NO)" >> "$PROV"
cat "$PROV" | cut -c1-200
