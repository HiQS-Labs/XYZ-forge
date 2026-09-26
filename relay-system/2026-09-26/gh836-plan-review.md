# RELAY · GH-836 plan review — trim the measured gate hotspots
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-26.
-->

NEXT: Producer
STATUS: Open
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
6. **Commit only the relay file** (`relay(gh836-plan-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh836-plan.md** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/0cc9b6f4-22bd-4606-b4ec-21e1b8f38591/scratchpad/gh836-plan.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-26
- Definition of Done: **Approved** when all of these hold:
  - (a) each recon claim R1–R5 matches the cited code and baseline evidence;
  - (b) each plan step removes measured cost without weakening what its leg or test proves, and names a red
    control that would catch the weakening;
  - (c) the plan adds no suite, registry entry or gate machinery, and touches only existing `test/` files and
    the plan;
  - (d) the red controls are falsifiable and not flaky, including step 1's smaller race window;
  - (e) the rating `70/45/50/70` and its rationale are grounded, and appeal is neutral (the operator set none).

## Review packet

**What this is.** The plan for #836 (`https://github.com/HiQS-Labs/XYZ-forge/issues/836`): trim three measured
test-side hotspots in `test/gh549-work-events.sh` and the `gh436` suite (`test/gh436-merge-cleanup.py`,
`test/gh534_phase_c_tests.py`), and fix `test/gh649-pdda-migration.sh`'s `/tmp` false red. The artifact is
`.relay-artifacts/gh836-plan.md`, a copy of `PROJECT/2-WORKING/GH-836-GATE-HOTSPOTS.md` at `5d463095`. The
branch is `fix/gh836-gate-hotspots` in this worktree.

**Operational envelope.** A single-repo local developer harness. The operator has ruled "no new tests"
(AGENTS.md): verification is by existing suites and recorded manual checks. The work is small edits to three
existing suites. Grade against the plan's stated requirements and commensurate complexity. Do not ask for new
suites, new helpers beyond the one extended helper, or runner changes.

**Read:**
- the artifact;
- `test/gh549-work-events.sh`: lines 160-165 (`seed_cursor_tail`), 935-1072 (section 21, especially the 21e red
  control at 1043-1072), and 1073-1190 (section 22, `rr`, 21f and its red controls);
- `utils/py/releases_app.py` 1610-1630 (`_dispatch_work_connectors`) and 5262-5275 (`_scan_review_ready`), for
  what `XYZ_WORK_CONNECTORS=0` switches off;
- `test/gh534_phase_c_tests.py` 522-600 and 920-966, and `test/gh436-merge-cleanup.py` 855-869;
- `test/gh649-pdda-migration.sh` 1-16 and `skills/4-occasional/vendor-stack/find-pdda.sh` 18-28;
- the baseline in `TESTS-RESULTS/2026-09-26+GH-836/` (`baseline-gh549-top-gaps.txt`,
  `baseline-gh436-durations.out`).

You may run read-only probes, but no suites: they belong in a disposable clone.

**Questions** (cite `file:line`):

1. **Step 1 (21e).**
   - Does bounding the mutated copy's sleep to the first 3 emits per process keep the red control reliable?
     Consider process start skew between the two `&`-launched racers, and whether both walk rows in the same
     order.
   - Is 3 enough, or should it be larger?
   - Is the process-global counter in the inserted text sound (Python `global` inside the mutated function)?
   - Does anything else in 21e depend on the per-row sleep?
2. **Step 2 (21f).**
   - Is it right that 21f's and red (iii)'s assertions never read board state, so `work backfill` can run with
     `XYZ_WORK_CONNECTORS=0`?
   - Does advancing the github_board cursor to the current tail before the next reconcile change what those
     reconciles do beyond skipping the replay? In particular, does review_ready emission depend on the cursor?
   - Is extending `seed_cursor_tail` with an optional id the least machinery?
   - Are the plan's listed backfill call sites (`:1127`, `:1132`, `:1141`, `:1178`) complete and correct?
3. **Step 3 (`gh436`).**
   - Is removing `run_tests` safe, given that all 17 named tests are in `gh436`'s collection (the recon's
     probe)?
   - Does GH-534's "exists and runs" requirement stay honest when "runs" means "runs in this same suite
     invocation"?
   - Is any named test excluded from collection in some mode, such as a skip decorator or an underscore name?
   - Are the two proposed red controls the right witnesses?
