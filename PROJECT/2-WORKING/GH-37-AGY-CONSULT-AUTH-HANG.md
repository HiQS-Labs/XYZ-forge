---
title: agy consult lane hangs on expired auth — fast pre-flight probe
status: Active (2-WORKING)
created: 2026-06-28
updated: 2026-06-28
owner: noelsaw1
branch: main
gh_issue: 37
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/37
doc_type: project
complexity: low
risk: low
effort: low
ratings_provisional: true
goal: >
  Make the agy (Antigravity) lane fail FAST when its session auth has expired, instead of opening an
  interactive browser prompt and hanging to the 300s cap — so a cross-model consult degrades to
  Codex-only in seconds with the real cause, not after a 5-minute silent stall.
---

## Status

| What was just completed | What's next |
|---|---|
| Promoted from `1-INBOX` to a marathon-ready capture doc with a Swarm Preflight Contract (2026-06-28). Root cause confirmed: expired token → agy attempts interactive re-auth in a non-interactive context (stdin `/dev/null`, no TTY) → blocks on a `[Y/n]` it can never receive → `consult.sh` SIGKILLs at 300s. | Fire the lane (**Codex builder** — agy is the broken subject, so it cannot reliably build its own fix; agy stays reviewer-only if authed). Add a fast auth pre-flight in the agy shim path; skip the lane in seconds naming `agy auth expired → run \`agy login\``. |

## Asks (acceptance criteria)
- [ ] Fast pre-flight auth probe (e.g. a short-timeout `agy whoami`/token check) in the agy shim /
  `consult.sh`; on failure **skip the agy lane within seconds** with a message naming the remedy
  (`agy auth expired → run \`agy login\``), not a 300s hang.
- [ ] Alternatively force non-interactive failure so an expired token exits non-zero immediately.
- [ ] Document the `agy login` re-auth step where the agy harness is described.
- [ ] Re-verify: valid auth → agy lane answers; expired auth → consult degrades fast with the real cause.
- [ ] `bash validate.sh` green; Codex lane behavior unchanged.

## Lane note
**Builder = Codex** (deliberate): GH-37 is the agy-auth failure itself, so an agy builder lane would hit
the very hang it is meant to fix. agy may serve as reviewer **only if** its auth is valid that session;
otherwise Codex self-review or a Claude inline review. The fix is shim-scoped — the containment kernel
(`relay-turn-lib.sh`, `bin/`, `.tick/`) is off-lane.

## Swarm Preflight Contract
```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "relay-automation/consult.sh", "pattern": "GH-37" } ],
  "artifacts":   [ "relay-automation/consult.sh", "relay-automation/agy-turn.sh" ],
  "remediation": { "source": "self#asks", "criteria": "Fast agy auth pre-flight: expired auth skips the lane in seconds with the agy login remedy; no 300s hang." },
  "lanes":       { "agy_safe": [], "orchestrator_only": [ "bin/", ".tick/", "relay-automation/relay-turn-lib.sh" ] }
}
```

## Related
- #20 (agy first-class footing, closed), #22 (agy worktree data loss, closed).
- `PROJECT/1-INBOX/AGY-RELIABILITY-TESTING.md`, `PROJECT/1-INBOX/agy-1.0.10-hang-bug-report.md`.
- Promoted from the 1-INBOX intake (2026-06-28) on adding the preflight contract.
