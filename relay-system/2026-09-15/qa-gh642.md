---
Goal: Codex final QA — GH-642 implementation vs approved plan v2.1
Date: 2026-09-15
NEXT: agy
STATUS: Changes requested
---

# Context

Final QA of the GH-642 implementation on branch `feat/gh642-consumer-fruit` (this tree; HEAD is
the reviewed state). The approved plan is `PROJECT/2-WORKING/GH-642-CONSUMER-FRUIT.md` (plan v2.1,
your round-3 APPROVED). Requirements source: [#642](https://github.com/HiQS-Labs/XYZ-forge/issues/642)
+ field evidence [#621](https://github.com/HiQS-Labs/XYZ-forge/issues/621).

Implementation commits to review (git log, read-only — you may run `git log`/`git diff`? NO:
do not run git; read the FILES as they now stand):
- relay-automation/xyz-vendor.sh — reconcile_ignore_state direction 1 → repo-local info/exclude
  (cwd-anchored), comments updated
- utils/py/claude-turn.py — Opus-class default-budget stderr warning
- utils/py/marathon_drive.py — resolve_force_relay_task() + call site before receipt/render
- relay-automation/relay-turn-lib.sh — rtl_worktree_begin disposable node_modules copy
- utils/py/xyz_init_clone.py — new initializer (py, no new Bash)
- utils/py/swarm_preflight.py — zero-criteria stderr warning before the dry-run exit
- test/gh642-consumer-fruit.sh — new focused suite (36 cases, currently 36/0 in the disposable clone)
- test/xyz-vendor.sh, test/gh312-vendor-preserves-state.sh, test/gh365-driver-lane-registry.sh,
  skills/vendor-stack/SKILL.md, validate.sh (TESTS registry), skills/relay-automation/relay-pkg.tar.gz

Frozen Bash fallbacks (claude-turn.sh, marathon-drive.sh, utils/swarm-preflight.sh) are untouched —
verify that claim.

Operational envelope: grade against the plan's stated requirements + commensurate complexity;
findings cite file:line; no speculative machinery.

Questions:

1. Does each of the six tranche items satisfy its acceptance line in the plan? Cite file:line.
2. Item 1: is the info/exclude destination correct and complete (cwd-anchored; three Git shapes;
   direction-2 refusal untouched; the `.gitignore` fallback for non-git targets reachable)?
3. Item 3: does resolve_force_relay_task implement the round-1 SHOULD spec exactly (spent ≡
   done|circuit_broken; missing/malformed fails before render; monotonic -R2…; explicit ids
   never rewritten)? Is the call site early enough that _RESULT["token"]/receipt/render all see
   ONE resolved identity?
4. Item 4: does the copy happen before the allowlist seeding loop matters, stay advisory on
   failure, and avoid the containment hole (no symlink)? Can a turn's writes through the copied
   tree reach ROOT?
5. Item 5: does xyz_init_clone.py match the approved contract (umbrella required; slug ≤3 words;
   -r2 on occupied; vendor Tier 2 always; hooks when present)? Any new-Bash or frozen-twin
   violation anywhere in the diff surface?
6. Item 6: warning placement — emitted before the dry-run exit, text-format only, exit unchanged?
7. Governance: confirm the frozen twins are byte-untouched and no new .sh was added under
   utils/ or relay-automation/ (xyz-init-clone as .py). Confirm validate.sh's TESTS registry
   entry + gh365 exemption entry are the only registry changes.
8. Tests: does test/gh642-consumer-fruit.sh actually falsify each item (would it catch a revert
   of each behavior)? Any tautological assertions?

Write `### Final QA · codex` below: per-question answers (file:line), findings tagged
BLOCKER/SHOULD/NIT, final line `VERDICT: APPROVED` or `VERDICT: CHANGES REQUESTED` + minimal
fix list. Edit ONLY this relay file. Do NOT run git.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex — FINAL QA REVIEWER role; ALLOW_PATHS is empty: this relay file is your
only writable path; verify the implementation against the plan, never edit code)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

### Final QA · codex

1. **Six acceptance lines:** items 1, 2, 4, 5, and 6 are implemented as planned. Item 1 resolves
   and cwd-anchors the repo-local exclude with a non-git `.gitignore` fallback
   (`relay-automation/xyz-vendor.sh:297-319`). Item 2 warns non-fatally for `claude-opus*` plus the
   effective `$0.50` default (`utils/py/claude-turn.py:96-110`). Item 4 performs an advisory real
   copy before allowlist seeding (`relay-automation/relay-turn-lib.sh:758-791`). Item 5 requires the
   umbrella, validates the slug, derives/retries the destination, clones the supplied remote, always
   vendors Tier 2, installs hooks when present, and prints next steps
   (`utils/py/xyz_init_clone.py:72-125`). Item 6 emits a text-format stderr warning before the
   dry-run exit without changing the exit (`utils/py/swarm_preflight.py:1688-1706`). Item 3 is not
   exact; see BLOCKER/SHOULD below (`utils/py/marathon_drive.py:487-522`).

2. **Item 1:** correct and complete. `rev-parse --git-path info/exclude` is anchored when relative,
   so normal clones, linked worktrees, and separate-git-dir layouts resolve correctly; failure/non-git
   falls back to the target `.gitignore` (`relay-automation/xyz-vendor.sh:297-319`). Direction 2 still
   runs first, uses `git check-ignore -v`, preserves the blocking rule, and performs no direction-1
   mutation until after its diagnostic (`relay-automation/xyz-vendor.sh:253-295`). The focused suite
   exercises the three Git shapes and preservation (`test/gh642-consumer-fruit.sh:29-65`), though it
   omits the reachable non-git fallback case.

3. **Item 3:** the call site is early enough: resolution and `_RESULT["token"]` assignment occur at
   `utils/py/marathon_drive.py:1378-1385`, before heartbeat (`:1443-1454`), receipt consumers, and
   relay rendering (`:2908-2938`), so one resolved identity flows downstream. Explicit ids and
   non-force calls are unchanged (`:496-497`), and spent means `done|circuit_broken` (`:511-515`).
   **BLOCKER:** malformed output is rejected only for the base token. During the `-R2...` scan,
   `_status(candidate) == "malformed"` falls through and the loop advances forever rather than
   failing before render (`:516-522`). A bounded monkeypatch probe observed calls to base, `-R2`,
   then `-R3` after malformed `-R2` output. **SHOULD:** the required fresh-id announcement is sent
   through `log()`, which writes stdout (`:484-485,520`), not stderr as specified.

4. **Item 4:** correct. The copy occurs immediately after worktree creation and before the allowlist
   seed loop (`relay-automation/relay-turn-lib.sh:750-774`); failure only traces and continues
   (`:766-771`); `cp -R` creates a separate tree, not a symlink (`:762-768`). Writes through the
   worktree copy therefore cannot mutate `RTL_ROOT/node_modules` through a link.

5. **Item 5:** the approved contract is present at `utils/py/xyz_init_clone.py:72-125`: required
   umbrella (`:79-80`), at-most-three-word lowercase slug (`:46-50,81-82,94-97`), monotonic `-r2`
   retry without reuse (`:53-61,99-105`), unconditional `--with-releases` (`:106`), conditional hook
   install (`:108-112`), and next steps (`:114-125`). **NIT:** the module prose says an explicitly
   passed existing `--dir` is refused (`:23-25`), while the parser and implementation treat `--dir`
   as the parent directory and permit it (`:83-85,99-103`); align the prose with the implemented and
   tested parent-directory contract.

6. **Item 6:** correct. The guard is text-format only, names the document and checklist fix, writes
   stderr, precedes the dry-run exit, and introduces no exit-code change
   (`utils/py/swarm_preflight.py:1688-1706`).

7. **Governance:** the supplied diff surface names no frozen twin, and the current frozen fallbacks
   contain none of the GH-642 behavior markers; the initializer exists only as
   `utils/py/xyz_init_clone.py`. Because this turn explicitly prohibited git/diff, byte equality to
   the base is necessarily based on the supplied diff surface rather than an independent byte
   comparison. The two registry additions are the focused-suite entry in `validate.sh:502` and its
   driver-lane exemption in `test/gh365-driver-lane-registry.sh:134`; no other GH-642 registry entry
   is present.

8. **Tests:** **BLOCKER:** `test/gh642-consumer-fruit.sh` does not falsify every item despite its
   36/0 result. The malformed-info case passes the literal path `"$STUB/tick"` from a single-quoted
   heredoc (`:101-111`), so it exercises the missing-binary branch, not malformed output. It never
   tests malformed/occupied suffix candidates or the required stderr announcement (`:75-113`). The
   Opus warning and zero-criteria warning are compile+grep assertions only (`:67-70,164-170`), so
   removing the runtime print or moving it after the dry-run exit can remain green. The Tier-2 claim
   checks only that `.xyz` exists (`:147-150`), which Tier 1 also supplies. The copy case does not
   mutate the copied tree and prove ROOT unchanged or exercise advisory copy failure (`:115-136`).
   Add behavior-level assertions for these paths; also add the omitted non-git fallback and default
   slug/three-word boundary cases if retaining the suite's claim that it covers the full contract.

VERDICT: CHANGES REQUESTED — fix suffix-candidate malformed handling, emit the auto-suffix notice on
stderr, and replace the false-positive/static checks with behavior-level regression assertions that
go red when each guarded behavior is reverted.

---

## QA round 2 request (operator, 2026-09-15)

All findings applied:
- BLOCKER malformed-scan: `_status(candidate) == "malformed"` mid-scan now dies (exit 2) —
  utils/py/marathon_drive.py (resolve_force_relay_task scan loop).
- SHOULD stderr: announcement printed to `sys.stderr` (log()/stdout untouched).
- BLOCKER tests: malformed-base case now uses the REAL stub path (exercises the malformed branch,
  not missing-binary); new behavior tests: malformed mid-scan → exit 2; monotonic skip of a
  claimed -R2 → takes -R3; stderr announcement captured; copy-mutation proves ROOT stays clean;
  non-git fallback exercised; slug 3-word accepted / 4-word refused. Suite now 42/0.
- NIT docstring: aligned with the parent-dir contract.

Please re-verify (same envelope) and return `VERDICT: APPROVED` or the remaining list.

### Final QA · codex (round 2)

1. **Six acceptance lines:** the implementation now satisfies all six. Items 1, 2, 4, 5, and 6
   remain as previously reviewed (`relay-automation/xyz-vendor.sh:297-319`,
   `utils/py/claude-turn.py:96-110`, `relay-automation/relay-turn-lib.sh:758-791`,
   `utils/py/xyz_init_clone.py:46-61,72-125`, `utils/py/swarm_preflight.py:1688-1706`). Item 3's
   two round-1 defects are fixed at `utils/py/marathon_drive.py:516-531`.

2. **Item 1:** correct. The relative `rev-parse --git-path info/exclude` result is anchored to the
   target (`relay-automation/xyz-vendor.sh:307-314`), all three Git layouts remain covered, the
   direction-2 diagnostic still precedes mutation (`:253-295`), and the non-git fallback is reachable
   (`:312-314`). The focused suite now exercises that fallback (`test/gh642-consumer-fruit.sh:61-64`).

3. **Item 3:** correct after round 2. A malformed suffix candidate now fails before selection
   (`utils/py/marathon_drive.py:518-524`), and the fresh-id notice is emitted on stderr (`:525-530`).
   Spent remains exactly `done|circuit_broken` (`:511-515`); explicit ids remain unchanged (`:496-497`);
   and resolution still precedes `_RESULT["token"]` and all downstream consumers (`:1388-1395`). The
   revised tests use the real stub path and cover malformed base, malformed `-R2`, occupied `-R2` /
   free `-R3`, and stderr (`test/gh642-consumer-fruit.sh:80-118`).

4. **Item 4:** implementation correct. The real copy precedes allowlist seeding, and copy failure
   remains advisory (`relay-automation/relay-turn-lib.sh:758-774`). The new mutation assertion proves
   writes in the copied tree do not reach ROOT (`test/gh642-consumer-fruit.sh:128-143`).

5. **Item 5:** implementation correct. The docstring now matches the parent-directory contract
   (`utils/py/xyz_init_clone.py:17-25`); required umbrella, slug validation/defaulting, monotonic
   occupied-name retry, unconditional Tier 2, conditional hooks, and next steps remain at `:46-61`
   and `:72-125`.

6. **Item 6:** implementation correct. The text-only stderr warning is before the dry-run exit and
   leaves exit behavior unchanged (`utils/py/swarm_preflight.py:1688-1706`).

7. **Governance:** the current frozen fallbacks still contain none of the GH-642 behavior and the
   initializer remains Python-only. The registry locations remain the focused-suite entry
   (`validate.sh:502`) and the gh365 exemption (`test/gh365-driver-lane-registry.sh:134`). As in round
   1, the no-git constraint means byte equality and base-diff exhaustiveness cannot be independently
   established; this confirmation is bounded to the supplied diff surface and current file contents.

8. **Tests:** the round-1 test BLOCKER is only partially fixed. The token, copy-mutation, non-git,
   and slug-boundary additions are behavior-level and useful. **BLOCKER:** item 2 is still only
   compile + source grep (`test/gh642-consumer-fruit.sh:72-75`), so removing the warning print,
   routing it to stdout, or warning for a non-default budget can remain green. **BLOCKER:** item 6 is
   still only compile + source grep (`:175-181`), so moving the warning after the dry-run exit,
   routing it to stdout, emitting it for JSON, or changing runtime exit behavior can remain green.
   **BLOCKER:** the Tier-2 assertion checks only `.xyz/relay-automation` (`:154-157`), which Tier 1
   also installs; removing `--with-releases` from `xyz_init_clone.py:106` would not make it fail.
   **SHOULD:** advisory copy failure and default-slug derivation remain unexercised, so regressions in
   those acceptance clauses can also pass.

VERDICT: CHANGES REQUESTED — add behavior-level Opus-warning and zero-criteria dry-run assertions;
prove a Tier-2-only vendored artifact; exercise advisory copy failure and default-slug derivation.

---

## QA round 3 request (operator, 2026-09-15)

Round-2 BLOCKERs resolved:
- Item 2: warning extracted to `warn_opus_budget(model, max_budget, stream)` and imported in the
  suite — behavioral fire/suppress matrix (opus+0.50 WARNED; opus+5.00 SILENT; sonnet+0.50 SILENT).
- Item 6: warning extracted to `warn_zero_criteria(acc_mode, acc_items, doc, fmt, stream)` —
  behavioral matrix (acceptance-section+0+text WARNED; items SILENT; other mode SILENT; json
  SILENT) + an ordering pin (call site line < `if args.dry_run:` line).
- Tier 2: asserted via the Tier-2-only artifact `.xyz/utils/py/releases_app.py`.
Suite: 49 pass / 0 fail. Please re-verify items 2, 6, 8 and return `VERDICT: APPROVED` or the
remaining list.

### Final QA · codex (round 3)

2. **Item 2 implementation:** correct. `warn_opus_budget()` fires only for `claude-opus*` with the
   effective `$0.50` default and writes to stderr by default (`utils/py/claude-turn.py:36-47`);
   `main()` resolves the unset budget to `0.50` and calls the helper before dispatch
   (`utils/py/claude-turn.py:110-116`). The helper matrix correctly covers fire/suppress semantics
   (`test/gh642-consumer-fruit.sh:74-87`).

6. **Item 6 implementation:** correct. `warn_zero_criteria()` is text-only, names the document and
   checklist repair, and defaults to stderr (`utils/py/swarm_preflight.py:1142-1152`). Its runtime
   call precedes the dry-run exit and changes no exit path (`utils/py/swarm_preflight.py:1701-1711`).
   The helper matrix correctly covers the intended fire/suppress cases
   (`test/gh642-consumer-fruit.sh:190-204`).

8. **Tests:** the Tier-2 regression is now real: it asserts the overlay-only
   `.xyz/utils/py/releases_app.py` (`test/gh642-consumer-fruit.sh:168-170`). **BLOCKER:** the two
   warning matrices inject `stream=buf`, so they do not prove the contract's stderr destination;
   changing either helper's default from `sys.stderr` to stdout would leave all 49 assertions green
   (`test/gh642-consumer-fruit.sh:74-87,190-204`). **BLOCKER:** neither matrix proves that `main()`
   invokes its helper. Removing `warn_opus_budget(model, max_budget)` at
   `utils/py/claude-turn.py:114` leaves the item-2 tests green. The item-6 ordering pin is also
   tautological: `grep ... | head -1` at `test/gh642-consumer-fruit.sh:205-209` resolves to the helper
   **definition** at `utils/py/swarm_preflight.py:1142`, not the runtime call at `:1703`; removing or
   moving the call after `if args.dry_run` still passes.

VERDICT: CHANGES REQUESTED — add default-stream assertions that capture stderr (and reject stdout),
pin the Opus helper's runtime call, and make the zero-criteria ordering assertion select the indented
call at `:1703` rather than the definition; mutation-check call removal/movement so each assertion is
known to go red.
