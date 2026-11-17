# RELAY · GH-1476 OL-09 plan QA round 2
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
6. **Commit only the relay file** (`relay(gh1476-plan-qa-r2): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1476-RAW-TASK-PREPARATION.md` revised at `c9168dc77` (round-1 reviewed `b76b62b1`; `git diff 8293b014 c9168dc77` touches only this plan). This is a PLAN review, round 2 of 3 total plan-review rounds. No source has been written; the plan must be approved before implementation.
- Round 1 (FAIL, preserved, do not edit): `relay-system/2026-11-16/gh1476-plan-qa/gh1476-plan-qa.md` Reviewer · Round 1 block (B1, S1-S6, N1-N3) and orchestrator notes `PRIMARY-PLAN-QA.md`. The plan's own dispositions are its section `## Round 1 dispositions and falsifying scenario matrix`; the Producer did not append a block to the round-1 thread, so grade the revised plan text itself.
- Reviewer: claude-review (same-provider Claude subscription route, one review turn, read-only)   ·   Producer: claude-a
- Started: 2026-11-16
- Definition of Done: the revised plan is a coherent, proof-honest, minimal instruction-only slice for OL-09 (umbrella #1400) that resolves round-1 B1 and S1-S6 without contradicting live consumer lines, does not claim OL-10 runtime admission or OL-09 operational verification, and keeps #1400's OL-09 checkbox unchecked.

### Operational envelope and non-goals

Local developer harness; instruction (SKILL.md prose) changes only. Out of scope and themselves findings if the plan requires them: new test suites or `validate.sh` entries (GH-831), runtime code, new schema/queue/state/readiness database, daemon, installed-skill mutation, amendment of #1328, numeric global research ceilings, live backlog execution. Reject speculative enterprise machinery. Scope is the needed minimal changes, not a rewrite of 10days.

### Files to read (all at the committed head)

- The plan, in full, and the round-1 thread block and `PRIMARY-PLAN-QA.md` above.
- `skills/1-hourly/conveyor/SKILL.md` (whole file, 71 lines).
- `skills/3-weekly/10days/SKILL.md` (whole file, 571 lines).
- `skills/2-daily/jog/SKILL.md` `## Preparation handoff (GH-1439)`; `skills/2-daily/flywheel/SKILL.md` where it references 10days/Jog.
- `skills/1-hourly/start-task/SKILL.md` `## Task rating policy`.
- `decisions/2026-11-04-gh1333-closure-appeal-row-at-start.md` (D-b / G6b); `PROJECT/PDDA.md` near lines 261 and 291.
- Optional, if `gh` works: `gh issue view 1476` and `gh issue view 1400 -R HiQS-Labs/XYZ-forge`. If it does not, say so; the orchestrator already read #1400 OL-09 = "Raw intake and research policy are implemented and verified".

### Questions

1. Round-1 closure: for each of B1, S1, S2, S3, S4, S5, S6 (and N1-N3), state Resolved / Partly / Not resolved with the revised plan line that resolves it. Re-run the B1 sweep: after plan:39's widened edit list, does any live 10days or Conveyor line still route an unknown, held or low-risk item to EXCLUDE or silent drop? Check 10days:73-75, 220, 232, 244, 253-254, 264, 288, 316-320, 389-393, 401, 430, 545-546 and Conveyor whole-file. Cite `file:line`.
2. Daily-goal ownership: plan:23 says "Conveyor owns explicit issue/daily-goals intake" and holds unlinked goals. Is that grounded in a live Conveyor line, or does the slice add a new Conveyor intake rule? Is it consistent with conveyor:19 (`No synthetic backlog`, one clarification) and conveyor:23 (`/idea`)? Is "daily-goals issue" defined precisely enough that an implementer cannot invent a new intake surface or issue-creation authority?
3. Selected-before-research primary write: plan:39 moves the committed-selection write to "before research dispatch" in Step 4 and rewords Conveyor Step 4 pickup as "committed preparation selection before dispatch per #1328". Is that consistent with D-b/G6b (decision:8, selection = commitment to an actual execution batch), with 10days:393 (pickup so `marathon-plan.sh` discovers rows in Step 5), and with the non-goal "no #1328 amendment"? Is the Step 3 `roadmap rate`/`--force` write (10days:253-254) unambiguously removed? Walk an unrated candidate EXCLUDEd/HELD at Step 3 and an INCLUDEd one to Step 5: expected zero writes for the first, a row before `marathon-plan.sh --write --deep` for the second.
4. Read-only child restriction: does plan:39 fence research children off from Conveyor Steps 3-6 (capture publication, pickup, preparation PR, marker comment, label) and from ledger writes, and name the parent as the sole advancer? Can a child that "follows the canonical Conveyor policy" still reach a write step?
5. Medium / deep / reuse / deferral: are (a) the medium default for selected unprepared work, (b) deepen triggers (no numeric global caps), (c) freshness reuse vs 10days Step 5 `--deep`, and (d) explicit batch-scoped risk deferral each concrete enough that an implementer cannot research the whole window, skip research, collide "deep" terminology, or apply deferral implicitly? Does "Do not repeat medium research already evidenced by Step 3" reopen S1's ambiguity (is the Step 3 validity subagent now a research child or not)? Is S4's budget record (parent selection/recon note) an existing record or new machinery?
6. Scenario falsifiers: plan:47 requires each row to name the old instruction giving the wrong result, the revised owner/line and the expected output, but the table at plan:49-62 has two columns. For every row, is there a concrete red control (old `file:line`) that the unchanged text fails and the revised text would pass? Name each row lacking one, and any round-1 S6 scenario (f)-(j) missing. Does any row pass on unchanged text (invalid red control)?
7. OL-09 remains unchecked: does plan:40 (and plan:62, 72-73) unambiguously forbid ticking #1400 OL-09 on this PR, with no conditional path to tick from paper evidence alone? Any wording implying OL-10 admission refusal is implemented?
8. Ratings: does the revision cover 10days:232 (malformed `ovr` at Step 2), 250 (appeal from clarity), 253 (`--force` clear), 316-320 (editable `rating_ovr` frontmatter vs start-task:410 read-back only), consistent with start-task's rating policy?
9. Over-engineering / missing: flag ceremony or new machinery introduced by the revision, and anything still missing for a minimal correct slice.

Grade each finding `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`, cite `file:line` or a quoted span, and include `Observed input:` / `Affected scope:` / `Falsifier:` for any finding requesting a change. End with `VERDICT: PASS|FAIL|PARKED` and a non-empty `Basis:`. Include `swept file: yes|no`. Set `STATUS: Approved` only on PASS. Do not edit the plan, the round-1 thread or any source; append only to this file.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

Agent: claude-review. Read in full at worktree HEAD `1991a32c` (plan at `c9168dc77`): the plan (82 lines), the round-1 Reviewer block (`gh1476-plan-qa.md:99-200`), `skills/1-hourly/conveyor/SKILL.md` (71), `skills/3-weekly/10days/SKILL.md` (571), start-task `## Task rating policy` (start-task:380-433), `decisions/2026-11-04-gh1333-closure-appeal-row-at-start.md`, PDDA.md:252-310, and the `roadmap pickup` parser (`utils/py/releases_app.py:7025-7032`). `PRIMARY-PLAN-QA.md` was not read. `gh issue view 1476 -R HiQS-Labs/XYZ-forge` exited `rc=1` inside the sandbox, and I did not retry it unsandboxed. The #1476 daily-goals wording and the #1400 OL-09 text were therefore not checked against GitHub. I relied on the orchestrator's OL-09 reading.

swept file: yes. I read the whole plan, the whole of Conveyor and the whole of 10days, not only the lines named in Q1. The sweep found one pre-existing 10days write instruction outside the plan's edit list (10days:338-343, under S-B below).

**Q1 Round-1 closure**
- [Pass] B1 resolved. plan:39 now names `completed-folder guardrail and Step 2` (10days:73-75, 220), `Step 3 sanity filter/ratings/verdict schema` (244, 264, and 288 via `EXCLUDE requires affirmative delivered/duplicate/not-work/superseded evidence; unknown reproduction/access is held`), `contract sniff failures are HELD` (389-391), `preflight exit 4 alone is not proof of delivery and is HELD` (430), and `Report held and excluded separately` (545-546). I re-ran the sweep against 10days:401, 405-406, 410, 432-434 and 441-442, and against all of Conveyor (conveyor:15 discovery list, :16 `report unprocessed IDs`, :19 `hold an item`, :23 delivered/duplicate `reported with its evidence`, :61 STALE `Investigate`, :71 `held` state). After plan:39's edits, no live line routes an unknown, held or low-risk item to EXCLUDE or a silent drop.
- [Pass] S1 resolved. plan:39 says `Selected means the parent has explicitly committed a bounded candidate set after validity triage` and `In Step 4, before contract authoring, ... dispatch one read-only medium research child per selected unprepared issue`. A residual reuse clause is graded N-A below.
- S2: partly resolved. The Step 3 write is gone (plan:39 `Step 3 validity researchers report provisional findings/ratings only, with no ledger writes`, `no forced clearing/rescoring`), and children are fenced off (Q4 [Pass]). Two write-timing defects remain, S-A and S-B.
- S3: partly resolved. plan:23 defines RAW as `an existing open GitHub issue` and says `this slice does not invent issue-creation authority`. The term "daily-goals issue" and how its linked candidates are selected are still undefined (S-C).
- S4: partly resolved. plan:38 says `record its numeric deadline and remaining authorized budget in the parent selection/recon note (before a capture or preflight packet exists)`. The phrase `carry that record into the eventual packet` is still ambiguous (N-B).
- [Pass] S5 resolved. plan:40 says `Do not tick OL-09 in #1400 on this PR. Its checkbox stays unchecked until a real bounded run witnesses the preparation behavior`.
- S6: partly resolved (S-D).
- N1 not resolved (N-C). N2 not resolved (N-D). N3 unchanged: the plan:31 prior-art/graph boilerplate is still harmless ceremony; no action.

**Findings**

- [Should] S-A (Q3): plan:39 `Correct Conveyor Step 4 pickup wording too: the canonical primary writer persists committed preparation selection before dispatch per #1328`, combined with plan:60 `selected parent writes through primary before research dispatch`, turns G6b's "before dispatch" into "before research dispatch" for Conveyor. Under that reading, Conveyor's pickup has to move ahead of its own research.
  Observed input: Conveyor runs research at Step 2 (conveyor:25), writes the capture at Step 3 (conveyor:27), and only then runs pickup at Step 4 with `--doc-path CAPTURE_PATH` (conveyor:36). If pickup must precede research dispatch, CAPTURE_PATH does not exist yet, and the Step 2/3/4 order changes without the plan saying so. G6b's "before dispatch" means execution dispatch (decision:8: `committing an issue to an actual execution batch ... created on the primary before dispatch`). PDDA.md:300-302 adds `Ranking or shortlisting does not`. Round-1's S2 fix also said `Conveyor's own pickup at conveyor:33 is unchanged by this slice`.
  Affected scope: Conveyor Step 4 timing only.
  Fix: keep Conveyor's pickup position and command unchanged. Limit the Conveyor wording change to "a shortlist is not selection; selection is not execution admission". Keep the before-research write only for 10days (Q3 walk below), and say there that a pre-research `roadmap pickup` omits `--doc-path` (it is optional, `releases_app.py:7029`) and repoints after Step 4 authors the doc.
  Falsifier: walk `/conveyor 1340` through the revised text. Expected: Steps 1→2→3→4 in today's order, with pickup carrying the real CAPTURE_PATH. If the revised text forces pickup before Step 2, S-A is confirmed.

- [Should] S-B (Q3, pre-existing, found by the sweep): 10days has two pickup instructions with different timing, and the plan names neither line for reconciliation. Adding a third ("before research dispatch") leaves the Q3 walk with no single answer.
  Observed input: 10days:338-339 `Persist ratings to releases.db at survivor pickup/planning (Step 5): When selecting survivor lanes for the marathon plan, admit each ...`. 10days:393 puts pickup in Step 4 so `marathon-plan.sh discover[s] it in Step 5`. plan:39 lists only `Step 5 terminology` (the `--deep` wording).
  Affected scope: every 10days INCLUDE candidate's row-creation point.
  Fix: name 10days:338-343 and :393 in plan:39, and collapse them into one pickup at the start of Step 4, after the parent commits the selection and before the research child is dispatched. That makes the Q3 walk deterministic:
  - an unrated candidate EXCLUDEd or HELD at Step 3 gets zero `rate`/`pickup` writes;
  - an INCLUDE gets its row before `marathon-plan.sh --write --deep`.
  Falsifier: if 10days:338 is already slated for deletion or rewording under the plan's existing text, cite the plan line and S-B drops.

- [Should] S-C (Q2): "Conveyor owns explicit issue/daily-goals intake ... identify linked open issue candidates before preparation" (plan:23), together with table row plan:52 `prepares linked candidate`, adds a new Conveyor selection rule that no live line grounds. The term "daily-goals issue" is also undefined.
  Observed input: conveyor:14 `prepare the named existing issues`. Linked issues are not named. conveyor:16 sets a five-item default bound for batch selection. The plan neither defines a daily-goals issue (label, title or body shape) nor says whether linked candidates count against that bound. `git grep -n -i "daily-goal\|daily goal" -- skills/ PROJECT/PDDA.md decisions/` returned no hits.
  Affected scope: Conveyor runs that name an issue linking other open issues.
  Fix: define a daily-goals issue as an operator-named open issue whose body lists goals. Linked open issues (explicit `#N` references) are reported as candidates. They enter preparation only when they are named or fall inside an existing batch scope (conveyor:14-16), and they count against its limit. Unlinked goals are reported as `held` in the conveyor:71 handoff under the goals issue, never as new issues and never routed to `/idea` automatically. This agrees with conveyor:19 `No synthetic backlog` and conveyor:23.
  Falsifier: `/conveyor <goals#>` where the goals issue links 12 open issues and no limit is given. Expected: 12 candidates reported, and at most 5 prepared, or none without explicit selection. Under the current plan text the count is undefined.

- [Should] S-D (Q6): the scenario table (plan:49-62) does not meet plan:47's own rule, `Each row must name the old instruction that gives the wrong result ..., the revised owner/line, and expected output`. It has two columns and no old `file:line` in any row.
  Observed input, per row:
  - Row 1 (plan:51), intake half: it passes on unchanged text, so it is an invalid red control. plan:29 itself says `The source Conveyor flow already accepts missing rows/contracts`, and 10days:222 routes `bucket: null` to Step 3/4. Only the medium-research half is a valid missing-rule control.
  - Row 3 (plan:53): unchanged text has no research child at all, so "redundant research child fails" can never fail. Invalid red control.
  - Round-1 S6(j) (a raw goal with no issue → clarification or `/idea`; red control conveyor:19) is missing.
  - S6(h) (a re-rate passes the retained `--ovr`; red control start-task:420-421 `pass the retained --ovr explicitly`) appears only as "preserve valid values".
  - S6(i) (a sniff failure is reported under held, not in the Exclusion Ledger; red controls 10days:391, 546) does not assert where it is reported.
  Affected scope: plan step 4 paper walk, plan:40 and plan:49-62.
  Fix: add a column for old instruction / red control, with these values:
  - row 4: 10days:73-75, 220
  - row 5: 10days:244
  - row 6: 10days:288, 389-391, 430
  - row 8: 10days:244
  - row 9: 10days:232, 250, 253
  - row 10: 10days:253-254, 338
  - rows 2, 7, 11: "missing rule"
  Recast row 1 to test only medium research. Replace row 3's falsifier with "Step 4 dispatches a research child for an item whose 10days:221 freshness check passed". Add (j), and make (h) and (i) explicit. Row 12 is a PR assertion, not a red-controlled scenario, so label it that way.
  Falsifier: any row whose cited old line yields the required result unchanged should be dropped, per round-1 S6.

- [Pass] Q4: plan:39 `Children must not invoke Conveyor Steps 3–6, write captures/ledger, publish, or execute. The parent preparation owner alone advances capture/contract/review after research.` This covers capture publication, pickup, the preparation PR, the marker comment and the label (conveyor:27-67). conveyor:10's blanket authorization belongs to the invoking parent; the explicit fence overrides it for children.
- [Pass] Q5(a)(b)(d): the default is one child per selected, unprepared issue in Step 4 (plan:39). Deepen triggers are `concrete state/authority/recovery uncertainty or credible high actual effort` with `not mandatory global 20/60/90-minute defaults` (plan:38). Deferral is `Remove automatic low-risk exclusion unless risk-deferral mode was explicitly requested` (plan:39) plus `explicit batch-scoped request` (plan:23). The terminology clash is handled by `marathon-plan --deep refreshes preflight and does not select research depth` (plan:39).
- [Pass] Q7: plan:40, plan:62 and plan:72-73 forbid ticking OL-09 on this PR, with no conditional path. plan:25 `OL-10 actual stale/held admission refusal remains separately open ... do not claim runtime enforcement from prose`.
- [Pass] Q8 partial: 10days:232 is covered by `Preserve malformed operator overrides and hold for an operator decision rather than clearing them`. 10days:250 is covered by `neutral appeal50 absent operator value`. 10days:253 is covered by `no forced clearing/rescoring`. All three match start-task:393 and :417-421. 10days:316-320 is not covered (N-D).

- [Nit] N-A (Q5): plan:39 `Do not repeat medium research already evidenced by Step 3` lets an implementer give the Step 3 subagents (10days:241, `every issue that survives Step 2`) the medium checklist. The whole window would then be researched and Step 4 would dispatch nothing, which reopens S1's cost ambiguity. Observed input: that sentence alongside 10days:241. Affected scope: Step 3 subagent instructions. Fix: "Step 3 stays cheap validity triage. Reuse applies only when a prior record already carries the full plan:38 medium checklist for that issue." Falsifier: a 20-issue window with 3 INCLUDEs produces exactly 3 medium outputs.
- [Nit] N-B (Q5/S4): `carry that record into the eventual packet` (plan:38). In 10days, "packet" is the swarm-preflight packet (10days:427-428), and writing a field there would be the schema change plan:25 forbids. Fix: say "into the capture doc / Conveyor preparation packet, never the swarm-preflight packet". Falsifier: an existing packet field for deadline and budget.
- [Nit] N-C (carried N1): `reuse fresh preparation` (plan:39) never says what "fresh" means. Fix: name the 10days:221 route (`2-WORKING with has_contract: true → ... freshness check`) and the existing Step 5/6 preflight as the freshness test, with no new staleness rule. Falsifier: a plan line that already defines it.
- [Nit] N-D (carried N2): 10days:316 and 320 keep `rating_ovr` and `is_manual_override` as editable frontmatter, and 10days:225 reads ratings `(or capture doc frontmatter)`. start-task:406 says `A displayed copy is a read-back of the DB, never a competing editable ranking`. Fix: add 10days:225 and 316-320 to plan:39's ratings edit, as read-back only. Falsifier: frontmatter is already documented as non-authoritative.
- [Nit] N-E: plan:39 swaps 10days:391 `exclude it from this run rather than firing on an untrustworthy guess` for "HELD", described as `a reporting disposition`. Fix: state that HELD items leave this run's fire list and the Step 5 intersection (10days:410), as planner holds already do (10days:405-406 `drops out of the fire list`). Falsifier: a sniff-failed item walked to Step 6 is not preflighted or fired.
- [Pass] Q9 over-engineering: the revision adds no runner, schema, suite, daemon or numeric cap (plan:25, 38, 41). The "parent selection/recon note" is a prose record, not machinery, once N-B is applied. The only new behaviour beyond minimal is the linked-candidate selection rule, which S-C bounds.

VERDICT: FAIL
Basis: B1, S1 and S5 are resolved, and the re-run B1 sweep finds no live exclusion or silent-drop route. The DoD still fails on "without contradicting live consumer lines" and on S6:
- the new Conveyor "before dispatch" wording conflicts with Conveyor's Step 2→3→4 order and its `--doc-path CAPTURE_PATH` pickup (S-A);
- 10days keeps a second pickup instruction at :338 that the plan does not reconcile (S-B);
- daily-goals linked-candidate selection is a new, unbounded Conveyor rule (S-C);
- the scenario table lacks the red controls its own plan:47 requires (S-D).
All four fixes are text edits to plan:23 and :39 and to the table. None needs new machinery. ROUND 1/1 ends without approval, so STATUS is Escalated. This round used review 2 of 3. A Producer revision that closes S-A to S-D, with the Nits optional, should be reviewable in the final round.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
