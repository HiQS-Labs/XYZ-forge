---
title: relay-drive attest-publish-failed when relay file is under a gitignored path
status: Proposed (1-INBOX — not yet active)
created: 2026-11-11
owner: Noel Saw
gh_issue: 1423
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1423
doc_type: bugfix
complexity: 2
risk: 2
effort: 1
phases: 1
ratings_provisional: true
reported_from: rebalanceOS
harness_commit: 966290ddd
non_goals:
  - changing which repos gitignore relay-system/
  - hiding genuine relay-file commit failures
related:
  - HiQS-Labs/rebalanceOS#375
goal: >
  An approval whose attestation commit lands is attested (exit 0) even when the relay file sits
  under a gitignored-but-tracked path; genuine commit failures still refuse.
---

# GH-1423 — relay-drive attest-publish-failed when relay file is under a gitignored path

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Symptom
relay-drive exits 4 (`attest-publish-failed`) when relay-system/ is gitignored in the target repo, though the attestation commit (a278102) lands.

## Environment
- **Observed from:** `rebalanceOS` (centralized harness)
- **Harness commit:** `966290ddd`
- **Worker/CLI:** codex (reviewer)
- **Runtime:** Python (default) — `utils/py/relay_drive.py`
- **Sandbox:** unknown (delegated run)

## Reproduction
1. In a rebalanceOS task clone (`.gitignore:143` = `relay-system/`), run `relay-drive.sh --review-once` on a tracked relay file under `relay-system/`.
2. TODO(operator): exact invocation and `git add` stderr from the delegated run transcript.

**Expected:** attested, exit 0 (or the existing untracked/ignored skip branch, `relay_drive.py:677-680`).
**Observed:** exit 4 `attest-publish-failed`; commit `a278102` present anyway.
**Frequency:** once so far

## Impact
Plan-QA approvals refused in repos that ignore `relay-system/`; workaround: put the relay file under a non-ignored path (final QA under `TESTS-RESULTS/` exited 0).

## Diagnosis pointer (unconfirmed)
`utils/py/relay_drive.py:670-686` `commit_relay_file` runs `git add` then `git commit -- <file>` unconditionally and fails if either is nonzero, so a failed add with a landed commit still returns False → `judge_terminal` refuses at `:772-773`. Why `git add` failed for a tracked file is not established.

## Phase 0 — Diagnose & scope
> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist
- [ ] Reproduce it in the intake repo (not just in the reporting repo)
- [ ] Locate the responsible script/path — name the concrete write-set
- [ ] Decide fix vs. guard-and-document; reuse an existing code path before adding one (`/ponytail`)
- [ ] Set/correct the triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [ ] The repro is confirmed from the report, not assumed
- [ ] An existing suite, or a recorded manual check, covers the failure path before the fix lands (no new test suites: `AGENTS.md` *No new tests*, GH-831)
- [ ] The fix composes with the existing harness rather than adding a parallel path

## Merge evidence

- PR #1424 merged 2026-11-12 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
