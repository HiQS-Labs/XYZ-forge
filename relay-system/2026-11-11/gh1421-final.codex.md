# GH1421 final implementation QA
STATUS: Approved
NEXT: orchestrator

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

### Round 1 · Reviewer · codex

swept file: yes

**Verdict:** Changes requested — Block on F1 below.

The implementation follows approved plan steps 1–5 literally: strict bool/default false, conditional agent query on the existing connection, additive merge, inner SQLite-error fallback, and one ordinary read-only open with a qualified no-sidecar warning. The plan's SQL itself contains F1, so literal conformance does not establish acceptance. No duplicate writer, subsystem, new registered suite or gate is introduced. This remains an Easy, reversible extension; key-on membership feeds board eligibility.

**F1 [Should fix] — HAVING resolves the stored column instead of the aggregate (`utils/py/board_sync.py:153-155`).**

Observed input: two in-window rows for the same repo with runs 0 and 5 (valid across days/devices/providers). The submitted `SUM(runs) AS runs ... HAVING runs > 0` returns no repo when the zero row is selected as SQLite's bare-column representative. Reversing row order returns the repo. SQLite resolves the HAVING name to the underlying column when it collides with the alias. Affected scope: opted-in agent-only repos with mixed zero/positive rows can silently disappear despite positive total runs, defeating acceptance A2. The default-zero schema makes this an ordinary valid input; no corruption or enterprise threat model is needed.

Falsifier / smallest correction: use `HAVING SUM(runs) > 0` (or an unambiguous aggregate alias), and extend the existing manual evidence matrix with multiple rows per repo, including a zero row before a positive row. Preserve ordering, zero-only exclusion and the existing error fallback. No new suite is needed. The current matrix at `manual_matrix.py:107-109` has only one row per exact repo, so its green result cannot catch F1.

Read-only probe command (exit 0; no fixture, source mutation or on-disk DB):

```python
# python3 - <<'PY'  (PYTHONDONTWRITEBYTECODE=1, TMPDIR=$PWD/.relay-scratch/tmp)
import sqlite3
c = sqlite3.connect(':memory:')
q = "WITH agent_session_activity(repo_full_name,day,runs) AS (VALUES ('o/mixed','2026-11-11',0),('o/mixed','2026-11-11',5)) SELECT repo_full_name, SUM(runs) AS runs FROM agent_session_activity WHERE day >= '2026-11-01' GROUP BY repo_full_name HAVING runs > 0 ORDER BY runs DESC, repo_full_name LIMIT 8"
print('submitted query:', c.execute(q).fetchall())
print('SUM(runs) control:', c.execute(q.replace('HAVING runs > 0','HAVING SUM(runs) > 0')).fetchall())
print('positive-first control:', c.execute(q.replace("0),('o/mixed','2026-11-11',5)","5),('o/mixed','2026-11-11',0)")).fetchall())
# PY
```

Decisive output:
```text
submitted query: []
SUM(runs) control: [('o/mixed', 5)]
positive-first control: [('o/mixed', 5)]
```

Evidence assessment: the base comparison uses nonempty resolved policy and nonempty config stdout, with key-on differentiation; it supports key-off identity for its populated fixture, rather than empirically proving “every DB.” Source inspection supports unchanged key-off control flow apart from warning wording. The missing-table and malformed-table preservation checks compare concrete nonempty lists. The F2 outer-catch mutation log has four relevant failures, rc=1, and restoration returns ALL PASS, rc=0: a meaningful red control. The other recorded checks substantiate their stated cases, but not multi-row aggregation (F1) or a name tie. Live output transparently records fallback and 25 rows through the diagnostic immutable read; production does not adopt immutable. Smoke explicitly discloses that live policy-preview was not run.

Read the supplied plan, prior approval, implementation reader/resolver, CHANGELOG entry, manual matrix, all matrix/red-control/smoke logs, suite tails and provenance. Existing-suite success is recorded at 49b9895bd in the supplied disposable-clone receipts; no suites, pytest, validate.sh, executable fixtures or git were run in this turn. Final committed-state harness qualification remains outstanding. The ledger row has 50/45/50/75 and an accepted-start in_flight event; the advisory projection impact and one-file implementation make that rating reasonable. No other blocking finding. Only this relay file was edited.

### Round 2 · Builder · orchestrator

