---
gh_issue: 1098
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1098
title: "Shift outer loop — Phase 3: apply Phase 2 lessons and run one measured shift"
status: Active
created: 2026-10-16
updated: 2026-10-16
owner: noelsaw1
goal: "Unattended `jog run` invocations from a disposable clone take >= 2 of 3 contract-complete items to PR-ready across at most three invocations (one stop per landing boundary, zero operator edits between), with no wrong-tree preflight, no idle-killed builder, no promoted-doc frontmatter failure, and every pre-advance gate inside the guard cap when measured on a post-landing development baseline."
doc_type: plan
effort: 2
complexity: 2
risk: 2
phases: 2
fix_probes:
  - test -f utils/py/jog_run.py
  - test -f utils/py/swarm_preflight.py
  - python3 test/gh280-jog-marathon-adapter.sh --help
---

# GH-1098: Shift outer loop — Phase 3

## Status

| What was just completed | What's next |
|---|---|
| Plan QA Approved (Codex, 3 rounds, `relay-system/2026-10-16/gh1098-plan-qa.md`); A1–A4 implemented (`4dc76a33`, `e358dd86`); manual checks A1–A4 witnessed on candidate and parent in the `-gate` clone (`TESTS-RESULTS/2026-10-16+GH-1098/`) | Focused suites + full `ci-local.sh` in the gate clone, final Codex QA, PR; Scope C after landing |

## Observed problem (from Phase 2, 2026-10-15/16, runner clone `XYZ-forge-gh1081-factory-manager-spike-2026-10-15-verify`)

| Run | Failure | Seam | Evidence |
|---|---|---|---|
| 3 | preflight exit 6 "no capture doc" for a doc jog had just promoted | `jog_run.run_marathon_phase` resolves `swarm_preflight.py` from `harness_home()` (honours global `XYZ_HARNESS`) and never passes `SWARM_PREFLIGHT_ROOT`; `compute_default_root(__file__)` then roots the doc glob in the primary clone | #1093; `temp/shift-2026-10-15-jog-run3.log` |
| 4 | agy builder killed at ~5 min, `timeout-no-artifact`, 0 CPU / 0 writes while holding 6 live TCP connections | `utils/py/agy-turn.py:22` `RELAY_TURN_IDLE_DEFAULT_S = 300` (GH-492); the packet itself suggested `turn_timeout_s: 1800` | `marathon-system/gh-942-*/ESCALATION.md`; rerun with `RELAY_TURN_IDLE_S=0` built in ~20 min |
| 5 | pre-advance gate: PDDA 6 errors `missing required frontmatter key updated/owner/goal` on the two promoted docs | `jog_run.promote_contract_to_working` copies 1-INBOX frontmatter verbatim and only rewrites `status:`/`updated:` when a `## Status` table is absent; 2-WORKING requires `title status created updated owner goal` (`utils/pdda/pdda.sh:40`) | run-5 log lines 215–240 |
| 5 | same gate then killed by the resource guard at the 1800 s wall cap | contract `gate` was `bash ci-local.sh` (full); `utils/ci-route.sh` classified the lane's two paths as tier 2 (`skills-army-hq`, ~95 s) | `marathon-drive: gate-guard: KILLING ... wall clock 1800s`; manual tier-2 run 6/6 green |

## Requirements (per issue #1098 Scope A; Scope B is process, Scope C is the run)

- **A1** Jog pins preflight to the repo it runs in. Closes #1093.
- **A2** Jog promotion yields a 2-WORKING doc that passes `pdda-check-frontmatter`.
- **A3** No agy turn dispatched by a jog invocation is idle-killed before its wall cap (operator export still wins; non-jog relays unchanged).
- **A4** When a contract names the default full gate, the pre-advance gate is the tier `validate.sh --auto` classifies for the lane's diff, consistent with the pre-push hook's existing tiered policy; the hook is not changed.

Issue #1098's original wording for criterion 1, A3 and A4 differs from the above. The adjustments are **proposed**, recorded with their source-grounded reasons at https://github.com/HiQS-Labs/XYZ-forge/issues/1098#issuecomment-6218983571; the operator accepts or objects there. Nothing in this plan treats them as accepted until that happens.

## Smallest affected surface and canonical writers

