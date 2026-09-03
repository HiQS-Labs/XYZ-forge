# Recon Map — harness root / vendored `.xyz/` resolution
Commit: `1b6058d7` · Mode: grep+read (no codebase-memory index consulted) · Lanes: A, B, C, D — all four ran, all four report `CUT OFF AT` honestly below

## Subject and change class

**Subject.** How every script in this harness answers three questions: (1) where is the **project** I'm operating on (`REPO_ROOT` / `TICK_REPO_ROOT` / `CALLER_ROOT`); (2) where does the **harness tooling** live (`HARNESS` / `harness_home` / `XYZ_ROOT`) — the bare repo root, or a vendored `.xyz/` subdirectory inside a consumer repo; (3) when several installs exist, which is authoritative.

**Change class: contract change + cross-module change.** Not state/authority — there is no new source of truth proposed; the existing `.xyz/VERSION` and `~/.config/xyz/registry.tsv` stay. But `find-harness.sh --env` is `eval`'d into every downstream shell and its precedence order is the thing being changed, and `XYZ_HARNESS` is a public env-var name whose meaning is currently ambiguous. `spike-360` not required.

**The twelve issues, re-sorted after reading them** (RADAR grouped them by `reported_from:`, which conflates "reported from a vendored install" with "caused by vendored resolution"):

| Sub-class | Issues | Belongs to this change? |
|---|---|---|
| **Root resolution proper** — a script picks the wrong root or the wrong harness | #215 (closed), #358 (closed, PR #359), **#395 (open, HIGH)**, **#394 (open)** | **Yes — the core** |
| **Capability / readiness check wrong** in `find-harness.sh` | **#393 (open)** | Yes — same file, same `--env` contract, cheap to carry |
| **Parser written against this repo's own conventions**, never generalised | #216 (open), #349 (closed, PR #350), #353 (closed) | **No** — PR #350 touched zero root-resolution lines (`git show 33e0dfd4 -- utils/py/releases_app.py` has 3 hunks mentioning `ROADMAP_NAME`, all in error strings). Separate class. |
| **Individual features / UX**, merely observed from a vendored install | #253 (rate parked row), #254 (sort order), #255 (remedy text), #256 (artifact preflight) | **No** — none touches resolution |

