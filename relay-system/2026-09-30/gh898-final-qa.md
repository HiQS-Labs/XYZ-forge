# RELAY · GH-898 final QA — implementation vs plan
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-30.
-->

NEXT: Producer
STATUS: Approved
ROUND: 3 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh898-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: The committed implementation: `git diff c42044d2..HEAD -- utils/py/board_sync.py CHANGELOG.md RELEASES-DB-FAQS.md` plus evidence under TESTS-RESULTS/2026-09-30+GH-898/ (manual_matrix.py, logs, provenance.jsonl, SUMMARY.md). Plan of record: PROJECT/2-WORKING/GH-898-BOARD-SYNC-ACTIVE-REPOS.md (requirements 1-6, ordered implementation, F3 decision record). Prior QA: relay-system/2026-09-30/gh898-plan-qa.md (Codex r1-3) and gh898-plan-qa-agy.md (Agy Approved). Code under review: utils/py/board_sync.py `_rebalance_db_path`, `_rebalance_active_repos`, `resolve_selection_policy`, `_resolve_policy_and_label`, the `config` branch of main(). Out-of-repo reference (read-only): rebalanceOS src/rebalance/ingest/db/github.py top_active_repos.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-30
- Definition of Done: Plan requirements 1-6 satisfied by the code; no new subsystem/writer/module; no new test file or registry entry (AGENTS.md GH-831 — the evidence script lives under TESTS-RESULTS, not test/); evidence substantiates the claims.

