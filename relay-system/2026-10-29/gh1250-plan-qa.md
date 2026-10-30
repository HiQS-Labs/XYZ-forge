---
Goal: Plan QA — marathon #1250 (GH-1175 Phase 0 follow-ups), four lane plans
Date: 2026-10-29
NEXT: codex
STATUS: Approved
---

# Context

Independent plan QA for marathon umbrella https://github.com/HiQS-Labs/XYZ-forge/issues/1250 before any build. Base `93f41cb8` (development). Each lane has its own issue with an `## Acceptance` checklist, copied verbatim into its doc. Direct `swarm-preflight --dry-run` currently reports READY (exit 0) for all four.

| Lane | Issue | Plan doc | Write-set |
|---|---|---|---|
| L1 | #1233 | `PROJECT/2-WORKING/GH-1233-JOG-RECOVERY-AFTER-DRIVER.md` | `skills/2-daily/jog/SKILL.md` (docs) |
| L2 | #1235 | `PROJECT/2-WORKING/GH-1235-MERGE-CLEANUP-JOG-LAND.md` | `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` |
| L3 | #1236 | `PROJECT/2-WORKING/GH-1236-JOG-MARATHON-LANE-RUNS.md` | `githooks/pre-push`, `utils/py/gate_receipt.py`, `utils/py/marathon_drive.py` |
| L4 | #1251 (slice 1 of #522) | `PROJECT/2-WORKING/GH-1251-GH-522-SLICE-1.md` | `utils/py/_marathon_plan.py` (+ existing planner tests only where they pin old behaviour) |

Operational envelope: four small, independent fixes. Grade each against its own issue's acceptance and commensurate complexity. Do not ask for new tests (AGENTS.md *No new tests*, GH-831), new suites, schemas, daemons or machinery. #522's larger program (model spike, monitor, automatic membership) is explicitly out of scope; #1251 is only its deterministic rung-2 slice.

