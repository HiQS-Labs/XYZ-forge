#!/usr/bin/env bash
# archive-commit.sh — GH-30 Phase 3 (Model A): the containment kernel commits the TRANSCRIPT (relay
# file) into the SEPARATE archive git repo, never the target repo, while code artifacts + the .tick
# token stay anchored to the target. Exercises relay-turn-lib.sh through the real claude-turn.sh shim
# with a stub agent (same pattern as worktree-isolation.sh), plus a direct-lib peer-commit case.
#
# What Phase 3 guarantees (the four QA-checklist items):
#   - a turn whose relay file lives in the archive writes its transcript to the archive repo and leaves
#     the TARGET tree free of relay-system/ (no relay commit in the target history)
#   - the code artifact still commits to the TARGET repo (archive redirect is transcript-only)
#   - the concurrent-commit guard (GH-13) does NOT reset/orphan a peer commit when token-tree (target)
#     and transcript-tree (archive) differ
#   - default (XYZ_ARCHIVE_ROOT unset, relay file under the target) is byte-for-byte the prior behavior
source "$(dirname "$0")/_setup.sh" archive-commit
export TICK_BIN="$TICK"

LIB="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-turn-lib.sh"
SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/claude-turn.sh"
[ -f "$LIB" ]  || fail "relay-turn-lib.sh not found at $LIB"
[ -f "$SHIM" ] || fail "claude-turn.sh not found at $SHIM"

tick_a init >/dev/null

# Target repo = the harness/coordination root $A (holds .tick + the code artifact). Committed baseline.
printf 'seed\n' >"$A/artifact.txt"
printf '.tick/\n' >"$A/.gitignore"
git -C "$A" add artifact.txt .gitignore >/dev/null 2>&1
git -C "$A" commit -q -m "seed target" >/dev/null 2>&1

# Archive repo = a SEPARATE git repo (Model A: a committed archive). Give it an identity + a root commit
# so a pathspec commit has an existing HEAD to extend.
ARCHIVE="$WORK/archive"
git init -q "$ARCHIVE"
git -C "$ARCHIVE" config user.email archive@t
git -C "$ARCHIVE" config user.name archive
git -C "$ARCHIVE" commit -q --allow-empty -m "init archive" >/dev/null 2>&1

# The relay thread lives INSIDE the archive repo, namespaced as the resolver would place it.
REL_DIR="$ARCHIVE/relay-system/target-slug/$(date +%F)"
mkdir -p "$REL_DIR"
ARCHIVE_RELAY="$REL_DIR/thread.md"
ARCHIVE_RELAY_REL="relay-system/target-slug/$(date +%F)/thread.md"
printf 'NEXT: Producer\nSTATUS: Open\n# archive thread\n' >"$ARCHIVE_RELAY"

# Stub `claude`: edits artifact.txt RELATIVE to CWD (= the worktree of the TARGET under isolation), and
# appends to the relay file via its ABSOLUTE archive path (it lives outside the target worktree).
STUB="$WORK/claude"
cat >"$STUB" <<STUB_EOF
#!/usr/bin/env bash
set -u
"\$TICK" claim "\$RELAY_TASK" --agent "\$RELAY_AGENT" --paths "artifact.txt" >/dev/null 2>&1
"\$TICK" ping  "\$RELAY_TASK" --agent "\$RELAY_AGENT" >/dev/null 2>&1
printf 'built by builder\n' >> artifact.txt
printf '\n### Round 1 · Builder\n' >> "$ARCHIVE_RELAY"
"\$TICK" release "\$RELAY_TASK" --agent "\$RELAY_AGENT" --to reviewer >/dev/null 2>&1
printf '{"usage":{"input_tokens":1,"output_tokens":1},"total_cost_usd":0}\n'
exit 0
STUB_EOF
chmod +x "$STUB"

seed_token(){ local task="$1"; tick_a log task.created "$task" --agent claude --paths "artifact.txt" >/dev/null; tick_a claim "$task" --agent claude --paths "artifact.txt" >/dev/null 2>&1; tick_a release "$task" --agent claude --to claude >/dev/null 2>&1; }

# --- (1) archive mode + worktree isolation ON: transcript → archive, code → target ---------------
seed_token RELAY-ARCHIVE-iso
A_BEFORE="$(git -C "$A" rev-parse HEAD)"
ARCH_BEFORE="$(git -C "$ARCHIVE" rev-parse HEAD)"
( cd "$A" && RELAY_AGENT=claude RELAY_FILE="$ARCHIVE_RELAY" RELAY_TASK=RELAY-ARCHIVE-iso RELAY_PEER=reviewer \
    CLAUDE_AGENT=claude CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$A" CLAUDE_LOG="$WORK/claude.iso.json" \
    ALLOW_PATHS="artifact.txt" CLAUDE_BLOCK_CMDS="" RELAY_WORKTREE_ISOLATION=1 \
    bash "$SHIM" >/dev/null 2>&1 ); rc=$?
[ "$rc" -eq 0 ] && pass "archive-mode isolated turn exits 0" || fail "archive-mode isolated turn rc=$rc"

# Code artifact committed to the TARGET repo.
[ "$(git -C "$A" rev-parse HEAD)" != "$A_BEFORE" ] && pass "code artifact committed to the target repo" || fail "no target commit"
grep -q "built by builder" "$A/artifact.txt" && pass "artifact edit landed in the target tree" || fail "artifact.txt missing builder content"

# Transcript committed to the ARCHIVE repo (a NEW commit, containing the relay file).
[ "$(git -C "$ARCHIVE" rev-parse HEAD)" != "$ARCH_BEFORE" ] && pass "transcript committed to the archive repo" || fail "no archive commit"
archlog="$(git -C "$ARCHIVE" show --stat --oneline HEAD)"
case "$archlog" in *"$ARCHIVE_RELAY_REL"*) pass "archive commit contains the relay file" ;; *) fail "archive commit missing the relay file (got: $archlog)" ;; esac
grep -q "Round 1 · Builder" "$ARCHIVE_RELAY" && pass "relay-file append persisted in the archive" || fail "relay append lost"

