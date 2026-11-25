# RELAY · GH-1606 delta QA — a nonzero probe exit with no fault line must not defer (PR #1614 review)
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
6. **Manual relay: commit only the relay file** (`relay(gh1606-delta-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1606-delta.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-XYZ-forge/e3f96cf1-a102-4b6b-8e5b-e513c6a2ffc3/scratchpad/GH-1606-delta.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-25
- Definition of Done: the post-approval change is correct and minimal, is consistent with the approved plan and `SKILL.md`, regresses none of the previously approved behaviour, and its retained controls would have rejected the unfixed code.

### Context (read this first)
- Codex plan QA (APPROVED round 3) and Codex final QA (APPROVED round 2, reviewed head `15792a167`) covered the code through `11ac019c7` / published head `99433678e`. PR #1614 was then opened. CodeRabbit's PR review raised ONE valid inline finding, which is the only reason this delta exists:
  > `gate_toolchain_fault_reason` returns the output tail when `validate.sh --print-mode` exits nonzero WITHOUT an `ENVIRONMENT FAULT` line, so the execute path defers a PR for a reason that names no fault (e.g. a clone whose own `validate.sh` rejects `--print-mode`). It conflicts with the helper's docstring and with the rule that a probe which cannot answer is skipped.
- The change under review is the delta from `99433678e` to the current HEAD, supplied as the artifact above (`skills/`, `TESTS-RESULTS/`, `PROJECT/`): the helper now returns `""` when no fault line is present; the plan, summary and provenance are updated; the driver gained `AC-1-nofault-red/green` and an end-to-end scenario `S8` (a `validate.sh` that answers `--print-mode` with a usage error and exit 2); the provenance was regenerated on the new commit and no longer contains an expanded home-directory path.
- Note: you earlier accepted the "empty nonzero fallback" at final QA round 2 (your probe asserted `reason(3)=='validate.sh --print-mode exited 3: '`). The fix reverses that on purpose. Say whether you now agree with the reversal and why, citing the plan's own rule and `skills/2-daily/merge-cleanup/SKILL.md:269`.

### Operational envelope and non-goals
- Same as before: local operator CLI tooling; grade against stated requirements and commensurate complexity. XYZ-forge forbids new tests (GH-831): a new `test/` suite or `validate.sh` entry is a finding; `run_controls.py` is a manual driver under `TESTS-RESULTS/`. No change to hook routing, the 2-repair budget, accounting, or the push path.
- Not yet run by design: the repository qualification gate on the new commit and hosted CI for the new head. Do not assume them and do not demand them here.

### Questions (answer each; cite `file:line`)
1. Is `return " | ".join(faults)` (`merge_cleanup.py` `gate_toolchain_fault_reason`) correct for every output shape: mixed php+python rc 3, php-only rc 0, python-only rc 3, stderr-only rc 3, rc 3 with no fault line, rc 2 with empty output, spawn error and timeout, and absent `validate.sh`? Say what you tried.
2. Is the reversal consistent with the approved plan, the helper docstring, `SKILL.md`, and the dry-run `preflight_warnings` entry (which also calls the helper)? Is there any remaining place that still describes or depends on the old tail fallback (grep the whole tree, not just the diff)?
3. Does the S8 scenario actually reach the code under test, and would the PRE-FIX commit fail it? Is `AC-3-S8-prefix-red` non-vacuous (can it pass on empty or absent output)? Are `AC-1-nofault-red/green` falsifiable?
4. Is anything in the delta outside the one finding's scope? Is the provenance free of absolute home-directory text, and is it internally consistent with `SUMMARY.md` and the plan (counts, commit ids)?
5. Does this change create any new way for a genuinely blocked gate to slip through un-deferred (a missed toolchain fault)? Where does the pre-push hook still enforce it, and is that enforcement unchanged?
6. Anything unverified or overstated in `SUMMARY.md` or the plan's new *Decisions after the PR review* section? Label each gap accepted-and-recorded or a finding.

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) each with a concrete fix and `file:line` citations, the required `swept file: yes|no` line, then `VERDICT:` and `Basis:`. Every behaviour-change finding needs `Observed input:` / `Affected scope:` / `Falsifier:`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
