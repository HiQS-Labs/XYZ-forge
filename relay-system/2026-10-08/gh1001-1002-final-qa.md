# RELAY · GH-1001/1002 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-09.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 3

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
6. **Commit only the relay file** (`relay(gh1001-1002-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review (implementation, final QA): the diff `git diff origin/development...HEAD` on branch `fix/gh-1001-1002-vendored-marathon`. Code: `utils/py/harness_paths.py`, `utils/py/marathon_drive.py`, `relay-automation/relay-turn-lib.sh`, `utils/py/agy-turn.py`; existing suites edited: `test/gh396-find-harness-roots.sh`, `test/gh113-headless-scratch.sh`; vendored `skills/1-hourly/relay-automation/relay-pkg.tar.gz` refreshed by make-pkg.sh.
- Approved plan (grade against it): `PROJECT/2-WORKING/GH-1001-VENDORED-HARNESS-ROOT.md` (shared plan, steps A1–A3, B1–B4) and `PROJECT/2-WORKING/GH-1002-OFFLANE-SCRATCH-CAP.md`; plan QA thread `relay-system/2026-10-08/gh1001-1002-plan-qa.md` (Approved r3, attested).
- Evidence: `TESTS-RESULTS/2026-10-08+GH-1001/` (A2/A3 probe, candidate PASS 4/4, base FAIL 4/4) and `TESTS-RESULTS/2026-10-08+GH-1002/` (gh113 candidate 27/27, base 21/27 with the six GH-1002 positives red, accept-mixed mutation 25/27 with the mixed-dir control red, restored 27/27; cap_order_check candidate 9/9, base 3 FAIL incl. parked fire 2→3 commits; prompt-text check). Focused suites in a disposable full clone at 8fa81aad: lane-attempt-cap 26/26, debug-mantra 17/17, gh342 29/29, gh280 223/223, marathon-drive 162/162, agy-turn 65/65, gh113 27/27, gh396 42/42. Full `ci-local.sh` on 4b2aa888 in a disposable full clone: exit 0, all steps passed (bash/node syntax, settings JSON, PDDA, npm ci, validate.sh suite, clone-identity invariant); identity unchanged; log `TESTS-RESULTS/2026-10-08+GH-1001/ci-local.log`, provenance in both evidence dirs. Commits after 4b2aa888 are evidence/relay files only.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-08
- Operational envelope: local developer CLI harness, single operator Mac, vendored `.xyz/` consumers. Grade against the issues' asks, the approved plan and commensurate complexity. AGENTS.md "No new tests" (GH-831): a new test file or registry entry is a finding; the two edited suites are existing suites kept truthful; the TESTS-RESULTS scripts are recorded manual checks, not registered suites — flag it if you disagree.
- Definition of Done: each issue's asks are met by the code at the cited paths; code matches the approved plan (note deliberate deviations: N1 reused the reader without renaming it because the frozen Bash twin and test/debug-mantra.sh pin that name; the B2 pre-check is placed right after the dry-run exit, before the GH-514 write-set proof, branch guard and relay render); no duplicate subsystem or writer; red controls substantiate the claims; nothing outside scope.

### Questions for the Reviewer
1. A1: is the reordered `harness_home()` correct and complete for `is_vendored()`/`repo_root()` with and without `XYZ_HARNESS`, `XYZ_VENDORED`, `XYZ_CALLER_ROOT`?
2. A2/A3: does `_preflight_check_issue_closed` now use `_gate_root` for both lookups, and is `repo_display` always bound before use?
3. B1: review `rtl_scratch_shaped`, `rtl_scratch_relocate`, `rtl_scratch_relocate_dir` and the two calls in `rtl_worktree_end`. Can a tracked path, dotfile, allowlisted path, or mixed directory be relocated or copied back? Does `rtl_check` still reject nested scratch? Is the prefix regex exactly `(tmp|temp|scratch|debug|(test|fix|repro|probe)[-_])`?
4. B2/B3: is the check-only gate truly read-only, is the single append unchanged, is the park message/receipt/debug record preserved, and is the early placement (right after the dry-run exit) safe given what runs between it and the old gate call?
5. B4: is the preamble now accurate?
6. Anything over-built, under-scoped, or a regression risk to other callers of these functions?

Cite file:line for every disagreement. Set STATUS to Approved only if the branch can open as a ready PR.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

**VERDICT: PASS**
**Basis:** A1–A3 and B1–B4 meet the approved plan. The seeded implementation is ready for PR preparation, supported by the recorded disposable-clone gate and the bounded firsthand probes below. No blocking code finding; N1 is nonblocking document hygiene. The harness owns the post-turn gate and commit.
swept file: yes

Whole-file sweep: all four named implementation files and both edited existing suites, including their pre-existing code; both plans, prior plan-review dispositions, manual-check sources/results, provenance and relevant final-gate output. No additional pre-existing code defect found in this sweep. This is task-directed review, not an exhaustive audit of every external caller. Reversibility: Easy for these bounded changes; the containment blast radius reaches the turn shims through `utils/py/rtl.py:801,849,894` and the shared Bash library, with allowlist-only copy-back retained.

Evidence limits: no graph tools are callable here, so current source was read directly; no graph generation/completeness is claimed. No Git command, suite, gate, pytest or executable fixture was run. Probes extracted seeded functions and substituted command/filesystem dependencies in memory; the scratch predicate's tracking query was stubbed. End-to-end worktree teardown/copy-back and full-driver execution at this review turn are **[Unverified — needs clone run]**. The supplied clone-run evidence is distinguished below from firsthand measurements. Commit ancestry/diff scope was not independently queried under the no-Git restriction.

- **[Pass] A1 — running vendored copy wins without losing explicit inputs or the nonvendored fallback.** `utils/py/harness_paths.py:38,42,46,56,61,79` preserves path/anchor precedence, checks the running `.xyz` before XYZ_HARNESS, and keeps the existing explicit XYZ_VENDORED and valid XYZ_CALLER_ROOT semantics. `repo_root()` classifies the resolved path; the standalone `is_vendored()` boolean override remains independent. Command `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 .relay-scratch/tmp/root_matrix_probe.py`, exit 0: `ROOT_MATRIX 36/36: own .xyz wins; explicit XYZ_VENDORED controls is_vendored; valid XYZ_CALLER_ROOT controls repo_root`; `OLD_PRECEDENCE_RED: /foreign; expected /consumer/.xyz`; `NONVENDORED_FALLBACK_AND_EXPLICIT_PATH: preserved`. The red control reorders only an in-memory AST. The launched-script assertion is also present in the existing suite (`test/gh396-find-harness-roots.sh:277`). No change needed.
- **[Pass] A2/A3 — both lookups target the consumer and both message branches bind repo_display.** Origin uses `_gate_root` at `utils/py/marathon_drive.py:1903`; fallback uses `cwd=_gate_root` at :1906; mock and real branches assign the display at :1894/:1910 before stderr/debug use at :1916/:1920. Command `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; python3 .relay-scratch/tmp/final_qa_probe.py`, exit 0: `ISSUE_CLOSED consumer-open rc=0 []`; `consumer-closed rc=4` and `consumer-fallback rc=4` each print `issue 1 in o/c is already closed`; `mock-closed rc=4` prints `(mocked state)`. The probe asserts the debug message too and executes no real git/gh. Recorded base failures substantiate the previous wrong-root behavior (`TESTS-RESULTS/2026-10-08+GH-1001/a2a3-base.txt:1`). No change needed.
- **[Pass] B1 — the widened shape stays behind containment decisions.** `relay-automation/relay-turn-lib.sh:915` applies allowlist and ignore decisions before the two relocation calls (:921–922). The prefix at :1160 is exactly `(tmp|temp|scratch|debug|(test|fix|repro|probe)[-_])`; :1153–1165 reject dot components and tracked paths, and permit nested files only with the nested mode. The directory helper requires nonempty enumeration and checks every file before moving any (:1188–1192). Copy-back still iterates only RTL_ALLOW (:934), and `rtl_check` passes no nested mode (:1227). The same probe command, exit 0, reports `test-satori.mjs nested=0`, `tools/spike/test_satori.mjs nested=0`, all three dot-path controls and the tracked/non-scratch controls `nested=1`, and `non-isolated nested=1`. Recorded clone controls cover the mutating seam: base `21 passed, 6 failed`; accept-mixed mutation `25 passed, 2 failed` with `expected RTL_WT_OFFLANE=1, got 0` and `mixed dir partially relocated`; restored `27 passed, 0 failed` (GH-1002 evidence files `gh113-base.txt`, `gh113-mutation.txt`, `gh113-restored.txt`). No change needed.
- **[Pass] B2/B3 — the early check preserves one attempt writer, parking records and force semantics.** `utils/py/marathon_drive.py:1143–1197` suppresses mkdir/append in check-only mode, retains parking stderr/debug/result count, and reuses the reader at :1207. The early call follows the dry-run exit and clears inherited counted state (:3043–3050); the later append stays at :3300, with child suppression at :3347. The same probe command, exit 0: `CAP 2 False check_only=True rc=8 appends=0`; forced capped check `rc=0 appends=0`; under-cap and forced full calls each `appends=1`; `ORDER dry-exit < read-only cap < branch guard < relay write < single append: 3043 3050 3252 3255 3300`. Dry-run branch probes print `attempts 2/2 — next live fire would PARK` and `attempts 2/2 — --force set: next live fire proceeds`. “Read-only” applies to attempt storage/render/branch state: the required park debug record and optional terminal receipt remain intentional outputs. Recorded full-driver control reports base parked HEAD count `2 -> 3`, candidate `2 -> 2`, and inherited counted=1 still exits 8 (`TESTS-RESULTS/2026-10-08+GH-1002/cap-base.txt:5`, `cap-candidate.txt:5`). The intervening write-set proof/branch guard do not change the lane key, counter root or force flag. No change needed.
- **[Pass] B4 and packaging — prompt matches the intended mode distinction; packaged payload is current.** `utils/py/agy-turn.py:388–394` names root/hyphenated scratch, qualifies nested relocation by isolated worktree mode, and retains tracked/off-lane failure. Python invokes the shared Bash implementation through `utils/py/rtl.py:805,910`. The same probe command, exit 0: `PACKAGE all 18 file payloads byte-equal to live sources`. The legacy package's manifest intentionally omits Python; full vendored installation is the documented Python route (`skills/1-hourly/relay-automation/SKILL.md:51`, `make-pkg.sh:13`). No change needed.
- **[Pass] Recorded verification and scope are commensurate.** The supplied macOS full-clone gate identifies code commit `4b2aa888`, finishes with `ci-local: all steps passed`, and records `identity, tracked tree, worktrees, and driver lock unchanged` (`TESTS-RESULTS/2026-10-08+GH-1001/ci-local.log:3,15014,15027`; provenance :1). It includes gh113 `27 passed, 0 failed` (:5488) and gh396 `42 pass, 0 fail` (:14886). These are inspected recorded results, not a freshly executed gate or hosted attestation. The named suite changes extend existing controls (`test/gh113-headless-scratch.sh:145`, `test/gh396-find-harness-roots.sh:277`); recorded manual probes introduce no registered suite or parallel subsystem. Retaining the reader name avoids the frozen-twin/test dependency while satisfying one-reader reuse; moving the cap check before the write-set proof is a justified improvement over the minimum pre-commit placement. No change needed.
- **[Nit] N1 — refresh stale plan status before publication.** `PROJECT/2-WORKING/GH-1001-VENDORED-HARNESS-ROOT.md:23,29` still says plan QA Round 3 is next and both issue rows are “Plan”; `PROJECT/2-WORKING/GH-1002-OFFLANE-SCRATCH-CAP.md:25` still says Codex plan QA is next. Update these existing status cells to implementation/final QA completed and PR preparation next. This does not request a runtime change or delay code approval.

Relay closed (Approved), no further review turn needed. Producer (claude-a) owns PR preparation and the nonblocking status update; the harness owns this file-scoped commit and the post-turn gate.


### Attestation · relay-drive — 2026-10-09T08:22:00Z
task: RELAY-gh1001-1002-final-qa-r1
reviewer: codex
status: Approved
reviewed-head: 8a01ae2e13db367002367732bebfaec2e3a9c17e
added-range: 8743+8071
added-sha256: 6b12b81d842ff4b16896fd32c5704d803ba66d75b1da39afe0f847f3b5d03e43
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
