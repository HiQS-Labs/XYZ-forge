# GH1430 independent final QA
STATUS: Open
NEXT: codex

Review the committed implementation of https://github.com/HiQS-Labs/XYZ-forge/issues/1430 on this branch against its approved plan `PROJECT/2-WORKING/GH-1430-BOARD-SYNC-WAL-READ.md` (plan QA: `relay-system/2026-11-11/gh1430-plan.codex.md`, Approved round 1). Diff: `git diff 0f21b761a..HEAD` (read it from the files; do not run git yourself if your turn forbids it: the changed files are `utils/py/board_sync.py` (lines ~135-190), `CHANGELOG.md` (top entry), the plan doc, `releases.db`/`releases.sql` (ledger row for GH-1430 via the CLI), and `TESTS-RESULTS/2026-11-11+GH-1430/` (SUMMARY.md, manual_matrix.py, matrix.log, smoke.sh, smoke-live.log, provenance.jsonl)).

Operational envelope: a local single-operator CLI reading a local SQLite DB to enrich an advisory board repo list. Grade against stated requirements and commensurate complexity; do not impose enterprise threat models. XYZ-forge forbids new tests (AGENTS.md, GH-831): a new `test/` suite or validate.sh registry entry would itself be a finding. The manual matrix under TESTS-RESULTS is the intended evidence.

Questions:
1. Does `board_sync.py` implement exactly plan steps 1-3 (mode=rw, `PRAGMA query_only=ON` as the first statement inside the existing inner try so `finally: conn.close()` still runs, timeout=2 kept, warn-and-fall-back unchanged, hint and docstring reworded)? Any behaviour change beyond that?
2. Does the matrix substantiate the acceptance: a non-empty red control (base returns [] with the CANTOPEN warning; new code returns both fixture repos), write refusal, unchanged fixture bytes/mtime, missing-file fallback with nothing created? Is the matrix sound (e.g. does it really load the base revision for the red control; can an empty result pass)?
3. Is the live smoke read-only and honestly reported, including that the agent-only on/off criterion is **outstanding** because no live repo is agent-only (all 3 agent repos also have github_activity rows), rather than claimed?
4. Does the persisted rating `rated 60/55/50/95` match the plan's rationale? Is the CHANGELOG entry accurate?
5. Did a duplicate subsystem/writer, new test, or unrelated change slip in?

Read whole affected contexts. Do not run test/*.sh, validate.sh or pytest in this worktree; read-only probes under $TMPDIR only (`export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"`). You may re-run `manual_matrix.py` under `/usr/bin/python3` only if it writes solely under $TMPDIR (it uses tempfile.mkdtemp). Findings that ask for a behaviour change carry `Observed input:`, `Affected scope:` and `Falsifier:` lines with file:line citations. Append `### Round 1 · Reviewer · codex`, a literal `swept file: yes/no`, and **Verdict:** Approved or Changes requested. Set STATUS: Approved only if approved, and NEXT: orchestrator. Do not edit any other file or run git.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
