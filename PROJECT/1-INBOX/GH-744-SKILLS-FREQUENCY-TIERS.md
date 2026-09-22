---
title: Organize skills/ into frequency-of-use tier folders (1-hourly, 2-daily, 3-weekly, 4-occasional)
status: Proposed (1-INBOX — not yet active)
created: 2026-09-21
owner: claude-a
gh_issue: 744
source: https://github.com/HiQS-Labs/XYZ-forge/issues/744
doc_type: refactor
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
harness_commit: e565c0fe   # origin/development at capture; task clone XYZ-forge-skills-tiers, branch feat/skills-frequency-tiers
non_goals:
  - Renaming any skill, editing any SKILL.md body, or touching Deployed Skills contents
  - Rewriting historical PROJECT/3-COMPLETED/**, marathon/relay transcripts, or CHANGELOG entries that cite old paths
  - A resolver library, registry file, or symlink shim layer — `ls -d skills/*/<name>` is the lookup
  - Changing the XYZ-mini published layout (its own skills/ stays flat)
related:
  - GH-325 (made skills/ the canonical home — this keeps that, one level deeper)
  - GH-660 (skill_drift_check.py — the scanner that must learn the second level)
  - GH-484 / GH-508 (Skills Army HQ collection and git-pulse projection — why app symlinks do not break)
goal: >
  `skills/` reads as a usage map: four numbered tier folders ordered by how often an operator
  reaches for a skill, every skill living in exactly one tier, and every scanner, locator, test
  and doc that addressed `skills/<name>` now addressing `skills/<tier>/<name>` — with the full
  gate green and the drift guard still recognising every forge-owned skill.
---

# GH-744 — Organize skills/ into frequency-of-use tier folders

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Observed problem

`skills/` is a flat alphabetical list of 60 directories. A newcomer (or an agent routing a task)
cannot tell the four skills used every hour from the eighteen used once a quarter without reading
the ARCHITECTURE.md Skills Index — which is also alphabetical and is missing seven skills
(browserbase, ci-optimize, converge, dry, timbre, unstuck, workhorse).

Operator decision 2026-09-21: physical tier folders, not a docs-only regrouping. Rationale given:
app discovery symlinks (`~/.claude/skills/<name>` → `Documents/Deployed Skills/<name>`) point at the
Skills Army HQ collection, not at this repo, so nesting does not break installed skills. Verified on
this machine: `readlink ~/.claude/skills/start-task` → `/Users/noelsaw/Documents/Deployed Skills/start-task`.

## Requirements (per issue #744)

1. Four tier folders under `skills/`, numbered so a directory listing sorts by frequency:
   `1-hourly/`, `2-daily/`, `3-weekly/`, `4-occasional/`.
2. Every existing skill moves with `git mv` into exactly one tier; names and contents unchanged.
3. Every scanner, locator, publisher, test and doc that addressed `skills/<name>` addresses the new path.
4. ARCHITECTURE.md Skills Index regrouped by tier and completed (the seven missing skills added).
5. `./validate.sh` green in a disposable clone; `utils/pdda/pdda.sh run` clean.

## Tier assignment

Operator-named anchors are marked **(op)**. Everything else is my placement from each skill's
trigger description; the PR reviewer and operator can re-tier any row by `git mv` — no code depends
on which tier a skill sits in, only on the two-level depth.

| Tier | Skills |
|---|---|
| `1-hourly` (14) | start-task **(op)**, recon **(op)**, debug-mantra **(op)**, ponytail **(op)**, triangulate, swe, five, better-options, relay, relay-xyz, relay-automation, consult, standup, unstuck |
| `2-daily` (14) | merge-cleanup **(op)**, marathon-triage **(op, "marathon build")**, jog, express, workhorse, xyz, agent-chorus, hq, file-xyz-bug, releases, relay-to-issue, review-xyz, phase-qa, ci-debug |
| `3-weekly` (14) | merge-cleanup-deep **(op)**, skills-army-hq **(op)**, radar **(op)**, end-of-week, weekly-shipped, whack-a-mole, 10days, sop, marathon-cleanup, dry, converge, honest, push-to-xyz-mini, push-to-skills-army-mini |
| `4-occasional` (18) | ate, browserbase, ci-doctor, ci-optimize, feynman, front-door, github-auth-debug, install-improve-audit, open-router, read-only, readme-audit, rpr, shakedown, spike-360, swe-diagram, timbre, vendor-stack, vscode-color |

Interpretation flagged: the operator wrote "marathon build"; no skill carries that name. The
marathon entry point that operators invoke is `marathon-triage` (it drives end to end since GH-724),
so it takes that slot. Plan QA round 1 moved `standup` up to `1-hourly` (session-boundary triage) and
`releases` down to `2-daily` (the ledger CLI is used every task; the `/releases` router skill is not).
`relay-automation` is a library skill, not invoked directly, but it ships the
relay package every `/relay` run consumes, so it sits beside `relay` and `relay-xyz`.

## Recon (base e565c0fe)

Enumerated with `grep -rn -E 'skills/[a-z0-9-]+'` over live code and docs, excluding history
(CHANGELOG, marathon-system/, relay-system/, PROJECT/3-COMPLETED, decisions/, evidence/, audit/,
TESTS-RESULTS/, SHAKEDOWN/, PARKED/, docs/ROADMAP-UPSTREAM-ARCHIVE) and app-discovery roots.
681 hits; the ones that execute are:

**Scanners / publishers that assume one level (must learn the second level)**
- `utils/py/skill_drift_check.py:36,52` — `canonical.glob("*/SKILL.md")` in the canonical loop AND
  `(canonical / name / "SKILL.md").is_file()` in the collection loop; both assume one level (plan QA r1 #4:
  patching only the glob leaves every vendored skill `unrecognized`). Consumed by
  `skills/skills-army-hq/scripts/sync.py` on every reconciliation (GH-660); a miss means every
  forge-owned skill is reported `unrecognized` and drift goes undetected.
- `utils/py/xyz_mini_sync.py:30-62` — MANIFEST source paths `skills/<name>` (destination in XYZ-mini
  stays flat: `skills/<name>`). `SKILLS_ARMY_MANIFEST` projects `skills/skills-army-hq` onto the child root.
- `utils/ci-route.sh:37-45,316` — subsystem registry path globs (`skills/hq/*`, `skills/releases/*`,
  `skills/agent-chorus/*`, `skills/standup/*`, `skills/skills-army-hq/*`, `skills/push-to-skills-army-mini/*`,
  `skills/relay-automation/*`, `skills/relay-xyz/*`). A miss silently drops the changed skill to the
  wrong tier; `test/ci-route.sh` pins the expected routing.
- `relay-automation/xyz-vendor.sh:432` — `VENDOR_DIRS` mirrors `skills` verbatim; the vendored
  `.xyz/skills/` becomes tiered with no code change. `UPGRADE.md` cites `.xyz/skills/<name>` twice.
- `skills/agent-chorus/publish-manifest.tsv:4-15` — canonical-source column (`skills/agent-chorus/...`) that
  `skills/agent-chorus/sync-to-standalone.sh:78` validates with `[ -f "$SOURCE_REPO/$source_rel" ]`; the
  destination column (the standalone repo's flat `skills/agent-chorus/`) stays. Same shape as the mini manifest.
- `skills/agent-chorus/standalone/ci.yml:24` — executable workflow in the standalone repo; clones this repo and runs
  `skills/agent-chorus/sync-to-standalone.sh --check` (repoint, it is code not prose).
- `repro.sh:165,167,276` — executes and greps `skills/relay-xyz/find-harness.sh` directly.
- `mini/skills/skill-viewer/scripts/list_skills.py:80` — globs `skills/*/SKILL.md` against the
  **XYZ-mini** root (flat by design). Untouched; its forge-side test `test/gh589-skill-viewer.sh`
  points it at fixtures.

**Skill scripts that derive the repo root from their own location (one level deeper now)**
- `skills/relay-xyz/find-harness.sh:103,172,207` — `$SELF_DIR/../..` (lib source, case 5 "self", vendored-live probe).
- `skills/file-xyz-bug/find-xyz.sh:70` — borrows relay-xyz's locator as a SIBLING (`$SELF_DIR/../relay-xyz/...`);
  under tiers they are in different folders. Becomes the tier-agnostic glob `"$SELF_DIR"/../../*/relay-xyz/find-harness.sh`
  (unquoted glob in the `for` list; no tier name hardcoded).
- `skills/relay-automation/make-pkg.sh:11,30` — writes/echoes the tarball at the literal `skills/relay-automation/relay-pkg.tar.gz` (besides the `cd ../..` at :5).
- `skills/review-xyz/scripts/review_engine.py:9` — `XYZ_ROOT = dirname(dirname(SKILL_DIR))`; needs one more `dirname` (it is not published flat anywhere; the Deployed-Skills copy already cannot resolve `utils/py/review_xyz.py` and exits 2 there today).
- `skills/hq/find-hq.sh:42,62`, `skills/file-xyz-bug/find-xyz.sh:46,64`, `skills/vendor-stack/find-pdda.sh:28,35`,
  `skills/vendor-stack/install.sh:50`, `skills/relay-to-issue/relay-to-issue.sh:49`, `skills/relay-automation/make-pkg.sh:5`.
- `skills/agent-chorus/scripts/agent_chorus.py:85` — `parents[3]`; this file is ALSO published flat
  into XYZ-mini, so it must resolve at both depths: walk up to the nearest ancestor containing `skills/`, fall back to `parents[3]`.
  This reproduces today's result in every layout — forge root, flat mini root, and a vendored copy, where `parents[3]` is
  already `<consumer>/.xyz` (the walk-up lands on the same directory). Re-homing a vendored agent-chorus's `relay-system/`
  to the consumer root (plan QA r1 #3) would be a behaviour change unrelated to the layout move — not done here.
- `skills/merge-cleanup/scripts/scan_clones.py:190` — `parents[3] / "bin" / "tick"`; same walk-up, keyed on `bin/tick`.
- Each skill's `install.sh` symlinks `~/.claude/skills/<name>` → `$SELF_DIR`; `SELF_DIR` is
  self-relative and needs no change. Only `vendor-stack/install.sh` derives `HARNESS` from `../..`.
- Every locator already guards the self-relative candidate with a marker check
  (`_has_harness`, `relay-automation/` presence), so a Deployed-Skills copy — where `../../..` is `$HOME` —
  still falls through to the next resolution step rather than mis-resolving.

**Tests with literal paths or fixture trees (35 files)** — mechanical repoint, verified by running each:
`test/gh77-standup-triage.sh` (59 refs), `agent-chorus.sh`, `agent-chorus-bridge.sh`, `ci-route.sh`,
`find-harness.sh`, `gh396-find-harness-roots.sh` (builds fake harness trees at `$_live/skills/relay-xyz/`),
`hq-locator.sh` (fake harness at `$HARN/skills/hq/`), `path-integrity.sh` (`skills/relay-automation/` package
files + a `skills/pdda/SKILL.md` fixture literal allowlist), `gh660-skill-drift.sh` (throwaway canonical tree —
a **red control** for the two-level scanner: it must still detect drift on its own fixture),
`gh165-governance-canonical-paths-guard.sh`, `gh589-xyz-mini-sync.sh`, `gh620-skills-army-mini-sync.sh`,
`gh609-sdlc-agent-gaps.sh`, `releases-skill.sh`, `gh681-reviewer-probe-rules.sh`, `gh448-driver-lock-resolver.sh`,
`relay-pkg-freshness.sh`, `skill-extract.sh`, `gh346-gateway-allowlists.sh`, `gh292-worktree-vendored-discovery.sh`,
`relay-xyz-skill-guard.sh` (its command text is pinned in `relay-automation/hooks/security-scan-baseline.txt:41`),
`gh132-review-xyz-skill.sh`, `gh233-agent-chorus-concurrency.sh`, `gh267-express-skill.sh`, `gh278-turn-timeout-parity.sh`,
`gh284-p4-release-lanes.sh`, `gh369-find-doc-root-resolution.sh`, `gh393-deepseek-readiness.sh`, `gh400-source-url.sh`,
`gh534_phase_a_tests.py`, `gh549-work-events.sh`, `gh578-ci-optimize-skill.sh`, `gh589-skill-viewer.sh`,
`gh615-start-task-reinforce.sh`, `gh616-start-task-commensurate-envelope.sh`, `gh617-relay-xyz-commensurate-review.sh`,
`gh645-merge-cleanup-xyz-tools.sh`, `gh649-pdda-migration.sh`, `skills-army-hq.sh`, `test_deploy_skills.py`, `xyz-vendor.sh`.

**Docs that instruct (repoint) vs. docs that record (leave)**
- Repoint: `ARCHITECTURE.md` Skills Index (53 refs), `README.md` (install lines), `UPGRADE.md`, `AGENTS.md`,
  `SOP.md`, `HOW-TO-USE.md`, `ROUTER.md`, `WORKTREE-SAFETY.md`, `HARNESS-MODELS-REGISTRY.md`, `mini/README.md`,
  `relay-automation/DUELING-CLAUDES.md`, `ARCHITECTURE/README.md` + `skills-git-pulse-projection-diagram.json`,
  `validate.sh` comment lines, in-skill cross-references (`skills/*/SKILL.md`, `README.md`, `FRONTDOOR.md`,
  `skills-army-hq/references/recovery.md`, `agent-chorus/standalone/README.md` + `ci.yml`).
- Leave: `PROJECT/**` (captures/plans record the paths of their day; the active GH-484 deploy-skills
  doc is superseded on this point by this capture), `PAGES/skills.html` (generated site; regenerate
  only if `utils/py/site_build.py` reads `skills/` — it does not, it renders a static list).

**Machine-local, post-merge (not in the diff)**
- Skills Army HQ provenance records `source: <forge>/skills/<name>` per forge-owned skill. After the
  merge lands, the operator runs `intake.py --apply update <name> --source <forge>/skills/<tier>/<name>`
  per skill (or the recorded remedy from `sync.py`'s `WARN`). Documented in UPGRADE.md and the PR body.

Untraced: `.github/workflows/*.yml` and `githooks/*` contain no `skills/` references (grep-verified);
the `hq` subsystem's `utils/hq/*` was not read line by line beyond the grep (no `skills/` hits).

## Smallest affected surface

- 60 `git mv` operations + 4 new directories + one `skills/README.md` (tier contract, ~15 lines).
- 3 scanner/publisher edits (`skill_drift_check.py` glob → two levels while still accepting one level
  for XYZ-mini collections; `xyz_mini_sync.py` manifest sources; `ci-route.sh` globs).
- 9 locator edits (`../..` → `../../..`; two Python walk-ups).
- 35 test repoints; 1 security-baseline line.
- Doc repoints listed above; Skills Index regrouped.

Existing subsystems extended, no new writer: `skills/` stays the canonical home (GH-325);
`skill_drift_check.py` stays the single drift oracle (GH-660); `xyz_mini_sync.py` stays the single
publisher (GH-589/620); `ci-route.sh` stays the single routing registry (GH-35).

## Risks / rollback

- **Risk:** a locator mis-resolves one level off and a skill run from the repo silently uses the
  wrong harness. **Check:** each locator's own test (`find-harness.sh`, `hq-locator.sh`, `gh396`,
  `gh369`) plus `bash skills/1-hourly/relay-xyz/find-harness.sh --check` in the task clone.
- **Risk:** drift guard stops recognising forge skills (`unrecognized` for all). **Check:**
  `skill_drift_check.py --canonical <clone> --collection "~/Documents/Deployed Skills" --json`
  reports the same `ok`+`drifted` name set before and after the move (captured in the PR).
- **Risk:** ci-route mis-tiers a skill change. **Check:** `test/ci-route.sh` expectations repointed and green.
- **Risk:** vendored consumers (`.xyz/skills/<name>`) on other repos break at their next
  `xyz-vendor.sh` refresh. **Mitigation:** UPGRADE.md entry; the locator inside the vendored copy
  resolves `.xyz/` by marker, not by depth.
- **Rollback:** single revert of the PR merge commit; no data, ledger or schema change. Paired machine-local
  action if the Skills Army HQ provenance was already re-pointed: `intake.py --apply update <name> --source <forge>/skills/<name>`
  per forge-owned skill (the reverse of the post-merge step below).

## Test scope

In scope: every test file repointed above, run individually during implementation
(`bash test/<name>.sh`); `./validate.sh --auto` between review rounds; one full `./validate.sh`
(parallel) in a disposable clone on the final approved commit; `utils/pdda/pdda.sh run`.

Explicit non-scope: no new test framework, no synthetic layout fuzzer, no new test for the tier
folders beyond the acceptance one-liners in #744 (a `find` count and an empty one-level `find`),
which run inline in the PR evidence, not as a new suite.

## Ordered implementation (verification inline)

1. `git mv` all 60 skills into their tiers; add `skills/README.md` (tier list + lookup contract).
   → `find skills -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l` = 60; one-level find is empty.
2. `skill_drift_check.py`: glob `*/SKILL.md` **and** `*/*/SKILL.md` on the canonical side (mini
   collections stay one level) and key the `unrecognized` loop on the canonical name set, not a flat path.
   `test/gh660-skill-drift.sh` gains one tiered canonical skill in its fixture so the two-level branch is
   exercised (drift detected there too). → `bash test/gh660-skill-drift.sh` green (red control retained);
   live run against Deployed Skills lists the same names as the pre-move run.
3. `xyz_mini_sync.py` manifest sources → tiered paths. → `bash test/gh589-xyz-mini-sync.sh`,
   `bash test/gh620-skills-army-mini-sync.sh` green.
4. `ci-route.sh` globs → `skills/*/hq/*` etc. → `bash test/ci-route.sh` green.
5. Locators: bash `../..` → `../../..` (find-harness ×3, find-hq ×2, find-xyz ×2, find-pdda ×2,
   vendor-stack/install.sh, relay-to-issue.sh, make-pkg.sh incl. its tarball literal); find-xyz.sh:70 sibling
   glob; review_engine.py extra `dirname`; Python walk-ups (agent_chorus.py, scan_clones.py). → `bash test/find-harness.sh test/hq-locator.sh test/gh396-find-harness-roots.sh
   test/gh369-find-doc-root-resolution.sh test/agent-chorus.sh test/gh645-merge-cleanup-xyz-tools.sh`
   green; `bash skills/1-hourly/relay-xyz/find-harness.sh --check` resolves the clone.
6. `make-pkg.sh` re-run so `relay-pkg.tar.gz` manifest matches. → `bash test/path-integrity.sh
   test/relay-pkg-freshness.sh test/skill-extract.sh` green.
7. Remaining test repoints + security-baseline line + `repro.sh` + `publish-manifest.tsv` source column +
   `standalone/ci.yml` + `.gitignore` (`skills/browserbase/.env*`). → each repointed test green;
   `bash skills/2-daily/agent-chorus/sync-to-standalone.sh --check` finds every source.
8. Docs: Skills Index regrouped + 7 additions; README/UPGRADE/AGENTS/SOP/HOW-TO-USE/ROUTER/
   WORKTREE-SAFETY/HARNESS-MODELS-REGISTRY/mini README/in-skill refs. → `grep -rn 'skills/[a-z]'`
   over live docs returns only tiered paths; `utils/pdda/pdda.sh run` clean.
9. `./validate.sh` full in a disposable clone once on the final commit; CHANGELOG entry.

## Rating (2026-09-21, provisional until plan QA)

`rated 55/25/50/45`

- **sev 25** — no defect, no data at risk; consequence of leaving it is navigation friction and a
  stale, incomplete Skills Index.
- **pri 55** — above severity-led ordering because the operator asked for it now and chose the
  physical layout knowing the alternative; nothing is blocked on it.
- **appeal 50** — neutral; no operator score given.
- **effort 45** — mechanical but wide (≈80 files, 35 tests, one full gate); not a quick win, not a rewrite.
- **Recurrence** — not a bug class. Same-topic history: GH-325 (2026-08-30, made `skills/` canonical)
  sits outside both 14-day windows (2026-09-07→09-21 and 08-24→09-07: no skills-layout issues either
  window; `gh issue list --search "skills folder OR organize skills OR skills index"` on 2026-09-21).
- **Uncertainty** — the tier placement of ~50 non-anchored skills is judgment; cheap to re-tier.
