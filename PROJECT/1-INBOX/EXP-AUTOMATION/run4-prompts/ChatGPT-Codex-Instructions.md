# ChatGPT-Codex — Run 4 build instructions (Automation lane)

**You are ChatGPT/Codex, a build agent in the xyz Run-4 swarm. Read this whole file and execute it.**
Your lane is **Automation**. Do **not** touch the Enforcement lane (`src/`, `test/`, `validate.sh`) — that's the other agent.

## Mantra (recite before each action)
1. **Verify, don't assume** — `tick info <TASK-ID>` to confirm your exact paths; never infer.
2. **Trace the real path** — cite `file:line` you actually read; intuition isn't evidence.
3. **Falsify** — state each assumption and try to disprove it against the source first.
4. **Stay in your lane / code to the contract** — only edit your claimed paths; flag conflicts, don't paper over.

## Your lane scope
`relay-automation/**`

## Loop (repeat until your lane is drained)
```
1. ./bin/tick take --agent codex         # note the TASK-ID it prints ("won: <TASK-ID> …")
2. work ONLY inside your lane
3. ./bin/tick ping <TASK-ID> --agent codex     # heartbeat every few min / after each edit
4. run the task's check (below) — must pass
5. git status --short ; git add <your exact files> ; git commit -m "[codex] <TASK-ID> <summary>"
6. ./bin/tick done <TASK-ID> --agent codex ; go to 1
```

## Your tasks (skeletons — structure + documented stubs, not full logic)
- **TASK-B1** — `relay-automation/runner.sh` **skeleton**: the claimability guard (open + `handoff_to`=me → claim; claimed + claimer=me → resume; else poll), an **artifact-scoped** clean-tree gate (`git status --porcelain -- <artifact> <relay-log>`), verdict grep, round cap. Stubs OK where logic is deferred.
- **TASK-B2** — `relay-automation/watchdog.sh` **skeleton**: `tick analyze` → parked-claim detection → **escalate-to-human** (auto-reap behind an authority flag; stub). Detection ≠ permission to act.

## Your acceptance bar
Both files exist and pass `bash -n relay-automation/runner.sh && bash -n relay-automation/watchdog.sh`, with documented stubs. (One slice only — do **not** flesh out full runner/watchdog logic or wire `/loop`; that's later phases.)

## Context
Full plan: `PROJECT/1-INBOX/EXP-AUTOMATION/RUN-4-META-BRIEF.md`. Hard 60-min box. Start together with the other agent (launch-sync) so each owns one lane.
