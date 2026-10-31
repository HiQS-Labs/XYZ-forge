# Plan draft: #384 Explore a secure cross-device AgentChorus bridge over Cloudflare Tunnel

> draft; preflight and independent plan QA outstanding

- Request: `gh-384-ac524018cce3` (tick `slot_094`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 14/15/50/20
- Capture doc: PROJECT/2-WORKING/GH-384-AGENTCHORUS-CLOUDFLARE-BRIDGE.md (sha256 319e1c1182302094454c791ec4141cf1203d94dac9ffd664d10ec9be3972983f)
- Issue sha256: ac524018cce36e30d66cc49759c4db4c20ec041a7d9873500fdb37a86178e3b0 (updated 2026-10-30T18:28:18Z)
- Dependencies: none

## Scope

_Source: PROJECT/2-WORKING/GH-384-AGENTCHORUS-CLOUDFLARE-BRIDGE.md:L7 (frontmatter goal)_

Implement a thin localhost HTTP bridge and client for AgentChorus with Cloudflare Tunnel/Access authentication, capability tokens, and 10-minute idle leases while preserving single-writer locking and transcript invariants

## Acceptance criteria

_Source: issue#384:L129 (Spike acceptance criteria)_

- [ ] A local AgentChorus participant and a remote test client complete at least four alternating turns through a Quick Tunnel.
- [ ] All writes pass through the existing AgentChorus mutation path.
- [ ] Concurrent or duplicated `send` requests produce exactly one committed turn.
- [ ] Out-of-turn, stale-version, wrong-seat, missing-token, revoked-token, closed-session, and expired-session requests fail closed.
- [ ] Killing the bridge or tunnel cannot corrupt or partially replace `conversation.md`.
- [ ] Ten minutes of inactivity expires remote access while preserving the canonical transcript.
- [ ] Restarting the bridge can recover status from the existing transcript without inventing a turn.
- [ ] Logs and telemetry contain no message bodies or credentials.
- [ ] The remote client needs access only to the bridge API, never the repository or transcript filesystem.
- [ ] The spike documents whether a managed Tunnel + Access service-token policy is sufficient for a supported version.

## Open questions

_Source: issue#384:L151 (Open questions)_

- Should both local and remote participants use the HTTP adapter, or may the local participant continue using the CLI directly?
- Is HTTP polling sufficient, or is a managed-tunnel WebSocket path worthwhile after the spike?
- Should an expired session be resumable with a fresh capability, or always require a new/superseding AgentChorus discussion?
- What transcript redaction or explicit consent is required before sending discussion content through a third-party edge?
- Can the bridge reuse helper functions in-process safely, or should it invoke the CLI as a stricter compatibility boundary?
- What minimum client contract does an off-device AI need: arbitrary HTTPS requests, MCP, or a dedicated AgentChorus client?

## Write set

- `skills/2-daily/agent-chorus/scripts/agent_chorus.py` (issue#384:L9)
- `test/agent-chorus-bridge.sh` (PROJECT/2-WORKING/GH-384-AGENTCHORUS-CLOUDFLARE-BRIDGE.md:L121)
- `test/agent-chorus.sh` (PROJECT/2-WORKING/GH-384-AGENTCHORUS-CLOUDFLARE-BRIDGE.md:L132)
- `relay-system/2026-09-02/gh-384-agentchorus-cf-bridge-qa.md` (PROJECT/2-WORKING/GH-384-AGENTCHORUS-CLOUDFLARE-BRIDGE.md:L133)

## Unresolved file names

- none

## Contract probes

- none
