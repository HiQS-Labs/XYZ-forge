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
| Plan QA round 1 adjudicated (F1–F6 adopted); operator answered Q1–Q5 | QA round 2, then execution |

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
| AgentChorus-Skill | a **second, separate** publisher: `skills/2-daily/agent-chorus/sync-to-standalone.sh` + `publish-manifest.tsv` (bash, 149 lines) | `.xyz-canonical-revision` only; **no MANIFEST.txt** | 15 tracked = 14 TSV rows (13 payload files + the TSV itself) + the marker; last sync 2026-09-29 (`c7ea57fde`); **its CI has been red since 2026-08-24** |

Receipts for the scan, history and CI claims: `TESTS-RESULTS/2026-10-03+GH-955/recon/` (org list, per-repo markers, XYZ-skills-army-mini commits since 10-01 and tag count, AgentChorus-Skill CI runs, the #934 diff and its source SHA).

Out of scope, recorded:

- `XYZ-team-work-skill` and `ai-catalog-update` are **empty** repos.
- Harness-vendored repos (for example XYZ-layout-engine) use `relay-automation/xyz-vendor.sh`, a different mechanism with a different job.

### What the two existing publishers do differently

| Behaviour | `xyz_mini_sync.py` | `sync-to-standalone.sh` |
|---|---|---|
| Manifest | Python tuple per target; directory entries expand to tracked files | TSV of individual files with declared mode 644/755 |
| Modes | managed / seed / adapted | managed only |
| Destination-only files | survive (an operator `NOTES.local` is kept) | destination-only **tracked** files refused (strict mirror) |
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
- **Smallest viable bet:** generalize the existing `xyz_mini_sync.py`, which already has target profiles. Add an `agent-chorus` profile, multi-target selection, and a read-only `--check` mode. AgentChorus-Skill gets one reviewed setup commit (no permanent flag). Retire the bash publisher. Reverse the #882 wording.
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
   - The selection is deduplicated: a target named twice, or named alongside `all`, publishes once, in profile order.
   - The current single-target body moves into `publish_one(target, args)`, unchanged. `main` loops over the selection, keeps going after a target fails, prints one summary line per target, and exits with the worst code (4 > 3 > 2 > 1 > 0).
   - `--dest` is refused when more than one target is selected (exit 2).
   - *Verify (existing gh589, new assertions):*
     - `--target A --target B --dest X` refuses.
     - `--target all --print-manifest` lists every profile.
     - Behavioural check: two targets via their env dests, the first refused (dirty destination) and the second clean. Expect exit 2, the second target published, and one summary line each.
     - Red control: short-circuit the loop after the first failure; the assertion must fail.
2. **Un-retire skills-army-mini.**
   - Delete `RETIRED_TARGETS` and its refusal (added by #950).
   - In `test/gh620-skills-army-mini-sync.sh`, drop the `XYZ_ALLOW_RETIRED_TARGET` opt-in and the default-refusal assertion.
   - Update the existing exact-set expectation (line ~69) to the nine-file payload without `UPSTREAM.md`, and refresh its retirement comments.
   - *Verify:* gh620 passes with no opt-in and still fails if a required payload is omitted.
3. **`agent-chorus` profile.**
   - The TSV's **13 payload rows** become a Python manifest tuple, all `managed`. The row that ships the TSV itself is dropped, and the forge TSV is deleted.
   - Profile: env `AGENT2AGENT_STANDALONE_REPO` (kept for compatibility), sibling `AgentChorus-Skill`, log `agent-chorus-sync`.
   - *Verify:* a preview against a throwaway clone of the real child, after the step-4 setup commit, plans 13 payload copies and 0 deletions.
4. **AgentChorus-Skill one-time setup** (replaces the proposed `--adopt` flag; Codex F1/F3, cheaper option).
   - After merge and before its first central publication, one reviewed commit in the child:
     - writes `MANIFEST.txt` listing the 13 payload paths;
     - deletes the legacy `.xyz-canonical-revision` and `skills/agent-chorus/publish-manifest.tsv`.
   - The commit is generated by a documented one-liner (`--print-manifest`, then `git rm` both legacy paths) and pushed.
   - From then on the ordinary publisher, guard and retry apply with no special case. No permanent adoption code exists to keep correct across retries.
   - *Verify (in a disposable clone of the child):*
     - The setup commit plus a normal `--push` yields exactly the 13 payload files, MANIFEST.txt and `.xyz-forge-revision`, with both legacy paths absent.
     - An unrelated tracked note survives.
     - Without the setup commit, the ownership guard refuses.
5. **`--check` (read-only managed-parity check for the child CI)** (Codex F2).
   - A separate path that **skips `destination_ready`**: no branch requirement, no origin query. It works on a detached PR checkout.
   - It is refused together with `--apply` or `--push` (exit 2, nothing written).
   - Exit 0 when every **managed** path is byte- and executable-bit-identical to the source at HEAD and `.xyz-forge-revision`'s `source_sha` equals HEAD. Otherwise exit 1, naming each drifting path.
   - Seed and adapted paths are not compared. It is reported as "managed parity", not whole-child identity.
   - Multi-target `--check` aggregates per the step-1 precedence.
   - *Verify (gh589 assertions):*
     - A detached, matching child passes.
     - One changed managed byte or mode returns 1 and names the path (red control).
     - A mixed matching and drifting multi-target run returns 1.
     - `--check --apply` refuses and leaves bytes, index and HEAD untouched.
6. **AgentChorus standalone CI and docs.**
   - `standalone/ci.yml`: read `source_sha` from `.xyz-forge-revision`, check out the forge at that SHA, and run `python3 utils/py/xyz_mini_sync.py --target agent-chorus --dest "$GITHUB_WORKSPACE" --check`. Fix the smoke step to `skills/agent-chorus/test-standalone.sh`.
   - Update `agent-chorus/README.md` and `standalone/README.md`.
   - Delete `sync-to-standalone.sh` and `publish-manifest.tsv`.
   - *Verify:* path-integrity passes, and no `sync-to-standalone` reference remains outside history.
7. **Reverse #882 in docs and routing.**
   - Delete `skills/3-weekly/skills-army-hq/UPSTREAM.md`.
   - Fold `push-to-xyz-mini` and `push-to-skills-army-mini` into `skills/3-weekly/push-downstream/SKILL.md` (Q2). Update every reference: `skills/README.md`, `ARCHITECTURE.md` skills index, `PAGES/skills.html` if it lists them, and `utils/ci-route.sh` path routing.
   - Revert the #882 wording in `skills/README.md`, `ROUTER.md:220`, `ARCHITECTURE.md`, and the `push-to-xyz-mini` / ADAPTATIONS text.
   - Land #934's two `SKILL.md` edits from `origin/feat/sharpen-skills-army-hq` (receipt: `recon/gh934-diff.txt`).
   - Update `PROJECT/2-WORKING/GH-882-SKILLS-ARMY-UPSTREAM.md` and the CHANGELOG.
   - `utils/ci-route.sh` keeps routing the skills-army paths to gh620.
   - **Transferred backlog (Codex F6, Q5):** the issue transfers happen after merge (closing actions). This PR only changes the wording that called the forge copy downstream.
   - *Verify:* path-integrity passes; `skills-army-hq.sh` passes; no duplicate active plan exists for a transferred item.
8. **Gate and previews.**
   - Run the focused suites (gh589, gh620, path-integrity, skills-army-hq) during iteration.
   - Run the full gate once on the final commit.
   - Run read-only previews (no `--apply`) against all three real children and record the plan lines in `TESTS-RESULTS/2026-10-03+GH-955/`.
   - Expected: XYZ-mini "delete 0"; skills-army-mini "delete 0"; agent-chorus refused by the ownership guard until the step-4 setup commit exists.

After merge, closing actions (not in this PR):

- Transfer mini #4–#7 back to XYZ-forge; park the new numbers with `roadmap add`; re-point the old rows and docs through the writer (Q5).
- Comment on and close #882 as reversed.
- Comment on mini#2 and mini#3.
- Reopen #933 as landed via #955.
- The operator runs the step-4 setup commit in AgentChorus-Skill, then the first `--target all --push` publication.

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
- **The setup commit claiming child-only content.** Mitigation: it lists only the 13 manifest-named payload paths, and the first publication's preview shows exactly what changes.
- **Multi-target partial failure.** Mitigation: targets are independent, and each publication is its own child commit; a summary line is printed per target.

## Operator questions: answered 2026-10-03 after QA round 1

- **Q1. Downstream set.** Answer: **only the 3 active repos.** The empty repos get a profile when they gain content.
- **Q2. Operator skill.** Answer: **one skill.** `push-to-xyz-mini` and `push-to-skills-army-mini` fold into one skill, `skills/3-weekly/push-downstream/` (`--target X` / `--target all`). The two old skill folders are deleted, and their discovery links are retired through Skills Army HQ after merge.
- **Q3. Mirror rule.** Answer: **the central rule.** Child-added files survive, and the ownership guard still blocks overwrites. No per-profile strict flag.
- **Q4. Filename.** Decided by the agent, unopposed: **keep `utils/py/xyz_mini_sync.py`.** Renaming it would churn tests, docs and the child CI for no behaviour change.
- **Q5. Moved issues.** Answer: **transfer them back to the forge.** After merge, run `gh issue transfer` on mini #4 / #5 / #6 / #7 to XYZ-forge (they get new forge numbers). Park each new number through `roadmap add`, and re-point the old #506 / #676 / #837 / #881 rows and docs to "returned as #N" through the writer. No feature work.

## Rating (2026-10-03)

`rated 55/40/50/50` (pri/sev/appeal/effort).

- **Severity 40:** no active data loss; #950 fixed the XYZ-mini deletion hazard. The cost is drift risk: two publishers, a broken child CI, and an upstream decision the operator wants reversed.
- **Priority 55:** the operator asked for it now, and it unblocks the 10-08 audit decision.
- **Appeal:** neutral 50; the operator gave no score.
- **Effort 50:** generalizes an existing ~380-line module, plus docs.
- **Recurrence:** publisher-drift class over the last 14 days: #951 (mini deletion hazard), #934 / #933 (upstream confusion), and the agent-chorus CI red since 08-24. These are distinct incidents with related causes, not one cross-posted incident.

## Plan QA dispositions: round 1 (Codex, `relay-system/2026-10-03/gh955-plan-qa.md`)

| Finding | Disposition |
|---|---|
| F1 adoption vs. retained-commit retry | **Modified:** dropped the `--adopt` flag. A one-time reviewed setup commit in AgentChorus-Skill (step 4) leaves the publisher and retry logic with no special case. |
| F2 `--check` must bypass `destination_ready` | **Implemented:** step 5 adds a separate read-only path, detached-checkout safe, refused with `--apply` / `--push`, with exit 1 in the precedence. |
| F3 13 payload rows; the legacy TSV stays in the child | **Implemented:** counts corrected; the setup commit removes both legacy paths. |
| F4 gh620's exact set still lists UPSTREAM.md | **Implemented:** step 2 updates the expectation to nine files. |
| F5 no behavioural multi-target check; dedup | **Implemented:** step 1 adds a two-target continue-on-failure assertion with a red control, plus dedup. |
| F6 transferred backlog ownership | **Implemented as an operator decision:** step 7 plus Q5. |
| Unverified remote claims | **Implemented:** receipts in `TESTS-RESULTS/2026-10-03+GH-955/recon/`. |
