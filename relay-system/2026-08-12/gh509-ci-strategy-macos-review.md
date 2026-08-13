# RELAY · GH-509 CI strategy replanned on the macOS-target reframe
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-12.
-->

NEXT: claude-a
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh509-ci-strategy-macos-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-509-CI-MINUTE-BURN.md` (committed at `5a510d20`)
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-08-12
- Definition of Done: the plan is a *meaningful improvement*, not ceremony — every section either
  changes cost, changes safety, or changes what a human actually reads. Grade it against the product
  reframe and the four operator goals below.

## Context you need — the product reframe

**XYZ is a local developer toolkit for macOS developers.** It is not a web service running on Linux
boxes. Linux and Windows support are on the roadmap and are *not here yet*; the Mac market is the
target market today.

This reframe arrived after the plan had already been adjudicated between two models (Claude + Codex,
agent2agent #987467, four turns, closed), and it **overturned conclusions both models had agreed on**:

- A recorded cross-release blocker dissolved — `registry-lock-concurrency.sh` is skipped as flaky, but
  its own comment says *"passes locally"*; it fails only under contended Linux CI, a machine no user
  will ever have. Local `validate.sh` is 190/190 including it.
- A whole "prove the hosted route equals `validate.sh`" phase collapsed — on macOS the boundary job
  just runs `validate.sh` with no skips, so there is no second list to keep honest.
- A shared argument against local gates was withdrawn — it held only while Linux was the reference,
  and the developer's Mac *is* the shipping platform.

Two models concurring is not evidence when they share a false premise. **Assume this plan may still
carry premises that have not been tested.** Finding one is worth more than a clean bill of health.

## The operator's four goals

1. Faster hosted CI, for cost and for timely review.
2. More strategic use of hosted CI.
3. Smarter use of CI generally — every trigger has a stated purpose.
4. Use local tests at gates and checkpoints.

## What the reviewer is specifically asked to attack

- **Is it ceremony?** The operator asked directly whether this is a meaningful improvement or ritual.
  Name any section that changes no cost, no safety, and no human behaviour. Deleting a section is a
  valid, welcome finding.
- **Does the promotion rule actually work?** §6 permits a *locally recorded* macOS result to qualify a
  commit. §5 admits that record is self-reported. Is that circular, and if so where does it break?
- **Is the advisory-Ubuntu decision stable?** A canary whose red is never breakage may simply be
  ignored into uselessness — the plan claims stripping it to advisory prevents this. Test the claim.
- **Is the macOS boundary trigger set right?** `main` + `workflow_dispatch` only, no macOS on PRs.
- **Anything the reframe should have deleted and did not.** The reframe removed three things; a fourth
  is likelier than zero.

Numbers, file:line citations and the plan's own quoted text are the currency here. The plan asserts a
~10× macOS runner multiplier and a ~60-run measurement; challenge either if it looks wrong.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

**Reviewer (agy):**
- **swept file: yes**
- `[Blocker]` **Circular promotion rule.** §6 permits a locally recorded result to qualify a commit for promotion ("hosted, or locally recorded per §5.1"). However, §5 admits this record is self-reported. If a local record satisfies the promotion rule, the hosted macOS gate is optional and can be bypassed entirely. The boundary exists to demand clean, independent evidence, but §6 accepts self-reported evidence in its place.
  *Fix:* Revise §6 to require a hosted macOS run (via `workflow_dispatch` or `main` push) for promotion. Local records can be sufficient for PRs/`development` but not for the final boundary.
- `[Should]` **Preserving per-SHA evidence for an advisory job is ceremony.** §4 designs a complex, route-scoped concurrency model (and Phase 3 implements it) costing +60 billed min/day to prevent a `docs` push from cancelling a `full` push. But §1 explicitly stripped the Ubuntu run (which is what runs on `development` pushes) to advisory-only. If it never gates, preserving its per-SHA evidence at extra cost is ceremony. The reframe should have deleted this.
  *Fix:* Delete the route-scoped concurrency complexity in §4 and Phase 3. Let pushes cancel each other as they do today, since they are only advisory canaries.
- `[Should]` **Advisory-Ubuntu decision stability is flawed.** §1 claims stripping Linux CI to advisory prevents it from being ignored. This is sociologically backward: non-blocking advisory jobs are *more* likely to be ignored into uselessness because developers are not forced to look at them.
  *Fix:* Define a mechanism in §1 for how "portability drift" is actioned (e.g., must be fixed before the next release), or delete the Ubuntu canary entirely.
- `[Pass]` **macOS boundary trigger is set right.** §2 correctly limits macOS hosted runs to `main` and `workflow_dispatch` ("macOS boundary job | main + workflow_dispatch"), and PRs get no macOS by default, successfully avoiding the 10x cost multiplier on routine PRs.

**Verdict:** Changes requested.
*handing off to Producer — go to the claude-a window and say 'take your turn'*

**Producer (claude-a) — round 1 dispositions:**
- `[Blocker]` circular promotion rule — **Implemented.** §6 now requires a green *hosted* macOS run (`main` push or `workflow_dispatch`). The "or locally recorded" clause is gone. The finding is exactly right: if self-reported evidence satisfies the boundary, the boundary buys nothing, and the whole point of the rare 10x run is a clean machine plus evidence not produced by the claimant. Local records stay first-class for everything short of promotion.
- `[Should]` per-SHA evidence for an advisory job is ceremony — **Implemented, and this is the best finding of the review.** §4 and its route-scoped job-level concurrency are deleted, along with the classifier-job split and the +60 billed min/day it cost. The cancellation defect was real when it was found, because the plan then still treated `development` full runs as meaningful; the reframe removed the meaning and the fix outlived its reason. Also verified the one thing that *does* need protection is already protected: `push` and `workflow_dispatch` are distinct `github.event_name` values and the existing group keys on it, so a push cannot cancel a macOS boundary run. Kept only as a hazard note for the case where `development` is ever promoted back to gating. Phase 3 is now simpler and cheaper than before the review.
- `[Should]` advisory-Ubuntu justification is sociologically backwards — **Implemented with a modification.** The critique is accepted verbatim: "advisory" describes what a red means and supplies no reason for anyone to read it, and non-blocking jobs are if anything more ignorable. Not accepting the offered fix of deleting the canary, because the operator had already chosen to keep it. Instead the mechanism is named: the canary's status is a line in the promotion output, so it is read at the moment a human is already deciding. Deletion stays on the table with a trigger — if two consecutive promotions ship with drift named and unresolved, the canary has proven it is not actioned and should go.
- `[Pass]` macOS boundary trigger — noted, no change.

Also admitted GH-509 to the Meter (0.6.0) frozen manifest by operator decision, recorded in `RELEASES.md` as a dated re-scope from five entries to six.

*handing off to Reviewer — go to the agy window and say 'take your turn'; every finding has a disposition and the artifact is updated at HEAD.*

**Reviewer (agy) — round 2:**
- **swept file: yes** — no further pre-existing defects found.
- `[Pass]` **Circular promotion rule fixed.** Verified the fix in §6: "No commit is promoted from `development` unless that exact commit has a green *hosted* macOS full result". The circular dependency on self-reported local records is removed.
- `[Pass]` **Concurrency ceremony deleted.** Verified the deletion in §4: "delete the classifier-job split along with its +60 min/day." The route-scoped concurrency has been effectively removed, lowering complexity and cost.
- `[Pass]` **Advisory-Ubuntu justification updated.** Verified the sociological fix in §1: "the canary's status is a line in the promotion output (§7), and a promotion with unresolved drift must name it." This forces humans to look at the advisory job before it is ignored.

**Verdict:** Approved.
*relay closed (Approved), no further turn needed*

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
