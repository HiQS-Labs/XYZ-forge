# RELAY · GH-1140 final QA — implementation vs approved plan
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
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
6. **Commit only the relay file** (`relay(gh1140-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the GH-1140 implementation on this branch — `skills/2-daily/merge-cleanup/scripts/batch_record.py`, `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, plus truthful edits to `test/gh436-merge-cleanup.py` (8 new pins) and `test/gh534_phase_a_tests.py` (signature mock). Review the diff `git diff origin/development..HEAD -- skills/ test/` against the approved plan `PROJECT/2-WORKING/GH-1140-BATCH-STALE-STATE.md`.
- Evidence to read: `TESTS-RESULTS/2026-10-18+GH-1140/provenance.jsonl` (+ the two scripts beside it), plan-QA thread `relay-system/2026-10-18/gh1140-plan-qa-r1.md`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- Definition of Done: every Phase B mechanism (1-8) is implemented as planned or the deviation is dispositioned; no new defect introduced; no scope creep; repo test policy respected (no new suites/registry entries — existing-suite edits and TESTS-RESULTS manual checks only).

## Context and questions

Operational envelope: local developer CLI skill; commensurate complexity — challenge over-engineering AND under-verification. The repo forbids new test suites (GH-831); existing-suite truthful edits and TESTS-RESULTS manual checks are the sanctioned verification lanes.

1. Mechanism 1 (extend() refresh, batch_record.py): does the refresh preserve order/outcomes, guard empty discovery, and strip `_refreshed` on persist?
2. Mechanism 2 (save() merge): are the merge rules correct for the r2 falsifiers (refresh wins, stale writer loses, verdict/sweep intentional replacement wins, outcomes field-merge monotonic, merged never downgraded)? Any case where the merge itself loses data or loops?
3. Mechanism 3 (QA-debt final status, merge_cleanup.py main tail): does it fire on every executing run incl. teardown-only, preserve exit 2/3 precedence, and never adopt without --resume?
4. Mechanism 4 (OID retention): is the verified OID recorded and the re-fetch demoted correctly at the caller? Is execute_pr_merge's contract change (Tuple return) handled at every call site?  [Unverified — no citation]
5. Mechanism 5 (veto): title fetched, title scanned word-boundary, final eligibility re-checks labels — any false-positive risk (e.g. common titles matching wip/hold) or bypass left?
6. Mechanism 6 (recovery): in-loop MERGED retention at the state!=OPEN branch; _recover_unrecorded_merges bounded to unfinished batches' planned PRs; positive evidence only. Any invented-landing path?
7. Mechanism 7 (command): mktemp form shell-safe.
8. Tests: are the 8 new pins meaningful (each can fail — red controls witnessed per provenance), and are the two signature-mock edits minimal and truthful?
9. Scope: anything in the diff beyond the approved plan? Any pre-existing defect made worse?

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
Basis: the implementation covers several planned mechanisms, but the save merge still loses durable updates and metadata refresh omits the explicitly accepted in-run repair shape. Integration evidence also overstates exit-4 coverage. These are bounded corrections to the approved mechanisms, not requests for new infrastructure.
swept file: yes

Read both complete implementation files, both complete named test files, the approved plan, plan-QA transcript, provenance and both manual-check scripts. **B** = `skills/2-daily/merge-cleanup/scripts/batch_record.py`; **M** = `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`; **T** = `test/gh436-merge-cleanup.py`; **E** = `TESTS-RESULTS/2026-10-18+GH-1140/`. No git command, suite, executable fixture, external query or artifact edit was run. The requested git diff was not run because this turn explicitly forbids git; scope assessment is from the seeded files and plan, not an independently enumerated changed-path list. Narrow probes below only imported B and called in-memory functions; save was replaced with a no-op for extend(). Full runtime and mutation controls remain [Unverified — needs clone run].

- [Blocker] **Stale concrete outcome fields still overwrite newer durable updates.** B:111-126 accepts every nonempty carried value from the saving snapshot, without distinguishing an intentional update. For the same merged PR, a stale `reconcile="failed: old"` overwrites disk `reconcile="ok"`; merge status being monotonic does not protect its fields. This directly leaves #1072's lost-update contract unsatisfied. Preserve disk values for unchanged carried fields while allowing an intentional reconciliation update; track update intent at the existing mutation/save boundary rather than treating every populated field as a new write.
  Observed input: disk and stale snapshot both have PR 1 status merged/OID `a` repeated 40 times; disk reconciliation advanced from `failed: old` to `ok`; saving stale yields `failed: old` (probe P below, exit 0).
  Affected scope: overlapping nonempty outcome fields in two snapshots of the same batch, particularly reconciliation updates; disjoint PR rows already merge.
  Falsifier: stale-save control must keep `ok`, while a subsequent intentional reconciliation change must persist and unrelated outcome fields must survive. Run through actual save in the disposable clone.

- [Should] **Same-second verdict/sweep timestamps cannot establish write intent.** B:43-44 timestamps only to seconds; B:169-176 resolves equal timestamps in favor of the saving snapshot. A routine stale save can therefore erase a new verdict covering another landing within that second and reintroduce QA debt. Sweep inputs have the same tie rule. Distinguish unchanged stale values from intentional replacements, including equal timestamps; merely changing `>` to `>=` would instead discard intentional same-second replacements.
  Observed input: disk verdict `{at:"2026-10-18T09:00:00Z",covers:[1,2],body:"new"}`, stale verdict `{at:"2026-10-18T09:00:00Z",covers:[1],body:"old"}`; `_merge_records` returns the old verdict (P, exit 0).
  Affected scope: verdict/sweep updates colliding within `_now()`'s one-second resolution.
  Falsifier: freeze the clock, record replacement coverage/body, then save an unchanged stale holder; new verdict must survive. A second intentional replacement at the same clock value must also succeed. Apply the equivalent control to sweep inputs.

- [Should] **Union landing order without reversing the persisted sequence.** B:163-167 starts with the stale writer's subset and appends disk entries, so disk `[1,2]` plus mine `[2]` becomes `[2,1]` (P, exit 0). B:403-406 uses the first/last OID for the sweep range, making this a materially wrong range, not just presentation. Preserve the existing durable sequence and append genuinely new entries rather than moving retained landings ahead of it.
  Observed input: disk landed_order `[1,2]`, saving snapshot landed_order `[2]`; output `[2,1]`.
  Affected scope: stale landing-order subsets that omit an earlier persisted landing.
  Falsifier: that merge must retain `[1,2]`; adding a genuinely new PR 3 must retain `[1,2,3]`, and the generated range must keep PR 1's first-parent start and PR 3's end.

- [Should] **Refresh removed dependencies as well as added dependencies.** B:98-103 skips fresh empty hard/soft collections even when the same discovery contains a valid nonempty file list. Empty dependency sets are normal authoritative discovery results, unlike a failed/empty file discovery. Existing stale dependency annotations therefore survive ordinary resume. Assign the supplied dependency fields when discovery is valid, including empty collections, while retaining the approved empty-files guard.
  Observed input: stored PR 1 files `["a"]`, hard `[7]`, soft `{"7":["overlap"]}`; discovery files `["a","b"]`, `_hard_deps=[]`, `_soft_reasons={}`; extend retains both obsolete dependencies (P, exit 0).
  Affected scope: known planned rows with valid refreshed files whose dependencies were removed.
  Falsifier: reload after that refresh and expect hard `[]`, soft `{}` and files `["a","b"]`; an empty-files discovery must continue preserving known files.

- [Should] **Implement the accepted in-run repair metadata refresh.** Phase B mechanism 1 explicitly requires the repaired PR's planned files to update within the same run. The only driver `batch_record.extend()` call is M:1814, before Phase 5. M:1225-1296 repairs/pushes/re-gates, but no planned-row update occurs before M:1044 computes shared files from B:408-411. Conflict-site capture at M:1229 does not update the planned file list. Refresh that row from the repair's authoritative changed-file data before sweep computation, preserving outcomes/order.
  Observed input: batch planned PR 1 files `["a"]`, PR 2 files `["b"]`; successful B1 repair adds `b` to PR 1's changed-file set at M:1225-1296. Both land, but B:408-411 still sees `["a"]` for PR 1 and omits shared file `b`.
  Affected scope: a discovered PR repaired and landed during this invocation, after the batch was selected.
  Falsifier: disposable-clone repair scenario must persist PR 1 files `["a","b"]` and report `b:[1,2]` in shared_files without needing another resume. Runtime execution is [Unverified — needs clone run]; the missing write path is visible in the complete driver.

- [Should] **Regenerate sweep inputs when recovering landings without a new landing loop.** M:1797-1798 stores recovered outcomes then publishes the issue without finalizing sweep inputs. With empty discovery, Phase 5 never runs (M:1700), so M:1044 never repairs that omission. The new recovery path can expose QA debt with no usable sweep range/command, or with a sweep still covering an earlier subset. Finalize the recovered batch's inputs before publishing it, using all surviving landings.
  Observed input: persisted batch planned `[1,2]`, both outcomes unattempted, sweep_inputs `{}`; `--resume --execute`, empty OPEN discovery, both remote PRs positively MERGED with OIDs. Recovery writes landings, but the path M:1772-1798 -> M:1814 -> M:1700(false) -> M:1766 leaves sweep_inputs `{}` and prints `see the batch record` instead of a command.
  Affected scope: recovered batch landing sets not subsequently passed through `_record_batch_outcomes`, including an empty resume queue.
  Falsifier: clone-run that shape; expect exit 4 plus a persisted complete OID range, shared files and executable command. CLOSED-without-merge must remain non-landed. Runtime execution is [Unverified — needs clone run].

- [Should] **Close the integration evidence gaps and correct the exit-4 claim.** E:`recovery-and-exit4.py` says “Exercise the exact main()-tail logic” but only calls `find_unfinished`; it never calls main or observes an exit status. Removing M:1753-1761 would leave that check green. T:984-990's “late label veto” likewise only calls hold_label, so removing M:1321-1327 leaves it green. None of the eight new pins exercises the retained-OID caller after confirmation failure, or the in-run MERGED branch. The provenance lists red controls only for extend/save/title; it does not establish each planned acceptance claim. In the existing suites or sanctioned manual evidence, drive the real orchestration paths for ordinary final-status masking (empty/one/new-batch/teardown), late-label arrival, OID retention after confirmation failure, and in-loop MERGED retention. Witness removal of each relevant mechanism causing a red result, and record the exact command/status/output and candidate identity. Add no suite or registry entry. Until then grade these integration claims [Unverified — needs clone run]. Also synchronize both race writers after reading the same snapshot in E:`two-writer-race.py`; currently process scheduling can serialize their reads/writes, so its “RED CONTROL” docstring is not a guaranteed exercised race.

- [Pass] **Implemented source paths worth retaining:** B:186-197 reads/merges/writes under the existing lock and updates the caller's dict; B:152-156 strips a refreshed marker on the normal existing-record merge path. M:248-249 fetches title, M:325-335 scans it with word boundaries, and M:1321-1327 performs the late veto. M:231/239 returns the observed OID and M:1339-1340 prioritizes it over re-query data. M:1753-1767 surfaces stored debt independently of adoption after successful Phase 6 while M:1705-1707/1749-1751 preserve earlier failure precedence. M:1782-1797 bounds recovery to unfinished planned PRs and positive MERGED+OID evidence. These are source-inspection passes only, not execution attestations.

Pre-existing defects found in the touched files are the accepted stale dependency/repair/sweep paths described above; no additional independent pre-existing defect was identified in this sweep. The two signature mock updates at T:447/597 and `test/gh534_phase_a_tests.py:567` match the tuple return contract. Existing-suite/manual-check placement follows the no-new-suite policy; complete diff scope and final clone gate remain unverified in this turn.

Probe P (single shell invocation, exit **0**; no file writes):
```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
python3 -B - <<'PYPROBE'
import sys,copy
sys.path.insert(0,'skills/2-daily/merge-cleanup/scripts')
import batch_record as b
base={'repo':'ex/ample','planned':[{'pr':1,'pos':1,'title':'old','files':['a'],'hard':[7],'soft':{'7':['overlap']}}], 'outcomes':{'1':{'status':'merged','merge_oid':'a'*40,'reconcile':'failed: old'}},'landed_order':[1], 'verdict':{'at':'2026-10-18T09:00:00Z','covers':[1],'body':'old'},'sweep_inputs':{}}
stale=copy.deepcopy(base); disk=copy.deepcopy(base)
disk['outcomes']['1']['reconcile']='ok'
print('stale_reconcile:',b._merge_records(disk,stale)['outcomes']['1']['reconcile'])
disk['verdict']={'at':'2026-10-18T09:00:00Z','covers':[1,2],'body':'new'}
print('same_second_stale_verdict:',b._merge_records(disk,stale)['verdict'])
stale['landed_order']=[2]; disk['landed_order']=[1,2]
print('stale_landing_order:',b._merge_records(disk,stale)['landed_order'])
rec=copy.deepcopy(base); b.save=lambda r:None
b.extend(rec,[{'number':1,'title':'fresh','files':['a','b'],'_hard_deps':[],'_soft_reasons':{}}])
print('removed_dependencies:',{k:rec['planned'][0][k] for k in ('hard','soft')})
PYPROBE
```
Decisive output:
```text
stale_reconcile: failed: old
same_second_stale_verdict: {'at': '2026-10-18T09:00:00Z', 'covers': [1], 'body': 'old'}
stale_landing_order: [2, 1]
removed_dependencies: {'hard': [7], 'soft': {'7': ['overlap']}}
```

Handing off to Producer (claude-a) — disposition these findings, make the bounded fixes and obtain truthful clone-run evidence, then request round 2 in the Producer window.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
