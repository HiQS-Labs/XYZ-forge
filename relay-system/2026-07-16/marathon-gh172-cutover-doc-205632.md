# Marathon Phase gh172-cutover-doc
STATUS: Approved
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH172-CUTOVER-DOC-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

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

Full context: [GH-172-VENDORED-ROOT-AUDIT.md](../GH-172-VENDORED-ROOT-AUDIT.md).
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

---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): PROJECT/2-WORKING/GH-172-VENDORED-ROOT-AUDIT.md,PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-CUTOVER-RECOMMENDATION.md
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH172-CUTOVER-DOC-TURN --agent codex --paths "phases/gh172-root-audit--gh172-cutover-doc/RELAY.md,PROJECT/2-WORKING/GH-172-VENDORED-ROOT-AUDIT.md,PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-CUTOVER-RECOMMENDATION.md"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH172-CUTOVER-DOC-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH172-CUTOVER-DOC-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gh172-root-audit--gh172-cutover-doc/RELAY.md and PROJECT/2-WORKING/GH-172-VENDORED-ROOT-AUDIT.md,PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-CUTOVER-RECOMMENDATION.md. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: PROJECT/2-WORKING/GH-172-VENDORED-ROOT-AUDIT.md,PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-CUTOVER-RECOMMENDATION.md.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH172-CUTOVER-DOC-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH172-CUTOVER-DOC-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh172-root-audit--gh172-cutover-doc/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · codex

Files touched:
- `PROJECT/2-WORKING/GH-172-VENDORED-ROOT-AUDIT.md`
- `PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-CUTOVER-RECOMMENDATION.md`
- `phases/gh172-root-audit--gh172-cutover-doc/RELAY.md`

What I changed:
- Added `Root contract (final)` to the canonical GH-172 capture doc, making the three-root contract
  explicit as the durable statement of record.
- Wrote the cutover recommendation doc from the recorded Phase 0, Bash, and Python findings only.
- Made the cutover calls unambiguous: safe to cut a stable Bash branch = **Yes**; safe to switch
  `main` to Python-default (`XYZ_PYTHON=1`) = **No**.

Key decision:
- The lone blocker in the recorded findings is Python-side consult parity:
  `utils/py/consult.py` still lacks the Bash degraded-panel `SINGLE-MODEL — NOT RECONCILED`
  stamping path, and the findings doc records that this keeps `XYZ_PYTHON=1 bash test/consult.sh`
  red. I treated that as a Python-default blocker but not a Bash-branch blocker.

Verification:
- Scoped PDDA checks passed for both edited docs via `PDDA_ONLY_FILE=... utils/pdda/pdda.sh frontmatter`
  and `PDDA_ONLY_FILE=... utils/pdda/pdda.sh status-table`.
- Repo-wide `utils/pdda/pdda.sh status-table` is still red on the older
  `GH-172-BASH-AUDIT-FINDINGS.md` and `GH-172-PYTHON-AUDIT-FINDINGS.md` artifacts, which I was not
  allowed to edit in this turn.

### Round 1 · Reviewer · agy

**Verdict:** Approved

The builder correctly updated the durable root contract in `PROJECT/2-WORKING/GH-172-VENDORED-ROOT-AUDIT.md` and authored the final cutover recommendation in `PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-CUTOVER-RECOMMENDATION.md`. The recommendation clearly states it is safe to cut a Bash branch and unsafe to switch to Python-default (due to the gap in `utils/py/consult.py`). The PDDA specific checks pass and both docs meet the acceptance criteria.