| Req | File / symbol | Change (≤ 15 lines each) |
|---|---|---|
| A1 | `utils/py/jog_run.py` `run_marathon_phase` (~:521–548) and the legacy relay-executor preflight call (~:1728–1735) | Marathon path: prefer `os.path.join(root, "utils", "py", "swarm_preflight.py")` when it exists, else the current `harness_home()` path (vendored installs); pass `env={**os.environ, "SWARM_PREFLIGHT_ROOT": root}` to the preflight `subprocess.run`; log one line when the resolved script is outside `root`. Legacy path already resolves from `root`; add the same env pin there. Marathon *retry* verbs re-enter `run_marathon_phase`, so they are covered by the first edit. `swarm_preflight.py:1199` reads `SWARM_PREFLIGHT_ROOT` for the doc glob (:1235) and target selection (:1204–1210). #1093 allows root pinning **or** refusal; the plan pins and logs. #1098's "refuse loudly" wording is recorded as superseded by that choice (a vendored `.xyz/` install legitimately differs). |
| A2 | `utils/py/jog_run.py` `promote_contract_to_working` (~:1177–1205) | Hoist the frontmatter rewrite out of the `if "## Status" not in content` branch so `status: Active` / `updated: <today>` apply whether or not a Status table exists; the Status table itself is still only inserted when absent. Then append **only the absent** keys among `updated`, `owner`, `goal`: `updated` = today, `owner` = `git config user.name` in `root` or `operator`, `goal` = the doc's `title:` value followed by a YAML comment line `# jog: goal auto-filled from title; refine` (an HTML comment would parse as a mapping key). Existing `owner`/`goal` values are never overwritten. |
| A3 | `utils/py/jog_run.py` `run_marathon_phase` env block (~:583–587) | `env.setdefault("RELAY_TURN_IDLE_S", env.get("RELAY_TURN_TIMEOUT_S", "900"))` — the idle bound equals the wall cap for **every agy turn a jog invocation dispatches** (builder or reviewer); an operator export still wins; non-jog relays keep the 300 s default. This is a deliberate narrowing of #1098's "builder-only" wording: the bound lives in `agy-turn.py:463` with no role input, and a role-aware reset would need a new seam in `relay_drive.py`, which is more machinery than the fix warrants. Recorded as a reconciled requirement, not an oversight. The 900 s wall cap does not promise a 20-minute build completes; Scope C measures that. |
| A4 | `utils/py/swarm_preflight.py` (~:1390 `gate_cmd = merged.get("gate", "")`) and the packet line (~:1834) | If `gate_cmd` is one of `bash ci-local.sh`, `bash validate.sh`, `./validate.sh` (the repo's full-gate spellings), set `gate_cmd = f"bash validate.sh --auto <ref>"` and record `- Gate: \`<new>\` (routed by validate.sh --auto from contract gate \`<old>\`)` in the packet; the invocation JSON `gate` and the `--pre-advance-cmd` argv carry the rewritten value. `validate.sh --auto <base>` classifies all tracked differences against the supplied ref (single-ref form: `git diff --name-only <ref>`) with `ci-route.sh` and fails closed to tier 3 when unclassifiable (validate.sh:891–894); at gate time HEAD is the lane's reviewed candidate and base is the contract's `target.ref`. Any other contract gate is passed through untouched. **Landing policy is unchanged and tiered:** `githooks/pre-push:258–299` runs the docs or tier-2 gate for eligible pushes and the full gate only as the fallback, so this change makes the pre-advance gate consistent with what push already enforces; it does not add or remove a full-gate run. #1098's "full gate still runs on push" wording is recorded as reconciled to that existing policy. |

Existing subsystems extended: Jog supervisor (`jog_run.py`), Swarm Preflight packet producer (`swarm_preflight.py`). No new module, flag, schema field, or writer. `marathon_drive.py`, `agy-turn.py`, `pdda.sh`, `ci-route.sh` unchanged.

## Non-goals

Auto-merge; scheduling; a `/shift` skill; Haiku recommendations; repairing #1020/#752; refusing on `harness_home() != root` (log only; a vendored `.xyz/` install legitimately differs); a role-aware idle bound (A3 applies to every agy turn jog dispatches; a builder-only variant would need a new seam in `relay_drive.py`); changing `RELAY_TURN_IDLE_DEFAULT_S` for non-jog relays; any change to queue/landing policy in `jog_run.py` (Scope C's criterion is reconciled to the existing boundary instead); any change to `githooks/pre-push`.

## Dependencies and ordering

A1 → A2 → A3 → A4 are independent edits in two files; land as four commits on one branch. Scope C depends on all four being on the branch the runner clone checks out. Scope B (morning checklist) needs no code.

## Risks and rollback

- A1: a vendored install whose `root` has no `utils/py/swarm_preflight.py` falls through to the existing path — behaviour unchanged there. Rollback: revert the commit.
- A2: `goal` auto-filled from `title` is a placeholder; the marker makes that visible to PDDA readers and reviewers. Rollback: revert; docs already promoted keep their keys.
- A3: a genuinely hung agy turn now runs to the wall cap (900 s default) instead of 300 s. Cost bounded by `RELAY_TURN_TIMEOUT_S`. Rollback: revert, or export `RELAY_TURN_IDLE_S=300`.
- A4: `validate.sh --auto` needs a git diff against `target.ref`; a lane whose ref is unreachable already fails earlier in preflight (exit 6). Fails closed to tier 3 when unclassifiable. Rollback: revert; contracts naming an explicit tier are unaffected.

## Verification (no new tests, GH-831)

| Req | Existing suite | Manual check recorded under `TESTS-RESULTS/2026-10-16+GH-1098/` | Red control |
|---|---|---|---|
| A1 | `test/gh280-jog-marathon-adapter.sh`, `test/jog-queue.sh` | In the disposable `-verify` clone with `XYZ_HARNESS` exported to the primary and a scratch capture doc present only in the clone's `2-WORKING`: a marathon-executor dispatch for that issue reaches `marathon-drive` (preflight exit 0 or a non-6 verdict) and the recorded preflight packet's `target_root` is the clone | Parent commit, identical setup: preflight exit 6 `no in-repo GH-N capture doc under PROJECT/2-WORKING/` (Phase 2 run 3 reproduced) |
| A2 | `test/pdda-local-checks.sh`, `test/gh280-jog-marathon-adapter.sh` | Seed two scratch 1-INBOX captures with `updated`, `owner`, `goal` deliberately stripped, one with and one without a `## Status` table; promote each via jog; `utils/pdda/pdda.sh run` reports 0 `pdda-check-frontmatter` errors for both, and a third capture that already carries `owner`/`goal` keeps its original values byte-for-byte | Parent commit on the same seeded inputs: 3 frontmatter errors per stripped doc (6 total) |
| A3 | `test/gh114-headless-tty.sh`, `test/gh492-idle-kill.sh` (unchanged, must stay green) | Scope C run log records the dispatched env with `RELAY_TURN_IDLE_S` equal to `RELAY_TURN_TIMEOUT_S`; the GH-942 lane's first agy turn produces a file write (no `timeout-no-artifact`) | Phase 2 run 4 is the recorded red; a parent-commit dispatch with no operator export shows no `RELAY_TURN_IDLE_S` in the env |
| A4 | `test/swarm-preflight*.sh`, `test/gh280-jog-marathon-adapter.sh` | For a contract whose `gate` is `bash ci-local.sh`, the emitted `marathon-invocation` JSON `gate` and `--pre-advance-cmd` argv read `bash validate.sh --auto development` and the packet carries the `(routed by validate.sh --auto from contract gate ...)` line; in Scope C the GH-960-shaped lane's pre-advance gate finishes inside the 1800 s guard | Parent commit, same contract: JSON `gate` and argv still read `bash ci-local.sh`. Compatibility (not a red control): a contract with `./validate.sh --tier 2 --subsystem x` is unchanged on both |

All manual checks are recorded under `TESTS-RESULTS/2026-10-16+GH-1098/` with the parent and candidate outputs side by side and a `provenance.jsonl`.

Final gate for this PR: the changed paths route `full` (kernel/gate surface), so `bash ci-local.sh` once on the final approved commit in a disposable `-gate` clone; the pre-push hook then applies its own tiered route (full for these paths). Evidence required before landing is the hook's routed gate plus hosted checks for the head SHA, per existing policy.

## Preflight Bet Check

- *Outcome sought:* a jog run that fails only for reasons inside the task, not the harness's own plumbing.
- *Smallest viable bet:* four ≤15-line edits in two files; no new verbs, no new config, no new tests.
- *Alternatives rejected:* (a) environment-only workarounds (`XYZ_HARNESS=$PWD RELAY_TURN_IDLE_S=0`) — they worked in Phase 2 but leave the trap armed for the next operator; (b) a `/shift` wrapper that pre-sets env — builds a second system around a bug instead of fixing the seam; (c) making the gate guard cap configurable — treats the symptom; the route is already computed by `ci-route.sh`.
- *Rollback / containment:* each requirement is one commit; revert individually. None touch the ledger, tick, or the pre-push hook.

## Scope C — the measured run (after A1–A4 are on the branch)

**Baseline (plan QA round 2, finding 2).** `validate.sh --auto development` diffs every tracked change against `development`, so on the unmerged Scope A branch the harness edits themselves (tier 3, kernel/gate surface) force the full gate for every lane and exit criterion 4 cannot be measured. Scope C therefore runs from a fresh `-verify` clone of **`development` after the Scope A PR has landed**. If the operator chooses to run it earlier on the branch, that run is labelled provisional: criteria 1–3 and 5 are measured, criterion 4 is reported as "not measurable on this baseline", never as met.

Run: `XYZ_HARNESS` left as the shell has it (A1 must make that irrelevant); queue GH-1075, GH-942 and one fresh item passing the Scope B checklist; `releases jog run --reviewer codex --builder agy --max-tasks 3`; no env overrides. A1's manual check requires the recorded preflight packet's `target_root` to be the clone **and** a successful marathon dispatch; a non-6 refusal alone is not success. A4's command quotes `target.ref` as one shell argument. Day report on #1098 against the exit criteria.

**Exit criterion 1 reconciled (plan QA round 1, finding 1).** Jog's documented landing boundary stops the queue at the first PR-ready item (`jog_run.py:405–426` returns `parked`, `:1717–1725` breaks) unless `--auto-merge` is set, which Phase 3 forbids. "≥ 2 of 3 PR-ready from one invocation" is therefore unreachable by design, and none of A1–A4 may change queue policy. The measured criterion is: **≥ 2 of 3 items reach PR-ready across at most three `jog run` invocations, each started only after the previous one stopped at its landing boundary, with zero operator edits to code, docs, env or ledger between invocations.** Each invocation is one row in the day report. #1098's criterion 1 is recorded as reconciled to this wording.

## Rating (2026-10-16)

PRS pri/sev/appeal/effort = 75/55/50/55. Severity: no data loss; the cost is wasted builder runs, false `failed` rows, and a dispatch loop that judges the wrong tree (recoverable). Recurrence: 2 of 3 preflight invocations in one shift hit A1; 1 of 2 builder turns hit A3; 2 of 2 promoted docs hit A2; 1 of 1 gates hit A4 — all within one day's window, prior trend unknown because unattended jog runs were rare before #1081. Priority follows severity plus the operator's stated ordering (Phase 3 next). Appeal neutral. Effort: four surgical edits in known lines.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash ci-local.sh",
  "fix_probes": [
    {
      "type": "grep_present",
      "path": "utils/py/jog_run.py",
      "pattern": "preflight_py = os.path.join\\(home, \"utils\", \"py\", \"swarm_preflight.py\"\\)\\n    if not os.path.isfile\\(preflight_py\\):",
      "note": "pre-fix: preflight resolved only from harness_home (A1); landed when the root-first resolution replaces it"
    },
    {
      "type": "grep_absent",
      "path": "utils/py/jog_run.py",
      "pattern": "RELAY_TURN_IDLE_S",
      "note": "landed when jog sets the idle bound for dispatched lanes (A3)"
    },
    {
      "type": "grep_absent",
      "path": "utils/py/swarm_preflight.py",
      "pattern": "validate.sh --auto",
      "note": "landed when preflight routes the default full gate (A4)"
    }
  ],
  "artifacts": [
    "utils/py/jog_run.py",
    "utils/py/swarm_preflight.py"
  ],
  "remediation": {
    "source": "issue#1098",
    "criteria": "A1 preflight resolved from root with SWARM_PREFLIGHT_ROOT; A2 promoted docs carry updated/owner/goal; A3 dispatched env sets RELAY_TURN_IDLE_S to the wall cap unless exported; A4 default full gate rewritten to bash validate.sh --auto <ref> and recorded in the packet."
  },
  "lanes": {
    "agy_safe": [
      "utils/py/jog_run.py",
      "utils/py/swarm_preflight.py"
    ],
    "orchestrator_only": []
  }
}
```

## Merge evidence

- PR #1099 merged 2026-10-16 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #1102 merged 2026-10-17 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #1104 merged 2026-10-17 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #1237 merged 2026-10-27 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #1274 merged 2026-10-30 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
