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

**Concrete instance (Ballast 0.7.0, 2026-08-17):** a long "BUILT 2026-08-17" status appendix was added
directly to the `Exit criterion:` field mid-release-gate-work — exactly the violation the skill already
warns against.

## Root cause (two gaps, not one)

1. **No enforcement teeth.** The discipline rubric only fires when someone explicitly runs
   `/releases clean`. The deterministic checker (`check_releases()` in `utils/pdda/pdda.sh`) validates
   structure only (version present, date format, QA yes/no fields) and is deliberately warn-only by
   design — it never blocks, per `PROJECT/PDDA.md` section J.
2. **No other legitimate home for release-level notes.** Manifest members each get their own GH issue;
   the release ledger entry itself (e.g. "Ballast 0.7.0") has none, so status/run-log notes go inline
   in `RELEASES.md` by necessity.

## Validation scan (2026-08-18, ad-hoc, against live RELEASES.md)

Ran the proposed checks against all 7 real blocks before writing any code:

| Release | Description >4 sentences | Manifest-Members >7 tokens | Exit criterion length |
|---|---|---|---|
| 0.1.0 Quicksilver | clean | — (no field) | clean |
| 0.2.0 Litmus | clean | — | 592 chars / 6 sentences |
| 0.3.0 Nightwatch | 6 sentences | — | 2007 chars / 9 sentences |
| 0.4.0 Plumbline | 5 sentences | — | clean |
| 0.5.0 Lantern | 5 sentences | — | 1544 chars / 6 sentences |
| 0.6.0 Meter | 17 sentences | 2 (clean) | 2718 chars / 10 sentences |
| 0.7.0 Ballast | clean | 4 (clean) | 2470 chars / 10 sentences |
| 0.8.0 (next) | 11 sentences | — | clean |

Two findings that changed the plan:

- **Manifest size is not the problem.** Only two blocks (0.6.0, 0.7.0) even use `Manifest-Members:`,
  and both are clean. The real bloat is entirely in `Description:` and `Exit criterion:`, and it's
  near-universal — 6 of 8 blocks trip the Description check, not just Ballast.
- **"Spans multiple lines" is the wrong signal.** Every field in the file is one long wrapped physical
  line, never literally multi-line — a line-count check would catch nothing.

## Consult (2026-08-18)

Ran `/consult` before promotion, per standing operator instruction to sharpen plans this way.
**Single-model result**: Codex answered; agy failed on `RESOURCE_EXHAUSTED (429)` — an infra/quota
failure, not a design disagreement, so there is no second-model cross-check on this round. Codex's
file:line citations were independently re-verified against the real files (not taken on faith) before
being adjudicated below — all confirmed accurate.

Findings that revised the plan:

- **[Blocker] The blocking-flip reverses documented policy, not code.** `PROJECT/PDDA.md` states
  RELEASES.md "never blocks, even in full mode" as an *intentional design stance* — the file is
  explicitly optional, not a checklist. Verified: the exact line exists in `PROJECT/PDDA.md`'s
  "RELEASES.md — release ledger" section. **Dropped entirely.** All new checks are permanently
  advisory, matching every existing `check_releases()` check. A future strict/blocking mode would need
  its own separately-approved issue, not a quiet flip inside this one.
- **[Blocker] The `>4 sentences` Exit-criterion threshold was never actually validated.** The scan's
  own data called a 6-sentence/592-char block (Litmus) "clean" while the proposed rule would flag it —
  an internal contradiction in the original plan. **Fixed:** `Exit criterion:` uses a length threshold
  (~1000 characters — the midpoint between the observed clean ceiling of 592 and the bloated floor of
  1544) instead of a sentence count. `Description:` keeps the sentence-count rule as-is — that one IS
  pre-existing documented policy (`PROJECT/PDDA.md`: "warns when this field exceeds four sentences"),
  not something this issue is inventing.
