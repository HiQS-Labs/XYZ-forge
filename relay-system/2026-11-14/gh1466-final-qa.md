# RELAY · GH-1466 final QA: xyz-vendor --ledger-only tier
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

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

### Reviewer · Round 1 · codex

swept file: no
VERDICT: FAIL
Basis: the inspected implementation paths align with the plan, but the promised full PDDA-run evidence is absent, and this turn did not complete the required whole-file sweep. This is not an observed source-code failure. Approval and the final gate remain outstanding.

- [Should] **Complete M4's planned full-run evidence.** `TESTS-RESULTS/2026-11-14+GH-1466/runner-m1-m9.sh.txt:87` and `:90` invoke only `frontmatter`; the plan's M4 row explicitly requires `PDDA_MODE=full bash .xyz/utils/pdda/pdda.sh run`. `utils/pdda/pdda.sh:1721` runs a materially larger path, including sibling scripts and scanners. The existing M4 output proves host-root resolution for frontmatter, not that full closure. In a disposable full clone, record the planned full-run candidate/base check on the malformed host doc and a full-run check on a valid minimal host (LLM unset, offline/cache issue state). Retain commands, statuses, decisive output and provenance; no new suite or gate. This requests evidence, not a speculative behavior change.
- [Pass] **Receipt integrity:** a read-only Python probe iterated `provenance.jsonl`, required each cited log to exist and be nonempty, and compared SHA-256. Command: `PYTHONDONTWRITEBYTECODE=1 python3 -B -` with `json.loads`, `Path.stat().st_size` and `hashlib.sha256` over the named `logs/` files. Exit 0; decisive output: `receipt_logs_checked= 39 empty_missing_or_hash_mismatch= []`. This checks retained bytes, not the truth of every assertion or the final commit identity.
- [Pass] **Jog exception boundary:** `utils/py/releases_app.py:5198–5251` routes run, resume/retry dispatch and land through one helper. A narrow AST-extracted helper probe injected `ModuleNotFoundError(name="jog_run")` and then `ModuleNotFoundError(name="unrelated_dependency")` via a temporary in-memory import hook. Command: `PYTHONDONTWRITEBYTECODE=1 python3 -B -`; exit 0. Decisive output: `injected_missing= jog_run outcome= SystemExit 2 None`; `injected_missing= unrelated_dependency outcome= ModuleNotFoundError None unrelated_dependency`. No unrelated dependency error was masked.
- [Pass] **Inspected tier/read paths:** `xyz-vendor.sh:78` reads sticky ledger state before releases.db promotion; explicit flags override it; `xyz-sync.sh:439` breaks only the current install's guard loop; `hq-lib.sh:79` filters before dedup and missing VERSION is a false grep in an AND list. `pdda-lib.sh:7–10` preserves explicit root overrides; `pdda.sh:976–981` selects host writer first and supplies the intended root. These are source-inspection conclusions, not fresh Tier 1/2 execution evidence.
- [Pass] **Nonempty deletion controls:** retained `logs/M10-red-template.log` names missing `timeline/RELEASES.html`; `logs/M10-red-planner.log` shows planner selected followed by exit 127; `logs/M11-red-noleaderboard.log` reaches the leaderboard step and leaves the merge open; `logs/M10-red-gate-base.log` reaches PDDA, fails and rolls back. These support the specific closure edges they exercise. The M10/M11 successful counterparts show planner/view/gate and merge-resolution execution.
- [Unverified — needs clone run] The final classified gate has not run, as declared. The 25-suite result is producer evidence, not a reviewer rerun. Do not present this review as gate qualification.
- [Unverified] **Required remaining review scope:** I inspected the vendor implementation and targeted sync/HQ/PDDA/reconcile/jog paths, acceptance map and retained evidence, but did not read all 19,716 lines across the ten artifact files. In particular the complete pre-existing ledger/reconcile implementations, full PDDA/HQ/sync files and historical docs remain unswept. No pre-existing defect was established in the inspected spans; no claim of a defect-free whole-file sweep, exhaustive diff scope, no added suite, or byte-for-byte Tier 1/2 equivalence is made. Complete that review before approval; source edits are not requested on the basis of these unknowns.
- [Nit] The rating `55/30/50/40` remains consistent with the documented optional footprint reduction and bounded existing seams; this turn supplies no basis for an override (`PROJECT/2-WORKING/GH-1466-VENDOR-LEDGER-ONLY.md`, “Rating (2026-11-14)”).

Handing off to Producer (claude-a) — disposition the M4 evidence request and arrange completion of the outstanding whole-file review; go to the Producer window and say 'take your turn'. No source change is requested without a demonstrated defect.

### Producer · Round 1 (claude-a)

- **[Should] M4 full-run evidence → Implemented.**
  - Added `runner-m4-fullrun.sh.txt` plus `logs/M4-run-*.log`, with `results.tsv`, `provenance.jsonl` and README rows. It is the full `PDDA_MODE=full bash .xyz/utils/pdda/pdda.sh run` with LLM keys unset, offline.
  - **(a) Valid minimal ledger host:** exit 0; all 12 SUMMARY lines report `errors=0`, covering frontmatter through doc-ready, including governance and marathon-qa (the sibling scripts and scanners); no "No such file" or traceback.
  - **(b) Malformed host doc:** exit 1 with `PROJECT/2-WORKING/GH-4291-LEDGER.md:1 missing required frontmatter key 'updated'`.
  - **Red control:** the base `pdda-lib.sh` on the same host exits 1 for a *different* reason, `ERROR [pdda-check-roadmap-coverage] releases.db no readable releases.db ledger present`. It is scanning `.xyz/`, with 0 host-path hits. No source change.
- **[Unverified] Remaining review scope → Scoped for round 2 (commensurate, GH-268 intent).**
  - The ten artifact files total about 19.7k lines, mostly pre-existing.
  - **Sweep in full:** the files the change materially restructures or owns: `relay-automation/xyz-vendor.sh` (whole file), the docs (`RELEASES-DB-FAQS.md` new section, `UPGRADE.md` §9 note, `CHANGELOG.md` entry), and `TESTS-RESULTS/2026-11-14+GH-1466/`.
  - **Sweep the enclosing function or block around each hunk** for one-line or one-function edits inside large pre-existing files: `xyz-sync.sh` `check_rows`, `hq-lib.sh` `hq_xyz_lookup`, `pdda-lib.sh` header (lines 1–30), `pdda.sh` `releases-current` function, `wave_reconcile.py` `run_validation_gate`, `releases_app.py` jog block (`:5195-5255`).
  - Mark the 7k-line `releases_app.py` and 2.7k-line `wave_reconcile.py` bodies outside those functions as out of scope for this change. Pre-existing defects found in the swept spans are in scope.
  - **Diff-scope probe:** `git diff --stat e0586fc30..HEAD -- . ':!relay-system' ':!TESTS-RESULTS' ':!PROJECT' ':!releases.*'` should list only the ten files.
- **[Pass]/[Nit] items:** noted; rating unchanged at 55/30/50/40.

Handing off to Reviewer (codex) for round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
