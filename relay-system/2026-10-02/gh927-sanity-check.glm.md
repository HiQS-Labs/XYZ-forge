# RELAY · GH-927 sanity-check independent GLM QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-02.
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
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-927-sanity-check-independent-glm-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/1-hourly/sanity-check/SKILL.md`, `skills/3-weekly/whack-a-mole/SKILL.md`, `skills/3-weekly/radar/SKILL.md`
- Reviewer: commandcode   ·   Producer: codex-producer
- Started: 2026-10-02
- Definition of Done: The operator requirements and review questions below are satisfied by the current Markdown instructions.

## Operator requirements and review questions

Provide an independent QA assessment of the current three skill files. Read them
in full; compare their diff to origin/development. Do not use the prior reviewer
verdict as evidence. The user selected Command Code, zai-org/glm-5.3, max effort.

Operational envelope: Markdown-only instructions for local coding agents. No new
scripts, suites, runners, or gates. This review is static behavioral QA, not a
request to run the skills, repair a live incident, file issues, or publish reports.
Only this relay file is writable. Do not run mutation-heavy suites, executable
fixtures, other agents, or broad audits from the review worktree.

Requirements: sanity-check assesses the first blocker, deepens on stalled
progress, asks about a core/user-facing capability's importance only when unclear,
and separates the reality of a failure from its necessity and urgency. Reuse
recon, debug-mantra, and ponytail. It may defer demonstrated low-risk work with
PRS-rated GitHub intake; feature retirement or weakening a required gate needs a
concrete operator decision. After two investigation attempts yield no new
evidence, reassess before another retry. Recommend whack-a-mole/radar when their
scope fits and add reciprocal operator-facing pointers without recursive audits
or inherited publication authority.

Read the relevant reference sections in recon, debug-mantra, ponytail,
triangulate, ci-suite-audit and start-task's rating policy as needed; do not
execute those workflows. Apply commensurate complexity: ask only for concrete,
material corrections, not speculative enterprise controls or extra machinery.

1. Does the decision ladder distinguish real failure, requirement value, current
   blocker, severity, and priority without masking an integrity/security risk?
2. Is the two-attempt reassessment rule actionable and bounded? Can it become an
   excuse to abandon a necessary repair or repeat the same assessment forever?
3. Are uncertainty, operator importance questions, residual risk, existing gates,
   reversible containment and retirement decisions handled consistently?
4. Does deferred-work intake reuse PRS correctly (four axes, cheapness direction,
   neutral appeal, preserved overrides, deduplication, redaction), without
   lowering severity to justify scheduling?
5. Are the recommendations and reciprocal pointers consistent with the full
   whack-a-mole/radar instructions, including priority and approval rules? Does
   an assessment of one cluster member improperly govern a wider cluster?
6. Walk through: a wording-only required gate after an authorized prose change;
   the sole transaction-integrity guard failing; an advisory unsupported-platform
   canary; two inconclusive probes of credible exposure; a low-risk member of a
   broader recurring cluster; and a Radar handoff on unchanged evidence. State
   disposition, any operator question, and allowed next action. Label these as
   static walkthroughs, not executed tests.

Cite exact file:line or quoted text. Each behavior-change finding needs Observed
input, Affected scope and Falsifier; a Blocker must cite an observed failure.
Report all material findings, distinguish pre-existing unrelated limitations,
and give PASS/FAIL/PARKED. A missing citation is not a verified finding. Existing  [Unverified — no citation]
metadata validation reports Radar's unchanged 1336-character description above
the validator's 1024-character maximum; this limit predates the added pointer.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

Independent static QA (commandcode, GLM seat). Method: read all three artifacts in full (`skills/1-hourly/sanity-check/SKILL.md` — 222 lines, new vs origin/development; `skills/3-weekly/whack-a-mole/SKILL.md` — one added sibling section L161–178; `skills/3-weekly/radar/SKILL.md` — one added sibling section L632–645); read recon, debug-mantra, ponytail, triangulate, ci-suite-audit, and start-task (incl. its rating policy) in full to cross-check every reused-skill claim; ran four read-only probes (quoted below). No prior reviewer verdict used as evidence.

swept file: yes

**Findings**

- **[Nit] Cluster-scope qualifier missing on the reciprocal disposition-reuse pointers.** whack-a-mole L173–174 ("For a cluster with a current sanity-check disposition, cite that assessment in §6's Priority `because` line") and radar L643 ("reuse any current sanity-check disposition for the same evidence") do not require the disposition's scope to cover the cluster or its shared mechanism rather than a single member. sanity-check's own reuse rule is scope-bound ("Reuse a current sanity-check disposition for the same scope and evidence", sanity-check L156), but whack-a-mole's pointer attaches a priority consequence ("A `Defer` or `Dismiss` disposition overrides the recurrence-only top-tier rule below", whack-a-mole L175–177), so a member-scoped Defer could pull a whole cluster's priority tier down.
  - Observed input: static walkthrough — cluster C = {#1, #2, #3}; sanity-check previously returned `Defer` for member #1 alone during an unrelated task; a whack-a-mole run finds C with 2 reopens; L173's condition "For a cluster with a current sanity-check disposition" is satisfied by #1's member-only disposition under a literal reading.
  - Affected scope: the two reuse sentences (whack-a-mole L171–174, radar L643); the predicate the qualifier would govern is "an existing sanity-check disposition exists for the cluster or its shared mechanism", excluding single-member dispositions.
  - Falsifier: whack-a-mole L297 ("set to the **highest value the evidence supports** on that scale") plus sanity-check L156 — if the Producer shows these already make a member-scoped citation impossible to act on, the qualifier changes nothing and is unnecessary; expected result in that case is identical behavior.
  - Concrete fix: qualify both pointers — whack-a-mole: "For a cluster with a current sanity-check disposition **covering the cluster or its shared mechanism (not a single member)**…"; radar: "reuse any current sanity-check disposition for the same **scope and** evidence". Wording-only; no machinery.
  - Grade rationale: bounded blast radius — the misrating stays visible at §7's exact-body operator approval (whack-a-mole L322 "Never file without approval"), and L168 ("Preserve the repository's evidence-based severity/priority rules") plus L176–177 ("rate at the highest value the combined consequence and scheduling evidence supports") constrain the outcome.
- **[Pass] Artifact scope and diff match the Setup.** `git diff --stat origin/development` (exit 0): sanity-check +222 (new file; absent from `git ls-tree -r origin/development`), whack-a-mole +19, radar +15 — only the two sibling sections; radar's frontmatter and description are untouched by the diff, matching the operator's note.
- **[Pass] Reuse claims are accurate.** Every row of sanity-check L49–57 matches the named skill's actual content: recon traces consumers/contracts/state (recon L68–73); debug-mantra observes/falsifies/preserves findings (debug-mantra L12–16); ponytail minimizes the mechanism once requirements are established (ponytail L21–27, L52–55); triangulate arbitrates evidence depth (triangulate L63–69); ci-suite-audit's contract/unique-coverage/assertion-quality criteria with manual-only invocation (ci-suite-audit L26, D3–D5, D9 L166–172); start-task rating policy reuse without launching its lifecycle (start-task L27–28); unstuck resumes the original task. All relative links resolve (probe 3, exit 0).
- **[Pass] No new machinery, consistent with the envelope.** sanity-check L18–19: "It does not need scripts, a new scoring system, a CI gate, or a full audit to judge one blocker."; L128 (Simplify) verifies "through existing checks or appropriate manual evidence"; L98–99 runs mutation-heavy probes "in the isolation required by the repository". Markdown-only; no scripts, suites, runners, or gates added.

**Review questions**

1. **[Pass] The ladder separates all five concerns without masking integrity/security risk.** Blocker reality: L66–72 (name goal, source of the blocking claim, "A red status alone does not explain product harm; an enforced gate can still be a real delivery blocker"). Real failure: L93–101 (validate claim, classify observation). Requirement value: L84–91. Severity: L74–82 + L186–188. Priority: L115–120 + L189–191. Masking is explicitly blocked: L77–79 ("For ongoing corruption, data loss, or security exposure, prioritize reversible containment within existing authority and escalate consequential actions"), L82 ("Record unknown exposure explicitly; do not label it safe by default"), L91 ("A low-value feature can still contain a high-severity defect"), L131 ("Do not translate uncertainty into low risk"), L186–188 ("Keep serious corruption or exposure serious even when the feature is unpopular").
2. **[Pass] The two-attempt rule is actionable and bounded in both directions.** Actionable: L162–164 ("**After two investigation attempts yield no new evidence, reassess before another retry.** Count consecutive attempts; eliminating a plausible cause is new evidence. An attempt is a probe or experiment, not a commentary update.") and L168–169 ("State what the next experiment could distinguish and how either result would change the disposition."). Cannot abandon a necessary repair: L165–166 ("This is a review trigger, not a timeout that permits ignoring a necessary defect") + L169–170 ("Continue when that experiment is justified by the consequence"). Cannot loop forever: L26 ("Do not repeat the assessment on every retry without new information"), L155–157 (reuse disposition for same scope/evidence; no straight-back handoffs), L171–173 ("Do not cycle through skills, add instrumentation, or raise retry caps merely to remain active… the same failed hypothesis cannot" reopen).
3. **[Pass] The six concerns are handled consistently across all three files.** Uncertainty: sanity-check L131, L99–101 ("failure to reproduce is uncertainty, not disproof"); whack-a-mole L230 ("What I could not verify"); radar L60–61 ("Degrade loudly") — same philosophy. Operator importance questions: sanity-check L28–30 and L86–90 (only when unclear, operator-answerable form, "Continue independent read-only work while awaiting an answer; do not treat silence as agreement to reduce scope"). Residual risk: L129 ("bounded, low residual risk"), L179–181 (intake fields incl. residual risk/mitigation and revisit trigger), L216 (report field). Existing gates: L36 ("Deferring a repair does not waive a required gate or establish merge readiness"), L129 ("no required acceptance condition is silently waived"). Reversible containment: L77–79. Retirement: L33–35 (propose-only, execute on authorization), L130, L112–113 ("removal of a redundant implementation requires evidence that those properties remain"). Siblings' boundaries intact and unweakened: whack-a-mole L31–32, L322; radar L46–47, L612–615.
4. **[Pass] Deferred-work intake reuses PRS faithfully.** Four axes 1–100 (L184) = start-task L242–244. Severity includes "credibly supported potential harm" and is not lowered to rationalize scheduling (L186–188, L189–191) = start-task L249–250. Appeal 50 neutral, prior explicit choices preserved (L192–193) = start-task L251. Effort is cheapness, "higher means easier, not more work" (L194–195) = start-task L252. `ovr` preserved, supported writer, read-back, "Never alter the sum formula or invent an urgency multiplier" (L197–200) = start-task L276–280. Dedup first (L177–178) = start-task L55–56. Redaction and private route (L202–203) matches whack-a-mole L36. No-PRS repos use the existing record, nothing installed (L181–182) = start-task L267–268.
5. **[Pass, with the Nit above] Pointers are consistent with the full sibling instructions; member→cluster leakage is guarded except for the Nit.** sanity-check L138–142 defers to whack-a-mole's own verification ("It verifies the cluster and root cause under its own rules; repetition does not establish a shared cause or automatically make the work top priority") — matching whack-a-mole §3 (L114–127) and §5 (L194). Radar scope gate at L143–146 ("One red check alone is insufficient") matches radar's 3-lens design. Run-only-on-request/authorization (L149–150) matches whack-a-mole L322 and radar L612–615. No inherited publication authority (L151–152); radar-report reuse (L152–153) matches whack-a-mole's GH-781 seed (L71–91); anti-recursion holds in all three directions (sanity-check L155–157, whack-a-mole L172–173, radar L643–645). whack-a-mole's priority override states its precedence explicitly ("overrides the recurrence-only top-tier rule below", L175) and keeps the harm floor (L177–178). The member-vs-cluster gap is the [Nit].
6. Walkthroughs below (all **static** — instruction reads, not executed tests).

**Static walkthroughs (a–f) — labeled static, not executed tests**

- **(a) Wording-only required gate after an authorized prose change — static.** Disposition: **Fix now** — the enforced gate is a real blocker (L71–72) but "Updating expected content after an intentional, authorized change is ordinary repair when the protected contract is preserved; narrowing coverage is weakening" (L37–38). Operator question: none — the change is already authorized; a question arises only if the repair would narrow coverage, which is gate-weakening requiring operator decision (L33–35). Allowed next action: update the expectation preserving coverage via the existing repair workflow (L127), then resume (L117–118).
- **(b) Sole transaction-integrity guard failing — static.** Classify first (L96–101). If corruption is ongoing: **Contain now** — reversible containment within existing authority, escalate consequential actions, "Do not replay a destructive failure against live data" (L77–79, L126). Otherwise **Fix now** — a "correctness property, or required gate" (L127). Sole coverage forecloses redundancy claims: "Similar names or shared entry points do not prove duplicate coverage" (L107–108) and "removal of a redundant implementation requires evidence that those properties remain" (L112–113). Operator question: only if containment exceeds existing authority (L78–79). Allowed next action: containment, then route repair; retirement unavailable without operator decision (L33–35).
- **(c) Advisory unsupported-platform canary — static.** "A red status alone does not explain product harm" (L70–71); advisory ≠ enforced gate, so it does not block the goal (L66–72). Disposition: **Defer** — "Evidence supports bounded, low residual risk; no required acceptance condition is silently waived. Record an issue and revisit trigger" (L129), e.g. "before enabling the affected feature" (L181–182); **Dismiss** only with direct evidence disproving the problem (L132). Severity stays honest — portability drift recorded, not inflated or excused (L186–188). Operator question: only if the capability's importance is unclear (L28–30). Allowed next action: file the PRS-rated issue, resume the original task.
- **(d) Two inconclusive probes of credible exposure — static.** The rule fires: "After two investigation attempts yield no new evidence, reassess before another retry" (L162–163). Reassessment must state "what the next experiment could distinguish and how either result would change the disposition" (L168–169); credible exposure keeps consequence-weighted continuation open (L169–170) and severity honest ("credibly supported potential harm", L187). If no justified experiment remains: **Unresolved** — "Name one discriminating observation or one exact operator question. Do not translate uncertainty into low risk" (L131), unknown exposure recorded explicitly (L82). Not an abandonment license (L165–166). Operator question: the one exact question, if reached. Allowed next action: the justified experiment, or surface the question; no retry-cap inflation or skill cycling (L171–172).
- **(e) Low-risk member of a broader recurring cluster — static.** Member: **Defer** with PRS-rated issue (L32–33, L129). Cluster: recommend whack-a-mole, passing "the concrete incidents, suspected shared mechanism, and any existing umbrella" (L138–141); it "verifies the cluster and root cause under its own rules" (L142), so the member's Defer neither verifies nor governs the cluster — subject to the [Nit] on the siblings' side. Operator question: none for the recommendation; running the sibling needs operator request or existing authorization (L149–150). Allowed next action: file the member issue, recommend the sibling, resume — "A recommendation does not pause unrelated work or start a scheduled monitor" (L158).
- **(f) Radar handoff on unchanged evidence — static.** A recommendation requires "observed evidence supports its scope" (L136) and must state "the evidence and decision the sibling would inform" (L148); on unchanged evidence there is no new decision to inform, and existing reports are passed rather than re-run (L146; L152–153 "reuse a current radar report as input to whack-a-mole; do not require a new radar run"). Radar's side: "Do not bounce back into Radar through a reciprocal pointer unless the scope or evidence has materially changed" (radar L643–645). Disposition: **reuse the current disposition/report** for the same scope and evidence (L155–157). Operator question: none. Allowed next action: continue the original task; no new radar run, no scheduled monitor (L158).

**Pre-existing limitations (distinguished, not counted against this change)**

- Radar's frontmatter description is 1336 characters, above the metadata validator's 1024 maximum. Verified by probe 2 and by committed evidence `TESTS-RESULTS/2026-10-02+GH-927/manual-validation.json` (radar: exit 1, "Description is too long (1336 characters). Maximum is 1024 characters."). The description is unchanged by this diff (only the L632–645 sibling section is added), matching the operator's note; already parked as `PARKED/2026-10-02-radar-description-limit.md`. Not a finding about the added pointer.
- whack-a-mole's description measures 1019 characters — under the limit, passes validation (manual-validation.json exit 0, "Skill is valid!"); unchanged by this diff. Noted for headroom only (5 chars).
- No other pre-existing defects found in the touched files during the full-file sweep (whack-a-mole §1–§7 and radar Steps 0–5 + guardrails + boundaries read in full; their approval/publication boundaries cited under Q3 are intact and unweakened by the additions).

**Probes (read-only, non-mutating; scratch under .relay-scratch/, discarded after this turn)**

1. `git diff --stat origin/development -- <three files>` → exit 0: sanity-check "222 +++…", whack-a-mole "19 +++", radar "15 +++", "3 files changed, 256 insertions(+)"; `git ls-tree -r origin/development` → no `skills/1-hourly/sanity-check/` on the base (only an unrelated `relay-system/2026-09-27/gh863-merge-sanity.md`).
2. `PYTHONDONTWRITEBYTECODE=1 python3 .relay-scratch/measure_desc.py` → exit 0: "sanity-check -> 445 chars / whack-a-mole -> 1019 chars / radar -> 1336 chars".
3. Link resolution from each file's own directory (`test -f` on the relative targets) → exit 0 for all five links (sanity-check → whack-a-mole, radar; whack-a-mole → sanity-check; radar → sanity-check).
4. Full reads of the seven referenced skills cross-checked against sanity-check L49–57 — all contributions as described (finding above).

**VERDICT: PASS**

Basis: every operator requirement and review question is satisfied by exact-citable instructions in the current Markdown (cited per finding above); the sole [Nit] is a wording qualifier with a bounded, approval-gated failure path — not a material correction under the commensurate-complexity envelope; the radar description-length item is pre-existing, unchanged by this diff, and already parked with its own decision path. Definition of Done met. No clone-run-dependent claims were made: all findings are static reads or read-only probes quoted above.

relay closed (Approved) — no further Producer turn needed; token closed with `tick done`.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
