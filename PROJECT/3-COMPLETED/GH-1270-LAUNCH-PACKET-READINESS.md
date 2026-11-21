---
gh_issue: 1270
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1270
title: "GH-1248 Phase 2C: plan-draft launch packet and read-only readiness check"
status: Complete
created: 2026-10-30
updated: 2026-10-30
owner: noelsaw1
goal: "Turn one wave of the plan-draft proposal into marathon launch packets an operator approves by copying, and stop closed, delivered-but-open or stale-contract issues from being packed, all read-only."
doc_type: plan
effort: 3
complexity: 3
risk: 2
phases: 1
branch: feat/XYZ-forge-gh1270-launch-packet-readiness-2026-10-30
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1248
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1261
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1175
  - https://github.com/HiQS-Labs/XYZ-forge/issues/522
non_goals:
  - Launching, scheduling or dispatching a marathon; the packet is written under temp/ only.
  - Running swarm-preflight (it fetches and adds worktrees) or executing `command` fix_probes.
  - Writing ledger state for closed or stale rows (report only).
  - Changing the marathon planner, MARATHON.yaml schema, bin/marathon-yaml or marathon.sh.
  - New test suites or gate registrations (GH-831).
---

# GH-1270 — plan-draft launch packet and read-only readiness check

## Status

| What was just completed | What's next |
|---|---|
| Plan QA approved (r2); built on `34edabb0`, `52406394`, `c8938705`; pilot, controls and smoke pass, ledger untouched; final Codex QA approved (r2) (`TESTS-RESULTS/2026-10-30+GH-1270/SUMMARY.md`) | Full gate on the final commit, then the PR |

## Problem

