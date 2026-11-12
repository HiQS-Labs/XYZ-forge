# GH1421 final implementation QA
STATUS: Open
NEXT: codex

Final QA of the committed implementation for https://github.com/HiQS-Labs/XYZ-forge/issues/1421 against its approved plan.

Read in full:
- Plan (approved in `relay-system/2026-11-11/gh1421-plan.codex.md`, round 3): `PROJECT/2-WORKING/GH-1421-BOARD-SYNC-REPOS-SOURCE.md`
- Implementation: `utils/py/board_sync.py` (`POLICY_DEFAULTS`, `_rebalance_active_repos`, `_resolve_policy_and_label`); diff with `git diff 046b41538 -- utils/py/board_sync.py` is the reviewed change (read it via the files; do not run git).
- Evidence: `TESTS-RESULTS/2026-11-11+GH-1421/` (`SUMMARY.md`, `manual_matrix.py`, `matrix-pass-live.log`, `redcontrol-*.log`, `suites/`, `smoke.md`, `smoke-live.err`, `provenance.jsonl`)
- `CHANGELOG.md` top entry.
- Ledger: `releases.sql` diff carries the GH-1421 row `rated 50/45/50/75` with an accepted start.

Operational envelope: local single-operator CLI reading a local SQLite DB read-only for an advisory repo list. Grade against the issue's acceptance and the approved plan with commensurate complexity; no enterprise threat models, new suites, registries or gates. XYZ-forge forbids new tests (GH-831): a new `test/` suite or `validate.sh` entry would be a finding; `manual_matrix.py` under TESTS-RESULTS is an evidence script like GH-898's.

Questions:
1. Does the code match plan steps 1-5 exactly (bool key default false and validation; agent query on the same connection after the GitHub rows; GitHub order unchanged, agent-only appended by runs DESC, name; inner try keeps GitHub rows on any agent-query error with a distinct missing-table message; single `mode=ro` open, no immutable, named-cause warning only when CANTOPEN and no sidecars)?
2. Is key-off behaviour unchanged (stdout and policy identical; only the no-sidecar stderr wording differs), and does the matrix's base comparison actually prove that?
3. Do the matrix checks and red controls substantiate each acceptance item, including the F2 mutation control? Any assertion that is vacuous or could pass on empty input?
4. Is the RELEASES rating consistent with the evidence (severity: degraded advisory projection plus the live reader falling back on this Mac; effort: one file)?
5. Any duplicate subsystem/writer, scope creep, or missing piece?

Do not run test/*.sh, validate.sh or pytest in this worktree; read-only probes under $TMPDIR only. Behaviour-change findings carry Observed input, Affected scope and Falsifier with file:line. Append `### Round 1 · Reviewer · codex` with `swept file: yes/no` and **Verdict:** Approved or Changes requested. Set STATUS: Approved only if approved, NEXT: orchestrator. Edit no other file; no git.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
