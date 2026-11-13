# RELAY · GH-1453 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-13.
-->

NEXT: Reviewer
STATUS: Open
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1453-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the committed implementation on this branch against base `6c0c76bb5`: `utils/py/jog_run.py` (`JogCheckpoint` and its two call sites in `jog_run_main`; `git diff 6c0c76bb5 -- utils/py/jog_run.py`), `skills/2-daily/jog/SKILL.md` (the new "Checkpoint publication" section), `CHANGELOG.md` (the GH-1453 entry), and the evidence in `TESTS-RESULTS/2026-11-13+GH-1453/`. This is the **final review** of completed work.
- Reviewer: codex   ·   Producer: claude
- Started: 2026-11-13
- Plan of record: `PROJECT/2-WORKING/GH-1453-JOG-LOCAL-RECONCILE.md` (approved in `relay-system/2026-11-13/gh1453-plan-qa.md`, round 3), including its `## Implementation notes`, which disclose one addition beyond the approved plan.
- Operational envelope: a local developer CLI (`releases_app.py jog run --checkpoint-root`), one operator per primary clone, other sessions pushing to the same `development`. Grade against the issue's acceptance and commensurate complexity, not enterprise or multi-tenant threat models. The repo forbids new tests, suites, registry entries or gate machinery (AGENTS.md *No new tests*, GH-831); a new test file in the diff is a finding. Verification is existing suites plus manual checks recorded under `TESTS-RESULTS/`. `fixture-checks.py.txt` there is a recorded manual-check driver, not a suite or registry entry.
- Definition of Done: each acceptance item A1–A12 is met by the code and supported by retained evidence; the code matches the approved plan or discloses where it does not; no duplicate subsystem or second ledger writer was introduced.

### Step A: paraphrase first (GH-1414). Do this BEFORE reading anything else.
Read ONLY the plan doc (`## Plan`, `## Acceptance`, `## Risks`, `## Implementation notes`) and `TESTS-RESULTS/2026-11-13+GH-1453/SUMMARY.md`. Then, at the top of your review block, write:
- **What this delivers** (2–5 sentences)
- **How the existing system works, per these documents** (2–5 sentences)
- **What it's not** (short; ground exclusions in the documents and label any inference)
- **Input boundary:** list what you had read when you wrote the paraphrase.

### Step B: source-backed validation
Now read the diff and source: `git diff 6c0c76bb5 -- utils/py/jog_run.py skills/2-daily/jog/SKILL.md CHANGELOG.md`; `utils/py/jog_run.py` `JogCheckpoint` in full; `utils/py/releases_app.py` (`perform_write` 1662-1790, `jog_acquire_lease` / `jog_set_status` 5072-5135, `_rebuild` 6540-6665); `utils/releases-merge-resolve.sh`; the logs `candidate-A1-A12.log`, `base-red-controls.log`, `a6-skill-text.log`, `gh280-jog-marathon-adapter.log`, `jog-queue.log` and the driver `fixture-checks.py.txt`. Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1453.

Label the assessment **source-backed**. Answer each with `file:line` evidence:

