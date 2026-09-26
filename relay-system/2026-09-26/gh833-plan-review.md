# RELAY · GH-833 plan review — define PRS, the Product Release System
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-26.
-->

NEXT: Producer
STATUS: Approved
ROUND: 3 / 3

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
6. **Commit only the relay file** (`relay(gh833-plan-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh833-plan.md** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/0cc9b6f4-22bd-4606-b4ec-21e1b8f38591/scratchpad/gh833-plan.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-26
- Definition of Done: **Approved** when all of these hold:
  - (a) each recon claim R1–R6 matches the cited files and lines;
  - (b) the plan covers every item of #833's scope and acceptance, or names why one is out;
  - (c) there is one canonical definition, and every other placement points to it without restating it;
  - (d) every touched file is docs to `utils/ci-route.sh`, so the landing is tier 1 and takes the hosted Small
    run; nothing touches `relay-automation/*` or `skills/*/relay-xyz/*`;
  - (e) the witnesses V1–V5 are falsifiable, their red controls fire, and nothing adds a suite, a registry
    entry or gate machinery;
  - (f) the rating `55/20/50/85` and its rationale are grounded, and appeal is neutral (the operator set none).

## Review packet

**What this is.** The plan for #833 (`https://github.com/HiQS-Labs/XYZ-forge/issues/833`): define PRS, the
Product Release System (the RELEASES ledger), once, and spell it out where the canonical docs and six skills
introduce the ledger. The artifact is `.relay-artifacts/gh833-plan.md`, a copy of
`PROJECT/2-WORKING/GH-833-PRS-DEFINITION.md` at `fd511c52`. Read #833's text with `gh issue view 833` if you can;
otherwise, the plan's scope follows the issue's steps 1–3, non-goals and acceptance.

**Operational envelope.** A single-repo local developer harness. This is a docs-only wording change. The operator
has ruled "no new tests" (AGENTS.md). The merge must also be docs-only to the tier router, because it is the
first landing meant to qualify through the hosted Small run (#831 Phase 3). Grade against the stated
requirements and commensurate complexity. Do not ask for new suites, lint rules, glossary machinery or code.

**Read:**
- the artifact;
- the placements it cites: `HOW-TO-USE.md` 5-10 and 67-80, `ROUTER.md` 1-12 and 110-125, `AGENTS.md` 154-178,
  `PROJECT/PDDA.md` 590-602 and 944-950, `SOP.md` 58-64, `ARCHITECTURE.md` 76-82 and 402-408,
  `RELEASES-DB-FAQS.md` 1-8, `README.md` 36-40 and 140-147;
- the skills: `skills/2-daily/releases/SKILL.md` 1-10, `skills/1-hourly/start-task/SKILL.md` 236-244,
  `skills/2-daily/merge-cleanup/SKILL.md` 1-10, `skills/2-daily/start-marathon/SKILL.md` 236-241,
  `skills/3-weekly/10days/SKILL.md` 1-25, `skills/3-weekly/end-of-week/SKILL.md` 28-34;
- `utils/ci-route.sh` 54-72 (`is_docs_surface`) and 305-350 (`full_required`);
- `utils/py/wave_reconcile.py` 589-614 (`select_qualification_gate`).

You may run read-only probes, such as `git grep -nw PRS` or piping a path list through
`bash utils/ci-route.sh push`. Do not run suites.

**Questions** (cite `file:line`):

1. **Placements.** Is each R2/R3 placement the right one? In particular:
   - `AGENTS.md` 173 rather than 157;
   - `ARCHITECTURE.md` 406 rather than the catalog row at 80;
   - `README.md` 145 rather than 38;
   - start-task's rating policy rather than its recite block;
   - editing `10days`'s frontmatter description and `end-of-week`'s recite block, where PRS first appears.
2. **`PROJECT/PDDA.md`.** It is the PDDA contract that other repos adopt. Is the proposed wording right for
   them, and is the roadmap-ledger contract at 948 the right place?
3. **The glossary.** Is `HOW-TO-USE.md`'s glossary the right single home for the definition, rather than
   `RELEASES-DB-FAQS.md`? Is the proposed entry accurate about what the ledger holds and how it is written?
4. **Tier 1.** Can any touched path, including the ledger dump and this relay thread, route as non-docs?
   Is the "only landing in its reconcile" condition correct?
5. **Witnesses.** Does V1 catch a PRS used before its definition, and an edit that is missing? Do V1's and V2's
   red controls fire? Is V3's suite list complete?
6. **Scope.** Anything missing from #833, over-built or out of scope?
7. **Rating.** Is `55/20/50/85` grounded in the rationale?

Write findings in the Log per the turn rules. Set `STATUS: Approved` only if the Definition of Done is met.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The wording scope is proportionate, but R6 misattributes coverage and V1 does not witness the canonical-definition requirement. Revise the plan's evidence, not the runtime.
swept file: yes

Reviewed the entire seeded plan, including recon, verification, merge conditions and rollback. Findings include existing inaccuracies in that artifact. No artifact/source edits or suites were run.

- **[Should] F1 — witness the canonical definition and its links separately from first-use expansion.** V1 at `.relay-artifacts/gh833-plan.md:145` accepts a missing glossary entry. Add a retained manual check that the glossary contains the single substantive definition and that other placements reach it (directly or through the FAQ); include a missing-entry/broken-link red control. No suite or gate machinery.
  Observed input: An in-memory HOW-TO-USE with only the planned introductory expansion, leaving its glossary unchanged. Probe command: `python3` with `s=Path('HOW-TO-USE.md').read_text(); s=s.replace('The **releases DB\nis the commitment ledger**','The **releases DB** — the Product Release System (PRS) — **is the commitment ledger**',1); first=next(l for l in s.splitlines() if re.search(r'\bPRS\b',l))` (imports: pathlib.Path, re). Exit 0; decisive output: `V1 checker_rc=0 canonical_glossary_entry_present=False` (entry predicate: `bool(re.search(r'^- \*\*PRS\*\*',s,re.M))`).
  Affected scope: Plan steps 1–4 and relay DoD (c), not runtime behavior.
  Falsifier: All first-use expansions but no canonical glossary entry must fail the additional manual check; the complete linked definition must pass. V1 may remain the narrow expansion check.

- **[Should] F2 — correct the reader map and coverage claims.** R6 at plan line 106 says gh400 reads 10days and gh436 reads merge-cleanup's SKILL.md. Those suites do not establish coverage of these wording edits. `test/gh400-source-url.sh:23` selects swarm_preflight.py; its unit function imports check_source_url and reads generated capture docs. Its 10days mention at line 5 is a historical comment. `test/gh436-merge-cleanup.sh:11` invokes the Python suite; `test/gh436-merge-cleanup.py:20` targets skill scripts, and its SKILL.md occurrences are temporary symlink fixtures. Reclassify these as optional code regression checks or omit them from the focused wording checks. Keep actual readers (releases-skill and gh609), and name manual text/link inspection for uncovered edits. Explicitly place any suite execution in a disposable full clone.
  Observed input: `rg -n 'SKILL\.md|read_text|open\(' test/gh436-merge-cleanup.py` exited 0; SKILL.md hits were lines 408–409, 678, 701 and 719, all fixture paths/comments. Reading gh400-source-url.sh showed generated capture-doc inputs, not the skill.
  Affected scope: R6, V3 and the skill-text regression coverage claim at plan line 172.
  Falsifier: A concrete assertion reading the real edited 10days/merge-cleanup SKILL.md and rejecting its relevant malformed text would justify the attribution. Fixture symlinks and comment mentions do not.

- **[Nit] F3 — correct V1's predicted baseline counts.** Plan line 148 says 13 absent and one bare use, contradicting R1. Applying its predicate with `python3`, Path.read_text and `re.search(r'\bPRS\b',line)` to the 14 named files exited 0 and reported `files=14 missing=10 bare=4 checker_rc=1`. Bare first matches: ROUTER:119, start-marathon:239, 10days:6, end-of-week:32. All 14 fail, for the stated 10/4 reasons. The in-memory ROUTER introduction/removal probe gave checker statuses 0 then 1, so that red-control design works.

- **[Pass] Placements, definition scope and rating.** The selected prose placements match AGENTS.md:173, ARCHITECTURE.md:406, README.md:145, SOP.md:62 and the six cited skill locations. HOW-TO-USE.md:67 is a reasonable glossary home; AGENTS.md:173 supports the two-subsystem description. PROJECT/PDDA.md:946–948 distinguishes legacy and releases-mode repositories, so “which XYZ Forge calls” appropriately limits the naming claim. Preserve usable links for downstream adopters. The rating rationale at plan lines 44–51 matches skills/1-hourly/start-task/SKILL.md:248–251, including neutral appeal and higher-is-cheaper effort.

- **[Pass] Planned paths and V2 red control.** Probe command: `python3` calling `subprocess.run(['bash','utils/ci-route.sh','push'], input='\n'.join(paths)+'\n', capture_output=True, text=True)` on the 14 named docs/skills plus CHANGELOG, the working plan, releases.db/sql, this relay and the two planned evidence paths (21 nonempty paths). Exit 0: `route=docs tier=1 full_required=false`. Repeating with `relay-automation/README.md` appended exited 0: `route=full tier=3 full_required=true`. This matches utils/ci-route.sh:64–68 and :339–341. Classification of the final committed diff remains owed.

- **[Nit] Reconcile and qualification wording.** wave_reconcile.py:597–612 selects Small for a tier-1 union; another docs-only landing does not prevent Small. Keeping a single-landing schedule is sensible for attribution, but label it a scheduling choice, not a classifier necessity (R5). Call V5 a local push self-check, reserving landing qualification for hosted Small; githooks/pre-push:22 and :260 distinguish these.

- **[Unverified — needs clone run]** V3/V4/V5 and final hosted qualification were not executed here. Their future results cannot be inferred from text probes. Live issue retrieval `gh issue view 833 --repo HiQS-Labs/XYZ-forge --json title,body` exited 1: `error connecting to api.github.com`; scope was assessed against the supplied review packet, as permitted.

Root cause: evidence descriptions overstate what the proposed checks observe; fix site: the plan's recon/verification prose and retained manual witnesses; no runtime or new test mechanism is needed.

Handing off to Producer (claude-a) to disposition F1–F3 and the qualification wording, then return the revised plan for review.

### Producer · Round 1

All in `ea7e030f`; the artifact is the plan at that commit. The two check scripts and their base output are committed
under `TESTS-RESULTS/2026-09-26+GH-833/` (`prs-order-check.sh.txt`, `prs-definition-check.py.txt`,
`red-controls-base.log`).

- **F1 — Implemented.** New V1b (`prs-definition-check.py.txt`):
  - exactly one `- **PRS**` glossary entry that spells out the term and names XYZ Forge and PDDA;
  - no restated entry in any other checked file;
  - in the seven linked docs, the spelled-out paragraph links the glossary, with the anchor checked against
    GitHub's slug of the real heading, or `RELEASES-DB-FAQS.md`, and the linked file must exist.
  - At base it reports 8 failures, rc 1. Three post-edit red controls are named: delete the entry, break
    ROUTER's anchor, add a second entry.
  - DoD (c)'s "points to it" is scoped: `PROJECT/PDDA.md` and the six skills carry the spelled-out form with no
    link, because PDDA.md is adopted by other repos and skills are deployed outside the repo. Plan steps 3-4
    say so.
- **F2 — Modified.**
  - `gh400` is removed: its 10days mention is a comment (`test/gh400-source-url.sh:5`), as you found.
  - `gh436` stays. Its symlink fixtures are not the reader; `test/gh436-merge-cleanup.py:863-865` imports
    `gh534_phase_c_tests` with `import *`, and that loads the real file at `test/gh534_phase_c_tests.py:523`
    (`SKILL_MD`) for the parity guard and the drive-loop check (`:870`).
  - R6 now says no registered suite reads the `10days`, `start-marathon` or `end-of-week` edits; V1 and reading
    the diff cover them.
  - V3 runs in a separate disposable full clone at the final commit.
- **F3 — Implemented.** V1's base result is 0/14: ten with no PRS, four bare-first (`ROUTER:119`,
  `start-marathon:239`, `10days:6`, `end-of-week:32`). It was run and recorded in `red-controls-base.log`.
- **Nit (reconcile) — Implemented.** R5 now says another docs-only landing keeps tier 1, and merging alone is a
  scheduling choice for attribution. V5 is called a local push self-check, not qualification.

Handing off to Reviewer (codex) for round 2.

### Reviewer · Round 2

VERDICT: FAIL
Basis: The evidence revisions resolve F2/F3, but the new no-pointer exemptions leave DoD (c) unmet. One portable-pointer correction is needed; no runtime change or new gate is requested.
swept file: yes

Read the entire revised seeded plan, including the pre-existing recon, rating, merge conditions and rollback. Applied the SWE and debug-mantra plan rubrics. No additional material defects found in that whole-plan sweep beyond the pointer gap and evidence-retention note below. No artifact/source edits, git commands or suites were run.

- **[Should] F1 remains partly open — preserve the canonical pointer for adopted PDDA and deployed skills.** Plan lines 123–124 promise that every other doc points to the canonical definition, but lines 144–146 explicitly remove the pointer from PDDA and all six skills. That does not meet this relay's unchanged DoD (c): “every other placement points to it without restating it.” Avoiding broken relative links is correct; omitting the pointer is not the only solution. Use a portable absolute repository URL to the canonical glossary for these placements (a nearby prose pointer is sufficient where frontmatter/recite formatting matters). Include those pointers in V1b or the retained manual link inspection; do not add gate machinery.
  Observed input: `.relay-artifacts/gh833-plan.md:144`: “PROJECT/PDDA.md gets no link”; `:145–146`: “The six skills: ... with no link.” The new V1b only checks the seven linked docs (`:166–168`), so the seven exemptions are intentional and unobserved by that witness.
  Affected scope: The seven distributed-doc/skill pointers required by DoD (c), plan steps 3–4 and their manual verification; no change to their operational instructions.
  Falsifier: Each of those seven placements names the expansion and provides a resolvable portable pointer to the one glossary definition, without duplicating its substantive contents. That satisfies (c) while surviving deployment outside this checkout.

- **[Pass] F2 — the indirect reader establishes gh436's inclusion.** My round-1 reader trace stopped too early. `test/gh436-merge-cleanup.py:865` imports `gh534_phase_c_tests`; that module defines the real `SKILL_MD` at `:523` and reads it at `:877`. Retaining gh436 in V3 is justified as regression coverage of that skill's contracts, not proof of its introductory expansion. `utils/ci-route.sh:38` includes gh436 and releases-skill in Small; `validate.sh:144` registers gh609. The correction that gh400 does not read 10days and the explicit disposable-clone boundary at plan lines 179–181 resolve the remaining F2 concerns.

- **[Pass] F3 and the baseline V1b failure are reproducible.** Read-only command: `python3` with `Path.read_text().splitlines()` over the 14 named paths, selecting the first `re.search(r'\bPRS\b', line)`; exit 0, decisive output: `files=14 missing=10 bare=4`. Bare-first locations were ROUTER:119, start-marathon:239, 10days:6, end-of-week:32. Command: `PYTHONDONTWRITEBYTECODE=1 python3 TESTS-RESULTS/2026-09-26+GH-833/prs-definition-check.py.txt "$PWD"`; exit 1, decisive output: `V1b: 8 failure(s)` (missing entry plus seven missing spelled-out paragraphs). This reproduces the retained base log; it does not establish the future post-edit green or mutation results.

- **[Pass] R1–R5, placements, rating and routing remain sound for this plan.** Re-read the target spans: HOW-TO-USE:7/67, AGENTS:173, PDDA:948, SOP:62, ARCHITECTURE:406, FAQ:3, README:145 and the six R3 locations. The single definition's two-subsystem description is supported by AGENTS:173–178; the conditional PDDA wording preserves the legacy/release-mode distinction at PDDA:948. Rating policy at start-task:248–251 supports neutral appeal and higher-is-cheaper effort. Router probe command: `python3` calling `subprocess.run(['bash','utils/ci-route.sh','push'], input='\n'.join(paths)+'\n', capture_output=True, text=True)`; the 22 nonempty planned/evidence paths exited 0 with `route=docs tier=1 full_required=false`. Appending `relay-automation/README.md` (23 paths) exited 0 with `route=full tier=3 full_required=true`. This includes the new .txt/.log evidence files. R5's corrected scheduling distinction matches `utils/py/wave_reconcile.py:597–612`; V5 now correctly distinguishes the local self-check from hosted qualification.

- **[Nit] Retain provenance with the already-recorded base results.** Plan lines 154–155 require `provenance.jsonl`, but `Path('TESTS-RESULTS/2026-09-26+GH-833/provenance.jsonl').is_file()` in the read-only Python probe exited 0 and printed `False`. The base log and check texts exist. Before citing these runs in the PR, retain their provenance alongside the final witness results as the plan already requires. Do not retrospectively invent missing execution metadata.

- **[Unverified — needs clone run]** V3/V4/V5, the final committed-diff classification and hosted qualification remain future execution work. The three post-edit V1b mutations remain specified controls, not witnessed results in this turn. Live issue command `gh issue view 833 --repo HiQS-Labs/XYZ-forge --json title,body` exited 1 with `error connecting to api.github.com`; issue scope was assessed against the supplied packet, as permitted.

Root cause: the revision solves relative-link portability by dropping a required canonical pointer; fix site: plan steps 3–4 and their manual witness; why not upstream/downstream: the mismatch is in the planned documentation contract, not the ledger or router.

Handing off to Producer (claude-a) — add the portable pointers and return the revised plan for round 3; go to the Producer window and say 'take your turn'.

### Producer · Round 2

All in `130804db`.

- **F1 (remaining) — Implemented as you proposed.** `PROJECT/PDDA.md` and the six skills now carry the absolute
  URL of the glossary heading on development,
  `https://github.com/HiQS-Labs/XYZ-forge/blob/development/HOW-TO-USE.md#glossary--the-five-terms-youll-hit-first`
  (plan steps 3-4).
  - This follows existing practice: `skills/1-hourly/relay-xyz/SKILL.md:44` and `:118` link `relay-automation/`
    by absolute URL.
  - Where PRS first appears in frontmatter (`10days:6`) or a recite block (`end-of-week:32`), the URL goes in the
    nearest prose after it.
  - V1b now checks that each of the seven contains that URL with the anchor equal to the real heading's slug.
    At base it reports 15 failures (recorded in `red-controls-base.log`). A fourth post-edit red control changes
    one skill's anchor.
  - DoD (c) now holds for all 13 placements: seven link through the glossary or the FAQ, and seven use the
    absolute URL. `HOW-TO-USE.md` itself is the definition, so the 14 files are 1 + 13.
- **Nit (provenance) — Implemented.** `TESTS-RESULTS/2026-09-26+GH-833/provenance.jsonl` records the base
  red-control run: what ran, where, the exit code, the artifacts and the result. The post-edit witnesses will be
  appended as they run.

Handing off to Reviewer (codex) for round 3, the last in the cap.

### Reviewer · Round 3

VERDICT: PASS
Basis: The portable canonical pointers close the remaining F1 gap; the plan is ready for implementation. Approval is of the plan, not a claim that its future execution gates have passed.
swept file: yes

Read the entire seeded plan, including recon R1–R6, rating, all verification criteria, merge conditions and rollback. Applied the SWE and debug-mantra plan rubrics. No remaining material defects found, including in the pre-existing plan text. No source/artifact edits, git commands or suites were run.

- **[Pass] F1 closed.** `.relay-artifacts/gh833-plan.md:144–153` now requires the absolute glossary URL in PDDA and all six skills, with nearby prose placements for frontmatter/recite uses. This preserves portability and DoD (c). `TESTS-RESULTS/2026-09-26+GH-833/prs-definition-check.py.txt:71–74` checks all seven portable pointers against the actual heading slug; the fourth mutation at plan line 185 targets a skill anchor. The definition remains in HOW-TO-USE's glossary, with expansion and pointers elsewhere.
- **[Pass] Baseline witnesses and provenance.** Read-only command: `PYTHONDONTWRITEBYTECODE=1 python3 TESTS-RESULTS/2026-09-26+GH-833/prs-definition-check.py.txt "$PWD"`; exit 1, decisive output: `V1b: 15 failure(s)` (one missing entry, seven missing expansion paragraphs, seven missing portable pointers). A Python `Path.read_text()` scan over the check's nonempty 14-file ALL list, selecting each first `re.search(r'\bPRS\b', line)`, exited 0 with `V1 files=14 missing=10 bare=4`. `TESTS-RESULTS/2026-09-26+GH-833/provenance.jsonl:1` now records the base run, source/base identifiers, timestamp, exit code and artifacts. This establishes the retained baseline record, not independent attestation of its historical execution metadata.
- **[Pass] Routing remains Small-eligible.** Probe: Python `subprocess.run(['bash','utils/ci-route.sh','push'], input='\n'.join(paths)+'\n', capture_output=True, text=True)` on the 14 docs/skills, CHANGELOG, working plan, releases.db/sql, this relay and four evidence files (23 nonempty paths). Exit 0: `route=docs tier=1 full_required=false`. Appending `relay-automation/README.md` (24 paths) exited 0: `route=full tier=3 full_required=true`. Supported by `utils/ci-route.sh:65–68` and `:336–337`; `utils/py/wave_reconcile.py:597–612` confirms classification of the pending-landings union. Final committed-diff classification remains an implementation obligation.
- **[Pass] Scope, placements, rating and suite attribution.** The R2/R3 placements still match the cited prose, including `AGENTS.md:173`, `PROJECT/PDDA.md:948`, `ARCHITECTURE.md:406`, `README.md:145`, `skills/1-hourly/start-task/SKILL.md:240`, `skills/3-weekly/10days/SKILL.md:6` and `skills/3-weekly/end-of-week/SKILL.md:32`. Rating rationale at plan lines 44–51 follows start-task's policy at lines 248–251. The gh436 indirect reader is present at `test/gh436-merge-cleanup.py:865` and `test/gh534_phase_c_tests.py:523,877`; V3 appropriately requires a disposable full clone. No new registered suite or gate is planned.
- **[Nit] Counting in Producer round 2.** The seven locally linked docs include HOW-TO-USE itself; the 13 other placements are six local docs plus seven portable placements. The plan/check lists already have the correct 14-file total; this arithmetic slip in the disposition requires no artifact change.
- **[Unverified — needs clone run]** V3/V4/V5 and final hosted qualification are future work. Post-edit green checks and all scratch mutation controls remain execution obligations under plan lines 179–196. No present result is claimed for them. `gh issue view 833 --repo HiQS-Labs/XYZ-forge --json title,body` exited 1 with `error connecting to api.github.com`; scope was assessed against the supplied packet as permitted. The development glossary URL is intentionally prospective until merge (plan line 153).

Root cause addressed: the planned distributed placements previously dropped the required canonical pointer; the revision fixes that contract at the documentation placements and their manual witness, without runtime changes.

Relay closed (Approved), no further turn needed. Producer (claude-a) may implement the approved plan and retain the specified execution evidence; final implementation QA is still required.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
