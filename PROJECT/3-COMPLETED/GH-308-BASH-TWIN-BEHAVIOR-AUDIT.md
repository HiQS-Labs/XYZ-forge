---
gh_issue: 308
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/308
title: "GH-308 Bash-twin behavior audit — behavior present only in Bash (dead on the default Python lane), classified and ported"
status: "Audit complete: all 11 pairs swept + runtime-proven. 16 divergences ported into utils/py/ (incl. #331 cost summary + #289 build-turn guard); 1 opt-in feature (XYZ_DEBUG_LOG) explicitly DEFERRED with rationale. 6 tests drive the default lane. Pending review + merge."
created: 2026-07-29
updated: 2026-07-29
owner: noel
doc_type: audit
complexity: 4
risk: 3
effort: 4
ratings_provisional: true
related:
  - "#322 — --log-github was Bash-only (ported PR #326); the accident that motivated this sweep"
  - "#331 — end-of-run cost summary is Bash-only (ported here)"
  - "#289 — --target-root build-turn guard is Bash-only (ported here)"
  - "#324 — the Python lane now rejects unknown flags (parse_known_args + explicit reject)"
  - "#320 — twin timeout-default drift (the constant-drift class)"
non_goals:
  - Editing the frozen Bash twins. GH-308 froze them; every fix goes in utils/py/. No Frozen-twin-exception is spent here.
  - "Fixing cosmetic divergences (help-text length, message wording): the Bash twins are allowed to drift; only behavior a user can invoke or observe that is present in Bash and ABSENT in Python is a defect."
  - Re-designing any twin. Ports mirror the Bash behavior byte-for-byte where a caller/test depends on it.
goal: >
  Answer the open question from #322/#331/#289 — "are those three the only Bash-only behaviors, or is
  there a whole class?" — by sweeping all 11 frozen twin pairs across six behavior surfaces, proving
  each real divergence at runtime on both lanes, classifying every finding, and porting every Inert
  feature and Missing guard into the Python twin that actually runs (XYZ_PYTHON unset since GH-264).
---

# GH-308 · Bash-twin behavior audit + port

