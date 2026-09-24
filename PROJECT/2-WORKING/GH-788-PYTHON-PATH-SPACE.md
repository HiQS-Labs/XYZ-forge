---
title: "GH-788: gate — suites fail when the Python path contains a space (shebang and unquoted sys.executable)"
status: In Progress
gh_issue: 788
source: https://github.com/HiQS-Labs/XYZ-forge/issues/788
doc_type: bugfix
created: 2026-09-24
updated: 2026-09-24
owner: operator (via /start-task)
goal: >
  Tests and fuzz self-tests run correctly when the Python interpreter lives under a path containing a
  space: executable stubs pin the exact interpreter through a quoted launcher, fuzz command strings quote it,
  and a ratchet keeps the three broken constructions from returning.
related:
  - "#651 — same class, one site (gh610) fixed by PR #753; closed 2026-09-24 while 13 sites remained"
  - "#787 — pushed with --no-verify because of this defect"
---

# GH-788 — suites fail when the Python path contains a space

## Status

| What was just completed | What's next |
|---|---|
| Implemented and verified with the spaced venv active (see Implementation notes; affected-suite rcs in the PR). | Codex final QA, then the full gate once in a disposable clone, then PR. |

## Problem (observed)

With a virtualenv active at `…/Documents/GH Repos/rebalanceOS/.venv` (VS Code activates it), `sys.executable`
contains a space. On 2026-09-24 the local pre-push gate refused #787's push on 10 suites that also fail on a
pristine `development` checkout on the same machine, and all pass once the venv is removed from `PATH`.

Two forms of one defect: the interpreter path is embedded without handling a space.

1. **`'#!' + sys.executable` stubs.** A `#!` line cannot contain a space, so macOS refuses to run the stub
   (`ENOEXEC`, "Exec format error"). The sites still on `development` (`337813e0`):
   - `test/gh492-roadmap-state-sweep.sh:24`
   - `test/gh648-l2-token-aftermath.sh:65`
   - `test/gh648-l4-285-revalidate.sh:49`
   - `test/gh648-l5-gh237-repro.sh:35`
   - `test/gh648-l6-muse-attribution.sh:33`
   - `test/gh666_agy_model_probe.py:32` (run by `test/agy-turn.sh`)
2. **Unquoted `f"{sys.executable} …"` command strings.** `fuzz_engine.build_argv` splits the head with
   `shlex.split`, so an unquoted spaced path becomes two argv words. The sites:
   - `utils/py/fuzz_engine.py:375,381,382,390,392`
   - `utils/py/repro_synth.py:199`
   - `utils/py/gen4_campaign.py:329`

   These break `gh-gen4-phase3/4/5` (`repro_synth.py --mode suite` → `emitted=0 skipped=1`).

`test/gh610-claude-subscription.sh` (the 10th suite) was fixed by PR #753 (#651, merged 2026-09-24 18:57Z).
Its convention is the one to reuse: `#!/bin/sh` + `exec` of `shlex.quote(sys.executable)`. #651 was closed
with 13 same-class sites still broken and no guard, which is how this recurred.

## Recon (base `337813e0`)

- **Stub interpreter:** `#!/usr/bin/env python3` would run whichever `python3` is first on the stub's
  `PATH`, not the interpreter under test, so the stub must pin `sys.executable` exactly (the property #753's
  launcher keeps). No existing test runs these stubs under an empty `PATH` (`test/gh666_agy_model_probe.py:136–147`
  expects `invoked=False` there); empty-`PATH` behaviour is a **new** acceptance case, not existing coverage.
  (Plan QA r1 nit.)
- **Import path:** four sites (`gh648-l2/l4/l5/l6`) run their Python with `PYTHONPATH=$ROOT/utils/py`;
  `gh666_agy_model_probe.py:13` inserts `utils/py` into `sys.path`; `gh492` has the repo root as `argv[1]`
  and needs an explicit insertion.
- **Command strings:** `utils/py/fuzz_engine.py:227-228` (`build_argv`) does
  `shlex.split(head) + mutant + shlex.split(tail)`, so `shlex.quote(sys.executable)` in the template is
  parsed back into one argv word. No engine change is needed.
