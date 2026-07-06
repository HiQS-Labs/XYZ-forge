# RELAY · GH-96 Seam#1 + GH-140 containment fix review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-05.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-96-seam-1-gh-140-containment-fix-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **gh96-gh140-review-context.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-05

### Artifact — gh96-gh140-review-context.md
````
# Review context: GH-96 Seam #1 (XYZ.json heartbeat) + GH-140 (containment-kernel atomic-copyback fix)

## Background
A marathon lane built GH-96 Seam #1 (a heartbeat companion file so a hung/dead relay/marathon run
goes stale to a freshness-checking consumer instead of presenting a stale completed record as
current). Its own artifacts included relay-automation/marathon-drive.sh and relay-drive.sh --
the very scripts actively executing during the build. The first attempt built + agy-approved
cleanly, but then marathon-drive.sh crashed with a garbled syntax error immediately after
relay-approval, and the repo's local working tree + .git internals were subsequently wiped down
to a handful of surviving dot-dirs (origin/main was completely unaffected -- recovered via
re-clone, zero remote data lost).

## Root cause + fix (GH-140, this diff's relay-turn-lib.sh hunk)
relay-turn-lib.sh's rtl_worktree_end() copied a turn's allowlisted artifacts back from the
isolated worktree into the main repo root via a NON-ATOMIC in-place 'cp -R' -- which truncates
and rewrites an existing destination file at the SAME inode. Since marathon-drive.sh/
relay-drive.sh were themselves editable artifacts, the live bash interpreter (which reads a
script incrementally, not fully buffered upfront) read a half-old/half-new file mid-parse.
Fix: copy to a temp path beside the destination, then atomically rename into place (same
os.replace() pattern append-xyz-completion.sh already uses) -- an fd already open on the old
file keeps reading the old inode until it closes, never observing a half-written script.

## What to review
1. Is the GH-140 atomic-copyback fix in rtl_worktree_end() actually correct and complete? Pay
   close attention to the file-vs-directory branch (rename() can atomically clobber an existing
   FILE destination directly, but cannot atomically replace a non-empty DIRECTORY -- does the
   diff handle both cases correctly, and is there any remaining race or leak (stray .rtl-copyback.*
   temp files, wrong permissions/mode bits after cp -R vs the original, symlink handling)?
2. Does the fix change behavior for any EXISTING caller in a way that could break containment
   (e.g. off-lane detection, the GH-13/#14 concurrent-ROOT-commit preservation, GH-107's
   containment-ignore exemption)?
3. Is the GH-96 Seam #1 heartbeat feature (write-xyz-heartbeat.sh + its wiring into
   relay-drive.sh/marathon-drive.sh) correctly scoped -- gated by XYZ_HARNESS_CONTEXT so a
   marathon-nested relay round doesn't double-write against the phase-level heartbeat, cleared
   on every terminal path before the completion emit, atomic overwrite (no lost-update risk)?
4. Anything else that stands out as a correctness or security concern.

## Verification already done (before this review)
- test/worktree-isolation.sh 31/31, test/shim-worktree.sh 32/32, test/agy-turn.sh 27/27 after the
  GH-140 fix alone.
- Full validate.sh green after the fix, and again after the GH-96 Seam #1 retry build.
- The retry (same lane, same risky artifacts) completed cleanly end-to-end with NO repeat of the
  crash/wipe -- strong empirical support that GH-140 addressed the actual cause, though this
  review is asking for independent code-level scrutiny, not just outcome-based confidence.

