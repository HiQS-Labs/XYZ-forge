# GH-1007 verification

Source: `skills/1-hourly/swe/SKILL.md`; SHA-256: `b8a507482cd0def67078df57b1477af014f63f78e8993e8061f73c6fae60fe2b`.
The provenance revision is the parent before applying the reviewed source; the digest
identifies the exact checked bytes. This evidence is committed with that source.

Existing format validator: PASS; isolated copy with missing frontmatter `name`:
FAIL as expected (`Missing 'name' in frontmatter`). This red control
establishes format-check sensitivity only. No new validator or test suite was added.

Existing Codex shim suite: 43 pass / 0 fail in a separate disposable full clone.
HEAD, core.bare, remotes, and local user.email remained unchanged. Output retained in
`codex-turn.txt`; command/revision/result in `provenance.jsonl`.

## Manual instruction application

Procedure: read each scenario below, apply the cited clauses, and compare the resulting
decision with its stated failure. These are reviewer judgments, not executed agent tests.

| Scenario | Observed decision supported by final text | Source lines |
|---|---|---|
| Small rename, existing coverage, suggestion to add four tests | Use existing check; no test quota or phase/benchmark ceremony. A four-test default contradicts explicit policy. | 20, 53–67, 75 |
| New authorization boundary, meaningful coverage gap | Preserve security verification; require gap/cost justification for a new test and a separate CI-placement decision; stricter repo prohibition still applies. | 18, 27, 57–67 |
| Feature fits existing writer; contrasting incompatible trust boundaries | Reuse existing owner in the first case; justify separation in the second. Neither duplication for convenience nor unsafe forced reuse is allowed. | 41–49 |
| CI drops from 10 to 7 minutes due to dependency cache | Report pipeline improvement only. No product-speed conclusion. A noisy product sample is inconclusive. | 81–84 |
| Hot path under a real latency constraint | Capture comparable base/candidate evidence and variability; advisory first; use existing task doc/issue with durable evidence. | 75–90 |
| Authorized irreversible action has no stop checkpoint; Easy rename control | Still flag missing stop condition and last intervention point for irreversible action; do not burden Easy rename with that ceremony. | 20, 100 |
| Rolling data migration, with offline alternative | Retain compatibility, ordering, convergence, rollback and delayed-consumer retirement; do not mandate bidirectional synchronization or unsafe fallback. | 49, 100–104 |

Negative comparisons: the former plan-only opening cannot satisfy implementation-mode
governance; its fixed phase scaffold and correlation-ID requirement fail the small-edit
case. The pre-review draft's missing one-way-door tripwire failed plan QA (S1). Restored
line 100 now explicitly addresses that concrete omission. No repository files were
mutated to manufacture these manual controls.

## Scope and limitations

No scripts, test files, registry entries, CI workflow, dependencies, or app links were
changed. Existing named Pillar 0/Blast consumer contracts remain. No runtime performance
improvement is claimed for this Markdown change; benchmarking would add no useful signal.
Format validation and manual scenarios do not prove future agent compliance. Independent
plan and final relay reviews supply a separate bounded assessment.

Plan receipt: `relay-system/2026-10-09/gh1007-plan.codex.md` (Approved, Round 2).
Final receipt: `relay-system/2026-10-09/gh1007-final.codex.md` (Approved, Round 2; driver exit 0).
The path classifier, documentation gate, pre-push gate and hosted results are recorded
separately as they run; none is inferred from an unexecuted configuration.

Classifier: docs/tier 1. Documentation gate: exit 0, no errors, 28 repository
warnings (issue/doc, governance, marathon QA); full output in `pdda.txt`.

Final QA independently applied the seven scenarios, matched all 15 text-file hunks
in the review packet to current files, confirmed the source digest and ledger admission,
and accepted the scope disposition for the parked architecture mismatch. This is bounded
instruction review. Bookkeeping after approval changes only status and receipt records.
