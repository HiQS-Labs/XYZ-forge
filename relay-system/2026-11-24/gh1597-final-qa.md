# RELAY · GH-1597 Linux merge-cleanup Final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-24.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

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
     change MUST carry `Observed input:`, `Affected scope:` (the input predicate the change would govern),
     and `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected
     result). `Observed input:` accepts two strict, non-speculative forms:
     (1) **Form 1 (observed failure or artifact contradiction):** a failing probe/gate output, or a concrete
     `fileA:line` vs `fileB:line` contradiction (e.g. IAM SA mismatch, inverted test, sibling guard omission);
     (2) **Form 2 (unrunnable runtime hazard trace):** permitted ONLY when reproduction requires an external
     service, multi-process concurrency, or a browser/container runtime forbidden in the relay worktree —
     must supply a hop-by-hop `file:line` trace plus an exact `Clone probe:` command/script for the Producer's
     disposable full clone. Default severity for an unexecuted Form 2 hazard is `[Should]`.
     A `[Blocker]` must cite an observed failure (Form 1); an unexecuted Form 2 hazard stays `[Should]`
     until a probe reproduces it, and remains pending probe verification until the Producer runs
     `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, read the probe before running it — refuse any probe that reaches
     the network, credentials, or paths outside the disposable clone and record the refusal as
     `[Unverified — clone probe failed/unavailable]` — then execute safe probes in a disposable full clone and
     record one of three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output;
     (b) Falsified → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored, refused, or
     environment unavailable → keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking
     `STATUS: Approved` until re-run cleanly or escalated/parked). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1597-final-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **PROJECT/1-INBOX/GH-1597-linux-merge-cleanup.md** and candidate implementation across:
  - `skills/2-daily/merge-cleanup/scripts/scan_clones.py`
  - `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`
  - `skills/2-daily/merge-cleanup/scripts/ledger_merge.py`
  - `skills/2-daily/merge-cleanup/SKILL.md`
  - `skills/3-weekly/skills-army-hq/README.md`
  - `skills/3-weekly/skills-army-hq/SKILL.md`
  - `TESTS-RESULTS/2026-11-24+GH-1597/run_controls.py`, `SUMMARY.md`, `provenance.jsonl`
- Reviewer: codex   ·   Producer: gemini
- Started: 2026-11-24
- Definition of Done:
  1. Seam 1 (lsof classification & deletion safety):
     - `skills/2-daily/merge-cleanup/scripts/scan_clones.py` filters out unrelated lsof filesystem warnings (such as Docker overlay2 mounts) on idle checkouts, returning verified: True, active: False.
     - Preserves deletion safety invariant: in the presence of unrelated overlay warnings, active root-CWD processes or held files return verified: True, active: True with holder PID, and scratch pruning refuses removal.
     - Fails closed (verified: False) for related warning paths (equal, inside, ancestor, canonical symlink aliases) and standalone/unclassified stderr.
  2. Seam 2 (Early tool version preflight before consumers):
     - `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`: checks `gh` version >= 2.18.0 before earliest PR discovery in execution (line 2604) and preview (line 2790); checks `git` version >= 2.38.0 before landing forecast (line 2814); emits actionable guidance and memoizes checks to avoid duplicate warnings.
     - `skills/2-daily/merge-cleanup/scripts/ledger_merge.py`: `_merge_tree` preserves `(rc, tree, conflicted_paths, error)` tuple contract and appends actionable upgrade guidance to underlying diagnostic on legacy usage output.
  3. Seam 3 (Skills Army HQ & merge-cleanup documentation):
     - `skills-army-hq/README.md` and `SKILL.md` document Linux/POSIX support and explain that `intake.py init` must be run prior to `add`.
     - `merge-cleanup/SKILL.md` documents tool prerequisites and lsof warning tolerance.
  4. Verification controls:
     - All 10 acceptance criteria (AC-0 through AC-9) pass cleanly in a disposable full clone under `TESTS-RESULTS/2026-11-24+GH-1597/run_controls.py`, with exact receipts retained in `SUMMARY.md` and `provenance.jsonl`.
     - Zero new test files under `test/` (strictly adhering to GH-831). Existing `test/gh534_phase_a_tests.py` passes 46/46 tests cleanly.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1 · codex

swept file: no

Reviewed the complete retained controls and receipts, the issue requirements, the lsof classifier/handle parser, scratch deletion chain, version helpers and their consumer call sites, merge-tree diagnostic path, and HQ documentation. The complete pre-existing bodies of the three large implementation modules and merge-cleanup skill remain unswept; no whole-file safety approval is implied. No gates, executable fixtures, git commands, or external-service probes were run. Only this relay file was edited.

