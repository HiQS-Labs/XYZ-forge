# RELAY · Review: GH-307 pre-advance gate env scrub
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-26.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(review-gh307-gate-scrub): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **gh307-review.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-26

### Artifact — gh307-review.md
````
# GH-307 fix under review — pre-advance gate must not inherit run-identity tags

## Diff (tracked files)
```diff
diff --git a/relay-automation/marathon-drive.sh b/relay-automation/marathon-drive.sh
index e610c48..b0aad56 100755
--- a/relay-automation/marathon-drive.sh
+++ b/relay-automation/marathon-drive.sh
@@ -339,6 +339,16 @@ run_pre_advance_gate() {
     if [[ -n "$TARGET_ROOT" ]]; then
       cd "$TARGET_ROOT"
     fi
+    # GH-307: the gate is a correctness check on the REPO — not part of this run's provenance,
+    # and it must not be able to see who is driving it. These tags otherwise leak into the gate
+    # via this subshell and break tests that legitimately assert on them
+    # (test/xyz-harness-hooks.sh reads XYZ_HARNESS_CONTEXT / XYZ_SESSION_ID; test/debug-mantra.sh
+    # reads MARATHON_LANE_NS), which made `bash validate.sh` — the DOCUMENTED DEFAULT GATE —
+    # impossible to pass inside a marathon. Keep this list identical to GATE_SCRUBBED_ENV in
+    # utils/py/marathon_drive.py; the Python twin is what runs by default (XYZ_PYTHON-1).
+    # Deliberately narrow: run-identity tags only, never repo/config inputs like MARATHON_ROOT,
+    # TICK_BIN or TICK_REPO_ROOT, which a gate may legitimately need.
+    unset XYZ_HARNESS_CONTEXT XYZ_SESSION_ID MARATHON_LANE_NS
     eval "$PRE_ADVANCE_CMD"
   )
 }
diff --git a/utils/py/marathon_drive.py b/utils/py/marathon_drive.py
index 7a7cc9d..da54928 100644
--- a/utils/py/marathon_drive.py
+++ b/utils/py/marathon_drive.py
@@ -461,9 +461,27 @@ relay-file: {rel_relay}
             log(f"transcript saved: {dest}")
         return True
 
+    # GH-307: the gate is a correctness check on the REPO — it is not part of this run's
+    # provenance, and it must not be able to see who is driving it. These tags otherwise leak
+    # into the gate subprocess and break tests that legitimately assert on them
+    # (test/xyz-harness-hooks.sh reads XYZ_HARNESS_CONTEXT / XYZ_SESSION_ID;
+    # test/debug-mantra.sh reads MARATHON_LANE_NS), which made `bash validate.sh` — the
+    # DOCUMENTED DEFAULT GATE — impossible to pass inside a marathon: every phase 1 escalated
+    # with reason `pre-advance-failed` while its own change was correct and approved.
+    # Scrubbing is deliberately narrow: only the run-identity tags, never repo/config inputs
+    # like MARATHON_ROOT, TICK_BIN or TICK_REPO_ROOT, which a gate may legitimately need.
+    GATE_SCRUBBED_ENV = ("XYZ_HARNESS_CONTEXT", "XYZ_SESSION_ID", "MARATHON_LANE_NS")
+
+    def _gate_env():
+        env = os.environ.copy()
+        for var in GATE_SCRUBBED_ENV:
+            env.pop(var, None)
+        return env
+
     def run_pre_advance_gate():
         cwd = args.target_root if args.target_root else None
-        return subprocess.run(pre_advance_cmd, shell=True, executable="/bin/bash", cwd=cwd).returncode
+        return subprocess.run(pre_advance_cmd, shell=True, executable="/bin/bash",
+                              cwd=cwd, env=_gate_env()).returncode
 
     def run_post_approve_cmd():
         cwd = args.target_root if args.target_root else None
diff --git a/validate.sh b/validate.sh
index f51dd63..f573925 100755
--- a/validate.sh
+++ b/validate.sh
@@ -48,6 +48,7 @@ TESTS=(
   "shim-worktree.sh"
   "marathon-yaml.sh"
   "marathon-drive.sh"
+  "gh307-gate-env-scrub.sh"      # GH-307 (pre-advance gate must not inherit run-identity tags)
   "hq-marathon-live.sh"          # GH-218 (cross-repo live marathon status)
   "debug-mantra.sh"              # GH-162 (debug-mantra auto-trigger note on a phase's prior attempt)
   "lane-attempt-cap.sh"
```

