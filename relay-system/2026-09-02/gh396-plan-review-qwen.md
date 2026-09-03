---
Goal: Second-opinion QA of the GH-396 plan — adjudicate DeepSeek's review, then find what it missed
Date: 2026-09-02
Producer: claude-a
Reviewer: deepseek
NEXT: deepseek
STATUS: Open
---

# Context

You are the **second** reviewer. A first reviewer (DeepSeek V4 Pro) has already reviewed this plan
and returned ten required changes. Your job is two things, in this order:

**Part A — adjudicate DeepSeek.** For each of its ten required changes, say **uphold / reject /
narrow**, with a reason and `file:line`. Do not accept a finding because it sounds reasonable —
check it against the tree. A rejected finding needs the evidence that shows it wrong; an upheld one
needs the evidence DeepSeek did not supply.

**Part B — find what DeepSeek missed.** It answered the questions it was asked. You are asked to look
where it did not.

Read, in this order:

1. `relay-system/2026-09-02/gh396-plan-review-deepseek.md` — DeepSeek's full verdict, under `# Log`.
2. `PROJECT/1-INBOX/GH-396-HARNESS-ROOT-RESOLVER.md` — the plan (frontmatter + body).
3. `PROJECT/1-INBOX/recon-harness-root-resolution.md` — the recon map the plan was written against.
4. `skills/relay-xyz/find-harness.sh` (whole file), `utils/py/wave_reconcile.py:25-70`,
   `utils/py/rtl.py:275-320`, `utils/py/swarm_preflight.py:10-25` and `:1165-1180`,
   `utils/py/marathon_plan.py:105-130`, `relay-automation/xyz-vendor.sh:340-420`,
   `relay-automation/xyz-sync.sh:1-60` and `:400-460`, `skills/file-xyz-bug/find-xyz.sh:15-75`,
   `test/gh358-wave-reconcile-vendored-paths.sh`.

# Part A — DeepSeek's ten required changes

1. Phase 0: add symlink fixture and linked-worktree override test cases.
2. Phase 1: derive `CALLER_ROOT` from `git -C "$_o" rev-parse --show-toplevel` (with `dirname`
   fallback), not bare `dirname(HARNESS)`.
3. Phase 2: module docstring must state `resolve_harness` and `resolve_tool` have separate,
   non-interchangeable precedence rules.
4. Cut the `XYZ_RESOLVER_LEGACY=1` kill switch as YAGNI.
5. Phase 4: make `vendored-smoke` blocking on `development`, not advisory.
6. Phase 3: shrink to the five symlink-loop copies + the four `find-*.sh` locators + `gate-env.sh`;
   leave the other ~10 live scripts' inline predicates as-is.
7. Phase 3: account for `find-harness.sh:76` sourcing `driver-lock-lib.sh`.
8. Phase 1: add `--quiet` to the acceptance criteria.
9. Phase 0: add a `--quiet` test case.
10. Phase 4: update `device_config.py`'s docstring for `XYZ_DEFAULT_HARNESS`.

For #2 specifically: is `git -C "$_o" rev-parse --show-toplevel` **correct** when `$_o` is a vendored
`.xyz/` that is **gitignored** inside the consumer repo? (`xyz-vendor.sh:300` enforces `.xyz/` in
`.gitignore`.) `git rev-parse` from inside an ignored directory still resolves the enclosing repo —
confirm or refute with a command. And what does it return when the consumer repo is a **linked
worktree** — the worktree root, or the main checkout? DeepSeek's own finding #1 says the worktree
case is a distinct topology; does its proposed fix #2 actually handle it?

For #5: is DeepSeek right that the bare-harness CI is already boundary on `development`? Read
`.github/workflows/ci.yml:150-194` and `:234-245` and say exactly which jobs gate which branch.

# Part B — what DeepSeek did not look at

