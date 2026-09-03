---
title: Harness root resolution — one resolver, two roots, pinned; retire RADAR-class-vendored-root-resolution
status: Proposed (1-INBOX — not yet active)
created: 2026-09-02
owner: noel
gh_issue: 396
source: https://github.com/HiQS-Labs/XYZ-forge/issues/396
doc_type: refactor
complexity: 4
risk: 3
effort: 4
phases: 5
ratings_provisional: true
recon: PROJECT/1-INBOX/recon-harness-root-resolution.md
radar_target: RADAR-class-vendored-root-resolution
closes:
  - GH-393
  - GH-394
  - GH-395
  - GH-234
related:
  - GH-293
  - GH-358
  - GH-215
  - GH-308
non_goals:
  - GH-216 / GH-349 follow-ups / GH-353 — ledger-parser generalisation, a different class
  - GH-253 / GH-254 / GH-255 / GH-256 — not resolution defects
  - The ten FROZEN Bash twins — 0.8.0 Sundown owns them
  - The ~250 ROOT= lines in test/*.sh — they resolve the bare harness repo the test lives in, correctly
  - A single global "current harness" pointer — a state/authority change, needs spike-360 first
goal: >
  One Python module and one sourceable Bash library answer harness_home / repo_root / is_vendored /
  harness_tool with one documented precedence, extracted from the code that already gets it right
  (wave_reconcile.harness_tool, rtl.resolve_turn_root); the #395 and #394 shapes are pinned red
  before the resolver is touched; live code stops deriving roots ad hoc; CI vendors the harness into
  a scratch repo; every resolution announces itself on stderr.
---

# GH-396 — Harness root resolution: one resolver, two roots, pinned

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward.

The plan body is the issue body, verbatim, so the two cannot drift. Read it at
https://github.com/HiQS-Labs/XYZ-forge/issues/396 or below.

Two `/relay-xyz` review rounds precede any code: DeepSeek V4 Pro, then Qwen 3.8 Max. Their threads
live under `relay-system/2026-09-02/` and their verdicts are appended to this doc under
`## Review findings` on promotion.

---

## Why this issue exists

Radar has watched the same defect class widen for three runs (report: `PROJECT/1-INBOX/RADAR-REPORT-2026-09-02.md`; live checklist: #293, target `RADAR-class-vendored-root-resolution`). Every instance has been fixed one at a time. This issue is the **one durable fix**, planned against a trace of the actual code rather than the symptom list.

**Recon map:** `PROJECT/1-INBOX/recon-harness-root-resolution.md` — commit `1b6058d7`, four read-only lanes, every claim below cites `file:line` from it.

## What the trace found (the part that changes the plan)

1. **Radar overcounted.** Reading the twelve issues it grouped, only **four are root resolution**: #215 and #358 (closed, fixed individually), **#395 (open, HIGH)**, **#394 (open)**. #393 sits in the same file and contract. #216/#349/#353 are "a parser written against this repo's own conventions" — PR #350 touched **zero** root-resolution lines. #253/#254/#255/#256 are individual features that merely happened to be *reported* from a vendored install. This issue fixes the class that produced the first five; it does not pretend to close twelve.

2. **The root resolution question is really two questions**, and the code conflates them: *where is the project* (`REPO_ROOT`/`TICK_REPO_ROOT`/`CALLER_ROOT`) and *where is the tooling* (`HARNESS`/`harness_home`/`XYZ_ROOT`). Bare layout: same directory. Vendored layout: `<repo>` vs `<repo>/.xyz`. **#395 is precisely a script answering question 2 and reusing the answer for question 1** — source-confirmed at `skills/relay-xyz/find-harness.sh:137-138`: the `XYZ_HARNESS` override branch at `:86-89` never sets `VENDORED=1` or `CALLER_ROOT`, so `TICK_REPO_ROOT` collapses onto `$HARNESS`. The same branch skips the staleness check at `:140-181`, so **#394 and #395 share one root cause**.

3. **Eight resolution strategies, ~290 sites, twelve spellings of "am I vendored?".** 15 byte-identical `dirname/..` prologues in `relay-automation/*.sh:15`; 20 Python `3×dirname(__file__)` copies; 14 distinct per-script override env vars (`CODEX_TURN_ROOT`, `MARATHON_ROOT`, `QUEUE_PLAN_ROOT`, `SWARM_PREFLIGHT_ROOT`, `ROADMAP_DASHBOARD_ROOT`, …); five copies of the same symlink-following loop. Full inventory in the recon map §State.

4. **Two correct pieces already exist and are duplicated, not shared.** `utils/py/wave_reconcile.py:31-68` `harness_home()`+`harness_tool()` (the PR #359 pattern — repo-first with a documented target-repo carve-out at `:762`) and `utils/py/rtl.py:282-310` `resolve_turn_root` (raise-never-default, GH-551). `utils/py/jog_run.py:186-193` is a byte-identical copy of `harness_home()`. The plan **extracts these**; it does not invent a new resolver.

5. **The bug has never been pinned.** `test/find-harness.sh` contains **zero** references to `XYZ_HARNESS` or `TICK_REPO_ROOT`. 21 of 329 suites build a vendored fixture, each open-coded — **no shared fixture builder**. No CI job vendors the harness into a scratch repo. That is why #395 survived and why the next instance will too.

6. **`XYZ_HARNESS` means two different things.** A filesystem path in `find-harness.sh:87` and the skill Step-0 snippets; a harness *name* in `utils/py/device_config.py:6,61,70`. A resolver that writes it corrupts device config.

7. **Ten FROZEN Bash twins, eight of which resolve ROOT** (`relay-automation/{agy,aider,claude,codex,pi}-turn.sh`, `consult.sh`, `marathon-drive.sh`, `relay-drive.sh`). A fix landing there is dead code — two documented instances already (`fa372590`; `fix(GH-255,GH-256): … the fix was in a file that never runs`). **This plan does not touch them.**

## The strategy, in one paragraph

Make the two-root distinction explicit and single-sourced: one Python module and one sourceable Bash library that each answer exactly `harness_home`, `repo_root`, `is_vendored`, and `harness_tool(rel)`, with one documented precedence, extracted from the code that already gets it right. Pin the #395 and #394 shapes in tests **before** touching the resolver (the Litmus/Nightwatch gate-first ordering this repo already uses). Replace the ad-hoc derivations in **live** code only. Add one shared vendored-fixture builder and one CI step that vendors the harness into a scratch repo. Rename the colliding env var with a one-release deprecation alias. Every resolution prints one stderr line saying what it chose and why, because a resolver that says nothing is indistinguishable from a wrong one (`AGENTS.md:100`).

## Phases

Each phase is independently shippable and leaves the tree green. Order is fixed: 0 must land red-then-green before 1; 1 before 2–3; 4 can run beside 2–3.

### Phase 0 — Pin the defect (gate first, arrives RED)

- [ ] Add to `test/find-harness.sh`: (a) **the #395 repro** — vendored fixture, `export XYZ_HARNESS=<fixture>/.xyz`, assert `--env` yields `TICK_REPO_ROOT=<fixture>` not `<fixture>/.xyz`, **and** assert it equals the value from an unset-`XYZ_HARNESS` run of the same fixture; (b) **the #394 shape** — vendored fixture with an older `source_commit` in `VERSION`, assert the WARNING fires *even when `XYZ_HARNESS` is exported*, and assert the remedy line is executable as printed (`bash -n` it, then run it with `--dry-run` if the grammar has one); (c) **precedence table** — one assertion per step 1–5 of `find-harness.sh:86-126` so any reordering is a visible diff.
- [ ] Add `test/gh393-deepseek-readiness.sh`: assert `RELAY_HAS_DEEPSEEK=1` when `python3` ≥ 3.8 and either `OPENROUTER_API_KEY` or `DEEPSEEK_API_KEY` is set, with **no** `dsh` on PATH — the readiness check must reflect what `utils/py/deepseek-turn.py` actually requires (`find-harness.sh:204-206,257`).
- [ ] Add `test/_vendored_fixture.sh` — one sourceable builder: `make_vendored_fixture <dir> [--stale <sha>] [--tier 1|2]` that runs the real `relay-automation/xyz-vendor.sh --no-register` into a scratch repo and returns `<dir>` and `<dir>/.xyz`. Use it in (a)–(c). **Acceptance:** the three new suites are registered in `validate.sh`'s `TESTS` array (bidirectional guard, PR #308, will refuse otherwise) and **all fail** at `1b6058d7`.
- [ ] Settle the two recon unknowns that gate the tests: `xyz-sync.sh`'s `update` grammar (`sed -n '1,60p' relay-automation/xyz-sync.sh`) and whether any of the ~19 unread root-named tests pins a precedence Phase 1 changes (`rg -n 'XYZ_HARNESS|TICK_REPO_ROOT|CALLER_ROOT' test/gh129-relay-tick-root.sh test/gh131-marathon-target-root.sh test/gh292-worktree-vendored-discovery.sh test/gh293-vendored-guard-drift.sh test/gh304-vendored-relay-path.sh test/gh417-turn-root-symlink-prefix.sh test/marathon-root-audit.sh test/relay-target-root*.sh`). Record the answers in the 2-WORKING doc.

### Phase 1 — `find-harness.sh`: two roots, one precedence, announced

- [ ] In the override branch (`:86-89`): after a candidate passes `_has_harness`, **if its basename is `.xyz`, set `VENDORED=1` and `CALLER_ROOT="$(dirname "$HARNESS")"`** — the override selects *which harness*, it does not get to redefine *which repo*. This alone closes #395.
- [ ] Move the staleness block (`:140-181`) out from under the `VENDORED=1`-only gate so an override pointing at a stale vendored copy still warns. Rewrite the remedy at `:170` to the confirmed grammar, absolute, copy-paste runnable — e.g. `bash "$CALLER_ROOT/.xyz/relay-automation/xyz-sync.sh" update "$CALLER_ROOT"` (exact form settled in Phase 0).
- [ ] When a documented script is requested from a vendored tree and is absent, and staleness was detected, the error names the staleness as the cause (#394's second half). Cheapest form: `--env` exports `XYZ_VENDORED_STATUS=behind|current|different|unknown` and `XYZ_VENDORED_COMMIT`; `resolve-profile.sh:25` reads them and says "vendored copy is behind (`<sha>`); this script landed after it" instead of `No such file or directory`.
- [ ] `--env` additionally exports `XYZ_VENDORED=0|1` and `XYZ_CALLER_ROOT` so no downstream consumer re-derives them.
- [ ] Fix the DeepSeek readiness gate (#393): `RELAY_HAS_DEEPSEEK` derives from `python3` + an API key env, not `command -v dsh`. Keep `DEEPSEEK_BIN` honoured if explicitly set.
- [ ] **Announce every resolution** on stderr unless `--quiet`: `find-harness: HARNESS=<h> REPO_ROOT=<r> vendored=<0|1> via=<override|caller-.xyz|worktree-.xyz|git-root|self>`. Mirrors `validate.sh:41-52`'s "announced, never silent" idiom.
- [ ] **Acceptance:** Phase 0 suites go green; `test/gh346-gateway-allowlists.sh:387-394` still passes (no exported name removed); `UPGRADE.md:571-578`'s GH-234 workaround paragraph is deleted because it is no longer needed, and GH-234 is closed citing this commit.

### Phase 2 — Python: one `harness_paths` module, extracted not invented

- [ ] Create `utils/py/harness_paths.py` by **moving** `harness_home()` and `harness_tool()` out of `wave_reconcile.py:31-68` verbatim, plus `is_vendored(path)` (single spelling: `os.path.basename(os.path.realpath(p)) == ".xyz"`) and `repo_root()` (= `dirname(harness_home())` when vendored, else `harness_home()`). Precedence documented in the module docstring and nowhere else. It **raises**, never defaults — same rule as `rtl.py:281`.
- [ ] Replace the duplicates: `jog_run.py:186-193` (delete, import); `marathon_plan.py:111-124` (the literal `.xyz/utils/…` strings become `harness_tool("utils/swarm-preflight.sh")` etc.); `swarm_preflight.py:16-21` `compute_default_root` (import; **keep** the deliberate second anchor at `:1171` and say why in a comment — it is not a duplicate, it is the relay-turn-lib sibling lookup); `marathon_drive.py:1038-1042` and `:1178-1179`.
- [ ] **Do not touch** `rtl.py:288 resolve_turn_root` or its five call sites — `test/gh308-turn-shim-parity.sh:73-88` asserts the literal call shape. `harness_paths` may be *called by* `rtl`, never the reverse.
- [ ] **Keep** the `utils/pdda/pdda.sh` carve-out at `wave_reconcile.py:762` repo-relative; `test/gh358-…` plants a decoy at `.xyz/utils/pdda/pdda.sh` that must never run.
- [ ] **Acceptance:** `rg -n 'basename\(.*\)\s*==\s*"\.xyz"' utils/py` returns exactly one hit (inside `harness_paths.py`); `test/gh358-wave-reconcile-vendored-paths.sh`, `test/gh273-marathon-root-audit-python-shape.sh`, `test/gh280-jog-marathon-adapter.sh`, `test/gh308-turn-shim-parity.sh` all green.

### Phase 3 — Bash: one sourceable library, live scripts only

- [ ] Create `relay-automation/harness-paths.sh` — sourceable, provides `xyz_harness_home`, `xyz_repo_root`, `xyz_is_vendored`, `xyz_harness_tool <rel>`, and the one symlink-following self-resolution loop (currently copied five times: `find-harness.sh:66-73`, `find-hq.sh:34-58`, `find-xyz.sh:37-75`, `find-pdda.sh:38-46`, `gate-env.sh:27-35`). It lives in `relay-automation/` because that is in `VENDOR_DIRS` (`xyz-vendor.sh:344`); anything outside those six dirs silently does not vendor.
- [ ] Source it from the **live** (non-FROZEN) resolvers only: `relay-automation/{finding-new,oracle-guard,smallcode-turn,target-checks,marathon,marathon-agent,improve-loop}.sh`, `utils/marathon-plan.sh:93-105`, `utils/swarm-preflight.sh:71-80`, `utils/roadmap-dashboard.sh:6,10`, the four `find-*.sh` locators, `gate-env.sh`.
- [ ] Replace the byte-identical Step-0 snippet in `skills/marathon-triage/SKILL.md:30-45` and `skills/10days/SKILL.md:91-105` with `eval "$("$L" --env)"` using the same locator loop `skills/relay-xyz/SKILL.md:23-30` already documents — the snippet today never validates the override (`_has_harness`), probes the wrong marker, and never derives `TICK_REPO_ROOT`.
- [ ] **Do not touch the ten FROZEN twins.** Their root resolution is retired by 0.8.0 Sundown, not by this issue.
- [ ] **Acceptance:** `rg -n 'basename.*"\.xyz"|\$\{1##\*/\} = "\.xyz"|\*/\.xyz\)' relay-automation utils skills --glob '!*FROZEN*'` — every hit outside `harness-paths.sh` is in a file whose line 2 carries the FROZEN banner; `test/gh308-frozen-twin-guard.sh` confirms no frozen twin changed.

