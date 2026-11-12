# GH1430 independent final QA
STATUS: Approved
NEXT: orchestrator

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


### Round 1 · Reviewer · codex

**Verdict:** Approved

swept file: yes

Ship the bounded GH-1430 implementation. No blocking finding in the supplied implementation and evidence. This approval does not certify the outstanding live agent-only criterion, the routed push gate, or program #87 completion.

1. **Implementation:** `utils/py/board_sync.py:135-192` follows plan steps 1–3: `mode=rw`, `uri=True`, `timeout=2`, then `PRAGMA query_only=ON` as the first statement inside the existing protected inner try, with `conn.close()` in finally. The queries, opt-in merge ordering, missing-file guard and warn/fallback path remain consistent with the approved plan. The docstring and qualified CANTOPEN hint explain the new open mode. The trailing gateway annotation still identifies the external Rebalance DB; the immediately preceding comment supplies the new rationale. No parallel reader, application writer, dependency or gate was introduced in the supplied changed-file scope. Reversibility is Easy: reverting this reader change restores fallback. SQLite sidecar creation and possible last-close checkpointing are accepted physical effects, not a claim of byte immutability in all cases.
2. **Manual matrix:** I read the entire script and its persisted log/provenance. `manual_matrix.py` retrieves the requested base source with a checked `git show`, writes it to scratch, and imports that file separately from the candidate. Fixture creation inserts both a GitHub repo and an agent-only repo; the first check requires WAL mode with no sidecars. The old-reader assertion requires both an empty result and the CANTOPEN warning, while the candidate must return exactly `['o/gh', 'o/agent-only']`; empty input/output cannot manufacture success. The log records all 10 checks passing, including SHA-256 plus nanosecond-mtime equality, refused INSERT, missing-path fallback and direct rw no-create behavior. The write-refusal probe duplicates the selected connection sequence rather than intercepting the real connection; source inspection confirms that sequence. This is proportionate manual evidence under GH-831, not a new registered suite.
3. **Live smoke:** `smoke.sh` uses scratch configuration/output, config and policy-preview only. I traced preview through `build_policy_preview`, `fetch_board_items(cache=False)` and `collect_github_state`: the board operations are reads, and the preview artifact is the intentional scratch write. `smoke-live.log` records successful on/off previews and unchanged main-file size/mtime. SUMMARY and provenance explicitly say the live agent-only criterion is outstanding because all three agent repos also have GitHub activity; the equal on/off results are not presented as proof of that criterion. The initial no-sidecar read and detailed live overlap/window counts are author-reported summary observations rather than fully captured raw queries. No live DB was opened during this review.
4. **Rating and narrative:** Both the SQL dump's GH-1430 row (`releases.sql:990`) and an independent immutable read of `releases.db` report 60/55/50/95, matching the plan's priority/severity/appeal/effort rationale. The CHANGELOG accurately describes rw/query_only, missing-file refusal, rejected immutable mode and the disclosed checkpoint effect. Its word “always” is understood in the immediately stated no-sidecar condition; it does not establish failure while another writer holds sidecars open.
5. **Nonblocking evidence limits:** The plan requested live SHA-256 plus mtime, but the live receipt supplies size plus mtime only. Thus byte equality is demonstrated for the clean fixture, not for the live DB. The plan status/acceptance checkboxes remain at their preimplementation checkpoint; the verification summary is the current result record. Neither gap changes the bounded reader's correctness, but neither should be represented as completed verification. Full/routed gate execution remains **[Unverified — needs clone run]** in this review and is left to the harness as instructed.

Inspection receipt: source/evidence reads and `rg -n '1430' releases.sql` exited 0. A `/usr/bin/python3` read-only AST/ledger probe (with `PYTHONDONTWRITEBYTECODE=1`, `TMPDIR="$PWD/.relay-scratch/tmp"`) exited 0. Its decisive operations were `ast.parse(Path('utils/py/board_sync.py').read_text())`, inspection of the reader's inner try, and `sqlite3.connect(Path('releases.db').resolve().as_uri()+'?mode=ro&immutable=1', uri=True)` followed by `select gh_number,rating_pri,rating_sev,rating_appeal,rating_effort,doc_path from roadmap_items where gh_number=?` with `('1430',)`. Decisive output: `first protected statement: conn.execute('PRAGMA query_only=ON')`; `finally: conn.close()`; `persisted rating: [(1430, 60, 55, 50, 95, 'PROJECT/2-WORKING/GH-1430-BOARD-SYNC-WAL-READ.md')]`.

No git command, suite, pytest, validate.sh or executable fixture was run. I did not rerun the matrix because its implementation invokes git, forbidden in this turn; runtime outcomes above are assessed from the committed receipts and script, not claimed as independent reruns. No full base-to-head diff was obtained under that restriction; scope assessment uses the seeded changed-file list and affected contexts. Only this relay file was changed outside exempt scratch.

### Attestation · relay-drive — 2026-11-12T03:44:24Z
task: RELAY-gh1430-final-r1
reviewer: codex
status: Approved
reviewed-head: 3e84400c3957d0456467f33fef15d8b9f679f272
added-range: 3029+5290
added-sha256: d843a8fc0ac4341fc6dd09103565552e4c8e7bca5984db17f60be028564fadab
