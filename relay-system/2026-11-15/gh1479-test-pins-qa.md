# RELAY · GH-1479 existing-test pin edits QA
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
6. **Commit only the relay file** (`relay(gh1479-test-pins-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **test-pins-qa-brief.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-15

### Artifact — test-pins-qa-brief.md
```
# GH-1479 — QA of two edits to EXISTING tests (commit 596375650)

Goal: decide whether two one-line edits to existing test files keep each test's original
protective intent, or whether either edit weakened a check to make a refactor pass.

Operational envelope: local developer harness repo (XYZ-forge), branch
`feat/XYZ-forge-gh1479-static-analysis-swarm-2026-11-14`, draft PR #1494. Review must stay
commensurate: these are two one-line source-text pin updates. Do NOT ask for new tests, new suites,
or new gate machinery (repo rule GH-831). Do not run `validate.sh`, `test/*.sh`, or pytest in the
relay worktree; read-only greps and `git show` / `git diff` are fine.

Background: GH-1479 decomposed `main()` in `utils/py/swarm_preflight.py` into typed stage functions
and replaced the CI install line `pip install ... pytest` with `pip install ... -r requirements-dev.txt`
(which lists `mypy==1.14.1`, `pytest`, `requests`, `PyYAML`). The full gate at 6ffa3f359 then failed in
two suites whose assertions matched literal source text. Commit 596375650 changed exactly these lines:

1. `test/gh642-consumer-fruit.sh:307`
   - old: `grep -n '^    warn_zero_criteria(acc_mode' "$PYPREFLIGHT"`
   - new: `grep -n '^    warn_zero_criteria(' "$PYPREFLIGHT"`
   The call is now `warn_zero_criteria(evaluation.acc_mode, ...)` at `utils/py/swarm_preflight.py:1990`,
   and `if args.dry_run:` is at `:1992`, both inside `write_packet`.
2. `test/gh421-auto-wave-reconcile.sh:611`
   - old marker: `python3 -m pip install --quiet --break-system-packages pytest`
   - new marker: `python3 -m pip install --quiet --break-system-packages -r requirements-dev.txt`
   matching `.github/workflows/wave-reconcile.yml:52`.

Read: `git show 596375650 -- test/`, both test files around the edited lines (and enough of each file
to understand what the assertion protects), `utils/py/swarm_preflight.py` (the `warn_zero_criteria`
definition, its call site, and the dry-run exit), `.github/workflows/wave-reconcile.yml`,
`.github/workflows/ci.yml`, `requirements-dev.txt`. Compare against `origin/development` where useful.

Questions:

1. gh642 pin: the comment above line 307 says the INDENTED runtime call must precede the dry-run exit
   and the column-0 `def warn_zero_criteria` line must NOT satisfy the pin. Does the loosened pattern
   `^    warn_zero_criteria(` still exclude the `def` line, and can it match anything other than the
   one runtime call (any other 4-space-indented occurrence in the file)? Cite file:line.
2. gh642 ordering: with the call at :1990 and `if args.dry_run:` at :1992, is the ordering assertion
   still meaningful, i.e. are both lines in the same function on the same execution path, and is the
   `head -1` match for `^    if args.dry_run:` the dry-run exit the pin was written for (no earlier
   4-space `if args.dry_run:` elsewhere)? Would the pin still go red if the call were moved after the
   dry-run exit or deleted?
3. gh421 marker: does the new marker still prove what the old one proved (that the wave-reconcile
   workflow installs the Python test dependencies before running)? Does `requirements-dev.txt`
   include pytest so the original guarantee is preserved rather than dropped?
4. Is either edit a weakening of the test (accepts a state the old assertion would have rejected, for a
   reason unrelated to the refactor)? Is there a tighter one-line pattern that would be clearly better,
   and if so is the difference material or a nit?
5. Are there other literal source-text pins under `test/` that reference the old `main()` internals or
   the old install line and were missed (a grep sweep is enough)?

Flag anything wrong, missing, or weakened. Be concrete; cite file:line. VERDICT PASS only if both
edits preserve the original intent of their tests.
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
