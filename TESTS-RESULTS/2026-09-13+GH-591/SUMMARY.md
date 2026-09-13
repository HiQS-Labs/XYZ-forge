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
