#!/usr/bin/env bash
set -uo pipefail
#
# gh544-pre-push-gate.sh — GH-544: the gate moved to the push boundary, hosted CI is off.
#
# Three things ship together and each can fail independently:
#   1. githooks/pre-push  — refuses a push when the gate is red, and announces every bypass
#   2. .github/workflows/ci.yml — no longer fires automatically, WITHOUT losing its reasoning
#   3. marathon-closeout.sh — can tell "no checks configured" from "checks failed"
#
# (3) is the one that would have bitten silently. With CI off every PR has zero checks, `gh pr checks`
# exits non-zero, and the pre-fix code took its `exit 4` "refusing to merge" path — so an automated
# closeout could never merge again. It is tested here against a STUB gh, because the real
# distinguishing input (a PR with no checks at all) cannot be conjured from a test.
#
# The pre-push hook is driven with a STUB validate.sh in a throwaway repo. Running the real gate from
# inside a suite that is part of that gate would recurse and cost ~4 minutes per case.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
HOOK="$REPO/githooks/pre-push"
INSTALL="$REPO/githooks/install.sh"
CLOSEOUT="$REPO/relay-automation/marathon-closeout.sh"

pass=0; fail=0
ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

echo "== test: gh544-pre-push-gate =="

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh544-prepush.XXXXXX")"
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "mktemp failed" >&2; exit 1; }
cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

# A throwaway repo carrying the real hook and a STUB validate.sh whose verdict we control.
mkrepo() {  # <validate-exit-code> -> prints repo path
  local rc="$1" r
  r="$(mktemp -d "$WORK/repo.XXXXXX")"
  git -C "$r" init -q
  git -C "$r" config user.email t@t
  git -C "$r" config user.name t
  mkdir -p "$r/githooks"
  cp "$HOOK" "$r/githooks/pre-push"; chmod +x "$r/githooks/pre-push"
  cat > "$r/validate.sh" <<STUB
#!/usr/bin/env bash
if [ "\${1:-}" = "--print-mode" ]; then echo "validate.sh: PARALLEL mode 4-wide — stub"; exit 0; fi
echo "stub gate ran"
exit $rc
STUB
  chmod +x "$r/validate.sh"
  printf 'x\n' > "$r/a.txt"
  git -C "$r" add -A >/dev/null 2>&1
  git -C "$r" commit -qm seed >/dev/null 2>&1
  printf '%s' "$r"
}

# Drive the hook the way git does: stdin carries "<lref> <lsha> <rref> <rsha>".
drive() {  # <repo> <stdin-line> [env...]
  local r="$1" line="$2"; shift 2
  ( cd "$r" && printf '%s\n' "$line" | env "$@" bash githooks/pre-push 2>&1 )
}
NORMAL="refs/heads/main abc123 refs/heads/main def456"
DELETE="refs/heads/gone 0000000000000000000000000000000000000000 refs/heads/gone def456"

# --- (1) a red gate REFUSES the push ---------------------------------------------------------------
R_RED="$(mkrepo 1)"
out="$(drive "$R_RED" "$NORMAL")"; rc=$?
ok "a red gate refuses the push (exit 1)" "[ $rc -eq 1 ]"
ok "  and says the push was REFUSED" "printf '%s' \"\$out\" | grep -q 'push REFUSED'"
ok "  and names the escape hatch rather than leaving you stuck" \
   "printf '%s' \"\$out\" | grep -q -- '--no-verify'"
ok "  and states that nothing downstream will catch it (CI is off)" \
   "printf '%s' \"\$out\" | grep -q 'only gate'"

# --- (2) a green gate ALLOWS the push --------------------------------------------------------------
R_OK="$(mkrepo 0)"
out="$(drive "$R_OK" "$NORMAL")"; rc=$?
ok "a green gate allows the push (exit 0)" "[ $rc -eq 0 ]"
ok "  and reports the wall-clock it cost" "printf '%s' \"\$out\" | grep -qE 'GREEN in [0-9]+s'"
ok "  and announced the mode before running" "printf '%s' \"\$out\" | grep -q 'PARALLEL mode'"

# --- (3) bypasses work AND announce themselves -----------------------------------------------------
# A silent bypass is the failure mode: a skipped gate that says nothing looks exactly like a passing one.
out="$(drive "$R_RED" "$NORMAL" XYZ_SKIP_PREPUSH=1)"; rc=$?
ok "XYZ_SKIP_PREPUSH=1 lets a RED tree through (exit 0)" "[ $rc -eq 0 ]"
ok "  and says loudly that nothing was verified" \
   "printf '%s' \"\$out\" | grep -q 'nothing was verified'"

