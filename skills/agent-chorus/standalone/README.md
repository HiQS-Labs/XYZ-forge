# AgentChorus

**Let your AI coding agents talk to each other — across terminals, harnesses, models, and UIs.**

Agent2Agent is local-first agent coordination for multi-agent development workflows. Install one
lightweight skill package and your Claude, Codex, and other coding-agent sessions can exchange
context through a serialized local discussion — no new platform to operate, no hosted service, no
database. Just one copy and paste.

Install in under 2 minutes. Start your first agent conversation in about 3.

🌐 **[agent-chorus install & docs](https://agent2agent.me/)** *(external site link retained until a new home is chosen; the Agent2Agent name is being phased out — see #193)*

## Why AgentChorus

- **Skill-first setup** — one installer drops the skill into every supported agent harness.
- **Local-first** — coordination runs on a local helper and durable files; nothing leaves your machine.
- **Model and harness agnostic** — mix Claude, Codex, and others in the same discussion.
- **Two or more agents** — stable rosters, not just fixed pairings.
- **Durable shared context** — every turn is recorded in a readable discussion file.
- **Explicit turn routing** — serialized turns keep the conversation orderly and inspectable.

Great for builder-reviewer workflows, cross-model technical review, debugging, pull request
review, and session-to-session handoffs.

## How it works

1. **Install the skill.** Run the lightweight installer once — it's idempotent and takes under 2 minutes.
2. **Ask your agent to start a session.** In plain language, e.g. *"Start an Agent2Agent session with Codex to review the new authentication protocol."* The starting agent packages the relevant conversation and repository context into Turn 1.
3. **Paste the invitation.** You get back a compact six-digit invitation — paste that (not the context packet) into each additional participant.
4. **Let them collaborate.** Agents take serialized turns over durable shared context, with a human-readable protocol you can inspect at any time.

## Quick start

```bash
bash skills/agent-chorus/install.sh
```

Then ask an installed agent:

```text
Start an Agent2Agent session with Codex to review the new authentication protocol.
```

See the [skill README](skills/agent-chorus/README.md) for requirements, installation details,
usage, and verification.

## Package

- [`SKILL.md`](skills/agent-chorus/SKILL.md) — agent instructions and operating contract
- [`install.sh`](skills/agent-chorus/install.sh) — idempotent skill installer
- [`agent_chorus.py`](skills/agent-chorus/scripts/agent_chorus.py) — local coordination helper
- [`test-standalone.sh`](skills/agent-chorus/test-standalone.sh) — dependency-free smoke suite
- [`publish-manifest.tsv`](skills/agent-chorus/publish-manifest.tsv) — declared canonical publishing surface

## Source of truth

This repository is a generated standalone distribution. The canonical implementation lives in
[`HiQS-Labs/XYZ-forge`](https://github.com/HiQS-Labs/XYZ-forge) under `skills/agent-chorus/`; the
exact source commit is recorded in `.xyz-canonical-revision`. Changes must land there first and
then be published one way into this repository.

## License

Agent2Agent is licensed under the [GNU AGPL-3.0-only](LICENSE), with optional proprietary terms
described in the [commercial license guide](LICENSE-COMMERCIAL.md). It is provided **as is**, without
warranty of any kind, to the extent permitted by the governing license and applicable law.
