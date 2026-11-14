# RELAY · GH-1466 final QA: xyz-vendor --ledger-only tier
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
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
6. **Commit only the relay file** (`relay(gh1466-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the committed implementation `git diff e0586fc30..HEAD`, excluding relay-system/. Files: `relay-automation/xyz-vendor.sh`, `relay-automation/xyz-sync.sh`, `utils/hq/hq-lib.sh`, `utils/pdda/pdda-lib.sh`, `utils/pdda/pdda.sh`, `utils/py/wave_reconcile.py`, `utils/py/releases_app.py`, `RELEASES-DB-FAQS.md`, `UPGRADE.md`, `CHANGELOG.md`. The approved plan is `PROJECT/2-WORKING/GH-1466-VENDOR-LEDGER-ONLY.md` (plan QA: `relay-system/2026-11-14/gh1466-plan-qa.md`, Approved r2). Evidence: `TESTS-RESULTS/2026-11-14+GH-1466/` (README, provenance.jsonl, results.tsv, logs/). Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1466.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-14
- Definition of Done: each issue #1466 requirement in the plan's acceptance map is met by the code and substantiated by the cited evidence; code paths match the approved plan; no duplicate subsystem or writer; no new test suite or `validate.sh` entry; Tier 1/2 behaviour unchanged.

### Operational envelope
Local developer CLI (bash + python) that vendors a harness into a host repo on one machine. Grade against the stated requirements and commensurate complexity, not enterprise threat models. XYZ-forge forbids new tests (AGENTS.md *No new tests*, GH-831): a new `test/` suite, `validate.sh` entry or gate machinery in the diff is a finding. The `.sh.txt` runner files under TESTS-RESULTS are command records, not executable suites; flag them if you disagree. Do not ask for new suites. You may run narrow read-only probes under `.relay-scratch/` (GH-681). Do not run `validate.sh`, `test/*.sh` or the runners in this worktree; grade such claims `[Unverified — needs clone run]`.

### Gate status
The classified route is full (`utils/ci-route.sh`: tier 3). `bash ci-local.sh` will run exactly once, in a disposable clone, on the commit this review approves. It has **not** run yet, so judge correctness, not gate status. Run so far: 25 focused existing suites in a disposable clone (pass=25), plus manual checks M1–M11 with red controls (all PASS; see README).

### Questions
1. For each acceptance-map row in the plan: does the code satisfy it, and does the cited evidence (log file, red control) actually observe that outcome? What prevents unchanged, unfixed code from passing each check, and where is the observed rejection in `logs/`?
2. `xyz-vendor.sh`: is the sticky-tier read correctly placed before the `releases.db` auto-promotion, and are the explicit upgrade/downgrade overrides right? Does the ledger branch of `materialize_vendor` skip anything that Tier 1/2 still need, and is Tier 1/2 output byte-for-byte unchanged in behaviour? Review the import check heredoc: are its exit semantics right (fail only on ModuleNotFoundError)?
3. `xyz-sync.sh` `check_rows`: the guard-loop `grep ... && break` placement. Does it skip only ledger rows, under `set -euo pipefail` semantics?
4. `hq-lib.sh`: does the ledger filter run before dedup, and is it safe when `$install/VERSION` is missing?
5. `pdda-lib.sh` root case and `pdda.sh` releases-current writer fallback: correct for a canonical checkout, a host-owned writer, and Tier 1/2 vendored copies? Is the new `--root "$PDDA_REPO_ROOT"` on the host-writer path a safe behaviour change?
6. `releases_app.py` `_import_jog_run`: are all jog entry points covered, and does `exc.name != "jog_run"` re-raise unrelated import errors?
7. Did a duplicate writer, speculative machinery or an unrelated change slip in? Is anything in the diff outside the plan?
8. The plan's rating is 55/30/50/40 (pri/sev/appeal/effort), with appeal neutral and no operator override. Does that still match the evidence?

Write graded findings with `file:line`. Put `VERDICT: PASS` or `VERDICT: FAIL` on its own line. Set STATUS to Approved only if the implementation is ready for the gate and PR.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