# --- (4) a delete-only push is not gated -----------------------------------------------------------
out="$(drive "$R_RED" "$DELETE")"; rc=$?
ok "a delete-only push skips the gate even when it is red (exit 0)" "[ $rc -eq 0 ]"
ok "  and says why" "printf '%s' \"\$out\" | grep -q 'delete-only'"
ok "  and did NOT run the gate" "! printf '%s' \"\$out\" | grep -q 'stub gate ran'"

# A mixed push (one delete + one real ref) must still gate — otherwise appending a delete is a bypass.
MIXED="$(printf 'refs/heads/gone 0000000000000000000000000000000000000000 refs/heads/gone def456\nrefs/heads/main abc123 refs/heads/main def456')"
out="$( cd "$R_RED" && printf '%s\n' "$MIXED" | bash githooks/pre-push 2>&1 )"; rc=$?
ok "a MIXED delete+real push is still gated (exit 1)" "[ $rc -eq 1 ]"

# --- (5) the installer is honest about a clone it has not wired ------------------------------------
R_I="$(mkrepo 0)"
cp "$INSTALL" "$R_I/githooks/install.sh"
out="$( cd "$R_I" && bash githooks/install.sh --check 2>&1 )"; rc=$?
ok "--check reports NOT INSTALLED on a fresh clone (exit 1)" "[ $rc -eq 1 ]"
ok "  and warns the clone will push WITHOUT the gate" \
   "printf '%s' \"\$out\" | grep -q 'WITHOUT running the gate'"
out="$( cd "$R_I" && bash githooks/install.sh 2>&1 )"; rc=$?
ok "install succeeds (exit 0)" "[ $rc -eq 0 ]"
# GH-549: the entrypoint lives in git METADATA, not the working tree — that is the whole fix. An
# in-tree hook wired through core.hooksPath vanished on any branch that predated it, and git skips a
# missing hook in total silence.
ok "  and writes the stub into the git hooks dir, not the tree" "[ -x '$R_I/.git/hooks/pre-push' ]"
ok "  and the stub is identifiable as ours" \
   "grep -q 'XYZ-GH549-PREPUSH-STUB' '$R_I/.git/hooks/pre-push'"
ok "  and core.hooksPath is left UNSET (it would override the stub)" \
   "[ -z \"\$(git -C '$R_I' config --get core.hooksPath || true)\" ]"
out="$( cd "$R_I" && bash githooks/install.sh --check 2>&1 )"; rc=$?
ok "--check now reports INSTALLED (exit 0)" "[ $rc -eq 0 ]"
out="$( cd "$R_I" && bash githooks/install.sh 2>&1 )"; rc=$?
ok "install is idempotent (exit 0 on a second run)" "[ $rc -eq 0 ]"

# The legacy wiring is MIGRATED, not tolerated — leaving it set would keep the silent-skip bug alive.
git -C "$R_I" config core.hooksPath githooks
out="$( cd "$R_I" && bash githooks/install.sh 2>&1 )"; rc=$?
ok "install CLEARS a legacy core.hooksPath=githooks (exit 0)" "[ $rc -eq 0 ]"
ok "  and says why it cleared it (GH-549)" "printf '%s' \"\$out\" | grep -q 'GH-549'"
ok "  leaving core.hooksPath unset" \
   "[ -z \"\$(git -C '$R_I' config --get core.hooksPath || true)\" ]"
# The stub location must NOT be read through `git rev-parse --git-path hooks`: that call OBEYS
# core.hooksPath, so with the legacy value still set it resolves to the in-tree githooks/ and the
# installer targets the very hook it delegates to. Found by this suite, not by review.
ok "  and did NOT overwrite the in-tree hook it delegates to" \
   "grep -q 'run the gate before anything reaches the remote' '$R_I/githooks/pre-push'"

