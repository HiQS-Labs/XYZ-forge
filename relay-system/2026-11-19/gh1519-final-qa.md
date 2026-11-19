# RELAY · GH-1519 Final QA: validate.sh mypy preflight
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-19.
-->

NEXT: Producer
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
6. **Manual relay: commit only the relay file** (`relay(gh1519-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `validate.sh`, `TESTS-RESULTS/2026-11-19+GH-1519/smoke.log`
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-19
- Definition of Done: issue #1519 acceptance — with `mypy` absent the gate exits within seconds naming
  the missing prerequisite and the install command; with `mypy` present it behaves as before. No new suite.

Simple change (plan QA skipped: one module added to the existing GH-732 check, local and reversible).
Diff: `git diff origin/development..HEAD` (validate.sh 2 lines, CHANGELOG, ledger row, smoke log).
Envelope: local gate prologue; XYZ-forge forbids new suites (GH-831).

Questions (cite file:line):
1. Does adding `mypy` to the loop at `validate.sh` (GH-732 block) meet both acceptance lines? Is
   `import mypy` the right probe for `python3 -m mypy` in `test/test_python_layer.py`?
2. Can the check refuse a run that should proceed: suites that invoke `validate.sh` themselves
   (e.g. `test/gh251-validate-pytest-skip.sh`, `test/gh544-parallel-default.sh`), hosted jobs in
   `.github/workflows/ci.yml` / `wave-reconcile.yml` that run validate.sh without installing
   `requirements-dev.txt`, or `--print-mode` in `githooks/pre-push`?
3. Do the pinned strings in `test/gh251-validate-pytest-skip.sh` still match the new message?
4. What would let an unchanged candidate be reported delivered, and does `smoke.log` show the refusal?

End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, a Basis; set STATUS Approved only on PASS.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

Block — the code change is sound by inspection, but the cited evidence needs provenance before approval.

- [Pass] The added prerequisite uses the existing refusal path, before suites and before `--print-mode` exits: `validate.sh:1035` includes `mypy`, and `validate.sh:1041` names both the missing modules and `pip install -r requirements-dev.txt`, then exits 3 at `validate.sh:1042`. Narrow probe (not the gate): `python3` read `validate.sh` lines 1033–1043, asserted the extracted loop was nonempty and contained `mypy`, then ran only that block with `/bin/bash -c` and `PATH=/opt/homebrew/bin:$PATH`. Probe driver exit 0; block exit 3 in 0.392s; decisive output: `python3 (/opt/homebrew/bin/python3) version 3.14.7; missing modules: mypy; requires Python >=3.10 with yaml/pytest/requests/mypy (pip install -r requirements-dev.txt)`. This independently witnesses the missing-mypy decision, not a full gate run.
- [Pass] Ordinary installation compatibility is appropriate: `test/test_python_layer.py:48` invokes `sys.executable -m mypy`; the gate and pytest use `python3` (`validate.sh:1036`, `validate.sh:1451`). Importing the installed package is a proportionate availability probe, though it does not prove mypy's execution or type-check result. Hosted callers install the full requirements at `.github/workflows/ci.yml:184`, `.github/workflows/ci.yml:402`, and `.github/workflows/wave-reconcile.yml:52`. `requirements-dev.txt:1` includes `mypy==1.14.1`.
- [Pass] The GH-251 literal pins remain compatible: `test/gh251-validate-pytest-skip.sh:60` matches `missing modules: pytest`, and line 78 matches `missing modules: yaml`; adding mypy does not change either substring when the other dependencies are installed. Nested validators and pre-push introspection use the same ambient interpreter, so a healthy outer run also satisfies this new prerequisite (`test/gh544-parallel-default.sh:63`, `githooks/pre-push:235`). Missing mypy intentionally refuses introspection too, consistent with its existing toolchain-diagnostic contract (`validate.sh:1047`–1050).
- [Should] Retain provenance for the smoke runs cited by `CHANGELOG.md:9`. The evidence directory contains only `smoke.log`; the required `provenance.jsonl` is absent. Read-only probe: `python3` evaluated `[p.name for p in Path('TESTS-RESULTS/2026-11-19+GH-1519').iterdir()]` and `Path('TESTS-RESULTS/2026-11-19+GH-1519/provenance.jsonl').exists()`; exit 0, decisive output `['smoke.log']` and `False`. AGENTS.md requires retained, committed provenance for every run cited in a decision/changelog. Fix: add the existing-format provenance identifying candidate revision, exact commands/arguments, interpreter/environment, exit statuses and retained output; distinguish the print-mode smoke from suite execution. No runtime behavior change requested.
- [Unverified — needs clone run] `smoke.log:2`–3 records the dependency refusal and lines 6–9 record mode introspection; lines 11–12 report GH-251's four passing checks. It supplies neither an exact candidate revision nor a full healthy gate result. I did not run validate.sh, suites, pytest, or fixtures here, and do not infer a later configured gate will qualify this candidate. Preserve or link existing disposable-clone evidence if claiming the full gate passed.
- [Unverified — no delivery-refusal evidence] Setup question 4: treating a successful process/relay status or print-mode exit 0 as proof of an artifact change could report an unchanged candidate delivered. `smoke.log:1`–14 demonstrates missing-dependency refusal, not unchanged-candidate delivery refusal. If that additional claim is intended, supply the actual delivery-check command and its refusal output; otherwise explicitly limit the evidence to GH-1519's dependency preflight. No delivery mechanism change requested.

swept file: yes
VERDICT: FAIL
Basis: Swept validate.sh's prologue, registry, selection, execution, retry, summary and receipt paths and all of smoke.log. No additional proven pre-existing runtime defect found in the reviewed artifacts. The two-line preflight extension meets the narrow missing-mypy behavior; approval is held for the explicit provenance requirement, not an invented requirement for a new suite. Graph project inventory had no matching task worktree; the nearest Forge index generation was 2026-11-18T19:39:07Z and cannot establish this candidate's freshness, so conclusions use direct source reads. Healthy full execution and unchanged-delivery refusal remain unverified as stated above.

Handing off to Producer (claude-a) — retain provenance and disposition the evidence limitations, then return for review.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
