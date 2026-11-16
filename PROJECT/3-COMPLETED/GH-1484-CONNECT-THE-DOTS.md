---
gh_issue: 1484
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1484
title: "New weekly skill: connect-the-dots — find existing modules to reuse before designing something new"
status: Complete
created: 2026-11-14
updated: 2026-11-15
doc_type: enhancement
effort: 1
complexity: 2
risk: 1
phases: 1
owner: Noel Saw
goal: "Given a problem, name the existing modules that already cover parts of it, with citations, before anything new is designed"
---
## Status

| What was just completed | What's next |
|---|---|
| Final review approved in round 3 of 3 (Codex, `relay-system/2026-11-14/gh1484-final-qa.md`). Skill accepted by the operator as a reuse map that shows its dismissals; paraphrase-first step added. Rewritten check partly met: runs 7 and 8 each meet 3 of 5 points. | Shipped: PR #1492 merged 2026-11-15 (`4635abe09`); #1484 closed. Follow-up: #1493 (clone retirement). |

# GH-1484: connect-the-dots skill

Tracking: https://github.com/HiQS-Labs/XYZ-forge/issues/1484 (the issue body is the full statement; its first comment holds the consult dispositions). Base: `origin/development@5967bde25`. Branch: `feat/XYZ-forge-gh1484-connect-the-dots-2026-11-14`.

## Quad Concepts
- Problem first, not subject first → Break the problem into the capabilities it needs (verbs), because a module is named for what it is, not for the problem it could solve.
- Maps, then index, then grep → Read the repo's purpose-written maps, then a code graph or RAG where installed; grep is the last rung and the mode is stated.
- A fit table, not a design → Each capability gets an existing module with `file:line`, its owner, the constraint that limits the fit, and the remainder that is new.
- Read-only and advisory → Chat output; no files, no ledger rows, no code. It hands off to `recon`, `ponytail`, `sanity-check`.

## Observed problem

