---
gh_issue: 528
source: https://github.com/HiQS-Labs/XYZ-forge/issues/528
title: "/unstuck — queue simultaneous blockers, tripwire recurring blocker classes"
status: Active (2-WORKING — captured + promoted 2026-09-09, execution same session)
created: 2026-09-09
updated: 2026-09-09
owner: noelsaw1
doc_type: plan
rating: "pri/sev/appeal/effort 60/20/50/100 · calc 230"
fix_probes:
  - grep -c "\*\*queued\*\*, not parked" skills/unstuck/SKILL.md
  - grep -c "Recurrence tripwire" skills/unstuck/SKILL.md
  - grep -c "^Queued:" skills/unstuck/SKILL.md
goal: >
  Close #528's two routing gaps in /unstuck with three surgical text edits, without
  adding engineering machinery to the interrupt: genuine-but-simultaneous blockers get
  a queued-not-parked disposition with a durable intake home, and a recurring blocker
  class trips a handoff to /workhorse instead of another narrow fix.
---

# GH-528 — /unstuck: queued blockers + recurrence tripwire

## Observed problem (recon, 2026-09-09)

Session evidence from a merge-cleanup run (PR #495 + `releases roadmap reconcile-state`
blockers, operator transcript 2026-09-09 13:35):

1. **Blocker fan.** Four genuine blockers surfaced at once. `/unstuck` Rung 3 classifies
   blockers individually but has no disposition for *real* blockers that are not on the
   critical path — "Park it" is scoped to cogs/polish. The operator had to enforce
   "focus on issue 1 only. Do NOT bring up anything else" manually, then separately
   instruct "always automatically file new GH issues."
2. **Recurring class.** A second mismatch-CLI-writer gap in the GH-424 class appeared.
   Rung 4's "fix one narrow, evidenced blocker" re-prescribes symptom relief for a class
   already narrowly fixed once; the operator had to demand the root-cause path by hand.

Base: `origin/development` @ 8445240e. Artifacts read: `skills/unstuck/SKILL.md`
(GH-473, ca8645c2), `skills/workhorse/SKILL.md` (ladder + escape hatches), live session
transcript. Workhorse already defines the workhorse→unstuck→return edge; the reverse
escalation edge is the missing half.

## Plan (surgical, routing-only)

One file: `skills/unstuck/SKILL.md`. Three edits, +13 lines total:

1. **Rung 3 (blocker fan):** rank simultaneous genuine blockers by critical path, act on
   the first, route the rest to existing durable intake (issue tracker/queue/ledger,
   never a new artifact). **queued ≠ parked** — queued is real outstanding work with a
   recorded home.
2. **Rung 4 (recurrence tripwire):** second occurrence of the same blocker *class*
   ⇒ hand the thread to `/workhorse` for the durable root-cause fix, or file the gap and
   take the bounded bridge once, labeled a bridge not a fix.
3. **Rung 5 (receipt):** add `Queued:` line mirroring `Parked:`.

## Non-goals

- No root-cause engineering, verification suites, or preservation gates inside unstuck
  (workhorse's ladder owns those).
- No trigger/description changes — firing conditions unchanged; the routing boundary
  stays as fenced.

## Rating rationale

- **sev 20** — process/skill-contract gap; cost is operator intervention and repeated
  symptom relief, not data loss or breakage. One concrete incident (2026-09-09) with a
  same-class antecedent (GH-424 family); trend unknown, not zero.
- **pri 60** — severity-led ordering would rank this lower; departure is the operator's
  same-session request. Recorded per the rating policy.
- **appeal 50** — neutral; no user score supplied.
- **effort 100** — 13-line doc diff, pre-drafted and already deployed via Skills Army
  this session; pure review/landing cost remains.

## Acceptance checks

- `grep -c "\*\*queued\*\*, not parked" skills/unstuck/SKILL.md` → 1
- `grep -c "Recurrence tripwire" skills/unstuck/SKILL.md` → 1
- `grep -c "^Queued:" skills/unstuck/SKILL.md` → 1 (receipt block)
- **Red control:** all three greps return 0 against `origin/development`'s version of the
  file (strings are new in this change — verified against ca8645c2).
- agy relay review of the committed diff returns **Approved** (reviewer named by
  operator, overriding the default Codex plan-QA reviewer; final-QA stage carries it).

## Deployment + risks

- Skills Army deployment already performed this session (source re-pointed to the
  maintained primary clone, deployed copy updated, all five IDE targets verified
  read-through). This PR lands the repo-side source so the deployed digest and the
  repo stay reconciled after merge.
- Reversibility: **Easy** — text revert of one file, plus `backups/unstuck-2026-09-09.zip`
  retained by the Skills Army manager.
