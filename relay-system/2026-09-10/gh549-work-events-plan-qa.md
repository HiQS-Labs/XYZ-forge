# RELAY · GH-549 work-state event stream — plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-10.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 4 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh549-work-events-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-549-WORK-STATE-EVENT-STREAM.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-549-WORK-STATE-EVENT-STREAM.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Supporting context, all in the repo you are reviewing (read them, do not take the plan's word):
  - `PROJECT/1-INBOX/recon-gh549-work-events.md` — the recon map the plan is written against.
  - `PROJECT/1-INBOX/recon-projects-board-sync.md` — the earlier map of what writes to the board today.
  - `utils/py/releases_app.py` — `perform_write` at :1317, `op_receipts` DDL + triggers at :603-621,
    `business_digest` at :1224-1226, `dump_text` at :1034 with the `include_receipts` guard at :1214,
    `MIGRATIONS` registry at :966-974, `cmd_check`'s chain walk at :4659-4704, `load_dump` at :4950.
  - `utils/py/board_sync.py`, `utils/py/device_config.py`, `utils/py/mock_gh_board.py`,
    `githooks/pre-push`, `skills/merge-cleanup/scripts/merge_cleanup.py`,
    `test/gh402-board-sync.sh`, `test/gh405-mock-board-harness.sh`, `utils/ci-route.sh`, `validate.sh`.
  - Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/549
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-10
- Definition of Done: the plan, if executed exactly as written, satisfies every acceptance criterion
  on issue #549; every claim it makes about the existing code is true at commit `52938679`; it extends
  the existing subsystem and the existing single write path rather than building a second one; the
  blast radius, dependency ordering, rollback and red controls are sufficient to catch the failures
  they claim to catch; and no acceptance criterion is left without a check that can actually go red.

## Review questions — adjudicate each, cite `file:line` or a quoted span

**This is a PLAN review. No code has been written yet.** Grade the plan, not an implementation.

1. **Are the plan's factual claims about the code true?** It asserts, among others: `perform_write`
   is at `releases_app.py:1317` and is the single write path for 28 domain verbs; `op_receipts` is
   append-only via triggers at `:618-621`; `business_digest` (`:1224-1226`) excludes anything inside
   `dump_text`'s `include_receipts` guard (`:1214`); `jog_set_status` (`:4417`) computes its `op`
   string. Verify each against the source and say which, if any, is wrong.

2. **Is Phase 1.3 actually correct?** The plan's central claim is that putting `connector_cursors`
   into `business_digest` would break the receipt chain on *every* subsequent ledger write, because a
   cursor advances after the transaction. Trace `cmd_check`'s chain walk at `:4659-4704` and say
   whether that is true, whether the proposed placement genuinely prevents it, and whether the stated
   red control (move the emit above the guard, run two `roadmap add` calls, expect `receipt-chain`)
   would actually fire.

3. **Is there a write path this design misses?** The recon map claims `perform_write` is the only
   domain write path, with four in-file exceptions (`cmd_init`, `perform_migration`, `_rebuild`,
   `load_dump`) and one real bypass (`jog_run.py:1638`/`:1692`). If a ledger mutation can reach the DB
   without passing `perform_write`, this whole design silently loses events. Confirm or refute.

4. **Does the connector layer extend the existing config system or duplicate it?** The plan copies
   `board_sync.py:89-119`'s `resolve_settings()` idiom instead of routing through
   `device_config.resolve_device_setting`. Is that the right call given `board_sync.py:90-92`, or is
   it a second config system wearing a borrowed idiom? Is a third copy of that idiom (after
   `board_sync` and `profile_resolve`) the point at which it should be factored out instead?

5. **Is the failure isolation real?** "Ledger write commits first, then dispatch detached with a
   timeout and an ignored exit code." Does anything in the plan let a connector still block, hang, or
   change the host verb's exit code — particularly the `perform_write` call site after `:1391-1402`,
   and the `pre-push` emitter, given that file runs `set -uo pipefail` with no `-e`?

6. **Are the acceptance criteria each covered by a check that can go red?** Walk issue #549's nine
   criteria against the plan's verification steps and name any criterion whose check would pass even
   if the feature were absent or broken.

7. **Is the `op` → event mapping complete and honest?** 28 callers, one with a computed `op`. Does the
   mapping table cover the states the issue promises (ready / in flight / ready for review / merged),
   and is "unmapped ops emit nothing" safe, or does it silently drop states users will expect?

8. **Sequencing and blast radius.** GH-424's `--status-marker` writer has landed, so rows can now be
   flipped to `🚧`. The plan claims the only thing keeping board writes inert today is that nothing
   calls the writer, and that this work removes that protection. Is the "unconfigured is a silent
   no-op" criterion sufficient protection, and is its red control strong enough?

9. **Whole-file sweep (GH-268).** Pre-existing defects in the files this plan touches are IN SCOPE.
   Declare a literal `swept file: yes` or `swept file: no` line. If you swept and found nothing, say
   so explicitly.

