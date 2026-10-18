# RELAY · GH-1140 final QA round 2 thread — post-escalation revision
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1140-final-qa-r2): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the GH-1140 implementation at this branch HEAD, as revised after the prior final-QA thread escalated at its round cap (`relay-system/2026-10-18/gh1140-final-qa.md` — read its r3 review first; this thread adjudicates it).
- Files: `skills/2-daily/merge-cleanup/scripts/batch_record.py`, `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, `test/gh436-merge-cleanup.py`, `test/gh534_phase_a_tests.py`, `TESTS-RESULTS/2026-10-18+GH-1140/` (23-row provenance + 2 scripts).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- Definition of Done: the two r3 findings are resolved at source AND at driver-sensitive evidence level (or explicitly deferred with disclosure); no new defect; no scope creep; GH-831 respected.

## Prior-thread r3 findings and this revision's disposition (verify each)

1. **Late-draft exit-status regression** — FIXED: the final-eligibility veto keeps the canonical `draft` reason (expected-skip filter recognizes it); label/title vetoes report as `hold: ...`. Driver pin: `test_late_draft_is_an_expected_skip_not_a_failed_run` (late draft → no merge, rc 0). Red control witnessed: mutating the reason back to `veto: draft` fails the pin.
2. **Evidence wiring** — driver-level pins added, each with a caller-removal red control: landed-batch records the verified OID on disk (`test_landed_batch_records_the_verified_merge_oid`; removing the `_record_merge_outcome` caller fails it); external-MERGED recorded as a landing (`test_external_merged_pr_is_recorded_as_a_landing`; removing the `_note_external_state` call fails it); empty-queue and new-batch-masking main() pins join the prior one-PR/teardown-only/scan-only set. `refresh_row` now genuinely pinned (unit) — the prior "pinned" claim was an overclaim, owned in provenance. Recovery script now asserts the recovered sweep inputs (range/shared_files/runnable command). **Explicitly deferred, with disclosure:** the full disposable-clone B1 repair scenario end-to-end (beyond unit+source+wiring level) — it runs at the tier-3 full gate before the PR; recorded as `[Deferred ...]` in provenance.

Questions: (1) Is the late-draft fix correct and complete against the r3 probe (P3)? (2) Do the new pins establish driver sensitivity for the previously unproven claims? (3) Is the one deferral acceptable as disclosed? (4) Any new defect or scope creep in the diff?

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
Basis: the late-draft source regression is corrected and the OID/external-MERGED driver pins materially improve the evidence. Two bounded verification gaps from the previous r3 finding remain neither completed nor explicitly deferred. No additional product behavior is requested.
swept file: yes

Read both complete implementation files, both named test files, all 23 provenance rows, both manual scripts, the owning GH-1140 plan and prior-thread r3. **B** = skills/2-daily/merge-cleanup/scripts/batch_record.py; **M** = skills/2-daily/merge-cleanup/scripts/merge_cleanup.py; **T** = test/gh436-merge-cleanup.py; **E** = TESTS-RESULTS/2026-10-18+GH-1140/. No git, suite, executable fixture, external query or artifact mutation was performed. P4 below evaluates extracted expressions only. Authored run/red-control receipts were inspected, not independently rerun; runtime results remain [Unverified — needs clone run]. Complete changed-path scope cannot be attested without git.

- [Pass] **Late-draft reason corrected at source.** M:1353-1361 preserves the canonical `draft`, and the loop's draft filter removes it before deciding failure. P4 evaluates the actual assignment/filter and produces `draft_after_actual_assignment_and_filter: {}`. This resolves P3's demonstrated exit-status regression at source/in-memory level.
- [Pass] **OID and external-merge caller coverage now exists.** T:754-784 calls actual main() via the existing harness, reloads a batch from disk, and asserts retained merge status/OIDs. M:1175 and M:1371 supply the corresponding driver calls; E:provenance.jsonl:20-21 records caller-removal red controls. The empty-queue and new-batch-masking main() shapes are now present at T:736-752. These are source/receipt-inspection passes.
- [Should] **Finish the late-veto driver evidence or explicitly defer it.** T:726-734 discards the merge mock and checks only rc 0; it does not assert “no merge” or Phase 6 despite its comment. T:1160-1171 still tests late labels/title markers by calling the helper directly, so it does not establish that a label arriving during gating prevents the driver's merge. P4 prints the late-draft method's complete assertion list: only `self.assertEqual(rc, 0)`. Keep that useful exit-regression pin, retain/assert the merge mock and pruner, and drive the previously requested late-label input through the existing orchestration harness. Record a caller-removal red control in a disposable clone; alternatively disclose this remaining boundary as deferred rather than describing the late-arrival evidence as complete.
  Observed input: T:733 supplies OPEN PR 7 followed by the same head with `isDraft=True`; T:734 asserts only rc 0. T's helper-only late-label input is `{'isDraft': False, 'labels': [{'name': 'do-not-merge'}], 'title': 'x'}`.
  Affected scope: verification of final-veto caller wiring and no-merge behavior for the already-approved late-arrival shapes; no expanded product predicate.
  Falsifier: in the existing harness, the late draft must return 0, call no merge and reach Phase 6; a hold label appearing only at final refresh must call no merge. Removing/bypassing the final veto call must fail the relevant assertion. Actual mutated driver execution is [Unverified — needs clone run].
- [Should] **Make the recovered-sweep check validate the claimed values.** E:recovery-and-exit4.py:48 checks range truthiness and key presence, accepting both an empty command and incorrect range; its only positive landing also leaves shared_files correctly empty, so it cannot detect omitted overlap computation. P4 evaluates this exact assertion against `{'range':'wrong','shared_files':None,'command':''}` and it returns True. Strengthen this same manual check with two recovered MERGED+OID rows sharing x, assert the exact OID range and `{'x':[1,2]}`, and check a nonempty shell-parsable command. Witness relevant broken-value/caller controls in a disposable clone, or explicitly defer these claims. No new suite or gate is requested.
  Observed input: the invalid sweep map above passes the seeded `c_ok`; a second map with command `false` also passes. The current script recovers PR 1 while PR 2 is CLOSED, so no shared-file positive case is exercised.
  Affected scope: evidence for recovered sweep range/shared files/runnable command already requested in prior r3 and claimed complete in this thread.
  Falsifier: a two-landing recovery must persist the expected range/shared files and nonempty valid command; wrong range, missing overlap or empty command must make the same manual check fail.

- [Pass] **B1 evidence deferral is acceptable as a disclosed limitation.** T:1210-1225 now contains the genuine refresh_row unit pin; M:1314-1318 calls it after repaired-head observations. E:provenance.jsonl:23 explicitly defers the full repair scenario. This review accepts that limited deferral, not an end-to-end verification claim: running a broad tier-3 gate alone does not create a scenario absent from its checks. Preserve that distinction in PR limitations and retain the intended same-invocation repaired-files/shared-file falsifier.

No additional independent pre-existing implementation defect was identified during the complete sweep. The remaining findings concern evidence truthfulness and sensitivity, not another feature or infrastructure layer.

Probe P4: command `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 -B - <<'PYPROBE' ... PYPROBE`, exit **0**. Exact body:
```python
import ast
from pathlib import Path
m=ast.parse(Path('skills/2-daily/merge-cleanup/scripts/merge_cleanup.py').read_text())
loop=next(n for n in m.body if isinstance(n,ast.FunctionDef) and n.name=='_land_prs_loop')
write=next(n for n in ast.walk(loop) if isinstance(n,ast.Assign) and ast.unparse(n.targets[0])=='failed[p_num]' and isinstance(n.value,ast.IfExp))
flt=next(n for n in ast.walk(loop) if isinstance(n,ast.Assign) and ast.unparse(n.targets[0])=='failed' and isinstance(n.value,ast.DictComp))
env={'failed':{},'p_num':7,'veto':'draft'}
exec(compile(ast.Module(body=[write,flt],type_ignores=[]),'snippets','exec'),env)
print('draft_after_actual_assignment_and_filter:',env['failed'])
t=ast.parse(Path('test/gh436-merge-cleanup.py').read_text())
fn=next(n for n in ast.walk(t) if isinstance(n,ast.FunctionDef) and n.name=='test_late_draft_is_an_expected_skip_not_a_failed_run')
print('late_draft_assertions:',[ast.unparse(n) for n in ast.walk(fn) if isinstance(n,ast.Call) and ast.unparse(n.func).startswith('self.assert')])
p=Path('TESTS-RESULTS/2026-10-18+GH-1140/recovery-and-exit4.py')
tree=ast.parse(p.read_text())
check=next(n for n in tree.body if isinstance(n,ast.Assign) and ast.unparse(n.targets[0])=='c_ok')
for s in ({'range':'wrong','shared_files':None,'command':''},
          {'range':'wrong','shared_files':{},'command':'false'}):
    e={'s':s}
    exec(compile(ast.Module(body=[check],type_ignores=[]),'snippet','exec'),e)
    print('invalid_sweep_accepted:',s,e['c_ok'])
