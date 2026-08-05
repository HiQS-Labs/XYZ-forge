# RELAY · GH-410 containment fix — QA review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-04.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

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
6. **Commit only the relay file** (`relay(gh410-containment-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **gh410.diff** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-08-04

### What this change does, and what to attack

GH-410: the worktree containment **verdict** was a substring scan of the agent's transcript
(`agy-turn.py`, `if root in line`). It answered "did the model mention a path", not "did it access
one", and on a hit it failed the turn — discarding completed reviews. This change demotes that scan
to an **advisory** and leaves `rtl.worktree_end()` (a real git-state diff of the worktree) as the
sole verdict.

**Please review as an adversary, not a proofreader. The highest-value questions:**

1. **Is this a safety regression?** The claim is that write-containment is untouched because
   `rtl.worktree_end()` still runs and still exits 6, and that read-containment was never real —
   a prose scan cannot observe access. Is that reasoning sound, or does demoting the scan lose a
   signal that was doing genuine work?
2. **Is the counter-pin adequate?** `test/gh410-containment-advisory.sh` C4/C4b/C5 exist so the
   suite can distinguish "narrowed correctly" from "containment deleted". Would they actually catch
   a regression, or can you construct a build that deletes containment and still passes them?
   (One weakness was already found and fixed: C4 originally passed because `worktree_end` appeared
   in a *comment*.)
3. **Is the advisory reachable and visible?** It writes to stderr and appends to the transcript.
   Any path where a real breach now produces silence?
4. **`narration_mentions_root()` in `rtl.py`** — correctness of the exemptions, and whether putting
   it in the shared lib (rather than the shim) is right given only agy calls it today.
5. **The retry-preamble change in `marathon_drive.py`** — does it still give an agent enough to find
   `DEBUG-MANTRA.md` and `ESCALATION.md`? An earlier draft broke GH-162's contract here.

**Correction this change makes to the issue's own recommendation:** the report asked to make
containment uniform across shims, on the premise that codex is under-contained relative to agy.
Verified false — `rtl.worktree_end()` is called and enforced with `exit 6` by all five shims. Push
back if you think that reading is wrong.

**Do not edit any file.** This is review-only: report findings in your Log block.

### Artifact — gh410.diff
```
 CHANGELOG.md                                       |   5 +
 PROJECT/2-WORKING/GH-410-CONTAINMENT-PROSE-SCAN.md | 149 +++++++++++++++++++
 ROADMAP-DASHBOARD.md                               |   3 +-
 ROADMAP.md                                         |   1 +
 skills/relay-automation/relay-pkg.tar.gz           | Bin 101040 -> 101520 bytes
 test/agy-turn.sh                                   |  16 +-
 test/gh410-containment-advisory.sh                 | 161 +++++++++++++++++++++
 utils/py/agy-turn.py                               |  58 +++++---
 utils/py/marathon_drive.py                         |  22 ++-
 utils/py/rtl.py                                    |  50 +++++++
 validate.sh                                        |   1 +
 11 files changed, 436 insertions(+), 30 deletions(-)
diff --git a/utils/py/agy-turn.py b/utils/py/agy-turn.py
index 94bbac1..c15e7f0 100644
--- a/utils/py/agy-turn.py
+++ b/utils/py/agy-turn.py
@@ -4,7 +4,8 @@ import sys
 import tempfile
 import subprocess
 import shlex
-from rtl import RelayTurnLib, claim_task_or_exit, rtl_default_log, resolve_turn_root
+from rtl import (RelayTurnLib, claim_task_or_exit, rtl_default_log, resolve_turn_root,
+                 narration_mentions_root)
 
 def die(msg):
     print(f"agy-turn: {msg}", file=sys.stderr)
@@ -207,27 +208,40 @@ def main():
         if off_lane:
             print("agy-turn: agy made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)", file=sys.stderr)
             sys.exit(6)
-        # GH-178 B1: Verify agy grounding stayed contained to $WT.
-        if bounded_rc == 0 and os.path.exists(agy_log) and os.path.getsize(agy_log) > 0:
-            # Filter out false-positive shapes before the ROOT substring scan:
-            #   [trace] lines (instrumentation, legitimately contain RTL_ROOT)
-            #   TICK_REPO_ROOT="..." (harness-mandated tick-command narration, GH-183)
-            #   file:// URIs and markdown link targets ](...) (file citations, GH-187)
-            breached = False
-            with open(agy_log, "r", errors="replace") as log_f:
-                for line in log_f:
-                    if line.startswith("[trace] "):
-                        continue
-                    if "TICK_REPO_ROOT=" in line or "file://" in line or "](" in line:
-                        continue
-                    if root in line:
-                        breached = True
-                        break
-            if breached:
-                print(f"agy-turn: agy transcript cited the real repo root ({root}) instead of the isolated worktree. This is an isolation breach. Failing the turn.", file=sys.stderr)
-                with open(agy_log, "a") as log_f:
-                    log_f.write("\n[FAIL] agy isolation breach: transcript cited the real repo root instead of the worktree.\n")
-                sys.exit(5)
+        # GH-178 B1, narrowed by GH-410: this used to exit 5 and throw the turn away.
+        #
+        # The verdict is `worktree_end` above — it diffs the worktree's git state, so it observes
+        # writes that actually happened, and every shim enforces it identically. What follows only
+        # observes whether the transcript NAMED the root, which is a different question: an agent
+        # that quietly touched the real tree without naming it was never caught here, and one that
+        # merely cited a path in a finding was failed for it. Measured in a single run, same builder
+        # and isolation settings: the phase with TEN repo-root mentions was Approved, the one with
+        # NINE failed three times running.
+        #
+        # The cost was asymmetric. A builder losing a turn loses regenerable work; a reviewer losing
+        # one loses a VERDICT — in the reported case a review that had already written
+        # `STATUS: Approved` was discarded and the chain halted. A heuristic that destroys completed
+        # work must fail toward keeping it.
+        #
+        # It is now advisory: recorded on the transcript and stderr so an operator still sees it,
+        # and it never changes the turn's outcome.
+        if bounded_rc == 0:
+            mentions, first_line = narration_mentions_root(agy_log, root)
+            if mentions:
+                print(f"agy-turn: ADVISORY — agy's transcript names the real repo root ({root}) on "
+                      f"{mentions} line(s); first: {first_line[:120] if first_line else ''}. This is "
+                      "NOT a containment verdict: naming a path is not accessing one, and the "
+                      "harness's own retry preamble renders absolute paths into the relay file. "
+                      "Out-of-worktree WRITES are enforced separately and did not occur (GH-410).",
+                      file=sys.stderr)
+                try:
+                    with open(agy_log, "a") as log_f:
+                        log_f.write(
+                            f"\n[ADVISORY] transcript names the real repo root on {mentions} line(s). "
+                            "Not a containment failure — out-of-worktree writes are checked against the "
+                            "worktree's git state and none were found (GH-410).\n")
+                except OSError:
+                    pass
 
     if bounded_rc == 7:
         print(f"agy-turn: agy -p exceeded {turn_timeout}s wall-clock cap — killed", file=sys.stderr)
diff --git a/utils/py/marathon_drive.py b/utils/py/marathon_drive.py
index 507754a..7b31014 100644
--- a/utils/py/marathon_drive.py
+++ b/utils/py/marathon_drive.py
@@ -400,11 +400,27 @@ def main():
                             break
             except Exception:
                 pass
+        # GH-410: name the files once, with their directories stated once, instead of repeating a
+        # full absolute path per line. This preamble renders ONLY on a retry, so the old form handed
+        # every re-attempt extra copies of the repo root — a recovery path that raised the very
+        # hazard it was retrying against, back when the containment scan failed turns on prose.
+        # That scan is advisory now, so this is hygiene rather than a fix, and it keeps the relay
+        # file readable. The tick-binary line elsewhere deliberately keeps its absolute path:
+        # "run it from any directory" is the whole point of that instruction.
+        # Name the file by its HARNESS-RELATIVE path — which contains no repo root — and give the
+        # directory once, instead of inlining a full absolute path per line. GH-162's contract that
+        # the note reference `relay-automation/DEBUG-MANTRA.md` is preserved exactly; what goes away
+        # is the repeated root. See test/debug-mantra.sh, which pins that reference.
+        mantra_rel = os.path.join(os.path.basename(os.path.dirname(mantra_file)),
+                                  os.path.basename(mantra_file))
+        mantra_dir = os.path.dirname(os.path.dirname(mantra_file))
         out = (f"\n## Debug mantra (auto-triggered — {prior} prior attempt(s) on this phase did not reach Approved)\n\n"
-               f"Before trying again, read {mantra_file} and follow its four-step discipline: reproduce reliably, "
-               f"know the fail path, question the hypothesis, treat this round as a breadcrumb for the next one.\n")
+               f"Before trying again, read `{mantra_rel}` (under `{mantra_dir}`) and follow its "
+               f"four-step discipline: reproduce reliably, know the fail path, question the hypothesis, treat this "
+               f"round as a breadcrumb for the next one.\n")
         if reason:
