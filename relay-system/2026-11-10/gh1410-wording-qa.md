# GH-1410 wording QA receipt (independent review, normal PR fallback)

- Reviewer: Claude Opus 5.5 (review sub-agent), 2026-11-10
- Clone: /private/tmp/xyz-debug-mantra-express-20261110
- Reviewed HEAD: 8a7e93d11301f11a4b2e84a37754dea98fe1b924 (`git diff origin/development..HEAD`)
- Scope: the 8-line addition at `skills/1-hourly/debug-mantra/SKILL.md:57-63`, read against the whole skill (swept file: yes)
- **Verdict: PASS.** No blockers, no should-fix findings. Two optional nits below.

## Findings

- [Pass] Addresses the failure class. Line 59 separates the reported symptom from a related synthetic reproduction and requires the distinction to be labelled. Lines 60-61 require tracing existing guarantees (code, tests, prior fix rationale) and trying to violate them, including "combinations of inputs tested separately". Line 63 covers assertion changes and says a red control is not proof that guarantees survived.
- [Pass] Does not overclaim. Line 63 says "Record unresolved checks as unverified; do not describe the candidate as regression-free." The addition creates no new gate, suite, runner or authority.
- [Pass] No contradiction with test policy. Line 61 says "Use existing tests or proportionate manual probes under the host repo's test policy". This agrees with the plan pivot's *No new tests* / GH-831 wording at line 90 and the "Scale rigor to the bug" rule at line 108.
- [Pass] No contradiction with reproducibility. Line 59 ("A synthetic reproduction of a related defect is insufficient") tightens step 1 (lines 28-32, "observe the primitive ground truth"). It does not loosen it. The recital (lines 12-16) is unchanged, so the verbatim rule still holds.
- [Pass] No contradiction with the plan pivots. The addition sits in the debug reading of step 3. Plan pivot 3 (line 90) is untouched and still compatible.
- [Nit] Line 59: "insufficient" has no object. Suggested fix: "is insufficient to claim the reported symptom is fixed". This would make clear that the synthetic case may still be used if it is labelled. Optional.
- [Nit] Line 57: "Before accepting a fix" sits under the hypothesis step, ahead of the mantra-4 RC statement (line 78). Order of use is clear enough, and the "Root or proximate" paragraph already uses "before accepting it" the same way. No change needed.

## Limitations

- I reviewed the wording only. I ran no tests and checked no behaviour, and the addition makes no code claims.
- This is a normal-PR-fallback review receipt. It is **not** a relay-drive attestation and does not stand in for the timed-out agy relay or the express `skill-unattested` refusal.
- Out of scope, noted only: the committed `relay-system/2026-11-10/gh1410-debug-mantra.md` is an unrun scaffold (`NEXT: Reviewer`, `STATUS: Open`, Definition of Done placeholder). It should not be read as review evidence.
- I did not review the ledger rows (`releases.db`/`releases.sql`), the CHANGELOG or the capture doc beyond reading them.
