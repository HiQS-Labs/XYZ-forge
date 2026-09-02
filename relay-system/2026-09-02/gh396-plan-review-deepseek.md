---
Goal: QA the GH-396 project plan (harness root resolver) before any code is written
Date: 2026-09-02
Producer: claude-a
Reviewer: deepseek
NEXT: qwen
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

### Round 1 · Reviewer · deepseek

**Verdict: STATUS: Open** — the plan is directionally sound but has actionable gaps in 5 of 10 questions. Required changes below.

---

#### 1. Scope re-sort — **Agree**

`git show 33e0dfd4 -- utils/py/releases_app.py` touches `ROADMAP_NAME` key matching, `_roadmap_gh_number`, `_is_doc_pointer`, `_roadmap_issue_url`, `_is_ledger_bullet`, and `_is_ledger_bullet` parser logic. Zero root-resolution lines touched. The plan's claim that #216/#349/#353 are parser-generalisation (not root-resolution) is correct. The 4-of-12 split is right.

---

#### 2. Phase 0 sufficiency — **Partially disagree**

The Phase 0 test for #395 (vendored fixture, exported `XYZ_HARNESS=<fixture>/.xyz`, assert `TICK_REPO_ROOT == <fixture>` and equals the unset-override run) is necessary but not sufficient. Three topologies it misses:

- **Override pointing at a linked worktree's main-checkout `.xyz`**: If the operator exports `XYZ_HARNESS=/path/to/main-checkout/.xyz` but their CWD is in a linked worktree, the override branch (step 1) wins, sets `CALLER_ROOT=dirname(HARNESS)` = `/path/to/main-checkout`, and `TICK_REPO_ROOT = /path/to/main-checkout` — not the worktree root where the actual relay task lives. This is the same vector as #395 but in the worktree topology. The Phase 0 test should add this case.

- **Symlinked `.xyz`**: If `XYZ_HARNESS` is a symlink pointing at a `.xyz` directory (or `.xyz` itself is a symlink), `pwd` at `find-harness.sh:88` returns the *logical* (symlink) path, and `dirname` of that gives the symlink's parent — not the actual git repo root. `git rev-parse --show-toplevel` run *inside* the resolved path would give the true root. Phase 0 should include a symlink fixture.

- **Bare harness override inside a vendored consumer**: If `XYZ_HARNESS` points at a bare (non-`.xyz`) harness clone while standing in a vendored consumer, the fix doesn't apply (no `.xyz` basename), but `TICK_REPO_ROOT` still collapses to the bare harness instead of the consumer. This is NOT the #395 bug (which is specific to `.xyz` overrides), but it's a related gap that could be noted as a non-goal.

The two recon unknowns (xyz-sync.sh grammar, unread tests) are correctly called out as Phase 0 blockers. The existing grammar at `xyz-sync.sh:16` confirms `xyz-sync.sh update <dir>` as the correct form — the current remedy at `find-harness.sh:170` says `xyz-sync --update $CALLER_ROOT` (double-dash form), which the usage block also accepts (`xyz-sync.sh --update <dir>`), so both forms work. The Phase 0 test should settle on one.

---

#### 3. The Phase 1 override rule — **Partially agree**

`basename == ".xyz"` is a **sufficient discriminator** for the override branch — the vendored `.xyz` directory is the one topology where the harness lives one level deeper than the target repo. However, `CALLER_ROOT="$(dirname "$HARNESS")"` is not sufficiently robust:

- **Symlinked `.xyz`**: As above, `dirname` of the logical path may not equal the git repo root. The plan should derive `CALLER_ROOT` from `git rev-parse --show-toplevel` run *inside* `$HARNESS` (which walks the real path via the kernel), with `dirname(HARNESS)` as the fallback when not in a git repo. Rationale: a symlinked `.xyz` still lives inside a real git repo, so `git rev-parse --show-toplevel` gives the authoritative caller root.

- **Nested `.xyz`**: If the override points at a path like `/repo/some/tools/.xyz` (`.xyz` not directly under the repo root), `dirname(HARNESS)` = `/repo/some/tools` — wrong. `git rev-parse --show-toplevel` inside `$HARNESS` would give `/repo`, the true root. This is an edge case but `git` handles it.

The plan should add: `CALLER_ROOT="$(git -C "$_o" rev-parse --show-toplevel 2>/dev/null || dirname "$(cd "$_o" && pwd)")"` when basename == ".xyz".

---

#### 4. Precedence conflict — **Partially agree with the concern**

`find-harness.sh` (env-override-first for *which harness*) and `harness_tool()` (repo-first for *which tool path*) answer **different questions** — they are not in conflict. However, the plan's language ("one documented precedence") risks conflating them into a single chain in the `harness_paths` module, which would be wrong.

The module should expose **separate functions with separate documented precedence rules**:

