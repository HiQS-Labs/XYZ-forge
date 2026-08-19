#!/usr/bin/env bash
# GH-32 — `check`'s target-date advisories: rule=release-overdue / rule=release-target-passed.
#
# What this pins, and why it exists:
#   * `ship` is deliberately a human verb (it demands evidence). The cost is that a release whose
#     exit criterion is already met can sit `active` forever with nobody noticing — 0.7.1 Bulwark
#     did, for a day, while its own merge and all three manifest items were closed. The advisory
#     removes the silence without touching the design.
#   * It must WARN and never REFUSE. A repo with an overdue release still passes `check` (exit 0),
#     because the alternative — a red gate on a calendar date — would get the check disabled.
#   * It must be a *falsifiable* assertion: a release whose target has NOT passed produces no
#     warning at all. Without that control, a rule that fires on everything looks identical to a
#     rule that works.
#   * It stays offline: no GitHub read, no network, just the stored target_date vs. the clock.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
APP="$ROOT_DIR/utils/py/releases_app.py"

pass=0; fail=0
pass_() { echo "  PASS: $1"; pass=$((pass+1)); }
fail_() { echo "  FAIL: $1" >&2; fail=$((fail+1)); }
# Deliberately no dynamic evaluation here: the ok() helper other suites share needs a
# security-scan baseline entry per suite, and nothing below needs that indirection.
yes_() { if [ "$2" = "0" ]; then pass_ "$1"; else fail_ "$1"; fi; }
has()  { printf '%s' "$1" | grep -Fq -- "$2"; }

echo "== test: gh32-release-target-advisory =="
command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh32-target-adv.XXXXXX")"
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
cleanup() {
  case "${WORK:-}" in
    "${TMPDIR:-/tmp}"/gh32-target-adv.*) [ -d "$WORK" ] && rm -rf "$WORK" ;;
    *) echo "gh32-target-adv: REFUSING cleanup outside the workspace: ${WORK:-<empty>}" >&2 ;;
  esac
}
trap cleanup EXIT

R="$WORK/r"
mkdir -p "$R"; require_fixture "$R" "target-advisory fixture"
git -C "$R" init -q -b main
git -C "$R" config user.email gh32adv@test.invalid
git -C "$R" config user.name gh32adv
ra() { require_fixture "$R" "target-advisory fixture"; python3 "$APP" --root "$R" "$@"; }

ra init --slug gh32adv >/dev/null

# The clock is mocked for every assertion below, so this suite does not rot as the wall clock moves.
NOW="2026-09-01T12:00:00Z"

TRACK="https://github.com/HiQS-Suite/XYZ-forge/issues/32"
ra add --version 1.0.0 --codename Overdue --target-date 2026-08-20 --status active \
  --tracking-issue "$TRACK" \
  --description "an active release whose target has passed" \
  --exit-criterion "the suite is green" >/dev/null
ra add --version 1.1.0 --codename Future --target-date 2026-12-01 --status draft \
  --tracking-issue "$TRACK" \
  --description "a release comfortably in the future" \
  --exit-criterion "the suite is green" >/dev/null

gid_of() { python3 "$APP" --root "$R" list 2>/dev/null | awk -v v="$1" '$2 == v {print $1}'; }

# ── 1. an active release past its target warns, by name, with the day count ─────────────────────
out="$(RELEASES_APP_NOW="$NOW" ra check 2>&1)"; rc=$?
yes_ "check still EXITS 0 with an overdue release (advisory, never a refusal)" "$([ $rc -eq 0 ] && echo 0 || echo 1)"
if has "$out" "rule=release-overdue"; then pass_ "  and names rule=release-overdue"; else fail_ "  and names rule=release-overdue"; fi
if has "$out" "1.0.0 Overdue"; then pass_ "  and names WHICH release"; else fail_ "  and names WHICH release"; fi
if has "$out" "12 day(s) past its target"; then pass_ "  and counts the days (12)"; else fail_ "  and counts the days (12)"; fi
if has "$out" "releases ship"; then pass_ "  and says what to do about it"; else fail_ "  and says what to do about it"; fi
if has "$out" "0 failures, 1 warning(s)"; then pass_ "  and is tallied as a warning, not a failure"; else fail_ "  and is tallied as a warning, not a failure"; fi

# ── 2. FALSIFIABLE: the future release is silent (the rule does not fire on everything) ─────────
if has "$out" "1.1.0 Future"; then fail_ "NEGATIVE CONTROL: a release whose target has NOT passed stays silent"; else pass_ "NEGATIVE CONTROL: a release whose target has NOT passed stays silent"; fi

# ── 3. a DRAFT past its target gets its own rule (stale plan, not a stuck ship) ─────────────────
ra add --version 0.9.0 --codename Stale --target-date 2026-07-01 --status draft \
  --tracking-issue "$TRACK" \
  --description "a draft nobody re-dated" --exit-criterion "the suite is green" >/dev/null
out="$(RELEASES_APP_NOW="$NOW" ra check 2>&1)"; rc=$?
yes_ "check still EXITS 0 with both an overdue active and a stale draft" "$([ $rc -eq 0 ] && echo 0 || echo 1)"
if has "$out" "rule=release-target-passed"; then pass_ "  and the draft gets rule=release-target-passed, not release-overdue"; else fail_ "  and the draft gets rule=release-target-passed, not release-overdue"; fi
if has "$out" "0.9.0 Stale"; then pass_ "  and names the stale draft"; else fail_ "  and names the stale draft"; fi
if has "$out" "0 failures, 2 warning(s)"; then pass_ "  and both advisories are tallied"; else fail_ "  and both advisories are tallied"; fi

# ── 4. shipping the overdue release silences ITS warning (the advisory tracks reality) ──────────
GID="$(gid_of 1.0.0)"
ra ship --gid "$GID" --evidence "suite green; pinned by this test" --date 2026-08-25 >/dev/null
out="$(RELEASES_APP_NOW="$NOW" ra check 2>&1)"
if has "$out" "release-overdue"; then fail_ "shipping clears the overdue advisory"; else pass_ "shipping clears the overdue advisory"; fi
if has "$out" "0 failures, 1 warning(s)"; then pass_ "  and the untouched draft advisory survives (only the shipped one cleared)"; else fail_ "  and the untouched draft advisory survives (only the shipped one cleared)"; fi

# ── 5. re-dating the draft also clears it — the other documented remedy ─────────────────────────
ra update --gid "$(gid_of 0.9.0)" --target-date 2026-11-30 >/dev/null
out="$(RELEASES_APP_NOW="$NOW" ra check 2>&1)"
if has "$out" "release-target-passed"; then fail_ "moving the target clears the stale-draft advisory"; else pass_ "moving the target clears the stale-draft advisory"; fi
if has "$out" "check: clean (0 failures, 0 warning(s))"; then pass_ "  and check reports fully clean again"; else fail_ "  and check reports fully clean again"; fi

# ── 6. the advisory is offline: no target date, no warning, no crash ────────────────────────────
ra add --version 2.0.0 --codename Undated --status draft --tracking-issue "$TRACK" \
  --description "no target at all" --exit-criterion "n/a" >/dev/null
out="$(RELEASES_APP_NOW="$NOW" ra check 2>&1)"; rc=$?
yes_ "a release with NO target_date neither warns nor crashes" "$([ $rc -eq 0 ] && echo 0 || echo 1)"
if has "$out" "Undated"; then fail_ "  and is not named by either advisory"; else pass_ "  and is not named by either advisory"; fi

echo
echo "  gh32-release-target-advisory: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
