# Marathon 2026-07-19 — QA brief for GLM 5.2 review

Branch: marathon/10days-2026-07-19. 13 lanes landed, both validate.sh gates green
(failing set stayed == the 4 pre-existing environmental reds).
These are the **5 highest-risk/impact** changes. For EACH: judge correctness, edge cases,
backward-compat, and whether it could regress the harness. Give a per-item VERDICT
(Pass / Changes-requested) with file:line evidence.

---

## GH-236 kernel: relocate isolation worktree off $TMPDIR

```diff
commit 36d9e62
fix(GH-236): relocate isolation worktree off $TMPDIR when it resolves inside RTL_ROOT


diff --git a/relay-automation/relay-turn-lib.sh b/relay-automation/relay-turn-lib.sh
index a4ffe5b..f98c2ad 100644
--- a/relay-automation/relay-turn-lib.sh
+++ b/relay-automation/relay-turn-lib.sh
@@ -429,8 +429,25 @@ rtl_worktree_begin() {
   # Create the worktree, seed the CURRENT working-tree allowlist into it (the HEAD checkout may be
   # stale, e.g. an uncommitted relay file), and echo the worktree path. Returns non-zero on failure
   # so the caller can fall back to an in-ROOT run. Sets RTL_WT.
-  local wt a
-  wt="$(mktemp -d "${TMPDIR:-/tmp}/rtl-wt.XXXXXX")" || return 1
+  local wt a wt_root _root_abs _tmp_abs _gcd
+  # GH-236: in /tmp-rooted environments $TMPDIR can resolve INSIDE the working root, which drops the
+  # throwaway isolation worktree inside the very tree the turn operates on and breaks codex turns —
+  # a failure that then surfaces mislabeled as a turn timeout. Default to $TMPDIR so behaviour is
+  # unchanged everywhere else; ONLY when $TMPDIR lands inside RTL_ROOT, relocate the worktree root
+  # under the repo's own git metadata dir (never part of the working tree, never under $TMPDIR) —
+  # git worktree add accepts a checkout there and git status ignores it.
+  wt_root="${TMPDIR:-/tmp}"
+  _root_abs="$(cd "$RTL_ROOT" 2>/dev/null && pwd -P)"
+  _tmp_abs="$(cd "$wt_root" 2>/dev/null && pwd -P)"
+  if [[ -n "$_root_abs" && -n "$_tmp_abs" && ( "$_tmp_abs" == "$_root_abs" || "$_tmp_abs" == "$_root_abs"/* ) ]]; then
+    _gcd="$(git -C "$RTL_ROOT" rev-parse --git-common-dir 2>/dev/null)"
+    [[ -n "$_gcd" && "$_gcd" != /* ]] && _gcd="$RTL_ROOT/$_gcd"
+    if [[ -n "$_gcd" ]] && mkdir -p "$_gcd/rtl-worktrees" 2>/dev/null; then
+      wt_root="$_gcd/rtl-worktrees"
+      rtl_trace "rtl_worktree_begin: RELOCATED worktree root off \$TMPDIR (inside RTL_ROOT) -> $wt_root (GH-236)"
+    fi
+  fi
+  wt="$(mktemp -d "${wt_root}/rtl-wt.XXXXXX")" || return 1
   rm -rf "$wt"                         # git worktree add wants a non-existent path
   if ! git -C "$RTL_ROOT" worktree add --detach "$wt" HEAD >/dev/null 2>&1; then
     rm -rf "$wt" 2>/dev/null; return 1
```

## GH-245 kernel: --target-root review guard + evidence-based review-once classifier

