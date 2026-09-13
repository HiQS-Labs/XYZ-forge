---
title: "GH-592: express landings write the provenance receipt they already have and reconcile with --gate"
status: 2-WORKING
created: 2026-09-13
updated: 2026-09-13
owner: orchestrator
gh_issue: 592
source: https://github.com/HiQS-Labs/XYZ-forge/issues/592
doc_type: bugfix
complexity: 1
risk: 2
effort: 2
phases: 1
related:
  - "https://github.com/HiQS-Labs/XYZ-forge/issues/591 — umbrella: the post-merge reconciler actually lands"
  - "https://github.com/HiQS-Labs/XYZ-forge/issues/546 — PR-path producer (sibling)"
  - "https://github.com/HiQS-Labs/XYZ-forge/issues/584 — catch-up abort on unattributable rows (covers express closeout failures)"
  - "https://github.com/HiQS-Labs/XYZ-forge/issues/267 — express design: one registered suite, direct push"
non_goals:
  - Making express run the full validate.sh gate. That is the GH-267/GH-516 lane design; the receipt records what ran (`gate: express-suite`), it does not widen it.
  - Any change to check_provenance_receipts or the receipt matcher — the consumer already supports commit landings.
  - PR-path receipts (#546) and catch-up demotion (#584) — sibling issues under #591.
fix_probes:
  - python3 utils/py/express.py --help
  - python3 -c "import sys; sys.path.insert(0,'utils/py'); import express; assert hasattr(express, 'write_receipt')"
goal: >
  Every /express landing on development leaves a TESTS-RESULTS provenance receipt attributable to
  its commit, and its inline reconcile runs under the same --gate the PR path uses — so the one
  no-human-gate landing path is no longer the only one the receipt gate never inspects.
---

## Status

| What was just completed | What's next |
| --- | --- |
| Recon of express.py, wave_reconcile.py gate + commit-landing metadata, gh267/gh425 test harnesses; issue #592 filed; plan written | Codex plan QA (relay), then implement in `fix/gh592-express-receipt` |

## Observed (recon, base `58d6f05a`)

- `utils/py/express.py` `cmd_land` (~L547): Step 7 runs **the fix's registered suite only**; pushes
  `HEAD:development` with `XYZ_SKIP_PREPUSH=1` (~L600). Comment says "skip duplicate hook" — the hook
  would run the *full* gate, so this is a design bypass, not a duplicate.
- `closeout()` (~L621): ship → issue close → `persist_closeout("chore(releases): express ship …")` →
  `wave_reconcile.py --commit <sha> --root <root>` **without `--gate`** (~L667) →
  `persist_closeout("chore(pdda): express reconcile …")`. Fail-closed with an
  `express-reconcile-failed` tick. `cmd_resume` (~L895) repeats the reconcile call, also ungated.
- `persist_closeout` (~L718) commits only paths under `CLOSEOUT_ALLOWLIST_PREFIXES` /
  `CLOSEOUT_ALLOWLIST_FILES`; `TESTS-RESULTS/` is not in either → a receipt written today would be
  refused as an "unexpected dirty path".
- `wave_reconcile.py`: `fetch_commit_metadata` (~L362) gives commit landings `number = sha[:12]` and
  `mergeCommit.oid = sha`; `check_provenance_receipts` (~L415) matches a receipt's `commit` field
  against that oid (prefix-tolerant, ≥7 hex). **The consumer needs no change.** The gate is applied
  for any `landing` when `args.require_receipts` (~L1699), so `--commit … --gate` is a supported
  invocation. wave_reconcile refuses a dirty tree, so the receipt must be committed *before* the
  reconcile call — the existing ship-persist commit is that slot.
- Evidence: `git log -- TESTS-RESULTS` contains no receipt for any express landing
  (`b348d9af`, `e30ceb86`, `d1485bc9`). Receipt shape in use (PR path, hand-written):
  `{"timestamp","pr","case","command","rc","result","output","environment"}` in
  `TESTS-RESULTS/<YYYY-MM-DD>+GH-<n>/provenance.jsonl`.
- `test/gh267-express-skill.sh` drives a full hermetic landing against a fixture repo with a stubbed
  `wave_reconcile.py` (~L135) that enforces clean-tree + on-development but ignores `--gate`.
  `test/gh425-gate-provenance-pr.sh` unit-tests `check_provenance_receipts` directly with synthetic
  metadata and receipt files — the right place for the red control.

## Requirements → change (one subsystem, one writer: the express driver)

1. **Receipt writer** — new `write_receipt(root, sha, suite, issue, rc=0)` in `express.py`, called in
   `closeout()` after the push-reachability check and **before** the ship `persist_closeout`. Path:
   `TESTS-RESULTS/<YYYY-MM-DD>+GH-<n>-express/provenance.jsonl`, one appended line:
   `{"timestamp", "commit": <full sha>, "issue": N, "case": "express-landing", "gate": "express-suite",
   "command": "bash <suite>", "rc": 0, "result": "pass", "environment": "express driver, direct
   development push"}`. Same field names as existing receipts; `commit` is the identity the gate reads.
   Idempotent: skip the append if an entry with that `commit` already exists (resume path).
2. **Allowlist** — add `"TESTS-RESULTS/"` to `CLOSEOUT_ALLOWLIST_PREFIXES` so the ship transaction
   commits the receipt. No other path widening.
3. **Gated reconcile** — `closeout()` and `cmd_resume` pass `--gate` on the `--commit` call. `cmd_resume`
   also calls `write_receipt` first (idempotent) so an interrupted landing can still pass the gate.
4. **Truthful comment** — replace "skip duplicate hook" with the fact: the registered suite already
   ran; the full pre-push gate is bypassed by lane design (GH-267/GH-516) and the receipt says so.
5. **Tests**
   - `test/gh425-gate-provenance-pr.sh`: new case — a receipt produced by `express.write_receipt` for
     commit A passes `check_provenance_receipts` with commit-landing metadata for A (`number=A[:12]`,
     `mergeCommit.oid=A`) and **fails with code 6** for commit B. This is the red control.
   - `test/gh267-express-skill.sh`: after the happy-path `run`, assert the receipt file exists at the
     expected path, its line carries `"commit": <sha>` for the pushed commit and `"gate": "express-suite"`,
     and that the ship commit includes it. Teach the stubbed `wave_reconcile.py` to honor `--gate`
     (exit 6 unless a `TESTS-RESULTS/**/provenance.jsonl` line carries the sha) and add one negative:
     `WR_STRIP_RECEIPT=1` in the stub's environment deletes the receipt before checking → the landing
     fails closed with `express-reconcile-failed`. (Stub-only knob; no production code path.)
6. **CHANGELOG** entry; this doc → `3-COMPLETED` at closeout.

## Acceptance

- [ ] Red control witnessed in PR body: gh425 new case — express receipt for A → 0; same receipt vs
      commit B → 6 with `No provenance.jsonl or error_log.jsonl entry matches`.
- [ ] `test/gh267-express-skill.sh` green incl. receipt-present and receipt-stripped cases.
- [ ] `test/gh425-gate-provenance-pr.sh` green.
- [ ] Full gate green from a disposable clone; PR opened against development; no `XYZ_SKIP_PREPUSH`.
- [ ] Post-merge: the next real express landing shows `TESTS-RESULTS/<date>+GH-<n>-express/` and a
      gated reconcile in its output (recorded on #592 when it happens).

## Risks / rollback

- Risk: `persist_closeout` allowlist widening lets an unrelated dirty `TESTS-RESULTS/` file ride a
  closeout commit. Mitigation: express's landing TOCTOU check already refuses unqualified drift before
  push; the widening only affects the post-push closeout commits. Rollback: revert the one commit.
- Risk: `--gate` on resume for a landing that pre-dates this change (no receipt). Mitigation:
  `cmd_resume` writes the receipt (idempotent) before reconciling.

## Rating (RELEASES, 2026-09-13)

`rated 55/45/50/80` — pri 55: evidence gap on the least-reviewed landing path, part of an active
umbrella (#591); sev 45: no data loss or breakage, but the gate contract is silently unenforced for
3/3 express landings to date; appeal 50 neutral (no operator preference given); effort 80: ~40 lines
in one driver + two test extensions, consumer untouched. Recurrence: 3 express landings in the last
14 days, 0 receipts (100%); prior 14 days: lane did not exist.

## Lessons Learned (For Future Agents)

- "Skip duplicate hook" was a mislabel: the hook is the *full* gate, the lane runs *one* suite. Name
  bypasses as bypasses so the next reader does not inherit the wrong model.
- The receipt consumer already understood commit landings; the gap was purely on the producer side.
  Check the consumer before designing a producer.
