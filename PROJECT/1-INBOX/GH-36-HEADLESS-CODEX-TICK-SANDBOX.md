---
gh_issue: 36
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/36
title: Headless Codex isolated-turn friction — .tick/ lock outside the workspace sandbox + relay-file-at-HEAD
status: Proposed (1-INBOX — not yet active)
created: 2026-06-28
doc_type: feedback
---

# GH-36 · Headless Codex isolated-turn friction

Field feedback from driving Codex through the harness for a single-turn review (KWFS #73 QA relay).
Two adjustments were needed to make a headless Codex turn work; both reproduce in the code. **Containment
was not compromised** — the harness's worktree + empty allowlist + `rtl_enforce` held (Codex only wrote
the relay file). These are ergonomics/robustness fixes, not containment holes.

## Finding 1 (primary) — Codex sandbox can't write the shared `.tick/` lock under worktree isolation

Under `RELAY_WORKTREE_ISOLATION=1` (the driven default), Codex's CWD is the throwaway worktree, but the
shared coordination state `.tick/` lives at `TICK_REPO_ROOT` = the harness root
([codex-turn.sh:57](../../relay-automation/codex-turn.sh)) — **outside Codex's workspace**. The default
`CODEX_FLAGS='-s workspace-write'` ([codex-turn.sh:64](../../relay-automation/codex-turn.sh)) therefore
can't write `.tick/locks` for claim/release → the token never releases → deadlock. Field fix:
`CODEX_FLAGS='--dangerously-bypass-approvals-and-sandbox'` (works, but a broad hammer). The shim already
half-documents this ([codex-turn.sh:17-20](../../relay-automation/codex-turn.sh)) as an opt-in escalation,
so it silently deadlocks when missed.

Fix directions (surgical preferred):
- Detect isolation + add the harness root (or just `.tick/`) as a Codex **writable root** (e.g.
  `-c sandbox_workspace_write.writable_roots=…`) so the token write is permitted without a full bypass.
- OR a loud **preflight**: if a dry `.tick/` write would be sandboxed, fail fast with the exact remedy.
- OR default the bypass under isolation, justified by "the harness contains Codex, not Codex's own sandbox"
  (field-confirmed safe), and document the reasoning. Likely applies to **agy** too.

## Finding 2 (secondary, mostly done) — relay file must be at HEAD before an isolated drive

The worktree runs at `ROOT@HEAD`, so an untracked relay thread is invisible to the turn. **Already
mitigated by GH-32 Phase 1** (`relay-drive.sh` warns when isolation=1 and `RELAY_FILE` isn't at HEAD).
Residual: the warn lives only in `relay-drive.sh`, not the shared worktree path, so a directly-driven shim
doesn't warn. Small follow-up: surface the warn from `rtl_worktree_begin` (covers all shims); consider
auto-staging the relay file.

## Acceptance

- A headless isolated Codex turn claims/releases the token with the **default** flags, or fails fast with
  the exact remedy (no silent deadlock).
- The relay-file-at-HEAD warn fires regardless of which shim/driver is used.
- `./validate.sh` green; containment behavior unchanged (worktree + off-lane still hold).
</content>
