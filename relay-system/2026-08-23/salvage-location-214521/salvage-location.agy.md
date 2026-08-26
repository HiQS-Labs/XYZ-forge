Here is my independent analysis based on the repository state and the constraints provided.

### 1. ANSWER
The marathon-cleanup SOP should store salvage data in a gitignored `.marathon-salvage/` directory at the root of the primary repo to evade the GH-141 sweep hazard, though replacing salvage entirely with a "merge-before-delete" gate is the operationally superior choice.

### 2. FINDINGS
- **[Blocker] Outside the repo (`~/marathon-clones/`)**: Inherently undiscoverable. No system or agent knows to look there, risking permanent data abandonment.
- **[Blocker] Inside the primary repo in tracked folders (`relay-system/` or `marathon-system/`)**: Fails the GH-141 hazard check. Untracked files dropped here will be destructively swept or reverted by `rtl_enforce` if a driven turn runs in the primary clone. It also dirties the working tree and risks accidentally committing binary `harnesses.db` blobs to git history.
- **[Blocker] `.tick/orphan-backups/`**: Confirmed unsuitable by construction. This directory lives at `$RTL_ROOT/.tick/orphan-backups/` (as implemented in `relay-automation/relay-turn-lib.sh:rtl_orphan_backup()`). Because it resides *inside* the clone, it is destroyed when the clone is `rm -rf`'d, failing the core requirement that data must survive teardown.
- **[Should] Replace salvage entirely with a "merge-before-delete" SOP gate**: This explicitly should replace salvage entirely. "Salvage" is deferred technical debt that invites bit rot. Forcing the operator to merge telemetry and generated docs directly into the primary clone *as a blocking condition* before deleting the disposable clone eliminates dangling state and the need for a salvage directory entirely.
- **[Pass] A gitignored directory in the primary repo (e.g. `.marathon-salvage/`)**: If deferred salvage is strictly necessary, this is the only safe location. `rtl_enforce` uses `git status --porcelain -z` without the `--ignored` flag, making gitignored files completely invisible to the GH-141 sweep hazard. Discoverability must be guaranteed by adding an explicit pointer to this directory in `skills/marathon-cleanup/SKILL.md`.

### 3. RECOMMENDATION
Replace salvage entirely with a strict "merge-before-delete" SOP gate; if deferred salvage is unavoidable, use a gitignored `.marathon-salvage/` directory in the primary repo with a pointer in the `marathon-cleanup` skill doc.
