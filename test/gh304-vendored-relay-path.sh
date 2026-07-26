#!/usr/bin/env bash
# test/gh304-vendored-relay-path.sh — GH-304 regression.
#
# Primary bug: driving a relay whose file lives in a SUBDIRECTORY of the true git repo root (the
# same-repo vendored `.xyz/` shape) used to embed a CWD-relative path in the turn-taker's prompt and
# fail to seed the file into the isolation worktree, so a headless turn-taker (Codex) whose worktree
# roots at the git toplevel could not find the relay file — a 100% failure. relay-drive.sh now
# absolutizes the relay path before exporting it, and rtl_turn_prompt derives the repo-root-relative
# EDIT path robustly, so the embedded path and the seeded path are the true repo-root-relative one.
#
# Secondary bug: when the relay file is gitignored, a turn that DID append findings produces the same
# empty commit-set as a genuine no-op, and both used to print byte-identical "no tracked changes
# (token-only move?)". rtl_enforce now prints a distinct, accurate message for the gitignored case.
#
# Unit-tests rtl_turn_prompt / rtl_worktree_begin / rtl_enforce directly (same pattern as
# relay-file-seeding-visibility.sh and relay-commit-pathspec.sh) — no model stub needed.
source "$(dirname "$0")/_setup.sh" gh304-vendored-relay-path
LIB="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-turn-lib.sh"
# shellcheck source=relay-automation/relay-turn-lib.sh
source "$LIB"

# Ensure $A has a checked-out branch at a real commit, independent of the ambient git
# init.defaultBranch (some hosts default the bare remote's HEAD to master while _setup.sh pushes main,
# leaving the clone with an unborn HEAD that `git worktree add HEAD` can't check out). Defensive only —
# does not affect what the test proves.
git -C "$A" rev-parse --verify -q HEAD >/dev/null 2>&1 \
  || git -C "$A" checkout -q -B main origin/main >/dev/null 2>&1 \
  || git -C "$A" commit -q --allow-empty -m "gh304 base" >/dev/null 2>&1 || true

# --- Case 1 (primary): relay file in a SUBDIR of the git root, passed ABSOLUTE (as relay-drive does) ---
# `.xyz/` is a plain subdir (no .git of its own) — the exact vendored-.xyz shape. RTL_ROOT resolves to
# the git toplevel ($A), so the correct repo-root-relative path is `.xyz/relay-system/…`.
REL=".xyz/relay-system/2026-07-24/gh304.md"
RELAY_SUB="$A/$REL"
mkdir -p "$(dirname "$RELAY_SUB")"
printf 'STATUS: In progress\nNEXT: Producer\nGH304 CONTENT %s\n' "$$" >"$RELAY_SUB"

rtl_init "$A" "$RELAY_SUB" ""

# Env-independent check of the normalization that DRIVES seeding: the allowlist entry (and thus the
# rtl_worktree_begin `-e "$RTL_ROOT/$a"` seed check) must be the true repo-root-relative path.
if [ "${RTL_ALLOW[0]:-}" = "$REL" ]; then
  pass "rtl_init normalizes the allowlist entry to the repo-root-relative path ($REL)"
else
  fail "rtl_init allowlist entry is '${RTL_ALLOW[0]:-}', expected '$REL'"
fi

prompt="$(rtl_turn_prompt codex "$RELAY_SUB" RELAY-TURN "" other)"
if grep -qF "Read $REL " <<<"$prompt"; then
  pass "turn prompt embeds the repo-root-relative relay path ($REL)"
else
  fail "turn prompt did not embed the repo-root-relative relay path; got: $(grep -oE 'Read [^ ]+' <<<"$prompt" | head -1)"
fi
# The absolute path must NOT leak into the prompt — an absolute EDIT path invites a write straight into
# RTL_ROOT, bypassing the worktree (the exact hazard rtl_turn_prompt's repo-root-relative rule avoids).
if grep -qF "Read $A/" <<<"$prompt"; then
  fail "turn prompt leaked an ABSOLUTE relay path"
