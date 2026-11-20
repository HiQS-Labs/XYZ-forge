# RELAY · GH-1479 PR 1494 whole-PR review (agy)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-15.
-->

NEXT: Producer
STATUS: Approved
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

Grade findings [Blocker]/[Should]/[Nit]/[Unverified — no citation] with file:line citations. Flag anything wrong,
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

### Reviewer · Round 1

VERDICT: PASS
Basis: Independent whole-PR review of draft PR #1494 on branch `feat/XYZ-forge-gh1479-static-analysis-swarm-2026-11-14` (commit `c8b2e7f6d`). Both existing-test pin updates preserve their original protective intent without weakening; the `swarm_preflight.py` decomposition into typed stage functions strictly preserves linear side-effect ordering, return values, and exit codes; and static-analysis configuration (`mypy.ini`, `requirements-dev.txt`, workflow updates) is sound and correctly scoped.
swept file: yes

- [Pass] Question A.1 (gh642 pin mechanics): `test/gh642-consumer-fruit.sh:307` loosened `call_line=$(grep -n '^    warn_zero_criteria(' "$PYPREFLIGHT" | head -1 | cut -d: -f1)`. The four-space start anchor strictly excludes the column-0 definition at `utils/py/swarm_preflight.py:1240` (`def warn_zero_criteria(`) and matches only the runtime call at `:1990` (`warn_zero_criteria(evaluation.acc_mode, evaluation.acc_items, selection.primary_doc, args.format)`). The call at `:1990` and the first dry-run check at `:1992` (`if args.dry_run:`) are direct sequential statements inside `write_packet()` (`:1971-2167`) on the identical execution path. The ordering condition at `test/gh642-consumer-fruit.sh:309` (`[ "$call_line" -lt "$dry_line" ]`) remains a real protective guarantee: deleting the call empties `call_line` and fails the test, and moving the call after the dry-run exit (`:1998`) makes `call_line > dry_line` and fails the test. AST parse and string-mutation probes confirmed this ordering cannot silently regress.
- [Pass] Question A.2 (gh421 marker): `test/gh421-auto-wave-reconcile.sh:611` pins `'python3 -m pip install --quiet --break-system-packages -r requirements-dev.txt'` matching `.github/workflows/wave-reconcile.yml:52`. `requirements-dev.txt:1-4` explicitly supplies `pytest` along with `requests`, `PyYAML`, and `mypy==1.14.1`. The workflow step runs before the reconciliation execution step (`:54`), preserving the guarantee that Python test dependencies are installed prior to test runs.
- [Pass] Question A.3 (evaluation of weakening): Neither edit is a material weakening. In `test/gh642-consumer-fruit.sh:307`, the previous pin specifically matched `acc_mode` only because `acc_mode` was the old local variable name in the monolith; refactoring into `evaluation.acc_mode` necessitated updating the argument pattern. Anchoring to `^    warn_zero_criteria(` preserves the indentation and call-before-dry-run exit ordering while avoiding unnecessary coupling to internal record field names. In `test/gh421-auto-wave-reconcile.sh:611`, updating the assertion to `-r requirements-dev.txt` matches the refactored installation method, where `pytest` is retained in `requirements-dev.txt:2`.
- [Pass] Question A.4 (sweep of test/ for missed pins): A broad search across `test/` (`rg -n 'warn_zero_criteria|pip install|requirements-dev.txt|acc_mode|swarm_preflight' test/`) identified no stale pins or unhandled references to old `main()` internals. Literal checks in `test/gh386-turn-budget-honesty.sh:113` match the ladder at `utils/py/swarm_preflight.py:2085-2087`; `test/gh399-packet-acceptance-continuation.sh:217` matches `acc_lost = verify_inlined_acceptance(` at `utils/py/swarm_preflight.py:1727` and `ready, ready_next = 0, (` at `:1729`; and `test/gh557-unknown-blocks-manifest.sh:268` matches `"NOT verifiable as things stand"` at `utils/py/swarm_preflight.py:2042`.
- [Pass] Question B.5 (behaviour preservation): Compared old `main()` at merge base `4635abe09:1225-1950` against the decomposed implementation at `c8b2e7f6d`:
  - `parse_args()` and `resolve_source_selection()` (`utils/py/swarm_preflight.py:1338-1428`) preserve argument handling, mode mutual exclusivity, and target-root validation (old `:1225-1328`).
  - `load_contracts()` (`:1431-1463`) preserves contract shape and merge validation (old `:1292-1324`).
  - `inspect_repository()` (`:1466-1594`) preserves branch, fetch, status, index-lock detection, ref verification, and temporary worktree probe evaluation and cleanup (old `:1330-1440`).
  - `evaluate_candidate()` (`:1597-1845`) preserves the readiness evaluation ladder, gate routing, acceptance fidelity, source URL check, inline checklist extraction, and lane planning (old `:1442-1685`).
  - `normalize_candidate()` (`:1848-1886`) preserves construction of the candidate dictionary and normalization (old `:1645-1685`).
  - `report_candidate()` (`:1889-1965`) preserves formatted console output, JSON serialization, and early exit codes (6 for BLOCKED, 7 for AMBIGUOUS, 4 for STALE, 5 for NOT-READY) (old `:1690-1755`).
  - `write_packet()` (`:1968-2162`) preserves dry-run exit 0, packet directory creation, individual artifact writes, and final success exit 0 (old `:1757-1950`).
  - Primary doc slug computation was moved ahead of contract loading; because slug derivation is a pure regex function on `primary_doc` without I/O or state modification, this pure reordering produces no change in behavior or error paths.
