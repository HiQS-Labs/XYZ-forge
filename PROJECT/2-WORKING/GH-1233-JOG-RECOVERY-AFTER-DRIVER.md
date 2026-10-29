---
gh_issue: 1233
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1233
title: "jog recovery after a driver crash: guidance for leftovers before retry-build"
status: Active
created: 2026-10-27
updated: 2026-10-29
owner: noelsaw1
doc_type: bugfix
complexity: 1
risk: 1
effort: 1
phases: 1
goal: "An operator recovering a crashed Jog item knows which leftovers exist, how to confirm each is safe to clear, and that retry-build goes into a fresh clone."
non_goals:
  - Code changes to jog resume, retry-build or _execution_root (doc-first; code only if the doc proves insufficient, per the issue).
related:
  - "Marathon umbrella #1250 (lane L1)"
  - "GH-1175 Phase 0 evidence: TESTS-RESULTS/2026-10-25+GH-1175-phase0/step3-*"
---

# GH-1233: jog crash recovery — guidance for leftovers before `retry-build`

## Status

| What was just completed | What's next |
|---|---|
| Promoted for marathon #1250 (lane L1) with plan, acceptance and contract | Codex plan QA, then build |

## Observed (GH-1175 Phase 0, 2026-10-26)

After a SIGKILL of the jog/marathon tree and a correct cold-start park, the target clone still held:
- a local `marathon/gh-416-…` branch with a render commit;
- the `rtl-wt.*` isolation worktree;
- the tick token `MARATHON-…-TURN`, still `claimed` by agy;
- `.git/relay-driver.lock`, holding the dead pid.

`jog resume` says "use jog retry-gate / retry-build / land", but neither it nor `skills/2-daily/jog/SKILL.md` (Recovery Verbs, lines 178-189 at 93f41cb8) says whether retry-build may reuse that clone or how to clear the leftovers. The Phase 0 run recovered by hand: `git worktree remove --force`, then a fresh clone for retry-build (`step3-recovery-prep.log`, `step3-leftovers-after-kill.log`).

## Plan (one phase)

Edit `skills/2-daily/jog/SKILL.md` "Recovery Verbs" only. Add a "Crash leftovers" block after the three verbs:
1. Name the four leftovers, and for each give the read-only check that shows it is safe:
   - the isolation worktree: `git worktree list`, plus no live pid holding the path;
   - the claimed tick token: `tick info <token>`, holder pid not alive;
   - the driver lock: the pid in the lock is not alive (`kill -0`), noting the driver reclaims a stale lock itself on the next run;
   - the local marathon branch: not pushed, so it is evidence only.
2. State the rule. After a cold-start park, `retry-build` targets a **fresh disposable full clone**, never the crashed one. Retire the crashed clone through `/merge-cleanup`, which preserves an unpushed branch until the operator says it is disposable.
3. Say which verb fits which state: `resume` first (spends no token), then `retry-gate` if the build is approved and only the gate failed, then `retry-build` for a real rebuild.

Write-set: `skills/2-daily/jog/SKILL.md`. Docs route (`utils/ci-route.sh` classifies `skills/*/SKILL.md` as docs, except merge-cleanup's).

## Acceptance

- `skills/2-daily/jog/SKILL.md` "Recovery Verbs" names each crash leftover (isolation worktree, claimed tick token, clone driver lock, unpushed local marathon branch) and how to confirm it is safe to clear.
- It states that after a cold-start park, `retry-build` targets a fresh disposable full clone and the crashed clone is retired through `/merge-cleanup`, never reused.
- `utils/pdda/pdda.sh run` is clean; no new tests (GH-831).

## Verification

Read the changed section from its consumer's entry point (the jog skill), and check it against the Phase 0 step-3 logs. Run `utils/pdda/pdda.sh run`. Rollback: revert the doc commit.

## Swarm Preflight Contract

```json
{
  "target": {"repo": ".", "ref": "development"},
  "gate": "bash utils/pdda/pdda.sh run",
  "fix_probes": [
    {"type": "grep_absent", "path": "skills/2-daily/jog/SKILL.md", "pattern": "Crash leftovers"}
  ],
  "artifacts": ["skills/2-daily/jog/SKILL.md"],
  "remediation": {"source": "issue#1233", "criteria": "Recovery Verbs gains a Crash leftovers block: four leftovers with safe-to-clear checks, and the fresh-clone rule for retry-build."},
  "lanes": {"agy_safe": ["skills/2-daily/jog/SKILL.md"], "orchestrator_only": []}
}
```
