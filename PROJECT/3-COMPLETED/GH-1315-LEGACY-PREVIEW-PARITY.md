---
gh_issue: 1315
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1315
title: "Legacy migration preview refuses unadopted skill retirement"
status: Complete
created: 2026-11-11
updated: 2026-11-26
owner: Conveyor preparation (Day 2 Flywheel proving-arc candidate; ledger #1610, ranking #1616)
doc_type: bugfix
goal: "Legacy migration preview refuses unadopted skill retirement"
---

# Legacy migration preview refuses unadopted skill retirement

## Status

| What was just completed | What's next |
|---|---|
| Re-prepared 2026-11-25 on top of the 2026-11-11 Jog-trial capture: refreshed recon, a CLI-level readiness probe, and both-consumer validation. History preserved; no implementation, no queue change. | Independent preparation review, publication of this preparation PR, then an explicit `/jog 1315` or `/start-task 1315` by the operator (or the Day 2 launch step). |

## Acceptance

- [ ] The preview should refuse with the same reason, and name the fix: adopt the skill first. For a payload that already matches, the GH-1306 receipt-only path is `intake.py update xyz --source <forge>/skills/2-daily/xyz`.
- [ ] Keep the existing apply rule: retirement needs a recorded skill, and `--migrate-legacy` does not accept a deployed-but-unadopted skill.
- [ ] An unadopted real legacy directory is refused by preview and apply with an adoption remedy.
- [ ] Refusal creates no backup, staging retirement, or link and preserves the directory.
- [ ] Recorded-skill migration remains supported; verify in isolated fixtures only.
- [ ] Preview and apply are both demonstrated through the full `sync.py` command line in a disposable fixture, not by calling functions.

## Acceptance — deviations from the issue

The issue states its acceptance under `## Expected`, not `## Acceptance`, so Preflight cannot compare the two lists (it reports `no-issue-section`, advisory). The first criterion above is the first part of `## Expected` copied verbatim; its remaining sentence is replaced below.

- [changed] Alternatively, `--migrate-legacy` could accept a deployed-but-unadopted skill. That is a design choice; the preview/apply mismatch is the defect either way. -> Keep the existing apply rule: retirement needs a recorded skill, and `--migrate-legacy` does not accept a deployed-but-unadopted skill. — reason: the issue leaves the design open; the newest triage note on #1315 (2026-11-25) settles it as "keep the existing apply rule and have preview explain the same refusal and adoption remedy", which also avoids broadening retirement authorization.
- [added] An unadopted real legacy directory is refused by preview and apply with an adoption remedy. — reason: carried over from the 2026-11-11 capture; turns the issue prose into a machine-checkable checklist (manual regression evidence follows the no-new-tests rule).
- [added] Refusal creates no backup, staging retirement, or link and preserves the directory. — reason: carried over from the 2026-11-11 capture; the issue records the leftover backup ZIP as the harm.
- [added] Recorded-skill migration remains supported; verify in isolated fixtures only. — reason: carried over from the 2026-11-11 capture; the positive control (the probe checks it).
- [added] Preview and apply are both demonstrated through the full `sync.py` command line in a disposable fixture, not by calling functions. — reason: the 2026-11-25 triage note and #1616 name the missing end-to-end CLI replay as unverified; the earlier apply reproduction used functions.

## Recon note (parent-only; no research child, per the operator's brief)

- **Baseline:** `origin/development` at `086b657ea37dc2c7d3e1433e29157b451b331f1c` (2026-11-25).
- **Preview path:** `sync.py` `reconcile` (`:265`) calls `retire_legacy` (`:242`, called at `:283`) for `--migrate-legacy NAME`; preview (`apply=False`) never builds the retirement action, so nothing validates ownership. Observed through the real CLI on 2026-11-25: preview exit 0, `errors: []`, `matches_managed: true`, one `link` action planned.
- **Apply path:** apply builds the `retire-directory` action after writing the backup ZIP; `intake.py` `validate_receipt` (`:571`) then refuses it with `Invalid retirement` unless `name == "skills-sync-trinity" or name in receipt["state"]["skills"]`. That ownership rule is the state guard to reuse, before the backup.
- **Downstream/retry boundary:** none; a refused apply leaves the folder and an orphan `backups/<name>-<date>.zip`; the operator re-runs after `intake.py update <name> --source ...` (receipt-only, GH-1306).
- **Dependencies:** none blocking. Open PR #1608 (STALE_CANONICAL_FORGE warning) also edits `sync.py` around `drift_gate`/`main`; it can shift line anchors and cause a rebase, not a semantic conflict, and the probe is behavior-based.
- **Discriminating check:** `TESTS-RESULTS/2026-11-25+GH-1315/readiness_probe.py` drives `intake.py` and `sync.py` as subprocesses in a disposable fixture (unadopted `xyz`; recorded `sample` as positive control). It exits 0 only when the fixed behavior is observed: preview and apply give the identical refusal for the unadopted folder, and that refusal states the ownership reason ("not adopted", "no recorded source" or "not recorded") and the remedy `intake.py update <name> --source ...` (an unrelated error, even one mentioning "adopt", fails the probe), nothing is written, and the recorded skill still previews and applies (managed link, retained archive).
- **Foreseeable approvals/runtime:** none; `sync.py` is in a published skill folder, so the implementer runs the usual published-skill suite check at landing. Gate caution: `test/skills-army-hq.sh` prints `SKIPPED: pytest not importable` and exits 0 when the running python lacks pytest, a vacuous pass (observed under python3.12; 34 passed under python3.14 with pytest, `TESTS-RESULTS/2026-11-25+GH-1315/existing-suites/`). The gate run must use a python that imports pytest.
- **Unknowns:** the exact remedy wording is the builder's call within "adopt first" plus the `intake.py update` path; `jog` and `file-xyz-bug` are also unadopted (issue scope note), the same guard covers them.
- **Next owner:** the operator.

## Attempt and retry history (read 2026-11-25, nothing reset)

- **`jog_queue` (origin/development):** one row, `jog-01M74KY8CS4RY60S9YSFCCZTTB`, `status=pending`, `attempt_count=0`, no lease, no failure reason, created 2026-11-11T06:15:20Z. The earlier "pending 0" status is verified, not assumed. (The primary checkout's local ledger was deliberately not read.)
- **Roadmap row:** `rmi-01M74KXXCTB4NC9H8BZJAKV2CM`, section `In progress`, marker 🚧, `status_label=in-progress`, rated 60/45/50/85, doc path unchanged. `work_events`: `parked` (06:15:08Z), `in_flight` with `accepted_start: true` via `roadmap-update` (06:15:19Z), `jog_pending` (06:15:20Z). `op_receipts`: `roadmap-pickup`, `roadmap-update`, `jog-add` on 2026-11-11. This accepted-start predates this preparation and is preserved as-is.
- **Prior attempt:** Jog trial #1386 (2026-11-11) prepared this issue, enqueued it, then ran one `jog run --max-tasks 2` loop that failed on the first task (#1171) at reviewer credit exhaustion; #1315 was never dispatched. The trial made three real Jog calls (two admission refusals, then the one loop), per its 2026-11-11 closeout comment. Trial closeout: "#1315 remains pending0". Evidence: `TESTS-RESULTS/2026-11-11+GH-1315/` (function-level probe, unfixed baselines) and `TESTS-RESULTS/2026-11-11+GH-1386/1315-packet.md`, `1315-marathon-invocation.json`.
- **Branches/PRs:** none for #1315. Marathon plans `PROJECT/2-WORKING/MARATHON-PLAN-2026-11-11..26.md` list it as an independent item, unexecuted.
- **Attempts consumed:** 0 queue, 0 native (no task branch, no PR, no builder turn).
- **Launch caution:** "held" in this doc is not a queue pause. Jog selects `pending` rows (`utils/py/jog_run.py:2843-2848`), so this existing row is eligible the moment a run starts. Day 2 must reuse that row (no second row, no reset), and the 2026-11-11 accepted-start is history, not fresh approval for a new run.

## Rating rationale

Existing row preserved: `rated 60/45/50/85` (sum 240), set at pickup on 2026-11-11. `pickup` reuse preserves it; nothing was rescored. Severity 45: a preview that over-promises and an apply that refuses cleanly, with one orphan backup ZIP as the only side effect; priority 60: Day 2 candidate (#1616 ranks it second); appeal 50 neutral; effort 85: one guard in `sync.py`. Recurrence: one incident (2026-11-01), trend unknown.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash test/skills-army-hq.sh",
  "round_cap": 2,
  "artifacts": [
    "skills/3-weekly/skills-army-hq/scripts/sync.py",
    "TESTS-RESULTS/2026-11-25+GH-1315/"
  ],
  "fix_probes": [
    {
      "type": "command",
      "cmd": "python3 TESTS-RESULTS/2026-11-25+GH-1315/readiness_probe.py",
      "expect_nonzero": true
    }
  ],
  "remediation": {
    "source": "issue#1315",
    "criteria": "Check the existing retirement ownership rule (a recorded skill, as validate_receipt requires) before sync.py retire_legacy archives or stages anything, so preview and apply refuse an unadopted skill identically, state the ownership reason (the skill is not adopted / has no recorded source) and give the adoption remedy for that skill (intake.py update NAME --source ...). Refusal writes no backup ZIP, staging directory or link and leaves the folder intact. Recorded-skill migration still previews and applies. Do not broaden retirement authorization or change deployed configuration. Use the existing skills-army-hq suite."
  }
}
```

The probe is a retained manual check, not a suite: it exits 0 only when the fixed behavior is observed, and `expect_nonzero: true` makes any crash read as unfixed. It replaces the 2026-11-11 function-level probe, which stays in `TESTS-RESULTS/2026-11-11+GH-1315/` as history. Probe evidence (unfixed, simulated fix, comment-only edit) and both consumers' exit codes are in `TESTS-RESULTS/2026-11-25+GH-1315/`.

## Merge evidence

- PR #1622 merged 2026-11-26 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
