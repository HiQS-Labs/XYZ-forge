# Recon Map — Git Sync Pulse as a Skills Army HQ distribution projection

Commit: XYZ Forge `48c1d3446c6fc71fb83c7eccb9d55bb4bc68c7b2`; rebalanceOS
`ed320289f78abe2e5f0228457a95b07a614c2d00`; live pulse checkout
`19600a83d82f9c6b01913b0643a5b08d888c89be` · Mode: grep-only + direct reads ·
Lanes: A–D, serial (subagent delegation was not requested)

## Subject and change class

Subject: use the existing private `Hypercart-Dev-Tools/rebalance-git-pulse` remote to
make one selected Skills Army HQ inventory available across Macs.

Change class: state/authority change if the Git repo replaces the local collection;
cross-repository contract change if it is only a portable projection.

## Authority classification (spike-360)

**Authority level: Read projection — recommended.** The Git-backed folder carries a
portable skill bundle or manifest, but each machine's Skills Army HQ collection remains
the source of truth for deployed payloads and links. This is Easy to undo: stop consuming
the projection and the current local collection keeps working.

**Real problem:** reproducing one selected inventory on another Mac required manually
mapping 15 names to local repositories, retyping eight prerequisite notes and recreating
targets. **Smallest fix:** #506's portable collection import/export, with the private pulse
remote as one optional transport location.

**Overbuild:** putting the live collection itself inside the hourly pulse checkout, adding
another background updater, or teaching the pulse collector to own Skills Army HQ state.
That would promote the Git checkout to a source of truth/replacement runtime and couple app
discovery to unrelated scheduled Git writers.

**Stop / Go:** go only with a projection first. A direct authoritative relocation requires
a separate approval and a design for cross-machine writer ordering, device-local metadata,
dirty-checkout recovery and rollback.

## The seams — where a change here escapes this file

| Seam | Location | Crosses | Breaks if |
|---|---|---|---|
| Collection authority | `PROJECT/2-WORKING/GH-484-DEPLOY-SKILLS.md:115-119` | selected payloads → all enabled consumers | two stores can independently claim the desired payload |
| Local source intake | `skills/skills-army-hq/scripts/intake.py:180-195` | local Git skill folder → copied payload receipt | projected folders are not inside a Git repo or name/digest validation changes |
| Root identity | `skills/skills-army-hq/scripts/intake.py:232-265` | absolute collection root → metadata and manager links | metadata is copied to a machine with a different root or manager link |
| Inventory authority | `skills/skills-army-hq/scripts/intake.py:268-280` | real immediate folders → desired skill set | a partial checkout looks like intentional deletion |
| Transaction boundary | `skills/skills-army-hq/scripts/intake.py:469-527` | pending receipt → payload, state, targets, catalog, history | Git observes or syncs the collection mid-transaction |
| App deployment | `skills/skills-army-hq/scripts/sync.py:23-65` | local collection → absolute app-root symlinks/ownership receipts | another device's targets or receipts are imported as local truth |
| Pulse repo contract | `~/.config/git-pulse/repo/AGENTS.md:3-30` | multiple scheduled producers → generated-data `main` | operator-managed files are treated as ordinary source without a writer policy |
| Pulse collector pull/write | `rebalanceOS/experimental/git-pulse/collect.sh:475-480,561-601` | shared checkout ↔ origin | tracked skill payloads are dirty when `pull --rebase` starts |
| Pulse publisher | `rebalanceOS/scripts/pulse_sync.sh:40-72`; `rebalanceOS/src/rebalance/ingest/pulse.py:797-874` | Rebalance DB → `live-pulse.md` commit/push | an unrelated writer leaves the checkout dirty or conflicted |
| Existing dirty-tree incident | `~/.config/git-pulse/repo/AGENTS.md:76-119` | third-party local write → hourly reconciliation | a tracked projection is changed but not committed before the next job |

## Call paths in

### Skills Army HQ today

```text
conversation / copied manager
  -> intake.py parser (--root defaults to ~/Documents/Deployed Skills)
     [intake.py:551-568]
  -> add/update -> source_record -> git rev-parse + status + digest
     [intake.py:180-195,631-649]
  -> transact -> pending receipt -> actions -> state/targets/catalog/history
     [intake.py:469-527]
  -> sync.py reconcile -> target × inventory desired set -> owned symlink actions
     [sync.py:23-65,107-156]
  -> configured agent applications read through absolute directory symlinks
     [skills/skills-army-hq/SKILL.md:12-25,76-90]
```

### Git Sync Pulse today

```text
launchd com.user.git-pulse (hourly)
  -> installed ~/bin/git-pulse
  -> collect.sh loads ~/.config/git-pulse/config.sh and takes collect.lock
     [collect.sh:7-17,317-325]
  -> scans watched repo reflogs
     [collect.sh:369-452]
  -> self-heals + pull --rebase
     [collect.sh:475-480]
  -> writes/stages only pulse, device, snapshots and PDDA projection paths
     [collect.sh:454-571]
  -> commit + push; one pull/rebase retry
     [collect.sh:572-601]

launchd com.rebalance-os.pulse-sync (hourly daytime)
  -> scripts/pulse_sync.sh -> reconcile_pulse_mirror
     [pulse_sync.sh:40-61; pulse.py:65-87]
  -> publish_pulse -> write/add/commit/push live-pulse.md
     [pulse.py:949-1020,797-874]
```

