# GH-280 Phase 5 — Legacy Relay Executor Audit (FINDINGS)

**Lane:** `docs/gh280-phase5-legacy-audit` off `development` @ `fa85a955` (2026-08-29)
**Scope:** Phase 5 items 3–4 — the map for removing the duplicated Jog execution code after the
default flip. Analysis-only PR: no production code changed. All mutation probes ran in a
disposable full clone at `/tmp/gh280-p5-fixture`; this lane clone never executed a suite.

## Verdict

At `fa85a955` the legacy relay executor is exactly **three functions + one dispatch arm + one CLI
choice**, and **none of it is dead at flip time** — the class-A set is empty. `--executor relay`
keeps the whole body alive for the window, and `--simulate` keeps a skeleton of it alive *past*
the window unless the removal commit acts. The single riskiest item is that **`--simulate` is
welded to the legacy skeleton**: `jog_run.py:1600`'s `executor == "marathon" and not simulate`
routes every simulate run — under EITHER default — through `run_single_phase_drive` and
`handle_landing_boundary`. Delete the legacy body without deciding simulate semantics and the
hermetic queue test (`jog-queue.sh` §15) and adapter §I die with it (proven by probe, below).

Two incidental defects surfaced for the flip lane (not this lane to fix):
1. **`--dry-run` is not exempt from marathon validation** (`jog_run.py:1486`) — a minimal flip
   breaks `jog-queue.sh` §12 (probe-confirmed, rc=2 refusing a reviewer for a zero-mutation run).
2. **No committed test asserts the executor default.** Adapter §I is named "legacy relay default
   unchanged" but asserts only simulate-path strings; it passes 167/167 with the default flipped.

## 1. Reachability map

Classes: **A** dead immediately post-flip · **B** alive only during the window (dies at removal) ·
**C** shared (must survive removal). Source of truth: `evidence/callgraph-reachability.txt`
(AST walk, `evidence/reachability_walk.py`) cross-checked by grep census
(`evidence/grep-census.txt`) and runtime traces (`evidence/trace-evidence.txt`).

### Class A — dead immediately post-flip: 0 functions

Nothing mechanical dies at flip. The flip-retired surface is non-code: the `default="relay"`
literals + help strings (`jog_run.py:1472-1475`, `releases_app.py:4748-4750`), the
`getattr(args, "executor", "relay")` fallback (`jog_run.py:1481`), and adapter §I's *intent*
(not its assertions — see §4). The flip PR owns those; the removal commit is a separate, later,
purely subtractive change — exactly why the plan demands two commits.

### Class B — alive only during the window: 3 functions + 1 arm + 1 CLI choice (dies at removal)

| Item | Location | Reaches it during the window | Post-window fate |
|---|---|---|---|
| `run_single_phase_drive` — real body (relay-drive discovery, relay-file scaffold, tick claim/release, shim env contract, dispatch, STATUS-done salvage) | `jog_run.py:1267-1378`; called only from `jog_run.py:1639` | `--executor relay` (non-simulate) only | delete |
| `run_single_phase_drive` — simulate arm (`:1269-1271`) | same | `--simulate` under EITHER default (the `and not simulate` at `:1600`) | delete WITH simulate decision |
| `_verify_legacy_pr_before_merge` | `jog_run.py:1381-1395`; called only from `:1415`, `:1449` | `--executor relay` + `--auto-merge` (or tty confirm) | delete |
| `handle_landing_boundary` — all arms (auto-merge `:1404-1428`, unattended park `:1430-1432`, tty confirm `:1434-1459`) | `jog_run.py:1398-1459`; called only from `:1653` | `--executor relay` (all arms) **and `--simulate`** (auto-merge + unattended arms; trace-proven lines 1404-1428) | delete WITH simulate decision |
| Legacy arm of `jog_run_main`: preflight invocation `:1617-1636`, drive call `:1638-1650`, landing call `:1652-1654` | `jog_run.py:1616-1660` | as above | delete |
| `--executor` `"relay"` choice + help | `jog_run.py:1472-1475`, `releases_app.py:4748-4750` | explicit `--executor relay` | drop the choice, keep `--executor` (or drop both) |

Notes:
- `run_single_phase_drive`'s dispatch half (`:1300-1378`) executed in **zero** traced
  configurations and is referenced by **zero** committed tests — it is live-only code with no
  test coverage, so deleting it destroys no coverage (trace + grep evidence).
