---
gh_issue: 955
source: https://github.com/HiQS-Labs/XYZ-forge/issues/955
title: "Forge is upstream again: one centralized publisher for all standalone downstream repos (reverse #882)"
status: Proposed
created: 2026-10-03
updated: 2026-10-03
owner: operator
goal: "XYZ-forge is the single upstream. One publisher refreshes any or all standalone downstream repos on demand."
doc_type: project
effort: 3
complexity: 3
risk: 2
phases: 4
---

# GH-955: Centralized downstream publisher (forge is upstream again)

## Status

| What was just completed | What's next |
|---|---|
| Intake, ground-truth recon, plan draft (2026-10-03) | Codex plan QA, then operator questions, then execution |

## Problem (observed)

On 2026-10-01, #882 and HiQS-Labs/XYZ-skills-army-mini#2 made XYZ-skills-army-mini the upstream for Skills Army HQ:

- The forge keeps a vendored copy (`skills/3-weekly/skills-army-hq/UPSTREAM.md`).
- `push-to-skills-army-mini` is retired.
- #950 made `--target skills-army-mini` refuse by default.

The operator wants this reversed. XYZ-forge should be the upstream for **every** standalone repo, refreshed occasionally through **one** publisher.

Ground truth that makes the reversal cheap:

- **XYZ-skills-army-mini never diverged.** Its only commit since 10-01 is `0ad4bf74 sync: XYZ-forge@a2af20b1 (feat/sharpen-skills-army-hq)`. That is a forge publication from #934's branch. The repo has no tags, and mini#3 (its planned upstream work) is still open. Its 11 tracked files are exactly MANIFEST.txt, `.xyz-forge-revision`, and 9 managed rows.
- **#934's two `SKILL.md` edits exist only downstream.** They were published from the branch. #934 was later closed with "already upstream". Under the reversal, they must land in the forge (+12/−2 in `skills/3-weekly/skills-army-hq/SKILL.md`).

### Downstream inventory

All 21 HiQS-Labs repos were scanned on 2026-10-03.

