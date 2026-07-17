# Marathon Phase gh172-python-audit
STATUS: Approved
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH172-PYTHON-AUDIT-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

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

---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/py/marathon_drive.py,utils/py/relay_drive.py,utils/py/rtl.py,utils/py/aider-turn.py,utils/py/consult.py,PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-PYTHON-AUDIT-FINDINGS.md
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH172-PYTHON-AUDIT-TURN --agent codex --paths "phases/gh172-root-audit--gh172-python-audit/RELAY.md,utils/py/marathon_drive.py,utils/py/relay_drive.py,utils/py/rtl.py,utils/py/aider-turn.py,utils/py/consult.py,PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-PYTHON-AUDIT-FINDINGS.md"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH172-PYTHON-AUDIT-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH172-PYTHON-AUDIT-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gh172-root-audit--gh172-python-audit/RELAY.md and utils/py/marathon_drive.py,utils/py/relay_drive.py,utils/py/rtl.py,utils/py/aider-turn.py,utils/py/consult.py,PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-PYTHON-AUDIT-FINDINGS.md. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/marathon_drive.py,utils/py/relay_drive.py,utils/py/rtl.py,utils/py/aider-turn.py,utils/py/consult.py,PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-PYTHON-AUDIT-FINDINGS.md.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH172-PYTHON-AUDIT-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH172-PYTHON-AUDIT-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh172-root-audit--gh172-python-audit/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · codex

Files touched:
- `utils/py/relay_drive.py`
- `utils/py/consult.py`
- `PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-PYTHON-AUDIT-FINDINGS.md`

Key decisions:
- Left `utils/py/marathon_drive.py`, `utils/py/rtl.py`, and `utils/py/aider-turn.py` unchanged after
  auditing the GH-172 seams there; the findings doc records the clean verdicts and cross-references
  the Bash audit.
- Fixed the one direct Bash-findings match in `utils/py/consult.py`: Gemini JSON cost capture now
  resolves tick via the shared `rtl.py` helpers against `TICK_REPO_ROOT` instead of re-deriving
  `${CONSULT_ROOT}/bin/tick`.
- Fixed a separate Python/Bash drift in `utils/py/relay_drive.py`: the uncommitted-relay warning now
  matches the current Bash same-repo/different-repo split instead of always claiming the reviewer
  will find nothing.

Verification:
- `python3 -m py_compile utils/py/consult.py utils/py/relay_drive.py`
- `XYZ_PYTHON=1 bash test/poll-relay.sh` -> 12 pass, 0 fail
- Targeted smoke on 2026-07-17 for `utils/py/consult.py`: foreign `CONSULT_ROOT` + separate
  `TICK_REPO_ROOT` + `CONSULT_GEMINI_JSON=1` produced a `cost.tokens` event under the pinned
  coordination repo `.tick`.
- Targeted smoke on 2026-07-17 for `utils/py/relay_drive.py`: same-repo uncommitted relay emitted
  `NOTE`; cross-repo relay emitted `WARNING`; both reached dry-run.
- `XYZ_PYTHON=1 bash test/consult.sh` is still red for a broader pre-existing Python parity gap in
  degraded consult stamping (`SINGLE-MODEL — NOT RECONCILED`). I did not change that behavior in this
  GH-172 seam pass; the findings doc calls it out explicitly so it is not misattributed to the
  tick-root fix.

### Round 1 · Reviewer · agy

The builder codex successfully audited the Python files for parity against the hardened Bash contract.
The changes correctly address:
- `utils/py/consult.py`: Replaced direct tick path derivation with `rtl.py` helpers (`resolve_tick_bin`, `resolve_tick_repo_root`) and correctly passed `TICK_REPO_ROOT` into the subprocess environment for the Gemini JSON cost capture.
- `utils/py/relay_drive.py`: Ported the Bash-side warning split, differentiating same-repo untracked relay files (NOTE) from cross-repo untracked relay files (WARNING) using git's `--show-toplevel`.
- `PROJECT/2-WORKING/MARATHON-2026-07-16-GH172-ROOT-AUDIT/GH-172-PYTHON-AUDIT-FINDINGS.md`: Fully documented these changes and accurately recorded clean verdicts for the other files (`marathon_drive.py`, `rtl.py`, `aider-turn.py`). 

No further issues were found.

**Verdict:** Approved
