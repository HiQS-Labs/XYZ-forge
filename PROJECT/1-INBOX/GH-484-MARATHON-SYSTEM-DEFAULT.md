---
title: "GH-484 — redefine the canonical marathon-phase directory default from phases/ to marathon-system/"
status: 1-INBOX
created: 2026-08-09
owner: noel
doc_type: project
goal: >
  Flip the DEFAULT value of the marathon drivers' per-phase run-output directory from
  `$ROOT/phases` to `$ROOT/marathon-system`, matching the naming already used by `relay-system/`,
  for every new install (vendored or not), while the existing `--phases-dir` / `PHASES_DIR`
  override keeps working exactly as it does today. Naming-consistency issue, not a bug fix.
---

Issue: [#484](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/484)

## Sequencing decision (operator, 2026-08-09)

Ships standalone, **before** Nightwatch (0.3.0) phase 1 begins — not as one of Nightwatch's phases.
Deliberate ordering, not just "not blocking": Nightwatch's actual work touches the same durability
surface this issue touches (the phase-output directory's git-add/containment behavior). Doing
Nightwatch's work first and renaming underneath it afterward would mean re-touching the same
freshly-changed lines a second time, running the GH-308 frozen-twin exception process twice instead
of once, and rebasing this rename against Nightwatch's own recent edits instead of the other way
around. GH-484 gives Nightwatch a correctly-named, already-hardened base to build on, not the
reverse. No RELEASES.md edit made alongside this — that file's own contract reserves edits for an
explicit release-planning ask, which this is a scoping decision adjacent to but not itself.

## Why this shape (ponytail: cheapest path that's actually correct)

The obvious-sounding version of this task is "rename `phases/` to `marathon-system/` everywhere" — a
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
- No re-vendoring sweep of the existing fleet installs. The goal covers **new** installs; the ~9
  already-vendored `.xyz/` copies on other repos keep the old default until their next normal
  `xyz-sync`, and the monitors' `phases/` fallback (Phase 1) keeps those repos visible in the
  meantime. Forcing a same-day fleet re-vendor would turn a 1-line default flip into a multi-repo
  campaign — exactly the scope creep this plan exists to avoid.
- Not a blanket repo-wide rename of every prose mention of "phases". Phase 0 below decides, file by
  file, which of the non-driver references actually need to change.
- **`marathon-system/` stays tracked in git, same as `phases/` is today — not gitignored.** Raised
  and settled by the operator directly: not worth the extra work this would create (a driver
  behavior change would be required first, or the first same-repo phase crashes recording itself —
  see the gitignore-landmine section above). If reducing per-run-artifact churn is ever wanted,
  that's GH-388's territory (run-log durability), a separate question this issue doesn't take on.

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

Category 4's check includes `ARCHITECTURE.md` — settle here whether it names the directory, so
Phase 2 isn't left holding a conditional.

Output: a short table **appended to this doc** naming every file in categories 2–5 by path, so
Phase 2 has a checklist instead of a re-grep. Phase 0 lands **zero edits** and is one sitting —
classification only; anything that looks like it needs design work gets a table row saying so, not
an on-the-spot fix.

### Phase 1 — flip the defaults, fix the literals, fix the monitors, prove parity (cx 3, risk 2, eff 3)

**Drivers:**
- `utils/py/marathon_drive.py`: change the `--phases-dir` default from `os.path.join(root,
  "phases")` to `os.path.join(root, "marathon-system")`. Note the default is computed at the
  resolution site (`phases_dir = args.phases_dir or os.path.join(root, "phases")`, currently
  `:687`), **not** in the argparse declaration (`:383` carries no default) — edit the former. Also
  fix the containment literal (current line, verify fresh: `:1666`) to compare against the resolved
  `phases_dir`'s repo-relative path, not the string `"phases/"` or a bare basename.
- `relay-automation/marathon-drive.sh`: same two changes — `PHASES_DIR="${PHASES_DIR:-"$ROOT/
  marathon-system"}"`, and the `:959-965` awk pattern matches the full repo-relative `$PHASES_DIR`
  value (metacharacter-safe), not a literal or an unescaped basename.
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
  looks in `marathon-system/` goes blind to every pre-flip run's history. Both must check
  `marathon-system/` first, then fall back to `phases/` for anything not found there — the honest
  reflection of "new runs go to the new place, old runs are still where they were." The same
  fallback also keeps fleet repos whose vendored harness hasn't re-synced yet (still writing to
  `phases/`) visible in the monitors — see the no-re-vendoring anti-goal.
- `marathon-tui.sh` inherits this automatically since it delegates to both scripts above.

**Dirty-check behavior change (intended, record it, don't special-case it):** the fixed awk/Python
exclusion tracks the *configured* directory, so leftover **uncommitted** legacy `phases/` debris
(e.g. from a crashed pre-flip run) will start surfacing in the dirty-tree warning and hard-stop a
`--require-clean` run. That is the correct reading — such debris genuinely is a stray file now —
so the fix is to note it in the warning's vicinity/CHANGELOG, not to add a legacy-path carve-out.
(Committed historical `phases/<run-id>/` records are clean in `git status` and unaffected.)

**Landmine fix:**
- Extend (or add a sibling to) `test/marathon-root-audit.sh`'s gitignore-safety assertion to cover
  the new default path. This must land before any real same-repo phase runs against the new default.

**Parity test:**
- New/extended regression test: a fresh run with no `--phases-dir` writes under `marathon-system/`
  via both `marathon.sh` and direct `marathon-drive` invocation; `--phases-dir <custom>` (including a
  nested path) still overrides correctly in both twins; the containment-literal fixes correctly
  recognize a non-default, nested `--phases-dir` value (the falsifiable case — assert it fails
  against the pre-fix code). **Must explicitly force `XYZ_PYTHON=0` for at least one parity run** —
  the Bash shim execs Python by default (`"${XYZ_PYTHON-1}" == "1"` at `marathon-drive.sh:9`), so an
  unforced pair of invocations tests Python twice and never exercises the edited Bash line at all.
  Beware: the shim's own header comment (`:6-8`, "Default (unset/0) runs the canonical Bash
  implementation") is **stale** — it predates the GH-264 Python-default flip and contradicts the
  code one line below it. Don't let it talk you out of forcing `XYZ_PYTHON=0`.

### Phase 2 — apply the Phase 0 checklist, docs, close (cx 1–2, risk 1, eff 1–2, size depends on Phase 0's count)

- Update every file Phase 0 categorized as 2–4. Each edit references its Phase 0 line, not a fresh
  ad-hoc decision.
- `README.md` / `relay-automation/README.md` / `ARCHITECTURE.md` (if it names the directory) updated
  to describe `marathon-system/` as the default, `--phases-dir` as the override, and the dual-path
  lookup behavior for historical runs.
- Re-run the full `validate.sh` suite; confirm no drift beyond what Phase 0 predicted (a surprise
  failure here means Phase 0's classification missed something and should be corrected, not papered
  over).
- Close out: CHANGELOG.md entry, move this doc to `PROJECT/3-COMPLETED/`, close #484 (standard
  `pdda-eod` flow). When all 8 acceptance items pass, this issue is **done** — anything discovered
  along the way that isn't on the acceptance list gets its own issue, not a Phase 3.

## Acceptance (issue #484's original 6, plus 2 added after consult — corrections noted inline)

1. A fresh same-repo marathon run (no `--phases-dir` passed) writes to `marathon-system/`, not the
   old directory, in both the Python and Bash drivers, **and via `marathon.sh`** (added — the
   original criterion covered only the drivers, not the orchestrator that actually forwards the flag).
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
   both a new (`marathon-system/`) and a pre-existing historical (`phases/`) run without operator
   intervention.
8. **(Added)** The gitignore-safety regression test passes against a clean tree (no stray `/phases`
   or `/marathon-system` line reintroduced) before this ships. Note the tension with the landmine
   section above: the **currently-live uncommitted `/phases` line** in the working `.gitignore` must
   be dispositioned by the operator (dropped, or consciously resolved under its own issue) before
   this criterion can pass — this plan doesn't decide its fate, only that it can't still be sitting
   in the tree at ship time.

## Sizing

cx/risk/eff **3/2/3**, 3 phases — revised upward from the pre-consult 2/2/2 after codex's review
surfaced a confirmed-real orchestrator + monitor-stack gap that would have shipped a plan satisfying
its own (too-narrow) acceptance criteria while leaving the actual multi-phase entry point unfixed.
Phase 0 stays cheap. Phase 1 now carries the orchestrator flip, the dual-path monitor design, and
the forced-Bash-path parity requirement, in addition to the original driver/literal work. Phase 2's
size still depends on Phase 0's enumerated count, not assumed up front.

---

## Phase 0 OUTPUT — enumeration complete (2026-08-09, branch `feat/gh484-marathon-system-default`)

Zero edits landed outside this table, as specified. Method: `/usr/bin/grep` (not `rtk grep` — see the
known false-negative), repo-wide for `phases`, then narrowed to *directory-shaped* references
(`phases/`, `/phases`, `phases_dir`, `PHASES_DIR`, `phases-dir`) since the bare word overwhelmingly
means either the PDDA frontmatter triage integer or the `MARATHON.yaml` `phases:` key — neither of
which is this directory.

**Funnel:** 685 files match `phases` repo-wide → 543 are in history/transcript trees
(`PROJECT/3-COMPLETED/`, `.tick/events/`, `relay-system/`, `temp/`, `AUDIT/`, `PROJECT/4-MISC/`,
`__pycache__/`, `phases/`, `marathon-plans/`) → 142 in the live surface → **17 carry a real
directory-shaped reference**. Everything else in those 142 is prose about plan phases.

### Category 2 — hardcodes the default, MUST update

| File | Line(s) | What it pins | Why it breaks |
|---|---|---|---|
| `test/marathon.sh` | 273 | `"$vendored_phases" == "$vendored_root/phases"` | **The single test that proves this issue's stated goal.** GH-206's vendored-install case asserts `marathon.sh`'s own default with zero env overrides. Fails outright after the flip — correctly. Must become `marathon-system`. |
| `test/marathon-drive.sh` | 819, 832, 917, 930–931 (stubs) + invocations at 836–847, 872–880 | Vendored-consumer chain (GH-171/GH-172) invoked with **no `--phases-dir`**; its stub agents append to `$PWD/phases/p1/RELAY.md` | **Not predicted by the plan.** Driver would write `marathon-system/p1/RELAY.md` while the stub writes `phases/p1/RELAY.md` → driver sees no progress; the test fails for a misleading reason. This is exactly the "new vendored installation" path the issue's goal names. |
| `test/gh401-dry-run-no-mutation.sh` | 56 | `[ ! -e "$MROOT/phases" ]`, run unscoped (no `--phases-dir`, confirmed at 45–47) | Goes **vacuously true** after the flip — stops testing anything while still reporting pass. The sibling `before`/`after` porcelain assertion survives, so this one fails silently-green, the worst shape. |
| `test/marathon-monitor.sh` | 42, 48 | Fixtures `mkdir -p "$repo/phases/p1"` for `marathon-ls.sh` | Dual-path fallback (Phase 1) keeps these **green without ever exercising the new default**. Must gain a `marathon-system/` fixture case — this is what proves acceptance #7, not the existing rows. |
| `test/marathon-root-audit.sh` | 250 | `for probe in phases/audit-probe/RELAY.md …` | The gitignore-safety probe. Already scoped in the plan's landmine fix; recorded here for completeness. |

### Category 3 — passes an explicit `--phases-dir` fixture, UNAFFECTED (verified, not assumed)

`test/debug-mantra.sh`, `test/gh284-runlog-heartbeat.sh`, `test/gh319-gate-path-with-space.sh`,
`test/gh322-runlog-python-lane.sh`, `test/gh331-cost-summary.sh`, `test/gh385-retry-token-satisfied.sh`,
`test/gh390-gate-guard.sh`, `test/gh407-gate-ran-attribution.sh`, `test/gh438-acceptance-recheck.sh`,
`test/gh438-removal-is-progress.sh`, `test/gh457-gate-tiers.sh`, `test/xyz-harness-hooks.sh`, and
`test/marathon-drive.sh` cases 1–16 + 19+ (its `run_driver()` helper passes `--phases-dir "$A/phases"`
at :57, which is why :79's `[ ! -e "$A/phases" ]` stays meaningful — unlike gh401's).

`$A/phases` here is a **fixture path the test chooses**, not the driver's default. These keep passing
unchanged and keep testing the override path, which is the point.

Also no-change, for a different reason — the string is an arbitrary relay-file path or a tick
`--paths` value, never the resolved output dir: `test/gh342-sentinel-debug-log-python.sh`,
`test/gh397-reviewer-turn-role.sh`, `test/sentinel-driver-hooks.sh`, `test/test_python_layer.py:193`,
`test/gh268-relay-cue-and-target-checks.sh` (comment), `test/litmus-release.sh` (comments, incl. the
`/phases/`-gitignore rationale at :104 — worth *reading* before Phase 1, not editing).

### Category 4 — documents the default, MUST update

| File | Line(s) | Note |
|---|---|---|
| `README.md` | 215 | "each gets `phases/<id>/RELAY.md`" |
| `relay-automation/README.md` | 123 | `MARATHON_ROOT` description names `phases/` |
| `relay-automation/MARATHON.example.yaml` | 36 | **Not in the plan's list.** The example plan users copy — `id → phases/<id>/RELAY.md`. |
| `.claude/commands/pre-marathon.md` | 9 | **Not in the plan's list.** A live operator command that inspects `phases/*/` for stale phase dirs — needs dual-path awareness, same as the monitors. |
| `relay-automation/marathon-drive.sh` | 26, 40, 41, 71, 603, 604, 634, 957, 969 | `--help` output + header comments. Same file as the Phase 1 default flip; edit together or the help text lies. |
| `relay-automation/marathon.sh` | 15, 84, 94, 96, 98 | Same — usage text, same file as its Phase 1 flip. |

**Plan candidates confirmed to need NO change** (checked, not skipped silently):
- `ARCHITECTURE.md` — **zero** matches for `phases` at all. This settles the plan's open conditional; Phase 2 is not left holding it.
- `relay-automation/CONTRACT.example.md` — no directory-shaped reference.
- `skills/marathon-triage/SKILL.md:103` and `skills/file-xyz-bug/SKILL.md` — `phases` here is the PDDA frontmatter **triage integer**, not the directory. Same for `PROJECT/PDDA.md`, `utils/pdda/pdda.sh`, `utils/hq/hq*.sh`, `sentinel-overlay/sentinel-nightly.sh`, `skills/skills-sync-trinity/scripts/render_working_doc.py` (an unrelated `dest="phases"` argparse target).
- `utils/swarm-preflight.sh:44`, `utils/py/swarm_preflight.py`, `test/swarm-preflight.sh`, `test/gh308-swarm-gate-path.sh` — the only match is the JSON literal `"source": "self#phases"`, an unrelated remediation-source token. Confirms the consult's ruling that swarm-preflight is out of scope.
- `src/marathon-yaml.js`, `bin/marathon-yaml` — parse the YAML `phases:` key; never touch the directory.
- `AGENTS.md`, `ROUTER.md`, `UPGRADE.md`, `PROJECT/PDDA.md` — no directory-shaped reference.

### Category 5 — live callers with their own independent default: SET CONFIRMED COMPLETE

The consult-supplied set is exactly right and gained no new members:

| File | Line(s) | Shape |
|---|---|---|
| `relay-automation/marathon.sh` | 167 (default), 200 (forwards `--phases-dir`) | Own default computation |
| `relay-automation/marathon-ls.sh` | 113, 117 | `local phases_dir="$repo/phases"`, no override read |
| `relay-automation/marathon-detail.sh` | 40, 44 | `PHASES_DIR="$REPO/phases"`, no override read |
| `relay-automation/marathon-tui.sh` | — | **Zero** direct references; inherits via delegation, as the plan assumed. Verified. |

**Non-literal construction: ruled out.** Swept every `.sh`/`.py`/`.js` under `relay-automation/`,
`utils/`, `bin/`, `src/`, `sentinel-overlay/` for `RELAY.md` path assembly outside the driver — the
only hits are the two monitors above. Nothing builds the directory name by concatenation or format
string, so the grep-based audit has no blind spot of that shape.

### Line-number drift since the plan was written

- `relay-automation/marathon-drive.sh` awk containment literal is at **961**, not `959–965`.
- `utils/py/marathon_drive.py` containment literal at **1666** and default at **687** — both still
  accurate. Re-verify anyway at build time.

### Phase 2 sizing, now that Phase 0 has counted

**11 files to edit** (5 Category 2 + 6 Category 4), of which 2 are the same files Phase 1 already
opens. Phase 2 lands at the low end of its estimate: **cx 1, risk 1, eff 1**. The Category 2 work is
the real content — four of those five tests need judgment, not a string swap, and two of them
(`gh401`, `marathon-monitor`) fail *silently green* rather than loudly if handled carelessly.

---

## Phase 1 OUTPUT — implementation landed (2026-08-09)

Everything the plan specified for Phase 1, plus the Category 2 tests that directly prove Phase 1's
own behavior (leaving those to Phase 2 would have meant committing a red suite between phases). The
Category 4 docs went in alongside them since they are the same edit-and-verify pass.

### Two defects found by building it, neither predicted

1. **The symlink defect — in my own fix, caught by its own test.** The containment fix compares the
   configured phase dir against the repo toplevel, and `git rev-parse --show-toplevel` **always
   reports the PHYSICAL path**. A repo reached through a symlinked ancestor (macOS `/var` and
   `/tmp`, plenty of home and network mounts) gives `/private/var/…` from git and `/var/…` from the
   flag; the prefix test then fails, the computed prefix goes empty, and the exclusion **silently
   stops working** — the exact failure mode the fix existed to remove. Both twins had it
   (`os.path.abspath` → `os.path.realpath`; a `phys()` helper added on the Bash side that resolves
   the deepest existing ancestor, since the leaf does not exist until Step 1 creates it).
2. **`test/marathon.sh` lines 184/193/211/220** — see the corrected Category 2 row above.

### The parity test's first version was vacuous, twice

`test/gh484-phase-dir-default.sh` case (3) passed against pre-fix code on its first two drafts. Both
causes are worth recording because neither is visible from reading the assertion:
- The driver probes the default gate (`bash validate.sh`) and **dies before Step 0** in a fixture
  repo that has none, so the clean check never ran. Fixed with `--pre-advance-cmd true` plus a
  positive control that asserts an unrelated stray file *was* reported — without it, "the phase dir
  was not called stray" also passes for a driver that exited earlier.
- `git status --porcelain` **collapses an untracked directory** to a single `?? state/` line, so an
  untracked fixture never emits a path the prefix comparison can act on. The driver commits its
  phase artifacts, so the fixture is now tracked-then-modified — the shape a real resumed run
  produces, and the only one that exercises the fix.

Final state, verified by replaying the whole file against `HEAD`'s drivers: both default assertions
and both containment assertions go **red pre-fix**; the two override assertions and the two positive
controls pass in both directions, which is what they are for.

### Verification run

| Test | Result |
|---|---|
| `test/gh484-phase-dir-default.sh` (new) | 10/0 · forces `XYZ_PYTHON=0` for the Bash lane |
| `test/marathon.sh` | 33/0 |
| `test/marathon-drive.sh` | 144/0 |
| `test/marathon-monitor.sh` | 17/0 (+4 new GH-484 assertions) |
| `test/gh401-dry-run-no-mutation.sh` | 4/0 |
| `test/marathon-root-audit.sh` | pass · 44 invocations audited, both dir names probed |

The monitor's mixed-population assertion was separately falsified against a deliberately naive
"check `marathon-system/` first, return if found" variant, which it catches and the other three
fixtures do not.

### Still open for Phase 2

`CHANGELOG.md`, the full `validate.sh` re-run, and the close-out flow. The `marathon-drive.sh` /
`marathon_drive.py` twin pair went through the GH-308 exception process with a
`Frozen-twin-exception:` trailer rather than around it.
