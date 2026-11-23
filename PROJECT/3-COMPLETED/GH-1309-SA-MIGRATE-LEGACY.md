---
title: Skills Army HQ migrate-legacy
status: Complete
owner: Claude
goal: One explicit, archived path to replace a real legacy folder in an app root with the managed link
created: 2026-11-01
updated: 2026-11-01
issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1309
---

# GH-1309 Skills Army HQ migrate-legacy

## Status

| What was just completed | What's next |
|---|---|
| Final Codex QA Approved (relay-system/2026-11-01/gh1309-final-qa.md); tier-2 gate 6/6 green | PR ready; awaiting merge. Carry-over: update deployed manager, then migrate xyz. Lessons: NO_ENTRY |

## Why

`~/.claude/skills/xyz` is a real directory from an older installer, so `sync.py --status` stays at exit 2
and Claude Code reads a stale `xyz`. `--migrate`, `--migrate-from` and `--adopt` refuse real directories;
`--archive-legacy` works only with `--retire-trinity`. See issue #1309.

## Recon (base `cb1bf933`, `skills/3-weekly/skills-army-hq/`)

Observed 2026-11-01 on the Mac Studio: `~/.claude/skills/xyz` is a real directory (installer-created
2026-06-30, `SKILL.md` 82,037 B) while the managed copy is 83,345 B and every other app links to it.
`sync.py --status` exits 2 on that one entry. Its sibling `~/.agents/skills/jog` (a link into the primary
checkout) was a supported `--migrate-from` and is already done, which is what isolates the gap to real folders.

| Fact | Where |
|---|---|
| Any real entry at an app path raises `Foreign real entry preserved` | `scripts/intake.py:367-371` (`link_text`) |
| `reconcile` calls `link_text` for every desired key, so a real folder can only land in `errors` | `scripts/sync.py:242-285` |
| The only real-folder path is `retirement()`, gated on `--retire-trinity`, a name check, and a digest equal to the selected source | `scripts/sync.py:287-323`, `:338`, `:370-374` |
| `retirement` takes the verified ZIP (`shared.archive`), stages under `.staging/<op>`, checks same filesystem, then emits a `retire-directory` action | `scripts/sync.py:307-318`, `scripts/intake.py:326-364` |
| Applying that action is hard-coded to the path `parent / "skills-sync-trinity"` | `scripts/intake.py:537-545` |
| Receipt validation allows `retire-directory` only when `name == "skills-sync-trinity"`; it does not check the action's root | `scripts/intake.py:565-568` |
| Replay of a finished `retire-directory` returns only when the path is absent; a path that is now a symlink fails the digest check | `scripts/intake.py:539-545` |
| Contract text: `--adopt`/`--migrate`/`--migrate-from` "cannot replace a real directory"; only `--archive-legacy` may, for trinity | `references/recovery.md:160,167,174-178` |
| Existing coverage: `test/test_deploy_skills.py` (a10 pins the trinity flow) carried by `test/skills-army-hq.sh`; tier-2 `skills-army-hq` subsystem in `utils/ci-route.sh:33` | no test pins the `Invalid retirement` text |

Prior art: `prior_art_recon.py --query "skills-army-hq legacy real directory migrate archive-legacy"` found no
open PR, merged PR, issue or helper. Recurrence: one instance on this device; other devices exist
(`pulse-noels-macbook-pro-14`, `pulse-noels-mac-mini`) whose app roots may hold legacy folders; trend unknown.

## Bet check

- **Outcome sought:** an operator can replace a stale real folder in an app root with the managed link
  through Skills Army HQ itself, with a verified backup and no manual `mv`/`rm` (hard rule 1).
- **Smallest viable bet:** one explicit flag, `sync.py --migrate-legacy SKILL` (repeatable), usable only with
  `--archive-legacy`, reusing the existing archive, `.staging` and `retire-directory` machinery.
- **Not built:** discovery or bulk migration of legacy folders; any change to `--adopt`, `--migrate`,
  `--migrate-from` or `--retire-trinity`; deletion; a content-match requirement; new suite or registry entry (GH-831).
- **Alternatives rejected:** (1) hand `mv` of the folder: breaks the script-only rule. (2) Require the legacy
  digest to equal a selected source, as trinity does: a stale copy differs by definition and no old checkout of
  each past version exists; the verified ZIP plus retained staging is the safety net instead. (3) Teach
  `--migrate` about real folders: it would widen a flag whose documented contract is "never a real directory". (4) Auto-archive any foreign real
  folder during a normal sync: unsafe and unrequested.
