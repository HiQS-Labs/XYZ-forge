# RELAY · GH-1466 plan QA: xyz-vendor --ledger-only tier
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
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
6. **Commit only the relay file** (`relay(gh1466-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-1466-VENDOR-LEDGER-ONLY.md` (the plan; no code has been written yet). Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1466 (its first comment holds an earlier consult's dispositions).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-14
- Definition of Done: the plan is grounded in the real code paths, covers every #1466 requirement, extends the existing vendor/sync/hq/pdda writers without a parallel subsystem, and has falsifiable checks that reject today's unfixed code.

### Operational envelope
Local developer CLI (bash + python) that vendors a harness into a host repo on one machine. Grade against the stated requirements and commensurate complexity, not enterprise multi-tenant threat models. XYZ-forge forbids new tests (AGENTS.md *No new tests*, GH-831): a new `test/` suite, `validate.sh` entry or gate machinery is a finding, and verification is existing suites plus manual checks under `TESTS-RESULTS/`. Do not ask for new suites.

### Step 1: paraphrase first (GH-1414)
Read ONLY the plan doc first, before the issue, any other source file, or this Setup's questions. Then write, in your review block, before anything else:
- **What this proposes** (2–5 sentences)
- **How the existing system works, per this document** (2–5 sentences)
- **What it's not**: exclusions grounded in the plan's sections. Label excluded vs deferred vs unresolved, and label any inference.
State the input boundary ("written after reading only the plan doc").

### Step 2: source-backed validation
Now read the issue and the cited sources: `relay-automation/xyz-vendor.sh`, `relay-automation/xyz-sync.sh`, `utils/hq/hq-lib.sh`, `utils/hq/hq.sh`, `utils/pdda/pdda-lib.sh`, `utils/pdda/pdda.sh`, `utils/py/wave_reconcile.py`, `utils/py/releases_app.py`, `utils/py/harness_paths.py`, `utils/py/work_connectors/`, `utils/py/board_sync.py`, `utils/py/_marathon_plan.py`, `utils/marathon-plan.sh`, `utils/releases-merge-resolve.sh`, `test/gh197-vendor-tier-split.sh`. Label this part **source-backed**.

Questions:
1. Is the LEDGER_MANIFEST closure complete for `releases_app.py` (including lazy paths reached by ordinary ledger writes), `wave_reconcile.py` (non-dry-run), `marathon-plan.sh`, `releases-merge-resolve.sh` and `pdda.sh`? Name any missing module, script or data file with `file:line`.
2. Does reading `.xyz/VERSION tier=ledger` before the `releases.db` auto-promotion (`xyz-vendor.sh:66-72`) make the tier persist across `xyz-sync update` (`xyz-sync.sh:296`)? Any path that bypasses it?
3. Is the import smoke in step 3 a fair closure guard under GH-831, or does it miss something that matters?
4. Is filtering `tier=ledger` inside `hq_xyz_lookup` the right single seam, and is skipping only the guard probe in `check_rows` correct, given that `tick_version` is harness-derived (`xyz-vendor.sh:196`)?
5. Is the `pdda-lib.sh:6` root change safe for non-vendored and Tier 1/2 copies? Is the `wave_reconcile.py:2098` fallback correct?
6. For each manual check M1–M11: what prevents unchanged, unfixed code from passing it, and where is the intended rejection? Are the red controls real?
7. Is the plan surgical and DRY? Flag any duplicate writer, speculative machinery or over-build.

Write graded findings with `file:line`. Set STATUS to Approved if the plan is ready to build; otherwise hand back to the Producer.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

**What this proposes** (written after reading only the plan doc): Add a persistent `--ledger-only` tier to the existing vendor, shipping the ledger, reconcile, PDDA and their planner/view dependencies. Keep the tier across sync, exclude it from HQ driven-lane eligibility, and refuse Jog execution cleanly.

**How the existing system works, per this document:** The vendor mirrors a full harness and uses a deny-list for Tier 1; a root releases.db auto-selects Tier 2. Sync re-invokes the vendor without flags. Existing harness-tool resolution provides host-first lookup, while vendored PDDA currently derives the wrong host root.

**What it's not:** Excluded: packaging, write-timing changes, host adoption/removal, registry schema changes, new suites and Tier 1/2 content changes (Non-goals). Deferred: packaging to #1224. Unresolved: whether the proposed reduced closure check and file count satisfy the issue's stronger acceptance contract; this requires an explicit disposition, not an inferred waiver.

swept file: yes

**source-backed — VERDICT: FAIL**

**Basis:** The overall design reuses existing writers and seams, but verification and acceptance gaps below need a plan revision before implementation. This is a full sweep of the plan, including its recon, risks, rating and acceptance map; source inspection found the pre-existing vendored `releases-current` gap noted below. No code or suites were executed. Runtime claims requiring fixtures remain **[Unverified — needs clone run]**.

- [Pass] Sticky tier selection is at the right boundary: `xyz-sync.sh:296` invokes the vendor without flags, and `xyz-vendor.sh:66-72` auto-promotes on releases.db. Implement plan step 1 before that branch, moving/initializing VENDOR_DIR before reading it (currently assigned at `xyz-vendor.sh:74`). Both single-target and `--all` updates share this invocation. Explicit upgrades/downgrades must override the persisted tier as specified.
- [Pass] HQ filtering belongs before row deduplication in `utils/hq/hq-lib.sh:75-98`; all five callers then inherit it. `xyz-vendor.sh:196-199` reads the harness schema version, so retaining tick/source drift checks while skipping only the ledger relay-guard probe (`xyz-sync.sh:433-440`) is appropriate. No second registry writer/schema is needed.
- [Pass] The manifest includes the identified default Python import chain (`_marathon_plan.py:33-35`, `work_connectors/__init__.py:35,95`, `work_connectors/github_board.py:58`), planner zones and timeline directory. PDDA root handling preserves explicit overrides and canonical layout; the wave fallback uses the existing resolver (`harness_paths.py:92-130`). These are static design assessments, not a successful offline run.

- [Should] **Make M10/M11 branch-complete and reconcile the closure-check promise.** Plan lines 94-96 call the import smoke “the closure guard,” but it cannot detect missing shell scripts, lazy imports or the HTML template. Issue #1466 explicitly requested those paths, while the plan describes the gap as only future drift. M10 does not explicitly seed enabled projections/adopted views or assert their changed outputs; M11 does not seed adopted views at all. Thus the optional downstream branches can be skipped while these checks appear green.
  Observed input: `wave_reconcile.py:2028-2045` skips exports when projections=off or adopted files are absent; `utils/releases-merge-resolve.sh:195-224` exports only entries in REGEN; `utils/timeline/export_timeline.py:521,570` reads RELEASES.html only during export. None is exercised by importing the five smoke modules.
  Affected scope: the ledger installation's promised non-dry-run reconcile and merge-resolution closure, specifically adopted views, planner and PDDA subprocesses.
  Falsifier: in a disposable full clone, remove the staged timeline template or planner shell entry point after a successful import smoke; the relevant offline operation must fail. The intact install must exit 0, regenerate adopted preview/leaderboard outputs from changed ledger data, execute the planner and use vendored PDDA with host copies absent.
  Fix: retain the cheap import sanity check, explicitly label its limited coverage, and specify those seeded fixtures/output assertions and manual deletion controls under existing TESTS-RESULTS evidence. Explicitly disposition the issue's stronger automated-closure request under GH-831; do not add a suite or new guard framework.

- [Should] **Give M4–M9 discriminating controls and failure assertions.** M4's “broken doc” is unspecified and the default PDDA mode reports errors with exit 0; M5's base cannot create a ledger install itself; M7/M8 may trivially pass with an empty/unselected registry. M9 covers only one of three guarded entry points. M6's conflict alone already exits 2 today as an unknown flag.
  Observed input: plan lines 116-121; `pdda-lib.sh:40-58` defaults to observe and gates errors to zero; `xyz-sync.sh:420-421` returns early on no selection; `hq-lib.sh:70` returns on missing registry; `xyz-vendor.sh:43-45` rejects unknown flags with exit 2.
  Affected scope: proof of the changed tier-persistence, relay-guard exemption, HQ filtering, PDDA host root and Jog refusal decisions.
  Falsifier: replay each consumer against the same preseeded ledger VERSION/registry host with only its relevant fix absent; expect base guard warning, base Tier A eligibility, base tier=2 update, missing host-doc detection or Jog traceback respectively. Intact candidate must reverse those observations. Valid Tier 1/2 rows must retain guard/drift enforcement.
  Fix: specify exact invalid host frontmatter and `PDDA_MODE=full` for M4; seed the same ledger install for base M5; require a selected matching registry row and inspect expected HQ refusal reason, not merely nonzero; exercise run/verb-dispatch/land refusal; assert M6 upgrade inventory and distinguish flag conflict from unknown-option failure. Keep M1/M2/M3 inventory/missing-source/import failures; these already describe meaningful rejection points. M10/M11 need the controls above. Smoke/regression checks need not each fail on the whole old implementation, but every changed decision needs an isolated red control.

- [Should] **Account for the pre-existing PDDA releases-current host-only lookup.** The plan says PDDA's closure uses sibling paths, but `pdda.sh:976-978` still requires the writer at the host root. Correcting PDDA_REPO_ROOT alone leaves this shipped ledger command reporting no ledger when releases.db exists only at the host and the CLI exists only in .xyz.
  Observed input: host `releases.db` present, host `utils/py/releases_app.py` and RELEASES.md absent, vendored writer present; `pdda.sh:976-984` bypasses the DB branch and prints “RELEASES.md not found.” Static source observation; not a runtime reproduction.
  Affected scope: `pdda.sh releases-current` in vendored installs with a DB-only ledger; ordinary deterministic checks need not change.
  Falsifier: execute that layout with an active release in a disposable clone; expect that release listed. A host-owned writer and a canonical checkout must still behave as before.
  Fix: include a small sibling/host-aware lookup using an existing resolution convention, or explicitly exclude/disposition this command with the producer's rationale. Do not claim the full PDDA surface works offline without addressing it.

- [Nit] Explicitly disposition issue inventory/docs deltas: the three recursive directory payloads alone contain 29 files, before 14 individually listed Python files and remaining entries. M1 records count but never checks the issue's “at most ~30 files”; the plan also drops the issue's UPGRADE.md note. Keeping dependency closure may justify a larger count, but name that accepted tradeoff rather than mapping M1 to full issue acceptance. Read-only probe: `python3` with `Path(d).rglob('*')` over utils/pdda, utils/timeline and utils/py/work_connectors, excluding pycache/pyc, exited 0: `recursive directory payload files: 29`; parsing the manifest's Python backtick names yielded `manifest explicitly enumerated Python files: 14`.

Handing off to Producer (claude-a) — revise/disposition these findings and take the next turn. Only this relay file changed; no git commands, fixtures, tests or gates were run.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
