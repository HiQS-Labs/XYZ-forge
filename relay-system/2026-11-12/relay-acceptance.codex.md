# Relay acceptance wording final QA
STATUS: Approved
NEXT: orchestrator

Review only the three added content lines in skills/1-hourly/relay-xyz/SKILL.md against origin/development, and TESTS-RESULTS/2026-11-12+relay-acceptance/SUMMARY.md. User explicitly approved this exact wording and a scoped manual documentation express exception; normal publication hooks remain required. Operational envelope: review instructions, no runtime enforcement. Simple change has no separate plan review.
Questions: Is the wording faithful and proportionate? Does it distinguish planned versus observed rejection and admission versus final acceptance without demanding every regression fail? Does it reuse the existing review stage and preserve execution authority? Are content/effectiveness and exception claims truthful? Check artifact hash against provenance. No new tests or machinery. Read only; no suites, pytest or validate. Edit only this relay file. Append verdict AFTER the closing automation marker and before NEXT TURN; earlier content unchanged except STATUS/NEXT. Findings require concrete input, scope and falsifier.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex reviewer verdict — Approved

[Pass] The wording at skills/1-hourly/relay-xyz/SKILL.md:734–736 is faithful and proportionate within the declared documentation envelope. Intended rejection belongs to plan review; observed evidence or an explicit unverified disposition belongs to final review. Admission is distinct from final acceptance. “Green regression coverage alone” leaves room for a separate defect-sensitive check; it does not demand that every regression fail. The existing QA-template stage carries the questions, with no new runtime enforcement, permission grant, or execution stage.

[Pass] SUMMARY.md truthfully limits its content/effectiveness claims to instruction interpretation, explicitly excludes future model compliance, and leaves independent QA/publication outcomes separate. The scoped manual exception is explicitly authorized in this relay's supplied context; the summary does not misrepresent it as express-driver admission or publication-hook bypass. Approval here covers wording and the supplied summary, not publication readiness.

Evidence: narrow inline Python probe using pathlib/json/hashlib, with PYTHONDONTWRITEBYTECODE=1 and TMPDIR="$PWD/.relay-scratch/tmp"; exit 0. It asserted nonempty artifact hash equality to provenance, exact question uniqueness and placement between the existing QA heading and example. Decisive output: “PASS: hash matches provenance; question occurs once in existing QA section”; SHA-256 d51ef7f5d2093e00ee3542f7009d35a310f5dd22742c2524e86ca55c203f0ec7.

Verification limit: direct origin/development comparison was attempted by a read-only inline Python pathlib/zlib loose-object reader (no git invocation), exit 1: FileNotFoundError for .git/objects/ed/0a386fac4caa170bd9d6b297da7154717288df. The remote ref resolves to the provenance base, but that object is not loose. Accordingly, the exact three-line-only delta against origin/development remains unverified here; the harness/publication checks must establish that scope. No suites, executable fixtures, runtime-effectiveness tests or publication gates ran during this turn. No blocking content findings.

<!-- NEXT TURN goes here -->