else
  pass "turn prompt did not leak an absolute relay path"
fi
# And it must not degrade to a bare basename (unresolvable from the worktree root).
if grep -qE "Read gh304\.md( |$)" <<<"$prompt"; then
  fail "turn prompt embedded a bare basename (loses the .xyz/ prefix)"
else
  pass "turn prompt kept the full repo-root-relative prefix"
fi

wt="$(rtl_worktree_begin)"; rc=$?
if [ "$rc" -eq 0 ] && [ -n "$wt" ] && [ -f "$wt/$REL" ]; then
  pass "worktree seeds the relay file at the repo-root-relative path"
  if grep -q "GH304 CONTENT $$" "$wt/$REL" 2>/dev/null; then
    pass "seeded worktree copy has the CURRENT (uncommitted) content"
  else
    fail "seeded worktree copy has stale content"
  fi
else
  fail "worktree did not seed the relay file at $REL (rc=$rc, wt=$wt)"
fi
[ -n "$wt" ] && { git -C "$A" worktree remove --force "$wt" >/dev/null 2>&1 || rm -rf "$wt"; git -C "$A" worktree prune >/dev/null 2>&1; }

# --- Case 2 (secondary): a gitignored relay file gets a distinct, accurate empty-commit message ---
printf '.tick/\nrelay-system/\n' >"$A/.gitignore"
git -C "$A" add .gitignore >/dev/null 2>&1
git -C "$A" commit -q -m "seed gitignore" >/dev/null 2>&1
LOG="$WORK/enforce.log"; : >"$LOG"

IGN="relay-system/2026-07-24/gh304-ignored.md"
mkdir -p "$(dirname "$A/$IGN")"
printf 'STATUS: In progress\nNEXT: Producer\n' >"$A/$IGN"
rtl_init "$A" "$A/$IGN" ""
rtl_before
printf '\n### Round 1 · Reviewer\nreal graded finding appended here %s\n' "$$" >>"$A/$IGN"   # real work
out="$( rtl_enforce "T-IGN" "codex" "$LOG" "codex" 2>/dev/null )"; rc=$?
[ "$rc" -eq 0 ] && pass "gitignored relay turn still exits 0" || fail "gitignored case expected exit 0, got $rc"
if grep -q "gitignored" <<<"$out" && grep -q "NOT git-tracked" <<<"$out"; then
  pass "gitignored relay file gets the distinct 'gitignored / not git-tracked' message"
else
  fail "gitignored relay file did not get the distinct message; got: $out"
fi
if grep -q "no tracked changes (token-only move?)" <<<"$out"; then
  fail "gitignored relay file still prints the misleading 'no tracked changes (token-only move?)' message"
else
  pass "gitignored relay file does NOT print the misleading token-only-move message"
fi

# --- Case 3 (control): a TRACKED, unchanged relay file (a genuine no-op) keeps the original message ---
printf 'STATUS: Open\n# tracked relay\n' >"$A/tracked-relay.md"
git -C "$A" add tracked-relay.md >/dev/null 2>&1
git -C "$A" commit -q -m "seed tracked relay" >/dev/null 2>&1
rtl_init "$A" "$A/tracked-relay.md" ""
rtl_before
# deliberately no edit → a true token-only move
out3="$( rtl_enforce "T-NOOP" "codex" "$LOG" "codex" 2>/dev/null )"; rc3=$?
[ "$rc3" -eq 0 ] && pass "control: tracked no-op turn exits 0" || fail "control expected exit 0, got $rc3"
if grep -q "no tracked changes (token-only move?)" <<<"$out3"; then
  pass "control: a genuine tracked no-op still reports 'no tracked changes (token-only move?)'"
else
  fail "control: expected the original token-only-move message for a tracked no-op; got: $out3"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
