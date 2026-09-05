# GH-439 rating amendment — Agy QA
NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

## Setup
Artifact: skills/start-task/SKILL.md
Producer: producer
Reviewer: agy
Definition of done: The revised skill rates every task through the canonical RELEASES schema, honors the operator's severity/priority/appeal policy, and preserves governance and overrides.

## Log

### Round 1 · Producer · 2026-09-04
**Did:** Added task rating policy and connected it to intake, recon, dependency-safe ordering, plan QA and final QA. No runtime/schema changes.
**Verification:** quick_validate.py skills/start-task passed; git diff --check passed. Canonical CLI help and handler inspected; GH-439 rated 80/35/50/85 via existing writer and read back.
**Re-review this:** Read skills/start-task/SKILL.md, RELEASES-DB-FAQS.md lines 21–36, and the Rating amendment in PROJECT/2-WORKING/GH-439-START-TASK-SKILL.md. Inspect utils/py/releases_app.py::cmd_roadmap_rate only if needed to verify override handling. Do not scan the entire repo.

User request: each task needs existing XYZ rating; severity informed by recent recurring bug classes and high for crashes/corruption/work-blocking; priority weighted toward severity and user input; appeal neutral unless user overrides. User initially called it severity/impact/appeal; canonical system actually stores priority/severity/appeal/cheapness, each 1–100, so impact is rationale rather than a new field. Old ledger rating vocabulary is retired; separately required PDDA metadata must not be silently removed. Re-run QA with Agy after changes.

Questions:
1. Is every requested rating rule reflected, without inventing a three-level scale, impact column, new rank formula or second write path?
2. Walk a single corrupting crash with no history; many duplicate reports of one incident; genuinely recurring same-class bugs; an explicit appeal/priority/rank override on resume; a grouped PR; and an untracked simple task. Does each yield an honest score and safe action?
3. Does the override policy agree with the CLI? Could --force silently drop user input? Are missing history and old PDDA metadata treated accurately?
4. Is anything blocking, contradictory or unnecessarily broad? Cite concrete file:line findings. Optional improvements should remain optional.

Only edit this relay file. Append graded findings and `VERDICT: PASS` or `VERDICT: FAIL`, plus `Basis: textual only`. PASS requires header STATUS: Approved and token done; FAIL leaves Open and releases to producer. Do not edit source/artifacts, run the full test suite, or run git commits: the shim owns the commit. Use the env-pinned tick in the runtime instruction. Keep the review concise.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (agy)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