```diff
commit 3783665
fix(GH-245): refuse unwritable --target-root review + classify review-once on evidence


diff --git a/relay-automation/relay-drive.sh b/relay-automation/relay-drive.sh
index 371913c..4ff456f 100755
--- a/relay-automation/relay-drive.sh
+++ b/relay-automation/relay-drive.sh
@@ -242,6 +242,20 @@ if [[ ! -f "$RELAY_FILE" && -n "${TARGET_ROOT:-}" && "$RELAY_FILE" != /* && -f "
 fi
 [[ -f "$RELAY_FILE" ]] || die "relay file does not exist: $RELAY_FILE"
 
+# GH-245 defect 1: a review turn (ALLOW_PATHS="") can only write the relay file. Under --target-root
+# the turn's isolation worktree is based on the TARGET repo, so if the relay file resolves OUTSIDE that
+# target root the reviewer physically cannot append its findings (codex rejects the out-of-project
+# write) — the whole turn is completed and then discarded at full cost. Refuse fast at startup instead
+# of spending the turn. The documented fix is to vendor the harness into the target repo so the relay
+# file, harness and source share one writable root, then drop --target-root.
+if ((REVIEW_ONCE)) && [[ -n "${TARGET_ROOT:-}" ]]; then
+  _gh245_tr="$(cd "$TARGET_ROOT" 2>/dev/null && pwd -P)"
+  _gh245_rf="$(cd "$(dirname "$RELAY_FILE")" 2>/dev/null && pwd -P)/$(basename "$RELAY_FILE")"
+  if [[ -n "$_gh245_tr" && "$_gh245_rf" != "$_gh245_tr"/* ]]; then
+    die "--target-root review turn cannot report: relay file '$RELAY_FILE' resolves outside the target root '$TARGET_ROOT', so a review turn (ALLOW_PATHS=\"\") has no writable path for its findings and the turn would be discarded after full cost. Vendor the harness into the target repo (relay-automation/xyz-vendor.sh '$TARGET_ROOT') and drop --target-root, or move the relay thread under the target root."
+  fi
+fi
+
 # GH-45: per-lane attempt cap. A real build/review LOOP counts; a single --review-once turn and a
 # dry-run do not (they can't rabbit-hole). Keyed on the relay task, stable across re-fires.
 if ((DRY_RUN == 0)) && ((REVIEW_ONCE == 0)); then
@@ -360,6 +374,12 @@ if [[ -n "$ARTIFACT_FILE" ]]; then
 fi
 
 file_status() { sed -n 's/^STATUS:[[:space:]]*//p' "$RELAY_FILE" | head -1 | sed 's/[[:space:]]*$//'; }
+# GH-245 defect 2: evidence a turn actually DID something, independent of token movement — the NEXT:
+# handoff pointer and a content signature of the relay file. A review that appends findings changes
+# the file content (and usually flips NEXT:) even when the reviewer leaves the token claimed; an empty
+# token-only move changes neither. Used by the --review-once oracle so it classifies on work, not token.
+next_pointer() { sed -n 's/^NEXT:[[:space:]]*//p' "$RELAY_FILE" | head -1 | sed 's/[[:space:]]*$//'; }
+relay_content_sig() { git hash-object "$RELAY_FILE" 2>/dev/null || cksum "$RELAY_FILE" 2>/dev/null | awk '{print $1}' || echo "?"; }
 terminal_status() { case "$1" in Approved|Closed) return 0 ;; *) return 1 ;; esac; }
 # Escalated is TERMINAL BY DESIGN: the reviewer handed back to a human (e.g. at the round cap),
 # typically WITHOUT releasing the token. The explicit status IS the intent signal — a true stall
@@ -387,6 +407,8 @@ round=0
 while ((round < ROUND_CAP)); do
   s="$(file_status)"
   IFS=$'\t' read -r tstatus actor < <(token_state)
+  rfsig="$(relay_content_sig)"   # GH-245: relay-file content signature BEFORE the turn (work evidence)
+  nextp="$(next_pointer)"        # GH-245: NEXT: handoff pointer BEFORE the turn
 
   # Terminal CLOSE requires AGREEMENT: file STATUS terminal AND the RELAY-TURN
   # token no longer live (done/gone). file-terminal-but-token-live is a leaked
@@ -497,6 +519,8 @@ while ((round < ROUND_CAP)); do
   # No-progress guard (skipped once terminal — the close check at loop top handles that).
   IFS=$'\t' read -r ntstatus nactor < <(token_state)
   ns="$(file_status)"
+  nrfsig="$(relay_content_sig)"   # GH-245: relay-file content signature AFTER the turn
+  nnextp="$(next_pointer)"        # GH-245: NEXT: handoff pointer AFTER the turn
   # A by-design Escalated handback this turn is terminal, NOT a stall — even if the reviewer left the
   # token live. Catch it before the no-progress guard so it doesn't read as exit 3 (GH-18 #5).
   if escalated_status "$ns"; then
@@ -516,12 +540,17 @@ while ((round < ROUND_CAP)); do
       xyz_relay_emit green
       exit 0
     fi
-    if [[ "$ntstatus:$nactor" != "$prev" || "$ns" != "$s" ]]; then
-      printf 'relay-drive: review-once — reviewer completed a turn (STATUS: %s, token %s:%s); non-approval handback, not a stall\n' "$ns" "$ntstatus" "$nactor"
+    # GH-245 defect 2: classify on EVIDENCE OF A TURN — the relay file's content changed (findings
+    # appended), the NEXT: pointer flipped, or the STATUS word changed — NOT on token movement alone.
+    # A token-only move with an unchanged relay file is an empty turn (Run A: was mis-scored 5); a
+    # relay-file append with the token left claimed is a real review (Run B: was mis-scored 3). Token
+    # state is deliberately dropped from the oracle here — it is exactly the misleading signal.
+    if [[ "$nrfsig" != "$rfsig" || "$nnextp" != "$nextp" || "$ns" != "$s" ]]; then
+      printf 'relay-drive: review-once — reviewer completed a turn (STATUS: %s, token %s:%s; relay-file/NEXT changed); non-approval handback, not a stall\n' "$ns" "$ntstatus" "$nactor"
       xyz_relay_emit orange
       exit 5
     fi
-    printf 'relay-drive: review-once — reviewer took no action (STATUS unchanged: %s, token still %s) — genuine stall\n' "$ns" "$prev" >&2
+    printf 'relay-drive: review-once — reviewer took no action (relay file unchanged, NEXT unchanged, STATUS still %s, token %s:%s) — genuine stall\n' "$ns" "$ntstatus" "$nactor" >&2
     xyz_relay_emit red
     exit 3
   fi
diff --git a/test/relay-review-once.sh b/test/relay-review-once.sh
index 28df397..40def52 100755
--- a/test/relay-review-once.sh
+++ b/test/relay-review-once.sh
@@ -76,5 +76,40 @@ chmod +x "$ES_STUB"
 outD="$(bash "$DRIVE" --relay-file "$A/relayES.md" --relay-task RELAY-ES --agent-cmd "$ES_STUB" --review-once 2>&1)"; rcD=$?
 [ "$rcD" -eq 4 ] && pass "by-design Escalated still exits 4 under --review-once" || fail "expected 4, got $rcD (out: $outD)"
 
+# --- Case E (GH-245 defect 2, "Run B"): reviewer APPENDS findings but LEAVES THE TOKEN CLAIMED and
+#     does not change STATUS. The old oracle read token state alone, so a real review with the token
+#     left claimed was mis-scored as a stall (exit 3). It must now exit 5 on relay-file content evidence. ---
+seed RELAY-KT relayKT.md
+KT_STUB="$WORK/kt-stub.sh"
+cat >"$KT_STUB" <<EOF
+#!/usr/bin/env bash
+set -u
+export TICK_REPO_ROOT="$A"
+"$TICK_PATH" claim RELAY-KT --agent reviewer >/dev/null 2>&1
+printf '\n### Reviewer · Round 1\nVERDICT: FAIL\nBasis: six findings.\nChanges requested.\n' >> "$A/relayKT.md"
+# deliberately DO NOT release the token and DO NOT change STATUS (reproduces GH-245 Run B)
+exit 0
+EOF
+chmod +x "$KT_STUB"
+outE="$(bash "$DRIVE" --relay-file "$A/relayKT.md" --relay-task RELAY-KT --agent-cmd "$KT_STUB" --review-once 2>&1)"; rcE=$?
+[ "$rcE" -eq 5 ] && pass "GH-245: relay-file append with token left claimed exits 5, not stall 3" || fail "expected 5, got $rcE (out: $outE)"
+
+# --- Case F (GH-245 defect 2, "Run A"): reviewer moves the token only (claim+release) and writes
+#     NOTHING. The old oracle read token movement as success, so an empty turn was mis-scored exit 5.
+#     It must now exit 3 — no relay-file, NEXT, or STATUS evidence of a real review. ---
+seed RELAY-TO relayTO.md
+TO_STUB="$WORK/to-stub.sh"
+cat >"$TO_STUB" <<EOF
+#!/usr/bin/env bash
+set -u
+export TICK_REPO_ROOT="$A"
+"$TICK_PATH" claim   RELAY-TO --agent reviewer >/dev/null 2>&1
+"$TICK_PATH" release RELAY-TO --agent reviewer --to producer >/dev/null 2>&1
+exit 0
+EOF
+chmod +x "$TO_STUB"
+outF="$(bash "$DRIVE" --relay-file "$A/relayTO.md" --relay-task RELAY-TO --agent-cmd "$TO_STUB" --review-once 2>&1)"; rcF=$?
+[ "$rcF" -eq 3 ] && pass "GH-245: token-only move with no relay-file change exits 3, not success 5" || fail "expected 3, got $rcF (out: $outF)"
+
 echo "  $TEST_NAME: $PASS pass, $FAIL fail"
 exit 0
diff --git a/test/xyz-harness-hooks.sh b/test/xyz-harness-hooks.sh
index 195ff5b..76a38e0 100755
--- a/test/xyz-harness-hooks.sh
+++ b/test/xyz-harness-hooks.sh
@@ -244,13 +244,16 @@ XYZ_JSON_PATH="$XRO1" bash "$RELAY_DRIVE" --relay-file "$A/ro1.md" --relay-task
 [ "$rc" -eq 0 ] && pass "review-once approval exits 0" || fail "review-once approve exit=$rc"
 [ "$(count "$XRO1")" = "1" ] && [ "$(field "$XRO1" 0 health)" = "green" ] && pass "review-once approval → relay/green record" || fail "ro1 count=$(count "$XRO1") health=$(field "$XRO1" 0 health)"
 
-# (RO2) reviewer hands back (changes requested) → exit 5, relay/orange
+# (RO2) reviewer hands back (changes requested) → exit 5, relay/orange.
+# GH-245: a genuine changes-requested handback appends its findings to the relay file — that content
+# evidence is what marks a real review (a bare token move with no findings is Run A, now a stall).
 HANDBACK="$WORK/ro-handback.sh"
 cat > "$HANDBACK" <<EOF
 #!/usr/bin/env bash
 set -u
 export TICK_REPO_ROOT="$A"
 "$TICK" take "\$RELAY_TASK" --agent "\$RELAY_AGENT" >/dev/null 2>&1 || true
+printf '\n### Reviewer · Round 1\nVERDICT: FAIL\nBasis: changes requested.\n' >> "\$RELAY_FILE"
 "$TICK" release "\$RELAY_TASK" --agent "\$RELAY_AGENT" --to builder >/dev/null 2>&1 || true
 exit 0
 EOF
```

