# GH-764 macOS gate evidence — 2026-09-23

Source code commit: `97d806e2e7ab109baee508a1b714fb0fd4775942` (final Codex relay attestation).
The full run used a separate disposable full clone of that commit. Python 3.9.6 had
`requests==2.32.5`, `PyYAML==6.0.3`, and `pytest==8.4.2` in a temporary venv; Node and `gh`
were on PATH. `XYZ_WORK_CONNECTORS_REGISTRY` was unset for the full gate.

`./validate.sh` exited 0 with **411/411 passed**. `security-scan.sh` failed during the parallel
pool on four transient test files created and removed by peer suites; the runner's built-in
isolated retry passed and counted the suite green. This is a parallel contention observation,
not a clean first-pass claim. The clone's HEAD, remote, `core.bare`, and local identity matched
their pre-run snapshot, and no tracked or untracked files remained outside ignored runtime data.

Focused runs in a separate disposable full clone, with changed code copied from the task branch:
GH-142 **30/30**, GH-605 **28/28**, GH-549 **124/124**. Separate venv controls lacking only
`requests` and only `yaml` each exited 1 with a named prerequisite message before the ATE chain.
Before the fixes, the same baseline clone gave GH-142 a `ModuleNotFoundError: requests`, GH-605
27/28, and GH-549 105 passed / 20 failed. The focused code was later committed unchanged.

Logs in this folder replace local home/clone paths and the fixture owner with placeholders. The
full-gate log retains numbered decisive excerpts; its complete raw output remains only in the
disposable qualifying clone and is identified by hash in `provenance.jsonl`. The receipt records
source SHAs, commands, results, identity observation, and sanitized-log digests.
