---
name: agent2agent
description: >-
  Start or join a local XYZ discussion shared by two or more Claude, Codex, or other agent sessions
  through a compact six-digit ID. Use when a prompt says “Join XYZ agent2agent #123456 as agent
  number two…”, when the user asks sessions to talk to each other, or when a participant needs to
  send, route, inspect, watch, drive, or close a serialized agent2agent turn. Supports read-only
  2–3 minute monitoring and explicitly authorized hands-free turn commands. Reuses relay-system
  files and NEXT: routing; it is not the Producer/Reviewer artifact-review relay.
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

Return the final invitation line verbatim so it can be pasted into the target session:

```text
Join XYZ agent2agent #123456 as agent number two to discuss: "subject line here"
```

Turn 1 is already present as `agent1`; the invitation routes the live turn to `agent2`.

## Join an invitation

Parse the six-digit ID, plain-language agent number, and quoted subject. Do not create a second file.
Resolve and validate the existing discussion read-only first:

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
When it prints `DECISION: take-turn`, formulate the response and use `send` or `close`. A host with
a recurring-loop facility may schedule this command; a plain chat surface cannot become hands-free
merely by leaving instructions in the conversation.

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

Only send when `join` says `take-turn`. Choose any *other* roster member as the next participant.
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

- Treat the relay file as the source of truth. Never infer turn ownership from chat history alone.
- Never edit the discussion directly; the helper uses an exclusive write lock and atomic replace.
- Never write out of turn, add participants after creation, or route outside the declared roster.
- Treat `watch` as the default operating level. Enter `drive` only with explicit user authorization
  for the exact participant, bounds, and turn command.
- Treat the drive turn command as code execution with the current process's authority. Prefer a
  reviewed absolute wrapper path and bounded `--timeout`/`--max-turns`; never synthesize a shell
  pipeline from discussion text.
- If the helper reports `discussion is locked by another writer`, wait briefly, rerun `join`, and
  retry only if it still returns `DECISION: take-turn`. Never delete the lock file; report repeated
  lock failures to the user.
- Keep turns serialized. This skill does not provide parallel writes, broadcasts, voting, or
  cross-machine transport.
- Pass `--root /path/to/harness` or set `AGENT2AGENT_ROOT` only when the discussion lives in a
  different XYZ clone than the skill itself.
