---
Goal: Final QA of the GH-505 / GH-509 / GH-510 implementation — driver-attested approval
Date: 2026-09-08
NEXT: Reviewer
STATUS: Open
ROUND: 3 / 3
---

# Context

Review the **committed implementation** of the design the operator chose after plan QA reached
its 3-round cap (`relay-system/2026-09-08/gh509-design-v2-plan-qa.md`, escalated; operator
chose option (b): implement on the producer-adjudicated revision with THIS review as the check).

Read in full:

- `PROJECT/2-WORKING/GH-505-RELAY-REVIEWER-INTEGRITY.md` — the adjudicated plan, with an
  **Implementation dispositions** table listing every place the code departs from it and why
- `test/baselines/GH-505-negative-control.md` — red controls as observed, and the same deviations
- `PROJECT/1-INBOX/GH-505-RELAY-REVIEWER-INTEGRITY.md`, `PROJECT/1-INBOX/GH-510-JOG-MERGE-FALSE-SUCCESS.md`

The implementation (all on this branch, base `a6441b9b`):

- `utils/py/relay_attest.py` — the one writer / resolver / validating reader of `relay-drive/attest@1`:
  `canonical()`, `write()`, `load(task, *, expected_reviewer, relay_file, target_repo, path=None)`,
  `candidate_ok(record, candidate_sha, target_repo)`
- `utils/py/relay_drive.py` — `--reviewer` / `--builder`; per-turn `RELAY_ROLE`, `RELAY_REVIEWED_HEAD`,
  `RELAY_ARTIFACT_SHA256`; `judge_terminal()` (forged-terminal revert + checked commit; empty-approval;
  review-body-rewritten; close-mismatch before publication; attest = trailer + checked commit + atomic
  record); `unattested-terminal` at all three terminal exits; the nonzero-shim path judges for revert only
- `relay-automation/relay-turn-lib.sh` — `rtl_is_reviewer_turn` first tier (`RELAY_ROLE` under
  `RELAY_DRIVER_LOCKED=1`); `rtl_worktree_begin` cuts at `RELAY_REVIEWED_HEAD` and verifies the seeded
  artifact digest; the approval instruction moved into the reviewer `role_note`
- `utils/py/marathon_drive.py` — `attested_terminal()` shared probe; `satisfied_lane_terminal()`, the
  exit-3 and exit-7 probes require it; `complete_phase_success()` binds the candidate before the approved
  event and again after the post-approve command; receipt gains `reviewed_candidate`, `reviewed_head`,
  `added_sha256`, `attest_path` (`MACHINE-CONTRACTS.md` Contract B updated; goldens re-recorded)
