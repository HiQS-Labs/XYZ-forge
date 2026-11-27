---
gh_issue: 1664
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1664
title: "GH-1664: Jog refuses a prepared packet whose cited evidence changed (OL-10 stale-evidence admission)"
status: "Captured; plan awaiting relay plan QA"
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
| Recon at base `52813e56f`; capture and plan written. | Relay plan QA (Codex), then build in `utils/py/jog_run.py` beside `hold_refusal`. |

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
   - It resolves the doc with `find_issue_doc(target, gh_num)`, the same doc Jog promotes and
     Marathon runs. If there is no doc or no contract heading, it returns `None`: preflight already
     refuses that case after the lease, as today.
   - It parses with `extract_contract`, catching `SystemExit` as `contract_probes_from_doc` does. An
     unparseable contract returns `None`, because preflight's exit 3 already parks it.
   - If `prepared_commit` is absent, it returns `None` and prints one note:
     `jog: GH-N stale-evidence check skipped: packet records no prepared_commit`. **Warn, not
     fail-closed. Reason:** every existing capture (start-task, express and legacy rows) records no
     preparation point. Failing closed would park every queued row at roll-out with no remedy except
     a hand edit, and it would break Acceptance 3. Without a recorded point there is no claim to go
     stale, and preflight's ref-pinned probe evaluation stays the freshness check. A packet that
     *does* record one is enforced fail-closed (below).
   - If `prepared_commit` is present but is not a 40-hex string, or does not resolve to a commit in
     the target repo (`target` joined with `target.repo`), it returns
     `stale-check-unavailable: <why>`. If `target.ref` does not resolve, or git fails, it also
     returns `stale-check-unavailable: <why>`. A check that cannot be made refuses, matching
     `hold_refusal`.
   - The cited paths are `artifacts` + `artifacts_new` + every non-`command` `fix_probes[].path`,
     deduplicated. Command probes cite no path field, so they are out of scope (non-goal). It runs
     `git diff --name-only <prepared_commit> <ref_commit> -- <paths>` in the target repo. This is
     a tree diff, so a squash, merge or parallel landing is all handled the same. Git pathspec
     handles the glob probe paths.
   - If anything changed, it returns
     `stale-evidence: cited paths changed since prepared_commit <12> (target.ref <ref> at <12>): a, b`.
     The paths are sorted, with at most 10 listed and the rest shown as `+N more`.
3. **Call it at the two existing pre-lease points.** Each call becomes
   `held = hold_refusal(...) or stale_evidence_refusal(...)`, reusing the same refusal handling:
   park with the reason, no lease, no promotion, no execution record, attempt count unchanged.
   `--simulate` stays exempt, as for holds. These are the only `jog_run.py` edits. They are confined
   to the admission path, away from the #1653 receipt-publication work.
4. **Refresh path (no new code).** A Conveyor refresh publishes the capture with a new
   `prepared_commit` (B). Then `jog retry N` followed by `jog run`, or `jog retry-build N`,
   re-admits the **same row**: no `jog add`, no new row, no reset. The attempt count then
   increments once, through the normal lease.
5. **Docs.** Conveyor Step 3 (record `prepared_commit`) and Step 6 (refresh rewrites it; the refusal
   names the changed paths). `relay-automation/CONTRACT.example.md` gets an annotation for the
   optional key. The Jog skill's admission text gets one line. A build-record line in the GH-1476
   doc points here. No #1400 scoreboard edit (OL-10 credit is the parent's call).

### Verification (existing suites only; no new suite or registry entry, GH-831)

- **Suite proof (red then green):** `test/gh280-jog-marathon-adapter.sh` gets cases G9–G11 after G8,
  reusing its fixture, `prepare_execution_target`, `jog_run_root` and `queue_status`. AGENTS.md *No
  new tests* allows editing an existing suite. The issue's Acceptance requires the proof in an
  existing Jog suite, so this is a case inside one, not a new file.
  - G9: `prepared_commit` = A, then commit a change to `src/feature.js` (a cited artifact) at B and
    advance `main` (the contract's `target.ref`). `jog run` must exit with the row
    `parked|stale-evidence: …src/feature.js…|0`, the output must say `not started: stale-evidence`,
    and there must be no execution ledger entry and no worker dispatch.
  - G10: refresh, so `prepared_commit` = B, committed, plus an unrelated file change committed after
    it. Then `jog retry 901` and `jog run` must lease the same row: exactly one `jog_queue` row for
    901, `attempt_count` 1, one execution, and a reason not starting with `stale-evidence`. This also
    covers Acceptance 3: unchanged cited files with an unrelated diff admit.
  - G11 (fail-closed control): `prepared_commit` set to a well-formed SHA that is not in the repo must
    give `parked|stale-check-unavailable: …|0`.
  - Existing G4 and later sections (no `prepared_commit`) must stay green. That is the "admits as
    before" regression.
  - **Red:** run the edited suite with `utils/py/jog_run.py` reverted to base. G9 and G11 must fail,
    because the row dispatches. **Green:** run it with the change. Both runs happen in a disposable
    full clone, and the outputs go under `TESTS-RESULTS/2026-11-27+GH-1664/`.
- **Disposable replay / Run A stale witness:** add a `stale-evidence` case kind to the existing
  Day 1 replay `TESTS-RESULTS/2026-11-25+GH-1476-day1/control.txt`. It is the same fixture as the
  GH-1476 holds cases and takes the clone as an argument. Steps: prepare at A, change the cited file
  at B, expect a 0-call refusal with the reason prefix `stale-evidence:` and an unchanged attempt
  count; then refresh `prepared_commit` to B, run `jog retry 901` and `jog run`, and expect 1 worker
  call, the same row and attempt 0→1. A wrapper `TESTS-RESULTS/2026-11-27+GH-1664/run-witness.sh
  <label> <clone>` writes a labelled log plus `provenance.jsonl`. Its `base` run is red, its
  `change` run is green, and the `change` log is the labelled stale witness Run A can cite.
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

- Risk: a packet cites a broad glob (`src/**`), so unrelated edits refuse it. The reason lists
  the paths, and the fix is a Conveyor refresh. This is intended conservatism.
- Risk: a `prepared_commit` from an unfetched branch refuses as unavailable. The reason says so.
- Rollback: revert the commit. The key is optional and ignored by every other reader, so reverting
  restores today's behaviour with no data migration. Parked rows recover with `jog retry`.

### Rating (2026-11-27)

`rated 70/55/50/65`. sev 55: a stale packet spends a real build attempt (out of 3) and reviewer time
on an out-of-date plan, and can land work against moved source; this is wasted or incorrect work,
not data loss. pri 70: OL-10 scoreboard item, item 4 of the #1657 batch. appeal 50 (neutral, no
operator value). effort 65: one helper, two call sites, docs, and one suite case. Recurrence: no
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
    "PROJECT/2-WORKING/GH-1476-RAW-TASK-PREPARATION.md",
    "TESTS-RESULTS/2026-11-25+GH-1476-day1/control.txt"
  ]
}
```
