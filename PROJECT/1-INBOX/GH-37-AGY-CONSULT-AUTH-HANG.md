---
gh_issue: 37
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/37
title: "consult/relay: agy lane hangs to the 300s cap on expired auth"
status: Proposed (1-INBOX — not yet active)
created: 2026-06-27
doc_type: bugfix
---

# GH-37 — agy consult lane hangs on expired auth

Capture of [#37](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/37). The live issue is the discussion surface; this is the in-repo back-reference.

## Bug

The agy (Antigravity CLI) lane fails on every headless `consult` / relay run when agy's session auth has expired: instead of failing fast it prints an **interactive browser auth prompt** (`Opening authentication page in your browser. Do you want to continue? [Y/n]:`) and blocks on stdin, hanging until `consult.sh`'s **300s cap SIGKILLs it** (`Killed: 9`). Every cross-model consult silently degrades to **Codex-only**.

- agy **1.0.13**; harness `relay-automation/consult.sh` (`agy ... < /dev/null`, headless).
- Reproduced twice 2026-06-27: `relay-system/2026-06-27/p51-design-080020/p51-design.gemini.md` and `.../refresh-v1-qa-agy-213426/refresh-v1-qa-agy.gemini.md`. Codex lane passed both → agy-specific.

## Root cause

Expired token → agy attempts interactive browser re-auth in a non-interactive context (no TTY, stdin `/dev/null`), waits on a `[Y/n]` it can never receive, blocks to the timeout. It neither re-auths nor exits non-zero quickly.

## Asks (acceptance criteria)

- [ ] Pre-flight auth check (fast `agy whoami`/token probe) in the agy shim / `consult.sh`; on failure **skip the lane within seconds** naming "agy auth expired → run `agy login`", not a 300s hang.
- [ ] Or force non-interactive failure (no-login flag/env) so an expired token exits non-zero immediately.
- [ ] Document the `agy login` re-auth step where the agy harness is described.
- [ ] Re-verify: with valid auth the agy lane answers; with expired auth the consult degrades fast with the real cause.

## Related

- #20 (agy first-class footing, closed), #22 (agy worktree data loss, closed).
- `PROJECT/1-INBOX/AGY-RELIABILITY-TESTING.md`, `PROJECT/1-INBOX/agy-1.0.10-hang-bug-report.md` — sibling agy fragility notes.
