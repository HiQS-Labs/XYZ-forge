# Recovery verification — GH-584 / umbrella GH-591

## Table of contents
- [Change and scope](#change-and-scope)
- [Witnessed controls](#witnessed-controls)
- [Validation and pending acceptance](#validation-and-pending-acceptance)

## Change and scope

The owning execution plan remains `PROJECT/2-WORKING/GH-591-RECONCILER-LIFECYCLE.md`, Phase 2.
Unattributable closed legacy rows warn without blocking valid work. API failures remain errors.
The existing catch-up path recovers every missing qualified PR since the workflow's first introduction,
using full Git history, paginated API metadata and committed validated receipts. No-issue landings and
open-issue references therefore survive lost events and rejected bot pushes. The PR-triggered job also
collects pending merges so one full validation qualifies a batch and queued repeats reuse its proof.

All pending landings get receipts; each issue's newest known closer owns its document/manifest/ledger
writes. Shallow history and malformed metadata fail closed. Empty qualified sweeps write nothing.

## Witnessed controls

- Parent source `5fa5520ce9ef11d80987b415c3dd365907e3658a`, loaded with `GH421_WAVE`, fails the new
  mixed fixture: `Closed GH-52 has reconciliation drift but no attributable merged development PR`.
  Full command and output are in `provenance.jsonl` and `recovery-red.log`; the current source passes.
- Removing lifecycle ownership reproduces an old merge SHA in manifest evidence; current source
  records the newest SHA, newest document date and newest PR in the roadmap. See `recovery-owner-red.log`.
- Two-page discovery recovers no-issue/open-reference PRs, retains invalid-receipt candidates, excludes
  pre-activation/unmerged PRs and only suppresses validated committed qualification.
- Missing/shallow history, API failure and malformed records are witnessed error controls.
- Live read-only discovery returned 24 pending PRs since `2026-09-09T19:08:00-07:00`;
  `live-recovery-discovery.log` retains the exact IDs. No reconciliation or receipt writes were run.

## Validation and pending acceptance

Focused checks: GH-421 24 tests, GH-425 22 tests, core reconciliation 16 checks, GH-496 checks pass.
PDDA has zero errors and 30 existing governance/issue-sync warnings; LLM doc-readiness is not enabled.
Full local pre-push gate passes; real hosted/scheduled acceptance remains pending. Red controls, actual
commands, and raw outputs are retained alongside this summary. This PR depends on the producer PR;
the umbrella remains open until three consecutive merges and the next scheduled sweep reconcile.

## Rollout lookup correction

Read-only inspection found that GH-496's lookup selected `recon-gh496-merge-churn-and-telemetry.md`
ahead of `GH-496-SHARPEN-CICD.md`. Recording an open-issue merge on that supporting note would then
violate the existing publisher's declared-path boundary. The lookup now enforces its documented
canonical filename prefix and deterministic ordering. `canonical-doc-red.log` witnesses the old
selection moving the supporting note; the current test closes the canonical document and preserves
the note byte-for-byte. The publisher allowlist remains unchanged.

Published diagnostic copies redact local username, home/clone roots and hostname. Original local logs remain outside Git; result values, run IDs and test counts are unchanged. These diagnostic copies are not machine-generated reconciliation receipts.

## Final local gate

Final normal pre-push gate: **374/374 passed** at `dc3da06f72f9741a361c2094f76e1b6361c40b78` in 827s, with no bypass or exclusions. This is local full-suite validation; hosted/sequential promotion remains unverified.

The Git boundary fixture now isolates global/system config and templates. A hostile inherited template
reproduced failure before the change and passes afterward; both outputs are retained. Malformed receipt
path hashes also fail the actual publisher. Runtime pytest remains required for qualification.
