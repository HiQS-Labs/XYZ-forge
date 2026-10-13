# GH982 required-gate adaptation QA

The operator requested merge-cleanup of all open PRs except held #930. PR #1009
has landed its independently reviewed SWE governance rewrite. PR #982's unchanged
dashboard candidate hit a required normal full push gate failure (409/410): only
the existing gh609 static SWE contract checker still required retired six-stage
wording and unconditional synchronization. No push/bypass occurred; Git identity
was unchanged. The checker adaptation is the second/final bounded repair for #982.

Review candidate da35178f and its change from 209fd0bd, especially the complete
test/gh609-sdlc-agent-gaps.sh, current skills/1-hourly/swe/SKILL.md and that skill's
47fb72dfcb change. Inspect TESTS-RESULTS/2026-10-09+GH-981/gate-repair.md and ALL
referenced failure, differential, positive/red logs and JSON provenance. The
original dashboard remains byte-identical; its prior valid implementation QA is
relay-system/2026-10-09/gh982-merge.codex.md. Full repaired gate remains pending.

1. Does the revised existing checker faithfully pin the intentional scoped
   migration policy, including compatibility/backfill, ordering/convergence,
   cutover/rollback, safe fallback and old readers/writers/queued consumers/window
   accounting, without silently weakening safety?
2. Are the two adapted existing mutation controls meaningful and actually
   rejected? Does the extra manual convergence removal fail the check? Does the
   parent-only SWE swap explain the original failure and rule out dashboard-only
   attribution? Distinguish witnessed checks from your own read-only review.
3. Is this one existing suite adaptation the smallest sound required-gate repair,
   with no new suite, registry, runner or product mechanism?
4. Is the receipt truthful about refused publication, exact source, unchanged
   identity, pending full qualification, and original bounded Darwin/browser gaps?
5. Any blocking introduced or pre-existing defect in the complete modified suite
   or policy boundary that prevents this repair from proceeding to qualification?

Write only the relay thread. No Git mutations, test/validate/pytest execution,
providers, browser/server, installs or fixture execution in the relay worktree.
Read-only comparisons are allowed; PYTHONDONTWRITEBYTECODE=1. Producer owns the
disposable-full-clone full gate and current-development ledger integration.

Use standalone VERDICT: PASS/FAIL and Basis:, five numbered questions, concrete
findings and `swept file: yes`. PASS may approve the repair implementation only,
not qualification or promotion. Leave STATUS Approved on PASS, NEXT Producer.
Close using the ACTUAL env-pinned tick done RELAY-gh982-gate-repair --agent codex.
Do not release to an actor named done; do not claim success if completion fails.
