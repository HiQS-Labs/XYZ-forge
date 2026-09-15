---
title: "GH-592: express landings write the provenance receipt they already have and reconcile with --gate"
status: Complete
created: 2026-09-13
updated: 2026-09-15
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
| Implemented and Codex-implementation-QA'd (3 rounds): all blockers resolved; receipt writer + committed-evidence reader + exact-path persist + gated reconcile + resume `--suite`; gh267 95/0, gh425 14/14; evidence in `TESTS-RESULTS/2026-09-13+GH-592/` | Operator decision on the Escalated relay (remaining items are shoulds on the documented recovery recipe), then full gate + PR |

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

Revised after Codex plan-QA rounds 1–2 (`relay-system/2026-09-12/gh592-plan-qa.md`, R1–R11).

1. **Receipt writer** — `write_receipt(root, sha, issue, suite, rc)` in `express.py`; stdlib JSON append,
   `now_iso` reused, errors **fatal** (not `write_tick`'s swallowed errors). Returns the receipt's
   repo-relative path. Called from `closeout()` **after** the clean-development check and reachability
   check and **before** the ship persist — so no cleanliness guard in `cmd_land`/`cmd_resume` is ever
   tripped by an untracked receipt, and the sha is known. `rc` is the real Step-7 result carried in
   `state` from the same process (never synthesized). (R1, R8)
   Path `TESTS-RESULTS/<YYYY-MM-DD>+GH-<n>-express/provenance.jsonl`; record:
   `{"timestamp", "commit": <full sha>, "issue": N, "case": "express-landing", "gate": "express-suite",
   "command": "bash <suite>", "rc": <int>, "result": "pass"|"fail", "environment": "express driver,
   direct development push"}`. `commit` is the identity the matcher reads; `gate` states what ran.
2. **One shared validation predicate** — `valid_express_receipt(rec, sha, issue, suite)`: `commit`
   equals the full sha, `issue == N`, `case == "express-landing"`, `gate == "express-suite"`,
   `rc` is int `0`, `result == "pass"`, `command == "bash <suite>"` (normalized). `find_receipt(root,
   sha, issue, suite)` scans every `TESTS-RESULTS/**/provenance.jsonl` and returns the path of the
   first record satisfying the predicate; malformed / failed / wrong-suite / wrong-issue records are
   ignored (they never count as evidence). Dedup is by predicate, not by path — a repeat resume across
   a UTC date boundary writes nothing. (R3, R9)
3. **Persist exactly the receipt** — `persist_closeout(root, message, extra_paths=())`; `closeout()`
   passes the returned receipt path to the ship persist only. No prefix widening; any other dirty
   `TESTS-RESULTS/**` path is still refused as "unexpected dirty path". (R2)
4. **Gated reconcile** — `closeout()` and `cmd_resume` pass `--gate`; on success the reconciler's stdout
   is printed (today it is captured and dropped) so the gate outcome is visible in the landing output;
   the failure hint says `wave_reconcile.py --commit <sha> --gate`. (R6, round-2 pass note)
5. **Resume never manufactures evidence** — `resume` gains a required `--suite` (the operator names the
   registered suite; no `--suite` today, so resume has no other trustworthy source of the expectation).
   `cmd_resume` calls `find_receipt(root, sha, issue, suite)`: if a **committed** valid receipt exists,
   proceed to `--gate`; if none exists, **refuse** before closing the issue or shipping, with the
   recovery recipe below. Resume writes no receipt and runs no suite. (R1, R9, R11)
   Recovery recipe (in the refusal message and SKILL.md): in a disposable full clone, `git checkout
   <sha>`, run `bash <suite>`, then from a clean `development` checkout of the same clone
   `python3 -c 'import sys; sys.path.insert(0,"utils/py"); import express;
   print(express.write_receipt(".", "<sha>", <issue>, "<suite>", <rc>))'`, commit that one file to
   development and push, then `express resume --issue N --sha <sha> --suite <suite>`. Same helper, same
   predicate, no new CLI verb, no parallel producer; the receipt records the actual rerun `rc`. (R11)
   **Identity check before issuing evidence (R12):** the recipe snapshots the clone's identity before
   and after `bash <suite>` — `git rev-parse HEAD`, `git status --porcelain`, `git remote -v`, and the
   sha256 of `git config --list --local` — and requires all four to be byte-identical afterwards; any
   difference (HEAD moved, dirt, a remote or local config/identity changed) voids the run and no
   receipt is written (a suite can mutate any of these and still exit 0 — AGENTS.md's
   attribution-failure rule). The four before/after values are written into `recovery-run.log`. The suite's stdout/stderr is saved beside the
   receipt as `TESTS-RESULTS/<date>+GH-<n>-express/recovery-run.log` and committed with it.
   Since the receipt is written after the clean check and immediately persisted, the only crash
   window that leaves an *uncommitted* receipt is between `write_receipt` and the ship persist; the
   resume cleanliness guard then reports it as dirt and the operator commits it (it is the exact
   receipt) — no guard relaxation is needed. (R8)
6. **Truthful wording in directly related lines** — module docstring L4–8 (registered suite + express
   qualification, not "every oracle a PR would have satisfied"); Step-7 comment ("bypass by lane
   design", not "duplicate hook"); docs template L433/L437 ("registered; green asserted at landing
   (Step 7)" — the scaffold is generated before the suite runs); ship evidence L646 ("registered suite
   green"); recovery hint with `--gate`; one sentence that `--gate` proves attribution, not test
   success. (R6, round-2 pass note)
7. **Tests**
   - `test/gh425-gate-provenance-pr.sh` — CLI commit-mode case in the existing in-process fixture
     (mock only unrelated external calls; the offline manifest declares **both** A and B): (a) empty
     `TESTS-RESULTS/` → `--commit A --gate --offline <m> --skip-pull --skip-branch-check --dry-run`
     exits 6 with the exact `No provenance.jsonl …` message; (b) `express.write_receipt` for A → passes
     the gate; (c) same receipt vs `--commit B` → 6 (B declared, so the matcher — not exit 4 — is
     reached). (R4, R10)
   - `test/gh267-express-skill.sh` — happy path: receipt exists; exactly one record whose
     `commit == <pushed sha>` and `case == "express-landing"` (per-sha, not per-file — GH-999 lands
     repeatedly in this suite); `command == "bash test/gh999-demo.sh"`, `rc == 0`,
     `gate == "express-suite"`; `git show --stat` of the ship commit lists the receipt. Stub
     `wave_reconcile.py`: asserts `--gate` in argv; after its cleanliness check, exits 6 unless a
     `TESTS-RESULTS/**/provenance.jsonl` line carries the `--commit` sha. Negative controls:
     (i) inject `TESTS-RESULTS/unrelated/provenance.jsonl` after the clean-development check → closeout
     refuses; remote `development` sha equals the post-fix-push sha (no closeout commits landed);
     (ii) **mutation control**: `write_receipt` monkeypatched to return the expected path **without
     writing** → the receipt assertion turns red and the stubbed gate fails closed with
     `express-reconcile-failed` (a `None` plumbing error cannot impersonate this);
     (iii) resume with no valid receipt → refused before issue close/ship, message contains the recipe;
     (iv) resume with a receipt that has `rc: 1`, or the wrong suite, or the wrong issue → refused;
     (v) genuine interrupted success: valid committed receipt, reconcile never ran → resume passes
     `--gate`, writes nothing, and a second resume is a no-op (no new record, no extra commit).
     `WR_STRIP_RECEIPT` is dropped. (R4, R5, R9, R10)
   - Witnessed output committed under `TESTS-RESULTS/<date>+GH-592/provenance.jsonl` and linked from the
     PR, per `TESTS-RESULTS/README.md`: CLI cases (a)–(c) **and** the driver-production pair — the
     normal fixture landing's created receipt, and mutation control (ii) reaching the missing-receipt
     assertion and the gated failure. Cases (a)–(c) alone could pass with `cmd_land` never calling the
     writer; (ii)'s retained output is what proves the driver produced it. (R4, R13)
8. **CHANGELOG** entry; this doc → `3-COMPLETED` at closeout.

## Acceptance

- [x] Red control witnessed and committed: CLI `--commit A --gate` with no receipt → 6; express receipt
      for A → passes; same receipt vs declared B → 6; plus the driver-production pair (normal landing
      creates the receipt; no-write mutation fails closed) — `TESTS-RESULTS/2026-09-13+GH-592/`.
- [x] `test/gh267-express-skill.sh` green (95/0) incl. controls (i)–(viii) and the docs `--suite` guard. `test/gh425-gate-provenance-pr.sh` green (14 tests).
- [ ] Full gate green from a disposable clone; PR opened against development; no `XYZ_SKIP_PREPUSH`.
- [ ] Post-merge: the next real express landing shows `TESTS-RESULTS/<date>+GH-<n>-express/` and the
      printed gated-reconcile outcome (recorded on #592 when it happens).

## Risks / rollback

- The receipt is written after every cleanliness guard and persisted in the very next commit, so the
  only crash window leaving an uncommitted receipt is between `write_receipt` and the ship persist;
  resume then reports exactly that file as dirt and the operator commits it. No guard is relaxed.
- No allowlist widening; the only new writable path in closeout is the exact receipt path.
- `resume --suite` is a new required argument: any existing operator recipe for `resume` must add it
  (SKILL.md updated). Rollback: revert the one commit.

## Rating (RELEASES, 2026-09-13; re-assessed after QA rounds 1–2)

`rated 55/45/50/70` — pri 55: evidence gap on the least-reviewed landing path, part of active umbrella
#591; sev 45: no data loss or breakage, but the gate contract is unenforced on this path; appeal 50
neutral (no operator preference given); effort 70: shared predicate, resume refusal + `--suite`, exact
path persistence and five negative controls beyond the first estimate. Recurrence evidence
(scope-qualified, attributed to the round-1 reviewer's search): the three `[express]`-tagged commits on
development since 2026-08-30 (`b348d9af`, `e30ceb86`, `d1485bc9`) have no matching `commit` in any of
the 36 committed provenance/error JSONL files (801 records). `b348d9af` (2026-09-08) is the earliest
landing in the inspected window; no claim is made about earlier periods.

## Lessons Learned (For Future Agents)

- "Skip duplicate hook" was a mislabel: the hook is the *full* gate, the lane runs *one* suite. Name
  bypasses as bypasses so the next reader does not inherit the wrong model.
- The receipt consumer already understood commit landings; the gap was purely on the producer side.
  Check the consumer before designing a producer.
