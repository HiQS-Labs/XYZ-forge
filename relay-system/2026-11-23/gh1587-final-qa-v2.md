# RELAY · GH-1587 Final Implementation & Verification QA (v2 — Step 8 Pre-Approval Gate)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
-->

NEXT: codex
STATUS: Open
ROUND: 2 / 3

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
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry `Observed input:`, `Affected scope:` (the input predicate the change would govern),
     and `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected
     result). `Observed input:` accepts two strict, non-speculative forms:
     (1) **Form 1 (observed failure or artifact contradiction):** a failing probe/gate output, or a concrete
     `fileA:line` vs `fileB:line` contradiction (e.g. IAM SA mismatch, inverted test, sibling guard omission);
     (2) **Form 2 (unrunnable runtime hazard trace):** permitted ONLY when reproduction requires an external
     service, multi-process concurrency, or a browser/container runtime forbidden in the relay worktree —
     must supply a hop-by-hop `file:line` trace plus an exact `Clone probe:` command/script for the Producer's
     disposable full clone. Default severity for an unexecuted Form 2 hazard is `[Should]`.
     A `[Blocker]` must cite an observed failure (Form 1), or a Form 2 static `file:line` trace proving an
     unconditional invariant breach; in either severity a Form 2 finding stays pending probe verification until
     the Producer runs `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, execute the probe in a disposable full clone and record one of
     three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output; (b) Falsified
     → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored or environment unavailable →
     keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking `STATUS: Approved` until
     the probe runs cleanly or the relay escalates/parks). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1587-final-qa-v2): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup

**Artifact under review:** `PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md`
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-23
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

### Continuity from Prior Final QA (`relay-system/2026-11-23/gh1587-final-qa.md`)

In `gh1587-final-qa.md`, Codex closed both technical findings (`[Pass]` on Reviewer-issued dual Form 2 `Clone probe:` smoke in Round 2; `[Pass]` on `16/16` focused suites + exact 4-field clone identity in Round 3) and escalated at Round 3/3 solely on the plan-wording sequencing contradiction where `:215` placed post-approval Step 9 push/PR delivery inside the pre-approval checklist.

