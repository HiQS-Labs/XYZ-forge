# RELAY · GH-1108 one-writer delivery1 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
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
6. **Commit only the relay file** (`relay(gh1108-one-writer-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: Runtime diff from b26c9edb73f61587a71287f68cb4338409188042 through d91f22ab; `PROJECT/2-WORKING/GH-1108-JOG-LAND-RECEIPTS.md`, `TESTS-RESULTS/2026-10-17+GH-1108/SUMMARY.md`, original portable bundles for GH1087/GH942, and all changed source/docs. Read whole touched source files; review only, no production edits.
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-17
- Definition of Done: Independent final QA against operator one-writer design and two-PR split. This delivery covers primary guard, disposable execution, committed portable evidence, mechanical stripped merge proof, and mapped merge-cleanup hook. Automatic transition push/retry is exclusively delivery2; manual pre-merge checkpoint and native auto-merge refusal are intentional interim behavior. Verify real fail paths, repo/root/identity ownership, bundle publication/recovery, old/plain/vendored compatibility, replay, B1 policy reuse and no new suites. Grade local operator tool scope and commensurate complexity, not unrequested enterprise threat models. Cited 223/34/180/8 focused suites ran at7551 with intact clone identity; later compatible branches/manual controls targetd91. Full push qualification is pending after QA; do not claim it ran. Historic primary checks currently use disposable primary with live GH data; actual machine-primary recovery is later, after review/qualification. Do not run suites or executable fixtures in reviewer worktree; use retained evidence and narrow nonmutating probes. Only this relay is writable.

## Terminal token protocol

Claim first as the shim instructs. Approval requires `TICK_REPO_ROOT="/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1108-jog-land-receipts-2026-10-17" "/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1108-jog-land-receipts-2026-10-17/bin/tick" done RELAY-gh1108-one-writer-final --agent codex`; do not release to Producer when approving. On findings, release to codex-producer. Never run git: the shim commits only this relay. Caps remain three review rounds.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL

Basis: The delivery-1 publication checkpoint is bypassable through a real legacy relay run. The native Marathon refusal works, but it is not a supervisor-wide refusal. No production state, source, or artifact was changed during this review; no Git command, suite, executable fixture, or network mutation was run.

swept file: no

Review coverage: read `utils/py/jog_run.py` and `utils/py/harness_paths.py`, traced the Jog writer guards and post-merge mapping/reconcile/publication seams in `releases_app.py`, `merge_cleanup.py`, and `ledger_merge.py`, and inspected the canonical plan, portable bundle manifests, provenance, retained logs and manual-control sources. The full-file sweep of those three larger supporting modules and the complete changed-file inventory remains outstanding; this is an early return with an observed blocker, not whole-artifact approval. The graph is XYZ-forge generation `2026-09-01T15:54:30Z`, rooted in a different checkout. Coverage reports changed metadata for Jog/releases and untracked metadata for the other modules; current source, not graph freshness, supports this finding. No exhaustive absence-of-defects claim is made about pre-existing supporting code.

- [Blocker] **Refuse real legacy auto-merge before leasing, too.** `utils/py/jog_run.py:1792` invokes the checkpoint refusal only when `executor == "marathon"`. With `executor="relay", simulate=False, dry_run=False, auto_merge=True`, the actual supervisor function reaches `jog_acquire_lease`. Downstream, `handle_landing_boundary` still calls `_merge_reviewed_pr` (`:1693–1709`), returns `completed` (`:1720`), and the supervisor can advance. This happens while the primary's lease/status transitions have no automatic publication in delivery 1. Existing attestation/head checks do not implement the missing primary publication checkpoint. The retained latest control (`TESTS-RESULTS/2026-10-17+GH-1108/compat-and-root-manual.py.txt:24`) calls the validator directly, so it does not exercise this routing gap.

  Observed input: `jog run --executor relay --auto-merge --builder codex --reviewer agy --target-root <valid-disposable-clone>` against a valid primary with one pending row. The non-mutating control below observes the lease boundary, with identity/DB/lock dependencies replaced in memory; it does not claim a real PR was merged.

  Affected scope: real supervisor dispatches with `auto_merge=True`, including the supported explicit legacy relay executor. Keep `--simulate` and `--dry-run` compatibility; keep the existing exact-head/attestation helpers intact. This asks for the delivery-1 refusal at the common dispatch entry, not delivery-2 publication machinery.

  Falsifier: the same real relay input must exit 2 with the publication-checkpoint explanation before lock/lease/doc/cache changes. The Marathon input must retain that refusal, and relay simulation/dry-run must retain their documented behavior. Reuse an existing covering suite or record a manual control in the disposable gate clone; do not add a suite. An observed pre-lease refusal for this real relay input would disprove this finding.

  Root cause: executor-specific validation owns a supervisor-wide interim policy; Fix site: the common real-dispatch validation in `jog_run_main`; Why not downstream: a merge-time refusal is too late to satisfy refusal before lease and leaves the policy split between executors.

  Probe command (exit **0**; AST-loaded seeded functions only, no module initialization, Git, DB writes, subprocess calls, real locks or dispatch):

  ```python
  # Run with: export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  # mkdir -p "$TMPDIR"; python3 - <<'PY'  [body below]  PY
  import ast, pathlib, types, os, sys
  p = pathlib.Path('utils/py/jog_run.py')
  tree = ast.parse(p.read_text())
  names = {'jog_run_main', 'validate_marathon_executor'}
  code = compile(ast.Module(body=[n for n in tree.body
      if isinstance(n, ast.FunctionDef) and n.name in names],
      type_ignores=[]), str(p), 'exec')
  class LeaseReached(Exception): pass
  class Conn:
      row_factory = None
      def execute(self, *a): return self
      def fetchone(self):
          return dict(id=1, global_id='probe-gid', gh_number=999901,
                      position=1, attempt_count=0)
      def close(self): pass
  class Lock:
      def __init__(self, *a): pass
      def acquire(self): pass
      def release(self): pass
  ns = dict(os=os, sys=sys,
      sqlite3=types.SimpleNamespace(connect=lambda *a: Conn(), Row=object),
      JogSupervisorLock=Lock,
      atexit=types.SimpleNamespace(register=lambda *a: None),
      signal=types.SimpleNamespace(SIGINT=2, SIGTERM=15, signal=lambda *a: None),
      _require_jog_primary=lambda *a: None,
      _execution_root=lambda *a: '/validated/disposable',
      jog_reconcile_orphan_leases=lambda *a: [],
      _ensure_jog_schema=lambda *a: None,
      JOG_RELAY_DEPRECATION_NOTICE='legacy notice', ContractError=Exception,
      subprocess=types.SimpleNamespace(CalledProcessError=RuntimeError),
      jog_acquire_lease=lambda *a: (_ for _ in ()).throw(LeaseReached()))
  exec(code, ns)
  a = types.SimpleNamespace(executor='relay', simulate=False, dry_run=False,
      auto_merge=True, root=os.getcwd(), target_root='/validated/disposable',
      builder='codex', reviewer='agy', max_tasks=1)
  for executor, simulate in [('marathon', False), ('relay', False), ('relay', True)]:
      a.executor = executor; a.simulate = simulate
      try: ns['jog_run_main'](a)
      except LeaseReached:
          print(f'executor={executor}, simulate={simulate}, auto_merge=True -> LEASE REACHED')
      except SystemExit as e:
          print(f'executor={executor}, simulate={simulate}, auto_merge=True -> REFUSED exit={e.code}')
  ```

  Decisive output:
  ```text
  executor=marathon, simulate=False, auto_merge=True -> REFUSED exit=2
  executor=relay, simulate=False, auto_merge=True -> LEASE REACHED
  executor=relay, simulate=True, auto_merge=True -> LEASE REACHED
  ```

- [Pass] **Retained evidence bytes are internally consistent.** A read-only Python hash probe (exit 0) checked all six nonempty files named by the two historical manifests, plus all four compressed focused-log hashes against `TESTS-RESULTS/2026-10-17+GH-1108/provenance.jsonl`, and compared the before/after identity JSON objects. Output: `bundle 1087 PR 1101 approved 088f5cd907d0e64007ec1b2f544351d8a157ce5f hashes OK`; `bundle 942 PR 1102 approved 6f521bc52aa07f1657e5ea6ef624b111bd8ad568 hashes OK`; `focused clone identity snapshots equal`; `nonempty portable files checked 6`. Citations: `TESTS-RESULTS/2026-10-16+GH-1087/jog/gh1087-exec1/receipt.json`, `TESTS-RESULTS/2026-10-17+GH-942/jog/gh942-exec2/receipt.json`, and the cited focused provenance. This verifies retained-byte consistency, not original-source equality or a new suite run.

- [Unverified — needs clone run] Full push qualification remains pending as explicitly stated in `TESTS-RESULTS/2026-10-17+GH-1108/SUMMARY.md`. The 223/34/180/8 results are retained Producer runs at `7551ca55`; the later compatibility control at `d91f22ab` does not cover real legacy dispatch. No gate was run here and no merge readiness is asserted.

Handing off to codex-producer — address the common-entry refusal, preserve simulation/dry-run and exact pre-merge checks, record the control in the disposable full clone, then return for Round 2 and the remaining whole-file sweep.

### Producer · Round 1 adjudication

Accepted the observed blocker. `9ec177d5` adds the interim publication-checkpoint refusal at the common real-dispatch entry; native validator keeps its direct-call contract. Both real Marathon and relay refuse before leases/locks/cache/doc changes. Simulation/dry-run remain excluded. Exact-head/attestation helpers are unchanged.

Recorded disposable-clone control: `TESTS-RESULTS/2026-10-17+GH-1108/auto-merge-entry-manual.py.txt` and `.log.txt`, with provenance. It executes the actual AST function bodies: prior `35ad8fda` real relay reaches the substituted lease boundary (red), fixed `9ec177d5` both real executors exit2 (green), simulation still reaches its lease boundary, and dry-run returns. No real locks, writes, or PR merges. Please complete the remaining whole-file sweep and final review. Full push qualification remains pending, intentionally after approval.

Handing off to codex — take Round 2; only this relay is writable. On approval tick done, not release.


### Reviewer · Round 2

VERDICT: FAIL

Basis: The Round 1 common-entry auto-merge refusal is corrected, but two supported legacy-relay branches still violate the new separate-clone / manual-publication boundary. These are local operator concurrency and landing contracts already required by this plan. No production file, Git command, suite, executable fixture, network request or real subprocess dispatch was used in the probe.

swept file: no

Coverage: read all of current jog_run.py and harness_paths.py, the merge-cleanup orchestrator through its Phase-6 flow, ledger_merge.py classification/replay/resolution, the Jog CRUD/low-level writer portion of releases_app.py, the updated canonical plan, retained summary and common-entry control. The complete releases_app.py sweep, remaining supporting-file tail and complete changed-file inventory remain outstanding; this is another observed-blocker return, not whole-artifact approval. No absence-of-pre-existing-defects claim is made for unswept portions. Graph project XYZ-forge remains generation 2026-09-01T15:54:30Z in another checkout; coverage reports metadata_changed for Jog/relay-drive and not_tracked for the actual skills/2-daily/merge-cleanup/scripts paths. Current source fallback supports the findings.

- [Pass] **Round 1 refusal is now common to both executors before mutation.** utils/py/jog_run.py:1795 checks real dispatch plus auto_merge before root/lock/lease work, independent of executor. The retained auto-merge-entry-manual.log.txt records prior real relay lease reach and fixed exit 2 for both real executors, with simulation/dry-run preserved. This closes the specific Round 1 finding; it does not establish the interactive branch below.

- [Blocker] **The interactive legacy landing branch still bypasses the primary publication checkpoint.** With auto_merge=False, a TTY and response Y, handle_landing_boundary reaches _merge_reviewed_pr and returns completed (utils/py/jog_run.py:1727–1763). jog_run_main calls it with target, then completes the primary queue row and can advance (:1985–1993). At this point the primary has acquired a lease and written queue state, and no checkpoint has required that primary state to be committed/pushed/clean. A Y to merging is not the plan's owned-state publication procedure. The new entry refusal only covers the flag, so this second merge route survives it.

  Observed input: executor relay, simulate=False, auto_merge=False, interactive stdin, input Y, valid legacy attestation/open PR. The AST probe below observes the actual seeded boundary reaching the substituted merge helper and returning (True, 'completed', None); it does not claim a remote PR was merged.

  Affected scope: real interactive legacy relay landing reached from the delivery-1 supervisor. Preserve simulation and the standalone exact-head/attestation helpers. Cheapest correction: have this supervisor landing route park with the primary-publication/merge-cleanup instruction too; do not add delivery-2 publication here.

  Falsifier: with the same TTY/Y input the delivery-1 supervisor must park before the merge helper and must not advance. Simulation should retain its current behavior. A control showing an actual enforced clean/published primary checkpoint before this route merges would disprove the finding.

  Root cause: the interim publication policy guards one dispatch option while the legacy landing boundary retains another merge-and-advance route; Fix site: the real legacy supervisor landing route; Why not downstream: the generic attestation merge helper has no primary publication context and should retain its existing exact-head contract.

- [Should] **Do not claim the target clone's driver lock is already held.** run_single_phase_drive sets RELAY_DRIVER_LOCKED=1 unconditionally (utils/py/jog_run.py:1559–1561). Its caller now passes the separate target clone (:1970–1976), while JogSupervisorLock was acquired against the primary (:1861–1862). relay_drive.py:506 skips its entire target lock acquisition for that value, including the live-holder refusal at :537–540. Thus the supported legacy path can run beside an existing target driver. The native Marathon path already removes this bypass, as the plan requires.

  Observed input: run_single_phase_drive('/validated/disposable', 999901, builder='codex', reviewer='agy', simulate=False) with inherited RELAY_DRIVER_LOCKED=1 from the primary supervisor. The seeded function passes env value '1' to the captured target dispatch.

  Affected scope: legacy relay dispatch into the separately validated full target clone. Its primary lock cannot confer ownership of that clone's independent .git/relay-driver.lock.

  Falsifier: dispatch must omit the bypass and the existing target driver's live lock must refuse the second run. An absent/stale target lock must still permit ordinary acquisition. Record that control in the disposable full clone with existing machinery; no new suite. Evidence that the primary and target genuinely share the same lock would disprove this finding, but _execution_root explicitly requires separate full clones.

  Root cause: the old same-clone nesting assumption survived the execution-root split; Fix site: run_single_phase_drive's child environment; Why not downstream: relay-drive's nested-driver bypass is valid when a caller actually owns that same root's lock.

Probe command: export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 - <<'PY' (body below). Exit **0**. This compiles only the two seeded function definitions; filesystem mutations, process execution, tick and merge helpers are replaced in memory.

```python
import ast, pathlib, types, os, datetime, tempfile, re
p = pathlib.Path('utils/py/jog_run.py')
tree = ast.parse(p.read_text())
names = {'run_single_phase_drive', 'handle_landing_boundary'}
nodes = [n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name in names]
events = []
def run(argv, **kw):
    if '--agent-cmd' in argv:
        events.append(('dispatch', kw['cwd'], kw['env'].get('RELAY_DRIVER_LOCKED')))
    return types.SimpleNamespace(returncode=0, stdout='123', stderr='')
ns = dict(os=types.SimpleNamespace(
    path=types.SimpleNamespace(join=os.path.join, isfile=lambda p: True),
    access=lambda *a: True, X_OK=os.X_OK, makedirs=lambda *a, **kw: None,
    environ={'RELAY_DRIVER_LOCKED': '1'}, getpid=lambda: 42),
    _dt=datetime, tempfile=tempfile, re=re, subprocess=types.SimpleNamespace(run=run),
    find_issue_doc=lambda *a: None,
    sys=types.SimpleNamespace(stdin=types.SimpleNamespace(isatty=lambda: True)),
    input=lambda *a: 'Y',
    _legacy_attestation=lambda *a: ({'task':'probe'}, None),
    _verify_legacy_pr_before_merge=lambda *a: [],
    _merge_reviewed_pr=lambda *a: (events.append(('merge-helper-reached',)) or (True, None)))
exec(compile(ast.Module(body=nodes, type_ignores=[]),str(p),'exec'),ns)
ns['run_single_phase_drive']('/validated/disposable',999901,builder='codex',reviewer='agy')
print('legacy dispatch observed:',events[-1])
print('receiver lock condition:',next(l.strip() for l in pathlib.Path('utils/py/relay_drive.py').read_text().splitlines() if 'if get_env("RELAY_DRIVER_LOCKED"' in l))
events.clear()
print('interactive landing result:', ns['handle_landing_boundary']('/validated/disposable',999901,auto_merge=False,reviewer='agy',simulate=False))
print('interactive landing observed:',events)
```

Decisive output:
```text
legacy dispatch observed: ('dispatch', '/validated/disposable', '1')
receiver lock condition: if get_env("RELAY_DRIVER_LOCKED", "0") != "1":
interactive landing result: (True, 'completed', None)
interactive landing observed: [('merge-helper-reached',)]
```

- [Unverified — needs clone run] Full push qualification remains pending. No suites or gate were run in this worktree, and no merge-readiness claim is made.

Handing off to codex-producer — address the interactive checkpoint route and target lock ownership, retain simulation and exact-head helpers, record focused controls in the disposable full clone, then return for Round 3 and the outstanding whole-artifact sweep.

### Producer · Round 2 adjudication

Accepted both concrete findings. `4015cfb9` and `bea9d480` park real legacy execution at the supervisor's primary publication checkpoint instead of entering either merge route. Simulated behavior and standalone exact-head/attestation helpers remain intact. Real legacy dispatch removes the inherited lock bypass, reuses the native root environment helper, and checks the same target ledger-byte invariant.

Recorded `legacy-boundary-manual.py.txt` / `.log.txt` under the GH1108 evidence directory: prior supervisor reaches the substituted interactive merge helper and completes; fixed supervisor parks without the helper. Old dispatch passes inherited lock1/ambient primary; fixed dispatch omits bypass and pins target. The actual existing relay driver in a separate full clone refuses a live target holder, then reclaims a stale lock and handles an absent lock via model-free dry runs, cleaning up both. All pass; provenance retained.

The full gate still running at9ec exposed the inventory ratchet's new direct SQLite site. Rather than exempt it or widen a baseline, the hook now reuses B1's qualified dump parser; the landing read uses releases_app.connect(readonly=True), with URI-quoted paths. `gateway-inventory-manual` records prior ratchet red/current green and actual readonly write refusal. `review-fix-one-writer-manual` repeats the complete prior one-writer checks againstbea9, including the actual mapped hook, existing post-merge publication, cache-independent landing, failure controls and real GH942 merge proof; all pass. No new suites or gate machinery.

Please complete the remaining whole-artifact sweep and review the final source throughbea9d480. Full gate final-source qualification and machine-primary historical recovery remain pending, not claimed. Only this relay is writable. This is Round3 of3; record the concrete verdict and evidence limits. On approval tick done as specified.

Handing off to codex for Round3.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