4. **Step 4 (`gh649`).** Is `pwd -P` the complete fix? Does anything else in the suite compare paths logically?
5. **Scope and machinery.** Anything over-built, under-built, or out of scope? Anything that should move to the
   operator decisions D1–D3 instead?
6. **Rating.** Is `70/45/50/70` grounded in the rationale?

Write findings in the Log per the turn rules. Set `STATUS: Approved` only if the Definition of Done is met.

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
Basis: The measured targets and steps 2–4 are sound, but step 1 does not yet satisfy DoD (d): ten ordinary starts cannot establish that the shortened race window tolerates startup skew. Revise that acceptance criterion before implementation. This is a plan review, not a failed execution claim.
swept file: yes

- [Should] **S1 — make the shortened race's acceptance criterion sensitive to startup skew.** `.relay-artifacts/gh836-plan.md:117-121` fixes the budget at three sleeps and concludes that ten consecutive witnesses mean “not flaky.” Both workers traverse the same ordered rows (`utils/py/releases_app.py:5175`), but `test/gh549-work-events.sh:1068` merely launches two background processes; it does not synchronize their arrival at the suppression read. A worker can consume its three sleeps before its peer reaches the relevant rows. Raising three to another arbitrary number does not settle that premise. Cheapest fix: describe three as a candidate budget, explicitly require deliberate staggered-start witnesses in both launch directions in the disposable clone (including skew beyond the nominal 1.2-second sleep budget), and name the fallback if those fail: retain the existing control or use bounded rendezvous inside the existing mutated-copy leg. Do not claim ten ordinary runs prove absence of flakes. No new suite, helper framework, or gate is requested.
  Observed input: the unsynchronized `for i in 1 2; do ... & done; wait` at `test/gh549-work-events.sh:1068`, the moved read before sleep at `:1057-1061`, and the proposed three-emission cap at plan `:118`.
  Affected scope: only 21e's intentionally broken copy and its evidence; the positive race and production runtime stay unchanged.
  Falsifier: run that edited existing leg in a disposable clone with controlled launch offsets in both directions; require successful worker exits and `NBF3 > NROWS` for each stated offset, alongside the unchanged positive `NBF2 = NROWS`. A demonstrated bounded overlap mechanism would remove the timing objection. Current dynamic reliability is **[Unverified — needs clone run]**.

- [Pass] **R1/R2/R3 measured costs match the retained evidence.** `TESTS-RESULTS/2026-09-26+GH-836/baseline-gh549-top-gaps.txt` records “124.8s line 1068”, “68.8s line 1127”, and “38.0s line 1178”; `baseline-gh436-durations.out` records “49.01s” for the parity test and “180 passed in 291.83s”. `provenance.jsonl` identifies the disposable baseline and exit 0. Those substantiate the targets, not the projected after-times. In R1, correct the positive-race citation from `:1052-1056` to `test/gh549-work-events.sh:1038-1041`.

- [Pass] **Step 2 preserves the event assertions.** `test/gh549-work-events.sh:1129-1147` and `:1179-1183` query events, not board state. The four listed calls at `:1127`, `:1132`, `:1141`, `:1178` correctly cover the positive interleave and red (iii). There is also a red (i) backfill at `:1159`; leaving it unchanged is reasonable (baseline 2.9s), but the list is not every backfill in the wider section. `utils/py/releases_app.py:5628-5641` scans before dispatch; `_scan_review_ready` at `:5264-5324` derives suppression from event history, not the cursor. Thus advancing the cursor skips old board replay without suppressing new review_ready emission. Extend `seed_cursor_tail` at `test/gh549-work-events.sh:162` with the optional id as proposed; preserve its default and both INSERT/UPDATE arms. The existing 22a board assertion at `:1104-1105` remains intact. Keep red (i) as well as (ii)/(iii) in the focused run.

