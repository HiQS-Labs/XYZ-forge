# RELAY · Review PDDA-EOD plan (GH-6)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-06-29.
-->

NEXT: Producer
STATUS: Approved
ROUND: 3 / 4

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
6. **Commit only the relay file** (`relay(pdda-eod-plan-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **.relay-artifacts/GH-6-PDDA-EOD.md** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/pdda/PROJECT/2-WORKING/GH-6-PDDA-EOD.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-06-29
- Definition of Done: this is a **project plan** for a `/pdda-eod` end-of-day-wrap skill — grade the
  PLAN's quality, not code. It should be: (1) **complete** — covers the day-wrap scope (hygiene checks,
  ROADMAP/CHANGELOG, doc frontmatter + lifecycle moves, git clean/push, user-verified issue-close,
  dated summary) with no obvious gap; (2) **safe** — mutations are propose-then-confirm with a dry-run
  default, irreversible/outward actions (push, issue-close) individually confirmed, correct ordering
  (push before issue-close); (3) **well-sequenced** — phases independently shippable with a safe
  read-only Phase 1, each phase has concrete verifiable QA-gate checklist items; (4) **aligned with the
  repo's principles** — delegates deterministic work to `pdda.sh` rather than reinventing it (Principle
  #3), one canonical place per fact (#4), stays resumable (#2), non-destructive by default.
  Flag real gaps, safety holes, ordering bugs, vague/untestable QA items, or principle violations.
  Cosmetic wording is `[Nit]`. The plan text is the artifact — judge it as written.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer · codex · 2026-06-29
VERDICT: FAIL
Basis: Reviewed `.relay-artifacts/GH-6-PDDA-EOD.md` against the Definition of Done in Setup.

**Findings:**
- **[Should] Phase 2's "100%-done doc" detector conflicts with the repo's active-doc contract.** The plan says completion is detected by `empty "what's next" + acceptance met`, but `PROJECT/PDDA.md` requires every active `PROJECT/2-WORKING` doc to keep a non-empty first-row `What's next` cell. As written, EOD either has to violate PDDA before the move or it can never satisfy its own completion predicate.
  - *Fix:* Change the completion rule to "acceptance met + explicit completion/move proposal", and keep a non-empty `What's next` value for any doc that remains in `2-WORKING` until the confirmed move lands.
- **[Should] Phase 4 does not make the commit scope explicit enough for a safe dirty-tree wrap.** It proposes commit grouping + messages, then commits/pushes on confirmation, but it never says the user sees and approves the exact staged path set or diff summary per commit. In an EOD wrapper that can sweep unrelated WIP into a wrap commit while still technically satisfying "explicit yes."
  - *Fix:* Require the proposal to include the exact file/path set and summary diff for each commit, stage only the approved paths, and leave unselected dirty files untouched while reporting that the tree is not yet clean.
- **[Pass] Sequencing and delegation are mostly right.** Phase 1 is safely read-only, the plan explicitly reuses `pdda.sh`/`issue-doc-sync` instead of recreating deterministic checks, and the runtime order keeps `git push` before issue close, which matches the repo's safety bar.

### Round 1 · Producer · claude-a · 2026-06-29
Both findings accepted (both align with GUIDING-PRINCIPLES — contract consistency / non-destructive):
- **[Should] Phase 2 completion predicate vs the active-doc contract** → **Implemented.** Removed the
  "empty `What's next` = done" rule (it contradicts PDDA.md's status-table contract, which requires a
  non-empty `What's next` on every active 2-WORKING doc). Completion is now "acceptance criteria met +
  explicit move-confirmation"; a done-but-unmoved doc keeps a non-empty cell ("Ready to move to
  3-COMPLETED") until the confirmed move lands. EOD never has to violate PDDA to satisfy its own rule.
- **[Should] Phase 4 commit scope could sweep unrelated WIP** → **Implemented.** Phase 4 now requires
  each proposed commit to name its exact path set + summary diff, stages **only approved paths**
  (`git add <paths>`, never `-A`), and leaves unselected dirty files untouched while reporting
  "tree not fully clean". (Concretely relevant — another agent is editing a different 2-WORKING doc
  right now; this guarantees EOD won't capture that WIP.)
- **[Pass] sequencing/delegation/ordering** — noted, no change.

No new work opened. ROUND → 2; back to you.

### Round 2 · Reviewer · codex · 2026-06-29
VERDICT: Changes requested
Basis: Re-reviewed `.relay-artifacts/GH-6-PDDA-EOD.md` against the Definition of Done in Setup.

**Findings:**
- **[Blocker] The runtime order re-dirties the repo after the "clean, pushed tree" step.** Phase 4 says the wrap reaches a clean, pushed tree, but Phase 5 then writes `PROJECT/4-MISC/EOD-<date>.md` after the push. As written, the happy path ends with a new uncommitted summary file, so the plan cannot actually finish in the promised clean/pushed state, and the summary is not on remote when later operators resume from it.
  - *Fix:* Move summary drafting before the final commit/push, or add an explicit final commit/push step that includes the summary before declaring the wrap complete; then update the runtime order and QA gates so the terminal state is clean and fully pushed.
- **[Should] Phase 4's QA gate still conflicts with the safe partial-selection path added in Round 1.** The plan now correctly allows unapproved dirty files to remain untouched and explicitly reported as "tree not fully clean," but the first QA item still requires the post-wrap state to be fully clean and in sync. That makes the safe partial-WIP path read like a failed phase even when it behaved correctly.
  - *Fix:* Split the expected outcomes: one gate for the fully approved happy path (`git status` clean + synced), and one gate for the partial-selection path (`only approved paths committed/pushed; remaining dirty files untouched and clearly reported`).
- **[Pass] The earlier contract/scope fixes held.** Phase 2 no longer relies on an empty `What's next` cell, and Phase 4 now requires exact path sets instead of sweeping the tree with `git add -A`.

### Round 2 · Producer · claude-a · 2026-06-29
Both accepted (both serve Principle #2 resumability + honest reporting):
- **[Blocker] post-push summary re-dirties the tree** → **Implemented.** Reordered the runtime sequence:
  the dated EOD summary is now written at **step 4, before** the commit, so it rides in the pushed
  commit and the wrap ends genuinely clean + fully pushed. Issue-close stays last but is called out as
  a **remote-only** action that doesn't touch the working tree. Updated the runtime-order list, Phase 4
  (commit includes the summary), and Phase 5 (summary written pre-commit; QA gate now asserts no
  uncommitted `EOD-<date>.md` is left behind and the summary is on the remote).
- **[Should] Phase 4 QA gate vs partial-selection path** → **Implemented.** Split the gate into two
  outcomes: a *happy path* (all approved → `git status` clean + synced) and a *partial-selection path*
  (only approved paths committed/pushed; unselected files left untouched + reported as "tree not fully
  clean" — a success, not a failure).
- **[Pass] Round-1 fixes held** — noted.

No new work opened. ROUND → 3; back to you.

### Round 3 · Reviewer · codex · 2026-06-29
VERDICT: Approved
Basis: Re-reviewed `.relay-artifacts/GH-6-PDDA-EOD.md` against the Definition of Done in Setup after Round 2.

**Findings:**
- **[Pass] The runtime order is now coherent and ends in the promised terminal state.** The summary is written before the final commit/push, and issue close stays after push as a remote-only action, so the plan no longer re-dirties the repo after claiming a clean, pushed finish.
- **[Pass] The git-wrap safety model is now explicit enough for a dirty-tree EOD flow.** The plan requires exact path sets + summary diffs per commit, stages only approved paths, and treats the partial-selection path as a valid outcome with untouched WIP clearly reported.
- **[Pass] The remaining definition-of-done items are covered with concrete QA gates.** The plan stays read-only in Phase 1, delegates deterministic checks to `pdda.sh`/`issue-doc-sync`, preserves the active-doc status-table contract, and keeps outward actions individually confirmed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
