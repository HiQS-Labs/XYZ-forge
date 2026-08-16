#!/usr/bin/env bash
set -euo pipefail
#
# gh527-destructive-git-guard.sh — GH-527: a git command that overwrites the working tree
# from a committed state must leave the tracked files it destroys recoverable.
#
# The guard is SNAPSHOT-THEN-ALLOW, not refuse-when-dirty, so the assertions below are about
# what it PRESERVES, not what it blocks. Two properties carry the whole issue:
#
#   1. It fires on a dirty tree and the destroyed content is recoverable END-TO-END
#      (GH-527 acceptance 4: "destroy -> recover from the snapshot", demonstrated not asserted).
#   2. It stays SILENT on a clean tree (GH-527 acceptance 3), because a guard that fires on the
#      safe case is a blanket, and a blanket trains the override reflex that makes it useless.
#
# Blast radius is asserted in both directions to match the issue's own reproduced fixture:
# TRACKED modifications are destroyed, untracked files survive. If that ever inverts, the guard
# is snapshotting the wrong set.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
GUARD="$REPO/relay-automation/hooks/gh527-destructive-git-guard.sh"

pass=0; fail=0
ok(){ if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }

echo "== test: gh527-destructive-git-guard =="

mkrepo() {
  _r="$(mktemp -d "${TMPDIR:-/tmp}/gh527.XXXXXX")"
  git -C "$_r" init -q
  git -C "$_r" config user.email t@t
  git -C "$_r" config user.name t
  printf 'v1\n' > "$_r/peer.txt"
  git -C "$_r" add peer.txt
  git -C "$_r" commit -qm init
  printf '%s\n' "$_r"
}

# hook_out <repo> <command> — run the guard with a PreToolUse-shaped payload, capture stderr
hook_out() {
  printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"%s"}}' "$1" "$2" \
    | bash "$GUARD" 2>&1 || true
}

ok "guard script exists and is executable" "[ -x '$GUARD' ]"

# --- (1) dirty tree: fires, and the snapshot actually contains the doomed content ------------
R="$(mkrepo)"
printf 'PEER-UNCOMMITTED-WORK\n' > "$R/peer.txt"
printf 'untracked peer work\n'   > "$R/peer-new.txt"
OUT="$(hook_out "$R" "git reset --hard HEAD")"

ok "dirty tree: guard announces the snapshot" "printf '%s' \"\$OUT\" | grep -q 'snapshot saved'"
ok "dirty tree: message names the command shape" "printf '%s' \"\$OUT\" | grep -q 'reset --hard'"
SNAP="$(ls -d "$R"/.tick/orphan-backups/*/ 2>/dev/null | head -1 || true)"
ok "dirty tree: a snapshot directory was created" "[ -n '$SNAP' ]"
ok "snapshot holds the pre-destruction content" \
   "grep -q 'PEER-UNCOMMITTED-WORK' '$SNAP/peer.txt' 2>/dev/null"
ok "snapshot does NOT include untracked files (they survive the command)" \
   "[ ! -f '$SNAP/peer-new.txt' ]"

# --- (2) recovery is demonstrated, not asserted (acceptance 4) --------------------------------
git -C "$R" reset --hard HEAD >/dev/null 2>&1
ok "the destructive command really did destroy the tracked edit" \
   "grep -q '^v1$' '$R/peer.txt'"
ok "untracked file survived the command (matches the issue's fixture)" \
   "[ -f '$R/peer-new.txt' ]"
cp -R "$SNAP". "$R"/
ok "RECOVERY: content restored from the snapshot end-to-end" \
   "grep -q 'PEER-UNCOMMITTED-WORK' '$R/peer.txt'"
rm -rf "$R"

# --- (3) THE CONTROL: clean tree must stay silent (acceptance 3) ------------------------------
# Without this the guard is a blanket. This assertion is the reason the guard checks tracked
# dirt at all rather than simply matching on the command.
C="$(mkrepo)"
OUT="$(hook_out "$C" "git reset --hard HEAD")"
ok "CONTROL: clean tree — guard stays silent" "[ -z \"\$OUT\" ]"
ok "CONTROL: clean tree — no snapshot directory created" \
   "[ -z \"\$(ls -d '$C'/.tick/orphan-backups/*/ 2>/dev/null || true)\" ]"

