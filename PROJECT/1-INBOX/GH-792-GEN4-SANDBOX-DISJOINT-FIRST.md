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
  - A new test suite or gate machinery (GH-831); edits to any existing suite, including the
    preflight-inferred `test/gh-gen4-phase5-campaign.sh`
  - Editing the retained readiness probe or its proof receipts under `TESTS-RESULTS/2026-11-27+GH-792/`
goal: >
  make_sandbox must resolve the source repo and the candidate clone path and refuse an
  overlapping pair (equal, clone inside source, or source inside clone) before any makedirs,
  rmtree or git clone, so no checkout at, inside or above <sandbox_root>/clone is ever
  deleted; disjoint sandboxes clone exactly as before.
---

# GH-792 · Gen 4 sandbox checks disjointness first

## Status

| What was just completed | What's next |
|---|---|
| Recon, capture, Preflight Contract, probe proof (unfixed / symmetric fix / forward-only fake / comment-only edit), both-consumer validation and PRS rating prepared 2026-11-27; probe strengthened after independent review round 1. No implementation, no queue admission. | Held: preparation review approval, publication of this preparation PR, merge to `development`, then a fresh preflight at the fetched integration ref (Conveyor step 6) before any readiness claim; then an explicit `/jog 792` or `/start-task 792` by the operator. |

## Acceptance

- [ ] The overlapping call refuses with zero `makedirs`/`rmtree`/`subprocess` calls (red control: the current order records a delete first).
- [ ] A disjoint candidate still clones as before.
- [ ] The existing self-test at `gen4_campaign.py:348` (`make_sandbox(host, os.path.join(host, "inside"))`) still refuses.

## Acceptance — deviations from the issue

The wording is unchanged: the three criteria above are the issue's `## Acceptance` bullets copied verbatim, and the issue's self-test reference `gen4_campaign.py:348` still matches the source at the baseline below. They are declared as `[added]` only because the issue writes them as plain `- ` bullets, and Preflight's acceptance parser reads only checkbox bullets (`- [ ]`). It therefore reads the issue's section as an empty list and reports NOT-READY (exit 5, `diverged`) unless they are declared. Evidence: `TESTS-RESULTS/2026-11-27+GH-792/probe-proof/1-unfixed-at-prepared-commit/preflight-792.github-origin.*`.

- [added] The overlapping call refuses with zero `makedirs`/`rmtree`/`subprocess` calls (red control: the current order records a delete first). — reason: verbatim copy of the issue's first plain-bullet criterion; declared because Preflight parses only checkbox bullets.
- [added] A disjoint candidate still clones as before. — reason: verbatim copy of the issue's second plain-bullet criterion; declared for the same parser reason.
- [added] The existing self-test at `gen4_campaign.py:348` (`make_sandbox(host, os.path.join(host, "inside"))`) still refuses. — reason: verbatim copy of the issue's third plain-bullet criterion; declared for the same parser reason.

## Recon note (parent-only)

The operator's brief for this run asked for capture, contract, preflight and one independent review. The parent read the whole seam itself, so no separate research child was dispatched. Time budget: this preparation session; attempts consumed: 0.

