---
gh_issue: 484
source: https://github.com/HiQS-Labs/XYZ-forge/issues/484
title: Deploy Skills
status: In progress — plan QA; implementation not started
created: 2026-09-07
updated: 2026-09-07
owner: Codex
goal: Manage a durable copied skill collection and global app links through conversation.
doc_type: plan
branch: feat/deploy-skills
reversibility: Costly — selected global skill behavior changes together; ZIP backups and exact link receipts bound rollback.
effort: 3
complexity: 3
risk: 3
phases: 4
---

# Deploy Skills — Build Plan

## Status

| What was just completed | What's next |
|---|---|
| Requirements confirmed, issue registered, initial recon recorded | First plan QA with Agy through relay-xyz; implementation remains unstarted |

## Table of contents

- [Requirements and design](#requirements-and-design)
- [Phase 1 — Collection and conversational skill](#phase-1--collection-and-conversational-skill)
- [Phase 2 — Managed sync and recovery](#phase-2--managed-sync-and-recovery)
- [Phase 3 — Alpha deployment and dependency proof](#phase-3--alpha-deployment-and-dependency-proof)
- [Phase 4 — Final QA, PR and immediate teardown](#phase-4--final-qa-pr-and-immediate-teardown)
- [Acceptance evidence](#acceptance-evidence)
- [Review and checkpoint](#review-and-checkpoint)

## Requirements and design

The user wants to talk to an agent in their existing VS Code extensions and agent apps to manage one durable collection of globally available skills. `skills/deploy-skills/SKILL.md` is the conversational interface, not a new VS Code extension. Two deterministic Python scripts perform intake/catalog maintenance and symlink synchronization. Current request is to write this plan and QA it with Agy first; code and live installation come after that checkpoint.

### Folder and ownership contract

Default runtime root is the user's Documents directory plus `Deployed Skills`; explicit `--root` supports redirected Documents or another user-chosen location. Use runtime home/Documents discovery, never a committed username or personal absolute path. macOS is the tested alpha; configurable paths and stdlib Python enable other devices without claiming untested Windows/Linux support. If a platform cannot create directory symlinks, fail with the capability error; do not silently copy into app folders.

```text
Documents/Deployed Skills/
  catalog.md                 generated inventory; not hand-edited deployment authority
  changelog.md               append-only operation history, UTC timestamps
  targets.json               editable enabled target roots and consumer labels
  .deploy-skills.json         schema version, collection identity, source receipts, owned links
  backups/<skill>-yyyy-mm-dd.zip
  intake.py                  convenience link to deploy-skills/scripts/intake.py
  sync.py                    convenience link to deploy-skills/scripts/sync.py
  deploy-skills/SKILL.md
  deploy-skills/scripts/intake.py
  deploy-skills/scripts/sync.py
  <selected-skill>/SKILL.md
  <selected-skill>/scripts/... references/... assets/...
```

Only two Python implementations ship. `intake.py` owns collection mutation, metadata persistence, locking, catalog and history helpers; `sync.py` imports those shared helpers and owns the link reconciliation algorithm. Entrypoints resolve their physical script directory before importing so root convenience links and arbitrary CWD work. No third CLI, daemon, DB, network registry, auto-updater, or shell implementation. Helpers may be factored within the two files; no generic plugin architecture.

Actual valid immediate skill folders are the desired set. Metadata records provenance and link ownership, not a competing list overriding folders. `targets.json` is the target configuration authority. `catalog.md` is rebuilt from the validated folders plus receipts, sorted by canonical skill name; include name/description, relative folder, original local source, import commit if available, content digest, imported/updated UTC time, and per-target status. Personal paths belong only in local outputs. A manual folder addition is adoptable after validation; an unexplained removal requires an explicit removal preview/apply before pruning links. Missing/unreadable collection or corrupt metadata is an error, not an empty desired set. Intentional removal of the final skill requires explicit empty-set authorization. Keep deploy-skills available until its own removal is explicitly requested; self-removal uses the already loaded tool and reports loss of conversational discovery.

### Conversation and command surface

Examples the skill must route: “Deploy recon from this repo,” “Update my deployed consult,” “List my deployed skills,” “Add Antigravity as a target,” “Refresh all links,” “Remove swe from global deployment,” and “Show what changed.” Show resolved source, destinations, collisions and changes in ordinary language. Translate requests to the same two scripts; never emit ad hoc filesystem mutation commands or execute an imported install.sh. Normal authorized user requests can apply after their concrete preview is inspected by the agent; ambiguous source/name collisions ask one targeted question.

Proposed commands: intake `init`, `add <local-folder>`, `update <name> [--source <local-folder>]`, `remove <name>`, `catalog`, `list`, `targets`; sync `preview`, `apply`, `status`. Mutations accept explicit `--apply`, and `--dry-run` is strictly read-only including no directory/log/lock creation. No import from a URL, package registry or ZIP in v1; Git is read-only provenance for local repository sources. No source repo modification. Initialize includes deploying the manager's own complete folder and default-disabled target presets, then enables selected targets in local configuration. Targets changes flow through intake so history and locking are consistent, but direct valid JSON edits are detected on the next run.

### Intake, archives and safety

Read and validate the whole candidate before touching the deployed copy: nonempty regular SKILL.md with required name/description frontmatter; normalized safe folder name matching skill name; reject path separators, traversal, reserved control names, case-fold duplicate names, FIFOs/devices/sockets. Resolve the source to an existing local Git repository folder and record dirty status/content hash rather than claiming HEAD represents dirty bytes. Preserve regular resources, executable modes and internal relative symlinks only when they remain within the skill folder; refuse external, absolute, dangling or cyclic payload links with a concrete diagnostic. Do not dereference outside the selected folder or silently omit resources. Inspect symbolic source aliases before resolving them, show the resolved source, and prevent source/destination overlap.

Before any update replaces an existing folder, create a ZIP in backups with the old full folder and metadata for permissions/symlinks; validate its members and CRC and verify content hashes against the old folder. First name is `<skill>-yyyy-mm-dd.zip` using UTC; subsequent same-day backups use `-02`, `-03`, etc., exclusive creation and never overwrite. Archive failure, source mutation during copy, or failed validation leaves the old deployment untouched. Stage on the same filesystem, then swap with recoverable old-folder staging; retain the ZIP. Removal also archives before withdrawing a folder. Updating deploy-skills itself uses the same protocol and restores the prior manager on failure.

Use one exclusive local operation lock shared by both scripts; busy means exit with owner/operation information, no automatic retry or stale-lock theft. Refuse overlapping collection/target roots, root symlink aliases and symlinked target roots/ancestors that redirect outside the explicitly selected root; canonicalize to deduplicate targets that legitimately share a physical directory. Validate at every mutation boundary with lstat/realpath containment; never recursively delete an app target. Real target directories are never replaced. A link conflict is an explicit blocked result, not success.

### Sync, provenance and interrupted operations

For every enabled target, create `<target>/<skill>` as a directory symlink to the durable copy. An already correct owned link is a no-op. A correct but unowned link needs explicit adoption before ownership is recorded. A conflicting real folder or unrelated symlink is preserved and reported. The alpha may explicitly migrate a matching selected legacy source link after preview; preserve its old link text in the receipt so rollback can restore it. No force-overwrite fallback.

Only remove a stale link when the ownership receipt identifies this collection and lstat/readlink still match the recorded link and destination. If a user retargeted it, preserve it and report lost ownership. Handle removed/disabled targets using their previous receipts; do not drop receipts until cleanup succeeded. Recreate desired owned links removed externally. Deduplicate shared Codex roots to avoid duplicate operations/discovery. One target failure need not prevent independent successful targets, but aggregate a nonzero partial-failure result with exact counts and retained receipts. Preview and status report missing source prerequisites separately from link status.

Before each operation, persist an atomic pending receipt containing operation ID, expected pre-state and intended post-state. After disk/link changes, atomically publish metadata/catalog and append one deduplicated changelog record through the shared writer; record failures/partial outcomes truthfully. On restart with pending state, inspect actual folders/link text and either finish the known operation or restore the staged prior state. Never infer ownership from a pathname alone. Corrupt receipt/config/history tail or unexpected external changes stop mutations and give a specific recovery action; list/status may report the problem. An empty or unreadable registry never authorizes cleanup. Changelog entries record init/import/update/remove/target changes/sync, source digest/commit where relevant, backup location, link changes and errors; no success entry for a preview/no-op. History is audit, not replay authority.

### Recon, reuse and alternatives

See [Recon Map](GH-484-DEPLOY-SKILLS/recon-deploy-skills.md), pinned to origin/development `2e4f8d48831b2265a29eeaca8ce93a61bc39e386`. Existing installers implement folder symlinks but replace unrelated entries; scaffold sync explicitly excludes installation. Therefore reuse folder layout and failure reporting patterns, not those mutation functions. Extend existing locator environment/caller-repo support for runtime prerequisites; do not invent a runtime path registry or silently bundle the harness. New files stay inside `skills/deploy-skills/`, with a focused Python test under `test/` and narrow start-task documentation alignment. Use existing test/test_python_layer.py discovery entry to invoke the new tests or explicitly register a test-only launcher after reading that integration surface; do not assume arbitrary Python files run under validate.sh.

Alternatives ranked: (1) requested actual-copy collection plus managed symlinks; (2) links directly to maintained repos, simplest but does not survive source relocation; (3) separate app copies, which multiply drift; (4) full package/runtime manager, which adds unrequested distribution scope. Strongest counterargument to (1): copied skills with source-relative runtime dependencies can become discoverable but unusable. Phase 3 must expose and prove these prerequisites; no blanket “portable skill” claim.

Authority classification from spike-360: user-approved source of truth for deployed payloads, catalog read projection, changelog audit-only. Readers: apps/agents and two CLIs. Writers: intake and managed sync through shared persistence; external users/installers are detectable conflicting writers. Resting state is validated folders/receipts; transient state is staging/pending receipt. Cold init must never adopt arbitrary preexisting contents destructively. Crash before write leaves old state; crash after payload swap or link mutation resolves through pending receipt; concurrent tools refuse via lock; corrupt/empty inputs refuse rather than replay. No dual-written peer, background event system or automatic upstream update is introduced.

### Blast, rollback and rating

Costly: replacing a selected skill changes all enabled consumers at once. Radius is the collection, backups, managed app links and selected skill runtime behavior. Shield: preview, one-skill alpha then full selection, verified ZIP and owned-link comparisons. Tripwire: backup verification failure, changed pre-state, unresolved dependency, wrong read-through digest or missing app discovery stops that rollout before further targets. Rollback restores the verified archived folder plus recorded old link text, then regenerates catalog/history; no source repository rollback needed. Removing the task clone is Easy only after remote refs/evidence and absence of depended-on local state are verified; otherwise preserve it and report the blocker.

RELEASES read-back: `rated 72/58/50/55` (priority/severity/appeal/cheapness), no override. Rationale dated 2026-09-07: current user-requested multi-app workflow is actionable; stale/broken skill availability creates workflow disruption but no new observed data-loss incident; appeal is neutral 50 as policy; two scripts are small but safe mutation and payload portability make delivery moderate. Recurrence search covered 2026-08-25–09-07 versus 2026-08-11–24: related #396 addresses root resolution; #458/#463 concern symlink test paths and may overlap, not confirmed deployment incidents. Search results do not establish a frequency trend; trend unknown. Scores assess supported consequences, not invented incident counts. PDDA effort/complexity/risk fields are separate metadata. Do not expand AGENTS.md or enforce speculative SOLID abstractions for this feature; apply its current durable/reversible/DRY contract and responsibility separation within these two tools.

## Phase 1 — Collection and conversational skill

**Goal:** A copied deploy-skills bundle can initialize and manage a local collection through its two Python entrypoints and agent instructions.

1. Implement SKILL.md and intake.py plus sync.py's shared-helper import; bootstrap the complete manager, root convenience links and configurable targets -> expect operation from a neutral CWD with the source clone absent.
2. Implement local add/update/remove, archive verification, metadata, generated catalog and append-only changelog under one lock -> expect old content survives deliberate copy/ZIP failures and repeated same-day updates preserve every archive.

### QA checklist

- [ ] DRY/responsibility check: one persistence implementation; no copied installer mutation code or new dependency framework.
- [ ] Empty/malformed input, name collision, external/cyclic links and overlapping roots refuse without changing prior files (A1–A3).
- [ ] ZIP restore verifies bytes, relative links and executable permissions; self-update remains runnable (A2).
- [ ] Errors name the operation/path/cause; previews do not write; debug-mantra is used for implementation failures.
- [ ] No remote deploy in this phase; no actual alpha app directories touched.

## Phase 2 — Managed sync and recovery

**Goal:** Desired copies reconcile into configured targets without damaging unrelated entries and with resumable receipts.

3. Implement preview/apply/status, owned-link create/adopt/migrate/remove and independent-target result aggregation -> expect exact link sets and idempotent second run (A4).
4. Implement pending operation recovery and shared changelog/catalog finalization -> expect interruption after each mutation boundary resolves truthfully, concurrent calls refuse, and stale/corrupt inputs cannot authorize pruning (A5).

### QA checklist

- [ ] Ownership/collision/retarget/disabled-target tests prove preservation via pre/post hashes and link text (A4).
- [ ] False empty scans, denied reads, malformed config and altered receipt fail closed (A3/A5).
- [ ] No speculative interfaces; common rules remain shared; partial success is distinguishable from full success.
- [ ] Mutation tests demonstrate the guards fail for the right reason; committed evidence is specified below.

## Phase 3 — Alpha deployment and dependency proof

**Goal:** The operator's selected collection is visible and usable in the requested consumers with runtime limitations honestly reported.

5. Resolve current local sources, list every intended skill and prerequisite, verify current official/local discovery support, and record local source/target configuration -> expect no personal configuration committed (A6).
6. Preview and deploy manager plus one simple skill, then the full alpha after that succeeds. Import relay-xyz, consult, marathon-triage, marathon-cleanup, unstuck, swe, ponytail, recon, daily, workhorse, merge-cleanup, start-task, debug-mantra -> expect copies and links point only to the stable collection, with ZIP-backed migration of selected existing entries (A6).
7. Exercise conversational list/import/update/preview/remove on a harmless fixture; verify each consumer's discovery and a bounded read-only invocation, then runtime-dependent skills from a neutral CWD with explicit stable prerequisites. Update start-task's installation guidance narrowly to accept this deployment option -> expect no global shell startup rewrites and no unrequested dependency installation (A7).

Candidate roots from existing repo instructions, **pending current consumer verification**: Claude `~/.claude/skills`; Codex `~/.codex/skills` and shared `~/.agents/skills` (choose verified shared discovery without duplicate names); Antigravity `~/.gemini/antigravity/skills`; Zcode `~/.zcode/skills`. App/extension labels may map to one physical root. Do not enable obsolete Gemini paths merely because an installer lists them. Custom targets remain supported with an unverified consumer label. Record app version, discovery path and evidence; a directory existing is insufficient.

Daily source is rebalanceOS `.agents/skills/daily/`; personal references stay in its private copied payload. Unstuck may be copied from its existing local branch checkout after recording exact dirty state/hash/commit; no forced merge or checkout. Marathon-related means the two actual marathon skill folders found in recon. Additional referenced skills are reported as prerequisites, not silently imported. Use the existing XYZ_HARNESS override scoped to commands/agent instructions and the maintained primary harness; caller .xyz is also supported. Deploy-skills's own agent instructions consult local source receipts for these prerequisites without rewriting imported payloads. Daily requires its Rebalance context. If a consumer cannot expose skills or a payload requires unavailable runtime context, leave that alpha check blocked; filesystem success is reported separately.

### QA checklist

- [ ] Alpha inventory contains all 14 named folders including deploy-skills; every source is local and no private payload/config enters the repo diff.
- [ ] Every app/extension has discovery evidence or an explicit blocker; shared directories are deduplicated (A6/A7).
- [ ] Imported files remain byte-faithful; runtime dependencies are visible; missing dependencies never become a successful usability claim.
- [ ] A selected conflicting legacy symlink migrates only after concrete preview; unrelated app entries are unchanged.

## Phase 4 — Final QA, PR and immediate teardown

**Goal:** Verified implementation and evidence are available on origin, with the task clone retired immediately afterward.

8. Run focused tests and required full macOS gate in a separate disposable full clone; bracket repository identity before/after. Run PDDA and final relay QA on the final committed artifact, using Agy for this first plan review and the start-task default Codex for final implementation unless user changes it -> expect applicable gates green and an Approved verdict with a valid driver result (A8).
9. Push through the required gate from a disposable push clone, open/verify the PR against development, its exact SHA, diff scope and checks, retaining required evidence. Once properly QAed and PR is on origin, immediately inventory task clone refs/stashes/worktrees/processes/ignored valuable state and deployed-link dependencies, preserve required evidence, and move the verified disposable clone to Trash -> expect task path absent and remote branch/PR recoverable (A9). Do not merge. A real cleanup blocker prevents teardown and is reported, never overridden.

### QA checklist

- [ ] Required tests/review are on final artifact revision; no stale approval or empty transcript (A8).
- [ ] Review and dogfood findings are resolved within this same scoped feature; a broader defect is recorded and the affected criterion blocks instead of silently growing scope.
- [ ] PR exists on origin; clone-local unique/depended-on state is zero before teardown; running reviewer/gate processes have ended (A9).
- [ ] Durable collection and read-through hashes still work after teardown; backups are retained locally and recovery location is reported.

## Acceptance evidence

Proposed focused suite: `python3 -m unittest discover -s test -p 'test_deploy_skills.py'`; validate its integration rather than assuming discovery. Use isolated temporary homes/repos/targets, no live app folders in automated tests. Commit nonempty results plus `provenance.jsonl` under `TESTS-RESULTS/2026-09-07+GH-484/`. Each receipt names command, artifact SHA, platform, actual exit status and evidence file. Red controls are **planned, not yet run**. Tests call real CLI paths, inspect filesystem bytes/links and compare independent expected outcomes; they do not merely check log wording.

| ID | Pass evidence | Red control and destination |
|---|---|---|
| A1 | Detached copied bundle initializes/list/catalog from alternate home and CWD; manager discovered via SKILL.md | Remove a required sibling resource; nonzero actionable result. `a1-portability.log` |
| A2 | Update/removal archive round-trip bytes/modes/internal links; two same-day updates yield distinct ZIPs; old state on failure | Inject archive write/copy failure and invalid CRC; compare old digest and link text. `a2-backups.log` |
| A3 | Strict read-only preview, valid nonempty intake, containment on source and targets | Empty/malformed SKILL.md, traversal/reserved/case names, denied scan, external symlink and cycle all refuse. `a3-containment.log` |
| A4 | Exact desired symlink set, no-op rerun, receipt-based deletion, disabled target cleanup | Retarget one owned link and place a real collision; both preserved, nonzero result. Bypass ownership guard in disposable mutation -> test fails. `a4-ownership.log` |
| A5 | Recovery after payload swap/link write/metadata publish/history append; busy lock refuses | Kill fixture operation at each boundary; corrupt receipt and history tail; no false successful state/prune. `a5-recovery.log` |
| A6 | All 14 named alpha folders and target mapping, hashes, local receipts | Omit debug-mantra or point one target at wrong payload; independent inventory check fails. `a6-alpha-redacted.log` |
| A7 | Per-app discovery and agent conversational management observed; runtime prerequisites exercised | Remove fixture prerequisite or manager link; do not report usability success. `a7-consumers-redacted.log` |
| A8 | Focused tests, full gate, PDDA, committed relay Approved on final revision | Nonzero/empty/missing-verdict fixture is rejected as QA evidence. `a8-qa.log` |
| A9 | Remote PR/SHA and evidence verified; task path retired; stable copies still usable | Fixture clone with unique commit/stash/active process/dependent link is preserved. `a9-teardown-redacted.log` |

Public evidence redacts personal source paths/content while retaining skill names, counts, hashes, exact command structure, statuses and version facts. Do not commit imported private daily contents or local target configuration. ZIPs remain local. This is not a new long-horizon marathon; no synthetic workload is needed.

## Review and checkpoint

First review: Agy via shipped relay-xyz, review-only ALLOW_PATHS, committed plan/recon in the isolated task clone; three review rounds maximum. Questions must include a dedicated omission-diff against every user requirement plus ownership/crash/portability scrutiny. Record each proposal's evidence and disposition; revise and re-review up to Approved, otherwise report the exact blocker. Plan approval is textual evidence, not implementation correctness.

Current checkpoint: plan authored; first Agy review pending. Implementation, actual collection, backups and live app links are not yet built. The user's immediate-teardown instruction applies when the reviewed branch and PR are on origin; do not discard unpushed plan/review evidence merely to satisfy a folder-cleanliness claim.
