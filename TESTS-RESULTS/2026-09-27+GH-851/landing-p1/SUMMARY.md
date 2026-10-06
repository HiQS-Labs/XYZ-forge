# PR #880 Codex review P1 — a timed-out git call left its children running

**Finding.** `scan_clones.run_git(timeout=…)` used `subprocess.run`, which kills only `git`. The bounded
push (`merge_cleanup.commit_and_push_phase5_writes`, `PUSH_GATE_TIMEOUT_S`) runs the pre-push hook as
git's child, so an expired push left the hook and its gate running after merge-cleanup had returned
failure. The bound was new in this window (#851), so the landing introduced it.

**Fix.** A bounded call runs in its own session (`start_new_session=True`); on expiry the whole group
gets TERM, a 5 s grace, then KILL, the same sequence as `utils/py/proc_group.py` `kill_existing`
(not importable here: the skill ships standalone and vendored `.xyz/` installs lack it). Unbounded
calls are unchanged.

**Witness** (`witness.py`: a git alias backgrounds a grandchild, then blocks; `run_git(timeout=2)`):
before `rc=124 grandchild_alive_after_timeout=True` FAIL; after `rc=124 …=False` PASS.

**Suites:** gh436 (includes `gh534_phase_c_tests.py`, 111 passed; its timed-call assertion now
patches `Popen` and checks `start_new_session` + the forwarded timeout), gh674, gh645: green.

## Follow-up: interrupt during a bounded call (Agy review of `a5b681b5`, blocker)

**Finding.** A bounded call's own session means a terminal Ctrl-C no longer reaches git. The interrupt raised
`KeyboardInterrupt` out of `communicate()` past the `TimeoutExpired` handler, so git and its hook kept running, and a
cancelled push could still land. Before this window's P1 fix, git shared the foreground group and got the SIGINT.

**Fix.** Any exception out of `communicate()` ends the group first; only `TimeoutExpired` is turned into rc 124, and
everything else is re-raised. The docstring now says which installs lack `proc_group.py`: standalone Deployed Skills and
`.xyz/` vendored before `utils/` was mirrored (current `xyz-vendor.sh` mirrors it).

**Witness** (`witness_sigint.py`: a child calls `run_git(timeout=60)` on the blocking alias, then gets SIGINT):
before `grandchild_alive_after_sigint=True` FAIL; after `=False` PASS. `witness.py` (timeout) still PASS.
Suites: gh436 (incl. `gh534_phase_c`), gh674 and gh645 green.