- **No existing stub helper** in `test/lib/` or `utils/py/`.
- **Untraced:** stub-writing in `skills/**` and `relay-automation/**` beyond the grep patterns below. The
  guard's scan covers `test/`, `utils/`, `relay-automation/` and `skills/`, so a missed site is caught by the guard.

## Plan

Extend, don't add systems. One small helper, the same edit at each site, and one guard.

1. **Helper** — `test/lib/pystub.py`, stdlib only, ~15 lines. `launcher(python=sys.executable) -> str`
   returns a two-line sh/Python polyglot header, the interpreter **always** single-quoted:
   ```
   #!/bin/sh
   "exec" '<python>' "$0" "$@"
   ```
   The single-quoted path is a valid string literal in both languages. A path containing `'`, `\` or a
   newline raises `ValueError` naming it, so the helper never emits a broken stub. (Plan QA r1 blocker:
   `shlex.quote` leaves an ordinary path such as `/usr/bin/python3` unquoted, making line 2 a Python
   `SyntaxError`. It is not used for the header.)
   `/bin/sh` runs line 2 as `exec`. Python treats line 1 as a comment and line 2 as a harmless
   string-literal expression, then runs the rest of the same file. The approach is #753's (sh `exec` of the
   quoted interpreter); the only difference is a single file instead of `$0.py` beside it, which keeps every
   site's structure unchanged. Absolute `/bin/sh` and an absolute interpreter mean it works with an
   empty `PATH`.
2. **Test sites (6)** — replace `'#!' + sys.executable + '\n'` with `pystub.launcher()` (plus the
   import; `gh492` inserts `argv[1]/utils/py` first). No other change to what the tests assert.
3. **Command strings (7)** — `f"{shlex.quote(sys.executable)} …"`, and quote `{tool}`/`{twin}` the same way
   (temp paths today, but the same class).
4. **Guard + acceptance suite** — `test/gh788-python-path-space.sh`, registered in `validate.sh`:
   - a stub from `pystub.launcher()` compiles and runs for **both** an ordinary interpreter path and a Python
     symlinked into a directory **with a space**, each with `PATH=""`, a stub path containing a space and an
     argument `x y`, asserting the exact argv (the r1 falsifier);
   - `launcher()` refuses a path containing `'`;
   - **red control:** a bare `#!<spaced python>` stub raises `OSError` (the actual defect);
   - `fuzz_engine.build_argv(f"{shlex.quote(spaced)} tool.py {{mutant}}", ["x"])[0] == spaced`, with a red
     control for the unquoted form;
   - **ratchet:** `git grep` over tracked `test/ utils/ relay-automation/ skills/` finds zero
     `'#!' + sys.executable` / `"#!" + sys.executable` / `f"{sys.executable} ` sites; the same matcher must
     flag a planted sample (red control, so an empty or broken matcher cannot pass). `git grep` exit 1 is
     "no match" (pass); any other non-zero exit is a scan error and fails the suite, never read as zero sites.
     Safe argv-list uses (`[sys.executable, …]`, e.g. `utils/py/gen4_campaign.py:231`) do not match.
5. **Verification:**
   - Run the 9 affected suites (`gh492`, `gh648-l2/l4/l5/l6`, `agy-turn`, `gh-gen4-phase3/4/5`) plus the new
     suite with the spaced venv active, which is the reproduction. Record each rc.
   - Run the full `validate.sh` once, on the final approved commit, in a separate disposable full clone.

## Implementation notes (verification findings)

- **A third form, found in verification and missed by plan and plan QA:** the gen4 bash suites defined
  `PY="$(command -v python3)"` and passed `--target "$PY tool.py {mutant}"`, which `fuzz_engine` shlex-splits.
  After the Python-side quoting, `gh-gen4-phase3/4` still failed (corpus_size=1, 150 misclassified rows).
  Fix: `PYQ` = `shlex.quote(sys.executable)` at the one definition in each file (`test/gh-gen4-phase3-fuzz-engine.sh`,
  `test/gh-gen4-phase4-repro-synth.sh`), all 10 `--target` uses renamed to `$PYQ`. The guard gained a
  third pattern (`--target "$PY `) with its own planted red control. The literal-pattern searches in recon and
  plan QA only looked for `sys.executable`, and this form never names it. That is the "alternate constructions"
  gap Codex flagged.