### Phase 4 — Vendored integration in CI, and the env-var collision

- [ ] Add a `vendored-smoke` job to `.github/workflows/ci.yml`: checkout, `xyz-vendor.sh --no-register` into a scratch repo, then run the three Phase 0 suites plus `test/gh358-…` and `test/gh292-…` **from inside the scratch repo** against `.xyz/`. This is the surface no CI job exercises today (`ci.yml:150-194,234-245` both run the bare layout). Advisory on `development`, boundary on `main`, same split as the existing jobs.
- [ ] Resolve the `XYZ_HARNESS` collision: `device_config.py:6,61,70` reads `XYZ_DEFAULT_HARNESS` first and falls back to `XYZ_HARNESS` **only if the value is not an existing directory**, with a one-line deprecation warning. Document in `UPGRADE.md`. The path meaning wins because it is the one in every operator's shell history.
- [ ] Migrate the 21 open-coded vendored fixtures to `test/_vendored_fixture.sh` **only where a suite is already being edited** by Phases 1–3; the rest are a follow-up, listed by name in the 2-WORKING doc.
- [ ] **Acceptance:** the `vendored-smoke` job is green on `development`; `rg -n 'XYZ_HARNESS' utils/py/device_config.py` shows only the deprecation fallback.

## Closes

Directly: **#393, #394, #395**, and **GH-234** (same defect as #395 from the other side, per `UPGRADE.md:571-578`). Retires `RADAR-class-vendored-root-resolution`'s first two checklist items in #293. Structurally prevents the class that produced #215 and #358.

