# RELAY · GH-1479 typed swarm-preflight final QA
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
6. **Commit only the relay file** (`relay(gh1479-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **final-qa-brief.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-15

### Artifact — final-qa-brief.md
```
# GH-1479 final QA brief — typed swarm-preflight stages and scoped mypy

Goal: final review of the implemented change on branch `feat/XYZ-forge-gh1479-static-analysis-swarm-2026-11-14`
before a DRAFT pull request. Your worktree is this branch at HEAD. Review the code, not this brief.

Operational envelope: a local developer CLI (`utils/py/swarm_preflight.py`) in a single repo. This is a
behavior-preserving refactor plus a one-module static-analysis baseline. Machinery must stay commensurate.
Non-goals (do not request): atomic-write repair, whole-repo typing, new test files/functions/suites/registry
entries (repo rule GH-831), changes to `marathon_drive.py`, `merge_cleanup.py`, `releases_app.py`.

Read:
- Plan and receipt: `PROJECT/2-WORKING/GH-1479-STATIC-ANALYSIS-SWARM.md` (whole file).
- Implementation diff: `git diff a7104e323 b2c5c32a7` (the single implementation commit) — and the whole of
  `utils/py/swarm_preflight.py` at HEAD, especially `parse_args` through `main`.
- Pre-change source for comparison: `git show a7104e323:utils/py/swarm_preflight.py` (`main()` at ~1206-1939).
- `mypy.ini`, `requirements-dev.txt`, `test/test_python_layer.py:44-52`, `.github/workflows/ci.yml`,
  `.github/workflows/wave-reconcile.yml`, `README.md`, `ROUTER.md`, `CHANGELOG.md` (top entry).
- Evidence: `TESTS-RESULTS/2026-11-14+GH-1479/` — `provenance.jsonl`, `stage-signatures.md`,
  `ab-compare/` (run.sh, exit-codes.txt, diff-old-vs-new.txt, old/, new/), `post-*.log`.

Questions:
1. Behavior preservation: comparing old `main()` with the extracted stages, is any early `SystemExit`, readiness
   precedence, side effect ordering (git fetch / worktree add/remove/prune, file writes), stdout/stderr text, or
   exit code changed? Cite the old and new `file:line` for anything that differs. Pay particular attention to
   paths the A/B comparison did NOT exercise (see `ab-compare/exit-codes.txt`: exits 0,2,3,4,5 were covered) —
   e.g. multi-issue `--gh-issue` mode success, stale index lock, frozen artifacts, lanes, fetch failure, exit 6+.
2. Is the A/B evidence sound and non-vacuous for what it claims? Is replacing the plan's step-5
   baseline-with-substitutions comparison by a same-path old-vs-new byte comparison acceptable?
3. Bounded decomposition: do the three frozen records and stage signatures give a bounded producer/consumer
   flow, or is the monolith merely relocated (`evaluate_candidate` is 250 lines, `write_packet` 197)? Only
   request a further split if you can name a concrete defect or review hazard it removes.
4. Typing: are annotations honest (no `Any` hiding a knowable type where it matters, no behavior-changing
   coercions introduced to satisfy mypy)? Is `mypy.ini` scoped correctly and is `follow_imports = skip` sound here?
5. Gate wiring: `test_swarm_preflight_module_load` now shells out to mypy. Does a missing mypy fail with actionable
   output? Are the three CI install steps and docs consistent with `requirements-dev.txt`? Any hosted-CI risk
   (e.g. `--break-system-packages -r requirements-dev.txt`, Python version vs `python_version = 3.10`)?
6. Scope: anything in the diff outside the plan, or anything the plan required that is missing?
7. Pre-existing defects in `swarm_preflight.py` you notice while sweeping the file: list them, marked as
   pre-existing, without requesting they be fixed in this PR unless the refactor made them worse.

Output graded findings with `file:line` citations. A behaviour-change request needs `Observed input:`,
`Affected scope:` and `Falsifier:` lines. Do not run `validate.sh`, `test/*.sh` or pytest in the relay worktree.
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
