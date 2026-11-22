# RELAY · GH-1576 Final QA: refuse push from unwired clone
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-21.
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
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1576-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the committed change `3dc703600..HEAD` on `fix/XYZ-forge-gh1576-prepush-hook-check-2026-11-21`:
  `skills/1-hourly/kickstart/scripts/run_record.py`, `utils/py/jog_run.py`, `utils/py/express.py`,
  `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, the skill text in
  `skills/1-hourly/start-task/SKILL.md`, `skills/1-hourly/kickstart/SKILL.md`,
  `skills/2-daily/express/SKILL.md`, fixture wiring in `test/gh280-jog-marathon-adapter.sh` and
  `test/gh436-merge-cleanup.py`, and the evidence in `TESTS-RESULTS/2026-11-21+GH-1576/`
  (`README.md`, `check.sh`, `red.log`, `green.log`, `provenance.jsonl`, `real-gate.log`,
  `focused-suites.log`).
- Plan (approved by Codex plan QA round 2): `PROJECT/2-WORKING/GH-1576-PREPUSH-HOOK-CHECK.md`;
  plan relay `relay-system/2026-11-21/gh1576-plan-qa.md`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-21
- Definition of Done: issue #1576 is satisfied (asks 1-3, red/green) by the smallest change that
  works; code paths match the approved plan; no second detector or writer slipped in; the evidence
  substantiates each claim. Issue #1576 asks: (1) clone provisioning runs `bash githooks/install.sh`;
  (2) immediately before every push by start-task and the lanes reusing its push step (kickstart,
  express, jog, merge-cleanup repairs), run `bash githooks/install.sh --check`, stop and do not push on
  failure, never fall back to `--no-verify`; (3) extend existing provisioning/push steps, no new
  subsystem, no new suite (GH-831).

Operational envelope: grade against the stated requirements, commensurate complexity and this
repo's own threat model (`githooks/install.sh` header: `--no-verify` and per-clone wiring are not
fixable client-side). XYZ-forge forbids new tests (AGENTS.md, GH-831): a new test file or registry
entry in the diff is a finding. This touches gate/hook surfaces: do not suggest deferring a finding.

**Step A — paraphrase first (GH-1414).** Before reading source or evidence, read only this Setup
section and the plan doc and write 2-5 sentences each under **What this proposes** and **How the
existing system works, per this document**, plus a short **What it's not**. Label inference.

**Step B — source-backed check.** Then read the diff and evidence. Answer:
1. Does each push site in the plan's table now run the check immediately before pushing, with
   the plan's applicability rule (missing installer refuses; only jog/express keep the existing
   vendored policy)? Cite `file:line`. Is any push site in the lane family still unguarded?
2. Does anything duplicate a subsystem or writer? (Three small direct `--check` calls plus
   express's existing `gate_check` were the approved shape.) Is `gate_unwired_reason(install=True)` in
   `prepare_landing_clone` the only new provisioning step, and is the `PUSH_GATE_TIMEOUT_S` change on the
   repair push correct?
3. Do `check.sh` / `provenance.jsonl` actually reject an unchanged, unfixed candidate (red rows push
   from unwired clones with the origin ref moving; green rows refuse with the ref unchanged)? Check
   the rows against the claims in `README.md` and its stated limits. Is the stub installer in the
   gh280 fixture and the module-level stub in gh436 acceptable, given the pushes there are mocked or
   fixture-only and the refusal is witnessed by the manual check?
4. Is `check.sh` under `TESTS-RESULTS/` a manual-check artifact or a new test/registry entry
   (GH-831)?
5. Rating `62/58/50/72` vs the evidence; anything over-built or missing.

Cite `file:line` for disagreements. End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, a Basis, and
set STATUS to Approved only on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
