# GH1428 final implementation QA
STATUS: Approved
NEXT: orchestrator

Final independent QA of the committed implementation for https://github.com/HiQS-Labs/XYZ-forge/issues/1428 against its Codex-approved plan (`relay-system/2026-11-11/gh1428-plan.codex.md`, R3 Approved, attested `67fa20b09`). Review `git diff 0f21b761a..HEAD` (read it with `git diff`/`git show` read-only, or read the files). Plan: `PROJECT/2-WORKING/GH-1428-REVIEWER-UNVERIFIED-APPROVAL.md`. Evidence: `TESTS-RESULTS/2026-11-11+GH-1428/SUMMARY.md` (+ receipts, provenance.jsonl).

Changed code: `utils/py/marathon_drive.py` (`reviewer_runnable_gate`, render-time `reviewer_gate_cmd`, builder `unverified:` sentence, reviewer step 3a, `env2` signal set/pop), `utils/py/relay_attest.py` (`declared_gate_run`, `builder_declared_unverified`, optional `gate-run:` trailer line, `_load` validation), `utils/py/relay_drive.py` (`judge_terminal` refusal `unverified-approval`, `record["gate_run"]`), `relay-automation/relay-turn-lib.sh:1067` (exception clause), docs (`relay-automation/README.md`, `skills/1-hourly/relay-xyz/SKILL.md`, CHANGELOG), regenerated `relay-pkg.tar.gz`, ledger pickup + accepted-start.

Operational envelope: local single-operator CLI harness; grade against the issue acceptance and the approved plan; commensurate complexity; GH-831 — a new test suite/registry entry/gate machinery would be a finding (TESTS-RESULTS manual-check scripts are receipts, not suites — say if you disagree). Parallel #1427 also edits marathon_drive.py; minimal footprint there is intentional.

Questions:
1. Does each issue acceptance item hold, per the acceptance map, and do the code paths match the approved plan steps 1–7 (no duplicate subsystem/writer)?
2. `reviewer_runnable_gate`: does it implement the R2-approved file/node-selector contract exactly (compound, `--` passthrough, GH-54 marker, directories, missing paths, runner-name denylist)? Any shape that wrongly qualifies or wrongly disqualifies the GH-955 gate?
3. `judge_terminal`: is the refusal placed correctly (after empty-approval, before token), does `post_canon[:added_start]` give the pre-turn text in both the canonical and separator-tolerant paths, and is behaviour unchanged when the env is absent? Note: `record["gate_run"]` is now always present, so every new attestation trailer gains a `gate-run:` line — any consumer this breaks?
4. `declared_gate_run`/`builder_declared_unverified`: regex correctness (last declaration wins, exit 0 only, latest Builder block only, `####` sub-headings inside a builder block).
5. Is the relay-turn-lib.sh clause correct inside its single-quoted bash string, and do the gh681 pinned needles still match?
6. Do the receipts substantiate the claims (red control witnessed on base, render variants, codex network red/green), and is the persisted rating 65/55/50/60 still consistent with the evidence?

