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

Final QA round1 found the legacy relay bypass of the interim publication checkpoint. At `9ec177d5`, the shared entry refuses both real executors before lease/lock/cache writes. The recorded AST control witnesses the prior relay lease reach at `35ad8fda`, fixed refusal, and preserved simulation/dry-run. No PR or ledger mutation is performed by the control.

Final QA round2 found the separate legacy interactive merge route and inherited target-lock bypass. At `bea9d480`, real legacy supervisor execution parks at the common primary publication checkpoint, and its target acquires its own lock. Red/green seeded-function controls plus the actual existing driver in a separate full clone prove live-holder refusal, stale-lock reclaim, absent-lock acquisition and cleanup. Native exact-head and attestation helpers remain intact. Both executors share the root environment helper and target-ledger byte invariant.

The in-flight full gate at `9ec177d5` exposed a new SQLite connection in the merge-cleanup hook (inventory ratchet). The hook now reads the qualified canonical dump through B1's existing parser; Jog's committed-landing reader uses the existing releases gateway with a read-only option. Recorded controls witness the old ratchet failure and current clean inventory, and verify a URI-special filesystem path opens read-only and refuses mutation. The end-to-end one-writer manual controls were repeated against `bea9d480`, including the actual mapped hook/publication, and pass. Full final-source qualification remains pending.

Requested Claude Code Opus5.5 high independent QA round1 ran and found three Should-level merge-cleanup issues. At `03fb2fd9`, recovery `--reconcile-pr --execute` uses the existing final publisher; terminal rows no longer map unrelated follow-ups; and capability comes from beside the exact releases CLI selected for execution. The retained manual control observes old recovery exit0 with dirty writes, then fixed recovery clean at origin with actual queue completion. It also witnesses old terminal follow-ups calling/refusing land and fixed skipping, and a harness-resident skill invoking an old consumer writer under the old check versus fixed refusal. Git, releases check, committed landing and final publication are real in a disposable primary; only fixture GH and the unrelated issue-doc-sync probe are stubbed. All controls pass. Actionable mapped rows still require valid evidence and refuse if missing, per operator requirement5; the review's broader suggestion to silently skip those is declined. Round1 model receipt retained; second independent review pending.

## Blocked final review checkpoint

Final Codex round3 is Escalated at the binding3-round cap. It observed a real mismatch: B1's conservative line-based dump classifier omits a valid actionable Jog row when a failure_reason contains a newline, while the canonical emitter/parser retains it. The hook must reuse the canonical root-bound Jog JSON reader (or canonical multiline parser); missing approval must still refuse, not become an empty queue. This concrete fix is NOT applied yet because exhausted review caps stop implementation under start-task. Operator continuation for one additional Codex round was requested. No PR has been published; machine primary remains untouched.

Opus5.5 high round2 accepts the3 earlier runtime dispositions and finds one existing gh436 fixture needs to mock/assert the newly required final publisher. Its model receipt and relay findings are retained. No third Opus verdict yet.

I started the broad gate before final approval. It is diagnostic evidence, not final qualification. At9ec177d5 it ended405/409 with unchanged clone identity. The4 real serial failures are gh777 inventory (already corrected by canonical reader/gateway reuse in newer source, except the multiline reader issue still pending), gh605-work-state (old fake .git fixture needs real primary identity), and gh290/gh291 landing fixture/golden assumptions (need pinned primary and committed receipt format). No failure was waived or called flaky. Canonical final-source full qualification has not run and cannot be claimed.

Next continuation: replace incomplete hook queue reader through existing canonical interface; truthfully adapt existing gh436, gh605, gh290 and gh291 fixtures without new suites; run focused red/green checks; obtain authorized final Codex continuation and remaining Opus round3; then exactly one required final approved-source push gate, machine-primary historical re-land and evidence, PR1 against development. PR2 remains dependent on PR1 landing or explicit stacked authorization. No merge authorized.
