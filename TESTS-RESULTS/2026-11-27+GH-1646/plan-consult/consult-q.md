Consult tie-break at a 4-round plan-QA cap (XYZ-forge GH-1646). Advisory, read-only.

Read, in this repo:
- PROJECT/2-WORKING/GH-1646-PLAIN-BULLET-ACCEPTANCE.md (the plan, final revision)
- relay-system/2026-11-27/gh1646-plan-qa.md (four Codex review rounds and Producer dispositions)
- utils/py/swarm_preflight.py lines 569-640 (extract_acceptance_criteria) and 935-1020 (check_acceptance_fidelity)

Operational envelope: local developer CLI; preflight's acceptance-fidelity comparison between a GitHub
issue's `## Acceptance` list and a capture doc's copy. Smallest change in the existing parser; no new test
suites (one case added to test/gh400-acceptance-fidelity.sh). Commensurate complexity governs.

The issue: plain `- `/`* ` bullets under an issue's Acceptance heading parse as an empty list, so a verbatim
checkbox copy reads `diverged` (exit 5). Codex found real edge cases each round; each was fixed. Round 4
left two blockers; the Producer fixed one (inline code span opener) and resolved the other by retracting an
earlier fix (fence-aware section boundaries), re-declining that earlier finding as pre-existing and
identical before/after the change (per the reviewer's own probe).

Questions (answer each in 1-3 sentences, cite file:line where you disagree):
1. Is the final plan correct and sufficient for issue #1646's requirements: plain bullets counted on the
   issue side, checkbox parsing, the deviations heading, nested bullets and horizontal rules unbroken,
   None vs [] preserved?
2. Is declining the fence-heading boundary finding (Round 3 finding 2) as pre-existing / out of scope
   sound, given the change now makes fence tracking affect only plain-bullet classification?
3. Is declining the #792 archived-doc cleanup sound?
4. Any remaining defect introduced by THIS change (not pre-existing) that should block implementation?
   Give a concrete input if so.
5. Verdict: APPROVE-FOR-IMPLEMENTATION or BLOCK, one line.