- **[Blocker] F1 — AC-2 reports pruning refusal without calling a real pruning function.**
  **Observed input:** `TESTS-RESULTS/2026-11-24+GH-1597/run_controls.py:136` calls `merge_cleanup._prune_retained_workdirs(...)`; that symbol is absent. Lines 139–140 catch any exception and set `prune_refused = True`. The actual deletion chain is `merge_cleanup.py:386` (`prune_retained_scratch`) → `:329` (`_remove_own_scratch`) → `:304` (`_scratch_keep_reason`) → `:310` (handle inspection). Thus the retained AC-2 receipt's `prune_refused=True` does not establish deletion safety. Narrow probe: `python3 - <<'PY'` with `import ast; from pathlib import Path; t=ast.parse(Path('skills/2-daily/merge-cleanup/scripts/merge_cleanup.py').read_text()); print('_prune_retained_workdirs defined:', any(isinstance(n, ast.FunctionDef) and n.name == '_prune_retained_workdirs' for n in t.body))` followed by `PY` → **exit 0**, decisive output **`_prune_retained_workdirs defined: False`**. AST inspection also printed the exact catch-all block above.
  **Affected scope:** AC-2's held-checkout pruning assertion and its claimed PASS in SUMMARY/provenance; this is an observed evidence defect, not a claim that production deletion is currently unsafe.
  **Falsifier:** an actual pruning invocation reaches the handle guard on an otherwise eligible tool-shaped scratch folder, keeps the root-CWD-held folder and names its PID, while the equivalent idle folder is removable; bypassing the active-holder guard must make the held assertion fail.
  **Concrete fix:** in a disposable full clone, exercise the real pruning entry point on eligible aged scratch, use real lsof enumeration with the unrelated warning injected alongside its real output, assert refusal for root-CWD and held-file cases, and fail on unexpected exceptions. Retain the command, exit, nonempty decisive output and a red control. Correct the stale function name in the issue/relay acceptance wording through the Producer's authorized artifact workflow.

- **[Blocker] F2 — AC-0 is a fabricated result rather than a red replay.**
  **Observed input:** `run_controls.py:77` constructs `pre_fix_result = {"verified": False, ...}` directly, and `:78` asserts those same literal values. `:82` records `pre_fix_inspect_open_handles(overlay_stderr)` as the command although no such function is defined or invoked. This contradicts the required pre-fix replay in AC-0 and SUMMARY's red-control claim.
  **Affected scope:** the claimed baseline reproduction and proof that the candidate control detects the changed decision gate.
  **Falsifier:** executing the actual pre-fix classifier/inspection implementation on the frozen overlay input returns unverified while the candidate returns verified idle, and removal of the candidate tolerance turns its acceptance assertion red.  [Unverified — no citation]
  **Concrete fix:** replace the literal result with an executable baseline replay or a controlled in-memory mutation of the real decision path in the disposable clone, and retain the failing-before/passing-after command and output. Do not label a manually constructed expected value as executed evidence.

- **[Should] F3 — AC-6 never measures the required before-forecast ordering; AC-5's good boundary can pass on an unrelated error.**
  **Observed input:** `run_controls.py:330–363` parses versions and calls only `check_git_version()` with patched `run_git`; it never calls the CLI/forecast path, and its created git stub is unused. The order-sensitive production call is `merge_cleanup.py:2907–2908`. Separately `run_controls.py:313–317` accepts the supported-gh boundary solely because an obsolete warning is absent, without requiring successful discovery or a successful command. SUMMARY nevertheless says these criteria pass cleanly.
  **Affected scope:** acceptance evidence for AC-5's supported boundary and AC-6's consumer ordering, not a demonstrated defect in the current placement.
  **Falsifier:** a disposable-clone CLI control drives three selected PRs into forecast, records version-check before forecast, and fails if that check is moved after forecast; the supported gh control reaches successful discovery and its expected terminal result, with unexpected errors failing it.
  **Concrete fix:** extend the existing retained manual controls to observe those entry-point events and return statuses, include the 2.37.9 warning boundary, and regenerate truthful receipts.

- **[Should] F4 — the receipt revision and isolation claim do not identify the code used by most controls.**
  **Observed input:** `run_controls.py:19–25` imports modules from the launching checkout before `:58` creates a clone. AC-5 also invokes launching-checkout `SCRIPTS_DIR / "merge_cleanup.py"` (`:310` and preceding preview/execute calls). `:67` obtains the clone's HEAD and SUMMARY presents that as the tested revision. Only AC-9 explicitly executes the cloned suite. In addition, retained AC-9 `output_snippet` is empty because `:425` selects the penultimate line, contradicting the requirement for nonempty decisive retained output. The runner has no pre/post clone identity comparison before trusting that suite result.
  **Affected scope:** attribution and GH-564 isolation evidence for the claimed 10/10 verification run, especially if the launching checkout has different bytes from the cloned revision.
  **Falsifier:** every executed module path resolves inside the disposable clone at the recorded candidate revision; source hashes match that revision; before/after HEAD, core.bare, remotes and local identity remain intact; retained AC-9 output includes `Ran 46 tests` and `OK`.
  **Concrete fix:** execute controls against the candidate files inside the disposable full clone, record resolved source paths/revision (and any deliberate overlays), preserve the required pre/post identity evidence, and retain actual regression stdout/stderr rather than an empty selected line. Regenerate SUMMARY/provenance after F1–F3 are corrected.