No current entry point reads, exports, stages or deploys a `skills/` subtree.

## State

Skills Army HQ has a single local writer implementation (`intake.py`, imported by
`sync.py`) and stores:

- real payload folders as the desired set (`intake.py:268-280`);
- absolute root, collection UUID, source paths/digests and owned-link receipts in
  `.deploy-skills.json` (`intake.py:232-252`);
- absolute, device-specific target roots in `targets.json` (`intake.py:198-229`);
- a local advisory lock and recoverable pending transaction (`intake.py:283-302,519-527`);
- retained `.staging`, ZIP backups, catalog and append-only changelog
  (`intake.py:305-390,502-516`).

The live tested collection contains 15 skills, eight prerequisite notes and 45 healthy
managed links; it is 756 KiB. Payload size is not the hard part. The metadata is: copying
it creates shared collection identity and machine-specific paths.

Git Sync Pulse `main` is a 45 MiB private generated-data checkout with multiple independent
scheduled writers. Its collector stages a bounded path list, not arbitrary root changes
(`collect.sh:561-572`). A new `skills/` path therefore has no writer today. More importantly,
an uncommitted tracked modification can prevent the pre-write `pull --rebase`; this exact
failure previously repeated for 229 hourly runs (`git-pulse AGENTS.md:76-119`).

## Contracts

| Contract | Consumer | Breaking if | Declaration |
|---|---|---|---|
| Actual valid immediate skill folders are desired | intake, sync, apps | projection is incomplete or partially pulled | `skills/skills-army-hq/SKILL.md:84-90` |
| Local Git repositories only | intake | a bundle is copied outside a Git checkout | `SKILL.md:76-82`; `intake.py:180-195` |
| Exactly two mutation tools; no background updater | operator/recovery model | Git transport logic is added as a third writer | `skills/skills-army-hq/SKILL.md:18-25`; `PROJECT/2-WORKING/GH-484-DEPLOY-SKILLS.md:83` |
| Root and targets are local | state validator, app roots | another device's absolute values are consumed | `intake.py:198-252`; `SKILL.md:76-78` |
| Pulse `main` is generated data with multiple producers | scheduled fleet jobs | human-managed deployment state shares their checkout | `git-pulse AGENTS.md:3-30` |
| Collector owns a bounded stage set | pulse sync repo | arbitrary skill changes are expected to auto-publish | `collect.sh:561-572` |

## Build, failure and rollback today

Skills Army HQ previews by default and uses digest-checked staging, atomic payload/link
replacement, checksummed pending receipts and verified ZIPs (`SKILL.md:40-52`;
`intake.py:305-340,393-527`). Its existing tests cover detached copied operation, source
validation, root overlap, target deduplication, foreign-entry preservation, selected source
migration, lock refusal and crash recovery (`test/test_deploy_skills.py:84-113,232-376,406-433`).

Git Sync Pulse has hourly jobs that reconcile and push. It can repair a non-fast-forward,
but intentionally refuses destructive reset in the current publisher
(`pulse.py:845-915`). Its rollback is Git history, but a dirty or rebasing live checkout can
stop every later run. Therefore the live `~/.config/git-pulse/repo` checkout must not become
the HQ collection or an uncoordinated payload writer.

The safest projection rollback is deletion of an isolated consumer checkout/config entry;
the already-deployed local collection and app links remain intact.

## Ponytail — lightest implementation worth testing

1. Do not relocate `~/Documents/Deployed Skills` and do not change either launchd job.
2. Use the existing private remote only as transport, through a separate clean checkout from
   the live pulse-writer checkout. Store only portable `skills/<name>/` payloads plus one
   generated manifest; exclude targets, ownership receipts, locks, staging, ZIPs and history.
3. Pull explicitly, then use the existing `intake.py add/update --source
   <checkout>/skills/<name>` and `sync.py` workflow. The source already satisfies the local-Git
   contract without any new downloader (`intake.py:180-195`).
4. Start manual. If the proof is too cumbersome, extend #506 with one stdlib export/import
   operation. Do not add a daemon, watcher, database, new repository, or Git implementation
   inside Skills Army HQ.

One small fixture test is enough: three skills, two simulated homes, different absolute
paths, and one conflicting update. Pass means the second collection reaches the same payload
digests while its local target/ownership state remains distinct and the live pulse checkout
stays clean.

## Unknowns

| Unknown | Why it matters | What would settle it |
|---|---|---|
| Should the shared artifact contain payload bytes or only source repo+commit references? | bytes work without every source clone; references avoid duplication | three-skill two-device fixture comparing operator steps and offline behavior |
| Is operator-managed `skills/` acceptable in the generated-data remote, even from an isolated checkout? | current repo policy says it holds generated data only | explicit owner decision or keep the content as a generated HQ export |
| Which device wins when two operators publish different versions of one skill? | a projection still needs deterministic conflict handling | choose single publisher initially; add no merge automation until a real second-writer need exists |
| Do all target applications refresh after a local import without restart? | transport success is not discovery success | app-by-app picker/refresh observation, already separate under Skills Army HQ's target contract |

## Current-state radius, one line

The proposed transport touches Skills Army HQ's 15 local payload copies, per-device target and
ownership metadata, 45 current app symlinks, the private Git Sync Pulse remote, and two independent
hourly Git writers across three Macs; the read-projection design keeps only the portable payload
selection on the cross-device side of that boundary.