# A stale core.hooksPath silently overrides the stub, so --check must FAIL on it even though the
# stub itself is present and perfect. Reporting only on the stub would report a gate that never runs.
git -C "$R_I" config core.hooksPath .other-hooks
out="$( cd "$R_I" && bash githooks/install.sh --check 2>&1 )"; rc=$?
ok "--check FAILS when a foreign core.hooksPath overrides the stub (exit 1)" "[ $rc -eq 1 ]"
ok "  and says the stub will not run" "printf '%s' \"\$out\" | grep -q 'will NOT run'"
out="$( cd "$R_I" && bash githooks/install.sh 2>&1 )"; rc=$?
ok "install REFUSES to clobber a different core.hooksPath (exit 4)" "[ $rc -eq 4 ]"
ok "  and names the path it refused to overwrite" "printf '%s' \"\$out\" | grep -q '.other-hooks'"
git -C "$R_I" config --unset core.hooksPath

# --uninstall removes only OUR stub. A pre-push hook some other tool installed is not ours to delete.
printf '#!/bin/sh\nexit 0\n' > "$WORK/foreign-hook"
cp "$R_I/.git/hooks/pre-push" "$WORK/our-stub"
cp "$WORK/foreign-hook" "$R_I/.git/hooks/pre-push"
out="$( cd "$R_I" && bash githooks/install.sh --uninstall 2>&1 )"; rc=$?
ok "--uninstall leaves a foreign pre-push hook alone" "[ -f '$R_I/.git/hooks/pre-push' ]"
ok "  and says so" "printf '%s' \"\$out\" | grep -q 'not this installer'"
out="$( cd "$R_I" && bash githooks/install.sh 2>&1 )"; rc=$?
ok "install REFUSES to overwrite a foreign pre-push hook (exit 4)" "[ $rc -eq 4 ]"
cp "$WORK/our-stub" "$R_I/.git/hooks/pre-push"; chmod +x "$R_I/.git/hooks/pre-push"
out="$( cd "$R_I" && bash githooks/install.sh --uninstall 2>&1 )"; rc=$?
ok "--uninstall removes OUR stub (exit 0)" "[ $rc -eq 0 ] && [ ! -f '$R_I/.git/hooks/pre-push' ]"

# --- (5b) THE PIN: a REAL `git push`, from a branch with no githooks/ ------------------------------
# Everything above drives the hook by invoking it directly, which is exactly what the ORIGINAL bug
# was invisible to: the defect was never in the hook's logic, it was that git never DISPATCHED to it.
# Only a real push through a real remote exercises that. This is the negative control for GH-549.
mkremote() {  # <repo> -> adds an 'origin' bare remote it can actually push to
  local r="$1" b
  b="$(mktemp -d "$WORK/bare.XXXXXX")"
  git init -q --bare "$b"
  git -C "$r" remote add origin "$b" 2>/dev/null || git -C "$r" remote set-url origin "$b"
}
# A branch that predates the hook: githooks/ simply does not exist on it.
strip_githooks() {  # <repo> <branch>
  local r="$1" br="$2"
  git -C "$r" checkout -q -b "$br"
  git -C "$r" rm -rq githooks
  git -C "$r" commit -qm "branch predating the in-tree hook"
}
realpush() {  # <repo> [env...] -> pushes the current branch; prints output + trailing RC=
  local r="$1"; shift
  local _o _r
  _o="$( cd "$r" && env "$@" git push -q origin HEAD:refs/heads/probe 2>&1 )"; _r=$?
  printf '%s\nRC=%s\n' "$_o" "$_r"
}

R_P="$(mkrepo 1)"   # RED gate
cp "$INSTALL" "$R_P/githooks/install.sh"
git -C "$R_P" add -A >/dev/null 2>&1; git -C "$R_P" commit -qm installer >/dev/null 2>&1
( cd "$R_P" && bash githooks/install.sh >/dev/null 2>&1 )
mkremote "$R_P"

out="$(realpush "$R_P")"
ok "REAL push on a branch WITH githooks/ is refused by the red gate" \
   "! printf '%s' \"\$out\" | grep -q 'RC=0'"
ok "  and it was the IN-TREE hook that ran (not the fallback)" \
   "! printf '%s' \"\$out\" | grep -q 'falling back'"

strip_githooks "$R_P" nohooks
out="$(realpush "$R_P")"
ok "THE PIN: REAL push on a branch with NO githooks/ still runs the gate" \
   "printf '%s' \"\$out\" | grep -q 'stub gate ran'"
ok "  and is REFUSED, not silently allowed" "! printf '%s' \"\$out\" | grep -q 'RC=0'"
ok "  and announces that it fell back rather than looking normal" \
   "printf '%s' \"\$out\" | grep -q 'falling back'"

