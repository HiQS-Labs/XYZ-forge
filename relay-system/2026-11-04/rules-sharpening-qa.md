# RELAY · Rule set sharpening: resolve conflicts and contradictions (G/R/P/X + C1-C3, W1, W2)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-04.
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

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: The whole embedded artifact was reviewed, including unchanged rules. Remaining contradictions concern decided policy versus deployed behavior, closure prerequisites, ledger ownership, and incompatible retry counters; the replacements below preserve operator decisions rather than silently creating exceptions.
swept file: yes

Evidence boundary: static source/text inspection only; no git, suites, fixtures, or runtime mutation. Graph discovery was unavailable (`list_projects` returned "MCP tool call requires approval, but approval policy is never"), so the named source locations were read directly. Issue-only decisions are taken from the supplied summary, not independently authenticated against GitHub. Runtime consequences are [Unverified — needs clone run]; the textual contradictions below are directly observable.

- [Should] **F1 — G2/G3 describe a completed rollout; the source explicitly says it is pending.** `decisions/2026-11-03-gh1333-issue-state-authority.md` says "policy decided, not yet implemented"; `PROJECT/PDDA.md:312` retains per-merge moves until the sweep lands. Moreover, `PROJECT/PDDA.md:297` sends any never-actioned closed capture to MISC and removes its pointer, contradicting its own stateReason rules at :300-308 and G3's repoint-only rule. Fix G2/G3 to distinguish binding destination policy from implementation status, and replace the older PDDA sentence at rollout with: "Closed captures follow the stateReason sweep below; existing pointers are repointed, not removed merely because work never started."
  Observed input: PDDA :297-299's "closed without work" versus :303's `COMPLETED` destination and :308's repoint.
  Affected scope: closed inbox captures and all readers/movers pending Tasks 1/9/10 rollout.
  Falsifier: an untouched inbox capture closed COMPLETED must resolve to COMPLETED, not MISC or pointer deletion; NOT_PLANNED resolves to MISC; unknown reason remains reported in place.

- [Should] **F2 — G2/G3 versus the in-flight fallback is a real implementation gap, not a reason to remove coverage.** `utils/pdda/pdda.sh:357-360` checks stored path substrings; :389-390 only accepts an absent inbox file with the identical basename. Renaming a moved doc while retaining its `gh_issue` defeats that fallback. `utils/py/jog_run.py:1524-1527` intentionally leaves the primary pointer alone, and `utils/py/wave_reconcile.py:2392-2397` records evidence without repointing an open issue; therefore even a merged partial delivery can retain a stale inbox pointer indefinitely, not just "until PR merge." G3's closed-issue sweep cannot repair an OPEN issue's promotion cache. Fix G2/C3 and carry explicit rollout wording: "Coverage resolves the doc and existing row by repository-qualified issue identity; an OPEN issue's landed promotion may refresh its cached path without marking it completed, while an in-flight move retains coverage through identity."
  Observed input: working doc with unchanged `gh_issue`, changed basename, absent old inbox file, and row still naming the old inbox basename; literal lookup/fallback at :357-390 cannot identify it.
  Affected scope: moved/renamed GH docs with existing rows, including open issues after partial PR merges; no-row inbox discovery remains a separate cutover concern.
  Falsifier: that renamed doc with a matching issue row remains covered, while a different issue's row does not cover it; an OPEN issue remains active after cache refresh.

- [Should] **F3 — C2 is not an authorized extension of G6a.** G6a freezes 69 existing proposals; C2 silently adds an unbounded new cohort. The incompatibility it identifies is real: `ROUTER.md:49`, `PROJECT/PDDA.md:288-294` and :1009 onward require intake rows; `utils/hq/hq.sh:412` writes one and `utils/pdda/pdda.sh:416-419` reports a missing row. Naming new rows "proposals" does not stop their creation or stored ratings. Correct C2 to report the implementation lag and avoid using a row-writing intake path for new unstarted work until cutover; do not weaken coverage or invent exemptions. P7's 209-issue preparation also cannot be described as currently compatible with every existing filing tool.
  Observed input: C2's "extending G6a to the gap period" versus G6a's "69 existing" and G6's "not when the issue is filed."
  Affected scope: new unstarted intake before the atomic cutover, not existing grandfathered rows or selected work.
  Falsifier: pre-cutover filing of unstarted work that creates no row and still satisfies applicable intake checks would make the operational conflict disappear; merely relabeling a newly created row does not.

