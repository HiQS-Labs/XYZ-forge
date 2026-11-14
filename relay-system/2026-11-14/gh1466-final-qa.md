# RELAY · GH-1466 final QA: xyz-vendor --ledger-only tier
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-14.
-->

NEXT: Producer
STATUS: Approved
ROUND: 3 / 3

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
- **[Unverified — no citation]/[Nit] items:** noted; rating unchanged at 55/30/50/40.

Handing off to Reviewer (codex) for round 2.

### Reviewer · Round 2 · codex

swept file: yes
VERDICT: FAIL
Basis: M4's evidence gap is resolved, and the whole-file sweep is complete, including pre-existing code and historical docs. Two narrow read-only probes establish real failures: the new HQ filter loses registered host location, and the normal reconciler's pre-existing lock path fails for linked worktrees. These require disposition before approval. The final gate remains outstanding.

- [Should] **R2-1 — Preserve registry location while declining driven-lane capability.** `utils/hq/hq-lib.sh:79` drops the entire ledger row; `:256–258` then falls back to filesystem search because no registry path survives. A ledger host outside the search roots becomes UNRESOLVED instead of the promised Tier B. M8's `runner-m1-m9.sh.txt:10` puts every fixture under `HQ_SEARCH_ROOTS`, and `logs/M8-status-candidate.log` explicitly reports `via filesystem`, so that evidence masks the lost locator. Preserve the existing registry's host identity/path independently of dispatch eligibility, retaining ambiguity/dedup guarantees; keep ledger hosts ineligible for driven lanes. No new registry or suite is needed.
  Observed input: a single TSV row `<scratch>/outside-search/ledger-host/.xyz<TAB>2026-11-14<TAB>1<TAB>seed<TAB><scratch>/outside-search/ledger-host`, an existing coordinate directory, `VERSION=tier=ledger`, and an empty search root elsewhere.
  Affected scope: registered ledger-only hosts whose path cannot be rediscovered through the depth-capped filesystem fallback.
  Falsifier: that same ledger row resolves a nonempty `REPO_PATH` with exit 0 while status remains Tier B and fire refuses; an otherwise identical Tier 2 row retains Tier A. A result showing successful ledger resolution under the measured inputs would disprove this finding.
  Probe command (scratch data only; no Git or executable fixture):
  ```bash
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  mkdir -p "$TMPDIR"
  P="$TMPDIR/hq-ledger-lookup"
  mkdir -p "$P/outside-search/ledger-host/.xyz" "$P/search" "$P/pdda"
  printf 'tier=ledger\n' > "$P/outside-search/ledger-host/.xyz/VERSION"
  printf '%s\t2026-11-14\t1\tseed\t%s\n' "$P/outside-search/ledger-host/.xyz" "$P/outside-search/ledger-host" > "$P/registry.tsv"
  export HQ_XYZ_REGISTRY="$P/registry.tsv" HQ_SEARCH_ROOTS="$P/search" HQ_PDDA_REGISTRY_DIR="$P/pdda" HQ_REBALANCE_DB="$P/absent.db"
  bash -c 'source utils/hq/hq-lib.sh; hq_resolve ledger-host; printf "resolver_rc=%s\n" "$?"'
  printf 'tier=2\n' > "$P/outside-search/ledger-host/.xyz/VERSION"
  bash -c 'source utils/hq/hq-lib.sh; hq_resolve ledger-host; printf "resolver_rc=%s\n" "$?"'
  printf 'tier=ledger\n' > "$P/outside-search/ledger-host/.xyz/VERSION"
  ```
  Shell exit 0. Decisive output: ledger `REPO_PATH=`, `REPO_PATH_SOURCE=unresolved`, `resolver_rc=1`; changing only the VERSION stamp to Tier 2 yields the registered path, `REPO_PATH_SOURCE=xyz-registry`, `resolver_rc=0`.
  Root cause: capability filtering discards authoritative location; Fix site: existing HQ resolver/capability boundary; Why not downstream: searching more directories cannot preserve the registry's authoritative identity.

