# Marathon Phase p2
STATUS: Open
NEXT: agy (Builder)

<!-- marathon-drive: task=MARATHON-P2-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

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


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): relay-automation/improve-loop.sh, TESTS-RESULTS/2026-10-25+GH-1221/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1221/provenance.jsonl
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick
   - /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick claim MARATHON-P2-TURN --agent agy --paths "marathon-system/gh1214-lessons-readback--p2/RELAY.md,relay-automation/improve-loop.sh, TESTS-RESULTS/2026-10-25+GH-1221/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1221/provenance.jsonl"
   - /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick ping MARATHON-P2-TURN --agent agy
   - /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick release MARATHON-P2-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh1214-lessons-readback--p2/RELAY.md and relay-automation/improve-loop.sh, TESTS-RESULTS/2026-10-25+GH-1221/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1221/provenance.jsonl. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/improve-loop.sh, TESTS-RESULTS/2026-10-25+GH-1221/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1221/provenance.jsonl. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick release MARATHON-P2-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick done MARATHON-P2-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick
   Edit ONLY marathon-system/gh1214-lessons-readback--p2/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
4c. A finding that asks for a behaviour change is a generalization unless you can paste the concrete
   input — a row, a value, a `file:line` — that fails under the current code (GH-681). Every
   `[Blocker]` or `[Should]` requesting a behaviour change MUST carry `Observed input:`,
   `Affected scope:` and `Falsifier:` lines; a `[Blocker]` must cite an observed failure. The Builder
   may disposition a request lacking these as `Declined — unproven generalization`.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to agy —
   agy, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.

---

### Round 1 · Builder · agy

Implemented GH-1221 pre/post-build snapshot, NUL-safe content/mode manifest, and off-`ALLOW` violation detection + restoration in `relay-automation/improve-loop.sh`:

- **Files touched**:
  - `relay-automation/improve-loop.sh`: added `il_build_guard` (`before` / `after`) and wired it around `eval "$BUILD_CMD"` in the hill-climb loop (`# GH-1221`).
  - `TESTS-RESULTS/2026-10-25+GH-1221/manual-check.md`: recorded red/green verification across cases (a)–(d) in throwaway git repositories under `$TMPDIR` plus existing test suite results.
  - `TESTS-RESULTS/2026-10-25+GH-1221/provenance.jsonl`: recorded structured provenance receipts for the red control, post-fix probe, and regression suites.
- **Key decisions**:
  - Before each build (`il_build_guard before`), `improve-loop.sh` records `git status --porcelain -z --untracked-files=all --ignored`, `git ls-files -z` (to distinguish clean tracked files from pre-dirty/untracked/ignored files), a NUL-safe content+mode manifest (`manifest.nul` / `manifest.json` with SHA-256 content hashes and octal modes), and a byte/mode/symlink snapshot under `$STATE_DIR/.gh1221_snap/files/` for every pre-existing path outside `ALLOW` and outside `$STATE_DIR`. If the snapshot fails, the iteration fails closed (`op=0`, rejected via `champion.sh judge`).
  - `REPO_ROOT` resolves to the current working tree's git toplevel only when `$ARTIFACT` resides inside that tree (or to `$ARTIFACT`'s own git toplevel if `$ARTIFACT` is in another git repo), so test harnesses invoking `improve-loop.sh` from a repo CWD against a non-git `$TMPDIR` artifact directory continue to work without snapshotting the caller's repo.
  - After each build (`il_build_guard after`), both porcelain status and the fresh content/mode manifest are compared against the pre-build snapshot. Any added path, removed path, or in-place byte/mode change outside `ALLOW` and `$STATE_DIR` logs `off-ALLOW write violation (<paths>) — restored snapshot`, forces `op=0` so `champion.sh judge` rejects the iteration (rolling back `$ARTIFACT` and recording provenance), removes newly created paths, restores clean tracked files from `HEAD` (`git checkout HEAD -- <path>` + mode) and pre-existing dirty/untracked/ignored files from the byte/mode snapshot.
- **Verification**:
  - Throwaway git repo probe under `$TMPDIR` verified red (before fix) and green (after fix) for cases (a), (b), (c), (d1 in-place ignored `cache/x`), and (d2 newly created ignored sibling `cache/y`).
- Existing suites `test/improve-loop.sh` (11/11), `test/improve-loop-qa.sh` (11/11), `test/improve-loop-dogfood.sh` (7/7), `test/champion.sh` (13/13), and `test/gh430-state-dir-tracked-default.sh` (8/8) all pass.

### Round 1 · Reviewer · codex

swept file: yes

**Verdict:** Changes requested

Reviewed the complete `relay-automation/improve-loop.sh` (486 lines) and both evidence artifacts. No unrelated pre-existing defect was found in the swept loop surface. Static syntax probe passed: `bash -n relay-automation/improve-loop.sh` → exit 0. I did not run the mutation-heavy suites or executable fixtures, per the relay constraint; their recorded runs remain builder-provided evidence.

[Should] Preserve and restore the Git index as well as worktree bytes for a pre-existing dirty tracked path. The current restore only runs `git reset -q HEAD -- <path>` for a post-build status path absent from the pre-build path set (`improve-loop.sh:318-323`); a path already dirty before the build is therefore skipped. The later restoration at `:357-369` copies (or checks out) worktree content only. Consequently, the guard does not restore the exact pre-build repository state when the build stages a pre-existing dirty path.

Observed input: before the iteration, `tracked_other.txt` has an unstaged pre-existing edit (porcelain `" M tracked_other.txt"`); the build runs `printf 'builder\n' > tracked_other.txt; git add tracked_other.txt` while `tracked_other.txt` is outside `ALLOW`. Post-build porcelain is `"M  tracked_other.txt"`. The path appears in both `pre_porc_set` and `post_porc_set`, so the `:318-323` reset condition is false; restoration copies the pre-build worktree bytes but leaves the builder's staged index entry.

Affected scope: every tracked file that was pre-existing and dirty (staged, unstaged, or both) before an off-`ALLOW` build write; this contradicts the brief's requirement to restore every pre-existing path exactly.

Falsifier: in a throwaway repo, seed distinct HEAD/index/worktree versions of an off-`ALLOW` tracked file, run one rejected iteration that stages a fourth version, then verify `git diff --cached -- <path>` and `git diff -- <path>` exactly match their pre-build outputs after restoration. A fix may snapshot/index-restore the preexisting index state rather than reset it to HEAD.

handing off to agy — agy, take your turn