# --- (4) every destructive spelling, including the ones an agy review found slipping ----------
# `git checkout <path>` (no `--`) and `git restore <path>` both slipped the first draft's regex.
# They are the most likely spellings an agent reaches for to revert a file, and both were verified
# to destroy a peer edit. Over-matching is cheap here — the guard only ever snapshots — so these
# are matched broadly on purpose.
printf 'dirty\n' > "$C/peer.txt"
# `git clean` is deliberately NOT in this loop: this fixture has only a TRACKED modification, and
# clean does not touch tracked files, so the guard correctly finds nothing to snapshot and stays
# silent. Asserting "snapshot saved" here would demand the wrong behaviour. Section 4b drives clean
# against the set it actually destroys.
for shape in "git reset --hard HEAD" "git checkout -- peer.txt" "git checkout peer.txt" \
             "git restore peer.txt" "git stash"; do
  OUT="$(hook_out "$C" "$shape")"
  ok "fires on: $shape" "printf '%s' \"\$OUT\" | grep -q 'snapshot saved'"
done

# --- (4b) `git clean` is the INVERSE case, and it needs its own everything --------------------
# clean deletes UNTRACKED files and leaves tracked modifications alone — the exact opposite of the
# other four shapes. The first draft matched clean but still snapshotted only tracked files, so it
# announced cover that did not exist. Worse, the snapshot went into `.tick/`, which `git clean -fdx`
# then deleted along with everything else: the guard destroyed its own evidence. Both found by
# testing recovery rather than asserting it.
K="$(mkrepo)"
printf 'tracked-edit\n' > "$K/peer.txt"          # tracked modification — clean must NOT save this
printf 'UNTRACKED-WORK\n' > "$K/untracked.txt"   # untracked — clean DOES destroy this
OUT="$(hook_out "$K" "git clean -fdx")"
ok "clean: names the untracked set, not the tracked one" \
   "printf '%s' \"\$OUT\" | grep -q 'untracked file'"
CSNAP="$(printf '%s' "$OUT" | sed -n 's/.*snapshot saved -> //p')"
ok "clean: snapshot is OUTSIDE the repo (git clean -x would delete an in-repo one)" \
   "case '$CSNAP' in '$K'*) false ;; /*) true ;; *) false ;; esac"
ok "clean: snapshot holds the untracked file" "[ -f '$CSNAP/untracked.txt' ]"
ok "clean: snapshot does NOT hold the tracked modification (clean would not touch it)" \
   "[ ! -f '$CSNAP/peer.txt' ]"
( cd "$K" && git clean -fdx >/dev/null 2>&1 )
ok "clean really destroyed the untracked file" "[ ! -f '$K/untracked.txt' ]"
ok "clean: the snapshot SURVIVED the command that deleted everything else" "[ -d '$CSNAP' ]"
cp -R "$CSNAP"/. "$K"/ 2>/dev/null || true
ok "clean: RECOVERY restores the untracked file end-to-end" \
   "grep -q 'UNTRACKED-WORK' '$K/untracked.txt' 2>/dev/null"
rm -rf "$CSNAP" "$K"

# --- (5) read-only git and non-Bash tools must NOT trip it ------------------------------------
for safe in "git status" "git stash list" "git log --oneline" "git diff"; do
  OUT="$(hook_out "$C" "$safe")"
  ok "silent on read-only: $safe" "[ -z \"\$OUT\" ]"
done
OUT="$(printf '{"tool_name":"Edit","cwd":"%s","tool_input":{"command":"git reset --hard"}}' "$C" | bash "$GUARD" 2>&1 || true)"
ok "ignores non-Bash tool calls" "[ -z \"\$OUT\" ]"

# --- (6) the documented escape hatch works ----------------------------------------------------
OUT="$(printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"git reset --hard HEAD"}}' "$C" \
  | XYZ_NO_GIT_SNAPSHOT=1 bash "$GUARD" 2>&1 || true)"
ok "XYZ_NO_GIT_SNAPSHOT=1 disables the guard" "[ -z \"\$OUT\" ]"
rm -rf "$C"

# --- (7) the rail exists and names all three shapes (acceptance 1) -----------------------------
ok "AGENTS.md rail names reset --hard"      "grep -q 'reset --hard' '$REPO/AGENTS.md'"
ok "AGENTS.md rail names checkout -- <path>" "grep -q 'checkout --' '$REPO/AGENTS.md'"
ok "AGENTS.md rail names stash"              "grep -qi 'git stash' '$REPO/AGENTS.md'"
ok "AGENTS.md rail points at the guard"      "grep -q 'gh527-destructive-git-guard' '$REPO/AGENTS.md'"

# --- (8) registered as a PreToolUse Bash hook (acceptance 5) -----------------------------------
ok "hook registered in .claude/settings.json" \
   "grep -q 'gh527-destructive-git-guard' '$REPO/.claude/settings.json'"

echo "  gh527-destructive-git-guard: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
