# GH1387 bounded setup/repair trial

Runtime candidate: `0ae5e01c3`; baseline: `1c2bd89eb7e4176f8333d338a74d2113bb581a32`.

Real driver replay uses the existing GH491 satisfied-lane fixture and real Tick/attestation, with a deterministic relay stub that must remain uncalled. It reconstructs the exact GH1254 two-line input from the committed gate-start.json and verifies SHA256 `d2565905a3f76fb1f98294f476b29515b3a671d28e6e27ac75c4f8924cd6aff2` before asserting retention.

Baseline RED: success exit 0, live file absent, zero archives, receipt count null. Candidate GREEN: success exit 0, live file absent, one exact-byte archive, receipt count 2, zero builder/relay dispatch. Failed gate exit 5 retains live bytes; post-approve exit 9 retains archived bytes; archive creation failure exit 2 is visible and retains live bytes. Existing reset boundary unchanged.

Adjacent controls: 14/14 across both actual nested reset/gate implementations extracted via AST. Nested counted reset no-op; exact-byte archival; repeated no-live reset creates no archive; first new fire counts one; failed fresh executions accumulate and third parks at cap two; second success preserves first archive; injected rename failure retains live bytes. These are function-level controls, not a standalone Relay end-to-end claim.

Manual commands are retained as `manual-replay.txt` and `adjacent-replay.txt`; they are evidence, not registered suites. Execute only in disposable storage. Manual fixtures and verification clone are preserved. Focused suites: GH491 passed; GH280 running at this checkpoint. Full gate and final independent QA still pending.

Initial `/usr/bin/python3` lacks requests; selected existing `~/.cache/gh805-test-venv/bin/python3`, verified imports requests/yaml/pytest. No packages installed. Focused clone identity snapshot was captured during the focused run, not before; a strict bracket is required for the full gate. No primary working-tree/index/config/hooks/peer-ref changes. Normal task-branch object writes explicitly authorized by parent.

Budget begins 2026-11-08T23:44:07Z, ends 2026-11-09T01:44:07Z. Builder attempt 1/2, runtime repair rounds 0; one fixture setup command had a shell glob error, corrected without mutation. Parent interventions: gate-slot coordination and clarification of permitted task-branch Git metadata writes. Tokens unknown. Agent-assisted; no unattended qualification, merge or cleanup.

Edit verdicts: archive helper helped (baseline loss vs retained exact bytes); gate-only count capture helped (null vs 2); shared caller change helped in function controls. NO_ENTRY for lessons: this bounded replay does not justify a broader operating lesson.