- [Should] **R2-2 — Reuse the existing worktree-aware lock-directory helper.** Pre-existing, found by the required whole-file sweep: `utils/py/wave_reconcile.py:2436` constructs `<root>/.git/wave-reconcile.lock` and `:2479` acquires it. This checkout's `.git` is a file, so that acquisition fails before ledger work. `reconciler_git_dir()` at `:1132–1140` already handles linked-worktree gitdir/commondir and is used by the sweep and delivery paths (`:1148`, `:2267`). Reuse it in the normal reconciler instead of creating a second lock-resolution mechanism.
  Observed input: this linked checkout's existing `.git` file and the normal main-path lock operand.
  Affected scope: normal reconciliation with a root whose `.git` is a file; ordinary full clones retain their current lock location.
  Falsifier: a linked-worktree root resolves/acquires the common-directory lock, and a full clone resolves the same `.git/wave-reconcile.lock` as before. The current file-based root acquiring the current main-path operand would disprove the observed failure.
  Probe command (AST-extracted lock only, not main, no Git, no files written):
  ```bash
  export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  python3 -B - <<'PYPROBE'
  from pathlib import Path
  import ast, os, fcntl, sys
  from datetime import datetime
  p=Path('utils/py/wave_reconcile.py')
  t=ast.parse(p.read_text())
  ns={'os':os,'fcntl':fcntl,'datetime':datetime,'sys':sys}
  for n in t.body:
      if isinstance(n,(ast.ClassDef,ast.FunctionDef)) and n.name in {'ReconcileError','ReconcilerLock','die','log_err'}:
          exec(compile(ast.Module(body=[n],type_ignores=[]),str(p),'exec'),ns)
  print('dotgit_is_file=',Path('.git').is_file())
  try:
      with ns['ReconcilerLock'](str(Path.cwd()/'.git'/'wave-reconcile.lock')): print('acquired')
  except ns['ReconcileError'] as e:
      print('outcome=ReconcileError code=',e.code,'message=',str(e))
  PYPROBE
  ```
  Probe exit 0; decisive output: `dotgit_is_file= True`, `outcome=ReconcileError code= 8`, `[Errno 20] Not a directory: '<cwd>/.git/wave-reconcile.lock'`. This measures the actual lock primitive/operand, not an end-to-end reconcile run.
  Root cause: main assumes .git is a directory; Fix site: main's lock operand; Why not upstream/downstream: the existing helper already resolves the supported Git layout.

- [Nit] **R2-3 — Narrow the runtime-flip wording.** `UPGRADE.md:560–562` says ledger installs have no “shims at all” and “nothing to toggle”. The manifest includes `utils/marathon-plan.sh`, whose `:19–43` selects Python/Bash via `XYZ_PYTHON`. Say no relay/agent shims; the retained planner still follows its existing runtime selection.

- [Pass] **M4 request resolved; receipt bytes checked.** `logs/M4-run-valid-candidate.log` ends `PDDA run complete: no errors, 2 warning(s)`; the malformed counterpart names `PROJECT/2-WORKING/GH-4291-LEDGER.md:1 missing required frontmatter key 'updated'`; the base-lib control instead reports `no readable releases.db ledger present` while scanning .xyz. A read-only `python3 -B -` probe parsed every provenance row, asserted each named log was nonempty, checked SHA-256, asserted exactly 12 valid-host SUMMARY lines all contained `errors=0`, and asserted the candidate/base distinguishing strings. Exit 0: `receipt_logs_checked= 42 hash_mismatches=0 M4_valid_summaries= 12 M4_bad_host_finding=yes base_wrong_root=yes`. This validates retained evidence, not a fresh full-run execution.

- [Pass] **Acceptance seams other than the HQ locator concern have support.** Inventory/source/import controls are retained in `logs/M1-inventory.txt`, `M2-vendor.log`, `M3-vendor.log`; sticky/conflict/upgrade/downgrade evidence is in `M5-*.log` and `M6-*.log`. The guard loop (`xyz-sync.sh:439`) breaks only its inner loop, and missing VERSION is safe in the AND list; `M7-check-candidate.log` and `M7-check-tier2.log` distinguish ledger exemption from Tier 2 missing-guard warnings. Jog runtime call sites all use the narrow missing-module helper (`releases_app.py:5198–5251`, reconcile alias `:7200`); M9 retains exit-2 candidate versus traceback base outputs. PDDA preserves explicit roots and host-first writer selection (`pdda-lib.sh:7–10`, `pdda.sh:976–981`); reconcile's changed fallback uses the existing `harness_tool` (`wave_reconcile.py:2098`). M10/M11 logs and deletion controls observe planner/view/PDDA/merge-resolve closure as recorded in round 1. No duplicate writer was established in the whole source-file sweep.

- [Pass] **Import heredoc semantics measured in memory.** Extracted the actual Python body at `xyz-vendor.sh:518–528` and temporarily replaced `importlib.import_module` in a `python3 -B -` process with three controlled outcomes. Exit 0 after assertions; decisive output: `smoke_case=missing exit=1`, `smoke_case=other-error exit=0`, `smoke_case=ok exit=0`. Thus ModuleNotFoundError refuses while TypeError warns/proceeds as documented. The first extraction attempt mistakenly included the shell continuation and exited 1 with IndentationError; the corrected extraction began at `import importlib, sys` before any behavioral conclusion. `bash -n relay-automation/xyz-vendor.sh relay-automation/xyz-sync.sh utils/hq/hq-lib.sh utils/pdda/pdda-lib.sh utils/pdda/pdda.sh` also exited 0.

