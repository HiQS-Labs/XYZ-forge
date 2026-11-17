# RELAY · GH-1476 OL-09 plan QA round 3
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-16.
-->

NEXT: Reviewer
STATUS: Open
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
