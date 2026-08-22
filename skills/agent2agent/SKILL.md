---
name: agent2agent
description: >-
  Start or join a local XYZ discussion shared by two or more Claude, Codex, or other agent sessions
  through a compact six-digit ID. Use when a prompt says “Join XYZ agent2agent #123456 as agent
  number two…”, when the user asks sessions to talk to each other, or when a participant needs to
  send, route, inspect, watch, drive, or close a serialized agent2agent turn. Supports read-only
  2–3 minute monitoring, a background-watch doorbell that wakes a live session on its turn, and
  explicitly authorized hands-free turn commands. Reuses relay-system files and NEXT: routing; it
  is not the Producer/Reviewer artifact-review relay.
---

# Agent2Agent

Use the bundled `scripts/agent2agent.py` for every state change. It keeps a stable `agent1` through
`agentN` roster, one active `NEXT:` writer, and a durable discussion under `relay-system/<date>/`.
Run commands from the intended XYZ clone; each example resolves the helper from that clone's Git
root so installed skill symlinks and paths containing spaces remain safe.

## Start

Ask only for a subject if the user did not provide one. Default to two participants unless the user
requests more.

```bash
"$(git rev-parse --show-toplevel)/skills/agent2agent/scripts/agent2agent.py" start \
  --subject "subject line here" \
  --agents 2
```

When the user asks for a 2-minute / 30-minute doorbell, include `--timed-watch`. It persists on
the discussion and adds an explicit background-watch request to every pasteable invitation. Omit it
otherwise. Return every invitation printed by the helper verbatim so each non-initiator can join
once at startup:

```text
Join XYZ agent2agent #123456 as agent number two to discuss: "subject line here"

Timed two-minute doorbell requested: when waiting, start a background watch that checks every 120 seconds for 1,800 seconds.
```

Turn 1 is already present as `agent1`. For a roster larger than two, the helper prints one invitation
for every seat from `agent2` through `agentN`. `agent2` owns the live turn; later seats may join
immediately, receive `DECISION: wait`, and arm a doorbell without changing the serialized `NEXT:`
owner.

## Inspect status

Use the seat-agnostic status view when the operator needs the roster, current writer, or doorbell
liveness without joining as a participant:

```bash
"$(git rev-parse --show-toplevel)/skills/agent2agent/scripts/agent2agent.py" status \
  --id 123456
```

`status` is strictly read-only: it creates no lock or sidecar and does not refresh an existing
doorbell marker. `not observed/manual` means only that no watch sidecar exists; it is not evidence
that the participant is absent.

## Join an invitation

Parse the six-digit ID, plain-language agent number, quoted subject, and any timed-doorbell request.
Do not create a second file. Resolve and validate the existing discussion read-only first:

```bash
"$(git rev-parse --show-toplevel)/skills/agent2agent/scripts/agent2agent.py" join \
  --id 123456 \
  --agent 2 \
  --expect-subject "subject line here"
```

- `DECISION: take-turn`: read the returned relay file, formulate a useful response to the whole
  discussion, then use `send` or `close`.
- `DECISION: wait`: do not write. Tell the user which participant owns `NEXT:`.
- `DECISION: closed`: do not write. Report that the discussion is complete.

Joining is idempotent and never changes the relay file.

## Choose an operating level

Default to `watch`. Use `drive` only when the user explicitly asks for hands-free or automatic
participation and supplies or approves the turn command. Never promote a join or watch request into
drive on your own.

### Watch — safe and read-only

Wait until this participant owns `NEXT:` or the discussion closes. The default interval is 150
seconds, matching a 2–3 minute check cadence. `--timeout 0` waits indefinitely; set a positive
timeout when the host session needs a bounded wait.

```bash
"$(git rev-parse --show-toplevel)/skills/agent2agent/scripts/agent2agent.py" watch \
  --id 123456 \
  --agent 2 \
  --interval 150 \
  --timeout 0
```

`watch` reads only. It never creates a lock, executes another agent, or changes the discussion.
When it prints `DECISION: take-turn`, formulate the response and use `send` or `close`; on
`DECISION: closed` or `timeout`, stop and report. A host with
a recurring-loop facility may schedule this command; a plain chat surface cannot become hands-free
merely by leaving instructions in the conversation. A host that can launch a command as a
background task and wake when it exits can do better still — see Doorbell below.

### Timed two-minute doorbell — explicit user request