## Status
| What was just completed | What's next |
|---|---|
| Swept all 11 twin pairs across the 6 behavior surfaces; runtime-proved every real divergence on both lanes (`XYZ_PYTHON=0` vs unset). Ported 16 findings into `utils/py/` incl. the two mandated (#331 cost summary → `relay_drive.py` + `marathon_drive.py`; #289 build-turn guard → `relay_drive.py`). Un-pinned `gh289` to drive both lanes; added 5 new default-lane tests, all registered in `validate.sh`. | Operator review + merge into `development`. Decide on the one DEFERRED finding (`XYZ_DEBUG_LOG` Sentinel capture → `marathon_drive.py`). Recommend closing #331 and #289 on merge (findings commented on both). |

## Why this exists

Every `.sh` entry point `exec`s its Python twin near the top when `XYZ_PYTHON` is unset — the default
lane since GH-264. So **behavior implemented only in Bash is dead code on the lane that actually
runs**: it ships, passes review, closes its issue, and never executes. Three instances were found by
accident (#322 `--log-github`, #331 cost summary, #289 build-turn guard). This audit answers whether
those were the only ones. **They were not** — the sweep found a class of them.

## Method

Per pair, compared six **behavior surfaces** one at a time (a naive string diff produces ~194 noise
hits): (1) CLI flags, (2) env vars read, (3) exit codes + triggers, (4) user-facing `tool:` diagnostics,
(5) guards/refusals, (6) side effects. Every suspected real divergence was proven at runtime — same
invocation under `XYZ_PYTHON=0` (Bash) and unset (Python), both exit codes + both outputs recorded —
before being called real. A grep is a lead, not a finding.

**Defect definition (narrow):** divergence is not automatically a defect — the frozen twins are
allowed to drift. The defect is *behavior a user can invoke or observe that is present in Bash and
absent in Python*, because that silently does nothing on the default lane.

## Classified inventory (all 11 pairs)

Legend: **PORT** = Inert feature / Missing guard, fixed in `utils/py/`. **DEFER** = real but
deliberately not landed in this PR (rationale given). **REC** = recorded, no action (cosmetic /
Python-only / already-aligned drift).

### relay-drive.sh ↔ relay_drive.py — 2 PORT

| # | Class | Finding | Action |
|---|---|---|---|
| 1 | Missing guard | **#289** `--target-root` build-turn guard: a relay file resolving OUTSIDE the target root means a build/review turn has no writable path and is discarded after full cost. Bash refuses (`exit 2`, exact diagnostic); Python had no guard → proceeded to `rc=4`. | **PORT** — byte-identical `exit 2` diagnostic (build/review kind), fires before the lane-attempt gate, for build turns AND `--review-once`. Proven: both lanes now emit the identical refusal; no false positive when relay is in-root. |
| 2 | Inert feature | **#331** end-of-run `tick analyze` cost summary (`RELAY_COST_SUMMARY` opt-out, GH-152). Bash-only → `grep -c analyze`: `.sh` 9, `.py` **0**. | **PORT** — wired into the same atexit as the lock cleanup; only fires once a turn was actually driven; `RELAY_COST_SUMMARY=0` opts out; a failed/forced `tick analyze` degrades and can never change the run's exit code (atexit never alters it). |

### marathon-drive.sh ↔ marathon_drive.py — 1 PORT, 1 DEFER

| # | Class | Finding | Action |
|---|---|---|---|
| 3 | Inert feature | **#331** end-of-run cost summary (`MARATHON_COST_SUMMARY`, GH-222). Worse than relay-drive: marathon tells its nested relay-drive child `RELAY_COST_SUMMARY=0`, so with the parent's own summary absent a driven phase had **zero** cost visibility. | **PORT** — mirrors relay-drive; fires at marathon's own exit (`drive_started`), `MARATHON_COST_SUMMARY=0` opts out, exit code preserved. |
| 4 | Inert feature | **`XYZ_DEBUG_LOG` Sentinel Tier-1 debug capture (GH-281)** — when `XYZ_DEBUG_LOG=1` (opt-in, default OFF) Bash appends PDDA-contract JSONL findings at three sites (stale-lock reclaim, `escalate()`, lane-park) and invokes `harvest-findings.sh` in `escalate()` + `save_transcript()`. Python has zero references. Runtime-proven: `XYZ_DEBUG_LOG=1` at the park cap writes `debug.log` in Bash, nothing in Python. | **DEFER** (see "Deferred" below). Genuine but default-OFF, multi-site, and pulls in `harvest-findings.sh` spawning — the heaviest and lowest-urgency finding. Kept out to keep this PR reviewable. |
| — | REC | Python-only extra `--target-root` guard (`die("--target-root has no validate.sh…")`); abbreviated `--help` text. | REC — Python-only / cosmetic. |

### poll.sh ↔ poll.py — 7 PORT, 1 REC-drift-aligned

| # | Class | Finding | Action |
|---|---|---|---|
| 5 | Missing guard | **GH-92 residue WARNING**: a `nudge-cross-model` whose parsed NEXT value isn't a clean id (markdown residue `relay_field` couldn't strip) must warn LOUD — this exact silent gap stalled a live relay ~90 min. Bash-only. | **PORT** — identical warning on both lanes (proven with `NEXT: claude*reb`). |
| 6 | Missing guard | `--watchdog-cmd` had no default in Python (`""`), so a `run-watchdog` decision ran `run_cmd("")` — dispatched **nothing**; the escalation path was dead. | **PORT** — default to `<root>/relay-automation/watchdog.sh` (mirrors Bash); proven to dispatch. |
| 7 | Missing guard | Invalid `--mode` not validated (fell through to the xyz branch and idled). | **PORT** — `--mode xyz|relay is required` (`exit 2`), byte-identical to Bash. |
| 8 | Missing guard | `--turn-source` value not whitelisted (any non-`file` silently treated as `tick`). | **PORT** — `--turn-source must be tick|file` (`exit 2`). |
| 9 | Missing guard | `--turn-source file` requiring `--mode relay` not enforced. | **PORT** — `--turn-source file requires --mode relay` (`exit 2`). |
| 10 | Missing guard | Stray positional args silently skipped (`else: i+=1`); Bash `die "unknown argument"`. | **PORT** — any unrecognized token → `poll: unknown argument: X` (`exit 2`), matching Bash. |
| 11 | Inert feature | `--help` unavailable (Python rejected it as an unknown flag). | **PORT** — full usage text, byte-identical to `poll.sh --help`. |
| 12 | Constant drift | Default git-root for the scope-clean check: Bash `${POLL_GIT_ROOT:-$ROOT_DIR}` (repo root); Python `POLL_GIT_ROOT` else `GIT_ROOT` env else `"."` (cwd). | **ALIGN** — default to the repo root (`xyz_root`), drop the Bash-absent `GIT_ROOT` env fallback. |
| — | REC | Python-only `--run`/`RUN_CMD`; Python reads many flag-values from env as defaults (`AGENT`/`MODE`/`TASK`/…); unknown-flag wording. | REC — Python-only / cosmetic. |

### consult.sh ↔ consult.py — 2 PORT

| # | Class | Finding | Action |
|---|---|---|---|
| 13 | Missing guard | **agy isolation-breach detector (GH-178 B1)**: after a successful agy run, Bash scans the transcript (filtering the `[trace]`, `TICK_REPO_ROOT=`, `file:`-scheme, and markdown-link false-positive shapes) for the real repo root; a hit means grounding escaped the throwaway worktree → advisor FAILED (`return 5`). Python checked only `returncode == 0` → a breached run counted as a clean answer. | **PORT** — breach detector + FAIL stamp; a breached-only consult now exits 5. No false positive on a clean run. |
| 14 | Inert feature | **codex ATTESTATION header**: Bash prepends `> **ATTESTATION** / Model / Provider / Sandbox` (parsed from codex output) to the transcript. Python wrote the raw output only. | **PORT** — attestation prepended to every codex transcript on the default lane. |
| — | REC | `--help` reduced to one line (Bash prints full env-knob docs); a value-taking flag as the last arg exits `1` silently in Bash (`set -e` `shift` abort) vs `2`+message in Python; advisor-failure wording. | REC — cosmetic; Python's last-arg behavior is the friendlier one. Env vars, all usage guards, not-a-git-repo (3), all-advisors-failed (5), citation/provenance classifiers: at parity. |

### swarm-preflight.sh ↔ swarm_preflight.py — 1 PORT

| # | Class | Finding | Action |
|---|---|---|---|
| 15 | Missing guard | **Gate-runnable PATH check exempts node/npm/python3**: Bash requires any non-`bash`/`sh` gate program to resolve on PATH (`command -v`) or forces NOT-READY (`exit 5`). Python guarded the check with `if g0 != "bash" and g0 != "node" and g0 != "npm" and g0 != "python3"`, so a contract whose gate runner (`npm test`) is NOT installed was emitted **marathon-ready** (`exit 0`) instead of refused. | **PORT** — remove the exemption; `elif not shutil.which(g0)` mirrors the Bash structure. Proven with a curated PATH that hides `npm` but keeps `python3`. |
| — | REC | `ready_next` / lane-note / self-verify wording; `--help` one-liner. | REC — cosmetic; verdict + exit-code mapping at parity. |

### claude-turn.sh ↔ claude-turn.py — 1 PORT

| # | Class | Finding | Action |
|---|---|---|---|
| 16 | Inert feature | **GH-68 cross-agent dependency-drift brief**: Bash prepends any UNREAD peer drift notice to the turn brief. claude-turn.py was the ONLY Python turn shim missing `rtl.drift_brief` (codex/pi/agy/aider all call it), so the Claude builder silently lost the "a peer changed a shared surface" heads-up. | **PORT** — prepend `rtl.drift_brief`; proven end-to-end on the default lane (a peer `tick drift` now appears in the turn prompt). |

### pi-turn.sh ↔ pi-turn.py — 1 PORT

| # | Class | Finding | Action |
|---|---|---|---|
| 17 | Inert feature (containment-adjacent) | ROOT rooted at `xyz_root` (the shim's own dir) instead of the CWD's git toplevel when `PI_TURN_ROOT` unset — the GH-296 bug `resolve_turn_root` fixes. codex/claude adopted it; pi was missed. pi has NO native sandbox — its containment relies entirely on worktree isolation, so mis-rooting the worktree undermines the only containment layer on a non-vendored run. | **PORT** — `resolve_turn_root(os.environ.get("PI_TURN_ROOT"), xyz_root)`. |

### aider-turn.sh ↔ aider-turn.py — 1 PORT

| # | Class | Finding | Action |
|---|---|---|---|
| 18 | Inert feature | Same ROOT-default divergence as pi: `os.environ.get("AIDER_TURN_ROOT", xyz_root)` instead of the CWD git-toplevel fallback. Affects worktree-isolation target, artifact copy-back, and claim/relay-file relative resolution on a non-vendored run. | **PORT** — `resolve_turn_root(os.environ.get("AIDER_TURN_ROOT"), xyz_root)`. |

### agy-turn.sh ↔ agy-turn.py — 1 PORT

| # | Class | Finding | Action |
|---|---|---|---|
| 19 | Inert feature | Bash exports `TICK_REPO_ROOT=$ROOT` unconditionally, so the agy child (which runs `tick` mid-turn) always inherits it. Python only set `run_env["TICK_REPO_ROOT"]` inside the worktree-isolation branch, so on the default non-worktree lane a cross-repo run left agy's `tick` resolving against its CWD. | **PORT** — set `run_env["TICK_REPO_ROOT"] = tick_repo_root` unconditionally before the worktree branch. |
| — | REC | `RTL_LOG` export (only affects `RTL_TRACE=1` debug routing — no default-lane observable diff); `RELAY_TURN_TIMEOUT_S` default is already aligned at 900 (prior #320-class drift, closed). | REC — debug-only / already-aligned. |

### codex-turn.sh ↔ codex-turn.py — CLEAN

Full parity across all six surfaces (root resolution, drift brief, `OPENAI_API_KEY` billing guard,
`.tick` sandbox grant, `CODEX_FLAGS`/timeout defaults). No action.

### relay-loop.sh ↔ relay_loop.py — REC only

Faithful wrapper; all substantive Bash-only behavior lives in `poll`, not the loop. Two cosmetic
divergences: `poll`'s stderr is merged onto stdout in Bash vs kept on stderr in Python; a `--max-ticks`
with no value exits `1` silently in Bash vs forwards to poll (`exit 2`) in Python. REC.

## Deferred (real, not landed in this PR)

**`XYZ_DEBUG_LOG` Sentinel Tier-1 debug capture → `marathon_drive.py` (finding #4).** Deferred, not
dropped. Rationale: it is opt-in (`XYZ_DEBUG_LOG=1`, default OFF), spans three emit sites plus
`harvest-findings.sh` subprocess spawning in `escalate()`/`save_transcript()`, and is the single
heaviest and lowest-urgency finding in the sweep. Landing it here would materially enlarge an already
large multi-file PR for a knob nobody has on by default. It is fully specified above and can be its own
small follow-up. **This is the only Inert-feature finding not ported;** everything else that a user can
invoke or observe on the default lane is fixed.

## Ports → files

`utils/py/`: `relay_drive.py` (#289 guard, #331 summary), `marathon_drive.py` (#331 summary),
`poll.py` (7 guards + drift-align), `consult.py` (agy breach + codex attestation),
`swarm_preflight.py` (gate-PATH), `claude-turn.py` (drift brief), `pi-turn.py` + `aider-turn.py`
(root resolver), `agy-turn.py` (TICK_REPO_ROOT propagation).

## Tests (all drive the DEFAULT lane; each observed FAILING against pre-change code first)

| Test | Covers | Before → after (default-lane fails) |
|---|---|---|
| `test/gh289-target-root-build-turn.sh` (un-pinned) | #289 build-turn guard, both lanes | 3 → 0 |
| `test/gh331-cost-summary.sh` (new) | #331 relay + marathon summary, opt-out, exit-code invariance | 4 → 0 |
| `test/gh308-poll-guards.sh` (new) | poll #5–#11 guards | 7 → 0 |
| `test/gh308-swarm-gate-path.sh` (new) | swarm gate-PATH #15 | 2 → 0 |
| `test/gh308-consult-guards.sh` (new) | consult #13 breach + #14 attestation | 3 → 0 |
| `test/gh308-turn-shim-parity.sh` (new) | claude drift #16 (runtime) + root/#19 parity (structural; runtime-proven in audit) | 4 → 0 |

All five new tests are registered in `validate.sh`'s `TESTS=()` array (it does not glob `test/`).

## Verification gates

- `./validate.sh` → exit 0, 0 FAIL lines.
- `bash utils/pdda/pdda.sh run` → 0 errors.
- `bash test/gh308-frozen-twin-guard.sh --check --staged` → `no frozen Bash twin changed` (every fix
  is in `utils/py/`; no `.sh` twin edited, no `Frozen-twin-exception` spent).

## Recommend

Close **#331** and **#289** on merge (findings commented on both issues; ports + default-lane tests
included). File a small follow-up for the deferred `XYZ_DEBUG_LOG` capture. The operator decides
closure — this doc does not close anything.
