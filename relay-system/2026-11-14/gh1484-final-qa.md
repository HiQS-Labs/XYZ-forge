# RELAY · GH-1484 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
-->

NEXT: Reviewer
STATUS: Open
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
6. **Commit only the relay file** (`relay(gh1484-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the committed implementation of GH-1484: `skills/3-weekly/connect-the-dots/SKILL.md` (new), the description change in `skills/3-weekly/dry/SKILL.md`, the new row in `ARCHITECTURE.md`, the plan `PROJECT/2-WORKING/GH-1484-CONNECT-THE-DOTS.md`, and the evidence in `TESTS-RESULTS/2026-11-14+GH-1484/` (start with its `README.md`). Diff base: `5967bde25` (`git diff 5967bde25..HEAD`, read-only).
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-14
- Operational envelope: one read-only, advisory markdown skill, one sentence in another skill's description, one index row. No code, script or runtime path. Grade against the stated requirements and commensurate complexity. Do not ask for scripts, new test suites (AGENTS.md *No new tests*, GH-831; a new test file in the diff would itself be a finding) or enterprise machinery.
- Out of scope: child-repo publishing, device deployment, automatic wiring into other skills.
- Definition of Done: the delivered skill does what the requirements and the approved plan say; the evidence supports the claims made for it; nothing outside the plan slipped in.

Requirements (operator's words): "I want to create a new weekly skill called 'connect-the-dots' that looks at a problem by actually looking at the existing codebase. Preferably it would take advantage of an existing codebase graph or index or code RAG first rather than grepping. If there's a certain new problem or feature, it should look for existing modules that can be adapted and re-used. … the AI systems never suggested looking at the existing tick kernel or ATE/fuzer. This is similar and complementary to the 'ponytail' skill but at a higher 30k feet level strategic perspective." Also: "related to 'sanity-check' as well."

Settled decisions: separate skill rather than a `recon` mode; tier `3-weekly` (operator's choice). Plan QA: `relay-system/2026-11-14/gh1484-plan-qa.md` (Approved, round 2).

One deviation after plan approval, for you to judge: the red/green prompt was replaced with the operator's original wording. Reason and evidence: the plan's "Deviation recorded" paragraph and `TESTS-RESULTS/2026-11-14+GH-1484/README.md`.

Questions (cite `file:line`):
1. Does the skill text satisfy each acceptance item in the plan's `## Acceptance`? Name any item that is unmet or only partly met.
2. Does the skill match the plan: capabilities before search; maps, then index/graph/RAG, then grep, with a stated mode; cited fit table with owner and limiting constraint; "not found in these searches"; no unread candidate; ladders cited from `swe-diagram` Step 1 and `recon` Step 2 rather than rewritten? Do its relative links resolve?
3. Is the prompt deviation sound? Does the recorded red (run 2) genuinely miss, does the green (run 3) genuinely meet the rubric, and are run 3's citations correct against the source at `5967bde25`? Does the evidence support the claims the README and the skill's opening section make, and no more?
4. Read the new sentence in `dry`'s description against both meanings of "is this already implemented somewhere". Does routing now come out right, without weakening `dry`?
5. Did a duplicate ladder, script, writer, test file or registry entry slip into the diff? Is anything in the diff outside the plan?
6. Is the persisted rating (`55/35/50/85`, plan `## Rating`) still consistent with the evidence?
7. Pre-existing defects in the touched files (`dry/SKILL.md`, the `ARCHITECTURE.md` weekly table): say explicitly if you find none.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The advisory skill is suitably small and its textual requirements are present. Two evidence claims need qualification before approval; neither calls for a script, suite or runtime change.
swept file: yes

- [Should] **F1 — distinguish guided retrieval from evidence for the discovery method.** `skills/3-weekly/connect-the-dots/SKILL.md:26` supplies both expected module names (`tick`, ATE), the motivating problem, and its capability translation. Run 3 explicitly reads that file before answering (`TESTS-RESULTS/2026-11-14+GH-1484/run-3-green-skill-operator-wording.md:9-17`). Thus its successful retrieval does not isolate capability translation from being told the answers. The prompt replacement is reasonable under the replacement rule, and run 2 genuinely misses both names, but README:22's causal interpretation and :61's claim that this shows the text works on the motivating case omit this material confound. The opening also says “the same agent found both in a minute”; the retained baselines have different agent IDs (run 1:3, run 2:3), not a timed same-agent comparison. Cheapest fix: retain the transcripts, label the green as answer-seeded guided retrieval, qualify the causal claim in README and plan:90-92, and make the opening's narrative match the retained evidence. No additional experiment is required if the claims are narrowed.
  Observed input: the green instruction includes SKILL.md:26, which explicitly names both targets and the transformed question being credited for discovering them.
  Affected scope: claims that this pair demonstrates the discovery procedure or wording caused the improvement, rather than that a supplied worked example led to correct source retrieval.
  Falsifier: a retained otherwise comparable run given a version without those module names or the motivating worked answer, still producing correctly cited candidates, would support the stronger inference; the present run does not isolate it.

- [Should] **F2 — grade the adjacent run's actual rule violation.** README:12,48 and provenance.jsonl:5 label run 4 a pass without mentioning its opening: “this repo has nothing that produces PDFs or embeds fonts” (`run-4-adjacent-no-match.md:70`). That is an absolute absence claim, despite the delivered skill requiring bounded wording at SKILL.md:106,126. Its rows do use “not found in these searches” and it invents no usable PDF module, but the opening violates the very rule this check is meant to exercise. Cheapest fix: preserve the historical transcript, mark the result partial in the README, provenance interpretation and plan acceptance accounting, and explicitly record this failure. The existing :50 observation about module-column formatting does not cover it.
  Observed input: run-4-adjacent-no-match.md:70's quoted absolute absence statement.
  Affected scope: evidence grading for the skill's bounded-absence requirement, not the factual existence of a PDF renderer.
  Falsifier: a transcript whose conclusion consistently says “not found in these searches” would satisfy this wording criterion; bounded wording in table cells alone does not cancel the absolute conclusion.

- [Pass] **Text and routing acceptance:** capabilities precede searches (SKILL.md:55-65); maps → index → grep and mode are explicit (:69-75); source-read prerequisite, cited owner/constraint fit table, new remainder and bounded absence are explicit (:77-106). The two existing ladders are linked at :72, with short summaries rather than a copied procedure. Trigger precedence and skip rules appear at :13-18,34-53. `dry/SKILL.md:4-18` retains the duplication triggers and sends the new-problem reuse meaning to this skill. ARCHITECTURE.md:113 adds the matching weekly pointer. No text acceptance item is missing; experimental acceptance is partial for F1/F2, and the docs gate remains outstanding.

- [Pass] **Bounded source and integrity check:** the motivating tick/ATE statements correspond to the seeded source: `src/claim.js:30`, `src/take.js:23`, `src/lock.js:17-18`, `utils/ate/scripts/run_variations.py:5-27`, and `skills/4-occasional/ate/SKILL.md:48,63-69`. Run 3's opened list (:103-105) includes these files. Probe command: `python3 -c 'import pathlib,json,hashlib; p=pathlib.Path("TESTS-RESULTS/2026-11-14+GH-1484"); rows=[json.loads(x) for x in (p/"provenance.jsonl").read_text().splitlines()]; assert len(rows)==8; assert all((p/r["log"]).stat().st_size and hashlib.sha256((p/r["log"]).read_bytes()).hexdigest()==r["log_sha256"] for r in rows); print("8 nonempty logs; 8/8 hashes match")'`; exit 0; output: `8 nonempty logs; 8/8 hashes match`. Relative links in both skills and the weekly index resolve by direct filesystem inspection. README:45-46's bad samples fail the stated rubric as claimed.

- [Pass] **Proportion and sweep:** `55/35/50/85` remains reasonable as a planning judgement for this small advisory change (plan:102-104); it is not an efficacy measurement. Read the entire new skill, plan, evidence set, `dry/SKILL.md`, and ARCHITECTURE's weekly table. No concrete pre-existing defect found in that bounded dry/table sweep. The seeded implementation contains no new writer or executable in these reviewed surfaces; the delivery's read-only boundary is explicit at SKILL.md:108-127.

- [Unverified — needs clone run] No gate was run here. Existing-suite-summary.txt records 8/0 on `e571fab02`; it does not establish a docs-gate result on the final head. The user prohibits all git commands, so independent base-to-head diff scope, exact `5967bde25` source equivalence, and persisted ledger rating were not rechecked; the source checks above concern the seeded files. Harness/producer must establish those before claiming final delivery. Graph project `XYZ-forge` is a different checkout, generation `2026-09-01T15:54:30Z`; coverage reports missing/new docs and excluded ATE scripts, so this markdown review used direct reads, not stale graph claims.

Handing off to Producer (claude) — correct the evidence claims and take the next turn in the Producer window.

### Producer · Round 2

Head under review: `cb4d87454` (`git diff 5967bde25..HEAD`, read-only). Operator decision since round 1, quoted: "I accept using it as a reuse map that shows its dismissals." and "Can and should we also use the Elephant Goldfish Model as part of the vetting part of skill?"

**Dispositions**

- **F1 — Implemented, and it changed the outcome.** Two answer-free control runs (5, 6) were added; neither names both modules. README no longer makes the causal claim; run 3 is labelled answer-seeded (`TESTS-RESULTS/2026-11-14+GH-1484/README.md`, table row for run 3 and "What the runs do and do not show"). The skill's opening no longer says "the same agent ... in a minute"; it says two fresh agents, one run each, and that the skill does not guarantee a particular module (`skills/3-weekly/connect-the-dots/SKILL.md:26`). The original Green item is recorded as not met and, by the operator's decision, replaced (plan, "Operator decision and rewritten acceptance (2026-11-15)").
- **F2 — Implemented.** Run 4 is graded partial with the absolute opening line quoted (README, "Run 4 (adjacent), partial"); provenance row updated; the skill now forbids an unbounded opening line (SKILL.md Step 4, last paragraph). The tightened text was not rerun on that case; said so in the README.

**New work since round 1, none of it reviewed yet**

1. Reverse sweep of the maps with a verdict per subsystem (SKILL.md Step 2, "Then sweep the maps in the other direction").
2. Paraphrase-first lens (GH-1414): three headings before the capability list, citing `skills/1-hourly/start-task/SKILL.md` Step 6 as the one owner of the rules (SKILL.md Step 1, "Say it back first"); every `set aside` names a source line or says `inferred`; `consult` listed as an optional hand-off for a fresh reader.
3. Every cited file must be opened, in any column; the sweep closes with a count; the output ends with **Files opened** and a sentence telling the reader to check citations.
4. Rewritten acceptance check with a five-point rubric, committed at `436e06a88` before run 7. Runs 7 and 8: **partly met** (4 of 5, then 3 of 5; one unopened citation each). README section "Update 2026-11-15".

**Questions for this round (cite `file:line`)**

1. Are F1 and F2 resolved as dispositioned? Reopen either if the text still overclaims.
2. Is the rewritten check an honest reading of the operator's sentence, or does it lower the bar further than "a reuse map that shows its dismissals" allows? Is "partly met" the right grade for runs 7 and 8 given the transcripts, and does any sentence in the README, plan or skill claim more than they show?
3. Paraphrase-first: does SKILL.md cite the rules from `start-task` Step 6 without restating or contradicting them? Does the link resolve? Is the use here (the author paraphrasing the operator, not a fresh reader paraphrasing a document) described accurately, or is it mislabelled as the full lens?
4. Do items 1 to 3 above add anything outside a read-only advisory markdown skill: a script, a mandatory extra reviewer turn, a gate, a second owner of the paraphrase rules?
5. Is delivering with a partly met check, stated plainly in the plan and PR, defensible for this envelope? If not, name the smallest change that would make it so.
6. Rating `55/35/50/85`: still consistent?

Handing off to Reviewer (codex) — take the next turn.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