- [Should] **F4 — G6b/C3 do not establish a usable dispatch boundary.** "Selection" could mean a ranked shortlist rather than commitment to execute; "before any batch PR opens" permits dispatch before the row/checkpoint exists. Jog rejects execution-clone ledger changes (`utils/py/jog_run.py:533-537`), so selection writes belong to the primary and must reach the disposable execution baseline before dispatch. Reuse existing proposal rows and preserve their ratings; do not create duplicates or recompute appeal. Replace G6b/C3, and replace C3's "again only" with lifecycle-boundary wording so it cannot prohibit necessary primary reconciliation.
  Observed input: shortlist selection under G6b, or dispatch before PR opening under C3, while `_execution_root` rejects ledger drift.
  Affected scope: committed batch/marathon selection and primary-to-execution handoff.
  Falsifier: a proposed shortlist creates no row; committed selected work has exactly one primary row available in a clean execution baseline before dispatch, without lane ledger writes.

- [Should] **F5 — C1 weakens G4, and R6 cannot bypass P5 or independent review.** "Covers the whole issue" in C1 omits G4's *reviewed assertion*; "every Acceptance item" omits the non-empty requirement. A PR can pass checks and cover its lane without satisfying the aggregate #1340/#1333/#1329 closure criteria in P5; `AGENTS.md:349` also forbids test-only review attestation. Correct C1 by referring to G4 and P5, preserve R6's batch-1-only scope, and name the orchestrator as closure actor after evidence review rather than treating the completion sweep as that actor. P1 is ownership, not advance permission to close.
  Observed input: empty Acceptance checklist or a partial Task PR with green checks; C1/R6 alone could emit a closing keyword despite G4/P5.
  Affected scope: each issue linked by a batch PR and the three aggregate closure decisions.
  Falsifier: a partial PR merges without closing its still-incomplete issue and records the reason once; a whole-issue PR with a recorded independent review assertion qualifies under G4, with P5 additionally satisfied for its named issues.

- [Should] **F6 — W1 conflates different counters and leaves bypass routes.** `utils/py/marathon_drive.py:1235` defaults the lane cap to 2, :1250-1267 parks at the prior-launch count, and :1271-1282 appends a fire; this is not a diagnosis/repair/verify round. :2834 resets the lane count on approved phase success, which cannot reset R2's unresolved-blocker history across sessions. Preserve both budgets independently and forbid counter/key resets or cap increases as substitutes for `--force` approval.
  Observed input: a lane with two prior fires and an unresolved blocker with only one repair round; W1's "three rounds, or fewer" supplies no correct mapping.
  Affected scope: launches, internal relay rounds, and outer blocker repairs across resumes.
  Falsifier: a third fire remains parked despite spare outer repair rounds; a fresh lane identity does not grant a fourth repair round for the same unresolved blocker.

- [Should] **F7 — R1 needs R3's exclusions, and W2 must cover strengthening as well as weakening.** A reversible edit to an acceptance predicate is still a design/check-policy change under W2, while R3 only explicitly says "weakening a check." R3's bare nouns "containment/sandbox/auth/credentials" can also be read as requiring renewed approval for ordinary use of already-authorized tools, contradicting `AGENTS.md`'s "Authorization persists across sessions." Define authorized repair as restoring already-agreed behavior, and require new approval for changing those boundaries, not ordinary authorized use.
  Observed input: changing a check's accepted inputs during a routine repair, or asking again to use an already-authorized reviewer account.
  Affected scope: runtime repairs and requests that change approval/security/design boundaries.
  Falsifier: implementation repair against an unchanged acceptance contract proceeds under R1; either widening or narrowing the contract stops for R3, while already-authorized tool use does not require redundant approval.

