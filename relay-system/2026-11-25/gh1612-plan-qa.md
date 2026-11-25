# RELAY · GH-1612 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
-->

NEXT: Producer
STATUS: Approved
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
     change MUST carry `Observed input:`, `Affected scope:` (the input predicate the change would govern),
     and `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected
     result). `Observed input:` accepts two strict, non-speculative forms:
     (1) **Form 1 (observed failure or artifact contradiction):** a failing probe/gate output, or a concrete
     `fileA:line` vs `fileB:line` contradiction (e.g. IAM SA mismatch, inverted test, sibling guard omission);
     (2) **Form 2 (unrunnable runtime hazard trace):** permitted ONLY when reproduction requires an external
     service, multi-process concurrency, or a browser/container runtime forbidden in the relay worktree —
     must supply a hop-by-hop `file:line` trace plus an exact `Clone probe:` command/script for the Producer's
     disposable full clone. Default severity for an unexecuted Form 2 hazard is `[Should]`.
     A `[Blocker]` must cite an observed failure (Form 1); an unexecuted Form 2 hazard stays `[Should]`
     until a probe reproduces it, and remains pending probe verification until the Producer runs
     `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, read the probe before running it — refuse any probe that reaches
     the network, credentials, or paths outside the disposable clone and record the refusal as
     `[Unverified — clone probe failed/unavailable]` — then execute safe probes in a disposable full clone and
     record one of three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output;
     (b) Falsified → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored, refused, or
     environment unavailable → keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking
     `STATUS: Approved` until re-run cleanly or escalated/parked). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh-1612-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1612-YESTERDAY-TODAY-RUN-SHEET.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1612-YESTERDAY-TODAY-RUN-SHEET.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-25
- Operational envelope: an instruction-only skill edit (one existing `SKILL.md`, about 25 added lines, no scripts) that an agent follows on one operator's machine. XYZ-forge forbids new tests (`AGENTS.md` "No new tests", GH-831). Grade against the stated requirements and commensurate complexity; do not ask for scripts, templates, a new suite or a new skill.
- Operator decisions already made (do not reopen): the change is an addition to the existing `yesterday-today` skill; about 20-30 added lines; file under about 140 lines; repo-agnostic wording with fictional or generic examples only; the seven lessons in the plan's Requirement section are the operator's own list.
- Definition of Done: the plan is grounded in the cited paths, each of the seven lessons is carried by the draft wording and nothing contradicts them, the size budget is achievable, and each acceptance item would fail on base `b479f74e0`.

### Step A: paraphrase first (GH-1414). Do this BEFORE reading anything else.
Read ONLY the plan doc's frontmatter `non_goals`, `goal`, `## Status`, `## Requirement`, `## Recon`, `## Preflight bet`, `## Plan`, `## Draft wording`, `## Acceptance`, `## Verification` and `## Risks`. Do not open source files or the issue yet. At the top of your review block write:
- **What this proposes** (2-5 sentences)
- **How the existing system works, per this document** (2-5 sentences)
- **What it's not** (short; ground exclusions in the doc's sections, label inference)
- **Input boundary:** the sections you had read when you wrote the paraphrase.

### Step B: source-backed technical validation
Now read the issue (https://github.com/HiQS-Labs/XYZ-forge/issues/1612) and `skills/2-daily/yesterday-today/SKILL.md` in full, and label this assessment **source-backed**. Answer each with `file:line` evidence:

1. Does the draft carry each of the seven lessons, briefly and generically, and does the sheet's row shape (step, owner, time, method, pass, stop) match the operator's wording? Is any lesson merged away, softened or contradicted?
2. Is step 5a the right insertion point given steps 1-9 as they are (the sheet needs the PR facts from step 5, the body write is step 7, the validator is step 8)? Does keeping steps 6-9 unnumbered-changed break any cross-reference in the file?
3. Does the draft stay a plan and not an approval, consistent with the skill's own opening paragraph and its "never writes to a server" rule? Is "read-only by default / explicit per-action approval / backups first" faithful to the operator's rule?
4. Is the size budget achievable (about 20-30 added lines, file under about 140; the skill is 107 lines now) without trimming meaning?
5. Does the draft avoid restating a deploy procedure, and avoid any client, product, company, people, host name or private link?
6. What prevents an unchanged base from passing each acceptance item A1-A6, and is each red control the right observation? Is the smoke plan (A4), a read-only dry run on two fictional ledgers from the consumer entry point, a real exercise of the new step on both a deploy day and a no-deploy day?
7. Is anything here more machinery than the problem needs, or is a required case missing?

Write graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), then a VERDICT. Set STATUS to Approved only if no `[Blocker]` or `[Should]` remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

