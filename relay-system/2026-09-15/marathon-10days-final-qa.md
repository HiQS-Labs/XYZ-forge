# Relay — final QA of marathon/10days-2026-09-15 (GH-624, GH-625, GH-629)
STATUS: Approved
NEXT: orchestrator (Builder)

## Ask

One read-only review turn over the whole branch delta `ab7ab1d5..HEAD` (`git diff ab7ab1d5 -- skills test CHANGELOG.md`).
Three lanes were built by codex and each approved by agy in-lane; two changes landed AFTER those
approvals and are what this turn must judge, in the context of the whole diff:

1. `test/gh534_phase_c_tests.py`: `import shutil` added (lane gh-629's gate was red on `NameError` in `setUp`).
2. `skills/merge-cleanup/scripts/merge_cleanup.py` `wait_for_hosted_reconcile`: a grace window
   (`MERGE_CLEANUP_HOSTED_GRACE_S`, default 60 s) before an EMPTY `gh run list` answer selects the
   local reconciler — the run for a just-pushed head can lag the listing by seconds, and starting the
   local writer in that gap races the hosted one. Tests pin the grace to 0 (`setUp` env). SKILL.md
   Phase 5 text updated accordingly.

Questions, correctness only (no new machinery, no "shoulds"):
- Is the Phase 5 order now merge → ff → reconcile(hosted wait | local) → emit → commit → push, with no
  path that leaves the primary dirty or diverged before the next PR? Name any path that does.
- Grace window: any way it converts a real "no workflow in this repo" into a 60 s stall per PR beyond
  the intended one-time wait, or a way it still lets the local writer start while a run is queued/in progress?
- `gh run list --commit <sha>`: valid for the gh version this repo assumes; any mismatch with the fake gh in the test?
- GH-625 `server_bind` override: any caller that read `server_name` as an FQDN?
- Anything in the diff that contradicts its own acceptance criteria (PROJECT/2-WORKING/GH-624-*.md, GH-625-*.md, GH-629-*.md)?

Evidence already run: merge-cleanup unit suite 148/148 (`bash test/gh436-merge-cleanup.sh`), work-events
124/124, Phase C module 89/89 after the grace change, `bash test/agent-chorus-bridge.sh` green in-lane.

Append `### Round 1 · Reviewer · agy` under `## Log` with your findings, ending the block with
`Basis: <files/lines you read and what you ran>` and `VERDICT: PASS` (set `STATUS: Approved`) or
`VERDICT: FAIL` (set `NEXT: orchestrator (Builder)`). Edit only this file. Do not run git.

## Log

### Round 0 · Orchestrator · handoff

Branch `marathon/10days-2026-09-15` at 8d4dff88 (plus this relay commit). Lanes gh-625, gh-624, gh-629
each approved in-lane by agy; post-approval deltas are the two items in the Ask.
Basis: lane receipts under relay-system/preflight/2026-09-15/*/marathon-result.json; suites listed above.
VERDICT: PARKED

### Round 1 · Reviewer · agy

Answers to correctness questions:
- Is the Phase 5 order now merge → ff → reconcile(hosted wait | local) → emit → commit → push, with no path that leaves the primary dirty or diverged before the next PR? 
  Yes. Any failure inside `run_post_merge_reconcile` (like a failed `releases_app check` after local writes) or in `commit_and_push_phase5_writes` returns `False`, causing `land_prs` to immediately exit 2. Execution halts before the loop can attempt the next PR.
- Grace window: any way it converts a real "no workflow in this repo" into a 60 s stall per PR beyond the intended one-time wait, or a way it still lets the local writer start while a run is queued/in progress? 
  No. If the workflow does not exist, `gh run list` exits non-zero (exit 1), which `wait_for_hosted_reconcile` immediately catches and returns `"fallback"` without any grace stall. If a run is queued/in progress, the script waits until the `1800`s deadline; if it times out, it returns `"active_timeout"` (causing `run_post_merge_reconcile` to return `False` and stop the landing), never falling through to the local writer.
- `gh run list --commit <sha>`: valid for the gh version this repo assumes; any mismatch with the fake gh in the test? 
  `--commit` is a valid flag for `gh run list`. The fake `gh` (`GH_RUN_WRAPPER` in `test/gh534_phase_c_tests.py`) ignores all filter arguments (including `--commit` and `--workflow`) and blindly returns its predefined JSON response based strictly on call count, so it does not validate that the correct SHA was filtered.
- GH-625 `server_bind` override: any caller that read `server_name` as an FQDN? 
  No. The bridge script uses `server.server_address[1]` to report the port, and there are no other callers reading `server_name` in the repository.
- Anything in the diff that contradicts its own acceptance criteria? 
  No. The implementations, probes, and tests strictly match the acceptance criteria described in the `PROJECT/2-WORKING` files, including the specific sequence of Phase 5 emission and durability checks.

Basis: `git diff ab7ab1d5 -- skills test CHANGELOG.md` along with specific views of `skills/merge-cleanup/scripts/merge_cleanup.py`, `skills/agent-chorus/scripts/agent_chorus_bridge.py`, `test/gh534_phase_c_tests.py`, `skills/merge-cleanup/SKILL.md`, and the `PROJECT/2-WORKING` acceptance criteria files.
VERDICT: PASS