Read each plan doc in full, plus the code each cites:
- L2: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:797-990`, its callers `:1615-1640` and `:1930-1945`, and the suites that mock `run_post_merge_reconcile` (`test/gh534_phase_a_tests.py:584`, `test/gh534_phase_b_tests.py:560,574`, `test/gh436-merge-cleanup.py:360,457`, `test/gh549-work-events.sh:620-640`).
- L3: `githooks/pre-push:58-80` and `:255-318`; `utils/py/gate_receipt.py`; `validate.sh:1575-1595`; `utils/py/marathon_drive.py:2810-2835`; `relay-automation/marathon-closeout.sh:149-190`.
- L4: `utils/py/_marathon_plan.py:1015-1205`, `test/marathon-plan.sh` (scenarios G and T).
- L1: `skills/2-daily/jog/SKILL.md:178-189`.

Questions:
1. Per lane: is the recon right, is the change the smallest that meets every acceptance item, and is anything missing or over-scoped? Cite file:line.
2. L2: does committing inside `run_post_merge_reconcile` on a Jog refusal (via the existing `commit_and_push_phase5_writes`) keep every current failure path stopping before the commit? Is any caller or suite broken by it?
3. L3: is reuse limited to the exact pushed SHA, a `validate.sh` full-gate receipt, and the full-gate arm only? Can any path weaken today's gate, for example through a stale receipt, a receipt from another tree, a docs/tier-2 route, or a marathon receipt? Is "marathon writes only when no receipt exists" sound?
4. L4: are the three fail-closed changes correct, and is the cycle case really what reaches the no-progress fallback? Is the Phase 0 grep plus the GH-698 parity precedent the right handling for existing fixtures?
5. Waves: are the four write-sets disjoint (including generated files and shared ledgers)? Can all four lanes run in one wave? L3 touches `utils/py/marathon_drive.py` and L4 touches `utils/py/_marathon_plan.py`; check that no lane edits a file another lane's gate or runtime depends on mid-wave in a way that matters.
6. Ratings (#1233 45/40/50/92, #1235 60/60/50/75, #1236 50/35/50/70, #1251 55/50/50/75): are they grounded?

Use `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]` per lane, citing file:line. End your final block with exactly `VERDICT: PASS` (or `FAIL`) on its own line, followed by a non-empty `Basis:` line (GH-533). Set STATUS to Approved on PASS.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log

### Codex — plan QA, 2026-10-29

Return for revision. L2's control-flow change is sound; L3's receipt assumptions are not yet sufficient to preserve the gate. This is plan review, not implementation approval. Reversibility: L1 is Easy; L2–L4 affect landing/gate/admission decisions and deserve Costly treatment until their focused clone checks establish the boundary. The proposed revert paths are appropriate, but a revert cannot retroactively validate an already-pushed commit.

- **L1 [Pass] scoped approach; [Should] make preservation checks concrete.** The Recovery Verbs at `skills/2-daily/jog/SKILL.md:178` omit leftovers, so a local documentation addition is the smallest remedy. However, `PROJECT/2-WORKING/GH-1233-JOG-RECOVERY-AFTER-DRIVER.md:43-48` must distinguish “no process owns this path” from “no unique work remains.” A listed worktree with no live process can still contain unpublished edits; an unpushed branch is evidence to preserve, not evidence that removal is safe. Direct readers to merge-cleanup's dirty/unpublished/dependent-worktree checks before clearing anything. `tick info` identifies an agent, not necessarily a process PID; name how the actual owning execution is established, and preserve on uncertainty. Keep the fresh-clone and resume/retry-gate/retry-build ordering. No runtime expansion needed.

- **L2 [Pass] proposed durability branch and unchanged callers.** `merge_cleanup.py:900-951` returns early for an unknown merged head, active hosted timeout, failed fetch or fast-forward; reconcile/check/pdda failures keep `ok=False`. An explicit `if not ok: return False` before the Jog hook therefore preserves those stops. Calling the existing durability writer only after that boundary and a false hook result is the smallest change. Its checks at `:954-990` already require commit/push/fetch success and clean local/origin equality. Returning False after either durability success or failure stops both callers at `:1622` and `:1935`; it does not run the caller's second commit or continue to another PR. Bool mocks in gh534 phase A/B and gh436 remain compatible; gh549's AST ordering assertion (`test/gh549-work-events.sh:627-640`) examines the outer loop and remains structurally satisfied.
  **[Should] report the actual hook failure, not a fictitious single parked row.** `run_jog_post_merge_land:805-875` can return False on queue/PR/capability failures before invoking land, and its loop can land one mapped row before a later row refuses. The proposed fixed message at the L2 plan's step 4 overstates those cases. Preserve the existing specific diagnostic and say reconciliation writes were made durable but Jog completion failed; leave row states as they actually are. This does not require a new result type. The requested smoke must also demonstrate false return/nonzero caller exit and no commit on check/pdda failure, not merely a clean repository.

- **L3 [Blocker] `gate == validate.sh` does not prove an unfiltered full run.** The recon at `PROJECT/2-WORKING/GH-1236-JOG-MARATHON-LANE-RUNS.md:39` misses `validate.sh:1182-1204`: `--skip` removes suites without changing tier or subsystem. At `:1575-1594` the producer announces omissions but still writes the same successful `validate.sh` receipt. A clean tier-3 run with a failing suite skipped can therefore suppress the next ordinary full pre-push run under the proposed check. Fix the existing producer and consumer together, in this lane, and fail closed on old receipts that cannot establish the stronger eligibility condition. Do not infer completeness from passed==total: the skipped suite has already been removed from the run list. This requires revising the current “do not change validate.sh” non-goal/write-set, not adding a new gate. Also distinguish Marathon provenance: `marathon_drive.py:2825` uses the arbitrary pre-advance command as `gate`, so a command literally named `validate.sh` with mode `marathon` must not masquerade as a producer receipt.

- **L3 [Blocker] existence-only preservation regresses closeout recovery.** Plan step 2 (`GH-1236…md:48`) preserves corrupt, failed, or wrong-SHA JSON forever. `gate_receipt.py:62-75` rejects those files, and `marathon-closeout.sh:149-160` stops before the push. Previously a successful pre-advance run replaced that invalid receipt. Preserve a validated eligible full-gate receipt; otherwise allow the successful Marathon receipt to replace invalid/stale data. Add the corrupt/failed pre-existing-file cases to the already planned manual smoke, alongside valid-receipt preservation.

- **L3 [Should] state the empty-input and fallback rules explicitly.** Require at least one non-delete `_real_ref_pairs` entry before “all receipts pass”; empty stdin deliberately gates today (`githooks/pre-push:58-80`). Apply the gate/provenance restriction to the legacy `.gate-evidence` fallback too (`gate_receipt.py:77-84`). Keep docs and tier-2 routes before reuse, require every pushed SHA, and let missing tools or malformed receipts fall through. Exact SHA prevents different-tree reuse under the existing local-receipt trust model; another SHA must fail. Age alone does not invalidate immutable commit evidence, but old weaker-producer receipts do. No new authentication subsystem or arbitrary expiration policy is needed.

- **L4 [Pass] three algorithmic changes; [Should] correct the rendering recon.** Unknown exit handling, missing-dependency propagation, and replacing the no-progress fallback are localized to the right owner. A two-node ready cycle really reaches that fallback: resolution permits ready dependencies (`_marathon_plan.py:1061`), but neither dependency is in `placed_issue` at packing (`:1145-1151`). Ordinary positive zone caps and write collisions alone do not prevent the first lane entering an empty wave; a zero cap can. Do not describe ordinary collisions as the demonstrated trigger.
  Rendering is not entirely generic: `:1425-1444` has explicit held-state buckets missing both new names. Add them to an existing bucket. Recompute/filter `active` after holding unplaceable items: it was captured at `:1131`, and summaries and the scoring table still iterate it (`:1262-1274`, `:1373`). Otherwise a cycle is reported both active and held. Keep existing exit-code precedence for mixed drift/held reports explicit; exit 5 is the isolated held-case expectation.
  Scenario G tests a present-but-held dependency (`test/marathon-plan.sh:234`), not a missing row. Scenario T has neither a dependency cycle nor deep delegation (`:629-685`), so these fixes should not change its dry-run parity. The GH-698 skip is specifically rendered-table divergence (`:688-697`); do not broaden it to hide an unrelated dry-run failure. Phase 0 fixture inspection and narrowly updating assertions that truly pin changed behavior is appropriate.

- **Wave [Should] enumerate the complete write allowances before dispatch.** The four source write-sets are disjoint, including L4's named existing planner suites and the needed L3 producer amendment. L2–L4's issue-specific `TESTS-RESULTS/<date>+GH-N/` bundles and L4's Phase 0 plan-doc update are additional writes promised by the plans but absent from the headline source-only sets. Include those explicitly; keep shared CHANGELOG/ledger/generated marathon-plan updates owned by the orchestrator. One wave is reasonable in isolated lane checkouts with disposable full-clone gates and a pinned supervisor runtime. L3 and L4 share no changed API; `marathon_drive.py` does not import the planner implementation. Do not run parallel mutation-heavy gates in the common working tree or adopt L3's live hook/driver edits into a running supervisor. No new contract framework is warranted for these independent changes.

- **Ratings [Pass as estimates, not measured scores].** The relative priorities match the cited consequences: L2 blocks subsequent landings, L4 admits invalid work, L3 wastes a measured second gate, and L1 repairs guidance. The high ease score for the documentation-only lane is reasonable; L3's 70 should be reconsidered after producer compatibility is included. Exact numbers and the common appeal score of 50 are judgment calls, not independently proven measurements. No rerating is needed merely for numerical precision.

Evidence: read-only source inspection, no git commands, suites, pytest, or executable fixtures. The following non-mutating Python text probe exited 0; the nonempty extraction assertion guards the scan:

```python
from pathlib import Path
v = Path('validate.sh').read_text()
p = Path('utils/py/_marathon_plan.py').read_text()
producer = v[v.index('if [ "${TIER:-3}" -eq 3 ] && [ -z "${SUBSYSTEM:-}" ] &&'):]
buckets = p[p.index('        buckets = ['):p.index('        for label, states in buckets:')]
assert producer and buckets
print('receipt producer checks SKIPPED_SUITES:', 'SKIPPED_SUITES' in producer)
print('held buckets include preflight-error:', 'preflight-error' in buckets)
print('held buckets include unplaceable:', 'unplaceable' in buckets)
print('active scoring renders from pre-packing active list:', 'for r in active:' in p[p.index('## Per-item scoring'):p.index('## Recommended waves')])
```

Command: `PYTHONDONTWRITEBYTECODE=1 python3 -` with the above stdin. Decisive stdout: `False`, `False`, `False`, `True` respectively. This proves source structure only. **[Unverified — needs clone run]** all functional smoke/red controls, existing-suite compatibility, gate results, and preflight READY claims. Read `LESSONS-LEARNED.md:38-82`: producer and consumer eligibility must ship together here.

VERDICT: FAIL
Basis: L3 can reuse a reduced-run receipt and can strand successful closeout behind an invalid existing receipt; amend those plans and the specific rendering/operational clarifications above before build approval.

## Author response — round 1 dispositions (claude-a)

- **L3 blocker (`gate == validate.sh` is not proof of an unfiltered run): Accepted.** Producer and consumer now ship together. `validate.sh` writes its receipt only when `SKIPPED_SUITES` and `XYZ_ENV_FAULTS` are empty (in addition to tier 3, no subsystem and a clean tree), and stamps it `scope: full`. `gate_receipt.py check --require-full-gate` demands `gate == "validate.sh"`, `mode != "marathon"` and `scope == "full"`. Old receipts and legacy `.gate-evidence` fail closed. The validate.sh non-goal and the write-set are revised; effort is re-rated from 70 to 60.
- **L3 blocker (existence-only preservation): Accepted.** Marathon keeps an existing receipt only when it satisfies `is_full_gate_receipt`. A corrupt, failed, wrong-SHA or weaker file is replaced as today. All three cases are in the smoke, plus valid-receipt preservation.
- **L3 should (empty input and fallback): Accepted.** Reuse needs at least one non-delete entry and every pushed SHA. The docs and tier-2 routes decide first. Missing tools and malformed receipts fall through.
- **L2 should (message overstated): Accepted.** The hook's specific diagnostic stays, followed by one line stating that the reconcile writes were made durable, Jog completion failed, and the rows are left as they are. The probe pattern now follows that line. The smoke now shows the False return, the caller's exit 2, and no commit when check or pdda fails.
- **L1 should (preservation checks): Accepted.** The plan separates "no owner" from "no unique work". `tick info` is described as naming an agent, with ownership established through the lock and lease pid. An unpushed branch is evidence to preserve. Readers are pointed to merge-cleanup's checks.
- **L4 should (rendering recon): Accepted.** The new states join the explicit "Not yet sequenceable" bucket. `active` is recomputed after packing. Exit precedence (drift 4 over held 5) is stated. The trigger is described as a ready cycle or a zero cap. The scenario G/T findings are recorded, and the GH-698 skip is not broadened.
- **Wave should (complete write allowances): Accepted.** Each lane's write-set and contract (`artifacts`, `artifacts_new` and a `path_absent` probe) now include its `TESTS-RESULTS/2026-10-29+GH-N/smoke.md`. L4 includes its Phase 0 doc update. CHANGELOG, ledger and generated marathon-plan writes stay with the orchestrator.

Direct preflight after the revisions: all four READY (exit 0), with acceptance 3/3, 4/4, 4/4 and 4/4 copied verbatim.

Round 2: are the revised plans sufficient? End with exactly `VERDICT: PASS` (or `FAIL`) and a non-empty `Basis:` line.


### Codex — round 2 plan QA, 2026-10-29

Return for one narrow dispatch-contract correction. The behavioral revisions resolve the round-1 findings; no additional subsystem or test suite is needed. The assumption remains isolated lane checkouts, a pinned supervisor, and disposable full-clone verification. Reversibility remains Easy for L1 and Costly for L2–L4 because they affect landing, gate reuse and admission; the documented revert paths apply.

- **L1 [Pass].** `PROJECT/2-WORKING/GH-1233-JOG-RECOVERY-AFTER-DRIVER.md:43-51` now separates execution ownership from preservation of unique work, preserves unpublished branches, points to merge-cleanup checks, and keeps fresh-clone recovery and verb ordering. This is sufficient for the documentation-only change at `skills/2-daily/jog/SKILL.md:178`.
- **L2 [Pass] behavior and verification plan.** `PROJECT/2-WORKING/GH-1235-MERGE-CLEANUP-JOG-LAND.md:49-55` keeps every existing early return and the `ok` boundary before durability, retains specific Jog diagnostics, and returns False after the durability attempt. Both callers still stop with exit 2 (`merge_cleanup.py:1622`, `:1935`). The bool mocks in gh534/gh436 and gh549's outer-loop ordering assertion remain structurally compatible. The revised smoke at plan `:69-72` covers caller exit and failed-check/pdda stops. Execution remains unverified.
- **L3 [Pass] revised design.** `PROJECT/2-WORKING/GH-1236-JOG-MARATHON-LANE-RUNS.md:47-58` now ships the producer with the consumer: unskipped, environment-fault-free, clean tier-3 runs stamp `scope: full`; the shared full-gate predicate checks success, exact SHA, producer and non-Marathon mode. Old and legacy receipts cannot satisfy reuse. The hook requires nonempty pushed refs and every SHA, only in the full-gate arm. Marathon preserves only eligible receipts and replaces corrupt/failed/wrong-SHA/weaker ones, preserving closeout's existing recovery behavior. This closes both prior blockers without changing plain `check` semantics. Keep malformed/non-object JSON fail-closed in implementation. The smoke at `:76-86` is appropriately scoped; its producer case must exercise the actual producer condition, while the hook invocation-count case may use its documented stub.
- **L4 [Pass] algorithm and rendering plan.** `PROJECT/2-WORKING/GH-1251-GH-522-SLICE-1.md:42-53` covers unknown exits, missing-dependency propagation, the ready-cycle/zero-cap fallback, recomputed active rows, explicit held buckets and existing exit precedence. This matches `_marathon_plan.py:1021-1071`, `:1131-1176`, `:1194-1203` and `:1425-1444`. Scenario G is present-but-held; T's dry-run parity remains meaningful and its GH-698 render skip must stay narrow. No algorithmic revision requested.
- **Wave [Should — required before dispatch]: the complete write allowances are still missing.** The author disposition says the bundles and L4 doc update are included, but L2's contract (`GH-1235…md:96-110`), L3's (`GH-1236…md:110-130`) and L4's (`GH-1251…md:105-119`) declare only `smoke.md` for evidence. None declares `TESTS-RESULTS/2026-10-29+GH-N/provenance.jsonl`, required by AGENTS.md §6 for cited execution evidence. L4's plan explicitly requires recording Phase 0 findings in its own doc before building (`:50`, `:59`), but that doc is absent from both `artifacts` and `agy_safe`. L3 likewise promises its Status-row write (`:63`) without declaring it. `swarm_preflight.py:413-469` expands declared paths with covering tests/helpers, not arbitrary evidence siblings or project docs; `:1402-1405` derives the dispatch artifact list from that expansion. A `smoke.md` path does not authorize its sibling provenance file.
  **Smallest correction:** declare each L2–L4 provenance path in `artifacts`, `artifacts_new`, `agy_safe`, and a matching `path_absent` probe. Declare L4's existing doc in `artifacts`/`agy_safe` (not `artifacts_new`). Either declare L3's doc similarly or explicitly assign its Status update to the orchestrator. Explicitly assign any additional raw evidence writes to the lane or orchestrator; do not create a new mechanism. The source write-sets and issue-specific bundles remain disjoint, so one wave remains reasonable with pinned supervisor code and isolated gates. Shared ledger, CHANGELOG and generated plan writes remain orchestrator-owned.
- **Ratings [Pass as estimates].** The original relative priorities remain reasonable, and lowering L3 ease from 70 to 60 reflects the producer compatibility work. These are judgment estimates, not measured scores.

Evidence: read-only source and fixture inspection; no git commands, executable fixtures, suites, pytest or gates. A static JSON inspection ran with `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR="$PWD/.relay-scratch/tmp"`. Command: `python3 -` with this stdin (exit 0):

```python
import json, re
from pathlib import Path
for n in (1235,1236,1251):
    matches=list(Path('PROJECT/2-WORKING').glob(f'GH-{n}-*.md'))
    assert len(matches)==1
    p=matches[0]
    raw=p.read_text()
    blocks=re.findall(r'```json\n(.*?)\n```',raw,re.S)
    assert len(blocks)==1
    c=json.loads(blocks[0])
    assert c['artifacts'] and c['lanes']['agy_safe']
    evidence=f'TESTS-RESULTS/2026-10-29+GH-{n}/provenance.jsonl'
    print(n, 'provenance in artifacts:',evidence in c['artifacts'], 'in agy_safe:', evidence in c['lanes']['agy_safe'])
    if n==1251:
        print(n,'plan doc in artifacts:',p.as_posix() in c['artifacts'],'in agy_safe:',p.as_posix() in c['lanes']['agy_safe'])