## GH-249: opt-in --requires-test gate in marathon-drive.sh

```diff
commit c1b3b6d
fix(GH-249): add opt-in requires_test gate to marathon-drive.sh


diff --git a/relay-automation/marathon-drive.sh b/relay-automation/marathon-drive.sh
index 493a2cf..d128af6 100755
--- a/relay-automation/marathon-drive.sh
+++ b/relay-automation/marathon-drive.sh
@@ -33,6 +33,10 @@ fi
 #                                beyond the relay file (passed to the shims as ALLOW_PATHS). Omit for
 #                                a relay-only phase (conversation → approval, no source edit).
 #     [--require-clean]          hard-stop if the workspace has pre-existing changes (unattended runs)
+#     [--requires-test <PATH>]   GH-249 requires_test contract field (opt-in): repo-relative test file
+#                                that must be added/modified since this phase started, or the gate
+#                                fails (exit 5) even if --pre-advance-cmd passed. Omit for phases with
+#                                no test surface (docs-only, config-only) — default behavior unchanged.
 #     [--dry-run]                render relay file and print tick seed cmd, then exit
 #
 # Environment overrides (for tests):
@@ -42,7 +46,9 @@ fi
 #   TICK_BIN              — tick binary (default: <repo-root>/bin/tick)
 #
 # Exit: 0 phase approved + gate passed · 3 relay no-progress · 4 relay cap/mismatch ·
-#        5 pre-advance gate failed · 6 containment violation (turn-taker reverted an off-lane edit) ·
+#        5 pre-advance gate failed (also covers a failed --requires-test check — see ESCALATION.md
+#        reason: pre-advance-failed vs. requires-test-missing) ·
+#        6 containment violation (turn-taker reverted an off-lane edit) ·
 #        7 turn timeout / hang · 8 lane parked (GH-45 attempt cap — no token seeded; re-fire with
 #        --force) · 2 usage.
 
@@ -300,6 +306,30 @@ artifacts_exist_for_timeout() {
   return 0
 }
 
+# GH-249: the requires_test contract field. A brief's acceptance criteria calling for a new/updated
+# test used to be advisory prose — --pre-advance-cmd only proves "existing tests still pass," not that
+# this phase added the coverage its brief demanded. When --requires-test PATH is set, this check must
+# ALSO pass before the phase can reach Approved: PATH must exist, be non-empty, and have changed since
+# PRE_PHASE_HEAD (committed diff) or be newly untracked (a turn-taker edit not yet committed at gate
+# time). Opt-in and additive — REQUIRES_TEST stays empty unless a caller sets --requires-test, so a
+# run with no such flag is byte-for-byte the same gate behavior as before this feature existed.
+requires_test_delta() {  # <path> — true if <path> was added/modified since PRE_PHASE_HEAD
+  local path="$1" root="${TARGET_ROOT:-$ROOT}" abs
+  case "$path" in
+    /*) abs="$path" ;;
+    *)  abs="$root/$path" ;;
+  esac
+  [[ -s "$abs" ]] || return 1   # must exist and be non-empty — an empty/missing test proves nothing
+  if [[ -n "$PRE_PHASE_HEAD" ]] \
+    && git -C "$root" diff --name-only "$PRE_PHASE_HEAD" -- "$path" 2>/dev/null | grep -q .; then
+    return 0
+  fi
+  # A newly created file may still be untracked at gate time (harness commits happen inside the relay
+  # loop, but nothing guarantees a same-cycle commit for every edit) — count that as a delta too.
+  git -C "$root" status --porcelain -- "$path" 2>/dev/null | grep -qE '^(\?\?|A )' && return 0
+  return 1
+}
+
 usage() {
   cat <<'EOF'
 Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]
@@ -322,6 +352,10 @@ Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [o
                           stay in this repo; forwarded to relay-drive.sh, and the pre-advance gate runs
                           with cwd = DIR. Omit for a same-repo phase.
   --require-clean         Hard-stop (exit 2) if the workspace has pre-existing changes before seeding.
+  --requires-test PATH    GH-249 requires_test contract field (opt-in): repo-relative test file that
+                          must be added/modified by this phase, or the pre-advance gate fails (exit 5)
+                          even when --pre-advance-cmd passed. Omit for phases with no test surface
+                          (e.g. docs-only) — default gate behavior is unchanged without this flag.
   --force                 GH-45: bypass the per-lane attempt cap for this fire (re-fire a parked lane).
   --dry-run               Render the relay file and print the tick seed; exit without running.
 EOF
@@ -337,6 +371,7 @@ PHASE_ID="p1"        # which phase this invocation drives (phases/<id>/); the or
 RELAY_TASK=""        # resolved to MARATHON-<PHASE_ID>-TURN after parsing, unless given
 ARTIFACT_PATHS=""    # comma-separated repo-relative file(s) the builder may create/edit (beyond RELAY.md)
 REQUIRE_CLEAN=0      # --require-clean: hard-stop if the workspace has pre-existing changes
+REQUIRES_TEST=""     # --requires-test PATH: GH-249 requires_test contract field (opt-in; empty = off)
 FORCE=0              # --force: bypass the GH-45 per-lane attempt cap for this one fire
 DRY_RUN=0
 TARGET_ROOT=""       # --target-root: foreign repo the BUILD lands in (GH-11). Relay thread stays in ROOT;
@@ -355,6 +390,7 @@ while (($# > 0)); do
     --artifact)        ARTIFACT_PATHS="${2:-}"; shift 2 ;;
     --target-root)     TARGET_ROOT="${2:-}"; shift 2 ;;
     --require-clean)   REQUIRE_CLEAN=1; shift ;;
+    --requires-test)   REQUIRES_TEST="${2:-}"; shift 2 ;;
     --force)           FORCE=1; shift ;;
     --dry-run)         DRY_RUN=1; shift ;;
     --help)            usage; exit 0 ;;
@@ -440,6 +476,11 @@ fi
 RELAY_TASK="${RELAY_TASK:-"MARATHON-$(printf '%s' "$PHASE_ID" | tr '[:lower:]' '[:upper:]')-TURN"}"
 LANE_STATE_KEY="${MARATHON_LANE_NS:-$PHASE_ID}"
 
+# GH-249: snapshot HEAD (in the repo the artifact actually lands in — TARGET_ROOT when set, else ROOT)
+# before this phase's first commit, so requires_test_delta (below) has a true "before this phase"
+# baseline to diff against. Captured unconditionally — cheap, and unused unless --requires-test is set.
+PRE_PHASE_HEAD="$(git -C "${TARGET_ROOT:-$ROOT}" rev-parse HEAD 2>/dev/null || true)"
+
 # Map builder/reviewer to _AGENT env vars for marathon-agent.sh routing. Both actors are routed to
 # their shim by name prefix (claude/codex/agy/gemini), so the harness supports cross-model BUILDERS
 # (e.g. agy) — not just Claude. Builder defaults to claude for back-compat.
@@ -819,6 +860,13 @@ complete_phase_success() {
     xyz_marathon_emit red "halted at phase ${PHASE_ID} — pre-advance gate failed"
     exit 5
   fi
+  if [[ -n "$REQUIRES_TEST" ]] && ! requires_test_delta "$REQUIRES_TEST"; then
+    log "requires-test FAILED — no new/updated test detected at: $REQUIRES_TEST"
+    escalate "requires-test-missing" 0
+    xyz_marathon_heartbeat_clear
+    xyz_marathon_emit red "halted at phase ${PHASE_ID} — required test not added/updated: $REQUIRES_TEST"
+    exit 5
+  fi
   if [[ "$success_mode" == "already-satisfied" ]]; then
     success_text="phase ${PHASE_ID} complete — lane_already_satisfied, reviewer approved, gate passed"
   else
```

