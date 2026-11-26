# RELAY · GH-1627 plan QA - gate selects prepared test venv
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

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
6. **Manual relay: commit only the relay file** (`relay(gh1627-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1627-GATE-VENV-AUTOSELECT.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1627-GATE-VENV-AUTOSELECT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-25
- Definition of Done: the plan's "Requirements" 1-5 (issue #1627 Acceptance) are each met by the plan, each with a falsifiable check that rejects the unchanged base.

### Review packet (plan QA, round 1)

**Paraphrase first (GH-1414).** Before reading anything except the plan, write 2-5 sentences each under **What this proposes** and **How the existing system works, per this document**, plus a short **What it's not**. Distinguish excluded work, deferred work, unresolved choices. Record this initial paraphrase as the first part of your review block, then continue with the source-backed assessment (label it "source-backed").

**Operational envelope.** Local developer shell gate in a single repo (`validate.sh`, a bash script). Grade against the stated requirements, commensurate complexity, and the repo's own rules: AGENTS.md "No new tests" (GH-831: no new suites or registry entries; use existing suites or manual checks under `TESTS-RESULTS/`), the GH-732 environment-fault contract, and `utils/py` / `githooks` conventions. Do not ask for speculative machinery (path knobs, locks, journals, venv creation).

**Read:** `PROJECT/2-WORKING/GH-1627-GATE-VENV-AUTOSELECT.md` (the plan, `.relay-artifacts/` copy), `validate.sh` (the `GH-732 environment faults BEGIN/END` block and everything up to `--print-mode`), `githooks/pre-push`, `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (`gate_toolchain_fault_reason`, `preflight_warnings`), `test/gh251-validate-pytest-skip.sh`, `README.md` (gate toolchain paragraph), `skills/2-daily/merge-cleanup/SKILL.md:269`, issues #1627 / #1437 / #1606 (as quoted in the plan).

**Questions (cite file:line):**
1. Is every claim in the plan's "Observed problem" table grounded in the actual paths? Is any entry wrong or missing?
2. Does the plan make a failing `python3` + healthy venv run on the venv, and ONLY then? Does the second `_xyz_python_probe python3` keep the failure output (fault line, remedy, exit 3) byte-identical to base when the venv is missing/failing? Is there any state (e.g. `_python_missing`, `_python_version`, PATH) that leaks differently from base?
3. Is it right that `githooks/pre-push` and `merge_cleanup.py` need no change? Trace every `python3` use before validate.sh in the hook (gate_receipt.py admit/check, docs route via pdda.sh, tier-2 route) and name any that would behave differently when PATH python3 is the toolchain-less 3.14. Does merge-cleanup's `validate.sh --print-mode` probe agree with the gate in all three cases?
4. Does the selection still hold for suites that re-exec `python3` or invoke `validate.sh` recursively (nested runs in the existing gh251 suite use a failing shim first on PATH)? Is the planned `HOME=` isolation of gh251's two failing-interpreter cases the right and minimal fix, and does anything else in `test/` break on a machine that has the venv?
5. What prevents an unchanged, unfixed candidate from being reported as delivered, and where is the observed rejection? Check the (a)-(f) table: does each row have a rejecting control on base, and is any row vacuous?
6. Is the plan surgical and DRY (one function, no copied module list, no second selector)? Flag any machinery that is unneeded, and any requirement left unmet. Does the plan respect "no change outside the repo" (no profile, no auto venv, no Homebrew edit)?
7. Surface-triggered: modified existing tests (Test-Honesty: does the gh251 edit keep its assertions real?); new wrapper layers (none intended).

Write your verdict (PASS / FAIL / PARKED, with `swept file: yes|no`) and set STATUS Approved only if the plan can be built as written.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
