# RELAY · GH-1484 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1484-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1484-CONNECT-THE-DOTS.md`. This is a **plan review**: the skill file has not been written yet.
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-14
- Operational envelope: one new markdown skill file (`skills/3-weekly/connect-the-dots/SKILL.md`), one sentence added to `skills/3-weekly/dry/SKILL.md`'s description, one `ARCHITECTURE.md` row. Read-only, advisory skill; no code, no script, no runtime path. Grade against the stated requirements and commensurate complexity; do not ask for scripts, new test suites (AGENTS.md *No new tests*, GH-831) or enterprise machinery.
- Out of scope: child-repo publishing, device deployment, automatic wiring into other skills.
- Definition of Done: the plan's claims are grounded in the cited paths; it meets `skills/README.md` "Mode before skill"; the planned skill would do what the requirements ask; and each acceptance check would fail on an unchanged or wrongly built candidate.

### Step A: paraphrase first (GH-1414). Do this BEFORE reading anything else.
Read ONLY the plan doc (`PROJECT/2-WORKING/GH-1484-CONNECT-THE-DOTS.md`). Do not open source files, the requirements below or the issue yet. Then, at the top of your review block, write:
- **What this proposes** (2-5 sentences)
- **How the existing system works, per this document** (2-5 sentences)
- **What it's not** (short; ground exclusions in the doc's sections, separate excluded from deferred work, and label any inference)
- **Input boundary:** list what you had read when you wrote the paraphrase.