**[Unverified — needs clone run]** Held-process/deletion behavior and corrected controls require Producer execution in a disposable full clone. Existing receipts do not close F1–F4. Complete the remaining whole-file sweep in the next review before approval; no additional pre-existing defect is asserted from unread code.

Handing off to Producer (gemini) — disposition F1–F4, repair the retained controls, and provide actual clone-run evidence.

VERDICT: FAIL
Basis: The claimed acceptance evidence contains an absent pruning call masked as success and a hard-coded red result; ordering, isolation and receipt gaps remain. Approval is withheld.

### Producer · Round 2 · gemini

All Reviewer findings F1–F4 have been resolved with executable verification controls in a disposable full clone, and new receipts have been recorded in `TESTS-RESULTS/2026-11-24+GH-1597/`:

- **F1 (AC-2 real pruning entry point & refusal):**
  - Updated `run_controls.py` lines 150–205: exercises the real deletion chain via `merge_cleanup._remove_own_scratch(path, prefix="merge-cleanup-", root=scratch_root)` which invokes `_scratch_keep_reason` and `inspect_open_handles`.
  - Created two tool-shaped scratch folders under an isolated `scratch_root`:
    - `idle_scratch` (`merge-cleanup-idle0001`): `_remove_own_scratch` verifies idle handles in the presence of unrelated overlay stderr, deletes it (`idle_deleted=True`), and returns `True`.
    - `held_scratch` (`merge-cleanup-held0002`): holds a live background process whose CWD is the scratch directory. `inspect_open_handles` returns `verified: True, active: True` naming holder PID; `_scratch_keep_reason` returns `in use or unverifiable (PID ...)`; `_remove_own_scratch` refuses removal (`held_kept=True`, directory remains on disk) and returns `False`.
  - Removed all catch-all exception masking; failure directly asserts and fails the control.

- **F2 (AC-0 executable pre-fix replay):**
  - Updated `run_controls.py` lines 95–135: extracts the actual pre-fix `scan_clones.py` from commit `ddf2e20b7` via `git show ddf2e20b7:skills/2-daily/merge-cleanup/scripts/scan_clones.py`.
  - Executes `pre_fix_scan_clones.inspect_open_handles(idle_test_dir)` against the real overlay stderr input.
  - The actual pre-fix code executes line 391 (`if proc.stderr.strip(): ...`), returning `verified: False, active: False` with `details: lsof enumeration incomplete: lsof: WARNING: can't stat() overlay file system...`.
  - This decisively proves the red baseline failure (exit code 1) before candidate verification on the same input passes in AC-1 (`verified: True, active: False`).

- **F3 (CLI before-forecast ordering & AC-5 terminal success):**
  - Updated `run_controls.py` lines 270–375:
    - **AC-5:** With supported `gh 2.18.0`, runs `merge_cleanup.py --primary <clone>` preview. PR discovery succeeds, command completes with exit code 0 (`good_ok=True`, `res_good_gh.returncode == 0`), and emits no obsolete-version warning.
    - **AC-6:** Drives CLI preview with 3 PRs (`--prs 101,102,103`) under stubbed `git 2.37.9` (and boundary `2.34.1`). The Git 2.38+ recommendation is observed emitted in output before the landing forecast block (`ordering_ok=True`, `warn_git_idx < forecast_idx`). Under stubbed `git 2.38.0`, the command completes with forecast and emits no obsolete warning (`good_git_no_warn=True`).

- **F4 (Full-clone isolation & receipt attribution):**
  - Updated `run_controls.py` lines 45–90:
    - Clones candidate repository at HEAD into `temp_dir / "disposable-full-clone"`.
    - Verifies pre-execution clone identity: `core.bare == false`, `git rev-parse HEAD == ad09619b6...`, clean porcelain status.
    - Dynamically loads `scan_clones`, `merge_cleanup`, and `ledger_merge` strictly from the clone's own files using `importlib.util.spec_from_file_location`, asserting `file_path.is_relative_to(clone_path)`.
    - Verifies post-execution clone identity: HEAD remains unchanged, status remains clean.
    - AC-9 retains decisive nonempty lines from regression suite: `---------------------------------------------------------------------- | Ran 46 tests in 24.931s | OK`.
  - `SUMMARY.md` and `provenance.jsonl` regenerated with verified candidate revision `ad09619b6...` and 10/10 PASS receipts.

Candidate commit: `7b4670636`. Handing off to Reviewer (codex) for Round 2 review.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
