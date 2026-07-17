---
title: "Phase brief: GH-172 Python entry-point parity audit (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-07-16
updated: 2026-07-16
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh172-python-audit phase —
  not itself an active-doc capture; the canonical capture doc is GH-172-VENDORED-ROOT-AUDIT.md one
  level up.
roadmap_exempt: true
---

## Status

| What was just completed | What's next |
|---|---|
| Brief authored 2026-07-16. | Fire this phase via the marathon, after gh172-bash-audit lands. |

## Phase: gh172-python-audit — Python parity against the hardened Bash contract

Full context: [GH-172-VENDORED-ROOT-AUDIT.md](../GH-172-VENDORED-ROOT-AUDIT.md).
GitHub issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/172

### Start here

Read `PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-BASH-AUDIT-FINDINGS.md` (produced
by the prior phase) before starting — any gap fixed there is the Bash-side reference behavior your
Python audit checks for parity against.

### Already audited and fixed — do NOT re-touch these

`utils/py/agy-turn.py`, Bash/Python `claude-turn`, and `utils/py/poll.py` were already fixed and
verified in Phase 0 (see the parent doc). Reading them for the shared-helper pattern they now use is
useful context; editing them is out of scope for this phase.

### What to audit (in scope)

For each of the following, confirm or fix:

- parity with the hardened Bash behavior (same file's Bash counterpart, or the closest analog)
- no stale re-derivation of the tick binary path from `TICK_REPO_ROOT`
- no stale re-derivation of the work root from the harness install root in vendored mode
- no missing ownership-before-launch guard where the Bash path already has one
- `XYZ_PYTHON=1` behavior matches the documented Bash contract for vendored `.xyz` runs

Files:

- `utils/py/marathon_drive.py` (kernel-sensitive — orchestrator_only lane)
- `utils/py/relay_drive.py`
- `utils/py/rtl.py` (kernel-sensitive — orchestrator_only lane; narrow fix only, flag prominently)
- `utils/py/aider-turn.py`
- `utils/py/consult.py`

### What to build

Write your findings to a new file,
`PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-PYTHON-AUDIT-FINDINGS.md`, one
subsection per file, same shape as the Bash findings doc: what you checked, verdict, and if a gap was
found, what you fixed and how you verified it. Call out explicitly whether each fix in the Bash
findings doc has a matching Python-side gap or is already covered — this cross-reference is what the
final cutover phase reads to state the safety verdict.

Only edit a Python file above if your audit finds a genuine parity gap. Do not refactor a file that's
already at parity.

### Acceptance / done means

- `GH-172-PYTHON-AUDIT-FINDINGS.md` exists, covers every file above, and cross-references the Bash
  findings doc for each corresponding fix.
- Any fix made is covered by an existing or new regression test; name it in the findings doc.
- `bash validate.sh` green (or unchanged from before your change — the pre-existing `#208`
  environment red is expected and not yours to fix). Also run `python3 -m py_compile` on any Python
  file you touch.
- Do NOT touch `utils/py/agy-turn.py`, `relay-automation/claude-turn.sh`, `utils/py/claude-turn.py`,
  or `utils/py/poll.py` — already fixed in Phase 0.
