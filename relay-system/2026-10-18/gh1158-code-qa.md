# RELAY · GH-1158 code QA — landing decision checkpoint implementation
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(gh1158-code-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review:
  - `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`
  - `skills/2-daily/merge-cleanup/scripts/batch_record.py`
  - `skills/2-daily/merge-cleanup/SKILL.md`
  - `TESTS-RESULTS/2026-10-18+GH-1158/verify-landing-plan-checkpoint.py`
  - `TESTS-RESULTS/2026-10-18+GH-1158/provenance.jsonl`
  - Reviewed commit: `c3d80cf7` (branch `feat/XYZ-forge-gh1158-landing-plan-checkpoint-2026-10-18`)
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- Definition of Done:
  1. Strict zero-mutation invariant on Exit 5 refusal when 3+ PRs lack `--landing-plan` and valid non-empty `--landing-reason`. Halts before `prepare_primary_landing` (`REBASE_HEAD`), before checkout ref fetches (`FETCH_HEAD`), before `--marker` comments, and before `batch_record` writes.
  2. `--landing-plan group` records the decision in `batch_record` (and GitHub batch issue if accessible, or warns without false claim), prints the GH-1066 checklist, and exits 0 cleanly without merging or checkout teardown.
  3. `--landing-plan direct` records the decision and proceeds through Phase 5 sequential merges.
  4. `batch_record.set_landing_plan` sets `_landing_plan_touched = True`; `_strip_marks` strips it on save (both first persistence and merge save); `_merge_records` preserves `disk["landing_plan"]` against stale writers.
  5. `--resume` reuses the recorded decision for an identical PR set; altered PR sets require a new decision (exits 5).
  6. Small queues (<3 PRs) are completely unaffected.
  7. `SKILL.md` documents `--landing-plan`, `--landing-reason`, Exit 5, and examples.
  8. No new test files in `test/` or entries in `validate.sh` (GH-831 strictly observed). All 10 verification checks pass in `TESTS-RESULTS/2026-10-18+GH-1158/verify-landing-plan-checkpoint.py` with committed provenance.
  9. Regression suites `test/gh436-merge-cleanup.py` (188 tests) and `test/gh534_phase_c_tests.py` (111 tests) pass cleanly.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: FAIL
Basis: Block — the early checkpoint does not bind the queue later sent to Phase 5; verification also overstates its sensitivity. No source/artifact edits or git commands were performed.
swept file: yes

- Scope/evidence: read all five Setup artifacts, including surrounding pre-existing code, plus the verification summary. No additional pre-existing defects identified in this sweep. Graph Verify lookup used `XYZ-forge`, generation `2026-09-01T15:54:30Z`; it refers to another checkout and returned no landing symbols, with coverage freshness `not_tracked`, so findings rely on direct source reads rather than graph completeness.

- [Blocker] **F1 — Phase 4 can widen the queue past the checkpoint.** `merge_cleanup.py:1597-1638` validates `early_ordered`, but `:1736-1755` discovers a new queue; `:1839-1844` sends that new queue to the landing loop without checking it against the checkpoint. `select_batch` (`:1931-1933`) can then record a decision against this expanded set despite the reason having been accepted for the earlier set.
  Observed input: `--execute`, first discovery PRs `[1,2]`, second discovery `[1,2,3]`, no landing flags. A non-mutating in-memory probe of the actual `main()` reached `land_prs([1,2,3])`. Second case: first `[1,2,3]`, second `[1,2,3,4]`, `--landing-plan direct --landing-reason 'reviewed three'`, reached `land_prs([1,2,3,4])`.
  Affected scope: executing ordinary landing runs whose second discovery introduces members absent from the pre-mutation checkpoint; this includes resume decisions adopted for the first discovery.
  Falsifier: first and second discovery both `[1,2,3]`, no flags, must return 5 before any mutator. The same probe did return `rc=5 events=[]`, excluding a probe that simply bypasses the checkpoint wholesale.
  Probe command: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 -` (inline Python imported `merge_cleanup`, patched `fetch_open_prs_with_retry` with the two queues, used identity `toposort_prs`, supplied affirmative readiness/policy, replaced all filesystem/network/landing/batch/teardown operations with in-memory stubs, and invoked `main()` with patched `sys.argv`; stdout/stderr captured). Shell exit 0. Decisive output:
  ```text
  early=2 late=3 flags=[] rc=0 events=[('prepare_primary',), ('scan',), ('fetch',), ('prepare_primary',), ('select_batch',), ('land_prs', [1, 2, 3])]
  early=3 late=4 flags=['--landing-plan', 'direct', '--landing-reason', 'reviewed three'] rc=0 events=[('prepare_primary',), ('scan',), ('fetch',), ('prepare_primary',), ('select_batch',), ('land_prs', [1, 2, 3, 4])]
  early=3 late=3 flags=[] rc=5 events=[]
  ```
  This observes dispatch/control flow, not real merges. Root cause: independent discovery snapshots govern permission and execution; Fix site: the queue handoff from the upfront checkpoint into Phase 4; Why not downstream: a late Exit 5 after scan/fetch/markers would violate the zero-mutation invariant. Cheapest fix: freeze the run's eligible member set at the early checkpoint and sequence only that set later (keep any broader discovery separately for stacked-dependent protection), or otherwise establish a single decision-bound queue before mutations. Measure the changing-queue case in the existing evidence script in a disposable full clone.

- [Should] **F2 — the batch-write assertion is blind to the actual storage path.** `verify-landing-plan-checkpoint.py:74-76` searches `.tick/merge-cleanup/batch-*.json`; `batch_record.py:63-64,82-92` delegates to `attempt_record.record_path`, whose `:49-51` adds the `<owner>-<repo>/` directory. A wrongly created record therefore still satisfies the assertion.
  Observed input: a real scratch file at `.tick/merge-cleanup/owner-repo/batch-seeded.json`; the exact `root.glob('batch-*.json')` used by the check returned `[]` while that file existed.
  Affected scope: the existing Exit 5 verification's no-batch-write assertion, not production record layout.
  Falsifier: seed a batch at the canonical owner-specific location and require the existing assertion to fail; with no batch it should pass.
  Probe command: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 -` with `TemporaryDirectory()`, `actual=root/'owner-repo'/'batch-seeded.json'; actual.parent.mkdir(parents=True); actual.write_text('{}'); print(actual.is_file(), list(root.glob('batch-*.json')))`. Shell exit 0; decisive output: `seeded actual batch exists: True ; current assertion glob: []`.
  Fix: use the canonical coordinator directory (or explicitly inspect its batch descendants), guard its nonempty seeded control, and record witnessed red/green results in existing evidence/provenance. Add the currently missing FETCH_HEAD and `--marker` boundary observations to that same manual verification, as DoD 1 specifically requires them; do not add a new test suite or gate.

- [Should] **F3 — the claimed red control is an ordinary happy-path run.** `verify-landing-plan-checkpoint.py:95-105` passes a valid direct plan and expects successful landing. It never bypasses/breaks the checkpoint or observes a failing assertion. `provenance.jsonl:1` nevertheless attests “red controls.” Static AST inspection (`PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 -`, `ast.parse` then enumerate calls under `test_03_red_control_bypassing_checkpoint`; exit 0) showed only branch setup, `run_main(... --landing-plan direct ... )`, and success assertions. Fix: in a disposable full clone, witness the existing no-plan check go red under a controlled checkpoint bypass, restore the candidate, run it green, and record the mutation, failing assertion, commands, statuses and revision in the existing provenance. Rename/reword the happy-path claim if retained. This requests evidence correction, not a new production behavior.

- [Pass] Static marker lifecycle matches DoD 4: `batch_record.py:49-57` strips `_landing_plan_touched`; `:189-190` preserves the disk plan for an unmarked stale writer; `:198-215` strips on first and merge persistence; `:310-320` marks an intentional decision before save. Documentation covers the flags, Exit 5, resume, and examples at `SKILL.md:229-243,595-600`.
- [Unverified — needs clone run] Did not execute verification fixtures or regression suites in this linked worktree. `provenance.jsonl:1-3` reports 10/188/111 passes at `2bcc35dd13083f01b6898c83875e912b3409ecfe`, whereas Setup identifies `c3d80cf7`; those are recorded prior-run claims, not a fresh final-state attestation by this reviewer. Re-run required checks on the corrected candidate in the disposable full clone and retain truthful receipts.

Handing off to Producer (claude-a) — disposition F1–F3, implement corrections, and return for review; go to the Producer window and say 'take your turn'.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
