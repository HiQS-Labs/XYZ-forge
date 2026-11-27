---
gh_issue: 1637
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1637
title: "Factory review loop: 4-round default and consult tie-break at the cap instead of stalling"
status: Complete
created: 2026-11-26
updated: 2026-11-27
owner: start-task implementation child (Flywheel Day 2, ledger #1610)
doc_type: feature
ratings_provisional: true
non_goals:
  - Changing the push gate, red-then-green, or operator merge (all kept)
  - The legacy Bash relay-drive.sh path (`XYZ_PYTHON=0`); it keeps its stall-at-cap behavior
  - `utils/py/jog_run.py` `_jog_task_local_failure` area (owned by the #1633 child)
  - Counting TESTS-RESULTS-only repairs as progress (`relay_drive.py` RECEIPT_DIRS); the consult tie-break supersedes it
  - A new test suite or runner (GH-831)
goal: >
  A factory phase whose reviewer still has open findings at the round cap no longer stalls with no PR:
  one Codex+agy consult adjudicates the findings, and the phase either continues to the real gate and a
  ready PR recorded as `Consult-Adjudicated` (distinct from `Approved`), takes one repair, or holds for safety.
---

# GH-1637 · Factory review loop: 4-round default and consult tie-break

## Status

| What was just completed | What's next |
|---|---|
| Plan QA 4 rounds (cap, 0 open Blockers); implemented; manual checks 25/25 and 9/9; existing suites green. | Final Codex QA, then the push gate and the ready PR. |

## Problem

Factory loops (Jog -> Preflight -> Marathon -> relay-drive) stall with no PR when the reviewer still has open
findings at the round cap (#1610: GH-1315 stalled after one review; a contract `round_cap: 2` is **turns**, not rounds).
A stall yields no forward progress while the real safety net (exact-head gate, red-then-green, operator merge) never runs.
Operator decision (2026-11-26, on the issue): the goal is net forward progress.

## Acceptance

- [x] Default factory review budget is 4 rounds: `max_review_rounds` default 4 (cap 9) in `relay-automation/marathon.sh`, and the `marathon_drive.py` default `round_cap` 9; the docs that state the old default are updated.
- [x] `relay_drive.py --consult-at-cap` (default off; `marathon_drive.py` passes it). When the cap is reached, no progress extension is available, the lane is non-terminal and not escalated, and at least one reviewer turn in this run appended a non-empty review block (the existing `review_blocks_added` predicate), the driver runs one consult (`consult.sh --models codex,agy`, `CONSULT_ROOT` = the target repo) pinned to one captured candidate SHA (`CONSULT_PIN_SHA`: the advisors' worktree is cut at that SHA, no stash of working changes, no untracked-file copy), over the diff against the integration merge-base, the relay file (open findings plus the builder rebuttal) and requires each advisor to end with exactly one `ADJUDICATION: NON-BLOCKING|REAL|SAFETY` line.
- [x] A complete result is required: both advisors answered `[ok]`, each with exactly one `ADJUDICATION:` line that is the last non-blank line of the answer, outside any code fence (a withdrawn, fenced, repeated or malformed verdict is no verdict). A missing, failed, partial, malformed or conflicting answer, or an empty diff, is a named hold (`consult-inconclusive`); any `SAFETY` is a hold (`consult-hold`).
- [x] Both `NON-BLOCKING` -> the driver itself records `STATUS: Consult-Adjudicated` (a driver-authored block linking both answers) and attests through the existing `judge_terminal`, in this order: driver-run gate first, then the token close (ordinary `tick` claim/release/done, passed in as a callback), then publication. Which gate runs: the focused gate when Marathon armed one (`MARATHON_REVIEWER_GATE_CMD`); otherwise (default or explicit full suite) there is none before `done`, and the real gate is Marathon's existing pre-advance gate, which runs after the attested terminal and before any PR or advance exactly as it does for `Approved`, with the existing red-gate escalation (recorded: `pre-advance-failed`, no approved outcome, no PR) and `--retry` recovery. A red focused gate or a refused close restores the previous STATUS and leaves the token open, so the lane stays recoverable; a publication failure after `done` is the existing spent-token case (fresh `--relay-task` via `marathon.sh --retry`) with the attestation record and trailer carrying an `adjudication` provenance field; exit 0. A reviewer or builder turn that writes `Consult-Adjudicated` itself is reverted as forged.
- [x] Any `REAL` (none `SAFETY`) -> exactly one repair, ending on a reviewer turn: the driver appends the findings, hands the token to the builder when the reviewer was next, and grants +2 turns (builder, reviewer), once, and the ordinary progress extension is off once the consult is spent, so the lane ends after exactly those turns whatever the reviewer records, and an early reviewer approval is impossible before the repaired SHA exists; a second cap escalates as today.
- [x] `Consult-Adjudicated` is not `Approved`: `_merge_reviewed_pr` (the one shared Jog merge boundary, refusing exactly this status; `Closed` and `Approved` keep their current eligibility) and `express.py` refuse it, and the push qualification path (`gate_receipt.py`) is unchanged, so landing stays an operator action; the lane PR body, the phase QA comment and the multi-phase closeout summary state `consult-adjudicated` and link both answers instead of "Approved by reviewer". The links must resolve from the published PR: the driver embeds each advisor's verdict line and a bounded excerpt of its answer in the consult block of the committed relay transcript and in the attestation record, and the lane PR body and phase QA comment render those excerpts inline (no shared archive needed); the multi-phase `--closeout-pr` summary is labelled from a one-line-per-phase file `marathon-drive` appends to (`MARATHON_ADJUDICATED_FILE`), which exists on that entry point without the progress result file.
- [x] The existing acceptance recheck still runs on the adjudicated candidate: with a fix probe, a still-unfixed candidate with two `NON-BLOCKING` stubs exits `acceptance-probes-unmet` before PR publication and a fixed one advances. A probe-less lane gets exactly the assurance the `Approved` path gives it today (reviewer judgement plus the gate); the consult prompt tells advisors that a diff which does not deliver the brief is `REAL`, and an empty **deliverable** diff is a hold, where deliverable means changed paths outside the harness receipt dirs and the phase's own `RELAY.md` (the existing `commits_touch_non_receipt(merge_base, head)` predicate), with the transcript still shown separately in the prompt. No new eligibility rule.
- [x] Default-off preserved: with the flag absent, `hard_cap` stays `round_cap * 2` and every existing direct caller and the `gh115-round-cap` suite behave as today (the Marathon fixture has no completed reviewer turn, so it still ends `cap-stalled`). With the flag, `hard_cap = round_cap + 2` (plus the one repair grant).
- [x] Verified by existing suites (`gh115-round-cap` and the attestation, marathon and jog suites that cover the touched seams) plus a recorded manual check under `TESTS-RESULTS/2026-11-26+GH-1637/`: stub-advisor runs for adjudicated, REAL-then-repair (at cap 9 and cap 2), SAFETY hold, one-advisor-missing hold, the unfixed-candidate negative control, a red focused driver gate after two `NON-BLOCKING` answers (STATUS restored, token still open) and, separately, a red pre-advance gate (the token is already done and the receipt keeps `Consult-Adjudicated`; the outcome is `pre-advance-failed`, not approved, no PR), an immediately-approving reviewer stub after `REAL` (builder dispatched first), a dirty-tree pin check (advisor reads the candidate's value, not the working tree's), the Approved / Closed / Consult-Adjudicated `_merge_reviewed_pr` triple (the first two reach the candidate checks, the third returns before any merge call), a refused token close, a refused handoff release and a refused reviewer claim (each: STATUS restored, token open to its original holder, no attestation), a receipt-write failure after `done` (no attestation, token spent; `marathon.sh --retry <phase-id>` is the existing recovery and is not exercised here), a mixed Approved/adjudicated `--closeout-pr` summary with progress disabled, a transcript-only candidate (only `RELAY.md` changed) that holds, a duplicate-verdict / quoted-token / missing-`[ok]` parser trio, a forged `Consult-Adjudicated` from a turn, and the default-off run.

## Decisions on the issue's notes

- `hard_cap = round_cap * 2`: replaced by `round_cap + 2` **only with `--consult-at-cap`** (the consult path supersedes long extensions); unchanged otherwise.
- TESTS-RESULTS-only repair not counting as progress (`relay_drive.py` RECEIPT_DIRS, GH-976): **Rejected (Out of Scope / Ponytail)**; the issue note says "count evidence repairs", and the operator's brief for this task ("Consider the issue's notes ... decide them with the leanest change") delegates that tradeoff, so the leanest change is the consult-at-cap, not a second progress rule. An evidence-only repair that makes no non-receipt change now reaches the consult at the cap instead of stalling, which removes the stall without reopening GH-976's transcript-commit thrash.
- "Contract templates that write round_cap": no code or skill writes one; the values in capture docs are hand-written explicit operator turn counts (`swarm_preflight.py:155` only validates them). They stay explicit; a short cap now ends in the consult instead of a stall.

## Recon note

- **Baseline:** `origin/development` `961cac652`.
- **Cap loop:** `utils/py/relay_drive.py` `main()`; `hard_cap = args.round_cap * 2` at `:1017`; progress extension and final `cap-stalled` / `cap-progressing-extended` escalation at `:1415-1436`. Progress is `commits_touch_non_receipt` or a resolved `[x]` item (`:764`; `TESTS-RESULTS/` is a receipt dir, GH-976).
- **Attestation:** `judge_terminal` (`:~810-1000`) is the one writer of the trailer and record; it needs a reviewer-role turn, runs `MARATHON_REVIEWER_GATE_CMD` itself on an approval, checks the token is `done`, and writes `record["status"]`. `relay_attest.TERMINAL = ("Approved","Closed")` (`relay_attest.py:28`) gates `load()`.
- **Terminal readers:** `marathon_drive.py:2553` (`terminal_status`), `relay_drive.py:556`. Others (`poll.py`, `check_marathon_qa.py`, legacy Bash) are the hands-free poll loop, a PDDA lint and the Bash fallback; left alone.
- **Existing consult path:** `--consult-verify` in `relay_drive.py` (`:1238`) already shells to `consult.sh`; the new path reuses `consult_sh` and the `[ok]`/`[FAIL]` result rows but NOT its loose parse: the adjudication parse is the strict one in the Acceptance list (one final `ADJUDICATION:` line per named `[ok]` advisor; a duplicate, a token only in quoted text, or a missing `[ok]` for either advisor is `consult-inconclusive`). The consult-entry SHA and the transcript preimage taken at that boundary are the `pre` snapshot passed to `judge_terminal`, not the latest ordinary turn's.
- **Cap writers:** `marathon.sh:587` (`rounds="${rounds:-2}"`, cap `2N+1`), `marathon_drive.py:3072` (`args.round_cap = 5`). Preflight contracts carry an explicit hand-written `round_cap` (`swarm_preflight.py:155`); that is an operator value and stays, but a short cap now ends in a consult rather than a stall.
- **Why a new STATUS word and not `Closed`:** `Closed` is already written by reviewers and accepted everywhere as done; reusing it would make an adjudicated phase indistinguishable from a reviewer close. The marathon result receipt already records `relay_status`, so the new word is visible in the receipt for free.
- **Preflight Bet Check:** outcome = no zero-progress stall; smallest bet = one opt-in tie-break in the existing driver; rejected = a new adjudication subsystem, a second attestation writer, and changing `Approved` semantics; rollback = drop the flag from `marathon_drive.py` (default-off elsewhere), revert the default.

## Plan (ordered, verification inline)

1. `relay_attest.py`: `ADJUDICATED = "Consult-Adjudicated"` added to `TERMINAL`; `trailer_text` prints an `adjudication:` line when the record has one; `load()` checks its shape. Verify: a stub record loads; existing attest suites stay green.
2. `relay_drive.py`: `--consult-at-cap`; `hard_cap` rule; `reviewer_turns_done` counter; `consult_adjudicate()` (captures one candidate SHA, prompt, `consult_sh` run with `CONSULT_ROOT` = target repo and `CONSULT_PIN_SHA`, strict parse of both answers, outcome adjudicated/real/hold); `judge_terminal(..., adjudicated=False, close_token=None)` so only the driver path may produce the new word, an ordinary turn writing it is reverted as forged, and the token close runs after the gate; token helpers (claim/release to the reviewer or builder as needed, claim/done as the reviewer); `actor = args.reviewer` for the record. Verify: the stub-advisor matrix in the acceptance list.
3. `marathon_drive.py`: `terminal_status` reads `relay_attest.TERMINAL`; default `round_cap` 9; passes `--consult-at-cap`; `lane_pr_notes`, the phase QA comment and the `marathon.sh --closeout-pr` summary (from the phase result evidence) name the adjudication and link both answers while keeping the completion count; success text derives from the attested status. `marathon.sh`: default 4 rounds. Docs: `MARATHON.example.yaml` and `marathon.sh` comments, `relay-automation/README.md` (then regenerate the packaged tarball with the existing `make-pkg.sh`, so `test/relay-pkg-freshness.sh` stays green).
4. `jog_run.py`: `_merge_reviewed_pr` returns before any merge call when the record's status is exactly `Consult-Adjudicated` (`Approved` and `Closed` keep reaching the same candidate checks as today; one hunk, away from `_jog_task_local_failure`). `express.py` already requires `Approved`.
`consult.py`: honor `CONSULT_PIN_SHA` (use it as the worktree base and skip the untracked-file copy) in the existing isolation path.
6. Run the existing suites and write the manual-check receipt (acceptance list); the unfixed-candidate control reuses the existing acceptance recheck.

## Verification (2026-11-26, disposable clone `-verify`)

- Manual checks, recorded under `TESTS-RESULTS/2026-11-26+GH-1637/` (README, logs, `provenance.jsonl`): `manual_check.sh` 40/40 (real `relay_drive.py` + real `consult.sh`, stub advisors) and `manual_check_marathon.sh` 11/11 (real `marathon_drive.py` end to end, the acceptance unfixed/fixed control, a red pre-advance gate, and a mixed multi-phase closeout summary through the real `marathon.sh`). Not exercised: `marathon.sh --retry` after a spent token (unchanged GH-116 behavior).
- Real-code bugs found by running it, all fixed: a function-local `import tempfile` shadowing the module in `main()` (first run); final-QA findings, a loose verdict parse that adjudicated on a withdrawn/fenced/malformed verdict, a repair ceiling that an ordinary extension could pass, and a refused release leaving the driver's claim on the token.
- Existing suites green on the final code: `gh115-round-cap`, `gh505-relay-attest`, `gh509-gate-evidence`, `relay-pkg-freshness` (tarball regenerated), `gh308-consult-guards`, `gh589-consult-no-tick`, `gh648-l3-consult-cap`, `gh376-relay-drive-lock-parity`, `marathon` (one pin edited deliberately: a phase with no `max_review_rounds` now gets cap 9, was 5), `gh267-express-skill`, `marathon-closeout`, `gh784-marathon-qa-gate`, `gh273-marathon-root-audit-python-shape`, `marathon-plan`, `gh280-jog-marathon-adapter`, `marathon-drive`.
- Final QA: 4 rounds (the cap) with Codex; every Blocker and Should named in rounds 1-4 was fixed with a recorded control; the round-4 findings were fixed without a fifth review and are covered by S2f/S3b. Final full gate: run on the approved commit in the push clone (Step 9), recorded in the PR.

## Risks / rollback

- Consult fails open to an approval-like terminal: mitigated by requiring every advisor to answer `NON-BLOCKING`, treating anything else as hold, and by the unchanged driver-run gate, push gate and operator merge.
- Reverting: remove `--consult-at-cap` from `marathon_drive.py` and restore the two defaults; the new word is inert without the flag.

## Rating rationale

Rated through `roadmap pickup` on 2026-11-26 (see the ledger row). Severity 55: a stalled phase wastes a day of factory work but loses no data. Priority 70: operator-prioritized and it blocks the Flywheel arc; recurrence 1 distinct incident (GH-1315, #1610) in the last 14 days, trend otherwise unknown. Appeal 50 (neutral). Effort 70.