- [Pass] Question B.6 (state hand-off): The three frozen dataclasses (`SourceSelection` at `:1260`, `RepositoryState` at `:1275`, `CandidateEvaluation` at `:1301`) faithfully encapsulate the intermediate state across stages. Mutable dictionaries and lists (`probes_res`, `frozen_artifacts`, `lane_plan_res`, `issue_state`) are created in their respective stages and passed forward strictly for reading, serialization, and reporting. No stage mutates container fields after instantiation.
- [Pass] Question B.7 (commensurate decomposition): The extraction of 7 stage functions with an 11-line `main()` (`:2165-2178`) strikes an appropriate balance. Keeping `evaluate_candidate` (~248 lines) and `write_packet` (~194 lines) intact preserves the readability and coherence of the linear readiness and packet generation flows without introducing unnecessary abstractions or fragmented helper classes.
- [Pass] Question C.8 (tooling and workflow portability): `mypy.ini:1-11` configures `python_version = 3.10` and `files = utils/py/swarm_preflight.py`. `follow_imports = skip` properly confines typechecking to the refactored module without erroring on untyped imported files. Workflows in `.github/workflows/ci.yml:184,402` and `.github/workflows/wave-reconcile.yml:52` install dependencies via `pip install --quiet --break-system-packages -r requirements-dev.txt`, which is compatible with GitHub Actions Ubuntu and macOS runner environments. `requirements-dev.txt` pins `mypy==1.14.1` while preserving `pytest`, `requests`, and `PyYAML`.
- [Pass] Question C.9 (Python layer gate diagnostics): In `test/test_python_layer.py:47-51`, `test_swarm_preflight_module_load` executes `[sys.executable, "-m", "mypy", "--config-file", ...]` via `subprocess.run`. If mypy is missing from the environment, Python emits `No module named mypy` on stderr and exits with code 1, which is asserted and displayed in the test failure output. `README.md:285-288` and `ROUTER.md:35` clearly document `python3 -m pip install -r requirements-dev.txt` as a requirement.
- [Pass] Evidence verification: Retained A/B comparison in `TESTS-RESULTS/2026-11-14+GH-1479/ab-compare/` contains 37 identical files between `old/` and `new/` across exits 0, 2, 3, 4, and 5. In `TESTS-RESULTS/2026-11-14+GH-1479/provenance.jsonl`, all 13 entries with `log_sha256` match their respective log files on disk byte-for-byte. Retained logs `post-mypy-pass.log:1` ("Success: no issues found in 1 source file") and `post-mypy-red-control.log:1-2` (incompatible return value type detected) confirm typechecking efficacy.
- [Nit] Pre-existing limitations observed during whole-file sweep of `utils/py/swarm_preflight.py`:
  1. Packet generation sequentially writes files (`:1999-2015`, `:2158-2159`) without writing to a staging directory first and performing an atomic rename, meaning an unexpected failure midway leaves a partial packet directory.
  2. Index lock detection (`:1512`) checks `os.path.join(target_root, ".git", "index.lock")`, assuming `.git` is a directory; in linked worktrees where `.git` is a pointer file, `.git/index.lock` is not checked.
  3. Worktree cleanup (`:1566-1567`) falls back to `shutil.rmtree` on remove failure, which could leave dangling worktree administrative entries in `.git/worktrees`.
  All three behaviors pre-existed the refactor; no modifications requested in this PR.
- [Unverified — needs clone run] In accordance with reviewer isolation rules, no full gate (`validate.sh`), pytest, or shell test suites were executed in this relay worktree. Final gate execution belongs in a disposable full clone managed by the harness.

Probe receipt (non-mutating source & AST analysis; exit 0). Ran `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"` and executed python inspection of AST structures, regex boundaries, dependency pins, and artifact hashes:
- AST confirmation: `write_packet` spans `:1971-2167`; `warn_zero_criteria` Call at `:1990`; `dry_run` If at `:1992`.
- Regex matching: `^    warn_zero_criteria(` matched exactly line 1990; `^def warn_zero_criteria(` matched line 1240; `^    if args.dry_run:` matched line 1992.
- Mutation simulation: Deletion of call yielded empty match (`call_match is None`); moving call after dry-run exit yielded `call_line (1992) < dry_line (1991) -> False`.
- Dependency & workflow probe: Marker present in `.github/workflows/wave-reconcile.yml:52`; `requirements-dev.txt` contains `mypy==1.14.1`, `pytest`, `requests`, `PyYAML`.
- Retained A/B parity: 37 of 37 files in `TESTS-RESULTS/2026-11-14+GH-1479/ab-compare/old` vs `new` identical byte-for-byte; all 13 provenance log SHA-256 hashes verified.

Relay closed (Approved), no further turn needed. Harness owns the file-scoped commit and subsequent gate.



### Attestation · relay-drive — 2026-11-16T01:34:24Z
task: RELAY-gh1479-pr-review-agy
reviewer: agy
status: Approved
reviewed-head: ce1b37cada1146ffccf51b37bf62892ae5d0f114
added-range: 11101+9824
added-sha256: 6cf9e71515714ca4e40a326167f8c562a9973357fe0ed73e104b5e9ebcc7cdda
gate-run: undeclared
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
