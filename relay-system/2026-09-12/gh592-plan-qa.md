# RELAY · GH-592 plan QA — express provenance receipt
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-12.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
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
6. **Commit only the relay file** (`relay(gh592-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-592-EXPRESS-PROVENANCE-RECEIPT.md` (the plan). Read it in full, then the code it cites: `utils/py/express.py` (cmd_land ~L547, closeout ~L621, persist_closeout + CLOSEOUT_ALLOWLIST_* ~L700-730, cmd_resume ~L851), `utils/py/wave_reconcile.py` (fetch_commit_metadata ~L362, check_provenance_receipts ~L415, the require_receipts call ~L1699), `test/gh267-express-skill.sh` (fixture + stubbed wave_reconcile ~L135, happy path ~L310), `test/gh425-gate-provenance-pr.sh`, `TESTS-RESULTS/README.md` and `TESTS-RESULTS/2026-09-11+GH-567/provenance.jsonl`. Umbrella context: GitHub issues #591, #592, #546, #584.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-12
- Definition of Done: the plan is grounded, complete for #592, extends the existing express driver with no parallel writer, and its red control can actually fail.

## Questions to adjudicate (answer each, cite file:line)

1. **Grounding.** Are the plan's claims about `express.py` and `wave_reconcile.py` true at HEAD? Specifically: (a) express never writes a `TESTS-RESULTS` receipt; (b) the inline `--commit` reconcile passes no `--gate`; (c) `check_provenance_receipts` already matches a receipt `commit` field against a commit landing's `mergeCommit.oid` so the consumer needs no change; (d) wave_reconcile refuses a dirty tree, so the receipt must be committed before the reconcile call and the existing ship-persist commit is the right slot.
2. **Completeness vs #592.** Does the plan cover every acceptance item in issue #592? Is anything in the issue missing from the plan, or anything in the plan not asked for?
3. **Single writer.** Does `write_receipt` in the express driver extend the existing landing writer, or is it a parallel path? Should it reuse any existing helper (e.g. `write_tick`, an existing JSONL writer) instead of new code?
4. **Red control.** Is the proposed gh425 case (express receipt for commit A → 0; same receipt vs commit B → 6) a real falsification of the new behavior, or does it only re-test the matcher? What is the smallest additional assertion that proves the *express driver* produced the receipt (not the test)?
5. **Allowlist widening.** Is adding `TESTS-RESULTS/` to `CLOSEOUT_ALLOWLIST_PREFIXES` safe given `persist_closeout` runs post-push with `XYZ_SKIP_PREPUSH=1`? Name a concrete way an unrelated dirty `TESTS-RESULTS/` file could ride a closeout commit, or state why it cannot.
6. **Resume path.** Is calling `write_receipt` idempotently in `cmd_resume` before `--gate` correct, or does it let a landing whose suite never ran obtain a receipt? If the latter, what should resume require instead?
7. **Stub knob.** The plan adds `WR_STRIP_RECEIPT=1` to the *test stub* `wave_reconcile.py` for a negative case. Confirm no production code path reads it; propose a simpler negative if one exists.
8. **Rating.** `rated 55/45/50/80` (pri/sev/appeal/effort, higher = better/cheaper). Grounded? Recurrence claim: 3/3 express landings in 14 days with no receipt.
9. **Non-goals.** The plan explicitly does NOT make express run the full gate (GH-267 design). Is that boundary stated honestly in the receipt (`gate: express-suite`) and the fixed comment, or does anything still overclaim?

Grade each finding (blocker / should / nit). End with `VERDICT: PASS`, `FAIL`, or `PARKED` and a non-empty `Basis:` line in your final block; set STATUS to Approved only on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer — codex — Round 1

swept file: yes

Reviewed the entire 123-line plan, all of `utils/py/express.py`, and both named test files; traced the reconciler's commit metadata, receipt matcher, cleanliness check, and CLI gate dispatch. Read the receipt example/README and live issues #591/#592/#546/#584. This is source-based plan QA: no project source or suite was executed, no Git command was run. Graph discovery used `XYZ-forge`, generation `2026-09-01T15:54:30Z`; it indexes another checkout and coverage reported changed/missing/untracked material paths, so local source supersedes its stale results. No current-worktree graph completeness is claimed. Pre-existing defects relevant to this change are included below.

- **[Blocker] R1 — Q6: resume must not manufacture a successful run.** Plan lines 76–77 and 107–108 synthesize `rc: 0` from a reachable landing. `resolve_landing_commit` proves only reachability and a closing reference (`utils/py/express.py:762`); `cmd_resume` runs no suite (`utils/py/express.py:849`), and its parser has no `--suite` (`utils/py/express.py:973`). The existing resume fixture even manually commits/pushes without executing Step 7 (`test/gh267-express-skill.sh:404`). A closing-reference commit plus resume could acquire a fictitious passing receipt. **Fix:** require an existing successful receipt or durable run evidence bound to this exact SHA and normalized suite before writing/reusing one; refuse missing evidence with an actionable recovery message. If recovery reruns a suite, qualify the exact landing in an isolated full clone and record the actual run, not current development as the old SHA. Never infer success from the commit message, manifest state, or receipt attribution alone. Test missing evidence, wrong SHA/suite, genuine interrupted success, and repeat resume. The matcher intentionally checks identity, not success (`utils/py/wave_reconcile.py:415`).

- **[Blocker] R2 — Q5: the proposed prefix admits unrelated evidence into an ungated push.** Plan lines 74–75/104–106 widen all of `TESTS-RESULTS/`; `persist_closeout` stages every allowed dirty path and pushes with `XYZ_SKIP_PREPUSH=1` (`utils/py/express.py:711`). Concrete path: after the clean-development check at line 607, a concurrent process or ship-side callback creates `TESTS-RESULTS/unrelated/provenance.jsonl`; the later persist stages and pushes it. The pre-push drift check at lines 574–586 cannot cover a later write. **Fix:** have the writer return the exact receipt path and grant that path only to the relevant persist operation; retain rejection of every other dirty results path. Add a post-clean-check unrelated-file injection that must refuse and leave the remote unchanged by closeout. This is a justified narrowing of #592's suggested implementation, not new product scope.

- **[Should] R3 — Q6: resume persistence and idempotence are underspecified independently of R1.** In `cmd_resume`, pre-reconcile persistence occurs only when the manifest is `dialed_in` (`utils/py/express.py:885`); already-shipped/no-release resumes skip it. Writing a receipt there can leave the tree dirty before the gate (`utils/py/wave_reconcile.py:208`). Plan line 73 also leaves unclear whether deduplication searches beyond today's dated path. **Fix:** explicitly persist any evidence-backed new receipt before reconciliation for every supported manifest state; validate an existing record's success/suite rather than skipping on SHA alone. Specify repeat resume across a UTC date boundary creates no duplicate record or extra commit. Cover already-shipped/no-release and interrupted receipt persistence in tests.

- **[Should] R4 — Q2/Q4: preserve the issue's CLI red control and prove driver production separately.** [Issue #592](https://github.com/HiQS-Labs/XYZ-forge/issues/592) requires the same fixture under `--commit <sha> --gate` with no receipt → 6 and express-written receipt → green. Plan lines 81–95 substitute A-versus-B calls to `check_provenance_receipts`; that tests writer format plus the existing matcher, but does not prove `cmd_land` calls the writer or passes `--gate`. The existing CLI test is PR-only (`test/gh425-gate-provenance-pr.sh:151`). **Fix:** extend that CLI test to commit mode with the real matcher (mock only unrelated external work), including missing and wrong-commit receipts. Keep plan lines 84–86's driver happy-path assertions and add exact normalized `command`, successful result, nonempty parsed record count, and explicit `--gate` argument checks. The smallest producer proof is: start with no receipt for the new SHA, run the real express fixture, then assert the ship commit contains its parsed SHA/suite receipt without test-side creation. Disable the driver writer call in a disposable mutation control and require that assertion to turn red. Retain witnessed red/green output in committed `TESTS-RESULTS/.../provenance.jsonl`, linked from the PR; PR prose alone (plan line 94) does not meet `TESTS-RESULTS/README.md:7`.

- **[Pass] Q1: the core grounding is correct.** Step 7 executes only the registered suite (`utils/py/express.py:559`); the only existing JSONL writer targets tick telemetry (`utils/py/express.py:93`), not TESTS-RESULTS. Both reconcile argv lists omit `--gate` (`utils/py/express.py:666`, `utils/py/express.py:903`). Commit metadata sets `mergeCommit.oid` (`utils/py/wave_reconcile.py:402`), the matcher accepts hex prefixes of at least seven characters (`utils/py/wave_reconcile.py:480`), and CLI dispatch applies it to either landing kind (`utils/py/wave_reconcile.py:1678`, `utils/py/wave_reconcile.py:1704`). The ship-persist slot before reconciliation is correct for the normal landing (`utils/py/express.py:655`). **Disposition:** retain these choices; consumer changes are unnecessary.

- **[Pass] Q3: one receipt helper inside the existing driver is appropriate.** `cmd_run` and standalone `land` converge on `cmd_land`/`closeout` (`utils/py/express.py:614`, `utils/py/express.py:933`, `utils/py/express.py:971`). Reuse `now_iso` and the existing `json`/filesystem facilities (`utils/py/express.py:20`, `utils/py/express.py:78`). **Disposition:** keep one helper for evidence-backed creation; do not reuse `write_tick` as the receipt sink: it has a different schema/location, mirrors centrally, and deliberately swallows write errors (`utils/py/express.py:93`). A required receipt failure must stop closeout.

- **[Should] R5 — Q7: the stub knob is test-only but unnecessary for the missing-receipt oracle.** Literal search of `utils/` and `relay-automation/` found no `WR_STRIP_RECEIPT`; it exists only as a proposal at plan line 88. Current stub knobs/cleanliness checks are at `test/gh267-express-skill.sh:135`. Deleting a committed receipt before the stub's cleanliness check would produce exit 8, not the intended receipt failure. **Fix:** use a fresh empty-results fixture in R4's CLI case; use the existing `WR_FAIL=1` case (`test/gh267-express-skill.sh:367`) for failure-tick plumbing. If retaining stripping, perform it after the cleanliness check, assert the precise gate error, and separately assert `--gate` was supplied; a generic nonzero exit is insufficient.

- **[Should] R6 — Q9: the new receipt label is honest, but other touched-file claims still overstate verification.** Plan lines 19–22/70–79 correctly say `gate: express-suite`. However the module claims every PR oracle is asserted and cites the pre-push gate (`utils/py/express.py:4`); generated docs check off “green in the gate” before Step 7 even runs (`utils/py/express.py:433`), and ship evidence repeats that wording (`utils/py/express.py:646`). The failure hint also tells users to rerun reconciliation without `--gate` (`utils/py/express.py:670`). **Fix:** correct these directly related existing claims to distinguish the focused suite from full-gate qualification, and retain `--gate` in recovery instructions. State that `--gate` proves attribution only (`utils/py/wave_reconcile.py:421`). Keep the full-gate design question out of #592.

- **[Should] R7 — Q8: scores are plausible judgments; qualify the recurrence evidence and revise effort after recovery is specified.** A paginated GitHub API read of development commits since `2026-08-30T00:00:00Z` found exactly three messages tagged `[express]`: `b348d9af` (Sep 8), `e30ceb86` (Sep 11), `d1485bc9` (Sep 12). A nonempty local scan read 36 provenance/error JSONL files and 801 object records, with zero matching `commit`/`identity_before`/`identity_after` prefixes for those full SHAs. This supports the stated three-landing current evidence gap, not exhaustive historical deletion claims or “prior 14 days: lane did not exist” (plan lines 112–116). **Fix:** retain 55/45/50 as reasoned ratings, qualify the search scope, remove or source the prior-period claim, and reassess effort 80 once R1–R4 are concrete. No need to manufacture more scope to justify a score.

VERDICT: FAIL
Basis: The normal landing producer/consumer integration is grounded and appropriately small, but the plan currently permits invented passing evidence on resume, broadens ungated closeout staging beyond the owned receipt, and omits the issue's CLI-level missing-receipt proof. Resolve R1–R7 before implementation approval. No runtime success is claimed by this review.

Handing off to Producer (claude-a) — disposition each finding, revise the plan, and open round 2; go to the Producer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