- **F1 [Should fix] — Accepted and fixed in 2565f073b.** The agent query now aliases `SUM(runs) AS total_runs` and uses `HAVING total_runs > 0 ORDER BY total_runs DESC, repo_full_name` (`utils/py/board_sync.py:153-155`); the plan's SQL is updated with the reason. The matrix gains A2b: `o/mixed` with a 0-run row inserted before a 5-run row, a runs tie (`o/tie-a` 2+3 vs `o/tie-b` 5) broken by name, and an all-zero repo excluded. Red control: the same matrix against 49b9895bd's `board_sync.py` fails A2b with `o/mixed` dropped, rc=1 (`TESTS-RESULTS/2026-11-11+GH-1421/redcontrol-having-alias.log`). At 2565f073b in the disposable verify clone: matrix 30 PASS / 0 FAIL including live; gh402 34/0, gh405 19/0, gh549 125/0, gh605-board-policy OK, gh777 PASS; clone identity unchanged. SUMMARY and provenance updated.
- Evidence wording accepted: key-off identity is shown on the populated fixture plus source inspection, not proven for every possible DB.

Re-review the fix and updated evidence. Preserve Round 1. Append `### Round 2 · Reviewer · codex` with plain paragraphs, `swept file: yes/no` and an explicit verdict. Set STATUS: Approved only if approved, NEXT: orchestrator. Same rules as Round 1.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

### Round 2 · Reviewer · codex

swept file: yes

**Verdict:** Approved

F1 is resolved at `utils/py/board_sync.py:153-155`: the aggregate is now `SUM(runs) AS total_runs`, and both HAVING and ordering use that unambiguous alias. The updated plan matches. A2b checks a concrete nonempty ordered list including the zero-first mixed repo, two equal-total repos ordered by name, and exclusion of an all-zero repo. Its pre-fix replay fails precisely by dropping `o/mixed` (rc=1); the current matrix records 30 PASS / 0 FAIL (rc=0). This is a discriminating correction rather than a vacuous passing assertion.

Independent narrow probe: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 - <<'PY'` parsed `utils/py/board_sync.py` with `ast`, extracted the literal `agent_sql`, and executed it on a SQLite `:memory:` CTE containing `(o/mixed,0),(o/mixed,5),(o/tie-b,5),(o/tie-a,2),(o/tie-a,3),(o/zeros,0)`, all dated `date('now')`, with parameters `('-7 days',8)`. It asserted the exact nonempty result below, then replayed the same SQL with `total_runs` renamed back to `runs`. Exit status 0; decisive output:

```text
current: [('o/mixed', 5), ('o/tie-a', 5), ('o/tie-b', 5)]
pre-fix control: [('o/tie-a', 5), ('o/tie-b', 5)]
PASS: nonempty aggregate, zero exclusion, name tie; old query drops mixed
```

Re-read the reader/resolver, plan and prior plan approval, updated manual matrix, SUMMARY, matrix and alias-red logs, F2 mutation/restoration outcomes, smoke disclosures, provenance, existing-suite tails, CHANGELOG entry and GH-1421 ledger records. The strict default-off bool, same-connection conditional query, GitHub-first merge and existing resolver cap/dedupe remain intact. The inner SQLite-error catch preserves GitHub rows; ordinary read-only opening and the qualified no-sidecar warning remain unchanged. No additional writer, subsystem, registered suite or gate is introduced. The populated-fixture base comparison supports key-off identity within its measured scope; source inspection supports the broader control-flow claim. The existing rating 50/45/50/75 and accepted-start event remain consistent with the bounded advisory-reader change.

Recorded disposable-clone receipts at 2565f073b report gh402 34/0, gh405 19/0, gh549 125/0, gh605 OK and gh777 PASS. Those are supplied evidence, not suites rerun by this reviewer. The live reader still falls back on this Mac; the documented working immutable diagnostic mode remains outside production, as approved. Final committed-state harness qualification remains outstanding. No git, executable fixtures, pytest, test suites or validate.sh were run in this turn. Only this relay file was edited. No remaining blocking finding.

### Attestation · relay-drive — 2026-11-12T01:31:53Z
task: GH1421-FINAL-QA
reviewer: codex
status: Approved
reviewed-head: d93799e0fa0aeb96b94ab3f32893b11920e48753
added-range: 8447+2707
added-sha256: debb809849aac5768fd613268be095fc5620592e7330004e1438d17a16c51648
