# RELAY · GH-1605 plan QA: STALE_CANONICAL_FORGE guard in sync.py
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
6. **Manual relay: commit only the relay file** (`relay(gh-1605-plan-qa-stale-canonical-forge-guard-in-sync-py): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1605-STALE-CANONICAL-GUARD.md` (the plan).
- Source files to inspect AFTER writing the initial paraphrase:
  - `skills/3-weekly/skills-army-hq/scripts/sync.py`
  - `skills/3-weekly/skills-army-hq/scripts/intake.py` (`git_at`, `collection_repo`)
  - `utils/py/skill_drift_check.py`
  - `skills/3-weekly/skills-army-hq/SKILL.md`
  - `skills/3-weekly/skills-army-hq/references/recovery.md`
  - `test/test_deploy_skills.py`
  - `AGENTS.md` (*No new tests*, GH-831)
- Reviewer: codex   ·   Producer: antigravity
- Started: 2026-11-25
- Definition of Done: The plan in `PROJECT/2-WORKING/GH-1605-STALE-CANONICAL-GUARD.md` solves GitHub issue #1605 (`STALE_CANONICAL_FORGE` warning instead of downgrade-risk `DRIFTED` re-vendor commands when the canonical `XYZ-forge` checkout is behind its upstream), extends existing `sync.py` helpers cleanly without duplicating `utils/py/skill_drift_check.py`, respects GH-831 (no new test files or `validate.sh` entries), preserves existing `test/test_deploy_skills.py` invariants, has grounded PRS ratings (`82/78/50/88`), and defines falsifiable acceptance criteria + red control.

## Review packet

**Paraphrase-first comprehension (GH-1414 — REQUIRED FIRST):**
Before reading any source files listed above, read ONLY `PROJECT/2-WORKING/GH-1605-STALE-CANONICAL-GUARD.md` and write:
- **What this proposes** (2–5 sentences)
- **How the existing system works, per this document** (2–5 sentences)
- **What it's not** (short bullet/sentence grounding exclusions in the plan's sections, distinguishing excluded work vs deferred work)
Label this section `Input boundary: plan doc only (PROJECT/2-WORKING/GH-1605-STALE-CANONICAL-GUARD.md)`.
Then read the source files listed in Setup and write your **Source-backed technical validation** with graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) and citations (`file:line`).

**Operational envelope:** Local macOS developer CLI (`sync.py`, offline/read-only on `--status` and preview, symlink manager on `--apply`) distributed via Git Pulse Sync. Grade against issue #1605 requirements, commensurate complexity, and GH-831 (*No new tests* — do not request new test files or `validate.sh` entries).

**Questions to check (cite `file:line`):**
1. Does extending `sync.py` (`ahead_behind()` + `drift_gate()`) without modifying `utils/py/skill_drift_check.py` actually close the AgentChorus #924765 failure mode (including when the stale canonical checkout contains an older `skill_drift_check.py`)?
2. Are there any edge cases in `ahead_behind()` (ref resolution order, `origin/development`, diverged `ahead > 0 & behind > 0`, non-git or no-remote fixtures in `test_deploy_skills.py`) or `drift_gate()` (`--status`, `--apply`, `--apply --allow-drift`, no enabled targets, JSON `result["drift"]` shape) that the plan misses or gets wrong?
3. Are the non-goals (no network calls, no `FETCH_HEAD` 24h gate on canonical Forge, no `skill_drift_check.py` duplication, no `RECEIPT-STALE`) and GH-831 verification + red-control plan sound?
4. Is the PRS rating (`82/78/50/88`, appeal neutral 50, recurrence evidence) grounded and consistent with `releases.db`?

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