- [Should] **F8 — R7 is not approved and "reset" risks destructive interpretation.** `AGENTS.md:7` prohibits hard resets in a checkout whose state matters, and Jog :533-537 says preserve/reconcile ledger drift, not erase it. "Merge open PRs first" lacks eligibility/scope limits and "one at a time" is not a global prohibition on the repo's intended parallel marathons. Retain the lesson label, scope it to the proposed batch procedure, and require preserving unique work before refreshing/replacing a disposable execution clone; no fresh authority to merge arbitrary PRs or reset primary/peer work.
  Observed input: an execution clone with unlanded work or ledger drift under the instruction "reset ... before each item."
  Affected scope: batch execution clone refresh and ordering, not primary history or unrelated PRs.
  Falsifier: dirty/unique work is preserved and reconciled before dispatch; an unrelated unreviewed PR is not merged merely because it is open.

- [Should] **F9 — X3's trigger is underspecified, and X5's justification wrongly makes R7 require another host.** "Until the first run" can mean before dispatch, at dispatch, or after completion; the supplied decision does not resolve which, so this review must not invent a security gate or permission to run. Keep the deferral and require its owner to identify the intended trigger before using it to justify that first run. Retain X5's operator-approved retirement, but remove "the second host R7 needs": avoiding concurrent full suites on one host can be met by serialization and R7 remains unapproved.
  Observed input: X3's "until the first run" and X5's "R7 needs" versus R7's "avoid two full-suite gates on one host at once."
  Affected scope: scheduling #1295 against the first generated-plan execution and retirement rationale only.
  Falsifier: the operator's original wording explicitly identifies the trigger event; use that wording directly instead of seeking clarification or guessing.

- [Pass] **C1's separation of merge and closure is sound once tightened; C3's early primary checkpoint is sound once moved before dispatch.** G4 says "Otherwise it leaves the issue open" and G6b says "row is created at selection"; those are the controlling spans, not green CI or PR creation.
- [Pass] **G5, P3/P6 and the X5 retirement decision need no reversal.** G5's "neutral 50 unless the operator supplies a value," P3's "one PR," P6's "waits for the cutover," and X5's "op approved retiring" are internally compatible. No additional pre-existing textual defect found in the unchanged IDs listed below; this is not runtime certification.
- [Nit] **Reduce duplicate policy bodies.** C1 should refer to G4/P5, C3 should implement G6b, and W1/W2 should refer to R2/R3 rather than maintain rival thresholds. P4's "overridable" adds nothing beyond its agreed status; X1/X2 can share a line, but X2's completed re-rating remains historical evidence rather than another instruction to rate.

Consolidated replacements (proposals for the Producer; operator decisions remain decided, agreements remain agreements, and R7 remains unapproved):

