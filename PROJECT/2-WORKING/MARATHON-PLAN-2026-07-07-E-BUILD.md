---
title: Marathon Plan E (2026-07-07) — acorn-integration + aider-turn.sh + hq-resolve bugfix cluster
status: 4 of 5 lanes shipped (PR #179, merged 2026-07-08) + #168's own follow-up (#186) — only #186 still fireable
created: 2026-07-07
updated: 2026-07-08
owner: noel
branch: main
doc_type: project
source: hand-curated — GH-163's acorn verdict (build follow-through) + a live aider-turn.sh bug found via a `.xyz`-vendored relay run in the pdda repo + a hq_repo_resolve dedup gap found live via GH-158 + a GH-168 follow-up found live reviewing its own fix (775380c)
generated_by: hand-authored (5 lanes, same-day + next-day intake, not ledger-ranked)
lanes: [159, 168, 169, 175, 186]
execution: Antigravity agent and sub-agents (Gemini), original 4 lanes; #186 not yet assigned
roadmap_exempt: true
goal: >
  Five build lanes. **#159, #168, #169, #175 already shipped together via PR #179** (merged
  2026-07-08, `39729a0`): the hq_repo_resolve dedup fix, the aider-turn.sh gitignore flag fix, the
  acorn+acorn-walk vendoring, and the #173 Phase-1 low-fruit slice. **#186 is a same-day follow-up**
  found reviewing #168's own fix after PR #179 landed: `775380c` (a later, separate commit on a
  different branch) dropped the same flag PR #179 had just added, because it turned out obsolete on
  the locally-installed aider version — verified only against that one version, so a vendored
  install on an older aider could silently regress. #186 is the only lane still open/fireable here.
---

# Marathon Plan E — 2026-07-07 · acorn-integration + aider-turn.sh + hq-resolve bugfix cluster

> Sibling of [Plan D](MARATHON-PLAN-2026-07-07-D-EXPLORE-IDEAS.md) (same-day explore cluster,
> GH-161..164) but a different shape: all lanes here are **build** lanes — real code changes
> with tests, not doc-only Phase 0 exploration.

## Status

| What was just completed | What's next |
|---|---|
| **All four original lanes (#159, #168, #169, #175) fired and shipped together as PR #179 "Marathon Plan E Build", merged to `main` 2026-07-08 (`39729a0`)** — confirmed in the working tree: `src/acorn-extract.js` present (#169), `hq_xyz_lookup`'s `seen_coords` dedup present (#159), `relay-automation/consult.sh` attestation parsing present (#175's A3), and #168's original `--add-gitignore-files` fix landed (then separately revisited — see below). Note: issues #159/#169/#175 are still **open** on GitHub despite the merge — not yet closed out. Reviewing #168's merged fix surfaced a live version-drift risk 2026-07-08 (aider upstream had since dropped the flag PR #179 added), fixed ad-hoc via `775380c` on an unrelated branch, and filed as **#186** — the only lane in this doc still open/fireable. | **Close out #159/#169/#175 on GitHub** (code already shipped) — operator call, not automatic. **Fire #186** — the version-drift follow-up, not yet built. |

## Why this cluster, why now

- **#168** (aider-turn.sh gitignore bug) surfaced live during a real relay run in a `.xyz`-vendored
  install of this harness (pdda repo) — a small, real, already-diagnosed bug with a one-line fix
  direction. Cheap to land immediately rather than let it sit.
- **#169** (acorn first-pass integration) is the natural build follow-through on GH-163's verdict
  (MIT license, zero deps, real-world tested) — wiring the dependency in now, while it's still a
  small additive unit, de-risks GH-156's later Phase 1 work.
- **#159** (`hq_repo_resolve` dedup) was captured a day earlier (2026-07-06, found live via GH-158's
  `marathon-scan.sh` dogfood run) but never got a local doc, so it sat in the held/`needs-doc`
  list. A repo-state audit surfaced it as small, real, and root-caused enough to fire today rather
  than stay parked.
