---
gh_issue: 284
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/284
title: "marathon: open a non-merging PR with closeout notes after a successful run"
status: "Contract authored 2026-07-23 (/10days sweep) — not yet fired"
created: 2026-07-23
updated: 2026-07-23
owner: noel
doc_type: feature
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
non_goals:
  - Auto-merging the closeout PR (explicit non-goal in the issue itself — open only, never merge/force-push/branch-create beyond what's already there).
goal: >
  After a marathon run completes successfully, open a non-merging PR carrying deterministic closeout
  notes (built from the plan name, phase count, and tick events) — reusing marathon-closeout.sh's
  existing PR-creation code path, gated behind a new opt-in flag so default behavior is unchanged.
---

# GH-284 · marathon closeout PR (non-merging, notes-only)

Well-specified by the issue itself: exact seam, step-by-step plan, acceptance criteria, and explicit
non-goals (no merge, no force-push, no branch creation). Confirmed unimplemented — no matching
commits/PRs, no capture doc, no test file existed before this one.

## Touch surface (confirmed by reading both files in full)

- `relay-automation/marathon-closeout.sh` (155 lines): currently always runs
  add → commit → push → PR-create → checks → merge → switch → pull as one atomic sequence. Add an
  `--open-only` (or `--no-merge`) flag that stops after `gh pr create` (skips `gh pr checks`,
  `gh pr view --json mergeable`, `gh pr merge`, `git switch`, `git pull`). Guard `git commit` against a
  clean tree (`git diff --cached --quiet` check before committing) so a no-op run doesn't hard-fail.
  Query for an existing open PR on `HEAD_BRANCH` before `gh pr create` to avoid a duplicate-PR failure.
- `relay-automation/marathon.sh` (234 lines): success tail is lines ~224-234, right after the phase
  loop, before `TICK_BIN log marathon.complete`. Add a `--closeout-pr` flag, wired in there, that
  builds deterministic PR notes from `PLAN_NAME`/phase count/tick events and invokes
  `marathon-closeout.sh --open-only`. A PR-creation failure should be logged but must NOT propagate to
  the marathon's own exit code (the marathon itself already succeeded).
- **Correction 2026-07-23 (swarm-preflight AMBIGUOUS catch):** `test/marathon-closeout.sh` already
  exists — a GH-273 Phase 3 regression test for the CURRENT closeout behavior (hermetic, PATH-shadowed
  git/gh stubs). It is unrelated to this issue's new flag but the filename collides with what would
  have been a "new" test file. Extend the EXISTING file with new cases (success / no-merge /
  notes-content / duplicate-PR / PR-creation-failure for `--open-only`/`--closeout-pr`), reusing its
  existing PATH-shadowed git/gh stub pattern — do not create a second file.
- `--help` text in both scripts needs updating for the new flag.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/marathon-closeout.sh", "pattern": "--open-only" }
  ],
  "artifacts": [ "relay-automation/marathon-closeout.sh", "relay-automation/marathon.sh", "test/marathon-closeout.sh" ],
  "remediation": {
    "source": "issue#284",
    "criteria": "marathon-closeout.sh gains --open-only (stops after gh pr create, clean-tree-safe, duplicate-PR-safe); marathon.sh gains --closeout-pr wired into its success tail, PR-creation failure non-fatal to the marathon's own exit code; the EXISTING test/marathon-closeout.sh (GH-273 Phase 3 regression test) gets new cases covering success/no-merge/notes/duplicate/failure paths for the new flags, reusing its existing PATH-shadowed git/gh stub pattern; --help text updated in both scripts."
  },
  "lanes": { "agy_safe": [ "relay-automation/marathon-closeout.sh", "relay-automation/marathon.sh", "test/marathon-closeout.sh" ], "orchestrator_only": [] }
}
```
