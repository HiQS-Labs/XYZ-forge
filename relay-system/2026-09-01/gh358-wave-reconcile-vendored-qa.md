---
Goal: QA the GH-358 fix — wave_reconcile resolving harness tools on a vendored install
Date: 2026-09-01
NEXT: Reviewer
STATUS: Approved
---

# Context

You are reviewing a fix that is ALREADY COMMITTED IN THIS CHECKOUT (HEAD = 8cc47f48, branch
`fix/358-wave-reconcile-vendored-paths`). Read the files here on disk — do not assume the
canonical `development` state. `git show --stat HEAD` will show you the change.

Read in full:
- `PROJECT/2-WORKING/GH-358-WAVE-RECONCILE-VENDORED-PATHS.md` — the plan and rationale
- `utils/py/wave_reconcile.py` — `harness_home()`, `harness_tool()`, `run_subprocesses()`, `run_validation_gate()`
- `test/gh358-wave-reconcile-vendored-paths.sh` — the regression test
- `utils/py/marathon_plan.py:112-124` and `utils/py/jog_run.py:189` — the prior art being copied

## The defect being fixed

`wave_reconcile.py` named five HARNESS tools as repo-root-relative paths and ran them with
`cwd=repo_root`. On a vendored (Tier 2) install those five files exist only under `<repo>/.xyz/`,
so all five were unreachable and the reconciler died on its first downstream step with
`can't open file '<repo>/utils/py/releases_app.py'` and rolled back. Observed live in
BinoidCBD/LTVera-Pandas against `.xyz` source_commit 6d23ac86.

## Questions — answer each concretely, citing file:line where you disagree

1. **Resolution order.** `harness_tool()` prefers the TARGET REPO's copy and only falls back to
   the harness home. Is repo-first correct, or is it a latent bug? Specifically: could a target
   repo legitimately carry a file at `utils/py/releases_app.py`, `utils/roadmap-dashboard.sh`,
   `utils/marathon-plan.sh`, or `utils/timeline/export_timeline.py` that is NOT the harness tool,
   and would silently shadow it? Note that the four existing wave-reconcile suites
   (`test/wave-reconcile.sh`, `gh168`, `gh202`, `gh232`) install mocks at `$REPO/utils/...` and
   depend on exactly this shadowing, so harness-first would break them. Is there a better
   ordering that keeps the mock seam?

2. **The PDDA exclusion.** `run_validation_gate()` at `utils/py/wave_reconcile.py:762` was
   deliberately left repo-root-relative because `utils/pdda/pdda.sh` is a TARGET-repo tool. Is
   that the right call? Is there any vendored install where the PDDA gate would now silently
   not run, or run against the wrong tree? Is `utils/pdda-local-checks.sh` (the other branch of
   that ternary) in the same category, or is it a harness tool that this fix should have covered?

3. **Completeness of the sweep.** Are there OTHER root-relative harness paths in
   `wave_reconcile.py` — or reachable from it — that this fix missed? Check subprocess argv,
   file reads, and any path joined against `repo_root` that should have been the harness home
   (and vice versa: anything joined against the harness that should be the repo).

4. **Test quality.** Does `test/gh358-wave-reconcile-vendored-paths.sh` actually prove the fix?
   Note the assertions use marker FILES rather than grepping the reconciler's stdout, because
   `wave_reconcile` captures subprocess stdout and does not echo it on success — an earlier draft
   grepped stdout and four assertions passed vacuously. Are any assertions still vacuous? Is the
   pre-fix control (1 passed / 8 failed) meaningful, or could it pass for the wrong reason? Does
   section 3 actually pin the canonical-checkout behavior, given it imports the module rather
   than running the reconciler?

5. **Fallback when neither location has the tool.** `harness_tool()` returns the repo-relative
   path so the error names what the caller asked for. Is silently returning a path that is known
   not to exist the right behavior, or should it refuse loudly? Consider that the reconciler's
   own subprocess error handling already dies with the tool name.

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. If the fix is sound,
say so plainly — do not manufacture findings.

Write your verdict below and set STATUS to Approved if it passes, or leave it In Review with the
required rework if it does not.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex reviewer verdict — Approved

1. **Resolution order:** Repo-first is correct for this reconciler's established contract. `harness_tool()` implements exactly that at `utils/py/wave_reconcile.py:62-66`; the four existing suites deliberately install their executable seams at the target path (for example, `test/wave-reconcile.sh:145-175`, `test/gh168-wave-reconcile-scope.sh:79-101`, `test/gh202-wave-reconcile-issue-state.sh:75-84`, and `test/gh232-wave-reconcile-multiphase.sh:76-85`). A target repository could technically contain an unrelated same-named tool, but treating that as a harness invocation is the pre-existing, test-relied-on override contract, not a newly introduced shadowing behavior. A different ordering would need an explicit mock-injection mechanism and is out of scope for this bug fix.

2. **PDDA exclusion:** Correct. `run_validation_gate()` resolves both branches relative to the target `repo_root` and executes them with that cwd (`utils/py/wave_reconcile.py:804-817`). It therefore cannot silently skip or redirect the gate because the harness is vendored: absence of both target paths produces a non-zero Bash invocation and `die()`. `utils/pdda-local-checks.sh` is likewise target-repo-owned: it locates its library relative to itself (`utils/pdda-local-checks.sh:41-49`) and evaluates the target's project material. The vendored test's repo marker and `.xyz` decoy assertions (`test/gh358-wave-reconcile-vendored-paths.sh:65-69,124-126`) pin this distinction.

3. **Sweep completeness:** No missed harness-relative path found. The only downstream harness argv entries are the two releases invocations plus timeline, dashboard, and planner (`utils/py/wave_reconcile.py:752-757`), and all route through `harness_tool()`. The remaining `repo_root` joins and subprocess cwds read, mutate, validate, or query the target repo (`utils/py/wave_reconcile.py:713-739,784,804-817`), so retaining their target scope is correct.

4. **Test quality:** The vendored integration run proves all five call sites: it requires a successful reconciliation and separately checks a durable marker for each tool (`test/gh358-wave-reconcile-vendored-paths.sh:111-122`). Those assertions are not vacuous; each marker is created only by the corresponding fixture executable. The pre-fix 1-pass/8-fail control is meaningful: before `harness_tool()` the first repo-relative releases invocation fails, no harness/PDA marker can be created, the missing-helper canonical check fails, and only the "decoy never ran" negative assertion remains true. Section 3 directly pins the helper's canonical/mock-seam contract (`test/gh358-wave-reconcile-vendored-paths.sh:128-143`); section 1 supplies the end-to-end dispatch evidence that a helper-only test cannot.

5. **Neither location:** Returning the target-relative spelling is appropriate. It does not silently continue: the next subprocess is checked and fails through the existing named-step error path (`utils/py/wave_reconcile.py:781-788`). This retains the prior diagnostic and avoids a redundant second error policy in the resolver.

Review method: static source and regression-test inspection. I did not execute the test from this linked worktree, per the repository's full-clone-only test-safety rail.
