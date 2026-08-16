#!/usr/bin/env bash
# GH-509: deterministic route selection for docs, fast PR, and full integration gates.
source "$(dirname "$0")/_setup.sh" ci-route
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROUTER="$ROOT/utils/ci-route.sh"

route() {
  local event="$1"
  shift
  printf '%s\n' "$@" | bash "$ROUTER" "$event"
}

expect_route() {
  local label="$1" event="$2" expected_route="$3" expected_pdda="$4"
  shift 4
  local out
  out="$(route "$event" "$@")"
  if grep -Fqx "route=$expected_route" <<<"$out" \
    && grep -Fqx "pdda_needed=$expected_pdda" <<<"$out"; then
    pass "$label"
  else
    fail "$label: $out"
  fi
}

expect_route "markdown-only PR uses the docs gate" pull_request docs true README.md PROJECT/1-INBOX/NOTE.md
expect_route "ordinary code-only PR uses the fast gate without PDDA" pull_request fast false utils/hq/hq.sh
expect_route "mixed docs and ordinary code runs both fast tests and PDDA" pull_request fast true README.md utils/hq/hq.sh
expect_route "Tick/event changes require the full pre-merge gate" pull_request full true src/events.js
expect_route "relay containment changes require the full pre-merge gate" pull_request full true relay-automation/relay-turn-lib.sh
expect_route "Python-authoritative twin changes require the full pre-merge gate" pull_request full true utils/py/relay_drive.py
expect_route "worktree safety test changes require the full pre-merge gate" pull_request full true test/worktree-isolation.sh
expect_route "CI workflow changes require the full pre-merge gate" pull_request full true .github/workflows/ci.yml
expect_route "PDDA implementation changes run PDDA plus the full gate" pull_request full true utils/pdda/pdda.sh
shell_suffix=sh
deleted_test="test/removed-regression.${shell_suffix}"
expect_route "a deleted regression test fails closed into the full gate" pull_request full true "$deleted_test"
# GH-509 Phase 3 relabelled this: a push is no longer unconditionally full. With NO paths it still
# is, because zero paths is the fail-closed case — which is what this line actually exercises.
expect_route "a push with no usable range fails closed into the full gate" push full true
expect_route "scheduled runs remain the full fallback boundary" schedule full true

out="$(route pull_request utils/hq/hq.sh)"
grep -Fqx 'changed_tests=hq.sh' <<<"$out" \
  && pass "fast routes include a directly matching changed-area test" \
  || fail "fast route omitted its changed-area test: $out"

out="$(printf '' | bash "$ROUTER" pull_request)"
grep -Fqx 'route=full' <<<"$out" \
  && pass "an empty PR diff fails closed into the full gate" \
  || fail "empty PR diff did not fail closed: $out"

set +e
unknown_out="$(bash "$ROUTER" unsupported </dev/null 2>&1)"
unknown_rc=$?
set -e
[[ "$unknown_rc" -eq 2 && "$unknown_out" == *"unsupported event"* ]] \
  && pass "unknown events fail loudly" \
  || fail "unknown event result: rc=$unknown_rc out=$unknown_out"

# ── GH-509 Phase 3: pushes are classified, not blanket-full ──────────────────────────────────────
# 72% of the billed minutes were pushes to `development`, every one on the full route. They now
# classify from their pushed range exactly as a PR classifies from its diff.
expect_route "docs-only push uses the docs gate (was blanket full)" push docs true README.md
expect_route "ordinary code-only push uses the fast gate" push fast false utils/hq/hq.sh
expect_route "a push touching the kernel still fails closed to full" push full true src/events.js
expect_route "a push touching relay containment still fails closed to full" push full true relay-automation/relay-turn-lib.sh

# The trigger that must NOT be routed. A manual dispatch is someone asking for the whole gate;
# answering with a routed subset answers a different question than the one asked.
out="$(printf '%s\n' README.md | bash "$ROUTER" workflow_dispatch)"
grep -Fqx 'route=full' <<<"$out" \
  && pass "workflow_dispatch stays unconditionally full even for a docs-only path list" \
  || fail "workflow_dispatch was routed away from full: $out"

# ── GH-509: a RENAMED regression test must select full ───────────────────────────────────────────
# This drives a real `git mv` through the exact command the workflow runs, because the defect lives
# in the FLAG, not in the classifier. With git's default rename detection, `--name-only` prints only
# the DESTINATION path — which still exists — so a renamed test reads as an ordinary changed file and
# ci-route.sh's fail-closed branch for a vanished test is never reached. That branch's comment says
# "deleted/renamed"; before this flag it only ever saw deletions.
#
# Asserting on ci-route.sh alone could not catch it: the classifier behaves correctly for whatever
# paths it is handed. The bug is in WHICH paths it is handed.
RENAME_REPO="$WORK/rename-fixture"
git init -q "$RENAME_REPO"
git -C "$RENAME_REPO" config user.email t@t
git -C "$RENAME_REPO" config user.name t
mkdir -p "$RENAME_REPO/test"
printf '#!/usr/bin/env bash\nexit 0\n' >"$RENAME_REPO/test/old-regression.sh"
git -C "$RENAME_REPO" add -A >/dev/null 2>&1
git -C "$RENAME_REPO" commit -q -m seed
RENAME_BASE="$(git -C "$RENAME_REPO" rev-parse HEAD)"
git -C "$RENAME_REPO" mv test/old-regression.sh test/new-regression.sh
git -C "$RENAME_REPO" commit -q -m rename

# The defect, demonstrated rather than described: default rename detection hides the source path.
if [ "$(git -C "$RENAME_REPO" diff --name-only "$RENAME_BASE" HEAD | wc -l | tr -d ' ')" -eq 1 ]; then
  pass "control: plain --name-only reports ONE path for a rename (the source is invisible)"
else
  fail "control failed: git no longer hides the rename source, so this guard's premise is stale"
fi

rename_paths="$(git -C "$RENAME_REPO" diff --no-renames --name-only "$RENAME_BASE" HEAD)"
# CWD must be the FIXTURE: ci-route.sh resolves `[[ -f "$path" ]]` relative to the working
# directory, which is the whole mechanism under test — a vanished source path is what trips the
# fail-closed branch. Run it from the harness root and every fixture path looks vanished, which
# would make this assertion pass for the wrong reason and the edit case below fail outright.
out="$(cd "$RENAME_REPO" && printf '%s\n' "$rename_paths" | bash "$ROUTER" push)"
grep -Fqx 'route=full' <<<"$out" \
  && pass "a renamed regression test selects full (--no-renames surfaces the removal)" \
  || fail "GH-509: a renamed test did not select full — test removal can escape the full gate: $out"

# And the reverse, so this is not simply "renames always full for some other reason": the same
# fixture with the file merely EDITED must not be forced to full.
printf '#!/usr/bin/env bash\nexit 1\n' >"$RENAME_REPO/test/new-regression.sh"
git -C "$RENAME_REPO" add -A >/dev/null 2>&1
git -C "$RENAME_REPO" commit -q -m edit
edit_paths="$(git -C "$RENAME_REPO" diff --no-renames --name-only HEAD~1 HEAD)"
out="$(cd "$RENAME_REPO" && printf '%s\n' "$edit_paths" | bash "$ROUTER" push)"
grep -Fqx 'route=full' <<<"$out" \
  && fail "an ordinary test EDIT was forced to full — the rename rule is over-broad" \
  || pass "an ordinary test edit is not forced to full (the rename rule is not a blanket)"

echo "  ci-route: $PASS pass, $FAIL fail"
exit "$FAIL"
