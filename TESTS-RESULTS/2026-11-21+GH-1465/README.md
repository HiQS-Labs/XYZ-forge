# GH-1465 bounded gate output capture (run-2 follow-up)

Three defects were found by independent QA in `08fee5d0f` (`131a8a31d`'s tail reader): the post-exit
`reader.join` had no deadline (wall-timeout escape), the unconditional 64 KiB tail hid differing output
prefixes from `metamorphic_oracle.check_idempotence`, and timeout cleanup discarded diagnostics.

`utils/py/proc_group.py:run_bounded` now keeps one reader per stream under one deadline that covers the
launcher wait and the drain; complete output is the default; `capture_tail_bytes` is opt-in (only the
reviewer gate in `relay_drive.py`). Plan and QA dispositions: `PROJECT/2-WORKING/GH-1465-DRIVER-RUN-REVIEWER-GATE.md`.

Manual controls (no new suite, GH-831): `python3 bounded-capture-controls.py <source-root> <label>` prints JSON per case.
Run it against a root that holds `utils/py/` (`git archive <sha> utils/py | tar -x -C <root>`); needs `ps`, so run it outside a
sandbox that blocks process listing.

| File | Source | Result |
|---|---|---|
| `approved-base-communicate.json` | `6c3dc3aa2` | defect cases 1,2,3,6 behave; new-API cases 5,7,14,15 unsupported |
| `red-08fee5d0f.json` | `08fee5d0f` | RED: 1,2,3,4,6,12 fail; 5,7,14,15 unsupported (API absent, not a reproduced defect) |
| `green-fa17a34b8.json` | repaired head | GREEN: all 15 cases |
| `manual-review-controls-green.json` | repaired head | retained RSS/attestation controls |
| `driver-smoke.out` | repaired head | driver main path and adjacent paths |

`provenance.jsonl` binds each output and the control script by SHA-256. Cases 1,2: a `sleep` holder keeps the pipe past
the cap; 3: the real `check_idempotence` on output with a differing prefix and identical >64 KiB suffix; 6: both pre-timeout
sentinels survive; 12: multibyte output across read boundaries; 13: cancellation leaves no live group; 14: an injected
reader `OSError` is raised; 15: a `setsid` descendant keeps the pipes past `grace + 5` (bounded return,
`capture_complete=False`, text and digest unchanged after later output).
