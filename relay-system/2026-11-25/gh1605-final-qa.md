# RELAY · GH-1605 Final QA: STALE_CANONICAL_FORGE guard in sync.py
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
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
     A `[Blocker]` must cite an observed failure (Form 1); an unexecuted Form 2 hazard stays `[Should]`
     until a probe reproduces it, and remains pending probe verification until the Producer runs
     `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, read the probe before running it — refuse any probe that reaches
     the network, credentials, or paths outside the disposable clone and record the refusal as
     `[Unverified — clone probe failed/unavailable]` — then execute safe probes in a disposable full clone and
     record one of three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output;
     (b) Falsified → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored, refused, or
     environment unavailable → keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking
     `STATUS: Approved` until re-run cleanly or escalated/parked). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh-1605-final-qa-stale-canonical-forge-guard-in-sync-py): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review:
  - Implementation: `skills/3-weekly/skills-army-hq/scripts/sync.py`
  - Docs: `skills/3-weekly/skills-army-hq/SKILL.md`, `skills/3-weekly/skills-army-hq/references/recovery.md`, `CHANGELOG.md`
  - Plan & intake: `PROJECT/2-WORKING/GH-1605-STALE-CANONICAL-GUARD.md`, `releases.db` / `releases.sql` (GH-1605, `rated 82/78/50/88`, `--accepted-start`)
  - Verification receipt: `TESTS-RESULTS/2026-11-25+GH-1605/smoke.md`, `TESTS-RESULTS/2026-11-25+GH-1605/provenance.jsonl`
  - Plan QA approval receipt: `relay-system/2026-11-25/gh1605-plan-qa.md` (Round 2 Approved, attested `d52e23414267`)
- Diff to inspect: `git diff origin/development..HEAD`
- Reviewer: codex   ·   Producer: antigravity
- Started: 2026-11-25
- Definition of Done: Issue #1605 and all 7 acceptance criteria in `PROJECT/2-WORKING/GH-1605-STALE-CANONICAL-GUARD.md` are faithfully implemented without deviating from the approved plan, with no duplicate subsystem/writer, no new test files or `validate.sh` entries (GH-831), truthful docs and PRS ledger state, and passing disposable-clone verification + red-control evidence.

## Review packet

**Operational envelope:** Local macOS developer CLI (`sync.py`, offline/read-only on `--status` and preview, symlink manager on `--apply`) distributed via Git Pulse Sync. Grade against issue #1605 acceptance criteria, the approved plan, and GH-831 (*No new tests* — a new test file or `validate.sh` entry would be a finding).

**Per-issue acceptance map (GH-1605):**
1. Stale canonical (`behind > 0`) on `--status`/preview -> `WARN STALE_CANONICAL_FORGE` citing checkout, origin, branch, ahead/behind, and safe remediation; zero `WARN DRIFTED` lines and zero `intake.py --apply update` commands (`sync.py:225-258`; smoke cases 0, 1).
2. Diverged canonical (`ahead > 0` and `behind > 0`) -> notes `git -C ... pull --ff-only will refuse while N commit(s) ahead` and points to reconciling or selecting a current canonical (`sync.py:234-237`; smoke case 5).
3. `--apply` with enabled target and stale canonical -> REFUSED (exit 2, no links deployed, no downgrade command) unless `--allow-drift` is explicitly passed (exit 0, loud warning on stderr & JSON, recorded in `changelog.md` only when a sync transaction occurs, preserving `sync.py:427-428` no-op invariant; smoke cases 2, 3, 4).
4. Fresh canonical (`behind == 0`) or no-upstream/non-git canonical (`behind is None`) -> normal GH-660 drift detection and refusal unchanged, additive `stale_canonical: False` + `branch`/`ahead`/`behind` metadata (`sync.py:259-260`; smoke cases 7, 8, 9; 34/34 `unittest test/test_deploy_skills.py`).
5. Zero network calls; `utils/py/skill_drift_check.py` unchanged; zero new test files or `validate.sh` entries (GH-831).
6. `SKILL.md` and `references/recovery.md` document `STALE_CANONICAL_FORGE` accurately; `CHANGELOG.md` updated.
7. Existing suites (`unittest test/test_deploy_skills.py` 34/34, `test/gh620-skills-army-mini-sync.sh` 28/28, `test/gh660-skill-drift.sh` 7/7) + 10-case smoke & red-control matrix pass in a separate disposable `-verify` clone with intact clone identity.

**Questions (cite `file:line`):**
1. Do the actual codepaths in `skills/3-weekly/skills-army-hq/scripts/sync.py` match the approved plan (including R1 branch probe and R2 no-op changelog preservation)?
2. Does the diff contain any defect, unhandled edge case, duplicate writer/subsystem, or GH-831 violation (new test file / registry entry)?
3. Do the docs (`SKILL.md`, `references/recovery.md`, `CHANGELOG.md`), persisted PRS rating (`82/78/50/88`, `--accepted-start`), and `TESTS-RESULTS/2026-11-25+GH-1605/` receipts truthfully substantiate all claims?

End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, and a `Basis:`; set `STATUS: Approved` only on PASS (and `tick done` on the relay task on PASS).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