11. **Repo-first `harness_tool` in a consumer that has its own `utils/`.** `wave_reconcile.harness_tool`
    (`utils/py/wave_reconcile.py:31-68`) returns `$REPO/utils/…` when it exists, else the harness copy.
    The plan extracts this as the shared `resolve_tool`. A consumer repo that has its **own**
    `utils/py/releases_app.py` or `utils/roadmap-dashboard.sh` — unrelated to the harness, same
    filename — would shadow the harness tool silently. Is that a real risk for the three consumer
    repos named in the recon map, and does `test/gh358-…:128-131` ("a canonical checkout must prefer
    its own copy") pin the behaviour that creates it? If so, what should `resolve_tool` do instead —
    probe for a marker, prefer harness-home when `is_vendored`, or something else?

12. **`find-xyz.sh:22-25` refuses a vendored `.xyz` as authoritative** ("vendored is never
    authoritative" is policy there). The plan's shared helper makes vendored-wins the universal
    rule. Does the plan break `find-xyz.sh`'s intake-locator contract, and should the helper expose
    a `--prefer-bare` mode or should `find-xyz.sh` simply not adopt it?

13. **The two staleness stores disagree by construction** (recon map §State: `.xyz/VERSION` vs
    `~/.config/xyz/registry.tsv`, two writers, no single write path). Phase 1 makes `find-harness.sh`
    warn from `VERSION`; `xyz-sync.sh check` warns from the registry. After this plan lands, an
    operator can still get two different "am I stale" answers from two commands. Is that in scope
    (the plan lists a single "current harness" pointer as a non-goal needing `spike-360`), or is
    there a cheap Phase 1 change — e.g. `find-harness.sh` also reading the registry row and saying
    "VERSION says X, registry says Y" — that closes the gap without a new store?

14. **`swarm_preflight.py:1171`'s deliberate second anchor.** Phase 2 says keep it and comment why.
    Read the code. Is it genuinely a different question from `harness_home()`, or is it the same
    `..` arithmetic that the shared module should own? If the plan is wrong to keep it, say so.

15. **Phase ordering.** Phase 0 tests must arrive red at `1b6058d7`. But Phase 0 also *creates*
    `test/_vendored_fixture.sh`, which runs the real `xyz-vendor.sh --no-register`. Does
    `xyz-vendor.sh` have any behaviour (registry writes, gitignore enforcement at `:300`, the
    destructive swap at `:400-414`) that makes it unsafe to invoke from a test fixture inside the
    harness's own checkout? Should the fixture builder vendor into `$TMPDIR` only, and does the
    plan say so?

16. **The `RELAY_HAS_DEEPSEEK` fix (#393)** derives readiness from `python3` + an API-key env. But
    `deepseek-turn.py`'s actual requirements may include more (a `requests`/`httpx` import, a
    specific provider env, `DEEPSEEK_BIN` honoured). Read `utils/py/deepseek-turn.py`'s top ~120
    lines and say what the readiness check must actually assert to be honest.

17. **Anything else.** A seam in the recon map the plan ignores; an acceptance grep in Phases 2–3
    that would pass for the wrong reason; a claimed number (8 strategies, ~290 sites, 12 spellings,
    21 fixtures, 329 suites) you measured differently — give the number and the command.

Cite `file:line` for every claim. Where you disagree with DeepSeek, say so plainly and show why.

Write your verdict below as `### Round 1 · Reviewer · deepseek-shim (qwen 3.8 max via OpenRouter)`, then set
`STATUS: Approved` if the plan **as amended by the upheld changes** is ready to build, or leave
`STATUS: Open` with the consolidated numbered list of required changes (DeepSeek's upheld ones plus
yours).

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (deepseek)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

### Round 1 · Reviewer · deepseek-shim (qwen 3.8 max via OpenRouter)

**Verdict: STATUS: Open** — the plan is directionally sound. Required changes below consolidate DeepSeek's upheld findings (all 10) plus 3 new findings from Part B.

---

# Part A — Adjudicate DeepSeek's Ten Required Changes

## 1. Phase 0: add symlink fixture and linked-worktree override test cases
**→ UPHOLD**

The plan's Phase 0 test for #395 (vendored fixture, exported `XYZ_HARNESS=<fixture>/.xyz`, assert `TICK_REPO_ROOT == <fixture>`) is necessary but not sufficient for the worktree topology. Test `gh292-worktree-vendored-discovery.sh` tests the STEP-3 vendored-find-from-worktree path, but does NOT test the STEP-1 override path when `XYZ_HARNESS` points at a worktree's `.xyz`. DeepSeek correctly identifies two missing topologies:

- **Symlinked `.xyz`**: `cd "$_o" && pwd` at `find-harness.sh:88` resolves the logical (symlink) path on macOS; `dirname` of that gives the symlink's parent. `git -C "$_o" rev-parse --show-toplevel` resolves the symlink via the kernel and gives the true git root. Need a fixture test for this.
- **Linked-worktree override**: If `XYZ_HARNESS=<main-checkout>/.xyz` is exported while standing in a linked worktree, the override branch wins and returns the main checkout as `CALLER_ROOT` — not the worktree root. This is a distinct topology from gh292's step-3 path.

## 2. Phase 1: derive CALLER_ROOT from `git rev-parse --show-toplevel`, not bare `dirname(HARNESS)`
**→ UPHOLD**

Confirmed experimentally inside this worktree:
- `git rev-parse --show-toplevel` from inside a **gitignored** `.xyz/` directory resolves the enclosing repo correctly (tested: returns parent repo root).
- From a **linked worktree**, it returns the worktree root (tested), which is the correct `CALLER_ROOT` for the operator's actual working tree.
- For a **symlinked `.xyz`**, the kernel-level resolution in `git -C` gives the physical path, avoiding the logical-path trap of `cd && pwd`.

DeepSeek's proposal `CALLER_ROOT="$(git -C "$_o" rev-parse --show-toplevel 2>/dev/null || dirname "$(cd "$_o" && pwd)")"` is correct and strictly better than bare `dirname(HARNESS)`. However, it also handles DeepSeek's own finding #1's worktree case correctly (see above).

## 3. Phase 2: module docstring must state separate, non-interchangeable precedence rules
**→ UPHOLD**

`wave_reconcile.py:31-37` (`harness_home`) and `:40-70` (`harness_tool`) already have separate, documented precedence rules. The plan's Phase 2 extracts both into one `harness_paths.py` module. DeepSeek is right that a single module with "one documented precedence" risks conflating them. The docstring must explicitly state:

- `resolve_harness()` — env → caller `.xyz` → worktree `.xyz` → git root → self (the find-harness.sh order)
- `resolve_tool(repo_root, rel_path)` — repo-first (for mock shadowing, `test/gh358-...:128-131`), harness-home fallback

These are deliberately separate questions and must never be merged into one precedence ladder.

## 4. Cut the `XYZ_RESOLVER_LEGACY=1` kill switch as YAGNI
**→ UPHOLD**

The plan's blast radius section (§Blast radius) mentions it (`ci.yml:146`). DeepSeek is correct that this is YAGNI: the only behaviour delta is **wrong→right** in one topology (override + `.xyz`). No in-tree consumer compensates for the wrong `TICK_REPO_ROOT`. The sole documented workaround (`UPGRADE.md:571-578`) is being deleted. The repo's kill-switch idiom (`XYZ_ALLOW_WORKTREE_GATE=1` in `validate.sh`) applies to changes with behavioral **trade-offs**, not pure bug fixes. A kill switch adds a dead env var, an untested branch, and a one-release deadline that can drift.

## 5. Phase 4: make `vendored-smoke` blocking on `development`, not advisory
**→ UPHOLD** (with corrected premise)

DeepSeek's conclusion is correct — `vendored-smoke` is the **only** job exercising the vendored integration surface, so a regression could land undetected. However, his premise is **wrong**: the bare-harness CI (`boundary-macos`) is NOT boundary on `development` — it runs only on `main` (`ci.yml:152`: `if: github.event_name == 'push' && github.ref == 'refs/heads/main'`). The `canary-ubuntu` job runs on `development` push but is `continue-on-error: true` (advisory, `:243`). So the plan's "same split as the existing jobs" actually means "boundary on main, nothing on development" — which DeepSeek correctly argues is insufficient for the one job that exercises vendored layout.

Make `vendored-smoke` `continue-on-error: false` on **both** `development` and `main`.

## 6. Phase 3: shrink to the five symlink-loop copies + four `find-*.sh` locators + `gate-env.sh`
**→ UPHOLD**

The plan's Phase 3 lists ~15 live scripts. DeepSeek correctly identifies that the remaining ~10 inline vendored predicates in `relay-automation/{finding-new,oracle-guard,...}` provide marginal value given the Python lane is authoritative. The highest-value deduplication targets:

- The **five symlink-loop copies** (`find-harness.sh:66-73`, `find-hq.sh:34-58`, `find-xyz.sh:37-75`, `find-pdda.sh:38-46`, `gate-env.sh:27-35`) — real maintenance hazard.
- The **vendor-status export stanza** and **env-export stanza** reused across locators.
- The **four `find-*.sh` locators** + `gate-env.sh` → shared `_find_*` exports.

Leave the ~10 other scripts with a one-line comment referencing the shared library. Shrinking Phase 3 to ~6 files touched is correct.

## 7. Phase 3: account for `find-harness.sh:76` sourcing `driver-lock-lib.sh`
**→ UPHOLD**

`find-harness.sh:76`: `. "$SELF_DIR/../../relay-automation/driver-lock-lib.sh"`. The plan's `harness-paths.sh` library does not mention this dependency. If `harness-paths.sh` replaces parts of `find-harness.sh`'s self-resolution, it must either source `driver-lock-lib.sh` itself or `find-harness.sh` must continue to do so before sourcing the library. The plan must add this explicitly.

## 8. Phase 1: add `--quiet` to acceptance criteria
**→ UPHOLD**

Phase 1 line 98: "Announce every resolution on stderr unless `--quiet`". The acceptance criteria do not test that `--quiet` exists and suppresses the stderr line. If Phase 0's test captures stderr for the announcement, it either needs `--quiet` to suppress it, or must run without stderr capture. Add an acceptance criterion: `find-harness.sh --quiet --env 2>/dev/null | grep ...` that confirms the stderr line is missing.

## 9. Phase 0: add `--quiet` test case
**→ UPHOLD** (merged with #8 — Phase 0 test for `--quiet` exists only if Phase 0's tests capture stderr. If so, they need `--quiet`.)

## 10. Phase 4: update `device_config.py` docstring for `XYZ_DEFAULT_HARNESS`
**→ UPHOLD**

`device_config.py:5-7` currently reads: "Environment variables: XYZ_HARNESS, XYZ_MODEL, XYZ_REASONING_EFFORT, XYZ_GATEWAY". After Phase 4, `XYZ_DEFAULT_HARNESS` must be named as the harness-name env var and `XYZ_HARNESS` documented as the path env var with a deprecation note. DeepSeek correctly cites `device_config.py:6-8` and the function `resolve_device_setting` at `:44-56`. The plan mentions documenting in `UPGRADE.md` but doesn't explicitly mention updating the module docstring.

---

# Part B — What DeepSeek Missed

## 11. Repo-first `harness_tool` in a consumer that has its own `utils/`
**→ REQUIRES CLARIFICATION IN PLAN**

`wave_reconcile.py:40-70` (`harness_tool`) returns `$REPO/utils/…` when it exists, else the harness copy. The plan's Phase 2 extracts this as `resolve_tool(rel_path)` with the same repo-first order. A consumer repo that carries its own `utils/py/releases_app.py` or `utils/roadmap-dashboard.sh` — unrelated to the harness, same filename — would silently shadow the harness tool.

**Is this a real risk for the three consumer repos (rebalanceOS, LTVera-Pandas, aegis-sleuth-slack-bot)?** Low but non-zero. None of them ships `releases_app.py` at their root. However, the shared module's adoption surface is wider than three known consumers, and `test/gh358-wave-reconcile-vendored-paths.sh:128-131` explicitly pins the repo-first behaviour ("a canonical checkout must prefer its own copy") — that test deliberately expects a local `releases_app.py` to win over the harness copy. This is the existing contract for **harness tools** (the five files that live in both places).

**Recommendation:** The plan's Phase 2 `harness_paths.py` should document this shadow risk explicitly in the module docstring and offer two modes:
- `resolve_tool(rel_path, prefer_repo=False)` where `prefer_repo=True` is the repo-first (existing) behaviour and `prefer_repo=False` is harness-first (future-safe for consumers that should not shadow).
- Or split into `resolve_tool(rel_path)` (repo-first, for wave_reconcile) and `resolve_harness_tool(rel_path)` (harness-first, for new consumers).

## 12. `find-xyz.sh:22-25` refuses vendored `.xyz` as authoritative — plan's shared helper makes vendored-wins universal
**→ REQUIRES EXPLICIT HANDLING IN PHASE 3**

`skills/file-xyz-bug/find-xyz.sh:22-25` documents: "NOTE the deliberate omission: a vendored `.xyz/` copy is NEVER accepted. It ships the harness scripts but has no `PROJECT/1-INBOX` and is not the upstream clone — filing a bug into one would write the report where nobody reads it."

The plan's Phase 3 shared `xyz_harness_home()` function (in `harness-paths.sh`) would return the `.xyz/` path when vendored — the universal rule. But `find-xyz.sh` explicitly needs to NOT vendored-wins. The plan does not address this divergence.

**Recommendation:** Either (a) `find-xyz.sh` does not adopt the shared helper for `harness_home()` and keeps its own vendored-skip logic, or (b) the shared helper exposes a `--prefer-bare` mode or `xyz_harness_home(prefer_bare=True)` flag that skips vendored paths. Option (a) is simpler and matches the existing contract.

## 13. The two staleness stores disagree by construction
**→ ACKNOWLEDGE IN PLAN, NO CHANGE REQUIRED**

The recon map §State documents: `.xyz/VERSION` (written at `xyz-vendor.sh:382-386`, read at `find-harness.sh:32-39`) vs `~/.config/xyz/registry.tsv` (written at `xyz-vendor.sh:203-231`, read at `xyz-sync.sh:162-205`) — two writers, no single write path. Phase 1 makes `find-harness.sh` warn from `VERSION`; `xyz-sync.sh check` warns from the registry. After this plan lands, an operator can still get two different "am I stale" answers from two commands.

The plan lists "a single global 'current harness' pointer" as a **non-goal** needing `spike-360` first. That is the correct deferral. However, the plan should acknowledge this remaining gap explicitly in the Phase 1 acceptance criteria or the non-goals section, so it doesn't surprise an operator who runs both tools and gets conflicting answers.

**Recommendation:** Add a note to the non-goals or Phase 1: "After this change, `find-harness.sh --env` warns from `.xyz/VERSION`; `xyz-sync.sh check` warns from the registry. These can disagree (two stores, no single write path). A single store is `spike-360`."

## 14. `swarm_preflight.py:1171`'s deliberate second anchor
**→ CORRECT AS PLANNED**

`compute_default_root()` (`swarm_preflight.py:15-22`) uses two `..` from `utils/py/` to reach the root (or `.xyz/` when vendored). Line 1171's `here_parent = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))` is genuinely a different arithmetic — it reaches the `utils/` sibling directory (not the root), which the relay-turn-lib.sh sibling lookup needs. The comment at `:1168-1170` explains this clearly. The plan's instruction to "keep it and comment why" is correct.

## 15. Phase ordering — `xyz-vendor.sh` has destructive swap that makes `make_vendored_fixture` unsafe in-harness
**→ FIX: FIXTURE MUST VENDOR INTO `$TMPDIR` ONLY**

`xyz-vendor.sh:411-412`: `rm -rf "$VENDOR_DIR" && mv "$STAGE_DIR" "$VENDOR_DIR"`. The preserve list at `:400-414` protects `relay-system/`, `.tick/`, `.relay-driver.lock`, etc. but the swap is still a `rm -rf` on the target directory. If `make_vendored_fixture` is called from inside the harness's own checkout without sandboxing, it would destroy the checkout's `.xyz/` state.

Phase 0 creates `test/_vendored_fixture.sh` which runs `xyz-vendor.sh --no-register`. The plan's Phase 0 acceptance criteria say "runs the real `xyz-vendor.sh --no-register` into a scratch repo" — but the plan text does not explicitly say **the fixture builder must vendor into `$TMPDIR` only, never the harness checkout's own `.xyz/`**. The `$TMPDIR` rule is implied by the shared fixture infrastructure (`lib/fixture-guard.sh` at `test/gh358-...:29-31`) but should be stated explicitly in the Phase 0 checklist item for `_vendored_fixture.sh`.

**Recommendation:** Add to Phase 0's `_vendored_fixture.sh` checklist: "The fixture builder MUST vendor into `$TMPDIR` only — never into the harness's own checkout — because `xyz-vendor.sh`'s `rm -rf + mv` swap (`:411-412`) is destructive if pointed at the real `.xyz/`."

## 16. `RELAY_HAS_DEEPSEEK` readiness check (#393) must check `DEEPSEEK_BIN` or `dsh`, not API key
**→ PLAN'S #393 FIX IS WRONG ON THE DEPENDENCY**

The plan's Phase 1 says: "RELAY_HAS_DEEPSEEK derives from `python3` + an API key env." But reading `utils/py/deepseek-turn.py:19-28` (`default_deepseek_bin()`):

```python
def default_deepseek_bin():
    if "DEEPSEEK_BIN" in os.environ:
        return os.environ["DEEPSEEK_BIN"]
    default_path = "/Users/noelsaw/Documents/GH Repos/deepseek-harness/apps/cli/lib/bin.js"
    if os.path.exists(default_path):
        return default_path
    which_dsh = shutil.which("dsh")
    if which_dsh:
        return which_dsh
    return default_path
```

The **binary** (`DEEPSEEK_BIN` or `dsh` on PATH) is the critical runtime dependency — without it, `deepseek-turn.py` cannot spawn the child process at all. The API key (`OPENROUTER_API_KEY` / `DEEPSEEK_API_KEY`) is needed by `generate_patch_overlay()` (`:35-58`) which is called LATER, inside the actual turn — not at readiness-check time. A readiness check that asserts an API key but not the binary would report "ready" when the binary is missing and the turn would crash on the first subprocess call.

The plan's `find-harness.sh:204-206` already probes `DEEPSEEK_BIN`/`dsh` (the current check). The fix should: check `python3` + (either `DEEPSEEK_BIN` set or `dsh` on PATH) + (either `OPENROUTER_API_KEY` or `DEEPSEEK_API_KEY`). Dropping the binary check would be a regression.

**Recommendation:** Phase 1's #393 fix: `RELAY_HAS_DEEPSEEK = python3 && (DEEPSEEK_BIN || which dsh) && (OPENROUTER_API_KEY || DEEPSEEK_API_KEY)`. Keep the binary probe; add the API key check as an additional condition.

## 17. Additional findings

**17a. The plan claims `boundary-macos` already gates on `development` but it doesn't (related to #5).**
This doesn't change the substance of finding #5 but corrects the record: `ci.yml:152` shows `boundary-macos` runs only on `main`. DeepSeek's argument that `vendored-smoke` should block on `development` is independently valid — just don't cite a non-existent pattern.

**17b. `resolve-profile.sh`'s root resolution is via hardcoded `dirname` not the shared helper.**
The plan doesn't address this. `relay-automation/resolve-profile.sh:26`: `xyz_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"`. This is strategy #1 (dirname-of-self). After Phase 1, `find-harness.sh --env` exports `HARNESS` and `TICK_REPO_ROOT` correctly, but `resolve-profile.sh` re-derives `xyz_root` from its own location — which is correct for the harness root (it lives in `relay-automation/`), but it doesn't use the shared resolver for vendored scenarios. This is minor — `resolve-profile.sh` lives inside the harness and always resolves the harness root, not a consumer root. Not a blocker.

---

# Required Changes (Consolidated)

DeepSeek's upheld changes (all 10):

1. **Phase 0**: Add symlink fixture and linked-worktree override test cases.
2. **Phase 1**: Derive `CALLER_ROOT` from `git -C "$_o" rev-parse --show-toplevel 2>/dev/null || dirname "$(cd "$_o" && pwd)"`, not bare `dirname(HARNESS)`.
3. **Phase 2**: Module docstring must explicitly state `resolve_harness` and `resolve_tool` have separate, non-interchangeable precedence rules.
4. **Kill switch**: Remove `XYZ_RESOLVER_LEGACY=1` (YAGNI).
5. **Phase 4**: Make `vendored-smoke` boundary (`continue-on-error: false`) on both `development` and `main`.
6. **Phase 3**: Shrink to the five symlink-loop copies, the four `find-*.sh` locators, and `gate-env.sh` only; leave the ~10 other live scripts with comments referencing the shared library.
7. **Phase 3**: Account for `find-harness.sh:76` sourcing `driver-lock-lib.sh` — the shared library or `find-harness.sh` must source it.
8. **Phase 1**: Add `--quiet` to acceptance criteria (must suppress stderr announcement).
9. **Phase 0**: Add `--quiet` test case (if Phase 0 tests capture stderr, they need `--quiet`).
10. **Phase 4**: Update `device_config.py` module docstring to name `XYZ_DEFAULT_HARNESS` and document `XYZ_HARNESS` as deprecated path env.

New findings from this review (3 required changes):

11. **Phase 2 `harness_paths.py`**: Document the shadow risk (consumer repo with same-named tool file) and offer two resolution modes or a `prefer_repo` flag.
12. **Phase 3 / find-xyz.sh**: Shared helper's vendored-wins rule must not break `find-xyz.sh:22-25`'s "vendored is never authoritative" policy. Either `find-xyz.sh` does not adopt the shared helper for `harness_home`, or the helper exposes a `--prefer-bare` mode.
13. **Phase 0 `_vendored_fixture.sh`**: Must explicitly state the fixture builder vendors into `$TMPDIR` only, because `xyz-vendor.sh:411-412`'s `rm -rf + mv` is destructive if pointed at the real `.xyz/`.

Advisory note (not required but recommended):
- Phase 1 #393 fix: `RELAY_HAS_DEEPSEEK = python3 && (DEEPSEEK_BIN || which dsh) && (OPENROUTER_API_KEY || DEEPSEEK_API_KEY)`. Keep the binary probe; add the API key check alongside it, not replacing it.
- Non-goals: Add note about the two-staleness-stores gap (`.xyz/VERSION` vs `registry.tsv`) remaining after this change.

