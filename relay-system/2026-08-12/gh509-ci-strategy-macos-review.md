# RELAY · GH-509 CI strategy replanned on the macOS-target reframe
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-12.
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
