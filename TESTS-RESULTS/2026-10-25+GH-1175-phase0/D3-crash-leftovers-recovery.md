TITLE: jog recovery after a driver crash: retry-build has no guidance for leftovers (isolation worktree, claimed tick token, clone driver lock, local branch)

## Observed (GH-1175 Phase 0, 2026-10-26)
After SIGKILL of the jog/marathon tree and a correct cold-start park, the target clone still held: a local `marathon/gh-416-…` branch with a render commit, the `rtl-wt.*` isolation worktree, tick token `MARATHON-…-TURN` `claimed` by agy, and `.git/relay-driver.lock` with the dead pid. `jog resume` says "use jog retry-gate / retry-build / land" but neither it nor jog/SKILL.md says whether retry-build may reuse that clone or how to clear the leftovers. Recovery was done by hand: `git worktree remove --force`, then a fresh clone for retry-build.

## Proposed remedy (for review)
Document in jog/SKILL.md "Recovery Verbs": after a cold-start park, retry-build into a fresh disposable clone (and retire the old one via /merge-cleanup), or have `_execution_root` refuse a target with a non-trunk branch / live tick claim / leftover worktree, naming them. Doc-first; code only if the doc proves insufficient.