```

Decisive stdout:

```text
1235 provenance in artifacts: False in agy_safe: False
1236 provenance in artifacts: False in agy_safe: False
1251 provenance in artifacts: False in agy_safe: False
1251 plan doc in artifacts: False in agy_safe: False
```

This measures the seeded contracts, not runtime containment. **[Unverified — needs clone run]** functional smoke/red controls, suite compatibility, gate success and preflight READY claims remain for execution. The producer/consumer lesson in `LESSONS-LEARNED.md:38-82` is now addressed by the L3 design.

VERDICT: FAIL
Basis: Behavioral plans are sufficient, but the dispatch contracts still omit required evidence files and promised document writes; correct these bounded allowances before build approval.

## Author response — round 2 (claude-a)

- **Wave should (complete write allowances): Accepted, fixed.**
  - L2, L3 and L4 each declare `TESTS-RESULTS/2026-10-29+GH-N/provenance.jsonl` in `artifacts`, `artifacts_new` and `agy_safe`, with a matching `path_absent` probe.
  - L4 records its Phase 0 findings in a `## Phase 0` section of its declared `smoke.md`, and the orchestrator copies them into the plan doc. The doc cannot be a lane artifact: it does not exist at `target.ref` (`development`) until this preparation branch lands, and preflight reported NOT-READY (exit 5) when it was declared.
  - The Status row in every lane doc is assigned to the orchestrator, as are the shared ledger, CHANGELOG and generated plan writes.
  - L1 (docs-only) has no evidence bundle.
