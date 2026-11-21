# Marathon Phase p2
STATUS: Approved
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-P2-TURN-2 builder=agy reviewer=codex round-cap=5 -->

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


## Debug mantra (auto-triggered — 1 prior attempt(s) on this phase did not reach Approved)

Before trying again, read `relay-automation/DEBUG-MANTRA.md` (relative to the harness root) and follow its four-step discipline: reproduce reliably, know the fail path, question the hypothesis, treat this round as a breadcrumb for the next one.
Last recorded reason (`marathon-system/gh1214-lessons-readback--p2/ESCALATION.md`): `unattested-terminal`. Read it before re-guessing.

---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): relay-automation/improve-loop.sh, TESTS-RESULTS/2026-10-25+GH-1221/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1221/provenance.jsonl
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick
   - /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick claim MARATHON-P2-TURN-2 --agent agy --paths "marathon-system/gh1214-lessons-readback--p2/RELAY.md,relay-automation/improve-loop.sh, TESTS-RESULTS/2026-10-25+GH-1221/manual-check.md, TESTS-RESULTS/2026-10-25+GH-1221/provenance.jsonl"
   - /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick ping MARATHON-P2-TURN-2 --agent agy
   - /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick release MARATHON-P2-TURN-2 --agent agy --to codex
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
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick release MARATHON-P2-TURN-2 --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/marathon-gh-1214-lessons-readback/bin/tick done MARATHON-P2-TURN-2 --agent codex
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

Verified the current tree (`relay-automation/improve-loop.sh`, `TESTS-RESULTS/2026-10-25+GH-1221/manual-check.md`, and `TESTS-RESULTS/2026-10-25+GH-1221/provenance.jsonl`) following the orchestrator's `262b6ffe` security-scan baseline update for the two re-indented trusted `eval` lines (`MARATHON-P2-TURN` escalated as `unattested-terminal` solely because `262b6ffe` landed after the prior Codex review at `b361d96f`):

- **Files verified (no rewrite needed; existing implementation satisfies all acceptance criteria)**:
  - `relay-automation/improve-loop.sh`: `il_build_guard` (`before` / `after`) records `git status --porcelain -z --untracked-files=all --ignored`, git index stage map + `.git/index` backup, and a NUL-safe content/mode manifest (`manifest.nul` + `manifest.json`) and byte/symlink/directory backup of every pre-existing path outside `ALLOW` and outside normalized `$STATE_DIR`. On snapshot failure it fails closed; on post-build content, mode, porcelain, or index-stage changes outside `ALLOW` and `$STATE_DIR`, it logs the offending paths, rejects the iteration through the existing champion rejection path (rolling back `$ARTIFACT` and recording provenance), removes newly created paths, restores clean tracked files to `HEAD`, and restores pre-existing dirty tracked (worktree + index), untracked, and ignored files to their exact pre-build bytes and mode.
  - `TESTS-RESULTS/2026-10-25+GH-1221/manual-check.md` & `TESTS-RESULTS/2026-10-25+GH-1221/provenance.jsonl`: document red (pre-fix `e7e0c628`) and green (post-fix) verification in throwaway git repos under `$TMPDIR` across cases (a) clean default settings, (b) clean and pre-dirty tracked file outside `ALLOW`, (c) untracked file creation, and (d1/d2) in-place mutation of pre-existing ignored `cache/x` and creation of ignored sibling `cache/y`.
- **Verification**:
  - `bash test/improve-loop.sh` (11/11 pass)
  - `bash test/improve-loop-qa.sh` (11/11 pass)
  - `bash test/improve-loop-dogfood.sh` (7/7 pass)
  - `bash test/champion.sh` (13/13 pass)
  - `bash test/gh430-state-dir-tracked-default.sh` (8/8 pass)
  - `bash test/security-scan.sh` (35/35 pass, including GH-64 active gate against `relay-automation/hooks/security-scan-baseline.txt`)

### Round 2 · Reviewer · codex

swept file: yes

**Verdict:** Approved

Reviewed the whole 532-line `relay-automation/improve-loop.sh`, both GH-1221 receipts, and the current security-scan baseline (including the two re-indented trusted `eval` rows). No pre-existing in-scope defect was found in the swept loop file.

The guard snapshots porcelain, the index, and a content/mode manifest plus byte backups; it excludes only `ALLOW`, the normalized state directory, and `.git`. Post-build it compares manifest/index/porcelain state, restores pre-existing dirty, clean tracked, untracked, and ignored paths, removes only new paths, and returns nonzero so the existing champion rejection path restores the artifact. The manual red/green transcript covers the requested clean-default, tracked, untracked, in-place ignored, new ignored, and additionally pre-dirty index/worktree cases. The baseline’s lines 21–23 exactly match the current trusted `eval` lines, so the `262b6ffe` indentation-only rebaseline is coherent.

Reviewer probe (permitted static check): `bash -n relay-automation/improve-loop.sh`; exit status `0`; decisive output: `bash -n exit=0`. I did not execute fixtures or suites in this linked worktree; the recorded disposable-repo manual probe and existing-suite receipt remain subject to the harness gate.

relay closed, no further turn needed

### Attestation · relay-drive — 2026-10-25T08:19:40Z
task: MARATHON-P2-TURN-2
reviewer: codex
status: Approved
reviewed-head: abe681dd61e71b44337d7008f100247e70f544da
added-range: 16509+1364
added-sha256: c2b1c99ba1f7c424ba916f0992f05e0f093b9cd9874c4ef492d61a24da354b38
