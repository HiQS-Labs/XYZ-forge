# GH-1498 — pr-minder evidence

This is a recorded manual check and smoke test. It is not a test suite (GH-831), and no test file or registry entry was added.

| File | What it shows |
|---|---|
| `manual_check.py.txt` | The driver. It puts a stateful fake `gh` on `PATH`, serves canned PRs and history, and logs every write verb. Assertions A1–A12 come from the approved plan (`PROJECT/1-INBOX/GH-1498-PR-MINDER.md`). Each assertion also runs a controlled bad candidate (an in-process monkeypatch, never committed) that must fail it. |
| `manual-check.log`, `manual-check-results.json` | 13 of 13 PASS, with every bad candidate rejected. A12 is a render check and has no bad candidate. |
| `smoke-plan-mode.log` | Two plan-mode runs on this real repo, back to back: the main path, then a rerun as the adjacent path. Both give identical output and both exit 0. Plan mode has no write path, and A1 proves that with the shim. Held #1024 is reported as held; #1391 and #1417 sit at rung 2 (conflicting). |
| `graphql-node-limit.log` | Why the author history is a separate query: adding `commits` to the bulk `gh pr list --limit 300` fails GitHub's 500,000-node limit (rc=1). |

**Fixture corrections during the run, recorded honestly.** The first run had 6/13 passing. The fake PRs lacked `state`, so the pre-write refresh correctly aborted every write. That was a fixture gap, and it shows the abort path works. The second run had 11/13 passing. The fake `gh` didn't clear `BEHIND` after an update-branch, and A11's bad candidate fell back to a 60-day age, which is rung 4 and report-only, so it couldn't produce a write. Both were fixture modelling problems. No product code changed between runs.

**Not exercised.** `--apply` was never run against real PRs. That writes to other people's PRs and needs the operator's explicit go. The conflict-file lookup was exercised live in plan mode (`--explain 1391` listed 2 files) but not under the shim, where `git fetch` has no remote and the comment shows "files unknown".