- **Full-gate findings on the approved commit (spaced venv, disposable clone, 413/420):** five failures were
  this branch's and are fixed. (1) GH-777's inventory ratchet forbids any new script under `utils/`, so the
  helper moved to `test/lib/pystub.py` (`test/` is pruned from that ratchet), and the six sites and the suite
  now put `test/lib` on `sys.path`. (2) `gh139`/`gh460` flag `printf … | grep -q` under pipefail, so the suite
  uses `grep -q … <<<"$out"`. (3) `sentinel-overlay`/`pdda-repo-contract`: this doc lacked `goal:`. The other
  three (`gh777` on `utils/py/work_connectors/github_labels.py`, `gh674` `No module named merge_cleanup`,
  `gh436` `test_unknown_mergeable_settles_and_the_pr_lands`) fail identically on pristine `development` `337813e0`.
- **Guard self-match:** once committed, the suite's planted samples and the helper's docstring matched the
  tree scan (it passed while they were untracked). The suite now excludes only its own file, and the helper
  docstring no longer quotes the bad construction.

## Non-goals

- Migrating `gh610`'s working two-file launcher (fixed, has its own red control).
- A general "path hygiene" framework, a preflight warning in the gate, or scanning non-Python stub writers.
  The issue lists the preflight warning as optional; this plan leaves it out, because the ratchet fixes
  the cause and a warning would only describe it.
- Changing `fuzz_engine`'s parser or any production behaviour beyond quoting the interpreter.
- A spaced `TMPDIR`: `test/gh-gen4-phase3-fuzz-engine.sh` still interpolates `$WORK/tool.py` (and
  `noisy.py`, `twin.py`) unquoted into `--target`. It is a different input (the temp root, not the
  interpreter), so it is out of scope (Codex final QA r1, noted).
- The pre-existing delete-before-disjointness-check in `gen4_campaign.make_sandbox` (Codex final QA r1 S2)
  is filed as #792.

## Risk / rollback

- Test-only for 6 sites. `utils/py` changes are quoting-only in three self-test/campaign entry points.
- A new helper module and a new suite. Rollback is a plain revert. There is no data, schema or ledger impact.

## Rating (2026-09-24)

`rated 75/70/50/70`

- **sev 70:** blocks every push from an affected shell (work-blocking for the gate, not data loss). The ways
  through are leaving the venv or `--no-verify`, and the second erodes the gate.
- **pri 75:** recurring. #651 (opened 2026-09-16, closed 2026-09-24 by PR #753 with 13 sites left) and #788
  (2026-09-24) fall in the last 14 days, and none of the same class in the prior 14. Search, 2026-09-24:
  `gh issue list --repo HiQS-Labs/XYZ-forge --state all --search '<q>'` for q ∈ {"space in path",
  "spaces in path", "\"GH Repos\"", "Exec format error", "shebang", "path with spaces"}. The only same-class hits
  were #651 and #788; other hits (#406, #435, #481, #722) are unrelated path topics.
- **appeal 50:** neutral; the operator gave no preference.
- **effort 70:** mechanical edits at 13 sites, a ~15-line helper and one suite.

## Acceptance

- [ ] The 9 affected suites pass with a Python whose path contains a space (spaced venv active), with the rc recorded.
- [ ] `test/gh788-python-path-space.sh` is green; its red controls (bare spaced shebang, unquoted argv, planted ratchet sample) each fail as designed.
- [ ] The ratchet reports zero remaining sites in tracked `test/ utils/ relay-automation/ skills/`.
- [ ] Full `validate.sh` green once on the final commit (disposable clone).
- [ ] Codex plan QA and final QA approved.

## Merge evidence

- (recorded at landing)

## Lessons Learned (For Future Agents)

- (to be written at closeout)