| Repo | How the forge feeds it | Ownership markers | State |
|---|---|---|---|
| XYZ-mini | `utils/py/xyz_mini_sync.py` (default `xyz-mini` target) | MANIFEST.txt + `.xyz-forge-revision` | 44 tracked, 41 manifest rows, `TODO.md` is seed |
| XYZ-skills-army-mini | `xyz_mini_sync.py --target skills-army-mini` (retired by #882 / #950) | MANIFEST.txt + `.xyz-forge-revision` | 11 tracked, no divergence |
| AgentChorus-Skill | a **second, separate** publisher: `skills/2-daily/agent-chorus/sync-to-standalone.sh` + `publish-manifest.tsv` (bash, 149 lines) | `.xyz-canonical-revision` only; **no MANIFEST.txt** | 15 tracked; last sync 2026-09-29 (`c7ea57fde`); **its CI has been red since 2026-08-24** |

Out of scope, recorded:

- `XYZ-team-work-skill` and `ai-catalog-update` are **empty** repos.
- Harness-vendored repos (for example XYZ-layout-engine) use `relay-automation/xyz-vendor.sh`, a different mechanism with a different job.

### What the two existing publishers do differently

| Behaviour | `xyz_mini_sync.py` | `sync-to-standalone.sh` |
|---|---|---|
| Manifest | Python tuple per target; directory entries expand to tracked files | TSV of individual files with declared mode 644/755 |
| Modes | managed / seed / adapted | managed only |
| Destination-only files | survive (an operator `NOTES.local` is kept) | **refused** (strict mirror) |
| Ownership guard | refuses to overwrite a file the last publication did not write | none (strict mirror instead) |
| Secret scan | yes (exit 4) | no |
| Provenance | `.xyz-forge-revision` (repo / sha / branch / dirty) | `.xyz-canonical-revision` (sha) |
| Commit / push | commits; `--push` pushes and reads back | neither (operator commits) |
| Drift check for downstream CI | **none** | `--check` (the standalone CI calls it at the recorded revision) |
| File modes | copies the source's executable bit | pins 644/755 |

The forge sources already match the TSV's declared modes (checked with `git ls-files -s`; no mismatches). The executable-bit copy is therefore equivalent to the TSV modes.

The AgentChorus-Skill CI (`skills/2-daily/agent-chorus/standalone/ci.yml`, published as `.github/workflows/ci.yml`) does two things:

1. It clones the forge at `.xyz-canonical-revision` and runs `sync-to-standalone.sh --check`.
2. It runs `bash skills/2-daily/agent-chorus/test-standalone.sh`, a path that does not exist in the child. The child path is `skills/agent-chorus/test-standalone.sh`. This was likely stale since the GH-744 tier move, and it is one reason the CI is red.

## Preflight bet check

- **Outcome sought:** one upstream and one command to refresh one, several, or all downstream repos. No second publisher drifting (the agent-chorus script already lacks the secret scan, the ownership guard, and the #950 adapted rules).
- **Smallest viable bet:** generalize the existing `xyz_mini_sync.py`, which already has target profiles. Add an `agent-chorus` profile, multi-target selection, a `--check` mode, and a one-time `--adopt` for a child that has no MANIFEST.txt. Retire the bash publisher. Reverse the #882 wording.
- **Alternatives rejected:**
  - *Keep two publishers.* That is the drift the operator wants gone.
  - *Make the bash script the shared one.* It lacks the safety logic, and porting that logic to bash is the larger job.
  - *A new `publish_downstream.py` module.* It would duplicate the existing one; generalizing in place is DRY. Renaming the file is a question for the operator (Q4).
- **Rollback / containment:** one PR. Reverting it restores both publishers and the #882 wording. Downstream repos change only when the operator runs a publication. Every publication is a normal commit in the child, which can be reverted there.

## Requirements → plan

R1. One publisher, every downstream: profiles `xyz-mini`, `skills-army-mini`, `agent-chorus`.
R2. Target one, many, or all in one run.
R3. Forge is upstream for Skills Army HQ again: reverse the #882 / #950 retirement and land #934's edits.
R4. AgentChorus moves onto the central publisher without breaking its CI. The old script is retired.
R5. Existing guarantees hold: XYZ-mini adapted ownership (#950), the ownership guard, the secret scan, verified push, and idempotence.

### Ordered implementation (verification inline)

1. **Multi-target CLI** (`utils/py/xyz_mini_sync.py`, `main`).
   - `--target` becomes repeatable and accepts `all`. The default stays `xyz-mini`.
   - The current single-target body moves into `publish_one(target, args)`, unchanged. `main` loops over the selected targets in a fixed order, keeps going after one fails, prints one summary line per target, and exits with the worst code (4 > 3 > 2 > 0).
   - `--dest` is refused when more than one target is selected (exit 2).
   - *Verify:* `test/gh589-xyz-mini-sync.sh` keeps passing for a single target. Two new assertions go in the existing suite: `--target xyz-mini --target agent-chorus` plus `--dest` refuses; `--target all --print-manifest` lists every profile.
2. **Un-retire skills-army-mini.**
   - Delete `RETIRED_TARGETS` and its refusal (added by #950).
   - Drop the `XYZ_ALLOW_RETIRED_TARGET` opt-in and the default-refusal assertion from `test/gh620-skills-army-mini-sync.sh`.
   - *Verify:* gh620 passes with no opt-in. A red control re-adds the refusal and gh620 fails.
3. **`agent-chorus` profile.**
   - The 15 TSV rows become a Python manifest tuple, all `managed`. The TSV row that ships `publish-manifest.tsv` itself is dropped, and the TSV is deleted.
   - Profile: env `AGENT2AGENT_STANDALONE_REPO` (kept for compatibility), sibling `AgentChorus-Skill`, log `agent-chorus-sync`.
   - *Verify:* a preview against a throwaway clone of the real AgentChorus-Skill lists exactly its 15 paths with no deletions.
4. **`--adopt` (one-time; for a child without MANIFEST.txt).**
   - Allowed only when the child has no MANIFEST.txt.
   - It treats child files the manifest names as owned, so the ownership guard does not refuse to overwrite them.
   - It removes the superseded `.xyz-canonical-revision` in the same commit.
   - It refuses on any other existing MANIFEST.txt.
   - Destination-only files survive, which matches the central publisher's semantics (the strict-mirror question is Q3).
   - *Verify:* a gh589 assertion that `--adopt` on a seeded child with unmanifested identical paths succeeds and writes MANIFEST.txt; without `--adopt`, the same run refuses.
5. **`--check` mode** (replaces the bash `--check` for downstream CI).
   - Read-only: exit 0 when every managed path is byte-identical to the source at HEAD, with the same executable bit, and `.xyz-forge-revision`'s `source_sha` equals HEAD. Otherwise exit 1, naming each drifting path.
   - Adapted and seed paths are not compared.
   - *Verify:* gh589 asserts check passes right after a publication and fails after one managed byte is changed (red control).
6. **AgentChorus standalone CI and docs.**
   - `standalone/ci.yml`: read `source_sha` from `.xyz-forge-revision`, then run `python3 utils/py/xyz_mini_sync.py --target agent-chorus --dest "$GITHUB_WORKSPACE" --check` in the forge clone. Fix the smoke step path to `skills/agent-chorus/test-standalone.sh`.
   - Update `agent-chorus/README.md` and `standalone/README.md` to point at the central publisher.
   - Delete `sync-to-standalone.sh` and `publish-manifest.tsv`.
   - *Verify:* path-integrity passes, and grep finds no remaining `sync-to-standalone` reference outside history.
7. **Reverse #882 in docs.**
   - Delete `skills/3-weekly/skills-army-hq/UPSTREAM.md`.
   - Un-retire `skills/3-weekly/push-to-skills-army-mini/SKILL.md`, or fold it per Q2.
   - Revert the #882 wording in `skills/README.md`, `ROUTER.md:220`, `ARCHITECTURE.md`, and the `push-to-xyz-mini` / ADAPTATIONS text.
   - Land #934's two `SKILL.md` edits, taken from `origin/feat/sharpen-skills-army-hq`.
   - Update `PROJECT/2-WORKING/GH-882-SKILLS-ARMY-UPSTREAM.md` and the CHANGELOG.
   - `utils/ci-route.sh` keeps routing the skills-army paths to gh620.
   - *Verify:* `gh267`-style doc pins are unaffected; path-integrity passes; `skills-army-hq.sh` passes.
8. **Gate and previews.**
   - Run the focused suites (gh589, gh620, path-integrity, skills-army-hq) during iteration.
   - Run the full gate once on the final commit.
   - Run read-only previews (no `--apply`) against all three real children and record the plan lines in `TESTS-RESULTS/2026-10-03+GH-955/`.
   - Expected: XYZ-mini "delete 0"; skills-army-mini "delete 0"; agent-chorus refuses without `--adopt` and plans 15 paths with it.

After merge, closing actions (not in this PR):

- Comment on and close #882 as reversed.
- Comment on mini#2 and mini#3.
- Reopen #933 as landed via #955.
- The operator runs the first `--target all` publication: `--adopt` once for agent-chorus, then `--push`.

### Non-goals

- Harness vendoring (`xyz-vendor.sh`).
- Inbound vendoring.
- The two empty repos: profiles are added when they get content.
- A path-rewrite vendoring mode.
- Scheduling or automation of publications.
- Renaming XYZ-mini's adapted mode.
- No new test suites (GH-831): every new check is an assertion in the existing gh589 / gh620 suites.

### Risks

- **Retiring the bash `--check` while the child CI still calls it.** Mitigation: `ci.yml` is a managed file of the profile, so the first central publication replaces it in the same commit.
- **`--adopt` overwriting child-only content.** Mitigation: it only claims manifest-named paths, and it refuses when MANIFEST.txt exists.
- **Multi-target partial failure.** Mitigation: targets are independent, and each publication is its own child commit; a summary line is printed per target.

## Open operator questions (asked after plan QA, before execution)

- **Q1.** The operator said "all 4" downstream repos, but the scan finds 3 active ones plus 2 empty repos. Is the fourth one of the empty repos, or something else?
- **Q2.** One operator skill for all targets (fold `push-to-xyz-mini` and `push-to-skills-army-mini` into one), or keep one skill per target?
- **Q3.** Should AgentChorus-Skill lose its strict-mirror behaviour (refusing destination-only files) and adopt the central "unrelated files survive" rule?
- **Q4.** Keep the filename `utils/py/xyz_mini_sync.py` (less churn), or rename it to match its wider job?

## Rating (2026-10-03)

`rated 55/40/50/50` (pri/sev/appeal/effort).

- **Severity 40:** no active data loss; #950 fixed the XYZ-mini deletion hazard. The cost is drift risk: two publishers, a broken child CI, and an upstream decision the operator wants reversed.
- **Priority 55:** the operator asked for it now, and it unblocks the 10-08 audit decision.
- **Appeal:** neutral 50; the operator gave no score.
- **Effort 50:** generalizes an existing ~380-line module, plus docs.
- **Recurrence:** publisher-drift class over the last 14 days: #951 (mini deletion hazard), #934 / #933 (upstream confusion), and the agent-chorus CI red since 08-24. These are distinct incidents with related causes, not one cross-posted incident.
