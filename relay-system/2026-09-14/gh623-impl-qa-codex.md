---
Goal: Final QA — GH-623 implementation (soft edges, fetch retry, resume loop)
Date: 2026-09-14
NEXT: Producer
STATUS: Changes requested
---

# Context

You are the FINAL implementation reviewer for GH-623. The approved plan is
`PROJECT/1-INBOX/GH-623-MERGE-CLEANUP-RESILIENCE.md` (Codex plan QA passed in 4 rounds —
see `relay-system/2026-09-14/gh623-plan-qa-codex.md`). The implementation is committed at HEAD
of this worktree (commits after the approval record): red controls + implementation + SKILL.md
+ CHANGELOG. The issue: HiQS-Labs/XYZ-forge#623.

Read: the plan, then the diff surface —
- skills/merge-cleanup/scripts/toposort_prs.py  (hard/soft edges, FetchError, bounded discovery)
- skills/merge-cleanup/scripts/scan_clones.py   (run_git additive timeout, default unbounded)
- skills/merge-cleanup/scripts/merge_cleanup.py (_transient/_retry_call/_net_git, defer-and-continue, refresh/discovery retry, --resume, exit-2 discovery refusal)
- skills/merge-cleanup/SKILL.md                 (drive loop, Done rule, classifier retry, parity rows)
- test/gh534_phase_b_tests.py                   (stub: files passthrough, view_fail/list_fail injectors)
- test/gh534_phase_c_tests.py                   (TestGh623Resilience + updated parity control)

Evidence so far: 13 red controls failed on pre-change code; after the change the full
merge-cleanup unit suite is 156/156 green (`bash test/gh436-merge-cleanup.sh`), including
TestParityGuard with the three new capability rows.

## Operational envelope

Grade against the approved plan's stated requirements and commensurate complexity. Do NOT
demand unrequested machinery — the plan's non-goals (no circuit breaker, B1 second-clone/push
stay unbounded, /unstuck self-trigger rejected) are deliberate scope.

## Questions to adjudicate (cite file:line)

1. Per-issue acceptance: does each of the issue's five acceptance bullets have committed
   code + a test that would fail without it (a) soft edges never block, (b) bounded calls +
   3x transient retry + defer-and-continue, (c) `--resume` skips landed/parked, (d) SKILL.md
   drive loop + Done rule, (e) classifier-block retry guidance?
2. Codepath fidelity: does the implementation match the approved plan's design section —
   including the round-3 reordering (refresh BEFORE the exhausted-record skip), the exact
   retry contract (3 calls, sleeps [2,4]), `_deps` kept as union, and the two deliberate
   non-deferral sites (pre-queue refusal with `--allow-unready-primary` unchanged; post-merge
   stop)?
3. Duplicates/writers: did any parallel subsystem or second writer slip in? Is `_deps` still
   serialized for `toposort_prs.py --json` consumers?
4. Checks: do the tests substantiate the claims — would each new control catch a regression
   of the behavior it pins? Is any assertion vacuous or empty-input-passing?
5. SKILL.md: do the new sections contradict any code behavior (parity guard aside)? Is the
   Done rule consistent with `--prs-only`/`--scan-only` legitimate uses?

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Be concrete.

Write your verdict below and change the STATUS to Approved/Closed if it passes.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex implementation QA — changes requested

**Verdict: FAIL (2 proof gaps).** The production implementation matches the approved hard/soft,
retry/defer, bounded-call, and resume design on direct inspection, but the committed tests do not
substantiate all five acceptance bullets and the advertised parity guard does not actually require
the three new capability rows.

### Graded findings

1. **BLOCK — the three new parity rows are not part of the fixed required set.** SKILL.md adds
   `soft-edge-nonblocking`, `network-retry-defer`, and `resume-skips-parked`
   (`skills/merge-cleanup/SKILL.md:202-204`), but `REQUIRED_CAPABILITIES` omits all three
   (`test/gh534_phase_c_tests.py:405-415`). `parity_failures()` checks only that fixed set
   (`test/gh534_phase_c_tests.py:450-465`), so deleting any or all of the new rows leaves the parity
   test green. This directly contradicts the plan's promise that the parity guard covers the three
   new rows (`PROJECT/1-INBOX/GH-623-MERGE-CLEANUP-RESILIENCE.md:222-224`) and makes the new
   capability documentation decorative. Add the three names to `REQUIRED_CAPABILITIES`; the
   existing deleted-row mutation control will then prove each one is required.

