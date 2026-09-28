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