## Non-goals — named so they stop resurfacing

- **#216, #349-follow-ups, #353**: ledger-parser generalisation. Different class, different file, own issue.
- **#253, #254, #255, #256**: not resolution defects; leave on their own issues.
- **The ten FROZEN Bash twins**: 0.8.0 Sundown owns their retirement. Any root fix there is dead code by construction.
- **The ~250 `ROOT="$(cd "$HERE/.." && pwd)"` lines in `test/*.sh`**: they resolve the *harness repo the test lives in*, which is always bare — correct as written. Not the same defect.
- **A single global "current harness" pointer** (the third store the recon found missing): a state/authority change that needs `spike-360` first. Out of band; noted in the recon map.
- **`find-pdda.sh:62-80`'s `$HOME` path guessing**: its own smell, its own issue.

## Blast radius

Starts from the recon map's current-state radius and adds what this plan introduces:

- **Every shell that `eval`s `find-harness.sh --env`** gains four exported names (`XYZ_VENDORED`, `XYZ_CALLER_ROOT`, `XYZ_VENDORED_STATUS`, `XYZ_VENDORED_COMMIT`) and one stderr line. No name is removed. Risk: a consumer greps `--env` output line-count; none found in-tree.
- **`TICK_REPO_ROOT` changes value** for exactly one topology — override pointing at a `.xyz` dir — from wrong to right. Anyone who had a workaround that *compensated* for the wrong value (e.g. hand-exported `TICK_REPO_ROOT` after `--env`) sees a redundant but harmless double-set. `UPGRADE.md:571-578` documents that workaround; it is deleted in Phase 1.
- **Python import graph**: `wave_reconcile`, `jog_run`, `marathon_plan`, `swarm_preflight`, `marathon_drive` gain one import. `rtl.py` unchanged.
- **Bash source graph**: ~15 live scripts gain one `source`. The 10 FROZEN twins are untouched; `XYZ_PYTHON=0` users see no change at all, which is the correct behaviour for a lane that is frozen.
- **Consumer repos** (`rebalanceOS`, `LTVera-Pandas`, `aegis-sleuth-slack-bot`) see the fix on their next `xyz-sync update`. Until then they carry the old `find-harness.sh` and the old bug — which is the exact staleness the new warning now surfaces even under an override.
- **Kill switch**: `XYZ_RESOLVER_LEGACY=1` in `find-harness.sh` restores the pre-Phase-1 branch **and announces it on stderr** (the `validate.sh:41-52` rule). Removed after one release.

