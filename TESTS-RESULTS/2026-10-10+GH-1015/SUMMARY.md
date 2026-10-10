# GH-1015 observer path verification

Base `9a923f3c`; candidate source `4ddc2ab4`. Independent plan QA Approved in the committed relay with attestation. Independent final QA Approved (b59b42ee); source bytes match approved-source-hashes.json. Full qualifying gate remains pending.

The retained `manual-replay.py` is a one-off manual evidence replay, outside the suite/registry. Run with `python3 TESTS-RESULTS/2026-10-10+GH-1015/manual-replay.py relay-automation/marathon.sh --expect-fixed` from a disposable full clone (create its ignored temp directory first). It extracts the exact embedded Python and exercises init/phase/finish/emit/finite observe with synthetic receipts and a controlled clock. No provider, worker, paid call, or live marathon was invoked. Fixture paths in raw evidence are ephemeral; the replay reconstructs its own fixtures.

| Check | Base | Candidate |
|---|---|---|
| Physical path verified | 1 | 1 |
| Absolute / relative symlink path verified | 0 / 0 | 1 / 1 |
| Foreign execution/token/schema/phase/lane/target | All 0 | All 0 |
| Non-green gate / missing reviewed head | 0 / 0 | 0 / 0 |
| Missed-check / check / observation-ended sorted keys | false / true / true | true / true / true |

Sensitivity controls: the acceptance assertion exits 1 on base; restoring old init in an owned source copy exits 1; independently restoring unsorted missed-check output exits 1. Nonempty raw results retained. Candidate exits 0. Source and artifact hashes are in the raw results and focused-artifact-hashes.json.

Existing checks: codex-turn 43/43 on base; GH-609 33/33 and package freshness 3/3 on candidate; Bash syntax clean. Separate full-clone Git identity brackets (HEAD, origin, bare flag, local email) match before/after. The relay package has 18 members and excludes marathon.sh, so it remains unchanged. Qualification/schema/executor predicates are unchanged; this is observation-fidelity verification, not a new delivered product milestone or proof of Flightdeck/live provider integration.