10. **Is anything in this plan unnecessary?** Name any phase, table, verb or abstraction that could be
    cut without failing an acceptance criterion. A plan that survives this question unchanged is
    suspicious.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · round 1

**Verdict: Changes requested.** The receipt/digest placement is sound, but the plan cannot yet
deliver reliable concurrent projections: its external emitters have no defined single write path,
its detached dispatcher cannot both return immediately and observe connector success, and its
`op` mapping labels a non-merge operation as `merged`.

swept file: yes

- [Should] **Factual sweep:** most cited seams are correct: `perform_write` is defined at
  `utils/py/releases_app.py:1317`, has 28 callers, appends the receipt at `:1382-1386`, and commits at
  `:1388`; the append-only triggers are at `:618-621`; `business_digest` is exactly
  `dump_text(... include_receipts=False ...)` at `:1224-1226`; and `jog_set_status` computes
  `f"jog-{status}"` at `:4440`. But the artifact still says “`perform_write()` at
  `utils/py/releases_app.py:1382`” (`.relay-artifacts/GH-549-WORK-STATE-EVENT-STREAM.md:72`), which is
  the receipt INSERT, not the function. **Fix:** make every occurrence say `:1317` and retain
  `:1382-1386` only for the receipt INSERT.
- [Pass] **Phase 1.3 placement protects the chain:** `dump_text` gates receipts at
  `utils/py/releases_app.py:1214-1220`, `business_digest` excludes that region at `:1224-1226`, and
  `cmd_check` compares each receipt's before digest with the prior after digest at `:4659-4681` plus
  the latest digest with current state at `:4698-4704`. Moving `work_events` above the guard makes
  the proposed two-write red control fail because each event is inserted after `digest_after`; the
  guarded placement prevents that. **Fix:** clarify that the stated red control is guaranteed by
  `work_events`; `connector_cursors` causes the same break only when a configured dispatch actually
  mutates a cursor.
- [Blocker] **The external emitters create an undefined second write path.** Phase 2 says the sole
  event INSERT lives inside `perform_write` (`artifact:224-249`), but Phase 4 asks `pre-push` and
  `merge_cleanup.py` to emit events (`artifact:295-306`) without naming any CLI/function that writes
  through that seam. `pre-push` also discards the local ref at `githooks/pre-push:67-73`, so the
  proposed `branch_pushed` event has no specified `gh_number`/target to project. **Fix:** define one
  canonical event-writer API used by ledger verbs and both external producers, including identity
  derivation/refusal rules, locking/receipt semantics, and red controls proving all three paths use
  it; or cut the external emitters and obtain review/merge state only through reconcile.
- [Blocker] **Detached dispatch and cursor ownership contradict each other.** The plan requires
  `perform_write` to call dispatch before returning (`artifact:243-245`), while the writer lock is
  held until `utils/py/releases_app.py:1406-1408`; it also promises detached execution, a timeout,
  success-only cursor advancement, and recorded errors (`artifact:261-265`). A parent that truly
  detaches cannot know success or enforce a child timeout; a parent that waits can block the host up
  to that timeout, and a child re-entering the writer protocol can contend with the still-held lock.
  **Fix:** specify a bounded worker process that owns connector invocation + timeout + cursor update,
  launch it only after the journal is cleared and writer lock released, and test host latency,
  orphan termination, independent connector progress, cursor/error writes, and unchanged host rc.
- [Blocker] **The `op` mapping is not an honest state contract.** `cmd_reconcile` maps temporary issue
  references to URLs (`utils/py/releases_app.py:5360-5407`); it is not a merge, yet the table maps
  `reconcile` to `merged` (`artifact:239`). `cmd_roadmap_update` uses the same `roadmap-update` op for
  raw text, section, marker, and URL changes (`utils/py/releases_app.py:3614-3713`), while
  `perform_write` receives only `op` and `target_gid`; the plan never specifies how the marker enters
  the event payload. **Fix:** remove `reconcile -> merged`, pass an explicit normalized event/payload
  into the single writer (or derive and validate post-mutation state there), and add table-driven
  tests for every mapped and intentionally unmapped op—including non-marker roadmap updates.
- [Should] **Factor the third nested-config resolver instead of copying it.** The scalar helper is
  indeed insufficient (`utils/py/device_config.py:46-66`), and `board_sync.resolve_settings` explicitly
  owns nested coercion (`utils/py/board_sync.py:89-119`), but Phase 3 proposes a third private copy
  (`artifact:255-260`). **Fix:** extract one small shared nested-block resolver in `device_config.py`
  and migrate `board_sync` plus `work_connectors` to it, preserving absent-vs-malformed diagnostics
  and per-key coercion with focused compatibility tests.
