# RELAY · GH-484 Deploy Skills plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-07.
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
6. **Commit only the relay file** (`relay(gh484-deploy-skills-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-484-DEPLOY-SKILLS.md` and `PROJECT/2-WORKING/GH-484-DEPLOY-SKILLS/recon-deploy-skills.md`. Read the actual committed files in your current isolated worktree, not another local clone or a remembered copy.
- Reviewer: agy   ·   Producer: codex-author
- Started: 2026-09-07
- Definition of Done: Complete, grounded and minimally scoped plan for all user requirements, with safe ownership/backup/recovery contracts and falsifiable per-phase acceptance tests. Textual plan approval only; no implementation claimed.
- Handoff: cli-driven (agy); reviewer writes this relay only, does not commit or push (the containment shim owns commit), and hands token back to codex-author or closes it on approval.

## User requirements — omission-diff source

The distributable skill must let a user talk to their existing VS Code agents/extensions to manage skills. Actual copied skill folders live in Documents/Deployed Skills, with catalog.md, changelog.md, target-folder list and exactly two Python tools (local-repo intake/catalog updater and add/delete directory-symlink sync). User/device agnostic distribution; local private config for this operator. Local sources only initially. ZIP soon-to-be-overwritten skill folders as skillname-yyyy-mm-dd.zip, retaining same-day backups safely. Alpha consumers: VS Code Claude Code, VS Code Codex, Codex app, Antigravity, Zcode GLM. Alpha skills: relay-xyz, consult, marathon-related skills, unstuck (possibly branch before merge), swe, ponytail, recon, daily from rebalanceOS, workhorse, merge-cleanup, start-task, debug-mantra, plus deploy-skills itself. After branch properly QAed and PR on origin, immediately tear down the clone safely. Current checkpoint: write plan and first QA with Agy; no code or live deployment yet.

## Specific questions

1. Perform a dedicated completeness/omission-diff pass: list every requirement above with no equivalent in the plan; report gaps, do not merely summarize. Check the 14-folder alpha and both VS Code conversational consumers.
2. Does actual-folder authority remain unambiguous against metadata/catalog, manual deletion, missing/corrupt state and disabled/removed targets? Are ownership adoption/migration, changed links and empty scans safe and implementable?
3. Are ZIP verification, same-day collision naming, self-update, concurrency and interrupted payload/link/catalog/changelog writes specified enough to implement without an oversized transaction framework?
4. Read cited existing installers, locator and scaffold boundaries. Is the smallest-change/reuse claim supported? Do copied payloads retain their runtime prerequisites without pretending source-relative references are portable?
5. Are per-phase tests falsifiable with negative controls and nonempty evidence? Does final app discovery/dogfood and post-PR immediate safe teardown close the actual user workflow?
6. Is scope appropriately sized for two stdlib Python tools? Are any commitments contradictory, overbuilt, or missing an exact conflict/rollback policy? Check rating neutrality and uncertainty; do not manufacture recurrence claims.

Write a concise Reviewer block with Verdict, Basis (textual only), swept file: yes/no, graded findings with file:line citations, and answers. Do not run the full test suite from your worktree. No external messages or app mutations.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Producer · 2026-09-07
**Did:** Authored issue #484 plan and separate recon map from live source reads, with local intake, archives, ownership sync, alpha and teardown phases.
**Verification:** RELEASES check clean; PDDA frontmatter/status-table/hardcoded-paths/roadmap-coverage zero errors. Separate disposable baseline full gate is in progress; its agy-turn and relay-review-once suites passed, telemetry test gh370 reported a broken-pipe assertion failure. No implementation tests exist yet.
**Review this:** Answer the six questions above; reconcile every requirement with the plan's actual text.
**Open questions:** Current consumer support is explicitly a Phase 3 verification task; do not assert existing candidate path strings prove app support.
**Commit:** committed review inputs; inspect HEAD in your isolated worktree.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
