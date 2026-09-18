---
gh_issue: 625
source: https://github.com/HiQS-Labs/XYZ-forge/issues/625
title: "GH-625: agent-chorus bridge — bind the HTTP server without socket.getfqdn() so the hosted macOS runner's suite goes green"
status: Complete
created: 2026-09-14
updated: 2026-09-15
owner: orchestrator (Claude Code) · builder codex · reviewer agy
doc_type: bugfix
effort: 1
complexity: 1
risk: 1
phases: 1
rating: "pri/sev/appeal/effort 85/90/90/80 · calc 345"
rating_ovr: null
is_manual_override: false
ratings_provisional: true
goal: test/agent-chorus-bridge.sh passes on the GitHub-hosted macOS runner so hosted wave-reconcile can qualify development again
related:
  - "https://github.com/HiQS-Labs/XYZ-forge/issues/619 — the other suite that was red on the runner; fixed by #607's test update (green on ab7ab1d5)"
  - "https://github.com/HiQS-Labs/XYZ-forge/issues/624 — merge-cleanup stop that made the hosted red visible"
---

# GH-625 — agent-chorus-bridge.sh red on the hosted macOS runner

## Status

| What was just completed | What's next |
|---|---|
| lane gh-625 approved by agy (round 1), gate green in 5 minutes: 5-line `server_bind` override + one test check with a negative control; CHANGELOG entry written | PR from `marathon/10days-2026-09-15`; post-merge: confirm the first hosted `wave-reconcile.yml` run no longer lists `agent-chorus-bridge.sh` in `failed:` |

Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified.

## Bug

`http.server.HTTPServer.server_bind` calls `socket.getfqdn(host)` to set `server_name`. On the
GitHub macOS runner that reverse lookup does not return inside the test's 4 s probe window
(`faulthandler` stack in the issue: `socket.py:817 getfqdn` ← `http/server.py:150 server_bind`
← `agent_chorus_bridge.py:744 start_bridge_server`), so the bridge never prints its banner or
the `--tunnel` refusal and A1 / A1b / A3 / A3b fail (39 passed, 4 failed on run 34901260733).
Locally: 43 passed, 0 failed. Hosted `wave-reconcile.yml` qualifies `development` with the full
suite first, so nothing merged since 2026-09-14 05:00 UTC has been reconciled by the hosted path.

Ground truth (this clone, `ab7ab1d5`): `class ThreadingHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer)`
at `skills/agent-chorus/scripts/agent_chorus_bridge.py:267`; the bind is `ThreadingHTTPServer((host, port), BridgeRequestHandler)`
at line 744; `rg -n server_bind skills/agent-chorus/scripts/agent_chorus_bridge.py` → 0 matches.

## Fix (smallest mechanism)

Override `server_bind` on the existing `ThreadingHTTPServer` subclass: call
`socketserver.TCPServer.server_bind(self)`, then set `self.server_name` from the bound host
(no DNS) and `self.server_port` from `self.socket.getsockname()[1]`. ~8 lines, stdlib only, no
behaviour change for callers. One check in `test/agent-chorus-bridge.sh` runs the bridge with
`socket.getfqdn` patched to block and asserts the banner still appears inside the probe window.

Test scope: `test/agent-chorus-bridge.sh` (one new check). Test non-scope: no runner
simulation, no DNS mocking framework, no change to the A-series checks themselves.

## Acceptance

- [ ] `skills/agent-chorus/scripts/agent_chorus_bridge.py` binds its HTTP server without calling `socket.getfqdn()`: `ThreadingHTTPServer` overrides `server_bind` to call `socketserver.TCPServer.server_bind(self)` and sets `server_name` / `server_port` from the bound socket (or an equivalent that never performs a reverse DNS lookup at bind time). No behaviour change for callers: `server_address`, the auth-posture banner, and every `--tunnel` path are unchanged.
- [ ] `test/agent-chorus-bridge.sh` gains one check that starts the bridge with `socket.getfqdn` patched to block (or raise) and asserts startup still reaches the banner / tunnel refusal within the existing 4 s probe window. Red control: the pre-fix server does not reach it under the same patch.
- [ ] `bash test/agent-chorus-bridge.sh` is green locally (all checks pass, none skipped that ran before).
- [ ] Post-merge verification (not part of the lane): the first hosted `wave-reconcile.yml` run on `development` after this lands no longer lists `agent-chorus-bridge.sh` in `failed:`.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash test/agent-chorus-bridge.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "skills/agent-chorus/scripts/agent_chorus_bridge.py", "pattern": "def server_bind\\(self" } ],
  "artifacts":   [ "skills/agent-chorus/scripts/agent_chorus_bridge.py", "test/agent-chorus-bridge.sh" ],
  "remediation": { "source": "issue#625", "criteria": "bridge binds without a reverse DNS lookup; suite green on the hosted macOS runner" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [ ".tick/", "CHANGELOG.md", "releases.db", "releases.sql", "LEADERBOARD.md", "PROJECT/" ] }
}
```

## Lessons Learned (For Future Agents)

- A suite that is green locally and red only on a hosted runner is usually an environment-dependent stdlib default, not a code regression; the `faulthandler` stack in the issue named the exact frame (`socket.getfqdn` inside `HTTPServer.server_bind`), which made the fix a five-line override with no behaviour change.
- Test the property, not the runner: patching `socket.getfqdn` to raise and asserting the bridge still reaches its banner proves the bind path never resolves the FQDN anywhere, including on runners we cannot reproduce.