## New test: test/gh307-gate-env-scrub.sh (source/parity guard)
```bash
#!/usr/bin/env bash
# test/gh307-gate-env-scrub.sh — GH-307: the pre-advance gate must not inherit the run's
# identity tags.
#
# marathon.sh drives each phase with XYZ_HARNESS_CONTEXT=marathon-phase and MARATHON_LANE_NS
# set, and the packet-generated invocation adds XYZ_SESSION_ID. The gate ran as a plain
# subshell/subprocess, so it inherited all three. test/xyz-harness-hooks.sh asserts on
# XYZ_HARNESS_CONTEXT / XYZ_SESSION_ID and test/debug-mantra.sh asserts on MARATHON_LANE_NS,
# so `bash validate.sh` — the documented default gate — could never pass inside a marathon:
# phase 1 escalated `pre-advance-failed` with a correct, approved change.
#
# Asserts BOTH twins scrub the same three variables and leave repo/config inputs alone.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
pass=0; fail=0
ok()   { echo "  PASS: $1"; pass=$((pass+1)); }
bad()  { echo "  FAIL: $1"; fail=$((fail+1)); }

echo "== test: gh307-gate-env-scrub =="

# The three tags must be scrubbed; the repo/config inputs must NOT be.
SCRUB=(XYZ_HARNESS_CONTEXT XYZ_SESSION_ID MARATHON_LANE_NS)
KEEP=(MARATHON_ROOT TICK_BIN TICK_REPO_ROOT)

for v in "${SCRUB[@]}"; do
  grep -q "unset .*$v" "$ROOT/relay-automation/marathon-drive.sh" \
    && ok "bash twin scrubs $v" || bad "bash twin does not scrub $v"
  grep -q "\"$v\"" "$ROOT/utils/py/marathon_drive.py" \
    && ok "python twin scrubs $v" || bad "python twin does not scrub $v"
done

# Parity: both twins scrub the SAME set — a one-sided fix is the drift class GH-278 exists for.
for v in "${KEEP[@]}"; do
  grep -q "unset .*$v" "$ROOT/relay-automation/marathon-drive.sh" \
    && bad "bash twin wrongly scrubs $v (gate may need it)" || ok "bash twin preserves $v"
done

# Behavioural check: the real failing tests must pass under a reconstructed marathon env
# once the tags are removed — this is the property the fix exists to guarantee.
if env XYZ_HARNESS_CONTEXT=marathon-phase MARATHON_LANE_NS=lane-x XYZ_SESSION_ID=sid-x \
     sh -c 'env -u XYZ_HARNESS_CONTEXT -u MARATHON_LANE_NS -u XYZ_SESSION_ID \
            bash "'"$ROOT"'/test/xyz-harness-hooks.sh"' >/dev/null 2>&1; then
  ok "xyz-harness-hooks passes once the tags are scrubbed"
else
  bad "xyz-harness-hooks still fails with the tags scrubbed"
fi

# Control: with the tags PRESENT it must fail — otherwise this test proves nothing.
if env XYZ_HARNESS_CONTEXT=marathon-phase bash "$ROOT/test/xyz-harness-hooks.sh" >/dev/null 2>&1; then
  bad "control: xyz-harness-hooks passed WITH the tag set — repro no longer valid, retire this test"
else
  ok "control: xyz-harness-hooks fails with the tag set (repro still valid)"
fi

echo "  gh307-gate-env-scrub: $pass pass, $fail fail"
[[ "$fail" -eq 0 ]]
```

