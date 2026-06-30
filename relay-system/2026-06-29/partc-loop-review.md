# RELAY · Part C self-improvement loop — code review (Codex)
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
6. **Commit only the relay file** (`relay(partc-loop-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: the Part C autonomous self-improvement loop on `feat/self-improvement-loop`. Read these repo-relative files directly:
  - The six primitives: `relay-automation/measure.sh`, `relay-automation/loop-stop.sh`, `relay-automation/oracle-guard.sh`, `relay-automation/champion.sh`, `relay-automation/heldout-check.sh`, `relay-automation/loop-cost.sh`
  - The orchestrator: `relay-automation/improve-loop.sh`
  - Tests: `test/measure.sh`, `test/loop-stop.sh`, `test/oracle-guard.sh`, `test/champion.sh`, `test/heldout-check.sh`, `test/loop-cost.sh`, `test/improve-loop.sh`, `test/improve-loop-qa.sh`, `test/improve-loop-dogfood.sh`
  - Context (don't grade): `PROJECT/2-WORKING/AUTONOMOUS-SELF-IMPROVEMENT-LOOP.md`, `decisions/2026-06-29-self-improvement-loop.md`
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-06-29
- Definition of Done (grade against these — this is a REVIEW-ONLY turn; do not edit any file, only append findings):
  1. **Guaranteed halt** — does `loop-stop.sh` + `improve-loop.sh` provably terminate on EVERY path? Can the main `while :` loop spin without advancing the iteration counter (e.g. a champion `judge` that doesn't increment, or a stop decision that's mis-parsed)? Is the required positive `--max-iterations` actually enforced?
  2. **Oracle-immutability** — is `oracle-guard.sh`'s disjointness sound (could a builder write path still reach an oracle path it doesn't textually overlap — symlink, `..`, glob)? Does `improve-loop.sh` actually run the guard before the first build, and fail closed?
  3. **No-regress / rollback** — can a rejected challenger ever leak into the champion? Is the snapshot/rollback (`cp`) correct for the accept AND reject paths, and on the final emit? Any TOCTOU or partial-write window?
  4. **Anti-gaming veto** — is the `heldout-check.sh` signature (visible-gain + held-out-loss) correctly wired into the judge as an oracle-fail, and is `HELD_CUR` tracked correctly across accept/reject?
  5. **Honest cost** — is `loop-cost.sh`'s exact-vs-floor honest (esp. the agy cost-blind path), and does the loop's spend accounting accumulate correctly into the budget stop?
  6. **Shell hygiene / portability** — `set -u` safety, quoting (paths with spaces), bash 3.2 portability (no `mapfile`/`${x,,}`), `eval` of `--build-cmd`/`--oracle-cmd`/`--measure-cmd` (injection/robustness), and any `/usr/bin/grep` vs RTK-`grep` issues.
  Grade `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]` with a concrete fix each; set a Verdict.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
