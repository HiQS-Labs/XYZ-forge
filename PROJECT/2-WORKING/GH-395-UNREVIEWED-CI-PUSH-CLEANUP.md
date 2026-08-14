---
gh_issue: 395
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/395
title: "Unreviewed CI push to main — f42305f bundles a skills/ponytail-refined/ revert plus a hardcoded local path"
status: 2-WORKING
created: 2026-08-14
updated: 2026-08-14
owner: unassigned
doc_type: capture
complexity: 1
risk: 1
effort: 1
ratings_provisional: true
goal: >
  Undo the two mechanical artifacts an unreviewed CI push left behind — a byte-duplicate
  skill directory and a hardcoded absolute tick path in generated relay files — and keep the
  operator-only half (branch protection, access audit) separate from the code half.
---

## Status

| What was just completed | What's next |
|---|---|
| **Half one shipped 2026-08-14** on `quickwins/parked-2026-08-14`: `skills/ponytail-refined/` is deleted. It was a byte-identical copy of `skills/ponytail/SKILL.md` (`cmp` clean; the only difference was that `ponytail/` also ships `install.sh`), and nothing live referenced it — the only remaining mentions are archival (`temp/`, `relay-system/`, `CHANGELOG.md`, a `3-COMPLETED` doc). | **Half two is not built:** the hardcoded absolute tick path still appears across generated `phases/**/RELAY.md` and `marathon-system/**/RELAY.md` files, and the template that emits it needs fixing rather than the generated artifacts. **Half three is operator-only and not marathonable:** the branch-protection rule and the `ci@runner.invalid` access audit are GitHub-settings work, and the issue's "Questions for Noel" block is discussion, not scope. |

## Why

An unreviewed CI push to `main` (`f42305f`) bundled two unrelated mechanical changes with no
review gate. Both survive on `main` and `development`:

1. A revert that re-created `skills/ponytail-refined/` — a byte-duplicate of `skills/ponytail/`
   that GH-180 had removed.
2. A hardcoded absolute path to this machine's `bin/tick` baked into generated relay files.

Neither is dangerous on its own. Together they are the visible residue of a push that no human
read, which is the actual subject of the issue.

## Key concepts

- The duplicate skill directory is safe to delete only because nothing live resolves it —
  Claude Code scans `~/.claude/skills/`, and the repo copy is the install source.
- The hardcoded path is a *template* defect: fixing the emitted `RELAY.md` files without fixing
  the emitter reintroduces it on the next render.

## Acceptance

Authored by `/10days` and this follow-up — the tracking issue has no `## Acceptance` section,
so there is no block to copy verbatim. Split by what is actually actionable in-repo.

1. `skills/ponytail-refined/` no longer exists in the tree. **[met 2026-08-14]**
2. No live (non-archival) file references `ponytail-refined`. **[met 2026-08-14]**
3. The template that emits `RELAY.md` no longer writes an absolute machine-specific tick path.
   **[not met]**
4. Existing generated `RELAY.md` files carrying the hardcoded path are regenerated or corrected.
   **[not met]**
5. Branch protection and the `ci@runner.invalid` access question are recorded as operator
   decisions, not code lanes. **[recorded here]**

## Acceptance — deviations from the issue

- [dropped] The branch-protection rule and `ci@runner.invalid` access audit — reason: GitHub
  settings work an in-repo lane cannot perform or verify; recorded as an operator decision.
- [dropped] The "## Questions for Noel" block — reason: discussion, not a checkable criterion.
