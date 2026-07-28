# RELAY · GH-284 Phase 2 QA — driver heartbeat + --log-github run-log
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-27.
-->

NEXT: Producer
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
6. **Commit only the relay file** (`relay(gh-284-phase-2-qa-driver-heartbeat-log-github-run-log): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **gh284-phase2.diff** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-27

### Artifact — gh284-phase2.diff
```
diff --git a/relay-automation/marathon-drive.sh b/relay-automation/marathon-drive.sh
index b0aad56..4f4b0c1 100755
--- a/relay-automation/marathon-drive.sh
+++ b/relay-automation/marathon-drive.sh
@@ -46,6 +46,8 @@ fi
 #                                that must be added/modified since this phase started, or the gate
 #                                fails (exit 5) even if --pre-advance-cmd passed. Omit for phases with
 #                                no test surface (docs-only, config-only) — default behavior unchanged.
+#     [--log-github]             GH-284 opt-in run log: update the lane's existing GitHub issue with
+#                                one marker comment. Default OFF; missing/unauthenticated gh is ignored.
 #     [--dry-run]                render relay file and print tick seed cmd, then exit
 #
 # Environment overrides (for tests):
@@ -231,6 +233,8 @@ if [[ "${RELAY_DRIVER_LOCKED:-0}" != "1" ]]; then
   # flip the driven run's reported result.
   _marathon_drive_on_exit() {
     local _code=$?
+    marathon_run_github_log "$_code"
+    marathon_driver_heartbeat_stop
     xyz_marathon_cost_summary
     rm -rf "$_lock" 2>/dev/null || true
     exit "$_code"
@@ -245,6 +249,144 @@ log()  { printf 'marathon-drive: %s\n' "$*"; }
 XYZ_APPEND_BIN="${XYZ_APPEND_BIN:-"$_xyz_harness/utils/telemetry/append-xyz-completion.sh"}"
 XYZ_HEARTBEAT_BIN="${XYZ_HEARTBEAT_BIN:-"$_xyz_harness/utils/telemetry/write-xyz-heartbeat.sh"}"
 
+# GH-284 Phase 2: local driver liveness. Unlike XYZ.heartbeat.json (which represents a harness
+# session), this record names the actual marathon driver PID and its phase. It is safe for a
+# sandboxed observer to read: no process-name inspection is needed. The timer is best-effort; the
+# initial write is enough to establish the record and a live PID always wins over stale freshness.
+MARATHON_DRIVER_HEARTBEAT_PID=""
+MARATHON_DRIVER_HEARTBEAT_STARTED=""
+MARATHON_DRIVER_HEARTBEAT_PLAN=""
+: "${MARATHON_DRIVER_HEARTBEAT_INTERVAL:=30}"
+: "${MARATHON_DRIVER_HEARTBEAT_STALE_AFTER:=120}"
+
+marathon_driver_heartbeat_start() {
+  local interval="$MARATHON_DRIVER_HEARTBEAT_INTERVAL" driver_pid="$$"
+  case "$interval" in ''|*[!0-9]*) interval=30 ;; esac
+  (( interval > 0 )) || interval=30
+  MARATHON_DRIVER_HEARTBEAT_STARTED="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
+  MARATHON_DRIVER_HEARTBEAT_PLAN="${MARATHON_PLAN_NAME:-$(basename "$PHASE_BRIEF_FILE" .md)}"
+  if ! rtl_driver_heartbeat_write "$ROOT" "$driver_pid" "$MARATHON_DRIVER_HEARTBEAT_STARTED" \
+      "$MARATHON_DRIVER_HEARTBEAT_PLAN" "$PHASE_ID" "$RELAY_TASK"; then
+    log "driver heartbeat unavailable — continuing without liveness record"
+    return 0
+  fi
+  (
+    while kill -0 "$driver_pid" 2>/dev/null; do
+      sleep "$interval"
+      rtl_driver_heartbeat_write "$ROOT" "$driver_pid" "$MARATHON_DRIVER_HEARTBEAT_STARTED" \
+        "$MARATHON_DRIVER_HEARTBEAT_PLAN" "$PHASE_ID" "$RELAY_TASK" >/dev/null 2>&1 || true
+    done
+  ) >/dev/null 2>&1 &
+  MARATHON_DRIVER_HEARTBEAT_PID=$!
+}
+
+marathon_driver_heartbeat_stop() {
+  # MUST always return 0. This runs inside the EXIT trap, whose whole design (see the GH-222 comment
+  # above) is that `_code` is captured first and re-exited explicitly so a trap-internal failure can
+  # never overwrite the script's real status. A `[[ ... ]] && cmd` tail defeats that: when the guard
+  # is false the function returns 1, `set -e` aborts the trap before it reaches `exit "$_code"`, and
+  # the shell reports 1. Concretely that made `--help` exit 1 instead of 0 (caught by the GH-273
+  # help assertion) and would have made `die()` report 1 instead of 2 — on every path where the
+  # heartbeat never started, which is every early exit.
+  if [[ -n "${MARATHON_DRIVER_HEARTBEAT_PID:-}" ]]; then
+    kill "$MARATHON_DRIVER_HEARTBEAT_PID" 2>/dev/null || true
+    wait "$MARATHON_DRIVER_HEARTBEAT_PID" 2>/dev/null || true
+  fi
+  if [[ -n "${MARATHON_DRIVER_HEARTBEAT_STARTED:-}" ]]; then
+    rtl_driver_heartbeat_clear "$ROOT" || true
+  fi
+  return 0
+}
+
+# GH-284 run log. This is deliberately restricted to comments on an already-existing lane issue:
+# no `gh issue create`, no close/reopen command, and no mutation at all unless --log-github was set.
+# Every failing gh probe is swallowed so external reporting can never alter the marathon result.
+marathon_lane_issue_number() {
+  local candidate
+  for candidate in "$LANE_STATE_KEY" "$RELAY_TASK" "$(basename "$PHASE_BRIEF_FILE")"; do
+    if [[ "$candidate" =~ GH-?([0-9]+) ]]; then
+      printf '%s' "${BASH_REMATCH[1]}"
+      return 0
+    fi
+  done
+  return 1
+}
+
+marathon_trunk_ref() {
+  local ref branch
+  ref="$(git -C "$ROOT" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
+  if [[ -n "$ref" && "$ref" != "origin/HEAD" ]]; then
+    printf '%s' "$ref"
+    return 0
+  fi
+  branch="$(git -C "$ROOT" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
+  [[ -n "$branch" ]] && printf '%s' "$branch"
+}
+
+marathon_run_github_log() {  # <driver-exit-code>
+  local driver_exit="$1" issue repo marker comments comment_id body branch trunk landed pr_url state plan
+  [[ "${LOG_GITHUB:-0}" == "1" && "${MARATHON_DRIVE_STARTED:-0}" == "1" ]] || return 0
+  if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
+    log "--log-github requested, but gh is unavailable or unauthenticated — local telemetry only"
+    return 0
+  fi
+  issue="$(marathon_lane_issue_number || true)"
+  if [[ -z "$issue" ]]; then
+    log "--log-github requested, but no GH issue number is derivable for lane $LANE_STATE_KEY — local telemetry only"
+    return 0
+  fi
+  repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)"
+  if [[ -z "$repo" ]]; then
+    log "--log-github requested, but repository lookup failed — local telemetry only"
+    return 0
+  fi
+  branch="$(git -C "$ROOT" symbolic-ref --quiet --short HEAD 2>/dev/null || echo '(detached)')"
+  trunk="$(marathon_trunk_ref || true)"; landed="no"
+  [[ -n "$trunk" ]] && git -C "$ROOT" merge-base --is-ancestor HEAD "$trunk" 2>/dev/null && landed="yes"
+  pr_url="$(gh pr view --head "$branch" --json url --jq .url 2>/dev/null || true)"
+  [[ -n "$pr_url" ]] || pr_url="NO PR OPENED"
+  state="$(rtl_driver_heartbeat_status "$ROOT" "$MARATHON_DRIVER_HEARTBEAT_STALE_AFTER" 2>/dev/null || true)"
+  [[ -n "$state" ]] || state="finished"
+  plan="${MARATHON_DRIVER_HEARTBEAT_PLAN:-$(basename "$PHASE_BRIEF_FILE" .md)}"
+  marker="<!-- xyz-marathon-run-log:${issue}:${LANE_STATE_KEY} -->"
+  body="$marker
+### Marathon run log
+- plan: \`$plan\`
+- phase: \`$PHASE_ID\`
+- branch: \`$branch\`
+- trunk (derived): \`$trunk\`
+- landed on trunk: **$landed**
+- PR: $pr_url
+- per-phase gate: **$RUN_GATE_RESULT**
+- driver still running: **$state**
+- driver exit: \`$driver_exit\`
+- recorded: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
+  comments="$(gh api --paginate "repos/$repo/issues/$issue/comments?per_page=100" 2>/dev/null || true)"
+  comment_id="$(printf '%s' "$comments" | python3 - "$marker" <<'PYEOF'
+import json
+import sys
+try:
+    comments = json.load(sys.stdin)
+except Exception:
+    comments = []
+for comment in comments if isinstance(comments, list) else []:
+    if sys.argv[1] in str(comment.get("body", "")):
+        print(comment.get("id", ""))
+        break
+PYEOF
+)"
+  if [[ -n "$comment_id" ]]; then
+    gh api --method PATCH "repos/$repo/issues/comments/$comment_id" -f body="$body" >/dev/null 2>&1 \
+      && log "updated GitHub run-log comment on issue #$issue" \
+      || log "GitHub run-log update failed — local telemetry only"
+  else
+    gh api --method POST "repos/$repo/issues/$issue/comments" -f body="$body" >/dev/null 2>&1 \
+      && log "posted GitHub run-log comment on issue #$issue" \
+      || log "GitHub run-log post failed — local telemetry only"
+  fi
+  return 0
+}
+
 # GH-75: append ONE final-completion record for a run whose WHOLE completion IS this single-phase
 # marathon-drive — i.e. a bare `marathon-drive.sh` run (harness:"marathon") or a swarm-preflight-
 # originated run (harness:"swarm", tagged via XYZ_HARNESS_CONTEXT=swarm baked into the generated
@@ -335,6 +477,7 @@ satisfied_lane_terminal() {
 }
 
 run_pre_advance_gate() {
+  local rc=0
   (
     if [[ -n "$TARGET_ROOT" ]]; then
       cd "$TARGET_ROOT"
@@ -350,7 +493,9 @@ run_pre_advance_gate() {
     # TICK_BIN or TICK_REPO_ROOT, which a gate may legitimately need.
     unset XYZ_HARNESS_CONTEXT XYZ_SESSION_ID MARATHON_LANE_NS
     eval "$PRE_ADVANCE_CMD"
-  )
+  ) || rc=$?
+  if [[ "$rc" -eq 0 ]]; then RUN_GATE_RESULT="green"; else RUN_GATE_RESULT="red"; fi
+  return "$rc"
 }
 
 run_post_approve_cmd() {
@@ -434,6 +579,12 @@ Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [o
                           even when --pre-advance-cmd passed. Omit for phases with no test surface
                           (e.g. docs-only) — default gate behavior is unchanged without this flag.
   --force                 GH-45: bypass the per-lane attempt cap for this fire (re-fire a parked lane).
+  --log-github            GH-284 opt-in run log (default OFF). Updates the lane's EXISTING GitHub
+                          issue in place via a marker comment — never creates an issue, never closes
+                          one. Records landed-on-trunk, driver liveness, branch, PR link (or an
+                          explicit NO PR OPENED), and the gate result. If gh is missing or
+                          unauthenticated it degrades to local telemetry and NEVER changes the
+                          marathon's own exit code.
   --dry-run               Render the relay file and print the tick seed; exit without running.
 EOF
 }
@@ -451,6 +602,8 @@ ARTIFACT_PATHS=""    # comma-separated repo-relative file(s) the builder may cre
 REQUIRE_CLEAN=0      # --require-clean: hard-stop if the workspace has pre-existing changes
 REQUIRES_TEST=""     # --requires-test PATH: GH-249 requires_test contract field (opt-in; empty = off)
 FORCE=0              # --force: bypass the GH-45 per-lane attempt cap for this one fire
+LOG_GITHUB=0         # GH-284: external run-log comment; opt-in only
+RUN_GATE_RESULT="not-run"
 DRY_RUN=0
 TARGET_ROOT=""       # --target-root: foreign repo the BUILD lands in (GH-11). Relay thread stays in ROOT;
                      # forwarded to relay-drive.sh (which exports RELAY_TARGET_ROOT for artifact routing).
@@ -471,6 +624,7 @@ while (($# > 0)); do
     --require-clean)   REQUIRE_CLEAN=1; shift ;;
     --requires-test)   REQUIRES_TEST="${2:-}"; shift 2 ;;
     --force)           FORCE=1; shift ;;
+    --log-github)      LOG_GITHUB=1; shift ;;
     --dry-run)         DRY_RUN=1; shift ;;
     --help)            usage; exit 0 ;;
     *)                 die "unknown argument: $1" ;;
@@ -914,6 +1068,7 @@ log "tick token seeded: $RELAY_TASK → $BUILDER"
 xyz_marathon_heartbeat_write
 log "phase start: running relay-drive --round-cap $ROUND_CAP"
 MARATHON_DRIVE_STARTED=1   # GH-222: past this point a phase is really being driven — arm the cost summary
+marathon_driver_heartbeat_start
 
 # ── Step 5: run relay-drive (the loop — unmodified) ────────────────────────
 
diff --git a/relay-automation/relay-turn-lib.sh b/relay-automation/relay-turn-lib.sh
index abfaa67..d247f2e 100644
--- a/relay-automation/relay-turn-lib.sh
+++ b/relay-automation/relay-turn-lib.sh
@@ -413,6 +413,93 @@ rtl_run_bounded() {  # <timeout_secs> <cmd...>
   return "$rc"
 }
 
+# GH-284: a driver heartbeat is deliberately a small, local JSON file rather than a process-name
+# probe. Sandboxed observers can read this file even when `ps` sees no host processes. The status
+# rule is intentionally asymmetric: a live PID is running even if the write is old; only an old
+# heartbeat *and* an absent PID is stale. This avoids the dangerous false "finished" answer while a
+# live driver is temporarily delayed.
+rtl_driver_heartbeat_path() {  # <repo-root>
+  printf '%s/.tick/driver-heartbeat.json' "$1"
+}
+
+rtl_driver_heartbeat_write() {  # <repo-root> <pid> <started-utc> <plan> <phase-id> <relay-task>
+  local root="$1" pid="$2" started="$3" plan="$4" phase_id="$5" relay_task="$6" path updated
+  path="${RTL_DRIVER_HEARTBEAT_FILE:-$(rtl_driver_heartbeat_path "$root")}"
+  updated="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
+  mkdir -p "$(dirname "$path")" 2>/dev/null || return 1
+  python3 - "$path" "$pid" "$started" "$updated" "$plan" "$phase_id" "$relay_task" <<'PYEOF'
+import json
+import os
+import sys
+import tempfile
+
+path, pid, started, updated, plan, phase_id, relay_task = sys.argv[1:]
+record = {
+    "pid": int(pid),
+    "started_utc": started,
+    "updated_utc": updated,
+    "plan": plan,
+    "phase_id": phase_id,
+    "relay_task": relay_task,
+}
+directory = os.path.dirname(path) or "."
+fd, tmp = tempfile.mkstemp(dir=directory, prefix=".driver-heartbeat.", suffix=".tmp")
+try:
+    with os.fdopen(fd, "w") as f:
+        json.dump(record, f, sort_keys=True)
+        f.write("\n")
+    os.replace(tmp, path)
+except Exception:
+    try:
+        os.unlink(tmp)
+    except OSError:
+        pass
+    raise
+PYEOF
+}
+
+rtl_driver_heartbeat_clear() {  # <repo-root>
+  local root="$1" path
+  path="${RTL_DRIVER_HEARTBEAT_FILE:-$(rtl_driver_heartbeat_path "$root")}"
+  rm -f -- "$path" 2>/dev/null || true
+}
+
+rtl_driver_heartbeat_status() {  # <repo-root> [stale-after-seconds] → running|finished|stale
+  local root="$1" stale_after="${2:-120}" path fields pid age
+  path="${RTL_DRIVER_HEARTBEAT_FILE:-$(rtl_driver_heartbeat_path "$root")}"
+  [[ -f "$path" ]] || { printf 'finished'; return 1; }
+  case "$stale_after" in ''|*[!0-9]*) stale_after=120 ;; esac
+  fields="$(python3 - "$path" <<'PYEOF'
+import datetime as dt
+import json
+import sys
+
+try:
+    with open(sys.argv[1]) as f:
+        data = json.load(f)
+    pid = int(data["pid"])
+    updated = dt.datetime.fromisoformat(str(data["updated_utc"]).replace("Z", "+00:00"))
+    age = max(0, int((dt.datetime.now(dt.timezone.utc) - updated).total_seconds()))
+    print(f"{pid}\t{age}")
+except Exception:
+    pass
+PYEOF
+)"
+  [[ "$fields" == *$'\t'* ]] || { printf 'finished'; return 1; }
+  pid="${fields%%$'\t'*}"; age="${fields#*$'\t'}"
+  case "$pid:$age" in *[!0-9:]*|:*) printf 'finished'; return 1 ;; esac
+  if kill -0 "$pid" 2>/dev/null; then
+    printf 'running'
+    return 0
+  fi
+  if [[ "$age" -gt "$stale_after" ]]; then
+    printf 'stale'
+    return 2
+  fi
+  printf 'finished'
+  return 1
+}
+
 # --- Worktree isolation (ROADMAP Part A Phase 3.6 — the airtight async/side-effect close) ----------
 # Before touching anything below: read WORKTREE-SAFETY.md (repo root) — it documents the
 # git-worktree footguns and the safe recovery path for a corrupted RTL_ROOT/.git (GH-177). This is
diff --git a/test/gh284-runlog-heartbeat.sh b/test/gh284-runlog-heartbeat.sh
new file mode 100644
index 0000000..a806d1d
--- /dev/null
+++ b/test/gh284-runlog-heartbeat.sh
@@ -0,0 +1,104 @@
+#!/usr/bin/env bash
+# GH-284 Phase 2: file-based driver liveness and opt-in, non-fatal GitHub run-log.
+source "$(dirname "$0")/_setup.sh" gh284-runlog-heartbeat
+
+ROOT="$(cd "$(dirname "$0")/.." && pwd)"
+LIB="$ROOT/relay-automation/relay-turn-lib.sh"
+DRIVER="$ROOT/relay-automation/marathon-drive.sh"
+source "$LIB"
+
+HB="$A/.tick/driver-heartbeat.json"
+export RTL_DRIVER_HEARTBEAT_FILE="$HB"
+mkdir -p "$A/.tick"
+
+# A minimal-env child is the relevant sandbox boundary: it can read the JSON without ps access.
+rtl_driver_heartbeat_write "$A" "$$" "2026-07-28T00:00:00Z" "gh284-plan" "p1" "MARATHON-GH284-TURN"
+READER="$(env -i PATH="$PATH" python3 - "$HB" <<'PYEOF'
+import json
+import sys
+with open(sys.argv[1]) as f:
+    h = json.load(f)
+required = {"pid", "started_utc", "updated_utc", "plan", "phase_id", "relay_task"}
+print("ok" if required <= set(h) and h["pid"] > 0 else "bad")
+PYEOF
+)"
+[ "$READER" = ok ] && pass "sandboxed reader sees the complete driver heartbeat" || fail "sandboxed heartbeat reader got: $READER"
+
+STATE="$(rtl_driver_heartbeat_status "$A" 1 2>/dev/null || true)"
+[ "$STATE" = running ] && pass "live driver heartbeat reports running" || fail "live heartbeat reported: $STATE"
+
+# A stale write alone must not classify a still-live PID as stale.
+python3 - "$HB" "$$" <<'PYEOF'
+import json, sys
+with open(sys.argv[1]) as f: h = json.load(f)
+h["pid"] = int(sys.argv[2]); h["updated_utc"] = "2000-01-01T00:00:00Z"
+with open(sys.argv[1], "w") as f: json.dump(h, f)
+PYEOF
+STATE="$(rtl_driver_heartbeat_status "$A" 1 2>/dev/null || true)"
+[ "$STATE" = running ] && pass "stale heartbeat plus live PID remains running" || fail "live stale heartbeat reported: $STATE"
+
+# Conversely, a dead PID alone is not labelled stale until the heartbeat is old too.
+python3 - "$HB" <<'PYEOF'
+import datetime as dt, json, sys
+with open(sys.argv[1]) as f: h = json.load(f)
+h["pid"] = 999999; h["updated_utc"] = dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z")
+with open(sys.argv[1], "w") as f: json.dump(h, f)
+PYEOF
+STATE="$(rtl_driver_heartbeat_status "$A" 3600 2>/dev/null || true)"
+[ "$STATE" = finished ] && pass "dead PID with fresh heartbeat is never reported running" || fail "dead fresh heartbeat reported: $STATE"
+python3 - "$HB" <<'PYEOF'
+import json, sys
+with open(sys.argv[1]) as f: h = json.load(f)
+h["updated_utc"] = "2000-01-01T00:00:00Z"
+with open(sys.argv[1], "w") as f: json.dump(h, f)
+PYEOF
+STATE="$(rtl_driver_heartbeat_status "$A" 1 2>/dev/null || true)"
+[ "$STATE" = stale ] && pass "staleness requires both an old heartbeat and absent PID" || fail "dead stale heartbeat reported: $STATE"
+rtl_driver_heartbeat_clear "$A"
+[ ! -e "$HB" ] && pass "heartbeat is removed on clean stop" || fail "heartbeat remained after clean stop"
+
+# --log-github is opt-in and a missing gh must never change the marathon's own exit code.
+tick_a init >/dev/null
+printf '.tick/\n' > "$A/.gitignore"
+git -C "$A" add .gitignore && git -C "$A" commit -qm init
+BRIEF="$WORK/GH-284-brief.md"; printf 'GH-284 heartbeat brief\n' > "$BRIEF"
+STUB_RD="$WORK/relay-drive.sh"
+printf '#!/usr/bin/env bash\nexit 3\n' > "$STUB_RD"; chmod +x "$STUB_RD"
+STUB_CLAUDE="$WORK/claude"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_CLAUDE"; chmod +x "$STUB_CLAUDE"
+STUB_AGY="$WORK/agy"; printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_AGY"; chmod +x "$STUB_AGY"
+
+# The point of the trimmed PATH below is to make `gh` unavailable, NOT to strip the toolchain.
+# A bare PATH=/usr/bin:/bin also loses `node` (it lives outside the system dirs on macOS/nvm-style
+# installs), so the driver's internal node calls died with 127 and this test failed for a reason
+# unrelated to what it asserts. Symlink just `node` into a dedicated dir and prepend that: `gh`
+# stays absent (it is outside /usr/bin and /bin here), which is the condition under test.
+NODE_ONLY="$WORK/node-only"; mkdir -p "$NODE_ONLY"
+if NODE_BIN="$(command -v node 2>/dev/null)" && [ -n "$NODE_BIN" ]; then
+  ln -sf "$NODE_BIN" "$NODE_ONLY/node"
+fi
+
+run_driver() {
+  XYZ_PYTHON=0 MARATHON_COST_SUMMARY=0 MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$STUB_RD" \
+    TICK_REPO_ROOT="$A" TICK_BIN="$TICK" CLAUDE_BIN="$STUB_CLAUDE" AGY_BIN="$STUB_AGY" \
+    PATH="$NODE_ONLY:/usr/bin:/bin" bash "$DRIVER" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
+      --phase-id "$1" --relay-task "MARATHON-GH284-${1}" --builder claude --reviewer agy \
+      --pre-advance-cmd true "${@:2}"
+}
+
+NO_LOG_OUT="$(run_driver no-log 2>&1)"; NO_LOG_RC=$?
+WITH_LOG_OUT="$(run_driver with-log --log-github 2>&1)"; WITH_LOG_RC=$?
+[ "$NO_LOG_RC" -eq 3 ] && [ "$WITH_LOG_RC" -eq 3 ] \
+  && pass "--log-github with gh unavailable preserves the marathon exit code" \
+  || fail "expected both runs to exit 3; no-log=$NO_LOG_RC with-log=$WITH_LOG_RC ($WITH_LOG_OUT)"
+printf '%s\n' "$WITH_LOG_OUT" | grep -q 'local telemetry only' \
+  && pass "missing gh degrades to local telemetry" \
+  || fail "missing-gh degradation was not reported: $WITH_LOG_OUT"
+[ ! -e "$A/.tick/driver-heartbeat.json" ] \
+  && pass "driver exit clears its heartbeat file" \
+  || fail "driver exit left a heartbeat file"
+XYZ_PYTHON=0 bash "$DRIVER" --help | grep -q -- '--log-github' \
+  && pass "--log-github is exposed as an explicit opt-in" \
+  || fail "--log-github missing from help"
+
+echo "  gh284-runlog-heartbeat: $PASS pass, $FAIL fail"
+[ "$FAIL" = 0 ]
diff --git a/validate.sh b/validate.sh
index 8609957..884b5ea 100755
--- a/validate.sh
+++ b/validate.sh
@@ -49,6 +49,7 @@ TESTS=(
   "shim-worktree.sh"
   "marathon-yaml.sh"
   "marathon-drive.sh"
+  "gh284-runlog-heartbeat.sh"   # GH-284 (driver heartbeat + opt-in idempotent run log)
   "gh307-gate-env-scrub.sh"      # GH-307 (pre-advance gate must not inherit run-identity tags)
   "hq-marathon-live.sh"          # GH-218 (cross-repo live marathon status)
   "debug-mantra.sh"              # GH-162 (debug-mantra auto-trigger note on a phase's prior attempt)
```
- Definition of Done (filled 2026-07-28, per codex round-1 Should #2):
  1. **Liveness is file-based, not process-based.** The driver writes `.tick/driver-heartbeat.json`
     with `{pid, started_utc, updated_utc, plan, phase_id, relay_task}`, refreshed while running and
     removed on clean exit. A minimal-env reader (no `ps`) can determine liveness from it.
  2. **Staleness requires BOTH** an old heartbeat AND an absent PID — never either alone. A live PID
     with a stale timestamp is `running`; a dead PID with a fresh timestamp is never `running`.
  3. **The driver's exit code is never altered** by any of this. `--log-github` failure, missing
     `gh`, or heartbeat teardown must not change it — including on early-exit paths (`--help` → 0,
     `die()` → 2), which is where an EXIT-trap tail returning non-zero silently corrupted it.
  4. **`--log-github` is default OFF** and updates the lane's **existing** issue in place via a
     marker comment. It never creates an issue and never closes one.
  5. **Idempotent across pagination.** Re-running a lane updates the one marker comment. A
     multi-page comment response must still resolve the existing comment id — the concatenated
     `--paginate` array previously broke this and silently posted duplicates.
  6. **Every `gh` call is scoped to `$ROOT`'s repository**, resolved without depending on the
     ambient CWD, so a `--target-root`/foreign-CWD run cannot post into the wrong repo. A
     local-path remote must not be accepted as an `owner/name` slug.
  7. **Regression coverage fails against the pre-fix code** — verified explicitly for the parser
     (old parser returns empty/raises on multi-page input; new returns the comment id).
  8. `bash validate.sh` exit 0, with the new test registered in its `TESTS` array.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · codex · Round 1

- [Blocker] `marathon_run_github_log` resolves its repository with `gh repo view` and looks up the PR with `gh pr view --head "$branch"`, neither scoped to `$ROOT` or `--target-root`. From a foreign invocation CWD, it can post to issue `#$issue` in the wrong repository (or report the wrong PR). Derive the repository from `$ROOT` and pass it explicitly to every `gh` call (`--repo "$repo"`).
- [Blocker] The marker lookup is not idempotent once an issue has more than one comments page: `gh api --paginate` emits one JSON array per page, so the quoted `json.load(sys.stdin)` fails on concatenated arrays, falls back to `[]`, and the code POSTS a second marker comment. Use `--paginate --slurp` and flatten the resulting page arrays (or otherwise parse every page) before choosing POST versus PATCH.
- [Should] `test/gh284-runlog-heartbeat.sh` only covers unavailable `gh`; it never exercises authenticated posting/updating, repository scoping, marker replacement, or multi-page comments. Add a stubbed `gh` happy-path test that asserts the first run POSTs exactly one marker, the next run PATCHes it, and a paginated comment response remains a PATCH.
- [Should] The Definition of Done is still the scaffold placeholder (`"_<fill in the acceptance criteria the Reviewer grades against>_"`), so there is no agreed acceptance contract for the heartbeat and external-comment behavior. Replace it with concrete criteria before final approval.

Verdict: Changes requested

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