# The pre-fix wiring, reproduced exactly: core.hooksPath=githooks on a branch without githooks/.
# It must SAIL THROUGH — that is the bug, and this control is what proves the fix is load-bearing
# rather than incidental.
git -C "$R_P" config core.hooksPath githooks
out="$(realpush "$R_P")"
ok "NEGATIVE CONTROL: the pre-fix core.hooksPath wiring pushes UNGATED and silent" \
   "printf '%s' \"\$out\" | grep -q 'RC=0' && ! printf '%s' \"\$out\" | grep -q 'stub gate ran'"
git -C "$R_P" config --unset core.hooksPath

# The two short-circuits have to hold on the FALLBACK path too, or an old branch would block
# `git push --delete` and ignore the automation bypass that every driven lane relies on.
out="$(realpush "$R_P" XYZ_SKIP_PREPUSH=1)"
ok "XYZ_SKIP_PREPUSH=1 works on the fallback path too" "printf '%s' \"\$out\" | grep -q 'RC=0'"
ok "  and still announces that nothing was verified" \
   "printf '%s' \"\$out\" | grep -q 'nothing was verified'"
out="$( cd "$R_P" && git push -q origin --delete probe 2>&1; printf '\nRC=%s\n' "$?" )"
ok "a delete-only push is not gated on the fallback path" "printf '%s' \"\$out\" | grep -q 'RC=0'"

# One install covers every LINKED WORKTREE of the clone — asserted because the header comment claims
# it. Git looks for hooks under the common dir, which a worktree shares with its parent, so a
# worktree cut from an old ref inherits the gate instead of being a fresh hole.
git -C "$R_P" worktree add -q "$WORK/wt-probe" -b wtprobe >/dev/null 2>&1
ok "a linked worktree resolves to the SAME hooks dir as its parent clone" \
   "[ \"\$(git -C '$WORK/wt-probe' rev-parse --git-common-dir)/hooks\" -ef '$R_P/.git/hooks' ]"
out="$( cd "$WORK/wt-probe" && git push -q origin HEAD:refs/heads/wtprobe 2>&1; printf '\nRC=%s\n' "$?" )"
ok "  and a push FROM that worktree is gated too" "printf '%s' \"\$out\" | grep -q 'stub gate ran'"
git -C "$R_P" worktree remove --force "$WORK/wt-probe" >/dev/null 2>&1

# Neither gate on the branch at all -> REFUSE. "Cannot run" must never resolve to "push anyway".
git -C "$R_P" rm -q validate.sh; git -C "$R_P" commit -qm "no gate at all" >/dev/null 2>&1
out="$(realpush "$R_P")"
ok "a branch with NEITHER gate refuses the push" "! printf '%s' \"\$out\" | grep -q 'RC=0'"
ok "  and says a gate that cannot run is not one that passed" \
   "printf '%s' \"\$out\" | grep -q 'not one that passed'"

# --- (6) ci.yml no longer fires automatically, and keeps its reasoning ------------------------------
CI="$REPO/.github/workflows/ci.yml"
ok "ci.yml has no push: trigger" "! grep -qE '^  push:' '$CI'"
ok "ci.yml has no pull_request: trigger" "! grep -qE '^  pull_request:' '$CI'"
ok "ci.yml still exists with its jobs intact" "grep -q '^jobs:' '$CI'"
ok "the GH-509 Phase 4 cost reasoning is PRESERVED for re-arm" \
   "grep -q 'THE PROMOTION BOUNDARY' '$CI'"
ok "the file states the re-arm trigger (repo goes public)" \
   "grep -qi 'RE-ARM WHEN THE REPO GOES PUBLIC' '$CI'"
ok "the macOS job still has NO workflow_dispatch of its own" \
   "! grep -qE '^      workflow_dispatch' '$CI'"

# --- (7) marathon-closeout distinguishes no-checks from checks-failed ------------------------------
# The real input (a PR with zero checks) cannot be conjured, so gh is stubbed. Both branches matter:
# treating "failed" as "none" would silently discard a real gate when CI returns.
mkgh() {  # <exit> <human-stdout> <json-stdout> -> dir to prepend to PATH
  # The --json call is answered separately from the prose call: the production block consults both,
  # and a stub that returned the same text for each could not tell them apart.
  local rc="$1" msg="$2" json="${3:-}" d
  d="$(mktemp -d "$WORK/bin.XXXXXX")"
  cat > "$d/gh" <<GHSTUB
#!/usr/bin/env bash
case "\$*" in
  *--json*) $( [ -n "$json" ] && printf 'echo %q; exit 0' "$json" || printf 'exit 1' ) ;;
  "pr checks"*) echo "$msg"; exit $rc ;;
  *) echo "stub-gh: \$*" ; exit 0 ;;