- `resolve_harness()` — env override → vendored caller `.xyz` → worktree `.xyz` → git root → self (the find-harness.sh order)
- `resolve_tool(repo_root, rel_path)` — repo-first (for mock shadowing), harness-home fallback (the `harness_tool` order)

These must never be merged into one precedence ladder. The module docstring should state: "These two resolution questions are deliberately separate. `resolve_harness` selects *which clone/install* to use; `resolve_tool` selects *which copy of a tool file* within that install. Their orderings differ by design."

---

#### 5. `XYZ_HARNESS` name collision — **Agree with direction, flag one gap**

The plan's resolution (path meaning wins, `device_config.py` reads `XYZ_DEFAULT_HARNESS` first, falls back to `XYZ_HARNESS` only if the value is not an existing directory) is correct. The path meaning is the one in every SKILL.md Step-0 snippet (`skills/relay-xyz/SKILL.md:23`, `skills/hq/SKILL.md:38`, `skills/file-xyz-bug/SKILL.md:30`), and any operator who exported `XYZ_HARNESS=deepseek` for device config gets a one-line deprecation warning and sets `XYZ_DEFAULT_HARNESS=deepseek`.

**Gap**: `device_config.py:6-8` and the function `resolve_device_setting` at `:44-56` document that `XYZ_HARNESS` is an env var for harness *name*. After this change, the docstring at `:5-7` reads "Environment variables: XYZ_HARNESS, XYZ_MODEL, XYZ_REASONING_EFFORT, XYZ_GATEWAY" — this must be updated to say `XYZ_DEFAULT_HARNESS` is the name env var and `XYZ_HARNESS` is the path env var (with a deprecation note). Also, `GLOBAL_DEFAULTS["default_harness"] = "dsh"` at `:19` is fine — that value is never a filesystem path.

---

#### 6. Blast radius honesty — **Agree with plan's assessment**

No in-tree consumer captures `find-harness --env` stderr. Verified:

- `relay_drive.py:598` merely *prints* a hint string `eval "$(find-harness.sh --env)"` — it doesn't invoke it.
- `marathon_drive.py:1366` devnulls stderr in `_cmd_out()`, but that's a generic helper for arbitrary commands, not a find-harness consumer.
- `rtl.py` references find-harness only in comments (`:793`).
- `utils/hq/marathon-live.sh` references find-harness only in a comment (`:79`).
- No Python code calls `subprocess.run` on find-harness; no shell script pipes `--env` through `2>&1`.

The one stderr line is safe. The four new exported names (`XYZ_VENDORED`, `XYZ_CALLER_ROOT`, `XYZ_VENDORED_STATUS`, `XYZ_VENDORED_COMMIT`) are additive; no consumer greps `--env` output by line count. `test/gh346-gateway-allowlists.sh:387-394` only asserts the `RELAY_HAS_*` flags exist — it will not break from additional exports.

---

#### 7. Phase 3 worth it? — **Partially disagree — keep but shrink**

Phase 3 creates genuine value for **three things**:
1. The **five symlink-loop copies** (`find-harness.sh:66-73`, `find-hq.sh:34-58`, `find-xyz.sh:37-75`, `find-pdda.sh:38-46`, `gate-env.sh:27-35`) — this duplication is a real maintenance hazard.
2. The **vendor-status export** (`XYZ_VENDORED`, `XYZ_VENDORED_STATUS`, `XYZ_VENDORED_COMMIT`, `XYZ_CALLER_ROOT`) that downstream scripts currently re-derive.
3. The **env-export stanza** reused across the four `find-*.sh` locators.

The remaining ~10 live script replacements (the inline vendored predicates in `relay-automation/{finding-new,oracle-guard,...}`) provide marginal value given the Python lane is authoritative. These scripts' vendored checks are simple and stable. Phase 3 should be **shrunk** to:

- The five symlink-loop copies → one shared `_resolve_self_dir()` function
- The `find-harness.sh` override branch fix (Phase 1 already does this)
- The four `find-*.sh` locators + `gate-env.sh` → shared `_find_*` exports
- **Do not** replace the inline vendored predicates in the other ~10 live scripts; leave them with a one-line comment referencing the shared library.

This cuts Phase 3 from ~15 scripts to ~6 files touched, while keeping the highest-value deduplication.

The plan's note about the `skills/marathon-triage/SKILL.md:30-45` and `skills/10days/SKILL.md:91-105` Step-0 snippets is correct — both do NOT validate the override with `_has_harness`, probe the wrong marker (`swarm-preflight.sh` instead of `relay-drive.sh`), and never derive `TICK_REPO_ROOT`. These should be replaced with `eval "$("$L" --env)"` per the plan.

---

#### 8. Kill switch — **Disagree — cut it**