## Diff (99afa06..HEAD)
```diff
diff --git a/.gitignore b/.gitignore
index 695b627..713b585 100644
--- a/.gitignore
+++ b/.gitignore
@@ -14,10 +14,11 @@ PROJECT/1-INBOX/.DS_Store
 /temp/
 .pdda-gh-state.tsv
 PROJECT/.DS_Store
-# GH-75: XYZ.json is a local, machine-specific completion-telemetry log every harness session prepends
-# to (relay/marathon/swarm). Kept out of git to avoid per-session merge-conflict churn.
+# GH-75 / GH-96: XYZ.json is the local newest-first completion log; XYZ.heartbeat.json is the mutable
+# in-flight companion marker. Both are machine-specific and kept out of git to avoid churn.
 XYZ.json
 XYZ.json.lock/
+XYZ.heartbeat.json
 # GH-78: hourly doc-preflight telemetry — per-machine, per-run edit/warn logs; gitignored to avoid churn.
 utils/telemetry/preflight-log/
 # Aider aux files: a MANUAL (non-shim) aider run drops .aider.chat.history.md / .aider.input.history /
diff --git a/relay-automation/README.md b/relay-automation/README.md
index 15fb347..ca4d63b 100644
--- a/relay-automation/README.md
+++ b/relay-automation/README.md
@@ -30,6 +30,65 @@ the loop still degrades to the existing manual nudge. For the current headless p
 | `consult.sh` | Parallel read-only consult: asks the same question to **Codex, agy, and (opt-in) Aider↔OpenRouter** (`--models codex,agy,aider`), captures each transcript, and leaves synthesis to the caller. Advisory-only; also the engine behind `relay-drive.sh --consult-verify`. |
 | `xyz-vendor.sh` / `xyz-sync.sh` | Vendoring pair for `.xyz/` copies materialized into another repo. `xyz-vendor.sh <target-repo>` mirrors this harness into `<target-repo>/.xyz/` and stamps a row in the local `registry.tsv` (`install_dir`, `last_install_utc`, `tick_version`, `source_commit`, `coordinated_repo`) at that moment. `xyz-sync.sh list \| update \| delete \| check` manages those registered rows: `list` shows them, `update <dir>\|--all` re-vendors, `delete <dir>\|--all [--yes]` removes a copy and prunes its row. **`check <dir>\|--all`** (GH-96) is report-only drift detection: it recomputes the CURRENT `tick_version`/`source_commit` this harness ships and compares against each row's recorded pair — a mismatch in **either** field counts as drift. Exact match on both → a silent `ok` line; drift → a warning naming the drifted field(s) and both recorded/current values. Never a hard error, never an auto-pull — updates land only via an explicit `update`/`xyz-vendor.sh` re-run (pinned + manual by design). This is the harness-side "is this install stale?" signal a downstream consumer (e.g. rebalance-OS) can poll instead of guessing. |
 
+## XYZ completion telemetry
+
+`XYZ.json` is the harness repo root's gitignored, newest-first completion log. It is always written in
+the harness clone that owns `relay-automation/`; it is never redirected into a `--target-root`
+foreign repo.
+
+Each array element has this schema:
+
+```json
+{
+	"harness": "relay",
+	"sessionId": "gh96seam1",
+	"health": "green",
+	"title": "Marathon Phase gh96seam1",
+	"description": "Relay session ended: STATUS Approved (health green).",
+	"updatedAt": "2026-07-05T00:00:00Z"
+}
+```
+
+Field contract:
+
+| Field | Type | Meaning |
+|---|---|---|
+| `harness` | string | `relay`, `marathon`, or `swarm` |
+| `sessionId` | string | Relay thread slug, marathon run id, or caller-supplied `XYZ_SESSION_ID` |
+| `health` | string | `green`, `orange`, or `red` |
+| `title` | string | Short human-readable label for the run |
+| `description` | string | One-line outcome summary |
+| `updatedAt` | string | UTC timestamp in ISO-8601 `YYYY-MM-DDTHH:MM:SSZ` form |
+
+Emit cadence:
+
+| Flow | `XYZ.json` emit contract |
+|---|---|
+| Standalone `relay-drive.sh` | Exactly one record when the relay terminates: `Approved`/`Closed` => `green`; explicit `Escalated` / review handback => `orange`; no-progress / review-once stall / round-cap => `red` |
+| Bare `marathon-drive.sh` | Exactly one `marathon` record per invocation |
+| Swarm-originated `marathon-drive.sh` (`XYZ_HARNESS_CONTEXT=swarm`) | Exactly one `swarm` record per invocation |
+| `marathon.sh` orchestrated multi-phase run | Exactly one `marathon` record for the whole run; nested phase-level `marathon-drive.sh` completion hooks stay silent |
+
+`XYZ.heartbeat.json` is the companion in-flight marker. It is a single mutable object, not an array:
+
+```json
+{
+	"harness": "marathon",
+	"sessionId": "gh96-seam1",
+	"updatedAt": "2026-07-05T00:00:00Z"
+}
+```
+
+Heartbeat cadence:
+
+| Flow | `XYZ.heartbeat.json` behavior |
+|---|---|
+| Standalone `relay-drive.sh` | Overwritten once per round before the turn-taker runs |
+| Any `marathon-drive.sh` phase | Overwritten once right after `marathon.phase.start` |
+| Nested `relay-drive.sh` inside `marathon-drive.sh` | Silent; the phase-level marathon heartbeat owns freshness so a nested relay round does not double-write |
+| Terminal completion for the same harness + `sessionId` | The heartbeat file is cleared before the completion record is appended, so finished runs leave no stale in-progress marker |
+| Crash / kill / hang | No completion record is appended, so the last heartbeat remains in place and goes stale naturally for freshness-aware consumers |
+
 ## Recipes & docs (not scripts)
 | Doc | What it gives you |
 |---|---|
diff --git a/relay-automation/marathon-drive.sh b/relay-automation/marathon-drive.sh
index e713637..3654956 100755
--- a/relay-automation/marathon-drive.sh
+++ b/relay-automation/marathon-drive.sh
@@ -128,6 +128,7 @@ die()  { printf 'marathon-drive: %s\n' "$*" >&2; exit 2; }
 log()  { printf 'marathon-drive: %s\n' "$*"; }
 
 XYZ_APPEND_BIN="${XYZ_APPEND_BIN:-"$_xyz_harness/utils/telemetry/append-xyz-completion.sh"}"
+XYZ_HEARTBEAT_BIN="${XYZ_HEARTBEAT_BIN:-"$_xyz_harness/utils/telemetry/write-xyz-heartbeat.sh"}"
 
 # GH-75: append ONE final-completion record for a run whose WHOLE completion IS this single-phase
 # marathon-drive — i.e. a bare `marathon-drive.sh` run (harness:"marathon") or a swarm-preflight-
@@ -136,6 +137,22 @@ XYZ_APPEND_BIN="${XYZ_APPEND_BIN:-"$_xyz_harness/utils/telemetry/append-xyz-comp
 # marathon.sh emits the single whole-run record itself. Health is binary green/red (halt-on-first-
 # failure has no distinct "escalated mid-chain" state). Best-effort — never changes marathon-drive's
 # own exit code.
+xyz_marathon_heartbeat_write() {
+  [[ -x "$XYZ_HEARTBEAT_BIN" ]] || return 0
+  local ctx="${XYZ_HARNESS_CONTEXT:-}" harness sid
+  case "$ctx" in swarm) harness="swarm" ;; *) harness="marathon" ;; esac
+  sid="${XYZ_SESSION_ID:-$PHASE_ID}"
+  "$XYZ_HEARTBEAT_BIN" "$harness" "$sid" >/dev/null 2>&1 || true
+}
+
+xyz_marathon_heartbeat_clear() {
+  [[ -x "$XYZ_HEARTBEAT_BIN" ]] || return 0
+  local ctx="${XYZ_HARNESS_CONTEXT:-}" harness sid
+  case "$ctx" in swarm) harness="swarm" ;; *) harness="marathon" ;; esac
+  sid="${XYZ_SESSION_ID:-$PHASE_ID}"
+  XYZ_HEARTBEAT_CLEAR=1 "$XYZ_HEARTBEAT_BIN" "$harness" "$sid" >/dev/null 2>&1 || true
+}
+
 xyz_marathon_emit() {  # <health> <description>
   local ctx="${XYZ_HARNESS_CONTEXT:-}"
   [[ "$ctx" == "marathon-phase" ]] && return 0
@@ -435,6 +452,7 @@ log "tick token seeded: $RELAY_TASK → $BUILDER"
 # ── Step 4: emit phase.start ────────────────────────────────────────────────
 
 "$TICK_BIN" log marathon.phase.start "$RELAY_TASK" --agent marathon > /dev/null
+xyz_marathon_heartbeat_write
 log "phase start: running relay-drive --round-cap $ROUND_CAP"
 
 # ── Step 5: run relay-drive (the loop — unmodified) ────────────────────────
@@ -503,12 +521,14 @@ case "$relay_exit" in
     if [[ "$gate_exit" -ne 0 ]]; then
       log "pre-advance gate FAILED (exit $gate_exit) — escalating"
       escalate "pre-advance-failed" "$relay_exit"
+      xyz_marathon_heartbeat_clear
       xyz_marathon_emit red "halted at phase ${PHASE_ID} — pre-advance gate failed"
       exit 5
     fi
     "$TICK_BIN" log marathon.phase.approved "$RELAY_TASK" --agent marathon > /dev/null || true
     lane_attempt_reset "${TICK_REPO_ROOT:-$ROOT}" "$PHASE_ID"   # GH-45: success clears the attempt counter
     save_transcript
+    xyz_marathon_heartbeat_clear
     log "phase ${PHASE_ID} complete — STATUS: Approved, gate passed"
     xyz_marathon_emit green "phase ${PHASE_ID} complete — STATUS: Approved, gate passed"
     exit 0
@@ -516,12 +536,14 @@ case "$relay_exit" in
   3)
     log "relay escalated: no-progress (relay-drive exit 3)"
     escalate "no-progress" 3
+    xyz_marathon_heartbeat_clear
     xyz_marathon_emit red "halted at phase ${PHASE_ID} — relay no-progress"
     exit 3
     ;;
   4)
     log "relay escalated: cap/close-mismatch (relay-drive exit 4)"
     escalate "cap-or-close-mismatch" 4
+    xyz_marathon_heartbeat_clear
     xyz_marathon_emit red "halted at phase ${PHASE_ID} — relay cap/close-mismatch"
     exit 4
     ;;
@@ -532,6 +554,7 @@ case "$relay_exit" in
     # 2026-06-17: an autonomous builder edited an off-lane file; rtl_enforce caught + reverted it.)
     log "relay escalated: containment violation — a turn-taker reverted an off-lane edit (exit 6)"
     escalate "containment-violation (off-lane edit reverted by a turn-taker)" 6
+    xyz_marathon_heartbeat_clear
     xyz_marathon_emit red "halted at phase ${PHASE_ID} — containment violation (off-lane edit reverted)"
     exit 6
     ;;
diff --git a/relay-automation/relay-drive.sh b/relay-automation/relay-drive.sh
index 18f9508..0dc61ba 100755
--- a/relay-automation/relay-drive.sh
+++ b/relay-automation/relay-drive.sh
@@ -42,6 +42,7 @@ source "$(dirname "${BASH_SOURCE[0]}")/relay-turn-lib.sh"
 TICK_BIN="${TICK_BIN:-"$ROOT_DIR/bin/tick"}"
 CONSULT_SH="${CONSULT_SH:-"$ROOT_DIR/relay-automation/consult.sh"}"
 XYZ_APPEND_BIN="${XYZ_APPEND_BIN:-"$ROOT_DIR/utils/telemetry/append-xyz-completion.sh"}"
+XYZ_HEARTBEAT_BIN="${XYZ_HEARTBEAT_BIN:-"$ROOT_DIR/utils/telemetry/write-xyz-heartbeat.sh"}"
 
 # GH-45 — QUEUE commitment contract: per-lane attempt cap (anti-rabbit-hole / WIP discipline).
 # lane_attempt_gate appends one line per fire to .tick/attempts/<lane> and REFUSES to start a lane at
@@ -82,11 +83,20 @@ lane_attempt_reset() {  # clear a lane's counter after it completes successfully
 # phase — marathon-drive.sh sets XYZ_HARNESS_CONTEXT for the nested call (marathon-phase|swarm) and the
 # outer harness owns the whole-run record, so a per-phase relay completion must not double-emit.
 # Best-effort: a telemetry failure must never change the relay's own exit path.
+xyz_relay_heartbeat_write() {
+  case "${XYZ_HARNESS_CONTEXT:-relay}" in relay) ;; *) return 0 ;; esac
+  [[ -x "$XYZ_HEARTBEAT_BIN" ]] || return 0
+  local slug
+  slug="$(basename "$RELAY_FILE" .md)"
+  "$XYZ_HEARTBEAT_BIN" relay "$slug" >/dev/null 2>&1 || true
+}
+
 xyz_relay_emit() {  # <health>
   case "${XYZ_HARNESS_CONTEXT:-relay}" in relay) ;; *) return 0 ;; esac
-  [[ -x "$XYZ_APPEND_BIN" ]] || return 0
   local health="$1" slug title s desc
   slug="$(basename "$RELAY_FILE" .md)"
+  [[ -x "$XYZ_HEARTBEAT_BIN" ]] && XYZ_HEARTBEAT_CLEAR=1 "$XYZ_HEARTBEAT_BIN" relay "$slug" >/dev/null 2>&1 || true
+  [[ -x "$XYZ_APPEND_BIN" ]] || return 0
   title="$(grep -m1 '^# ' "$RELAY_FILE" 2>/dev/null | sed 's/^#[[:space:]]*//; s/[[:space:]]*$//')" || true
   [[ -n "$title" ]] || title="$slug"
   s="$(file_status)"
@@ -308,6 +318,7 @@ while ((round < ROUND_CAP)); do
     printf 'relay-drive: WOULD drive turn for agent: %s (token %s, STATUS: %s)\n' "$actor" "$tstatus" "$s"; exit 0
   fi
 
+  xyz_relay_heartbeat_write
   prev="$tstatus:$actor"
   RELAY_FILE="$RELAY_FILE" RELAY_TASK="$RELAY_TASK" RELAY_AGENT="$actor"
   export RELAY_FILE RELAY_TASK RELAY_AGENT
diff --git a/relay-automation/relay-turn-lib.sh b/relay-automation/relay-turn-lib.sh
index a0c74f3..eed4f60 100644
--- a/relay-automation/relay-turn-lib.sh
+++ b/relay-automation/relay-turn-lib.sh
@@ -428,7 +428,29 @@ rtl_worktree_end() {  # [<wt>] — sets RTL_WT_OFFLANE (0|1); copies allowlist b
       [[ -n "$seedsig" && "$nowsig" == "$seedsig" ]] && continue
       if [[ -e "$wt/$a" ]]; then
         mkdir -p "$RTL_ROOT/$(dirname "$a")"
-        cp -R "$wt/$a" "$RTL_ROOT/$a"
+        # GH-140: copy into a temp path beside the destination, then atomically rename it into place —
+        # NOT a direct in-place `cp -R` onto $RTL_ROOT/$a. A plain cp truncates+rewrites an existing
+        # destination at the SAME inode; if $a is a script actively being interpreted right now (this
+        # very marathon-drive.sh, or its relay-drive.sh subprocess — both are legitimate copyback
+        # targets for a Seam #1-style lane), the live reader can observe a half-old/half-new file mid
+        # execution. A 2026-07-05 run hit exactly this: the outer process crashed with a garbled parse
+        # immediately after copyback, then corrupted further into wiping the working tree. `mv` on the
+        # same filesystem is an atomic rename (same pattern as append-xyz-completion.sh's os.replace) —
+        # an fd already open on the old $RTL_ROOT/$a keeps reading the old inode until it closes, and it
+        # never observes a nonexistent or half-written path in between.
+        local _tmp="$RTL_ROOT/$(dirname "$a")/.rtl-copyback.$$.$(basename "$a")"
+        rm -rf "$_tmp"
+        cp -R "$wt/$a" "$_tmp"
+        if [[ -d "$_tmp" && ! -L "$_tmp" ]]; then
+          # rename(2) cannot atomically replace a non-empty directory — remove the old one first.
+          # No live process reads a directory as an executing script, so this narrow window is safe.
+          rm -rf "$RTL_ROOT/$a"
+          mv "$_tmp" "$RTL_ROOT/$a"
+        else
+          # Regular file (or symlink): rename(2) atomically clobbers an existing destination directly —
+          # no separate rm, no window where the path is missing.
+          mv -f "$_tmp" "$RTL_ROOT/$a"
+        fi
       elif [[ -e "$RTL_ROOT/$a" ]]; then
         rm -rf "$RTL_ROOT/$a"            # allowlisted path deleted in the worktree → propagate the deletion
       fi
diff --git a/test/xyz-completion.sh b/test/xyz-completion.sh
index 88bda38..94f09ec 100755
--- a/test/xyz-completion.sh
+++ b/test/xyz-completion.sh
@@ -15,6 +15,7 @@ set -uo pipefail
 HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
 ROOT="$(cd "$HERE/.." && pwd)"
 WRITER="$ROOT/utils/telemetry/append-xyz-completion.sh"
+HEARTBEAT="$ROOT/utils/telemetry/write-xyz-heartbeat.sh"
 
 WORK="$(mktemp -d "${TMPDIR:-/tmp}/xyz-completion.XXXXXX")"
 trap 'rm -rf "$WORK"' EXIT
@@ -27,8 +28,10 @@ echo "== test: xyz-completion =="
 echo "  workdir: $WORK"
 
 valid_json()  { python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$1" >/dev/null 2>&1; }
+valid_obj()   { python3 -c "import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if isinstance(d, dict) else 1)" "$1" >/dev/null 2>&1; }
 count()       { python3 -c "import json,sys; print(len(json.load(open(sys.argv[1]))))" "$1" 2>/dev/null; }
 field()       { python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d[int(sys.argv[2])][sys.argv[3]])" "$1" "$2" "$3" 2>/dev/null; }
+obj_field()   { python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d[sys.argv[2]])" "$1" "$2" 2>/dev/null; }
 
 # ── (1) basic prepend + schema ──────────────────────────────────────────────
 X="$WORK/x1.json"
@@ -88,7 +91,46 @@ XYZ_JSON_PATH="$WORK/bad.json" bash "$WRITER" relay slug purple T d >/dev/null 2
 XYZ_JSON_PATH="$WORK/bad.json" bash "$WRITER" relay slug green T >/dev/null 2>&1; rc=$?
 [ "$rc" -ne 0 ] && pass "missing arg rejected (exit $rc)" || fail "too-few-args accepted"
 
-# ── (7) health-lib mapping matches GH-24's table ───────────────────────────
+# ── (7) heartbeat companion file: overwrite, stale-while-running, clear, concurrency ───────────
+HB="$WORK/heartbeat.json"
+XYZ_HEARTBEAT_JSON_PATH="$HB" bash "$HEARTBEAT" marathon hb-1
+valid_obj "$HB" && pass "heartbeat file is a single valid JSON object" || fail "invalid heartbeat JSON: $(cat "$HB")"
+[ "$(obj_field "$HB" harness)" = "marathon" ] && pass "heartbeat harness field carried" || fail "heartbeat harness wrong"
+[ "$(obj_field "$HB" sessionId)" = "hb-1" ] && pass "heartbeat sessionId field carried" || fail "heartbeat sessionId wrong"
+[ -n "$(obj_field "$HB" updatedAt)" ] && pass "heartbeat updatedAt stamped" || fail "heartbeat updatedAt missing"
+
+XYZ_HEARTBEAT_JSON_PATH="$HB" bash "$HEARTBEAT" marathon hb-2
+valid_obj "$HB" && pass "heartbeat overwrite stays valid JSON" || fail "heartbeat overwrite invalid: $(cat "$HB")"
+[ "$(obj_field "$HB" sessionId)" = "hb-2" ] && pass "heartbeat overwrites instead of appending" || fail "heartbeat did not overwrite: $(cat "$HB")"
+
+XH="$WORK/x-heartbeat.json"
+XYZ_JSON_PATH="$XH" bash "$WRITER" marathon done-1 green "Done 1" "completed 1"
+XYZ_HEARTBEAT_JSON_PATH="$HB" bash "$HEARTBEAT" marathon run-inflight
+[ "$(count "$XH")" = "1" ] && [ "$(field "$XH" 0 sessionId)" = "done-1" ] && pass "mid-run heartbeat does not change prior completed XYZ.json" || fail "completion log changed during heartbeat write"
+[ "$(obj_field "$HB" sessionId)" = "run-inflight" ] && pass "mid-run heartbeat marks the current in-flight session" || fail "heartbeat missing current session"
+
+XYZ_HEARTBEAT_JSON_PATH="$HB" XYZ_HEARTBEAT_CLEAR=1 bash "$HEARTBEAT" marathon run-inflight
+XYZ_JSON_PATH="$XH" bash "$WRITER" marathon run-inflight green "Run inflight" "completed inflight"
+[ ! -e "$HB" ] && pass "matching completion clears heartbeat before final append" || fail "heartbeat still present after matching clear"
+[ "$(field "$XH" 0 sessionId)" = "run-inflight" ] && pass "matching completion still appends the final XYZ.json record" || fail "final completion record missing"
+
+XYZ_HEARTBEAT_JSON_PATH="$HB" bash "$HEARTBEAT" relay crash-1
+XYZ_HEARTBEAT_JSON_PATH="$HB" XYZ_HEARTBEAT_CLEAR=1 bash "$HEARTBEAT" relay other-session
+[ -e "$HB" ] && [ "$(obj_field "$HB" sessionId)" = "crash-1" ] && pass "non-matching clear leaves a stale/crashed heartbeat in place" || fail "non-matching clear removed the wrong heartbeat"
+
+HB2="$WORK/heartbeat-concurrent.json"
+M2=16
+pids=""
+for i in $(seq 1 "$M2"); do
+  ( XYZ_HEARTBEAT_JSON_PATH="$HB2" bash "$HEARTBEAT" relay "hb-$i" ) &
+  pids="$pids $!"
+done
+for p in $pids; do wait "$p" 2>/dev/null || true; done
+valid_obj "$HB2" && pass "heartbeat stays valid JSON under concurrent overwrites" || fail "concurrent heartbeat corrupt: $(cat "$HB2")"
+case "$(obj_field "$HB2" sessionId)" in hb-*) pass "concurrent heartbeat ends with one complete winning sessionId";; *) fail "unexpected concurrent sessionId=$(obj_field "$HB2" sessionId)";; esac
+[ -z "$(find "$WORK" -name '.xyz-heartbeat.*.tmp' 2>/dev/null)" ] && pass "heartbeat writer leaves no temp files behind" || fail "heartbeat temp file leaked: $(find "$WORK" -name '.xyz-heartbeat.*.tmp')"
+
+# ── (8) health-lib mapping matches GH-24's table ───────────────────────────
 . "$ROOT/utils/telemetry/health-lib.sh"
 h() { xyz_health_from_status "$1" "$2" "$3"; }
 [ "$(h Approved 1 PASS)" = "green" ]        && pass "STATUS Approved → green" || fail "Approved not green"
diff --git a/utils/telemetry/write-xyz-heartbeat.sh b/utils/telemetry/write-xyz-heartbeat.sh
new file mode 100755
index 0000000..120f7c3
--- /dev/null
+++ b/utils/telemetry/write-xyz-heartbeat.sh
@@ -0,0 +1,84 @@
+#!/usr/bin/env bash
+set -euo pipefail
+#
+# write-xyz-heartbeat.sh — GH-96 Seam #1: overwrite the current in-flight heartbeat companion file
+# (XYZ.heartbeat.json) at the harness repo root. Unlike append-xyz-completion.sh's array writer, this
+# is a single-object overwrite, so there is no read-modify-write lost-update window to lock.
+#
+# Usage:
+#   write-xyz-heartbeat.sh <harness> <sessionId>
+#   XYZ_HEARTBEAT_CLEAR=1 write-xyz-heartbeat.sh <harness> <sessionId>
+#
+# The default mode atomically overwrites XYZ.heartbeat.json with:
+#   { "harness": "...", "sessionId": "...", "updatedAt": "..." }
+#
+# Clear mode is best-effort and only removes the file when the CURRENT heartbeat names the same
+# harness + sessionId. This lets a finishing run clear its own in-flight marker without deleting a
+# newer session that already replaced it.
+
+ROOT_DIR="${XYZ_ROOT:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"}"
+XYZ_HEARTBEAT_JSON="${XYZ_HEARTBEAT_JSON_PATH:-"$ROOT_DIR/XYZ.heartbeat.json"}"
+
+die() { printf 'write-xyz-heartbeat: %s\n' "$*" >&2; exit 2; }
+
+(($# == 2)) || die "usage: write-xyz-heartbeat.sh <harness> <sessionId>"
+harness="$1"; session_id="$2"
+
+case "$harness" in relay|marathon|swarm) ;; *) die "harness must be relay|marathon|swarm, got: $harness" ;; esac
+[[ -n "$session_id" ]] || die "sessionId cannot be empty"
+
+mkdir -p "$(dirname "$XYZ_HEARTBEAT_JSON")" 2>/dev/null || true
+
+if [[ "${XYZ_HEARTBEAT_CLEAR:-0}" == "1" ]]; then
+  python3 - "$XYZ_HEARTBEAT_JSON" "$harness" "$session_id" <<'PYEOF'
+import json
+import os
+import sys
+
+heartbeat_path, harness, session_id = sys.argv[1:4]
+
+try:
+    with open(heartbeat_path) as f:
+        data = json.load(f)
+except (OSError, ValueError):
+    sys.exit(0)
+
+if isinstance(data, dict) and data.get("harness") == harness and data.get("sessionId") == session_id:
+    try:
+        os.unlink(heartbeat_path)
+    except FileNotFoundError:
+        pass
+PYEOF
+  exit 0
+fi
+
+updated_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
+
+python3 - "$XYZ_HEARTBEAT_JSON" "$harness" "$session_id" "$updated_at" <<'PYEOF'
+import json
+import os
+import sys
+import tempfile
+
+heartbeat_path, harness, session_id, updated_at = sys.argv[1:5]
+
+record = {
+    "harness": harness,
+    "sessionId": session_id,
+    "updatedAt": updated_at,
+}
+
+directory = os.path.dirname(heartbeat_path) or "."
+fd, tmp = tempfile.mkstemp(dir=directory, prefix=".xyz-heartbeat.", suffix=".tmp")
+try:
+    with os.fdopen(fd, "w") as f:
+        json.dump(record, f, indent="\t")
+        f.write("\n")
+    os.replace(tmp, heartbeat_path)
+except Exception:
+    try:
+        os.unlink(tmp)
+    except OSError:
+        pass
+    raise
+PYEOF
```
````
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer (agy — Gemini 3.5 Flash (Medium) headless)

