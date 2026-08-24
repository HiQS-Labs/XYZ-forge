# RELAY · GH-197 vendor tier-split plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-23.
-->

NEXT: Producer
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
6. **Commit only the relay file** (`relay(gh-197-vendor-tier-split-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-197-VENDOR-TIER-SPLIT.md (plan QA — no code exists yet; review the PLAN, not an implementation)
- Reviewer: commandcode   ·   Producer: claude-a
- Started: 2026-08-23
- Definition of Done: the plan is implementable as written — (1) the deny-list tier mechanism is sound and doesn't reintroduce the GH-77 curated-manifest failure; (2) the migration story keeps all 9 vendored repos safe, incl. the live adopter (LTVera-Pandas), and the auto-detect-over-registry decision is defensible; (3) the onboarding SOP steps faithfully mechanize the LTVera-Pandas ad0d816 reference incl. the shared-tracking-URL refusal; (4) the GH-312 preserve-list constraint is correctly analyzed (overlay state at target ROOT, nothing new under .xyz/); (5) the Swarm Preflight Contract JSON is internally coherent (probes match artifacts_new, lanes don't conflict with the plan's write set); (6) every Acceptance checkbox is falsifiable and covered by a named test; (7) no contradiction with the #105 supersession as documented.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## commandcode (Reviewer) · r1 · 2026-08-24

**Verdict: Approved** — plan is implementable as written. All DoD points checked against the
artifact and the cited code spans in the primary clone.

swept file: yes

**DoD coverage:**
1. Deny-list mechanism — sound. Tier 1 stays a full mirror, overlay paths removed pre-swap; new
   `utils/` files default to shipping, so the GH-77 curated-manifest failure can't recur.
2. Migration — auto-detect-over-registry is defensible: registry write fails open under lock
   contention (`xyz-vendor.sh` run_with_advisory_lock path "update skipped … The vendor still
   succeeds"), so it genuinely cannot be source of truth. `releases.db`-at-root sticky detect keeps
   LTVera-Pandas safe; other 8 have no root state to lose.
3. Onboarding SOP faithfully mechanizes ad0d816 incl. shared-tracking-URL refusal with stop-and-report,
   never auto-filing or committing.
4. GH-312 analysis correct — verified preserve loop at `xyz-vendor.sh` (~L373) preserves only
   target-owned root/`.xyz` runtime state; overlay state lives at target root, nothing new joins it;
   Phase 4 pins the invariant either way.
5. Preflight JSON coherent — fix_probes match artifacts_new exactly; lanes don't collide with the
   plan's write set (`relay-automation/`, `test/`, SKILL.md, README all inside lane bounds).
6. Every acceptance checkbox falsifiable with a named test in Plan step 4. No contradiction with #105
   supersession as documented.

**Findings (none blocking):**
- `[Nit]` "grep sweep: no hits" overstates slightly — `utils/marathon-plan.sh:209` mentions
  `release-lanes.sh` in a comment ("the trunk as the remote declares it (same source
  release-lanes.sh uses)"). Comment-only, no import/call, conclusion stands. Fix: reword to "no
  imports/calls (one comment-only mention)" when editing, or leave as-is.
- `[Nit]` Acceptance line 169 says gate green "in a disposable clone" but doesn't name GH-564's
  separate-full-clone rule explicitly; step 6 does implicitly. Optional: add "(separate full clone,
  not a linked worktree — GH-564)".

Pre-existing defects found by sweep of the artifact itself: none beyond the two Nits above.

Handing off to claude-a (Producer) — relay closed on Approved; no further Producer turn needed unless
the two Nits are worth folding in during Phase 1.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
