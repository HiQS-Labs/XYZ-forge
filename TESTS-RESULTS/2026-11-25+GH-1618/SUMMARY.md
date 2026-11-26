# GH-1618 verification summary (manual checks; no new tests, GH-831)

Change: documentation only. Corrects the claim in the two merged GH-1606 documents that the
merge-cleanup phase B/C suite is "ungated" and that "no gated suite enters the B1 reserve path".

Evidence is `provenance.jsonl` (one row per check); the probe is `probe_gate_reserve.py`, a one-off
manual driver, not a suite, registered nowhere.

## Ground truth at base `086b657ea`

| Row | Result |
|---|---|
| COLLECTION | The gated entry point `test/gh436-merge-cleanup.py` (registered at `validate.sh:96`) imports phases A, B and C with `import *` (lines 1382-1384) and collects 227 tests, 39 of them phase B, 47 phase C |
| PROBE-RESERVE | A phase B end-to-end test, collected through `gh436`, was run once with call counters: `attempt_record.reserve` called once, the toolchain probe once, test OK |
| BASE-DIFF | Between the GH-1606 base `b479f74e0` and `086b657ea`, `gh436`, phase A and phase C are unchanged and phase B differs only by the 8-line PR #1617 stub, so the 227 / 39 collection and the module-level stub at `gh436:43` hold at both revisions |
| NO-FAULT-TEST | No test under `test/` names `gate_toolchain_fault_reason` (a direct-reference search). This does not establish that no gated test supplies a fault indirectly through `run_main()`; the fault ordering is demonstrated by the GH-1606 manual driver, and gated fault-ordering coverage was not established |

## Limits (stated, not hidden)

- The reserve probe covers one test on the healthy path; the other gated phase B/C tests were not
  individually checked for the reserve call.
- The probe ran at `086b657ea`, where the shared fixture also stubs the wiring check (PR #1617). The
  statement about the gate at the GH-1606 base rests on `gh436:43` being a module-level stub, BASE-DIFF
  (suite sources unchanged apart from that fixture stub), the GH-1606 AC-5 run (`gh436` 227 tests OK) and
  the GH-1615 base receipts; the gate itself was not re-run at `b479f74e0`.
- The count 227 is a collection count; pass/fail of the full gated run is the existing GH-1606 AC-5 and
  GH-1615 evidence, not re-run here.

## Acceptance on the edited documents

| Row | Result |
|---|---|
| AC-1 | Every remaining "ungated" / "no gated suite" / "never saw" / "referenced by" hit is a struck-through original, a correction note, or the untouched `provenance.jsonl` row; the same grep at `origin/development` finds the unqualified hits |
| AC-2 | 9 files changed: the two target files, the plan, this evidence, the relay thread, ledger pickup files; `provenance.jsonl` of GH-1606 is byte-identical |
| AC-3 | `39 tests`, `14 failures`, `GH-1576` present in both target files |
| AC-4 | `pdda.sh run`: no errors; `hardcoded-paths`: 0 errors |
