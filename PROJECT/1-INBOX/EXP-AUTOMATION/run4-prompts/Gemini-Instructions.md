# Gemini — Run 4 build instructions (Enforcement lane)

**You are Gemini, a build agent in the xyz Run-4 swarm. Read this whole file and execute it.**
Your lane is **Enforcement**. Do **not** touch the Automation lane (`relay-automation/**`) — that's the other agent.

## Mantra (recite before each action)
1. **Verify, don't assume** — `tick info <TASK-ID>` to confirm your exact paths; never infer.
2. **Trace the real path** — cite `file:line` you actually read; intuition isn't evidence.
3. **Falsify** — state each assumption and try to disprove it against the source first.
4. **Stay in your lane / code to the contract** — only edit your claimed paths; flag conflicts, don't paper over.

## Your lane scope
`src/claim.js, src/take.js, test/**, validate.sh`

## Loop (repeat until your lane is drained)
```
1. ./bin/tick take --agent gemini        # note the TASK-ID it prints ("won: <TASK-ID> …")
2. work ONLY inside your lane
3. ./bin/tick ping <TASK-ID> --agent gemini    # heartbeat every few min / after each edit
4. run the task's check (below) — must pass
5. git status --short ; git add <your exact files> ; git commit -m "[gemini] <TASK-ID> <summary>"
6. ./bin/tick done <TASK-ID> --agent gemini ; go to 1
```

## Your tasks
- **TASK-A1** — `tick` handoff-exclusive rule in `src/claim.js` + `src/take.js`: **reject** `claim`/`take` of a task whose `handoff_to` is set and ≠ the calling agent; write **zero events** on rejection. (Today `claim.js` has no handoff check and `take.js` falls through to `candidates[0]`.)
- **TASK-A2** — add `test/handoff-exclusive.sh` proving the rule (rejected claim → no event written) and wire it into `validate.sh`.

## Your acceptance bar
`bash validate.sh` is green **including the new `handoff-exclusive.sh`** (≥ 13/13). If you see `0/12` with `EPERM mkdir` / paths collapsing to `/agent-a`, that's a blocked `$TMPDIR`, not a real failure — re-run with a writable temp dir.

## Context
Full plan: `PROJECT/1-INBOX/EXP-AUTOMATION/RUN-4-META-BRIEF.md`. Hard 60-min box. Start together with the other agent (launch-sync) so each owns one lane.