- [Unverified — needs clone run] The final classified gate and fresh Tier 1/2 execution remain outstanding; the 25 existing suites are producer evidence. No Git command, suite, pytest or executable fixture was run this turn. The raw base-to-head file list was not independently regenerated under the explicit Git prohibition, so this review does not certify exact diff inventory/no added suite from a fresh diff. Whole-file coverage was completed collectively by this reviewer and read-only recon subagents: all ten Setup files, including all 4,718 CHANGELOG lines. Apart from R2-2, no additional pre-existing source defect was established. Historical changelog entries were treated as dated records, not current runtime promises.

- [Nit] The plan's `55/30/50/40` rating still fits the bounded optional-footprint change; these observations do not justify an operator override.

Handing off to Producer (claude-a) — disposition R2-1/R2-2, correct R2-3 if accepted, and retain focused red/green evidence in a disposable clone without adding a suite. Go to the Producer window and say 'take your turn'.

### Producer · Round 2 (claude-a)

- **[Should] R2-1 — Preserve registry location while declining driven-lane capability → Implemented (`2e6a1eb51`).**
  - `utils/hq/hq-lib.sh`: removed the early `tier=ledger` skip in `hq_xyz_lookup` so registered ledger hosts remain in `matches` with full same-repo dedup and cross-repo basename ambiguity checks intact. When `chosen` has `tier=ledger` in `$c_install/VERSION`, `hq_xyz_lookup` emits `XYZ_REG_PATH=<coord>`, `XYZ_INSTALL=<install>`, `XYZ_TIER=ledger` (without `XYZ_PATH=`). `hq_repo_resolve` falls back to `XYZ_REG_PATH` after `XYZ_PATH`, preserving `REPO_PATH` and `REPO_PATH_SOURCE=xyz-registry` without falling back to `hq_fs_find`. All driven-lane/tier checks in `hq.sh` read `XYZ_PATH`, so ledger hosts resolve as Tier B (with PDDA) or Tier C (without) and `hq fire` refuses (`is not Tier A`).
  - **Evidence (`TESTS-RESULTS/2026-11-14+GH-1466/logs/R2-1-candidate.log`, `R2-1-red-prior.log`, `runner-r2-fixes.sh.txt`):** `ledger-host` outside `HQ_SEARCH_ROOTS` resolves `REPO_PATH` via `xyz-registry` (`resolver_rc=0`), `hq status` shows `Tier B` (`via xyz-registry`), `hq fire` refuses (`fire_rc=1`), identical `tier2-host` shows `Tier A`, cross-repo `api` collision returns `collision_rc=2` (`RESOLVED_VIA=ambiguous`), and `dup-ledger` (legacy `xyz-tick` + `.xyz` `tier=ledger`) collapses to `.xyz` (`dup_rc=0`, `XYZ_TIER=ledger`). Red control at prior `af858405d` fails with `resolver_rc=1`, `REPO_PATH_SOURCE=unresolved`.
- **[Should] R2-2 — Reuse the existing worktree-aware lock-directory helper → Implemented (`2e6a1eb51`).**
  - `utils/py/wave_reconcile.py:2436`: replaced `os.path.join(repo_root, ".git", "wave-reconcile.lock")` with `str(reconciler_git_dir(repo_root) / "wave-reconcile.lock")`, matching `sweep_issue_docs` (`:1146`) and jog delivery (`:2267`).
  - **Evidence (`TESTS-RESULTS/2026-11-14+GH-1466/logs/R2-2-candidate.log`, `R2-2-red-prior.log`, `runner-r2-fixes.sh.txt`):** `wave_reconcile.py --dry-run` in a real linked worktree (`dotgit_wt_is_file=True`) exits `wt_rc=0` and in the full clone (`dotgit_full_is_dir=True`) exits `full_rc=0`. Red control at `af858405d` on the same linked worktree exits `wt_rc=8` with `[Errno 20] Not a directory: '<work>/r22/wt/.git/wave-reconcile.lock'`.
- **[Nit] R2-3 — Narrow the runtime-flip wording → Implemented (`2e6a1eb51`).**
  - `UPGRADE.md:560-563`: narrowed to say no `relay-automation/` or relay/agent shims, noting that the retained `utils/marathon-plan.sh` still follows its existing `XYZ_PYTHON` runtime selection. Updated `CHANGELOG.md` wording for `hq_xyz_lookup` to match.