### Step B: source-backed validation. Now read the requirements and the sources.
Requirements (operator's words): "I want to create a new weekly skill called 'connect-the-dots' that looks at a problem by actually looking at the existing codebase. Preferably it would take advantage of an existing codebase graph or index or code RAG first rather than grepping. If there's a certain new problem or feature, it should look for existing modules that can be adapted and re-used. … I've been struggling with trying to figure out how to get the outer loop for the software flywheel outer loop going and the AI systems never suggested looking at the existing tick kernel or ATE/fuzer. This is similar and complementary to the 'ponytail' skill but at a higher 30k feet level strategic perspective." Also: "related to 'sanity-check' as well."

Recorded decisions (settled unless you bring new evidence): a separate skill rather than a `recon` mode (reason in the plan's "Mode before skill" table; a prior consult's dissent is recorded on issue #1484); tier `3-weekly` is the operator's stated choice.

Sources: `skills/README.md`, `skills/1-hourly/recon/SKILL.md`, `skills/1-hourly/ponytail/SKILL.md`, `skills/1-hourly/sanity-check/SKILL.md`, `skills/1-hourly/triangulate/SKILL.md`, `skills/1-hourly/better-options/SKILL.md`, `skills/3-weekly/dry/SKILL.md`, `skills/4-occasional/swe-diagram/SKILL.md`, `ARCHITECTURE.md` (Skills Index), `ROUTER.md` (Routing hints), `test/gh589-skill-viewer.sh`, `mini/skills/skill-viewer/scripts/list_skills.py`, `utils/ci-route.sh`, `AGENTS.md` (sections 6 and *No new tests*).

Questions (cite `file:line`; label this part **source-backed**):
1. Are the plan's Recon claims accurate against the cited paths? Name any that are wrong.
2. Is any operator requirement missing from the plan, or narrowed by it?
3. For each plan step, what prevents an unchanged or wrongly written candidate from being reported as delivered, and which acceptance check observes the rejection? Is the manual red/green pair plus rubric control a sound red control here, and what artifact does each check observe?
4. Does the plan extend what exists (cited ladders, existing index row, existing suite) without a duplicate ladder, script or writer?
5. Is the one-sentence edit to `dry`'s description enough to settle the shared phrase "is this already implemented somewhere", or does it leave both skills firing?
6. Is the rating (`55/35/50/85`) grounded, with appeal neutral and no invented recurrence claim?
7. Anything over- or under-built for a single markdown skill?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

**What this proposes:** Add a separately invocable weekly, advisory skill that translates a new problem into capabilities and finds existing modules covering them before designing anything new. It will produce a cited fit table with owners, limitations and remaining new work, supported by a small discovery-trigger clarification and an index row.

**How the existing system works, per this document:** Existing skills require reuse but do not supply this cross-system capability-discovery method. Recon traces a named system, dry audits duplication, and ponytail sizes solutions; existing discovery ladders and purpose-written maps provide the search infrastructure this skill will reference.

**What it's not:** The Non-goals and Preflight bet exclude tracing, duplicate auditing, value judgement, building, and new scripts/indexes. Child-repo publishing, device deployment and automatic wiring are explicitly deferred, rather than permanently excluded.

**Input boundary:** Read the relay instructions and only `PROJECT/2-WORKING/GH-1484-CONNECT-THE-DOTS.md` for the paraphrase; no source paths or external issue opened. The relay file exposes the requirements before Step A; I did not use them to construct this paraphrase.

**source-backed**

swept file: yes

**VERDICT: FAIL**
**Basis:** The bounded markdown-only approach meets the operator's discovery goal and the settled skill/tier decisions. One acceptance check still lacks the fixed search boundary required by the issue; correct it before implementation. No other pre-existing defect found in the full plan sweep beyond the findings below. This is plan QA, not implementation sign-off.

- **[Should] S1 — Pin the adjacent check's search scope before asserting absence.** `PROJECT/2-WORKING/GH-1484-CONNECT-THE-DOTS.md:87` fixes only the PDF prompt and dictates “not found in these searches.” Issue #1484's adjacent-check requirement explicitly says “the input and search scope fixed before running.” Neither the acceptance item nor Test scope identifies the target root/revision, included source surfaces, or whether installed external skills count. The same prompt evaluated against Forge source and against an agent's installed PDF tooling can legitimately yield different answers. Fix: name the bounded corpus/revision and exclusions, establish that this corpus has no reusable match before freezing the expected result, and retain those searches with the adjacent transcript. If it has a match, choose a different negative case before execution. No new fixture or script needed.
  Observed input: the complete item at plan line 87 is `Adjacent check, input fixed before running: "We need to render PDF invoices with embedded fonts." Expected: "not found in these searches", with the searches listed, and no invented fit.` No search scope is specified there or in Test scope (line 94).
  Affected scope: this one manual negative acceptance case; no change requested to runtime discovery or unrelated skills.
  Falsifier: a pre-run record fixing corpus/revision and exclusions, with bounded searches supporting no fit, would remove this finding; a genuine reusable candidate inside that corpus must invalidate the chosen negative case rather than be suppressed to pass it.

- **[Nit] N1 — Correct the suite classification.** Plan line 40 calls `test/gh589-skill-viewer.sh` “Small list.” Source inspection command `rg -n "gh589-skill-viewer" validate.sh utils/ci-route.sh` exited 0 and returned `utils/ci-route.sh:33:SUBSYSTEM_TESTS_skills_army_hq=... gh589-skill-viewer.sh` and `validate.sh:680: "gh589-skill-viewer.sh"`; it is absent from `SUBSYSTEM_TESTS_small` at `utils/ci-route.sh:38`. Remove “Small list” or name the actual subsystem. Keep the explicit focused suite invocation in Plan step 5.

- **[Pass] Recon and Mode before skill, with N1 above.** `skills/README.md:23` requires the tier and index row; lines 25–28 require named alternatives. The plan's table at lines 49–58 supplies them and records the operator's separate-skill decision. `recon/SKILL.md:32` sends greenfield away, lines 44 and 126 establish its subject/map contract; `ponytail/SKILL.md:48` calls its ladder “a reflex, not a research project”; `sanity-check/SKILL.md:4` judges necessity; `better-options/SKILL.md:4` judges an option set; `triangulate/SKILL.md:45` judges competing evidence-depth demands. These support the distinction without reopening the settled choice. Paths in this bullet are under `skills/1-hourly/` unless stated otherwise.

- **[Pass] Discovery and reuse obligations are preserved.** `skills/4-occasional/swe-diagram/SKILL.md:37` supplies the broad ladder; `skills/1-hourly/recon/SKILL.md:48` supplies graph freshness/source confirmation and its line 130 supplies `Mode:`. The maps-first adaptation is explicitly requested in issue #1484, and `ROUTER.md:219` / `:222` name tick and ATE by purpose. Plan lines 69 and 80–82 require citations to these ladders, source-read candidates and bounded absence. Plan line 69 incorporates the issue's four steps, including outcome/constraints, fit categories, adaptation cost, composition sketch, unknowns and one next action. No operator requirement identified as omitted; the final text must retain those incorporated details. Existing reuse obligations are visible at `skills/1-hourly/swe/SKILL.md:41`–46 and `skills/2-daily/workhorse/SKILL.md:42`.

- **[Pass] Per-step rejection paths are proportionate, subject to S1.** Step 1's inventory check observes the actual candidate SKILL.md, rejecting missing/name-mismatched/invalid frontmatter (`mini/skills/skill-viewer/scripts/list_skills.py:83`–95); semantic reading at plan lines 80–82 rejects a syntactically valid but wrongly written skill. Step 2's diff inspection and precedence reading observe dry's actual description. Step 3's presence/link check observes the actual index row. Step 4 observes retained baseline/candidate transcripts and the deliberately bad output, not merely the skill author's assertions. Step 5 observes parser/suite and PDDA results; these are supporting compatibility checks and can pass on the unchanged repo, so they cannot replace steps 1–4. The existing suite checks actual disk names/counts and malformed frontmatter at `test/gh589-skill-viewer.sh:17`–25 and `:50`–56.

- **[Pass] Planned red control is sound for the stated limited claim.** Plan lines 83–90 require an unfixed baseline miss, a fresh-agent green with source citations/capabilities/material limitations, and a bad output rejected by the same rubric. This combines a behavior comparison with a control on the grader; the stated one-case, one-family limitation avoids claiming generality. Retain prompts, supplied context, source reads, outputs and grades with the provenance required at plan line 72; those are what establish that the candidates were read and runs were fresh. These controls are specified, not witnessed in this review. `AGENTS.md:119` and `:122` require retained provenance and a witnessed red control during implementation.

- **[Pass] A conditional description exclusion can settle dry's shared phrase without removing it.** `skills/3-weekly/dry/SKILL.md:6`–7 currently claims “is this already implemented somewhere”; lines 14–16 already use conditional exclusions. Plan line 70's new-problem exclusion plus the precedence contract at line 82 can route that phrase by the open question: reuse discovery here, consolidation of existing duplicates to dry. Retaining the phrase alone is not a conflict if the new sentence explicitly excludes the former meaning. Final QA should read the actual sentence against both meanings; no wider wiring required.

- **[Pass] Scope and rating are proportionate.** Plan lines 63–65 and 94 exclude new scripts/suites/writers and make rollback a revert; the index insertion fits the existing tier table at `ARCHITECTURE.md:109`–114. Markdown routing is supported by `utils/ci-route.sh:63`–69 and `:475`–477. Plan line 102 grounds 55/35/50/85 in the current request, one reported motivating case, neutral appeal and cheap docs work, explicitly declining an invented recurrence window. These are reasoned ratings, not measured incident statistics. No additional machinery is warranted.

**Evidence limits:** Verify-tier review of the seeded plan and cited local sources. MCP project listing (all 86 entries, no remaining page) had no matching current worktree project. The nearest Forge index was ready at generation `2026-11-15T06:36:06Z`, but belongs to the main checkout; coverage marked this plan missing there. The viewer-symbol query returned six results, no more pages; coverage reported no recorded gaps on the other supplied paths. Local source reads, rather than cross-checkout graph freshness, ground the findings. `gh issue view 1484 --repo HiQS-Labs/XYZ-forge --json body,comments` exited 0; its adjacent-check span quoted in S1 supplies the additional boundary requirement. No suites, fixtures, git commands, implementation edits or phase gates executed; implementation test results remain **[Unverified — needs clone run]**.

Handing off to Producer — fix S1, disposition N1, and open the next review round. Go to the Producer window and say 'take your turn'.

### Producer · Round 2

- **S1 — Implemented.** The adjacent check in the plan's Acceptance now fixes the corpus (git-tracked files at base `5967bde25`), the exclusions (installed skills and tools outside the repo, relay threads, project docs, test receipts, changelog, docs, ledger dumps), the pre-run searches and their recorded result, and the rule that a real candidate invalidates the case rather than being suppressed. Pre-run searches were run before freezing: `pdf` matches only the excluded ledger dumps; `invoice` / `embedded font` / `reportlab` / `weasyprint` match CI config, a fuzzy-match test fixture and gate baselines, no rendering module.
- **N1 — Implemented.** Recon now names `SUBSYSTEM_TESTS_skills_army_hq` (`utils/ci-route.sh:33`) and the full `validate.sh` list, and says the suite is not in the Small list. Plan step 5 keeps the explicit suite invocation.
- No other change to the plan. Handing off to Reviewer — take your turn.

### Reviewer · Round 2

**What this proposes:** Add a weekly advisory skill that breaks a new problem into capabilities, searches for existing owners, and returns a cited fit table and composition sketch before new implementation is designed. The delivery is one skill file, a conditional exclusion in dry's description, and an index row, with bounded manual evidence.

**How the existing system works, per this document:** Existing skills require reuse but start from a named system, solution, duplication concern or option set. Existing maps describe modules by purpose, while existing graph/RAG discovery ladders supply leads that must be checked against source. The viewer and index already provide registration surfaces.

**What it's not:** The Non-goals section excludes tracing, duplicate auditing, value judgement, building and new discovery infrastructure. Child-repo publishing, device deployment and automatic wiring into other skills are deferred (Non-goals and Preflight bet).

**Input boundary:** For this turn's paraphrase, read the whole relay (including historical review and embedded requirements) and then only the current plan; no source files or issue were opened until afterward. This is a round-2 paraphrase with that prior context, not a blind first exposure.

**source-backed**

swept file: yes

**VERDICT: PASS**
**Basis:** Approve the plan. S1 and N1 are resolved in the seeded artifact. The whole-plan sweep found no additional pre-existing defect requiring a change. This verdict authorizes proceeding to implementation review; it does not certify unexecuted acceptance checks.

- **[Pass] S1 resolved.** `PROJECT/2-WORKING/GH-1484-CONNECT-THE-DOTS.md:87` now pins the PDF prompt to git-tracked repository files at `5967bde25`, enumerates exclusions, specifies search terms, requires retaining pre-run evidence and says a genuine candidate invalidates the negative case. This supplies the missing boundary from issue #1484's “input and search scope fixed before running.” The reported preliminary search result is Producer-supplied evidence; I did not rerun git searches. Implementation must retain the actual searches and outputs as promised, rather than treat this plan's summary as a receipt.

- **[Pass] N1 resolved; Recon remains grounded.** Plan line 40 names `SUBSYSTEM_TESTS_skills_army_hq` and explicitly excludes Small, matching `utils/ci-route.sh:33` and `:38`; the suite remains in `validate.sh:680`. The viewer reads both skill-folder depths and rejects folder/name mismatch (`mini/skills/skill-viewer/scripts/list_skills.py:83`–95). Maps name tick and ATE by purpose (`ROUTER.md:219`, `:222`); discovery/source-confirmation claims match `skills/4-occasional/swe-diagram/SKILL.md:37`–64 and `skills/1-hourly/recon/SKILL.md:48`–60, with its mode stamp at line 130. No materially wrong Recon claim remains.

- **[Pass] Requirements and Mode before skill.** Plan lines 49–58 name neighboring skills and distinguish the capability-list unit and chat output from recon's named-system map; this meets `skills/README.md:25`–28 under the settled separate-skill decision. Recon's greenfield skip is at `skills/1-hourly/recon/SKILL.md:32`; ponytail's deliberately light ladder is at `skills/1-hourly/ponytail/SKILL.md:48`; sanity-check's necessity question and better-options' option-set trigger are in their frontmatter. Plan line 69 incorporates the issue's four steps, including outcome/constraints, fit categories, adaptation cost/risk, composition, unknowns and next action. Lines 80–82 retain maps → index → grep, stated mode, source-read candidates and bounded absence. No operator requirement is missing or narrowed.

- **[Pass] Each implementation step has an observable rejection path.** Plan steps 1–3 (lines 69–71) are observed by inventory plus semantic file reading (lines 79–82), dry's actual description/diff, and the actual index row/link (line 88). Missing files, wrong frontmatter, missing capability/source/precedence obligations and a missing row therefore cannot count as delivery. Step 4 observes retained baseline/candidate transcripts and the bad sample (lines 83–87), with provenance required at line 72. Step 5 observes the existing suite and PDDA results (line 73); those can pass unchanged and are supporting compatibility evidence, not substitutes for steps 1–4. The suite's disk/name assertions and malformed-frontmatter red controls are visible at `test/gh589-skill-viewer.sh:17`–25 and `:50`–56.

- **[Pass] Red control and scope are proportionate.** Plan lines 84–86 require a baseline miss before the green counts, correct citations/capability/limitation for both candidates, and rejection of a deliberately deficient output by the same rubric. Line 87 independently observes bounded absence rather than invented fit. Line 90 limits the inference to one case and one model family. This is a sound planned red/green and grader control for a markdown skill; it is not yet witnessed evidence. No new suite, script, writer or duplicated ladder is proposed (lines 63, 81, 94); the new row extends the existing weekly table (`ARCHITECTURE.md:109`–114).

- **[Pass] Trigger collision and rating are addressed without extra machinery.** Plan line 70's conditional “Do NOT fire” clause, coupled with line 82's precedence requirement, can distinguish discovery for a new problem from consolidation of already duplicated paths despite retaining dry's shared phrase (`skills/3-weekly/dry/SKILL.md:6`–16). Final QA must read the delivered sentence against both meanings. Plan line 102 grounds 55/35/50/85 in the current request, one motivating case, neutral appeal and cheap markdown work, explicitly rejecting an invented recurrence window. No over- or under-building identified for this envelope.

**Evidence limits:** Verify-tier, source-backed plan review. MCP listed all 86 projects with no remaining page and no current-worktree index. The inspected `XYZ-forge` project belongs to the main checkout; its coverage generation is `2026-09-01T15:54:30Z`, with missing/not-tracked/changed freshness on the supplied paths, so local source reads and targeted text checks ground this review, not that stale graph. `gh issue view 1484 --repo HiQS-Labs/XYZ-forge --json body` exited 0 and supplied the four-step contract and adjacent-check requirement. No git commands, suites, executable fixtures or phase gates were run. Implementation behavior and gate results remain **[Unverified — needs clone run]**.

Relay closed (Approved), no further turn needed. Producer may proceed with the approved plan and retain the promised implementation evidence.


### Attestation · relay-drive — 2026-11-15T06:47:58Z
task: RELAY-gh1484-plan-qa-r2
reviewer: codex
status: Approved
reviewed-head: 6abae3f1ec59ee917f95735a9d33a4302c11a7e6
added-range: 19772+6648
added-sha256: 032f2c26c9e63b37cc34fd9d44a8fc22fe28ccf187bbafe204501bb5fc688980
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
