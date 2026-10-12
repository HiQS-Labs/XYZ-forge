---
title: "Weekly ledger integration and shared boundaries — Recon Map"
status: Reference
created: 2026-10-12
updated: 2026-10-12
owner: Codex
doc_type: reference
roadmap_exempt: true
goal: Ground remaining W7–W11 owner changes without inventing another backlog or approval authority.
---

# Recon Map — ledger integration and shared boundaries

## Status

| What was just completed | What's next |
|---|---|
| Four read-only lanes expanded the existing map's integration, caller, contract and failure cutoffs. | Settle the canonical preservation transaction and its supported merge shapes before implementation planning. Remaining approval/budget/custom-consumer cutoffs stay explicit. |

Source: 7214ed3c0c6dc0e8503ff6e44a4d099a7f78c072. Root confirmed that revision and clean state before lanes; subsequent 232c292a/437462a4 changes are documentation/evidence only. Mode: grep-only/direct reads; no graph tools exposed. Lanes A entry/calls, B state/data, C contracts, D failure/operations ran concurrently, read-only, each bounded to about eight minutes. No suites, fixtures, network, Git mutations, approval review or writes by lanes. This expands [the earlier map](recon-remaining-boundaries.md); it is not a plan or operational qualification.

## Subject and authority

Remaining weekly reconciliation/rollover, authoritative proposal, immutable freeze/exact consent and shared fire/phase/resume/landing are cross-module and state/contract changes. RELEASES remains the authoritative ledger. Existing drivers/tokens/peer attestations remain their own owners; real human consent remains separate. Proposed accounting/freeze/prior-art records are views/audit/evidence, not a second backlog, coordinator framework or new consent source. The user selected this ownership in #1022. A proposal to elevate a new store into authority would require a fresh authority decision; none is made here.

## Call paths and seams

| Seam | Confirmed source | Consequence |
|---|---|---|
| Weekly core entry | planner_core.py:1365,1387,1400,1410–1413; weekly/SKILL.md:89,158,170 | Discovery/census/preparation exist. Reconciliation/publication/rollover modes do not. Daily/weekly outlines and 10days remain separate callers of the same core. |
| Preparation commit | planner_core.py:977,1155,1187–1217,1338–1355 | Private intent and clone lock, canonical rows/generation/captures, staged objects and completed checkpoint are real effect boundaries; no-change retains prior cut/commit. |
| Planner/proposal | marathon_plan.py:165,192,197; _marathon_plan.py:766,802,865,910,1037,1064–1173 | Authoritative rank/render/waves exist; bare-number identity, informational missing dependencies and deferred packing are not strict qualified readiness. Dry rendering is removed, normal output is written. |
| Preflight/artifacts | swarm_preflight.py:1084–1116,1705–1725,1825 | Pure structured invocation builder is not authorization; deep preflight and actual packet writes have their own owner. Dry packet mode does not write packets, but other preflight Git effects remain as earlier map documents. |
| YAML transport | marathon_yaml_emit.py:71,135,171,226–244,288; bin/marathon-yaml:14,72,81,99,105,123 | Existing emitter/validator own constrained dependencies/order and a closed phase-field set. Emitter/Jog allow gemini, validator codex/agy only. New receipt/budget fields require explicit compatible transport or schema disposition. |
| Launcher/driver entry | marathon.sh:423,631–717,740–770,793; marathon_drive.py:1126,1127,3334–3376 | Configurable executables, direct native entry and every phase are real routes below weekly. Whole-run closeout differs from per-phase open-only publication. |
| Approval effects | marathon_drive.py:2465–2467,2652–2666,2668–2758,2861–2863 | Already-satisfied startup reaches success effects. Arbitrary post-approve Bash runs before candidate rebind; a guard afterward cannot prevent its external effects. |
| Jog paths | releases_app.py:5187–5225,7127–7129; jog_run.py:547–609,651–700,707–848 | Run/build retry dispatch; resume only reprojects/parks history. Gate retry has transcript advancement semantics. Do not apply a fire check indiscriminately to harmless projection, but guard optional landing effects. |
| Landing/publication | jog_run.py:356–421,1430–1462; marathon-closeout.sh:185–207,250–294 | Jog merges exact head with peer binding. Standalone closeout commits/pushes before PR/CI/merge; launcher and direct closeout are independent effect sites. |

