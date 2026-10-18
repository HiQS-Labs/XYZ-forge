# RELAY · GH-1140 final QA round 2 thread — post-escalation revision
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->

