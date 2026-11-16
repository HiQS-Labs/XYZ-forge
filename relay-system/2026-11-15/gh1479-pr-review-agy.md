# RELAY · GH-1479 PR 1494 whole-PR review (agy)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-15.
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
6. **Commit only the relay file** (`relay(gh1479-pr-review-agy): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **pr-review-agy-brief.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-11-15

### Artifact — pr-review-agy-brief.md
```
# GH-1479 / PR #1494 — independent whole-PR review (second reviewer)

Goal: independently review draft PR #1494 on branch
`feat/XYZ-forge-gh1479-static-analysis-swarm-2026-11-14` (head `c8b2e7f6d`, merge base with
`origin/development` `4635abe09`), with special attention to two one-line edits to EXISTING tests.
You are a second, independent seat: an earlier Codex review passed. Do not defer to it; form your own
view from the code.

Operational envelope: local developer harness repo (XYZ-forge). The change is a behaviour-preserving
refactor plus a scoped static-analysis baseline. Review must stay commensurate. Do NOT ask for new
tests, new suites, or new gate machinery (repo rule GH-831). Do not run `validate.sh`, `test/*.sh`
or pytest in the relay worktree; read-only greps, `git show`, `git diff`, and narrow non-mutating
probes writing only under `.relay-scratch/` are fine. Do not edit any file except this relay thread.

What the PR claims:
- `utils/py/swarm_preflight.py`: `main()` decomposed from 734 lines into 11 lines calling typed stage
  functions (`resolve_source_selection`, `load_contracts`, `inspect_repository`, `evaluate_candidate`,
  `normalize_candidate`, `report_candidate`, `write_packet`), passing frozen dataclasses
  `SourceSelection`, `RepositoryState`, `CandidateEvaluation`. Claimed: no change to CLI output, exit
  codes, network calls, or packet contents.
- New `mypy.ini` (scoped to that one module, `follow_imports = skip`) and `requirements-dev.txt`
  (`mypy==1.14.1`, `pytest`, `requests`, `PyYAML`).
- `test/test_python_layer.py`: the existing `test_swarm_preflight_module_load` now also runs mypy.
- `.github/workflows/ci.yml` (two places) and `.github/workflows/wave-reconcile.yml`: install line
  changed to `pip install ... -r requirements-dev.txt`.
- Two existing source-text pins re-pointed (commit 596375650), comment fixed in c8b2e7f6d:
  1. `test/gh642-consumer-fruit.sh:307`: `'^    warn_zero_criteria(acc_mode'` -> `'^    warn_zero_criteria('`
  2. `test/gh421-auto-wave-reconcile.sh:611`: marker `... --break-system-packages pytest` ->
     `... --break-system-packages -r requirements-dev.txt`
- Evidence under `TESTS-RESULTS/2026-11-14+GH-1479/` (old-vs-new A/B comparison, mypy pass and red
  control, gate logs). Plan and receipt: `PROJECT/2-WORKING/GH-1479-STATIC-ANALYSIS-SWARM.md`.

Read: `git diff 4635abe09..HEAD -- utils/py/swarm_preflight.py` and the resulting file in full;
`git show 4635abe09:utils/py/swarm_preflight.py` for the old `main()`; `mypy.ini`;
`requirements-dev.txt`; the workflow diffs; `test/test_python_layer.py` diff; both edited test files
around the edited lines with enough surrounding context to know what each assertion protects.

Questions:

A. The two test edits (highest priority)
1. `test/gh642-consumer-fruit.sh:307`: does the loosened pattern still exclude the column-0 `def`
   line and match only the runtime call? Are the matched call and the first `^    if args.dry_run:`
   in the same function and on the same execution path, so the "call precedes dry-run exit" ordering
   is still a real guarantee? Would the assertion go red if the call were deleted or moved after the
   dry-run exit? Is there any way the refactor made this pin pass while the behaviour it protects
   (zero-criteria warning emitted before a dry-run exit) silently regressed?
2. `test/gh421-auto-wave-reconcile.sh:611`: does the new marker preserve the original guarantee
   (the workflow installs its Python test dependencies)? Is pytest still installed?
3. Is either edit a weakening that accepts a state the old assertion rejected for a reason unrelated
   to the refactor? Material or nit?
4. Sweep `test/` for other literal pins on old `main()` internals or the old install line that were
   missed.

B. The refactor
5. Behaviour preservation: compare old `main()` against the staged version. Find any reordering of
   side effects (prints, stderr warnings, file writes, lock handling, git/network calls, `sys.exit`
   points and their codes) or any value computed differently. Cite old line vs new line.
6. State hand-off: any field of the three dataclasses that is stale, computed before a mutation that
   the old code performed later, or dropped? Any use of a mutable object inside a frozen dataclass
   that a later stage mutates in a way the old linear code did not?
7. Is the decomposition commensurate, or is there needless abstraction? `evaluate_candidate` is ~250
   lines and `write_packet` ~197: acceptable for this change, or a real problem?

C. Tooling
8. `mypy.ini` / `requirements-dev.txt` / workflow changes: anything that would break on a hosted
   Ubuntu or macOS runner (pip flags, unpinned packages, Python version vs `python_version = 3.10`,
   `follow_imports = skip` hiding real errors)? Note: on this PR only the smoke lane has run on hosted
   CI; the Ubuntu and macOS lanes were skipped, so this path is unexercised there.
9. Does extending `test_swarm_preflight_module_load` to run mypy make the Python layer fail in an
   environment that previously passed (mypy absent)? Is that failure mode clear to the operator?

Grade findings [Blocker]/[Should]/[Nit]/[Pass] with file:line citations. Flag anything wrong,
missing, weakened, or over-engineered. VERDICT PASS only if both test edits preserve their tests'
intent and you find no behaviour change in the refactor.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
