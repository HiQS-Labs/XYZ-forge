---
title: Marathon Plan K (2026-07-19) — ddb6c40 shim-root regression + 10-day sweep backlog
status: "RETIRED 2026-08-03 to 4-MISC — never fired; 16 of 17 lanes are now CLOSED (223 234 241 236 245 218 247 250 224 232 249 225 242 199 248 294). Only #191 remains OPEN, which this doc itself files as deferred backlog. Wave 1's construct survives in utils/py/rtl.py:resolve_turn_root and is carried forward as issue #417 — the GH-171/GH-172 failures cited here are no longer among development's failures, but nothing recorded why. Kept for the triage record only."
created: 2026-07-19
updated: 2026-08-03
owner: noel
branch: development
doc_type: project
source: /10days sweep (window 10 days, 27 open issues) + two live validate.sh failures on development
generated_by: /10days Steps 1-6 (auto-fire deliberately withheld — see "Why this was not fired")
lanes: [B, A, 247, 250, 223, 234, 241, 236, 245, 218, 224, 232, 249, 225, 242, 199, 191]
execution: waves — Wave 1 serialized (regression), later waves parallel on disjoint write-sets
roadmap_exempt: true
goal: >
  Close a verified regression introduced by ddb6c40 on `development` — all four turn shims now
  default ROOT to `git rev-parse --show-toplevel`, the exact construct relay-turn-lib.sh warns
  against in a "caught live" comment — then work the surviving backlog from a 10-day issue sweep.
  The regression is Wave 1 and blocks the package regen behind it; shipping the regen first would
  bake the defect into the consumer tarball.
---

# Marathon Plan K — 2026-07-19 · post-ddb6c40 regression + 10-day sweep

> Built by `/10days` Steps 1–6. **Auto-fire was withheld** — see below. The headline is not a
> backlog item: `development` currently carries a regression that two tests already catch.

## Status

| What was just completed | What's next |
|---|---|
| **Triaged 2026-07-19.** Swept 27 open issues in the 10-day window. 12 excluded with commit/PR evidence (8 of them look closeable outright). 15 survive as lanes, plus 2 previously-unfiled defects found by investigating the live `validate.sh` failures. Root-caused `test/marathon-drive.sh`'s GH-171 failure to commit `ddb6c40` and verified the mechanism end to end. | Operator decision on Wave 1 (see "Why this was not fired"). Then fire waves in order; Wave 1 must land and go green before Wave 2 regenerates the package. |

## Why this was not fired

`/10days` is authorized to auto-fire. Three preconditions in its own Step 7 do not hold, so it stopped:

1. **Wave 1 is a regression in someone else's merged commit, not a queued backlog item.** The skill's mandate covers firing triaged intake, not silently rewriting a teammate's just-landed fix. This needs an operator call on approach (fix-forward vs revert).
2. **The skill's Step 7 gate is `git rev-list --count HEAD..origin/main` must be 0.** `main` is 49 commits behind `development`; the check is written against a `main`-based workflow this repo no longer uses (GH-216). The gate as written cannot pass, and forcing past it would defeat its purpose.
3. **`validate.sh` is currently red on `development`** (113/116). Firing a marathon onto a red baseline makes every downstream lane's gate result ambiguous.

## Wave 1 — the regression (serialized, blocks Wave 2)

### Lane B — turn shims reintroduce the GH-160 physical-path mismatch  🔴 **verified**

**Commit `ddb6c40`** changed all four shims' default root:

```diff
-ROOT="${CODEX_TURN_ROOT:-"$(cd "$HERE/.." && pwd)"}"
+ROOT="${CODEX_TURN_ROOT:-"$(git rev-parse --show-toplevel 2>/dev/null || (cd "$HERE/.." && pwd))"}"
```

`relay-turn-lib.sh:225-231` warns against precisely this, in the repo's own words:

> STRING-based, not `rev-parse --show-toplevel` (physical path, e.g. /private/var) … correcting to
> the physical toplevel would just move the mismatch … **(caught live: an early version of this fix
> did exactly that)**

**Mechanism, verified link by link:**