esac
GHSTUB
  chmod +x "$d/gh"; printf '%s' "$d"
}
extract_block() {  # isolate the checks block so the whole closeout need not run
  sed -n '/# >>> GH-544 checks-gate BEGIN/,/# <<< GH-544 checks-gate END/p' "$CLOSEOUT"
}
run_block() {  # <ghdir> -> runs just the checks block; prints its output plus a trailing RC=<code>
  # TWO THINGS HERE ARE LOAD-BEARING, and each was got wrong once before this shape:
  #
  # 1. `set -euo pipefail` — the PRODUCTION options (marathon-closeout.sh:12). Without them this
  #    harness green-lit a version of the block that was DEAD CODE in production: under `set -e` a
  #    failing `var="$(cmd)"` exits before the next line, so `_checks_rc=$?` never ran and the entire
  #    no-checks branch was unreachable. A test that runs code under gentler options than production
  #    is not testing production. Caught by a cross-model review, not by this suite.
  #
  # 2. The block `exit 4`s on a real failure, which kills the subshell — so the exit code must be
  #    taken FROM the subshell, not echoed inside it. An earlier version echoed after the eval and
  #    never reached that line on the one branch that mattered.
  local d="$1" _o _r
  _o="$( set -euo pipefail; PATH="$d:$PATH"; PR_URL="https://example/pr/1"
         eval "$(extract_block)" 2>&1 )"; _r=$?
  printf '%s\nRC=%s\n' "$_o" "$_r"
}

# (a) --json unavailable, prose says none  -> the fallback signal carries it
GH_NONE="$(mkgh 1 'no checks reported on the {branch} branch')"
out="$(run_block "$GH_NONE")"
ok "zero configured checks does NOT refuse the merge (prose fallback)" "printf '%s' \"\$out\" | grep -q 'RC=0'"
ok "  and says it is merging WITHOUT CI rather than staying silent" \
   "printf '%s' \"\$out\" | grep -q 'WITHOUT CI'"
ok "  and names GH-544 so the reason is findable" "printf '%s' \"\$out\" | grep -q 'GH-544'"

# (b) --json returns an empty list -> structured signal carries it, wording-independent
GH_JSON_EMPTY="$(mkgh 1 'some other wording entirely' '[]')"
out="$(run_block "$GH_JSON_EMPTY")"
ok "an empty --json bucket is accepted as no-checks even if the PROSE changes" \
   "printf '%s' \"\$out\" | grep -q 'RC=0'"
ok "  and says which signal it used" "printf '%s' \"\$out\" | grep -q 'json bucket'"

# (c) --json returns a NON-empty list while exiting non-zero -> that is a real failure, refuse
GH_JSON_FAIL="$(mkgh 1 'tier1  fail' '[{"bucket":"fail"}]')"
out="$(run_block "$GH_JSON_FAIL")"
ok "a NON-empty --json bucket with a failure still refuses (exit 4)" \
   "printf '%s' \"\$out\" | grep -q 'RC=4'"

GH_FAIL="$(mkgh 1 'tier1  fail  2m  https://example/run/1')"
out="$(run_block "$GH_FAIL")"
ok "a genuine check FAILURE still refuses the merge (exit 4)" \
   "printf '%s' \"\$out\" | grep -q 'RC=4'"
ok "  and says checks are not green" "printf '%s' \"\$out\" | grep -q 'not green'"
ok "  and echoes gh's own output so the failure is visible" \
   "printf '%s' \"\$out\" | grep -q 'tier1'"

GH_OK="$(mkgh 0 'all checks passed')"
out="$(run_block "$GH_OK")"
ok "passing checks proceed silently (exit 0)" "printf '%s' \"\$out\" | grep -q 'RC=0'"
ok "  and do NOT claim CI was absent" "! printf '%s' \"\$out\" | grep -q 'WITHOUT CI'"

echo "  gh544-pre-push-gate: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