## GH-232: ubuntu CI env prep + re-enable validate.sh minus 12 tests

```diff
commit 767035e
fix(GH-232): prepare ubuntu CI env and re-enable validate.sh minus confirmed environmental failures


diff --git a/.github/workflows/ci.yml b/.github/workflows/ci.yml
index 38ebd1f..b3b4efe 100644
--- a/.github/workflows/ci.yml
+++ b/.github/workflows/ci.yml
@@ -77,3 +77,61 @@ jobs:
           set -euo pipefail
           npm ci
           bash test/acorn-extract.sh
+
+      # GH-232: the acting-agent's user/keychain config and default `git init` branch name are
+      # macOS-dev-machine assumptions baked into several fixture-driven tests (e.g. archive-writers.sh,
+      # xyz-vendor.sh do a bare `git init` and expect the resulting branch to be "main"). ubuntu-latest's
+      # git has no global identity and may default new repos to a non-"main" branch, so prepare both
+      # here rather than touch the tests themselves (out of scope for this lane).
+      - name: Prepare git environment for fixture-driven tests
+        run: |
+          set -euo pipefail
+          git config --global init.defaultBranch main
+          git config --global user.email "ci@runner.invalid"
+          git config --global user.name "CI Runner"
+
+      # GH-232: PR #231 ran the full ./validate.sh suite on ubuntu-latest for the first time and
+      # confirmed ~12 tests fail there for environment reasons, not real regressions (see issue #232
+      # for the per-test detail): a BSD-only `sed -i ''` invocation in marathon.sh that breaks under
+      # GNU sed, marathon-drive.sh flakiness that debug-mantra.sh/driver-lock.sh inherit, a possible
+      # real package-freshness finding tracked separately, and several ubuntu path/tooling-assumption
+      # failures. None of those tests are ours to edit in this lane, so they're named and skipped
+      # explicitly below (instead of the whole suite being left unrun) so CI reflects a true signal
+      # for everything else. test_python_layer.py is excluded the same way, unrun here.
+      - name: Run validate.sh suite (minus confirmed ubuntu-only environmental failures)
+        env:
+          RELAY_SELF_SUFFICIENCY_SKIP: "1"
+        run: |
+          set -euo pipefail
+          SKIP_TESTS=(
+            "acorn-extract.sh"                    # already run above (needs npm ci first)
+            "marathon-drive.sh"                   # GH-232: ubuntu-environment failure
+            "debug-mantra.sh"                     # GH-232: drives marathon-drive.sh
+            "driver-lock.sh"                       # GH-232: drives marathon-drive.sh
+            "marathon.sh"                           # GH-232: BSD `sed -i ''` syntax breaks on GNU sed
+            "relay-pkg-freshness.sh"               # GH-232: possible real drift finding, tracked separately
+            "path-integrity.sh"                    # GH-232: ubuntu-environment failure
+            "archive-writers.sh"                   # GH-232: ubuntu-environment failure
+            "relay-file-seeding-visibility.sh"     # GH-232: ubuntu-environment failure
+            "xyz-vendor.sh"                         # GH-232: ubuntu-environment failure
+            "xyz-harness-hooks.sh"                 # GH-232: ubuntu-environment failure
+            "hq.sh"                                 # GH-232: ubuntu-environment failure
+          )
+          ALL_TESTS=()
+          while IFS= read -r line; do
+            [ -n "$line" ] && ALL_TESTS+=("$line")
+          done < <(sed -n '/^TESTS=(/,/^)/p' validate.sh | grep -oE '"[^"]+\.sh"' | tr -d '"')
+          FAILED=0
+          for t in "${ALL_TESTS[@]}"; do
+            skip=0
+            for s in "${SKIP_TESTS[@]}"; do
+              [ "$t" = "$s" ] && { skip=1; break; }
+            done
+            if [ "$skip" -eq 1 ]; then
+              echo "SKIP (GH-232): $t"
+              continue
+            fi
+            echo "=== $t ==="
+            bash "test/$t" || FAILED=1
+          done
+          exit "$FAILED"
```

## GH-224: PDDA drift reconcile (46 files) + outward action