- `jog_reconcile_cold_start` (`:440-487`) is the only function whose reachability **grows** at
  flip (it is marathon-arm-only, `:1544-1547`): pre-flip default never reaches it; post-flip
  default does.
- The legacy failure path exits 0 (`jog_run_main` breaks on drive failure without a nonzero
  exit — observed in the relayreal trace). Pre-existing quirk; dies with the arm, so no action.

### Class C — shared, must survive removal: 36 functions (jog_run.py) + the releases_app jog surface

- **Queue/lease/landing policy stays in Jog** (plan item 3): `jog_run_main` skeleton (lock,
  dry-run, loop, lease, promotion) `:1462-1660` minus the legacy arm; `JogSupervisorLock`
  `:1050-1115`; `find_issue_doc`/`extract_probes_from_doc`/`lint_probe`/
  `promote_contract_to_working` `:1118-1264` (intake/promotion — `find_issue_doc` is ALSO a
  legacy-body callee at `:1351`, but its other caller `:1584` is the shared loop).
- **All marathon machinery**: contracts (`:57-145`), state ledger (`:200-360`), projection
  (`:363-437`), cold start (`:440-487`), dispatch (`:490-619`), resume/retry-gate/retry-build
  (`:655-858`), `_gh_pr_view` (`:861-871` — shared: marathon verify + jog_land, AND the legacy
  verifier), `jog_land` (`:874-1047`).
- **releases_app.py**: `cmd_jog_run` `:3716-3723` (dispatch only), verb dispatchers
  `:3725-3756`, queue layer `jog_acquire_lease`/`jog_set_status`/`jog_reconcile_orphan_leases`
  `:3623-3714`, all `cmd_jog_*` CRUD `:3331-3612`, `_ensure_jog_schema`/migration 006
  `:861-880`. The executor surface in this file is exactly the argparse block `:4747-4753` —
  nothing else reads `args.executor`.
- **Shared infrastructure the legacy body calls** (must NOT be removed with it):
  `relay-automation/relay-drive.sh`, `relay-automation/<builder>-turn.sh` shims, `bin/tick`,
  `utils/py/swarm_preflight.py`, `utils/py/marathon_drive.py` — all serve the marathon lane and
  other relays (grep census §6: no twin invokes jog; the twins are callees, not callers).

## 2. Test inventory

