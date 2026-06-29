# RELAY · GH-40 branch code QA (Codex review)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-06-29.
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
     (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh40-codeqa): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: the GH-40 branch work (`tests/self-improvement-loop`). Read these repo-relative files directly:
  - `validate.sh` (the new TESTS entries — the 3 canary verifiers + `phase3-signoff-guard.sh`)
  - `test/fixtures/gamma-poison/verify-fixture.sh`
  - `test/fixtures/canary-token-reuse/verify-fixture.sh`
  - `test/fixtures/canary-peer-orphan/verify-fixture.sh`
  - `test/fixtures/canary-reviewer-overstep/verify-fixture.sh`
  - `relay-automation/proposals-sink.sh`
  - `test/phase3-signoff-guard.sh`
  - Context (don't grade, use to judge intent): `PROJECT/2-WORKING/GH-40-DOUBLE-BLIND-REVIEWER.md`
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-06-29
- Definition of Done (grade against these):
  1. **Correctness** — each `verify-fixture.sh` actually proves what it claims; assertions are sound, not vacuous (e.g. a `grep` that can't fail). The Gamma assertion must be count-independent.
  2. **Safety / no pollution** — the driven-kernel fixtures (peer-orphan, reviewer-overstep) and `phase3-signoff-guard.sh` must not be able to mutate the real repo: `GIT_CEILING_DIRECTORIES` + a scratch-`.git` assertion where they touch git; scratch dirs cleaned via traps; no stray refs/commits. (The GH-44 lesson — flag any residual fall-through risk.)
  3. **`proposals-sink.sh` trust boundary** — is the rule/operator-doc refusal robust (basename-only; bypassable via path tricks, symlinks, case)? Bash 3.2-portable (no `mapfile`/`${x,,}`)? `set -u` / quoting safe?
  4. **validate.sh wiring** — new entries honor the exit-code contract, don't break the count logic, and Gamma is correctly left OUT (it runs the suite itself → recursion).
  5. **Shell hygiene** — quoting around paths with spaces, `set -u` safety, portable `grep -E`/`sed`, cleanup on failure paths.
  Grade `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]` with a concrete fix each; set a Verdict. REVIEW-ONLY — do not edit any file, only append findings here.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
