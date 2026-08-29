# GH-222 part 2 — vendored `.xyz` consumer dogfood (stubbed agents, not real turns)

Pattern copied from section E/H of `test/gh280-jog-marathon-adapter.sh`: consumer repo with
a real origin, harness vendored under `.xyz/`, GH-901 fixture lane with a Swarm Preflight
Contract, stub codex (builder) + agy (reviewer) binaries, canned-gh stub, `releases init` +
`jog add 901`, then ONE queue item driven end-to-end by the vendored executor invoked from a
FOREIGN cwd. Harness source: the executor lane tree at f82ce8cd.

Result: exit 0, one build round, reviewer Approved, fixture gate passed, closeout published
PR #42 (canned), queue row parked `awaiting-landing (PR #42)`.

- `marathon-invocation.json` — `harness_home` = `<consumer>/.xyz`, `argv[0]` =
  `<consumer>/.xyz/relay-automation/marathon-drive.sh`, `target_root` = the consumer repo
- `marathon-result.json` — outcome `approved`, `target_repo.path` = the consumer repo
  (`head_branch=main`, `base_branch=null`: no redirect — the fixture lane is not on a
  protected branch)
- `state.json` — vendored execution ledger inside the consumer's `.tick/jog/<gid>/`
- `queue-row.txt` — terminal `parked | awaiting-landing (PR #42: …)`
- `assertions.txt` / `vendored-run.log` — the assertion run (one earlier assertion script
  compared `/tmp` against macOS `/private/tmp` realpath form and false-failed; the corrected
  comparison passes 5/5 load-bearing checks) and the full run log
- Foreign cwd stayed clean: no `marathon-system/`, `relay-system/`, or `.tick/` created
  outside the consumer (GH-279 #2 regression check)
