# RELAY · GH-1341 plan QA: todo-list + start-task issue closeout
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-04.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 4

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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1341-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **gh1341-plan-qa.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-04

### Artifact — gh1341-plan-qa.md
```
# GH-1341 plan QA packet

Goal: review the PLAN in `PROJECT/2-WORKING/GH-1341-TODO-LIST-CLOSEOUT.md` (read it in full) before
any skill text is written. Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1341 (body + the
2026-11-04 scope-addition comment, both summarised in the plan).

Operational envelope: two Markdown skill instruction files read by a single agent session
(Claude Code / Codex / Cowork / plain chat). No script, helper, test, or gate is being added
(AGENTS.md "No new tests", GH-831). Grade against the stated requirements and commensurate
complexity; do not ask for enterprise machinery, new tooling, or tests.

Files to read:
- PROJECT/2-WORKING/GH-1341-TODO-LIST-CLOSEOUT.md (the plan)
- skills/2-daily/todo-list/SKILL.md (all of it; sections 0-3, note the section 2 wake prompt and section 3 step 4)
- skills/1-hourly/start-task/SKILL.md (Step 9, "Open or update the ready PR and hand off", and the "Skipped independent review" note)
- skills/1-hourly/handsfree/SKILL.md (only to confirm the plan does not change it)
- utils/ci-route.sh around line 336 (full-gate Markdown surfaces)

Questions:
1. Does the plan cover every ask in the issue: trigger points (normal end AND halts), touched-issue
   scope with owner/repo#N, comment content, marker idempotency (edit on rerun), tier behaviour
   (A/B gh + URLs in note, C render in chat), never close/relabel, URLs in final checklist,
   frontmatter description?
2. Is the claim that run end is defined in TWO places (section 3 step 4 and the section 2 wake
   prompt) correct, and are both covered? Any other run-end path missed?
3. Are the gh primitives correct and sufficient (list comments with --paginate and a marker
   match, create via `gh issue comment -R --body-file`, edit via `gh api -X PATCH
   repos/O/R/issues/comments/ID -F body=@F`)? Any quoting/encoding trap worth one line in the skill?
4. Start-task reuse: is "defined once in todo-list section 4, start-task Step 9 names its own marker
   and timing" a sound DRY split, or should the canonical text live in start-task instead? Is the
   nested-run rule (todo-list skips an issue already closed out by a nested start-task in the same run)
   correct and sufficient to avoid double comments?
5. Is the gate route right (docs -> `utils/pdda/pdda.sh run`; neither file is a full-gate surface)?
6. Is the smoke check (read-only marker lookup on #1341: empty -> create branch; after a closeout
   exists -> edit branch) adequate for a docs-only change? Anything over- or under-built?
7. Is the rating 55/35/50/90 (pri/sev/appeal/effort) grounded? appeal must stay 50 (neutral).

Flag anything wrong, missing, mis-scoped or over-engineered, with file:line citations. Set STATUS
Approved if the plan is fit to implement.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The scope and shared procedure fit the issue; two small instruction gaps need correction before implementation. No new tooling or tests requested.
swept file: yes

- [Should] Make the start-task next step conditional. `PROJECT/2-WORKING/GH-1341-TODO-LIST-CLOSEOUT.md:78-82` applies the body to both ready PRs and blocked/deferred groups but fixes the next step to "awaiting merge". That is false for a group stopped at plan QA with no PR. Use awaiting merge only for a verified ready PR; otherwise state the actual blocker/decision and resumption action. Ensure early stops invoke this closeout before handoff rather than depending on reaching Step 9 normally.
  Observed input: Plan lines 78-81 explicitly include "when a group ends blocked/deferred" and "next step: awaiting merge"; start-task lines 211-214 explicitly stop implementation when plan review is unavailable or unresolved.
  Affected scope: Tracked start-task groups ending blocked/deferred before a ready PR exists.
  Falsifier: Walk a group stopped at Step 6 with no PR through the proposed instructions; a closeout naming the actual review blocker and resume action, without claiming awaiting merge, disproves the concern.

- [Should] Add one failure rule to the shared gh procedure: only a successful, fully paginated lookup with no exact marker match permits creation; failed lookup/post/edit must be reported as unposted/unknown, with rendered text retained for paste or retry. Do not claim a URL or blindly retry a possibly completed write. The plan currently defines only found/absent and a Tier B fallback (`PROJECT/2-WORKING/GH-1341-TODO-LIST-CLOSEOUT.md:68-71`).
  Observed input: Read-only probe `gh issue view 1341 -R HiQS-Labs/XYZ-forge --json body,comments` exited 1 with "error connecting to api.github.com"; a subsequent `gh api repos/HiQS-Labs/XYZ-forge/issues/1341/comments --paginate` exited 0 with one non-closeout scope-addition comment. An unavailable lookup is an observed, distinct state from an absent marker.
  Affected scope: A/B closeout operations when gh fails or a write outcome is uncertain.
  Falsifier: A manual instruction walk with lookup exit 1 must produce no create attempt and an explicit unposted/unknown result; successful lookup with no matching marker must still select create.

- [Pass] Both todo-list run-end definitions are covered: source `skills/2-daily/todo-list/SKILL.md:92-99` and `:121-124`; plan `:59-60` targets both. The asynchronous turn yield at source `:116-120` is a wait, not run completion. Preserve the wake prompt's user-stop case when editing. No additional independent run-end definition found in the full todo-list file.
- [Pass] Plan `:62-76` covers qualified issue scope, no-issue outcome, factual content/evidence, per-run markers, tier behavior, URL reporting, description and no lifecycle mutations. Canonical todo-list section 4 plus start-task-specific timing/marker is the requested DRY split; the issue's scope-addition comment explicitly requires skipping the second nested comment (issue comment 6638233042, read via the paginated API probe above). Keep "same run" qualification from plan `:74-75` when implementing.
- [Pass] Local `gh api --help` (exit 0) states that `-F` values beginning with `@` read a file and that pagination fetches successive pages; `gh issue comment --help` (exit 0) exposes `--body-file` and `-R`. These support plan `:46-49`. Quote filenames/arguments and match the marker as literal text; do not use `--edit-last`, which can target an unrelated comment. Live create/PATCH execution remains unverified and was not attempted.
- [Pass] Docs routing is correct for these two files: `utils/ci-route.sh:63-65` recognizes Markdown; `:336-343` escalates merge-cleanup, relay-automation and relay-xyz, not todo-list/start-task. Plan `:83` overstates "only ... merge-cleanup"; remove "only" or qualify it to these candidates.
- [Nit] The docs consumer read and read-only absent/present marker selection are proportionate (`plan:88-92`), but label the empty lookup a negative case, not proof that a check can fail. Record nonempty successful response plus exit status and the exact matched marker/ID for the present case; retain provenance as required. No clone suite was run in this turn.
- [Nit] `55/35/50/90` is plausible for a small instruction change, but plan `:21` records only numbers. Add one brief rationale for priority above severity and high cheapness; unknown recurrence stays unknown. Appeal 50 follows `skills/1-hourly/start-task/SKILL.md:360` and must remain neutral.

Whole-file sweep: read the entire plan and todo-list source, start-task source including skipped-review and blocked paths, handsfree, and the classifier excerpts. No further pre-existing defect requiring expansion of this task found. The issue body was independently read with `gh api repos/HiQS-Labs/XYZ-forge/issues/1341 --jq .body` (exit 0); it agrees with the packet's requirements. This is plan QA, not implementation or gate approval.

Handing off to Producer (claude-a) — address the two Should findings, disposition the notes, then return for review.

### Producer · Round 2

Dispositions (plan updated in `PROJECT/2-WORKING/GH-1341-TODO-LIST-CLOSEOUT.md`):

- [Should] conditional start-task next step — **Implemented.** Plan item 4: "awaiting merge" only for a verified ready PR; an earlier stop (plan QA unresolved, blocked gate, deferred) states its blocker and resume action, and the closeout runs at that stop, not only on reaching Step 9.
- [Should] gh failure rule — **Implemented.** Plan item 2 idempotency bullet: only a successful, fully paginated lookup with no literal match permits create; a failed lookup/post/edit is reported `unposted` (or `unknown` when a write may have landed), text kept for paste/rerun, no URL claimed, no blind retry.
- [Pass] wake prompt user-stop case — **Noted**; the edit keeps it.
- [Pass] "only merge-cleanup" overstatement — **Implemented**; now cites `utils/ci-route.sh:336-343` (merge-cleanup, relay-automation, relay-xyz).
- [Nit] smoke labelling — **Implemented**; empty lookup is a negative case, exit status and matched marker/ID recorded, failed lookup must select `unposted`.
- [Nit] rating rationale — **Implemented**; `## Rating` section added, appeal stays 50, recurrence unknown.
- [Pass] avoid `--edit-last`, literal marker match, quote paths — **Noted** for the skill text.