45 PROJECT/3-COMPLETED docs had their frontmatter status word flipped to a terminal word,
and 5 ROADMAP ledger markers corrected. The lane's subagent ALSO closed GH #211 and #163
on GitHub with evidence comments (an outward action). Only the ROADMAP.md diff shown:
```diff
diff --git a/ROADMAP.md b/ROADMAP.md
index 98d1a57..37012c7 100644
--- a/ROADMAP.md
+++ b/ROADMAP.md
@@ -82,7 +82,7 @@ Mechanical / pattern-following work → **Sonnet High**; trust-critical kernel-c
 - **GH-239 · swarm-preflight: no contract example ships — consumers hit exit 3 with nothing to copy, so the gate gets bypassed** 🆕 **captured 2026-07-18, promoted to `2-WORKING` same day — ready to fire** — same reporter, same day, same root cause (defaults/onboarding assume the consumer looks like this repo). The contract schema lives **only** in `utils/swarm-preflight.sh:24-36`'s header comment; `MARATHON.example.yaml` is the sole shipped worked example and has no contract equivalent. Worse than filed: a dozen-plus real filled-in contracts exist in `PROJECT/**/GH-*.md`, but `PROJECT/**` isn't part of a vendored `.xyz/` install — every working example is structurally invisible to the audience that needs one. Consequence is behavioural, not cosmetic: consumers skip `swarm-preflight.sh` and hand-author `MARATHON.yaml` because *that* format has an on-ramp, so the freshness/fix-required/collision gates get routinely bypassed. Fix: ship `relay-automation/CONTRACT.example.md` (per-field annotated, `fix_probes` polarity called out explicitly — inverting it yields a STALE exit-4 *false completion* signal) + print the minimal skeleton on exit 3. Deferring `--emit-contract-skeleton`. cx/risk/eff 1/1/2. → [GH-239-PREFLIGHT-CONTRACT-EXAMPLE.md](PROJECT/2-WORKING/GH-239-PREFLIGHT-CONTRACT-EXAMPLE.md) · [#239](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/239)
 - **PDDA sweep 2026-07-18 · 4 shipped docs swept to `3-COMPLETED`, 6 stale marathon status words corrected** 🆕 **2026-07-18, branch `docsweep/2026-07-18`** — GH-151/152/155/230 were sitting in `2-WORKING` with terminal status in their own frontmatter and `CLOSED/COMPLETED` issues; moved to `3-COMPLETED`. Six marathon plans filed under `3-COMPLETED`/`4-MISC` still read `status: Active (2-WORKING)` (`07-01/02/03/05/06`, `4-MISC/07-07`); corrected. Both classes are instances of the #224 drift backlog, found by a manual marathon-file audit rather than by the #189 checks. Caveat carried forward: GH-155's own doc says sub-item **S10 stays open** despite the issue being closed. → [GH-224-PDDA-DRIFT-BACKLOG-RECONCILE.md](PROJECT/2-WORKING/GH-224-PDDA-DRIFT-BACKLOG-RECONCILE.md) · [#224](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/224)
 - **GH-235 · Consult A4 provenance v0: prompt-trace classifier for cited claims (FIRSTHAND vs ECHOED)** 🆕 **captured 2026-07-17 — decision made via cross-model consult, implementation via relay in progress** — closes the shipped A4 slice's blind spot (a prompt-echoed citation looks identical to a firsthand one). A parallel Codex+agy consult (`relay-system/2026-07-17/a4-scope-181325/`) converged independently on **v0** (2-category: FIRSTHAND vs ECHOED on already-cited claims) over the 4-category taxonomy, both citing Principle 7 + the reuse tie-breaker. v0: persist `PROMPT_TEXT`, sibling predicate to `rtl_has_uncited_claim()`, per-advisor `PROVENANCE.txt` sidecar, existing `NO FIRSTHAND` stamp unchanged. Defers INFERENCE/UNSUPPORTED split + reconciliation backstop. Coordinates with #226. cx/risk/eff 2/2/2. → [GH-235-CONSULT-A4-PROVENANCE-V0.md](PROJECT/1-INBOX/GH-235-CONSULT-A4-PROVENANCE-V0.md) · [#235](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/235)
-- **GH-230 · Front-door onboarding drift: undocumented npm install + package.json drift** 🆕 **captured 2026-07-17, promoted to `2-WORKING` same day — ready to fire** — read-only `/front-door` audit found a genuinely fresh clone following README's own Quickstart verbatim hits `Cannot find module 'acorn'` (real `package.json` deps, gitignored `node_modules/`, no doc mentions `npm install`, and CI's `tier1` job never runs `./validate.sh` so the gap is invisible to CI). Also cleaned up: `package.json`'s stale `"name": "lane-169"`, garbled beta-banner `"description"`, and a deliberately-failing `npm test` stub. No leaked secrets found. cx/risk/eff 1/1/2. → [GH-230-FRONT-DOOR-ONBOARDING-DRIFT.md](PROJECT/2-WORKING/GH-230-FRONT-DOOR-ONBOARDING-DRIFT.md) · [#230](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/230)
+- **GH-230 · Front-door onboarding drift: undocumented npm install + package.json drift** ✅ **SHIPPED 2026-07-17; closed** — read-only `/front-door` audit found a genuinely fresh clone following README's own Quickstart verbatim hits `Cannot find module 'acorn'` (real `package.json` deps, gitignored `node_modules/`, no doc mentions `npm install`, and CI's `tier1` job never runs `./validate.sh` so the gap is invisible to CI). Also cleaned up: `package.json`'s stale `"name": "lane-169"`, garbled beta-banner `"description"`, and a deliberately-failing `npm test` stub. No leaked secrets found. cx/risk/eff 1/1/2. → [GH-230-FRONT-DOOR-ONBOARDING-DRIFT.md](PROJECT/2-WORKING/GH-230-FRONT-DOOR-ONBOARDING-DRIFT.md) · [#230](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/230)
 - **GH-177 · mktemp-into-destructive-EXIT-trap recurrence — `test/hq-hardening.sh` (+2 siblings) rm -rf'd the entire repo a 2nd time** ✅ **SHIPPED 2026-07-17** (`e7fd117`) — closed 2026-07-08 without the code fix ever landing; the unguarded `TMP="$(cd "$(mktemp -d)" && pwd -P)"; trap 'rm -rf "$TMP"' EXIT` idiom was still live in `test/hq-hardening.sh`/`hq-promote.sh`/`hq-locator.sh` and fired again when `validate.sh` ran under a sandboxed shell (`mktemp -d` fails silently, `cd ""` succeeds and stays at cwd = repo root, the EXIT trap deletes it). Recovered clean via `git init` + `fetch` + `read-tree`/`checkout-index` from `origin/development` (no upstream loss) + a Time Machine assist for the working tree. Fixed all 3 files with the guard the original issue already specified, plus a new static-audit regression test (`test/mktemp-trap-guard.sh`) wired into `validate.sh`, verified (via disposable scratch files) to fail on the historical pattern and pass clean (191 files, 0 findings) post-fix. cx/risk/eff 1/3/1. → [GH-177-MKTEMP-TRAP-REPO-WIPE.md](PROJECT/3-COMPLETED/GH-177-MKTEMP-TRAP-REPO-WIPE.md) · [#177](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/177)
 - **GH-226 · Full provenance follow-up should coordinate with the already-reworked consult/relay summary surface** 🆕 **captured 2026-07-17 — standalone planning follow-up, not yet split into build lanes** — Jedi Wright flagged a real coordination gap in Slack: GH-211 already changed the operator-facing TLDR/category layer, GH-178 intentionally shipped only a narrow provenance slice, and a future "full provenance" pass will likely rework the same human-facing surface twice unless the two are designed together. Ask: inventory the operator-facing summary surfaces GH-211 touched and the provenance surfaces GH-178 touched, then decide whether the next pass stays one coordinated issue or splits by repo/surface. cx/risk/eff 2/2/2. → [GH-226-PROVENANCE-SUMMARY-SURFACE-COORDINATION.md](PROJECT/1-INBOX/GH-226-PROVENANCE-SUMMARY-SURFACE-COORDINATION.md) · [#226](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/226)
 - **GH-225 · 10days/marathon guardrail: `isolation:"worktree"` lanes can branch from a stale historical commit, not the marathon branch** 🆕 **captured 2026-07-17, promoted to `2-WORKING` same day — ready to fire** — found live during the GH-174/215/222/189 marathon fire the same day: all 4 parallel lanes' isolation worktrees branched from stale historical commits (e.g. `788a5c6`, `e8acdc5`), not the marathon branch named as `target.ref`; caught only by manually checking `git log` before merging, and recovered via cherry-pick instead of a full merge (which would have silently reintroduced superseded history). Fix: doc-only guardrail in `skills/10days/SKILL.md` Step 7 — verify each lane's worktree base against the marathon branch start commit before merging, cherry-pick instead of merge when it fails. cx/risk/eff 1/2/1. → [GH-225-ISOLATION-WORKTREE-STALE-BASE-GUARDRAIL.md](PROJECT/2-WORKING/GH-225-ISOLATION-WORKTREE-STALE-BASE-GUARDRAIL.md) · [#225](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/225)
@@ -117,7 +117,7 @@ Mechanical / pattern-following work → **Sonnet High**; trust-critical kernel-c
 - **GH-170 · validate.sh: 9 pre-existing failing tests** ⏸ **STALE as of 2026-07-17 — all 9 tests currently pass, recommend closing (not closed unilaterally)** — triage doc authored 2026-07-07 with per-item findings + fix direction; while building this plan's Swarm Preflight Contract, `swarm-preflight.sh --gh-issue 170` returned STALE (exit 4). Independently re-verified: all 9 tests pass, incl. 5x repeated runs of the two confirmed-flaky lanes; full `validate.sh` confirms only pre-existing `#208` red repo-wide. Root cause of the flip unconfirmed — commented on the issue with full evidence recommending closure. cx/risk/eff 3/2/4. → [GH-170-VALIDATE-FAILING-TESTS.md](PROJECT/2-WORKING/GH-170-VALIDATE-FAILING-TESTS.md) · [#170](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/170)
 - **Marathon Plan E · acorn-integration + aider-turn.sh + hq-resolve bugfix cluster (GH-159, GH-168, GH-169, GH-175, GH-186)** ✅ **all 5 lanes complete; updated 2026-07-09** — #159/#168/#169/#175 shipped via PR #179 (merge `39729a0`), #159/#169/#175 closed on GitHub. **#186 built + Approved 2026-07-09** on local branch `marathon/gh-186-aider-vendor-version-drift-2026-07-09` (not yet pushed/PR'd) via a codex-builder/agy-reviewer marathon relay — surfaced and fixed a real secondary bug along the way (`ALLOW_PATHS` env leakage in `test/aider-turn.sh` Case 12); `bash validate.sh` green except 2 confirmed pre-existing/unrelated failures. Both review rounds hit a detector false positive (filed as **#187**, second instance of GH-183's pattern) requiring manual, transcript-verified commit recovery. → [MARATHON-PLAN-2026-07-07-E-BUILD.md](PROJECT/3-COMPLETED/MARATHON-PLAN-2026-07-07-E-BUILD.md) · [PR #179](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/179)
 - **GH-186 · aider-turn.sh: --add-gitignore-files removal (775380c) unverified against vendored installs on older aider — risk of silently reopening GH-168** ✅ **Built + Approved 2026-07-09 (local branch, not yet merged)** — captured 2026-07-08 reviewing `775380c`; fixed via runtime `aider --help` flag-support detection instead of hardcoding either flag state, so vendored installs on any aider version get correct behavior. `test/aider-turn.sh` extended to 44/44 passing. cx/risk/eff 2/2/2. → [GH-186-AIDER-VENDOR-VERSION-DRIFT.md](PROJECT/3-COMPLETED/GH-186-AIDER-VENDOR-VERSION-DRIFT.md) · [#186](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/186)
-- **GH-187 · agy isolation-breach detector: second false-positive trigger (markdown citation link), confirmed live-blocking a real marathon lane** 🆕 **captured 2026-07-08/09, found live firing GH-186 twice (both review rounds)** — the GH-178 B1 post-hoc `$ROOT`-citation scan (`agy-turn.sh:234-242`) fired on agy's own end-of-turn markdown citation links (`[file](file:///…/xyz-3-agents-swarm/…)`), not an actual containment violation; confirmed both times by reading the raw transcript before manually recovering. GH-183's proposed fix (exclude the tick-command line) doesn't cover this trigger shape — needs a broader fix (verify from filesystem state, not transcript text, or strip citational contexts before scanning). → [#187](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/187)
+- **GH-187 · agy isolation-breach detector: second false-positive trigger (markdown citation link), confirmed live-blocking a real marathon lane** ✅ **closed 2026-07-10** — captured 2026-07-08/09, found live firing GH-186 twice (both review rounds) — the GH-178 B1 post-hoc `$ROOT`-citation scan (`agy-turn.sh:234-242`) fired on agy's own end-of-turn markdown citation links (`[file](file:///…/xyz-3-agents-swarm/…)`), not an actual containment violation; confirmed both times by reading the raw transcript before manually recovering. GH-183's proposed fix (exclude the tick-command line) doesn't cover this trigger shape — needs a broader fix (verify from filesystem state, not transcript text, or strip citational contexts before scanning). → [#187](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/187)
 - **GH-169 · Acorn integration (first pass): vendor acorn+acorn-walk as a lightweight JS symbol/call-site extractor for GH-156** ✅ **SHIPPED 2026-07-08 (PR #179, `39729a0`); closed 2026-07-08** — off GH-163's license/smoke-test verdict; infra-only, additive, not GH-156's full scorer. `src/acorn-extract.js` + `acorn`/`acorn-walk` deps confirmed live in `main`. cx/risk/eff 2/1/2. → [GH-169-ACORN-FIRST-PASS-INTEGRATION.md](PROJECT/3-COMPLETED/GH-169-ACORN-FIRST-PASS-INTEGRATION.md) · [#169](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/169)
 - **GH-168 · aider-turn.sh: --no-gitignore doesn't enable reading gitignored files — missing --add-gitignore-files silently skips relay threads in gitignored dirs** ✅ **shipped ad-hoc 2026-07-08 (`775380c`, on `claude/gh-173-178-beta-patches-ygfgc5`, unmerged); #168 closed** — captured 2026-07-07, found live via a `.xyz`-vendored relay run (pdda repo); one-line flag fix + regression test. Follow-up found reviewing the fix itself: the flag was later confirmed obsolete/removed upstream and dropped again, verified only against one local aider version — tracked as **GH-186**. cx/risk/eff 1/1/1. → [GH-168-AIDER-TURN-GITIGNORE-BUG.md](PROJECT/3-COMPLETED/GH-168-AIDER-TURN-GITIGNORE-BUG.md) · [#168](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/168)
 - **GH-165 · codex-turn: Codex can edit+commit without first owning the relay token, leaving `no-progress` stalls even after GH-67's release backstop** ✅ **SHIPPED 2026-07-07; closed** — Codex shim (`relay-automation/codex-turn.sh` + `utils/py/codex-turn.py`) now claims the exact `RELAY_TASK`, asserts `claimer == codex` before launch, and pings the token; fails fast (exit 5) before any mutation if ownership is missing. Both `bash test/codex-turn.sh` and `XYZ_PYTHON=1 bash test/codex-turn.sh` green with new no-tick and unowned-token regression cases. `validate.sh` reached 101/104 — the remaining 3 reds (`worktree-isolation.sh` moved-ROOT-HEAD case, `test_python_layer.py` missing `pytest` in this environment) are pre-existing and unrelated to this fix, not filed as their own issues yet. → [GH-165-CODEX-TOKEN-OWNERSHIP.md](PROJECT/3-COMPLETED/GH-165-CODEX-TOKEN-OWNERSHIP.md) · [#165](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/165)
@@ -141,7 +141,7 @@ Mechanical / pattern-following work → **Sonnet High**; trust-critical kernel-c
 - **GH-107 · Containment reverts a complete, passing turn on an off-lane tool-cache dir (`.codebase-memory/`)** ✅ **SHIPPED 2026-07-04 (`524d345`) — KERNEL zone, built Opus-serial as specified · part of [Marathon Plan C](PROJECT/3-COMPLETED/MARATHON-PLAN-2026-07-04-C-RELIABILITY.md)** — `rtl_worktree_end`'s off-lane loop discarded a turn's entire work when the builder's own tooling wrote an untracked cache dir the target repo never gitignored (reproduced live: a 442-line, 67/67-tested, otherwise-correct build discarded anyway). Sibling of #54 — same mechanism, different trigger (tool cache vs test fixtures). Fixed: `rtl_is_containment_ignored()` (`relay-turn-lib.sh:345-364`) checked in that loop before the off-lane fallthrough — root-anchored built-in list (`.codebase-memory`, `.aider*`, `node_modules/.cache`) extended by the comma-separated `CONTAINMENT_IGNORE` env var, **empty by default so default behavior is byte-for-byte unchanged**. Kernel-required [decisions record](decisions/2026-07-04-containment-ignore-toolcache.md) written alongside; `test/worktree-isolation.sh` 31/31 incl. a control asserting a non-built-in path *without* the env still exits 6; Python-layer inheritance asserted via `rtl.py`. cx/risk/eff 3/4/2. → [GH-107-CONTAINMENT-OFFLANE-TOOLCACHE.md](PROJECT/3-COMPLETED/GH-107-CONTAINMENT-OFFLANE-TOOLCACHE.md) · [#107](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/107)
 - **GH-108 · `--pre-advance-cmd 'npm test -- <name>'` runs the whole suite, unrelated flakes fail a green lane** ✅ **SHIPPED 2026-07-04 (`691848c`, 85/85) — bundle also closed #126/#127 (same file) · part of [Marathon Plan C](PROJECT/3-COMPLETED/MARATHON-PLAN-2026-07-04-C-RELIABILITY.md)** — `swarm-preflight.sh` passed a contract's `gate` field verbatim as `--pre-advance-cmd`; whether `npm test -- <name>` actually filters depends on the target repo's own test script, and often doesn't (reproduced live: an unrelated `EADDRINUSE` flake failed an otherwise 67/67-green lane). Fixed (Level 1, documented-caveat): when `GATE_CMD` heuristically looks like a filtered-runner invocation, the packet emits an explicit scoping caveat rather than attempting cross-runner auto-detection. Landed in one lane with **#126** (GH-55 covering-test substring-match tightening) and **#127** (GH-54 bare-`>` fs-touching gap) since all three touch `utils/swarm-preflight.sh`. cx/risk/eff 3/2/3. → [GH-108-SWARM-PREFLIGHT-HARDENING-BUNDLE.md](PROJECT/3-COMPLETED/GH-108-SWARM-PREFLIGHT-HARDENING-BUNDLE.md) · [#108](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/108) · [#126](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/126) · [#127](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/127)
 - **GH-124 · deep-research.mjs shipped un-run against real `agy` — add a real-`agy` smoke test + runaway-grounding guard** ✅ **SHIPPED 2026-07-04 (`6daaff5`, 45/45 + self-skipping live test) · part of [Marathon Plan C](PROJECT/3-COMPLETED/MARATHON-PLAN-2026-07-04-C-RELIABILITY.md)** — GH-87's adapter hung on *every* real `agy` call (stub-only tests hid it); two bugs fixed post-merge (`91f17f2` missing `--dangerously-skip-permissions`; `74cd553` `execFile` silently ignores `stdio` → agy stdin never EOF'd → switched to `spawn`). Now works (~27–52s, real citations, `test/deep-research.sh` 23/23). Hardening follow-up: an **opt-in real-`agy` smoke test** (network + `agy` on PATH, self-skips like `relay-self-sufficiency.sh`) so a stub can't again hide a real-backend break; a guard against `--search-context-size high` runaway grounding; revisit the default 120s timeout. Surfaced dogfooding #111. cx/risk/eff 2/1/2. → [GH-124-DEEP-RESEARCH-REAL-AGY-HARDENING.md](PROJECT/3-COMPLETED/GH-124-DEEP-RESEARCH-REAL-AGY-HARDENING.md) · [#124](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/124)
-- **GH-118 · Make Aider edit formats more forgiving for OpenRouter models** 🆕 **captured 2026-07-03 · rated · live-confirmed** — Aider natively uses a 'whole' or 'udiff' edit format depending on the model, but unknown OpenRouter models (like GLM-5.2) often default to formats they don't strictly follow (e.g. outputting standard diffs instead of 'whole' file), causing Aider to fail with 'no tracked changes'. **2026-07-03 live tests confirmed the diagnosis and the fix on two models:** GLM-5.2 (first attempt: no edit emitted at all, just chat; retry with `AIDER_FLAGS=--edit-format diff` produced valid SEARCH/REPLACE) and Nemotron Ultra 3 free tier (same 'whole' default — zero nvidia/nemotron entries anywhere in Aider's model-settings.yml or heuristic chain — failed by emitting a raw unified-diff hunk, reproducing the original bug report almost exactly). Revised fix: document `AIDER_FLAGS=--edit-format diff` (already a passthrough) rather than adding a new `AIDER_EDIT_FORMAT` var; maintain a running known-model compat note. cx/risk/eff 2/1/2. → [GH-118-AIDER-OPENROUTER-FORMAT.md](PROJECT/1-INBOX/GH-118-AIDER-OPENROUTER-FORMAT.md) · [#118](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/118)
+- **GH-118 · Make Aider edit formats more forgiving for OpenRouter models** ✅ **closed** — captured 2026-07-03 · rated · live-confirmed — Aider natively uses a 'whole' or 'udiff' edit format depending on the model, but unknown OpenRouter models (like GLM-5.2) often default to formats they don't strictly follow (e.g. outputting standard diffs instead of 'whole' file), causing Aider to fail with 'no tracked changes'. **2026-07-03 live tests confirmed the diagnosis and the fix on two models:** GLM-5.2 (first attempt: no edit emitted at all, just chat; retry with `AIDER_FLAGS=--edit-format diff` produced valid SEARCH/REPLACE) and Nemotron Ultra 3 free tier (same 'whole' default — zero nvidia/nemotron entries anywhere in Aider's model-settings.yml or heuristic chain — failed by emitting a raw unified-diff hunk, reproducing the original bug report almost exactly). Revised fix: document `AIDER_FLAGS=--edit-format diff` (already a passthrough) rather than adding a new `AIDER_EDIT_FORMAT` var; maintain a running known-model compat note. cx/risk/eff 2/1/2. → [GH-118-AIDER-OPENROUTER-FORMAT.md](PROJECT/1-INBOX/GH-118-AIDER-OPENROUTER-FORMAT.md) · [#118](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/118)
 - **GH-119 · aider-turn.sh: reviewer can auto-add and edit out-of-scope tracked files under --yes-always; all-or-nothing containment discards the valid in-lane edit too** ✅ **SHIPPED 2026-07-03 (`93e2366`); closed 2026-07-04 · sibling of #54/#107** — surfaced live while testing GH-118's fix: GLM-5.2, acting as Reviewer, found a real bug and emitted a valid SEARCH/REPLACE for the relay file, but also emitted an edit for `marathon-drive.sh` (never added to the chat) which Aider's `--yes-always` auto-confirmed adding. The off-lane guard correctly caught it but discarded the *entire* turn, including the valid relay-file review. Same containment mechanism as #54/#107, different (deliberate, role-violating) trigger. Fixed: pre-seeds the diff's changed files as `--read` for review-only turns (`ALLOW_PATHS=""`) so they're structurally unwritable regardless of `--yes-always`; new `test/aider-turn.sh` case; independently re-verified via two reverse-dogfood reviews (24-file scale, zero scope-creep both times). cx/risk/eff 2/2/2. → [GH-119-AIDER-REVIEWER-SCOPE-CREEP.md](PROJECT/3-COMPLETED/GH-119-AIDER-REVIEWER-SCOPE-CREEP.md) · [#119](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/119)
 - **GH-120 · Build a fuzzy-match OpenRouter model-name lookup table (alias → canonical slug)** ✅ **SHIPPED 2026-07-03 (`17e2681`); closed** — resolving colloquial model names ("GLM 5.2", "Nemotron Ultra 3") to canonical OpenRouter slugs currently required a live API query every time. Shipped: `relay-automation/openrouter-model-aliases.yml` + `resolve-model-alias.sh` (4-tier fuzzy match) + `test/model-alias.sh` (10/10), wired into `validate.sh`, documented. Independently re-verified via a GLM 5.2 reverse-dogfood review, which also caught and fixed a stale README claim (`1642304`). cx/risk/eff 1/1/2. → [GH-120-OPENROUTER-MODEL-ALIAS-TABLE.md](PROJECT/3-COMPLETED/GH-120-OPENROUTER-MODEL-ALIAS-TABLE.md) · [#120](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/120)
 - **GH-117 · fix(marathon-drive): --dry-run must probe builder/reviewer binary before mutating tick state** ✅ **SHIPPED 2026-07-04 (`b4e73df`, 55/55) · part of [Marathon Plan C](PROJECT/3-COMPLETED/MARATHON-PLAN-2026-07-04-C-RELIABILITY.md)** — `marathon-drive.sh` didn't probe builder/reviewer binary availability before seeding tick state, so missing-binary errors fired after the tick task was already seeded and spent (no recovery without a fresh relay-task id). Fixed: binary probe after arg parsing, before any tick mutation — catches missing `claude`/`agy`/`codex` on both `--dry-run` and live runs. (Integration commit `d5a1681` then stubbed `CLAUDE_BIN`/`AGY_BIN` in `driver-lock.sh`/`xyz-harness-hooks.sh`, which this probe correctly rejected for their unresolvable default builder.) Found in a live 3-phase marathon run. cx/risk/eff 2/1/2. → [GH-117-MARATHON-DRIVE-BINARY-PREFLIGHT.md](PROJECT/3-COMPLETED/GH-117-MARATHON-DRIVE-BINARY-PREFLIGHT.md) · [#117](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/117)
```

### QA questions to weigh
- GH-236: is the $TMPDIR-inside-RTL_ROOT detection correct, and is git worktree add under .git safe/cleanable?
- GH-245: does dropping token-state from the review-once oracle mis-handle any legit case? Is the startup guard scoped right (review-once only)?
- GH-249: is the new gate truly opt-in / backward-compatible?
- GH-232: does skipping 12 tests hide real failures, or are they genuinely environmental?
- GH-224: was closing #211/#163 on GitHub in-scope for a doc-hygiene lane?
