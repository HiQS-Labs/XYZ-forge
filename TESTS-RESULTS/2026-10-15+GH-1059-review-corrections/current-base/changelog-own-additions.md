## 2026-10-15 — Preserve ignored content during published worktree closeout (GH-1059)

A clean Git status and a fully published PR do not preserve ignored worktree files.
Ordinary native worktree removal deletes those files. Both native cleanup paths now
enumerate ignored files through the existing inspection owner and preserve linked
worktrees when any remain, or when enumeration fails. Whole-clone Trash relocation and
the ordinary merged-only history requirement are unchanged. This extends no test registry or CI case.

Easy to reverse by reverting the scoped guard; preserving an uncertain worktree has no
data-loss effect. A backed-up synthetic native-Git fixture demonstrated the deletion;
existing cleanup checks and recorded manual evidence must verify the guarded mode before
publication. No existing checkout was removed for this observation.

## 2026-10-14 — Retire fully published task checkouts before merge (GH-1059)

Start-task now invokes targeted checkout retirement after verified ready-PR publication.
Merge-cleanup's opt-in published-PR mode verifies live canonical PR/head/ref recovery,
then reuses existing local-state/session/dependency checks, fresh inspection and removal.
Full clones go to Trash; linked worktrees use native Git removal. The primary working
tree and unrelated checkouts are excluded; normal merged-only cleanup is unchanged.

This changes cleanup eligibility, so unknown or local-only state preserves the checkout.
Rollback by reverting GH-1059 or omitting the new mode; recover full clones from Trash.
Existing cleanup180 tests, three focused start-task suites and41 isolated manual cases
passed, with negative controls and committed provenance under `TESTS-RESULTS/2026-10-14+GH-1059/`.
Independent plan/final QA approved; the full publication gate passed409/409 in a separate full clone.