-            out += f"Last recorded reason ({phase_dir_}/ESCALATION.md): `{reason}`. Read it before re-guessing.\n"
+            out += (f"Last recorded reason (`ESCALATION.md` in `{phase_dir_}`): `{reason}`. "
+                    "Read it before re-guessing.\n")
         return out
 
     if get_env("RELAY_DRIVER_LOCKED", "0") != "1":
diff --git a/utils/py/rtl.py b/utils/py/rtl.py
index 0944c9c..b5f4746 100644
--- a/utils/py/rtl.py
+++ b/utils/py/rtl.py
@@ -278,3 +278,53 @@ echo -n "${{RTL_WT_OFFLANE:-0}}"
 """
         res = self._run_rtl(cmd)
         return res.stdout.strip() == "1"
+
+
+# GH-410: ADVISORY ONLY — never a verdict.
+#
+# `worktree_end` above is the containment verdict: it diffs the worktree's own git state, so it
+# observes writes that actually happened, and all five turn shims exit 6 on it identically.
+#
+# This function answers a strictly weaker question — does the transcript NAME the real repo root —
+# and the two diverge in both directions. An agent that quietly touched the real tree without naming
+# it is not detected here; an agent that merely cites an absolute path in a finding is. Measured
+# (#410): two phases in one run, same builder and same isolation settings, where the one with TEN
+# repo-root mentions was Approved and the one with NINE failed three consecutive times.
+#
+# It used to fail the turn, which discarded completed reviews. Three exemption patches were spent
+# trying to make it precise (#183 `TICK_REPO_ROOT=`, #187 `file://` and `](`) and a fourth shape was
+# still outstanding: the harness's own retry preamble renders absolute paths into the relay file, so
+# an agent following instructions writes the trigger into its own transcript.
+#
+# Do NOT re-promote this to a verdict without first making reads observable. If that ever happens,
+# the seeding in marathon_drive's retry preamble has to be fixed first.
+def narration_mentions_root(log_path, root):
+    """Count transcript lines naming `root`, ignoring known-benign shapes. (count, first_line).
+
+    Returns (0, None) when the log is missing, empty, or names nothing. The exemptions are kept only
+    to stop the advisory from being pure noise — they are no longer load-bearing, because nothing
+    fails on this result.
+    """
+    if not root or not log_path or not os.path.exists(log_path):
+        return 0, None
+    try:
+        if os.path.getsize(log_path) == 0:
+            return 0, None
+    except OSError:
+        return 0, None
+
+    count, first = 0, None
+    try:
+        with open(log_path, "r", errors="replace") as fh:
+            for line in fh:
+                if line.startswith("[trace] "):
+                    continue
+                if "TICK_REPO_ROOT=" in line or "file://" in line or "](" in line:
+                    continue
+                if root in line:
+                    count += 1
+                    if first is None:
+                        first = line.strip()
+    except OSError:
+        return 0, None
+    return count, first
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

### Review (agy, r1)
swept file: yes
- **Safety regression:** `[Pass]` (`agy-turn.py:213-214` "diffs the worktree's git state") The reasoning is sound. Write-containment remains enforced by `rtl.worktree_end()`. The prose scan for reads was an unsound heuristic. Demoting it to advisory is safe.
- **Counter-pin adequacy (C4/C4b):** `[Blocker]` The tests `C4`/`C4b` just grep the source code. A build could comment out `sys.exit(6)` (e.g., `# sys.exit(6)`) and still pass both `C4` and `C4b` while silently deleting containment! You already set up `STUB_MODE=offlane` in `agy-stub` (`test/gh410-containment-advisory.sh:94`) but never execute it. Replace the source-code greps with a real test: run `run_turn offlane "$offlanelog"` and assert it exits 6.
- **Advisory reachability:** `[Should]` In `agy-turn.py`, the check `if bounded_rc == 0:` skips the advisory if the agent failed the turn for other reasons (like a timeout or bad exit code). A failing agent might still have cited the root. Consider un-gating it from `bounded_rc == 0` so the advisory is printed even on failure.
- **`narration_mentions_root()` location:** `[Should]` The function was moved to the shared lib `rtl.py`, but its exemptions (`[trace] `, `TICK_REPO_ROOT=`) are highly specific to `agy-turn.py`'s log format. Since only `agy-turn.py` uses it today, it should stay in `utils/py/agy-turn.py`.
- **Retry-preamble change in `marathon_drive.py`:** `[Blocker]` The PR claims to remove the repo root from the transcript, but `mantra_dir = os.path.dirname(os.path.dirname(mantra_file))` returns an **absolute** path that starts with the repo root! The rendered string ``(under `{mantra_dir}`)`` still embeds the root into the preamble. Similarly, `phase_dir_` is an absolute path, so ``in `{phase_dir_}` `` also leaks the root. Use `os.path.relpath()` for both, or omit the absolute directory portions entirely.

**Verdict:** Changes requested.


### Producer (claude-a, r1 dispositions)

**Both Blockers accepted and fixed; one Should accepted; one Should declined with reasoning.**

- **Counter-pin C4/C4b — `[Blocker]` → Implemented.** Correct, and worse than described: the
  `offlane` stub branch also wrote to `$AGY_TURN_ROOT` rather than into the worktree, so it would
  not have tripped `worktree_end()` even if it had been called. Both fixed — the stub now writes to
  CWD (the worktree) and `run_turn offlane` is actually executed, asserting exit 6 plus that the file
  never reached the real tree. **Verified against your exact attack:** commenting out `sys.exit(6)`
  now yields exit 5 and C4 fails; the old `grep -q "sys.exit(6)"` matched the commented-out line and
  passed. You caught a check that asserted what the code says instead of what it does — the same
  substitution this whole issue is about, reproduced in the test written to guard against it.

- **Retry preamble — `[Blocker]` → Implemented.** Correct. `dirname(dirname(mantra_file))` is
  absolute and `phase_dir_` is absolute, so the root was still embedded once per line; "given once"
  is not "not given". Both now go through `os.path.relpath`, guarded so a cross-repo `--target-root`
  run that would produce a `../../..` chain keeps the absolute path deliberately rather than emitting
  something useless. **The assertion moved too:** it is now a behavioural check on the RENDERED relay
  file in `test/debug-mantra.sh` (which already owns a fixture that renders the preamble), not a
  source grep here — applying your own C4 lesson to the case that would have repeated it.

- **Advisory reachability — `[Should]` → Implemented.** Un-gated from `bounded_rc == 0`. You are
  right that a timed-out or errored turn could have cited the root and produced no signal, which
  withheld the note from exactly the runs most likely to need explaining. Since the advisory changes
  no outcome, there was nothing to gate.

- **`narration_mentions_root()` location — `[Should]` → Declined, with reasoning.** The YAGNI
  argument is fair and I nearly took it. Declining because this repo has a documented, repeated
  failure mode of per-shim copies drifting: #296 (a fix that landed in Bash and never in the Python
  twin that actually runs), #320 (timeout defaults 900/300/600 across three shims), #215 and #223
  (`consult.py` missing Bash behaviours). A single-consumer helper in the shared lib costs nothing;
  a helper that a second shim copies later is how every one of those started. The exemptions are
  agy-log-shaped today and the docstring says so.

- **Safety regression `[Pass]`** — noted, no action.

All suites green after the changes: `gh410-containment-advisory` 10/0 (C4 now a real execution
test), `debug-mantra` 15/0 (gained the rendered-preamble assertion), `agy-turn` 62/0.

Handing back to the Reviewer — please verify the two Blocker fixes actually hold, especially whether
C4 can still be defeated, and say whether the declined Should changes your verdict.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