# The TARGET tree must be FREE of relay-system/ and carry NO transcript commit.
[ ! -e "$A/relay-system" ] && pass "target tree is free of relay-system/" || fail "relay-system/ leaked into the target repo"
targetlog="$(git -C "$A" log --oneline)"
case "$targetlog" in *"transcript"*) fail "a transcript commit leaked into the target history" ;; *) pass "no transcript commit in the target history" ;; esac

# --- (2) default unchanged: XYZ_ARCHIVE_ROOT unset, relay file UNDER the target → no archive mode --
printf 'NEXT: Producer\nSTATUS: Open\n# in-tree thread\n' >"$A/relay.md"
git -C "$A" add relay.md >/dev/null 2>&1; git -C "$A" commit -q -m "seed in-tree relay" >/dev/null 2>&1
STUB2="$WORK/claude-intree"
cat >"$STUB2" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "artifact.txt" >/dev/null 2>&1
printf 'built by builder 2\n' >> artifact.txt
printf '\n### Round 1 · Builder\n' >> relay.md
"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to reviewer >/dev/null 2>&1
printf '{"usage":{"input_tokens":1,"output_tokens":1},"total_cost_usd":0}\n'
exit 0
STUB_EOF
chmod +x "$STUB2"
seed_token RELAY-INTREE
A_BEFORE="$(git -C "$A" rev-parse HEAD)"
ARCH_BEFORE="$(git -C "$ARCHIVE" rev-parse HEAD)"
( cd "$A" && RELAY_AGENT=claude RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-INTREE RELAY_PEER=reviewer \
    CLAUDE_AGENT=claude CLAUDE_BIN="$STUB2" CLAUDE_TURN_ROOT="$A" CLAUDE_LOG="$WORK/claude.intree.json" \
    ALLOW_PATHS="artifact.txt" CLAUDE_BLOCK_CMDS="" RELAY_WORKTREE_ISOLATION=1 \
    bash "$SHIM" >/dev/null 2>&1 ); rc=$?
[ "$rc" -eq 0 ] && pass "in-tree (default) turn exits 0" || fail "in-tree turn rc=$rc"
[ "$(git -C "$A" rev-parse HEAD)" != "$A_BEFORE" ] && pass "in-tree turn committed to the target (relay + artifact together)" || fail "no target commit for in-tree turn"
grep -q "Round 1 · Builder" "$A/relay.md" && pass "in-tree relay edit committed to the target" || fail "in-tree relay edit lost"
[ "$(git -C "$ARCHIVE" rev-parse HEAD)" = "$ARCH_BEFORE" ] && pass "archive repo untouched when var unset (default unchanged)" || fail "archive was written on a default turn"

# --- (3) concurrent peer commit preserved when token-tree ≠ transcript-tree (direct-lib) ----------
# Drive the lib directly (in-ROOT), simulate worktree mode (RTL_WT_USED=1) so the GH-13 peer-preserve
# branch is exercised, and land a peer commit on the TARGET between rtl_before and rtl_enforce. Assert:
# the peer commit survives (not orphaned), the artifact commits on top, and the transcript still lands
# in the archive — proving the archive commit is isolated from the target's HEAD-moved guard.
# shellcheck disable=SC1090
( source "$LIB"
  export TICK_REPO_ROOT="$A"
  printf 'NEXT: Producer\nSTATUS: Open\n# peer-case thread\n' >"$ARCHIVE_RELAY"
  git -C "$ARCHIVE" add "$ARCHIVE_RELAY_REL" >/dev/null 2>&1; git -C "$ARCHIVE" commit -q -m "reset peer thread" >/dev/null 2>&1
  rtl_init "$A" "$ARCHIVE_RELAY" "artifact.txt"
  [ "${RTL_ARCHIVE_MODE:-0}" = 1 ] || { echo "  FAIL: rtl_init did not detect archive mode" >&2; exit 1; }
  rtl_before
  RTL_WT_USED=1                               # simulate a worktree-isolated turn (agent can't move target HEAD)
  printf 'built in peer case\n' >> "$A/artifact.txt"    # the turn's own allowlisted edit
  printf '\n### Peer-case round\n' >> "$ARCHIVE_RELAY"  # the turn's transcript edit (archive)
  git -C "$A" commit --allow-empty -q -m "concurrent peer commit during turn" >/dev/null 2>&1  # peer lands on target
  rtl_enforce "" claude "$WORK/peer.log" claude >/dev/null 2>&1
) ; rc=$?
[ "$rc" -eq 0 ] && pass "peer-case direct-lib enforce exits 0 (no reset+fail)" || fail "peer-case enforce rc=$rc (GH-13 regressed?)"
peerlog="$(git -C "$A" log --oneline)"
case "$peerlog" in *"concurrent peer commit during turn"*) pass "concurrent target commit PRESERVED (not orphaned) with archive transcript" ;; *) fail "peer commit orphaned when token-tree ≠ transcript-tree" ;; esac
case "$(cat "$A/artifact.txt")" in *"built in peer case"*) pass "turn's allowlist edit committed on top of the peer commit" ;; *) fail "artifact edit lost after peer preserve" ;; esac
archpeer="$(git -C "$ARCHIVE" log --oneline)"
case "$archpeer" in *"transcript"*) pass "transcript still committed to the archive under a moved target HEAD" ;; *) fail "archive transcript commit missing in the peer case" ;; esac

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
