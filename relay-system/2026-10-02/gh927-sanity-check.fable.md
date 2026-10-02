# RELAY · GH-927 sanity-check skill and sibling logic QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-02.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 3

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
6. **Commit only the relay file** (`relay(gh-927-sanity-check-skill-and-sibling-logic-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/1-hourly/sanity-check/SKILL.md`, `skills/3-weekly/whack-a-mole/SKILL.md`, `skills/3-weekly/radar/SKILL.md`
- Reviewer: claude-fable   ·   Producer: codex-producer
- Started: 2026-10-02
- Definition of Done: The operator requirements and QA questions below are satisfied without new runtime machinery or unauthorized side effects.

## Operator requirements and QA scope

Review the entire sanity-check skill and the entire two sibling files, including the inserted pointers (compare with origin/development). Reference skills: recon, debug-mantra, ponytail, triangulate and start-task rating policy. Do not invoke their workflows. This is static behavioral QA of Markdown instructions for local coding agents, not a runtime incident or a request to execute any repair or audit.

Operator decisions: activate at the first blocker and deepen on stalled progress; ask about core/user-facing importance only when unclear; defer low-risk work with PRS-rated GitHub intake; propose removals or weakening of required gates. Explicitly reassess after two investigation attempts yield no new evidence before another retry. Recommend whack-a-mole and radar with appropriate scope and add reciprocal pointers. User requested Claude Code Fable at high effort for this QA.

Commensurate scope: three Markdown skill files only. No new scripts, suites, gates, or enterprise architecture. Preserve safety and the sibling skills' existing approval boundaries. Do not file issues or publish reports. Your only writable artifact is this relay thread. Do not run validation suites, fixtures or executable tests in the worktree. Do not run other agents or audits.

Questions:
1. Does the ladder distinguish a real failure, requirement value, actual dependency, and urgency without excusing necessary correctness/security/integrity controls?
2. Is the two-attempt trigger unambiguous and bounded without abandoning high-risk unknowns or allowing endless ritual reassessment?
3. Are PRS axes, uncertain severity, operator overrides, deduplicated issue intake and public-issue redaction coherent with existing policy?
4. Are whack-a-mole/radar recommendations specific, proportionate, nonrecursive, and consistent with their independent authorization boundaries? Identify any pre-existing text in those files that defeats the new pointers.
5. Work through these scenarios as written and report the disposition, question (if needed), and allowed next action: a wording-only CI assertion after a prose edit; the sole transaction-integrity guard failing; an advisory unsupported-platform canary; two inconclusive probes of a credible exposure; recurring fixes across distinct issues; and a broad repair-churn report that sends a previously assessed blocker back to sanity-check. Do not actually perform those actions.
6. Are instructions overly long, contradictory, missing a material step, or likely to launch irrelevant work? Recommend only concrete corrections justified by this scope.

Cite file:line for findings. Give observed instruction/input, affected scope and falsifier for each behavior-change finding. Distinguish static scenario walkthroughs from executed tests. Report whether pre-existing contradictions affect this change, without expanding into an unrelated rewrite.

## Verification context

The new skill and whack-a-mole pass the existing skill metadata validator. A deliberately invalid skill-name copy is rejected (red control). Radar's pre-existing, unchanged description is 1336 characters and fails that validator's 1024-character limit; do not mistake this for a newly introduced failure. The Claude adapter suite passed 37/37 in a separate full clone. The driver-lock fixture initially failed because an inherited XYZ_HARNESS override resolved to the primary clone; removing the override yields 18/18. These are harness/format checks, not executed behavioral proof of the Markdown ladder.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes — all three files read end to end (sanity-check 1–218, whack-a-mole 1–326, radar 1–656), not just the diff.
Method: static reading plus four non-mutating probes. Nothing below is an executed behavioural test; the six scenarios are static walkthroughs of the Markdown.

Probes (run from the worktree root, all exit 0):
- `git diff --stat origin/development -- skills/1-hourly/sanity-check skills/3-weekly/whack-a-mole skills/3-weekly/radar` → `sanity-check/SKILL.md | 218 +`, `radar/SKILL.md | 15 +`, `whack-a-mole/SKILL.md | 15 +`, `3 files changed, 248 insertions(+)`. Sibling changes are pure additions (radar 632–645, whack-a-mole 161–174); no pre-existing line was altered.
- `ls -d skills/*/<name>` for recon, debug-mantra, ponytail, triangulate, ci-suite-audit, start-task, unstuck → every one resolves (`skills/1-hourly/...`, `skills/4-occasional/ci-suite-audit`).
- Description lengths (python, whitespace-collapsed): sanity-check 445, whack-a-mole 1019, radar 1336.
- `rg -n -i 'rated |ovr|appeal|...' skills/*/start-task/SKILL.md` → rating policy at start-task 242–280.

**Findings**

- **[Should] F1 — whack-a-mole's pre-existing "top tier" rule defeats the new pointers (Q4).** sanity-check:137–138 promises "repetition does not establish a shared cause or automatically make the work top priority", and the new whack-a-mole pointer says a high churn score "does not alone prove that ... the repair must block the goal" (166–168). But the unchanged whack-a-mole text sets priority from recurrence counts alone: "an umbrella behind ≥2 reopens or ≥1 revert justifies the top tier" (293), "Push it to the head of the line" (292), and the mandatory recital ends "file a top-priority, actionable umbrella remediation plan" (21, 23). The pointer's "Reuse an existing sanity-check verdict" (172) never says what the verdict is reused *for*, and "Preserve the repository's evidence-based severity/priority rules" (168) points back at line 293. Net: a cluster that sanity-check deferred as low-consequence is still drafted at P0.
  - Observed input: scenario 5 — recurring fixes across distinct issues, e.g. a cluster with 2 reopens whose blocker already holds a sanity-check `Defer` (bounded, low residual risk). whack-a-mole:293 rates it top tier; nothing at 161–174 or in §6 lets the disposition change that.
  - Affected scope: only clusters that carry a current sanity-check disposition when §6's Priority section is drafted. Clusters with no disposition keep today's behaviour.
  - Falsifier: any line in whack-a-mole §6/§7 that already feeds an existing assessment into the Priority `because` line. I found none (292–297 and 302–306 read in full). If one exists, this finding is unnecessary.
  - Fix (two lines in the new pointer section only; no recital, description, or §6 rewrite — the description has 5 characters of headroom under the 1024 limit): after line 173 add roughly "When a current sanity-check disposition covers the cluster, cite it in §6's Priority `because` line; a Defer or Dismiss disposition means recurrence counts alone do not support the top tier — rate at the highest value the combined evidence supports." Exact-body approval (§7) is untouched.

- **[Nit] F2 — "weakening a gate" versus tracking an intended change (Q5 scenario 1, Q6).** sanity-check:33–35 sends "any weakening or removal of a required gate" to the operator, and `Fix now` (123) routes a required gate to repair, but neither says which side "update the pinned wording to match the authorized prose edit" falls on. Optional one-clause fix at 33–35: updating an expected value to follow an intentional, authorized change to the checked content is repair; narrowing what the check covers is weakening.
- **[Nit] F3 — who may defer high severity (Q1/Q3).** `Defer` requires "bounded, low residual risk" (125) and line 32 limits self-authorized deferral to "demonstrated low-risk" work, yet the Priority bullet says "Explain a decision to defer despite high severity" (186) with no owner. Optional fix: "an operator decision to defer".
- **[Nit] F4 — sibling links assume the repo tree.** `../../3-weekly/...` (134, 139; mirrored at whack-a-mole:164, radar:636) do not resolve in a flat installed collection. Line 41–43's name-based resolution covers the table skills only; extending that sentence to the siblings would close it. whack-a-mole:94 already uses a repo path, so this matches precedent — no change required.

- **[Pass] Q1 — ladder separates failure, value, dependency and urgency without excusing controls.** Dependency source test at sanity-check:62–68 ("an enforced gate can still be a real delivery blocker"); harm before popularity at 70–78; "A low-value feature can still contain a high-severity defect" (87); duplicate-coverage proof at 100–109; "Deferring a repair does not waive a required gate or establish merge readiness" (36); "Do not translate uncertainty into low risk" (127).
- **[Pass] Q2 — two-attempt trigger is defined and bounded.** "Count consecutive attempts; eliminating a plausible cause is new evidence. An attempt is a probe or experiment, not a commentary update" (159–160); "a review trigger, not a timeout that permits ignoring a necessary defect" (161–162); continuation requires a stated discriminating experiment (164–165); anti-ritual clause at 167–169 and 26. High-risk unknowns exit to `Unresolved` (127), not `Defer`.
- **[Pass] Q3 — PRS coherent with start-task.** Axis order and 1–100 scale (sanity-check:180) match start-task:242–243; appeal 50 (188–189 vs start-task:251); effort as cheapness (190–191 vs start-task:252); `ovr`, supported writer and read-back (194–195 vs start-task:276–279); no formula change (195–196 vs start-task:279–280). Dedupe at 173; "not filed" draft fallback at 197–198; redaction and private route at 198–199.
- **[Pass] Q4 (apart from F1) — recommendations are scoped, nonrecursive, and keep separate authority.** Evidence thresholds at sanity-check:134–142 ("One red check alone is insufficient"); "issue-filing authority does not authorize a whack-a-mole umbrella or radar report publication" (147–148); "handoffs, not recursive calls" (151–153). Reciprocal text: whack-a-mole:170–173 ("does not ... change this skill's exact-body approval requirement"), radar:641–645 ("does not automatically invoke sanity-check or inherit its issue-filing authority"). Radar reuse rule at sanity-check:148–149 agrees with whack-a-mole's freshness gate (78–79).
- **[Pass] Pre-existing text checked and found not to affect this change.** radar:373 ("file one umbrella per root cause") versus whack-a-mole:318 (one issue per run) is an older mismatch inside an operator proposal; radar:241–242 ranks any 2-day red trunk "above every backlog cluster" without regard to an existing disposition, but radar only reports and recommends (46, 58), so the pointer survives. Radar's 1336-character description is unchanged by this diff (probe above) and stays out of scope. No pre-existing defects found in sanity-check (new file).
- **[Pass] Q6 — length and scope.** 218 lines, no scripts or gates ("It does not need scripts, a new scoring system, a CI gate, or a full audit", sanity-check:18–19); "Keep the initial assessment small" (55); full audit stays "a separately invoked workflow" (51). No contradiction found beyond F1–F3.

**Q5 — static scenario walkthroughs (not executed)**

| Scenario | Disposition | Operator question | Allowed next action |
|---|---|---|---|
| Wording-only CI assertion after a prose edit | `Fix now` if the gate is required (123); `Propose retirement` if step 5 shows it protects nothing (99–104, 126) | None — not a core or user-facing capability (28) | Align assertion and prose through the normal repair path; the gate is not waived meanwhile (36). See F2. |
| Sole transaction-integrity guard failing | `Fix now`; `Contain now` if live corruption is observed (122–123) | None — integrity consequence stands regardless of feature value (87) | Route to repair; no deferral or retirement, since no other verified check covers it (100–103, 108–109) |
| Advisory unsupported-platform canary | `Dismiss the claim` as a blocker (128); any real defect it shows is `Defer` (125) | Only if platform support status is itself unclear (82–84) | Resume the original task now; dedupe then file or update a rated issue with a revisit trigger (173–177) |
| Two inconclusive probes of a credible exposure | `Unresolved`, exposure recorded as unknown (78, 127) | The one exact missing decision or observation, if no discriminating experiment remains (166–167) | Reassess before a third probe (158–159); continue only with a stated discriminating experiment (164–165); never defer as low risk; keep details off public issues (198–199) |
| Recurring fixes across distinct issues | Current blocker keeps its own disposition; recommend whack-a-mole (134–138) | None required | State the evidence and recommendation (144); run it only on request or existing authorization (145–146); unrelated work continues (153–154). F1 applies once it runs. |
| Radar report sends an assessed blocker back | Reuse the existing disposition (151–153; radar:643–645) | None | Cite the prior receipt and continue; reopen only on new contradictory evidence or materially changed scope |

**VERDICT:** FAIL

**Basis:** The sanity-check ladder itself meets the Definition of Done on Q1–Q3, Q5 and Q6. One requested change stands: F1, where unchanged whack-a-mole text (21, 23, 292–293) assigns top priority from recurrence counts and so contradicts what both new pointers promise. It is a two-line edit inside the already-added pointer section. F2–F4 are optional. No runtime machinery or side effects are requested.

Handing off to Producer (codex-producer) — go to the Producer window and say "take your turn": disposition F1–F4, apply F1, then return for Round 2.

### Producer · Round 1 disposition

- F1 Implemented: the new whack-a-mole pointer explicitly overrides the recurrence-only top-tier rule for clusters with a current Defer/Dismiss assessment; cite it in §6's Priority rationale and use combined consequence/scheduling evidence. This is confined to the already-added pointer section and preserves exact-body approval.
- F2 Implemented: updating expected content after an authorized intentional change is repair only when the protected contract remains; narrowing coverage is weakening.
- F3 Implemented: high-severity deferral language now explicitly names an operator decision.
- F4 Implemented: name-based discovery now explicitly includes sibling links in flat installed collections.

Please re-sweep the final three files and verify these changes against the operator requirements and your scenario walkthroughs. No scope expansion or new tests. Handing off to Reviewer (claude-fable) for Round 2.

### Reviewer · Round 2

swept file: yes — all three files re-read end to end at 33cba144 (sanity-check 1–222, whack-a-mole 1–330, radar 1–656), not just the Round 1 fix diff.
Method: static reading plus two non-mutating probes. Nothing below is an executed behavioural test; the scenario re-walks are static readings of the Markdown. Line numbers are the current ones (sanity-check shifted +4 after line 36, whack-a-mole +4 after line 173).

Probes (run from the worktree root, both exit 0):
- `git show 33cba144 --stat` → `sanity-check/SKILL.md | 8 ++++++--`, `whack-a-mole/SKILL.md | 8 ++++++--`, radar untouched. The fix commit changed only sanity-check 37–38, 43–46, 190 and whack-a-mole 173–178.
- `git diff --numstat origin/development -- <three files>` → `222 0 sanity-check`, `15 0 radar`, `19 0 whack-a-mole`. Zero deletions: the sibling changes remain pure additions inside the new pointer sections; the whack-a-mole description, recital and §6 are byte-unchanged, so the 1019-character description measured in Round 1 still stands.

**Round 1 findings — verification**

- **[Pass] F1 resolved.** whack-a-mole:173–177 now reads "For a cluster with a current sanity-check disposition, cite that assessment in §6's Priority `because` line. A `Defer` or `Dismiss` disposition overrides the recurrence-only top-tier rule below: rate at the highest value the combined consequence and scheduling evidence supports, without treating churn counts alone as urgency." The rule it names is still at whack-a-mole:297 ("an umbrella behind ≥2 reopens or ≥1 revert justifies the top tier") and the `because` line it names exists at whack-a-mole:222. Harm carve-out kept at 177–178 ("Credible immediate harm still requires prompt attention"); exact-body approval kept at 170–171. Clusters with no disposition keep the old behaviour, as scoped.
- **[Pass] F2 resolved.** sanity-check:37–38: "Updating expected content after an intentional, authorized change is ordinary repair when the protected contract is preserved; narrowing coverage is weakening."
- **[Pass] F3 resolved.** sanity-check:190: "Explain an operator decision to defer despite high severity; do not lower the severity to rationalize it." This now agrees with line 32 ("defer demonstrated low-risk, nonblocking work") and the `Defer` row (129).
- **[Pass] F4 resolved.** sanity-check:43–45: "including the siblings below. Relative links describe the repository layout; in a flat installed collection resolve by skill name."

**Re-sweep**

- **[Pass] No regression in Q1–Q4, Q6.** The passages cited in Round 1 are intact at their shifted lines: dependency source test (sanity-check:66–72), harm before popularity (74–82), "A low-value feature can still contain a high-severity defect" (91), duplicate-coverage proof (104–107), "Do not translate uncertainty into low risk" (131), two-attempt trigger (162–166), anti-ritual clause (171–173), sibling authority split (151–152), "handoffs, not recursive calls" (155–157), PRS axes and `ovr` (184–200), not-filed draft and redaction (201–203). Radar pointer unchanged (radar:632–645).
- **[Pass] Pre-existing text that still contradicts the pointer is now explicitly subordinated, not silently left.** The verbatim recital (whack-a-mole:21, 23), the "Push it to the head of the line" rule (296) and the template's "<top value on the repo's own scale>" (222) are unchanged by design; 175–176 names the rule it overrides ("the recurrence-only top-tier rule below"), so a reader who reaches §6 with a `Defer`/`Dismiss` disposition has an explicit instruction. Radar's pre-existing items from Round 1 (radar:241–242, 373; 1336-character description) are unchanged and still do not affect this change. No new pre-existing defect found in any of the three files.
- **[Nit] N1 — disposition scope versus cluster scope (no change requested).** whack-a-mole:173–174 says "a cluster with a current sanity-check disposition", while a disposition normally covers one blocker; sanity-check:155–156 limits reuse to "the same scope and evidence". A disposition on one member could be read as covering the whole cluster. The "combined consequence and scheduling evidence" wording (176) and the "unless new evidence contradicts it" clause (172) keep this from forcing a wrong rating, so I am not asking for an edit.
- **[Nit] N2 — line wrap only.** sanity-check:163 and 190 exceed the file's wrap width. Cosmetic.

**Q5 re-walk — static, only the rows the fixes touch**

| Scenario | Round 2 reading |
|---|---|
| Wording-only CI assertion after a prose edit | Now unambiguous: updating the pinned wording to follow the authorized prose edit is `Fix now` ordinary repair (sanity-check:37–38, 127), no operator question; shrinking what the assertion checks would be weakening and goes to the operator (33–35). |
| Recurring fixes across distinct issues | Recommend whack-a-mole (sanity-check:138–142). If it runs on a cluster holding a `Defer`, §6 cites the disposition and does not rate top tier on counts alone (whack-a-mole:173–177); filing still needs exact-body approval (170–171, 322). |
| Other four rows | Unchanged from Round 1; cited lines intact at their shifted positions. |

**VERDICT:** PASS

**Basis:** All four Round 1 findings are implemented as requested and verified by quoted text; the one behaviour-change request (F1) is confined to the already-added pointer section and leaves approval boundaries intact. The full re-sweep of the three files found no regression and no new blocker; N1 and N2 are optional and need no further round. The Definition of Done is met: Q1–Q6 are satisfied with no new runtime machinery and no unauthorized side effects. Not measured here: validator and suite results (graded [Unverified — needs clone run]; the harness gate runs after this turn).  [Unverified — no citation]

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
