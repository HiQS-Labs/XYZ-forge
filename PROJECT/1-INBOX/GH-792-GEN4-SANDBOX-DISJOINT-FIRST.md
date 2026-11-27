---
gh_issue: 792
source: https://github.com/HiQS-Labs/XYZ-forge/issues/792
title: "gen4_campaign.make_sandbox checks disjointness before deleting or cloning"
status: "Prepared 2026-11-27 (1-INBOX, held: not enqueued, not started)"
created: 2026-11-27
updated: 2026-11-27
owner: Conveyor preparation (Day 3 Flywheel proving-arc candidate, post-checkpoint successor; ledger #1611)
doc_type: bugfix
ratings_provisional: true
non_goals:
  - Any change to run_campaign, reset_sandbox, the campaign suite or targets
  - Hardening other sandbox helpers in the repository
  - A new test suite or gate machinery (GH-831)
goal: >
  make_sandbox must resolve the source repo and the candidate clone path and refuse an
  overlapping pair before any makedirs, rmtree or git clone, so a checkout that happens to sit
  at <sandbox_root>/clone is never deleted; disjoint sandboxes clone exactly as before.
---

# GH-792 · Gen 4 sandbox checks disjointness first

## Status

| What was just completed | What's next |
|---|---|
| Recon, capture, Preflight Contract, probe proof (unfixed / simulated fix / comment-only edit), both-consumer validation and PRS rating prepared 2026-11-27. No implementation, no queue admission. | Independent preparation review, publication of this preparation PR, then an explicit `/jog 792` or `/start-task 792` by the operator. |

## Acceptance

- [ ] The overlapping call refuses with zero `makedirs`/`rmtree`/`subprocess` calls (red control: the current order records a delete first).
- [ ] A disjoint candidate still clones as before.
- [ ] The existing self-test at `gen4_campaign.py:348` (`make_sandbox(host, os.path.join(host, "inside"))`) still refuses.

## Acceptance — deviations from the issue

None. The three criteria above are the issue's `## Acceptance` bullets copied verbatim. The issue's self-test reference `gen4_campaign.py:348` still matches the source at the baseline below.

## Recon note (parent-only)

The operator's brief for this run asked for capture, contract, preflight and one independent review. The parent read the whole seam itself, so no separate research child was dispatched. Time budget: this preparation session; attempts consumed: 0.

- **Baseline:** `origin/development` at `cf04c03b4586ad46a5fa1143648e86a6c28b4f4e` (2026-11-27; seam files identical to `76808a53b`, where the reproduction first ran).
- **Observed (reproduced):** `TESTS-RESULTS/2026-11-27+GH-792/readiness_probe.py` builds a real fixture repo at `<base>/clone` and calls `make_sandbox(repo=<base>/clone, sandbox_root=<base>)`. Today the fixture source repo is deleted, then `git clone` fails with exit 128 (`CalledProcessError`); the refusal never fires (exit 1, unfixed).
- **Code path:** `utils/py/gen4_campaign.py:84-97` `make_sandbox` runs `os.makedirs(sandbox_root)` → `shutil.rmtree(clone)` if `<clone>/.git` exists → `git clone repo clone` → only then the realpath equality/descendant check that raises `RuntimeError`. Caller: `run_campaign` (`:134`); self-test (`:348`).
- **State writer:** `make_sandbox` itself (`rmtree`, `git clone`). **Consumer/retry boundary:** `run_campaign` uses the returned clone; nothing retries.
- **Smallest plan:** compute `clone` and both realpaths first; run the existing check (plus the reverse-descendant case, source inside the clone path) before `makedirs`/`rmtree`/`clone`. One function, one file.
- **Dependencies / overlap:** no open PR touches `utils/py/gen4_campaign.py` or `test/gh-gen4-phase5-campaign.sh`. Disjoint from #1626's write set.
- **Discriminating check:** the probe records `os.makedirs` / `shutil.rmtree` / `subprocess.run` calls (each passed through) and exits 0 only when the overlapping call raises `RuntimeError` with zero such calls, the source repo and its sentinel commit are intact, a disjoint call still yields a working clone, and the `:348` descendant shape still refuses. Simulated fix: exit 0. Comment-only edit: still exit 1. Local git only, everything under one temp fixture.
- **Foreseeable approvals/runtime:** none beyond the normal gate; `test/gh-gen4-phase5-campaign.sh` runs the campaign self-test (bounded soak, local only).
- **Unknowns:** none blocking.
- **Next owner:** the operator (explicit `/jog 792` or `/start-task 792`).

## Attempt and retry history (read 2026-11-27, nothing reset)

- `jog_queue` (primary ledger, read-only, and this clone): no row for #792. `roadmap_items`: no row before this preparation. `work_events`: none.
- Branches and PRs: none for #792 (PR #795 is GH-788, where this was found). No prior capture doc; listed as `needs-doc` in the dated marathon plans. No issue comments.
- Attempts consumed: 0 queue, 0 native.

## Rating rationale

`rated 50/60/50/90` (sum 250), written through `roadmap pickup` on 2026-11-27; `ratings_provisional` stays true until the operator confirms.

- Severity 60: deletes a source repository irreversibly, but only on an unusual argument pair (a checkout named `clone` directly under the chosen sandbox root).
- Priority 50: no incident; found by review (Codex probe during #788 final QA, 2026-09-24) and recorded without real deletion.
- Appeal 50: neutral (no operator preference supplied).
- Effort 90: reorder one function's statements.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash test/gh-gen4-phase5-campaign.sh",
  "round_cap": 2,
  "artifacts": [
    "utils/py/gen4_campaign.py",
    "TESTS-RESULTS/2026-11-27+GH-792/"
  ],
  "fix_probes": [
    {
      "type": "command",
      "cmd": "python3 TESTS-RESULTS/2026-11-27+GH-792/readiness_probe.py",
      "expect_nonzero": true
    }
  ],
  "remediation": {
    "source": "issue#792",
    "criteria": "make_sandbox resolves repo and the candidate clone path and runs the existing equality/descendant check before makedirs, rmtree or git clone; an overlapping call refuses with zero mutations; a disjoint candidate still clones; the gen4_campaign.py:348 self-test still refuses. Existing suite only. No new suite."
  }
}
```

The probe is a retained manual check, not a suite: it exits 0 only when the fixed behavior is observed, and `expect_nonzero: true` makes any crash read as unfixed. Probe evidence and both consumers' exit codes are in `TESTS-RESULTS/2026-11-27+GH-792/`.
