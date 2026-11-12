# GH1443 independent final QA
STATUS: Approved
NEXT: orchestrator

Review the committed implementation against PROJECT/2-WORKING/GH-1443-JOG-READINESS.md and TESTS-RESULTS/2026-11-12+GH-1443/SUMMARY.md. Read source utils/py/jog_run.py and diff against origin/development; skill explanation and two existing-suite call corrections. Read manual CLI/helper evidence, original false-ready baseline, focused results and provenance. This is final QA round1/3, separate from plan rounds. Write only this review thread; no source edits, suites, live network/provider or primary changes. Small read-only evidence verification is permitted; do not run mutation-heavy suites here.

Local CLI operational envelope, no new subsystem/schema/gate machinery. Target-aware readiness deliberately stricter, bare preview unchanged. No live capacity/environment certification. No merge/deploy/factory run authorized.

1. Do selected nonzero/unevaluated results force nonzero CLI without hiding later items? Is exact legacy-first promotion semantics preserved?
2. Are roles/checkpoint validation reused without altering live recovery ordering or state? Any actual queue/ledger/lock/journal mutation introduced in dry-run?
3. Are 16 actual CLI controlled cases and8 helper controls discriminating and honestly scoped (controlled preflight, not provider availability)? Do focused suites and revisions support main/adjacent paths? No new suite/registry entries.
4. Are scope, ratings65/55/50/65, remaining gaps and user preservation constraints truthful? First fixture/containment/focused failures retained. Is a final classified full qualification appropriate after approval?

Cite concrete source/input/falsifier for blockers; reject speculative architecture. Verdict Approved or ChangesRequested. Full gate is intentionally after this final approval; do not count its pending state as a source defect or claim it passed.

▶ TAKE YOUR TURN (codex)

## Codex final QA — round 1 — Approved

Ship within the stated local CLI scope; no blocking findings. This approves proceeding to classified full qualification in a disposable full clone, not merge, deployment or factory execution. That qualification remains pending.

Reviewed the working plan, summary, spikes, manual control sources/receipts, provenance, focused logs, Jog source and skill. Compared the four implementation/skill/existing-suite files against origin/development 43265eed2359f781f942543af74c6d12c990cf00 by reading Git object storage with Python (no Git command). The successful read-only Python/zlib/struct/difflib probe exited 0: only promotion extraction, publication/option check extraction, target-aware admission/exit aggregation, the scoped skill explanation and two bare-preview invocation corrections changed. Initial loose-object/ref-only probes exited 1 because the baseline objects/ref are packed; the pack-aware comparison superseded them. No product execution occurred in these probes.

1. `jog_run.py:2218` returns numeric failure for missing helper or inbox identity/probe rejection and propagates the subprocess status. At :2345 each selected item is evaluated before aggregation; :2351 exits 2 only after the loop and connection cleanup. Status 4 also refuses new-work readiness. The mixed control records both GH-99001 and GH-99002 then rc 2. Bare preview retains its role exemption and return behavior.
2. `promotion_probes` at :1677 exactly preserves the former valid-legacy-first list/filter and contract fallback only when no valid legacy probe remains. The real fallback and valid-legacy/invalid-contract helper controls discriminate that selection. No duplicate contract command execution was added.
3. Static executor validation reuses the existing route/binary owner. `JogCheckpoint.check_publication` remains at the same live finish position after committed-state save; begin/recovery ordering is unchanged. Shared checkpoint option checks remain before lock acquisition. The dry-run branch opens SQLite mode=ro and returns before primary pinning, supervisor lock, recovery, journal begin/save/finish or queue writes. Target preflight side effects are explicitly disclosed rather than presented as globally read-only.
4. Actual CLI receipts support 16/16 controlled cases versus baseline 3/16, with unchanged ledger bytes/no Jog state. Eight helper controls cover real fallback, missing helper, mixed queue, preview and ambient-state preservation. These are controlled preflight/inert executable checks, not provider availability evidence. Existing focused receipts report 227 pass/0 fail and 34 passed/0 failed; the two changed calls remove helper-injected target arguments so their bare-preview assertions remain truthful. No new suite/registry/gate machinery appears in the reviewed changes.

Evidence verification: read-only `python3` using `json.loads`, `hashlib.sha256` and `Path.read_bytes` over the latest artifact mapping in `TESTS-RESULTS/2026-11-12+GH-1443/provenance.jsonl` exited 0; all 17 latest artifact hashes MATCH. Parsing `cli-baseline.json` and `cli-fixed.json` printed respectively `3 16 True` and `16 16 True` (passed, total, all_preserved). Reading final log tails showed `gh280-jog-marathon-adapter: 227 pass, 0 fail` and `34 passed, 0 failed`. No suites, pytest or executable fixtures were run in this reviewer worktree; clone execution is producer evidence, not an independently repeated run.

Ratings 65/55/50/65 remain explicitly provisional, with trend unknown and no established corruption/loss claim. Scope and remaining environment/provider/freshness/recovery/deadline/useful-delivery gaps are honest. First malformed fixture, containment and focused failures are retained and hashed. Preservation constraints are respected; no cleanup or source changes performed. Full classified qualification after this approval is appropriate and must attest the final committed state before readiness is claimed.
