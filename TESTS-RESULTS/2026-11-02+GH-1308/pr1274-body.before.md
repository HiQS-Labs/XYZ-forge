Closes #1270

## What this does

GH-1248 Phase 2C, the step that makes the Flywheel's output usable. The plan-draft loop (Phases 2A/2B, landed via #1249) drafted briefs and a provisional wave proposal, but nothing consumed it, and it trusted the ledger's view of readiness. Now:

- **Real issue state at init.** One read-only `gh issue list --state all` freezes the state of every issue before the planner runs, so the planner's own `already-closed` rule drops CLOSED rows. #1075 was CLOSED but sat in wave 1; it is now listed under a new **Closed** section of the proposal.
- **Delivered but still open.** One read-only `gh pr list --state merged` plus the reconciler's existing `extract_linked_issues` (scoped to this repo's slug) finds merged PRs that close a still-open issue. Such candidates are excluded at init, and such planner lanes are held in the provisional view.
- **Partly landed (stale) contracts.** A contract with any landed `fix_probes`, checked with the planner's read-only `_eval_probe`, is held as `stale-contract`. This applies to briefed lanes and to planner lanes with no brief. `command` probes are never run; they are reported as unverified. Briefs carry `probe_results`.
- **Launch packet.** New `harness.py factory-primitive --run-root R packet --wave N`:
  - For each lane of a provisional wave, it writes one `MARATHON.yaml` and one `brief.md` under the run root.
  - `marathon_yaml_emit.render` renders the YAML, and `bin/marathon-yaml` validates each lane's file.
  - It refuses unless the proposal's hash matches the latest completed plan-draft receipt.
  - The README lists, per lane, the copy step and the `marathon.sh --dry-run` command, with a builder distinct from the reviewer.
  - Copying a folder into `PROJECT/2-WORKING/` is the approval. Nothing launches.

Unchanged: the planner, the `MARATHON.yaml` schema, the validator and the launcher. Run time stays read-only to git, the ledger and GitHub, and there are no new test suites (GH-831). All changes are in `utils/py/harness.py`.

## Result on 15 real issues

- **Planner view:** 5 lanes / 2 waves, now on real state (Phase 2B had 6 / 2 with state off).
- **Provisional view:** 10 lanes / 4 waves, with 7 held.
- **Held as stale:** **#418 and #1098**, both former planner wave-1 lanes. Each has 2 of 3 contract probes already landed.
- **Closed section:** #255, #1075, #1087.
- **Delivered map:** 9 open issues have a merged PR claiming to close them: #1002, #1012, #1157, #384, #470, #484, #777, #800, #879. None was a candidate this run; they are listed as follow-ups.
- **Packet for wave 1:** 5 lanes. All 5 pass `bin/marathon-yaml`, and a copied lane passes `marathon.sh --dry-run` ("1 phase(s) would run in order").
- **Ledger:** byte-identical throughout.

## Verification

- **Plan QA:** Codex relay approved in round 2 (`relay-system/2026-10-30/gh1270-plan-qa.md`). Two findings were implemented before code:
  - the stale check must also cover planner lanes without briefs;
  - the packet must only consume a proposal from a verified tick.
- **Final QA:** Codex relay approved in round 2 (`relay-system/2026-10-30/gh1270-final-qa.md`). Round 1 found that same-repo URL closers were missed; fixed in `c8938705` by passing the repo slug, with four differential controls added.
- **Manual controls** (`TESTS-RESULTS/2026-10-30+GH-1270/controls.txt`), all passing:
  - frozen state vs a red control with seeded-only state (#1075 returns to an active lane);
  - closer vs mention, and same-repo vs foreign URL;
  - delivered planner lane held; delivered candidate excluded at init (via a gh shim);
  - unbriefed lane with a landed probe held; the all-unfixed falsifier stays eligible;
  - a `command` probe is never run;
  - the verifier refuses a brief without `probe_results`;
  - the packet emits after a clean tick and refuses (rc=2) after a `fail-after-output` tick.
- **Smoke** (`smoke.txt`): a packet rerun is digest-identical; `--wave 9` is refused; the validator passes on every lane; the copied-lane dry run passes. The smoke run found and fixed the missing `--builder` in the printed command.
- **Full gate:** `./validate.sh` (route=full) at `9f895a8f` (code identical to the final commit): **408/409**. The only failure is `relay-self-sufficiency.sh`, which makes one live agy call; agy returned `RESOURCE_EXHAUSTED (429): Individual quota reached … Resets in 51h`. This is external, and the suite is skipped by pre-push and CI by design (GH-836). A working-tree slip in the disposable clone during the run is disclosed in `gate.txt`: 19 evidence files were deleted, no code was affected, and the files were restored.
- **Ledger:** `ledger-identity.txt` shows `releases.db` and `releases.sql` identical before and after the pilot and the controls.
- **Receipts:** `TESTS-RESULTS/2026-10-30+GH-1270/provenance.jsonl`.

## Not in this PR

- Launching, scheduling or creating the per-lane clones.
- Ledger writes for closed or stale rows, which are reported only.
- Follow-ups recorded in the plan doc:
  - verify and close the nine delivered-but-open issues;
  - refresh or close #418 and #1098.

Rating: `rated 60/40/50/50` (rationale in `PROJECT/2-WORKING/GH-1270-LAUNCH-PACKET-READINESS.md`). A lesson entry was added to `LESSONS-LEARNED.md`. Reversibility: Easy (revert; the packet is a separate command).

🤖 Generated with [Claude Code](https://claude.com/claude-code)