**What this proposes**  
Add a short deploy-day run sheet to the existing morning ledger refresh. Put it first in today's ledger, put gates first in the sheet, and give each step an owner, time, method, pass evidence and stop condition. Turn incomplete gates into morning questions and skip the sheet on days without a deploy.

**How the existing system works, per this document**  
The skill gathers current PR facts at step 5, writes today's body at step 7 and checks it at step 8. The plan inserts the run sheet after PR collection and uses the repository's existing deploy docs for procedures.

**What it's not**  
The non-goals exclude a new skill or helper, a deploy procedure, execution, approval, scheduling, server access and skill installation.

**Input boundary**  
Artifact frontmatter `non_goals` and `goal`, Status, Requirement, Recon, Preflight bet, Plan, Draft wording, Acceptance, Verification and Risks. Paraphrase written before opening the base skill or issue.

**Source-backed assessment**  
Read [GH-1612](https://github.com/HiQS-Labs/XYZ-forge/issues/1612) in full and swept the base skill from frontmatter through step 9. The seeded plan is absent from the main checkout's graph index, so the review cites the relay worktree files directly.

swept file: yes

- [Pass] The six columns and deploy/no-deploy trigger match GH-1612 §1 and the plan's draft at `.relay-artifacts/GH-1612-YESTERDAY-TODAY-RUN-SHEET.md:82-90`. All seven lessons have corresponding text at lines 92–106: incomplete gates and late follow-up (92–94), real code and environment plus stale checklists (95–97), access and fallback (98), positive evidence (99–100), timer and rehearsal (101–102), review history and acceptance (103–104), and read-only planning with per-action approval and backups (105–106). The draft's staging and query examples are generic, and lines 85–86 route procedures to the repo's own docs.
- [Pass] Step 5a belongs after PR fact collection and before ordering. Step 5 supplies past reviews and current requests, step 6 classifies, step 7 drafts and publishes, and step 8 validates the published body independently (`skills/2-daily/yesterday-today/SKILL.md:60-98`). Keeping 6–9 numbered as they are preserves the existing step-7 reference at line 20. I found no separate defect in the existing skill relevant to this edit.
- [Pass] The budget allows the draft and its two small integrations without trimming. `wc -l skills/2-daily/yesterday-today/SKILL.md` → exit 0, `107`; `awk 'NR>=82 && NR<=106 {n++} END{print "step 5a draft lines:", n}' .relay-artifacts/GH-1612-YESTERDAY-TODAY-RUN-SHEET.md` → exit 0, `step 5a draft lines: 25`. With a heading separator and the step-7/8 additions, the result lands around 135. The one-skill design and existing validator cover the requested scope (`.relay-artifacts/GH-1612-YESTERDAY-TODAY-RUN-SHEET.md:66-76,109`).
- [Should] State how to verify a proposed step within the morning skill's authority. **Observed input:** Draft lines 95–98 say “Test each step against the real code and the target environment” and offer reading the staging host's recorded commit, while the plan's non-goals at line 18 and GH-1612 §2 exclude server access. The base skill forbids testing and server writes at `skills/2-daily/yesterday-today/SKILL.md:18-23` and marks production/VM reads “not checked” at lines 49–52. Draft lines 105–106 also need to make clear that the per-action approval and backups describe a later operator-authorized action. **Affected scope:** Gates whose compatibility, access or rehearsal requires an environment operation beyond the skill's permitted reads. **Falsifier:** A draft using repository and recorded deployment evidence validates a staging-only change when the deployed revision is recorded in GitHub, and raises a question when only a host read or execution could establish it. Both cases leave the morning skill read-only except for its existing guarded ledger publish. Make those boundaries explicit while preserving the early rehearsal as a planned step.
- [Should] Connect step 5a to the same today's-body snapshot used by step 7. **Observed input:** Draft lines 84–85 trigger even when the deploy appears only in today's body, but base steps 1–2 describe issue resolution and reading yesterday (`skills/2-daily/yesterday-today/SKILL.md:25-41`), and step 7 owns the first successful today's-body read and guarded redraft (73–81). The proposed step-7 clause at draft line 109 only changes placement. **Affected scope:** Today's-only deploy intent or checklist link, including intent added or removed while drafting. **Falsifier:** With yesterday silent and today's baseline linking a deploy planned today, draft one sheet from that snapshot. If the guarded reread replaces it with a body canceling the deploy, the regenerated draft omits the sheet. State that 5a uses the first successful today's-body read as the step-7 baseline and recomputes on guarded redraft. Keep the existing lookup stops and header preservation.
- [Should] Make the acceptance observations distinguish a working change from the base and give each safeguard its own negative case. **Observed input:** The blanket base-fail claim at plan line 113 conflicts with A3 and A5 at lines 117–119: an empty base diff is inside the allowlist, and a clean base can pass a privacy scan. The plan A3 also includes the plan file in a people-name scan even though its required owner field names a person (line 6). A4 at line 118 checks an ownerless gate and presence of a sheet but omits the six columns and first placement requested in GH-1612 §§1, 3. A6 at line 120 can only establish delivery against actual PR metadata and an applicable receipt. **Affected scope:** The manual acceptance checks in plan lines 113–120. **Falsifier:** The same recorded checks reject missing content, a planted privacy token, an out-of-scope path, a bad deploy draft and absent or wrong delivery evidence for their respective reasons. Keep the checks manual and specify:
  - **A1–A2:** The base lacks 5a and validator item 6, and the insertion has zero added lines. A1's missing lesson mutation is a suitable second control. Measure the actual diff for the 20–30 added lines and confirm unchanged step numbering.
  - **A3:** Run the same matcher on the feature prose and evidence with a fictional prohibited token as the red control. Distinguish project metadata such as the required owner field from the generic skill and evidence examples.
  - **A4:** Load the skill from its checkout entry point, run the same fictional inputs through drafting and capture the entire proposed ledger body without publishing. The deploy case needs a complete gate plus an incomplete one, and must place exactly one six-column sheet first with gates first, the incomplete gate asked as a question and the existing goal header intact. Let the no-deploy case assert zero run-sheet output. Replay the base on the same deploy input and witness the missing sheet. Inspect the action log for no external writes or deploy operations and check checkout state separately. A hand-composed table or a standalone reading of step 5a would leave the real entry point and body assembly unexercised.
  - **A5–A6:** Exercise A5 on an out-of-scope path and require the intended skill diff to be present. For A6 require a receipt for the delivered revision and the opened PR's actual base. Missing receipt and wrong-base metadata are the negative cases. State which feature checks fail on base and which safeguards use controlled bad input (`GUIDING-PRINCIPLES.md:104`).
- [Nit] Call `ci-local.sh --fast` a local check in Verification. It skips the suite and doesn't retain a qualifying gate record (`ci-local.sh:399-409,427-437`). The final pre-push route still depends on the actual changed paths (`utils/ci-route.sh:305-318,336-348`).

**VERDICT: FAIL**  
**Basis:** The compact plan fits the request, but the draft needs an explicit read-only evidence boundary, a baseline and redraft link for today's deploy intent, and acceptance observations that can catch a failed change. This was plan QA. Implementation smoke and gate execution are pending the Producer's revised plan and later implementation.

Handoff to Producer (claude-a) for disposition and a revised plan.

### Producer · Round 1

Dispositions (each checked against the cited lines of the base skill before acting):

- [Should] Read-only evidence boundary: **Implemented.** Lesson 2's bullet now says to check each step against what is recorded (repo, PR, deploy log, the host's recorded commit); where only a host read or run could settle it, ask a question and plan it as an owner's step, and "this skill makes no host read". The early rehearsal is its own row. The approval line says "any later server write" needs per-action approval with backups first.
- [Should] Today's-body baseline link: **Implemented.** Step 5a reads today's side from the same first read that step 7 uses as its baseline and recomputes if step 7 redrafts from a newer read; the step-7 clause says the same.
- [Should] Acceptance observations: **Implemented.** The plan's `## Acceptance` is rewritten: base-fail only for feature checks (A1, A2, A4); controlled bad inputs for A3, A5, A6; the plan file scanned apart from the generic text with its required `owner` field listed as metadata; A4 now captures the whole proposed body for a deploy case with one complete and one ownerless gate, checks six columns, first placement and an intact header, replays the base, and checks the action log for writes; A6 needs a delivered-revision receipt and the PR's real base, with missing-receipt and wrong-base controls.
- [Nit] `ci-local.sh --fast` wording: **Implemented** (called a local check that skips the suite and keeps no qualifying gate record).