- **Baseline:** `origin/development` at `cf04c03b4586ad46a5fa1143648e86a6c28b4f4e` (2026-11-27; seam files identical to `76808a53b`, where the reproduction first ran).
- **Observed (reproduced):** `TESTS-RESULTS/2026-11-27+GH-792/readiness_probe.py` builds a real fixture repo at `<base>/clone` and calls `make_sandbox(repo=<base>/clone, sandbox_root=<base>)`. Today the fixture source repo is deleted, then `git clone` fails with exit 128 (`CalledProcessError`); the refusal never fires (exit 1, unfixed).
- **Code path:** `utils/py/gen4_campaign.py:84-97` `make_sandbox` runs `os.makedirs(sandbox_root)` → `shutil.rmtree(clone)` if `<clone>/.git` exists → `git clone repo clone` → only then the realpath equality/descendant check that raises `RuntimeError`. Caller: `run_campaign` (`:134`); self-test (`:348`).
- **State writer:** `make_sandbox` itself (`rmtree`, `git clone`). **Consumer/retry boundary:** `run_campaign` uses the returned clone; nothing retries.
- **Smallest plan:** compute `clone` and both realpaths first; run the existing check (plus the reverse-descendant case, source inside the clone path) before `makedirs`/`rmtree`/`clone`. One function, one file.
- **Dependencies / overlap:** no open PR touches `utils/py/gen4_campaign.py` or `test/gh-gen4-phase5-campaign.sh`. Disjoint from #1626's write set.
- **Discriminating check:** the probe records `os.makedirs` / `shutil.rmtree` / `subprocess.run` calls, passing each one through. It exits 0 only when all of these hold:
  - The equal-path call raises `RuntimeError` with zero such calls, leaving the source repo and its sentinel commit intact.
  - The **reverse-containment** call (a checkout already at `<base2>/clone`, source nested at `<base2>/clone/nested`) also refuses with zero calls and leaves both checkouts intact. The issue's narrow wording ("run the existing equality/descendant check before …") would miss this, and today it deletes both checkouts. It is the same disjointness rule, so it is in scope.
  - A disjoint call still yields a working clone.
  - The `:348` descendant shape still refuses, also with zero recorded calls and `<host>/inside` never created (added after review round 2: an early guard covering only equality and reverse containment would otherwise pass while still cloning into `host/inside/clone`).

  Every git call, including the product's `git clone`, runs with ambient `GIT_*` variables dropped, global/system config ignored and hooks pointed at an empty fixture directory. Matrices (`TESTS-RESULTS/2026-11-27+GH-792/review-round1-fixes/`, `review-round2-fixes/`): equality-and-reverse-early with forward-late (round-2 fake) 1; base 1; symmetric fix 0; forward-only early check 1; fixed tree under a hostile `GIT_DIR` and a global hook config 0, with the hook sentinel absent. Negative control: the pre-isolation probe under the same global hook ran it twice.
- **Write set:** the declared artifacts are the product file plus one new delivery receipt (`artifacts_new`, with a `path_absent` probe). The retained probe and its proof stay outside the builder's lane. Preflight also infers `test/gh-gen4-phase5-campaign.sh` into the lane; editing it is a non-goal here.
- **Foreseeable approvals/runtime:** none beyond the normal gate; `test/gh-gen4-phase5-campaign.sh` runs the campaign self-test (bounded soak, local only).
- **Unknowns:** none blocking.
- **Next owner:** the operator (explicit `/jog 792` or `/start-task 792`).

## Attempt and retry history (read 2026-11-27, nothing reset)

- `jog_queue` (primary ledger, read-only, and this clone): no row for #792. `roadmap_items`: no row before this preparation. `work_events`: none before this preparation. The preparation pickup itself wrote one `parked` event (`releases.sql`), which is not an execution attempt.
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
    "TESTS-RESULTS/2026-11-27+GH-792/delivery.md"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-11-27+GH-792/delivery.md"
  ],
  "fix_probes": [
    {
      "type": "command",
      "cmd": "python3 TESTS-RESULTS/2026-11-27+GH-792/readiness_probe.py",
      "expect_nonzero": true
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-11-27+GH-792/delivery.md"
    }
  ],
  "remediation": {
    "source": "issue#792",
    "criteria": "make_sandbox resolves repo and the candidate clone path and refuses any overlapping pair (equal, clone inside repo, or repo inside clone) before makedirs, rmtree or git clone; an overlapping call refuses with zero mutations; a disjoint candidate still clones; the gen4_campaign.py:348 self-test still refuses. Record the manual check (readiness probe output before/after) in TESTS-RESULTS/2026-11-27+GH-792/delivery.md. Do not edit the readiness probe, its proof receipts or any test suite. Existing suite only. No new suite."
  }
}
```

The probe is a retained manual check, not a suite: it exits 0 only when the fixed behavior is observed, and `expect_nonzero: true` makes any crash read as unfixed. Probe evidence and both consumers' exit codes are in `TESTS-RESULTS/2026-11-27+GH-792/`.

## Merge evidence

- PR #1647 merged 2026-11-27 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
