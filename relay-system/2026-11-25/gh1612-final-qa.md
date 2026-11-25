# RELAY · GH-1612 final QA
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
6. **Manual relay: commit only the relay file** (`relay(gh-1612-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/2-daily/yesterday-today/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-25
- Operational envelope: an instruction-only edit of one existing skill (`skills/2-daily/yesterday-today/SKILL.md`, 30 added lines), no scripts. XYZ-forge forbids new tests (`AGENTS.md` "No new tests", GH-831): a new test file, `validate.sh` TESTS entry or gate machinery in the diff is itself a finding. Grade against the stated requirements and commensurate complexity; do not ask for scripts, templates or a new skill.
- Operator decisions already made (do not reopen): the change extends the existing `yesterday-today` skill; the seven lessons in the plan's Requirement section are the operator's list; size about 20-30 added lines and under about 140 lines; generic, fictional examples only; the plan was Approved by Codex plan QA at round 3 (`relay-system/2026-11-25/gh1612-plan-qa.md`).
- Inputs (committed): issue https://github.com/HiQS-Labs/XYZ-forge/issues/1612; plan `PROJECT/2-WORKING/GH-1612-YESTERDAY-TODAY-RUN-SHEET.md` (acceptance A1-A6, draft wording); the diff `git diff b479f74e0 HEAD`; evidence `TESTS-RESULTS/2026-11-25+GH-1612/` (`SUMMARY.md`, `provenance.jsonl`, logs, four smoke receipts, `inputs/`). Base is `b479f74e0`.
- Definition of Done: each of the seven lessons is carried by step 5a, step 7 and step 8 as the plan's approved draft says; the acceptance checks A1-A5 are substantiated by their receipts (A6 is the delivery step, completed after approval); the smoke exercised the real consumer entry point on a deploy day, a reread-cancels case and a no-deploy day; nothing implies approval; nothing private or non-generic is in the diff; the per-issue rating matches its evidence.

Questions (answer each with `file:line` or the receipt that supports it):

1. Does the final text of step 5a, the step-7 sentence and step-8 item 6 (`skills/2-daily/yesterday-today/SKILL.md:66-91,105,123-124`) carry each of the seven lessons in `PROJECT/2-WORKING/GH-1612-YESTERDAY-TODAY-RUN-SHEET.md` (Requirement section) and the issue, with nothing contradicted? Is any wording ambiguous enough that an agent following it literally could get a lesson wrong?
2. Does anything in the new text conflict with the rest of the skill (its opening "never writes to a server", step 3's "not checked" rule, step 7's guarded publish, step 8's validator)? Any cross-reference or step number that the insertion broke?
3. What prevents an unchanged, unfixed candidate from being reported as delivered, and where is the observed rejection? Check `a1-content.log` (base MISSING x19), `smoke-base-replay.md` and the red controls in `a1-content.log`, `a3-privacy-scan.log`, `a5-diff-invariant.log`. Do the receipts observe what each acceptance item says?
4. Do the four smoke receipts show what they claim? Read each proposed body, not just `SUMMARY.md`: sheet first with six columns, the owner-but-no-time gate and the no-owner gates asked as questions, no sheet after the reread cancels the deploy, no output on the no-deploy day, header intact. Is the executor's "Read-only, 4/5/4/4 Read calls" claim credible from the receipts? Are the observations (chronological row order; a proposed owner marked "to confirm") fairly stated?
5. Privacy: is there any client, product, company, people, host name or private link in the skill diff, plan, evidence or relay threads (the plan's `owner` field is project metadata, and this repo's own issue URLs are public)? Re-run your own scan; do not rely on `a3-privacy-scan.log`.
6. Size and scope: 30 added lines and 136 total against "about 20-30" and "under about 140"; changed paths limited to the skill, the plan, the ledger files, relay threads and evidence. Any new test, suite, script or registry entry? Does the persisted rating `30/10/50/90` match the plan's rationale and the ledger row?
7. Anything required by the issue that is missing, or any machinery here beyond what the problem needs?

Write graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), then a VERDICT. Set STATUS to Approved only if no `[Blocker]` or `[Should]` remains. Every `[Pass]` needs a quoted span or a `file:line`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