2. **BLOCK — R4 has prose but no regression test.** The Drive loop, Done rule, and
   permission-classifier retry guidance are present (`skills/merge-cleanup/SKILL.md:143-169`), and
   the Done exception correctly includes the legitimate `--prs-only` mode alongside
   `--teardown-only`/`--scan-only` (`:162-164`). However, no test references or asserts any of those
   contracts: the parity parser is confined to the capability-table section and documented CLI
   options (`test/gh534_phase_c_tests.py:442-469`). Removing the entire Drive loop, weakening the
   Phase-5 Done condition, or deleting the retry-once guidance therefore leaves the suite green.
   The adjudication question explicitly requires a test that fails without acceptance bullets (d)
   and (e). Add focused, non-vacuous document-contract assertions (including the Phase 5 condition,
   all three explicit-mode exceptions, and retry-identical-once-before-escalation), with mutation
   controls so wording checks cannot pass on unrelated text.

### Adjudication of the remaining questions

- **Hard/soft behavior — pass.** `toposort_prs.py` publishes `_hard_deps`, `_soft_deps`, and the
  sorted union `_deps` before Kahn mutates the graph (`toposort_prs.py:145-152`). `land_prs()` blocks
  only on hard predecessors and attempts soft successors (`merge_cleanup.py:568-582`). The mixed
  soft/hard fixture proves PR 3 lands while explicit dependent PR 4 remains open
  (`test/gh534_phase_c_tests.py:508-526`). No second dependency writer appears in the reviewed
  surface, and standalone JSON still serializes the PR dictionaries with `_deps`
  (`toposort_prs.py:235-238`).
- **Network contract — pass.** The retry constants pin three calls and sleeps `[2, 4]`
  (`merge_cleanup.py:73-75,100-116`); retry-site Git calls route through finite-time `_net_git`
  (`:89-97,229-239,737-741,883-894`); discovery is bounded and raises `FetchError`
  (`toposort_prs.py:16-49`). Initial per-PR refresh and landing-clone exhaustion defer and continue
  (`merge_cleanup.py:583-621`), while pre-queue refusal (with the existing override) and post-merge
  stop remain deliberate. The view, discovery, hung-clone, default-unbounded, and override tests
  contain populated fixtures and observable call/sleep/state assertions
  (`test/gh534_phase_c_tests.py:528-643,683-726`); none of those assertions is empty-input based.
- **Resume ordering — pass.** Live refresh and landing simulation precede the exhausted-record
  shortcut; the record is consulted only after a conflicting landing (`merge_cleanup.py:583-645`),
  and non-resume repair still reaches under-lock `reserve()` (`:647-668`). The paired tests prove a
  still-conflicting exhausted PR skips without B1 while a clean PR whose last repair resolved lands
  (`test/gh534_phase_c_tests.py:644-681`).
- **Scope/duplication — pass.** `scan_clones.run_git()` gained only the additive, default-`None`
  timeout (`scan_clones.py:85-109`); the implementation reuses the existing ordering, outcome map,
  attempt-record writer, and landing loop. No parallel subsystem or second durable writer was added.

No source, artifact, or test command was executed in this reviewer turn. Graph verification used
the `Users-noelsaw-Documents-GH-Repos-XYZ-forge` full index at generation
`2026-09-15T04:47:51Z`; all reviewed production/test paths reported no recorded coverage issue.
The approved plan was missing from that index generation and was read directly, and all material
claims above were confirmed against numbered source reads because the indexed symbol signatures  [Unverified — no citation]
still reflected the pre-change branch.

## Log

### Codex implementation QA handoff

VERDICT: FAIL

Basis: production behavior passes inspection, but the new parity rows are not required by the
parity guard and the Drive-loop/Done/classifier acceptance text has no regression proof.
