# Reconciler diagnosis — GH-591

## Table of contents
- [Witnessed controls](#witnessed-controls)

## Witnessed controls

The sibling provenance file retains exact local commands, output, exit status and source commit.
Both unmodified CI invocations exit 6: missing PR #590 receipt; legacy GH-52 aborts catch-up.
A real throwaway source/bare-remote Git push runs a receipt-writing hook: its file exists in the
working tree but the pushed tree contains only `source`. No remote service is used for that proof.
These are diagnostic controls, not passing suite qualification or a manual reconciliation receipt.
