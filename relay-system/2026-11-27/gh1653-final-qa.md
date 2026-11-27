# RELAY · GH-1653 final QA - jog books receipt-publication attempt
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-27.
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
6. **Manual relay: commit only the relay file** (`relay(gh1653-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the committed diff `git diff 52813e56f..HEAD -- utils/py/jog_run.py utils/py/gate_receipt.py test/gh280-jog-marathon-adapter.sh` plus `PROJECT/2-WORKING/GH-1653-JOG-RECEIPT-ATTEMPT.md` and `TESTS-RESULTS/2026-11-27+GH-1653/` (read them in the worktree; do NOT edit).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-27
- Definition of Done: plan Requirements 1-4 (issue #1653, ledger #1657) are met by the built code with observed evidence: (1) approved lane publishes in the same wake/resume/gate-only retry with no manual attempt-start; (2) an unreserved task push is still refused by the unchanged gate; (3) consumed attempts survive retry and restart, an exhausted budget refuses, nothing renames/resets; (4) reuse of gate_receipt/rtl accounting, no new scheduler/suite/bypass.

### Review packet (final QA, round 1)

**Operational envelope.** Local agent CLI (Jog), single repo, canonical remote behind the repo's pre-push gate. Commensurate complexity; AGENTS.md "No new tests" (GH-831): a new `test/` file or `validate.sh` registry entry is a finding; focused cases in the existing gh280 suite are allowed (the plan named them). Never weaken the gate. Grade against the stated requirements, not speculative hardening.

**Plan QA history.** `relay-system/2026-11-27/gh1653-plan-qa.md`: 4 Codex rounds, all FAIL, cap reached; every finding dispositioned in the plan; consult tie-break single-model (Codex PROCEED, agy timed out) — not a cross-model approval. Re-check that the R1-R4 findings are actually implemented in code, including the R1-S5 probe now run.

**Evidence.** `TESTS-RESULTS/2026-11-27+GH-1653/README.md` and logs: gh280 242/0 at the fix; base-runtime red control 17 fails (wake G4, gate-only K2, retry-build K4 hit the Day 3 refusal); two-resume probe (B exit 4, one added row); installed-hook smoke (`smoke.sh`) green through the real `githooks/install.sh` stub and full pre-push gate; full `./validate.sh` at `8164e2ec1` red only on two pipe-grep guards caused by new test lines, fixed in `e9127b18` (guards green, smoke at `e9127b18` passed the full gate).

**Questions (cite file:line):**
1. Does `_jog_publish_under_attempt` / `jog_settle_publication_attempt` (jog_run.py) implement the plan exactly: book before commit, push with the context, finish completed/failed, post-push finish error reported as accounting pending (not a failed publication), exact env restore, ValueError→ContractError?
2. Already-published shortcut: only when the bundle was committed before the call AND the exact live ref equals HEAD; absent ref (empty ls-remote) and transport failure (nonzero) distinguished? Any path where a genuinely unpublished lane skips the push or the cap?
3. Settlement: completed live row archived via `rtl.archive_lane_attempts`; active row finished only with the exact-ref proof. Could it archive/finish a row belonging to a different publication or reset an exhausted budget?
4. Lock: `jog_resume` acquires `JogSupervisorLock`; `_jog_supervise_recover` calls `_jog_resume_locked`. Any other caller of `jog_resume` that already holds the lock?
5. `gate_receipt.py` extraction: CLI output/exit codes byte-compatible for attempt-start/attempt-finish?
6. Test honesty: does the gh280 hook exercise the real admission seam; do the new cases fail on the base runtime (see red log) for the right reason; any assertion that passes vacuously?
7. Is anything over-built, or is a requirement unmet? Is `run_record.py checkpoint --push` correctly left out of scope (#1653 Observed vs Next owner)?

Write your verdict below and set STATUS to Approved if it passes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
