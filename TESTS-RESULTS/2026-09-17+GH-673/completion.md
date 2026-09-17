# GH-673 focused completion evidence

2026-09-17; task branch fix/gh673-reader-completion; baseline origin/development
0389dc6ef4aadc9323341253ecd7a5fa49333ea4. Original reader f7f760a3 and its capped
review remain in the separate original full clone; this is a selective replay,
not a claim that historical receipts attest this new candidate.

Before repair: the two new invalid-row Python regressions failed (availability
unavailable; missing exclusion diagnostic). The real Chrome unchanged healthy
clock-tick regression failed (`false !== true`). After repair, the full focused
Python suite passes 37/37. Production selector and expanded real Chrome checks pass.
An intermediate reversed-order test caught issue-local copies of a root diagnostic;
the diagnostic is now only on the root, and both orderings compare identically.

Populated synthetic fixtures only; Chrome HTTP and debugging bind loopback. No live
status, GitHub label, schema migration or reader deployment. Tests verify source
data/schema preservation under the operator-approved coordination-file policy.
These checks do not attest the unmerged writer, full gate or final reviewer approval.

Workhorse consult: SINGLE-MODEL, NOT RECONCILED. Codex design answer has no qualifying
firsthand-verification receipt. Agy failed idle-progress detection (>=90 seconds),
then consult reported failed/exceeded 180-second cap. Its failure is not agreement.
Raw preserved transcripts are local scratch, not a final QA verdict.

Additional checks: the manual fixture/server/production UI harness passes. Deleting
the selector per-row error guard fails (`conflict` instead of `unknown`); deleting
per-row finalization preservation fails at the intended marker assertion
(`None != 'unqualified-ledger-row'`). No production files were mutated for these
controls. An initial mutation-run setup copied globals and bypassed its mock; its
availability failure was discarded, then the live-globals version proved the
intended error-preservation assertion.

Synthetic writer-to-reader comparison uses reviewed writer candidate `ecb39a10`
and reader runtime `95b3cc24`: accepted start + projected mock label -> In progress;
native closure before label cleanup -> Completed, cleanup pending; completed writer
and mock label cleanup -> Completed without warning; reopen without accepted restart
-> Not marked active. Every phase has one nonempty issue and unchanged source DB
bytes across reads. GitHub is mocked; this is not real-world end-to-end qualification.

Full harness preflight was deliberately stopped with exit143 after source inspection
confirmed the newly reported GH-678/PR680 baseline installer-test HOME escape.
All three real Gemini links were read before/after and remained unchanged. No green
broad run or final QA approval is claimed. Safer follow-up redirects all five
installer target variables to owned scratch, without changing HOME or source code.
