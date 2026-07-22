---
gh_issue: 258
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/258
title: "vendor-stack skill: one-step XYZ harness + PDDA governance install into a target repo"
status: "SHIPPED — closed 2026-07-21, see GitHub issue comment for evidence (commit cb01fae, merged PR #259)."
created: 2026-07-20
updated: 2026-07-20
owner: noel
doc_type: feature
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: false
non_goals:
  - Not modifying relay-automation/xyz-vendor.sh to know about PDDA (keeps the vendored .xyz/ copy PDDA-agnostic)
  - Not creating a third combined upgrade registry — each tool keeps its own (~/.config/xyz, ~/.config/pdda)
  - Not auto-installing PDDA without asking; the governance layer stays an explicit opt-in per repo
related:
  - relay-automation/xyz-vendor.sh
  - relay-automation/xyz-sync.sh
  - skills/relay-xyz/find-harness.sh
  - skills/relay-xyz/install.sh
roadmap_exempt: false
---

# GH-258 · vendor-stack skill — one-step XYZ + PDDA install into a target repo

> **Retroactive capture.** The skill was authored first (operator request to vendor XYZ into
> `hyper-pandas-python-stack`, then to generalize into a skill that also installs PDDA); this doc and
> issue #258 bring the work into PDDA compliance per the issue-first SOP. The three files below are
> already on disk under `skills/vendor-stack/` and smoke-tested.

## Summary

A new repo skill that onboards any target repo to the full swarm stack in one step: vendor the XYZ
harness into `<target>/.xyz/`, then optionally install the PDDA doc-governance runtime. It
**orchestrates** the two canonical installers — it does not reimplement them.

## Asks / acceptance criteria

- `skills/vendor-stack/SKILL.md` — orchestrator procedure: resolve both source repos → vendor XYZ
  (`xyz-vendor.sh`) → ask the operator about PDDA → install PDDA (pdda `install.sh`, observe mode) →
  verify → per-tool upgrade notes.
- `skills/vendor-stack/find-pdda.sh` — device-agnostic PDDA-repo resolver: `$PDDA_REPO`/`$PDDA_HOME`
  override → harness sibling `<harness-parent>/pdda` → conventional `~/…/pdda` clone paths. No
  hardcoded machine path; mirrors `relay-xyz/find-harness.sh`. `--root` / `--env` / `--check`.
- `skills/vendor-stack/install.sh` — symlink the skill into `~/.claude/skills/` for discoverability
  (mirrors `relay-xyz/install.sh`), and report what XYZ/PDDA resolve to.
- Graceful degradation: an unresolved PDDA clone downgrades to XYZ-only with a note, never a hard error.
- Both installers register the target into their own per-user upgrade registry so later
  `xyz-sync check/update` and `pdda-sync status/push` carry updates forward.

## Design decision (the fork the operator raised)

The "also install PDDA?" prompt and PDDA path resolution live at the **skill layer**, not inside
`xyz-vendor.sh`, because that script is copied verbatim into every vendored `.xyz/` and runs
headlessly from marathon/relay automation. Baking in cross-repo PDDA resolution would ship dead logic
to machines with no pdda clone and put an interactive prompt inside a must-stay-non-interactive
script. Each tool keeps its own installer and its own upgrade registry (shared-nothing); the skill
runs them in sequence.

## Verification (done)

- `find-pdda.sh --check` resolves the pdda clone via the harness-sibling rule (`via harness sibling`)
  and via `PDDA_REPO` override (`via env override`).
- `bash -n` clean on `find-pdda.sh` and `install.sh`.
- XYZ was vendored into `hyper-pandas-python-stack` (`.xyz/` present, `bin/tick` runs, `.xyz/`
  gitignored, XYZ registry row written) as the original driving task.

## Open follow-ups

- Discoverability symlink (`install.sh`) not yet run in this session; the skill lives in `skills/`,
  which Claude Code does not auto-scan, so it must be symlinked once per machine to be invocable by name.
- Consider promotion to `3-COMPLETED` once the symlink install is run and the skill is exercised end
  to end against a fresh repo other than the original dogfood target.

## Closure note (2026-07-21)

Shipped via commit `cb01fae`, merged PR [#259](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/259); issue #258 closed on GitHub. Promoted to `3-COMPLETED`. The open follow-ups above (discoverability symlink run, fresh-repo end-to-end exercise) are not independently re-verified by this closure pass — carried forward as-is.
