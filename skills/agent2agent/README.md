# Agent2Agent

Agent2Agent lets two or more supported agent sessions hold a serialized, local discussion about the
same repository. Install the lightweight skill package, ask one agent to start a discussion,
and paste only its six-digit invitation into the other sessions. The starting agent prepares and
embeds the goal, scope, evidence, constraints, questions, and done condition as Turn 1.

> **Note:** This README ships in two repositories: the canonical
> [XYZ Forge](https://github.com/HiQS-Suite/XYZ-forge) repository and the standalone
> [Agent2Agent-Skill](https://github.com/HiQS-Labs/Agent2Agent-Skill) distribution. The
> instructions below apply to whichever repository you cloned; edits must land in XYZ Forge
> first and are published one way into the standalone repository.

## Requirements

- A local clone of this repository that every participating agent can access
- Python 3, Bash, and Git
- A supported skill-aware agent harness, such as Claude Code, Codex, or a supported Gemini surface

## Install

From the repository root, run:

```bash
bash skills/agent2agent/install.sh
```

The idempotent installer symlinks this repo-backed skill into the standard skill directories for
Claude Code, Codex, Gemini Config, Gemini Antigravity, and Gemini Antigravity CLI. Restart or open a
new agent session if the harness does not discover newly installed skills automatically.

The installation is intentionally small: `SKILL.md` contains the agent instructions and the bundled
Python helper manages the local discussion protocol. No hosted service or database is required.

## Start a discussion

Ask your first agent in plain language, for example:

```text
Start an Agent2Agent session with Codex to review the new authentication protocol.
```

The agent infers the intent from the recent conversation, asks focused clarification only when
needed, prepares the context packet, creates the discussion, and returns one invitation for each
additional participant:

```text
Join XYZ agent2agent #123456 as agent number two to discuss: "Review the new authentication protocol"
```

Paste each invitation—without a second context block—into its intended agent session. Agent2Agent
keeps one active writer at a time, routes turns among the declared participants, and uses one
`conversation.md` as both the live canvas and raw transcript. New sessions default to an
`Agent2Agent-Transcripts/` folder beside the canonical repository, outside Git; runtime locks and
watch markers stay in the session's `runtime/` directory. Set `AGENT2AGENT_HOME` or pass
`--store` to select another private external location. Persist one user-level default with:

```bash
"$(git rev-parse --show-toplevel)/skills/agent2agent/scripts/agent2agent.py" configure-store \
  --path /private/path/to/Agent2Agent-Transcripts
```

Legacy `relay-system/` sessions remain readable and writable in place. To archive them, copy the
dated directories to private storage while closed; do not rename them into the live external store
or delete them automatically. A future migration tool must preserve each raw conversation rather
than create a second live canvas.

For watch, doorbell, hands-free drive, status, and protocol details, see [SKILL.md](./SKILL.md).

The helper also makes four common long-running-discussion transitions explicit:

- `extend` records an operator follow-up and replaces the live done condition without an ad hoc turn.
- `close` requires a structured final consensus unless `--trivial` explicitly marks an administrative close.
- `send`, `extend`, and `close` accept `--check-clean` when a Git handoff claims that work is clean and pushed.
- `ping` refreshes a participant heartbeat without changing the canonical transcript; `--stale-after`
  changes the default 30-minute inactive-seat threshold.

## Verify

Run the skill's dependency-free smoke suite from the repository root:

```bash
bash skills/agent2agent/test-standalone.sh
```

## Publish the standalone distribution

XYZ Forge is canonical. `publish-manifest.tsv` declares every file shipped to the standalone
repository, including its README, CI workflow, tests, metadata, and licenses. Preview by default,
then publish only from a clean committed canonical revision:

```bash
bash skills/agent2agent/sync-to-standalone.sh --preview
bash skills/agent2agent/sync-to-standalone.sh --apply
bash skills/agent2agent/sync-to-standalone.sh --check
```

Set `AGENT2AGENT_STANDALONE_REPO` to select another checkout. The publisher refuses undeclared
tracked destination files, preserves declared executable modes, verifies byte parity, and records
the exact XYZ commit in `.xyz-canonical-revision`. Standalone changes never sync back automatically.

## License

- Agent2Agent inherits this repository's default [GNU AGPL-3.0-only license](../../LICENSE); optional proprietary use is described in the [commercial license guide](../../LICENSE-COMMERCIAL.md).
- The software is provided **as is**, without warranty of any kind, to the extent permitted by the governing license and applicable law.
