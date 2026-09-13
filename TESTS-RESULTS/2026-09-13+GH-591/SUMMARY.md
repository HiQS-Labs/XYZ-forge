# Reconciler diagnosis — GH-591

## Table of contents
- [Witnessed controls](#witnessed-controls)

## Witnessed controls

The sibling provenance file retains exact local commands, output, exit status and source commit.
Both unmodified CI invocations exit 6: missing PR #590 receipt; legacy GH-52 aborts catch-up.
A real throwaway source/bare-remote Git push runs a receipt-writing hook: its file exists in the
working tree but the pushed tree contains only `source`. No remote service is used for that proof.
These are diagnostic controls, not passing suite qualification or a manual reconciliation receipt.

## Producer verification

- Unmodified producer control: `bash test/gh425-gate-provenance-pr.sh Qualification.test_full_gate_produces_attributable_retained_proof` exits 1 because no producer exists; raw output is in `producer-red.log`.
- Candidate tests retain the same command's positive path plus failures for unrelated SHA, failed gate, incomplete telemetry, timeout and clone mutation. New-schema failures never fall through to legacy PR identity.
- Workflow fixtures exercise the actual publishing script, allow both declared evidence files, reject arbitrary files and witness rejected pushes.
- Baseline full hook: 373/373, 1038 seconds, unchanged HEAD/envelope. One parallel Releases suite failure passed the runner's existing isolated retry. This is the baseline, not candidate evidence.
- Deterministic PDDA: zero errors, 30 existing issue-sync/governance warnings; LLM doc readiness was not enabled. Other focused static results are retained beside this summary.
- Full candidate hook and first hosted run remain outstanding until recorded below.

## Candidate gate and timeout correction

The first candidate push at `5fa5520ce9ef11d80987b415c3dd365907e3658a` was refused after
3,121 seconds: 373 checks passed and `gh544-parallel-default.sh` failed its no-args default-reason
assertion because the sequential run was selected through `XYZ_VALIDATE_PARALLEL=0`. The isolated
fixture reproduces red with that export and passes with it absent. The hosted producer already
strips inherited `XYZ_VALIDATE_*` and selects `--sequential` explicitly. The next local push uses
the normal hook defaults; no bypass or suite exclusion. This red run does not count as qualification.
Raw telemetry and the exact failure excerpt are retained beside this summary. Its 52-minute runtime
also invalidates the historical 13–15 minute estimate, so the bounded validation/job timeouts are
now 90/120 minutes. Actual hosted latency and sustainable queue behavior remain acceptance work.

## Passing candidate gate

Full normal pre-push gate: **374/374 passed** at `ea0a4e687d652c4e72ac5a71d938b2c968c2e582` in 820s, with no bypass or exclusions. `gh53-releases-merge-resolve.sh` failed in parallel and passed the gate's built-in isolated retry. This is local full-suite validation, not hosted/sequential promotion evidence.

The actual full run also produced nested validator telemetry. The producer now binds selection to
the launched process PID and run ID; `nested-telemetry-red.log` witnesses the old ambiguity.

Published diagnostic copies redact local username, home/clone roots and hostname. Original local logs remain outside Git; result values, run IDs and test counts are unchanged. These diagnostic copies are not machine-generated reconciliation receipts.
