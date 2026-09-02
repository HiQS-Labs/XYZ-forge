---
Goal: QA the GH-396 project plan (harness root resolver) before any code is written
Date: 2026-09-02
Producer: claude-a
Reviewer: deepseek
NEXT: deepseek
STATUS: Open
---

# Context

Adjudicate a **plan**, not code. Nothing in the plan has been implemented. Your job is to find where
the plan is wrong, missing, mis-scoped, or over/under-engineered — **before** it costs a build.

Read, in this order:

1. `PROJECT/1-INBOX/GH-396-HARNESS-ROOT-RESOLVER.md` — the plan (frontmatter + body; the body
   mirrors GitHub issue #396 verbatim).
2. `PROJECT/1-INBOX/recon-harness-root-resolution.md` — the recon map the plan was written against.
   Every `file:line` in the plan comes from here. Spot-check at least five of them against the tree.
3. The three defect captures the plan claims to close: `PROJECT/1-INBOX/GH-393-DEEPSEEK-READINESS-GATE.md`,
   `PROJECT/1-INBOX/GH-394-STALE-VENDOR-PROFILE-RESOLVER.md`,
   `PROJECT/1-INBOX/GH-395-XYZ-HARNESS-TICK-ROOT-DIVERGE.md` — **these three are untracked and may
   be absent from your worktree; if so, say so and rely on the recon map's summary of them.**
4. The code the plan touches most: `skills/relay-xyz/find-harness.sh` (all of it, ~300 lines),
   `utils/py/wave_reconcile.py:25-70`, `utils/py/rtl.py:275-320`, `utils/py/device_config.py`,
   `test/find-harness.sh`, `relay-automation/xyz-vendor.sh:340-420`.

# Questions

Answer each with a verdict (**agree / disagree / partially**) and a one-paragraph reason with
`file:line` citations. Do not summarise the plan back to me.

1. **Scope re-sort.** The plan says only 4 of the 12 RADAR-grouped issues are root-resolution defects,
   and moves #216/#349/#353 and #253–#256 out of scope. Is that split correct? In particular: does
   `git show 33e0dfd4 -- utils/py/releases_app.py` (PR #350, the #349 fix) touch root resolution at
   all, or is it purely parser work as the plan claims?

2. **Phase 0 sufficiency.** The plan pins #395 with one test: vendored fixture, exported `XYZ_HARNESS`
   pointing at `<fixture>/.xyz`, assert `TICK_REPO_ROOT == <fixture>` and equals the unset-override
   run. Is that enough to catch a regression? Name any topology it misses — e.g. an override pointing
   at a **linked worktree's** main-checkout `.xyz` (find-harness.sh step 3), a **bare** harness clone
   given as the override while standing inside a vendored consumer, or a symlinked `.xyz`.

3. **The Phase 1 override rule.** "The override selects *which harness*; it does not get to redefine
   *which repo*" — implemented as: after `_has_harness` passes, `if basename == .xyz then VENDORED=1;
   CALLER_ROOT=dirname(HARNESS)`. Is `basename == ".xyz"` a sufficient discriminator, or must
   `CALLER_ROOT` be derived from `git rev-parse --show-toplevel` run *inside* the override path (so a
   `.xyz` nested deeper than one level, or one reached via symlink, still resolves to the true repo)?

4. **Precedence conflict.** `find-harness.sh` is env-override-**first**. `wave_reconcile.harness_tool`
   (`utils/py/wave_reconcile.py:31-68`, the PR #359 pattern the plan extracts) is repo-**first**,
   harness-home-second. Phase 2 puts both behind one module with "one documented precedence." Can
   those two orderings coexist under one contract, or is the plan papering over a real conflict? If
   they must differ, say what the module's API should look like so the difference is explicit.

5. **`XYZ_HARNESS` name collision.** `find-harness.sh:87` reads it as a *path*; `utils/py/device_config.py:6,61,70`
   reads it as a harness *name*. The plan makes the path meaning win and has `device_config` read
   `XYZ_DEFAULT_HARNESS` first, falling back to `XYZ_HARNESS` only if the value is not an existing
   directory. Is that the right direction? What breaks for a user who exported `XYZ_HARNESS=deepseek`
   for device config?

6. **Blast radius honesty.** `--env` gains four exported names and **one stderr line** on every
   resolution. Find any in-tree consumer that captures `--env` with `2>&1`, counts lines, or would
   otherwise break on a new stderr line. `relay-automation/driver-lock-lib.sh`, `utils/py/marathon_drive.py`,
   `utils/py/relay_drive.py`, `utils/py/rtl.py`, `utils/hq/marathon-live.sh` all reference
   `find-harness` — check how each invokes it.

7. **Phase 3 worth it?** The Bash library replaces the vendored predicate in ~15 *live* scripts, while
   the 10 FROZEN twins (8 of which resolve ROOT) are left for 0.8.0 Sundown. Is Phase 3 real value or
   ceremony, given the Python lane is authoritative? Would you cut it, keep it, or shrink it to only
   the four `find-*.sh` locators + `gate-env.sh` (the five symlink-loop copies)?

8. **Kill switch.** `XYZ_RESOLVER_LEGACY=1` restores the old override branch, announced on stderr,
   removed after one release. Necessary, or YAGNI for a change whose only behaviour delta is
   wrong→right in one topology?

9. **Phase 4 CI split.** The new `vendored-smoke` job copies the existing pattern: advisory on
   `development`, boundary on `main`. It is the **only** job that will ever exercise the vendored
   integration surface. Should it be boundary on `development` too?

10. **What is missing.** Anything the plan should do that it does not — a seam in the recon map it
    ignores, an acceptance criterion that cannot actually be checked as written, a phase that should
    be split or merged.

Flag anything wrong, missing, mis-scoped, or over/under-engineered. Cite `file:line`. Where you
disagree with a number (8 strategies, ~290 sites, 12 spellings, 21 fixtures, 329 suites), give
the number you measured and the command you used.

Write your verdict below as `### Round 1 · Reviewer · deepseek`, then set `STATUS: Approved` if the
plan is ready to build as-is, or leave `STATUS: Open` with a numbered list of required changes.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (deepseek)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

# Log

