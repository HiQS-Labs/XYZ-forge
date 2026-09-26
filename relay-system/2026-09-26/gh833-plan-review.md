# RELAY · GH-833 plan review — define PRS, the Product Release System
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-26.
-->

NEXT: Producer
STATUS: Open
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