Handing off to Reviewer (codex) — re-review the updated plan.

### Reviewer · Round 2

VERDICT: PASS
Basis: The revised plan is fit to implement within the two-skill Markdown envelope. Both required findings are resolved; no remaining Blocker or Should findings.
swept file: yes

- [Pass] Early blocked/deferred groups now close out at the actual stop, with the actual blocker and resume action; “awaiting merge” is restricted to verified ready PRs (`PROJECT/2-WORKING/GH-1341-TODO-LIST-CLOSEOUT.md:87-95`). This covers the pre-Step-9 stop in `skills/1-hourly/start-task/SKILL.md:211-214` without changing the skipped-independent-review policy.
- [Pass] Failed lookup and uncertain writes are distinguished from absence: only successful fully paginated lookup with no literal match permits create; text is retained and no URL or blind retry is claimed (`PROJECT/2-WORKING/GH-1341-TODO-LIST-CLOSEOUT.md:75-78`). A walk of lookup exit 1 therefore selects unposted, while successful absence still selects create.
- [Pass] Full-plan sweep retains both end triggers, qualified issue scope, factual body, per-run idempotency, tier fallback, final URLs, nested same-run suppression, description update and no lifecycle changes (`PROJECT/2-WORKING/GH-1341-TODO-LIST-CLOSEOUT.md:66-96`). Both existing todo-list end paths remain at `skills/2-daily/todo-list/SKILL.md:92-99` and `:121-124`; the asynchronous yield at `:116-120` remains a wait. Keep the explicitly noted literal matching, quoted arguments and avoidance of `--edit-last` during implementation.
- [Pass] The revised smoke specification records lookup status and marker/ID and distinguishes an absent-marker negative case from lookup failure (`PROJECT/2-WORKING/GH-1341-TODO-LIST-CLOSEOUT.md:99-106`). The rating now has a bounded rationale with neutral appeal and unknown trend (`:23-28`). Neither todo-list nor start-task is in the full-gate exceptions shown in `utils/ci-route.sh:336-343`.

Whole-file sweep: reread the entire revised plan and todo-list/start-task sources, plus handsfree and the classifier excerpts. No additional pre-existing defect requiring scope expansion found. This turn used source inspection and instruction walks only; no executable fixtures, suites, live create/PATCH, or implementation gate ran. Plan approval does not attest implementation or publication.

Relay closed (Approved), no further turn needed. Producer may implement the approved plan.


### Attestation · relay-drive — 2026-11-04T18:11:07Z
task: RELAY-gh1341-plan-qa
reviewer: codex
status: Approved
reviewed-head: 8b38d189b3ebb1f6cc03b1a7e4d61513feeec20b
added-range: 14985+2377
added-sha256: 50f545f7490a0bedd3660bd96657cd5d25a8d73b4717115cc9f98e2c5b7e0522
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
