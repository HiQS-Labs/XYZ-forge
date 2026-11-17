# RELAY · GH-1476 OL-09 plan QA round 3
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
6. **Commit only the relay file** (`relay(gh1476-plan-qa-r3): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1476-RAW-TASK-PREPARATION.md` revised at `d2ea31935` (round 2 reviewed `c9168dc77`; `git diff c9168dc77 d2ea31935 -- PROJECT/` touches only this plan). This is a PLAN review, FINAL round 3 of 3 total plan-review rounds; no budget reset. No source has been written; the plan must be approved before implementation.
- Prior rounds (FAIL, preserved, do not edit): round 1 `gh1476-plan-qa.md` (B1, S1-S6, N1-N3); round 2 `gh1476-plan-qa-r2.md` Reviewer · Round 1 block (S-A..S-D, N-A..N-E); orchestrator notes `PRIMARY-PLAN-QA.md`. The Producer did not append to the r2 thread; grade the revised plan text itself (plan:23, 38, 39, 49-70).
- Reviewer: claude-review (same-provider Claude subscription route, one review turn, read-only)   ·   Producer: claude-a
- Started: 2026-11-16
- Definition of Done: the revised plan is a coherent, proof-honest, minimal instruction-only slice for OL-09 (umbrella #1400) that resolves round-2 S-A..S-D (and states a disposition for N-A..N-E) without contradicting live consumer lines or reopening round-1 B1/S1-S6, does not claim OL-10 runtime admission or OL-09 operational verification, and keeps #1400's OL-09 checkbox unchecked.

### Operational envelope and non-goals

Local developer harness; instruction (SKILL.md prose) changes only. Out of scope, and themselves findings if the plan requires them: new test suites or `validate.sh` entries, runtime code, new schema/queue/state/readiness database, daemon, installed-skill mutation, amendment of #1328, numeric global research ceilings, live backlog execution. This is an instructions-only plan: do NOT demand runtime tests, model-behaviour proofs or live runs as a condition of PASS; a manual paper walk with red controls is the agreed verification. No operational OL09 credit may be granted or implied. Reject speculative machinery. Grade substantive contradictions, not style.

### Files to read (all at the committed head)

- The plan, in full; the r2 Reviewer block; `PRIMARY-PLAN-QA.md`.
- `skills/1-hourly/conveyor/SKILL.md` (whole file); `skills/3-weekly/10days/SKILL.md` (whole file).
- `skills/1-hourly/start-task/SKILL.md` `## Task rating policy`; `decisions/2026-11-04-gh1333-closure-appeal-row-at-start.md`; `PROJECT/PDDA.md` near 252-310; `utils/py/releases_app.py` `roadmap pickup` parser (~7025-7032).

### Questions

1. S-A: does plan:39 now keep Conveyor Steps 2→3→4 and its pickup command (`--doc-path CAPTURE_PATH`, conveyor:33-36) in today's order, with the only Conveyor wording change being shortlist≠selection≠execution admission? Walk `/conveyor <issue>` through the revised text. Any residual "before research dispatch" for Conveyor?
2. S-B: does plan:39 collapse 10days:338-343 and :393 into exactly one parent-owned pickup at the start of Step 4, after committed selection and before the research child, with `--doc-path` omitted until the capture exists and a later supported repoint? Walk an unrated candidate EXCLUDE/HELD at Step 3 (expect zero rate/pickup writes) and an INCLUDE (expect a row before `marathon-plan.sh --write --deep`). Is "repoint through the supported writer" an existing supported operation (cite it) or new machinery? Is Step 5 `marathon-plan.sh` discovery (10days:393) still satisfied?
3. S-C: is the daily-goals definition (plan:23) bounded: operator-named, explicit #N links reported as candidates, preparation only when named or inside existing batch scope, counted against the existing default five, unlinked goals held, no issue-creation authority? Consistent with conveyor:14-19, 23? Does it add a new intake surface?
4. S-D: does the table (plan:49-66) now give each row an old-source/control type, with existing behaviour labelled regression control rather than a reproduced defect? Does any row labelled red control actually pass on unchanged text (invalid control), or any S6(h)/(i)/(j) gap remain?
5. N-A..N-E: for each, Resolved / Partly / Not, with the plan line (Step 3 cheap triage + full-checklist reuse; capture doc not swarm-preflight packet; freshness = 2-WORKING/has_contract + Step 5/6 preflight; frontmatter read-back 225/316-320; HELD leaves Step 5 intersection and fire list).
6. Regression sweep: does the revision reopen any round-1 item (B1 exclusion/silent drop, S1 selection meaning, S2 write timing, S5 OL-09 unchecked) or introduce a new contradiction with a live 10days/Conveyor/start-task/PDDA line? Cite `file:line`.
7. Over-engineering / missing: flag new machinery or anything still missing for a minimal correct slice. Treat demands for runtime proof as out of scope.

Grade each finding `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`, cite `file:line` or a quoted span, and include `Observed input:` / `Affected scope:` / `Falsifier:` for any finding requesting a change. End with `VERDICT: PASS|FAIL|PARKED` and a non-empty `Basis:`. Include `swept file: yes|no`. Set `STATUS: Approved` only on PASS (Nits alone do not block PASS). Do not edit the plan, earlier threads or any source; append only to this file.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

Agent: claude-review. Read in full at worktree HEAD `06e777cb` (plan at `d2ea31935`): the plan (90 lines), the r2 Reviewer block (`gh1476-plan-qa-r2.md:99-174`), `skills/1-hourly/conveyor/SKILL.md` (71), `skills/3-weekly/10days/SKILL.md` (571), start-task:393/407/418, `decisions/2026-11-04-gh1333-closure-appeal-row-at-start.md`, PDDA.md:290-306, and `utils/py/releases_app.py` `roadmap pickup`/`repoint` (parser 7025-7038, `cmd_roadmap_pickup` 3823-3972). `PRIMARY-PLAN-QA.md` was not read; GitHub #1400/#1476 were not re-fetched.

swept file: yes. I read the whole plan, Conveyor and 10days, plus the writer that plan:39's new pickup instruction relies on. The sweep found one new defect (R3-A), and it comes from my own round-2 S-B fix, which said to omit `--doc-path`. That advice was wrong about the writer.

**Findings**

- [Should] R3-A (Q2, S-B fix): plan:39 says `Where no capture exists, omit optional --doc-path and repoint through the supported writer after capture synthesis; never point to a nonexistent document.` The writer does not behave that way. When `pickup` creates a new row without `--doc-path` and no `GH-N-*.md` exists, it fills in a made-up path and stores it in the row.
  Observed input: `releases_app.py:3866-3877`. When `doc_rel` is empty and no candidate doc is found, the code sets `doc_rel = "PROJECT/2-WORKING/GH-%d.md"`. Lines 3962-3963 then insert that value as `doc_path`. Probe on a scratch copy of `releases.db` (tree unchanged, `git status --porcelain` empty): `python3 utils/py/releases_app.py --root $TMPDIR/root roadmap pickup --issue-num 987654 --issue-url https://github.com/HiQS-Labs/XYZ-forge/issues/987654 --title probe --rated 60/60/50/60 --dry-run`. Result: rc=0, `ROADMAP line: ... [GH-987654.md](PROJECT/2-WORKING/GH-987654.md)`. That file does not exist, and 10days authors `GH-<N>-<slug>.md` instead (10days:318). The consequence: a 10days INCLUDE with no existing doc gets a row pointing at a file that does not exist. If the research child then HOLDs it, no capture is ever written, so nothing repoints the row. Step 7 commits that row anyway (`git add ... releases.db`, 10days:492).
  Affected scope: 10days Step 4 INCLUDEs where `find-doc.sh` returned `bucket: null`.
  No live rule requires the row before research. PDDA.md:300-302 creates the row when work is committed to an actual execution batch, `before dispatch`, and says `Ranking or shortlisting does not`. plan:39 already reads that "before dispatch" as execution dispatch when it reasons about Conveyor.
  Fix (text only, mirrors Conveyor's research→capture→pickup order): in 10days Step 4, record committed selection in the parent note before research, with no ledger write. Run the single parent-owned `pickup` after the capture exists, using its real `--doc-path` (with `--rated`/retained `--ovr`), and before Step 5. Refresh the frontmatter rating display from the read-back after pickup, so N-D's read-back rule still holds. An item HELD after research gets no row in this run.
  Falsifier: walk an INCLUDE with `bucket: null` through the revised text. Expected: zero ledger rows whose `doc_path` names a missing file at any point, a row present before `marathon-plan.sh --write --deep`, and zero writes for a Step 3 EXCLUDE/HELD or a post-research HELD. The current plan text fails the first expectation.
- [Pass] Repoint is an existing supported operation. `roadmap repoint` (`releases_app.py:7034-7038`) exists, and `pickup` repoints an existing row in place (3843-3860). That in-place repoint refuses a path that does not exist (3845-3847 `no-such-doc`). So plan:39's "repoint" is not new machinery. The defect is only the omit-`--doc-path` step on a new row.
- [Pass] Q1 S-A resolved. plan:39 says `Keep Conveyor Steps 2→3→4 and its pickup command unchanged: research, capture, then pickup with the real capture path` and `#1328 before-dispatch here refers to execution dispatch`. Walking `/conveyor 1340`: resolve (conveyor:23), then research per plan:38 (conveyor:25), then capture (conveyor:27), then pickup with `--doc-path CAPTURE_PATH` (conveyor:36). `rg "before research dispatch"` over the plan finds no match. Table row plan:63 is labelled a regression control.
- [Pass] Q2 remainder. The Step 3 EXCLUDE/HELD walk gives zero writes: plan:39 says `Step 3 validity researchers report provisional findings/ratings only, with no ledger writes` and `Step 3 HELD/EXCLUDE candidates receive no selection/rating write`. The two pickup directions (10days:338-343, 393) are collapsed into one, and Step 5 discovery (10days:393) is still satisfied, because the row exists before `marathon-plan.sh`.
- [Pass] Q3 S-C resolved. plan:23 has an operator-named open issue whose body lists goals, linked `#N` reported `as candidates, not automatic selection`, preparation `only when individually named ... or inside the existing authorized batch scope, counting against its item/time limit (existing default five)`, `A goals issue linking twelve tasks does not authorize twelve preparations`, unlinked goals held, and `does not invent issue-creation authority`. This is consistent with conveyor:14-16, :19 `No synthetic backlog` and :23 `/idea only for a separately requested new issue`. It is a variant of the conveyor:14 named-issue input, not a new intake surface.
- [Pass] Q4 S-D resolved. plan:49-66 gives every row a source or control type, and existing behaviour is labelled a regression control (plan:51, 53, 63, 65) per plan:68. The red controls fail on unchanged text:
  - 10days:220 says `Exclude immediately`.
  - 10days:244 classifies low-risk noise as `EXCLUDE`.
  - 10days:288 sends `unreproducible` to `EXCLUDE`.
  - 10days:391 says `exclude it from this run`.
  - 10days:430 says `drop it, propose closing`.
  - 10days:232 and 253 force-clear the override.
  - 10days:250 scores appeal from clarity.
  - 10days:254 has a Step 3 persist.
  - 10days:316-320 has editable frontmatter.
  None of the red controls passes on unchanged text. S6(h), (i) and (j) are explicit at plan:61, plan:56 and plan:65.
- [Pass] Q5. N-A is resolved by plan:39 `Step 3 stays cheap validity triage ... Reuse only a prior record already containing the full medium checklist`. N-B is resolved by plan:38 `capture doc / Conveyor preparation packet, never into the swarm-preflight packet schema`. N-C is resolved by plan:39 `existing 2-WORKING/has_contract route and Step 5/6 preflight, not a new staleness rule`. N-D is resolved by plan:39 `frontmatter ratings/overrides (current lines 225 and 316–320) read-back displays`, but its timing depends on R3-A's fix. N-E is resolved by plan:39 `HELD removes the item from this run's Step 5 intersection and fire list`.
- [Pass] Q6 regression sweep. B1 is not reopened: every exclusion route in 10days (220, 244, 288, 391, 430, 546) is edited by plan:39, and 10days:433-434 already reports every drop. S1 is held by the plan:39 definition of Selected. S2 is held for Step 3; Step 4 timing is R3-A. S5 is held by plan:40 `Do not tick OL-09`. 10days:86-87 (ledger writes only from the Step 4 intake row) still agrees with a Step 4 pickup. I found no new contradiction with start-task:393/407/418 or PDDA.md:296-302 beyond R3-A.
- [Nit] N-F: table row plan:64 expects `exhausted budget prevents launch`, but plan:38 only says to record the remaining budget and `No automatic cap renewal`. Fix: add "with no remaining budget, do not launch; hold with next owner" to plan:38. Falsifier: an existing plan line that already says so.
- [Pass] Q7. No runner, schema, suite, daemon or numeric cap is added (plan:25, 38, 41). The parent note is prose. The R3-A fix removes a write rather than adding machinery.

VERDICT: FAIL
Basis: S-A, S-C, S-D and N-A to N-E are resolved, and the regression sweep reopens no round-1 item. The DoD still fails on "without contradicting live consumer lines" in one place. The S-B fix tells 10days to run `roadmap pickup` without `--doc-path` before any capture exists. A probe shows that writes `PROJECT/2-WORKING/GH-N.md`, a file that does not exist (`releases_app.py:3876-3877`). That contradicts the plan's own "never point to a nonexistent document", and for a post-research HELD the bad row is never repointed. The fix is one sentence: move the single 10days pickup to after capture synthesis, with the real `--doc-path`, before Step 5. This was review 3 of 3 and ROUND 1/1 ended without approval, so STATUS is Escalated to the operator. Handing off to Producer (claude-a) for disposition: go to the Producer window and say "take your turn". The operator decides whether a further round is granted.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
