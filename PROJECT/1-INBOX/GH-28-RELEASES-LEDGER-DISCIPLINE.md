---
gh_issue: 28
source: https://github.com/HiQS-Suite/XYZ-forge/issues/28
title: "RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue"
status: Proposed (1-INBOX — not yet active)
created: 2026-08-18
doc_type: feedback
effort: 2
complexity: 2
risk: 1
phases: 2
---

# GH-28: RELEASES.md Ledger Discipline

## Context & Purpose

`RELEASES.md` is contracted to be ~90% pointers/manifest (`PROJECT/PDDA.md` → "RELEASES.md — release
ledger"), with a narrative discipline rubric already living in `skills/releases/SKILL.md`
("Discipline and abuse warnings" — Description ≤4 sentences, Manifest ≤7 issues, no execution-history
prose). In practice the ledger keeps ballooning anyway: status appendices, run logs, and dated notes
get written directly into `Description:`/`Exit criterion:`/`Manifest:` fields.

**Concrete instance (Ballast 0.7.0, 2026-08-17):** a multi-line "BUILT 2026-08-17" status appendix was
added directly to the `Exit criterion:` field mid-release-gate-work — exactly the violation the skill
already warns against.

## Root cause (two gaps, not one)

1. **No enforcement teeth.** The discipline rubric only fires when someone explicitly runs
   `/releases clean`. The deterministic checker (`check_releases()` in `utils/pdda/pdda.sh`) validates
   structure only (version present, date format, QA yes/no fields) and is deliberately warn-only by
   design — it never blocks, per `PROJECT/PDDA.md` section J.
2. **No other legitimate home for release-level notes.** Manifest members each get their own GH issue;
   the release ledger entry itself (e.g. "Ballast 0.7.0") has none, so status/run-log notes go inline
   in `RELEASES.md` by necessity.

## Proposed fix (lightest viable — no new skill, no new scanner binary)

1. Add a `Tracking Issue:` field to the `RELEASES.md` block spec (`PROJECT/PDDA.md` contract +
   `skills/releases/SKILL.md`'s plan-subroutine template). Extends the existing Issue-first SOP
   (`PROJECT/PDDA.md` → "GitHub issue intake") to the release ledger itself. Release-level status/run-log
   notes go there, not inline in the ledger.
2. Extend `check_releases()` in `utils/pdda/pdda.sh` with a few deterministic bloat checks:
   - `Description:` exceeding 4 sentences
   - `Manifest:` exceeding 7 tokens
   - `Exit criterion:` or `Manifest:` spanning multiple lines (the shape a pasted status appendix takes)
   Same line-based-check style already used in that function — no LLM needed for detection.
3. Flip only the *new* checks to blocking; leave existing structural checks warn-only as today, so
   sparse/missing-file tolerance is unaffected.
4. `/releases clean`'s existing LLM rubric remains the fix-up drafting tool once a violation is
   flagged by (2) — never the detector. Matches this repo's deterministic-before-LLM constitution rule.

## Sequencing

Queued as a **post-Ballast 0.7.0 follow-up** — not a Ballast manifest member, no dependency on the
in-flight release-gate run.

---

## Acceptance Criteria
- [ ] `Tracking Issue:` field documented in `PROJECT/PDDA.md`'s RELEASES.md contract and
      `skills/releases/SKILL.md`'s plan-subroutine template.
- [ ] `check_releases()` flags Description/Manifest/Exit-criterion bloat deterministically, with a
      registered regression test.
- [ ] The new bloat checks block (non-zero exit) while existing structural checks remain warn-only.
- [ ] `skills/releases/SKILL.md`'s discipline section cross-references the new field/checks instead of
      relying solely on manual `/releases clean` invocation.