- **[Unverified — needs clone run] Fresh diff inventory & focused suites on `2e6a1eb51`:**
  - `git diff --stat origin/development..HEAD -- . ':!relay-system' ':!TESTS-RESULTS' ':!PROJECT' ':!releases.*'` lists only the 10 expected files (`165 insertions(+), 38 deletions(-)`).
  - Re-ran 28 focused existing suites (`hq*`, `gh238`, `gh239`, `gh197`, `gh105`, `gh312`, `gh358`, `gh448`, `wave-reconcile`, `xyz-vendor`, `gh429`, `gh293`, `xyz-sync-check`, `gh292`, `pdda*`, `gh365`, `gh568`, `jog-queue`, `gh280`, `gh53`, `gh349`, `gh708`) in a disposable clone of `2e6a1eb51`: `pass=28 fail=0` (`provenance.jsonl` `focused-suites-r2`). Full `bash ci-local.sh` will run once in a disposable `-gate` clone on the approved commit.
- **[Nit] Rating:** `55/30/50/40` unchanged.

Handing off to Reviewer (codex) for round 3 — go to the Reviewer window and say 'take your turn'.

### Reviewer · Round 3 · codex

swept file: yes
VERDICT: PASS
Basis: ready for the declared disposable-clone gate and subsequent PR workflow. The round-two whole-file sweep remains the review baseline; this turn inspected the producer's fixes and their consumers/evidence. R2-1, R2-2 and R2-3 are resolved. No additional pre-existing defect was established. Approval does not certify the outstanding full gate.

- [Pass] **R2-1 resolved.** `utils/hq/hq-lib.sh:138–145` keeps the chosen ledger registry location in `XYZ_REG_PATH` while withholding `XYZ_PATH`; `:266–269` uses that location before filesystem search. Dispatch consumers still test `XYZ_PATH` (`utils/hq/hq.sh:248`, `:531`, `:605`, `:647`). Narrow scratch-only probe: create one ledger registry row outside an empty search root, then run `HQ_XYZ_REGISTRY="$P/registry.tsv" HQ_SEARCH_ROOTS="$P/search" HQ_PDDA_REGISTRY_DIR="$P/pdda" HQ_REBALANCE_DB="$P/absent.db" bash -c 'source utils/hq/hq-lib.sh; hq_resolve ledger-host; printf "resolver_rc=%s\n" "$?"'`. Exit 0; decisive output: `XYZ_TIER=ledger`, nonempty `XYZ_REG_PATH` and `REPO_PATH`, `REPO_PATH_SOURCE=xyz-registry`, `resolver_rc=0`, no `XYZ_PATH=`. Retained `logs/R2-1-candidate.log` additionally observes Tier B, `fire_rc=1`, Tier 2 Tier A, collision rc=2 and duplicate rc=0; `R2-1-red-prior.log` records the original unresolved rc=1.
- [Pass] **R2-2 resolved through reuse.** `utils/py/wave_reconcile.py:2436` now uses `reconciler_git_dir` (`:1132–1140`), matching the existing sweep lock. Read-only AST-extracted helper probe with `python3 -B -` asserted this checkout's .git is a file and the resolved common gitdir is a directory; exit 0, output `linked_gitdir_is_directory= True`, `normal_main_uses_helper= True`. No lock was acquired or Git command invoked here. Retained `logs/R2-2-candidate.log` records linked-worktree `wt_rc=0` and full-clone `full_rc=0`; `R2-2-red-prior.log` records the same linked-root scenario failing with Errno 20 and `wt_rc=8`.
- [Pass] **R2-3 resolved.** `UPGRADE.md:560–563` now says no relay/agent shims and explicitly retains the planner's existing `XYZ_PYTHON` selection.
- [Pass] **Retained receipt integrity.** Command: `PYTHONDONTWRITEBYTECODE=1 python3 -B -`, parsing every provenance JSON row, asserting each named log nonempty, and comparing SHA-256. Exit 0; decisive output `receipt_logs_checked= 46 hash_mismatches=0`. This checks retained bytes, not independent reruns. `bash -n utils/hq/hq-lib.sh` also exited 0.
- [Unverified — needs clone run] The full classified `bash ci-local.sh` gate remains outstanding by the Setup contract. The 28 focused suites and broader candidate/base executions are producer evidence. No suite, executable fixture, pytest or Git command ran in this turn; exact diff inventory was not independently regenerated under the Git prohibition. Earlier acceptance conclusions and the unchanged 55/30/50/40 rating stand.

Relay closed (Approved), no further turn needed. Producer/harness acts next: run the declared full gate in its disposable clone before claiming gate qualification or PR readiness.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
