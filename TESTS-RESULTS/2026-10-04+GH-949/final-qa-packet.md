# PR953 resumed final independent QA

Goal: determine whether PR953 can leave draft after its latest Fable B1 blocker
is repaired. Current implementation `3a2e1d5e`; previous PR head `0b892acd`;
integration base `6beac5bf` (PR948 merged). This continues the existing approved
GH949/GH912 plan, not a new feature or architecture.

Operational envelope: local macOS developer CLI. Use commensurate complexity:
reuse existing helpers; no new executor, global library signal registration,
suite, gate, registry, schema, dependency or speculative enterprise machinery.
No live provider calls, services, tunnels, merge or promotion are in scope.

Read the complete canonical plan and Fable review, the retained original evidence,
and this resumed evidence summary. Sweep all six touched runtime files in full:
`utils/py/proc_group.py`, `domain_oracles.py`, `metamorphic_oracle.py`,
`utils/ate/scripts/run_variations.py`, `skills/1-hourly/relay-xyz/find-harness.sh`,
and `test/lib/runner-envelope.sh`. The resumed runtime diff is only the two oracle
imports and `__main__` guards; approved original API shapes should remain intact.

Questions:

1. Does B1 close at both actual CLI entry points: catchable TERM/INT unwinds through
   shared group cleanup, preserves143/130 and leaves library/threaded calls free
   of global handlers? Do normal exit, argument-error and JSON CLI contracts hold?
2. Are the source-pinned red/base/repaired controls meaningful and nonempty?
   Base outer-cap cleans the same-group command; pre-repair PR orphans it; repaired
   controls remove it. Direct TERM orphaning is inherited, now also repaired.
   Eight repaired controls cover both CLIs, TERM/INT, outer-cap and direct TERM
   against a resistant command. No SIGKILL or deliberate session-escape guarantee.
3. Does the whole PR still satisfy F1–F9/K1 without unjustified changes to existing
   caller result shapes, ATE record consumers or selector precedence? Check original
   evidence rather than assuming historical approvals establish it.
4. Is nonblocking S1 correctly dispositioned to PARKED, with no false repair claim?
   Concurrent idempotence cancellation remains bounded by worker timeouts, as Fable
   allowed; do not silently extend this into a new thread-cancellation contract.
5. Do governance and ledger statements distinguish current readiness from earlier
   checkpoints? The disjoint merge replayed only949/912 using the existing writer;
   both owned rows were explicitly readmitted and retain their original ratings.
   Final full gate runs once after your valid approval, in a separate full clone.

Focused suites: domain17/0, metamorphic8/0, process guard43/0. Codex shim preflight
43/0 in a separate verification clone; raw log will ride with final receipts.
Read `TESTS-RESULTS/2026-10-04+GH-949/` source identities, results and provenance.
Older full870s gate is historical; do not reuse it as new implementation evidence.

Graph handoff: Verify tier; nearest primary project
`Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation2026-10-05T04:59:22Z.
Primary graph is development, not this unmerged PR. Search proc_group exhausted
7 results; one-hop run_bounded traces show ATE/fuzz/Claude/reconcile callers.
Coverage reported primary metadata_match for proc_group/domain/metamorphic/ATE
and runaway guard, missing canonical GH949 plan. Direct PR-source reads override
that graph. Ledger helper discovery15 results exhausted; coverage metadata_match;
exact clone source was read before use. No exhaustive graph claim is supplied.
If graph tools are unavailable, use exact source and do not claim MCP access.

Reviewer writes ONLY the relay thread; ALLOW_PATHS is empty. Do not run suites,
pytest, validate, installs, executable fixtures or mutating Git commands inside
the relay worktree. Narrow read-only/in-memory probes may use `.relay-scratch`.
Source claims need file:line; every behavior finding needs Observed input,
Affected scope, Falsifier. Declare swept file yes/no. Append one substantive
review block, preserve all prior bytes except header NEXT/STATUS/ROUND, set
PASS/FAIL with honest limits, and hand off. The harness commits; do not commit
or push yourself. Three-round review budget; no merge authority.