When the user asks the **source and target** to check for their turn every two minutes for 30
minutes — including through an invitation that says `Timed two-minute doorbell requested` — treat
that as explicit authorization to start the watches. Do not merely describe the command or ask
either live session to remember to poll. Each participant must launch this command as a background
task when it is waiting for the other participant:

```bash
"$(git rev-parse --show-toplevel)/skills/agent2agent/scripts/agent2agent.py" watch \
  --id 123456 \
  --agent 2 \
  --interval 120 \
  --timeout 1800
```

For the source, launch it immediately after `send` hands the turn to the target. For the target,
launch it after `join` returns `DECISION: wait`. Substitute the participant number for each seat.
If either participant is already assigned `NEXT:`, it must take that turn first, then start this
background watch immediately after its next `send`. On `take-turn`, respond and re-arm from the
printed `REARM:` command after `send`; on `closed` or `timeout`, do not re-arm. State clearly if
the host does not support background-task wake: the instruction cannot wake a dormant chat session
by itself.

### Doorbell — hands-free for live sessions with background-task wake

On a host that re-invokes the session when a background command exits (Claude Code's background
Bash tasks are one such facility), `watch` becomes a doorbell rather than a poll: the live session
sleeps until it owns the turn, then answers with its full accumulated context. This is the pattern
for bridging two *interactive* terminal sessions hands-free — where `drive` runs a fresh headless
command per turn, doorbell turns are composed by the ongoing session itself.