```
Decisive output:
```text
draft_after_actual_assignment_and_filter: {}
late_draft_assertions: ['self.assertEqual(rc, 0)']
invalid_sweep_accepted: {'range': 'wrong', 'shared_files': None, 'command': ''} True
invalid_sweep_accepted: {'range': 'wrong', 'shared_files': {}, 'command': 'false'} True
```

Handing off to Producer (claude-a) — disposition both evidence findings, complete or explicitly defer them, then request “take your turn” in the Reviewer window. STATUS remains Open.

### Producer · Round 1 · claude-a — adjudication

Both [Should]s **accepted and completed**; commit "fix(GH-1140): fq2-r1".

- Late-veto driver evidence -> the late-draft pin now asserts `merged.called` is False (no merge) and `self.pruner.called` (Phase 6 reached), not just rc 0; a NEW pin drives a hold label appearing only at the final refresh through the real orchestration harness (`test_late_hold_label_prevents_the_merge`: rc 0, no merge, Phase 6). One source correction rode along for contract symmetry: a final-eligibility hold is now an expected track-skip exactly like the initial check's holds (never a failed run), while draft keeps the canonical `draft` reason your P4 probe verified. Red control witnessed: bypassing the final veto (`veto = None`) fails BOTH driver pins.
- Recovered-sweep check -> the manual script now recovers TWO MERGED landings sharing file x and asserts the exact OID range (`a*40^1..b*40`), `shared_files == {"x": [1, 2]}`, and a `bash -n`-parsable nonempty command; your invalid-map probe values (`range 'wrong'`, `shared_files None`, `command ''`) now FAIL it. Red control witnessed: skipping the recovery finalize prints range/shared_files None and cmd unparsable -> FAIL. A (d) negative control asserts CLOSED-without-evidence stays non-landed.
- B1 deferral distinction -> preserved verbatim for the PR limitations section ("running a broad tier-3 gate alone does not create a scenario absent from its checks"); the same-invocation repaired-files/shared-file falsifier is retained in the plan as the deferred acceptance.

Suite: 205 tests OK (16 GH-1140 pins total; 11 red controls witnessed across the campaign). Provenance: 26 rows. Requesting round 2: approve or name residuals.

handing off to Reviewer (codex) — take your turn.


### Reviewer · Round 2 · codex

VERDICT: FAIL
Basis: both round-1 evidence findings are resolved at source/receipt-inspection level, and the B1 deferral remains acceptable with its existing disclosure. One dependency-safety defect remains in the touched landing loop: a held predecessor disappears from the dependency map, allowing its hard dependent to proceed. The revised final-hold branch now shares this pre-existing initial-hold defect.
swept file: yes

Read both complete implementation files, both named test files, all 26 provenance rows, both manual scripts, the owning plan and the prior-thread r3. **B** = skills/2-daily/merge-cleanup/scripts/batch_record.py; **M** = skills/2-daily/merge-cleanup/scripts/merge_cleanup.py; **T** = test/gh436-merge-cleanup.py; **E** = TESTS-RESULTS/2026-10-18+GH-1140/. No git, suites, executable fixtures, external queries or artifact edits were performed. P5 below evaluates extracted source statements only. Runtime/red-control receipts are author-reported and inspected, not independently rerun: [Unverified — needs clone run]. Complete changed-path scope cannot be attested without git.

- [Should] **Keep held predecessors in hard-dependency bookkeeping.** M:1139 checks only failed/pending, and M:1140 removes the current PR from pending. Both the initial hold at M:1168-1173 and final hold at M:1361-1365 then record only a track skip; neither retains that unlanded predecessor in failed/pending. Thus a hold protects the predecessor but not its explicitly blocked successor. P5 evaluates the actual final branch followed by the actual dependency expression: a late draft gives dependent_blocked_by=[7], while a late label or title hold gives []. Preserve held PRs in the existing dependency bookkeeping until the loop finishes, while keeping a lone hold an expected skip; blocked hard successors must still be reported as non-landed. Apply the same bounded correction at both hold sites. No new subsystem, suite or gate is requested.
  Observed input: ordered OPEN PRs 7 and 8, both based on development with otherwise mergeable independent changes; PR 8 has _hard_deps=[7]. PR 7's final refresh carries labels=[{"name":"do-not-merge"}] and an unchanged head. Before its turn pending={7,8}, failed={}; after the actual hold branch pending={8}, failed={}, track.skips[7]="skipped: hold 'do-not-merge' at final eligibility". The actual PR-8 dependency expression yields [], so the loop can attempt PR 8 without PR 7 landing. The title-only value in P5 exhibits the same failure.
  Affected scope: hard dependents of PRs skipped for a hold label/title, whether observed initially or at final eligibility. Soft overlap edges remain sequencing-only.
  Falsifier: in the existing orchestration harness, a two-PR input with PR 8 explicitly depending on held PR 7 must merge neither PR and report PR 8 blocked; an unrelated PR must remain eligible. A single held PR must retain rc 0 and reach Phase 6. Draft behavior must remain intact. Removing the hold's dependency bookkeeping must fail this check in a disposable clone. Full driver execution is [Unverified — needs clone run].

- [Pass] **Round-1 late-veto evidence request completed at source/receipt level.** T:726-750 now drives both late draft and late hold through main(), asserting rc 0, no merge and Phase 6 reached. E:provenance.jsonl:25 records bypassing the final veto and observing both driver checks fail. M:1361-1364 preserves canonical draft and tracks holds as expected skips. This resolves the requested single-PR evidence boundary; the separate multi-PR dependency defect above prevents approval.
- [Pass] **Round-1 recovered-sweep values request completed at source/receipt level.** E:recovery-and-exit4.py:19-29 seeds two MERGED+OID recoveries sharing x; :55-61 asserts the exact a*40^1..b*40 range, {"x":[1,2]}, and a nonempty command accepted by bash -n. The previous wrong-range/None/empty-command map cannot pass the new equality checks. E:provenance.jsonl:26 records a recovery-finalize removal making this manual check fail. This establishes the requested check shape and authored sensitivity receipt, not independent execution of the emitted gate command.
- [Pass] **Earlier caller pins and B1 limitation retained.** T:767-797 reloads the driver-created record and checks verified OIDs/external MERGED retention; E:provenance.jsonl:20-21 retains caller-removal receipts. B:212-221 and M:1314-1318 retain repaired-file refresh; E:provenance.jsonl:23 explicitly defers its full B1 driver scenario. Keep that limitation in the PR: a broad gate alone cannot supply an absent scenario.

No other independent pre-existing implementation defect was identified during the sweep. The finding above includes the pre-existing initial-hold path as required by the whole-file review contract. No source change was made by this reviewer.

Probe P5: command below, exit **0**. It imports no repository module and runs no fixture or driver:
```sh
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 -B - <<'PYPROBE'
import ast
from pathlib import Path
p=Path('skills/2-daily/merge-cleanup/scripts/merge_cleanup.py')
tree=ast.parse(p.read_text())
loop=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='_land_prs_loop')
veto=next(n for n in ast.walk(loop) if isinstance(n,ast.If) and ast.unparse(n.test)=='veto')
blocked=next(n for n in ast.walk(loop) if isinstance(n,ast.Assign) and ast.unparse(n.targets[0])=='blocked_by')
discard=next(n for n in ast.walk(loop) if isinstance(n,ast.Expr) and ast.unparse(n)=='pending.discard(p_num)')
print('source_lines:', {'veto':veto.lineno,'dependency_check':blocked.lineno,'processed_discard':discard.lineno})
for reason in ('draft','do-not-merge','title: feat: x (do not merge: soak owed)'):
    env={'failed':{},'track':{'skips':{}},'p_num':7,'pending':{7,8},'veto':reason,'log':lambda *_:None}
    exec(compile(ast.Module(body=[discard]+[n for n in veto.body if not isinstance(n,ast.Continue)],type_ignores=[]),'actual-held-predecessor-snippets','exec'),env)
    env['pr']={'number':8,'_hard_deps':[7]}
    exec(compile(ast.Module(body=[blocked],type_ignores=[]),'actual-dependent-expression','exec'),env)
    print('predecessor_veto:',reason,'failed:',env['failed'],'skips:',env['track']['skips'],'dependent_blocked_by:',env['blocked_by'])
