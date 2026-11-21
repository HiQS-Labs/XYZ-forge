# Acceptance question final QA
STATUS: Approved
NEXT: done

Review the three-line diff to skills/1-hourly/start-task/SKILL.md and TESTS-RESULTS/2026-11-12+acceptance-review/SUMMARY.md. User explicitly requested this question and merge if green. Operational envelope: existing plan-review instructions, no runtime enforcement. Simple change skipped plan QA.
Questions: Is wording faithful to the user requirement? Does it distinguish admission and final acceptance without demanding all regression suites fail baseline? Does it fit existing Step6 without extra stage/authority? Are evidence claims proportionate and honest? Check main/adjacent consumer paths in SUMMARY. No speculative machinery or new tests. Read only; no suites/pytest/validate. Edit only this relay file. Append verdict AFTER the automation block below; do not edit earlier content except STATUS/NEXT. For behavioral findings give observed input, scope and falsifier.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

<!-- NEXT TURN goes here -->

## Codex reviewer verdict — 2026-11-12

**Ship. Approved** for the stated documentation-only scope. No blocking findings.

Source-backed review: `skills/1-hourly/start-task/SKILL.md:215–220` places the three-line question within the existing Step 6 technical questions. It faithfully asks what prevents false delivery and where rejection was observed; admission probes cannot substitute for final acceptance. It does not require every regression suite to fail on the baseline. A separate acceptance check that rejects the unfixed candidate can satisfy the question while regression suites pass. The surrounding Step 5 red-control instructions and Step 8 final QA remain the existing owners; no new stage, runtime mechanism or approval authority is introduced.

Consumer read-through: on the main path (unfixed candidate with green regressions), the wording demands rejection evidence beyond that green result. On the adjacent path (green regressions plus a defect-sensitive final acceptance check), the wording permits that separate check. Admission-only detection does not answer final acceptance. These are content interpretations, not executed agent-behavior results.

`TESTS-RESULTS/2026-11-12+acceptance-review/SUMMARY.md` is proportionate: it explicitly limits evidence to instruction/content verification, disclaims demonstrated future compliance, and records the simple-change plan-QA skip. Historical issue assertions and exact user-approved phrasing are supplied context, not independently revalidated here. The before-state comparison is author-reported; this reviewer independently confirmed current text and its provenance hash.

Non-mutating probe: with `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR="$PWD/.relay-scratch/tmp"`, ran `python3` using `hashlib.sha256(Path('skills/1-hourly/start-task/SKILL.md').read_bytes())`, compared it to `json.loads(Path('TESTS-RESULTS/2026-11-12+acceptance-review/provenance.jsonl').read_text())['sha256']`, and asserted the question prefix occurs exactly once. Exit 0; decisive output: `PASS: artifact SHA256 matches provenance; acceptance question occurs once in Step 6`.

No suites, pytest, validate, executable fixtures or Git commands ran. Applicable harness/post-turn gates and merge remain outside this reviewer turn; this approval does not assert they passed.

### Attestation · relay-drive — 2026-11-12T20:25:58Z
task: ACCEPTANCE-REVIEW-20261112
reviewer: codex
status: Approved
reviewed-head: f4c7ab4657e4cf576c4bb6ed95e306baf4a56e48
added-range: 1101+2317
added-sha256: 3a3830f671a2d5a135d415fe4bfe9be11495a4b563be4bfc611d1261b9c85719
gate-run: undeclared
