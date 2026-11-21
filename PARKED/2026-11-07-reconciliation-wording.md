# Reconciliation ownership wording

- Observation: AGENTS.md "What this file owns" says hosted reconciliation runs automatically
  after development merges, while its GH-1127 gate rail says development merges reconcile locally.
- Source: AGENTS.md at base 49777b82d1be9ac915e9cdced5db2adb6018607f;
  relay-system/2026-11-07/gh1366-plan.codex.md independent review.
- Outside GH-1366's selected red-control/appendix wording slice; no runtime failure reproduced.
- Next check: compare both passages with the current workflow trigger and merge-cleanup caller,
  then reconcile wording in a separately scoped change. Do not change runtime based on this note.