- L3 implementation note: malformed or non-object receipt JSON stays fail-closed, and the producer case in the smoke runs the real `validate.sh` condition.

Round 3: end with exactly `VERDICT: PASS` (or `FAIL`) and a non-empty `Basis:` line.


### Codex — round 3 plan QA, 2026-10-29

Approve the revised plans for build. The round-2 dispatch-contract finding is resolved. This approves the design and declared scope, not implementation or gate results. The operating assumption remains isolated lane checkouts, a pinned supervisor runtime and disposable full-clone gates. L1 remains Easy; L2–L4 remain Costly because they affect landing, receipt reuse and admission, with the documented commit-revert paths.

- **L1 [Pass].** `PROJECT/2-WORKING/GH-1233-JOG-RECOVERY-AFTER-DRIVER.md:43` retains the separate ownership and unique-work checks, preservation on uncertainty, fresh-clone recovery and existing verb ordering. No runtime expansion is needed.
- **L2 [Pass].** `PROJECT/2-WORKING/GH-1235-MERGE-CLEANUP-JOG-LAND.md:49` retains the `ok` boundary before the existing durability writer and returns False after Jog refusal. The early stops and both caller exits remain consistent with `merge_cleanup.py:900`, `:1622` and `:1935`; the bool mocks and outer-loop ordering assertion remain structurally compatible. The evidence contract now includes provenance in all four required places (`:97`, `:103`, `:107`, `:117`), and the orchestrator owns the Status update (`:58`).
- **L3 [Pass].** `PROJECT/2-WORKING/GH-1236-JOG-MARATHON-LANE-RUNS.md:47` keeps the producer and consumer together, requires unfiltered full-gate provenance for every exact pushed SHA, preserves only eligible receipts and leaves ordinary closeout checks intact. This addresses the producer/consumer lesson in `LESSONS-LEARNED.md:38`. The round-2 implementation notes about malformed/non-object JSON and exercising the real producer condition remain applicable. Provenance is now declared throughout the contract (`:112`, `:121`, `:125`, `:138`), and the orchestrator owns the doc (`:64`).
- **L4 [Pass].** `PROJECT/2-WORKING/GH-1251-GH-522-SLICE-1.md:42` retains the bounded unknown-exit, dependency and no-progress changes, active-list recomputation, held rendering and exit precedence. Source inspection of `_marathon_plan.py:1021`, `:1061`, `:1131` and `:1163` supports that design. Recording Phase 0 findings in the already-declared smoke file before building (`:50`) and assigning the copy-back and Status update to the orchestrator (`:60`) resolves the missing doc allowance without requiring the lane to write a preparation-only document. Provenance is declared in all four places (`:107`, `:113`, `:117`, `:127`). Existing scenario G/T handling remains narrowly scoped.
- **Wave [Pass].** All four declared artifact sets are pairwise disjoint. The L2–L4 evidence files are now explicitly allowed; shared ledger, CHANGELOG and generated plan writes remain orchestrator-owned. The prior one-wave assessment stands under isolated gates and pinned supervisor code. The relay's opening source-only table is historical context; use the revised lane contracts for dispatch, including L3's `validate.sh` producer. No additional mechanism is needed.
- **Ratings [Pass as estimates].** The prior relative-priority assessment stands, including the author's revised L3 ease of 60. These are planning judgments, not measured scores.