- [Pass] **Step 3 removes duplicate execution in the full registered invocation.** `test/gh436-merge-cleanup.py:863-869` imports the phase classes and invokes unittest; the extra invocation is precisely `test/gh534_phase_c_tests.py:587-590`, requested at `:928`. The deleted-row and forced-named-test-failure witnesses at plan `:142-143` are appropriate. An AST-only inspection found all 17 table names as public test methods in the imported phase classes, with no method/class skip decorators. A separate read-only count command, `python3` with `n=set(re.findall(r'^\|[^\n]+\| script \| (Test\w+\.test_\w+) \|$', Path('skills/2-daily/merge-cleanup/SKILL.md').read_text(), re.M)); print('named tests:',len(n)); print('open-handles named:', 'TestA4OpenHandles.test_ix_held_descriptor_is_active_process_naming_the_pid' in n)`, exited 0: `named tests: 17` / `open-handles named: True` (imports: `from pathlib import Path; import re`). No test module was executed.

- [Nit] **Qualify R3's “every named test ... runs” statement.** `TestA4OpenHandles.setUp` skips when `lsof` is absent (`test/gh534_phase_a_tests.py:427-431`), including its named method at `:441`. This is an existing qualification, not a regression from removing the nested runner: unittest also treats the nested skip as successful. State that all 17 are collected in the full invocation, with execution subject to existing prerequisites; the retained macOS baseline reports no skips. Selecting only the parity test will check existence/parity, not execute the named behavioral tests. No additional guard is needed for that narrower mode.

- [Pass] **Step 4 addresses the observed resolver mismatch.** `test/gh649-pdda-migration.sh:4,15` compares logical ROOT to the resolver's physical result (`skills/4-occasional/vendor-stack/find-pdda.sh:22,26`). The retained red log `TESTS-RESULTS/2026-09-26+GH-835/full-gate-b2c307b4-tmp-red.log:426` says `FAIL - resolver`. The rest of the 165-line suite uses ROOT to locate files; its other comparisons concern contents and fixture-derived state. `pwd -P` is sufficient for this ROOT mismatch. Execute the planned before/after from the logical `/tmp/...` spelling explicitly; merely storing a clone beneath `/private/tmp` would not reproduce it.

- [Pass] **R5, scope and rating are reasonable.** `githooks/pre-push:295` runs validate without setting the skip; `ci-local.sh:404` and `.github/workflows/ci.yml:194,402,483` set it. This is the default behavior, subject to an inherited opt-out (`test/relay-self-sufficiency.sh:29`). D1–D3 remain operator decisions. The plan's non-goals and steps introduce no suite, registry entry, or runner change. The rating rationale explicitly says “Appeal 50. Neutral; the operator gave no score,” distinguishes unknown trend, and labels after-times “Expected”; the numerical values are judgment, not measurements. Record the existing easy reversibility explicitly if desired; no additional ceremony is needed.

- [Unverified — needs clone run] **Implementation proof remains outstanding.** No suite, pytest, or executable fixture was run in this review. The proposed global counter is sound in principle only if initialized and declared before its first use in `_emit_work_event`; the plan has no inserted code yet to validate. Nothing else in 21e uses the sleep beyond inducing overlap and the final duplicate count (`test/gh549-work-events.sh:1067-1071`). I found no additional pre-existing defect in the reviewed plan beyond S1 and the cited qualifications.

Handing off to Producer (claude-a): revise S1 and disposition the findings, then return the plan for round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