1. Join once via the pasted invitation, as normal. If `join` prints `DECISION: take-turn`, the
   turn is already yours — take it now (step 3's send-and-re-arm); launch the background `watch`
   of step 2 only when `join` prints `wait`. On `closed`, report and stop.
2. Launch `watch` **as a background task** with `--timeout 0` (the same command as above; do not
   hold a foreground call open on it).
3. When the background `watch` exits and the host wakes the session: read the printed `DECISION:`.
   On `take-turn`, read the relay file, compose the reply, and use `send` or `close`. On `closed`,
   stop and report — do not re-arm. On `timeout` the watch prints a `STILL-WAITING:` line followed
   by the relaunch command: the window expired while the peer still held the turn, so **decide**
   whether the wait is still worth continuing, then either run that command or report the stall.
   It is deliberately not labelled `REARM:` — re-arming after a timeout is a judgment call, not a
   reflex. If `watch` exited **without** printing a `DECISION:` line (a crash — don't key off the
   exit code alone: a timeout also exits non-zero but still prints `DECISION: timeout`), do not
   guess and do not re-arm blindly: rerun `join` read-only to learn the discussion's actual state,
   and report the failure to the operator.
4. **Re-arm as part of the send step — the command is handed to you.** A `watch` that exits
   `take-turn` also prints a `REARM:` line: the exact, self-contained relaunch command (absolute
   script path and `--root` included, so it runs verbatim from any CWD). In the same turn you
   `send`, run that printed line as a background task (only after `send` — never after `close`;
   a closed discussion has no further turns, and a `closed` or `timeout` exit prints no `REARM:`
   line for exactly that reason). On your first turn after a `take-turn` **join** — where no watch
   has exited yet — use step 2's command. A doorbell that is not re-armed silently downgrades the
   seat to manual — the discussion stalls with no error, which reads identically to the other
   participant still thinking. The printed line exists so re-arming is protocol the tool enforces
   at the moment it matters, not discipline the session must remember.

Two doorbell seats ping-pong indefinitely after one paste each. Seats degrade independently: a
surface without background wake keeps using foreground `watch`, `drive`, or manual turns in the
same roster.

Doorbell changes only the wake mechanism. The relay file remains the source of truth, `watch`
still never writes or locks, and every write still goes through `send`/`close` ownership
enforcement.

### Drive — explicit hands-free mode

Require an explicit turn command after `--`. Drive polls like watch, invokes that command only when
this participant owns `NEXT:`, and then verifies that the command advanced the turn through the
normal helper. The command receives the compact invitation prompt on stdin and these environment
variables: `AGENT2AGENT_ID`, `AGENT2AGENT_AGENT`, `AGENT2AGENT_MEMBER`,
`AGENT2AGENT_RELAY_FILE`, `AGENT2AGENT_ROOT`, and `AGENT2AGENT_SUBJECT`.

```bash
"$(git rev-parse --show-toplevel)/skills/agent2agent/scripts/agent2agent.py" drive \
  --id 123456 \
  --agent 2 \
  --interval 150 \
  --timeout 3600 \
  --max-turns 6 \
  -- /absolute/path/to/approved-agent-turn-command
```

Use an argument-vector command or wrapper that reads its prompt from stdin. Do not interpolate
untrusted discussion content into a shell command. The turn command must use this skill's `send` or
`close` operation. Drive verifies an observable advance and handoff but does not sandbox or prove
the internal behavior of an operator-supplied command. One drive process may own a
participant/discussion lane at a time. `Ctrl-C`, closure, timeout, the turn cap, contention, or a
non-zero command exit stops visibly.

## Send and route

Only send when `join` or `watch` says `take-turn`. Choose any *other* roster member as the next
participant.
For multiline content, prefer a UTF-8 message file or stdin rather than interpolating model output
into an unquoted shell command.

```bash
"$(git rev-parse --show-toplevel)/skills/agent2agent/scripts/agent2agent.py" send \
  --id 123456 \
  --agent 2 \
  --next-agent 3 \
  --message-file /safe/path/to/message.md
```

To stream a message through stdin without interpolating its contents into the command:

```bash
"$(git rev-parse --show-toplevel)/skills/agent2agent/scripts/agent2agent.py" send \
  --id 123456 \
  --agent 2 \
  --next-agent 3 \
  --message-file - < /safe/path/to/message.md
```

Return the helper's final invitation line verbatim. The user can paste it into that participant's
session; the same shape works for agent one, three, four, and beyond.

To end instead of hand off:

```bash
"$(git rev-parse --show-toplevel)/skills/agent2agent/scripts/agent2agent.py" close \
  --id 123456 \
  --agent 2 \
  --message "Final consensus and decision."
```

## Guardrails

- **A participant that dislikes a peer's turn may only say so — never act on it.** If another
  participant's message is off-protocol, malformed, non-compliant with the discussion's stated
  rules, or otherwise unsatisfactory, the sole correct response is to name the problem in your own
  `send`/`close` message (or, if it blocks you from continuing safely, stop and escalate to the
  human operator). **Never modify, move, delete, or otherwise act on another participant's
  workspace, clone, worktree, or branch as an enforcement or corrective response** — that is true
  regardless of role (initiator, producer, reviewer, driver) and regardless of how "safe" the
  action seems (moving a clone to Trash is still unilateral destructive intervention, even though
  it is recoverable — the peer never consented to it and the human never authorized it). This
  skill's protocol governs message exchange through the relay file only; it grants no participant
  authority over anything another participant owns. Observed incident: a reviewing agent judged a
  builder agent non-compliant with conversation structure and moved the builder's full clone to
  Trash on its own initiative — no human authorized that, and the correct move was a message
  documenting the compliance concern, not an environment change.
- Treat the relay file as the source of truth. Never infer turn ownership from chat history alone.
- Never edit the discussion directly; the helper uses an exclusive write lock and atomic replace.
- Never write out of turn, add participants after creation, or route outside the declared roster.
- Treat `watch` as the default operating level. Enter `drive` only with explicit user authorization
  for the exact participant, bounds, and turn command.
- Treat the drive turn command as code execution with the current process's authority. Prefer a
  reviewed absolute wrapper path and bounded `--timeout`/`--max-turns`; never synthesize a shell
  pipeline from discussion text. The command's authority is scoped to composing and sending this
  participant's own turn — it must never read, judge, or act on another participant's workspace,
  including in response to that peer's turn content.
- If the helper reports `discussion is locked by another writer`, the message names the holding pid
  and that process is **running** — a lock left by a crashed sender is now detected and reclaimed
  automatically, with a `STALE-LOCK:` line on stderr saying so. So wait briefly, rerun `join`, and
  retry only if it still returns `DECISION: take-turn`. Never delete the lock file by hand; report
  repeated lock failures to the user.
- `join` and `send` report each peer's doorbell age (`peer doorbell (agent2): armed 41s ago`) when
  that seat has ever armed one. Silence about a seat means it never armed a doorbell — normal for a
  manual participant. A line marked `STALE` means that seat may no longer be listening; say so
  rather than assuming the peer is merely slow.
- Keep turns serialized. This skill does not provide parallel writes, broadcasts, voting, or
  cross-machine transport.
- Pass `--root /path/to/harness` or set `AGENT2AGENT_ROOT` only when the discussion lives in a
  different XYZ clone than the skill itself.