| Link | Evidence |
|---|---|
| The warning exists and names this construct | `relay-turn-lib.sh:225-231`, read verbatim |
| `ddb6c40` introduces that construct in all 4 shims | `git show ddb6c40` — `agy:78`, `codex:60`, `claude:74`, `aider:87` |
| Fixtures run under a symlinked TMPDIR | `$TMPDIR` on this host resolves through a symlink to a different physical prefix (confirmed via `realpath`) |
| Caller builds paths in the symlink string form; shim ROOT now resolves to the physical form | prefix strip in `rtl_in_allow` / `agy-turn.sh:167` cannot match |
| GH-160's collapse can't rescue it | `--show-prefix` is empty when ROOT is already a toplevel, so `relay-turn-lib.sh:233-236` never fires |
| Symptom is a containment violation, not a missing target | `marathon-drive.sh:45` — exit 6 = "turn-taker reverted an off-lane edit"; observed failure is exactly `expected 4, got 6` |

**Why it passed the author's manual check:** a repo in a normal home-directory checkout has no symlinked prefix, so the mismatch is invisible outside `$TMPDIR`-rooted fixtures.

- **Fails now:** `test/marathon-drive.sh:615` (GH-171) and `:648` (GH-172, `XYZ_PYTHON=1`) — same cause.
- **Fix shape:** derive ROOT string-wise from `$PWD` mirroring GH-160 (strip `--show-prefix` off `$PWD`), preserving the caller's symlink form — rather than taking `--show-toplevel`.
- **Parity note:** `utils/py/*-turn.py` were **not** touched by `ddb6c40` and still carry the old `$HERE/..` default. Either the Python layer is now divergent, or it never had the bug — resolve before porting.
- **Artifacts:** `relay-automation/{codex,agy,claude,aider}-turn.sh`, `utils/py/*-turn.py`, `test/marathon-drive.sh`
- **Open question for the operator:** ddb6c40's *stated goal* (root at the target for non-vendored cross-repo runs, GH-248) is legitimate and its issue is real. Fix-forward preserves that intent; a revert restores green but reopens #248. **Recommend fix-forward.**

## Wave 2 — unblocked by Wave 1

### Lane A — `relay-pkg.tar.gz` stale  ⚠️ **must not run before Lane B**

Packaged `codex-turn.sh` + `agy-turn.sh` drift from source (14/16 packaged paths identical, exactly those 2 differ) because `ddb6c40` skipped the regen. Fix is one command — `skills/relay-automation/make-pkg.sh` — but **regenerating before Lane B ships the regression to every consumer.**

- **Fails now:** `test/relay-pkg-freshness.sh` · **Artifacts:** `skills/relay-automation/relay-pkg.tar.gz` · No issue filed yet.

## Wave 3 — parallel, disjoint write-sets

| Lane | Issue | Why it survives triage | Artifacts |
|---|---|---|---|
| 223 | consult.py A4 parity | `consult.sh` has citation stamping; `utils/py/consult.py` has zero matches. Direct port, no design work | `utils/py/consult.py`, `utils/py/rtl.py`, `test/consult.sh` |
| 234 | `find-harness.sh --env` roots one dir too deep | `skills/relay-xyz/find-harness.sh:178` unchanged; all 6 vendored copies re-vendored from it | `skills/relay-xyz/find-harness.sh`, `test/xyz-vendor.sh` |
| 241 | `marathon-yaml` list-form guard | Docs fixes (1)(2)(4) shipped in `353d4c0`; fix (3) explicitly deferred and still open | `bin/marathon-yaml`, `test/marathon-yaml.sh` |
| 236 | worktree isolation under `$TMPDIR` | `relay-turn-lib.sh:433` `mktemp -d` unchanged; no commit references it | `relay-automation/relay-turn-lib.sh`, `test/path-integrity.sh` |
| 245 | `--target-root` review turn unwritable | `relay-drive.sh:507-524` still classifies on token state alone | `relay-automation/relay-drive.sh`, `test/relay-drive.sh` |
| 218 | cross-repo marathon status | PR #220 shipped docs only; `utils/hq/marathon-live.sh` does not exist | `utils/hq/marathon-live.sh`, `utils/hq/rollup.sh` |

