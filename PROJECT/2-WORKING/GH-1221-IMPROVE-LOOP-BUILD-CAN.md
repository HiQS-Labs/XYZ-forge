---
gh_issue: 1221
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1221
title: "improve-loop: build can change files outside ALLOW unnoticed — snapshot/restore write check (#1214 P4)"
status: Active (2-WORKING — marathon GH-1214 phase p2)
created: 2026-10-25
updated: 2026-10-25
owner: marathon-gh-1214
doc_type: bugfix
complexity: 3
risk: 2
effort: 2
phases: 1
ratings_provisional: false   # rated 2026-10-25 at marathon prep: one Bash orchestrator, dormant loop (no production caller), restore semantics are the blast radius
non_goals:
  - Read isolation for the builder (a worktree) — later, once a real caller exists
  - Changing champion/measure/heldout/loop-stop/loop-cost semantics
  - Firing any live improve-loop run (Phase 6b, separately approved)
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1214 (umbrella, Phase 4; precondition for 6b)
  - GH-50 (Part C loop), GH-430 (state dir default)
goal: >
  An improve-loop iteration whose build changes any file outside ALLOW (tracked, untracked or ignored),
  other than the loop's own state, is rejected and every such change is restored; a clean iteration
  with default settings is not rejected.
---

# GH-1221 — improve-loop: a build can change files outside ALLOW unnoticed

## Status

| What was just completed | What's next |
|---|---|
| 2026-10-25: promoted to 2-WORKING as phase p2 of marathon #1214; Kimi K3.1 QA blocker (plain porcelain check is wrong) folded into the design | Marathon phase p2 (agy builder, codex reviewer): pre/post-build snapshot, reject + restore off-ALLOW changes, manual check, gate green |

Umbrella: #1214 · Phase p2 · `depends_on: p1`.

## Ground truth (`origin/development` 395e9d64)

- `relay-automation/improve-loop.sh:124` runs `eval "$BUILD_CMD" >/dev/null 2>&1` with nothing checking what it wrote.
- `:144-152`: a rejected iteration restores only `$ARTIFACT` (`cp "$SNAP" "$ARTIFACT"`).
- `:69-77`: `ALLOW` defaults to the artifact, and `STATE_DIR` defaults to `relay-automation/state/improve-loop.$$`, which is **outside** `ALLOW`.
- `.gitignore:1,23-27`: `.tick/` and `relay-system/logs/` are ignored, so a plain `git status --porcelain` never shows them.

## Plan (one phase)

1. Before each build: record `git status --porcelain -z --untracked-files=all --ignored` for the repo, and save a copy of every tracked file's content that the restore might need (for example with `git stash create`, or a per-iteration copy of changed paths). Keep it inside the loop's existing state dir.
2. After the build: take the same listing and compare it with the **pre-build** listing, not with a clean tree. Any path that is new or changed and lies outside `ALLOW` and outside `$STATE_DIR` is a violation.
3. On a violation: log one line naming the paths, treat the iteration as rejected (the existing rejection path, provenance included), and restore every violating path from the snapshot. Restore tracked files to their pre-build content, delete newly created untracked or ignored files, and restore previously existing ignored files that were changed. Also restore `$ARTIFACT` as today.
4. Allowed changes (`ALLOW` entries plus the loop's own `$STATE_DIR`) behave exactly as before.
5. Manual check under `TESTS-RESULTS/2026-10-25+GH-1221/` in a throwaway git repo under `$TMPDIR` with a scripted `--build-cmd`. Cover four cases: (a) a clean iteration with default settings is not rejected; (b) a tracked file outside `ALLOW` is changed, then detected and restored; (c) an untracked file is created, then detected and removed; (d) an ignored file is created or changed, then detected and restored. Record each case before the fix (red control) and after. Write `manual-check.md` plus `provenance.jsonl`.

Rules: Bash 3.2-compatible (match the file's existing idiom); shortest diff; no new script file (inventory ratchet) and no new suite (GH-831 D7). Edit an existing improve-loop suite only if one of its pinned assertions becomes untrue. Never run the loop against this repository's own tree with a live agent.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh",
  "fix_probes": [
    {
      "type": "grep_absent",
      "path": "relay-automation/improve-loop.sh",
      "pattern": "GH-1221"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-25+GH-1221/manual-check.md"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-25+GH-1221/provenance.jsonl"
    }
  ],
  "artifacts": [
    "relay-automation/improve-loop.sh",
    "TESTS-RESULTS/2026-10-25+GH-1221/manual-check.md",
    "TESTS-RESULTS/2026-10-25+GH-1221/provenance.jsonl"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-10-25+GH-1221/manual-check.md",
    "TESTS-RESULTS/2026-10-25+GH-1221/provenance.jsonl"
  ],
  "remediation": {
    "source": "issue#1221",
    "criteria": "relay-automation/improve-loop.sh snapshots porcelain -z --untracked-files=all --ignored before each build, compares post-build against that snapshot, rejects the iteration and restores every tracked/untracked/ignored change outside ALLOW and outside its own STATE_DIR, leaves allowed artifact and loop-state changes working, and a default-settings clean iteration is not rejected; tagged GH-1221; manual red/green check under TESTS-RESULTS/2026-10-25+GH-1221/; existing improve-loop suites green."
  },
  "lanes": {
    "agy_safe": [
      "relay-automation/improve-loop.sh",
      "TESTS-RESULTS/2026-10-25+GH-1221/manual-check.md",
      "TESTS-RESULTS/2026-10-25+GH-1221/provenance.jsonl"
    ],
    "orchestrator_only": []
  }
}
```

## Acceptance

- Cases (a)–(d) above behave as stated, recorded as red before and green after.
- `test/improve-loop.sh`, `test/improve-loop-qa.sh`, `test/improve-loop-dogfood.sh`, `test/champion.sh`, `test/gh430-state-dir-tracked-default.sh` and the full `bash validate.sh` are green.

## Lessons Learned (For Future Agents)

- (filled at closeout)