## Definition of done

`validate.sh` green on macOS boundary; `vendored-smoke` green; the three Phase 0 suites exist and were observed red at `1b6058d7` and green at the fix commit (record both SHAs in the doc); #393/#394/#395/GH-234 closed citing commits; `rg` acceptance greps in Phases 2–3 hold; `PROJECT/2-WORKING/GH-<this>-*.md` has a Lessons Learned section; #293's `RADAR-class-vendored-root-resolution` items 1–2 struck with the commit SHA.

## Reviewed by

Two `/relay-xyz` review rounds are scheduled on this plan before any code: DeepSeek V4 Pro, then Qwen 3.8 Max. Their findings land as comments here and in the 2-WORKING doc.

---

## Review findings — two headless rounds, consolidated

**Reviewers.** DeepSeek V4 Pro (`relay-system/2026-09-02/gh396-plan-review-deepseek.md`, commit `8f18997d`) then Qwen 3.8 Max (`relay-system/2026-09-02/gh396-plan-review-qwen.md`, commit `c9f42ce7`). Both returned `STATUS: Open` — directionally sound, build only after the changes below. Qwen adjudicated all ten of DeepSeek's changes (**ten upheld, one with a corrected premise**) and added three. The orchestrator then re-tested two claims both reviewers made and found both reversed by evidence; those corrections are marked **[orchestrator]**.

