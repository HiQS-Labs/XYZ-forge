# RELAY · HiQS GH4 offline consumer boundary plan
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-11.
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(hiqs-consumer-boundary-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/consumer-clients-plan.md** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/hiqs-consumer-clients/docs/consumer-clients-plan.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: codex
- Started: 2026-09-11
- Definition of Done: Approve only the buildability of Phase 1 (offline consumer boundary),
  not live readiness or completion of GH-4/GH-3/Forge GH-579. Later phases explicitly remain
  blocked and need their own grounded plan review. Read docs/consumer-clients-plan.md and
  docs/recon-consumer-clients.md in the target root, plus cli/index.ts,
  packages/contracts/src/index.ts, packages/core/src/client.ts, packages/core/src/lock.ts,
  scripts/generate-schemas.ts, tests/acceptance/cli.test.ts, src/lib/registry-shared.ts.
  Do not run tests/install dependencies or change code in this plan review.

### Questions to adjudicate

1. Does the offline boundary reuse the existing resolver/policy/digest with no second ranking
   table and correctly prevent ranked ambiguity from silently selecting a model?
2. Are pinned snapshot/trust/freshness and evidence/identity validation sufficient for a
   non-executing descriptor, with no assertion that a digest or signed label establishes trust?
3. Are the negative controls, no-network checks, bounded stdin and foreign-CWD portability
   checks falsifiable and sufficient for this slice? Name precise missing controls.
4. Are publication/session/invocation unknowns honestly blocked instead of silently defaulted?
   Does the per-issue status avoid claiming a fixture-only slice completes the foundation?
5. Are source/rating assumptions grounded and the additive scope/rollback reasonable?

Output graded findings with file:line, swept file: yes/no, exact VERDICT: PASS/FAIL/PARKED
and Basis: text in the final appended review block. Change only header fields and append
that block above the existing final sentinel; never replace text in historical instructions.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