Commit `37a9e5613` (`pdda.sh run` exit 0) resolved that sequencing contradiction directly per `skills/1-hourly/start-task/SKILL.md` Steps 8–9 (GH-1518: *Step 8 Final Codex Relay QA reaches `Approved` before Step 9 runs `ci-local.sh --fast` and pushes through the pre-push Tier-3 `./validate.sh` hook and opens the PR*):
- **Step 8 Pre-Approval Final QA Gate (this review's acceptance target):**
  1. `16/16` focused suites pass (`exit 0`) in `-verify` (`TESTS-RESULTS/2026-11-23+GH-1587/layer-a-focused-16-suites.log`) + red-on-base rejection of `14cb8a60d` (`layer-a-red-on-base.log`) + exact 4-field clone-identity match (`verify-clone-identity.json`).
  2. Live GH-836 `test/relay-self-sufficiency.sh` passes non-skipped (`4 pass, 0 fail`, `layer-b1-relay-self-sufficiency.log`).
  3. Live `new-relay.sh` dual Form 2 `Clone probe:` smoke passes with both Reviewer-issued findings: working TOCTOU probe reproduced (`exit=1`) and fixed (`exit=0`, `Implemented`) + unavailable `acme-pay-cli` probe (`exit=2`) kept OPEN as `[Unverified — clone probe failed/unavailable]` refusing `STATUS: Approved` (`layer-b2-smoke-relay-transcript.md`).
  4. All tracked receipts (`TESTS-RESULTS/2026-11-23+GH-1587/`), `LESSONS-LEARNED.md: NO_ENTRY` disposition, and plan status are committed **before** Final QA approval (`provenance.jsonl`, `PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md`).
- **Step 9 Post-Approval Delivery Gate (strictly AFTER this relay reaches `STATUS: Approved`, per `skills/1-hourly/start-task/SKILL.md:268-335` & GH-1518):** wired first-push pre-push Tier-3 `./validate.sh`, 4-field pre/post-push identity, ready PR against `development`, `#1587` closeout comment, and clone retirement.

### Changed Implementation Surfaces (`git diff --stat 14cb8a60d..HEAD`)
- `skills/2-daily/review-code-xyz/SKILL.md`, `skills/2-daily/review-pr-xyz/SKILL.md`
- `relay-automation/relay-turn-lib.sh`, `relay-automation/new-relay.sh`, `relay-automation/README.md`, `utils/py/marathon_drive.py`, `skills/1-hourly/relay/SKILL.md`, `skills/1-hourly/relay-xyz/SKILL.md`, `skills/1-hourly/start-task/SKILL.md`, `skills/1-hourly/relay-automation/relay-pkg.tar.gz`
- In-place test edits (zero new test files per GH-831; `relay-automation/marathon-drive.sh` untouched per GH-308): `test/gh681-reviewer-probe-rules.sh`, `test/gh778-review-code-skill.sh`, `test/gh616-start-task-commensurate-envelope.sh`, `test/gh615-start-task-reinforce.sh`, `test/gh798-status-skill.sh`
- `releases.db`, `releases.sql`, `PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md`, `TESTS-RESULTS/2026-11-23+GH-1587/*`

Please review the plan, receipts, and implementation diff against the Step 8 Pre-Approval Final QA Gate and issue your final verdict.

## Log

### Reviewer · Round 1
swept file: yes

- [Should] Reconcile the clone identity evidence with the actual candidate revisions and each verification run, or rerun the affected checks with contemporaneous pre/post identity receipts. **Observed input:** `PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md:177-183` requires identity before and after every mutation-heavy run, and :235 claims the `0e7ad617` identity pair covers all runs. However, `TESTS-RESULTS/2026-11-23+GH-1587/provenance.jsonl:4-5` assigns both live Layer B runs to `19476291`, while `verify-clone-identity.json:3-16` records only a single pair with HEAD `0e7ad617`. The pair cannot establish unchanged HEAD around runs recorded at the other revision, nor independently establish identity around each run. **Affected scope:** pre-approval reliance on the Layer B and focused-run isolation/identity claims. **Falsifier:** contemporaneous per-run four-field receipts matching the provenance SHAs, or a documented correction supported by original run evidence showing the recorded SHAs are erroneous and each run had intact identity. Provide the receipts and correct the plan/provenance, or repeat the affected runs in a disposable full clone and record the results.

VERDICT: FAIL
Basis: The required identity evidence is inconsistent with the recorded live-run revisions; the prior relay's closure does not resolve this specific receipt contradiction. The full plan was swept; no other pre-existing finding was established in that artifact.

Handing off to Producer — reconcile the identity evidence and return for review.

### Producer · Round 1 (claude-a)

1. **`[Should]` Per-run 4-field clone-identity receipts across `19476291` and `0e7ad617` — `Implemented` (commit `5a1088886`, `pdda.sh run` exit 0):**
   - Restored **both** contemporaneous pre/post 4-field clone-identity pairs directly from git history (`e317eda3e` for `19476291ef3e0f4a3f5ecf20b2745e4829c7fd1e`, and `57e560912` for `0e7ad61718e4c0c359feb2bdce811f325f2ae099`) into `TESTS-RESULTS/2026-11-23+GH-1587/verify-clone-identity.json` (`runs[0]`: `verify-run-1-19476291` covering Layer A red-on-base + Layer B.1 live GH-836 + Layer B.2 live dual Form 2 smoke; `runs[1]`: `verify-run-2-0e7ad617` covering the `16/16` focused green run after test-only `gh615`/`gh798` pin reconciliation, with zero skill/relay/tarball changes between `19476291` and `0e7ad617`).
   - Added explicit per-run `verify-clone-identity` rows matching each candidate SHA into `TESTS-RESULTS/2026-11-23+GH-1587/provenance.jsonl` and updated `PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md` to cite both contemporaneous per-run identity receipts accurately.

Handing back to Reviewer (`codex`) for Round 2 final verdict.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
