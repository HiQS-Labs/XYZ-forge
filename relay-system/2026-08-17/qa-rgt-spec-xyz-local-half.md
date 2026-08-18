# RELAY · QA rgt spec (xyz local half)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-17.
-->

NEXT: Producer
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
6. **Commit only the relay file** (`relay(qa-rgt-spec-xyz-local-half): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/rgt-spec-xyz-local.md** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/XYZ-forge/temp/rgt-spec-xyz-local.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-08-17
- Definition of Done: the artifact is a **spec for the local execution half** of the `rgt:` adoption
  in THIS repo (pairs with upstream Hypercart-Dev-Tools/pdda#63). The Reviewer grades it against:
  1. **Grounded** — claims about THIS repo are checkable in-tree: `skills/radar/SKILL.md` Lens 1
     (bucket table, `0% (rgt: adoption: N docs)` form, named malformed-prefix families), `AGENTS.md`
     commit rails, `PROJECT/PDDA.md` + `utils/pdda/` vendored-copy status, and the carried decision
     record in HiQS-Suite/XYZ-forge#26. Flag any anchor that is wrong or unverifiable.
  2. **Complete & consistent** — every work item has an owner-ready acceptance state; no internal
     contradictions (e.g. blocked vs unblocked items clearly separated); the split of upstream vs
     local work matches jediwright's direction quoted in #26.
  3. **Testable** — each acceptance checkbox is objectively decidable (a command, diff, or observed
     output settles it), including the negative control on work item 1.
  4. **Scoped** — no scope creep: no redesign of radar, no contract edits done locally, no retroactive
     tagging of docs that do not exist here.
  5. **Implementable cold** — an agent that has never seen this conversation could execute each work
     item from the spec alone.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · round 1

swept file: yes

- [Blocker] Work item 1 is not cold-executable or safely testable: “sync … (`PDDA-SOURCE.md` mechanism)” supplies neither the source revision/operation nor the required deletion-inventory and local-sign-off review. That omission conflicts with the dependency-sync policy at `PROJECT/PDDA-SYNC-POLICY.md:16-33`; the current `pdda.sh frontmatter` dispatcher also gives no `rgt:` check yet (`utils/pdda/pdda.sh:35-104`). Fix: name the exact upstream #63 revision and vendor-sync procedure, require the policy’s deletion inventory/classification/sign-off, and give concrete valid/absent/invalid fixture inputs plus command, expected exit status, and recorded rejection text.
- [Blocker] Work item 2’s positive control is false as written: a doc with any valid `rgt:` can be `run` or `grow`, while Transform is only enabled by `rgt: transform` (`.relay-artifacts/rgt-spec-xyz-local.md:24-26`; `skills/radar/SKILL.md:63-65`). Fix: require a governing doc with `rgt: transform` for the `Transform > 0` observation, and separately state the expected Run/Grow outcomes for those valid values without retroactively tagging existing docs.
- [Blocker] Work item 4 leaves the local issue permanently uncloseable and subjective: “next genuinely direction-changing effort” has no decision rule, owner, or observable acceptance state (`.relay-artifacts/rgt-spec-xyz-local.md:49-55`). Fix: define who classifies a qualifying effort and when; either make its future frontmatter a tracked follow-on (not this issue’s acceptance) or specify a concrete already-authorized governing document and an exact `rgt:` value.
- [Should] The proposed commit-convention location is not a currently named “commit-rails bullet” in `AGENTS.md`; the nearby authoritative rails identify `ROUTER.md` for command rails and `AGENTS.md` for behavioral playbook (`AGENTS.md:19-25`, `AGENTS.md:107-116`). Fix: name the new subsection/bullet precisely and add an objective check for both the new `GH-NNN:` malformed-prefix detection and the allowed trailing/trailer forms.
- [Pass] The pre-existing radar-consumption statements are grounded: its Run/Grow overrides, Transform-only gate, and required zero-adoption format appear in `skills/radar/SKILL.md:63-68`; no other pre-existing defect was found in the artifact on this whole-file sweep.

Verdict: Changes requested

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