**Infra note.** Qwen's first attempt via Command Code failed on `insufficient credits` (exit 10, wrote nothing); its second via OpenRouter hung on an external call and was timeout-killed at 25 min (exit 7, wrote nothing); the third via OpenRouter with a 45-min ceiling completed. Both no-op failures were correctly classified by the shim and the token was released each time (GH-409). `relay-drive --review-once` reported the first failure as **exit 5 "non-approval handback"** — a failed turn read as a successful review. That is `RADAR-class-dark-telemetry` and should be filed as a follow-up, not folded into this plan.

### Required changes — 15, ordered by phase

**Phase 0**
1. Add three topologies to the #395 test: (a) override pointing at a **linked worktree's** main-checkout `.xyz` while CWD is the worktree; (b) **symlinked `.xyz` inside the repo** (`.xyz -> ./vendor/xyz`); (c) **symlinked `.xyz` to a directory outside the repo**. *(DeepSeek 1, Qwen upheld, orchestrator split the symlink case in two — see correction A.)*
2. Add a `--quiet` case: `find-harness.sh --quiet --env 2>&1 | grep -c '^find-harness:'` is 0. *(DeepSeek 9, Qwen upheld.)*
3. `test/_vendored_fixture.sh` **must vendor into `$TMPDIR` only, never the harness checkout** — `xyz-vendor.sh:411-412` is `rm -rf "$VENDOR_DIR" && mv`, destructive if pointed at the real `.xyz/`. State it in the checklist item, not just the acceptance line. *(Qwen 13.)*