- **#186** (aider-turn.sh vendored-install version drift) surfaced live 2026-07-08 while reviewing
  #168's own fix commit (`775380c`, a later commit on a different branch than PR #179): that commit
  dropped `--add-gitignore-files` because it's obsolete on the locally-installed aider version, but
  the flag's *presence* was #168's original fix (PR #179) for a different, vendored install running
  a different aider version. Same file, same bug family, real risk of silently reopening #168 on
  any vendored consumer that hasn't upgraded aider — cheap to make version-aware now while the
  context is fresh.

All lanes surfaced from real dogfood/field use of the harness, not speculative work; none depended on
each other and each touched an entirely different file. **#159/#168/#169/#175 are historical record
below (shipped via PR #179) — #186 is the only lane with any remaining collision surface, and it has
`aider-turn.sh` entirely to itself since #168 already landed.**

## The one safety rule

Two lanes are safe to run concurrently **iff their write-sets are disjoint**. Trivially true here:

## Collision map

| Zone (shared file) | Parallel-safe? | Lanes |
|---|---|---|
| `relay-automation/aider-turn.sh` (+ its test) | ✅ **#168 already shipped** (PR #179) — #186 has this file to itself now | **#168** (shipped), **#186** (open) |
| new dependency + new utility module (package.json, new file, its test) | ✅ **#169 already shipped** (PR #179) | **#169** (shipped) |
| `utils/hq/hq-lib.sh` (+ its test) | ✅ **#159 already shipped** (PR #179) | **#159** (shipped) |
| `README.md` + headless bring-up docs + `relay-automation/consult.sh` (+ its test) | ✅ **#175 already shipped** (PR #179) | **#175** (shipped) |

Historical: no two lanes ever shared a write-set, so all four fired in parallel in PR #179 without
collision. **The only remaining open work is #186**, and it has `aider-turn.sh` entirely to itself
(#168 already landed). It doesn't touch the relay kernel (`relay-turn-lib.sh`), containment, or
tick — zone `shim`, not `kernel`.

## Per-lane summary

| # | Item | Deliverable | Write-set | cx/risk/eff |
|---|------|-------------|-----------|-------------|
| #159 | `hq_repo_resolve` dedup | ✅ **Shipped** (PR #179, `39729a0`) — dedup-by-resolved-path in `hq_xyz_lookup`, confirmed live in `utils/hq/hq-lib.sh` | `utils/hq/hq-lib.sh` (+test) | 2/1/2 |
| #168 | aider-turn.sh missing `--add-gitignore-files` | ✅ **Shipped** (PR #179), then the flag was found obsolete and dropped again via a separate later commit (`775380c`) — see #186 | `relay-automation/aider-turn.sh` (+test) | 1/1/1 |
| #169 | Acorn first-pass integration | ✅ **Shipped** (PR #179) — `src/acorn-extract.js` + `acorn`/`acorn-walk` deps confirmed live | new dependency entry + new utility module + test | 2/1/2 |
| #175 | #173 feedback Phase-1 low-fruit | ✅ **Shipped** (PR #179) — B4/D2/A3 confirmed live in `README.md` + `relay-automation/consult.sh` | `README.md` + bring-up docs + `relay-automation/consult.sh` (+test) | 2/1/2 |
| #186 | aider-turn.sh vendored-install version drift on the gitignore flag (follow-up to #168) | **Not yet built.** Version-aware flag detection/guard + extended regression test | `relay-automation/aider-turn.sh` (+test) | 2/2/2 |

## Recommended waves

**This marathon is effectively closed except for one lane: #186.** #159/#168/#169/#175 shipped
together in PR #179 and need no further firing — only a GitHub close-out (operator call).

**Wave 1 — solo:** #186 (no concurrent lane touches `aider-turn.sh` now that #168 has landed). No
kernel track — #186 doesn't touch containment, tick, or the relay kernel core.

## Execution contract

- **Path:** #186 fires as a worktree-isolated build/review turn (Codex or agy, per `marathon-drive.sh`
  `--reviewer`), scoped via `ALLOW_PATHS`/`--artifact` to `relay-automation/aider-turn.sh` +
  `test/aider-turn.sh` only.
- **Per lane:** complete the doc's Phase 0 checklist and QA checklist in place, land the change with
  a passing regression test, and leave a one-line status update in the doc's own Status table.
- **#186 stays scoped to version-safety of the gitignore flag only** — do not use it as an
  opportunity to re-audit `aider-turn.sh`'s other flags; land it on top of #168's already-shipped
  state (PR #179 + the later `775380c` revision), not as a revert of either.
- **Rated:** all lanes carry provisional cx/risk/eff in their own doc frontmatter (`ratings_
  provisional: true`) — same-day/prior-day intake, not yet validated against `pdda.sh doc-ready`.

<details>
<summary>Historical: #159/#169/#175's own execution-contract scope notes (already shipped, PR #179)</summary>

- **#169** stayed scoped to infra-only — did not wire into GH-156's active code path; that's gated
  on GH-156's own Phase 0 scoring-contract decision, separate unresolved work.
- **#159** stayed scoped to the dedup fix only — did not refactor `hq_xyz_lookup`/`hq_repo_resolve`
  more broadly; the genuine-collision disambiguation path (Blocker 1) still works unchanged.
- **#175** stayed scoped to its three named sub-items only (B4 docs, D2 docs, A3 attestation
  parse) — did not touch the design-heavy #173 items (B1/B2/B3/A1/A2/A4), which stay parked in
  `PROJECT/2-WORKING/GH-173-JEDI-WRIGHT-FEEDBACK.md`.

</details>

## How to fire

```
utils/swarm-preflight.sh --gh-issue 186   # or --project-doc PROJECT/2-WORKING/GH-186-*.md
   → ready packet (candidate/freshness/fix-still-required + lane assignment)
relay-automation/marathon-drive.sh --phase-brief <brief.md> --reviewer <codex|agy> \
  --artifact relay-automation/aider-turn.sh,test/aider-turn.sh --relay-task MARATHON-GH186-TURN
   → build→gate→review, contained
```

GH-186's doc carries a `Swarm Preflight Contract` JSON block and was promoted to `PROJECT/2-WORKING/`
(`swarm-preflight.sh` requires the capture doc under `2-WORKING/`, per `GUIDING-PRINCIPLES.md` §11).

#159/#168/#169/#175 are already shipped (PR #179) — no preflight/fire needed for them.

---

*Source docs:* [GH-159](GH-159-HQ-REPO-RESOLVE-DEDUPE.md) ·
[GH-168](GH-168-AIDER-TURN-GITIGNORE-BUG.md) ·
[GH-169](GH-169-ACORN-FIRST-PASS-INTEGRATION.md) ·
[#175 → parent GH-173](GH-173-JEDI-WRIGHT-FEEDBACK.md) ·
[GH-186](GH-186-AIDER-VENDOR-VERSION-DRIFT.md) ·
sibling: [Plan D](MARATHON-PLAN-2026-07-07-D-EXPLORE-IDEAS.md) · [PR #179](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/179).
