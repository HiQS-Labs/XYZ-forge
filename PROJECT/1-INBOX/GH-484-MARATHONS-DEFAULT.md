---
title: "GH-484 — redefine the canonical marathon-phase directory default from phases/ to MARATHONS/"
status: 1-INBOX
created: 2026-08-09
owner: noel
doc_type: project
goal: >
  Flip the DEFAULT value of the marathon drivers' per-phase run-output directory from
  `$ROOT/phases` to `$ROOT/MARATHONS`, for every new install (vendored or not), while the
  existing `--phases-dir` / `PHASES_DIR` override keeps working exactly as it does today.
  Naming-consistency issue, not a bug fix — the harness's entire vocabulary says "marathon"
  except the one directory holding a marathon's actual run state.
---

Issue: [#484](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/484)

## Why this shape (ponytail: cheapest path that's actually correct)

The obvious-sounding version of this task is "rename `phases/` to `MARATHONS/` everywhere" — a
repo-wide search-and-replace across ~70 files. That is not what's actually needed, and building it
that way would be doing far more than the ask requires:

- `utils/py/marathon_drive.py` and its frozen GH-308 Bash twin `relay-automation/marathon-drive.sh`
  **already** take `--phases-dir` / `PHASES_DIR`, both defaulting to `$ROOT/phases`. The override
  mechanism has parity today. Flipping the *default* value is a 1-line change in each twin — no new
  config surface needs to be invented.
- `relay-automation/xyz-vendor.sh` (the vendoring installer) has **zero** hardcoded "phases"
  references, grep-confirmed. A vendored install inherits whatever default the driver code defines.
  Nothing to touch there for "all new (vendored) installations" — that requirement is already met by
  changing the two twins' default.
- Of the ~70 files a bare grep for "phases" turns up, the large majority are prose mentions in docs,
  historical `PROJECT/3-COMPLETED/**` records, and `temp/relay-system-collected/**` (other repos'
  archived transcripts, not this repo's live code) — none of those need editing for the tool's actual
  behavior to change.

So the real work is small and mechanical: flip 2 defaults, fix 2 already-latent literal-string bugs,
and enumerate (not assume) which of the remaining files actually assert the *default value* rather
than just describing or using the override.

## Consult (codex, 2026-08-09 — single-model, degraded)

`/consult` was run against this doc per the operator's request. agy timed out twice (300s cap,
"failed or exceeded the cap" both times, no further detail available) — this is a **single-model,
un-reconciled** result, stated plainly rather than presented as agreement. Codex read the live code
directly (not just this doc) and returned 3 Blockers, all independently re-verified firsthand below
before being accepted into the plan. Full transcript:
`relay-system/2026-08-09/gh484-marathons-default-215746/gh484-marathons-default.codex.md`.

**Accepted, verified firsthand:**

1. **`relay-automation/marathon.sh` independently defaults and always forwards `--phases-dir`.**
   Confirmed by direct read: `marathon.sh:167` — `PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"` — is
   its own separate default computation, not inherited from the driver, and `marathon.sh:200`
   passes `--phases-dir "$PHASES_DIR"` to `marathon-drive` on every single-phase invocation of a
   multi-phase run. **Flipping only the driver's internal default, as originally scoped, would do
   nothing for `marathon.sh` runs — the actual multi-phase orchestrator entry point most marathons
   go through.** This was a real gap in the original scope, not a false positive: my first grounding
   pass greped `marathon.sh` into the file list but never opened it to check whether it computed its
   own default. It must be in Phase 1, not discovered later in Phase 0.
2. **Two live monitors go blind after the flip.** Confirmed by direct read: `marathon-ls.sh:110-118`
   (`newest_relay_file()`, hardcoded `"$repo/phases"`) and `marathon-detail.sh:39-53` (hardcoded
   `"$REPO/phases"`), neither reads any override. `marathon-tui.sh` delegates to both. These are
   runtime behavior — an operator running the live status monitor after this ships would see nothing
   for any new run, silently. Moves into Phase 1.
3. **The gitignore landmine is live right now, not historical.** Corrected framing below.

**Corrections codex made to this doc's own claims, accepted:**

- The three `git add --` + `check=True` call sites in `utils/py/marathon_drive.py` are currently at
  `:1183`, `:1223`, `:1782` (ESCALATION/transcript/RELAY.md) — this doc's original `:1129`/`:1169`/
  `:1728` were stale (the file had shifted since that first grounding pass). Exact line numbers
  will drift again before implementation — verify fresh at build time, don't trust either set.
- Only **one** frozen Bash twin is edited by this plan (`marathon-drive.sh`); `marathon.sh` is not
  in the GH-308 `TWINS` array (verified: it has no Python counterpart, no port exists) so fixing it
  needs no exception trailer. The original Acceptance #6 wording ("both edited Bash twins") was
  imprecise and is corrected below.
- The proposed variable-driven literal fix, as originally described ("read `$PHASES_DIR`'s
  basename"), is under-specified and wrong for a nested override: git porcelain paths are
  repo-relative, so for `--phases-dir "$ROOT/state/marathon-runs"` a basename-only match
  (`marathon-runs/`) would fail to exclude `state/marathon-runs/...`. Fix must compare the full
  repo-relative configured path, and a custom directory name containing awk-regex metacharacters
  must not be interpolated unescaped into the pattern. Both twins' fix design corrected below.
- The twin-parity test must force the Bash code path explicitly (`XYZ_PYTHON=0`) — the Bash shim
  execs Python by default (`marathon-drive.sh:9-18`), so an ordinary pair of invocations would test
  Python twice and never actually exercise the edited Bash line.
- `utils/swarm-preflight.sh` / `utils/py/swarm_preflight.py` generate a `marathon-drive` invocation
  with no `--phases-dir`, so they inherit the corrected default automatically — no change needed
  there. `poll.sh` / `relay-turn-lib.sh` carry no directory-name assumption. Both confirmed, ruled
  out of scope.

## What's actually broken today, independent of this rename

Found while grounding this, not part of the ask, but real and worth fixing in the same lane since
the same lines are being touched anyway:

- `utils/py/marathon_drive.py` (line current as of this writing: `:1661-1667`, verify fresh) —
  `p.startswith("phases/")` — a hardcoded literal in a containment-adjacent check. It does not read
  `phases_dir`, so it is **already wrong today** for anyone who passes a non-default `--phases-dir`:
  their phase output would not match this check.
- `relay-automation/marathon-drive.sh:959-965` — `awk '{ p=substr($0,4); if (p !~ /^phases\// && p
  !~ /^\.tick\//) print p }'` inside the dirty-tree pre-flight warning — same class of bug, same
  twin pairing.

Both need to become variable-driven — comparing the full repo-relative configured path, not a
literal or a bare basename (see consult correction above) — regardless of what the default is named.

## The gitignore landmine — LIVE IN THE CURRENT WORKING TREE, not historical

`marathon_drive.py` stages phase output with `git add --` + `check=True` at three call sites. `git
add` on an explicitly gitignored path exits 1, so `check=True` raises and the phase dies while
trying to record itself.

`test/marathon-root-audit.sh` (added 2026-08-09) pins exactly this. The committed history shows a
blanket `/phases/` gitignore line landing and being reverted the same day (`2dff4b2` then a same-day
revert) after hitting this exact crash — **but as of this writing there is a second, independent,
currently-uncommitted `/phases` line back in the operator's own working `.gitignore`** (confirmed:
`git status --short .gitignore` shows it modified, `git diff` shows a bare `+/phases` addition, not
present in `HEAD`). This is not a closed historical incident this plan can treat as resolved — it is
reproducing live, right now, outside this issue's scope to fix on its own. Flagged to the operator
separately; noted here so this plan doesn't imply it's already handled.

## `marathon-plans/` — confirmed dead, explicitly out of scope

`marathon-plans/2026-07-15-gh205-207/MARATHON.yaml` has zero references anywhere in scripts or
docs and exactly 2 commits, both from 2026-07-15 — a one-off artifact from a single past marathon
run, superseded by the live `PROJECT/2-WORKING/MARATHON-PLAN-*.md` convention (generated by
`utils/marathon-plan.sh`). Noted here only so nobody conflates the two conventions; not touched by
this issue.

## Anti-goals

- No migration of the ~72 already-committed historical `phases/<run-id>/` records. They stay where
  they are as history. The new default applies to new runs only — this is a forward-looking default
  change, not a repo reorganization.
- No change to `PROJECT/2-WORKING/MARATHON-PLAN-*.md` or `marathon-plans/` — different, unrelated
  convention, already covered above.
- No new environment variable, config file, or abstraction layer. `MARATHON_ROOT` (repo root) and
  `--phases-dir`/`PHASES_DIR` (phase-output dir) already fully cover this; adding a third knob would
  be unrequested surface for a value that has exactly one real override case.
- Not a blanket repo-wide rename of every prose mention of "phases". Phase 0 below decides, file by
  file, which of the non-driver references actually need to change.

## Phases

### Phase 0 — enumerate, don't assume (cx 1, risk 1, eff 1)

Turn the ~70-file grep hit list into a real classification before any edit lands. The consult
already resolved one category (live callers with their own independent default — see below), so
Phase 0's job is confirming nothing else in that shape was missed, plus the mechanical rest:
1. Mentions/prose only (docs, `PROJECT/3-COMPLETED/**`, `temp/relay-system-collected/**`) → no
   change needed, explicitly recorded as reviewed-and-skipped, not silently ignored.
2. Tests that hardcode the *default value* specifically (would silently start asserting against a
   directory the driver no longer writes to) → must update.
3. Tests that already pass an explicit `--phases-dir` fixture path → unaffected, recorded as such.
4. Skills/docs that document the default for a new user (`skills/marathon-triage/SKILL.md`,
   `skills/file-xyz-bug/SKILL.md`, `README.md`, `relay-automation/README.md`,
   `relay-automation/CONTRACT.example.md`) → must update for consistency.
5. **Live callers/consumers with their own independently-computed default** — not test or doc, but
   another script that constructs or assumes the directory name on its own. Already known members,
   promoted straight to Phase 1, not re-discovered: `marathon.sh`, `marathon-ls.sh`,
   `marathon-detail.sh`, `marathon-tui.sh`. Phase 0's job for this category is confirming the set is
   complete, not finding it from scratch.

Output: a short table in this doc (or a linked file) naming every file in categories 2–5 by path, so
Phase 2 has a checklist instead of a re-grep.

### Phase 1 — flip the defaults, fix the literals, fix the monitors, prove parity (cx 3, risk 2, eff 3)

**Drivers:**
- `utils/py/marathon_drive.py`: change the `--phases-dir` default from `os.path.join(root,
  "phases")` to `os.path.join(root, "MARATHONS")`; fix the containment literal (current line, verify
  fresh: `:1661-1667`) to compare against the resolved `phases_dir`'s repo-relative path, not the
  string `"phases/"` or a bare basename.
- `relay-automation/marathon-drive.sh`: same two changes — `PHASES_DIR="${PHASES_DIR:-"$ROOT/
  MARATHONS"}"`, and the `:959-965` awk pattern matches the full repo-relative `$PHASES_DIR` value
  (metacharacter-safe), not a literal or an unescaped basename.
- `marathon-drive.sh`/`marathon_drive.py` is the **one** GH-308 frozen twin pair touched here → goes
  through the documented exception process (`test/gh308-frozen-twin-guard.sh --check --base <rev>
  --allow-exceptions`, with a `Frozen-twin-exception: relay-automation/marathon-drive.sh — <reason>`
  commit trailer), not around it. The operator has already accepted this cost explicitly.

**Orchestrator (not a frozen twin — confirmed no Python counterpart exists):**
- `relay-automation/marathon.sh:167`: flip its own independent `PHASES_DIR="${PHASES_DIR:-"$ROOT/
  phases"}"` default the same way. This is the one that actually matters for a real multi-phase run.

**Monitors (not frozen twins, hardcode the literal directly, no override support today):**
- `marathon-ls.sh` and `marathon-detail.sh`: **dual-path lookup, not a straight swap.** Because this
  plan's anti-goal is "no migration of historical `phases/<run-id>/` records," a monitor that only
  looks in `MARATHONS/` goes blind to every pre-flip run's history. Both must check `MARATHONS/`
  first, then fall back to `phases/` for anything not found there — the honest reflection of "new
  runs go to the new place, old runs are still where they were."
- `marathon-tui.sh` inherits this automatically since it delegates to both scripts above.

**Landmine fix:**
- Extend (or add a sibling to) `test/marathon-root-audit.sh`'s gitignore-safety assertion to cover
  the new default path. This must land before any real same-repo phase runs against the new default.

**Parity test:**
- New/extended regression test: a fresh run with no `--phases-dir` writes under `MARATHONS/` via
  both `marathon.sh` and direct `marathon-drive` invocation; `--phases-dir <custom>` (including a
  nested path) still overrides correctly in both twins; the containment-literal fixes correctly
  recognize a non-default, nested `--phases-dir` value (the falsifiable case — assert it fails
  against the pre-fix code). **Must explicitly force `XYZ_PYTHON=0` for at least one parity run** —
  the Bash shim execs Python by default, so an unforced pair of invocations tests Python twice and
  never exercises the edited Bash line at all.

### Phase 2 — apply the Phase 0 checklist, docs, close (cx 1–2, risk 1, eff 1–2, size depends on Phase 0's count)

- Update every file Phase 0 categorized as 2–4. Each edit references its Phase 0 line, not a fresh
  ad-hoc decision.
- `README.md` / `relay-automation/README.md` / `ARCHITECTURE.md` (if it names the directory) updated
  to describe `MARATHONS/` as the default, `--phases-dir` as the override, and the dual-path lookup
  behavior for historical runs.
- Re-run the full `validate.sh` suite; confirm no drift beyond what Phase 0 predicted (a surprise
  failure here means Phase 0's classification missed something and should be corrected, not papered
  over).

## Acceptance (issue #484's original 6, plus 2 added after consult — corrections noted inline)

1. A fresh same-repo marathon run (no `--phases-dir` passed) writes to `MARATHONS/`, not the old
   directory, in both the Python and Bash drivers, **and via `marathon.sh`** (added — the original
   criterion covered only the drivers, not the orchestrator that actually forwards the flag).
2. `--phases-dir <custom>` still overrides the default exactly as today, in both twins, **including
   a nested custom path** (added — the naive basename-match design would have silently failed this).
3. The two hardcoded containment literals track the actual configured directory as a full
   repo-relative path, not a fixed string or bare basename (corrected) — verified with a fixture
   that passes a nested `--phases-dir` and confirms the containment/dirty-check logic still
   recognizes it correctly.
4. A `git add --` on the new default's phase artifacts does not crash — equivalent assertion to the
   existing gitignore-safety regression test, extended to the new path.
5. Every test identified in Phase 0 that hardcoded the old default is either updated or confirmed
   unaffected, with the reasoning recorded per-file, not asserted in bulk.
6. GH-308 frozen-twin exception process followed for the **one** edited frozen Bash twin
   (`marathon-drive.sh`, correcting the original "both" wording — `marathon.sh` is edited too but is
   not a frozen twin), not bypassed.
7. **(Added)** `marathon-ls.sh` / `marathon-detail.sh` / `marathon-tui.sh` correctly show status for
   both a new (`MARATHONS/`) and a pre-existing historical (`phases/`) run without operator
   intervention.
8. **(Added)** The gitignore-safety regression test passes against a clean tree (no stray `/phases`
   or `/MARATHONS` line reintroduced) before this ships.

## Sizing

cx/risk/eff **3/2/3**, 3 phases — revised upward from the pre-consult 2/2/2 after codex's review
surfaced a confirmed-real orchestrator + monitor-stack gap that would have shipped a plan satisfying
its own (too-narrow) acceptance criteria while leaving the actual multi-phase entry point unfixed.
Phase 0 stays cheap. Phase 1 now carries the orchestrator flip, the dual-path monitor design, and
the forced-Bash-path parity requirement, in addition to the original driver/literal work. Phase 2's
size still depends on Phase 0's enumerated count, not assumed up front.