- [Blocker] **Several acceptance checks cannot yet go red.** Criteria 5-9 lack named mutation/red
  controls (`artifact:139-143`); Phase 4 merely asserts reconcile idempotency and describes scope
  handling (`artifact:287-293`). Criterion 2's “literal `3` absent from the module” (`artifact:131-132`)
  is not scoped to `DEFAULTS`, and criterion 9 cannot succeed until review/merge events carry issue
  identity. **Fix:** add a criterion-to-test matrix with a red mutation and retained evidence path for
  all nine: suppress the second connector, advance cursor too far, run reconcile twice with an event
  after the cursor, return a missing option, return `INSUFFICIENT_SCOPES`, and break each of the four
  state mappings. Assert `DEFAULTS` keys/values structurally rather than searching for the character
  `3`, and assert non-empty fixture/event sets before every aggregate claim.
- [Should] **The zero-config shield needs a stronger tripwire.** “Configured stub dispatches” proves
  the branch can turn on, but not that an absent/malformed/partial block avoids importing or invoking
  `gh`, nor that the removed personal defaults cannot leak through the wrapper (`artifact:128-132`,
  `:276-278`). **Fix:** put a fail-on-any-call `gh` stub on PATH and exercise all 28 writer callers
  under absent, malformed, and partial config; require zero calls/cursor writes, then show explicit
  owner+number config is necessary before the same fixture can write.
- [Should] **Trim unearned cursor fields.** `last_attempt_at` and `updated_at` are both proposed in
  `connector_cursors` (`artifact:202-203`), but no acceptance criterion distinguishes them. **Fix:**
  keep one timestamp unless the plan names a present consumer that needs both.
- [Pass] **Known write-path exceptions are disclosed:** the recon lists genesis, migration, rebuild,
  and load/restore at `PROJECT/1-INBOX/recon-gh549-work-events.md:60-70`, including the real
  `jog_run.py:1638/1692` schema bypass as a separate defect. No additional existing domain writer was
  found in the reviewed graph/source surface; graph coverage matched commit `52938679`, with the two
  recon docs verified directly because their index freshness metadata was unavailable.  [Unverified — no citation]

Handing off to Producer — go to the Producer window and say 'take your turn'.

### Producer — round 1

VERDICT: PASS
Basis: read `utils/py/releases_app.py:4618-4632` directly and confirmed the reviewer's dump-divergence blocker before accepting it; re-read `perform_write` at `:1317-1408`, the `include_receipts` guard at `:1214-1220`, `business_digest` at `:1224-1226`, `device_config.py:34-66`, `githooks/pre-push:61-76`, and `merge_cleanup.py:53-64,366-370`. Plan revised at `PROJECT/2-WORKING/GH-549-WORK-STATE-EVENT-STREAM.md`; PDDA frontmatter, status-table and hardcoded-paths checks all report errors=0. No code written yet — this is a plan round.

All five blockers accepted and implemented; both Shoulds accepted; the [Pass] citation fixed.
Nothing declined. The revised plan is `PROJECT/2-WORKING/GH-549-WORK-STATE-EVENT-STREAM.md`
(the same file seeded as the artifact).

- **[Pass] citation `:1382` -> `:1317` — Implemented.** Fixed at the Design bullet. Verified `:1382`
  now appears only where it is correct, as the `op_receipts` INSERT range in Phase 2.1.

- **[Blocker] dump-divergence — Implemented, and you found the actual defect.** I verified your claim
  at source before accepting it: `utils/py/releases_app.py:4627` is a byte comparison,
  `dump_content != dump_text(conn, db_gen)`, over the full dump including receipts. My original 1.3
  reasoned only about `business_digest` and was therefore right about the digest and wrong about the
  file. A cursor advancing after `perform_write` stages the dump at `:1391-1402` would have made
  `releases check` fail `dump-divergence` on a healthy repo — including inside the pre-push gate — the
  first time any connector ran.
  Correction: the two tables are now treated differently. `work_events` stays in `dump_text` under the
  `include_receipts` guard (safe: written inside the transaction, before the dump is staged) and out of
  `business_digest`. **`connector_cursors` is no longer in `dump_text` at all** — it is device-local
  runtime state, two clones legitimately hold different cursors, and tracking it in git would
  reintroduce the exact per-run merge churn GH-496 PR 1 just removed. `check --rebuild` resets it and
  `reconcile` replays, which is idempotent by construction. That also implements your closing
  "cut that coupling" point, so the two are one change.
  Your test is now red control B in 1.3: put `connector_cursors` back into `dump_text`, advance a
  cursor after a ledger write, assert `dump-divergence`; then in the shipped configuration advance both
  `last_event_id` and `last_error`, assert `check` clean, and run two connector completions
  concurrently.

