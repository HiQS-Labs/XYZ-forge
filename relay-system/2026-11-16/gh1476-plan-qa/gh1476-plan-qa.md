# RELAY · GH-1476 OL-09 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-16.
-->

NEXT: Producer
STATUS: Escalated
ROUND: 1 / 1

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
6. **Commit only the relay file** (`relay(gh1476-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1476-RAW-TASK-PREPARATION.md` (committed at `b76b62b1e02ce6c398e30a1975e1262015f8e226`). This is a PLAN review: no source has been written yet; the plan must be approved before implementation.
- Reviewer: claude-review (same-provider Claude subscription route, one review turn, read-only)   ·   Producer: claude-a
- Started: 2026-11-16
- Definition of Done: the plan is a coherent, proof-honest, minimal instruction-only slice for OL-09 (umbrella #1400 criterion OL-09) that can be implemented without contradicting live consumer lines, and that does not claim OL-10 runtime admission or OL-09 operational verification.

### Operational envelope and non-goals

Local developer harness; instruction (SKILL.md prose) changes only. Out of scope and themselves findings if the plan requires them: new test suites or `validate.sh` entries (GH-831), runtime code, new schema/queue/state/readiness database, daemon, installed-skill mutation, amendment of #1328, numeric global research ceilings, live backlog execution. Reject speculative enterprise machinery. Scope is the needed minimal changes, not a rewrite of 10days.

### Files to read (all at the committed head)

- The plan above, in full.
- `skills/1-hourly/conveyor/SKILL.md` (whole file, 71 lines).
- `skills/3-weekly/10days/SKILL.md` (whole file; Guardrails, Steps 2, 3, 4, 5, 6, 8 matter most).
- `skills/2-daily/jog/SKILL.md` section `## Preparation handoff (GH-1439)`; `skills/2-daily/flywheel/SKILL.md` where it references 10days/Jog.
- `skills/1-hourly/start-task/SKILL.md` section `Task rating policy`.
- `decisions/2026-11-04-gh1333-closure-appeal-row-at-start.md` (D-b / G6b: what "selection" means for ledger row creation); `PROJECT/PDDA.md` lines near 261 and 291.
- Optional, read-only, if `gh` works: `gh issue view 1476 -R HiQS-Labs/XYZ-forge` and `gh issue view 1400` (OL-09 / OL-10 rows and the "Current execution alignment" table).

### Questions

1. Does the plan correctly accept RAW requests? Identify which existing entry point(s) a "raw daily-goal" request actually enters through in source (10days Step 1 scan, Conveyor issue IDs, anything else). Is "daily-goal intake" grounded in a real source owner, or is the term undefined for implementation?
2. Medium research default: in 10days, where exactly would the default read-only research child run relative to Step 3's existing subagent fan-out and Step 4/5 selection? Is "selected unprepared work" defined precisely enough that an implementer cannot either research the whole window or select before researching?
3. Deepen-when-warranted and reuse-valid-evidence: are the triggers concrete enough without numeric global defaults? Is "freshness reuse" distinguishable from 10days Step 5 `--deep` (a preflight freshness refresh)?
4. Holds and exclusion: list every live line in 10days (and Conveyor) that would still route an unknown/held item to EXCLUDE or silent drop after the plan's named Step 2/3/8 edits. Check Guardrails, Step 3 sanity-check filter, Step 3 "Prioritization Rules", Step 4 contract sniff test, Step 5 planner Held section, Step 8 Exclusion Ledger. Cite `file:line`.
5. Risk deferral opt-in: does any live line perform an implicit (non-requested) deferral or exclusion based on low risk/consequence that the plan leaves untouched?
6. Ratings: does the plan's neutral-appeal / preserve-override / no-forced-clearing change cover every conflicting line (e.g. appeal rubric, `--force` clear, `ovr` invalidation)? Is it consistent with start-task's rating policy?
7. No ledger writes on shortlist: given D-b/G6b, which live lines in 10days AND Conveyor write ledger rows or ratings before committed execution selection? If 10days is told to "consume Conveyor's policy", could an implementer or runtime agent end up executing Conveyor Steps 3-6 (capture publication, `roadmap pickup`, readiness label) from a 10days research child?
8. OL-10 separation: does any plan wording imply admission refusal is implemented? Does the manual scenario walk (plan step 4) honestly distinguish prose consistency from real model behavior, and does the plan unambiguously forbid ticking #1400's OL-09 checkbox ("implemented AND verified") on this PR alone?
9. Acceptance mapping: for each acceptance bullet, is there a concrete check (old-text red control, expected disposition) that would reject an unchanged or partially changed instruction set? Name any bullet with no rejecting check.
10. Over-engineering: flag anything in the plan that is ceremony or speculative machinery, and anything missing that is needed for a minimal correct slice.

Grade each finding `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`, cite `file:line` or a quoted span, and include `Observed input:` / `Affected scope:` / `Falsifier:` for any finding requesting a change. End with `VERDICT: PASS|FAIL|PARKED` and a non-empty `Basis:`. Include `swept file: yes|no`. Do not edit the plan or any source; append only to this file.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

Agent: claude-review. Read in full at worktree HEAD `a16b1d38` (plan unchanged since `b76b62b1`): the plan (60 lines), `skills/1-hourly/conveyor/SKILL.md` (71), `skills/3-weekly/10days/SKILL.md` (571), `decisions/2026-11-04-gh1333-closure-appeal-row-at-start.md`, Jog `## Preparation handoff (GH-1439)` (jog:28-103), start-task `## Task rating policy` (start-task:380-433), flywheel 10days sections (flywheel:154-215), PDDA.md:255-295. Optional `gh issue view 1476/1400` was not run: the sandboxed call returned `rc=1` and the unsandboxed retry was denied, so the OL-09/OL-10 wording on #1400 was not checked against the issue.

swept file: yes. I read the whole plan and every live consumer file, not only the sections the plan names. The Q4 sweep found pre-existing 10days lines outside the plan's named Step 2/3/8 that still route items to exclusion. They are listed in B1.

**Grounding claims (plan:29)**
- [Pass] "10days Step 2 immediately excludes completed-folder captures": 10days:220 `bucket: "3-COMPLETED"` → strong already-done signal. Exclude immediately`.
- [Pass] "scores appeal from clarity and forcibly clears overrides": 10days:250 `appeal (motivation / clarity): 90 = clear reproduction steps`; 10days:253 `If ovr is invalid or absent, clear it by running roadmap rate ... --force`.
- [Pass] "Step 8 mixes holds into exclusions": 10days:545-546 `Exclusion Ledger ... held-by-preflight / held-by-planner`.
- [Pass] "Step 5 --deep refreshes preflight, not research depth": 10days:401 `--deep delegates to ... swarm-preflight.sh --dry-run per ready item for an authoritative freshness verdict`. Q3's split between freshness and depth is grounded.
- [Pass] Jog already owns the preparation handoff (jog:28-31). 10days is not re-enqueued into Jog, which matches flywheel:164-168 `Do not send its issues through Jog`.
- [Pass] The plan keeps OL-10 out of the claimed scope (Q8). plan:25 `do not claim runtime enforcement from prose`; plan:51 `OL-10 runtime admission ... not claimed implemented`; plan:40 `proves instruction consistency, not behavioral compliance by a model or actual admission interception`.
- [Pass] The plan's rating (plan:56) follows start-task policy: appeal 50 with no operator value (start-task:391), and the recurrence trend is recorded as unknown rather than zero (start-task:402).

**Findings**

- [Blocker] B1 (Q4/Q5): the plan's 10days edit list, "Step 2/3/8" (plan:39), leaves live lines that still exclude or drop unknown, held or low-risk items. That contradicts the plan's own acceptance bullets plan:47 (`never silent exclusion`) and plan:48 (explicit risk deferral only).
  Observed input: these lines survive the named edits.
  - 10days:73-75 (Guardrails): `an existing capture doc parked in PROJECT/3-COMPLETED, is evidence`. This directly contradicts plan:39 `A completed folder alone cannot exclude an open request`.
  - 10days:244 (Step 3 sanity-check filter): `low-consequence noise with a clear deferral path, classify it as EXCLUDE`. This is an implicit, unrequested risk deferral.
  - 10days:264: the verdict enum is `"INCLUDE|EXCLUDE"` only, with no HELD.
  - 10days:389-391 (Step 4 sniff test): `drop that issue back to needs_contract and exclude it from this run`.
  - 10days:430: exit `4` is read as `stale/already landed (drop it, propose closing the GH issue — the fix shipped ...)`. But conveyor:61 says `An incorrect polarity and an already-fixed issue can both yield STALE`, so this is an exclusion without affirmative evidence.
  Affected scope: every 10days candidate whose disposition comes from those lines (3-COMPLETED-only evidence, low-consequence sanity-check results, failed contract sniff test, preflight exit 4 without a delivering commit or PR).
  Fix: widen plan:39 to name Guardrails (73-75), Step 3 (244, 264, 288), Step 4 (389-391), Step 6 (430) and Step 8 (545-546). Wording per line:
  - 3-COMPLETED-only evidence → research or HELD.
  - The sanity-check low-risk result → EXCLUDE only under an explicit batch-scoped deferral request, otherwise HELD/INCLUDE.
  - Add HELD to the verdict enum.
  - A sniff-test failure → HELD, reported under held.
  - Exit 4 → EXCLUDE only with a delivering commit or PR, otherwise HELD (polarity suspect).
  Falsifier: a paper walk of an open issue whose only evidence is a 3-COMPLETED capture through the post-edit text, with no delivering commit or PR, expected HELD. If every listed line already yields HELD under the plan's edits as written, B1 is wrong.

- [Should] S1 (Q2): the plan never says where the default research child runs inside 10days, or what "selected" means there. Two incompatible implementations both fit the text.
  Observed input:
  - plan:39 names only Step 2/3/8.
  - 10days:241 `For every issue that survives Step 2, spawn subagents`. Putting research here researches the whole window.
  - 10days:393 does pickup only `for the survivors it plans into the marathon` (Step 4).
  - 10days:410 intersects at Step 5. Selecting there comes after contracts are authored, so contracts would be written before any research.
  Affected scope: 10days INCLUDE candidates without valid prior preparation.
  Fix: state that Step 3 stays the cheap validity triage and that "selected" means the Step 3 INCLUDE set the run plans into the marathon (the same set as 10days:393). Put the one medium research child per selected, unprepared item in Step 4, before contract and acceptance authoring, and name Step 4 in plan:39.
  Falsifier: a paper walk of a 20-issue window with 3 INCLUDEs. The expected result is exactly 3 research children, each finishing before its Step 4 contract is drafted.

- [Should] S2 (Q7): the plan does not reconcile "persist only committed execution selection, not every shortlist" (plan:39) with live write points, and it does not fence Conveyor's write steps off from a 10days research child.
  Observed input:
  - 10days:254 (Step 3) `Persist newly evaluated ratings to releases.db via releases roadmap rate`. This writes before selection.
  - 10days:253: `--force` writes for every unrated candidate.
  - 10days:393: `This makes marathon-plan.sh discover it in Step 5`. Rows must exist before Step 5, so moving pickup later breaks the planner.
  - Conveyor Steps 3-6 (conveyor:27-67) publish captures, run `roadmap pickup` (conveyor:36), open a preparation PR and add `status:ready-for-pickup`.
  - plan:39 says only `consume that policy`.
  Affected scope: ledger writes in 10days Steps 3-4, and any 10days research child that loads Conveyor.
  Fix:
  - Delete the Step 3 write at 10days:253-254.
  - Declare the 10days:393 Step 4 pickup to be the D-b committed selection (decision:8), leaving its timing unchanged.
  - Make 10days link the Conveyor policy section by anchor. The research child is read-only, returns provisional ratings and findings to the 10days primary, and runs no Conveyor Step 3-6 action (no capture publication, pickup, preparation PR, marker comment or label).
  - Say that Conveyor's own pickup at conveyor:33 is unchanged by this slice.
  Falsifier: a walk of an unrated candidate that is EXCLUDEd or HELD at Step 3. The expected result is zero `roadmap rate` or `pickup` writes, and still a row for every marathon-planned survivor before `marathon-plan.sh --write --deep`.

- [Should] S3 (Q1): "RAW daily-goal requests" (plan:9, 23, 50) has no source owner, so an implementer could invent a new intake surface.
  Observed input:
  - `git grep -n -i "daily-goal\|daily goal" -- 'skills/**' 'PROJECT/*.md' 'decisions/**'` exited 0. The only skill or governance hits are in this plan; the other hits are marathon-plan issue titles (#1474).
  - The real entry points take GitHub issues only: 10days:208 `one JSON object per OPEN issue`, and conveyor:8 `Turn existing issues`.
  - conveyor:19 says a request with no IDs or scope `needs one clarification`, with `No synthetic backlog`.
  - Flywheel's Daily is observation-only (flywheel:156-160).
  Affected scope: the wording of the new Conveyor policy and of plan:50.
  Fix: define RAW as an open GitHub issue that lacks a capture, row, contract or rating, entering through 10days Step 1 or Conveyor's issue-ID, `--prs-min` or batch modes. Free-text goals with no issue route to `/idea` (conveyor:23). Rewrite plan:50 to say this.
  Falsifier: if some skill line already defines a daily-goal intake owner, cite it and S3 drops.

- [Should] S4 (Q10): plan:38 `record numeric deadline and remaining authorized budget in the existing packet`. No packet exists when research runs. The swarm packet is written later by `swarm-preflight.sh` (10days:427 `let it write the real packet`), so recording the budget there implies a packet-schema or runtime change, which the envelope puts out of scope.
  Observed input: plan:38 quoted above, read against 10days:427.
  Affected scope: where research deadline and budget evidence is recorded.
  Fix: record it in the batch's existing record (Conveyor handoff at conveyor:71, 10days Step 8 report), not in the preflight packet.
  Falsifier: an existing pre-research packet field for deadline and budget, cited by `file:line`.

- [Should] S5 (Q8): plan:40 `Record remaining real-follow-up requirement before ticking OL-09 as operationally verified` reads as permission to tick once the follow-up is recorded. It does not forbid ticking #1400's OL-09 box ("implemented AND verified") on this PR.
  Observed input: plan:40 quoted.
  Affected scope: #1400's OL-09 checkbox and the PR body.
  Fix: replace with "Do not tick #1400 OL-09 on this PR. Tick only after a real 10days or Conveyor run shows the dispositions; this PR records instruction consistency only."
  Falsifier: none needed. This is a wording tightening with no behavior change to a skill.

- [Should] S6 (Q9): the plan:40 scenario walk has no rejecting check for several acceptance bullets and plan:39 claims:
  - bullet plan:49, ratings: neutral appeal, `ovr` preserved, no forced clearing;
  - bullet plan:50, intake and Jog;
  - completed-folder-only evidence;
  - held reported separately from excluded;
  - no ledger write on the shortlist.
  Observed input: plan:40 lists only five scenarios, mapped to plan:45-48.
  Affected scope: plan step 4.
  Fix: add paper scenarios, each with old text as the red control.
  - (f) Open issue with only a 3-COMPLETED capture → HELD or research. Red controls: 10days:73-75 and 220.
  - (g) Unrated issue with no operator values → appeal 50, no `--force`, no write before selection. Red controls: 10days:250, 253, 254.
  - (h) Valid `ovr` is preserved and a re-rate passes the retained `--ovr`. Red control: start-task:420.
  - (i) Sniff-test failure → reported under held, not the Exclusion Ledger. Red controls: 10days:391 and 546.
  - (j) Raw goal with no issue → `/idea` or clarification, not synthetic intake. Red control: conveyor:19.
  Falsifier: a scenario that the unchanged text already passes is not a valid red control and should be dropped.

- [Nit] N1 (Q3): name the existing reuse path. The 10days:221 route (`2-WORKING with has_contract: true → route through Step 3 for freshness check`), plus the existing Step 5 and 6 preflight, should be the "freshness reuse" check. That adds no new staleness rule.
- [Nit] N2 (Q6): 10days:316-320 keep `rating_ovr` and `is_manual_override` as editable frontmatter. start-task:410 says a displayed copy is `a read-back of the DB, never a competing editable ranking`. The plan's rating edit should mark that frontmatter as read-back only.
- [Nit] N3 (Q10): the prior-art and graph-coverage boilerplate at plan:31 is ceremony for a plan review, though harmless. Beyond that, the plan adds no speculative runner, schema or suite, and the deepen triggers carry no numeric global caps (plan:38). [Pass] on over-engineering otherwise.

VERDICT: FAIL
Basis: the plan is grounded, keeps OL-10 out of scope and matches the envelope, but it is not yet implementable without contradicting live consumer lines. Its named 10days edit set (Step 2/3/8) leaves five live exclusion or silent-drop routes, cited in B1, that break its own "never silent exclusion" and "explicit risk deferral" acceptance. It also leaves the research child's placement and "selected" undefined against 10days:241/393/410 (S1). The ledger-write and Conveyor-write fencing (S2) and the term "daily-goal" (S3) need pinning before implementation. ROUND 1/1 ends without approval, so STATUS is Escalated. A Producer revision that addresses B1 and S1-S3 should get one more review round.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
