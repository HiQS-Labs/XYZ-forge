---
gh_issue: 1098
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1098
title: "Shift outer loop — Phase 3: apply Phase 2 lessons and run one measured shift"
status: Proposed
created: 2026-10-16
updated: 2026-10-16
owner: noelsaw1
goal: "One unattended `jog run` from a disposable clone takes >= 2 of 3 contract-complete items to PR-ready with no wrong-tree preflight, no idle-killed builder, no promoted-doc frontmatter failure, and every pre-advance gate inside the guard cap."
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
| Phase 2 (#1081) ran five live shifts; one PR (#1097); four pre-build deaths each traced to a seam | Plan QA (Codex), then Scope A fixes, then Scope C measured run |

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
- **A3** A jog-dispatched builder turn is not idle-killed before its wall cap.
- **A4** When a contract names the default full gate, the pre-advance gate is the routed tier, not the full suite; the full gate stays on the pre-push hook.

## Smallest affected surface and canonical writers

| Req | File / symbol | Change (≤ 15 lines each) |
|---|---|---|
| A1 | `utils/py/jog_run.py` `run_marathon_phase` (~:521–548) | Prefer `os.path.join(root, "utils", "py", "swarm_preflight.py")` when it exists, else the current `harness_home()` path (vendored installs). Pass `env={**os.environ, "SWARM_PREFLIGHT_ROOT": root}` to the preflight `subprocess.run`. Log one line when the resolved script is outside `root`. Same two edits at the retry path (~:1728) if it builds its own env. |
| A2 | `utils/py/jog_run.py` `promote_contract_to_working` (~:1177–1205) | Hoist the frontmatter rewrite out of the `if "## Status" not in content` branch; after setting `status: Active` and `updated: <today>`, append any of `updated`, `owner`, `goal` that are absent: `updated` = today, `owner` = `git config user.name` in `root` or `operator`, `goal` = the doc's `title:` value with a trailing `<!-- jog: goal auto-filled from title; refine -->` comment on the next line. No other key is touched. |
| A3 | `utils/py/jog_run.py` `run_marathon_phase` env block (~:583–587) | `env.setdefault("RELAY_TURN_IDLE_S", env.get("RELAY_TURN_TIMEOUT_S", "900"))` — the idle bound equals the wall cap for jog-dispatched lanes; an operator export still wins. `agy-turn.py` is unchanged. |
| A4 | `utils/py/swarm_preflight.py` (~:1390 `gate_cmd = merged.get("gate", "")`) and the packet line (~:1834) | If `gate_cmd` is one of `bash ci-local.sh`, `bash validate.sh`, `./validate.sh` (the repo's full-gate spellings), set `gate_cmd = f"./validate.sh --auto {merged['target']['ref']}"` and record `- Gate: \`<new>\` (routed by validate.sh --auto from contract gate \`<old>\`)` in the packet. `validate.sh --auto` already classifies the diff with `ci-route.sh` and fails closed to tier 3 (validate.sh:891–894). Any other contract gate is passed through untouched. |

Existing subsystems extended: Jog supervisor (`jog_run.py`), Swarm Preflight packet producer (`swarm_preflight.py`). No new module, flag, schema field, or writer. `marathon_drive.py`, `agy-turn.py`, `pdda.sh`, `ci-route.sh` unchanged.

## Non-goals

Auto-merge; scheduling; a `/shift` skill; Haiku recommendations; repairing #1020/#752; refusing on `harness_home() != root` (log only; a vendored `.xyz/` install legitimately differs); builder-only vs reviewer-only idle bounds (the bound lives in agy-turn.py only, so A3 is builder-only in practice); changing `RELAY_TURN_IDLE_DEFAULT_S` for non-jog relays.

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
| A1 | `test/gh280-jog-marathon-adapter.sh`, `test/jog-queue.sh` | From a sibling clone with `XYZ_HARNESS` pointed at the primary and a doc present only in the clone's `2-WORKING`, `jog run --dry-run` then a real preflight dispatch finds the doc (no exit 6) | Same command on the parent commit reproduces exit 6 |
| A2 | `test/pdda-local-checks.sh`, `test/gh280-jog-marathon-adapter.sh` | Promote a 1-INBOX doc lacking the three keys (GH-942's current doc); `utils/pdda/pdda.sh run` reports 0 frontmatter errors on the result | Parent commit: 3 errors for that doc |
| A3 | `test/gh114-headless-tty.sh`, `test/gh492-*` (unchanged, must stay green) | Run-log of Scope C shows the dispatched env with `RELAY_TURN_IDLE_S` equal to the wall cap; no `timeout-no-artifact` escalation while agy holds backend connections | Phase 2 run 4 is the recorded red |
| A4 | `test/swarm-preflight*.sh`, `test/gh280-jog-marathon-adapter.sh` | Preflight packet for GH-960-shaped artifacts shows `Gate: ./validate.sh --auto development (routed ...)`; the gate finishes under the 1800 s guard in Scope C | Contract with an explicit `./validate.sh --tier 2 --subsystem x` passes through unchanged |

Final gate for this PR: the changed paths route `full` (kernel/gate surface), so `bash ci-local.sh` once on the final approved commit in a disposable `-gate` clone, plus the pre-push hook.

## Preflight Bet Check

- *Outcome sought:* a jog run that fails only for reasons inside the task, not the harness's own plumbing.
- *Smallest viable bet:* four ≤15-line edits in two files; no new verbs, no new config, no new tests.
- *Alternatives rejected:* (a) environment-only workarounds (`XYZ_HARNESS=$PWD RELAY_TURN_IDLE_S=0`) — they worked in Phase 2 but leave the trap armed for the next operator; (b) a `/shift` wrapper that pre-sets env — builds a second system around a bug instead of fixing the seam; (c) making the gate guard cap configurable — treats the symptom; the route is already computed by `ci-route.sh`.
- *Rollback / containment:* each requirement is one commit; revert individually. None touch the ledger, tick, or the pre-push hook.

## Scope C — the measured run (after A1–A4 are on the branch)

Fresh `-verify` clone of this branch; `XYZ_HARNESS` left as the shell has it (A1 must make that irrelevant); queue GH-1075, GH-942 and one fresh item passing the Scope B checklist; `releases jog run --reviewer codex --builder agy --max-tasks 3`; no env overrides. Day report on #1098 against the five exit criteria in the issue.

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
    "criteria": "A1 preflight resolved from root with SWARM_PREFLIGHT_ROOT; A2 promoted docs carry updated/owner/goal; A3 dispatched env sets RELAY_TURN_IDLE_S to the wall cap unless exported; A4 default full gate rewritten to ./validate.sh --auto <ref> and recorded in the packet."
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
