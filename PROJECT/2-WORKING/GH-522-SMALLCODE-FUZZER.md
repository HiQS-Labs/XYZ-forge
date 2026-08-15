---
gh_issue: 522
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/522
title: "SmallCode fuzzer experiment — LM Studio Qwen 2.5 32B as an autonomous marathon Builder"
status: 2-WORKING
created: 2026-08-12
updated: 2026-08-14
owner: unassigned
doc_type: capture
complexity: 2
risk: 1
effort: 2
ratings_provisional: true
related:
  - "https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/523 — the target issue the fuzzer was pointed at"
  - "https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/548 — the hardcoded SmallCode path this experiment introduced, fixed on merge"
goal: >
  Establish whether a local Qwen 2.5 32B under SmallCode can serve as an autonomous Builder lane in
  the marathon fuzzer loop, and record honestly where it fails.
---

# GH-522: SmallCode Fuzzer Experiment (LM Studio Qwen 2.5 32B)

## Status

| What was just completed | What's next |
|---|---|
| **Experiment run 2026-08-12..13, four runs, verdict recorded.** SmallCode (local Qwen 2.5 32B via LM Studio) drives the harness correctly — token passes, a Codex change-request absorbed, a real fix landed in `test/acorn-extract.sh` — but wedges in tool-call loops and is **not autonomous** without strict repeat bounds. Merged via PR #529 with two experiment-introduced defects fixed rather than shipped (#548's hardcoded path; the driver script withheld). | Nothing scheduled. The lane exists and works; making it unattended needs repeat-bound configuration on the SmallCode side, which is outside this repo. |

## Objective
Evaluate the viability of using `smallcode` running `qwen/qwen2.5-coder-32b` locally via LM Studio as an autonomous Builder inside the Marathon fuzzer loop.

## Setup
- **Harness**: `fuzz-smallcode-plan.sh` inside standalone clone `fuzzing-smallcode`.
- **Builder**: `smallcode`
- **Reviewer**: `codex`
- **Target Issue**: GH-523

## Configuration Patches Required
1. Disabled `RELAY_WORKTREE_ISOLATION` in `smallcode-turn.sh` due to SmallCode creating off-lane state files.
2. Injected API endpoints (`SMALLCODE_PROVIDER`, `SMALLCODE_MODEL`, `SMALLCODE_BASE_URL`) directly into the shim environment.
3. Added `.smallcode/` and `.memory/` to `.gitignore`.
4. Disabled `git checkout development` branch resets in `fuzz-smallcode-plan.sh` to avoid clobbering local patches during standalone runs.
5. Added `smallcode` agent recognition to `marathon-agent.sh` and `utils/py/marathon_drive.py`.

## Execution Log
- **Run 1 (Failed)**: Exited with exit code 6 (Containment Violation). Cause: Worktree isolation flagged un-allowlisted files.
- **Run 2 (Failed)**: Exited with exit code 2 (Agent not recognized). Cause: `marathon_drive.sh` branch clobbered by `fuzz-smallcode-plan.sh` resetting to `development`.
- **Run 3 (Active)**: successfully pushed first edit to `RELAY.md`, passed to `codex`, currently continuing loop.

## Findings
*(To be populated after run completes)*
- **Run 3 Findings**: The Fuzzer successfully completed 2 full loops (Round 1 and Round 2) with Codex correctly rejecting the initial implementation and requesting changes. On Round 3, SmallCode correctly implemented the fix by editing `test/acorn-extract.sh`. However, the loop stalled because Qwen 32B entered an infinite tool-call repetition loop, continually attempting to run `tick claim MARATHON-P1-TURN` despite it succeeding and returning `won`. SmallCode's built-in `quality-monitor` repeatedly flagged `repeat_call` but did not abort the LM.

## Conclusion
SmallCode operating with a local Qwen 2.5 32B model via LM Studio *can* successfully interact with the Fuzzer harness and successfully make targeted codebase changes and handle token passes. However, its inference engine has a high likelihood of becoming stuck in recursive tool execution loops when a shell command outputs identical success statuses repeatedly. A hardened SmallCode configuration with strict maximum-repeat bounds or token-claiming side-effects is required for full autonomy.
- **Run 4 Findings**: The Fuzzer successfully booted with all configurations, but SmallCode fell into a read_file loop where it iteratively read the same files repeatedly without outputting any code changes. It eventually hit the 30-minute turn timeout limit. This confirms the model needs significant strictness configurations to avoid getting trapped in tool loops.

## The experiment driver is deliberately NOT in this repo

`fuzz-smallcode-plan.sh` was committed to this branch by accident — this document's own Setup section
places it *"inside standalone clone `fuzzing-smallcode`"*, which is where it belongs and where the
author retains it. It was removed before merge rather than hardened, for three reasons, each of which
is a property of an experiment driver rather than a defect to fix:

1. **It wipes the coordination kernel's durable record.** `rm -rf .tick/attempts/* .tick/events/*
   .tick/state/*` — `README.md` calls `.tick/events/` the shared event log the whole harness
   coordinates through. Resetting it between experiment runs is correct *for an experiment*; a script
   at this repo's root that does it on invocation is a loaded gun, and this repo has already spent
   two incidents (#177, #233) on exactly that class.
2. **It force-deletes the driver lock.** `rm -rf .git/relay-driver.lock` steals a lock that may be
   held by a live run. That lock is the GH-42/GH-354 concurrency guarantee; stealing it is how two
   drivers corrupt one git state.
3. **It hardcodes two absolute paths to repos that exist on one machine** (`Agent-Devtools`,
   `fuzzing-smallcode`), and auto-pushes plus opens a PR on success.

Nothing is lost by its absence: every finding it produced is recorded above, and the harness-side
changes it depended on — `smallcode` agent routing in `marathon-agent.sh` and `marathon_drive.py`,
and `relay-automation/smallcode-turn.sh` — did merge and are what a future run would use.