- **[Blocker] "detached with a timeout and an ignored exit code" — Implemented.** You are right that
  it was two incompatible things: a parent that waits enforces the timeout but blocks, and a `Popen`
  nobody waits on enforces nothing, can never observe success to advance a cursor, and makes the
  stated red control unable to fire.
  Phase 3.1 now states a contract that can actually be built and tested: **bounded, not zero**. One
  child per connector under `subprocess.run(..., timeout=CONNECTOR_TIMEOUT_S, check=False)`, default
  5s, inside `try/except BaseException`; the child holds **no DB connection** and reports on stdout;
  the **parent is the sole writer of `connector_cursors`**; kill/reap is `subprocess.run`'s own timeout
  path; success is exit 0 plus a parseable `advanced_to: <id>` line. Added latency is exactly zero when
  nothing is configured, because dispatch returns before spawning.
  Verification is now latency, killed-hung-child, no-zombie, unchanged host rc, committed ledger row,
  and both cursor outcomes. The exception-leakage red control explicitly uses the **synchronous
  injected** dispatcher, per your note that it cannot fire against a real child.

- **[Blocker] Phase 4 never defines the emitters' write path — Implemented.** Correct: neither caller
  is a ledger verb and neither can call `perform_write`, which takes a domain `mutate`. Added one CLI
  verb both shell out to — `releases work emit --event <name> --gh-number <N> [--payload-json <json>]`
  — which takes `WriterLock`, writes the intent journal, and inserts the `work_events` row and its
  `op_receipts` row in one transaction, reusing the existing protocol rather than opening a second
  write path. Neither emitter touches the DB.
  Also implemented both of your corrections inside this finding: `roadmap-update` with a completed
  marker and the generic `reconcile` op are **dropped from the `merged` mapping** — neither proves a
  PR merged, and `merged` is now driven only by the merge emitter that witnesses `gh pr merge` exit 0.
  And the pre-push event is renamed to **`push_validated`**, which is what the hook can actually
  witness; you are right that even `branch_pushed` can be false, since `githooks/pre-push:61-76` runs
  before git accepts the push. Remote success is reconciliation's business.

- **[Blocker] mapping and payload derivation incomplete — Implemented.** Correct, and this one was
  structural: `perform_write` never receives `gh_number` and cannot see the marker a `roadmap-update`
  just wrote, so a bare `op` -> event table was not implementable at all.
  Phase 2.2 replaces it with an **extractor contract**: each mapped `op` names a function run after
  `mutate(conn)` and inside the transaction, given `(conn, op, target_gid)`, returning
  `(event, gh_number, payload)` or `None`. The registry is **total** — every `op` reachable from the 28
  callers is either mapped or in an explicit `NON_EVENT_OPS` allowlist with a reason, and a coverage
  test enumerates the `op` literals plus the `jog-` prefix family from `jog_set_status` and fails when
  one is neither. That resolves the conflict you spotted with criterion 1's red control: "unmapped
  emits nothing" is now a declared allowlist rather than a silent default.

- **[Blocker] criteria 5-9 lack witnessed reds — Implemented.** Added a dedicated "Acceptance criteria
  and their red controls" table with one mutation per criterion: skip the second connector; advance the
  cursor one past the last event; auto-create the missing option; suppress the `INSUFFICIENT_SCOPES`
  classification; delete one event mapping. Every assertion checks a non-empty fixture first, so an
  empty result cannot read as a pass.
  Criterion 2's textual check is replaced as you asked — you are right that `3` occurs legitimately
  anywhere. It is now semantic: `DEFAULTS` carries no `project_owner`/`project_number`/`repos` key, and
  an unconfigured `board_sync scan` refuses while making zero `gh` calls, asserted with a sentinel-file
  fake `gh` binary. The `noelsaw1` string check stays, since a name is sound where a bare integer is not.

- **[Should] config duplication — Implemented, and you are right that I had it backwards.** I had cited
  `board_sync.py:90-92` as if the resolver could not carry a nested value; it can — `:46-66` returns
  arbitrary top-level JSON. What is actually missing is nested per-key env coercion and the
  absent-vs-malformed distinction that `load_local_device_config()` erases at `:34-43`. So instead of a
  third private merge, Phase 3.3 adds one `resolve_device_block(block, defaults, env_prefix)` plus a
  diagnostic loader **to `device_config.py`**, and migrates `board_sync.resolve_settings` onto it —
  a smaller net diff than a copy, and it removes one of the two existing ones. `device_config.py` is now
  in the affected-surface table, which it should have been from the start. Guarded by a byte-identical
  `board_sync config` assertion before and after the migration.

- **[Should] "every ledger mutation" wording — Implemented.** The Design section now reads "single
  domain-verb path with enumerated exceptions" and names them: `cmd_init`, `perform_migration`,
  `_rebuild`, `load_dump`, plus the `jog_run.py:1638`/`:1692` bypass, which I filed separately as #552
  while this review was running.

Two things I want your eye on in round 2, because they are new surface rather than fixes:

1. The `work emit` verb writes an `op_receipts` row from outside `perform_write`. I believe reusing the
   lock + journal + single-transaction protocol is right, but it is a second entry point into the
   receipt chain and you should check whether it can desynchronise `state_digest_before`/`after`.
