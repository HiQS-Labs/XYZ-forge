---
gh_issue: 508
source: https://github.com/HiQS-Labs/XYZ-forge/issues/508
title: "Git Sync Pulse as a portable Skills Army HQ projection"
status: Active (2-WORKING — spike complete 2026-09-09, all acceptance PASS; PR pending)
created: 2026-09-08
doc_type: plan
effort: 2
complexity: 3
risk: 2
phases: 1
ratings_provisional: true
---

# GH-508 — Git Sync Pulse skills projection

## Quad Concepts

- Manual second-device reconstruction → carry only a portable skill projection through the existing private remote.
- Shared live-checkout authority risk → retain device-local HQ authority and use an isolated explicit-import checkout.

## Verdict

Explore the existing private Git Sync Pulse remote only as an optional read projection / transport.
Keep every device's local Skills Army HQ collection authoritative. Do not relocate the collection
into the scheduled live pulse checkout and do not introduce another background writer.

Reversibility is **Easy** for this projection: deleting the isolated consumer checkout leaves the
local collection and deployed app links intact. Promoting the pulse checkout to deployment authority
would instead be **Costly** and is outside this capture.

## Actionable scope

1. Use a separate clean checkout of the existing private remote, not the checkout used by scheduled
   pulse writers.
2. Project three portable `skills/<name>/` payloads plus one generated manifest; exclude collection
   identity, targets, ownership receipts, locks, staging, backups, and history.
3. Import explicitly through the existing Skills Army HQ `add` / `update` and `sync` paths.
4. Designate one publisher for the spike; add no merge automation, daemon, watcher, database, new
   repository, or Git implementation.
5. If manual import remains cumbersome, route the smallest export/import improvement to GH-506.

## Acceptance criteria

- [ ] Two simulated device homes with different absolute paths import identical payload digests for
      three skills while retaining distinct local targets and link-ownership receipts.
- [ ] A conflicting update follows the initial single-publisher rule.
- [ ] The scheduled live Git Pulse checkout remains clean and unchanged.
- [ ] Removing the projection leaves both local collections and their deployed links functional.
- [ ] The spike records whether payload bytes or source-repo-plus-commit references are lighter and
      whether offline import is a real requirement.
- [ ] If operator-managed content is incompatible with the generated-data remote's contract, stop.

## Recon

The deep end-to-end trace, authority classification, failure paths, rollback, and Ponytail reduction
are recorded in [RECON-GH-508-GIT-PULSE-SKILLS.md](RECON-GH-508-GIT-PULSE-SKILLS.md).

Related: GH-506 (replication/import UX) and GH-484 (original local deployment system).

## Status

| What was just completed | What's next |
|---|---|
| Spike complete: all 6 acceptance criteria PASS in disposable fixtures (evidence table below); findings recorded; row text updated | Final relay QA, PR, and the #506 verb recommendation handoff |

## Recon addendum (2026-09-09, spike session)

- Live writer: `~/bin/git-pulse`, hourly launchd `com.user.git-pulse`, config `~/.config/git-pulse/config.sh`. Remote: `Hypercart-Dev-Tools/rebalance-git-pulse`. Live checkout `/Users/noelsaw/git-pulse-sync` — untouchable; baseline at spike start: `main...origin/main`, tracked tree clean, pre-existing untracked `pdda/registry-*.tsv` + `xyz/`, HEAD `277a339f`.
- Writer stages only the pulse file, `devices/<id>.yaml`, metadata rel paths and `snapshots/` via pathspec-bounded `git add`; a `skills-projection/` path is invisible to it. Its pre-write `pull --rebase` coexists with foreign commits on `main`.
- `intake.py` accepts any local Git repo as source (the projection checkout qualifies). Digest contract: `intake.snapshot`/`intake.digest` — the manifest generator imports these rather than reimplementing.

## Spike plan (acceptance mapping)

1. Separate clean clone of the private remote -> "live checkout clean" acceptance.
2. Project exactly `unstuck`, `ponytail`, `debug-mantra` as payload bytes under `skills-projection/skills/<name>/` + generated `manifest.json` (digest via imported `intake.digest`, per-file sha256, source repo+commit). No receipts, targets, backups, or collection identity.
3. Two simulated homes in /tmp via `--root`: `init`, `add` x3, one distinct fake target each, `sync --apply` -> identical payload digests, distinct targets/ownership.
4. Conflict demo: rival edit commit, then the designated publisher's next projection overwrites wholesale; import is explicit-pull. No merge machinery.
5. Delete the projection checkout; homes and links still functional -> removal reversibility.
6. Findings: bytes-vs-refs operator cost, offline import, #506 recommendation.

