# ESCALATION — Marathon Phase p1

phase: p1
task: MARATHON-P1-TURN
relay-drive-exit: 6
reason: containment-violation (off-lane edit reverted by a turn-taker)
gate: not-run
relay-file: marathon-system/gh648-headless-turn-timeout--p1/RELAY.md

turn-log: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/relay-system/logs/2026-09-16/codex-turn-MARATHON-P1-TURN-62647.log

<details>
<summary>Last 40 lines of failing turn log</summary>

```text
+    ) -> dict[str, object]:
+        """Classify this observation and package it for the run log."""
+        reason, detail = self.classify()
+        return termination_record(
+            termination, reason, detail,
+            exit_code=exit_code, observed_at=observed_at,
+        )
+
+    def emit_termination_record(
+        self,
+        termination: str,
+        *,
+        exit_code: int = 7,
+        observed_at: float | None = None,
+        stream: TextIO | None = None,
+    ) -> dict[str, object]:
+        """Classify and emit this observation as one structured log line."""
+        reason, detail = self.classify()
+        return emit_termination_record(
+            termination, reason, detail,
+            exit_code=exit_code, observed_at=observed_at, stream=stream,
         )
diff --git a/validate.sh b/validate.sh
index 613266c988eb227bb6adf510acf2851df315d7fc..0c717ac9d6884e0b63f22291c8f9366b24020861
--- a/validate.sh
+++ b/validate.sh
@@ -296,6 +296,7 @@
   "gh142-ate-exit-contract.sh"   # #142 (ATE filing exit contract: 0 filed/dry-run · 3 no-records · 1 gh-failed, propagated through run_variations; hermetic stub gh; also #141 Phase 4's three outcomes + dedup seen-Nx)
   "gh148-deepseek-turn.sh"       # #148 + #399 (DeepSeek shim: turn safety core, provider routing table, key-file fallback, 30/30 assertions)
   "gh608-deepseek-effort.sh"     # GH-608 (DEEPSEEK_REASONING_EFFORT matrix, early claim prevention, telemetry normalization)
+  "gh648-l1-turn-termination.sh" # GH-648 L1 (honest idle attribution + structured termination records)
   "gh156-turn-shims-help.sh"     # #156 (All 7 turn shims cleanly handle --help and -h before requiring RELAY_AGENT, 14/14 assertions)
   "gh155-phase1-metamorphic-invariants.sh" # #155 Phase 1 (Metamorphic Invariant Assertions & Sandbox Hardening: zero-mutation, idempotence, realpath containment)
   "gh155-phase2-differential-oracle.sh" # #155 Phase 2 (Differential Multi-Harness Cross-Testing Oracle across all 7 turn shims)

tokens used
58,222
Implemented GH-648 L1 and verified the focused suite: `PASS: 22 assertions`, including a witnessed failing mutation control. Full gate was intentionally not run.

Token released successfully. Handing off to agy — agy, take your turn.
```
</details>