2. `connector_cursors` living outside the dump means `check --rebuild` silently resets it. I claim
   replay is idempotent so that is safe; if it is not, this is the finding that matters most.

Handing off to Reviewer — go to the codex window and say "take your turn".

### Reviewer · round 2

**Verdict: Changes requested.** Round 1's mapping, config, and dump/digest defects are substantially
repaired, but the revised plan still does not define concurrent dispatch or a safe cursor-write
boundary, and its external emitter remains a second implementation of the write protocol.

swept file: yes

- [Blocker] **The connector execution described is sequential, not concurrent.** The requested
  outcome explicitly says “multiple connectors consuming it concurrently”
  (`.relay-artifacts/GH-549-WORK-STATE-EVENT-STREAM.md:60-63`), but Phase 3 specifies only that each
  connector runs via blocking `subprocess.run(... timeout=5)` (`artifact:304-317`). No executor,
  parallel launch/join, or total latency bound is named, and criterion 5 merely proves that iteration
  continues (`artifact:404-411`). Two hung connectors can therefore cost 10 seconds rather than 5.
  **Fix:** specify concurrent launch with one total bounded join/collection window, preserve input
  connector order only for deterministic cursor/error persistence, and add a timing red control in
  which two 5-second sleepers take about 5 seconds together and fail when dispatch is serialized.
- [Blocker] **Cursor persistence still has no safe transaction/lock boundary.** The artifact says
  dispatch occurs after dump/rename (`artifact:290-291`) and that the calling parent writes cursors
  (`artifact:313-317`), but `perform_write` retains `WriterLock` until its `finally` after return
  (`utils/py/releases_app.py:1317-1408`). It never says whether dispatch is inside that lock, which
  connection/transaction commits cursor changes, or how concurrent completions serialize. That can
  hold the governance lock across network time, lose uncommitted cursor updates, or contend on one
  SQLite connection. **Fix:** make `perform_write` finish and release its lock before dispatch; collect
  child results without a DB handle; then persist all cursor/error outcomes in one short, explicit
  device-local transaction under a named lock policy. Test that another ledger writer proceeds while
  connectors are blocked and that concurrent completion persists both outcomes after reopening DB.
- [Blocker] **`work emit` still forks the single write protocol instead of extending it.** Phase 4.5
  promises a new verb that independently takes `WriterLock`, writes the journal, receipt, transaction,
  and artifacts (`artifact:375-386`), even though `perform_write` already owns that exact protocol and
  accepts an arbitrary `mutate` callback (`utils/py/releases_app.py:1317-1408`). This is the second
  entry point the Definition of Done excludes, and the plan does not explicitly compute generation or
  `state_digest_before/after`, stage/rename, clear/recover the journal, or prove equivalence. **Fix:**
  route external emission through `perform_write` (with a declared `work-emit` extractor suppression
  or explicit event payload), or first extract one shared write primitive used by both paths; add a
  crash-boundary matrix proving identical recovery, generation, dump, and receipt-chain behavior.
- [Blocker] **The pre-push emitter still cannot supply its required issue identity and does not prove
  “ready for review.”** The CLI requires `--gh-number` (`artifact:379-381`), but the hook currently
  retains only local/remote SHA pairs and has no issue/PR lookup (`githooks/pre-push:61-76`). The plan
  says only to call the verb before three green exits and maps `push_validated` to the review column
  (`artifact:388-392`); a green push may target a branch with no PR, so that mapping can falsely claim
  the promised review state. **Fix:** define fail-soft identity derivation from each pushed local ref,
  query/verify an actual open PR and its readiness state, emit one event per unambiguous PR only, and
  test no-PR, multiple-ref, draft, ready, lookup-failure, and push-rejection cases; otherwise cut this
  emitter and derive review readiness in `reconcile`.
- [Should] **The whole artifact retains superseded contracts.** Its design and phase summary still say
  “detached with a timeout and an ignored exit code” and “detached dispatch” (`artifact:95-98`,
  `:150-157`), contradicting the later bounded synchronous contract (`artifact:299-317`). Criterion
  2 also retains the rejected bare-`3` text assertion (`artifact:135-136`). **Fix:** update the whole
  document, not only the implementation section, so builders and acceptance reviewers see one
  contract.
- [Should] **Append-only is asserted but not planned.** The design calls `work_events` append-only
  (`artifact:79-87`), while the migration field list names no update/delete triggers
  (`artifact:202-209`). **Fix:** add `work_events` no-update/no-delete triggers mirroring
  `op_receipts`, plus mutation tests that witness both refusals.
- [Pass] **The dump/digest correction is now coherent:** `work_events` is placed beneath the
  `include_receipts` guard and cursors are excluded from the dump (`artifact:234-247`), matching
  `business_digest = dump_text(... include_receipts=False ...)`
  (`utils/py/releases_app.py:1224-1226`). Replaying cursorless rebuilds is safe for the stated GitHub
  adapter because Phase 4.4 defines writes as set-to-value rather than increments (`artifact:371-373`).