Draft wording is also tightened (the sheet is now about 28 lines with heading and blanks) to stay near the size budget.

Handing off to Reviewer for round 2.

### Reviewer · Round 2

**What this proposes**  
Extend the morning ledger refresh with a deploy-day sheet at the top of today's body. Put gates first and give each step an owner, time, method, pass evidence and stop condition. Turn incomplete gates into morning questions and generate the sheet from the same snapshot as the rest of the draft.

**How the existing system works, per this document**  
Step 5 gathers PR state and earlier reviews. Step 7 builds today's draft from a saved baseline and rechecks the body before publishing. Step 8 gives an independent reviewer a checklist for the published ledger.

**What it's not**  
The plan's non-goals exclude a new skill or script, deploy instructions, server access, deployment execution or approval, and skill installation.

**Input boundary**  
The proposal paraphrase used the updated plan's `non_goals`, `goal`, Status, Requirement, Recon, Preflight bet, Plan, Draft wording, Acceptance and Risks. The source-backed assessment below followed the base skill and issue reads.

**Source-backed assessment**  
Read GH-1612 §§1–3 and the entire 107-line base skill. The Forge main-checkout index generation is `2026-11-25T18:19:12Z`. Coverage reports the relay artifact missing from that checkout, so plan evidence comes from the seeded copy. I found no additional issue in the base skill that this plan needs to fix.

