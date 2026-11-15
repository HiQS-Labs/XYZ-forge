---
title: A /re-vendor-xyz skill that refreshes one vendored .xyz copy safely, end to end
status: In progress
created: 2026-11-14
updated: 2026-11-14
owner: Noel Saw
branch: docs/XYZ-forge-gh1486-re-vendor-xyz-skill-2026-11-14
gh_issue: 1486
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1486
doc_type: feature
complexity: 2
risk: 2
effort: 2
phases: 1
harness_commit: 5967bde25
non_goals:
  - Changing relay-automation/xyz-sync.sh or relay-automation/xyz-vendor.sh
  - First install into a repository with no .xyz/ (that is /vendor-stack)
  - A fleet (--all) mode
  - Deploying the new skill into any Skills Army collection or onto another person's machine
goal: >
  An agent asked to refresh one repository's vendored `.xyz/` copy follows one skill that
  checks the source is published code, refuses while something runs from that copy, keeps the
  tier, backs up, refreshes through the existing `xyz-sync.sh`, judges success on three
  conditions rather than an exit code, and hands deployed-skill drift to Skills Army HQ.
---

# GH-1486 — `/re-vendor-xyz`: refresh one vendored `.xyz/` copy safely

## Status

| What was just completed | What's next |
|---|---|
| Issue filed with a two-model consult on the first draft (2026-11-13/14); task clone provisioned; recon and plan written. | Codex plan QA through relay-xyz, then write the skill and run the fixture checks. |

## Rating rationale (2026-11-14)

`rated 55/35/50/75` (pri/sev/appeal/effort).

