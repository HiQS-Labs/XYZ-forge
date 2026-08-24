# Consult synthesis — clone-teardown salvage location

**Run:** salvage-location-214521 · codex + agy, both answered · reconciled by Claude (coordinator), with the operator's XYZ-Transcripts candidate folded in post-fan-out.

## TLDR

Both models independently rejected every in-repo tracked location and `.tick/orphan-backups/`; both want merge-before-delete as the primary gate. They split on where the fallback salvage lives — codex: host-owned `~/.xyz/salvage/` with a manifest/index; agy: gitignored `.marathon-salvage/` inside the primary repo. **Call: outside the repo, per codex — but at the operator's renamed `~/Documents/GH Repos/XYZ-Transcripts/salvage/` rather than a hidden dotfolder**, keeping codex's manifest + fail-closed index and merge-first gate.

## Disagree (adjudicated)

1. **Fallback location.** codex: `~/.xyz/salvage/<repo-id>/<marathon-id>/<clone>/` (outside every git tree, per-device hierarchy). agy: gitignored `.marathon-salvage/` at the primary repo root — technically safe from the GH-141 sweep (`rtl_enforce` reads `git status --porcelain` without `--ignored`, so ignored files are invisible to it). **Adjudication: codex.** agy's mechanism claim is correct but the location is fragile anyway: it requires a `.gitignore` edit in every clone generation, is invisible to humans (hidden + ignored), and codex cites a real past failure of repo-local scratch leaking into a PR (`AGENTS.md:150-160`). Outside-repo survives any clone-level operation by construction.
2. **Does merge-before-delete replace salvage?** agy: yes, entirely — salvage is deferred debt. codex: merge-first is the happy path, but salvage stays as the mandatory, hash-verified fallback for failed/deferred imports. **Adjudication: codex.** A gate with no failure buffer forces either unsafe deletion or indefinite clone retention when a merge can't run (today's case exactly: the merge decision is blocked on the PR #199 disposition).
3. **Visible folder vs dotfolder** (operator candidate vs codex). codex's `~/.xyz/` is hidden; the salvage is operator-facing — a human must remember to merge it. **Adjudication: operator's candidate.** `~/Documents/GH Repos/XYZ-Transcripts/` (renamed from `Agent2Agent-Transcripts`) is an existing, tooling-known, outside-repo XYZ host-state root, resolved via the `~/.config/xyz/agent2agent-home` pointer — human-visible where `~/.xyz/` is not. Mechanical discoverability comes from the skill pointer + index either way, so the visible root costs nothing.

## Agree (cross-model, high confidence)

- `.tick/orphan-backups/` unsuitable by construction — inside the clone, gitignored, dies with `rm -rf` (`relay-turn-lib.sh` rtl_orphan_backup).
- Never a tracked in-repo path (`relay-system/`, new top-level folder): GH-141 sweep hazard on driven turns, tree-dirtying, and binary `harnesses.db` blobs risk entering git history.
- Merge-before-delete is the preferred path; the marathon-cleanup SOP must gate deletion on it.
- Discoverability must be mechanical (skill doc pointer + index), not a README hope.
- codex extras worth keeping: don't use `.xyz/trash/` (72h reaper, `workspace_manager.py:78-95`); treat `harnesses.db` + lossless SQL dump as the import source of record, markdown is derived; `manifest.json` per snapshot (source path, HEAD, hashes, integrity, `pending|imported`).

## Sorted

**Blocking (for the SOP change):** codify the location + merge-before-delete gate in `skills/marathon-cleanup/SKILL.md` (it currently ends with no clone-state check, `SKILL.md:134-150`); teardown refuses deletion unless merged-and-verified OR a pending salvage snapshot is registered.

**Worth doing, optional:** `manifest.json` + `salvage/index.json` fail-closed pending index; ROUTER.md routing hint; migrate today's `~/marathon-clones/gh174-telemetry-salvage-2026-08-23/` into the new home as its first `pending` entry.

**Skip / out of scope:** agy's in-repo gitignored dir (adjudicated out); `.tick/orphan-backups/`; `.xyz/trash/`.

## Decided shape

```
~/Documents/GH Repos/XYZ-Transcripts/          # renamed from Agent2Agent-Transcripts (agnostic)
  repositories/…  runtime/…                     # existing agent2agent store, unchanged
  salvage/<repo-id>/<date>-<clone-name>/        # teardown salvage: raw files + manifest.json
  salvage/index.json                            # pending|imported ledger, fail-closed
```
Pointer file `~/.config/xyz/agent2agent-home` updates to the new path (only reference; no code hardcodes it). Rename only after confirming no live agent2agent session holds `runtime/allocation.lock`.
