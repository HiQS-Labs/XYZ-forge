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
| Codex plan-QA round 1: 2 blockers (resume manufactured evidence; allowlist too wide) + 5 shoulds, all accepted and folded in | Codex round 2 on the revised plan, then implement in `fix/gh592-express-receipt` |

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

Revised after Codex plan-QA round 1 (`relay-system/2026-09-12/gh592-plan-qa.md`, findings R1–R7).

1. **Receipt writer** — `write_receipt(root, sha, suite, issue, rc)` in `express.py`, reusing `now_iso`
   and the same JSONL-append shape `write_tick` uses. Returns the receipt's repo-relative path.
   Called in `cmd_land` **immediately after Step 8's commit and before the push** — the sha is known,
   and `rc` is the real Step-7 result from this process (never synthesized). Path:
   `TESTS-RESULTS/<YYYY-MM-DD>+GH-<n>-express/provenance.jsonl`; line:
   `{"timestamp", "commit": <full sha>, "issue": N, "case": "express-landing", "gate": "express-suite",
   "command": "bash <suite>", "rc": <int>, "result": "pass", "environment": "express driver, direct
   development push"}`. `commit` is the identity `check_provenance_receipts` reads; `gate` states what
   ran (the registered suite, not the full pre-push gate). (R1)
   Dedup by **content, not path**: `find_receipt(root, sha)` scans every `TESTS-RESULTS/**/provenance.jsonl`
   for a line with `commit == sha` and `case == "express-landing"`; if found, return it and write
   nothing — so a repeat resume across a UTC date boundary creates no second record. (R3)
2. **Persist exactly the receipt, nothing else under `TESTS-RESULTS/`** — `persist_closeout(root,
   message, extra_paths=())`; `closeout()` passes the receipt path returned by the writer to the ship
   persist only. `CLOSEOUT_ALLOWLIST_PREFIXES` is **not** widened; any other dirty `TESTS-RESULTS/**`
   path is still refused as "unexpected dirty path". (R2)
3. **Gated reconcile** — `closeout()` and `cmd_resume` pass `--gate` on the `--commit` call; the failure
   hint (~L670) says `wave_reconcile.py --commit <sha> --gate`. (R6)
4. **Resume never manufactures evidence** — `cmd_resume` calls `find_receipt(root, sha)`; if none
   exists it **refuses** with: "no express receipt bound to <sha>; re-run `bash <suite>` at that commit
   in an isolated clone and commit its receipt to TESTS-RESULTS/, then resume". No suite is run and no
   receipt is written by resume. If the receipt file exists but is uncommitted (interrupted between
   commit and push), resume persists it via `persist_closeout(..., extra_paths=[receipt])` before
   `--gate`, for **every** manifest state (dialed_in / shipped / no release). (R1, R3)
5. **Truthful wording in directly related lines** — module docstring L4–8 ("every oracle a PR would
   have satisfied" → the registered suite + express qualification, not the full gate); Step-7 comment
   ("skip duplicate hook" → bypass by lane design); docs template L433 ("green in gate" → "registered
   suite green"); ship evidence L646 (same); `--gate` in the recovery hint. Add one sentence to the
   `--gate` line: it proves attribution, not test success. (R6)
6. **Tests**
   - `test/gh425-gate-provenance-pr.sh` — new **CLI** commit-mode case: temp repo with an offline
     manifest declaring commit A; (a) empty `TESTS-RESULTS/` → `wave_reconcile.py --commit A --gate
     --offline <m> --skip-pull --skip-branch-check --dry-run` exits 6 with the `No provenance.jsonl …`
     message; (b) a receipt produced by `express.write_receipt` for A → passes the gate; (c) the same
     receipt vs commit B → 6. This is the red control the issue asks for. (R4)
   - `test/gh267-express-skill.sh` — happy path: assert the receipt exists, its parsed record has
     `commit == <pushed sha>`, normalized `command == "bash test/gh999-demo.sh"`, `rc == 0`,
     `gate == "express-suite"`, exactly one record, and `git show --stat` of the ship commit lists it.
     Stub `wave_reconcile.py` asserts `--gate` is in argv and, **after** its cleanliness check, exits 6
     unless a `TESTS-RESULTS/**/provenance.jsonl` line carries its `--commit` sha (mirrors the real
     matcher's identity check). Negative controls: (i) inject `TESTS-RESULTS/unrelated/provenance.jsonl`
     after the clean-development check → closeout refuses, remote unchanged; (ii) **mutation control**:
     run the driver with `write_receipt` monkeypatched to a no-op (`python3 -c "import express; …"`) →
     the receipt assertion turns red and closeout fails closed with `express-reconcile-failed`;
     (iii) resume with no receipt → refused with the recovery message; (iv) resume with an uncommitted
     receipt → persisted, gate passes, second resume writes nothing. `WR_STRIP_RECEIPT` is dropped. (R4, R5)
   - Witnessed red/green output of (a)–(c) committed under `TESTS-RESULTS/<date>+GH-592/provenance.jsonl`
     and linked from the PR, per `TESTS-RESULTS/README.md`. (R4)
7. **CHANGELOG** entry; this doc → `3-COMPLETED` at closeout.

## Acceptance

- [ ] Red control witnessed and committed: CLI `--commit A --gate` with no receipt → 6; express receipt
      for A → passes; same receipt vs B → 6.
- [ ] `test/gh267-express-skill.sh` green incl. unrelated-file refusal, mutation control, resume-refuses,
      resume-persists cases. `test/gh425-gate-provenance-pr.sh` green.
- [ ] Full gate green from a disposable clone; PR opened against development; no `XYZ_SKIP_PREPUSH`.
- [ ] Post-merge: the next real express landing shows `TESTS-RESULTS/<date>+GH-<n>-express/` and a
      gated reconcile in its output (recorded on #592 when it happens).

## Risks / rollback

- Receipt written between commit and push: if the process dies there, the fix commit is local-only and
  the receipt is a dirty untracked file; `resume` today refuses an unpushed sha
  (`resolve_landing_commit`), so the operator pushes and resumes — the receipt is then persisted (item 4).
- No allowlist widening; the only new writable path in closeout is the exact receipt path the writer
  returned. Rollback: revert the one commit.

## Rating (RELEASES, 2026-09-13; re-assessed after QA round 1)

`rated 55/45/50/70` — pri 55: evidence gap on the least-reviewed landing path, part of active umbrella
#591; sev 45: no data loss or breakage, but the gate contract is unenforced on this path; appeal 50
neutral (no operator preference given); effort 70 (was 80): resume refusal + exact-path persistence +
CLI red control add ~2 test cases and one helper beyond the first estimate. Recurrence evidence
(scope-qualified): the three `[express]`-tagged commits on development since 2026-08-30 (`b348d9af`,
`e30ceb86`, `d1485bc9`) have no matching `commit` in any of the 36 committed provenance/error JSONL
files (801 records scanned by the reviewer). The lane's first landing is `b348d9af` (2026-09-08), so no
earlier period exists to compare; no claim is made about deleted history.

## Lessons Learned (For Future Agents)

- "Skip duplicate hook" was a mislabel: the hook is the *full* gate, the lane runs *one* suite. Name
  bypasses as bypasses so the next reader does not inherit the wrong model.
- The receipt consumer already understood commit landings; the gap was purely on the producer side.
  Check the consumer before designing a producer.
