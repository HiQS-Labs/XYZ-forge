---
title: debug-mantra — add explicit Root Cause Analysis gate (root vs proximate cause, symptom-fix trap, RC ledger statement)
status: Proposed (1-INBOX — not yet active)
created: 2026-09-21
owner: agent-b
gh_issue: 737
source: https://github.com/HiQS-Labs/XYZ-forge/issues/737
doc_type: feedback
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
harness_commit: b804b584
non_goals:
  - Changing the verbatim mantra recitation block
  - Any script, harness, or test machinery — docs-only skill sharpening
related:
  - GH-603 (merge-cleanup discipline mantra block — same "sharpen a skill" class)
goal: >
  debug-mantra stops accepting the nearest proximate cause as the root cause. Mantra 3 gains
  a root-vs-proximate check, a named symptom-fix-trap anti-pattern, mantra 4 gains a one-line
  RC close-out statement, and the plan pivot table mirrors the check.
---

# GH-737 — debug-mantra: explicit Root Cause Analysis gate

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet.

## Why
The skill hunts a root cause (mantra 3: "does it explain the symptom end-to-end?") but never asks
whether the accepted hypothesis is the *root* or merely the *proximate* cause. Grounding (mantra 1)
covers observation depth, not causation depth. A guard at the crash site passes all four mantras
while the upstream state defect survives.

## Recon (docs-only: instruction/consumer path)
- Source: `skills/debug-mantra/SKILL.md` (94 lines). Mantra 3 at lines 46–55, mantra 4 at 57–62,
  plan pivot table rows at 72–75, self-check list at ~85–94.
- Consumers: `/debug-mantra` direct invocation; `workhorse` and `start-task` load it by name for
  ground truth / acceptance criteria. Neither parses the file — prose-only change, zero blast radius.
- Deployed copies: `~/.claude/skills/debug-mantra` is a symlink to the primary clone (GH-660 drift
  rule: edit only the repo source).

## Plan (surgical, single ordered list)
1. Mantra 3: insert a "Root cause or proximate cause?" bullet block — class-vs-instance test,
   "what let that happen?" until the answer is a design/contract/state-origin.
2. Same section: name the **symptom-fix trap** anti-pattern.
3. Mantra 4: add the close-out RC statement line.
4. Plan table row 3: mirror the class-vs-instance check for acceptance criteria.
5. Verify recitation block byte-identical (`diff` of lines 1–19 against origin/development).

## Acceptance
- `rg -c 'proximate' skills/debug-mantra/SKILL.md` ≥ 2; `rg -c 'symptom-fix trap'` ≥ 1;
  `rg -c 'Root cause:'` ≥ 1. Red control: all three return 0 on origin/development.
- `git diff origin/development -- skills/debug-mantra/SKILL.md | rg '^[-+]> '` prints nothing
  (recitation block untouched).
- Codex final relay QA Approved.

## Rating rationale (2026-09-21)
pri 45 / sev 30 / appeal 50 (neutral, no operator preference) / effort 95 (quick win, prose only).
No incident history: the gap is a skill-quality observation from the operator, not a recurring defect
class (unknown trend, not zero). Severity moderate: a wrong-site fix is real waste but recoverable.
