---
Goal: Final implementation QA — GH-534 merge-cleanup failure modes, Phases A+B+C (PR #538)
Date: 2026-09-10
Producer: claude-a
Reviewer: codex
NEXT: codex
STATUS: Open
Round-cap: 3
---

# Context

The plan `PROJECT/1-INBOX/GH-534-MERGE-CLEANUP-FAILURE-MODES.md` (rev 5, Approved through
`relay-system/2026-09-09/gh534-plan-qa-codex-r4-bounded.md` + operator adjudication) is now
implemented on branch `fix/merge-cleanup-failure-modes` at **aa40c0a4** (draft PR #538). Full gate
GREEN in a disposable clone for each of the three phase commits (43db7ec4, 80fd37cb, aa40c0a4).
This is a **review turn**: report, do not edit anything but this file.

Read, in this order:

1. The plan — sections *Phase A*, *Phase B1*, *E / E.6*, *Phase C*, *Acceptance check*.
2. `skills/merge-cleanup/scripts/scan_clones.py` — A.1–A.5 (`DEFAULT_SAFE_ROOTS`,
   `classify_local_refs`, `inspect_tick_claims`, `inspect_open_handles`, `inspect_checkout`).
3. `skills/merge-cleanup/scripts/ledger_merge.py` — B1 + E.6 (`classify`, `replay_ops`,
   `resolve_ledger_conflict`, `pre_merge_ledger_gate`).
4. `skills/merge-cleanup/scripts/attempt_record.py` — Phase C record, `RecordLock`, CLI.
5. `skills/merge-cleanup/scripts/merge_cleanup.py` — `land_prs` (E, E.6, B1 dispatch, C
   reserve/park/dependents), `refresh_for_teardown`, `teardown_checkout`.
6. `skills/merge-cleanup/scripts/toposort_prs.py` — `_deps` kept for Phase 5.
7. `bin/tick` `claims` verb + `decisions/2026-09-09-tick-claims-verb.md`.
8. `skills/merge-cleanup/SKILL.md` — Phases 1–6, caller ladder, capability table.
9. Tests: `test/gh534_phase_a_tests.py`, `test/gh534_phase_b_tests.py`,
   `test/gh534_phase_c_tests.py` (collected by `test/gh436-merge-cleanup.py`, registered via
   `test/gh436-merge-cleanup.sh` in `validate.sh`). 126 tests.
10. Red-control evidence: `TESTS-RESULTS/2026-09-09+GH-534/`,
    `TESTS-RESULTS/2026-09-10+GH-534-phase-b/`, `TESTS-RESULTS/2026-09-10+GH-534-phase-c/`
    (each `provenance.jsonl` names control, mutated file, pinning test, red/green exit).

# Questions

Answer every one with `file:line` citations. A textual review does not replace the tests; where
you dispute a test, say what input would make it pass wrongly.

1. **Is each acceptance item satisfied by actual code paths?** Walk the plan's *Acceptance
   check* (A.1–A.5, E, E.6, B1, C, Parity guard, Gate) and for each say satisfied / partial /
   missing, naming the function and the test that pins it. Name any acceptance bullet that has
   no pinning test or whose red control mutates something other than the guard it claims.

2. **Fail-closed audit.** Find any path in `scan_clones.inspect_checkout`,
   `inspect_tick_claims`, `inspect_open_handles`, `classify_local_refs`, or
   `merge_cleanup.refresh_for_teardown` where a query failure, empty output, or parse error is
   defaulted to "none / idle / landed" instead of `PRESERVE_*`. Cite lines.

3. **B1 safety.** Can `ledger_merge.classify` report `disjoint` for two sides that are not
   semantically disjoint (same key under different table parsers, a `settings`/generation
   change, a delete masked as an update, a cross-table reference the FK check misses)? Can
   `resolve_ledger_conflict` push anything without the second-clone validation and the
   remote-head equality check? Does `replay_ops` ever bypass the writer (`releases_app.py`)?

4. **Phase C accounting.** Is the record truly pinned to `--primary` everywhere the script and
   the CLI resolve it (no `Path.cwd()` fallback)? Is `RecordLock` held across the whole
   read → count → reserve → write? Does a lock timeout count, skip, or stop? Does any code path
   mint a fresh budget on a new head or a fresh clone? Are dependents of a parked/handed-off PR
   refused via `_deps` for both explicit and file-collision edges, and do independents proceed?

5. **Duplicate subsystem / writer check.** Did any parallel write path slip in for the ledger
   (raw SQL, direct `releases.sql` edits), for tick state (anything but `readAllEvents`+`fold`),
   or for the record (a second store)? Is `attempt_record.py` the only writer of the record?

6. **Rating.** The row is `rated 75/70/50/30` (calc 225). Given the implemented scope and
   evidence, is the persisted rating still grounded? Appeal stays at the neutral 50 (no
   operator value given).

Mark each question **Closed** or **Blocking** with the disputed code cited. Set
`STATUS: Approved` only if none is Blocking; otherwise leave `STATUS: Open`, set
`NEXT: claude-a`, and list every Blocking item as a numbered finding with the smallest fix you
would accept.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log
