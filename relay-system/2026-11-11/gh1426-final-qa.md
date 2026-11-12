# RELAY · GH-1426 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-11.
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
6. **Commit only the relay file** (`relay(gh1426-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the implementation diff `git diff 0f21b761a..HEAD -- utils/py/jog_run.py`, the approved plan `PROJECT/2-WORKING/GH-1426-JOG-DRYRUN-TARGET-READINESS.md` (Plan + Acceptance → check map), and the evidence `TESTS-RESULTS/2026-11-11+GH-1426/` (README.md, provenance.jsonl, captured outputs). The plan review is `relay-system/2026-11-11/gh1426-plan-qa.md` (Approved r3, reviewed `56cdca9f1`).
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-11
- Operational envelope: a local developer CLI (`releases_app.py jog run`), one operator. Grade against issue #1426's acceptance and the approved plan, with commensurate complexity. The repo forbids new tests, suites, registry entries or gate machinery (AGENTS.md "No new tests", GH-831). A new test file in the diff is a finding; asking for one is out of scope. Sibling issues #1427/#1428 are out of scope.
- Measuring: read-only probes only (`export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"`). Do not run `validate.sh`/`test/*.sh` here. The suites already ran in a disposable clone (logs in the evidence dir), and the full gate runs on push from a disposable clone.

Questions:
1. Is each of the five issue acceptance criteria satisfied by the code at `utils/py/jog_run.py` (cite lines), and does the cited evidence file substantiate it?
2. Do the actual codepaths match the approved plan's Steps 1–5 (`_validate_execution_target`, `_resolve_preflight_py`, `_preflight_summary`, `_dry_run_preflight`, the reworded pre-preflight line, the refusal summary, the halt line, the legacy relay summary)? One addition beyond the plan: `_preflight_summary` replaces a `CONTRACT ERROR … see message above` headline with preflight's stderr cause. Is that in scope and correct?
3. Behaviour preservation: is `run_marathon_phase` otherwise unchanged (resolution order, the "resolved outside this root" notice, record/state writes, exit-4 handling)? Is the no-`--target-root` dry-run output unchanged (R3)? Does the dry-run path stay free of Jog ledger, queue, state, lock and lease writes (R1 snapshot)?
4. Robustness: can `_preflight_summary` raise or return empty for any preflight output? Does `_dry_run_preflight` handle a missing preflight script, a 1-INBOX doc with a mismatched identity, and the `--out` path, as planned? Does the `from swarm_preflight import doc_frontmatter_issue` import have side effects?
5. Did a duplicate subsystem or writer, or a new test, slip in? Is the persisted rating (`rated 55/45/50/70`, rationale in the plan doc) consistent with the evidence?
6. Is the evidence truthful (pre/post pairs, fixture description, sanitized paths, provenance SHAs)?

Write graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) with file:line. Behaviour-change requests carry `Observed input:` / `Affected scope:` / `Falsifier:`. VERDICT PASS → set `STATUS: Approved`.
- Definition of Done: every acceptance criterion is met with substantiating evidence; the code matches the approved plan; no duplicate subsystem or new tests; the dry-run effect contract holds.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
