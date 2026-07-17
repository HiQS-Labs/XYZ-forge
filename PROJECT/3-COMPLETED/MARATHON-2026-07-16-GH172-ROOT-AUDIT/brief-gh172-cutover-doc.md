---
title: "Phase brief: GH-172 root contract write-up + cutover recommendation (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-07-16
updated: 2026-07-16
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh172-cutover-doc phase —
  not itself an active-doc capture; the canonical capture doc is GH-172-VENDORED-ROOT-AUDIT.md one
  level up.
roadmap_exempt: true
---

## Status

| What was just completed | What's next |
|---|---|
| Brief authored 2026-07-16. | Fire this phase via the marathon, after gh172-vendored-e2e lands. |

## Phase: gh172-cutover-doc — final write-up and explicit cutover recommendation

Full context: [GH-172-VENDORED-ROOT-AUDIT.md](../../3-COMPLETED/GH-172-VENDORED-ROOT-AUDIT.md).
GitHub issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/172

This is a **writing and synthesis phase**, not a code-fixing phase. Read all three prior artifacts
before writing anything:

- `GH-172-BASH-AUDIT-FINDINGS.md`
- `GH-172-PYTHON-AUDIT-FINDINGS.md`
- The Phase 0 findings already recorded in the parent capture doc

### What to build

1. **Update `PROJECT/2-WORKING/GH-172-VENDORED-ROOT-AUDIT.md`**: add a "Root contract (final)" section
   restating the three-root contract as the durable, canonical statement (this doc is already linked
   from `ROADMAP.md`, so it is the intended durable home — do not assume a different doc needs to
   carry it unless you find one already claims that role and would conflict).
2. **Write `PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-CUTOVER-RECOMMENDATION.md`**
   containing, at minimum:
   - Every remaining known Bash/Python parity gap, if any (pull directly from the two findings docs —
     do not re-audit).
   - An explicit yes/no: is it safe to cut a stable Bash branch? State the reasoning.
   - An explicit yes/no: is it safe to switch `main` to Python-default mode (`XYZ_PYTHON=1` becoming
     default)? State the reasoning.
   - If either is "not safe," list the specific blocking gap(s) by file and finding — not a vague
     caveat.

### Non-goals (do not do these in this phase)

- Do not switch `main` to Python-default mode.
- Do not delete the Bash path.
- Do not re-run the Bash or Python audits — trust the two findings docs; if you spot something they
  clearly missed, note it as an open item in the recommendation doc rather than silently fixing it
  here (scope creep in a synthesis phase is exactly what turned GH-209 broad in the prior marathon).

### Acceptance / done means

- Both documents above exist and are internally consistent with the two findings docs (no claim in
  the recommendation doc should contradict what a findings doc actually reported).
- The cutover recommendation gives an unambiguous yes/no on both questions, not a hedge.
- `bash validate.sh` green (or unchanged from before your change — the pre-existing `#208`
  environment red is expected and not yours to fix). This phase should not touch code at all; if
  `validate.sh`'s result changes, that's a signal you edited something out of scope.