**⚠️ 247 + 250 share one lane** — both edit `skills/marathon-triage/SKILL.md`. Never concurrent.

| Lane | Issue | Why it survives triage | Artifacts |
|---|---|---|---|
| 247+250 | vendored `utils/` paths + default recommendation | Skill is still **untracked**; both changes unimplemented | `skills/marathon-triage/SKILL.md` |

## Wave 4 — larger / lower urgency

| Lane | Issue | Note |
|---|---|---|
| 224 | PDDA drift reconcile | Partially chipped (`4b32bd3`); 15 ROADMAP mismatches outstanding. Per-item, not a bulk edit |
| 232 | 12 ubuntu-latest CI failures | CI still narrowed to acorn-extract. **Now higher value** — CI runs on `development` as of `9f320ec` |
| 249 | gate enforces existing tests, not new-test presence | Design gap; expect conflict window with #238 follow-ups (same gate surface) |
| 225 | worktree stale-base guardrail | Doc-only, targets `skills/10days/SKILL.md` — the very skill that built this plan |
| 242 | agy S10 repro | Repro spike; genuine risk no deterministic trigger exists |
| 199 | swe-diagram font picker | **Work already exists** on unmerged remote branch `gh-199-swe-diagram-font-picker` (`322ecbe`). Likely a merge, not a build |
| 191 | ATE generalize beyond Aider | Confirmed unfixed; owner marked deferred backlog |

## Excluded — with evidence

| Issue | Reason | Evidence |
|---|---|---|
| 201 | Already landed | merged PR #244, commit `6df5bfc` |
| 211 | Already landed, issue just un-closed | commit `91f2fda`; ROADMAP:88 says SHIPPED |
| 216 | Retire+recut already happened | `development-archived-2026-07-04` = `bf6950c1`; fresh `development`; commit `788a5c6` |
| 235 | v0 shipped, awaiting bookkeeping | commits `bfbd357`, `6158eed`, `e1a7b61` |
| 238 | All 3 DoD items landed | commits `d999c36`, `54e8bf2`; merged PR #243 |
| 239 | Both in-scope fixes shipped | `relay-automation/CONTRACT.example.md` exists; `swarm-preflight.sh:531` points at it |
| 248 | Primary defect closed by `ddb6c40` | all 4 shims changed — but see Lane B for the cost, and 2 named follow-ups remain unimplemented |
| 170 | No longer reproducible | capture doc marks STALE; all 9 tests pass; preflight exit 4 |
| 123 | Not a work item | beta-tester onboarding protocol, no acceptance criteria |
| 202 | Discussion dump, overlaps #204 | no capture doc, no repro |
| 204 | Exploratory, ends in 4 open design questions | no acceptance criteria |
| 226 | Not a work item | DoD is "decide and record", non-goals exclude implementing |

**Propose closing:** 170, 201, 211, 216, 235, 238, 239 — each has commit/PR evidence the ask is met. (#248 closes once Lane B resolves its fallout.)

## Contracts owed

No lane here carries a `/10days`-auto-drafted contract — **auto-drafting was skipped deliberately.** Lanes 191, 199, 225, 232, 234, 236, 241, 242, 245, 247, and B have `needs_contract: true` and no verified contract. Per the skill's own guardrail, an unverified `artifacts` list makes the wave/collision map untrustworthy; the wave grouping above is derived from subagent-identified touch surfaces and is **an ordering proposal, not a safety guarantee.** Author and verify contracts before firing any wave concurrently.

## Method

`/10days` Steps 1–6, sandbox off for `gh`/`git fetch`. Step 1 `scan-issues.sh 10 0` → 27 open issues. Step 2 `find-doc.sh` per issue. Step 3 five parallel read-only subagents, receipts required (commit sha / merged PR / `3-COMPLETED` doc); no subagent executed a project script. Steps 4–5 (contract authoring, `marathon-plan.sh --deep`) deliberately not run — see "Contracts owed". Step 6 preflight not run: it writes real packets, which is a fire-path action.
