---
title: "Marathon plan — GH-497: make the roadmap ledger's state trustworthy"
status: Active (2-WORKING)
created: 2026-09-07
updated: 2026-09-07
owner: noel
umbrella: 497
marathon_gid: mar-01M1ZPJKHC6N2SMP8KYBZYF8JB
clone: XYZ-forge-marathon-ledger-trust (dedicated full clone, sibling of the primary checkout)
lanes: 3
waves: 3
roadmap_exempt: true
goal: run marathon #497 (GH-491, GH-492, GH-355) to completion in strict wave order, landing each lane's PR before the next lane starts
---

## Status

| What was just completed | What's next |
|---|---|
| Lane C (#355) built by codex, reviewed by agy, approved; migration verified in place (`doc_lines.updated_at` present); gate held on two of this plan doc's own defects (missing frontmatter, no Status table) — fixed in place, not attributed to the lane | Confirm the gate is green with these fixes, close out phase gh355-p1, land lane C's PR, then run lane A (#491) |

## Why these three

One seam, three halves of the same failure: `roadmap_items` cannot be trusted to reflect reality.

Measured on 2026-09-07 (`11d3e77d`): **33 of the ledger's non-Completed rows had a closed GitHub
issue**, the oldest closed 13 days earlier. While stale, `releases_app.py next` recommended
GH-204, GH-205 and GH-243 as upcoming work — all three finished for nearly two weeks. The cost is
not an untidy table; it is a planning surface confidently proposing completed work.

| Lane | Issue | Owns | Doc |
|---|---|---|---|
| A | #491 | The **write path** accepts values the renderer drops | `PROJECT/2-WORKING/GH-491-ROADMAP-SECTION-VALIDATION.md` |
| B | #492 | Nothing **converges** state for issues closed outside a merged PR | `PROJECT/2-WORKING/GH-492-ROADMAP-STATE-SWEEP.md` |
| C | #355 | No **change substrate** — 12 of 14 tables have no `updated_at` | `PROJECT/2-WORKING/GH-355-UPDATED-AT-MIGRATION.md` |

B is the payload. A and C are its preconditions: a sweep that writes sections is unsafe while the
write path accepts unrenderable values, and expensive while nothing records change.

## Waves — strictly serial

```
W1  C (#355)   invasive migration, ~144 write sites. Alone in its wave, own gate, own PR.
W2  A (#491)   section vocabulary + validation; moves ledgerSections to a shared source.
W3  B (#492)   the sweep, on A's validated vocabulary and C's updated_at.
```

Serial, not parallel. All three touch `utils/py/releases_app.py` in different regions
(migrations / argparse+validation / a new subcommand), so concurrent lanes would collide on one
file for no schedule gain — and the driver lock serializes lanes within a clone regardless.

#355's own issue notes it is *"independent of everything already landed"* and can land in any
order. It takes W1 anyway because it is the riskiest change and benefits most from an empty
in-flight queue.

## Collision map

| File | A (#491) | B (#492) | C (#355) |
|---|---|---|---|
| `utils/py/releases_app.py` | argparse help + `--section` validation | new `roadmap reconcile-state` verb | migration 007 + ~144 write sites |
| `utils/roadmap-dashboard.sh` | `ledgerSections` becomes shared | — | — |
| `utils/py/wave_reconcile.py` | — | reuses `fetch_issue_state` | — |
| `utils/pdda/pdda.sh` | — | section-drift warning | — |
| `releases.sql` / `releases.db` | — | — | schema + backfill (orchestrator_only) |
| `test/gh32-releases-app.sh` | — | — | round-trip cases ported |

**The one real seam is `ledgerSections`.** A moves it to a single source the CLI and renderer both
read. B must land after that, because a sweep validating against a second copy of the list
reintroduces exactly the drift A closed.

## Preflight status — verified in this clone

`bash utils/swarm-preflight.sh --gh-issue N --dry-run` → **exit 0 for all three** (491, 492, 355),
against `development @ 66130821`.

Two contracts were wrong on the first pass and are worth recording, because both failed *silently
in the direction of looking fine*:

- **`"type": "grep"` is not a probe type.** The valid set is `path_absent`, `path_present`,
  `grep_present`, `grep_absent`, `command` (`utils/py/swarm_preflight.py:208-233`); anything else
  hits `else: verdict = "blocked"`. Lanes A and C both read BLOCKED until corrected to
  `grep_present`.
- **C's first probe could never flip.** It grepped `releases.sql` for `CREATE TABLE doc_lines`,
  which is as true after the migration as before. Worse, `updated_at` already appears **152 times**
  in that file because `roadmap_items` is one of the two tables that has it — so no file-level grep
  discriminates here. Replaced with a `command` probe that asks the schema directly whether
  `doc_lines` has the column, `expect_nonzero: true`, verified `rc=1` against the live ledger.

A probe that cannot flip is worse than no probe: it reports "unfixed" forever and the lane never
registers as done.

## Held / flagged

- **Do not port** `parse_roadmap_ledger` / `cmd_roadmap_sync` from
  `fix/gh351-gh349-releases-ledger-fixes`. That is the rejected GH-349 half, superseded by #350,
  carrying a **silent-wipe defect on a 0-byte `ROADMAP.md`**. Pulling it in would add a data-loss
  path to the subsystem this marathon exists to make trustworthy.
- **Not in scope:** the six lanes of the #490 ledger-flip marathon (#418, #421, #423, #424, #425,
  #454), carried by PR #495. Separate cluster.
- **#446** (`marathon_plan.py` writes an unprompted plan file) was considered as the third lane and
  rejected: it is already claimed by marathon #462.

## Ledger registration

```
marathon  mar-01M1ZPJKHC6N2SMP8KYBZYF8JB   tracking #497   status=planned
roadmap   rmi-01M1ZPPHM8Y4N6YXBXY1FB54KE   GH-491
roadmap   rmi-01M1ZPPHVJ3BXMNPB1QJ5SJ9X8   GH-492
roadmap   rmi-01M1ZPPJ2JYV2F6ZWCKB7CX4C6   GH-355
```

`releases check` clean (0 failures). The 8 `mig-ref-stale` warnings and 24 pending grandfather
entries are pre-existing migration debt, untouched here.

## Running a lane

```bash
cd XYZ-forge-marathon-ledger-trust    # the dedicated full clone for this marathon
bash utils/swarm-preflight.sh --gh-issue 355        # writes the packet
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-355-updated-at-migration \
RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md --reviewer agy --builder codex
```

This clone is dedicated to the marathon so it holds its own `.git/relay-driver.lock` and does not
contend with the primary checkout or with #495's lanes.
