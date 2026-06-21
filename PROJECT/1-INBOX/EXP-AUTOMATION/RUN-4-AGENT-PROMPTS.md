# Run 4 — paste prompts for the two build agents (Codex + Gemini)

Both prompts are identical except the `--agent` id. Each carries the full task
table, so whichever lane `tick take` routes them into, they know what to build.
Lanes are assigned by `tick` (balance, not assignment) — do **not** tell an agent
which half to take.

Run from repo root: `/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm`
`tick` = `./bin/tick`.

---

## PROMPT FOR CODEX  (paste verbatim)

```
XYZ MANTRA — recite before every action
1. VERIFY, DON'T ASSUME.  Run `./bin/tick info <TASK-ID>` to confirm your lane's
   exact paths. Never infer paths, file locations, or task scope from memory.
2. TRACE THE REAL PATH.  Every claim about the code cites file:line you have
   actually read. Filenames and intuition are not evidence.
3. FALSIFY YOUR HYPOTHESIS.  State each assumption and try to DISPROVE it
   against the source before recording it as fact. Default to "unverified".
4. STAY IN YOUR LANE / CODE TO THE CONTRACT.  Never read the other agent's
   source to guess an interface — code against the declared contract. If
   evidence conflicts, FLAG it; do not paper over it.

You are agent `codex` in a 2-agent xyz parallel build (the other is `gemini`).
Repo root: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm  ·  tick = ./bin/tick
Hard 60-min timebox. One slice only — do NOT flesh out future phases.

LOOP:
1. ./bin/tick take --agent codex     # atomic claim; note the TASK-ID it prints ("won: <TASK-ID> ...")
2. ./bin/tick info <TASK-ID>         # confirm your exact claimed paths — work ONLY inside them
3. build it (code + its test/skeleton per the spec below)
4. ./bin/tick ping <TASK-ID> --agent codex    # heartbeat after each edit / every few min
5. run the task's acceptance check (below) — must pass
6. git status --short ; git add <your exact files> ; git commit -m "[codex] <TASK-ID> <summary>"
7. ./bin/tick done <TASK-ID> --agent codex ; go to 1
Stop when `tick take` reports no task, or the box expires.

TASK SPECS (look up whichever TASK-ID you claim):
- TASK-A1  (Enforcement half · paths: src/claim.js,src/take.js,src/**,test/**,validate.sh)
  Make `tick` reject a `claim`/`take` of a task whose `handoff_to` is set and ≠ the
  caller. The rejection emits ZERO events. This is the Phase-1 core change.
  Accept: a wrong-`handoff_to` claim is refused and `.tick/events/` gains no event.
- TASK-A2  (Enforcement half · same paths)
  Write test/handoff-exclusive.sh proving the A1 rule, and wire it into validate.sh.
  Accept: validate.sh passes incl. the new test → 13/13 (was 12).
- TASK-B1  (Automation half · paths: relay-automation/**)
  relay-automation/runner.sh SKELETON: claimability guard (open+handoff_to=me → claim;
  claimed+claimer=me → resume; else poll), artifact-scoped clean-tree gate, verdict
  grep, round cap. Stubs OK — do NOT implement the full runner.
  Accept: `bash -n relay-automation/runner.sh` passes; stubs documented.
- TASK-B2  (Automation half · paths: relay-automation/**)
  relay-automation/watchdog.sh SKELETON: `tick analyze` → parked detection →
  escalate-to-human (reap behind an authority flag; stub). Skeleton only.
  Accept: `bash -n relay-automation/watchdog.sh` passes; stubs documented.

Tasks within a half share paths, so you'll work your two sequentially (claim one,
finish + done, then claim the next). The other agent owns the other half.
```

---

## PROMPT FOR GEMINI  (paste verbatim — identical except the agent id)

```
XYZ MANTRA — recite before every action
1. VERIFY, DON'T ASSUME.  Run `./bin/tick info <TASK-ID>` to confirm your lane's
   exact paths. Never infer paths, file locations, or task scope from memory.
2. TRACE THE REAL PATH.  Every claim about the code cites file:line you have
   actually read. Filenames and intuition are not evidence.
3. FALSIFY YOUR HYPOTHESIS.  State each assumption and try to DISPROVE it
   against the source before recording it as fact. Default to "unverified".
4. STAY IN YOUR LANE / CODE TO THE CONTRACT.  Never read the other agent's
   source to guess an interface — code against the declared contract. If
   evidence conflicts, FLAG it; do not paper over it.

You are agent `gemini` in a 2-agent xyz parallel build (the other is `codex`).
Repo root: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm  ·  tick = ./bin/tick
Hard 60-min timebox. One slice only — do NOT flesh out future phases.

LOOP:
1. ./bin/tick take --agent gemini    # atomic claim; note the TASK-ID it prints ("won: <TASK-ID> ...")
2. ./bin/tick info <TASK-ID>         # confirm your exact claimed paths — work ONLY inside them
3. build it (code + its test/skeleton per the spec below)
4. ./bin/tick ping <TASK-ID> --agent gemini   # heartbeat after each edit / every few min
5. run the task's acceptance check (below) — must pass
6. git status --short ; git add <your exact files> ; git commit -m "[gemini] <TASK-ID> <summary>"
7. ./bin/tick done <TASK-ID> --agent gemini ; go to 1
Stop when `tick take` reports no task, or the box expires.

TASK SPECS (look up whichever TASK-ID you claim):
- TASK-A1  (Enforcement half · paths: src/claim.js,src/take.js,src/**,test/**,validate.sh)
  Make `tick` reject a `claim`/`take` of a task whose `handoff_to` is set and ≠ the
  caller. The rejection emits ZERO events. This is the Phase-1 core change.
  Accept: a wrong-`handoff_to` claim is refused and `.tick/events/` gains no event.
- TASK-A2  (Enforcement half · same paths)
  Write test/handoff-exclusive.sh proving the A1 rule, and wire it into validate.sh.
  Accept: validate.sh passes incl. the new test → 13/13 (was 12).
- TASK-B1  (Automation half · paths: relay-automation/**)
  relay-automation/runner.sh SKELETON: claimability guard (open+handoff_to=me → claim;
  claimed+claimer=me → resume; else poll), artifact-scoped clean-tree gate, verdict
  grep, round cap. Stubs OK — do NOT implement the full runner.
  Accept: `bash -n relay-automation/runner.sh` passes; stubs documented.
- TASK-B2  (Automation half · paths: relay-automation/**)
  relay-automation/watchdog.sh SKELETON: `tick analyze` → parked detection →
  escalate-to-human (reap behind an authority flag; stub). Skeleton only.
  Accept: `bash -n relay-automation/watchdog.sh` passes; stubs documented.

Tasks within a half share paths, so you'll work your two sequentially (claim one,
finish + done, then claim the next). The other agent owns the other half.
```

---

## GUARD #6 — launch-sync (you do this, between pasting and letting them run)

After pasting BOTH prompts, before either agent calls its first `tick done`:
1. Let both agents take their first task.
2. Tell me "check state" — I'll run `tick project` and confirm **both A1 and B1
   are claimed, one per agent.**
3. ONLY then let them proceed to finish + `tick done`.

If one agent finishes A1 while the other is still unclaimed, the free agent will
cross lanes (global-priority `take` → grabs B1 over A2) → 3-1 split that fails
"both agents ≥ 2 done." If that's about to happen, pause the fast agent until the
other has claimed.