| Suite / section | Class | Fate |
|---|---|---|
| `test/jog-queue.sh` §1-12, §14 (CRUD, dump/rebuild, dry-run*, orphan reconcile) | shared | survives (§12 needs the flip's dry-run exemption or `--reviewer`) |
| `test/jog-queue.sh` §13 (driver-lock refusal via `--simulate`) | shared | survives removal — the lock is acquired before any executor dispatch (`:1523`) |
| `test/jog-queue.sh` §15 + §16 cascade (simulate run, completed row, drop-guard) | **legacy-coupled** | dies at removal unless simulate semantics are defined; probe: 3 of the 4 post-removal failures |
| `test/gh280-jog-marathon-adapter.sh` §A-H, §J-P (contracts, receipts, marathon executor, verbs, landing, boundary guard) | shared | survives (post-removal probe: gh291 20/0, gh290 37/0 pass with the legacy body deleted) |
| `test/gh280-jog-marathon-adapter.sh` §I "legacy relay default unchanged" (I1/I1b/I2) | **legacy-exclusive** | I1/I1b die WITH the removal (simulate-coupled strings); I2 survives. **As written §I is also flip-blind** (passes 167/167 post-flip) — the flip PR must rewrite it to pin the marathon default, the removal commit then deletes it |
| `test/gh291-contract-goldens.sh`, `test/gh290-ate-variation-grid.sh` | shared | survive; import only marathon-side symbols (`load_marathon_*`, `jog_project_marathon_outcome`, `jog_land`) |

No test anywhere imports the legacy trio (grep census §1: zero test references) — the tests that
touch the legacy path do so only through the `--simulate` CLI shape.

## 3. The removal-commit manifest (post-window)

One subtractive commit, **no schema/data changes** (`jog_queue` has no executor column;
`.tick/jog/` ledgers are per-execution artifacts on disk and are not code's to touch):

1. `utils/py/jog_run.py`: delete `run_single_phase_drive`, `_verify_legacy_pr_before_merge`,
   `handle_landing_boundary`, the legacy arm (`:1616-1660`), the `"relay"` argparse choice
   (`:1472`), and `--simulate` **or** re-point simulate at the marathon arm with a no-dispatch
   short-circuit (decision required — see riskiest item). Update the module docstring (items
   5-7 describe the legacy flow) and the Phase-2 comment block (`:148-158`, "Legacy `relay`
   remains the default executor until Phase 5").
2. `utils/py/releases_app.py`: drop `"relay"` from `--executor` choices + help (`:4748-4750`);
   `--simulate` help (`:4752`) follows the simulate decision.
3. `jog_run.py:669-670`: `jog_resume`'s hint says `run releases jog run --executor marathon` —
   drop the now-redundant flag mention.
4. Tests: rewrite adapter §I out of existence (keep I2's no-state assertion if desired);
   rewrite `jog-queue.sh` §15/§16 against whatever simulate becomes (§13 untouched). Order
   matters: `test/_setup.sh:168`'s `fail()` hard-exits, so §I1 currently aborts the whole
   adapter suite — fix §I before anything later in that file can run.
5. Docs: `skills/jog/SKILL.md` (lines 8, 57, 87 describe the relay-drive lifecycle and the
   flagless run signature); `MACHINE-CONTRACTS.md:137-138` (drop the "legacy `--executor relay`
   path is the declared exception" carve-out; optionally tighten the P tripwire — §5 below).
   CHANGELOG: add the removal entry (B-sized bet: one-way-ish for anyone scripting the flag,
   hence the window; record per PDDA).

**Trigger (state precisely):** one full release cycle after the flip PR lands and its
deprecation notice ships. The flip PR's notice must name (a) the flag (`--executor relay`),
(b) the window ("removed one release cycle after this flip"), and (c) this manifest's issue.
The removal PR cites the shipped post-flip release (releases ledger) as the window's end —
that release entry is the verifiable artifact, matching MACHINE-CONTRACTS.md's
release-cycle-bounded deprecation window.

**Rollback shape:** a single `git revert` restores the commit wholesale. Nothing else: no
schema, no queue data, no Tick state is touched (statuses in `jog_queue` are
executor-agnostic; the row history survives). Reversibility: **Easy** (one commit, no
migration, probe-verified that the surrounding suites don't depend on the deleted symbols).

## 4. What the flip PR must carry (handoff to the parallel lane)

Probe-verified at `/tmp` (see `evidence/mutation-probe-matrix.txt`):
1. Exempt `--dry-run` at `jog_run.py:1486` (`and not getattr(args, "dry_run", False)`) or the
   hermetic dry-run refuses post-flip (rc=2, jog-queue §12 red).
2. Add a default-assertion test: bare `jog run` (no `--reviewer`) must exit 2 with the
   reviewer-demand message — the cheapest detector that actually distinguishes the defaults
   (§I today does not: 167/167 green with the default flipped).
3. Rewrite adapter §I from "default unchanged" to "rollback flag still works" —
   `--executor relay --simulate ...` keeps the window honest without pretending to pin the
   default.
4. Name the window + removal trigger in help text, `skills/jog/SKILL.md`, CHANGELOG.

## 5. GH-195 discipline — what each detector does NOT match

- **Name-based AST edges**: `getattr(jog_run, fn_name)` (`releases_app.py:3731`) and the
  handlers dict (`releases_app.py:4780+`) are dynamic; covered only by the hand-audited verb
  table. A future verb added by getattr string would be invisible to the walk.
- **Subprocess reachability**: `relay-drive.sh`, `<builder>-turn.sh`, `bin/tick`, `gh`, and
  marathon-drive are argv-level — invisible to the Python AST and to `grep --include="*.py"`.
  Covered by grepping `*.sh` for the `jog run` CLI shape (zero hits outside jog_run.py /
  releases_app.py / tests). Someone invoking `python3 utils/py/jog_run.py --simulate` DIRECTLY
  (bypassing releases_app) matches no `releases jog` grep — only the argparse inside
  jog_run.py admits it.
- **Frozen Bash twins**: jog has NO twin (not in the Tier-A list; no `utils/jog*.sh`). The
  twins are *callees* of the legacy path (`run_single_phase_drive` invokes
  `relay-drive.sh` + `agy-turn.sh` etc.), never callers — verified zero `jog` references in
  `relay-automation/*.sh`. Removing the jog legacy body removes a twin *caller*, not a twin.
- **Env-var branches**: `MARATHON_INTEGRATION_BRANCH` (`jog_run.py:265`),
  `AGY_BIN`/`CODEX_BIN`/`GEMINI_BIN` (`:190-194`), `RELAY_DRIVER_LOCKED`, `XYZ_PYTHON`
  (twins-only) — none select the legacy executor; none affect the A/B/C map.
- **Live specimen — the existing P2 tripwire is evaded today**: adapter §P asserts
  `jog_run.py` never invokes the tick binary by grepping the literal `bin/tick`, but the
  legacy path builds it as `os.path.join(root, "bin", "tick")` (`jog_run.py:1325`) and calls
  it three times (`:1327-1329`) — string-splitting defeats the fixed-string grep. The pass is
  real but the *reason* it passes is luck, not compliance (the legacy exception is declared in
  MACHINE-CONTRACTS.md:137-138, yet the guard cannot see the legacy invocation it exempts).
  After removal, P2 becomes genuinely true; the removal commit may also tighten the pattern to
  `"bin", "tick"` so the exemption-by-accident cannot recur.
- **My own tooling bit me once**: the first version of `reachability_walk.py` shallow-copied
  edge sets, so the first legacy config re-added its arm to every later config — every config
  looked identical (the exact failure shape this audit exists to catch). Fixed and noted in
  the script; committed output is from the fixed version.
- **Trace rc artifact**: `python3 -m trace` reports rc=0 for a `sys.exit(2)` refusal; the
  un-traced re-run gives the true rc=2. Exit-code claims in `trace-evidence.txt` cite the
  un-traced run.
- **Config-matrix blind spot**: reachability here is decided by `executor` x `simulate` x
  `dry_run` interactions; the walk models five configs and treats `--dry-run` as
  pre-dispatch (it returns before the loop). Any FUTURE flag that gates the arms would need
  the walk's rule table updated — the table is line-number-keyed and will drift with edits.

## 6. Verification evidence (committed)

| File | What it proves |
|---|---|
| `evidence/reachability_walk.py` | the tool (AST walk, config rules, self-documented limits) |
| `evidence/callgraph-reachability.txt` | per-config reachability matrix; A=0, B=3, C=36 |
| `evidence/grep-census.txt` | raw call-site counts; legacy trio confined to jog_run.py; zero test imports; zero twin callers |
| `evidence/trace-evidence.txt` | line-level execution of the three runs; simulate couples to `handle_landing_boundary`; legacy dispatch half executes nowhere |
| `evidence/mutation-probe-matrix.txt` | baseline / minimal-flip / removal states x 4 suites; the flip-blind and dry-run findings; class-C suites green post-removal |

Probes ran in `/tmp/gh280-p5-fixture` (fresh full clone @ `fa85a955`, identity checked before
and after: `core.bare=false`, origin = the local lane clone, HEAD unchanged). This lane clone
ran no suites — `git status` shows only this evidence directory.

## 7. Bets and the riskiest item

**Bet:** the flip PR is a *minimal* default change (the three `default="relay"` sites) and does
not itself repoint `--simulate`. If it instead rebuilds simulate onto the marathon path, part of
class B (the simulate arms) moves into class A at flip time and the removal manifest shrinks —
the map above still holds for everything else.

**Single riskiest removal item: the `--simulate` coupling.** `--simulate` is the hermetic test
surface for the queue loop (jog-queue §13/§15, adapter §I) and it currently IS the legacy
skeleton. The removal commit must choose: (a) delete `--simulate` and rewrite the tests against
a marathon-shaped no-dispatch mode, or (b) keep the flag and short-circuit it before the
executor arm. Choice (a) is cleaner but rewrites three test sections; (b) preserves the test
shapes but leaves a vestigial flag. Deciding this late is what makes the removal commit risky —
it is the one deletion whose blast radius extends past the dead code into the tests that
gate every future jog change.

**What fought back:** (1) the simulate coupling itself — predicted invisible, then probe-measured;
(2) the dry-run/validation ordering break (found only because the probe re-ran jog-queue
post-flip); (3) my own walker's aliasing bug; (4) `python3 -m trace` swallowing `sys.exit(2)`.
All four are documented above with their evidence.
