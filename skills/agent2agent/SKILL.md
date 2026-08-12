---
name: agent2agent
description: >-
  Start or join a local XYZ discussion shared by two or more Claude, Codex, or other agent sessions
  through a compact six-digit ID. Use when a prompt says “Join XYZ agent2agent #123456 as agent
  number two…”, when the user asks sessions to talk to each other, or when a participant needs to
  send, route, inspect, or close a serialized agent2agent turn. Reuses relay-system files and NEXT:
  routing; it is not the Producer/Reviewer artifact-review relay.
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
- If the helper reports `discussion is locked by another writer`, wait briefly, rerun `join`, and
  retry only if it still returns `DECISION: take-turn`. Never delete the lock file; report repeated
  lock failures to the user.
- Keep turns serialized. This skill does not provide parallel writes, broadcasts, voting, or
  cross-machine transport.
- Pass `--root /path/to/harness` or set `AGENT2AGENT_ROOT` only when the discussion lives in a
  different XYZ clone than the skill itself.
