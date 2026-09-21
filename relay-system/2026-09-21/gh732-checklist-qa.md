# RELAY · GH-732 CI/CD optimizations checklist — accuracy and grounding QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-21.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh732-checklist-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-732-MID-SEPTEMBER-CICD-OPTIMIZATIONS.md` (verbatim capture of GitHub issue #732's body — the checklist under review). Sources to check it against: `validate.sh`, `utils/ci-route.sh`, `githooks/pre-push`, `.github/workflows/ci.yml`, `.github/workflows/wave-reconcile.yml`, `utils/py/wave_reconcile.py`, `utils/py/_marathon_plan.py`, `skills/merge-cleanup/scripts/merge_cleanup.py`, `test/gh35-test-tiers.sh`, `test/gh251-validate-pytest-skip.sh`, `test/gh425-gate-provenance-pr.sh`, `AGENTS.md`, `ROUTER.md`, `SOP.md`, `PROJECT/2-WORKING/GH-496-SHARPEN-CICD.md`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-21
- Definition of Done: every checklist item's factual premise is either confirmed against the cited source line (or corrected with the right citation), or marked as an operator observation that the source cannot confirm; no item duplicates an open issue without saying so; the carry-over from #496 is accurate (landed vs not landed); the proposed action per item is proportionate (no new subsystem) and its acceptance is falsifiable.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer R1 — QA packet: is the checklist accurate and grounded?

VERDICT: PARKED
Basis: requesting independent verification of a checklist before anyone acts on it.

**Operational envelope.** A GitHub issue checklist for small, independent CI/CD optimisations in this repo's local pre-push gate and reconciliation loop. Grade facts and proportionality; do not propose new machinery. Timings in the table are the Producer's observations from six gated pushes on one 12-core host this week (2026-09-17..21) and cannot be re-run in this turn — grade their *plausibility* against the gate's mechanics, not their exact values.

**Read the artifact in full, then verify each item. For every item answer: (a) is the cited line/behaviour real (quote it), (b) is the diagnosis correct, (c) is the proposed action the smallest one, (d) is the acceptance falsifiable, (e) does an open issue already own it.** Measure read-only where useful (`--help`, `grep -n`, reading the hook/workflow); do not execute the gate, tests, or harness entrypoints.

Specific questions:
1. **Timing claims in docs:** confirm `AGENTS.md:180` says ~4–6 min and `ROUTER.md:63/:89-90` say ~16 min / 3-minute. Is "refresh the numbers or point at the gate's own `GREEN in Ns` line" the right fix?
2. **Per-suite durations:** does `validate.sh` really print no per-suite wall-clock (check the result loop near `:1309-1330` and the summary renderer)? If durations exist somewhere (a results file, `TESTS-RESULTS`), say where and correct the item.
3. **Toolchain preflight:** does `gh251-validate-pytest-skip.sh` establish pytest-absence as a named skip, and does `gh425-gate-provenance-pr.sh` still call `python3 -m pytest` in a way that hard-fails when pytest is missing? Is a 2-second preflight in `validate.sh` (import check + `php -v`) the smallest fix, or does an existing mechanism (e.g. the GH-251 skip path) just need extending? Note: `php` is used by `gh268-relay-cue-and-target-checks.sh` via target-checks — is that the right suite name?
4. **Re-run ladder:** confirm `vp_rerun_alone` (`validate.sh:1325`) re-runs pooled failures alone and serially. Is "print time spent in re-runs; consider a 2-wide re-run pool or short-circuit on a reproduced toolchain error" proportionate, or does it weaken GH-528's guarantee?
5. **Tier-2 width:** at `validate.sh:994-996` is `PARALLEL_JOBS=2` applied *before* or *after* the `--burst`/`XYZ_VALIDATE_MAX_JOBS` levers (precedence comment `:684`)? State precisely whether the levers are ignored for tier 2.
6. **Ledger-row routing:** does `ci-route.sh:458` (`tier=2`) plus the `releases` mapping at `:38` mean an intake-only `releases.sql/.db` delta always runs the full releases subsystem? Is the "evaluate" framing honest, or is the answer already knowable from the code?
7. **gh35 nice-nesting:** read the assertion in `test/gh35-test-tiers.sh` around the "ran 10 below its caller" message. Does it compute `caller+10` without clamping at 20? Is `min(caller+10, 20)` the right fix?
8. **Contention rule / docs-vs-code split:** are these already stated somewhere (ROUTER, SOP §4, AGENTS)? If so the items are duplicates — say so.
9. **Hosted `--qualify`:** confirm `wave-reconcile.yml` runs `--pr N --catch-up --gate --qualify` on `pull_request: closed` and that `--qualify` is the full sequential suite; is the "decide in #591" framing right, or does this belong in its own item?
10. **Carry-over from #496:** verify each landed/not-landed claim: #548/#553/#580 merged; `ci.yml:533-536` frozen-twin guard under `vendored-smoke` on PRs; `ci-route.sh:38/:42` mappings; `githooks/pre-push:34-35/:49` lever diagnostics; `run_pre_merge` at `wave_reconcile.py:1700` validating Lessons Learned (`:1789`); `merge_cleanup.py` **not** invoking `--pre-merge`; `releases.db` still tracked; `GH-496-SHARPEN-CICD.md` `updated: 2026-09-10` with 3 unticked items. Is "wire `--pre-merge` into E.6" the smallest fix for the post-merge Lessons-Learned failures, and is it correctly attributed to #496 Phase 2?
11. **Duplicates:** for each cross-ref (#382, #30, #730, #223, #591, #674, #722) is the boundary drawn correctly — nothing in the checklist re-asks what those issues own?
12. **Anything missing** that the same week's evidence clearly supports and the list omits? Anything listed that the evidence does *not* support?

Output: one graded finding per checklist item (`[Blocker]/[Should]/[Nit]/[Pass]`) with the citation, `swept file: yes|no`, VERDICT with Basis. Findings only — do not edit the artifact.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
