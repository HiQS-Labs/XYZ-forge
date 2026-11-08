# Plan draft: #1098 Shift outer loop — Phase 3: apply Phase 2 lessons (jog root pin, promotion frontmatter, builder idle bound, routed gate) and run one measured shift

> draft; preflight and independent plan QA outstanding

- Request: `gh-1098-6e96919f9b32` (tick `slot_091`)
- Draft status: **stale-contract** (held: 2 of 3 fix_probes already landed)
- Planner state: ready; flags: none
- Rating: 75/55/50/55
- Capture doc: PROJECT/2-WORKING/GH-1098-SHIFT-PHASE3.md (sha256 fca9c3b112ab1865eb46e7c78500b5d13ffbcb38893710f63898e92f2463228a)
- Issue sha256: 6e96919f9b327a830b69712050f6b01d057eb4c75fd20feccab110efcfd17a55 (updated 2026-10-30T18:46:26Z)
- Dependencies: none

## Scope

_Source: issue#1098:L5 (Scope A — machinery fixes (small, each its own commit, one PR))_

| # | Lesson from Phase 2 | Change | Where | Proof |
|---|---|---|---|---|
| A1 | Jog in a disposable clone judged the primary tree via global `XYZ_HARNESS` (#1093) | `run_marathon_phase` resolves `swarm_preflight.py` from `root` when present and exports `SWARM_PREFLIGHT_ROOT=root`; refuse loudly if `harness_home()` ≠ `repo_root(root)` in a non-vendored layout | `utils/py/jog_run.py:522-548` | Existing jog suite + manual: run from a sibling clone with `XYZ_HARNESS` pointed elsewhere, preflight finds the clone's 2-WORKING doc. Closes #1093 |
| A2 | Promoted docs failed the 2-WORKING frontmatter contract (`updated/owner/goal`) | `promote_contract_to_working` fills `updated` (today), `owner` (from `gh api user` or `git config user.name`), `goal` (from `title` when absent) and leaves a `<!-- jog: goal auto-filled; refine -->` marker; status table unchanged | `utils/py/jog_run.py:1177-1243` | `utils/pdda/pdda.sh run` green on a promoted doc that lacked all three; existing pdda suite |
| A3 | 300 s idle bound killed a healthy agy builder on a 14-file brief | Marathon executor passes `RELAY_TURN_IDLE_S` = `max(current, turn_timeout)` for **builder** turns only, or honours `turn_timeout_s` from the preflight packet's suggestion; reviewer turns keep the default | `utils/py/jog_run.py` dispatch env (~:585), `utils/py/agy-turn.py:22` | Existing gh114/gh492 suites unchanged; manual: GH-942 build reaches a file write |
| A4 | Contract gate `bash ci-local.sh` vs 1800 s gate guard; `ci-rout

_Source: issue#1098:L16 (Scope B — process (no code))_

- **Morning preflight checklist** before `jog run`, recorded in the run log: (1) every queued issue is OPEN and its `fix_probes` still read "unfixed" against current `development`; (2) no queued item's artifacts overlap an open PR's files (`gh pr list --json files`); (3) every capture doc has a `## Swarm Preflight Contract` whose `gate` is the `ci-route` tier, not `bash ci-local.sh`; (4) `XYZ_HARNESS` printed and equal to the runner clone. Radar's open-PR-collision and delivered-but-open checks are the source for (1) and (2); it is not run in full.
- Authoring rule for new contracts: `gate` = output of `printf '%s\n' <artifacts> | bash utils/ci-route.sh pull_request`.

_Source: issue#1098:L21 (Scope C — the run)_

From a fresh disposable clone of `development` after Scope A lands (or from the Scope A branch if the operator says so), queue three contract-complete items: GH-1075 and GH-942 (contracts already authored in Phase 2) plus one fresh small item chosen by the checklist. `releases jog run --reviewer codex --builder agy --max-tasks 3`, no `--auto-merge`, no env overrides beyond what Scope A made unnecessary.

_Source: PROJECT/2-WORKING/GH-1098-SHIFT-PHASE3.md:L38 (Requirements (per issue #1098 Scope A; Scope B is process, Scope C is the run))_

- **A1** Jog pins preflight to the repo it runs in. Closes #1093.
- **A2** Jog promotion yields a 2-WORKING doc that passes `pdda-check-frontmatter`.
- **A3** No agy turn dispatched by a jog invocation is idle-killed before its wall cap (operator export still wins; non-jog relays unchanged).
- **A4** When a contract names the default full gate, the pre-advance gate is the tier `validate.sh --auto` classifies for the lane's diff, consistent with the pre-push hook's existing tiered policy; the hook is not changed.

Issue #1098's original wording for criterion 1, A3 and A4 differs from the above. The adjustments are **proposed**, recorded with their source-grounded reasons at https://github.com/HiQS-Labs/XYZ-forge/issues/1098#issuecomment-6218983571; the operator accepts or objects there. Nothing in this plan treats them as accepted until that happens.

_Source: PROJECT/2-WORKING/GH-1098-SHIFT-PHASE3.md:L93 (Scope C — the measured run (after A1–A4 are on the branch))_

**Baseline (plan QA round 2, finding 2).** `validate.sh --auto development` diffs every tracked change against `development`, so on the unmerged Scope A branch the harness edits themselves (tier 3, kernel/gate surface) force the full gate for every lane and exit criterion 4 cannot be measured. Scope C therefore runs from a fresh `-verify` clone of **`development` after the Scope A PR has landed**. If the operator chooses to run it earlier on the branch, that run is labelled provisional: criteria 1–3 and 5 are measured, criterion 4 is reported as "not measurable on this baseline", never as met.

Run: `XYZ_HARNESS` left as the shell has it (A1 must make that irrelevant); queue GH-1075, GH-942 and one fresh item passing the Scope B checklist; `releases jog run --reviewer codex --builder agy --max-tasks 3`; no env overrides. A1's manual check requires the recorded preflight packet's `target_root` to be the clone **and** a successful marathon dispatch; a non-6 refusal alone is not success. A4's command quotes `target.ref` as one shell argument. Day report on #1098 against the exit criteria.

**Exit criterion 1 reconciled (plan QA round 1, finding 1).** Jog's documented landing boundary stops the queue at the first PR-ready item (`jog_run.py:405–426` returns `parked`, `:1717–1725` breaks) unless `--auto-merge` is set, which Phase 3 forbids. "≥ 2 of 3 PR-ready from one invocation" is therefore unreachable by design, and none of A1–A4 may change queue policy. The measured criterion i

_Source: PROJECT/2-WORKING/GH-1098-SHIFT-PHASE3.md:L9 (frontmatter goal)_

Unattended `jog run` invocations from a disposable clone take >= 2 of 3 contract-complete items to PR-ready across at most three invocations (one stop per landing boundary, zero operator edits between), with no wrong-tree preflight, no idle-killed builder, no promoted-doc frontmatter failure, and every pre-advance gate inside the guard cap when measured on a post-landing development baseline.

## Acceptance criteria

_missing_

## Open questions

_missing_

## Write set

- `utils/py/jog_run.py` (PROJECT/2-WORKING/GH-1098-SHIFT-PHASE3.md:preflight-contract)
- `utils/py/swarm_preflight.py` (PROJECT/2-WORKING/GH-1098-SHIFT-PHASE3.md:preflight-contract)

## Unresolved file names

- none

## Contract probes

- grep_present `utils/py/jog_run.py`: unfixed
- grep_absent `utils/py/jog_run.py`: landed
- grep_absent `utils/py/swarm_preflight.py`: landed

## Existing preflight contract

```json
{
  "artifacts": [
    "utils/py/jog_run.py",
    "utils/py/swarm_preflight.py"
  ],
  "fix_probes": [
    {
      "note": "pre-fix: preflight resolved only from harness_home (A1); landed when the root-first resolution replaces it",
      "path": "utils/py/jog_run.py",
      "pattern": "preflight_py = os.path.join\\(home, \"utils\", \"py\", \"swarm_preflight.py\"\\)\\n    if not os.path.isfile\\(preflight_py\\):",
      "type": "grep_present"
    },
    {
      "note": "landed when jog sets the idle bound for dispatched lanes (A3)",
      "path": "utils/py/jog_run.py",
      "pattern": "RELAY_TURN_IDLE_S",
      "type": "grep_absent"
    },
    {
      "note": "landed when preflight routes the default full gate (A4)",
      "path": "utils/py/swarm_preflight.py",
      "pattern": "validate.sh --auto",
      "type": "grep_absent"
    }
  ],
  "gate": "bash ci-local.sh",
  "lanes": {
    "agy_safe": [
      "utils/py/jog_run.py",
      "utils/py/swarm_preflight.py"
    ],
    "orchestrator_only": []
  },
  "remediation": {
    "criteria": "A1 preflight resolved from root with SWARM_PREFLIGHT_ROOT; A2 promoted docs carry updated/owner/goal; A3 dispatched env sets RELAY_TURN_IDLE_S to the wall cap unless exported; A4 default full gate rewritten to bash validate.sh --auto <ref> and recorded in the packet.",
    "source": "issue#1098"
  },
  "target": {
    "ref": "development",
    "repo": "."
  }
}
```
