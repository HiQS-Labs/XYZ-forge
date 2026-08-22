# RELAY · QA skills/agent2agent/test-standalone.sh (new standalone regression suite)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-22.
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
6. **Commit only the relay file** (`relay(gh-agent2agent-test-standalone-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/test-standalone.sh** — the read-only path that
  `relay-drive.sh --artifact-file skills/agent2agent/test-standalone.sh` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: aider   ·   Producer: claude-a
- Started: 2026-08-22
- Definition of Done: `.relay-artifacts/test-standalone.sh` is a new, minimal, dependency-free
  regression suite for `skills/agent2agent/scripts/agent2agent.py` (present in the worktree at its
  normal committed path — read it too). It claims to run with NO dependency on this repo's
  `bin/tick`, `relay-automation/`, or `test/_setup.sh`/`lib/fixture-guard.sh` — only bash + python3 +
  coreutils. It was verified locally by running it (26/26 pass) both from the repo root and from
  `/tmp`, and by confirming `test/agent2agent.sh` (the full 129-assertion suite) still passes
  unaffected. Grade: (1) is the "no repo dependency" claim actually true — does every assertion in
  the file genuinely avoid `tick`/`relay-automation`/repo-specific fixtures, or is there a hidden
  coupling? (2) does each assertion test what its label says it tests, and does it match the real
  behavior of `agent2agent.py` (cite line numbers on both sides for any mismatch)? (3) is the lock-
  contention test (a real `flock` held by a background python process) safe and non-flaky — race
  conditions, cleanup, zombie processes? (4) is anything from `agent2agent.py`'s command surface
  (start/status/join/watch/send/close/drive) meaningfully under-covered that a 26-assertion minimal
  suite should still catch? (5) any bug in the shell script itself (quoting, `set -u` interaction,
  exit-code handling, temp-dir safety).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
