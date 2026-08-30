# RELAY · Post-merge QA of PR #236 agent-chorus — close semantics, doorbell liveness, onboarding (qwen3.8-max via CommandCode)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-30.
-->

NEXT: Reviewer
STATUS: Open
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
6. **Commit only the relay file** (`relay(pr236-agent-chorus-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Reviewer: commandcode   ·   Producer: claude-a
- Started: 2026-08-30
- Artifact under review: `skills/agent-chorus/scripts/agent_chorus.py` — plus, as supporting
  context, `skills/agent-chorus/SKILL.md`, `skills/agent-chorus/README.md`,
  `skills/agent-chorus/TELEMETRY.md`, `skills/agent-chorus/agents/openai.yaml`,
  `skills/agent-chorus/test-standalone.sh` and `test/agent-chorus.sh`.
  Read-only for you: do NOT edit them; append findings here only.
- Definition of Done: **PR #236 is already MERGED to `development`** (9 files, +454/-65,
  "fix(agent-chorus): close semantics, doorbell liveness, onboarding — pilot findings (#231)").
  This is therefore a **post-merge review of live code**, not a gate. That changes what is useful:
  a defect you find here is already shipped, so prioritise correctness and safety over style, and
  say plainly whether each finding warrants a follow-up issue or is fine to leave.

  Review the merged state as it stands. Grade against these questions:

  1. **Close semantics.** The PR claims to fix them. Read the close/teardown path end to end in
     `agent_chorus.py`. Is every resource opened on the happy path also released on the error and
     signal paths — file handles, subprocesses, sockets, temp files, locks? Name any path where a
     failure mid-flight leaks or leaves state behind, with `file:line`.
  2. **Doorbell liveness.** Same file. Can the liveness mechanism deadlock, spin, or miss a wakeup —
     a signal delivered between check and wait, a timeout that never fires, a waiter that is never
     notified? A concrete interleaving that breaks it is a `[Blocker]`; a theoretical worry with no
     interleaving is a `[Nit]`.
  3. **Concurrency and process handling.** Look for unbounded waits, missing timeouts, orphaned
     child processes, and reads of shared state without a guard. `agent_chorus.py` orchestrates
     multiple agents, so a hang here strands the operator with no signal.
  4. **Error paths and failure reporting.** Does a failing agent surface distinguishably from a
     succeeding one, or can a silent failure read as success? Exit codes, empty output, and
     partial results are the cases that matter.
  5. **Do the tests actually test the fixes?** `test/agent-chorus.sh` and
     `test-standalone.sh` are in the PR. Would either fail if the close-semantics or doorbell fix
     were reverted? If not, say which assertion is missing — that is the most valuable finding
     available here, because it is what lets this regress silently.
  6. **Doc-vs-code drift.** `SKILL.md`, `README.md`, `TELEMETRY.md` and `openai.yaml` all changed in
     the same PR. Quote anything they promise that the code does not do, or that the code does and
     they do not mention.

  **Review the whole file, not just the PR's diff** (GH-268): pre-existing defects in
  `agent_chorus.py` are in scope, and if you find none say so explicitly. Cite `file:line` or a
  quoted span for every `[Pass]`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