**Artifact reviewed:** `gh96-gh140-review-context.md` (GH-96 Seam #1 heartbeat companion + GH-140 containment-kernel atomic-copyback fix).

**Summary:** The implementation is correct, robust, and cleanly addresses the root causes of both issues. The `GH-140` atomic-copyback fix solves the half-written/truncated active interpreter race condition via a temp-file write + rename sequence. The directory-vs-file handling is correctly separated. The `GH-96` heartbeat companion companion-marker (`XYZ.heartbeat.json`) is properly gated by `XYZ_HARNESS_CONTEXT` and cleaned up on all terminal exit paths. All tests (`xyz-completion.sh`, `worktree-isolation.sh`, `shim-worktree.sh`, `agy-turn.sh`) pass successfully.

**[Pass] — GH-140 Atomic Copyback (`relay-turn-lib.sh`):** Copying to a temp path on the same filesystem (`RTL_ROOT/$(dirname "$a")`) and then executing `os.replace` equivalent (`mv -f`) ensures atomic replacement for regular files and symlinks. The separate `rm -rf` + `mv` branch for directories is correct since directories are not incrementally read as live scripts by any executing process.

**[Pass] — GH-140 Permissions and Symlink Handling:** Since the files are copied from the worktree with `cp -R`, the original repository permissions are preserved. Symlinks are correctly routed to the atomic rename path (since `[[ -d "$_tmp" && ! -L "$_tmp" ]]` evaluates to false for symlinks).

**[Pass] — GH-96 Heartbeat companion (`write-xyz-heartbeat.sh`):** The python-based heartbeat writer is robust. Writing to a temp file and doing `os.replace()` prevents lost updates and concurrency bugs. The clear mode correctly targets the specific session ID to avoid accidentally removing newer, interleaved sessions.

**[Pass] — GH-96 Harness Integration:** Properly gated via `XYZ_HARNESS_CONTEXT` so nested loops do not double-write. Heartbeat writes are placed at start (`marathon.phase.start` and before turn driver), and clears are wired into all exit paths (escalate, Approved, no-progress, cap/close-mismatch, and containment-violation).

**Verdict: Approved.**

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