t=ast.parse(Path('test/gh436-merge-cleanup.py').read_text())
for name in ('test_late_draft_is_an_expected_skip_not_a_failed_run','test_late_hold_label_prevents_the_merge'):
    fn=next(n for n in ast.walk(t) if isinstance(n,ast.FunctionDef) and n.name==name)
    print(name,fn.lineno, 'assertions:',[ast.unparse(n) for n in ast.walk(fn) if isinstance(n,ast.Call) and ast.unparse(n.func).startswith('self.assert')])
PYPROBE
```
Decisive output:
```text
source_lines: {'veto': 1354, 'dependency_check': 1139, 'processed_discard': 1140}
predecessor_veto: draft failed: {7: 'draft'} skips: {} dependent_blocked_by: [7]
predecessor_veto: do-not-merge failed: {} skips: {7: "skipped: hold 'do-not-merge' at final eligibility"} dependent_blocked_by: []
predecessor_veto: title: feat: x (do not merge: soak owed) failed: {} skips: {7: "skipped: hold 'title: feat: x (do not merge: soak owed)' at final eligibility"} dependent_blocked_by: []
test_late_draft_is_an_expected_skip_not_a_failed_run 726 assertions: ['self.assertEqual(rc, 0)', 'self.assertFalse(merged.called)', 'self.assertTrue(self.pruner.called)']
test_late_hold_label_prevents_the_merge 738 assertions: ['self.assertEqual(rc, 0)', 'self.assertFalse(merged.called)', 'self.assertTrue(self.pruner.called)']
```

Handing off to Producer (claude-a) — disposition the held-predecessor finding, preserve the resolved evidence and B1 limitation, then open round 3 and request “take your turn” in the Reviewer window. STATUS remains Open.

### Producer · Round 2 · claude-a — adjudication

The [Should] **accepted and implemented**; commit "fix(GH-1140): fq2-r2".

- Held predecessors now stay in the dependency map at BOTH hold sites (the pre-existing initial-hold path and my final-eligibility branch — your whole-file contract applied): each hold writes `failed[p_num] = "hold: <marker>"` alongside its track skip, so `blocked_by` sees it; the end-of-loop classification filters `hold:` entries exactly like `draft` (logged as "Skipped held PR(s)", removed before the exit-3 decision) — a lone hold keeps rc 0 and Phase 6, while a blocked hard dependent is reported as not-landed.
- Your falsifier is pinned through the real harness: `test_held_predecessor_blocks_its_hard_dependent` — PR 8 with body "depends on #7", PR 7 held at final eligibility -> NEITHER merges (`merged.called` False), PR 8 reported "#8 (blocked by #7)", rc 3, PR 7 logged as a held skip. Red control witnessed: reverting the final-hold branch to track-skip-only (the r2 defect shape) fails the pin.
- Draft behavior unchanged (your P5 late-draft dependent case: drafts were already retained in `failed` during the loop).

Suite: 206 tests OK (26 GH-1140 pins; 13 red controls witnessed across the campaign). Provenance: 29 rows. Requesting round 3: approve or name residuals.

handing off to Reviewer (codex) — take your turn.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->


