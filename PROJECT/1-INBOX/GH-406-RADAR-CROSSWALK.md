---
title: "Crosswalk — Russ K.'s external review (GH-406) against Radar run 2 (2026-09-01)"
status: active
created: 2026-09-03
owner: orchestrator (Claude Code)
goal: determine whether an outside cold read of the repo and the internal recurring-defect radar independently found the same thing, and where each was structurally blind
doc_type: report
roadmap_exempt: true
gh_issue: 406
source: https://github.com/HiQS-Labs/XYZ-forge/issues/406
related:
  - PROJECT/1-INBOX/RADAR-REPORT-2026-09-01.md
  - PROJECT/1-INBOX/RUSS-TRIAGE.md
  - PROJECT/1-INBOX/GH-406-RUSS-EXTERNAL-REVIEW.md
---

# Crosswalk: GH-406 external review × Radar run 2

Two instruments, run independently, three days apart, with no shared inputs:

- **Radar run 2** (2026-09-01) clustered 21 days of issue and commit history from the inside.
- **Russ K.** (2026-09-02) cold-read the public tree from the outside with no issue history at all.

They converged on the same defect class. That is the finding.

## The shared class

| Source | Wording |
|---|---|
| Radar **T2** `RADAR-class-dark-telemetry` (NEW, score **9.0** — highest in the report) | "Instruments that report a state they never measured: the writer silently no-ops, writes to the wrong place, or a reader turns a write failure into a wrong verdict." |
| Radar **T3** `RADAR-class-guard-blind-matcher` (score 6.4) | "Guards whose matcher is hand-written instead of derived from the authoritative source, so they stay green while a new shape walks past." |
| **Russ K.**, §2 | "A doc states a guarantee and the mechanism covers a narrower path than the sentence implies." |
| Repo's own **§13** | "A green gate without a witnessed red control is not evidence." |

Same class, three namings. The repo named it first, Radar measured its recurrence, and an outside
reader hit it without being told it existed.

## Per-finding mapping

| Russ K. | My rank | Radar target | Relationship |
|---|---|---|---|
| 1.2 `validate-relay-block` off the driven path | **R1** | **T2** | Textbook T2 — an instrument reporting a verdict it never computed. Parallel to T2's own checklist item *"a gateway that writes zero rows fails its own turn instead of reporting success."* |
| 1.3 `tick log` outside the foreign-cwd guard | **R2** | **T1** + **T2** | Sits on the seam of the two highest-scored targets. "Writes to the wrong place" is T2's literal wording; root resolution is T1's whole subject. |
| 3.1 transient claim collision == durable loss | **R3** | **T2** | "A reader turns a write failure into a wrong verdict," exactly. |
| 1.1 destructive-rebuild marker | **R4** | *none* | **Radar was structurally blind.** One file, no issue trail, no recurrence — invisible to a clusterer. |
| 1.5 kernel cites absent ADRs → new R5 check | **R5** | **T2** | Generalises T2 from telemetry to documentation. Russ K. asked the question ("does anything catch comment rot?"); the answer was no. |
| 1.4 guard hook matches 6 of 11+ entrypoints | **R6** | **T3** | A **third member** of T3's one remaining open item: *"generalize the derive-from-source pattern… at least `test/marathon-root-audit.sh` and the agy preflight guard derive their expected set rather than hardcoding it."* Russ K. found a third guard Radar had not named. |
| 1.6 / 3.2 doc drift | R7 | T4-adjacent | Nits; not a recurrence. |

**Four of my top five map to T2.** I ranked them by ROI without having read the Radar report.
Radar scored T2 highest by an independent formula. The rankings agree.

## Where each instrument was blind

**Radar could not see** 1.1 (destructive-rebuild marker). It clusters issues; a defect nobody
ever filed produces no cluster. An outside cold read is the only thing that finds these.

**Russ K. could not see** T1 `vendored-root-resolution` — Radar's #2 at 7.7, nine issues across
four consumer repos. Vendored `.xyz/` installs are invisible from a public-repo read. He touched
its edge at 1.3 without being able to see the class behind it.

Neither instrument subsumes the other. Running only one leaves a known blind spot.

## The executive finding

Radar records T2 as **UNCLAIMED**: *"No unshipped release band names telemetry integrity."* Its
natural home, `0.5.0 Lantern`, is `draft`, its exit criterion is **NOT BUILT**, and it sits behind
0.9.0 and 0.6.0.

So the class an external reviewer independently ranked as the repo's most valuable fix is the one
class the release plan has not scheduled. Radar said so from the inside on 2026-09-01 and was not
acted on; Russ K. said it from the outside on 2026-09-02 without knowing Radar existed.

## State changes since Radar run 2 (verified 2026-09-03)

Radar's numbers are two days stale in two ways that matter:

1. **Radar's blocker is resolved and inverted.** Run 2 reported local `development` 57 ahead / 4
   behind with two locally-merged PRs showing open+CONFLICTING on GitHub. Now: local `e58f339f`
   is **2 ahead / 37 behind** `origin/development` (`322eeead`). PRs #356 and #364 are gone. The
   data-loss exposure is closed; the new condition is a stale local checkout.

2. **T1's headline item has landed.** `origin/development` carries GH-396 Phases 0–4 —
   `relay-automation/harness-paths.sh`, `utils/py/harness_paths.py`,
   `test/gh396-find-harness-roots.sh`, plus a vendored smoke CI gate. That is precisely T1's
   two-run-old unchecked box (*"add one shared root-resolution helper"* + *"add a vendored-`.xyz/`
   fixture to the suite"*). Radar run 3 should be able to strike both against named commits.

   **Consequence for GH-406: R2 is unblocked.** I had sequenced it behind #396; #396 has landed.

3. **The GH-406 verification still holds.** All eight findings were checked against local
   `e58f339f`, 37 commits behind origin. Of the eleven files those findings touch, the 37 commits
   modify exactly one — `skills/relay-xyz/SKILL.md`, a one-line `DEEPSEEK_PROVIDER` change
   unrelated to 3.2's `CODEX_FLAGS` claim. So "all eight reproduce" survives the staleness, but
   re-run the checks after rebasing before opening R1–R6 as issues.

## Two process notes both instruments produced independently

- **`gh` lies inside the sandbox.** Radar run 2 logged it as a degradation row; this session hit
  the identical false negative (`x509: OSStatus -26276`) on its first call. Radar's reconciliation
  note #5 already says re-run unsandboxed.
- **A tool that cannot report a presence must not be read as reporting an absence.** This session
  asserted "GH-408 does not exist" from a `grep --include=…` that ripgrep silently refused —
  retracted on #406. Same defect as T2, committed while triaging T2. Worth a checklist item of its
  own.

## Recommendation

Fold R1, R3 and R5 into T2 rather than tracking them separately, and let R6 join T3's open helper
item. T2 then has both an internal recurrence case (8 issues over 10 days) and an external
corroboration, which is a materially stronger argument for writing `0.5.0 Lantern`'s exit criterion
and pulling it forward than either instrument makes alone.
