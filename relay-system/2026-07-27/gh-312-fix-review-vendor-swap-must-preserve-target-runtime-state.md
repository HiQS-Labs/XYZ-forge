# RELAY · GH-312 fix review — vendor swap must preserve target runtime state
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-27.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-312-fix-review-vendor-swap-must-preserve-target-runtime-state): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **gh312-fix.diff** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-27

### Artifact — gh312-fix.diff
```
commit 4ec5928836ff2048d5a88aacf4cf57aaa4f84f4c
Author: CI Runner <ci@runner.invalid>
Date:   Mon Jul 27 10:53:10 2026 -0700

    fix(GH-312): preserve target-owned runtime state across the vendor swap
    
    materialize_vendor() staged a mirror of the harness and swapped it in over an
    unconditional `rm -rf "$VENDOR_DIR"`. The stage is built purely from
    HARNESS_ROOT, so anything the target accumulated at runtime was deleted unread.
    Because ensure_gitignore keeps .xyz/ out of git, nothing under it was ever
    hashed into a git object -- no reflog, stash, or fsck recovery. A real incident
    on 2026-07-27 destroyed a completed two-round Codex relay thread plus its full
    tick event log.
    
    Carry target-owned state across the swap instead. The intake report named
    relay-system/, .tick/ and .relay-driver.lock; auditing what .xyz/ actually
    accumulates added the GH-75 telemetry trio (XYZ.json, XYZ.json.lock/,
    XYZ.heartbeat.json), which had identical exposure -- not in VENDOR_DIRS, so
    never recreated by the stage.
    
    Preservation over a warning or a refusal: both of those still depend on an
    operator reading output at the right moment, and the docs frame `update` as
    deliberate, never as destructive.
    
    Regression coverage lands with the fix and fails without it (6 failures
    pre-fix), and pins the other half of the contract too -- VERSION must still
    restamp to live HEAD, so a fix that "preserved" state by skipping the update
    cannot pass. Also covers the direct xyz-vendor.sh re-run path, which the
    capture flagged as unverified and which had the same destructive swap.
    
    Docs: xyz-sync.sh header and relay-xyz/SKILL.md now state what update does to
    runtime state, and that new .xyz/ artifacts must join the preserve list.
    
    Refs GH-312
    Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>

diff --git a/relay-automation/xyz-sync.sh b/relay-automation/xyz-sync.sh
index 17e4272..a576eb0 100755
--- a/relay-automation/xyz-sync.sh
+++ b/relay-automation/xyz-sync.sh
@@ -14,6 +14,15 @@ set -euo pipefail
 # This is report-only: a mismatch prints a warning naming the drifted field(s) and both values
 # (recorded vs current) -- it is NEVER a hard error and NEVER auto-pulls. Updates land only via an
 # explicit `xyz-sync update` / `xyz-vendor.sh` re-run (pinned + manual, by design).
+#
+# GH-312 -- what `update` does to the target's RUNTIME STATE: it updates harness CODE only and
+# preserves state the target owns. `xyz-vendor.sh` rebuilds the tree by staging a fresh mirror of
+# the harness and swapping it in over `rm -rf`, so anything the target accumulated that is not
+# harness source would be destroyed unread -- and `.xyz/` is gitignored, so that loss has no git
+# recovery path. materialize_vendor() therefore carries these across the swap:
+#   relay-system/  .tick/  .relay-driver.lock  XYZ.json  XYZ.json.lock/  XYZ.heartbeat.json
+# Adding a new runtime artifact under `.xyz/` means adding it to that preserve list, or `update`
+# will silently delete it. Regression coverage: test/gh312-vendor-preserves-state.sh.
 
 usage() {
   cat <<'USAGE'
diff --git a/relay-automation/xyz-vendor.sh b/relay-automation/xyz-vendor.sh
index c3e6555..5363c8a 100755
--- a/relay-automation/xyz-vendor.sh
+++ b/relay-automation/xyz-vendor.sh
@@ -278,6 +278,29 @@ materialize_vendor() {
     printf 'vendored_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
   } > "$STAGE_DIR/VERSION"
 
+  # GH-312: carry TARGET-owned runtime state across the swap. $STAGE_DIR is mirrored purely from
+  # $HARNESS_ROOT, and none of these paths are in VENDOR_DIRS, so the `rm -rf` below would delete
+  # whatever the target accumulated -- relay threads, tick event logs, GH-75 telemetry -- unread.
+  # `.xyz/` is gitignored (ensure_gitignore), so nothing under it was ever hashed into a git object:
+  # there is no reflog, stash, or `git fsck --lost-found` recovery. A destroyed relay thread is gone.
+  #
+  # Preservation rather than a warning or a refusal: both of those still depend on an operator
+  # reading output at the right moment, and this script's own docs frame `update` as deliberate
+  # (pinned + manual) but never as destructive. This makes it non-destructive by default.
+  #
+  # The list is state that BELONGS TO THE TARGET, not harness code:
+  #   relay-system/         relay threads (what vendoring is sold on -- per-repo isolation)
+  #   .tick/                tick event logs / claim state
+  #   .relay-driver.lock    live driver lock (a running relay or marathon)
+  #   XYZ.json{,.lock/}     GH-75 completion telemetry + its mkdir advisory lock
+  #   XYZ.heartbeat.json    liveness stamp
+  for _keep in relay-system .tick .relay-driver.lock XYZ.json XYZ.json.lock XYZ.heartbeat.json; do
+    [ -e "$VENDOR_DIR/$_keep" ] || continue
+    rm -rf "$STAGE_DIR/$_keep"
+    cp -Rp "$VENDOR_DIR/$_keep" "$STAGE_DIR/$_keep" \
+      || die "failed to preserve target runtime state: $_keep (aborting before the destructive swap)"
+  done
+
   rm -rf "$VENDOR_DIR"
   mv "$STAGE_DIR" "$VENDOR_DIR"
 }
diff --git a/skills/relay-xyz/SKILL.md b/skills/relay-xyz/SKILL.md
index 18961c1..5c5b80b 100644
--- a/skills/relay-xyz/SKILL.md
+++ b/skills/relay-xyz/SKILL.md
@@ -119,6 +119,13 @@ so each gets its own lock, `.tick/`, and worktrees:
 | `install.sh` (tick-only) | `bin/tick` + `src/*.js` | ❌ falls back to the centralized harness | shared (serializes) |
 | **`xyz-vendor.sh vendor <repo>`** | full harness (`relay-automation/` + tick + src) into a gitignored `.xyz/` | ✅ per-repo | **own** `.xyz/.relay-driver.lock` |
 
+Updating a vendored copy (`xyz-sync.sh update`, or re-running `xyz-vendor.sh` over an existing
+`.xyz/`) replaces the harness **code** and preserves the per-repo state above — `relay-system/`,
+`.tick/`, `.relay-driver.lock`, and the `XYZ.json*` telemetry ride across the rebuild (GH-312). This
+matters because `.xyz/` is gitignored: state lost there is unrecoverable, with no reflog or stash
+behind it. A new runtime artifact under `.xyz/` must be added to the preserve list in
+`xyz-vendor.sh`'s `materialize_vendor()`, or the next update will delete it.
+
 So: **`xyz-vendor.sh` (not `install.sh`) is the path to concurrent per-repo relays.** Once a repo has
 `.xyz/`, `find-harness.sh` prefers it automatically (env → `.xyz/` → current repo → script-relative), and
 `find-harness.sh --check` **warns** when you're in a foreign repo with no `.xyz/` (using the shared
diff --git a/test/gh312-vendor-preserves-state.sh b/test/gh312-vendor-preserves-state.sh
new file mode 100755
index 0000000..99153e3
--- /dev/null
+++ b/test/gh312-vendor-preserves-state.sh
@@ -0,0 +1,85 @@
+#!/usr/bin/env bash
+# GH-312 — `xyz-sync update` / `xyz-vendor.sh` must NOT destroy the target's live runtime state.
+#
+# materialize_vendor() stages a fresh mirror from $HARNESS_ROOT and then does an unconditional
+#   rm -rf "$VENDOR_DIR"; mv "$STAGE_DIR" "$VENDOR_DIR"
+# The stage is built purely from harness source, so anything the TARGET accumulated at runtime --
+# relay-system/ threads, .tick/ event logs, .relay-driver.lock -- was deleted unread. That state is
+# invisible to git by construction (ensure_gitignore puts .xyz/ in .gitignore), so there is no
+# reflog/stash/fsck recovery: a destroyed relay thread is simply gone.
+#
+# These assertions pin the contract both ways: target-owned RUNTIME STATE survives, and harness
+# CODE still updates (a fix that preserved state by skipping the update would be worse than the bug).
+source "$(dirname "$0")/_setup.sh" gh312-vendor-preserves-state
+
+ROOT="$(cd -P "$(dirname "$0")/.." && pwd)"
+VENDOR="$ROOT/relay-automation/xyz-vendor.sh"
+SYNC="$ROOT/relay-automation/xyz-sync.sh"
+
+export XYZ_REGISTRY="$WORK/registry.tsv"
+mkdir -p "$WORK/foreign"; git init -q "$WORK/foreign"; REPO="$(cd "$WORK/foreign" && pwd -P)"
+
+# Seed every target-owned runtime path with recognizable content.
+#
+# The intake report named only relay-system/, .tick/ and .relay-driver.lock. Auditing what `.xyz/`
+# actually accumulates (repo .gitignore + GH-75) turned up more state with the same exposure:
+# XYZ.json is the GH-75 completion-telemetry record array, XYZ.heartbeat.json its liveness stamp,
+# and XYZ.json.lock/ the mkdir-based advisory lock guarding it. None are in VENDOR_DIRS, so the
+# stage never recreates them and the swap deleted them exactly like the three named paths.
+seed_state() {
+  mkdir -p "$REPO/.xyz/relay-system/2026-07-27" "$REPO/.xyz/.tick/events"
+  printf 'PRODUCER-TURN-1\n' > "$REPO/.xyz/relay-system/2026-07-27/thread.md"
+  printf '{"seq":1,"verb":"claim"}\n' > "$REPO/.xyz/.tick/events/agent-a.jsonl"
+  printf 'pid=4242\n' > "$REPO/.xyz/.relay-driver.lock"
+  printf '[{"harness":"relay","health":"green"}]\n' > "$REPO/.xyz/XYZ.json"
+  printf '{"beat":1}\n' > "$REPO/.xyz/XYZ.heartbeat.json"
+}
+
+assert_state_survived() {
+  local label="$1"
+  [ "$(cat "$REPO/.xyz/relay-system/2026-07-27/thread.md" 2>/dev/null)" = "PRODUCER-TURN-1" ] \
+    && pass "$label: relay-system/ thread survived with content intact" \
+    || fail "$label: relay-system/ thread destroyed or corrupted"
+  [ "$(cat "$REPO/.xyz/.tick/events/agent-a.jsonl" 2>/dev/null)" = '{"seq":1,"verb":"claim"}' ] \
+    && pass "$label: .tick/ event log survived with content intact" \
+    || fail "$label: .tick/ event log destroyed or corrupted"
+  [ "$(cat "$REPO/.xyz/.relay-driver.lock" 2>/dev/null)" = "pid=4242" ] \
+    && pass "$label: .relay-driver.lock survived" \
+    || fail "$label: .relay-driver.lock destroyed"
+  [ "$(cat "$REPO/.xyz/XYZ.json" 2>/dev/null)" = '[{"harness":"relay","health":"green"}]' ] \
+    && pass "$label: XYZ.json telemetry survived with content intact" \
+    || fail "$label: XYZ.json telemetry destroyed or corrupted"
+  [ "$(cat "$REPO/.xyz/XYZ.heartbeat.json" 2>/dev/null)" = '{"beat":1}' ] \
+    && pass "$label: XYZ.heartbeat.json survived" \
+    || fail "$label: XYZ.heartbeat.json destroyed"
+}
+
+HEAD="$(git -C "$ROOT" rev-parse HEAD)"
+
+# --- path 1: xyz-sync update (the command in the reported incident) ---
+"$VENDOR" "$REPO" >/dev/null 2>&1 || fail "initial vendor exited non-zero"
+seed_state
+printf 'source_commit=deadbeef\ntick_version=x\nvendored_utc=x\n' > "$REPO/.xyz/VERSION"
+"$SYNC" update "$REPO" >/dev/null 2>&1 || fail "xyz-sync update exited non-zero"
+assert_state_survived "xyz-sync update"
+grep -q "^source_commit=$HEAD$" "$REPO/.xyz/VERSION" \
+  && pass "xyz-sync update still restamps VERSION to live HEAD (code really updated)" \
+  || fail "xyz-sync update did not restamp VERSION — state preserved by skipping the update"
+[ -x "$REPO/.xyz/bin/tick" ] && pass "xyz-sync update: harness code intact (bin/tick present)" \
+  || fail "xyz-sync update: harness code missing after update"
+
+# --- path 2: a direct xyz-vendor.sh re-run over an existing .xyz/ (same destructive swap) ---
+seed_state
+"$VENDOR" "$REPO" >/dev/null 2>&1 || fail "re-vendor exited non-zero"
+assert_state_survived "xyz-vendor re-run"
+
+# --- a vendor into a repo with NO prior state must still work (no preserve-list crash) ---
+mkdir -p "$WORK/fresh"; git init -q "$WORK/fresh"; FRESH="$(cd "$WORK/fresh" && pwd -P)"
+"$VENDOR" "$FRESH" >/dev/null 2>&1 || fail "fresh vendor (no prior state) exited non-zero"
+[ -x "$FRESH/.xyz/bin/tick" ] && pass "fresh vendor unaffected by preservation logic" \
+  || fail "fresh vendor broken"
+[ -e "$FRESH/.xyz/relay-system" ] && fail "fresh vendor invented a relay-system/ dir" \
+  || pass "fresh vendor does not fabricate empty runtime dirs"
+
+echo "  $TEST_NAME: $PASS pass, $FAIL fail"
+exit 0
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