## Non-goals (hard)

- No verb/daemon/DB added to skills-army-hq in this PR; repo-side change is docs-only.
- The real `~/Documents/Deployed Skills` root and real IDE targets are never touched — all receiving sides run under `--root` fixtures.
- Plan-QA stage skipped (reason recorded): the plan is the issue's own acceptance list; final relay QA still applies.

## Rating note

The DB rating (2/3/2/1, parked 2026-09-08) stands. This session's operator request is an ordering
signal, not a re-score; per the rating policy the stored axes stay honest and a rank override
would be the operator's explicit choice.

## Spike results (2026-09-09, fixtures under /tmp/gh508-spike.*)

| # | Acceptance criterion | Result | Evidence |
|---|---|---|---|
| 1 | One publisher, three skills; two homes, different absolute roots, identical payload digests, distinct targets/ownership | **PASS** | Projection commit `2a200a72`; `unstuck` 0ea0342209bb / `ponytail` bb7d6011af07 / `debug-mantra` 0e6830b300b6 identical across home-a, home-b, and manifest. Targets `sim-home-a`/`sim-home-b` at different paths; each home's deployed links resolve into its own root. Source provenance (same projection commit in both receipts) is shared by design — that is the transport contract, not drift. |
| 2 | Conflicting update has a deterministic single-writer policy; no auto multi-writer merge | **PASS** | Rival edit pushed (`d1ed5fe0`, ponytail digest 015601761a61); designated publisher's next projection (`0db1e88d`) overwrote the whole tree; home-a explicit `update ponytail --source` returned **Unchanged** (canonical digest restored). Import side only ever pulls; nothing merges. |
| 3 | Scheduled live Git Pulse checkout clean and unchanged | **PASS** | `/Users/noelsaw/git-pulse-sync` before and after: tracked tree clean, same untracked writer exhaust (`pdda/registry-*.tsv`, `xyz/`), HEAD `277a339f`. The writer stages only pulse/devices/metadata/snapshots via pathspec-bounded `git add` — `skills-projection/` is invisible to it. The remote already carries other foreign non-pulse commits (`chore(sleuth)` publishes), so coexistence is established behavior, not a novelty. |
| 4 | Removing the projection checkout leaves local collections and links functional | **PASS** | Projection + rival checkouts removed (renamed `*.removed`); both homes re-verified: all digests intact, links resolve, `sync` reports zero errors. |
| 5 | Record bytes-vs-refs cost and offline answer | **PASS** | Findings below. |
| 6 | Operator-managed content acceptable in the generated-data remote? | **YES, with a namespaced path** | Precedent: the remote already hosts operator-tooling publishes. The projection is one removable path; the pulse writer's contract is untouched (pathspec staging verified). Stays the operator's standing policy call. |

### Findings

- **Payload bytes beat source-repo+commit refs** at skill scale: bytes import offline after one
  clone/pull, need no per-source-repo access or network, and digest equality is direct. Refs would
  shrink transport but require every private source repo reachable at import time and add one
  `add --source` per repo — strictly more operator steps for KB-scale payloads.
- **Offline import matters and works**: after `git clone` / `git pull` of the projection, all
  adds and sync run with zero network.
- **Operator cost at 3 skills**: clone, pull, 3× `add --source`, 1× `targets`, 1× `sync` ≈ 7
  commands. At the real 15-skill inventory this is ~19 — cumbersome enough that #506's smallest
  stdlib verb (`import-projection <path>` looping the existing add) is justified; per this issue's
  scope, no verb was added to skills-army-hq here.
- **Remote end-state**: `main` carries the demo history (`2a200a72` publish → `d1ed5fe0` rival →
  `0db1e88d` designated re-publish); tree state is the designated publisher's. History rewrite was
  deliberately NOT performed — the hourly writer rebases onto this branch and a force-push would
  wedge it (the 229-run incident class from the issue). Full removal of `skills-projection/` is one
  ordinary commit if the operator wants the remote pristine.
