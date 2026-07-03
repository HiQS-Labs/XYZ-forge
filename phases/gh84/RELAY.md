# Marathon Phase gh84
STATUS: Approved
NEXT: agy

<!-- marathon-drive: task=MARATHON-GH84-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Phase brief — GH-84: make test/runner-loop.sh hermetic

## Goal
Fix the non-hermetic `test/runner-loop.sh` so it stops false-failing whenever the **real** working
tree's `README.md` (or any file it uses as the runner's artifact) has uncommitted changes.

## Root cause (verified)
`relay-automation/runner.sh:4` sets `ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"` —
its own script location, i.e. the **real repo** — not `TICK_REPO_ROOT`. Its dirty-tree guard
(`runner.sh:71` `git -C "$ROOT_DIR" diff --quiet -- "${ARTIFACTS[@]}"`) therefore checks the real repo.
`test/runner-loop.sh:27` passes `-- README.md` as the runner's artifact, so a dirty real `README.md`
trips the guard (`runner: artifact paths have unstaged changes`) and the test fails.

In live relay use the guard is correct (the runner commits to the repo it lives in); this is a
**test-side hermeticity leak** only.

## Fix (additive, default-preserving)
1. In `relay-automation/runner.sh`, add an optional `RUNNER_ROOT_DIR` env override:
   `ROOT_DIR="${RUNNER_ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"`.
   When `RUNNER_ROOT_DIR` is unset, behavior is **byte-for-byte identical** to today (no live-relay change).
   Add a `# GH-84` marker comment.
2. In `test/runner-loop.sh`, export `RUNNER_ROOT_DIR="$A"` for the `run_runner` invocations so the
   guard checks the hermetic temp repo (`$A`), where the artifact is clean.
3. Add a regression assertion in `test/runner-loop.sh`: with a deliberately-dirtied tracked file in the
   REAL repo, `run_runner` still passes (proving the guard no longer reaches the real tree).

## Scope lock (ALLOW_PATHS)
Edit ONLY: `relay-automation/runner.sh`, `test/runner-loop.sh`. Do not touch the kernel
(`relay-turn-lib.sh` / `bin/tick` / `relay-drive.sh`) or any other file.

## Definition of done (gate)
- `bash test/runner-loop.sh` passes regardless of the real working tree's cleanliness.
- `runner.sh` default `ROOT_DIR` unchanged when `RUNNER_ROOT_DIR` is unset.
- `bash validate.sh` green (the pre-advance gate).
- `src/project.js` / kernel untouched.

Contract of record: `PROJECT/1-INBOX/GH-84-RUNNER-LOOP-NONHERMETIC.md`.

---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): relay-automation/runner.sh,test/runner-loop.sh
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH84-TURN --agent agy --paths "phases/gh84/RELAY.md,relay-automation/runner.sh,test/runner-loop.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH84-TURN --agent agy
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH84-TURN --agent agy --to codex
4. Edit ONLY these paths: phases/gh84/RELAY.md and relay-automation/runner.sh,test/runner-loop.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/runner.sh,test/runner-loop.sh.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH84-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH84-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh84/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · agy
- Modified [runner.sh](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/relay-automation/runner.sh) to support an optional `RUNNER_ROOT_DIR` environment variable, defaulting to the original script directory.
- Modified [runner-loop.sh](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/test/runner-loop.sh) to export `RUNNER_ROOT_DIR="$A"` so the runner-loop hermetically checks `$A` instead of the real repo directory.
- Added a regression test in [runner-loop.sh](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/test/runner-loop.sh) that dirties the real repo `README.md` and asserts that the runner still successfully passes, proving the hermetic guard no longer checks the real workspace.

### Round 1 · Reviewer · codex
**Verdict:** Approved
- Reviewed `relay-automation/runner.sh` and `test/runner-loop.sh` on disk. The `RUNNER_ROOT_DIR` override is additive, and the default `ROOT_DIR` path remains unchanged when the env var is unset.
- Verified the regression path stays hermetic by running `bash test/runner-loop.sh`; result: `7 pass, 0 fail`, including the dirty-real-README regression assertion.
