# RELAY · GH-1196 final QA: task-sync pins active Claude Desktop sessions
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-24.
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
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
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
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1196-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/3-weekly/task-sync/scripts/adapters/claude.py` (`ClaudeDesktopAdapter.sweep` and its docstring), `skills/3-weekly/task-sync/SKILL.md` ("Claude Desktop (GH-1191)" section: pin paragraph and procedure step 6), `CHANGELOG.md` (top entry).
- Evidence directory TESTS-RESULTS/2026-10-24+GH-1196/ holds probes.py, probes.log, probe-results.json, gh1191-probes.log, red-control.log, live-smoke.md and provenance.jsonl. Approved plan: PROJECT/2-WORKING/GH-1196-TASK-SYNC-DESKTOP-PINS.md; plan QA thread relay-system/2026-10-24/gh1196-plan-qa.md (round 4 operator-authorized; its one wording fix was applied after the round and is in scope here).
- The diff for the code/docs paths is embedded below (review turns cannot run git); read the full files too.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-24
- Operational envelope: a local, single-operator CLI planner that only proposes renames and pins; the app's `set_session_title` and `set_pinned` are the only writers, driven by an agent following SKILL.md. Grade against the approved plan and commensurate complexity. XYZ-forge forbids new `test/` suites, `validate.sh` TESTS entries or gate machinery (AGENTS.md, GH-831): a new one in the diff is a finding, and do not ask for one. Gate routed by `utils/ci-route.sh pull_request` as `tier=1 docs-only`; `utils/pdda/pdda.sh run` exit 0, 0 errors.
- Change beyond the plan, found in the live smoke: 3 of 4 live pin proposals were the device's own hourly scheduled-task runs. `list_sessions` rows don't carry `scheduledTaskId`; `get_session` does. SKILL step 6 now skips sessions with a `scheduledTaskId`. Judge whether that rule is sound and sufficient, and whether it belongs in the procedure rather than the planner.
- Definition of Done:
  1. R1–R3 of the plan's Scope table are met by the code, SKILL section and receipts.
  2. Codepaths match the approved plan (steps 1–4); no second writer, CLI change or report-shape change; title behaviour unchanged.
  3. The probes and red control substantiate the claims; live-smoke.md states truthfully what was and wasn't witnessed.
  4. The persisted rating `rated 55/20/50/85` still matches the evidence.

Questions:
1. Does `sweep` implement plan step 1 exactly (literal-`false` `isArchived`, literal-boolean `isRunning`, self skip, running rows with bad activity skipped, idle rows with bad activity abort, pin rule, title rules unchanged)? Cite lines.
2. Is SKILL step 6 complete against plan step 2 (fresh `list_sessions` recheck, `pinned: true` skip, decline = skip, receipt, no automatic undo, never unpin) plus the scheduled-run skip?
3. Do the 11 probes each fail when their behaviour breaks, and does red-control.log show the pinned check is load-bearing?
4. Any defect, over-engineering or missing piece? Cite file:line.

<details><summary>Embedded diff (origin/development...HEAD, task-sync + CHANGELOG)</summary>

````diff
diff --git a/CHANGELOG.md b/CHANGELOG.md
index f1e80714..ecd7784e 100644
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -1,5 +1,19 @@
 # Changelog
 
+## 2026-10-24 — task-sync: pin active Claude Desktop sessions (GH-1196)
+
+`--ide claude-desktop` now also proposes pins: a non-archived, non-self session with a literal
+boolean `isRunning`, `pinned` missing or `false`, and activity inside `--pin-hours` (default 24).
+A running session can be pinned; `--no-pin` turns pins off. The planner still never writes. The
+new step in `SKILL.md` rechecks with a fresh `list_sessions`, then calls `set_pinned` (a decline is
+a skip) and logs a receipt line. task-sync never unpins, because `pinned` does not record who set
+it. The live smoke found that a device's own hourly scheduled runs were pin candidates. Each run is
+a new session, so the pin step now skips any session whose `get_session` has a `scheduledTaskId`.
+Probes 11/11 on Python 3.9 and 3.14, the GH-1191 battery 17/17, and a red control (the
+already-pinned probe fails without its check). No new tests (GH-831). Plan QA: Codex, 4 rounds
+(the 4th authorized by the operator). Reversibility: **Easy**. Revert to stop new pins; existing
+pins stay until the operator unpins them.
+
 ## 2026-10-24 — task-sync: Claude Desktop sidebar titles (GH-1191)
 
 The Claude Desktop app keeps each Code session's sidebar title in its own session record,
diff --git a/skills/3-weekly/task-sync/SKILL.md b/skills/3-weekly/task-sync/SKILL.md
index 69fc9a69..82c26d41 100644
--- a/skills/3-weekly/task-sync/SKILL.md
+++ b/skills/3-weekly/task-sync/SKILL.md
@@ -205,7 +205,8 @@ The Claude Desktop app keeps each Code session's sidebar title in its own sessio
 so `--ide claude`'s transcript append does not reach the sidebar. **`--ide claude-desktop`**
 is a read-only planner like `codex` and `claude-cloud`: `set_session_title` owns every
 write. It needs a Claude Desktop session (the native session tools exist only there) and
-refuses `--apply`, `--set-title`, `--group` and `--unpin-days`.
+refuses `--apply`, `--set-title`, `--group` and `--unpin-days`. It also proposes pins
+(GH-1196), written with `set_pinned`; it never unpins.
 
 Snapshot: `{ "captured_at": <Unix seconds>, "sessions": [<list_sessions rows>] }`, at most
 300 seconds old. Activity is each row's own `lastActivityAt` (Desktop's turn activity), so
@@ -216,6 +217,11 @@ missing either flag is skipped; a candidate with a missing, unparseable or futur
 `sessions` list is a valid zero-candidate inventory. The title keeps its full wording; only
 the stamp changes.
 
+Pins: a non-archived, non-self row with a literal boolean `isRunning`, `pinned` missing or
+`false`, and `lastActivityAt` within `--pin-hours` (default 24) gets a `pinned` proposal.
+A running session can be pinned. A running row with bad activity is skipped, as before.
+`--no-pin` turns pins off.
+
 Native Desktop sweep procedure:
 
 1. `list_sessions(limit=100)`. Require a successful response; "no other sessions" is an
@@ -235,7 +241,16 @@ Native Desktop sweep procedure:
    `{"at", "session_id", "old", "new"}` to `~/.cache/task-sync/claude-desktop-renames.jsonl`
    (private, machine-local). Undo from that line only while `get_session(<id>)` still shows
    its `new` title: `set_session_title(<id>, <old>)`. A title changed since is left alone.
-6. Stay quiet when nothing changed; report failures, a missing tool, or declines that need
+6. For each `pinned` proposal, recheck with a fresh `list_sessions` (`get_session` has no
+   `pinned` field). The row must still exist, not be archived or your own session, have
+   activity inside `--pin-hours`, and have `pinned` missing or `false`; `pinned: true` (a
+   manual pin since) is a skip with no call. Also skip a session whose `get_session(<id>)`
+   has a `scheduledTaskId`: scheduled runs (this sweep's own heartbeat included) start a new
+   session each time, and a pin would also keep them from being auto-archived. Then
+   `set_pinned(<id>, true)`; a decline is a skip. Append `{"at", "session_id", "op": "pin"}` to the same
+   receipt. There is no automatic undo: `pinned` does not record who set it, so an unpin could remove a pin the
+   operator made. Unpinning is the operator's own choice.
+7. Stay quiet when nothing changed; report failures, a missing tool, or declines that need
    the operator.
 
 No concurrency guarantee: the recheck narrows, but cannot close, a race with a manual rename.
diff --git a/skills/3-weekly/task-sync/scripts/adapters/claude.py b/skills/3-weekly/task-sync/scripts/adapters/claude.py
index 462b8af9..275922ce 100644
--- a/skills/3-weekly/task-sync/scripts/adapters/claude.py
+++ b/skills/3-weekly/task-sync/scripts/adapters/claude.py
@@ -364,6 +364,7 @@ class ClaudeDesktopAdapter:
     does not reach it; ``set_session_title`` owns every write. The snapshot rows are
     ``list_sessions`` rows, whose ``lastActivityAt`` is the session's own turn activity.
     ``list_sessions`` excludes the caller, so an empty inventory is valid, not a refusal.
+    Pins (GH-1196) are proposals for ``set_pinned``; the planner only ever adds pins.
     """
 
     NAME = "claude-desktop"
@@ -406,22 +407,31 @@ class ClaudeDesktopAdapter:
     def sweep(self, *, hours=24, include_all=False, pin=True, pin_hours=24,
               unpin_days=None, include_cron=False, group=None):
         if unpin_days is not None or group:
-            raise core.AdapterError("claude-desktop: no pins or groups; --unpin-days/--group unsupported")
+            raise core.AdapterError("claude-desktop: no groups or unpinning; --unpin-days/--group unsupported")
         captured, sessions = self._snapshot()
         report = core.new_ide_report()
         report["scope"] = "list_sessions inventory; the sweeping session is excluded by the tool"
         report["execution"] = "native-tools-required"
         cutoff = captured - hours * 3600
+        pin_cutoff = captured - pin_hours * 3600
         for row in sessions:
             session_id = row["sessionId"]
-            if row.get("isArchived") is not False or row.get("isRunning") is not False \
-                    or session_id == self.exclude_thread:
+            running = row.get("isRunning")
+            if row.get("isArchived") is not False or session_id == self.exclude_thread \
+                    or not isinstance(running, bool):
                 report["skipped"] += 1
                 continue
             at = _iso_to_local(row.get("lastActivityAt"))
             if at is None or at.timestamp() > captured + 60:
+                if running:  # skipped before activity was read, as before GH-1196
+                    report["skipped"] += 1
+                    continue
                 raise core.AdapterError(f"claude-desktop lastActivityAt missing/invalid for {session_id}")
-            if at.timestamp() < cutoff:
+            # GH-1196: pins only ever get added; a running session can be pinned.
+            if pin and row.get("pinned") is not True and at.timestamp() >= pin_cutoff:
+                report["pinned"].append({"task_id": session_id, "title": row["title"],
+                                         "activity_at": row["lastActivityAt"]})
+            if running or at.timestamp() < cutoff:
                 report["skipped"] += 1
                 continue
             report["swept"] += 1
````

</details>

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.


## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