swept file: yes

- [Pass] The six columns, deploy trigger and repo-owned procedure links match GH-1612 §§1–2 and draft lines 84–91. Draft lines 93–109 cover the deploy and after-deploy owners, recorded code and environment evidence and stale checklists, access and fallback, positive pass evidence, timer and early rehearsal, prior PR findings and their acceptance, and the read-only and later per-action approval rules. The staging and query examples are generic. The evidence boundary from round 1 is resolved by lines 96–100 and 108–109, consistent with `skills/2-daily/yesterday-today/SKILL.md:18–23,49–52`.
- [Pass] The baseline wording now carries the snapshot through draft and redraft (`.relay-artifacts/GH-1612-YESTERDAY-TODAY-RUN-SHEET.md:84–87,112`). Step 5a follows PR evidence and precedes classification. Existing steps 6–9 retain their numbers and the opening reference to the step-7 write still points to the right step (`skills/2-daily/yesterday-today/SKILL.md:18–23,60–98`). The published-body validator still reads the issue independently (lines 85–95).
- [Pass] The size budget is feasible. `wc -l skills/2-daily/yesterday-today/SKILL.md` → exit 0, `107`. `awk 'NR>=82 && NR<=109 {n++} END {print "draft lines:", n}' .relay-artifacts/GH-1612-YESTERDAY-TODAY-RUN-SHEET.md` → exit 0, `draft lines: 28`. Adding a separator and the checklist line while extending the existing step-7 line fits within 30 added lines and leaves the file under 140. Lines 69–76 and 112 reuse the existing skill and validator without a separate helper.
- [Pass] A1 can reject the base by scoping the content check to the missing step 5a and item 6. A2 can reject it because it adds zero lines. A4's base replay must miss the deploy sheet. A5 handles empty and out-of-scope changes, and A6 uses the delivered revision and the opened PR's actual base with separate negative controls (`.relay-artifacts/GH-1612-YESTERDAY-TODAY-RUN-SHEET.md:116–123`; base skill lines 60–71 and 85–100). The round-1 verification nit is closed. Plan line 127 calls fast mode a local check, consistent with `ci-local.sh:399–409,427–437`.
- [Should] Make the incomplete-gate rule agree across the draft, validator and smoke. **Observed input:** The goal requires a question for a gate missing any required value (`.relay-artifacts/GH-1612-YESTERDAY-TODAY-RUN-SHEET.md:20–24)). Draft lines 93–95 use “no owner, time and method,” and the validator and A4 name only ownerless gates (lines 112,121). A gate row for a go-ahead with a named owner and no planned time can be omitted without a question while the remaining sheet satisfies those named observations. **Affected scope:** Deploy-day gates with an owner but a missing required field. **Falsifier:** Give the go-ahead a named owner, a method, pass evidence and a stop condition, and leave the planned time blank. The full draft raises a morning question for the missing time, and the checklist catches a draft that silently omits it. Say “missing any required field” in the draft and checklist and include one partially specified gate in the existing deploy smoke alongside the issue's ownerless gate.
- [Should] Carry the revised baseline rule into the existing A4 exercise. **Observed input:** Plan step 2 still describes dry-running step 5a (`.relay-artifacts/GH-1612-YESTERDAY-TODAY-RUN-SHEET.md:75–77`), and A4 permits a deploy expressed in yesterday's ledger (line 121). That input and the no-deploy input can both pass without using today's baseline or the recompute clause at lines 84–87 and 112. **Affected scope:** Deploy intent present only in today's ledger and changed in the guarded reread. **Falsifier:** Yesterday is silent, today's first body plans the deploy, and the simulated reread cancels it. The two captured drafts show one sheet then zero, with the goal header preserved and no publish. Use those bodies in the existing fictional smoke and make Plan step 2 point to A4's full drafting flow.
- [Should] Include people names in the A3 privacy observation. **Observed input:** Requirement line 46 explicitly excludes people names, but A3 line 120 lists client, product, host, email and private-link patterns only. A standalone person's name in example prose may match none of those categories. **Affected scope:** Generic skill and smoke prose, excluding the plan's required owner metadata. **Falsifier:** A planted person-name example is caught while a generic role label and the documented metadata exception pass. Add a manual look for proper names alongside the existing pattern scan.

**VERDICT: FAIL**  
**Basis:** The revised plan sets the right insertion point, evidence boundary and drafting baseline. Tighten the validation of incomplete gates, exercise the baseline branch through the existing smoke, and cover the remaining privacy requirement. This was source-backed plan QA. Implementation smoke and pre-push verification remain pending.

Handing off to Producer (claude-a) to revise these three observations and the incomplete-gate wording.

### Producer · Round 2

- [Should] Incomplete-gate rule agrees across draft, validator and smoke: **Implemented.** The draft now says a gate "missing any field (above all owner, time or method) is not planned" and is asked as a morning question; validator item 6 says "gates missing a field"; the A4 smoke has an owner-but-no-time gate and a no-owner gate beside a complete one.
- [Should] Baseline rule exercised by the smoke: **Implemented.** A4 is now three drafts: (a) yesterday silent and today's first body plans the deploy; (b) the same case after a simulated guarded reread whose live body cancels the deploy (expect no sheet, header intact); (c) a no-deploy day. The base is replayed on (a). Plan step 2 now points at A4's full drafting flow.
- [Should] Privacy observation covers people names: **Implemented.** A3 adds a manual look for proper names, with a planted person-name control and a generic role label that must pass; the plan's `owner` field stays listed as project metadata.

Handing off to Reviewer for round 3 (the last round under the cap).

### Reviewer · Round 3

**What this proposes**  
Add a deploy-day run sheet to the existing morning ledger refresh. Put it at the top of today's body, with gates first and six fields per step. Ask a morning question for each incomplete gate and omit the sheet on a no-deploy day.

**How the existing system works, per this document**  
Step 5 collects current PR facts, step 7 drafts today's body and step 8 supplies the validator checklist. The proposed step 5a uses step 7's baseline and regenerates the sheet when the guarded reread prompts a redraft.

**What it's not**  
The non-goals exclude helper code, a separate skill, a deploy procedure, server access, deploy execution or approval, and skill installation.

**Input boundary**  
The paraphrase used the seeded plan's frontmatter goal and non-goals, Status, Requirement, Recon, Preflight bet, Plan, Draft wording, Acceptance, Verification and Risks, before the source and issue reads for this turn.

**Source-backed assessment**  
Read [GH-1612](https://github.com/HiQS-Labs/XYZ-forge/issues/1612) §§1–3 and the base skill from frontmatter through step 9. The main-checkout index generation is `2026-11-25T18:19:12Z`; coverage marks the seeded plan and relay log missing there, so their citations use the worktree files. I found no separate defect in the existing skill relevant to this edit.

swept file: yes

- [Pass] The trigger and six fields match GH-1612 §1, and the draft routes procedures to the repo's docs (`.relay-artifacts/GH-1612-YESTERDAY-TODAY-RUN-SHEET.md:84–91`). The seven bullets carry missing gates and late follow-up (93–95), recorded code and environment evidence and stale checklists (96–100), access and fallback (101), positive pass evidence (102–103), timer and early rehearsal (104–105), review history and acceptance (106–107), and read-only planning with later per-action approval and backups (108–109). The examples are generic. The evidence boundary and the existing guarded ledger edit agree with `skills/2-daily/yesterday-today/SKILL.md:18–23,49–52,73–83`.
- [Pass] Step 5a has the PR facts from step 5 and precedes classification. The baseline and recompute clauses use the same body as step 7, and step 8 still reads the published ledger independently. Keeping steps 6–9 numbered preserves the opening step-7 reference (`skills/2-daily/yesterday-today/SKILL.md:18–23,60–98`; plan lines 84–87,112).
- [Pass] The revised rule, validator and A4 agree on any missing gate field. A4 includes both the ownerless gate and the gate with an owner and no time. It uses today's first body as the sole deploy signal, cancels that deploy in the simulated guarded reread and also exercises an independent no-deploy day. The plan calls for the full draft from the consumer entry point, captures the whole body, checks the header and confines verification to the action log and checkout state. This closes both round-two drafting findings (plan lines 75–76,93–95,112,121). A3 now adds the proper-name check, planted name and passing role label, with the owner metadata handled separately (lines 46,120), closing the third round-two finding.
- [Pass] A1 fails on the base's missing 5a and validator item 6, with a removed lesson as a second control. A2 fails on zero added lines. A4's base replay fails on the missing sheet. A3's privacy controls, A5's empty and out-of-scope diffs and A6's missing receipt and wrong PR base test their respective safeguards. A5 also rejects an unchanged skill and A6 requires evidence for the delivered revision and actual PR base. These are manual observations with no separate script or suite (plan lines 116–127; base skill lines 60–98; `GUIDING-PRINCIPLES.md:104`). Fast mode is correctly described as a local check (`ci-local.sh:399–409,427–437`).
- [Pass] The size budget is achievable. `wc -l skills/2-daily/yesterday-today/SKILL.md` → exit 0, `107`; `awk 'NR>=82 && NR<=109 {n++} END {print "draft lines:", n}' .relay-artifacts/GH-1612-YESTERDAY-TODAY-RUN-SHEET.md` → exit 0, `draft lines: 28`. Combining one continuation line leaves room for a separator, the replacement step-7 line and the step-8 checklist line inside A2's 30 added lines without dropping any text (plan lines 75,82–112,119).

**VERDICT: PASS**  
**Basis:** The revised draft covers the seven lessons, and the acceptance plan now exercises incomplete gates, snapshot changes and privacy with concrete controls. The three round-two findings are closed. Approval is for the plan. Implementation smoke and pre-push verification are pending.

Relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-11-25T20:06:04Z
task: RELAY-gh1612-plan-qa
reviewer: codex
status: Approved
reviewed-head: bff4f1ab4e4bc5588a091269eecd6c0706a04c48
added-range: 28807+4630
added-sha256: e6d94d1fb005c746315ff291213b849d38ada14dfec455a41a6796588e8456b5
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
