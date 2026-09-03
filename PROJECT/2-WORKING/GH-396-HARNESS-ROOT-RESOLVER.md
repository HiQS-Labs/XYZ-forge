---
title: Harness root resolution — one resolver, two roots, pinned; retire RADAR-class-vendored-root-resolution
status: Active
created: 2026-09-02
updated: 2026-09-02
owner: noel
gh_issue: 396
source: https://github.com/HiQS-Labs/XYZ-forge/issues/396
doc_type: refactor
complexity: 4
risk: 3
effort: 4
phases: 5
revision: 4
ratings_provisional: false
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

## Status

| What was just completed | What's next |
|---|---|
| Phase 2: Python: one `harness_paths` module, extracted not invented (validated green) | Phase 3: Bash: one sourceable library, six files, not fifteen |

## Table of contents

- [Why this issue exists](#why-this-issue-exists)
- [What the trace found](#what-the-trace-found-the-part-that-changes-the-plan)
- [The strategy, in one paragraph](#the-strategy-in-one-paragraph)
- [Phases](#phases)
  - [Phase 0 — Pin the defect (gate first, arrives RED)](#phase-0--pin-the-defect-gate-first-arrives-red--built-at-87e30924-as-built-checklist-and-what-it-changed-are-under-phase-0--built-below)
  - [Phase 1 — find-harness.sh: two roots, one precedence, announced](#phase-1--find-harnesssh-two-roots-one-precedence-announced)
  - [Phase 2 — Python: one harness_paths module, extracted not invented](#phase-2--python-one-harness_paths-module-extracted-not-invented)
  - [Phase 3 — Bash: one sourceable library, six files, not fifteen](#phase-3--bash-one-sourceable-library-six-files-not-fifteen)
  - [Phase 4 — Vendored integration in CI (blocking), and the env-var collision](#phase-4--vendored-integration-in-ci-blocking-and-the-env-var-collision)
- [Closes](#closes)
- [Non-goals](#non-goals--named-so-they-stop-resurfacing)
- [Blast radius](#blast-radius)
- [Definition of done](#definition-of-done)
- [Reviewed by](#reviewed-by)
- [Phase 0 — built](#phase-0--built-revision-3-2026-09-02)
- [Review findings](#review-findings--two-headless-rounds-consolidated)

---

## Why this issue exists

Radar has watched the same defect class widen for three runs (report: `PROJECT/1-INBOX/RADAR-REPORT-2026-09-02.md`; live checklist: #293, target `RADAR-class-vendored-root-resolution`). Every instance has been fixed one at a time. This issue is the **one durable fix**, planned against a trace of the actual code rather than the symptom list.

**Recon map:** `PROJECT/1-INBOX/recon-harness-root-resolution.md` — commit `1b6058d7`, four read-only lanes, every claim below cites `file:line` from it.

**Revision 2 (2026-09-02).** This body folds in the 15 required changes from two headless reviews — DeepSeek V4 Pro (`relay-system/2026-09-02/gh396-plan-review-deepseek.md`, `8f18997d`) and Qwen 3.8 Max (`…/gh396-plan-review-qwen.md`, `c9f42ce7`) — plus two orchestrator corrections where both reviewers' reasoning was reversed by a test. The consolidated findings are the first comment on this issue. Revision 1 is in the issue's edit history.

## What the trace found (the part that changes the plan)

1. **Radar overcounted.** Reading the twelve issues it grouped, only **four are root resolution**: #215 and #358 (closed, fixed individually), **#395 (open, HIGH)**, **#394 (open)**. #393 sits in the same file and contract. #216/#349/#353 are "a parser written against this repo's own conventions" — PR #350 touched **zero** root-resolution lines (both reviewers confirmed). #253/#254/#255/#256 are individual features that merely happened to be *reported* from a vendored install. This issue fixes the class that produced the first five; it does not pretend to close twelve.

2. **The root resolution question is really two questions**, and the code conflates them: *where is the project* (`REPO_ROOT`/`TICK_REPO_ROOT`/`CALLER_ROOT`) and *where is the tooling* (`HARNESS`/`harness_home`/`XYZ_ROOT`). Bare layout: same directory. Vendored layout: `<repo>` vs `<repo>/.xyz`. **#395 is precisely a script answering question 2 and reusing the answer for question 1** — source-confirmed at `skills/relay-xyz/find-harness.sh:137-138`: the `XYZ_HARNESS` override branch at `:86-89` never sets `VENDORED=1` or `CALLER_ROOT`, so `TICK_REPO_ROOT` collapses onto `$HARNESS`. The same branch skips the staleness check at `:140-181`, so **#394 and #395 share one root cause**.

3. **Eight resolution strategies, ~290 sites, twelve spellings of "am I vendored?".** 15 byte-identical `dirname/..` prologues in `relay-automation/*.sh:15`; 20 Python `3×dirname(__file__)` copies; 14 distinct per-script override env vars; five copies of the same symlink-following loop. Full inventory in the recon map §State. **Plus one the map missed:** `utils/py/deepseek-turn.py:22` hardcodes an absolute path under one operator's `$HOME` (now #398).

4. **Two correct pieces already exist and are duplicated, not shared.** `utils/py/wave_reconcile.py:31-68` `harness_home()`+`harness_tool()` (the PR #359 pattern — repo-first with a documented target-repo carve-out at `:762`) and `utils/py/rtl.py:282-310` `resolve_turn_root` (raise-never-default, GH-551). `utils/py/jog_run.py:186-193` is a byte-identical copy of `harness_home()`. The plan **extracts these**; it does not invent a new resolver.

5. **The bug has never been pinned.** `test/find-harness.sh` contains **zero** references to `XYZ_HARNESS` or `TICK_REPO_ROOT`. 21 of 329 suites build a vendored fixture, each open-coded — **no shared fixture builder**. No CI job vendors the harness into a scratch repo.

6. **`XYZ_HARNESS` means two different things.** A filesystem path in `find-harness.sh:87` and the skill Step-0 snippets; a harness *name* in `utils/py/device_config.py:6,61,70`.

7. **Ten FROZEN Bash twins, eight of which resolve ROOT.** A fix landing there is dead code — two documented instances. **This plan does not touch them.**

8. **#393 was misdiagnosed in its own report.** The issue says the DeepSeek shim "never shells out to any `dsh` binary." `deepseek-turn.py:176-186` does (`subprocess.Popen(["node", deepseek_bin, …])`). It worked without `dsh` only because of the hardcoded path in finding 3. The readiness check (`command -v dsh`) and the runtime (`default_deepseek_bin()`) resolve the binary by **different rules** — that disagreement is the real #393.

## The strategy, in one paragraph

Make the two-root distinction explicit and single-sourced: one Python module and one sourceable Bash library that each answer `harness_home`, `repo_root`, `is_vendored`, and `harness_tool(rel)` — **with two deliberately separate precedence rules, never merged**: *which install* is env-first; *which copy of a tool inside it* is repo-first. Extracted from the code that already gets it right. Pin the #395 and #394 shapes in tests **before** touching the resolver (the Litmus/Nightwatch gate-first ordering this repo already uses). Replace the ad-hoc derivations in **live** code only, and only where the duplication is a real hazard. Add one shared vendored-fixture builder that vendors into `$TMPDIR` only, and one **blocking** CI job that vendors the harness into a scratch repo. Rename the colliding env var with a one-release deprecation alias. Every resolution prints one stderr line saying what it chose and why (`AGENTS.md:100`), silenceable with `--quiet`. No kill switch — the only behaviour delta is wrong→right.

## Phases

Each phase is independently shippable and leaves the tree green. Order is fixed: 0 must land red-then-green before 1; 1 before 2–3; 4 can run beside 2–3.

### Phase 0 — Pin the defect (gate first, arrives RED) — **BUILT at `87e30924`; as-built checklist and what it changed are under “Phase 0 — built” below**

- [x] `test/_vendored_fixture.sh` — one sourceable builder: `make_vendored_fixture <dir> [--stale <sha>] [--tier 1|2] [--symlink-inside|--symlink-outside] [--worktree]` that runs the real `relay-automation/xyz-vendor.sh --no-register` into a scratch repo and returns `<dir>` and `<dir>/.xyz`. **It MUST vendor into `$TMPDIR` only — never the harness's own checkout.** `xyz-vendor.sh:411-412` is `rm -rf "$VENDOR_DIR" && mv`, destructive if pointed at the real `.xyz/`. Guard it: refuse if the target resolves inside `$(git rev-parse --show-toplevel)` of the harness. *(review change 3)*
- [x] Add to `test/find-harness.sh` — **the #395 repro, five topologies**, each asserting `TICK_REPO_ROOT` from an `XYZ_HARNESS`-override run equals the value from an unset-override run of the same fixture: (a) plain vendored `.xyz`; (b) override pointing at a **linked worktree's** main-checkout `.xyz` while CWD is the worktree; (c) **symlinked `.xyz` inside the repo** (`.xyz -> ./vendor/xyz`); (d) **symlinked `.xyz` to a directory outside the repo** — this one must additionally assert that the `dirname` **fallback** fired, because `git -C <link> rev-parse` returns `fatal: not a git repository` there (orchestrator correction A); (e) a **precedence table** — one assertion per step 1–5 of `find-harness.sh:86-126` so any reordering is a visible diff. *(review change 1)*
- [x] Add to `test/find-harness.sh` — **the #394 shape**: vendored fixture with an older `source_commit` in `VERSION`, assert the WARNING fires *even when `XYZ_HARNESS` is exported*, and assert the remedy line is executable as printed (`bash -n` it, then run it with `--dry-run`).
- [x] Add to `test/find-harness.sh` — **`--quiet`**: `find-harness.sh --quiet --env 2>&1 | grep -c '^find-harness:'` is 0, and the exported names are unchanged. *(review change 2)*
- [x] Add `test/gh393-deepseek-readiness.sh`: `RELAY_HAS_DEEPSEEK=1` iff `python3 ≥ 3.8` **AND** the binary resolves by **the shim's own rule** (`$DEEPSEEK_BIN` → `dsh` on PATH → the documented sibling-clone path; see #398) **AND** (`OPENROUTER_API_KEY` or `DEEPSEEK_API_KEY`). Negative controls: binary present + no key → 0; key present + no binary → 0. *(review change 6)*
- [x] Settle the two recon unknowns that gate the tests: `xyz-sync.sh`'s `update` grammar (`sed -n '1,60p' relay-automation/xyz-sync.sh`) and whether any of the ~19 unread root-named tests pins a precedence Phase 1 changes (`rg -n 'XYZ_HARNESS|TICK_REPO_ROOT|CALLER_ROOT' test/gh129-relay-tick-root.sh test/gh131-marathon-target-root.sh test/gh292-worktree-vendored-discovery.sh test/gh293-vendored-guard-drift.sh test/gh304-vendored-relay-path.sh test/gh417-turn-root-symlink-prefix.sh test/marathon-root-audit.sh test/relay-target-root*.sh`). Record the answers in the 2-WORKING doc.
- [x] **Acceptance:** the new suites are registered in `validate.sh`'s `TESTS` array (bidirectional guard, PR #308, will refuse otherwise) and **all fail** at the pre-fix commit. Record that commit SHA and the red output in the 2-WORKING doc.

### Phase 1 — `find-harness.sh`: two roots, one precedence, announced
 
- [x] In the override branch (`:86-89`): after a candidate passes `_has_harness`, **if its basename is `.xyz`, set `VENDORED=1` and `CALLER_ROOT="${_g:-$(git -C "$_o" rev-parse --show-toplevel 2>/dev/null || dirname "$(cd "$_o" && pwd)")}"`** — the override selects *which harness*, it does not get to redefine *which repo*. The `||` fallback is load-bearing (symlink-outside case, correction A); keep **logical** `pwd`, not `pwd -P`. This alone closes #395. *(review change 4)*
- [x] Move the staleness block (`:140-181`) out from under the `VENDORED=1`-only gate so an override pointing at a stale vendored copy still warns. Rewrite the remedy at `:170` to the confirmed grammar, absolute, copy-paste runnable (exact form settled in Phase 0).
- [x] When a documented script is requested from a vendored tree and is absent, and staleness was detected, the error names the staleness as the cause (#394's second half): `--env` exports `XYZ_VENDORED_STATUS=behind|current|different|unknown` and `XYZ_VENDORED_COMMIT`; `resolve-profile.sh:25` reads them and says "vendored copy is behind (`<sha>`); this script landed after it" instead of `No such file or directory`.
- [x] `--env` additionally exports `XYZ_VENDORED=0|1` and `XYZ_CALLER_ROOT` so no downstream consumer re-derives them.
- [x] **#393 (rewritten):** `RELAY_HAS_DEEPSEEK` = `python3 ≥ 3.8` AND binary-by-the-shim's-rule AND an API key. `find-harness.sh:204-206` must call the **same** resolution the shim uses — expose `default_deepseek_bin()` as a `--print-bin` mode of `deepseek-turn.py` or a tiny shared helper, so the check cannot drift from the runtime again. The hardcoded path itself is #398, not this issue. *(review change 6, correction B)*
- [x] **Announce every resolution** on stderr unless `--quiet`: `find-harness: HARNESS=<h> REPO_ROOT=<r> vendored=<0|1> via=<override|caller-.xyz|worktree-.xyz|git-root|self>`. Mirrors `validate.sh:41-52`'s "announced, never silent" idiom.
- [x] **Acceptance:** Phase 0 suites go green; `test/gh346-gateway-allowlists.sh:387-394` still passes (no exported name removed); `--quiet` suppresses the announcement and nothing else; `UPGRADE.md:571-578`'s GH-234 workaround paragraph is deleted and GH-234 closed citing this commit. **Known and accepted:** after this change `find-harness.sh` warns from `.xyz/VERSION` and `xyz-sync.sh check` warns from `~/.config/xyz/registry.tsv`; the two can disagree (two writers, no single write path — recon map §State). A single store is a `spike-360` non-goal, stated so nobody is surprised by two answers. *(review changes 5, 7)*

### Phase 2 — Python: one `harness_paths` module, extracted not invented

- [x] Create `utils/py/harness_paths.py` by **moving** `harness_home()` and `harness_tool()` out of `wave_reconcile.py:31-68` verbatim, plus `is_vendored(path)` (single spelling: `os.path.basename(os.path.realpath(p)) == ".xyz"`) and `repo_root()` (= `dirname(harness_home())` when vendored, else `harness_home()`). It **raises**, never defaults — same rule as `rtl.py:281`.
- [x] **The module docstring states, verbatim in spirit:** *"Two resolution questions live here and they are deliberately separate. `resolve_harness()` selects which clone/install to use — env override → caller `.xyz` → worktree `.xyz` → git root → self. `resolve_tool(repo_root, rel, prefer_repo=True)` selects which copy of a tool file inside that install — repo-first so a canonical checkout and test mocks shadow the harness copy (`test/gh358-…:128-131`), harness-home fallback. Their orderings differ by design and are never merged into one ladder."* *(review change 8)*
- [x] **Shadow risk is exposed, not hidden:** `resolve_tool(rel, prefer_repo=True)` is the existing contract for the five harness tools `wave_reconcile` runs. A consumer repo carrying its own same-named `utils/…` file would win silently under repo-first. New consumers pass `prefer_repo=False`; the docstring names the risk and the flag. *(review change 9)*
- [x] Replace the duplicates: `jog_run.py:186-193` (delete, import); `marathon_plan.py:111-124` (the literal `.xyz/utils/…` strings become `resolve_tool(…)`); `swarm_preflight.py:16-21` `compute_default_root` (import; **keep** the deliberate second anchor at `:1171` — Qwen read it and confirmed it is the `utils/` sibling lookup, a different question — and say so in a comment); `marathon_drive.py:1038-1042` and `:1178-1179`.
- [x] **Do not touch** `rtl.py:288 resolve_turn_root` or its five call sites — `test/gh308-turn-shim-parity.sh:73-88` asserts the literal call shape. `harness_paths` may be *called by* `rtl`, never the reverse.
- [x] **Keep** the `utils/pdda/pdda.sh` carve-out at `wave_reconcile.py:762` repo-relative; `test/gh358-…` plants a decoy at `.xyz/utils/pdda/pdda.sh` that must never run.
- [x] **Acceptance:** `rg -n 'basename\(.*\)\s*==\s*"\.xyz"' utils/py` returns exactly one hit (inside `harness_paths.py`); `test/gh358-wave-reconcile-vendored-paths.sh`, `test/gh273-marathon-root-audit-python-shape.sh`, `test/gh280-jog-marathon-adapter.sh`, `test/gh308-turn-shim-parity.sh` all green.

### Phase 3 — Bash: one sourceable library, **six files, not fifteen**

- [ ] Create `relay-automation/harness-paths.sh` — sourceable, provides `xyz_resolve_self_dir` (the one symlink-following loop currently copied five times), `xyz_harness_home`, `xyz_repo_root`, `xyz_is_vendored`, `xyz_harness_tool <rel>`, and the shared `--env` export stanza. It lives in `relay-automation/` because that is in `VENDOR_DIRS` (`xyz-vendor.sh:344`). **It sources `driver-lock-lib.sh` itself**, so `find-harness.sh:76`'s dependency is preserved when that line moves. *(review change 11)*
- [ ] Adopt it in **exactly** the five symlink-loop sites — `find-harness.sh:66-73`, `skills/hq/find-hq.sh:34-58`, `skills/file-xyz-bug/find-xyz.sh:37-75`, `skills/vendor-stack/find-pdda.sh:38-46`, `relay-automation/gate-env.sh:27-35` — and the four `find-*.sh` locators' export stanzas. *(review change 10)*
- [ ] **`find-xyz.sh` adopts only the symlink loop, not `xyz_harness_home`.** Its `:22-25` policy — a vendored `.xyz` is never authoritative for filing a bug — is correct and stays. *(review change 12)*
- [ ] The other ~10 live scripts with inline vendored predicates (`relay-automation/{finding-new,oracle-guard,smallcode-turn,target-checks,marathon,marathon-agent,improve-loop}.sh`, `utils/marathon-plan.sh`, `utils/swarm-preflight.sh`, `utils/roadmap-dashboard.sh`) get a **one-line comment** pointing at the library. Nothing else. Their predicates are simple and stable; the Python lane is authoritative.
- [ ] Replace the byte-identical Step-0 snippet in `skills/marathon-triage/SKILL.md:30-45` and `skills/10days/SKILL.md:91-105` with `eval "$("$L" --env)"` using the locator loop `skills/relay-xyz/SKILL.md:23-30` already documents.
- [ ] **Do not touch the ten FROZEN twins.**
- [ ] **Acceptance:** the symlink-following loop appears once in the tree (`rg -c 'readlink' relay-automation skills --glob '*.sh'` names only `harness-paths.sh` among non-FROZEN files); `test/gh308-frozen-twin-guard.sh` confirms no frozen twin changed; `test/gh448-driver-lock-resolver.sh` still green.

### Phase 4 — Vendored integration in CI (blocking), and the env-var collision

- [ ] Add a `vendored-smoke` job to `.github/workflows/ci.yml`: checkout, `xyz-vendor.sh --no-register` into a scratch repo under the runner's temp dir, then run the Phase 0 suites plus `test/gh358-…` and `test/gh292-…` **from inside the scratch repo** against `.xyz/`. **`continue-on-error: false` on both `development` and `main`.** Corrected premise: `boundary-macos` runs on `main` only (`ci.yml:152`) and `canary-ubuntu` is advisory (`:243`) — there is no existing "blocking on development" pattern to copy, and the one job that exercises the vendored surface must not inherit the advisory default. *(review change 13)*
- [ ] Resolve the `XYZ_HARNESS` collision: `device_config.py:6,61,70` reads `XYZ_DEFAULT_HARNESS` first and falls back to `XYZ_HARNESS` **only if the value is not an existing directory**, with a one-line deprecation warning. **Update the module docstring at `device_config.py:5-7`** to name `XYZ_DEFAULT_HARNESS` as the harness-name var and `XYZ_HARNESS` as the path var with the deprecation note. Document in `UPGRADE.md`. *(review change 14)*
- [ ] Migrate the 21 open-coded vendored fixtures to `test/_vendored_fixture.sh` **only where a suite is already being edited** by Phases 1–3; the rest are a follow-up, listed by name in the 2-WORKING doc.
- [ ] **Acceptance:** `vendored-smoke` is green and blocking on `development`; `rg -n 'XYZ_HARNESS' utils/py/device_config.py` shows only the deprecation fallback and the docstring note.

## Closes

Directly: **#393** (readiness half; the hardcoded path is #398), **#394, #395**, and **GH-234** (same defect as #395 from the other side, per `UPGRADE.md:571-578`). Retires `RADAR-class-vendored-root-resolution`'s first two checklist items in #293. Structurally prevents the class that produced #215 and #358.

## Non-goals — named so they stop resurfacing

- **#216, #349-follow-ups, #353**: ledger-parser generalisation. Different class, different file, own issue.
- **#253, #254, #255, #256**: not resolution defects; leave on their own issues.
- **The ten FROZEN Bash twins**: 0.8.0 Sundown owns their retirement.
- **The ~250 `ROOT="$(cd "$HERE/.." && pwd)"` lines in `test/*.sh`**: they resolve the bare harness repo the test lives in — correct as written.
- **A single global "current harness" pointer** (the third store the recon found missing): needs `spike-360` first. The two existing stores can disagree after this plan; Phase 1 says so.
- **`find-pdda.sh:62-80`'s `$HOME` path guessing** and **`deepseek-turn.py:22`'s hardcoded path** (#398): portability defects, own issues.
- **The 14 per-script override env vars** (`CODEX_TURN_ROOT`, `MARATHON_ROOT`, `QUEUE_PLAN_ROOT`, `SWARM_PREFLIGHT_ROOT`, …): they are *target-repo* overrides, not harness overrides, and survive unchanged.
- **A kill switch.** Removed in revision 2 — the only behaviour delta is wrong→right in one topology and the sole workaround is being deleted. *(review change 15)*
- **`relay-drive --review-once` misclassifying a no-op turn as exit 5** (#397): found during this plan's review, dark-telemetry class, own issue.

## Blast radius

Starts from the recon map's current-state radius and adds what this plan introduces:

- **Every shell that `eval`s `find-harness.sh --env`** gains four exported names (`XYZ_VENDORED`, `XYZ_CALLER_ROOT`, `XYZ_VENDORED_STATUS`, `XYZ_VENDORED_COMMIT`) and one stderr line (suppressible). No name is removed. DeepSeek verified each of the eight in-tree script callers: none captures `--env` stderr or counts lines.
- **`TICK_REPO_ROOT` changes value** for exactly one topology — override pointing at a `.xyz` dir — from wrong to right. `UPGRADE.md:571-578`'s workaround is deleted in Phase 1.
- **`RELAY_HAS_DEEPSEEK` may flip 1→0** on a machine that has `dsh` on PATH but no API key. That is a correct 0; it was a false 1.
- **Python import graph**: `wave_reconcile`, `jog_run`, `marathon_plan`, `swarm_preflight`, `marathon_drive` gain one import. `rtl.py` unchanged.
- **Bash source graph**: six files gain one `source`. The 10 FROZEN twins are untouched; `XYZ_PYTHON=0` users see no change.
- **Consumer repos** (`rebalanceOS`, `LTVera-Pandas`, `aegis-sleuth-slack-bot`) see the fix on their next `xyz-sync update`.
- **No kill switch.** Rollback is `git revert` of the Phase 1 commit; Phase 0's tests go red again, which is the signal that it happened.

## Definition of done

`validate.sh` green on macOS boundary; `vendored-smoke` green and **blocking** on `development`; the Phase 0 suites exist and were observed red at the pre-fix commit and green at the fix commit (both SHAs recorded); #393/#394/#395/GH-234 closed citing commits; the `rg` acceptance greps in Phases 2–3 hold; `PROJECT/2-WORKING/GH-396-*.md` has a Lessons Learned section; #293's `RADAR-class-vendored-root-resolution` items 1–2 struck with the commit SHA.

## Reviewed by

DeepSeek V4 Pro and Qwen 3.8 Max, 2026-09-02, both `STATUS: Open` on revision 1. Revision 2 (this body) applies their 15 upheld changes and two orchestrator corrections; see the first comment on this issue for the adjudication.

---

## Phase 0 — built (revision 3, 2026-09-02)

Built in a full clone at `~/marathon-clones/gh396-phase0` on `feat/gh396-harness-root-resolver`,
commit `87e30924`. Every guard the repo runs on new test code is green (`gh139`, `security-scan`,
`mktemp-trap-guard`, `gh306-registry-bidirectional`). **Both suites arrive red, as designed:**

| Suite | Observed at `1114627b` | What the reds are |
|---|---|---|
| `test/gh396-find-harness-roots.sh` | **17 pass / 8 fail** | the four #395 topologies (plain, linked-worktree override, symlink-inside, symlink-outside); both #394 halves (warning suppressed under override; remedy `xyz-sync --update <dir>` not runnable as printed); `--quiet` (exit 2 usage) ×2 |
| `test/gh393-deepseek-readiness.sh` | **6 pass / 3 fail** | ambient flag is 0 while the shim's own rule resolves the hardcoded path (#398 leg); the flag ignores the API key in both directions |

Every control assertion passed — the precedence table (steps 1, 2, 4, 5; step 3 delegated to
`gh292`), the symlink-outside proof that `git -C <link>` fails and the fallback is load-bearing,
and the oracle's own existing→1 / missing→0 check.

### What building it changed in the plan (the reason this revision exists)

1. **The fixture builder lives at `test/lib/vendored-fixture.sh`, not `test/_vendored_fixture.sh`.**
   `test/lib/` is the established helper home (`fixture-guard.sh`, `clone-identity.sh`,
   `runner-envelope.sh`) and the bidirectional registry guard (`gh306`) already exempts it. A
   top-level `test/_*.sh` would have needed a new exemption.
2. **The builder has two modes, and locator tests use the fast one.** `--stub` (default) plants the
   two marker files `find-harness.sh` probes plus a `VERSION` file — milliseconds, and it is what
   `test/find-harness.sh` and `gh292` already do by hand. `--real` runs `xyz-vendor.sh --no-register`
   — seconds and megabytes per fixture, right only for suites that *execute* vendored tools. The
   plan's "runs the real `xyz-vendor.sh`" wording was correct for integration and wrong as a default.
3. **The safety refusal is two-sided and on physical paths.** The target must be under `$WORK`
   *and* must not be under the harness checkout, both resolved with `cd -P`, so a symlink cannot
   smuggle the real tree past the guard. Refusal names both paths.
4. **The #395 suite is a new file, not an extension of `test/find-harness.sh`.** The existing suite
   uses a grandfathered `ok "$1" "$2"` eval helper that the GH-64 security gate rejects in new
   code. New assertions use the decided-verdict `ok`/`bad` form (`gh292`'s idiom) and
   capture-then-match (`gh139`). Leaving the GH-70 suite untouched also keeps its history clean.
5. **The #395 oracle is "override agrees with auto-discovery on the same fixture," not a hardcoded
   expected path.** That makes the test immune to being "fixed" by redefining the right answer —
   it passes only when both resolution paths agree. Each topology additionally asserts the
   override still selects the harness it names, so Phase 1 cannot pass by ignoring overrides.
6. **The #393 pin is parity, not a value.** `RELAY_HAS_DEEPSEEK` must equal
   `python3 ≥ 3.8 ∧ shim-rule-resolves-existing-file ∧ API-key` in the same environment. The
   shim's rule is **ast-extracted** (`default_deepseek_bin` only) because `deepseek-turn.py`'s
   module-level imports are not importable without the harness `PYTHONPATH`; `ast.fix_missing_locations`
   is required on the synthesized module. Case 3 neutralises the hardcoded-path leg by `sed`-ing a
   copy of the shim — the only way to make "unresolvable" true on a machine where that path exists.
7. **A lesson the suite taught its own author, kept as a header comment:** the first draft wrapped
   cases in `( … )` subshells; `pass`/`fail` incremented inside were lost and the suite printed
   two `FAIL` lines then reported `0 fail, exit 0`. *A check that cannot fail is not a check*
   (`AGENTS.md:100`). Cases now use `env -u … bash -c "$(declare -f actual_flag); …"` — which
   also sidesteps the security scan's `credential-literal` rule, which fires on the literal text
   `API_KEY=` even when clearing a variable.
8. **Tests run unsandboxed or not at all.** The repo's GH-177 hook refuses any test invocation
   under the sandboxed Bash tool (a sandbox-broken `mktemp` once fed an `rm -rf` trap that wiped
   the checkout twice). Every Phase 0 run used `dangerouslyDisableSandbox: true`. Phase 1–4
   executors must know this up front.
9. **1-INBOX docs are not coverage-exempt in this repo.** `pdda-check-roadmap-coverage` refused
   the push until #396 was parked via `releases_app.py roadmap add` (the DB is roadmap truth;
   `ROADMAP.md` is regenerated, never hand-edited). The radar skill's "1-INBOX carries no
   coverage requirement" is wrong for XYZ-forge; the radar SKILL.md should be corrected.
10. **Recon unknowns settled.** `xyz-sync.sh` accepts both `update <dir>` and `--update <dir>`
    (`:12-19`); the #394 remedy defect is that neither `xyz-sync` is on PATH, not the verb. None of
    the 16 unread root-named suites references `XYZ_HARNESS`/`CALLER_ROOT`; `gh292` pins step 3
    (linked worktree → main `.xyz`) via `--root` and `--env`, which Phase 1 preserves.

### Phase 0 checklist, as built

- [x] `test/lib/vendored-fixture.sh` — `make_vendored_fixture <dir> [--stub|--real] [--stale <sha>] [--tier 1|2] [--symlink-inside|--symlink-outside] [--worktree <path>]`, `remove_vendored_fixture`; refuses targets outside `$WORK` or inside the harness checkout.
- [x] `test/gh396-find-harness-roots.sh` — five #395 topologies with the agree-with-auto oracle; #394 warn-under-override + remedy-runnable; `--quiet` accepted / silences only the announcement / exports identical.
- [x] `test/gh393-deepseek-readiness.sh` — parity pin with ast-extracted oracle, two negative controls, oracle self-check.
- [x] Both registered in `validate.sh`'s `TESTS` (with "arrives RED by design" in the comment); `gh306` green.
- [x] Recon unknowns settled (item 10) — recorded here rather than in a 2-WORKING doc, since the doc has not been promoted yet.
- [x] Red observed and recorded: `1114627b` → 17/8 and 6/3.

### What Phase 1 inherits from this

- The `--quiet` flag must be added to the `case` at `find-harness.sh:213` **before** the announcement is added, or every existing caller's stderr changes in the same commit as the flag that silences it.
- The #394 remedy line must print `bash <live-harness>/relay-automation/xyz-sync.sh update <caller-root>` — `LIVE_HARNESS` is already resolved at `:140-153` when the warning fires, so the absolute path is available.
- `RELAY_HAS_DEEPSEEK` needs a shared binary rule. The cheapest honest form: `deepseek-turn.py --print-bin` (prints `default_deepseek_bin()` and exits 0/1 on existence), called from `find-harness.sh:204-206`. Then the suite's ast oracle and the runtime cannot drift.

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

**B. #393 — the issue's own premise was wrong, and the plan inherited it.** Issue #393 says the shim "never shells out to any `dsh` binary." `deepseek-turn.py:176-186` does: `subprocess.Popen(["node", deepseek_bin, "--profile", "headless", …])`. It succeeded on this machine with no `dsh` on PATH because `deepseek-turn.py:22` hardcodes `$HOME/Documents/GH Repos/deepseek-harness/apps/cli/lib/bin.js`, which exists here. That hardcoded absolute path is itself a recon-map strategy-6 site the map missed, and it is why the readiness check (`command -v dsh`) and the runtime (`default_deepseek_bin()`) disagree. Change 6 above is the honest fix; **replacing the hardcoded path with a discoverable one is a separate issue** and should be filed as its own issue.

### Unchanged after review
- The scope re-sort (4 of 12 are root resolution; PR #350 touched zero root lines) — DeepSeek 1 agree, Qwen did not contest.
- Blast radius: no in-tree consumer captures `--env` stderr or counts its lines — DeepSeek 6 verified each of the eight script callers.
- `swarm_preflight.py:1171`'s second anchor stays — Qwen 14 read it and confirms it is a different question (the `utils/` sibling, not the root).

### Follow-ups to file separately, not folded in
- `relay-drive --review-once` classifies a shim that wrote nothing as exit 5 "non-approval handback" (observed twice today). Dark-telemetry class.
- `deepseek-turn.py:22` hardcoded machine path.
- Command Code account out of credits (`glm 5.3 max` profile is unusable until topped up).