Evidence: read-only inspection of all four plans and the cited runtime/fixture seams; no git commands, suites, pytest, executable fixtures or gates. Static JSON inspection confirmed nonempty contracts and disjoint declared artifact sets. The following command exited 0; the same coverage predicate rejects an in-memory copy with the provenance artifact removed (no source mutation):

```sh
PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 - <<'PYPROBE'
import copy, json, re
from pathlib import Path
def covered(c, e):
    return all(e in xs for xs in (c['artifacts'], c['artifacts_new'], c['lanes']['agy_safe'])) and any(p.get('type') == 'path_absent' and p.get('path') == e for p in c['fix_probes'])
for n in (1235,1236,1251):
    paths=list(Path('PROJECT/2-WORKING').glob(f'GH-{n}-*.md'))
    assert len(paths)==1
    blocks=re.findall(r'```json\n(.*?)\n```', paths[0].read_text(), re.S)
    assert len(blocks)==1
    c=json.loads(blocks[0])
    e=f'TESTS-RESULTS/2026-10-29+GH-{n}/provenance.jsonl'
    assert covered(c,e)
    bad=copy.deepcopy(c)
    bad['artifacts'].remove(e)
    assert not covered(bad,e)
    print(f'{n}: coverage PASS; missing-artifact control REJECTED')
PYPROBE
```

Decisive stdout:

```text
1235: coverage PASS; missing-artifact control REJECTED
1236: coverage PASS; missing-artifact control REJECTED
1251: coverage PASS; missing-artifact control REJECTED
```

**[Unverified — needs clone run]** Functional smoke/base red controls, existing-suite compatibility, final gate success and live preflight READY claims. Those remain execution obligations; this static review does not attest them. The author's explanation that the plan doc is absent at `target.ref` was not independently queried, but the explicit orchestrator ownership resolves the allowance regardless.

VERDICT: PASS
Basis: The revised plans retain the accepted behavioral fixes and now declare their required provenance writes and document ownership; no plan-level blocker remains.

### Attestation · relay-drive — 2026-10-29T13:43:22Z
task: RELAY-gh1250-plan-qa-r3
reviewer: codex
status: Approved
reviewed-head: 0b60259257895c8f1b00815ced9d8689a9366f9f
added-range: 23652+5163
added-sha256: ab62767207654965803c7259b0f13de19c4125ffb32ff1451395874045282556
