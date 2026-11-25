# GH-1606 — verification summary (manual checks; no new tests, GH-831)

Change: before reserving a B1 repair slot, `merge_cleanup.py` probes the clone's own
`validate.sh --print-mode`; a blocking toolchain fault defers the PR (exit 3, fault named, no slot
spent) and the dry run warns first. Base `b479f74e0`; candidate `cabf9c530`.

Evidence is `provenance.jsonl` (one row per check); the driver is `run_controls.py`
(`run_controls.py --base-repo <clone at base> --candidate-repo <task clone> --out <dir>`). It is a
one-off manual driver, not a suite, and is registered nowhere.

## Controls (BASE vs CANDIDATE, identical inputs, separate processes)

| Row | Result |
|---|---|
| AC-1-base / -fault / -healthy | Real `validate.sh`: helper absent at base; returns the `ENVIRONMENT FAULT` line under system `python3`; returns `''` under the test venv |
| AC-2-base-red | BASE reproduces the incident: exit 2, B1 entered (7 `B1:` lines), 1 slot spent, push called once, fault never named |
| AC-2-cand-green | CANDIDATE: exit 3, fault named, `DEFERRED` named, B1 routed to but not entered (0 `B1:` lines), attempt record `absent`, 0 pushes, origin branch SHA unchanged, PR still OPEN |
| AC-2-mutant-red | Same probe placed AFTER `reserve`: exit 3 and fault named, but `attempts == 1` — the central check rejects it (separates the origin fix from a symptom fix) |
| AC-3 S3 / S5 | Healthy and consumer-shape (no `validate.sh`): BASE == CANDIDATE; real `push_resolved_head`; published head (captured immediately after the push) equals the recorded repair commit; PR MERGED; attempts == 1 |
| AC-3 S4 | Fault run defers (exit 3, record absent); `--resume` with the toolchain fixed lands with exactly one slot |
| AC-3 S7 | `--resume` at the 2-repair ceiling stays parked under a fault on BASE and CANDIDATE; record unchanged; no push |
| AC-4 | CANDIDATE dry run warns under a fault, silent when healthy, no attempt record; BASE emits no warning |
| SMOKE-main / -adjacent | Real `validate.sh`, real `preflight_warnings`: warning under system python (0.2 s probe), none under the venv, none for a consumer shape or the legacy no-argument call |
| AC-5 | Gated suites on the candidate in a disposable clone: `gh436` 227 tests OK, `gh645` 8 OK, `gh674` 6 OK |

## Notes and limits (stated, not hidden)

- The fixture seams are declared: `githooks/install.sh` and a `validate.sh` shim that answers
  `--print-mode` only. The real `validate.sh` behaviour is witnessed by AC-1 and the smoke rows.
- A first attempt to build the ordering mutant aborted on a bad sanity assertion in my own mutation
  script and ran the UNMODIFIED candidate. That result was discarded as a harness error and the
  mutant was rebuilt and verified (22 differing lines; probe after `reserve`) before the row above.
- Conservative deferral is unmeasured on a real docs-route push (plan, *Risks*): the probe can defer a
  repair whose hook route would have skipped `validate.sh`; cost is exit 3 and a named fix, no slot.
- `test/gh534_phase_b_tests.py` is red at the clean base (39 tests, 14 failures, 1 error) and ungated;
  not caused by this change and not fixed here. Only its fixture class is reused.
- Not run: the final repository gate for the pushed commit (Step 9) and the final independent review.