Phases 2A and 2B (#1257, #1261, landed via #1249) draft briefs and a provisional wave proposal, but:

1. **Nothing consumes the proposal.** There is no step from "wave proposal" to "a marathon an operator can approve".
2. **Readiness trusts the ledger alone.** `init_from_prs` (`utils/py/harness.py`) computes the planner with GitHub state `off`, and `plan_draft` uses a `stub` state file that holds only the seeded issues, all `OPEN`. A CLOSED ledger row therefore stays a ready planner lane: #1075 is CLOSED yet sits in planner wave 1 in the 2B pilot. The GH-1175 spike found 7 of 11 contracts stale and five "ready" issues that all failed (`TESTS-RESULTS/2026-10-25+GH-1175-phase0/D4-stale-contracts-intake.md`).

## Recon findings

- Base `2fa49d95` (`development`).
- **Packet format.** `MARATHON.yaml` is parsed and validated by `bin/marathon-yaml` (top level `name`, `phases`; phase fields `id, name, reviewer, max_review_rounds, depends_on, brief, artifact, turn_timeout_s`; `id` unique; `reviewer` codex/agy; single-scalar `depends_on`). `relay-automation/marathon.sh` additionally needs `brief` to exist and the plan to sit under `PROJECT/2-WORKING/` (marathon.sh:421-449, 590-596). Phases run strictly one at a time, so a wave's parallel lanes are separate marathons in separate clones, one per lane (`relay-automation/MARATHON.example.yaml` header; parallelism is across clones).
- **Existing emitter.** `utils/py/marathon_yaml_emit.py` `render(lanes, packets, reviewer, plan)` builds a validated `MARATHON.yaml` from `Lane(issue, title, dependency_issue, score)` and `Packet(issue, path, artifact)`; `brief_value` makes the brief path cwd-relative.
- **Closed issues.** `_marathon_plan.Engine._gh_state` returns the state-file value in `stub` mode; a `CLOSED` value makes a Queue / In progress row `already-closed`, which removes it from active lanes (`_marathon_plan.py:994`, readiness loop skips rows that already have a state). With state `None` the row only gets `gh-unverified` and stays ready, which is the #1075 case.
- **Delivered but open.** `wave_reconcile.extract_linked_issues(pr_meta, repo_slug)` already splits a PR's references into closers and mentions; it is importable (stdlib + `harness_paths`). Nothing applies it at intake.
- **Stale contracts.** `Engine._eval_probe` is a read-only port of the `fix_probes` predicate over the working tree (`path_absent`, `path_present`, `grep_present`, `grep_absent`; `command` returns `blocked`). The planner already marks a row `already-landed` when every probe reads `landed` (`_marathon_plan.py:1003-1011`); a partial landing is not caught.

## Bet

- **Outcome:** after a pilot run, the operator gets one ready-to-copy marathon per lane of a chosen wave, and closed, delivered-but-open or partly landed issues are kept out of it with a stated reason.
- **Smallest bet:** reuse the planner's own `already-closed` path by freezing real issue state at init; reuse `extract_linked_issues` and `_eval_probe`; reuse `marathon_yaml_emit.render` and validate with `bin/marathon-yaml`. Changes stay in `utils/py/harness.py`.
- **Alternatives rejected:** running `swarm-preflight --dry-run` (fetches, adds worktrees, runs `command` probes); one multi-phase `MARATHON.yaml` per wave (phases run serially, so it would hide the wave's parallelism); a new packet format (the launcher already has one).
- **Rollback:** revert the PR. The packet step is a separate CLI command, so the tick loop is unaffected if it is never run.

## Plan

1. **Freeze real issue state at init** (`init_from_prs`).
   - One read-only `gh issue list --state all --limit 2000 --json number,state` writes `backlog/gh-state.json` for every issue (replacing the seeded-only map), before the planner runs, so both init and `plan_draft` compute the planner in `stub` mode with real state. A failed listing fails init before any state is admitted.
   - Effect: CLOSED Queue / In progress rows become `already-closed` and leave both the planner and provisional views; seeded candidates exclude them as today.
   - The wave proposal gets a `Closed (excluded by frozen GitHub state)` section listing every Queue / In progress row the planner marked `already-closed`, so the reason is visible instead of the lane silently vanishing (plan QA nit).
   - Verify: #1075 is absent from every wave and listed in that section.
2. **Delivered-but-open check at init.**
   - One read-only `gh pr list --state merged --limit 300 --json number,title,body` ; `extract_linked_issues` closers that are still OPEN are frozen to `backlog/delivered.json` as `{issue: [pr, ...]}`.
   - A seeded candidate listed there is excluded at init with reason `possibly delivered: closed by merged PR #N, issue still open`. A planner lane listed there is held in the provisional view with the same reason (the planner view is left as computed).
   - Verify: a manual control with a merged PR that closes an open candidate excludes it; an open issue only mentioned (not closed) by a merged PR is not excluded.
3. **Partial-landing (stale contract) hold, for every lane** (plan QA R1).
   - One helper evaluates a record's contract `fix_probes` with `engine._eval_probe`; `command` probes are counted as unverified, never run.
   - In `plan_draft`: any `landed` result sets the brief's `draft_status` to `stale-contract` (held) with `k of n fix_probes already landed`, and the per-probe results go in a new brief field `probe_results` (in `BRIEF_KEYS`, rendered, verified).
   - In `_build_proposal`: the same helper runs over **every** candidate provisional lane, including planner lanes with no seeded brief; a lane with any landed probe is kept out of the provisional view and listed under held with the same reason. The planner view is left as computed.
   - Verify: a seeded control and an unseeded (no brief) control, each with one landed and one unfixed probe, are both held and absent from packets; the same records with two unfixed probes stay eligible.
4. **Launch packet command** `harness.py factory-primitive --run-root R packet --wave N [--reviewer codex|agy]`.
   - Accepts the proposal only if it belongs to a verified tick (plan QA R2): the latest `completed` `plan-draft` receipt in `state.db` must record `output_files["wave-proposal.json"]`, and that hash must equal the file on disk. Otherwise the command refuses with the reason (for example a later `uncertain` attempt rewrote the file) and writes nothing.
   - Reads that proposal and the accepted briefs; for each lane of provisional wave N writes `out/launch-packet/wave-N/GH-<n>-LAUNCH/` with `brief.md` (the plan-draft brief, or a pointer file naming the capture doc for planner lanes without a brief) and `MARATHON.yaml` rendered by `marathon_yaml_emit.render` with `Lane(issue, title, None, 0)` and `Packet(issue, PROJECT/2-WORKING/GH-<n>-LAUNCH/brief.md, ",".join(write_set))`, so paths are correct once the folder is copied into `PROJECT/2-WORKING/`.
   - Each `MARATHON.yaml` is validated with `bin/marathon-yaml`; a lane that fails (empty write set, unrepresentable scalar) is skipped and listed with its reason. A `README.md` lists each lane, the copy step and the `marathon.sh --plan … --dry-run` command; it says the packet is a draft and that copying it is the approval.
   - Read-only to the repository: writes only under the run root; never runs `marathon.sh`.
   - Verify: every emitted `MARATHON.yaml` passes `bin/marathon-yaml`; copied into a disposable clone's `PROJECT/2-WORKING/`, `marathon.sh --plan … --dry-run` accepts it.
5. **Run and record.** Pilot in a disposable full clone (`init --from-prs --limit 10 --unregistered 5`, ticks to completion, `packet --wave 1`), manual controls for steps 1–4 including the R2 negative control (a `fail-after-output` tick after a completed draft, then `packet` refuses; a clean completed tick then emits), ledger byte-identical before and after, evidence under `TESTS-RESULTS/2026-10-30+GH-1270/`. Full gate once on the final commit (changed `utils/py/harness.py` → full route).

## Acceptance

- #1075 (CLOSED) is in no wave of either view.
- A merged PR that closes a still-open candidate excludes it at init with the PR number; a mere mention does not.
- A contract with any landed `fix_probes` is held as `stale-contract` with counts, whether or not the lane has a seeded brief; `command` probes are never executed.
- `packet` refuses a proposal whose hash does not match the latest completed plan-draft receipt, and emits nothing from it.
- `packet --wave 1` writes one folder per lane; each `MARATHON.yaml` passes `bin/marathon-yaml` unmodified, and one copied into `PROJECT/2-WORKING/` passes `marathon.sh --dry-run`.
- The repository ledger is byte-identical before and after; nothing is launched.
- Red controls: with the state file reduced to seeded issues (Phase 2B behaviour), #1075 returns to wave 1; with the stale check disabled, the partly landed control is packed.

## Risks

- **Planner view changes.** The planner view now reflects real GitHub state, so its lane count can drop versus Phase 2B. That is the intended correction; the report says so.
- **Listing limits.** `--limit 2000` issues and 300 merged PRs bound the reads; an older delivering PR outside the window is missed (conservative miss, not a false hold).
- **Working-tree probes.** `_eval_probe` reads the clone's working tree, which is the frozen HEAD in a clean disposable clone; a dirty tree could skew it. The pilot runs in a clean clone.

## Rating

`rated 60/40/50/50` (pri/sev/appeal/effort), 2026-10-30. Severity: packing closed or delivered issues wastes a marathon run, but nothing launches automatically yet. Priority: this is the step that makes the Flywheel's output usable. Appeal neutral. Effort: four bounded steps in one file plus reuse of two existing helpers. Recurrence: #1075 observed today; GH-1175 measured 7 of 11 stale; trend unknown.

## Lessons Learned

- A planner fed partial GitHub state treats closed rows as ready (entry in `LESSONS-LEARNED.md`, 2026-10-30).
- Smoke the printed operator command, not just the generated file: the packet validated, but its dry-run command failed on builder == reviewer until run end to end.

## Follow-ups

- Nine open issues have a merged PR that claims to close them (#1002, #1012, #1157, #384, #470, #484, #777, #800, #879): verify and close, or reopen the work.
- #418 and #1098: 2 of 3 contract probes already landed; refresh or close.