**Phase 1**
4. Derive `CALLER_ROOT` as `git -C "$_o" rev-parse --show-toplevel 2>/dev/null || dirname "$(cd "$_o" && pwd)"`, not bare `dirname`. The formula is right; the stated reason is not — see correction A. *(DeepSeek 2, Qwen upheld.)*
5. Add `--quiet` to the acceptance criteria. *(DeepSeek 8, Qwen upheld.)*
6. **#393 readiness fix is rewritten.** `RELAY_HAS_DEEPSEEK` = `python3 ≥ 3.8` **AND** a resolvable binary **AND** an API key. "Resolvable binary" must use the **same rule as the shim** (`utils/py/deepseek-turn.py:19-28` `default_deepseek_bin()`: `$DEEPSEEK_BIN` → hardcoded `bin.js` path → `which dsh`), not a separate `command -v dsh`. Today the check and the runtime disagree, which is the whole #393 symptom. *(Qwen 16 — upheld and sharpened; correction B.)*
7. Acknowledge in the Phase 1 acceptance text that after this change `find-harness.sh` warns from `.xyz/VERSION` and `xyz-sync.sh check` warns from `registry.tsv`, and they can disagree. The single store stays a `spike-360` non-goal. *(Qwen 13 advisory — promoted to required because an unstated known gap is how #394 happened.)*

**Phase 2**
8. `harness_paths.py` docstring states that `resolve_harness()` (env → caller `.xyz` → worktree `.xyz` → git root → self) and `resolve_tool(repo_root, rel)` (repo-first, harness-home fallback) answer **different questions with deliberately different precedence** and are never merged into one ladder. *(DeepSeek 3, Qwen upheld.)*
9. Document the **shadow risk** — a consumer repo carrying its own `utils/py/releases_app.py` would silently win under repo-first — and expose it: `resolve_tool(rel, prefer_repo=True)` keeps the `test/gh358-…:128-131` contract for the five harness tools; new consumers pass `prefer_repo=False`. *(Qwen 11.)*

**Phase 3**
10. **Shrink** to the five symlink-loop copies (`find-harness.sh:66-73`, `find-hq.sh:34-58`, `find-xyz.sh:37-75`, `find-pdda.sh:38-46`, `gate-env.sh:27-35`), the four `find-*.sh` locators, and `gate-env.sh`. The other ~10 live scripts get a one-line comment pointing at the library, nothing more. *(DeepSeek 6, Qwen upheld.)*
11. `find-harness.sh:76` sources `driver-lock-lib.sh`; the shared library must either source it or leave that line in place. *(DeepSeek 7, Qwen upheld.)*
12. `find-xyz.sh:22-25` refuses a vendored `.xyz` by policy ("filing a bug into one writes the report where nobody reads it"). It **does not adopt** `xyz_harness_home()`; it may adopt only the symlink loop. *(Qwen 12.)*

**Phase 4**
13. `vendored-smoke` is **blocking (`continue-on-error: false`) on both `development` and `main`**. Corrected premise: `boundary-macos` runs on `main` only (`ci.yml:152`), and `canary-ubuntu` is advisory (`:243`) — there is no existing "boundary on development" pattern to copy, which is exactly why the one vendored-integration job must not inherit the advisory default. *(DeepSeek 9 with wrong rationale; Qwen 5 + 17a corrected it; orchestrator confirms from Lane D.)*
14. Update `device_config.py:5-7`'s module docstring: `XYZ_DEFAULT_HARNESS` is the harness-**name** env var; `XYZ_HARNESS` is the **path** env var with a deprecation fallback. *(DeepSeek 10, Qwen upheld.)*

**Cut**
15. Remove the `XYZ_RESOLVER_LEGACY=1` kill switch. The only behaviour delta is wrong→right in one topology, the sole documented workaround (`UPGRADE.md:571-578`) is being deleted, and the repo's kill-switch idiom is for trade-offs, not bug fixes. *(DeepSeek 4, Qwen upheld.)*

### Two corrections to the reviewers [orchestrator]

**A. Symlinks — both reviewers had it backwards.** Both claimed `git -C` resolves a symlinked `.xyz` "via the kernel" where `dirname(pwd)` fails. Tested at `1b6058d7`:

| Topology | `git -C <link> rev-parse --show-toplevel` | `dirname "$(cd <link> && pwd)"` |
|---|---|---|
| `.xyz` gitignored, real dir | consumer root ✓ | consumer root ✓ |
| linked worktree, `.xyz` inside it | worktree root ✓ | worktree root ✓ |
| `.xyz-link -> dir outside repo` | **`fatal: not a git repository`** | consumer root ✓ (logical) |

So the `||` fallback in change 4 is load-bearing, not decorative, and the Phase 0 symlink-outside test must assert that the **fallback** produced the answer. `dirname "$(pwd -P)"` would be wrong there (it gives the physical parent, outside the repo) — the formula must keep logical `pwd`.

**B. #393 — the issue's own premise was wrong, and the plan inherited it.** Issue #393 says the shim "never shells out to any `dsh` binary." `deepseek-turn.py:176-186` does: `subprocess.Popen(["node", deepseek_bin, "--profile", "headless", …])`. It succeeded on this machine with no `dsh` on PATH because `deepseek-turn.py:22` hardcodes `/Users/noelsaw/Documents/GH Repos/deepseek-harness/apps/cli/lib/bin.js`, which exists here. That hardcoded absolute path is itself a recon-map strategy-6 site the map missed, and it is why the readiness check (`command -v dsh`) and the runtime (`default_deepseek_bin()`) disagree. Change 6 above is the honest fix; **replacing the hardcoded path with a discoverable one is a separate issue** and should be filed as its own issue.

### Unchanged after review
- The scope re-sort (4 of 12 are root resolution; PR #350 touched zero root lines) — DeepSeek 1 agree, Qwen did not contest.
- Blast radius: no in-tree consumer captures `--env` stderr or counts its lines — DeepSeek 6 verified each of the eight script callers.
- `swarm_preflight.py:1171`'s second anchor stays — Qwen 14 read it and confirms it is a different question (the `utils/` sibling, not the root).

### Follow-ups to file separately, not folded in
- `relay-drive --review-once` classifies a shim that wrote nothing as exit 5 "non-approval handback" (observed twice today). Dark-telemetry class.
- `deepseek-turn.py:22` hardcoded machine path.
- Command Code account out of credits (`glm 5.3 max` profile is unusable until topped up).
