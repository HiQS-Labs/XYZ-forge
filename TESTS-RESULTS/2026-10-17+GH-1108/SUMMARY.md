# GH-1108 delivery 1 verification

Focused code revision: `7551ca55baf3f3ab7b00bb252105082a3a2518e0`. The subsequently reviewed implementation at `d91f22ab` adds older/plain consumer compatibility and the interim auto-merge checkpoint guard; those branches and the explicit-root correction pass `compat-and-root-manual.log.txt`. Required full push qualification and final independent QA are still pending at this checkpoint.

| Existing suite | Result |
|---|---|
| gh280 Jog/Marathon adapter | 223 pass, 0 fail |
| Jog CRUD/recovery | 34 pass, 0 fail |
| merge-cleanup | 180 tests, OK |
| vendored merge-cleanup tools | 8 tests, OK |

Runs used the separate disposable full gate clone. Its core.bare, origin, local user identity and HEAD stayed identical across the fixed-revision batch; both identity snapshots are retained. Compressed suite logs include expected negative-fixture messages; `OK`/final counts are the verdicts. No new suite, test file or registry entry was added. One-off manual scripts are retained as text records, never registered executables.

Manual controls pass: primary-only queue writes with a named-primary refusal; clone ledger byte invariance; explicit preflight/harness/target roots; receipt-push failure then resume without another builder; receipt-only lane delta; Phase-0 refusal before the documented manual publication checkpoint and readiness afterward; committed-receipt landing with no .tick cache; mapped post-merge hook and existing final publisher; replay without duplicate queue receipts; failed fetch, red hosted run and empty provenance refusing without queue mutation.

Merge proof controls pass: ledger-conflicted but source-clean upstream merge accepted after stripping; changed nonledger merge tree, nonledger conflict, unreachable upstream parent, missing/nonancestor approved object and source edit+revert with equal endpoint trees all refuse. `tail-proof-manual.log.txt` retains the negative results and required tree IDs. No manual override was used.

The actual original GH-1087/#1101 and GH-942/#1102 result and gate files were re-emitted byte-for-byte into committed portable bundles. `historical-land-manual.log.txt` lands both from a disposable primary using live GitHub PR truth and hosted success, with an intentionally foreign GH_REPO proving explicit origin binding. Original approval 6f521bc5 is preserved for #1102; its upstream merge recomputes to tree `121a33348db69fdd2bb30ff164c83c007c6206dc`, exactly the recorded stripped tree. Landing evidence includes hosted runs 38998203092 and 39000753405. Both replay without a new ledger transition. The operator's machine primary has not yet been changed by these checks.

Plain/older consumers retain non-Jog merge-cleanup behavior when the shared policy module is absent/old. Mapped Jog landing refuses an old harness before writes. Global --root selection now survives recovery/landing subparser defaults; a witnessed pre-fix exit 3 and post-fix successful foreign-CWD call are retained.

Delivery 2 owns automatic per-transition commit/push and bounded non-ff replay. Delivery 1 uses the explicit owned-state publication checkpoint and refuses native auto-merge before leasing; it does not introduce that push path.
