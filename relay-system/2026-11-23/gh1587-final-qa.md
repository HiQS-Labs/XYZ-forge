# RELAY · GH-1587 Final Implementation & Verification QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
-->

NEXT: Reviewer
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
6. **Manual relay: commit only the relay file** (`relay(gh1587-final-qa): <role> r<N>`); no push.
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

### Scope & Changed Files (`14cb8a60d..e317eda3e`)

- **Approved plan:** `PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md` (Plan QA approved & attested in `relay-system/2026-11-23/gh1587-plan-qa-v3.md`; Option 1 / GH-681 prose-pin precedent authorized by operator).
- **Skill & relay edits:**
  - `skills/2-daily/review-code-xyz/SKILL.md` (Lanes B, C, E; Step N+1 Rollout Coexistence; Phase 2 Mantras 3–4 & Feature Stress; Phase 4 Mutation Falsification; preserved exact `Centralized Helper Adherence:` heading for `gh798`).
  - `skills/2-daily/review-pr-xyz/SKILL.md` (Phase 1 Claim Validation: Test-invariance / historical-invariant row; Phase 2–4 delegation untouched).
  - `relay-automation/relay-turn-lib.sh`, `relay-automation/new-relay.sh`, `utils/py/marathon_drive.py`, `skills/1-hourly/relay/SKILL.md`, `skills/1-hourly/relay-xyz/SKILL.md`, `relay-automation/README.md`, `skills/1-hourly/relay-automation/relay-pkg.tar.gz` (Form 1 vs Form 2 `Observed input:` + `Clone probe:` + Producer closure paths + errored/unavailable keep-open guard).
  - `skills/1-hourly/start-task/SKILL.md` (Step 6 Surface-triggered QA questions + Step 8 disposable-clone `Clone probe:` execution).
- **In-place pin test updates (GH-831: zero new test files, zero `validate.sh` additions; GH-308: `relay-automation/marathon-drive.sh` untouched):**
  - `test/gh681-reviewer-probe-rules.sh`
  - `test/gh778-review-code-skill.sh` (also reconciled line 51 to GH-1266 `366e492a7` heading + exact disk-vs-table row parity)
  - `test/gh616-start-task-commensurate-envelope.sh`
- **Ledger & receipts:**
  - `releases.db`, `releases.sql` (`rmi-01M859AVNYRXE06BH6A6QH6F5E` rated `85/80/50/70`, `--accepted-start`).
  - `TESTS-RESULTS/2026-11-23+GH-1587/` (`provenance.jsonl`, `layer-a-red-on-base.log`, `layer-a-focused-16-suites.log`, `layer-a-base-preexisting-drift.log`, `layer-b1-relay-self-sufficiency.log`, `layer-b2-smoke-relay-transcript.md`, `layer-b2-reviewer-drive.log`, `verify-clone-identity.json`).
  - `LESSONS-LEARNED.md` disposition: `NO_ENTRY` (all changed components are `confounded` per writer rules; documented in plan).

### Surface-Triggered QA Questions

1. **Cross-file prompt & package parity:** Are `relay-turn-lib.sh`, `new-relay.sh`, `utils/py/marathon_drive.py`, `relay/SKILL.md`, `relay-xyz/SKILL.md`, `start-task/SKILL.md`, `relay-automation/README.md`, and `relay-pkg.tar.gz` consistent on Form 1 vs Form 2 severity/closure rules, `Clone probe:`, errored/unavailable keep-open guard, and canonical `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]` tags without altering `utils/py/review_xyz.py` or `utils/py/rtl.py`?
2. **Test-Honesty & Historical-Invariant Audit:** Do the in-place updates to `test/gh681-reviewer-probe-rules.sh`, `test/gh778-review-code-skill.sh`, and `test/gh616-start-task-commensurate-envelope.sh` preserve all prior invariants (with `gh778` line 51 transparently reconciled to GH-1266 `366e492a7` while preserving exact 2-daily disk-vs-table parity) and genuinely fail on base `14cb8a60d` specifically on GH-1587 pins?
3. **Verification completeness & honesty:** Do the committed receipts in `TESTS-RESULTS/2026-11-23+GH-1587/` (including transparent disclosure of pre-existing unregistered base drift in `gh615`/`gh798`, live GH-836 `4 pass, 0 fail`, live `new-relay.sh` Form 2 `Clone probe:` Reviewer+Producer smoke across working + errored/unavailable + unproven-generalization paths, exact 4-field clone-identity match, and `LESSONS-LEARNED.md: NO_ENTRY`) satisfy the approved Plan QA contract?
4. **Gate readiness:** After this Final QA reaches `Approved`, zero code/doc/plan edits will follow; Step 9 will run `ci-local.sh --fast` and push through the wired first-push Tier-3 `./validate.sh` pre-push hook (per GH-1518).

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
