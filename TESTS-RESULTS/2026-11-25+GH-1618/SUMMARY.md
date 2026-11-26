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
| NO-FAULT-TEST | No test under `test/` references `gate_toolchain_fault_reason`: the GH-1606 fault ordering is covered by its manual driver, not a gated test |

## Limits (stated, not hidden)

- The reserve probe covers one test on the healthy path; the other gated phase B/C tests were not
  individually checked for the reserve call.
- The probe ran at `086b657ea`, where the shared fixture also stubs the wiring check (PR #1617). The
  statement about the gate at the GH-1606 base rests on `gh436:43` being a module-level stub, the
  GH-1606 AC-5 run (`gh436` 227 tests OK), and the GH-1615 base receipts; it was not re-run at
  `b479f74e0`.
- The count 227 is a collection count; pass/fail of the full gated run is the existing GH-1606 AC-5 and
  GH-1615 evidence, not re-run here.
