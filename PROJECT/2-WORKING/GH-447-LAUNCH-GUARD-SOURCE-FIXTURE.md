---
title: "GH-447: isolate launch destination checks from dirty caller source"
status: active
created: 2026-09-05
updated: 2026-09-05
owner: Codex
gh_issue: 447
source: https://github.com/HiQS-Labs/XYZ-forge/issues/447
goal: Exercise destination safety regardless of unrelated tracked caller edits.
doc_type: project
effort: 1
complexity: 1
risk: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Isolated fixture passes with dirty caller; current-builder negative control fails | Run the full disposable-clone gate and open the PR |

## Recon and change

The suite invokes `utils/build-launch-artifact.sh` from its caller checkout. That builder refuses uncommitted tracked changes before extraction because it archives HEAD. Destination refusal cases run before this check, so they pass; the positive discard-history case fails. The production refusal is correct.

Easy to reverse: change only the test's source fixture. Clone the committed caller into a guarded full-clone fixture, copy the current builder into it and commit that file with a fixture identity. Copying the current builder ensures an uncommitted regression remains observable. Do not relax source cleanliness or destination deletion guards.

## Verification plan

1. Run the unchanged suite with clean and dirty callers; retain both results and Git identity checks in `TESTS-RESULTS/2026-09-05+GH-447/provenance.jsonl`.
2. Run the isolated suite with clean and dirty callers; expect all destination assertions to pass.
3. Mutate the current builder to bypass the non-git destination refusal; expect the copied-marker assertion to fail despite the fixture starting from committed HEAD. Restore the exact saved bytes.
4. Run `validate.sh` in a separate disposable full clone; retain its outcome and identity comparison before claiming a green gate.

## Related handoff

PR #440 is merged and issue #439 is closed, but its project doc lacks the required lessons section. Reconstruct only lessons supported by its committed review/verification records, then use `wave_reconcile.py` for the document and ledger transition. No original-author-only rule was found in PDDA.

## Handoff outcome

The canonical PR #440 reconciliation completed with exit 0 and its PDDA gate passed. It reported unrelated existing roadmap drift without blocking this transition. The original author was not required: the lessons are explicitly reconstructed from committed evidence.

The optional closes-on-mention claim is not reproduced in the reconciler: bare references remain mentions, while closing keywords and trailing issue tags in PR titles are closers. No separate closer was found in the inspected repository workflows, Git hooks, or global Claude hook commands. Leave any external automation unchanged until its owning script or a concrete closure event identifies it.

## Lessons Learned (For Future Agents)

- Reproduce reported baseline failures in a clean full clone and vary caller dirt separately; a correct source precondition can mask the behavior the suite intends to test.
- A source fixture must overlay the current implementation before committing it. Otherwise an uncommitted regression can pass because the fixture silently tests the older HEAD. The negative control here caught that distinction.
- A dry-run previews lifecycle changes without applying them, so its downstream planner can still flag the closed issue against the unchanged active document. The actual scoped reconcile successfully moves the document before planning.
