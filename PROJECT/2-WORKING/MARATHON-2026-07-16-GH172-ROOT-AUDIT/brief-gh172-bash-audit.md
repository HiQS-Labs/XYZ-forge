---
title: "Phase brief: GH-172 Bash entry-point root-contract audit (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-07-16
updated: 2026-07-16
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh172-bash-audit phase —
  not itself an active-doc capture; the canonical capture doc is GH-172-VENDORED-ROOT-AUDIT.md one
  level up.
roadmap_exempt: true
---

## Status

| What was just completed | What's next |
|---|---|
| Brief authored 2026-07-16. | Fire this phase via the marathon. |

## Phase: gh172-bash-audit — audit remaining Bash entry points against the root contract

Full context: [GH-172-VENDORED-ROOT-AUDIT.md](../GH-172-VENDORED-ROOT-AUDIT.md).
GitHub issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/172

### Root contract (read this first)

In a vendored consumer repo, three roots are distinct and must stay distinct:

1. **Harness install root** — where `.xyz/relay-automation`, `.xyz/bin/tick`, `.xyz/utils/py` live.
2. **Coordination root** — where `.tick/` lives (`TICK_REPO_ROOT`).
3. **Target/work root** — where the editable repo + throwaway worktrees live.

**Never re-derive one of these from another** when the orchestrator already handed the right one in.
The tick binary path and the tick repo root are always resolved separately.

### Already audited and fixed — do NOT re-touch these

`utils/py/agy-turn.py`'s claim guard, Bash/Python `claude-turn` ownership + cost capture, and Python
`poll.py`'s tick-binary fallback were already fixed and verified in Phase 0 (see the parent doc's
"Findings written back from the audit" section and Phase 0 checklist — all checked). Reading them for
context is fine; editing them is out of scope for this phase.

### What to audit (in scope)

For each of the following, confirm or fix:

- does it distinguish harness-install root vs `TICK_REPO_ROOT` vs target/work root?
- does it resolve the **tick binary** separately from the **tick repo root**?
- does it preserve an orchestrator-pinned root instead of overwriting it locally?
- if it is a driven worker shim, does it prove token ownership before launch?
- does worktree isolation still point at the correct shared `.tick` location?

Files:

- `relay-automation/marathon-drive.sh`
- `relay-automation/relay-drive.sh`
- `relay-automation/marathon-agent.sh`
- `relay-automation/relay-turn-lib.sh` (kernel-sensitive — orchestrator_only lane; if you find a real
  gap here, fix it narrowly and flag it prominently in the findings doc rather than restructuring it)
- `relay-automation/aider-turn.sh`
- `relay-automation/consult.sh`
- `relay-automation/relay-loop.sh`
- `relay-automation/watchdog.sh`
- `relay-automation/runner.sh`
- `utils/swarm-preflight.sh`

### What to build

Write your findings to a new file,
`PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-BASH-AUDIT-FINDINGS.md`, one
subsection per file audited: what you checked, verdict (clean / gap found), and if a gap was found,
what you fixed and how you verified it (which test, what it now proves). If a file is already clean,
say so plainly — a clean audit result is a valid, useful outcome; do not manufacture a fix.

Only edit a Bash file in the list above if your audit finds a genuine gap against the root contract.
Do not refactor, rename, or restructure a file that's already compliant.

### Acceptance / done means

- `GH-172-BASH-AUDIT-FINDINGS.md` exists and covers every file in the list above.
- Any fix made is covered by an existing or new regression test; name it in the findings doc.
- `bash validate.sh` green (or unchanged from before your change — the pre-existing `#208`
  environment red is expected and not yours to fix).
- Do NOT touch `utils/py/agy-turn.py`, `relay-automation/claude-turn.sh`, `utils/py/claude-turn.py`,
  or `utils/py/poll.py` — already fixed in Phase 0.