Paths are repo-relative: core/intake under skills/3-weekly/weekly-planner/scripts; Python owners under utils/py; launcher/closeout under relay-automation. Every cited seam was read, not inferred from a graph.

## Canonical ledger state and preservation

`releases_app.py:1099–1284` owns logical serialization, GID references, ratings/status/raw/first_seen fields, ordered receipts and event GID/transaction/payload/history. Physical IDs are regenerated; device-local connector cursors are omitted; Jog lease PID is serialized NULL. Preservation means logical owner/history identity, not identical SQLite bytes or a transferable live lease.

Canonical parser/merge-damage validator/loader (`:6197,6226,6290,6440,6479,6490`) retain row order and restore logical identities/FKs. The merge-damage check is not a general source validator. `_rebuild:6497–6611` consumes a judged dump, restores registry migrations, advances generation and appends merge-rebuild; it never decides whose rows survive.

Existing B1 (`skills/2-daily/merge-cleanup/scripts/ledger_merge.py:42,170,294,477–595`) excludes receipts/events from comparison and replays through verbs. Canonical additions mint new row/event IDs (`releases_app.py:3674,1603,1620`); original label/full first_seen/accepted-start history is not supplied by replay. B1 cannot satisfy weekly preservation unchanged. Resolver (`utils/releases-merge-resolve.sh:108,139,148,161,226`) enforces parent generation/rebuild/verify/views/staging after row-survival judgment; it cannot provide that judgment.

Ordinary writes (`releases_app.py:346–381,1662–1780,1903–1939`) use the shared Git-common-dir fcntl lock, audit and journal → transaction → staged outputs → rename → clear. Pre-commit errors roll back; committed interruption retains recoverable intent. `cmd_check:5918–5955,6129` can recover a prior journal and writes lock audit; it is not a pure read.

Rebuild is materially different: it overwrites the fixed .bak, swaps DB before dump rewrite and creates no rebuild intent (`:6603–6611`). Earlier temporary construction failures clean only the temp DB. B1's second rebuild can overwrite the first backup; success deletes it. Treating this as the ordinary journaled transaction would be false. New reconciliation must preserve existing backups and use a supported canonical transaction/recovery path or hold; no weekly SQL writer or unreviewed generic resolver.

Root follow-up read: `perform_write:1702–1707` invokes `_sync_status_labels:1646–1659` after mutation, preserving the old row's label or NULL for a new GID. An imported accepted-start row therefore needs an explicit canonical preservation disposition; a clear/reload proposal must not silently strip incoming owner labels. `perform_write:1684` computes next generation from current DB, so a merged higher-generation target likewise needs an explicit floor. These are planning cutoffs, not implemented repairs.

## Coordination, consent and bounds

Weekly private owner/receipt/lock and committed intake paths (`planner_core.py:1013–1015,1133,1155`) serialize one clone. Target advance or preexisting remote auto-date branch currently holds (`:1029,1040,1052,1126`). Shared preparation ownership, branch adoption/publication/rollover are not implemented. Declared roots/context census (`:857–899`) is held; absent contexts do not prove global idle.

Shared driver lock (`rtl.py:966; marathon_drive.py:1270`) scopes to a clone family/vendor root, uses local PID stale-owner handling and is not fleet coordination. Observer write actions (`marathon.sh:109,365–402`) persist attribution/liveness, not consent. Peer attestation (`relay_drive.py:694–755; relay_attest.py:195–318`) witnesses reviewer role, done token, exact review bytes/HEAD/repository/isolation and permitted candidate changes. It does not witness human firing approval.

YAML round fields are not a total budget: launcher maps two review rounds to five driver turns; relay extensions can reach twice the initial cap (`marathon.sh:684; relay_drive.py:771,1136`). Driver may run another relay pass during timeout recovery (`marathon_drive.py:3438–3507`). Gate budgets are separate (`:853,876,2347,2409`); arbitrary post-approval hook lacks its own timeout; cost summary is optional observational reporting (`:1729–1736`). No strict whole-run monetary ceiling is established.

## Concrete compatibility boundaries and rollback