`XYZ_RESOLVER_LEGACY=1` is YAGNI for this change. The plan correctly identifies that the only behavior delta is **wrong→right** in one topology (override + `.xyz`). No in-tree consumer compensates for the wrong `TICK_REPO_ROOT` — the sole documented workaround (`UPGRADE.md:571-578`) is being deleted. A kill switch adds:
- A new env var that must be documented in `MACHINE-CONTRACTS.md`
- A conditional branch that is never exercised by any test
- A one-release removal deadline that can drift

The repo's idiom (`XYZ_ALLOW_WORKTREE_GATE=1` in `validate.sh`) applies to changes with behavioral *trade-offs*, not pure bug fixes. Cut the kill switch.

---

#### 9. Phase 4 CI split — **Disagree — make it boundary on development too**

The `vendored-smoke` job exercises the **only** vendored integration surface. Making it advisory on `development` means every PR against `development` can land a vendored-smoke regression that goes undetected until promotion to `main`. Since `development` is the standing WIP branch (per `AGENTS.md`), PRs against it should be gated on pass.

Change: `vendored-smoke` is **boundary on both `development` and `main`**. Use `continue-on-error: false` for both. This matches the pattern that the bare-harness CI is boundary on `development` — the vendored path deserves the same.

---

#### 10. What is missing

1. **`driver-lock-lib.sh` not accounted for in Phase 3**: `find-harness.sh:76` currently sources `driver-lock-lib.sh`. The Phase 3 `harness-paths.sh` library does not mention this dependency. If `harness-paths.sh` replaces parts of `find-harness.sh`'s self-resolution, it must either source `driver-lock-lib.sh` itself or `find-harness.sh` must continue to do so. No mention in the plan.

2. **`find-xyz.sh` cross-reference to `find-harness.sh`**: `skills/file-xyz-bug/find-xyz.sh:63-64` falls back to `find-harness.sh` as a locator. If Phase 3 adds `xyz_harness_home()` to `harness-paths.sh`, `find-xyz.sh` should prefer sourcing the library before falling back to `find-harness.sh`. Not mentioned.

3. **`resolve-profile.sh:25` not addressed**: The recon map lists it as an unknown (`sed -n '20,30p' relay-automation/resolve-profile.sh`). It's the "one-line shortcut" #394 names. The plan should verify this file's root resolution doesn't need updating in Phase 1 or note it as out of scope.

4. **`--quiet` acceptance criterion missing**: Phase 1 line 98 says "Announce every resolution on stderr unless `--quiet`". But no acceptance criterion asserts `--quiet` exists and suppresses the stderr line. If Phase 0's test greps stderr for the announcement, it must use `--quiet` to suppress it — or run without stderr capture. Add a Phase 0 test case: `find-harness.sh --quiet --env 2>/dev/null | grep ...`.

5. **`device_config.py` docstring needs update**: The module docstring at line 5-7 reads "Environment variables: XYZ_HARNESS, XYZ_MODEL, XYZ_REASONING_EFFORT, XYZ_GATEWAY". After Phase 4, `XYZ_DEFAULT_HARNESS` must be named and `XYZ_HARNESS` documented as the deprecation fallback.

6. **MARATHON_* namespace not checked**: The recon map lists `MARATHON_ROOT`, `QUEUE_PLAN_ROOT`, `SWARM_PREFLIGHT_ROOT`, `ROADMAP_DASHBOARD_ROOT` as distinct override names (14 total). The plan centralizes via `XYZ_HARNESS`/`XYZ_REPO_ROOT` in the find-harness override branch, but doesn't verify these are never captured or checked in Phase 2's Python consumers. `marathon_plan.py:116,121` reads `QUEUE_PLAN_ROOT` — this is a target-repo override, not a harness override, and should stay. The plan should explicitly note the ~14 per-script override names as a non-goal (they survive), to prevent scope creep.

---

**Summary of required changes:**

1. Phase 0: Add symlink fixture and linked-worktree override test cases.
2. Phase 1: Derive `CALLER_ROOT` from `git rev-parse --show-toplevel` inside the override path (with `dirname` fallback), not from bare `dirname(HARNESS)`.
3. Phase 2: Module docstring must clearly state that `resolve_harness` and `resolve_tool` have separate, non-interchangeable precedence rules.
4. Kill switch: Remove `XYZ_RESOLVER_LEGACY=1`.
5. Phase 4: Make `vendored-smoke` boundary (blocking) on `development` too.
6. Phase 3: Shrink to the five symlink-loop copies, find-harness override, and the four `find-*.sh` locators + gate-env.sh only; leave the ~10 other live scripts' inline predicates as-is with comments.
7. Phase 3: Address `driver-lock-lib.sh` dependency (source from the shared library).
8. Phase 1: Add `--quiet` to acceptance criteria.
9. Phase 0: Add `--quiet` test case.
10. Phase 4: Update `device_config.py` docstring for `XYZ_DEFAULT_HARNESS`.

