---
gh_issue: 1664
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1664
title: "GH-1664: Jog refuses a prepared packet whose cited evidence changed (OL-10 stale-evidence admission)"
status: "Captured; plan QA at cap (4 rounds), consult tie-break pending"
created: 2026-11-27
updated: 2026-11-27
doc_type: bug
owner: Claude
goal: At Jog admission, before the lease, refuse a prepared packet whose cited files changed since it was prepared; a Conveyor refresh re-admits the same row.
effort: 1
complexity: 2
risk: 2
phases: 1
---

# GH-1664 · stale-evidence admission refusal (OL-10)

Canonical discussion: [Issue #1664](https://github.com/HiQS-Labs/XYZ-forge/issues/1664).
Parent: [#1476](https://github.com/HiQS-Labs/XYZ-forge/issues/1476) (admission plan). Scoreboard:
#1400 (OL-10; read only, not touched here). Engineering batch: #1657 (item 4).

## Status

| What was just completed | What's next |
|---|---|
| Plan QA rounds 1–4 (Codex) FAIL at the 4-round cap; every finding folded in (R1–R4). | Consult tie-break at the cap, then build in `utils/py/jog_run.py` beside `hold_refusal`. |

## Acceptance

- [ ] A packet prepared at commit A, whose cited target files change at commit B, is refused at Jog admission on B. The refusal names the reason and the changed paths. The row stays pending/held with its attempt count unchanged.
- [ ] After the packet is refreshed through Conveyor at B, the same row admits and dispatches. No duplicate row exists and the attempt budget is unchanged.
- [ ] A fresh packet with unchanged cited files admits as before (no regression).
- [ ] The red-then-green proof sits in an existing Jog/preflight suite.

## Observed problem (recon, base `52813e56f0abd76cd3ba277602cc3e7fdf1e6f90`)

- `PROJECT/2-WORKING/GH-1476-RAW-TASK-PREPARATION.md:32` records OL-10's stale/held admission
  refusal as open. The held half is built: `utils/py/jog_run.py:1663` `hold_refusal`, called
  before the lease in the `jog run` loop (`jog_run.py:3071`) and in `_jog_retry_build_locked`
  (`jog_run.py:1114`). A refusal there parks the row with the reason (`jog_set_status`,
  `releases_app.py:5106`), which leaves `attempt_count` alone; only `jog_acquire_lease`
  (`releases_app.py:5097`) increments it.
- Nothing compares a packet's evidence with the current source. Preflight's exit 4 (`STALE`)
  means probes say the fix already landed; Jog then marks the row `completed`. It is not an
  evidence-age check.
- What a packet records today: the capture's `## Swarm Preflight Contract` JSON
  (`target.repo`, `target.ref`, `fix_probes[].path`, `artifacts`, `artifacts_new`), parsed by
  `swarm_preflight.extract_contract` (`swarm_preflight.py:96`). The shape validator
  (`contract_shape_error`, `swarm_preflight.py:61`) ignores keys it does not know. Conveyor
  (`skills/1-hourly/conveyor/SKILL.md` Steps 1 and 6) pins the fetched integration SHA and puts
  the "reviewed commit and evaluated integration SHA" in its issue marker comment as prose. That
  comment is not machine-readable and needs a network lookup, so no packet field records the
  preparation point today.
- Same-row recovery already exists: `jog retry N` (`releases_app.py:4938`) sets a parked row back
  to `pending` and keeps `attempt_count`. `jog add` of an existing row resets `attempt_count` to 0
  (`releases_app.py:4770`), which is why the refresh path must not use it. `jog retry-build N`
  also re-admits a parked row through `_jog_retry_build_locked`.

## Plan (smallest viable bet)

Outcome sought: Jog does not spend a build attempt on a plan whose cited files moved after the
plan was written. The operator gets a precise reason and the row survives untouched for refresh.

1. **Record the preparation point in the existing contract.** Add one optional key to the capture's
   contract JSON: `"prepared_commit": "<full 40-hex SHA>"`. This is the integration-ref commit the
   preparer's recon and probes were grounded at (Conveyor Step 1's fetched SHA). The contract can
   hold it without containing its own commit ID. No parser, packet schema or DB change: both
   validators already ignore unknown keys. Conveyor Steps 3 and 6 and the `CONTRACT.example.md`
   annotations document it. A refresh re-grounds the work and rewrites it to the newly fetched SHA.
2. **`stale_evidence_refusal(target, gh_num)` in `jog_run.py`, directly after `hold_refusal`.**
   It returns a reason or `None`:
   - **(R1 B1) It checks every capture that either selector could execute,** not one pick.
     Preflight `--gh-issue` takes the first `PROJECT/2-WORKING/GH-N-*.md` glob match
     (`swarm_preflight.py:1439–1446`). `find_issue_doc` can return `None` on a tie
     (`wave_reconcile.py:1129–1144`). `hold_refusal` already enumerates that set:
     `find_issue_doc_candidates` (2-WORKING, 1-INBOX), the 2-WORKING glob, and the canonical pick
     (`jog_run.py:1687–1698`). That enumeration moves into one small shared helper,
     `_admission_captures(target, gh_num)`, which both refusals call. The hold behaviour is
     unchanged; it is a pure extract. A stale or unavailable verdict on **any** capture refuses.
     A capture with no contract heading, or an unparseable contract, is skipped, because preflight
     already refuses those after the lease, as today.
   - It parses with `extract_contract`, catching `SystemExit` as `contract_probes_from_doc` does.
   - If `prepared_commit` is absent **in a capture**, that capture is skipped with one note
     (`jog: GH-N stale-evidence check skipped: <capture> records no prepared_commit`), and the scan
     continues to the other captures (R2 Pass note: a legacy sibling cannot end the scan). **Warn, not
     fail-closed. Reason:** every existing capture (start-task, express and legacy rows) records no
     preparation point. Failing closed would park every queued row at roll-out with no remedy except
     a hand edit, and it would break Acceptance 3. Without a recorded point there is no claim to go
     stale, and preflight's ref-pinned probe evaluation stays the freshness check. A packet that
     *does* record one is enforced fail-closed (below).
   - **(R1 B2) Same root and revision as Preflight.** The repository is the execution root `target`,
     the same `SWARM_PREFLIGHT_ROOT`/`--target-root` Jog hands Preflight (`jog_run.py:644–647`).
     Python Preflight ignores `target.repo` (`swarm_preflight.py:1412–1418`), so this check does
     too. Preflight runs `git fetch --prune --quiet` in that root and then resolves `target.ref`
     (`swarm_preflight.py:1519–1521, 1560–1561`). This check runs the same fetch first, only when
     a capture records `prepared_commit`, so legacy rows make no new network call. It then resolves
     `target.ref` the same way, so it compares against the commit Preflight will evaluate seconds
     later. **(R2 B1)** A nonzero fetch refuses before the lease with
     `stale-check-unavailable: fetch failed in <target>`. A failed fetch could otherwise leave a
     cached ref at A and an empty diff, and Preflight treats `fetch_ok == 0` as BLOCKED, exit 6
     (`swarm_preflight.py:1639–1641, 1940–1943`), but only after the lease. The remaining window is
     a landing between the two successful fetches; at this scale that is accepted, and the next
     admission catches it.
   - If `prepared_commit` is present but is not a 40-hex string, or does not resolve to a commit in
     `target`, it returns `stale-check-unavailable: <why>`. If `target.ref` does not resolve, or
     git fails, it also returns `stale-check-unavailable: <why>`. A check that cannot be made
     refuses, matching `hold_refusal`.
   - **(R1 S2) The cited paths use the consumer's literal semantics.** They are `artifacts`
     (which includes the `artifacts_new` subset) plus every non-`command` `fix_probes[].path`,
     deduplicated. Each is passed as a `:(literal)<path>` pathspec, normalized the way Preflight
     reads it. **(R2 B2)** Artifact strings are `.strip()`ped, as Preflight does before its
     existence check (`swarm_preflight.py:1586–1593`); blank results are dropped. Probe paths are
     kept literal and unstripped, as `eval_probes` reads them (`swarm_preflight.py:257–282`).
     Command probes cite no path field, so they are out
     of scope (non-goal). It runs `git diff --name-only <prepared_commit> <ref_commit> -- <paths>`
     in `target`. This is a tree diff, so a squash, merge or parallel landing is all handled the
     same.
   - If anything changed, it returns
     `stale-evidence: cited paths changed since prepared_commit <12> (target.ref <ref> at <12>): a, b`.
     The paths are sorted, with at most 10 listed and the rest shown as `+N more`.
3. **Call it at the two existing pre-lease points.** Each call becomes
   `held = hold_refusal(...) or stale_evidence_refusal(...)`, reusing the same refusal handling:
   park with the reason, no lease, no promotion, no execution record, attempt count unchanged.
   `--simulate` stays exempt, as for holds. These edits, plus the `_admission_captures` extract,
   are the only `jog_run.py` changes. They are confined to the admission path, away from the #1653
   receipt-publication work.
4. **Refresh path (no new code).** A Conveyor refresh publishes the capture with a new
   `prepared_commit` (B) to the integration branch. **(R2 S2)** The execution clone must then carry
   the published capture: a supervised `jog run` aligns its target first (`_jog_align_target`),
   while a hand-supplied `--target-root` clone has to be updated (pull or re-provision) before
   recovery. `retry-build` reads the supplied clone before the lease without aligning it
   (`jog_run.py:1114`), so a clone still holding the A-stamped capture refuses again, with the same
   named reason. Then `jog retry N` followed by `jog run`, or `jog retry-build N`, re-admits the
   **same row**: no `jog add`, no new row, no reset. **(R4 B1) Recovery verb:** the documented and
   witnessed recovery is `jog retry N` followed by `jog run`. Only the run loop promotes a
   `1-INBOX` capture before Preflight (`jog_run.py:3091–3103`). `jog retry-build N` calls
   `run_marathon_phase` without promotion (`jog_run.py:1114–1127`), and Preflight `--gh-issue`
   searches only `2-WORKING` (`swarm_preflight.py:1433–1446`). So `retry-build` re-admits a refreshed
   packet only when its capture is already in `2-WORKING`. That limit is pre-existing, applies to
   every retry-build, and is not changed here; Conveyor and the Jog skill name `jog retry` + `jog run`
   as the stale-refusal recovery. **(R3 S1, R4 S1) Ref precondition:** the check compares against
   exactly the commit Preflight's probes evaluate (`target.ref` after the same fetch). It does not
   pin the commit Marathon later branches from: Marathon creates or switches the lane from the
   execution clone's checkout (`marathon_drive.py:3365–3367, 3421–3434`). The claim is limited to
   "the evidence matches the ref Preflight judged ready". For a local-branch `target.ref` such as `development` on a hand-supplied target, a fetch
   moves only `origin/development`. So the operator must bring the local branch current (a
   supervised run does this through `_jog_align_target`) before admission. Otherwise both the check
   and Preflight judge the stale local commit, and a cited change that exists only upstream goes
   unseen until the branch is updated. Conveyor and the Jog skill state this precondition. The attempt count then increments once,
   through the normal lease. The Conveyor and Jog skill text states this handoff.
5. **Docs.** Conveyor Step 3 (record `prepared_commit`) and Step 6 (refresh rewrites it; the refusal
   names the changed paths). `relay-automation/CONTRACT.example.md` gets an annotation for the
   optional key. The Jog skill's admission text gets one line. A build-record line in the GH-1476
   doc points here. No #1400 scoreboard edit (OL-10 credit is the parent's call).

### Verification (existing suites only; no new suite or registry entry, GH-831)

- **Suite proof (red then green):** `test/gh280-jog-marathon-adapter.sh` gets cases G9–G11 after G8,
  reusing its fixture, `prepare_execution_target`, `jog_run_root` and `queue_status`. AGENTS.md *No
  new tests* allows editing an existing suite. The issue's Acceptance requires the proof in an
  existing Jog suite, so this is a case inside one, not a new file.
  - **(R1 S1) Fixture discipline.** A/B commits are made on the primary fixture `$FR` *before*
    `jog_run_root` re-clones the execution target, so the target sees them. Moving `main` (the
    contract's `target.ref`) is restored to `$INIT_HEAD_R` immediately after each case's last run,
    not only at the end of the section, because `cleanup_root_fixture` resets `development` but not
    `main` (`test/gh280-jog-marathon-adapter.sh:230–236`).
  - G9: `prepared_commit` = A, then commit a change to `src/feature.js` (a cited artifact) at B and
    advance `main`. `jog run` must leave the row `parked|stale-evidence: …src/feature.js…|1` (the seeded spent attempt, unchanged; R3 B1), the
    output must say `not started: stale-evidence`, and there must be no execution ledger entry
    (no lease, no preflight, no worker).
  - **(R2 S1) Budget witness.** Before G9's refusal, the row is seeded with `attempt_count = 1`
    (one prior spent attempt, written with a single `sqlite3 UPDATE`, as G6 already does for
    `status`). G9 must leave it at 1, it must still be 1 right after `jog retry`, and it must be 2
    after G10's dispatch. A `jog add` substitution resets it to 0, which fails the count
    assertion.
  - **(R2 B2) Padded artifact.** G9's capture lists the artifact as `" src/feature.js "` (padded).
    The probe stays on the unchanged `notes/landing-note.txt`, and only `src/feature.js` changes.
    The refusal must still name `src/feature.js`.
  - **(R1 B3) G10, positive dispatch after refresh.** Refresh so `prepared_commit` = B, committed,
    plus an unrelated file change committed after it. Then `jog retry 901` and `jog run` with G4's
    environment (canned PR, suggested lane branch, approving agent stubs). The assertions: the same
    `global_id` as before the refusal; exactly one `jog_queue` row for 901; `attempt_count` 2 (seeded 1 + this lease; R3 B1); the
    ledger holds exactly one execution with `outcome == "approved"`; the row is
    `parked|awaiting-landing (PR #42`, as in G4; and the stub builder's artifact edit is present in
    the target. A preflight refusal or a missing capture cannot satisfy those, unlike the round-1
    predicates. This also covers Acceptance 3: unchanged cited files with an unrelated diff admit
    and dispatch.
  - G11–G13 run from a clean fixture with no seeded attempt, so their expected count is the
    unchanged starting `0`.
  - G11 (fail-closed control): `prepared_commit` set to a well-formed SHA that is not in the repo must
    give `parked|stale-check-unavailable: prepared_commit … not found…|0` and no execution.
  - **(R1 B2) G12, fetched-ref parity.** The contract's `target.ref` is `origin/main` and
    `prepared_commit` = A. The execution clone is prepared while the fixture remote's `main` is at A.
    The cited file then changes at B on the fixture remote only, and Jog runs directly, without
    re-cloning. The check must fetch as Preflight does, see `origin/main` at B, and park with
    `stale-evidence: …src/feature.js…|0` and no execution. Without the fetch it would read A and
    dispatch.
  - **(R2 B1) G13, failed fetch.** This is G12's setup with the execution clone's existing
    `gh280.fixtureRemote` pointed at a nonexistent path, so the stubbed fetch fails while
    `origin/main` still resolves to A. The row must park with
    `stale-check-unavailable: fetch failed…|0` and no execution. Restoring the remote and re-running
    after `jog retry` gives G12's `stale-evidence:` refusal. No git-stub change is needed.
  - Existing G4 and later sections (no `prepared_commit`) must stay green. That is the "admits as
    before" regression.
  - **Red:** run the edited suite with `utils/py/jog_run.py` reverted to base. G9, G11 and G12 must
    fail, because the row is leased and dispatches. This proves the base run reaches the worker.
    **(R4 S2)** G13 has its own red oracle: on base, the lease is spent (`attempt_count` 1) and an
    execution record is written, then Preflight reports BLOCKED (exit 6) on the failed fetch and Jog
    parks with `preflight-refused (exit 6)`, with no worker call. G13's count, reason and no-execution
    assertions must therefore fail on base. **Green:** run it
    with the change. Both runs happen in a disposable full clone, with outputs under
    `TESTS-RESULTS/2026-11-27+GH-1664/` and `provenance.jsonl`.
- **Disposable replay / Run A stale witness (R2 S3):** the archived Day 1 control is **not** edited.
  It is copied to `TESTS-RESULTS/2026-11-27+GH-1664/control.txt` and a `stale-evidence` case kind is
  added to the copy, so the GH-1476 receipts keep their bytes. The copy's sha256 and its source sha
  go in the new `provenance.jsonl`. The copy keeps the same fixture and takes the clone as an
  argument. It seeds `attempt_count = 1`, like G9. Steps: prepare at A, change the cited file
  at B, expect a 0-call refusal with the reason prefix `stale-evidence:` and an unchanged attempt
  count; then refresh `prepared_commit` to B, run `jog retry 901` and `jog run`, and expect exactly
  1 refresh worker call (counted from the append-only call log), the same `global_id`, one row and
  attempt 1 → 1 on refusal → 2 after the dispatch. **(R1 S1)** For this case kind, the control exits nonzero when either assertion
  fails. There is no new wrapper script: the exact env and command lines are recorded in
  `provenance.jsonl`. The `base` log is red, the `change` log is green, and the `change` log is the
  labelled stale witness Run A can cite.
- **Smoke (GH-1088):** the main path is the replay's `jog run` refusal. The adjacent path is
  `jog retry-build 901` on the same stale packet (also refused, same row), then a re-admit after the
  refresh.
- **Final gate:** the classified route for a `utils/py` + `test/` change, i.e. the full gate through
  the push hook from a disposable qualification clone.

### Non-goals

- No marker-comment parsing, reviewer-identity attestation, managed-admission opt-in block or
  `relay_attest` binding. Those belong to the superseded R1/R2 designs in the GH-1476 doc.
- No staleness for command-probe scripts, or for files the capture's prose cites but the contract
  does not list.
- No change to preflight's exit-4 meaning, Conveyor's readiness label or the jog schema, and no
  automatic `jog retry`. The operator or Conveyor's handoff names the recovery verb.
- No #1400 scoreboard edit and no #1418 change.

### Alternatives rejected

- *Derive the preparation point from the last commit that touched the capture* (`git log -1 -- capture`).
  It needs no new key, but any capture edit (a typo, a status table, a promotion commit) would
  silently re-anchor the check and mask real staleness. An explicit key changes only when a
  preparer deliberately re-grounds the work.
- *Parse the Conveyor marker comment.* It is prose, needs a network call at every admission, and
  the GH-1476 R2 design shows that making it trustworthy needs author/PR/receipt verification. That
  is out of commensurate scope.
- *Fail closed on a missing `prepared_commit`.* Rejected; reasons above.

### Risks and rollback

- Risk (R2 B2): cited paths are literal, as Preflight reads them. A glob-looking artifact string
  matches only a file with that literal name, so it neither over-refuses nor expands. A packet
  that cites a directory refuses on any change beneath it; that is intended conservatism, and the
  reason lists the paths.
- Risk: a `prepared_commit` from an unfetched branch refuses as unavailable. The reason says so.
- Rollback: revert the commit. The key is optional and ignored by every other reader, so reverting
  restores today's behaviour with no data migration. Parked rows recover with `jog retry`.

### Rating (2026-11-27)

`rated 70/55/50/65`. sev 55: a stale packet spends a real build attempt (out of 3) and reviewer time
on an out-of-date plan, and can land work against moved source; this is wasted or incorrect work,
not data loss. pri 70: OL-10 scoreboard item, item 4 of the #1657 batch. appeal 50 (neutral, no
operator value). effort 65: one helper plus a pure extract, two call sites, docs, five cases (G9–G13) in an existing suite and a copied replay; still about one day of work (R2 note). Recurrence: no
distinct stale-dispatch incident was found in the last 14 days versus the prior 14 (prior-art scan:
0 matching issues/PRs). Trend unknown, not zero; the gap is known by inspection (GH-1476:32).

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "./validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/py/jog_run.py", "pattern": "def stale_evidence_refusal" }
  ],
  "artifacts": [
    "utils/py/jog_run.py",
    "test/gh280-jog-marathon-adapter.sh",
    "skills/1-hourly/conveyor/SKILL.md",
    "skills/2-daily/jog/SKILL.md",
    "relay-automation/CONTRACT.example.md",
    "PROJECT/2-WORKING/GH-1476-RAW-TASK-PREPARATION.md"
  ]
}
```