Agents design from the problem statement outward. Across the sessions on the flywheel outer loop (#1474), no agent proposed the `tick` kernel or ATE until the operator pointed at them. Reuse is already required by `workhorse` (`skills/2-daily/workhorse/SKILL.md`) and `swe` (`skills/1-hourly/swe/SKILL.md`), but neither says how to find a module whose name does not match the problem.

## Recon (base 5967bde25; graph not used for this docs task, direct reads)

- `skills/README.md` "The contract": add a skill under the tier it is used at; the Skills Index row is part of the change; **Mode before skill (GH-1299)** requires naming the skills checked.
- `ARCHITECTURE.md` Skills Index: alphabetical rows per tier; `baseline` at line 112, `dry` at 114. The new row sits between them.
- `test/gh589-skill-viewer.sh` (in `SUBSYSTEM_TESTS_skills_army_hq`, `utils/ci-route.sh:33`, and the full `validate.sh` list; not in the Small list) runs `mini/skills/skill-viewer/scripts/list_skills.py` over `skills/*/*/SKILL.md`: `name` must equal the folder name; `description` must use an accepted scalar style.
- Existing discovery ladders to cite: `skills/4-occasional/swe-diagram/SKILL.md` Step 1 (graphify → codebase-memory → `ask_self` → written maps → source) and `skills/1-hourly/recon/SKILL.md` Step 2 (graph first, revision check, "The graph is a lead, not a citation", grep fallback) plus the `Mode:` stamp in its Step 5 template.
- `ROUTER.md` "Routing hints" already describes `tick` ("multi-agent coordination kernel") and ATE ("unattended variation-test fuzzing") by purpose.
- `skills/3-weekly/dry/SKILL.md` description claims the phrase "is this already implemented somewhere".
- `utils/ci-route.sh`: a new `skills/3-weekly/**/SKILL.md` and `ARCHITECTURE.md` route as docs; final gate is `utils/pdda/pdda.sh run`.
- Not traced: the publish manifests for child repos (publishing is out of scope here).

## Mode before skill (GH-1299)

| Skill checked | Why it cannot carry this |
|---|---|
| `recon` | Closest owner. Its skip rule sends this case away ("Greenfield — there is no existing system to trace … go plan"), and it judges one named system and writes a Recon Map file. This judges a problem's capability list across many systems and answers in chat. A mode would need its own trigger, skip rule and output contract. |
| `ponytail` | Judges the size of a solution; keeps its own search deliberately light. |
| `dry` | Audits the whole codebase for paths that already duplicate each other; takes no problem statement. |
| `sanity-check` | Judges whether a problem is real and worth fixing, not what already exists to solve it. |
| `triangulate`, `better-options` | Start from a known change or from options already on the table. |
| `workhorse`, `swe` | State the reuse obligation inside a larger ladder; they would call this method. |

The operator also asked for a separately invocable skill by name. Codex's consult preferred a `recon discover` mode; recorded on the issue with the reason it was not chosen.

## Preflight bet

- **Outcome sought:** when a problem looks new, the agent names the existing owners that cover parts of it before proposing a new subsystem.
- **Smallest bet:** one `SKILL.md`, one Skills Index row, one sentence in `dry`'s description. Not built: any script, index, test suite, automatic wiring into `start-task` / `workhorse` / `flywheel`, child-repo publishing, device deployment.
- **Alternatives rejected:** a recon mode (table above); a flag on `prior_art_recon.py` (keyword matching is the failure, and it only reads Python definitions).
- **Rollback:** revert the commit; nothing else depends on the skill. Reversibility: Easy.

## Plan

1. Write `skills/3-weekly/connect-the-dots/SKILL.md`: frontmatter (`name: connect-the-dots`, folded `description` with triggers and a "Do NOT fire" clause), when to run / skip, the four steps from the issue, the fit-table template, trigger precedence, hand-offs. Cite the two existing ladders; do not restate them. -> expect `python3 mini/skills/skill-viewer/scripts/list_skills.py` to list it with no error.
2. `skills/3-weekly/dry/SKILL.md` description: add one "Do NOT fire" clause sending "what do we already have for a new problem" to `/connect-the-dots`. `dry` keeps its phrase list. -> expect `git diff` to show one sentence added to the description and nothing else.
3. `ARCHITECTURE.md`: add the Skills Index row between `baseline` and `dry`. -> expect the row link to resolve.
4. Manual red/green pair and adjacent check, recorded under `TESTS-RESULTS/2026-11-14+GH-1484/` with `provenance.jsonl` (see Acceptance). -> expect red to miss, green to hit, the bad sample to be rejected.
5. `bash test/gh589-skill-viewer.sh` and `utils/pdda/pdda.sh run`. -> expect both green.

## Acceptance

Each check names what it observes and what an unchanged repo would show.

- [ ] Skill file present, `name` equals folder name. Observed by `list_skills.py`; before the change the skill is absent from its output.
- [ ] Skill text requires: capabilities before any search; maps → index → grep with a stated mode; a fit table with `file:line`, owner, limiting constraint and a named new remainder; "not found in these searches" wording; no unread candidate. Observed by reading the file against this list.
- [ ] Ladders are cited from `swe-diagram` Step 1 and `recon` Step 2, not rewritten. Observed by reading.
- [ ] Trigger precedence against `recon`, `dry`, `triangulate`, `better-options`, and a "skip when" rule are in the text; `dry` points here.
- [ ] Manual pair on a fixed prompt with no repo nouns and no "flywheel": *"We want an unattended overnight loop that claims tasks so two agents never collide, runs parameter variations to find edge-case failures, and records completion receipts. What should we build?"*
  - **Red (unfixed candidate):** a fresh agent on base `5967bde25` without the skill, plus `prior_art_recon.py --query` on the prompt's keywords. The pair counts only if this output does not cite both `tick` and ATE. If it does, the prompt is too easy: replace it and rerun before the green run counts. This is what stops an unchanged repo being reported as delivered.
  - **Green:** a fresh agent given the skill text and the same prompt cites `tick` and ATE, each with a correct `file:line`, the capability covered and one material limitation. A name without those fails.
  - **Rubric control:** one deliberately bad output (a candidate dropped, or a citation to a file that was not read) is graded with the same rubric and must fail.
- [ ] Adjacent check, input and search scope fixed before running. Prompt: *"We need to render PDF invoices with embedded fonts."* Corpus: files tracked by git in this repo at base `5967bde25` (`git ls-files`). Excluded: the agent's installed skills and tools outside the repo, `relay-system/`, `PROJECT/`, `TESTS-RESULTS/`, `CHANGELOG.md`, `docs/`, and the ledger dumps (`releases.db`, `releases.sql`), which hold prose, not modules. Pre-run evidence, retained with the transcript: `git grep -il` for `pdf`, `invoice`, `embedded font`, `reportlab`, `weasyprint` over that corpus. Run on 2026-11-14 before freezing this case: `pdf` matched only the excluded ledger dumps; the other terms matched CI config, a fuzzy-match test fixture and gate baselines, none of them a rendering module. Expected: "not found in these searches", with the searches listed, and no invented fit. If the pre-run searches are repeated at execution and show a real candidate, this case is invalid and is replaced before it counts; a candidate is never suppressed to pass it.
- [ ] `ARCHITECTURE.md` row present; `test/gh589-skill-viewer.sh` and `utils/pdda/pdda.sh run` green.

## Operator decision and rewritten acceptance (2026-11-15)

The operator's words: "I accept using it as a reuse map that shows its dismissals." and "Can and should we also use the Elephant Goldfish Model as part of the vetting part of skill?"

This **replaces the Green item above**. The original Green item ("cites `tick` and ATE") stays recorded as not met; it is no longer a delivery condition. The skill does not promise a particular module.

Added to the skill for the second sentence, citing `start-task` Step 6 as the one owner of the paraphrase-first rules: a three-heading paraphrase of the problem before the capability list; every `set aside` names its source line or says `inferred`, and an `inferred` dismissal of a subsystem sharing a capability verb is opened before it stands; `consult` as an optional hand-off for a fresh reader. No new reviewer turn, script or gate.

- [ ] **Reuse-map check (run 7), rubric fixed before the run.** A fresh agent on base `5967bde25`, given an answer-free copy of the committed skill and the operator's original wording, passes only if all hold:
  1. The three headings (What this asks for / How it is handled today, per the operator / What it's not) appear before the capability list.
  2. Every fit-table row that names a module cites `file:line`, and every cited file is in the run's own opened list.
  3. The reverse sweep lists subsystems with a verdict each; every `set aside` carries a source line or the word `inferred`.
  4. No unbounded absence claim anywhere in the answer.
  5. A new remainder and exactly one next action are named.
  An unchanged repo (run 2, no skill) fails 1, 2 and 3. Whether `tick` or ATE appear is recorded, not graded.

  **Result: partly met.** Run 7 and run 8 each meet 3 of 5 (points 1, 4, 5). Both cite one file that was searched and not opened (point 2), and neither sweep gives every mapped subsystem a verdict (point 3: run 7 omits ATE, run 8 dismisses about 69 as one group). A text change between the runs did not fix that. The skill now ends its output with a **Files opened** list and tells the reader to check citations; not rerun. Detail: `TESTS-RESULTS/2026-11-14+GH-1484/README.md`.

**After final review (2026-11-15), from the automated PR review, not re-reviewed by Codex:** the skill now continues to the index and grep when a shortlisted candidate fails the constraint check. Lessons: `NO_ENTRY`. A drafted entry was withdrawn because its only support is single runs in which more than one thing changed, which the admission rule calls `confounded`; the observation stays in the evidence README.

## Stop state (2026-11-14)

Final review round 1 (Codex, `relay-system/2026-11-14/gh1484-final-qa.md`): FAIL with two Should findings.

- **F1, accepted and it turned out to matter.** The skill text named `tick` and ATE, so the green run was told the answer. Two control runs with an answer-free copy of the skill did not name both: one named neither, and after a reverse map sweep was added, `tick` was surfaced and set aside and ATE was not listed. The Green acceptance item below is **not met**.
- **F2, accepted.** The adjacent run is graded partial: its opening line claims absolute absence. The skill text now forbids that; not rerun.

Changes after plan approval, all unreviewed: the reverse map sweep in Step 2, the bounded-absence rule for opening lines, and the reworded opening example.

Decision needed from the operator before more work: keep the "names `tick` and ATE" criterion and keep changing the skill; or accept the skill for what the runs show (a cited reuse table and visible dismissals, no guarantee of a particular module); or stop. Resume: on a decision, address it, then run final review round 2 (two rounds remain of three).

**Deviation recorded 2026-11-14 (after plan approval).** The fixed capability-worded prompt above was found by the clean baseline without the skill, so under the rule in the Red item it was replaced with the operator's original wording: *"I've been struggling to get the outer loop for the software flywheel going. What should we build to get it running?"* On that wording the baseline names neither `tick` nor ATE and the skill run names both. Plan review had advised against the word "flywheel"; the runs showed it is what causes the miss. Evidence and grading: `TESTS-RESULTS/2026-11-14+GH-1484/README.md`.

Limits: the one passing pair (runs 2 and 3) was first read as showing the text works on the motivating case. **Superseded:** run 3 was answer-seeded, so it shows only that an agent told the answer can retrieve and cite it; runs 5 and 6 without the answer did not meet the original criterion, and the 2026-11-15 decision replaced it. Fresh agents are Claude subagents in this session; a single model family.

## Test scope

No new suite, registry entry or script (AGENTS.md *No new tests*, GH-831). Existing: `test/gh589-skill-viewer.sh`, `utils/pdda/pdda.sh run`. Manual checks retained under `TESTS-RESULTS/2026-11-14+GH-1484/`.

## Non-goals

Not a tracer (`recon`), not a duplicate audit (`dry`), not a value judgement (`worth-it`), not a builder. No new index, graph, RAG or script. Deferred, not excluded: child-repo publishing, device deployment through Skills Army HQ, automatic wiring into other skills.

## Rating (2026-11-14)

`rated 55/35/50/85`. Severity 35: no defect or data loss; the cost is operator sessions spent re-deriving designs that existing modules already cover (one documented case, #1474). Priority 55: the operator asked for it now and it supports the active outer-loop work. Appeal 50: neutral, no operator score given. Effort 85: one markdown file plus two small doc edits. Recurrence: not a defect class; no incident window applies. No operator override.