## New behavioural case added to test/marathon-drive.sh (section 5b)
```bash
# ── (5b) GH-307: the gate must NOT inherit the run's identity tags ───────
# The gate is a correctness check on the repo, not part of the run's provenance. When these
# leaked in, test/xyz-harness-hooks.sh (reads XYZ_HARNESS_CONTEXT / XYZ_SESSION_ID) and
# test/debug-mantra.sh (reads MARATHON_LANE_NS) failed inside every marathon, so `bash
# validate.sh` — the documented default gate — always escalated phase 1 with a correct,
# approved change. Behavioural: the gate itself reports what it can see.
GATE_ENV_OUT="$WORK/gate-env-seen.txt"
GATE_ENV_CMD="$WORK/gate-report-env.sh"
cat > "$GATE_ENV_CMD" <<'GATEEOF'
#!/usr/bin/env bash
{
  printf 'XYZ_HARNESS_CONTEXT=%s\n' "${XYZ_HARNESS_CONTEXT-<unset>}"
  printf 'XYZ_SESSION_ID=%s\n'      "${XYZ_SESSION_ID-<unset>}"
  printf 'MARATHON_LANE_NS=%s\n'    "${MARATHON_LANE_NS-<unset>}"
  printf 'MARATHON_ROOT=%s\n'       "${MARATHON_ROOT-<unset>}"
  printf 'TICK_REPO_ROOT=%s\n'      "${TICK_REPO_ROOT-<unset>}"
} > "$GATE_ENV_OUT_PATH"
exit 0
GATEEOF
chmod +x "$GATE_ENV_CMD"

GATE_ENV_OUT_PATH="$GATE_ENV_OUT" \
XYZ_HARNESS_CONTEXT=marathon-phase XYZ_SESSION_ID=sid-gh307 MARATHON_LANE_NS=lane-gh307 \
RELAY_DRIVE_EXIT=0 run_driver --pre-advance-cmd "bash $GATE_ENV_CMD" >/dev/null 2>&1 || true

if [ -f "$GATE_ENV_OUT" ]; then
  for v in XYZ_HARNESS_CONTEXT XYZ_SESSION_ID MARATHON_LANE_NS; do
    grep -q "^$v=<unset>$" "$GATE_ENV_OUT" \
      && pass "GH-307: gate cannot see $v" \
      || fail "GH-307: gate inherited $v ($(grep "^$v=" "$GATE_ENV_OUT"))"
  done
  # Narrowness: repo/config inputs a gate may legitimately need must survive the scrub.
  grep -q "^MARATHON_ROOT=<unset>$" "$GATE_ENV_OUT" \
    && fail "GH-307: scrub was too broad — MARATHON_ROOT was removed" \
    || pass "GH-307: scrub is narrow — MARATHON_ROOT preserved"
else
  fail "GH-307: gate never ran (no env report written)"
fi
rm -f "$GATE_ENV_OUT"
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

### Reviewer · codex · Round 1

- [Should] The Definition of Done is still the placeholder `_&lt;fill in the acceptance criteria the Reviewer grades against&gt;_`, so this review has no agreed, durable acceptance contract. Concrete fix: replace it with criteria requiring both twins to remove exactly `XYZ_HARNESS_CONTEXT`, `XYZ_SESSION_ID`, and `MARATHON_LANE_NS` only from the pre-advance gate environment; preserve repo/config inputs; exercise both runtime paths; and register an executable focused test in `validate.sh`. Citation: `gh307-review.md` embedded Definition of Done: `_<fill in the acceptance criteria the Reviewer grades against>_`.
- [Should] The focused source/parity guard does not prove Python-side narrowness or that the Python gate receives `_gate_env()`: its Python assertion is only `grep -q "\"$v\""`, which succeeds if a tag is mentioned in a comment or unused tuple, while the `KEEP` loop checks only `relay-automation/marathon-drive.sh`. Concrete fix: add structural assertions that `GATE_SCRUBBED_ENV` contains exactly the three scrubbed names, that `subprocess.run(... env=_gate_env())` is used by the pre-advance gate, and that none of `KEEP` appears in the Python scrub set. Citation: `test/gh307-gate-env-scrub.sh` embedded excerpts: `grep -q "\"$v\"" "$ROOT/utils/py/marathon_drive.py"` and `for v in "${KEEP[@]}"; do` followed only by the Bash-twin grep.
- [Should] The behavioural marathon-driver case records `TICK_REPO_ROOT` but never asserts it survived, despite the stated narrowness requirement naming it as an input a gate may need. Concrete fix: assert a non-`&lt;unset&gt;` `^TICK_REPO_ROOT=` line (and seed it explicitly in the invocation if the test harness does not guarantee it), alongside the existing `MARATHON_ROOT` preservation assertion. Citation: `test/marathon-drive.sh` embedded excerpts: `printf 'TICK_REPO_ROOT=%s\\n'` and the only preservation check, `grep -q "^MARATHON_ROOT=<unset>$"`.

Verdict: Changes requested

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