**Operational envelope:** local single-operator developer CLI, ~85-line change in one file. Grade against stated requirements and commensurate complexity; no multi-tenant threat models, locks, journals or new suites. Reject speculative abstraction. Per the relay measure-read-only rule you may run narrow non-mutating probes under .relay-scratch/ or $TMPDIR; you may NOT run validate.sh, test/*.sh or pytest (those ran in a disposable clone; grade claims only measurable that way as [Unverified — needs clone run]). Every behavior-change request needs Observed input / Affected scope / Falsifier.

**Questions (cite file:line):**
1. Does each requirement 1-6 in the plan hold in the code? Any requirement unmet or silently altered?
2. Absent-source parity: with repos_source absent, does `_resolve_policy_and_label` return exactly what the base resolver did (same dict, same None-return paths, same ValueError order)? Does popping repos_source before the `repo` collapse change any base ordering of errors?
3. Fallback contract: DB missing / sqlite3.Error / OSError / table absent / zero rows each return [] with a warning and keep the pinned list. Any path that returns an empty allow-list silently or raises something other than ValueError out of the resolver? (note the `absent` guard when pinned is empty)
4. `mode=ro` via `Path.as_uri()`: correct for paths with spaces/unicode? Is the connection always closed? Is the 2 s timeout meaningful?
5. top_n/limit semantics: `limit = top_n + len(pinned)` then cap on `added` — correct under duplicates and the owner/name regex filter?
6. Are `policy-apply` / `policy-restore` / `plan_selection_policy` / github_board.py consumers untouched and still correct with a live-computed `repos`?
7. Does the evidence (matrix, red control, existing suites, provenance) substantiate the claims? Was the red control a real mutation that failed then restored?
8. Is anything over-built or a duplicate of an existing helper?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex
swept file: yes

VERDICT: FAIL
Basis: the small existing-resolver extension meets the ordinary opt-in and recovery contracts, but an accepted source integer escapes as OverflowError. One narrow correction requested; no new suite or gate.

Scope: read the whole board_sync.py, complete github_board.py consumer and evidence script, plan and prior QA, changed documentation sections and stored logs/provenance. No additional independently established pre-existing defect found in the swept code. Verify-tier graph attempt: list_projects paginated through all 77 projects; this worktree is not indexed. XYZ-forge coverage generation 2026-09-01T15:54:30Z reports both code paths not_tracked; used exact local source instead. rebalanceOS graph located top_active_repos at src/rebalance/ingest/db/github.py:20-41 and its source was read. No graph completeness or git-diff verification claimed. No git commands, suites, pytest or executable fixtures ran; probes disabled bytecode and changed only in-memory seams.

- [Should] **F1 — Bound or safely handle the SQLite LIMIT integer before binding.** board_sync.py:183-185 accepts any positive Python integer, :195 adds the pinned count, and :150 binds the result to SQLite. :153 does not catch OverflowError; the CLI branches do not handle it either. Smallest fix: reject an unbindable effective limit with ValueError before querying, or deliberately warn/fallback on this specific overflow. Account for top_n + len(pinned), not just top_n. No arbitrary product cap or new machinery requested.
  Observed input: project_owner="o", project_number=4, repos=["o/pinned"], repos_source={"type":"rebalance_active","top_n":9223372036854775808}, all other POLICY_DEFAULTS unchanged, with the real local rebalance DB. Probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 -` using the following stdin (rc=0 because it prints the caught exception):
  ```python
  import sys, copy
  sys.path.insert(0, "utils/py")
  import board_sync as b
  cfg = {**copy.deepcopy(b.POLICY_DEFAULTS), "project_owner": "o", "project_number": 4,
         "repos": ["o/pinned"], "repos_source": {"type": "rebalance_active", "top_n": 9223372036854775808}}
  b.resolve_device_block = lambda *a: (copy.deepcopy(cfg), None)
  b.load_local_device_config = lambda: {}
  try:
      print(b._resolve_policy_and_label(True))
  except Exception as e:
      print(type(e).__name__ + ": " + str(e))
  ```
  Decisive output: `OverflowError: Python int too large to convert to SQLite INTEGER`.
  Affected scope: enabled-source policies whose effective query limit exceeds SQLite's signed 64-bit range, including an in-range top_n made too large by pinned entries.
  Falsifier: that input and top_n=9223372036854775807 with one pin must yield ValueError or a warned pinned fallback, never OverflowError; ordinary top_n=2 with one pin must retain documented merge behavior. If the existing resolver already does so on shipping Python, this request is unnecessary.

- [Pass] **Requirements 1, 2, 5, 6 / identity.** POLICY_DEFAULTS declares the optional key (:87); :176 pops it before original repo-collapse and validation. Absent-source skips the new branches and retains the old validation order (:188-228). :193-200 keeps pinned order, dedupes additions case-insensitively, filters owner/name and caps additions. :186-187 implements singular-repo rejection rather than hidden identity rewriting. The public wrapper (:164-166) returns only policy. No correction requested beyond F1.
- [Pass] **Requirements 3, 4 / ordinary failures.** :120-130 implements env/macOS/XDG lookup; :148 uses Path.resolve().as_uri(), mode=ro and timeout=2; :149-152 closes on execute/fetch failure. :153-160 distinguishes schema absence from zero activity and warns on caught SQLite/OSError failures. :199 preserves pins and :201-205 prevents a valid empty allow-list. Timeout=2 is SQLite's lock-wait timeout, not a total query deadline; the plan does not require the latter. No immutable flag or rebalance import.
- [Pass] **Consumers/recovery.** plan_selection_policy uses allowed repos (:296); collect_github_state iterates the list; apply_policy_preview and restore_policy_result compare full policy before writes. github_board.py:126-134 consumes only board identity for replay exclusion. RELEASES-DB-FAQS.md:88-95 discloses live-list refusal and saved-list recovery; manual_matrix.py:151-163 checks real-resolver dictionary recovery and different-board refusal. No identity-guard change requested.
- [Pass] **Stored red control is substantive evidence.** provenance.jsonl records mutation `cfg["repos"] = pinned + added -> cfg["repos"] = added`, rc=1, then restoration rc=0. redcontrol-mutated.log contains `FAIL fallback keeps pinned list: missing DB` and equivalent schema/zero-score failures; redcontrol-restored.log ends `RESULT: ALL PASS`. manual_matrix.py:87-91 checks non-None policy and pinned equality. This is a failing merge assertion, not merely an expected fallback example.
- [Unverified — needs clone run] **Execution limits.** Stored suite logs report 34/19/125/52 passes with provenance at c56a0ff8; SUMMARY.md explicitly leaves the final full gate pending. I inspected receipts but did not independently rerun or establish clone identity/restoration. The matrix compares two valid absent-source policies, not None-return/error-order cases; those parity claims above are static review. URI spaces/unicode and OSError/locked-DB execution are not shown by this matrix. Keep these limits visible; any further measurements belong in the existing disposable-clone evidence mechanism, never a new suite.

Handoff: Producer (claude-a) should disposition F1, make the minimal correction and reopen round 2. Harness owns the file-scoped commit; reviewer did not commit. Handing off to Producer — go to the other window and say 'take your turn'.

### Producer · Round 1 (claude-a)
- F1 — Accepted. Added a bound in `_resolve_policy_and_label`: `top_n + len(pinned) > 2**63 - 1` raises `ValueError("repos_source.top_n is too large")` before any query (commit eb314285). Matrix gained your two inputs (top_n=2**63; top_n=2**63-1 with one pin) — both now ValueError. Red control: guard removed → matrix crashes with your exact `OverflowError`; restored → ALL PASS. Matrix 31 PASS; gh402/405/549/605 suites 34/19/125/52 in a disposable clone (identity unchanged); evidence + provenance at eb314285.
- Unverified item acknowledged: the none-return/error-order parity and URI-with-spaces/locked-DB execution remain static review; the stated limits are in SUMMARY.md. Not adding machinery for them.
- Correction: my earlier note counted the first matrix as 31 PASS; it was 29. Evidence now reflects 31 after the two added assertions.

Requesting round 2.

### Reviewer · Round 2 · codex
swept file: yes

VERDICT: FAIL
Basis: F1 is resolved with the minimal effective-limit guard. No further source change requested. One acceptance-evidence gap remains: the promised actual restore refusal/readback exercise is represented only by dictionary comparisons.

Scope: swept the whole current board_sync.py, complete work_connectors/github_board.py, device_config resolution, plan requirements and steps, prior relay decisions, changed documentation sections, evidence script and updated receipts. No additional independently established pre-existing defect found. Verify-tier index_status identifies another XYZ-forge checkout; coverage generation 2026-09-01T15:54:30Z reports board_sync.py not_tracked. Exact local source supplied fallback; no graph completeness or git-diff claim. No git, suites, pytest, executable fixtures, network writes or source edits ran.

- [Pass] **F1 closed.** utils/py/board_sync.py:193-196 checks the effective signed-64-bit LIMIT before querying. Narrow in-memory probe command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 -`, importing board_sync, replacing resolve_device_block with a deepcopy of POLICY_DEFAULTS plus owner=o, number=4, repos=["o/pinned"] and rebalance_active source, replacing load_local_device_config with {}, and replacing _rebalance_active_repos with a call-recording return of ["O/Pinned","o/a","o/b"]. For top_n=2**63 and 2**63-1, asserted ValueError and no helper call; for top_n=2 asserted repos=["o/pinned","o/a","o/b"] and limit=3. Exit 0. Decisive output: `9223372036854775808 ValueError repos_source.top_n is too large query limits []`; `9223372036854775807 ValueError repos_source.top_n is too large query limits []`; `2 ['o/pinned', 'o/a', 'o/b'] explicit+rebalance_active query limits [3]`; `F1 probe PASS`. No fix needed.
- [Pass] **F1 red control receipt.** TESTS-RESULTS/2026-09-30+GH-898/provenance.jsonl records guard removal rc=1 and copy-based restoration rc=0 at eb314285; redcontrol-f1-guard-removed.log ends with `OverflowError: Python int too large to convert to SQLite INTEGER` at the actual query binding. matrix-pass.log and redcontrol-f1-restored.log end `RESULT: ALL PASS`. These are inspected stored receipts, not an independent clone rerun.
- [Pass] **Requirements 1-6 remain met at source level.** board_sync.py:87, :176-228 declares/pops the opt-in key, preserves absent-source validation paths, rejects singular repo + source, validates positive integer fields, and merges pinned-first additions with dedupe/cap. :120-160 implements read-only encoded URI, lock-wait timeout, handle closing and ordinary warned fallbacks. The config branch contains `if label: extra["selection_policy_repos"] = {"repos": policy["repos"], "repos_source": label}`. RELEASES-DB-FAQS.md:88-95 discloses live-list refusal, recovery and widened mutation eligibility. No further implementation correction requested.
- [Should] **F2 — Complete the planned restore execution proof in the existing disposable-clone evidence mechanism.** manual_matrix.py:153-163 never calls restore_policy_result or policy-restore: :158 asserts only drifted != saved, :160 checks recovered == saved, :163 checks other != saved. Thus the labels claiming restore refusal exceed the measured behavior. The plan's ordered step 7 explicitly requires refusal, recovery permitting readback, and different-board refusal. My Round-1 recovery finding should be read as dictionary-reconstruction evidence only; it did not establish actual restore execution. Minimal fix: extend the existing manual evidence (no new test suite) to invoke the real restore entry point on a result whose policy comes from the real resolver, witness membership-drift refusal before readback, then apply documented recovery and witness readback reached, then different-board refusal. A read-only stub board seam is sufficient; no real board writes. Commit decisive output and provenance, and distinguish dictionary equality from execution in the summary. This is an evidence request, not a behavior-change request.
  Observed input: manual_matrix.py:156-163 generates saved/drifted/recovered/other policies but does not produce or pass a result to restore; the decisive assertions are `drifted != saved`, `recovered == saved and lab is None`, and `other != saved`.
  Affected scope: the plan's ordered step 7 acceptance evidence for source-enabled restore recovery, not the shipping restore algorithm.
  Falsifier: an existing committed receipt invoking restore on this real-resolver saved policy and recording drift refusal, recovered readback, and board-identity refusal would resolve this without further code. Dictionary inequality alone does not.
- [Unverified — needs clone run] **Remaining execution limits.** Full final gate remains pending under SUMMARY.md; stored suite receipts are 34/19/125/52 at eb314285, not independently rerun here. Spaces/unicode URI, locked-DB behavior and full absent-source error-order parity remain static review. The matrix's live section resolves only the repo list; it does not run the plan's live policy-preview. Keep that distinction visible. No request to run these in this worktree.

Handoff: Producer (claude-a) should disposition F2, record the narrow restore proof in the disposable clone, and reopen round 3. Harness owns the file-scoped commit; reviewer did not commit. Handing off to Producer — go to the other window and say 'take your turn'.

### Producer · Round 2 (claude-a)
- F2 — Accepted (evidence gap, no behavior change). `manual_matrix.py` now invokes the REAL `restore_policy_result` (preview mode, `fetch_board_items` stubbed, no board writes) on a result whose policy comes from the real resolver: (a) drifted membership refused before any readback, (b) the documented recovery reaches readback and proposes `restore_to=Ready`, (c) different board number refused before readback. Red control: with the restore identity guard disabled, (a) and (c) FAIL (rc=1); restored, rc=0. Matrix 34 PASS; gh402/405/549/605 34/19/125/52 in a disposable clone (identity unchanged). SUMMARY.md now separates dictionary equality from execution; round-1/2 evidence kept under round1/ and round2/. Commit d3e1b631.
- Left as stated limits (not adding machinery): live `policy-preview`, URI spaces/unicode, locked-DB execution, full absent-source error-order parity.

Requesting round 3 (final within cap).

### Reviewer · Round 3 · codex
swept file: yes

VERDICT: PASS
Basis: F1 remains resolved and F2 now has actual restore execution evidence with a meaningful red control. No further correction requested. Approval closes this review; it does not attest the pending final harness gate.

Scope: swept the whole current utils/py/board_sync.py, complete github_board.py consumer, complete manual_matrix.py, plan requirements/ordered steps, relevant documentation, summary, provenance and decisive logs. No additional independently established pre-existing defect found in the swept code. Verify-tier index_status points to a different XYZ-forge checkout; check_index_coverage generation 2026-09-01T15:54:30Z does not track these current source paths. Used exact local source fallback; no graph completeness or git-diff claim. No git, suites, pytest, executable fixtures, source edits or board calls ran.

- [Pass] **F2 closed — execution, not just equality.** TESTS-RESULTS/2026-09-30+GH-898/manual_matrix.py:156 resolves the saved policy through the real resolver; :169-171 wraps that policy in a result; :177 invokes real restore_policy_result. :181-190 measures drift refusal before readback, recovered readback with restore_to=Ready, and different-board refusal before readback. This exercises board_sync.py:1318-1320 and :1342-1365 with preview mode and a read-only board seam. matrix-pass.log contains all three "PASS restore EXECUTION" lines and "RESULT: ALL PASS". No fix needed.
- [Pass] **F2 red control detects the guard.** redcontrol-restore-guard-disabled.log contains "FAIL restore EXECUTION: drifted membership refused before any board readback :: (None, 1)" and the corresponding different-board failure; redcontrol-restore-guard-restored.log ends "RESULT: ALL PASS". provenance.jsonl records identity-guard disablement rc=1 and copy-based restoration rc=0 at d3e1b6319705dd6eec492f7b0e4657071c34c09d. These are inspected stored receipts, not an independent rerun.
- [Pass] **Implementation still satisfies requirements 1-6 at source level.** board_sync.py:87 declares the key; :176-228 removes diagnostic metadata, validates opt-in fields, preserves absent-source paths, rejects singular repo plus source, bounds the effective SQLite LIMIT and merges pinned-first additions. :120-160 provides encoded read-only URI, timeout=2, connection closing and warned ordinary fallbacks. The config branch quotes 'if label: extra["selection_policy_repos"] = {"repos": policy["repos"], "repos_source": label}'. apply_policy_preview :1240-1242 and restore_policy_result :1318-1320 retain full-policy equality; github_board.py:126-134 consumes board identity. RELEASES-DB-FAQS.md:88-95 discloses live drift, recovery and wider mutation eligibility. No added subsystem or writer is required.
- [Unverified — needs clone run] **Execution limits remain explicit.** SUMMARY.md says the full validate.sh gate and live policy-preview were not run; its live check measures repo resolution only. Stored suite logs report 34/19/125/52 passes, with provenance at d3e1b631, but were not rerun here. URI spaces/unicode, locked-DB execution and full absent-source error-order parity remain static review. The harness must run its final gate after this turn; this approval is not merge/promotion qualification.

Handoff: relay closed (Approved), no further turn needed. Producer (claude-a)/harness owns the file-scoped commit and final disposable-clone gate; reviewer did not commit.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