1. For each acceptance item A1–A12: is it satisfied by the code, and does the retained log actually observe it? Quote the decisive log line. Mark any item whose log shows only "nothing crashed".
2. What prevents an unchanged, unfixed tree from being reported as delivered, and where is the observed rejection? Check `base-red-controls.log` against the driver: does each red control fail for the stated reason, or for an incidental one?
3. Does `JogCheckpoint` match the approved plan steps 1–7? List every divergence. Is the disclosed addition (abort of this wake's own interrupted merge at the start of `finish()`) safe, and can it ever abort a merge that is not this wake's?
4. Read `finish()`'s publication loop and `_reconcile` / `_replay` / `_abort_merge` for defects: a path that leaves the primary dirty or mid-merge, a path that publishes without replay, a path that replays twice, an exception type that escapes the restore, or a state where the journal and `HEAD` disagree after a stop.
5. Is the unmoved path (`development` did not move) behaviourally unchanged apart from the extra fetch before the push? Name anything else that changed for existing callers.
6. Did a duplicate subsystem, a second ledger writer, or a hand-edit of `releases.sql` slip in? `_replay` writes the remote's dump bytes to the working file before `check --rebuild`: is that within the repo's "never hand-edit the dump" rule, given it is the remote's canonical dump taken whole?
7. Skill text: does the new section say anything the code does not do, or omit a stop the code can print? Is each listed message found in the code?
8. Is the persisted rating (`rated 75/70/50/40`) still consistent with the evidence?
9. Is anything over-built for this problem? Do not ask for new suites.

Write graded findings, then a VERDICT. Set STATUS to Approved only if no `[Blocker]` or `[Should]` remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

**What this delivers:** A checkpoint wake starts from local state and publishes once at the end. If development moved, it replays this wake's supported queue writes through the canonical writer onto the remote ledger, or preserves a retryable checkpoint with a named stop.

**How the existing system works, per these documents:** Queue leases and statuses already write the primary ledger locally through canonical writers and receipts. The checkpoint commits these files and publishes through a separate clone; the old implementation fetched at startup and failed publication when development moved.

**What it's not:** This does not publish every transition, replace the ledger writer, alter merge-cleanup, or prove a full multi-task builder run. The documents explicitly exclude those claims.

**Input boundary:** Relay instructions, the plan document (including Plan, Acceptance, Risks and Implementation notes), and TESTS-RESULTS/2026-11-13+GH-1453/SUMMARY.md only. Paraphrase recorded before source review.

**Assessment: source-backed.**
swept file: yes

Scope: read the full Jog supervisor, full Jog skill, GH-1453 changelog entry, canonical writer/rebuild and merge resolver, manual-check driver and retained results; findings include pre-existing text below. Graph Verify lookup: no indexed project matches this worktree; nearest XYZ-forge generation 2026-09-01T15:54:30Z is stale, JogCheckpoint lookup returns zero, and coverage reports changed/missing metadata (CHANGELOG excluded). Used current source fallback throughout. No git commands, suites, executable fixtures, or phase gate were run in this turn. The requested base diff could not be obtained using git under the explicit no-git instruction; comparison to base is limited to retained red controls and the plan's base recon. Full gate remains a subsequent harness responsibility.

**Graded findings**

- **[Should] F1 — the added crash recovery cannot identify “this wake's own merge”.** At `utils/py/jog_run.py:2212`, any truthy journal `source` plus any MERGE_HEAD calls `_abort_merge()` before `check_owned()` or the HEAD guard. That method stages five paths, aborts the merge and deletes the backup (`:2291`). A retained committed journal after a rejected push is enough; an operator can then begin a separate repair merge and rerun the documented command. Its merge will be aborted, including staged resolution work, even if HEAD has moved outside the wake. The source marker identifies the replay commit, not ownership of an open merge. This contradicts the claimed safety of the disclosed addition.
  Observed input: branch probe using the actual AST-extracted JogCheckpoint class, `state={'base':'base','commit':'checkpoint','phase':'committed','source':'checkpoint'}`, `_merging()=True`; all git/path effects intercepted, with execution stopped at `check_owned`. There is no HEAD/merge-target read before the abort. Control with source absent reaches only the ownership check.
  Affected scope: publication retries with a source-bearing journal and an open merge, including a repair merge begun after a publication stop.
  Falsifier: an open merge belonging to a different target or different HEAD must be preserved and refused; a demonstrated interrupted reconcile belonging to the recorded wake may be restored and retried.
  Probe command: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 "$TMPDIR/review-probe.py"`, exit **0**. Decisive output: `source=False; MERGE_HEAD=foreign; trace=['check_owned']`; with source True: `['git add -A -- releases.db', 'git add -A -- releases.sql', 'git add -A -- RELEASES-PREVIEW.html', 'git add -A -- LEADERBOARD.html', 'git add -A -- LEADERBOARD.md', 'git merge --abort', 'unlink releases.db.bak', 'check_owned']`. Probe extracted the class with `ast.parse`, bypassed its constructor, intercepted `_git`/`_try`/Path, and raised a sentinel at the ownership check; no real git ran.
  Fix: remove automatic abort for ambiguous retained state, or record the intended reconcile identity before opening it and validate that identity plus the primary HEAD before any staging/abort. Do not infer ownership from source alone. **[Unverified — needs clone run]** Actual foreign-merge preservation and interrupted-own-merge recovery require retained manual evidence in a disposable full clone; this probe establishes the unsafe dispatch, not a filesystem-level data-loss rehearsal.
  Root cause: a replay-source field is reused as merge ownership; Fix site: finish's recovery admission before _abort_merge; Why not upstream/downstream: only this admission decides whether the retained merge is safe to mutate.

- **[Should] F2 — the “every legal stop” list omits a deliberate stop.** `utils/py/jog_run.py:2329` raises `unmerged or unstaged changes remain after the ledger merge resolver`. It is absent from `skills/2-daily/jog/SKILL.md:191`–`:216`; the catch-all at `:215` says every other message is a failed command, but this one is Jog's own postcondition. Fix the list and catch-all so this legal stop is explicit. A6 checks only that the 17 listed messages exist, so its green result does not establish the reverse claim (all code stops are documented).

- **[Nit] F3 — pre-existing landing instructions contradict current admission.** `skills/2-daily/jog/SKILL.md:120`–`:122` still instruct interactive confirmation and describe supported automatic merge/advance. The actual real `jog run --auto-merge` input is refused before leasing at `utils/py/jog_run.py:2460`, and real legacy execution parks at `:2729`. The newer skill section `:158`–`:166` already explains that interim restriction. Replace the stale three bullets with that current landing policy. No additional pre-existing source defect established by this sweep.

**Acceptance / evidence audit**

Paths below abbreviate `TESTS-RESULTS/2026-11-13+GH-1453/` as E. These are assessments of retained observations, not reruns.

| Item | Source and decisive retained observation | Assessment |
|---|---|---|
| A1 | `jog_run.py:2313`, `:2338`–`:2396`; E/candidate-A1-A12.log:7–14: `journal_phase: published`, `remote_roadmap_pri: [61]`, queue `['parked', 1, 'fixture park']`, ancestors/check/clean/equality true | [Pass] Disjoint ledger writes preserved. |
| A2 | `jog_run.py:2200`–`:2208`; candidate log:17–27: `begin_rc: 0`, `tracking_ref_stale: True`, publication and clean/equality true | [Pass] Local stale tracking ref starts. |
| A3 | `jog_run.py:2376`–`:2379`, `:2331`–`:2333`, `:2558`; candidate log:34–46: GH-1315 named, `cli_rc: 2`, `cli_no_traceback: True`, tree restored and remote unchanged | [Pass] Expected overlap rejection, with successful disjoint control at log:62. Direct-class traceback is intentional; CLI behavior is separately measured. |
| A4 | `jog_run.py:2225`–`:2252`, `:2265`; candidate log:74–79 and base log:22–27: `parent_is_base: True`, `one_parent: True`, original subject and console formats | [Pass] Measured nonempty unmoved publication preserved. Broader unchanged-behavior claim needs qualifications below. |
| A5 | `jog_run.py:2184`–`:2189`; candidate log:48–60: `rc: 0`, `no_dispatch: True`, published/clean/equality true; driver:252–265 invokes the actual CLI | [Pass] Publication retry without task dispatch observed. |
| A6 | skill:168–221; E/a6-skill-text.log:1–21: `listed stop messages = 17`, `states remote ledger activity is not a stop: True`, base section false | Partial: listed-message existence passes; exhaustive legal-stop requirement fails F2. |
| A7 | `jog_run.py:2236`–`:2259`, immutable source at `:2233`; candidate log:83–95: `hook_fired: True`, `reconciles: 2`, queue attempt_count 1, remote priority 65 | [Pass] Second movement is reconciled without doubled lease. |
| A8 | `jog_run.py:2313`–`:2316`; candidate log:99–107: `merge_parents_are_checkpoint_and_remote: True`, `ledger_files_byte_equal_to_checkpoint: True` | [Pass] Code-only movement preserves ledger bytes. |
| A9 | `jog_run.py:2146`–`:2153`, `:2228`; candidate log:110–116: `view_committed_with_checkpoint: True`, foreign-control.txt refused | [Pass] Adoption and foreign-dirt control both exercised. |
| A10 | `jog_run.py:2184`, `:2217`–`:2224`; candidate log:124–129: `published_head_is_the_merge: True`, receipts 2926 → 2926, row B running before/after, `no_dispatch: True` | [Pass] Committed-merge crash window recognized, orphan scan avoided. |
| A11 | `jog_run.py:2291`–`:2297`, `:2331`; candidate log:142–151: `fixture: generator died mid-write`, `every_tracked_path_equals_head: True`, no merge/backup, `retry_published: True` | [Pass] Injected partial-output restore measured. Driver:418–448 injects ContractError after resolver; does not exercise real generator death or startup crash recovery F1. |
| A12 | `jog_run.py:2316`–`:2324` and resolver's adopted-view regeneration; candidate log:155–166: `conflicting_lines: [375]`, `view_regenerated_from_ledger: True`, published/clean/equality true | [Pass] Actual conflicting view lines exercised, with ledger-byte preservation separately controlled by A8. |

None of these candidate checks relies solely on “nothing crashed”: each asserts output state, refusal, content or ancestry. A6's assertion is narrower than its description. A12 asserts disappearance of the injected edit plus clean check/state, rather than byte-comparing to an independent render.

**Base controls and delivery claim:** E/base-red-controls.log:3–18,29–44 observes A1 rejected push with committed journal/unchanged remote; A2 the exact equality refusal; A9 adopted-view refusal; A10 receipts 2920 → 2921 and running → pending. Driver a1 checks `ContractError`, journal and remote head (driver:210); a2 checks the exact message; a9 checks the dirty view and named refusal; a10 measures the orphan scan's row mutation. Thus the reds are for the stated reasons, not missing setup. A10's base input is a local orphan row, while the candidate uses a disjoint remote running row and post-merge crash window: it isolates the old scan mechanism, not an identical end-to-end fixture. Base A4 passes as required. A6's base section-absence red is retained separately. The plan's blanket requirement for base reds on every change item was not fully executed: A3/A5/A7/A8/A11/A12 have no base runs, explicitly disclosed in SUMMARY. The existing-suite receipts report `227 pass, 0 fail` and `34 passed, 0 failed`; neither suite covers checkpoints (SUMMARY). These controls prevent treating the unchanged base as delivering A1/A2/A6/A9/A10; they do not independently qualify every stop branch or the full final commit.

**Plan / failure-path audit:** Steps 1–7 are represented in begin, owned views, publication loop, receipt replay, parent/message recognition, abort restore and the two CLI handlers (`jog_run.py:2180`–`:2396`, `:2553`, `:2743`). Differences found: the disclosed startup abort (F1); the four-status replay whitelist disclosed in Implementation notes (`:2122`); ancestor-based already-published/empty recognition (`:2241`); immediate named refusal of a divergent legacy journal rather than trying a known-doomed push first (`:2253`); and `check` runs only when the resolver runs, rather than unconditionally on the clean code-only merge (`:2316`–`:2324`). The last four are bounded, understandable refinements; the startup abort lacks ownership proof and a fixture.

Normal reconcile always takes the remote dump before replay and uses immutable source receipts, preventing cumulative replay on retry (`:2341`–`:2359`, `:2233`). Code-only movement deliberately skips replay. Overlap is checked before writer calls and final row triples are checked afterward (`:2376`–`:2396`). ContractError/OSError/sqlite3.Error/SubprocessError restore the open merge (`:2331`); writer SystemExit is converted at `:2388`. Signals/SystemExit outside that conversion and save/read I/O can escape: interruption recovery is deferred to rerun, making F1 material. A crash after merge commit but before journal save is handled by first-parent/subject recognition, as A10 observes. No additional concrete double replay, replay omission, or journal/HEAD mismatch was established on the retained normal paths. Writer-refusal execution and actual interrupted-open-merge recovery remain unverified by clone evidence.

**Unmoved callers:** A4 supports the original nonempty commit/parent/message/output, not absolute behavioral identity. Other changes include adopted-view ownership, local-ref/unpublished-commit admission, queue/receipt snapshots, committed-resume bypass of cold recovery, CLI ContractError conversion, extra fetches before publication and at completion, and skipping publication-clone checks/push when the checkpoint is already reachable from the remote. These are visible at `jog_run.py:2146`, `:2180`–`:2208`, `:2241`, `:2260`, `:2558` and are consistent with the intended scope apart from F1.

**Writer ownership / complexity / rating:** No second mutation writer is introduced within the reviewed implementation: replay delegates to `jog_acquire_lease`/`jog_set_status` (`jog_run.py:2384`–`:2387`), which call `perform_write` (`releases_app.py:5096`, `:5132`). Replacing the entire dump with canonical remote bytes before `check --rebuild` (`jog_run.py:2341`–`:2343`) is merge-side selection, not manually synthesizing ledger rows, and fits the dump rule. Rebuild owns regeneration and generation advancement (`releases_app.py:6570`, `:6654`–`:6663`). No parallel general ledger-merge subsystem is needed; the receipt replay remains scoped to this wake. The unsafe abort heuristic adds more authority than its evidence supports; remove or constrain it, without a new suite/framework.

Read-only rating query `SELECT gh_number,rating_pri,rating_sev,rating_appeal,rating_effort FROM roadmap_items WHERE gh_number=1453` via SQLite mode=ro exited 0 with `[(1453, 75, 70, 50, 40)]`. The issue read (`gh issue view 1453 --repo HiQS-Labs/XYZ-forge --json title,body`, exit 0) agrees with the plan's real downstream blockage and no-data-loss rationale. The persisted rating remains consistent; none of these observations warrants inventing a new rating.

**VERDICT: FAIL**
**Basis:** Main reconciliation behavior has substantial retained evidence, but F1 permits aborting an unowned merge and F2 leaves the required legal-stop documentation incomplete. Resolve those two Should findings and retain narrow manual recovery evidence in a disposable full clone. F3 is a pre-existing documentation nit. Full final-commit gate is not claimed here.

Handing off to Producer (claude-a) — go to the Producer window and say 'take your turn'.

### Producer · Round 2

Dispositions for Round 1. Fix commit `33c8682c3`; evidence refreshed on that commit.

- **F1 — Implemented (constrained, not removed).** Ownership is now recorded instead of inferred. `_reconcile` saves the merge target in the journal as `merging` before it opens the merge, and clears it on commit and on a handled failure. At the start of `finish()`, an open merge is restored only when `MERGE_HEAD` equals that recorded target **and** `HEAD` is still the journal's `commit`; any other open merge raises `checkpoint refuses a merge in progress that this wake did not start` before any staging or abort. `source` plays no part in the decision. Evidence in a disposable fixture, as you asked: **A13** kills the process while its own merge is open (journal `merging` equals the remote commit, `MERGE_HEAD` present), then the rerun restores, reconciles and publishes; **A14** leaves a committed, unpublished checkpoint, opens an operator merge of a different commit in the primary and reruns: exit non-zero with the named message, `MERGE_HEAD` still the operator's commit, the operator's file still present, `HEAD` at the checkpoint commit. `candidate-A1-A14.log`.
- **F2 — Implemented.** The skill now lists `unmerged or unstaged changes remain after the ledger merge resolver`, the new ownership stop, and the three Jog-authored command-failure messages (`checkpoint reconcile could not merge development`, `ledger merge resolver refused`, `checkpoint ledger command failed`, the last renamed from `releases %s failed` so it can be listed verbatim). The catch-all is narrowed to `git <command> failed: ...`, which is the only remaining source (`_git`). A6 now checks both directions: 22 listed messages all found in the class, and all 23 `ContractError` literals in `JogCheckpoint` listed. `a6-skill-text.log`.
- **F3 — Implemented.** The three stale landing bullets are replaced with the current policy: real runs refuse `--auto-merge` before any lease and park the published task awaiting landing; the interactive and `--auto-merge` paths remain for `--simulate` only.
- **Your note on base reds** (A3/A5/A7/A8/A11–A14 have no base run): unchanged and still disclosed in SUMMARY. Base has no reconcile path, so those checks cannot reach their starting state on base; A1 is their shared red control (base rejects the push every one of them begins with).
- **Existing suites** were run at `f4626d09b`, before this fix. The fix touches only `JogCheckpoint`, which neither suite exercises. They are not rerun here; the full push gate runs on the final commit.

Questions for this round: (1) are F1–F3 resolved; (2) can the recorded-ownership rule still abort a merge that is not this wake's, or fail to restore one that is; (3) anything else that must change before the gate and PR.

### Reviewer · Round 2

**What this delivers:** Jog starts a checkpoint wake using local state, then publishes at completion. A moved development is reconciled by replaying the wake's supported queue writes onto the remote ledger; unsafe overlap preserves a retryable checkpoint.

**How the existing system works, per these documents:** Canonical queue writers already record receipts and refresh adopted views. The checkpoint journal records the wake's start and immutable replay source, while a separate publication clone runs push hooks. The resolver rebuilds the selected dump and regenerates views.

**What it's not:** Per-transition publication, a general ledger merge, altered execution-clone preflight, or proof of a dispatched multi-task run (explicit exclusions).

**Input boundary:** Entire relay (including earlier review and producer reply), ROUTER.md, GUIDING-PRINCIPLES.md, review-code-xyz skill, plan and SUMMARY.md. Step A was not pristine: startup policy was read before the plan; this paraphrase is recorded before further source validation, and does not claim independent blindness to the earlier review.

**Assessment: source-backed.**
swept file: yes

Read the full Jog supervisor and skill, GH-1453 changelog entry, plan, manual driver and retained results, canonical writers/rebuild and merge resolver. No additional pre-existing runtime defect established. Graph Verify: no indexed project matches this worktree; nearest XYZ-forge generation `2026-09-01T15:54:30Z`, JogCheckpoint lookup zero, coverage changed/not-tracked (CHANGELOG excluded); current source fallback used. No git, suite, executable fixture or gate ran. Consequently no fresh base diff or final-commit gate is claimed. `gh issue view 1453 --repo HiQS-Labs/XYZ-forge --json title,body` exited 1: `error connecting to api.github.com`; issue assessment uses the retained plan and earlier relay read.

**Findings / dispositions**

- **[Pass] F1 resolved for the reported foreign-merge case.** `jog_run.py:2212`–`:2222` reads HEAD and MERGE_HEAD and refuses before staging unless both recorded identities match; `_reconcile` records the target before merging (`:2311`–`:2313`) and clears it on handled failure/success (`:2343`, `:2347`). E/candidate-A1-A14.log:170–183 observes `merge_left_open: True`, `journal_records_merge_target: True`, `rerun_rc: 0`, clean/published afterward. Lines 190–194 observe the named foreign-merge refusal and `operator_merge_still_open_with_its_file: True`. Driver:481–493 injects KeyboardInterrupt before replay; this is controlled interruption, not an OS-kill rehearsal. Driver:503–518 creates an actual separate-target operator merge and checks its preservation. A different HEAD also fails the source predicate, though that variant has no retained clone run. Identity matching cannot distinguish a manually replaced merge with exactly the same HEAD and target while a stale ownership marker remains; that operator intervention is outside the demonstrated recovery case, not a reason to add a new ownership framework in this envelope.

- **[Pass] F2 resolved.** Skill:212–225 now includes the postcondition, ownership refusal and command-failure prefixes; `jog_run.py:2296`, `:2315`, `:2332`, `:2339` contain the corresponding stops. Retained A6 reports `22` messages / `23` literals. Independent non-mutating AST/text check (`PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 -`, exit 0) found `listed: 22 ContractError literals: 23 unlisted: []`: each ContractError's leading constant starts with a listed prefix. This checks message coverage, not every explanation or external exception.

- **[Pass] F3 resolved.** Skill:120–125 now limits merge paths to simulation and describes real-run parking, matching admission at `jog_run.py:2473` and real legacy parking at `:2742`–`:2743`.

- **[Should] F4 — measure the published roadmap row, not the other session's copy.** `E/fixture-checks.py.txt:163`–`:166` implements `remote_pri()` by running `roadmap list` in `self.other`. That clone still has its own write even if reconciliation loses that write in the published ledger. A1, A2 and A7 use this helper to assert preservation (`:225`–`:226`, `:242`, `:323`); their log label `remote_roadmap_pri` therefore overstates what was read. The source appears to preserve the remote dump, but the central disjoint-ledger acceptance claim lacks its asserted observation. This corrects Round 1's evidence assessment; earlier log text is preserved.
  Observed input: AST-extracted current `Fx.remote_pri`, N=1315, `self.other='OTHER_SESSION_CLONE'`, app stub returning `[{'gh_number':1315,'rating_pri':61}]`; controlled published priority 999. Result remains `[61]`; the only read is `('OTHER_SESSION_CLONE', ('roadmap','list','--json'))`, with **zero published-ledger reads**. Command: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 - <<'PY'` (parse the recorded driver with `ast.parse`, compile only `Fx.remote_pri`, call with the above stub); exit **0**. Decisive output: `remote_pri returns: [61]`; `published ledger reads: 0; evidence blind spot reproduced`. No fixture or real git executed; this proves the observer's blind spot, not an observed production loss.
  Affected scope: retained A1/A2/A7 preservation assertions and their reported remote priorities.
  Falsifier: hold the other-session row at 61 but supply a published DB with priority 999 (or the row missing); the observation must report 999 (or absence), and A1 must fail. With the intact published DB at 61, A1 must pass.
  Fix: read `roadmap_items` from the already available `fx.remote_db()` snapshot in read-only mode; refresh the affected manual evidence in a disposable full clone and retain that narrow controlled failure. No new suite, registry or runtime machinery. Root cause: the helper reads the producer clone instead of the assertion target; Fix site: `Fx.remote_pri`; Why not upstream/downstream: changing replay code or relabeling successful output would not establish the required preserved row.

**Acceptance audit** (E = `TESTS-RESULTS/2026-11-13+GH-1453/`; candidate log below is `candidate-A1-A14.log`). These are retained observations, not reruns.

| Item | Source / decisive retained observation | Assessment |
|---|---|---|
| A1 | `jog_run.py:2354`–`:2409`; log:7–14 `remote_queue_row: ['parked', 1, 'fixture park']`, ancestors/clean/equality true | Partial: queue and publication observed; roadmap priority reads wrong clone (F4). |
| A2 | `:2200`–`:2208`; log:17–28 `begin_rc: 0`, `tracking_ref_stale: True`, published/clean/equal | Local-state admission passes; disjoint-row measurement inherits F4. |
| A3 | `:2389`–`:2392`, `:2341`–`:2345`, `:2571`; log:34–46 named GH-1315, `cli_rc: 2`, `cli_no_traceback: True`, restored tree/remote unchanged | [Pass] Actual refusal and restore; log:62–70 disjoint control passes. |
| A4 | `:2236`–`:2239`, `:2251`–`:2254`; log:74–79 `parent_is_base: True`, `one_parent: True`, original subject/console; base log same assertions | [Pass] Nonempty unmoved publication preserved. |
| A5 | `:2184`–`:2189`; log:49–60 `rc: 0`, `no_dispatch: True`, published/clean/equal | [Pass] CLI retry measured. |
| A6 | Skill:171–231 / entire class; A6 log `22` messages, `23` literals, `VERDICT: PASS`; independent AST count above | [Pass] Both directions checked; base section absent. |
| A7 | `:2244`–`:2267`, immutable source `:2241`; log:83–95 `hook_fired: True`, `reconciles: 2`, final queue attempt 1 | Retry and no doubled lease pass; latest roadmap priority assertion inherits F4. |
| A8 | `:2323`–`:2326`; log:99–107 `merge_parents_are_checkpoint_and_remote: True`, `ledger_files_byte_equal_to_checkpoint: True` | [Pass] Code-only merge preserves ledger bytes. |
| A9 | `:2146`–`:2153`, `:2236`; log:110–116 `view_committed_with_checkpoint: True`, foreign file refused | [Pass] Adopted view plus foreign-dirt control. |
| A10 | `:2184`, `:2224`–`:2232`; log:124–129 `published_head_is_the_merge: True`, receipts `2927` → `2927`, row B running unchanged | [Pass] Committed-merge resume, no orphan scan. |
| A11 | `:2299`–`:2305`, `:2341`; log:142–151 injected partial output, `every_tracked_path_equals_head: True`, `retry_published: True` | [Pass] Restore measured; direct injection, not actual generator death. |
| A12 | `:2326`–`:2339`, resolver:161–237; log:155–166 `conflicting_lines: [375]`, `view_regenerated_from_ledger: True`, clean/equal | [Pass] Conflicting edit removed and resolver succeeds; no independent render byte-comparison. |

No acceptance observation above is merely “nothing crashed”; F4 is a wrong-target observation, a distinct limitation. A13/A14 supply the new ownership evidence described above.

**Base / negative controls:** Driver:217–221 requires ContractError, committed journal and unchanged remote for A1; base log quotes non-fast-forward push rejection. A2 checks the precise equality refusal (`:235`–`:238`); A9 requires dirty adopted view plus its named refusal (`:351`–`:355`); A10 measures the orphan-scan receipt and row mutation (`:370`–`:388`, log `2920` → `2921`, running → pending). A4 preservation passes on base. These fail for the stated reasons, not incidental setup, but do not falsify roadmap-loss after successful reconciliation (F4). Missing base runs for A3/A5/A7/A8/A11–A14 remain disclosed; base cannot reach those reconcile states. A1 is their shared rejection control, not an identical per-case base rehearsal. Existing suite logs retain `227 pass, 0 fail` and `34 passed, 0 failed` at `f4626d09b`, before the ownership fix; SUMMARY and provenance state that limit. Full gate on the final commit remains outstanding by design.

**Plan / runtime questions:** Plan steps 1–7 are represented in `begin`, publication loop, receipt replay, resume recognition, restore and CLI catches (`jog_run.py:2180`–`:2409`, `:2565`–`:2577`, `:2756`–`:2761`). Divergences: recorded-target startup recovery (disclosed and now bounded); four-status replay whitelist (disclosed); ancestor-based empty/already-published recognition (`:2249`); immediate divergent-legacy-journal refusal (`:2261`); and conditional resolver/check for clean code-only movement (`:2326`). Renamed command-failure text supports the stop list. No further implementation divergence established without the prohibited git diff.

`_replay` always selects the remote dump whole (`:2354`), then replays immutable source receipts (`:2359`–`:2384`) and compares touched and untouched triples (`:2404`–`:2409`); successive reconciles therefore do not accumulate prior replay. Code-only movement intentionally needs no replay. Caught reconcile failures stage/abort/clear the marker (`:2341`–`:2345`); a commit-before-save interruption is recognized by first parent and subject (`:2224`–`:2232`). Signals and unexpected exceptions outside that catch can leave the recorded merge for rerun, now covered at the pre-replay interruption point only. Canonical writer SystemExit is converted (`:2401`); the writer-refusal branch remains unverified by clone evidence. No additional concrete dirty-primary, double-replay, skipped-replay or journal/HEAD defect established in this sweep.

Unmoved behavior is not literally unchanged apart from one fetch: adopted-view ownership, local-ref admission, snapshots, committed-resume bypass of cold recovery, CLI error conversion, additional fetches and ancestor-based publication skipping are visible at `:2146`, `:2184`–`:2208`, `:2247`–`:2269`, `:2571`. A4 proves the narrower normal nonempty commit/message/console preservation.

No second ledger writer or general merge subsystem appears in the reviewed code: replay calls canonical lease/status writers (`:2397`, `:2400`), which delegate to `perform_write` (`releases_app.py:5096`, `:5132`). Whole canonical remote dump selection before rebuild is merge-side selection, not hand-authored ledger rows; rebuild controls generation and serialization (`releases_app.py:6570`, `:6654`–`:6659`). The receipt replay and small ownership marker are commensurate with this local CLI; no new abstraction or suite is warranted. A read-only SQLite rating query exited 0 with `[(1453, 75, 70, 50, 40)]`; the documented downstream blockage and effort remain consistent with that rating (plan Rating rationale / SUMMARY).

**VERDICT: FAIL**
**Basis:** F1–F3 are resolved. One Should remains: fix the published-row observation and retain truthful A1/A2/A7 evidence (F4). No new runtime defect is asserted. The harness gate still follows review; it cannot substitute for the missing checkpoint-specific observation.

Handing off to Producer (claude-a) — go to the Producer window and say 'take your turn'.

### Producer · Round 3

Disposition for Round 2. No product code changed; the code under review is still `33c8682c3`.

- **F4 — Implemented.** You are right: `Fx.remote_pri` read the other session's own clone. It now opens `releases.db` taken from the bare origin's `development` ref, read-only, and selects `rating_pri` from `roadmap_items` for the row (`fixture-checks.py.txt`, `Fx.remote_db(ref)` / `Fx.remote_pri(ref)`). All 14 checks were rerun on `33c8682c3` in the disposable fixture with the corrected reader: `candidate-A1-A14.log` line 14 `published_roadmap_pri: [61]` (A1), line 23 `[62]` (A2), line 87 `[65]` (A7). The controlled failure you asked for is retained as an observer control inside A1: the same reader against the origin's ledger at the wake's base, before the other session's write, returns `[60]` (line 15), and A1's verdict requires that it is not `[61]`. So the reader reports what the published ledger holds and distinguishes a kept write from a lost one. The log labels are renamed `published_roadmap_pri`. SUMMARY carries a correction section naming the earlier wrong-target runs; those logs remain in history at `95c3421ac`.

Question for this round: is F4 resolved, and is anything left before the full gate and the PR?

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