Rules: final QA only. Read whole affected contexts. Do NOT run validate.sh, test/*.sh, pytest or executable fixtures in this clone; read-only probes under `$TMPDIR` only. Behaviour-change [Blocker]/[Should] need `Observed input:`, `Affected scope:`, `Falsifier:` and file:line. Append `### Round 1 · Reviewer · codex` with plain paragraphs directly under the heading (no nested `####` headings), a literal `swept file: yes|no` line, and `**Verdict:** Approved` or `**Verdict:** Changes requested`. Set `STATUS: Approved` only if approved; set `NEXT: orchestrator`. Edit ONLY this file; do not run git commands that write.


### Round 1 · Reviewer · codex

Block pending the selector-path correction below. The implementation otherwise follows the approved extension points: render-time eligibility and child-environment set/pop in marathon_drive, declaration parsing and optional trailer binding in relay_attest, and the existing terminal-refusal seam in relay_drive. No parallel runner or new registered suite was introduced. The manual scripts are bounded receipts rather than new gate machinery.

[Should] Enforce selector containment and preserve worktree-relative test selection at utils/py/marathon_drive.py:583-587.
Observed input: an explicit command `pytest ../test_other_revision.py`, with that regular file in the target directory's parent, is returned unchanged by reviewer_runnable_gate. An absolute path to that external file also qualifies. os.path.join(target_root, path) does not enforce containment: parent traversal escapes it and an absolute path replaces it entirely. This contradicts approved step 1's requirement that selectors be under the target root. Absolute selectors even inside the original target checkout also remain anchored there when the rendered instruction runs from a review worktree, undermining the reviewed-revision promise at lines 3142-3145.
Affected scope: focused explicit gates using parent-relative or absolute selectors, including ordinary commands copied from another checkout. The generated reviewer exception can authorize execution against files outside the reviewed worktree and produce evidence for another revision. This is a path/revision correctness issue, not a demand for a general shell security scanner.
Falsifier: a narrow inert-file probe must reject selectors escaping the root (including symlink escapes) and either reject absolute selectors or render a contained worktree-relative equivalent. Retain the existing relative-file/node positive control and directory/missing-path negatives. Resolve containment against the real target root before qualifying the command; do not solve this by falling back to another checkout's source.

Probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 -B - <<'PY' … PY`. The Python body parsed marathon_drive.py with ast, extracted only reviewer_runnable_gate, supplied its re/os/shlex globals and unchanged _FULL_SUITE_RE, then created an inert target/test_one.py and sibling test_other_revision.py in tempfile.TemporaryDirectory(dir=os.environ['TMPDIR']). It called reviewer_runnable_gate(cmd, True, str(root), '') for each input; no tests, fixtures, imports of application modules, or subprocesses were executed. Exit status 0. Decisive output: `'pytest test_one.py' -> 'pytest test_one.py'`; `'pytest ../test_other_revision.py' -> 'pytest ../test_other_revision.py'`; the absolute sibling selector was likewise returned unchanged; `'pytest test_one.py -- --collect-only' -> ''`. All created files stayed under sanctioned scratch.

[Unverified — no citation] The terminal refusal is after empty-approval and before token validation. Both accepted prefix paths use an added_start in post_canon, so post_canon[:added_start] contains the preserved pre-turn history rather than the new reviewer block. The builder regex stops at another level-three heading, retains level-four subheadings, and selects the last Builder block. The declaration parser selects the last matching declaration and distinguishes yes/failed/no/undeclared for the documented inputs. The absent environment signal bypasses the new refusal; marathon_drive explicitly removes an inherited signal for harness-only gates. The new field is always emitted for new records, is optional for legacy loads, and is bound by trailer recomputation. I found no incompatible consumer in the inspected attestation path.

[Pass with evidence limits] The committed SUMMARY, provenance, red-control.out and load-check.out support the stated base-attests/fix-refuses control, failed/missing-exit cases, exit-zero positive, unarmed compatibility, and legacy/tamper loading claims. render.out supports the seven listed render variants and instruction-only tooling fallback. The network receipts support the documented per-turn opt-in; they do not establish a live DB-backed reviewer run, which SUMMARY correctly excludes. The Bash role note uses “the REVIEWER steps in your relay file” and introduces no apostrophe into its single-quoted string; existing gh681 wording is preserved. Package regeneration has an existing freshness-suite receipt. The 65/55/50/60 rating remains reasonable for the reported incident and limited field evidence.

[Note] The active task document's near-top Status table still says plan QA R3 is next, despite completed implementation and final QA. Update that existing table during closeout. Final full-gate verification remains [Unverified — needs clone run]; it was neither run nor claimed by this reviewer and is explicitly deferred to the harness after this turn.

swept file: no

Read the complete final relay, approved plan and review history, affected implementation contexts, documentation changes and committed evidence summaries/receipts. This was a scoped review of the affected paths, not a claim to have swept every line of the large pre-existing driver modules. No git command, validate.sh, test/*.sh, pytest, executable fixture or network server was run. Only this relay file was edited outside sanctioned scratch.

**Verdict:** Changes requested

Handing off to orchestrator — orchestrator, take your turn.

### Round 2 · Builder · orchestrator

Dispositions for Round 1:
- [Should] selector containment — **Implemented** (`utils/py/marathon_drive.py` `reviewer_runnable_gate`): a selector must be relative, and its realpath must be a regular file inside `realpath(target_root)` (`os.path.commonpath`). Absolute selectors are rejected even inside the target, so the rendered command stays worktree-relative. Receipt `TESTS-RESULTS/2026-11-11+GH-1428/containment.out`: relative file and `::node` qualify; `../other.py`, an absolute outside path, an absolute inside path, a symlink escaping the target, a directory and a missing file are harness-only. Your R1 probe is the pre-fix red. Focused suites and render smoke are re-run on the new head (receipts refreshed).
- [Note] Status table — **Implemented**.

Re-review the delta (`git diff <R1 reviewed head>..HEAD`) and confirm. Same rules. Append `### Round 2 · Reviewer · codex` with plain paragraphs (no nested headings), a `swept file:` line and an explicit `**Verdict:**`; STATUS: Approved only if approved; NEXT: orchestrator.

### Round 2 · Reviewer · codex

Ship within final-QA scope. The Round 1 selector-containment finding is resolved: `reviewer_runnable_gate` now rejects absolute selectors, resolves relative selectors against the real target root, requires a regular file, and checks containment with `os.path.commonpath`. This preserves the worktree-relative GH-955 command while rejecting parent and symlink escapes. The existing Status table now reflects implementation and final QA. No further required finding in this correction.

[Pass — independently measured] Command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 -B - <<'PY' … PY`. The Python body parsed `utils/py/marathon_drive.py` with `ast`, extracted only `_FULL_SUITE_RE` and `reviewer_runnable_gate`, supplied `os/re/shlex`, and evaluated inert files created with `tempfile.TemporaryDirectory(dir=os.environ['TMPDIR'])`. It asserted expected results for twelve commands and a GH-54 negative; no application import, subprocess, fixture or test execution occurred. Exit status 0. Decisive output: `pytest tests/x.py => qualifies`; `pytest tests/x.py::test_a => qualifies`; `.venv/bin/pytest -q tests/x.py => qualifies`; parent traversal, absolute outside, absolute inside, escaping symlink, directory, missing file, passthrough, compound and unscoped pytest all returned `harness-only`; `PASS: 12 selector cases plus GH-54 negative`. Together with the R1 pre-fix red, this witnesses that the correction addresses the reported failure.

[Evidence limits] Inspected the refreshed provenance entry for `c64d83d02`, focused suite logs and render receipt. These report five existing suites green and seven unchanged render variants; they are builder-provided clone evidence, not suites independently executed in this reviewer turn. A first attempt to read `focused.out` exited 1 because receipts use `focused-*.log`; the actual logs were then read. Full final-commit gate remains [Unverified — needs clone run] and must run in the harness disposable full clone after this turn. This approval concerns the scoped code correction and does not claim that deferred gate passed or that a live DB-backed reviewer run was measured.

swept file: no

Reviewed the complete predicate and its surrounding context, the R1 finding and R2 disposition, the updated plan/status and relevant receipts. This is a delta re-review carrying forward the prior review, not a new sweep of the entire driver. No git commands or prohibited suites were run. Only this relay file was changed outside sanctioned scratch.

**Verdict:** Approved

Handing off to orchestrator — orchestrator, take your turn.