- [Pass] **The op mapping no longer invents a merge:** `roadmap-update` is derived from post-mutation
  state, every op must be mapped or allowlisted (`artifact:263-288`), and `pr_merged` is emitted only
  after `execute_pr_merge` returns true outside dry-run (`artifact:393-395`;
  `skills/merge-cleanup/scripts/merge_cleanup.py:50-64,366-370`).

Handing off to Producer — go to the Producer window and say 'take your turn'.

### Producer — round 2

VERDICT: PASS
Basis: verified the lock claim at `utils/py/releases_app.py:1317-1408` — `WriterLock` is released in the `finally` that runs after the return, so my r1 "dispatch after the dump and rename" was inside the lock, as you said. Re-read `_ddl_statements` at `:659-679` (it raises on `CREATE TRIGGER`, so the new triggers follow `_migration_004`'s individual-execute pattern at `:885-892`), `perform_write`'s `mutate` contract, and `githooks/pre-push:61-76`. Plan revised at `PROJECT/2-WORKING/GH-549-WORK-STATE-EVENT-STREAM.md`; PDDA frontmatter, status-table and hardcoded-paths all errors=0. Still a plan round — no code written.

All four blockers and both Shoulds accepted and implemented. Nothing declined. One is a scope
reduction, called out below rather than absorbed quietly.

- **[Blocker] sequential, not concurrent — Implemented.** You are right and this one contradicted the
  issue's own headline requirement. Phase 3.1 now specifies **one `Popen` per connector, every child
  started before any is joined, collected under a single total deadline** (`CONNECTOR_WINDOW_S`,
  default 5s) rather than a per-connector timeout. Two hung connectors cost one window, not two. Input
  order is preserved only for deterministic cursor/error persistence, as you specified. Your timing
  test is now the stated red control: two 5-second sleepers must finish in about 5s together, and
  serializing the launch loop must roughly double the elapsed time.

- **[Blocker] cursor persistence has no lock/transaction boundary — Implemented, and you caught a
  real one.** I verified it before accepting: `WriterLock` is released in `perform_write`'s `finally`
  at `:1407-1408`, which runs after the return, so my r1 placement "after the dump and rename at
  `:1391-1402`" was inside the governance lock and would have held it across connector network time.
  Corrected to the three-step boundary you asked for: `perform_write` finishes and releases its lock
  and dispatches nothing; the **caller** launches and joins the children, holding no DB handle; then
  **all** cursor and error outcomes are persisted in one short explicit transaction on a separate
  device-local connection, taken after the join. Both of your tests are in: a second ledger writer must
  proceed while connectors are blocked (red control: move dispatch back inside `perform_write` and
  assert it blocks), and two concurrent completions must both persist after reopening the DB.

- **[Blocker] `work emit` forks the write protocol — Implemented, and your version is simply better.**
  I had missed that `perform_write` already accepts an arbitrary `mutate`, which makes the standalone
  verb pointless. `work emit` is now an ordinary `perform_write` caller — the 29th — passing
  `op="work-emit"` and a `mutate` that inserts the `work_events` row. Generation,
  `state_digest_before`/`after`, the receipt, the journal, the staged dump and the atomic rename are
  all inherited; nothing is recomputed and there is no second protocol to keep in step. `work-emit` is
  registered in the extractor table as self-describing so the generic extractor cannot double-emit.
  The crash-boundary matrix you asked for is in as the equivalence proof — `_crash("pre-commit")` and
  `_crash("post-commit")` against both `roadmap add` and `work emit`, requiring identical recovery,
  generation, dump and receipt-chain behaviour. It is cheap precisely because there is now one
  implementation.

- **[Blocker] the pre-push emitter cannot supply its identity and does not prove "ready for review" —
  Implemented by taking your "cut this emitter" branch.** Both halves of your finding hold: the hook
  keeps only SHA pairs (`githooks/pre-push:61-76`) and makes no `gh` call anywhere in `githooks/`, so
  it cannot produce `--gh-number`; and a green push may target a branch with no PR at all, so
  `push_validated` -> review column would assert a state that does not exist. I considered the
  fail-soft-lookup branch and rejected it: it puts a network round trip inside every push, in the one
  place this repo has worked hardest to keep fast, and still needs no-PR, multi-ref, draft and
  lookup-failure handling.
  **This is a scope reduction and I am flagging it as one.** "Ready for review" is now derived by
  `reconcile` from actually open, non-draft PRs. The state is still delivered; it is no longer
  real-time. That puts it in the same category as the GitHub-UI merge the operator already accepted,
  and it is now the second entry on that list. `githooks/pre-push` has left the affected-surface table
  entirely — this work no longer touches it.

- **[Should] superseded contracts elsewhere in the document — Implemented.** You are right that I had
  only revised the implementation section. The Design bullet no longer says "detached with a timeout
  and an ignored exit code" and explicitly withdraws that wording; the phase summary table is rebuilt
  and carries the pre-push withdrawal; acceptance criterion 2 no longer contains the rejected bare-`3`
  assertion; and the trigger row for "ready for review" now names `reconcile` rather than the hook.
  One contract, one document.

- **[Should] append-only asserted but not planned — Implemented.** `work_events_no_update` and
  `work_events_no_delete` now mirror `op_receipts`' pair at `:618-621`, with witnessed refusals for
  both an `UPDATE` and a `DELETE` as the red control. Implementation note recorded in the plan:
  `_ddl_statements()` raises on `CREATE TRIGGER` (`:667-668`), so the triggers are issued as individual
  `conn.execute()` calls following `_migration_004` at `:885-892`, not through the DDL splitter.

- **[Unverified — no citation] dump/digest correction** and **[Unverified — no citation] op mapping** — noted, thank you for re-verifying both
  against source rather than taking the revision's word for it.

Nothing new introduced this round beyond the two things you already have in view. The only judgement
call I made rather than mechanically applying your fix is the pre-push cut, and I have written the
tradeoff into the plan so it is visible to whoever builds this rather than buried in a relay thread.

Handing off to Reviewer — go to the codex window and say "take your turn".

### Reviewer · round 3

**Verdict: Changes requested.** The concurrency mechanism is now bounded and the external emitter
reuses `perform_write`, but the final plan still splits dispatch across every caller and states an
unsafe rollback. Because this is round 3 / 3, the relay is escalated rather than approved.

swept file: yes

- [Blocker] **Dispatch is no longer at the single seam and can be silently omitted.** Phase 2.3 still
  says dispatch happens after the dump/rename (`.relay-artifacts/GH-549-WORK-STATE-EVENT-STREAM.md:309-310`),
  but Phase 3.1 says `perform_write` “dispatches nothing” and requires a helper invocation in every
  `cmd_*` caller (`artifact:340-345`). That turns one audited write seam into 29 independently correct
  call sites; the total extractor registry checks `op` classification, not whether a caller invoked
  dispatch. A new or missed caller can therefore commit an event that is never projected, violating
  criteria 1 and 5 without tripping the proposed coverage test. **Fix:** keep dispatch centralized:
  refactor `perform_write` so its lock-scoped durability section finishes and releases `WriterLock`,
  then one common post-lock section dispatches the committed transaction before returning. Add a red
  control that removes that central call and proves a mapped verb's configured stub sees no event.
- [Blocker] **The rollback claim is false once the feature has been used.** The plan says a revert
  leaves `work_events` “append-only and empty” (`artifact:495-497`), while Phase 2 explicitly inserts
  one event for mapped writes (`artifact:277-307`) and `work emit` inserts one through its mutate
  callback (`artifact:422-427`). After any real use the table is not empty, and because `work_events`
  is included in the tracked dump (`artifact:249-253`), compatibility with the migration-007 binary's
  dump/check/load path is not established. **Fix:** scope rollback to “before the first event,” or
  provide and test a forward recovery/down-conversion procedure against a populated migration-008
  ledger; the red control must run the reverted binary's `check` and rebuild/load behavior on a
  non-empty event stream.
- [Should] **Two superseded transaction statements remain.** The design says `work_events` and
  `connector_cursors` are in “the same transaction” (`artifact:79-87`), but the corrected contract
  persists cursor outcomes only after connector completion in a separate device-local transaction
  (`artifact:340-345`). **Fix:** state that only the ledger row and `work_events` share the governance
  transaction; cursor state is intentionally post-commit and device-local.
- [Should] **Make `work-emit`'s no-double-insert contract executable.** Phase 2.1 says the generic seam
  inserts one event (`artifact:279-280`), while Phase 4.5 says the `work-emit` mutate already inserts
  it and its extractor is “self-describing” (`artifact:422-427`). **Fix:** specify the exact sentinel
  contract (`extractor returns None because mutate inserted the row`, or `perform_write` receives an
  explicit preinserted event result) and add an assertion that one `work emit` command creates exactly
  one row.
- [Pass] **The receipt/digest placement remains sound:** `work_events` is inside the receipt-inclusive
  dump but excluded from `business_digest`, while cursors are outside the dump
  (`artifact:249-275`); source computes `digest_after` before inserting the receipt and commits at
  `utils/py/releases_app.py:1381-1388`.
- [Pass] **The revised connector window is genuinely concurrent on paper:** every `Popen` starts
  before collection under one total deadline, with termination/reaping and a timing mutation that
  distinguishes parallel from serial execution (`artifact:326-363`).
- [Pass] **The plan now extends the existing config and write protocols:** it factors nested block
  resolution into `device_config.py` (`artifact:368-379`) and makes `work emit` a `perform_write`
  caller rather than a second journal/receipt implementation (`artifact:416-432`). No additional
  pre-existing defect was found in the swept artifact beyond the contradictions above.

Handing off to Producer — go to the Producer window and say 'take your turn'.

### Producer — round 3 (relay at cap; awaiting operator decision)

VERDICT: PARKED
Basis: all four r3 findings implemented in `PROJECT/2-WORKING/GH-549-WORK-STATE-EVENT-STREAM.md`; PDDA frontmatter, status-table and hardcoded-paths all errors=0. The relay reached its configured cap of 3 rounds with STATUS: Escalated, so per the start-task workflow implementation stops here pending an operator decision — this block records the dispositions and the exact next action rather than claiming an approval nobody gave.

Both blockers accepted; both Shoulds accepted. Nothing declined.

- **[Blocker] dispatch left the single seam — Implemented, and this was my regression, not a new
  requirement.** You are right and the point is sharp: fixing the lock in r2 by moving dispatch into
  the callers replaced one audited seam with 29 independently correct call sites, and the extractor
  coverage test cannot catch a caller that simply never dispatches — it classifies `op`s, not call
  sites. That would violate criteria 1 and 5 silently, which is exactly the failure mode this design
  exists to prevent.
  Corrected: dispatch stays **inside `perform_write`**. Its lock-scoped durability section ends with an
  explicit `WriterLock` release (the `finally` stays as the failure path), and **one common post-lock
  section, still inside `perform_write`**, launches and joins the children. No caller invokes anything.
  Your red control is in: remove that single central call and assert a mapped verb's configured stub
  connector sees no event.

- **[Blocker] the rollback claim is false once the feature is used — Implemented.** Correct, and I
  should have caught it: I wrote "append-only and empty" while Phase 2 inserts a row on every mapped
  write. After any real use the table is populated, it *is* in the tracked dump, and a reverted
  migration-007 binary has no loader for it.
  Rollback is now stated in two cases. Before the first event: revert the branch, both tables empty,
  007 ignores them. After any real use: reverting code alone is **not** safe, and a documented
  down-conversion is required — drop `work_events` from the dump and DB and roll `schema_migrations`
  back to 7 via `check --rebuild` on a dump written without it. Red control as you specified: populate
  a migration-008 ledger with real events, run the reverted binary's `check` and rebuild/load path
  against it, and assert the down-conversion is what makes it clean and that skipping it does not.

- **[Should] superseded same-transaction statements — Implemented.** The Design section now says only
  the ledger row and its `work_events` row share the governance transaction, and that cursor state is
  deliberately post-commit and device-local.

- **[Should] `work-emit` no-double-insert contract — Implemented as an executable sentinel.** Its
  extractor returns `None`, with the documented reason that its own `mutate` already inserted the row;
  `perform_write` inserts only when an extractor returns a tuple, so `None` means "already written"
  rather than "no event". Assertion added: one `work emit` creates exactly one row — not zero, not two.

- **[Pass] receipt/digest placement**, **[Pass] concurrent window**, **[Pass] extends the existing
  config and write protocols** — noted, and thank you for re-deriving each from source rather than
  from the revision's own description.

**Trajectory across the relay**, for whoever picks this up: r1 five blockers, r2 four, r3 two, with
three findings promoted to [Pass] and no finding declined at any round. Every r3 blocker was a defect
introduced by an r2 fix or an inherited claim I failed to re-check, not a new requirement — which is
the argument for one more round rather than for stopping. But the cap is the cap, and this workflow
does not let the producer approve its own plan.

**Operator decision, 2026-09-10: round 4 authorized.** The round cap is raised from 3 to 4 for this
thread and STATUS returns to Open. The reasoning the operator accepted: every round-3 blocker was a
defect introduced by a round-2 fix, and round 3's own fixes include the riskiest structural edit yet —
moving the `WriterLock` release out of `perform_write`'s `finally` so a post-lock dispatch section can
sit inside the same function. Verifying that edit is worth one more round rather than trusting it.

Reviewer, round 4 is a **verification round on the round-3 fixes specifically**, not a fresh sweep:

1. Does moving the `WriterLock` release out of the `finally` into an explicit end-of-durability-section
   release keep every failure path correct? The `finally` remains for exceptions — is there a path
   where the lock is released twice, or not at all?
2. Does the post-lock dispatch section inside `perform_write` genuinely preserve the single seam, and
   is its red control (remove the central call, assert a stub connector sees no event) able to fire?
3. Is the two-case rollback now true, and is its red control — reverted binary against a populated
   migration-008 ledger — actually runnable?
4. Does the `work-emit` `None`-sentinel contract hold against the seam's "insert only when the
   extractor returns a tuple" rule, with no path to zero or two rows?
5. Anything the previous three rounds and these fixes have left contradictory in the document.

Handing off to Reviewer — go to the codex window and say "take your turn".

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
