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

## Retry note (2026-10-25, orchestrator)

The first attempt's implementation is **already in the tree**: codex approved it at `b361d96f`. Its gate went red on `security-scan.sh` alone, because two pre-existing trusted `eval` lines were re-indented. The orchestrator re-baselined those two lines in `262b6ffe` (scan exit 0, `test/security-scan.sh` 35/0). That commit landed after the reviewed head, so GH-505 correctly refused the old attestation, and this retry exists to get a review of the current tree.

**Builder:** verify the current `relay-automation/improve-loop.sh` and the `TESTS-RESULTS/2026-10-25+GH-1221/` receipt against the acceptance list. Fix only a concrete gap you can show. Do not rewrite working code. Then hand off.

**Reviewer:** review the current tree, including `262b6ffe` (the baseline-only indentation change in `relay-automation/hooks/security-scan-baseline.txt`).

## Plan (one phase)

1. Before each build, take a snapshot inside the loop's state dir. If the snapshot fails, reject the iteration (fail closed).
   - Record `git status --porcelain -z --untracked-files=all --ignored`, parsed NUL-safe.
   - Save the bytes, mode and directory shape of **every pre-existing path outside `ALLOW`** that the build could change, for example with a `tar` of those paths. This covers tracked files with local changes, untracked files and **ignored** files. Clean tracked files can be restored from `git` itself.
   - Exclude `$STATE_DIR` by its normalized repo-relative prefix. Plan review (Codex, 2026-10-25) noted that a status listing records paths, not bytes, so it alone cannot restore a pre-existing ignored file.
2. After the build, detect by **content**, not by path. Also record a NUL-safe content manifest before the build: path, mode and content hash (for example `shasum`/`git hash-object`) for every pre-existing path outside `ALLOW`, whether tracked, untracked or ignored, excluding `$STATE_DIR`. After the build, compare the new porcelain listing (for new paths) and a fresh manifest (for same-path byte or mode changes) against the pre-build versions. Any new path, removed path, or changed bytes or mode outside `ALLOW` and outside `$STATE_DIR` is a violation. A status listing alone cannot see a same-path change to an ignored file. (Plan review round 2, Codex, 2026-10-25.)
3. On a violation: log one line naming the paths, treat the iteration as rejected (the existing rejection path, provenance included), and restore from the snapshot:
   - pre-existing paths go back to their exact pre-build bytes and mode, whether tracked, untracked or ignored
   - clean tracked files go back to `HEAD` content
   - only paths that are new since the build started are removed

   Also restore `$ARTIFACT` as today.
4. Allowed changes (`ALLOW` entries plus the loop's own `$STATE_DIR`) behave exactly as before.
5. Manual check under `TESTS-RESULTS/2026-10-25+GH-1221/` in a throwaway git repo under `$TMPDIR` with a scripted `--build-cmd`. Cover four cases: (a) a clean iteration with default settings is not rejected; (b) a tracked file outside `ALLOW` is changed, then detected and restored; (c) an untracked file is created, then detected and removed; (d) a pre-existing ignored `cache/x` with known bytes and mode is changed **in place** by the build (no new path), then detected, rejected and restored to exactly its old bytes and mode; separately, a newly created ignored sibling is removed. Record each case before the fix (red control) and after. Write `manual-check.md` plus `provenance.jsonl`.

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