- G2: Readers resolve a GH doc by repository-qualified issue identity (`gh_issue`, otherwise the GH filename prefix; `source` disambiguates a foreign repository); stored paths are caches. This is decided policy pending the reader rollout, not a claim that today's path-based readers comply.
- G3: The planned single idempotent sweep reads current CLOSED issue state in both inbox and working folders, moves COMPLETED to `3-COMPLETED` and NOT_PLANNED to `4-MISC`, and leaves OPEN or unknown cases in place (reporting unknown cases); it repoints only existing rows and never closes issues. Until it lands, the documented per-merge mover and drift reporter remain the implementation, with their gaps explicit; remove the conflicting "closed without work" destination/removal text when implementing the sweep.
- G4: For each issue, the orchestrator may close at merge only with a recorded independent review assertion that the delivered lane covers the whole issue, or a non-empty Acceptance checklist whose every item is checked, additionally satisfying P5 for its named issues. Otherwise leave it open with one delivery/reason comment; mention alone is never authority, and use `Refs #N` plus "leaves #N open" rather than negated closing keywords.
- G6: The decided cutover policy creates a PRS row and stored rating when work starts, not at filing; until then the rating proposal belongs in the issue body. G6a is the bounded existing-row exception, and C2 describes current implementation lag without enlarging that exception.
- G6b: Selection means committing an issue to the actual execution batch or marathon, not merely ranking or shortlisting it. At that point create its primary row, or reuse its existing proposal row and rating, before dispatch.
- R1: During a run, repair routine reversible implementation defects without asking when the repair restores already-agreed behavior within the authorized scope. R2/W1 bound the attempts, and R3/W2 exclude changes to acceptance, design, safety, authority, or spending boundaries.
- R2: Count at most three diagnosis/targeted-repair/verification rounds per unresolved blocker across sessions and wakes, retaining the count and evidence in existing run records. At exhaustion file/update the issue, keep the milestone visibly blocked, and continue only independent eligible work; W1 independently limits tool launches and retries.
- R3: Obtain operator approval for force push, deletion of unlanded work, history rewrite, acceptance/check-policy changes or bypasses, changes to containment/sandbox/authentication/credential boundaries, ledger schema, merge policy, design/architecture, spending or access beyond existing authorization. Existing explicit authorization continues within its stated scope; routine use of an authorized tool/account is not a new boundary change.
- R6: For batch 1 only, merge batch PRs automatically once required checks and independent review are satisfied within the approved merge scope. Merge permission does not authorize issue closure, which follows G4/P5, or automatically extend to batch 2.
- R7: Unapproved batch lesson: execute items serially, first land eligible prerequisite PRs through normal review/merge rules, and refresh a disposable execution clone from current origin/development only after preserving and reconciling any unique state. Keep ledger writes/checkpoints on the primary under C3 and avoid overlapping full-suite gates on one host; this authorizes neither destructive reset nor merging unrelated PRs nor a global ban on parallel marathon lanes.
- P1: This session owns delivery of #1340 Tasks 1-12 and evaluating closure of #1333, #1340 and #1329 under G4/P5. Ownership is not advance closure approval.
- P4: Task 13 moves to its own dated issue under the current session agreement.
- P5: After reviewed evidence establishes Tasks 1-12 merged with PR, merge SHA and a manual check under `TESTS-RESULTS/` with committed provenance, the orchestrator closes #1340 and then #1333 under G4. Close #1329 only after every batch-protocol idea is explicitly adopted or declined in #1298's batch 2 report; a partial task PR must not close these aggregate issues early.
- P7: The earlier request to register the 209 no-row issues is superseded by Task 5's preparation of issue text, capture doc, contract and issue-body rating proposal, without creating rows merely for intake. Execute that preparation through the cutover-compatible intake path; C2 is not permission to bulk-register them meanwhile.
- X3: #1295 remains deferred to the first execution of a plan or launch packet generated by `factory-primitive`. The summary does not establish whether action is due before dispatch, at start or after completion; resolve that timing from the operator's original instruction before relying on the deferral to schedule the first run.
- X5: Retired by operator approval: the 2026-10-31 restriction on long Mac Studio runs pending admission/landing evidence. The recorded basis is census 6/298 and batch 1 landing 5/6; retirement does not depend on R7 requiring a second host and does not waive other run gates.
- C1: Until Task 7 implements closure policy, write a closing keyword only when G4 and any applicable P5 criteria are met; otherwise use `Refs #N` and "leaves #N open" with the single reason comment. Batch-1 auto-merge remains governed by R6 independently of closure.
- C2: Current intake tools and coverage rules still require/write rows at filing, so G6 is decided policy awaiting the atomic cutover; do not treat new gap-period rows as an approved expansion of G6a. Until a compatible intake path exists, defer affected new unstarted intake through those row-writing paths rather than create prohibited rows, invent exemptions, or weaken coverage; selected work may still obtain its row under G6b.
- C3: On committed selection, write/reuse the rows on the primary and checkpoint them before dispatch, making that baseline available to the clean disposable execution clone; lanes do not write the ledger. After landing, reconcile and checkpoint on the primary, refreshing existing path caches for landed OPEN-issue promotions without completing them and leaving closed-issue terminal moves to G3's sweep once deployed.
- W1: Enforce R2's blocker repair-round budget and each tool's configured launch/round budget independently, stopping when the next action would exceed either applicable limit; Marathon's default two lane fires are not two outer repair rounds. Do not bypass exhaustion with `--force`, increased caps, erased counters, or replacement identities without operator approval, and never reset an unresolved blocker's R2 count merely because a tool resets its own counter.
- W2: Runtime repairs may restore a check's implementation to its already-agreed acceptance contract, but changing that contract in either direction requires R3 approval. A green result does not authorize changing what the check accepts.

Unchanged IDs: G1, G5, G6a, R4, R5, P2, P3, P6, X1, X2, X4. C1/C3/W1/W2 are corrected; C2's extension of G6a is rejected and replaced with an implementation-gap rule.

Handing off to Producer (claude-a) — disposition each finding and revise the embedded rule set; then return it for review.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
