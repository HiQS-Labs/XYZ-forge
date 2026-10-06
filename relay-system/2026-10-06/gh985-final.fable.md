# RELAY · GH-985 Claude continuation final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-06.
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
6. **Commit only the relay file** (`relay(gh-985-claude-continuation-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **skills/2-daily/workhorse/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/2-daily/workhorse/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: Fable   ·   Producer: Producer
- Started: 2026-10-06
- Definition of Done: full source sweep and cited acceptance/evidence review, no unresolved Blocker/Should, truthful runtime limits, PASS/Approved only when satisfied.

Final-review envelope: user-selected Fable low effort, independent of the earlier planner and Agy builder turns. Scope is 11 source additions / 3 deletions on top of parent PR #984 at aedc0726, plus required GH-985 governance and evidence. Read full SKILL.md and stop-hook.sh (not just diff), approved canonical plan and current SUMMARY.md, comparison-final.json, manual-hook-checks-final.json/provenance, final validator outputs and governance identity/route/outputs as needed. Intermediate comparison.json, manual-hook-checks.json and builder logs are historical receipts, not current acceptance. Current source hashes in comparison-final.json and final manual result must match. Do read-only JSON/hash inspection if helpful; do not run suites/gates/operational tests or git commands. Write only this relay; parent/harness owns commits.

Questions: Does guidance preserve the shared evidence/outcome audit, authorized feasible queue, optional/deferred distinction, independent-work-first blocker and pause/window boundaries? Is existing Python AST unchanged except reason and installer/frontmatter preserved? Are Claude Stop/cap/StopFailure/native /goal claims grounded and limits truthful (no semantic or live multi-turn guarantee, no implicit activation/mod/new gate)? Are completed checks current, non-empty, able to fail via witnessed controls; unresolved intermediate findings actually fixed? Does publication target development, declare #984 dependency and incremental comparison with no merge/deploy authorization? Are ratings 65/45/50/85 and scope commensurate? Do not demand unrequested new machinery. Grade concrete observed failures only.

TOKEN CLOSEOUT: For Approved, while still owning GH985-FINAL, call existing tick `done GH985-FINAL --agent Reviewer`; do NOT release/handoff an Approved token. Set NEXT Producer / STATUS Approved, append a nonempty Reviewer block with VERDICT PASS/FAIL/PARKED, Basis, cited sweep. Harness commits and mechanically attests. On non-approval, release to Producer with findings.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
