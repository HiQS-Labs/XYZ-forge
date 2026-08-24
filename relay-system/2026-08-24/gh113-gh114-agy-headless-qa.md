# RELAY · GH-113/GH-114 QA — agy headless scratch + TTY fixes
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-24.
-->

NEXT: claude-a
STATUS: Approved
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-113-gh-114-qa-agy-headless-scratch-tty-fixes): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **gh113-114-review.diff** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-08-24

### Artifact — gh113-114-review.diff
```
diff --git a/relay-automation/relay-turn-lib.sh b/relay-automation/relay-turn-lib.sh
index 9b026bfe..8b756f1d 100644
--- a/relay-automation/relay-turn-lib.sh
+++ b/relay-automation/relay-turn-lib.sh
@@ -808,6 +808,11 @@ rtl_worktree_end() {  # [<wt>] — sets RTL_WT_OFFLANE (0|1); copies allowlist b
     esac
     rtl_in_allow "$path" && continue
     rtl_is_containment_ignored "$path" && continue   # GH-107: opt-in tool-cache exemption
+    # GH-113: same scratch relocation as rtl_check's non-worktree path — a scratch-shaped untracked
+    # root file in the throwaway worktree is moved into RTL_ROOT's .tick/scratch for inspection
+    # (the worktree itself is destroyed below, which would otherwise destroy the evidence) and the
+    # turn is NOT failed on it.
+    rtl_scratch_relocate "$path" "$wt" "$RTL_ROOT" && continue
     rtl_offlane_hint "$path"                         # GH-90: name a file-vs-directory lane-spec mistake
     rtl_trace "rtl_worktree_end: OFFLANE path=$path"
     RTL_WT_OFFLANE=1                    # a non-allowlist, non-.tick change → off-lane
@@ -987,6 +992,43 @@ rtl_orphan_backup() {  # <path> — copy pre-revert content aside; must never bl
   rtl_log_always "rtl_check: orphan-backup path=$p dest=$RTL_ORPHAN_BACKUP"
 }
 
+# GH-113 — relocate, don't fail, the headless builder's root-level scratch.
+#
+# The observed incident (marathon/daybreak-wave-2, 2026-08-20): the agy builder wrote fix_lens1.py /
+# test_lens6.py / tmp.json into the working-tree ROOT while debugging, rtl_check reverted them at
+# exit 6, and a turn whose actual lane work was fine died on incidental scratch. Prose in the prompt
+# is not a guarantee the builder model weights, so this is the mechanical half of the fix: a
+# scratch-SHAPED write is moved into the sanctioned scratch lane and the turn proceeds.
+#
+# Deliberately NARROW — this is a room, not an amnesty (same line GH-91 drew for .relay-scratch):
+#   - ROOT-LEVEL only (no "/" in the path): the incident shape is a transient script dropped in the
+#     tree root; a nested off-lane path is a lane mistake, not scratch, and still violates.
+#   - UNTRACKED only: an edit to a TRACKED file is an off-lane content change whatever its name —
+#     the GH-22 self-escape backstop must keep biting there (GH-113 acceptance pins this).
+#   - NAME must look like transient scratch (tmp*/temp*/scratch*/debug*/test_*/fix_*/repro_*/probe_*
+#     prefix, or *.tmp/*.temp/*.bak/*.orig/~ suffix). "offlane.md" and friends still violate.
+# The destination is .tick/scratch/ (exempted intrinsically, never rides into a commit, recoverable
+# for inspection) — NOT .relay-scratch/, which rtl_enforce sweeps at end of turn and which would
+# therefore destroy the evidence this function exists to preserve.
+rtl_scratch_relocate() {  # <path> <src-root> [dest-root] — 0 = relocated, 1 = not scratch-shaped
+  local p="$1" src_root="$2" dest_root="${3:-$2}" dest
+  [[ -n "$p" && -n "$src_root" ]] || return 1
+  case "$p" in ""|.|..|*/*|.*) return 1 ;; esac
+  [[ "$p" =~ ^(tmp|temp|scratch|debug|test_|fix_|repro_|probe_) ]] \
+    || [[ "$p" =~ \.(tmp|temp|bak|orig)$ ]] \
+    || [[ "$p" == *~ ]] \
+    || return 1
+  git -C "$src_root" ls-files --error-unmatch -- "$p" >/dev/null 2>&1 && return 1
+  [[ -e "$src_root/$p" ]] || return 1
+  dest="${RTL_SCRATCH_DIR:="${dest_root:?}/.tick/scratch/$(date -u +%Y%m%dT%H%M%SZ)-$$"}"
+  mkdir -p "$dest" 2>/dev/null || return 1
+  mv "$src_root/$p" "$dest/$p" 2>/dev/null || return 1
+  printf '%s-turn: SCRATCH RELOCATION (GH-113): untracked root-level %s moved to %s — turn NOT failed. Write scratch under $TMPDIR or .relay-scratch/ instead.\n' \
+    "${RTL_TOOL:-relay}" "$p" "$dest" >&2
+  rtl_log_always "rtl_scratch_relocate: path=$p src=$src_root dest=$dest (GH-113)"
+  return 0
+}
+
 rtl_check() {  # <path> — reads RTL_ROOT/RTL_LOG_REL/RTL_TOOL, sets RTL_VIOLATION
   local p="$1"
   [[ -n "$p" ]] || return 0
@@ -1015,6 +1057,10 @@ rtl_check() {  # <path> — reads RTL_ROOT/RTL_LOG_REL/RTL_TOOL, sets RTL_VIOLAT
     rtl_trace "rtl_check: ALLOW path=$p"
     return 0
   fi
+  # GH-113: scratch-shaped untracked root files relocate instead of violating — AFTER the allowlist
+  # check so an explicitly allowlisted path keeps its normal handling, and BEFORE the revert so the
+  # turn is not failed on transient scratch.
+  rtl_scratch_relocate "$p" "$RTL_ROOT" && return 0
   printf '%s-turn: OFF-ALLOWLIST change: %s — reverting\n' "$RTL_TOOL" "$p" >&2
   rtl_log_always "rtl_check: OFF-ALLOWLIST path=$p tool=$RTL_TOOL — reverting"
   rtl_offlane_hint "$p"    # GH-90: name a file-vs-directory lane-spec mistake before the revert
diff --git a/test/gh113-headless-scratch.sh b/test/gh113-headless-scratch.sh
new file mode 100755
index 00000000..12e6d367
--- /dev/null
+++ b/test/gh113-headless-scratch.sh
@@ -0,0 +1,146 @@
+#!/usr/bin/env bash
+# test/gh113-headless-scratch.sh — GH-113: a headless builder's root-level scratch no longer fails
+# the turn at exit 6; it relocates to the sanctioned scratch lane instead.
+#
+# The observed incident (marathon/daybreak-wave-2, 2026-08-20): the agy builder dropped fix_lens1.py,
+# test_lens6.py and tmp.json into the working-tree root while debugging; rtl_check reverted them as
+# OFF-ALLOWLIST and failed the turn (exit 6) even though the lane work itself was fine. GH-91 had
+# already sanctioned a scratch ROOM (.relay-scratch/, opt-in by location); GH-113 adds relocation for
+# the complementary shape — the builder writes scratch AT THE ROOT, where no affordance existed.
+#
+# Drives the lib functions directly (same shape as test/gh91-relay-scratch.sh): no agy binary, no
+# timing dependence. Controls pin that this is a room, not an amnesty: non-scratch untracked names,
+# nested untracked paths, and TRACKED off-lane edits all still violate.
+set -uo pipefail
+
+HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
+LIB="$HERE/relay-automation/relay-turn-lib.sh"
+
+WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh113-headless-scratch.XXXXXX")"
+[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "FATAL: mktemp -d failed" >&2; exit 1; }
+. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"
+fixture_guard_init "$WORK"
+trap 'rm -rf "$WORK"' EXIT
+
+PASS=0; FAIL=0
+pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
+fail() { echo "  FAIL: $*"; FAIL=$((FAIL+1)); }
+
+# A throwaway repo standing in for RTL_ROOT: one committed allowlist lane file plus a second
+# TRACKED file (for the tracked-off-lane control GH-113's acceptance pins).
+R="$WORK/repo"
+mkdir -p "$R"
+require_fixture "$R" "fixture repo"
+git -C "$R" init -q
+git -C "$R" config user.email t@example.com
+git -C "$R" config user.name t
+printf 'lane v1\n' >"$R/lane.md"
+printf 'tracked v1\n' >"$R/tracked.md"
+git -C "$R" add -A
+git -C "$R" commit -qm init
+
+# shellcheck source=/dev/null
+source "$LIB"
+RTL_ROOT="$R"
+RTL_TOOL="agy"
+RTL_LOG=""
+RTL_LOG_REL=""
+RTL_ARTIFACT=""
+RTL_ALLOW=("lane.md")
+
+scratch_dir_of() { find "$R/.tick/scratch" -name "$1" 2>/dev/null | head -1; }
+
+# ── (1) the incident shape: root scratch relocates, turn does NOT fail ───────────────────────────
+printf '{"lens":6}\n' >"$R/tmp.json"
+printf 'import sys\n' >"$R/fix_lens1.py"
+printf 'import sys\n' >"$R/test_lens6.py"
+RTL_VIOLATION=0
+rtl_check "tmp.json"; rtl_check "fix_lens1.py"; rtl_check "test_lens6.py"
+[ "$RTL_VIOLATION" -eq 0 ] && pass "rtl_check: root tmp.json/fix_*/test_* scratch is NOT a violation" \
+  || fail "rtl_check: incident-shape scratch flagged as violation"
+[ ! -e "$R/tmp.json" ] && [ ! -e "$R/fix_lens1.py" ] && [ ! -e "$R/test_lens6.py" ] \
+  && pass "rtl_check: scratch files are gone from the tree root" \
+  || fail "rtl_check: scratch file left in tree root"
+for f in tmp.json fix_lens1.py test_lens6.py; do
+  [ -n "$(scratch_dir_of "$f")" ] && pass "rtl_check: $f relocated under .tick/scratch/ (recoverable)" \
+    || fail "rtl_check: $f not found under .tick/scratch/"
+done
+cmp -s <(printf '{"lens":6}\n') "$(scratch_dir_of tmp.json)" && pass "rtl_check: relocated content is intact" \
+  || fail "rtl_check: relocated content corrupted"
+
+# ── (2) the amnesty line: what still violates ────────────────────────────────────────────────────
+# (2a) untracked but NOT scratch-shaped by name (the existing off-lane shape from test/agy-turn.sh).
+printf 'off-lane\n' >"$R/offlane.md"
+RTL_VIOLATION=0; rtl_check "offlane.md"
+[ "$RTL_VIOLATION" -eq 1 ] && pass "CONTROL: untracked non-scratch root file (offlane.md) still violates" \
+  || fail "CONTROL: offlane.md not flagged — the relocation is an amnesty, not a room"
+
+# (2b) scratch-shaped but NESTED — a lane mistake, not transient scratch.
+mkdir -p "$R/src"; printf 'x\n' >"$R/src/tmp.json"
+RTL_VIOLATION=0; rtl_check "src/tmp.json"
+[ "$RTL_VIOLATION" -eq 1 ] && pass "CONTROL: nested untracked src/tmp.json still violates (root-level only)" \
+  || fail "CONTROL: nested scratch-shaped path not flagged"
+
+# (2c) TRACKED off-lane edit — GH-113 acceptance: exit 6 unchanged.
+printf 'tracked v2\n' >"$R/tracked.md"
+RTL_VIOLATION=0; rtl_check "tracked.md"
+[ "$RTL_VIOLATION" -eq 1 ] && pass "CONTROL: off-lane edit to a TRACKED file still violates (exit-6 path intact)" \
+  || fail "CONTROL: tracked off-lane edit not flagged"
+
+# (2d) dot-prefixed paths are never relocation candidates.
+printf 'x\n' >"$R/.env.tmp-local"
+RTL_VIOLATION=0; rtl_check ".env.tmp-local"
+[ "$RTL_VIOLATION" -eq 1 ] && pass "CONTROL: dot-prefixed root file still violates" \
+  || fail "CONTROL: dotfile escaped containment"
+
+# ── (3) rtl_enforce end-to-end: scratch + lane edit -> exit 0, no scratch in the commit ──────────
+git -C "$R" checkout -q -- . && rm -f "$R/offlane.md" "$R/src/tmp.json" "$R/.env.tmp-local"
+RTL_BEFORE=(); RTL_BEFORE_HEAD="$(git -C "$R" rev-parse HEAD)"
+rtl_before >/dev/null 2>&1
+printf 'lane v2\n' >"$R/lane.md"
+printf 'probe\n' >"$R/tmp2.json"
+RTL_VIOLATION=0
+rtl_enforce "RELAY-TURN-gh113" "agy" "/dev/null" "agy"
+rc=$?
+[ "$rc" -eq 0 ] && pass "rtl_enforce: lane edit + root scratch -> exit 0 (turn not failed)" \
+  || fail "rtl_enforce: expected exit 0, got $rc"
+[ ! -e "$R/tmp2.json" ] && [ -n "$(scratch_dir_of tmp2.json)" ] \
+  && pass "rtl_enforce: scratch relocated (not reverted-and-lost, not committed)" \
+  || fail "rtl_enforce: scratch not relocated"
+grep -q "tmp2.json" <<<"$(git -C "$R" show --stat --name-only HEAD)" \
+  && fail "rtl_enforce: scratch rode into the commit" \
+  || pass "rtl_enforce: commit contains no scratch"
+grep -q "lane v2" <<<"$(git -C "$R" show HEAD:lane.md 2>/dev/null)" \
+  && pass "rtl_enforce: the legitimate lane edit was committed" \
+  || fail "rtl_enforce: lane edit missing from commit"
+
+# ── (4) rtl_worktree_end parity: scratch in an isolated worktree does not set RTL_WT_OFFLANE ─────
+# CONTROL first: a non-scratch write in the worktree must still be off-lane.
+WT="$(rtl_worktree_begin 2>/dev/null)"
+if [ -n "$WT" ] && [ -d "$WT" ]; then
+  printf 'off-lane\n' >"$WT/offlane.md"
+  rtl_worktree_end "$WT"
+  [ "${RTL_WT_OFFLANE:-1}" -eq 1 ] && pass "CONTROL(worktree): non-scratch worktree write still sets RTL_WT_OFFLANE" \
+    || fail "CONTROL(worktree): offlane.md in worktree not flagged"
+else
+  fail "rtl_worktree_begin did not produce a worktree"
+fi
+WT2="$(rtl_worktree_begin 2>/dev/null)"
+if [ -n "$WT2" ] && [ -d "$WT2" ]; then
+  n_before="$(find "$R/.tick/scratch" -name tmp_wt.json 2>/dev/null | wc -l | tr -d ' ')"
+  printf 'probe\n' >"$WT2/tmp_wt.json"
+  rtl_worktree_end "$WT2"
+  [ "${RTL_WT_OFFLANE:-1}" -eq 0 ] \
+    && pass "rtl_worktree_end: root scratch in the worktree does NOT fail the turn" \
+    || fail "rtl_worktree_end: worktree scratch flagged off-lane"
+  n_after="$(find "$R/.tick/scratch" -name tmp_wt.json 2>/dev/null | wc -l | tr -d ' ')"
+  [ "$n_after" -gt "$n_before" ] \
+    && pass "rtl_worktree_end: worktree scratch relocated into ROOT .tick/scratch before teardown" \
+    || fail "rtl_worktree_end: worktree scratch not relocated (count $n_before -> $n_after)"
+else
+  fail "rtl_worktree_begin did not produce a second worktree"
+fi
+
+echo
+echo "gh113-headless-scratch: $PASS passed, $FAIL failed"
+[ "$FAIL" -eq 0 ]
diff --git a/test/gh114-headless-tty.sh b/test/gh114-headless-tty.sh
new file mode 100755
index 00000000..32d2bd14
--- /dev/null
+++ b/test/gh114-headless-tty.sh
@@ -0,0 +1,135 @@
+#!/usr/bin/env bash
+# test/gh114-headless-tty.sh — GH-114: headless `agy -p` gets a TTY, and an idle kill names its blocker.
+#
+# The observed stall (marathon/daybreak-wave-2, 2026-08-20): `agy -p` wedged at ~0 CPU under the
+# 300s idle watchdog while its transcript said `bubbletea: could not open TTY` — the CLI's TUI needs
+# a TTY even in -p mode, and the watchdog's attribution only offered the generic "a lock, a prompt,
+# or a hung network call". The fix has two halves, both pinned here:
+#   1. agy-turn.py provisions a pty for the turn by default (AGY_PTY=0 restores the pipe path).
+#   2. On an idle/wall kill it runs _probe_idle_blocker BEFORE signalling and emits an
+#      "idle-blocker attribution: blocker=<tty|lock|network|unknown>" block to stderr + transcript.
+#
+# Drives the real shim with a stub `agy` (same shape as test/agy-turn.sh) for the e2e cases, and
+# imports the module directly for the lsof-based blocker branches (a live network hang is not
+# reproducible deterministically, so the open-file table is faked on PATH instead).
+set -uo pipefail
+
+source "$(dirname "$0")/_setup.sh" agy-turn
+export TICK_BIN="$TICK"
+SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/agy-turn.sh"
+PY_SHIM="$(cd "$(dirname "$0")/.." && pwd)/utils/py/agy-turn.py"
+tick_a init >/dev/null
+
+printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
+printf '.tick/\n' >"$A/.gitignore"
+git -C "$A" add relay.md .gitignore >/dev/null 2>&1; git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1
+
+# Stub `agy`: passes the whoami/models pre-flights, then for the real turn checks whether stdin is a
+# TTY. STUB_MODE: ttycheck (default) — fail loudly with the exact observed bubbletea error if not a
+# TTY, else perform the good-turn contract and print a TTY-OK marker; idle — print the bubbletea
+# error and stall (no CPU, no file progress) until killed, reproducing the watchdog shape.
+STUB="$WORK/agy"
+cat >"$STUB" <<'STUB_EOF'
+#!/usr/bin/env bash
+set -u
+if [ "${1:-}" = whoami ]; then printf 'agy@example.test\n'; exit 0; fi
+if [ "${1:-}" = models ]; then printf 'Gemini 3.5 Flash\n'; exit 0; fi
+TTY_ERR='CLI error: bubbletea: error opening TTY: bubbletea: could not open TTY: open /dev/tty: device not configured'
+if [ "${STUB_MODE:-ttycheck}" = idle ]; then
+  printf '%s\n' "$TTY_ERR"
+  sleep 120
+  exit 0
+fi
+if ! [ -t 0 ]; then
+  printf '%s\n' "$TTY_ERR"
+  exit 1
+fi
+printf 'agy-stub: TTY-OK stdin is a tty; model response for %s\n' "$RELAY_AGENT"
+export TICK_REPO_ROOT="$A"
+"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
+"$TICK" ping  "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
+printf '\n### Round 1 · Reviewer · %s (agy-stub)\n**Verdict:** Changes requested\n' "$RELAY_AGENT" >>"$RELAY_FILE"
+"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to claude-a >/dev/null 2>&1
+exit 0
+STUB_EOF
+chmod +x "$STUB"
+
+seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to agy >/dev/null; }
+
+# --- (1) pty default: a headless turn with no controlling TTY never logs the TTY error ---------
+seed_token RELAY-TURN-gh114-pty
+log="$WORK/gh114-pty.log"; : >"$log"
+err="$WORK/gh114-pty.err"; : >"$err"
+RELAY_AGENT=agy RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-gh114-pty AGY_AGENT=agy \
+AGY_BIN="$STUB" AGY_TURN_ROOT="$A" AGY_LOG="$log" STUB_MODE=ttycheck \
+bash "$SHIM" >/dev/null 2>"$err"; rc=$?
+[ "$rc" -eq 0 ] && pass "pty default: turn exits 0 with a stub that REQUIRES a TTY on stdin" \
+  || fail "pty default: expected exit 0, got $rc"
+grep -q "TTY-OK" "$log" && pass "pty default: the child saw a real tty on stdin (isatty true)" \
+  || fail "pty default: child did not see a tty — pty not provisioned"
+if grep -qi "could not open TTY" "$log" || grep -qi "could not open TTY" "$err"; then
+  fail "pty default: the bubbletea TTY error was logged on a headless turn"
+else
+  pass "pty default: no 'could not open TTY' error anywhere in the turn's output"
+fi
+
+# --- (2) idle kill attribution: AGY_PTY=0 + stalled child -> blocker=tty, exit 7 ---------------
+seed_token RELAY-TURN-gh114-idle
+log2="$WORK/gh114-idle.log"; : >"$log2"
+err2="$WORK/gh114-idle.err"; : >"$err2"
+RELAY_AGENT=agy RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-gh114-idle AGY_AGENT=agy \
+AGY_BIN="$STUB" AGY_TURN_ROOT="$A" AGY_LOG="$log2" STUB_MODE=idle \
+AGY_PTY=0 RELAY_TURN_IDLE_S=4 RELAY_DIAG_INTERVAL_S=1 RELAY_TURN_TIMEOUT_S=40 \
+bash "$SHIM" >/dev/null 2>"$err2"; rc=$?
+[ "$rc" -eq 7 ] && pass "idle stall (pipe mode): watchdog kills at exit 7" \
+  || fail "idle stall: expected exit 7, got $rc"
+grep -q "idle-blocker attribution: blocker=tty" "$err2" \
+  && pass "idle stall: stderr attribution block names blocker=tty" \
+  || fail "idle stall: no blocker=tty attribution block on stderr"
+grep -q "\[GH-114 idle-blocker\] blocker=tty" "$log2" \
+  && pass "idle stall: the transcript carries the same attribution block" \
+  || fail "idle stall: transcript missing the attribution block"
+
+# --- (3) blocker branches: lock / network / unknown via a faked open-file table ----------------
+FAKEBIN="$WORK/fakebin"; mkdir -p "$FAKEBIN"
+mk_fake_lsof(){ printf '#!/usr/bin/env bash\ncat <<EOF\n%s\nEOF\n' "$1" >"$FAKEBIN/lsof"; chmod +x "$FAKEBIN/lsof"; }
+probe(){ # <log-content> -> prints blocker name from the module's own probe
+  PATH="$FAKEBIN:/usr/bin:/bin" \
+  python3 - "$PY_SHIM" <<'PYEOF'
+import importlib.util, os, subprocess, sys
+sys.path.insert(0, os.path.dirname(os.path.abspath(sys.argv[1])))  # rtl/turn_diagnostics live beside the shim
+spec = importlib.util.spec_from_file_location("agy_turn_mod", sys.argv[1])  # dashed filename: importlib, not `import`
+m = importlib.util.module_from_spec(spec)
+spec.loader.exec_module(m)
+log = os.environ["GH114_PROBE_LOG"]
+proc = subprocess.Popen(["/bin/sleep", "5"])
+try:
+    print(m._probe_idle_blocker(proc, log)[0])
+finally:
+    proc.kill(); proc.wait()
+PYEOF
+}
+PROBE_LOG="$WORK/gh114-probe.log"
+GH114_PROBE_LOG="$PROBE_LOG" ; export GH114_PROBE_LOG
+
+printf 'ordinary transcript, no tty complaint\n' >"$PROBE_LOG"
+mk_fake_lsof 'agy 1234 u 5u REG 1,2 0 123 /repo/.git/index.lock'
+[ "$(probe x)" = "lock" ] && pass "blocker probe: an open .lock file attributes blocker=lock" \
+  || fail "blocker probe: expected lock, got '$(probe x)'"
+
+mk_fake_lsof 'agy 1234 u 6u IPv6 0x0 TCP 10.0.0.2:51734->140.82.121.6:443 (ESTABLISHED)'
+[ "$(probe x)" = "network" ] && pass "blocker probe: an open TCP socket attributes blocker=network" \
+  || fail "blocker probe: expected network, got '$(probe x)'"
+
+mk_fake_lsof ''
+[ "$(probe x)" = "unknown" ] && pass "blocker probe: no tty error + empty table attributes blocker=unknown" \
+  || fail "blocker probe: expected unknown, got '$(probe x)'"
+
+printf 'CLI error: bubbletea: error opening TTY: bubbletea: could not open TTY: open /dev/tty: device not configured\n' >"$PROBE_LOG"
+mk_fake_lsof 'agy 1234 u 6u IPv6 0x0 TCP 10.0.0.2:51734->140.82.121.6:443 (ESTABLISHED)'
+[ "$(probe x)" = "tty" ] && pass "blocker probe: the transcript's own TTY error outranks open sockets (tty first)" \
+  || fail "blocker probe: expected tty, got '$(probe x)'"
+
+echo
+echo "gh114-headless-tty: $PASS passed, $FAIL failed"
+[ "$FAIL" -eq 0 ]
diff --git a/utils/py/agy-turn.py b/utils/py/agy-turn.py
index 61f62cb9..323bc482 100644
--- a/utils/py/agy-turn.py
+++ b/utils/py/agy-turn.py
@@ -4,6 +4,8 @@ import sys
 import time
 import signal
 import tempfile
+import threading
+import pty
 import subprocess
 import shutil
 import shlex
@@ -62,6 +64,51 @@ def _kill_turn_group(proc):
         except subprocess.TimeoutExpired:
             continue
 
+def _probe_idle_blocker(proc, log_path):
+    """GH-114: name WHAT an idle turn was blocked on, BEFORE the kill destroys the evidence.
+
+    The observed stall showed `bubbletea: could not open TTY` in the transcript while the
+    watchdog reported only the generic "a lock, a prompt, or a hung network call". Probe in
+    priority order — the CLI's own words about itself first, then the open-file table:
+
+      tty     — the transcript already contains agy's TTY error prefixes
+      lock    — the process tree holds a .lock file open (git index, harness driver lock)
+      network — the process tree has TCP/UDP sockets open (model backend call hung)
+      unknown — nothing probe-able; say so rather than guess
+
+    Returns (blocker, human_detail). Best-effort throughout: a probe failure degrades to
+    "unknown" and can never fail the turn it is describing.
+    """
+    tail = ""
+    try:
+        with open(log_path, "rb") as f:
+            tail = f.read()[-8192:].decode("utf-8", "replace").lower()
+    except OSError:
+        pass
+    if "could not open tty" in tail or "error opening tty" in tail or "open /dev/tty" in tail:
+        return ("tty",
+                "the CLI's terminal UI reported it could not open /dev/tty — the headless turn had "
+                "no usable TTY (bubbletea blocking on terminal setup). If AGY_PTY=0 was set, remove "
+                "it; otherwise investigate why the pty allocation did not reach the child.")
+    open_files = ""
+    try:
+        open_files = subprocess.run(
+            ["lsof", "-nP", "-a", "-g", str(proc.pid), "-w"],
+            capture_output=True, text=True, timeout=5).stdout.lower()
+    except Exception:
+        open_files = ""
+    if ".lock" in open_files:
+        return ("lock",
+                "the process tree held a .lock file open (e.g. a git index or harness driver lock) — "
+                "it was waiting on a lock held by someone else, not working.")
+    if "tcp" in open_files or "udp" in open_files:
+        return ("network",
+                "the process tree had open network sockets — it was waiting on a network call "
+                "(most likely the model backend), not working.")
+    return ("unknown",
+            "no TTY error, no open lock, no open socket in the process tree — the blocker left no "
+            "probe-able trace; the transcript is the remaining evidence.")
+
 def agy_auth_preflight(agy_bin):
     secs = int(os.environ.get("AGY_AUTH_TIMEOUT_S", AGY_AUTH_TIMEOUT_DEFAULT_S))
     out_file = os.path.join(tempfile.gettempdir(), f"agy-auth-{os.getpid()}.log")
@@ -301,6 +348,15 @@ def main():
         pass
 
     prompt = rtl.turn_prompt(me, t, peer)
+    # GH-113 proposed fix 1: prompt reinforcement. Prose is not a guarantee (that is why the
+    # mechanical rtl_scratch_relocate half exists in relay-turn-lib.sh), but naming the failure
+    # mode and the sanctioned location at the point of use removes the "I didn't know" shape.
+    prompt = (
+        "SCRATCH DISCIPLINE (hard requirement, GH-113): every probe script, test file, or temporary "
+        "output you create must be written under $TMPDIR or the repo's .relay-scratch/ directory — "
+        "NEVER the repository root. A root-level scratch file (tmp.json, fix_*.py, test_*.py, ...) is "
+        "auto-relocated out of the tree by containment and reported; an off-lane edit to a TRACKED "
+        "file still fails the whole turn at exit 6.\n\n" + prompt)
     drift_brief = rtl.drift_brief(me, tick_repo_root)
     if drift_brief:
         prompt = drift_brief + "\n" + prompt
@@ -352,7 +408,10 @@ def main():
     # Sample the turn while it runs so an exit-7 timeout can be attributed to a
     # cause. A reviewer turn hits the same modal-dialog hazard as a builder: it
     # reads the target's files and can trip a credential prompt just as easily.
-    diag = TurnDiagnostics(worktree=run_cwd)
+    # RELAY_DIAG_INTERVAL_S is a test hook (tightens the sample cadence so an
+    # idle kill is reachable in seconds, not at the 10s production cadence).
+    diag = TurnDiagnostics(worktree=run_cwd,
+                           interval=float(os.environ.get("RELAY_DIAG_INTERVAL_S", "0") or 10.0))
     diag.start()
     # GH-492: the wall cap alone cannot contain the observed failure. A 900s hang burned its
     # entire budget at cpu=0.02s/s with worktree-progress=no, and the verdict was unanimous
@@ -366,15 +425,52 @@ def main():
     # rather than by wrapping the command — see the capture doc.
     idle_cap = int(os.environ.get("RELAY_TURN_IDLE_S", RELAY_TURN_IDLE_DEFAULT_S))
     idle_killed = False
+    # GH-114: blocker evidence captured at the moment the idle bound fires, BEFORE the kill —
+    # _probe_idle_blocker reads the transcript tail and the live process tree, and both stop
+    # being readable once the group is signalled. (blocker, detail); None = probe never ran.
+    idle_blocker = None
     # Hoisted out of the try: the exit-7 reporting below reads it, and a launch failure
     # would otherwise raise NameError inside the error path — turning a clean exit 5 into
     # a crash with no attribution, which is this issue's own complaint.
     started = time.monotonic()
+    # GH-114: run `agy -p` under a pty by default. The CLI's bubbletea TUI opens /dev/tty (or
+    # requires a TTY on stdin) even in -p mode; with pipes/DEVNULL it periodically wedged at
+    # ~0 CPU until the idle watchdog killed it, and its own transcript said why: "bubbletea:
+    # could not open TTY". AGY_PTY=0 restores the old pipe behaviour (the fallback the
+    # attribution probe still names, for the case where a pty itself fails or is refused).
+    use_pty = os.environ.get("AGY_PTY", "1") != "0"
+    pty_master = None
+    pty_slave = None
+    pty_reader = None
     try:
-        with open(agy_log, "w") as log_f:
-            proc = subprocess.Popen(cmd, env=run_env, cwd=run_cwd, stdout=log_f,
-                                    stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL,
-                                    start_new_session=True)
+        log_f = open(agy_log, "w")
+        try:
+            if use_pty:
+                pty_master, pty_slave = pty.openpty()
+                proc = subprocess.Popen(cmd, env=run_env, cwd=run_cwd,
+                                        stdin=pty_slave, stdout=pty_slave, stderr=pty_slave,
+                                        start_new_session=True, close_fds=True)
+                os.close(pty_slave)
+                pty_slave = None
+                def _pty_drain(master=pty_master, sink=log_f):
+                    # Drain the pty master into the transcript, normalizing the ONLCR \r\n
+                    # the tty line discipline inserts back to \n so downstream greps and
+                    # readers see byte-identical content to the old pipe path.
+                    while True:
+                        try:
+                            chunk = os.read(master, 65536)
+                        except (OSError, ValueError):
+                            return
+                        if not chunk:
+                            return
+                        sink.write(chunk.replace(b"\r\n", b"\n").decode("utf-8", "replace"))
+                        sink.flush()
+                pty_reader = threading.Thread(target=_pty_drain, name="agy-pty-drain", daemon=True)
+                pty_reader.start()
+            else:
+                proc = subprocess.Popen(cmd, env=run_env, cwd=run_cwd, stdout=log_f,
+                                        stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL,
+                                        start_new_session=True)
             while True:
                 rc = proc.poll()
                 if rc is not None:
@@ -382,6 +478,7 @@ def main():
                     break
                 elapsed = time.monotonic() - started
                 if elapsed >= turn_timeout:
+                    idle_blocker = _probe_idle_blocker(proc, agy_log)
                     _kill_turn_group(proc)
                     bounded_rc = 7
                     break
@@ -389,11 +486,28 @@ def main():
                     _idle = diag.idle_seconds()
                     # `None` is "not measured yet", never "not idle" — see idle_seconds().
                     if _idle is not None and _idle >= idle_cap:
+                        idle_blocker = _probe_idle_blocker(proc, agy_log)
                         _kill_turn_group(proc)
                         bounded_rc = 7
                         idle_killed = True
                         break
                 time.sleep(TURN_POLL_S)
+        finally:
+            # Close the master FIRST: the drain thread's blocking read then returns/raises
+            # and the join below can reap it. Order matters — join-then-close deadlocks.
+            if pty_master is not None:
+                try:
+                    os.close(pty_master)
+                except OSError:
+                    pass
+            if pty_slave is not None:   # only non-None when Popen itself failed post-openpty
+                try:
+                    os.close(pty_slave)
+                except OSError:
+                    pass
+            if pty_reader is not None:
+                pty_reader.join(timeout=3)
+            log_f.close()
     except Exception:
         bounded_rc = 5
     finally:
@@ -448,6 +562,15 @@ def main():
         # different questions — "why did the harness stop it" vs "what was it doing". Three
         # causes and two bounds stay independently readable, as GH-390 established.
         _reason, _detail = diag.classify()
+        if idle_blocker is not None:
+            _blk, _blk_detail = idle_blocker
+            _blk_line = (f"agy-turn: idle-blocker attribution: blocker={_blk} — {_blk_detail}")
+            print(_blk_line, file=sys.stderr)
+            try:
+                with open(agy_log, "a") as log_f:
+                    log_f.write(f"\n[GH-114 idle-blocker] blocker={_blk} — {_blk_detail}\n")
+            except OSError:
+                pass
         if idle_killed:
             print(f"agy-turn: agy -p was IDLE for >={idle_cap}s (no CPU, no worktree progress) — "
                   f"killed early at ~{int(time.monotonic() - started)}s of a {turn_timeout}s wall cap "
diff --git a/validate.sh b/validate.sh
index 7b137028..17cfd602 100755
--- a/validate.sh
+++ b/validate.sh
@@ -216,6 +216,8 @@ TESTS=(
   "marathon-root-audit.sh"       # GH-209 (static audit: every test/marathon*.sh invocation is MARATHON_ROOT-scoped)
   "rtl-orphan-backup.sh"         # GH-141 (concurrent peer-edit race: revert unchanged, content recoverable)
   "gh91-relay-scratch.sh"          # GH-91 (sanctioned .relay-scratch/ for builder verification output: exempted in rtl_check + rtl_worktree_end, pre-created by begin, named in the turn prompt; never copied back, discarded under ROOT; controls pin that stray writes and lookalike prefixes still go off-lane) — 15/0, driven at the lib-function level, no builder binary needed
+  "gh113-headless-scratch.sh"    # GH-113 (headless builder's root-level scratch tmp.json/fix_*/test_* RELOCATES to .tick/scratch/ instead of failing exit 6, on BOTH rtl_check and rtl_worktree_end; controls pin the amnesty line: non-scratch names, nested paths, dotfiles, and TRACKED off-lane edits still violate) — 17/0, lib-function level, no builder binary needed
+  "gh114-headless-tty.sh"        # GH-114 (agy -p runs under a pty by default so a no-controlling-TTY turn never logs the bubbletea error; an idle kill runs _probe_idle_blocker BEFORE the kill and emits blocker=tty|lock|network|unknown to stderr + transcript; lsof branches faked on PATH) — 10/0
   "gh124-closeout.sh"            # GH-124 (closeout automation, on-disk gate receipts, workspace sweep GC, and early drift alert)
   "gh129-relay-tick-root.sh"     # #129/#136 (relay-drive self-resolves TICK_REPO_ROOT ahead of the lane-attempt gate, NOTE prints after the lock for gh376 parity; not-found names the root+dir searched; escalate exits 4 never 0; attempts land beside the token) — 17/0; negative control: pre-fix red on self-resolution (recorded in PR #134 + #136's fix PR)
   "gh130-agy-auth-whoami.sh"     # #130/#135 (agy auth preflight three-state verdict on BOTH agy-turn.py and consult.py: usage-error probes unverifiable+non-blocking, credentials/silent non-zero still fatal) — 11/0
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer · agy
- swept file: yes (no pre-existing defects found)
- `[Pass]` `relay-automation/relay-turn-lib.sh:1057`: `rtl_scratch_relocate` correctly relocates untracked scratch files before reverting.
- `[Pass]` `utils/py/agy-turn.py:534`: The `pty.openpty()` logic gracefully provisions pseudo-terminals for headless `agy -p` executions.
- `[Pass]` `test/gh114-headless-tty.sh:1`: Exhaustive faked lsof table validates `_probe_idle_blocker` attributes accurately.

**Verdict:** Approved

handing off to claude-a — relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
