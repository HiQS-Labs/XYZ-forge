# RELAY · GH-1191 step 4 final QA: Desktop scheduled task per device (docs)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-24.
-->

NEXT: Closed
STATUS: Approved
ROUND: 2 / 2

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
6. **Commit only the relay file** (`relay(gh1191-scheduler-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/3-weekly/task-sync/SKILL.md` (new paragraph in "The heartbeat (single scheduler)"), `TESTS-RESULTS/2026-10-24+GH-1191/scheduled-run.md`, `TESTS-RESULTS/2026-10-24+GH-1191/provenance.jsonl`, `PROJECT/2-WORKING/GH-1191-TASK-SYNC-CLAUDE-DESKTOP.md` (new "Step 4" section), `CHANGELOG.md` (top entry). Docs only; full diff embedded below.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-24
- Context: step 4 of https://github.com/HiQS-Labs/XYZ-forge/issues/1191. Operator decision 2026-10-24: "I don't want to rely on the Zcode automation. I cancelled that plan. Can we do it in Claude Desktop?" Plan QA was skipped as a simple change: docs only, and the operator already made the decision. The native procedure being scheduled was approved in PR #1194 (merged).
- Operational envelope: local single-operator tooling docs. No new suites or gates (AGENTS.md, GH-831). Grade the docs against the evidence and the existing SKILL rules; do not demand machinery.
- Definition of Done:
  1. The new heartbeat paragraph is accurate against the receipt and the GH-1191 procedure, and doesn't contradict the ZCode/Codex/cloud rules it sits beside.
  2. The receipt states only what was observed, with its limits.
  3. The plan-doc and CHANGELOG entries are truthful and consistent.

Questions:
1. Does the paragraph contradict "never a second local scheduler" in the ZCode paragraph, or the Install SOP? If so, what's the smallest wording fix?
2. Are the receipt's claims, especially the declined title and the default permission mode, supported, and are its limits stated?
3. Anything inaccurate, missing or over-claimed? Cite file:line.

<details><summary>Embedded diff</summary>

```diff
diff --git a/CHANGELOG.md b/CHANGELOG.md
index f1e80714..d90567d2 100644
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -1,5 +1,18 @@
 # Changelog
 
+## 2026-10-24 — task-sync: one Claude Desktop scheduled task per device (GH-1191 step 4)
+
+The operator dropped the ZCode heartbeat for Claude Desktop. `SKILL.md`'s heartbeat section now
+names one hourly Claude Desktop scheduled task per Mac, created from a Desktop session.
+- Its self-contained, `$HOME`-relative prompt runs the GH-1191 native sweep against the
+  deployed copy; each Mac renames only its own sessions.
+- The first unattended run on one device (default permission mode) renamed an app-generated
+  title and declined, as a reported skip, a title the operator had set. Receipt:
+  `TESTS-RESULTS/2026-10-24+GH-1191/scheduled-run.md`.
+- The ZCode, Codex and cloud scheduler rules are unchanged.
+
+Reversibility: **Easy** (docs; disable the scheduled task per device).
+
 ## 2026-10-24 — task-sync: Claude Desktop sidebar titles (GH-1191)
 
 The Claude Desktop app keeps each Code session's sidebar title in its own session record,
diff --git a/PROJECT/2-WORKING/GH-1191-TASK-SYNC-CLAUDE-DESKTOP.md b/PROJECT/2-WORKING/GH-1191-TASK-SYNC-CLAUDE-DESKTOP.md
index dbf7ffae..daa1532c 100644
--- a/PROJECT/2-WORKING/GH-1191-TASK-SYNC-CLAUDE-DESKTOP.md
+++ b/PROJECT/2-WORKING/GH-1191-TASK-SYNC-CLAUDE-DESKTOP.md
@@ -155,3 +155,15 @@ Codex relay `relay-system/2026-10-24/gh1191-final-qa.md`, Approved in round 2 of
 ## Merge evidence
 
 - PR #1194 merged 2026-10-24 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
+
+## Step 4 (2026-10-24): one Desktop scheduled task per device
+
+- **Operator decision:** no ZCode heartbeat. The scheduler is one hourly Claude Desktop scheduled task per Mac (`SKILL.md` → "The heartbeat").
+- **First device (MacBook Pro 14"):** `task-sync-desktop-titles` was created, and its first unattended run succeeded.
+  - It renamed an app-generated title.
+  - It declined an operator-set title, which needs approval.
+  - Receipt: `TESTS-RESULTS/2026-10-24+GH-1191/scheduled-run.md`.
+- **Still open:**
+  - re-stamping a `tool`-sourced title on a later day;
+  - the 16" and Mac Studio rollout (step 5);
+  - pinning (#1196, plan QA escalated).
diff --git a/TESTS-RESULTS/2026-10-24+GH-1191/provenance.jsonl b/TESTS-RESULTS/2026-10-24+GH-1191/provenance.jsonl
index b5b0c55a..dcdbae81 100644
--- a/TESTS-RESULTS/2026-10-24+GH-1191/provenance.jsonl
+++ b/TESTS-RESULTS/2026-10-24+GH-1191/provenance.jsonl
@@ -1,3 +1,4 @@
 {"kind": "manual_probe", "command": "python3 TESTS-RESULTS/2026-10-24+GH-1191/probes.py . TESTS-RESULTS/2026-10-24+GH-1191", "sha_base": "b5f32502", "platform": "macOS 15 (Darwin 24.6.0); Python 3.14.7 and /usr/bin/python3 3.9.6", "exit_code": 0, "checks": "17/17", "results": "probe-results.json", "log": "probes.log", "qualification": "fixture snapshots only; fixtures created and removed under the receipt dir"}
 {"kind": "red_control", "command": "probes.py against a scratch copy with the isRunning skip removed from ClaudeDesktopAdapter.sweep", "sha_base": "b74f8547", "exit_code": 1, "checks": "15/17", "log": "red-control.log", "qualification": "the two running/missing-flag probes go red as expected"}
 {"kind": "live_smoke", "command": "SKILL.md 'Claude Desktop (GH-1191)' native procedure: list_sessions, task_sync.py --ide claude-desktop, get_session, set_session_title, get_session, rerun, undo", "sha": "b74f8547fb79eccda7c3f4f602985116294892e6", "platform": "Claude Desktop Code session on macOS (bypass permissions mode)", "exit_code": 0, "results": "live-smoke.md", "qualification": "one idle target session; IDs, titles and account path sanitized; unattended-decline behaviour not witnessed"}
+{"kind": "live_scheduled_run", "command": "Claude Desktop scheduled task task-sync-desktop-titles, Run now", "platform": "Claude Desktop on macOS, default permission mode, unattended", "exit_code": 0, "results": "scheduled-run.md", "qualification": "one run on one device; tool-sourced re-stamp across a date change not yet witnessed"}
diff --git a/TESTS-RESULTS/2026-10-24+GH-1191/scheduled-run.md b/TESTS-RESULTS/2026-10-24+GH-1191/scheduled-run.md
new file mode 100644
index 00000000..e46a0b4a
--- /dev/null
+++ b/TESTS-RESULTS/2026-10-24+GH-1191/scheduled-run.md
@@ -0,0 +1,17 @@
+# GH-1191 step 4: first unattended Desktop scheduled run (one device, 2026-10-24)
+
+Scheduled task `task-sync-desktop-titles` (hourly at :22) was created from a Desktop Code session. Its prompt is the procedure in `SKILL.md`, "Claude Desktop (GH-1191)", titles only, run from `~/git-pulse-sync/Deployed Skills/task-sync`. One run was started with "Run now"; it starts exactly as a scheduled run does.
+
+| Fact | Observed |
+|---|---|
+| Permission mode | Default mode (the creating session's bypass mode is **not** saved with the task); nobody present |
+| Duration | ~40 s, status `succeeded` |
+| Run's report | `task-sync desktop: proposed=2 renamed=1 skipped=0 declined=1` |
+| App-generated title | Renamed (stamp added; one undo line appended to `~/.cache/task-sync/claude-desktop-renames.jsonl`) |
+| Operator-set title | **Declined** by `set_session_title`: it needs approval and nobody could give it. The run reported this as a skip, not an error |
+| Script call | The `task_sync.py` Bash call did not block the run |
+| Run session record | Carries `scheduledTaskId: task-sync-desktop-titles` |
+
+Session IDs and titles are omitted (public repo).
+
+Not yet witnessed: re-stamping a title already marked `titleSource: tool` on a later day, which needs a date change.
diff --git a/skills/3-weekly/task-sync/SKILL.md b/skills/3-weekly/task-sync/SKILL.md
index 69fc9a69..3a798381 100644
--- a/skills/3-weekly/task-sync/SKILL.md
+++ b/skills/3-weekly/task-sync/SKILL.md
@@ -260,6 +260,19 @@ before enabling the replacement. Never introduce launchd, a daemon or a second
 writer. A Codex-only installation runs only the native sweep; adding Codex does
 not authorize enabling absent ZCode/Agy stores. Keep it quiet while unchanged.
 
+Claude Desktop sidebar titles (GH-1191) have one writer **per device**: one hourly Claude
+Desktop scheduled task on that Mac, created from a Desktop Code session (the native session
+tools exist only there). Each Mac renames only its own sessions, so the devices never compete
+and a closed laptop simply skips its runs (missed runs fire on the next app launch). Inspect
+the Mac's existing scheduled tasks first and repoint a task-sync one instead of adding a second.
+Use an off-minute hourly schedule; each run opens a short session, so 15 minutes would flood
+the sidebar. The task prompt must be self-contained and `$HOME`-relative so the same text works
+on every Mac: run the "Claude Desktop (GH-1191)" native sweep above from
+`~/git-pulse-sync/Deployed Skills/task-sync`, titles only, ending with one line
+`task-sync desktop: proposed=N renamed=M skipped=K declined=D`. Runs start in the device's
+default permission mode, not the creating session's mode. Observed on the first unattended
+run: app-generated titles are renamed, and a title the operator set is declined and reported.
+
 Cloud Claude Code titles have exactly one writer: one hourly Claude Code scheduled
 task (cloud tasks run at most hourly) that selects the XYZ-forge repository and runs
 the native cloud sweep procedure above with
```

</details>

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes

- [Should] The receipt's precise report is `proposed=2 renamed=1 skipped=0 declined=1`, but it then says the declined operator-set title was “reported ... as a skip” (`TESTS-RESULTS/2026-10-24+GH-1191/scheduled-run.md:9-11`). The new heartbeat paragraph repeats the same ambiguity (`skills/3-weekly/task-sync/SKILL.md:272-274`), and the CHANGELOG does too (`CHANGELOG.md:9-11`). Narrow those claims to “declined and reported” (or explain the counters) rather than calling this observed decline a reported skip. Observed input: the one scheduled run's reported counter line, `task-sync desktop: proposed=2 renamed=1 skipped=0 declined=1` (`scheduled-run.md:9`). Affected scope: documentation that describes a `set_session_title` decline from the scheduled-run report. Falsifier: a corrected/complete run report showing `skipped=1` for this declined title would make “reported as a skip” accurate. Probe: `rg -n -F 'task-sync desktop: proposed=' skills/3-weekly/task-sync TESTS-RESULTS/2026-10-24+GH-1191 PROJECT/2-WORKING/GH-1191-TASK-SYNC-CLAUDE-DESKTOP.md CHANGELOG.md; rg -n -F 'skipped=0 declined=1' TESTS-RESULTS/2026-10-24+GH-1191 PROJECT/2-WORKING/GH-1191-TASK-SYNC-CLAUDE-DESKTOP.md CHANGELOG.md` (exit 0; decisive output: the template is at `SKILL.md:272`, while the sole observed result is `scheduled-run.md:9` with `skipped=0 declined=1`).
- [Pass] The full `SKILL.md` sweep found no other pre-existing defect in the touched scheduler context: the Desktop writer is explicitly per-device (`skills/3-weekly/task-sync/SKILL.md:263-267`), it requires inspecting/repointing an existing task before adding one (`:267`), and it remains distinct from the ZCode/Agy/local-Claude-Code scheduler (`:245-251`) and the Codex single-scheduler exception (`:253-261`). The receipt confines its evidence to one unattended default-permission run and explicitly records the unwitnessed later-day tool-title restamp (`TESTS-RESULTS/2026-10-24+GH-1191/scheduled-run.md:3,7,17`; `provenance.jsonl:4`).

VERDICT: FAIL

Basis: One concrete counter/prose contradiction must be narrowed before the receipt and downstream documentation can be called truthful. No other finding from the swept artifact.

Handing off to Producer — go to the Producer window and say “take your turn”.

### Producer · Round 1

- Finding 1 ("reported as a skip" contradicts `skipped=0 declined=1`): **Implemented.**
  - The receipt now says the run continued and reported the decline under `declined=1`, separate from `skipped=0`.
  - The CHANGELOG now says the title was declined and reported (`declined=1`, not an error).
  - `SKILL.md` already read "declined and reported" (line 274), so it is unchanged.
  - The older #1194 CHANGELOG phrase "a decline is a skip" describes the procedure's handling (skip that rename, don't error), not the counter, so it is left as is.

Round 2: please re-review the two edited lines.

### Reviewer · Round 2

swept file: yes

- [Pass] The counter/prose mismatch is resolved: the receipt records `skipped=0 declined=1` and says the decline was reported under `declined=1` (`TESTS-RESULTS/2026-10-24+GH-1191/scheduled-run.md:9-11`); the heartbeat and CHANGELOG now say only that the title was "declined and reported" / reported as `declined=1` (`skills/3-weekly/task-sync/SKILL.md:272-274`; `CHANGELOG.md:9-12`). Probe: `rg -n -F 'reported as a skip' skills/3-weekly/task-sync/SKILL.md TESTS-RESULTS/2026-10-24+GH-1191 PROJECT/2-WORKING/GH-1191-TASK-SYNC-CLAUDE-DESKTOP.md CHANGELOG.md; rg -n -F 'missed runs fire on the next app launch' . --glob '!relay-system/**' --glob '!*.jsonl'` (exit 0; decisive output: no remaining "reported as a skip" match, and the sole scheduler-resumption wording is `SKILL.md:266`).
- [Pass] The full `SKILL.md` sweep found no pre-existing defect in the touched scheduler context: its ZCode rule is expressly scoped to ZCode/Agy and local Claude Code (`skills/3-weekly/task-sync/SKILL.md:245-251`), while the Desktop task is explicitly one writer per device and requires repointing instead of duplication (`SKILL.md:263-274`). The receipt limits its observation to one unattended default-permission run and identifies the unwitnessed later-day tool-title restamp (`scheduled-run.md:7-17`; `provenance.jsonl:4`); the plan document consistently retains that item and the remaining-device rollout as open (`PROJECT/2-WORKING/GH-1191-TASK-SYNC-CLAUDE-DESKTOP.md:161-169`).

VERDICT: PASS

Basis: The corrected evidence and every downstream claim are consistent, bounded to the observed one-device run, and do not introduce a second writer within any device.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