- GH544 shared closeout deliberately accepts no-checks results (`marathon-closeout.sh:259,269`), with existing positive assertions (`test/gh544-pre-push-gate.sh:688,696`) and real-failure refusal at703. Weekly required-CI policy must be explicit. Do not silently weaken tests or overwrite this standing shared policy.
- Historical Jog resume fixture J1 (`test/gh280-jog-marathon-adapter.sh:752–777`) seeds an old result without new prior-art/plan fields and proves no new dispatch. Mandatory fire receipts cannot be blindly demanded for reconciliation-only projection. Optional merge still crosses landing authority.
- Direct gate-only re-fire fixtures (`test/gh491-gate-only-refire.sh:48,77,102,111`) use a plain brief and pin retry/satisfied-no-new-turn semantics. Receipt rollout must account for these callers, not hide bypasses or change their assertions to retain green.
- Existing timeout restoration (`rtl.py:304–388`) stops the captured group and preserves edits/ref history; moved start refs require manual recovery. Driver documents a partial-artifact seam/frozen Bash divergence (`marathon_drive.py:3469,3474`); #752/#1020 remain explicit open holds, not repaired by this map.
- Relay/unmapped Python changes require existing full classification (`utils/ci-route.sh:342–350`). No new test/case/parameter/registry or gate is authorized. Existing/manual controls retain source-bound negative evidence. Every individual proposed CI addition needs its own actual operator approval.

At map creation, the normal gate is a live delivery dependency: first7214 full408/409 + Python21 passed, PDDA missing recon Status table failed both retries. Owned doc fixed232c; existing PDDA noerrors48warnings; normal437 retry underway. This is not an overall green claim or permission to waive a gate. Source-approved Phase7/R6/Phase6 history remains immutable.

## Unknowns

| Unknown/cutoff | Why it matters | Settling evidence |
|---|---|---|
| Full supported append-only/disjoint merge shapes, nullable/defaulted fields and schema variants | Parser/rebuild alone cannot guarantee exact owner/history preservation. | Complete canonical dump/load/schema and row-for-row roundtrip/refusal controls before the owner API plan; preserve unknown/deletion/reference conflicts. |
| Safe preservation transaction, status-label maintenance and generation floor | Ordinary writer is journaled but currently assumes existing rows/next local generation. | Trace explicit merge operation through perform_write, label/event/check/recovery readers; support only a bounded proven shape. |
| Human confirmation origin/storage | Self-authored JSON/peer PASS cannot create human consent. | Actual trusted human confirmation flow and explicit caller transport before mechanical binding; no new auth source silently introduced. |
| Full tick persistence and downstream turn/shim/plugin graph | Token/attestation contradiction must hold every applicable route. | Read tick and relay turn/shim owners plus configured consumers; graph absent is not proof of absence. |
| Shared coordinator and unobserved roots | Local locks/PIDs cannot guarantee one global writer/Marathon. | Explicit caller-authority roots and existing-owner coordination contract; missing/foreign/ambiguous roots hold. |
| Required-CI names/source and global compatibility | Current standing NoChecks policy and weekly unknown/missing-required holds differ. | Explicit packet/caller policy and documented shared-policy disposition; no inferred defaults. |
| Strict qualified planner projection/dependencies/cycles, YAML numeric edges | Current bare-number/advisory interfaces cannot authorize selection. | Read complete loader/packing/parser consumers and constrained fixture semantics before changing those owners. |
| Total time/cost enforcement across recovery, gates, hooks and provider adapters | Per-invocation limits and optional summary are not approved total bounds. | Complete routing/accounting/custom-command reads plus caller-declared policies; unavailable evidence remains held. |
| Arbitrary custom executables and downstream installations | Environment overrides escape repo-owned code paths. | Declared executable bytes/roots/actual consumers; unsupported routes hold rather than implying universal enforcement. |

Current-state radius: canonical RELEASES logical rows/events/receipts/recovery and weekly/daily/10days readers; authoritative planner/preflight/YAML and wave reconciliation; launcher/native and frozen driver, relay/tick/turn supervision, Jog projection/retry/landing, closeout/custom hooks and existing covering CI. External/provider/deployed consumer behavior remains outside this read-only trace.