- **[Blocker] The parser can't see most of the bloat.** Verified directly in `utils/pdda/pdda-lib.sh`:
  the shared awk field-parser captures only the single physical line prefixed `Description:` (etc.) —
  it has no continuation handling. Verified against `RELEASES.md`'s own Sundown (0.8.0) block: it has
  two full narrative paragraphs immediately after the `Description:` line with no field prefix,
  invisible to the parser today. Implementing the bloat checks as originally scoped would silently
  under-detect almost everything, including the exact kind of appendix that motivated this issue.
  **Required implementation step, not optional:** fold continuation lines into the field they follow,
  up to the next recognized field header, in both `check_releases()` and `cmd_releases_current` (they
  share the same parser — verified in `pdda-lib.sh`).
- **[Should] Drop the `Manifest-Members:` bloat check from this issue's scope.** Verified: the
  documented `>7`-issue threshold in `PROJECT/PDDA.md`/`skills/releases/SKILL.md` applies to
  `Manifest:`, not `Manifest-Members:` — a separate, undocumented, release-gate-machine-readable field.
  Needs its own contract decision before it gets a bloat rule; not bundled here.
- **[Should] `Tracking Issue:` stays optional, pointer-only, local syntax** (`Tracking Issue: #123`).
  Verified: `Milestone:` is explicitly documented as the release→issue-set join key, and `GH_URL:`
  explicitly marks "a GitHub Release object exists" — neither is available to repurpose. Never
  required, never auto-created.
- **[Should] Scope new warnings to active/unshipped blocks only**, matching `/releases clean`'s
  existing documented default (verified in `skills/releases/SKILL.md`) — otherwise shipped history
  collects permanent, un-actionable noise.

## Revised proposed fix (lightest viable — no new skill, no new scanner binary, permanently advisory)

1. Extend the shared field parser (`pdda-lib.sh`, used by both `check_releases()` and
   `cmd_releases_current`) to fold continuation lines into the field they follow, up to the next
   recognized field header.
2. Add a `Tracking Issue: #N` optional field to the `RELEASES.md` block spec (`PROJECT/PDDA.md`
   contract + `skills/releases/SKILL.md`'s plan-subroutine template). Never required, never
   auto-created. Extends the existing Issue-first SOP to the release ledger itself.
3. Extend `check_releases()` with two **permanently-advisory** checks, scoped to active/unshipped
   blocks only:
   - `Description:` exceeding 4 sentences (existing documented rule, now made mechanical)
   - `Exit criterion:` exceeding ~1000 characters (new; calibrated against the validation scan, not
     the earlier unvalidated sentence rule)
4. No blocking phase, ever, for these checks — same warn-only-forever posture as the rest of
   `check_releases()`.
5. `/releases clean`'s existing LLM rubric remains the fix-up drafting tool once a violation is
   flagged by (3) — never the detector. Matches this repo's deterministic-before-LLM constitution rule.
6. `Manifest-Members:` bloat checking is explicitly **out of scope** for this issue — needs its own
   contract decision on that field's syntax/ownership first.

## Sequencing

Queued as a **post-Ballast 0.7.0 follow-up** — not a Ballast manifest member, no dependency on the
in-flight release-gate run.

---

## Acceptance Criteria
- [ ] Parser folds continuation lines correctly; `check_releases()` and `cmd_releases_current` both
      updated together with regression fixtures: absent-field default, threshold boundaries at both
      edges, continuation-line folding, punctuation edge cases that shouldn't count as sentence-enders,
      shipped-vs-active scoping, and parser-slot ordering preserved (per the precedent in
      `test/gh284-p3-release-milestone.sh`).
- [ ] `Tracking Issue:` field documented in `PROJECT/PDDA.md`'s RELEASES.md contract and
      `skills/releases/SKILL.md`'s plan-subroutine template — optional, pointer-only.
- [ ] New checks are advisory-only (never gate exit code) and skip shipped blocks by default.
- [ ] `Manifest-Members:` bloat checking explicitly out of scope for this issue (needs its own contract
      decision).