- **Severity 35.** No data loss or corruption in the normal case. The consequence is a copy that reports success while stale or from unpublished code, or a run broken by a mid-run refresh (#1011, recoverable by rerunning). Recovery is easy (re-vendor), so mid-low band.
- **Priority 55.** Two downstream users needed a hand-written eight-step prompt on 2026-11-13, and every Forge fix reaches consumer repositories only through this refresh. Operator asked for it directly.
- **Appeal 50.** Neutral; the operator set no appeal.
- **Effort 75.** One instruction-only skill file and three one-line pointer edits, no code and no new suite; the fixture checks are the larger part.
- **Recurrence.** Window 2026-10-31 to 2026-11-14 versus 2026-10-17 to 2026-10-30: one operator-reported incident in the recent window (the hand-written prompt), none found in the earlier one by issue search for "vendor"/"xyz-sync"; #1011 (2026-10-10) is the same class but older. Coverage is issue titles only, so trend is unknown rather than zero.

## Recon (base `5967bde25`)

Issue body records the observed traps with file:line receipts; re-verified here at `5967bde25` (no change to `relay-automation/xyz-sync.sh`, `relay-automation/xyz-vendor.sh`, `skills/4-occasional/vendor-stack/`, `skills/3-weekly/skills-army-hq/` since the issue's recon commit `6f4dbaf9c`).

- **Writers this skill drives, unchanged.** `xyz-sync.sh update <dir>` selects registry rows matching `<target>` or `<target>/.xyz` (`xyz-sync.sh:193-197`) and calls `xyz-vendor.sh <target>` (`:291-296`) with no flags. `xyz-vendor.sh` stages a fresh copy from its own Forge checkout (`HARNESS_ROOT`, the script's parent), carries `XYZ_RUNTIME_PATHS` (`relay-system .tick .relay-driver.lock XYZ.json XYZ.json.lock XYZ.heartbeat.json`, `:236`) across, aborts before the swap if that copy fails, then `rm -rf` + `mv` (`:495-503`), writes `VERSION` (`source_commit`, `tick_version`, `vendored_utc`, `tier`, `:474-479`) and the registry row (`register_vendor`).
- **Traps the bare commands leave open** (all verified): exit 0 on no matching row (`:241-246,282`) and on a missing repository (`:292-295`); source guard only on `--all` (`:284-289`); no fetch, `check` compares against the local Forge `HEAD` (`:423-431`); `ok` then `SAFETY GUARD MISSING` for the same copy (`:442-451`); tier 2 kept only if `releases.db` is at the target root (`xyz-vendor.sh:66-72`); whole-tree replacement under a live run (#1011).
- **Live-run signals available without new code.** Relay driver lock path from `relay-automation/driver-lock-lib.sh:20-32` (`<target>/.git/relay-driver.lock`, or the common git dir for a linked worktree). Any process whose command line contains `<target>/.xyz/` (relay, marathon, Jog and turn shims all execute from there in a vendored repository).
- **Forge source location.** `XYZ_FORGE_ROOT`, else `canonical` in `<collection>/targets.json` (collection = `XYZ_SKILLS_ROOT`, else `~/git-pulse-sync/Deployed Skills`, per `skills-army-hq/SKILL.md:30-34`). On this machine that key is the primary Forge checkout. `find-hq.sh` is not usable here: from `<target>/.xyz/skills/...` it resolves `<target>/.xyz` (it has `utils/hq/hq.sh`), and from a deployed copy it resolves the collection.
- **Deployed skills.** `python3 <collection>/skills-army-hq/scripts/sync.py --root <collection> --status --canonical <forge>` reports `DRIFTED` per skill; updates go through the `skills-army-hq` skill's preview/apply (`intake.py update NAME --source <forge>/skills/<tier>/<name>`). `--canonical` must be passed: without it a stale fallback can downgrade skills (`skills-army-hq/SKILL.md:30-40`).
- **Registration surfaces for a new skill.** `ARCHITECTURE.md` Skills Index (alphabetical; row goes between `open-router` and `read-only`); `README.md` "Into another repo" section mentions only first install (`README.md:254-263`); `vendor-stack/SKILL.md` "Upgrades" (`:146-156`). `test/gh589-skill-viewer.sh` counts `skills/*/*/SKILL.md` and needs valid frontmatter; `test/path-integrity.sh` reads `ARCHITECTURE.md` links.
- **Gate route.** All changed paths are `*.md` outside the full-gate skill list in `utils/ci-route.sh:63-68`, plus `releases.db`/`releases.sql` and `TESTS-RESULTS/`, `PROJECT/`, `relay-system/` (docs surfaces). Route is docs: `utils/pdda/pdda.sh run`.

## Preflight bet

- **Outcome sought.** A downstream user's agent refreshes their `.xyz/` copy and the report is true: published source, nothing running, tier kept, backup made, current afterwards, deployed skills current.
- **Smallest viable bet.** One instruction-only `SKILL.md` that sequences commands that already exist, plus three one-line pointers. Not built: script changes, a helper script, a fleet mode, detection of hand edits inside `.xyz/`.
- **Alternatives rejected.** (a) A `## Refresh` section in `vendor-stack`: recommended by both consult advisors under `skills/README.md:25-28`; the operator chose a separate skill for a memorable name (recorded on the issue). (b) Fixing the scripts: protects direct callers too, but changes shared tooling and its `--help` contract; left for a separate decision.
- **Rollback.** Revert the commit. Operational writes made while using the skill (the `.xyz/` copy, registry row, target `.git/info/exclude`, Skills Army collection commits) are recovered from the backup zip and Skills Army's own backup, not by the revert.

## Plan

1. **Write `skills/4-occasional/re-vendor-xyz/SKILL.md`** (extends the existing writers `relay-automation/xyz-sync.sh` and the `skills-army-hq` skill; adds no script). Frontmatter `name: re-vendor-xyz`; description triggers on "/re-vendor-xyz", "re-vendor", "refresh the .xyz copy", "update the vendored harness", and says it is not for first install (`/vendor-stack`) or fleet refresh. Body, in order, with copy-paste shell for each step:
   1. Find the Forge source: `XYZ_FORGE_ROOT`, else `canonical` from the collection `targets.json`, else ask. Accept only if `git -C "$FORGE" rev-parse --show-toplevel` equals `$FORGE`, `basename "$FORGE"` is not `.xyz`, and `$FORGE/relay-automation/xyz-sync.sh` exists.
   2. Source is published code: branch in `${XYZ_SYNC_CANONICAL_BRANCHES:-main,development}`; `git status --porcelain` empty; `git fetch origin <branch>`; `git merge --ff-only origin/<branch>`; `HEAD` equals `origin/<branch>`. Never stash, reset or discard.
   3. Target: the argument, else the session's repository if it is not `$FORGE`. Resolve to an absolute path `$T`; `$FORGE/relay-automation/xyz-sync.sh list` must show `$T/.xyz`; `$T` must exist. No row: route to `/vendor-stack`.
   4. Nothing running: relay lock path per `driver-lock-lib.sh` absent; no process command line contains `$T/.xyz/` (shown with `ps -axo pid=,command=` and a fixed-string match that excludes itself).
   5. Tier: `tier=` from `$T/.xyz/VERSION`; if `2` and `$T/releases.db` is absent, stop.
   6. Current test (used before and after): `xyz-sync.sh check "$T/.xyz"` output has `ok    $T/.xyz`, has no `SAFETY GUARD MISSING $T/.xyz` line, and `source_commit=` in `$T/.xyz/VERSION` equals `git -C "$FORGE" rev-parse HEAD`. All three true before the refresh: report "already current" and go to step 9.
   7. Backup: zip `$T/.xyz` to `~/.local/state/xyz/backups/<basename $T>-<UTC yyyymmddTHHMMSSZ>.zip`; `[ -s ]`; report the path.
   8. Refresh: `"$FORGE/relay-automation/xyz-sync.sh" update "$T/.xyz"`, then the step-6 test. Repeat `ROUTER DRIFT` and `xyz-vendor.sh: WARNING` lines verbatim; never run `router_audit.py --fix` unasked.
   9. Deployed skills: if the collection exists, run `sync.py --status --canonical "$FORGE"` read-only; list Forge skills reported `DRIFTED` and hand them to `/skills-army-hq` (preview, then apply with `--source "$FORGE/skills/<tier>/<name>"`). No collection: say so.
   10. Report: Forge commit, the `check` lines for `$T/.xyz`, backup path, deployed-skill result, and "sessions already open keep the old skill text".
   - **Closed list of stops**, each printed as `re-vendor-xyz: stopped: <reason>` with the command output: Forge source not found / not a Forge checkout; branch not canonical; tree dirty; cannot fast-forward; `HEAD` not equal to origin; target not registered or missing; relay lock present; process running from `$T/.xyz/`; tier 2 without `releases.db`; backup missing or empty; any current-test condition false after the refresh. Anything else continues.
   - **Never:** commit or push in the target; touch another vendored copy; pass `XYZ_SYNC_ALLOW_UNSAFE_SOURCE`; use `--all`.
2. **`ARCHITECTURE.md`**: one Skills Index row between `open-router` and `read-only`.
3. **`skills/4-occasional/vendor-stack/SKILL.md` "Upgrades"**: first bullet names `/re-vendor-xyz` as the way to refresh one copy; the two bare commands stay as the underlying reference.
4. **`README.md`** "Into another repo": one sentence pointing to `/re-vendor-xyz` for later refreshes.
5. **`CHANGELOG.md`** entry; evidence under `TESTS-RESULTS/2026-11-14+GH-1486/`.

## Acceptance

Each item fails on base `5967bde25` because the skill does not exist; fixture items record the bare-command contrast in the same log.

- [ ] A1 `skills/4-occasional/re-vendor-xyz/SKILL.md` exists with `name: re-vendor-xyz` and the triggers above; `test/gh589-skill-viewer.sh` passes (count and name set include it). Red control: `ls skills/*/re-vendor-xyz` fails on base.
- [ ] A2 The skill states the closed list of stops and the three-part current test. Red control: `git grep -n "SAFETY GUARD MISSING" -- skills/` is empty on base.
- [ ] A3 Fixture, main path: target vendored from an older Forge commit, private `XYZ_REGISTRY`, the skill's commands run in order end with all three current-test conditions true. Contrast: `check` before the refresh prints `DRIFT`.
- [ ] A4 Fixture stops, each before anything is vendored and with `$T/.xyz/VERSION` byte-identical afterwards: unregistered target; dirty Forge source; Forge `HEAD` ahead of origin; relay lock present; process running from `$T/.xyz/`; tier 2 without `releases.db`. Contrast: bare `xyz-sync.sh update` exits 0 on the unregistered, dirty and ahead fixtures.
- [ ] A5 Fixture: a copy that `check` reports `ok` plus `SAFETY GUARD MISSING` (a guard pattern removed from the installed copy) is not judged current.
- [ ] A6 Adjacent path: rerun on an already-current target reports "already current", makes no backup and does not call `update` (`VERSION` `vendored_utc` unchanged).
- [ ] A7 `ARCHITECTURE.md`, `README.md` and `vendor-stack/SKILL.md` name `re-vendor-xyz`; `test/path-integrity.sh` passes. Red control: `git grep -n re-vendor-xyz -- ARCHITECTURE.md README.md skills/4-occasional/vendor-stack/SKILL.md` is empty on base.

## Verification

No new test suite or registry entry (GH-831). A3–A6 run as one manual fixture driver in a disposable full clone `XYZ-forge-gh1486-re-vendor-xyz-skill-2026-11-14-verify` (so the dirty and ahead cases never touch a valued checkout), with fixture targets under `$TMPDIR` and a private `XYZ_REGISTRY`; the driver executes the commands exactly as written in the skill (extracted from its code blocks) and logs each case with its contrast. Logs and provenance under `TESTS-RESULTS/2026-11-14+GH-1486/`. Regression suites re-run: `test/gh589-skill-viewer.sh`, `test/path-integrity.sh`, `test/gh660-skill-drift.sh`, `test/gh312-vendor-preserves-state.sh`, `test/gh293-vendored-guard-drift.sh`. Gate: docs route, `utils/pdda/pdda.sh run`. Step 9 is exercised read-only (`sync.py --status`) on this machine and recorded as observed.

## Risks

- Wording an agent reads as permission to refresh from unsafe source or during a live run → closed stop list, "never" list.
- The process check can false-positive on an unrelated process whose command line merely mentions the path (an editor) → it stops, which is the safe direction; the report names the process.
- Skills Army step depends on a machine-local collection → optional, says so when absent.