- **Rollback / containment:** the flag is opt-in, so no existing flow changes. A migrated folder is recoverable
  from `backups/<name>-<date>.zip` and from `.staging/<op>/retired`; restoring is `unlink` of the managed link
  plus a rename back. Reverting the PR removes the flag. Reversibility: **Costly** (it mutates app roots
  outside the repo) but contained by explicit flags, a preview-first default and the archive.

## Plan

Behaviour (what the flag does):

- `sync.py --root R --migrate-legacy xyz --archive-legacy` previews; adding `--apply` executes.
- For each **enabled** target holding a **real directory** named like a deployed skill: require
  `--archive-legacy`, require a valid skill folder whose frontmatter `name` equals the folder name, then (apply
  only) take the verified ZIP, move the folder to `.staging/<op>/retired` on the same filesystem, and create the
  owned link in one transaction. The change record carries the legacy digest, `matches_managed`
  (true/false) and the ZIP path, so the preview says whether the copy differs.
- Entries that are already links, or absent, are left to the normal reconcile. If the named skill has no real
  folder in any enabled target the run errors ("nothing to migrate"), so a typo or a repeat run is loud, not silent.
- `--migrate-legacy` with `--retire-trinity` is refused; `--archive-legacy` is accepted with either flag and
  refused alone (message updated from "requires --retire-trinity").

Ordered implementation, verification inline:

1. `scripts/intake.py`: in `action_apply`, retire `parent / safe_name(action["name"])` instead of the constant;
   make replay return when the path is absent **or is now a symlink**, after checking the staged copy's digest.
   Verify: the existing trinity flow still passes (`test/skills-army-hq.sh`).
2. `scripts/intake.py` `validate_receipt`: allow `retire-directory` for `skills-sync-trinity` **or** a name in
   `receipt["state"]["skills"]`, and for every `retire-directory` require its root to lie outside the
   collection (the same overlap rule links already use). Verify: manual red controls below.
3. `scripts/sync.py`: add `--migrate-legacy`, thread `legacy`, `archive_directories` and `apply` into
   `reconcile`, build the `retire-directory` action immediately before the link action for the same path,
   add the "nothing to migrate" and flag-combination errors, update the `--archive-legacy` help text.
4. Docs: a short "Replacing a real legacy folder" section in `references/recovery.md` (when to use it, the
   archive, how to restore) and the two command lines in `SKILL.md`; hard rule 2's "ask before archiving a real
   legacy app directory" stays and is cited. `CHANGELOG.md` entry.
5. Verification (no new test file or registry entry): (a) `bash test/skills-army-hq.sh` and the tier-2
   `skills-army-hq` subsystem suites in a disposable full clone; (b) a manual check recorded under
   `TESTS-RESULTS/2026-11-01+GH-1309/` with `provenance.jsonl`, run against a throwaway collection and app roots
   built with `intake.py`/`sync.py` only.

Manual check (main path, adjacent paths, red controls):

| Case | Expect |
|---|---|
| Main: stale real folder (extra file, internal symlink) + `--migrate-legacy X --archive-legacy --apply` | ZIP verified; folder in `.staging/<op>/retired`; link owned and resolving; `--status` clean; changelog entry |
| Adjacent 1: same without `--archive-legacy` | refused, folder untouched |
| Adjacent 2: repeat after success | "nothing to migrate", rc 2, nothing changed |
| Adjacent 3: replay (apply each action twice, second pass after the link exists) | second pass is a no-op, no error |
| Adjacent 4: folder whose frontmatter name differs from its folder name | error, folder untouched |
| Adjacent 5: identical content to the managed copy | `matches_managed: true`, otherwise same path |
| Red control A: base `cb1bf933` scripts with `--migrate-legacy` | argparse rejects it; `Foreign real entry preserved` stays |
| Red control B: forged receipt `retire-directory` with root = collection, name = a deployed skill | `validate_receipt` rejects it |
| Red control C: forged receipt `retire-directory` for a name that is not deployed and not trinity | rejected |

Acceptance for #1309: the flag works on the main path and the adjacent cases above; existing suites stay
green; the docs state the restore path. Out of this PR (carry-over): after merge, update the deployed manager
(`intake.py update skills-army-hq`), then run the real `xyz` migration through it with the operator's go.

## Ratings

`rated 45/30/50/60` (2026-11-01). Severity 30: a stale copy of one skill in one app and a permanently
non-zero status line; no data loss. Priority 45: the operator asked for it, and it is likely to recur on other
devices. Appeal 50: neutral, none given. Effort 60: about 80 changed lines in a careful mutator plus docs, with
a manual verification matrix. Trend unknown beyond one instance.