- `utils/py/jog_run.py` — override deleted; `run_single_phase_drive` requires a reviewer and dispatches
  via `marathon-agent.sh`; `_merge_reviewed_pr()` serves all three landing branches with
  `candidate_ok` + `--match-head-commit`; parks on refusal / failure / no PR (#510); simulate lands as
  a simulated completion
- `utils/py/gate_env.py` + the marathon literal — the three new exports classified SCRUB
- `test/gh505-relay-attest.sh` (50 cases, real `codex-turn.sh` with a stub binary, base-driver red
  controls); `test/lib/attest-stub.sh`; 30 shipped suites re-pointed at the attestation;
  `test/fixtures/contracts/result-at1-*.json`
- Migration: `skills/relay-xyz/SKILL.md` recipes, `relay-automation/README.md`, `relay-drive.sh` header

Gate: `validate.sh` 355/356 in a disposable clone at `2ca56630` (the one failure, `gh280` N1, was a
fixture without an attestation — fixed in the next commit); the full re-run at the reviewed HEAD is
recorded under `TESTS-RESULTS/2026-09-08+GH-505/` once it completes.

## Questions

Answer each with a verdict and cite `file:line` where you disagree.

1. **Is the trust boundary the code enforces the one the plan states?** The driver's exit depends
   only on `attested` (in-process memory). Find any path where a terminal exit 0 is reachable
   without `judge_terminal` having attested in this process.
2. **B1 (round 2 of plan QA): can a turn's permissions still be decided by bytes a builder can
   write?** `relay-turn-lib.sh` `rtl_is_reviewer_turn`, `rtl_worktree_begin`, and the `rtl.py` bridge.
3. **Is the reviewed revision really pinned?** `RELAY_REVIEWED_HEAD` → `git worktree add --detach … "$_cut"`.
   Non-isolated turns → `isolated:false` → `candidate_ok` refuses. Seeded artifact → digest verified
   at seed, record merge-ineligible. Any gap?
4. **Reader obligations (B3):** does `load()` check everything the plan required — task, file,
   repo, expected reviewer, status (record = file), range + digest, trailer by offset — and does
   every consumer pass a trusted expected reviewer and require the token `done`?
5. **Candidate binding (B2):** `candidate_ok` = ancestor + endpoint diff outside `relay-system/`,
   the relay file, and its directory (`:(top,literal,exclude)`). Marathon binds before publication
   and after post-approve; jog binds to the PR head and merges with `--match-head-commit`. Is the
   transcript-path allowance too wide (the relay file's *directory*)? Is the marathon-executor
   landing's `expected_candidate == receipt.reviewed_candidate` check sufficient?
6. **Each implementation disposition** in the plan's table: accept, or name the cheapest
   correction. In particular `--reviewer` warn-not-refuse and the uncited-claim downgrade port in
   `canonical()` (is the port byte-faithful to the awk in `relay-turn-lib.sh:1195-1230`?).
7. **Falsifiability:** are the red controls real? Cases A and C invoke the base driver from a
   `git archive a6441b9b` copy without the new flags. Is anything in the 50 cases passing for a
   reason unrelated to the fix? Is `test/lib/attest-stub.sh` an honest stand-in for the driver, or
   does it let a suite pass that should not?
8. **Scope:** any second subsystem or parallel writer? Anything changed that the issues do not
   require? Ratings #505 `85/85/50/55`, #509 `75/85/50/25`, #510 `70/70/50/90` — still grounded?

Reviewer writes ONLY to this relay file. Set `STATUS: Approved` only if the implementation is sound
as committed; otherwise list findings ranked, each with the cheapest correction.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Round 1 — Reviewer (codex) — 2026-09-08

VERDICT: Changes required — two High blockers and four Medium findings. STATUS remains Open.

Basis: source inspection of the supplied implementation, adjudicated plan, issue captures,
negative-control report and named fixtures. No source or artifact was executed, no tests or git
commands were run, and no file other than this relay was edited. Graph tools were unavailable;
the evidence below comes from direct source reads. Counterexamples below are source-derived,
not claims of fresh runtime reproduction. The advertised `TESTS-RESULTS/2026-09-08+GH-505/`
directory is absent in this review checkout, so final-HEAD gate provenance remains outstanding.

### Ranked findings

**B1 — High / Block: a failed reviewer turn can publish an attestation.**
`utils/py/relay_drive.py:880` calls `judge_terminal()` on the nonzero-shim path for **both** roles.
That function receives no shim result or publication permission; after the reviewer/body/done
checks, it appends and commits the trailer and writes the record at `:689-700`. The comment at
`:878` and the relay's claim that this path judges “for revert only” are therefore false.

This is reachable through the shipped shim: `utils/py/codex-turn.py:119-135` copies back and
enforces a failed/timed-out turn before returning 5 or 7 at `:164-167`. A reviewer can append an
approval, mark done, then fail or time out. The driver returns the failure but leaves a valid
approval record. With artifacts present, marathon's timeout recovery accepts that record at
`utils/py/marathon_drive.py:3364-3368`, converts the result to success at `:3386-3391`, and can
complete the phase. A later startup can also accept the record through `:2751-2757`.

Cheapest correction: make the failure-path call explicitly revert-only (or call it only for a
builder role), with publication impossible unless the shim returned zero. Preserve the original
shim exit. Extend the existing `failafter` fixture to a **reviewer** (`test/gh505-relay-attest.sh:77-82`);
A2 currently uses only `bld` at `:130-135`. Assert no trailer/record on reviewer exit 5 and 7, and
that marathon's timeout/startup recovery cannot promote either failure to success.

**B2 — High / Block: candidate binding exempts arbitrary neighboring source files.**
`utils/py/relay_attest.py:231-235` treats the parent directory of *every* tracked relay file as
harness metadata. Nothing establishes that the directory contains only records. For a supported
tracked relay `src/review[1].md`, an unreviewed descendant commit changing `src/service.py` is
excluded by `:(top,literal,exclude)src/`; ancestry still passes and the remaining endpoint diff
can be empty. The same hole reaches marathon and all three jog merge paths through the shared
reader. Literal matching fixes metacharacters, not an overbroad allowance.

Cheapest correction: keep the exact relay path exclusion and narrowly name the additional
harness-owned record paths needed by marathon. Do not infer authority over a directory from the
location of a user-selected relay. Restore the adjudicated N3 control: neighboring source drift
must refuse, while the exact relay and required metadata-only changes pass. Reject this
implementation disposition as written.

**F1 — Medium / Fix: jog never requires the token to read done at landing.**
Marathon's shared probe checks the token explicitly (`utils/py/marathon_drive.py:2402-2405`), but
jog's legacy loader goes straight to `load()` (`utils/py/jog_run.py:1462-1472`), its marathon
projection does the same (`:435-441`), and `_merge_reviewed_pr()` performs no token read
(`:1438-1459`). `load()` does not inspect tick. Consequently a valid record/file/candidate can
merge even if the current token is missing or unreadable. This contradicts the plan's explicit
consumer obligation, independently of the historical done check at publication.

The new legacy landing fixture actually encodes this omission: it manufactures the record and
successfully merges at `test/gh505-relay-attest.sh:308-332` without creating/completing that token
in its target repo. Cheapest correction: add the done check using the appropriate pinned tick
root at the shared landing boundary, then seed a real done token in positive fixtures and cover
missing, unreadable and live-token refusals for both executors. Keep receipt-provided reviewer
identity under the stated trusted-receipt contract; no second identity system is needed.

**F2 — Medium / Fix: the uncited-claim transform is not stable under appending text.**
`utils/py/relay_attest.py:61` looks forward into subsequent lines. Suppose the original body ends
in the uncited line `verified` and the reviewer only appends a line containing a backtick citation.
The pre-snapshot synthesizes an Unverified stamp, but the post-turn awk sees the new nearby citation
and leaves the original line untouched (`relay-automation/relay-turn-lib.sh:1216-1219`). The
post-snapshot also leaves it untouched, so `relay_drive.py:657` rejects a genuinely append-only
review as `review-body-rewritten`. Builder turns do not pre-stamp these claims (`relay-turn-lib.sh:1373-1377`),
so an ordinary builder-to-reviewer handoff can contain this input.

The claimed byte-faithful port also differs on CRLF and unterminated lines: Python strips CR/LF
then restores the original terminator (`relay_attest.py:50-65`); awk retains a CR in `$0` and
`print` adds LF (`relay-turn-lib.sh:1207,1220-1223`). Its environment-number parsing also differs
from Python's `int` with fallback. B5 tests a newly appended uncited finding, not these boundaries.

Cheapest correction: make comparison of the existing prefix independent of newly appended
citation context while accounting for the actual harness rewrite; use one explicitly defined
line-ending/window policy in both implementations. Add the trailing-claim/new-citation control
and byte-level CRLF/no-final-LF parity cases. Accept the need to account for the harness stamp,
but not the current equivalence claim.

**F3 — Medium / Fix: malformed records can raise instead of returning a refusal.**
The mandatory-field list at `utils/py/relay_attest.py:165-168` omits `attested_at`, which
`trailer_text()` dereferences at `:120`. A syntactically valid record missing that key gets past
the field check and raises at `:197`. Invalid range types/strings similarly raise at `:191`, and
invalid path types reach `realpath()` at `:176-178`. These exceptions escape callers which expect
`(None, reason)` and park/escalate cleanly. The L control only truncates JSON syntax
(`test/gh505-relay-attest.sh:254`), so it does not cover this contract.

Cheapest correction: validate the fields/types used downstream, including the trailer fields,
before using them; return a named malformed-record refusal on invalid input. Extend L with
valid JSON missing a required trailer field and invalid range/path types, asserting the refusal
tuple rather than a traceback. This is reader robustness, not an argument for signing records.

**F4 — Medium / Fix: several substituted controls do not exercise the promised guard.**
B4's peer commit happens *inside the model stub* (`test/gh505-relay-attest.sh:78`), after the
worktree HEAD was already sampled at `:54`. A shim reverted to cutting live HEAD would still
have cut the same revision in this fixture. B4 proves post-cut drift rejection, not pinning
between the driver's snapshot and worktree creation. Move that commit into dispatch before the
real shim starts, and require the live-HEAD mutation to fail the cut assertion.

The gh280 N2 substitution also stops at the old `head_sha` identity check
(`test/gh280-jog-marathon-adapter.sh:1143-1148`), before the new candidate check. It does not
exercise a PR head matching receipt `head_sha` but differing from `reviewed_candidate`, nor
missing-attestation refusal. Add those narrow projection cases. The cited GH-273 hook tests
write a marker or fail (`test/marathon-drive.sh:251-264`); converting success stubs to attest
does not replace H4's source-committing post-approve hook and final-receipt assertion. Keep an
explicit H4 case. No new test framework is required.

### Answers to the eight questions

1. **Terminal exit invariant: passes source inspection; trust contract: blocked by B1.** All three
   terminal exit-zero sites require in-process `attested` (`relay_drive.py:720,1015,1056`). Help and
   dry-run zero exits are not terminal approvals. However, the durable record can authorize
   consumer success after a failed reviewer turn, contrary to the publication prerequisite.
2. **Role permissions: acceptable within the declared dispatch contract.** The driver's role
   export (`relay_drive.py:770-774`) outranks editable directives in the shared helper
   (`relay-turn-lib.sh:90-94`); the Python bridge preserves the environment (`rtl.py:690-696`).
   The documented manual/inherited-marker limitation remains accepted.
3. **Pinning: implementation acceptable for the shipped isolated shim; proof incomplete (F4).**
   The cut uses the exported revision (`relay-turn-lib.sh:749-750`), seeded bytes are checked
   (`:794-800`), and non-isolated/artifact records are merge-ineligible (`relay_attest.py:214-217`).
   These conclusions assume the stated custom-command/contained-shim contract.
4. **Reader obligations: partial; F1 and F3.** Task/repo/file/reviewer/status/range/digest and
   offset-based trailer checks exist. Marathon passes its configured reviewer and checks done.
   Jog uses its argument or trusted receipt reviewer but omits the current done-token check.
5. **Candidate binding: blocked by B2.** The ancestor/endpoint policy and literal exact-path
   encoding are otherwise coherent. PR head equality with `reviewed_candidate`, followed by
   `candidate_ok` and `--match-head-commit` (`jog_run.py:1448-1455`), is sufficient for the stated
   trusted-receipt/SHA contract once the exclusion and consumer gaps are fixed.
6. **Implementation dispositions:** accept warn-not-refuse for missing reviewer and the matching
   review-once exception because neither permits terminal approval; update contradictory
   startup-refusal prose. Accept simulate-only completion. Reject directory-wide exclusion (B2).
   Accept the need for stamp normalization but require F2. Accept two candidate checks to retain
   GH-273 ordering, with the explicit limitation that `marathon.phase.approved` precedes the hook
   (`marathon_drive.py:2622-2633`); final candidate fields and green telemetry follow validation.
   The substituted test coverage is not equivalent as claimed (F4).
7. **Falsifiability: partial.** A/C really dispatch the archived base driver without the new flags
   (`test/gh505-relay-attest.sh:355-368`); the report records the opposite outcomes, though I did
   not rerun them. B4 and the substituted consumer cases need F4. `attest-stub.sh` is reasonable
   as an explicit success fixture, not as proof of driver publication: it suppresses token failures
   (`test/lib/attest-stub.sh:35-41`) and publishes regardless (`:60-73`). Make success fixtures
   assert done, and preserve separate malformed/missing/failure controls instead of blessing
   every terminal stub. I2/I3/J's base outcomes are described, not executed by the A/C-only base
   section; distinguish that source comparison from observed red evidence.
8. **Scope/ratings: acceptable provisional judgments.** The shared attestation module and one jog
   merge helper extend the existing pipeline. In the inspected production scope,
   `relay_drive.py:696` is the record publication call; the test helper is a fixture writer.
   The operator-excluded merge surfaces remain explicit non-goals. The stated severity/priority
   rationales still fit; #509 effort remains provisional and #510's cheapness applies to its
   narrow false-success correction, not this entire integration. Live ledger persistence and
   external incident statistics were not independently checked.

SWE disposition: **Minimal acceptable; Diagnosable Fix (F3); Blast Block (B1/B2);
Proof Fix (F1/F2/F4 and final-HEAD provenance).** Return to the producer for these bounded
corrections; no implementation approval is granted.

NEXT: Producer (claude-b)

## Round 1 — Producer (claude-b) — 2026-09-08

All six findings accepted; none rejected. Fixed in the commit this turn reviews; the plan's
"Implementation dispositions" table and `test/baselines/GH-505-negative-control.md` record each.

- **B1** → `judge_terminal(ns, role, pre, shim_ok)`: any turn whose shim returned non-zero is
  reverted whatever its role and never attested (`failed-turn-terminal`); the shim's exit is
  preserved. Fixture **A3**: a reviewer that approves, marks done, then fails → exit 5, STATUS
  reverted in HEAD, no trailer, no record.
- **B2** → `candidate_ok` excludes `relay-system/`, the relay file, and marathon's two named
  phase records beside it (`ESCALATION.md`, `PHASE-INTERRUPTED.md` — the only files marathon
  writes there) — never the directory. Fixture **N3**: tracked `src/review[1].md`, neighbouring
  `src/service.py` drift refused; relay-only + `ESCALATION.md` change passes.
- **F1** → jog's landing reads the token in the repo's own tick root (`_token_done`) and parks
  unless it is `done`, for all three branches. Fixture **I0** (record valid, token absent →
  parked, merge not reached); I1 now seeds a real done token. gh280 **N0** seeds the token
  and asserts it reads done.
- **F2** → the pre-turn snapshot's downgrade is judged with the POST-turn lines as look-ahead
  (`canonical_prefix`); records split on LF only with a CR kept in the record and a final LF
  always added; window parsing mirrors awk's numeric coercion. Fixtures **B6** (old uncited
  claim, reviewer appends a backtick citation within the window → attested, old line stays
  un-stamped — verified against the shipped awk directly) and **B7** (CRLF file → attested,
  record loads).
- **F3** → `load()` never raises: any malformed record is `(None, reason)`; `attested_at`
  required; string and integral types checked. **L** extended (missing `attested_at`, string
  range, non-string path).
- **F4** → B4's peer commit now lands in the dispatch script, after the driver's pin and before
  the shim cuts its worktree, with a control asserting HEAD had already moved; gh280 **N2b**
  (PR head == receipt `head_sha` ≠ `reviewed_candidate` → refused) and **N2c** (no binding →
  refused); marathon-drive **H4** (post-approve hook commits source → exit 4,
  `candidate-drifted-from-reviewed-head`, no approved run).

Provenance: `TESTS-RESULTS/2026-09-08+GH-505/` is written from the strict gate run at this
revision (the previous strict run at `a2ce2755` was 355/356; the one failure,
`gh32-releases-app.sh`, passes alone on both base and branch — parallel contention, GH-528 class).

Please review the revision against the same eight questions.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Round 2 — Reviewer (codex) — 2026-09-08

VERDICT: Changes required — the two High findings are resolved in the inspected source;
two Medium corrections and the final gate evidence remain. STATUS remains Open.

Basis: direct source inspection of the revised implementation, full adjudicated plan, both issue
captures, negative-control report, and the named fixtures. Graph tools are unavailable in this
session. No source/artifact or test was executed, no git command was run, and only this relay file
was edited. All counterexamples below are source-derived, not newly reproduced runtime results.
The claimed `TESTS-RESULTS/2026-09-08+GH-505/` directory is still absent from this review checkout.

### Ranked findings

**R2-F1 — Medium / Fix: malformed candidate fields still escape the validating reader.**

The original missing-timestamp/range/path exceptions are handled, but the validation at
`utils/py/relay_attest.py:211-220` does not cover the fields used by `candidate_ok()`. Starting
with a valid record and replacing `relay_file_rel` with a nonempty JSON object leaves every
`load()` check satisfied: that field is neither checked nor included in the trailer. After the
ordinary ancestry check, `candidate_ok()` reaches `os.path.dirname(rel)` at `:285` and raises
`TypeError`. This is outside `load()`'s exception handler. Both marathon
(`utils/py/marathon_drive.py:2412`) and jog (`utils/py/jog_run.py:1480`) call it without converting
the exception to a refusal, so the consumer crashes instead of parking/escalating normally.

There is also a fail-open type variant: a valid non-isolated record with `isolated` changed from
JSON `false` to the string `"false"` is accepted by `load()` and passes the truthiness test at
`relay_attest.py:266`. The isolation field is not in the trailer either. This is malformed-record
handling within the stated reader contract, not a request to authenticate hostile same-user writes.

Cheapest correction: validate the candidate-consumed schema fields before returning a record:
`isolated` must be a boolean; `relay_file_rel` and `artifact_sha256` must have their declared
nullable-string shapes. Keep candidate failures as refusal tuples. Extend L with the nonempty
object path and string-boolean cases, then exercise the consumer boundary to assert a refusal
without a traceback. The current L additions at `test/gh505-relay-attest.sh:290-292` cover only
the earlier timestamp/range/absolute-path cases.

**R2-F2 — Medium / Fix: H4 still does not establish that the second candidate check was reached.**

The new source-committing hook is the right stimulus (`test/marathon-drive.sh:271-278`), but the
only assertions are exit 4 and the generic `candidate-drifted-from-reviewed-head` reason at
`:279-281`. The *first* bind, before the hook, produces exactly those same outcomes on any invalid
attestation/candidate (`utils/py/marathon_drive.py:2612-2621`). Thus an early refusal can make H4
pass without executing the hook or exercising the post-hook check at `:2633`. The fixture also
never reads a result receipt or checks green telemetry, despite the producer's “no approved run”
claim and the earlier request for a final-receipt assertion.

Cheapest correction: assert that the hook actually committed the expected source change, capture
a nonempty result receipt, and assert the final outcome is not approved and no green completion
was emitted. Preserve the accepted GH-273 ordering: the earlier `marathon.phase.approved` event
may exist. Run the focused control with only the second bind disabled and observe it fail, then
restore the bind and observe it pass. This finishes the existing H4 case; it needs no new framework.

### Answers to the eight questions

1. **Trust boundary: acceptable on source inspection; prior B1 resolved.**
   `judge_terminal(..., shim_ok=False)` is now explicit on the nonzero path
   (`relay_drive.py:887-893`), and `:651-659` reverts before publication for either failed role.
   The original shim result is preserved. All three terminal-success paths still require
   in-process `attested` (`:727`, `:1025`, `:1066`). A3 now exercises a failed reviewer through the
   real shim (`test/gh505-relay-attest.sh:142-148`). Exit-7 recovery has the same source-level
   protection, although A3 itself exercises exit 5 only.
2. **Role permissions: acceptable within the declared contained-shim contract.** The shared
   first tier remains invocation-derived (`relay-turn-lib.sh:90-94`), and the bridge preserves
   those exports (`rtl.py:690-696`). The new exports are SCRUB in `gate_env.py:74-76` and the
   marathon literal at `marathon_drive.py:2212`. The documented inherited-marker limitation
   remains a limitation, not a newly discovered authority source.
3. **Pinning: acceptable; B4's original proof defect is corrected.** The worktree cuts at the
   exported pin (`relay-turn-lib.sh:749-750`) and checks seeded artifact bytes (`:794-800`).
   B4 now advances parent HEAD in dispatch before the real shim starts
   (`test/gh505-relay-attest.sh:95-98`), checks that advancement, and checks the cut against the
   old SHA (`:179-180`). Non-isolated/artifact records are refused for correctly typed records;
   malformed shapes need R2-F1.
4. **Reader obligations: runtime token omission resolved; schema handling needs R2-F1.** Jog
   now pins `TICK_REPO_ROOT` and explicitly reads done (`jog_run.py:1435-1450`), from the common
   merge helper used by all three branches (`:1466-1468`). I0 checks a valid record with an absent
   token and no merge call (`test/gh505-relay-attest.sh:387-391`); gh280 N0 independently asserts
   done (`test/gh280-jog-marathon-adapter.sh:1085`). Trusted expected-reviewer inputs and the
   status/range/digest/offset checks remain as described in round 1.
5. **Candidate binding: prior B2 resolved.** The exclusions now name the exact relay and two
   explicit phase records, rather than every neighboring file (`relay_attest.py:279-287`). N3
   checks neighboring `src/service.py` drift (`test/gh505-relay-attest.sh:296-309`). I accept the
   two named metadata files as the documented allowance. Marathon retains two binds; jog retains
   receipt-candidate equality and `--match-head-commit` (`jog_run.py:1477-1484`). N2b and N2c now
   reach the newly added candidate-equality and missing-binding guards
   (`test/gh280-jog-marathon-adapter.sh:1154-1172`).
6. **Dispositions: mostly accepted.** Accept warn-not-refuse, the matching review-once exception,
   simulate completion, named metadata allowances, revert-only failed turns, done-token reads,
   and two candidate checks preserving GH-273. The default-window trailing-claim correction and
   LF/CRLF normalization are coherent (`relay_attest.py:56-87`, `:128-131`; B6/B7 at
   `test/gh505-relay-attest.sh:201-218`). Do not claim complete awk coercion parity: `_window()`
   still uses Python `int()` (`relay_attest.py:47-53`), while Bash defaults an empty value to 3
   and awk numerically coerces the supplied string (`relay-turn-lib.sh:1203-1206`). For example,
   `3.0` becomes 0 in Python, and Python accepts `1_0` as 10. Low-priority correction: define one
   supported integer policy consistently, or narrow the parity claim and cover the accepted
   values. Reader robustness remains subject to R2-F1; substituted proof remains subject to
   R2-F2. The startup-refusal sentence in the plan at `:209` still contradicts its disposition.
7. **Falsifiability: improved, incomplete.** The A/C base-driver calls remain real fixture
   dispatches without the new flags (`test/gh505-relay-attest.sh:416-429`); I did not rerun them.
   B4 and gh280 N2b/N2c now target the requested guards. H4 needs R2-F2. The success stub still
   suppresses token-operation errors (`test/lib/attest-stub.sh:35-41`) and publishes at `:73`;
   it is suitable only as a manufactured success record, never evidence of driver publication.
   The real consumer's done check prevents that stub behavior from excusing a missing token.
   An explicit done assertion in the shared success fixture would make fixture failures easier
   to diagnose. The baseline report still mixes observed A/C red runs with source comparisons
   for I/J; label those evidence types accurately.
8. **Scope and ratings: unchanged provisional acceptance.** The inspected production path still
   has one publisher (`relay_drive.py:703`) and shared reader/merge helpers. No additional review
   subsystem is needed. The stated excluded merge surfaces and ratings retain round 1's limits;
   no external incident census or live ledger was checked in this turn.

**Evidence outstanding:** the plan requires committed final-revision `provenance.jsonl`
(`PROJECT/2-WORKING/GH-505-RELAY-REVIEWER-INTEGRITY.md:217`), but the advertised campaign directory
is absent here. Supply the retained final-state gate receipt for the next review and distinguish
earlier 355/356 runs from the final result. This reviewer did not run a gate, as instructed; the
producer/harness owns that remaining evidence.

Disposition: return to the producer for R2-F1, R2-F2 and final-state evidence. The prior High
blockers are closed on source inspection; implementation approval is not yet granted.

NEXT: Producer (claude-b)

## Round 2 — Producer (claude-b) — 2026-09-08

Both findings accepted; the low-priority parity note and the evidence gap addressed too.

- **R2-F1** → `load()` validates the fields `candidate_ok()` consumes: `isolated` must be a
  boolean; `relay_file_rel`, `artifact_sha256`, `transcript_repo` must be null or a non-empty
  string. `candidate_ok()` itself never raises (any exception is `(False, "candidate check
  failed …")`). **L** extended with the object `relay_file_rel` and string-`"false"` `isolated`
  cases plus a direct malformed `candidate_ok` call; **I7** exercises the consumer boundary: a
  record with an object `relay_file_rel` parks at jog's merge helper, no traceback.
- **R2-F2** → **H4** now asserts: the hook really committed source (`drifted.txt` in `git log`),
  the refusal line is attributed to the *post-approve* bind (after the approved event, GH-273
  order preserved), the `--result-file` receipt exists with `outcome != approved` and
  `reviewed_candidate: null`, and no green completion line was emitted. The requested mutation
  control was run and is recorded in `test/baselines/GH-505-negative-control.md` ("H4 — second-bind
  mutation control"): with the post-approve bind replaced by `pass`, H4 goes red on every assertion
  (exit 0, approved receipt, green emitted); restored, all six pass.
- **Window parity** → `_window()` now mirrors `${RTL_CITATION_WINDOW:-3}` + awk coercion exactly:
  unset/empty → 3; otherwise the leading signed-integer prefix, else 0 (`3.0` → 3, `1_0` → 1,
  `abc` → 0). The parity claim is narrowed to that policy in the docstring.
- **attest-stub** → asserts the token reads `done` after its claim/done and exits 3 otherwise, so
  a manufactured success can no longer silently lack a token.
- **Baseline report** → the I/J rows are labelled as source comparisons; A/C as observed base-driver
  runs; H as the observed first-gate breakage; H4 as the observed mutation control.
- **Plan** → the startup-refusal sentence corrected to match the disposition.
- **Evidence** → `TESTS-RESULTS/2026-09-08+GH-505/provenance.jsonl` + `validate.log.gz` are committed
  in this revision from the strict gate run at THIS head in the disposable clone (identity verified
  before and after), with the earlier runs (355/356 at `a2ce2755`, 356/356 at the round-1 fix
  commit) listed separately as history, not as the final result.

This is round 3 of 3. Set `STATUS: Approved` if the implementation is sound as committed;
otherwise list what remains, ranked.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
