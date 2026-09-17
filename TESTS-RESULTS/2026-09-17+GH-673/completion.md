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

Extended comparison adds explicit restart, native cancellation before cleanup,
and cancellation after cleanup: seven populated phases pass, with both Completed
and Cancelled labels asserted and source bytes unchanged. The retained recipe is
`writer-reader-crosscheck.py --writer-root <full reviewed writer clone>`; only the
GitHub test double and owned temporary ledgers are mutated. The independent
Codex turn shim test passes 43/43 in a disposable full clone; this is not yet the
complete harness preflight or a reader approval.

Bounded one-shot implementation audit answered (Codex only, 1 answer / 0 failures),
but remains advisory and mechanically stamped NO FIRSTHAND VERIFICATION CITED.
It found two real Should gaps: equal-time native identity disagreement was omitted
from the duplicate signature, and a root cap overwrote the row identity diagnosis.
Both populated regression tests failed before repair. Identity joins the signature;
row `error` and independent `root_error` now survive together. Full focused suite
then passes 39/39; production selector, real Chrome and manual harness still pass.
Deleting either fix in memory fails its intended assertion. GH492 helper/caller
state-sweep tests also pass, in an isolated full clone with installer targets isolated.
The seven-phase writer-reader comparison was rerun after these repairs and passes.
None of this is an attested final reviewer approval or qualifying broad-gate result.

Batch handoff: the safer broad preflight at c77b3a05 was stopped with exit143
before the 23:18:02 UTC wall deadline. Its log records 272 suite completions, not
a complete result; no broad pass, final-candidate qualification or reader approval
is claimed. Clone identity remained c77b3a05, core.bare=false, expected local origin
before stopping. Real Gemini links remained on their pre-existing pr235 clone.
The final candidate includes later audit repairs; this partial run does not attest it.
Prepared replacement relay remains Open, ROUND1/2, token handed to Codex, no
reviewer turn dispatched. Next: safe complete harness preflight, actual replacement
review, then fresh final-tip sequential qualification and gated separate PRs.
No push/bypass, PR, merge, live task/label write, migration or deployment in this batch.
The task clone preserves one uncommitted CLI-generated LEADERBOARD view; routine
views are intentionally not included in task commits under repository policy.
