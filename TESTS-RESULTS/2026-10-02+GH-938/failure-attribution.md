# Full-gate failure attribution — head 204750c5 vs base 5212dae4 (same Linux box)

Head lines come from the gate's serial re-run (`validate-full.log`, which keeps only the last 40 lines
per failed suite); where that tail did not show the failing assertions, the suite was re-run alone on
head and logged under `head-204750c5/`. Base lines come from `base-5212dae4/base-<suite>.log`.
Temp-dir and ULID path segments are ignored in the comparison.

| Suite | Head (204750c5) decisive failure | Base (5212dae4) | Match |
|---|---|---|---|
| gh610-claude-subscription | `FAIL: test_real_probe_and_consult_dispatch` | same test fails | same |
| gh399-packet-acceptance-continuation | `FAIL: C4 no relay file produced (marathon-drive rc=1)` | same | same |
| gh390-timeout-attribution | `FAIL: idle: BAD timeout-unclassified :: ... one-shot network probe failed` | same | same |
| gh492-idle-kill | `FAIL: expected timeout-idle-unknown for the blocked turn, got timeout-unclassified` | same | same |
| gh505-relay-attest | `FAIL: N3: candidate binding wrong for a relay beside source` | same | same |
| gh402-board-sync | `29 passed, 5 failed`; `FAIL-` lines (head-204750c5/head-gh402-board-sync.log) | `29 passed, 5 failed`; identical `FAIL-` lines (diff empty) | same |
| gh544-pre-push-gate | `FAIL: criss-cross fixture is degenerate: fewer than two best common ancestors` | same | same |
| swarm-preflight | `98 passed, 2 failed`; T37c/T38 stale-lock (head-204750c5/head-swarm-preflight.log) | `98 passed, 2 failed`; identical `FAIL:` lines (diff empty) | same |
| gh123-lock-progress-bound | 3 `FAIL:` lines (moving queue exited 75 after 2s; acquired within bound; writer wrote no file) | same 3 | same (timing-sensitive) |
| gh280-jog-marathon-adapter | `FAIL: H2 unexpected vendored row state: ... containment-violation ... (exit 6)` | same (tmp/ULID path differs) | same |
| gh436-merge-cleanup | `FAILED (failures=18, skipped=6)` (head-204750c5/head-gh436-merge-cleanup.log) | `FAILED (failures=18, skipped=6)`; identical `FAIL:` test list (diff empty) | same |

Conclusion: every full-gate failure reproduces on the base commit with the same failing assertions,
so none is attributable to this one-section markdown diff.