So the durable fix targets **4 open issues** (#393, #394, #395, plus #216 only if the operator wants it in-band) and closes the class that produced #215 and #358, not "twelve." Saying twelve was the radar's overcount, and the plan should say so.

## The seams — where a change here escapes this file

| Seam | Location | Crosses | Breaks if |
|---|---|---|---|
| `find-harness.sh --env` output shape | `skills/relay-xyz/find-harness.sh:217-230` | Every shell that `eval`s it: `UPGRADE.md:566-570`, `skills/relay-xyz/SKILL.md:98-110,292`, `skills/hq/SKILL.md:39`, `skills/file-xyz-bug/SKILL.md:30-38`; script callers `relay-automation/driver-lock-lib.sh`, `utils/py/marathon_drive.py`, `utils/py/relay_drive.py`, `utils/py/rtl.py`, `utils/hq/marathon-live.sh`, `skills/hq/find-hq.sh`, `skills/vendor-stack/find-pdda.sh`, `skills/file-xyz-bug/find-xyz.sh` | Any exported name is removed or renamed; `RELAY_HAS_*` flags change meaning (`test/gh346-gateway-allowlists.sh:387-394` pins them) |
| `find-harness.sh` 5-step precedence | `find-harness.sh:86-126` | Same as above, plus GH-234 workaround text in `UPGRADE.md:571-578` | Step order changes and a user's exported `XYZ_HARNESS` stops winning — or keeps winning, which is #395 |
| `XYZ_HARNESS` env var — **two meanings** | Path: `find-harness.sh:87`, `skills/*/SKILL.md` Step-0 snippets. **Harness *name*:** `utils/py/device_config.py:6,61,70` | A resolver that *writes* `XYZ_HARNESS` corrupts device config; a device-config user who exports it as a name breaks path resolution | Either side reads the other's value |
| `resolve_turn_root(...)` call literal | `utils/py/rtl.py:288`; callers in all 5 Python turn shims | `test/gh308-turn-shim-parity.sh:73-88` asserts the literal call shape structurally | Any refactor renames or wraps the call |
| `harness_tool()` repo-first precedence | `utils/py/wave_reconcile.py:31-68` | `test/gh358-wave-reconcile-vendored-paths.sh:128-131` (a canonical checkout must prefer its own copy); carve-out for `utils/pdda/pdda.sh` at `:762` (target-repo tool, must stay repo-relative) | Harness-first ordering is adopted; the pdda carve-out is generalised away |
| `basename == ".xyz"` vendored predicate | 12 spellings — see "State" | `marathon_plan.py:111-124` emits *literal* `.xyz/` command strings; `swarm_preflight.py:1171` deliberately keeps a second, shallower anchor | A single predicate normalises the depth and one of the two anchors moves |
| FROZEN Bash twins | 10 files, banner at line 2; 8 resolve ROOT | `test/gh308-frozen-twin-guard.sh` | A root fix lands in a frozen twin — it is dead code (RADAR-class-frozen-twin-dead-fix, 2 documented instances) |
| `.xyz/VERSION` ↔ `registry.tsv` ↔ live-HEAD | `xyz-vendor.sh:382-386` (writes VERSION), `:307-334` (writes registry), `find-harness.sh:140-181` (reads VERSION, compares to live) , `xyz-sync.sh:404-455` (reads registry, compares to *this clone*) | Two staleness answers from two files written in the same second | Either writer is skipped (`--no-register`, lock unavailable, dir unwritable — `xyz-vendor.sh:180-188,314`) |
| `VENDOR_DIRS` payload list | `xyz-vendor.sh:344` | Anything the helper ships must be in `relay-automation bin src utils test skills`; the GH-312 preserve list at `:400-414` | A new helper file lands outside those six dirs — it silently does not vendor |

## Call paths in

```
operator / agent shell
  └─ eval "$(skills/relay-xyz/find-harness.sh --env)"      find-harness.sh:213-230
       ├─ step 1  $XYZ_HARNESS / $XYZ_REPO_ROOT            :86-89   ← #395 enters here
       ├─ step 2  <git-toplevel>/.xyz                      :91-101  sets VENDORED=1, CALLER_ROOT
       ├─ step 3  <git-common-dir>/../.xyz  (worktree)     :103-116 sets VENDORED=1
       ├─ step 4  <git-toplevel> itself                    :118-121
       ├─ step 5  $SELF_DIR/../..                          :123-126
       ├─ TICK_REPO_ROOT = HARNESS, or CALLER_ROOT iff VENDORED=1   :137-138  ← #395 collapses here
       ├─ staleness warn  iff VENDORED=1 && LIVE_HARNESS found      :140-181  ← #394 remedy line at :170
       └─ readiness  RELAY_HAS_DEEPSEEK ← `command -v dsh`          :~200     ← #393

bin/tick                              bin/tick:19-51       reads TICK_REPO_ROOT, warns on foreign CWD
relay-automation/relay-drive.sh       (FROZEN) → utils/py/relay_drive.py → rtl.resolve_turn_root  rtl.py:288
relay-automation/*-turn.sh ×5         (FROZEN) prologue :15 sets XYZ_ROOT from dirname/.. → exec utils/py/*-turn.py
utils/py/wave_reconcile.py:750-757    harness_tool(repo_root, rel) ×5                          (PR #359 pattern)
utils/py/jog_run.py:186-193           harness_home()  — byte-identical duplicate of wave_reconcile's
utils/py/marathon_plan.py:111-124     is_vendored → literal ".xyz/utils/…" strings
utils/py/swarm_preflight.py:16-21     compute_default_root (two-.. correction, GH-267) + second anchor at :1171
utils/py/marathon_drive.py:1038-1042  basename(xyz_harness)==".xyz" → default_root
skills/marathon-triage/SKILL.md:30-45 ┐ byte-identical inline Step 0 — no _has_harness validation,
skills/10days/SKILL.md:91-105         ┘ probes utils/swarm-preflight.sh, never derives TICK_REPO_ROOT
skills/consult/SKILL.md:52-56         third dialect: git toplevel → CONSULT_ROOT mandatory
skills/vendor-stack/find-pdda.sh      fourth dialect + $HOME path guessing :62-80
```

## State

**Read sites for "which root":** ~290 (Lane A: ≈40 production, ≈250 test), across **8 strategies**:

1. dirname-of-self + `..` — 15 byte-identical prologue copies in `relay-automation/*.sh:15`, 20 Python `3×dirname(__file__)` copies, no vendor awareness
2. dirname-of-self + `basename == ".xyz"` — 6 sites, **sh and py twins disagree on hop count** (GH-267)
3. env-var override, first hit wins — **14 distinct override names** (`CODEX_TURN_ROOT`, `MARATHON_ROOT`, `QUEUE_PLAN_ROOT`, `SWARM_PREFLIGHT_ROOT`, `ROADMAP_DASHBOARD_ROOT`, …)
4. `git rev-parse --show-toplevel` — turn shims, githooks, `bin/tick`
5. symlink-following self-resolution + marker walk — the 4 `find-*.sh` locators + `gate-env.sh`, **5 copies of the same 8-line symlink loop**
6. hardcoded `$HOME/...` guesses — `find-pdda.sh:62-80` only
7. registry lookup — `~/.config/xyz/registry.tsv`, default expression copy-pasted 6×; `hq-lib.sh:88-118` is the only "which install wins" tiebreak (vendored-wins within a repo)
8. post-hoc collapse by path comparison — `relay-turn-lib.sh:283-300` (GH-160) exists *because* strategies 1+4 get it wrong

**The vendored predicate is spelled 12 ways:** `basename == ".xyz"` (×6), `${1##*/} == ".xyz"`, `case */.xyz)` (×3), awk `parts[n]==".xyz"`, `VENDORED=1` flag, absence-of-`.git` (`driver-lock-lib.sh:14,34`), "not my own toplevel" (`relay-turn-lib.sh:283`), and 3 path-probes.

**Write sites for "which harness is current":** three stores, two writers, **no single write path** (Lane B §6):
- `.xyz/VERSION` — written only at `xyz-vendor.sh:382-386`; read only at `find-harness.sh:32-39`
- `~/.config/xyz/registry.tsv` — written only at `xyz-vendor.sh:203-231`; skippable; read only at `xyz-sync.sh:162-205`
- "the live harness" — **no recorded pointer at all**; `find-harness.sh:140-153` guesses from env or `SELF_DIR/../..`; `xyz-sync.sh:74` independently guesses `SELF_DIR/..`

**Already-shared Python pieces worth extracting rather than reinventing:**
- `utils/py/wave_reconcile.py:31-68` — `harness_home()` + `harness_tool(repo_root, rel)`, repo-first with a documented target-repo carve-out. **This is the pattern that fixed #358 and it is correct.**
- `utils/py/rtl.py:282-310` — `resolve_tick_repo_root` / `resolve_turn_root`, raise-never-default (GH-551), precedence documented in-line.
- `utils/py/jog_run.py:186-193` — duplicate of `harness_home()`, to be deleted in favour of the shared one.

## Contracts

| Name | Consumer | Breaking if | Declared |
|---|---|---|---|
| `HARNESS`, `TICK_REPO_ROOT`, `TICK`, `*_BIN`, `RELAY_HAS_*` from `--env` | every eval'ing shell + 8 script callers | any name dropped | `find-harness.sh:217-230`; `SKILL.md:292`; `test/gh346-gateway-allowlists.sh:387` |
| `XYZ_HARNESS` = path | `find-harness.sh:87`, 2 skill Step-0 snippets, `SKILL.md:23` locator | value not a harness dir | `UPGRADE.md:566`, `find-harness.sh:130` error text |
| `XYZ_HARNESS` = harness **name** | `device_config.py:6,61,70` | value is a path | undocumented outside the file |
| `RELAY_AGENT` | 6 Python turn shims (die without it) | resolver exports/clears it | `codex-turn.py:29` et al. |
| `XYZ_HARNESS_CONTEXT`, `XYZ_HARNESS_DB/_SQL/_GENERATED_MD/_DOCS_DIR` | gate_env, harness_app, site_build | greedy `XYZ_HARNESS*` prefix handling | `MACHINE-CONTRACTS.md:50`; `harness_app.py:24-54` |
| `XYZ_PYTHON=0` → FROZEN Bash lane | every driver | a helper landing only in Python is absent under `=0` | `AGENTS.md:40-42` |
| `resolve_turn_root(...)` literal | 5 py shims | wrapped/renamed | `test/gh308-turn-shim-parity.sh:73-88` |
| `harness_tool` repo-first | wave_reconcile | harness-first | `test/gh358-…:128-131` |
| `utils/pdda/pdda.sh` stays repo-relative | wave_reconcile:762 | generalised away | test plants a decoy at `.xyz/utils/pdda/pdda.sh` |
| `VENDOR_DIRS` | consumers | new file outside the six dirs | `xyz-vendor.sh:344` |
| `xyz-sync --update <repo>` remedy line | operators (copy-paste) | **already broken** — not on PATH (#394) | `find-harness.sh:170` |
| "vendored is never authoritative" | `find-xyz.sh:22-25` (intake locator refuses `.xyz`) | shared helper makes vendored-wins universal | in-file policy |

## Build, failure and rollback today

**Tests.** 329 registered suites (`validate.sh:55`); **21 construct a vendored fixture**, each open-coded — **no shared vendored-fixture builder**. `test/find-harness.sh` has **0 references** to `XYZ_HARNESS` or `TICK_REPO_ROOT`: the override branch and the collapse at `:137-138` have never been pinned. `test/gh308-turn-shim-parity.sh` pins the Python resolver call shape; `test/gh358-…` pins repo-first precedence; `test/gh273-marathon-root-audit-python-shape.sh` pins sh/py root-shape parity.

**CI.** `ci.yml:150-194` `boundary-macos` runs `validate.sh --sequential` on macOS, **main only**. `ci.yml:234-245` `canary-ubuntu` is `continue-on-error`. **No job vendors the harness into a scratch repo** — the vendored integration surface is exercised only inside individual fixtures.

**Failure modes, per Lane D.** (a) no harness → clear error, exit 1 — fine. (b) #395 → **silent wrong-but-plausible**, and the override branch also suppresses the staleness warning, so #394 and #395 share a root cause: the override bypasses every vendored-aware branch. (c) stale vendor → warning only, remedy not runnable. (d) #358 pre-fix → hard crash naming the path, not the cause.

**Rollback.** No per-resolution kill switch exists. `XYZ_PYTHON=0` reverts the whole lane to FROZEN Bash, which does not help. The repo's kill-switch idiom to copy: `validate.sh:41-52` `XYZ_ALLOW_WORKTREE_GATE=1` — **announced on stderr, never silent**.

**Observability.** No runtime line records which root was resolved. Nearest: `swarm_preflight.py:1105-1107` writes `harness_root`/`harness_home`/`target_root` into the invocation contract — one dispatch path only.

## Unknowns

| Unknown | Why it matters | What would settle it |
|---|---|---|
| Exact assertions in ~19 root/vendored-named tests not read by content (`gh129`, `gh131`, `gh256`, `gh292`, `gh293`, `gh304`, `gh343`, `gh369`, `gh417`, `archive-root`, `marathon-root-audit`, `relay-target-root*`, `shim-worktree`) | One of them may pin a precedence the helper changes | `rg -n 'XYZ_HARNESS\|TICK_REPO_ROOT\|CALLER_ROOT' test/gh129-relay-tick-root.sh test/gh131-marathon-target-root.sh test/gh292-worktree-vendored-discovery.sh test/gh293-vendored-guard-drift.sh test/gh304-vendored-relay-path.sh test/gh417-turn-root-symlink-prefix.sh test/marathon-root-audit.sh test/relay-target-root*.sh` |
| `xyz-sync.sh`'s actual CLI grammar for `update` | #394's remedy line must print something runnable; guessing the grammar reproduces the bug | `sed -n '1,60p' relay-automation/xyz-sync.sh` (usage block) |
| Whether `rtl.py:526`'s `driver_lock_path` agrees with `driver-lock-lib.sh:20-35` | The "no `.git` means vendored" proxy lives in both | `sed -n '500,560p' utils/py/rtl.py` |
| Whether `~/.claude/skills/.marathon-triage.pre-repo-20260718/` carries a stale copy of the Step-0 snippet | A shared helper fixes the repo's copy and leaves a stale global one | `rg -n 'XYZ_HARNESS\|swarm-preflight' ~/.claude/skills/.marathon-triage.pre-repo-20260718/` |
| `resolve-profile.sh:25`'s own root resolution under a vendored tree | It is the "one-line shortcut" #394 names | `sed -n '20,30p' relay-automation/resolve-profile.sh` |
| Full `MARATHON_*` namespace | A greedy prefix scrub could hit one | `rg -on 'MARATHON_[A-Z0-9_]+' relay-automation utils bin \| sort -u` |

Six unknowns on a ~290-site subject is the honest count — none of them changes the shape of the plan; two (`xyz-sync` grammar, unread tests) must be settled inside Phase 0 before its tests are written.

## Current-state radius, one line

Every shell that `eval`s `find-harness.sh --env` (operators, all relay/consult/hq/file-xyz-bug/marathon-triage/10days skill sessions, 8 script callers), the 5 Python turn shims via `rtl.resolve_turn_root`, `wave_reconcile`/`jog_run`/`marathon_plan`/`swarm_preflight`/`marathon_drive` via four ad-hoc `harness_home` derivations, `bin/tick`'s event-log location, and the three consumer repos (`rebalanceOS` ×5, `LTVera-Pandas` ×4, `aegis-sleuth-slack-bot` ×3) that run all of the above from a `.xyz/` copy stamped by `xyz-vendor.sh` and audited by two disagreeing staleness checks.
