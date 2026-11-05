# RELAY · Rule set sharpening: resolve conflicts and contradictions (G/R/P/X + C1-C3, W1, W2)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-04.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(rules-sharpening-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **rules-artifact.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-04

### Artifact — rules-artifact.md
```
# Consolidated rule set for the XYZ Forge factory work (2026-11-04)

Status key: **op** = decided by the operator; **agreed** = agreed between two sessions (AgentChorus #542648), not separately approved; **proposed** = this review's subject.
Where written today: G1-G3 in `PROJECT/PDDA.md` (~:45-51, ~:296-312) and `decisions/2026-11-03-gh1333-issue-state-authority.md`; G4-G6b only in GitHub comments on #1333/#1340; R1-R5 in issue #1328 and an `AGENTS.md` pointer (Standing authorization section); the rest in issue comments.

## G — Governance (issues, docs, ledger)
- **G1 (op)** GitHub issue state is the only authority for "done". A doc's folder and its ledger section are views of it.
- **G2 (op)** Readers find a `GH-<n>-` doc by issue number, never by a stored path.
- **G3 (op)** One idempotent completion sweep keyed on `stateReason`: `COMPLETED` -> `3-COMPLETED`, `NOT_PLANNED` -> `4-MISC`, anything else stays and is reported. Covers `1-INBOX` and `2-WORKING`, repoints only existing rows, never closes an issue.
- **G4 (op)** The merge step closes an issue only if (a) a reviewed assertion says the lane covered the whole issue, or (b) the issue has a non-empty Acceptance checklist with every item checked. Otherwise it leaves the issue open with one "delivered, left open because …" comment. Never close on a mention alone; never use negated close keywords ("does not close #N" closes #N; write "leaves #N open").
- **G5 (op)** Keep the appeal axis: neutral 50 unless the operator supplies a value.
- **G6 (op)** A ledger row (and its stored PRS rating) is created when work starts, not when the issue is filed. Until then the rating proposal lives in the issue body.
- **G6a (op)** The 69 existing "Queue / parked intake" rows stay as proposals; no migration now; revisit ~1 month after the cutover.
- **G6b (op)** Selection into a marathon or batch counts as work starting; the row is created at selection.

## R — Run rules (issue #1328 and batch 1)
- **R1 (op)** During a run the orchestrator repairs routine, reversible defects without asking.
- **R2 (op)** At most three counted repair rounds (diagnose, targeted repair, verify) per unresolved blocker, counted across sessions and wakes; then file/update an issue, keep the milestone visibly blocked, move only to independent eligible work.
- **R3 (op)** Still ask the operator for: force push, deleting unlanded work, history rewrite, weakening a check or `--no-verify`, containment/sandbox/auth/credentials, ledger schema, merge policy, design or architectural choices, spending or access.
- **R4 (op)** A run with agent repairs is reported as agent-assisted, never as unattended qualification.
- **R5 (op)** Before proposing a milestone: three gates as a three-line check (capability vs observed baseline; critical-path blocker removed; evidence + budget + escalation). No separate document per milestone.
- **R6 (op, batch 1 only)** Batch PRs merge automatically once checks are green.
- **R7 (lessons, not approved)** Run items one at a time; reset the execution clone's `development` to origin before each item; merge open PRs first, checkpoint the primary's ledger after; avoid two full-suite gates on one host at once.

## P — Plan and ownership
- **P1 (agreed)** This session owns #1340 Tasks 1-12 and closing #1333, #1340, #1329.
- **P2 (agreed)** Order: Task 1 -> Task 10 -> Task 9 -> one cutover PR (Tasks 2, 3, 4, 6 + Task 11 rating contract, with Task 5 as the #1298 rollout instruction) -> Task 7 -> Task 8 -> Task 12 -> #1332 item 2 -> #1298 batch 2.
- **P3 (agreed, from #1340)** The cutover lands as one PR (filing stops creating rows only when pickup and no-row discovery exist).
- **P4 (agreed, overridable)** Task 13 moves to its own dated issue.
- **P5 (agreed)** #1340 closes when Tasks 1-12 are merged with PR, merge SHA and a manual check under `TESTS-RESULTS/`; #1333 closes when #1340 closes; #1329 closes when each batch-protocol idea is marked adopted/declined in #1298's batch 2 report.
- **P6 (agreed)** Batch 2 waits for the cutover (needs Task 4's no-row discovery).
- **P7 (follows G6)** The operator's earlier request to register the 209 no-row issues is replaced by #1340 Task 5 (prepare issue text, capture doc, contract and a rating proposal in the issue body; no row).

## X — Specific items
- **X1 (op)** #670 deferred. **X2 (op)** #670 severity re-rated 60 -> 20 (done). **X3 (op)** #1295 deferred until the first run of a plan or launch packet generated by `factory-primitive`. **X4 (op)** #1332 item 2 after the cutover.
- **X5 (op approved retiring)** "No long Mac Studio runs until admission and landing produce evidence" (set 2026-10-31). Its condition is met (census 6/298; batch 1 landed 5/6) and it blocks the second host R7 needs. **Retired.**

## Proposed fixes (from a first conflict pass)
- **C1** R6 vs G4: until Task 7 lands, a batch PR writes `Closes #N` only when it covers the whole issue or every Acceptance item; otherwise `Refs #N` + "leaves #N open". Auto-merge may stay.
- **C2** G6 vs current tools: until the cutover PR lands, filing keeps today's behaviour (rows at filing) and those rows count as proposals, extending G6a to the gap period. Reason: the inbox coverage check (`utils/pdda/pdda.sh` ~:415-430) errors on a capture with no row, and the planner discovers work only from rows.
- **C3** R7 vs G6b: checkpoint the primary's ledger once right after selection, before any batch PR opens, then again only after the PRs merge.
- **W1** R2 vs harness caps: three rounds, or fewer where a tool's own cap is lower (Marathon parks a lane after 2 attempts); never `--force` past a cap without operator OK (R3).
- **W2** R1 vs R3: run-time repairs never change what a check accepts; that always goes through R3.
```
- Definition of Done: one sharpened, internally consistent rule set: every remaining conflict or contradiction between two rules (or between a rule and the repo text it governs) is named with its evidence and given exact replacement wording; the proposed fixes C1-C3, W1, W2 are confirmed, corrected or rejected. Operator decisions (op) are not reopened; only their wording, scope and interaction are sharpened.

**Operational envelope.** Local single-operator repo; this is a rules-text review, nothing executes. Read the repo checkout (current `development`): `PROJECT/PDDA.md` (G1-G3 text ~:31-60 and ~:290-315; roadmap ledger contract ~:979), `AGENTS.md` (Standing authorization section, the #1328 pointer), `utils/pdda/pdda.sh` (`check_roadmap_coverage`, ~:330-430), `utils/py/jog_run.py` (`promote_contract_to_working` ~:1438; `_execution_root` ~:524), `utils/py/wave_reconcile.py` (~:2380-2420, `update_roadmap_entry` ~:1540), `utils/hq/hq.sh` (park ~:300-360). Issues #1328, #1333, #1340 are not in the repo; their relevant text is summarised in the artifact. Commensurate complexity: no new machinery, suites or gates (GH-831). Run no git, no suites. Edit only this relay file.

**Questions.**
1. **Conflicts left.** List every pair of rules (or rule vs repo text) that still contradict each other or cannot both be followed today, after applying C1-C3, W1, W2. Cite `file:line` for repo-text cases. Pay attention to: G4 vs R6 vs P5 (who closes what, when); G6/G6b/C2/C3 vs `pdda.sh` inbox coverage and `hq park`; G3 vs the #1339 in-flight fallback in `pdda.sh` (`2-WORKING` doc covered by a `1-INBOX` pointer); G2 vs that same fallback; R2 vs Marathon's lane-attempt cap; R1 vs R3; X3's trigger wording.
2. **The proposed fixes.** For each of C1, C2, C3, W1, W2: correct and minimal? If not, give the replacement wording.
3. **Ambiguities that will cause a wrong action.** Any rule whose wording a later agent could reasonably misread into an action the operator did not decide (e.g. "selection" in G6b, "reviewed assertion" in G4, "routine, reversible" in R1, "fewer where a tool's own cap is lower" in W1). Give tighter wording.
4. **Redundancy.** Any rule that duplicates another and should be merged, or that is now obsolete (as X5 was).
5. **Output.** End with a single consolidated list: `ID: final wording` for every rule you changed, plus a list of unchanged IDs. Keep each rule to one or two sentences.

Grade findings `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`; a finding that asks for a wording change needs the concrete conflicting pair or the misreading it prevents.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
