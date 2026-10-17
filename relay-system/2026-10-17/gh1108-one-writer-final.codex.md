# RELAY · GH-1108 one-writer delivery1 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
-->

NEXT: Producer
STATUS: Approved
ROUND: 4 / 4

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

### Producer · Round 2 supplement before resumed Round3

The initial Round3 dispatch was interrupted before producing any review block or verdict so we could fold in independently arriving Opus findings. No code was edited while that driven turn was active. The token was handed back by the shim. This resumes the same third review round, not a fourth verdict cycle.

`03fb2fd9` additionally fixes three Opus Should findings: executed --reconcile-pr now reuses the same final publisher; terminal queue rows do not pull unrelated follow-ups into Jog; and runtime capability is checked beside the exact resolved releases CLI instead of the skill's B1 policy copy. Actionable pending/running/failed/parked mapped rows still must pass land and valid committed evidence; missing receipts refuse as operator requirement5 specifies. Comments and clone-ledger-changed cache state were corrected too.

`merge-hook-review-manual.py.txt` / `.log.txt` retain actual prior recovery exit0/dirty (red) and fixed real queue completion/publication clean at origin (green), prior terminal follow-up land invocation/refusal versus fixed skip, and old vendored consumer invoked by prior capability check versus fixed pre-writer refusal. Manual controls in disposable primary use real Git/release writer/check/landing/publisher, fixture GH and stubbed unrelated issue-doc-sync only. Provenance and actual Opus5.5-high round1 model receipt retained. Please review final source through03fb2fd9 plus these controls, and complete remaining whole-file sweep. Final full gate and machine-primary historical recovery remain pending, not claimed.

Handing off to codex for resumed Round3; only this relay writable. Approval must tick done, as specified.


### Reviewer · Round 3

VERDICT: FAIL

Basis: The prior supervisor findings are addressed, but the revised post-merge hook silently skips an actionable Jog row for a supported multiline reason. This violates requirement 5 even when the canonical dump is valid. The three-round cap is reached: STATUS is Escalated, not Approved. No Git command, suite, pytest, executable fixture, real writer, network request or source/artifact edit was run here.

swept file: no

Coverage: read current jog_run.py, harness_paths.py and ledger_merge.py; examined merge-cleanup's mapping, normal landing, recovery, final publisher and teardown flows, the releases writer/guard/CRUD/dump/parser seams, canonical plan, retained manual controls and provenance. The remaining whole releases_app.py sweep, whole marathon_drive.py sweep and independently established complete changed-file inventory remain outstanding. No whole-artifact approval or absence-of-pre-existing-defects claim is made. The finding below is a pre-existing limitation of B1's classifier newly promoted into an authoritative queue reader. Graph lookup used XYZ-forge generation 2026-09-01T15:54:30Z in another checkout; graph search returned no relevant matches, and coverage reports metadata_changed/not_tracked for the relevant paths. Current source fallback supports the findings; the graph does not establish freshness or completeness.

- [Blocker] **Use a complete canonical reader for Jog mapping; B1's line classifier loses valid rows.** `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:631–635` treats B1's parsed `jog_queue` as authoritative. `ledger_merge.py:107–112` processes individual lines and puts unmatched content into `other`; the hook ignores `other`. The canonical writer `_sql_str`/`_emit` preserves newlines inside SQL strings (`utils/py/releases_app.py:1077–1093`), and its actual `parse_dump` accumulates multiline statements (`:5990–6024`). Consequently, changing only an actionable row's reason to contain a newline makes the hook omit that row and return success without `jog land`. A prior clean `releases check` does not establish completeness of this different parser.

  Observed input: the actual seeded GH-942 failed queue row from `releases.sql:888`, with only `failure_reason` changed in memory to the supported value `"gate failed\nretry required"`, re-emitted by the actual canonical `_emit`, and PR identity `1102`, body `Fixes #942`. The canonical parser still returns that row; the hook's reader does not. A single-line reason on the same row reaches land. `cmd_jog_skip` accepts `args.reason` without a one-line restriction (`utils/py/releases_app.py:4756–4795`); low-level `jog_set_status` also accepts this value (`:4878–4912`). The probe substitutes the external land call and filesystem/GitHub reads, so it measures routing, not a remote merge or actual queue transition.

  Affected scope: actionable queue rows whose canonical INSERT spans lines, demonstrated specifically with a multiline `failure_reason`. Keep terminal-row skipping and the mapped-row evidence requirement. Do not turn an incomplete extraction into “no Jog row”.

  Falsifier: for the same canonical GH-942 row and mapped PR, both the single-line and multiline versions must reach the same committed-receipt landing path; missing/invalid receipt must refuse, rather than silently skip. A normal non-Jog PR and terminal rows must retain their skip behavior. Evidence that the canonical writer rejects or normalizes this exact multiline value would disprove the finding; the actual emitter/parser control below shows the opposite. Record a red/green manual control in the disposable full clone or use existing coverage; no new suite.

  Root cause: a conservative B1 classification parser (which can preserve unsupported text in `other`) is used as a complete row reader without checking that contract. Fix site: the hook's queue-reading seam. Why not upstream/downstream: rejecting valid multiline reasons would unnecessarily change the writer contract, and downstream land cannot check a row it is never asked to land. Reuse an existing complete authoritative reader (for example the existing root-bound read-only Jog JSON interface or canonical dump reader), rather than adding a second parser or raw SQLite writer site. Preserve the inventory ratchet.

  Probe command (exit **0**; AST-loaded seeded definitions, in-memory canonical dump and substituted external dependencies only):

  ```python
  # export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
  # mkdir -p "$TMPDIR"; python3 - <<'PY' [body below] PY
  import ast, pathlib, re, types, json, sys
  from typing import Any, Dict, List, Optional

  def seeded(path, names, ns):
      tree = ast.parse(pathlib.Path(path).read_text())
      nodes = [n for n in tree.body
          if (isinstance(n, ast.FunctionDef) and n.name in names)
          or (isinstance(n, ast.Assign) and any(
              isinstance(a, ast.Name) and a.id in names for a in n.targets))]
      exec(compile(ast.Module(body=nodes, type_ignores=[]), path, 'exec'), ns)

  writer = {'re': re}
  seeded('utils/py/releases_app.py',
      {'_sql_str', '_emit', 'INSERT_RE', '_split_values', '_value', 'parse_dump'}, writer)
  b1 = dict(re=re, Any=Any, Dict=Dict, List=List, Optional=Optional)
  seeded('skills/2-daily/merge-cleanup/scripts/ledger_merge.py',
      {'_INSERT_RE', '_split_values', 'parse_dump'}, b1)
  original = pathlib.Path('releases.sql').read_text()
  rows = writer['parse_dump'](original)['jog_queue']
  row = next(dict(r) for r in rows if r['gh_number'] == '942')
  line = next(l for l in original.splitlines()
      if l.startswith('INSERT INTO jog_queue') and row['global_id'] in l)

  class Root:
      def __truediv__(self, name): return self
      def is_file(self): return True
      def read_text(self, **kw): return dump
      def __str__(self): return '/validated/primary'

  events = []
  policy = types.SimpleNamespace(
      github_slug_from_origin=lambda _: 'HiQS-Labs/XYZ-forge',
      require_primary=lambda _: None)
  ns = dict(Path=pathlib.Path, LEDGER_DUMP='releases.sql', sys=sys, re=re, json=json,
      ledger_merge=types.SimpleNamespace(parse_dump=b1['parse_dump'],
          harness_paths_module=lambda *a, **kw: policy),
      tool_path=lambda *a: pathlib.Path('/seeded/utils/py/releases_app.py'),
      linked_issues=lambda pr: [942], log=lambda _: None, log_err=print,
      _gh=lambda *a, **kw: types.SimpleNamespace(returncode=0,
          stdout=json.dumps({'body': 'Fixes #942'})),
      subprocess=types.SimpleNamespace(run=lambda argv, **kw:
          (events.append(argv) or types.SimpleNamespace(
              returncode=0, stdout='captured land', stderr=''))))
  seeded('skills/2-daily/merge-cleanup/scripts/merge_cleanup.py',
      {'run_jog_post_merge_land'}, ns)
  for reason in ['gate failed', 'gate failed\nretry required']:
      row['failure_reason'] = reason
      emitted = []
      writer['_emit'](emitted.append, 'jog_queue', list(row), [row])
      dump = original.replace(line, emitted[1])
      events.clear()
      canonical = writer['parse_dump'](dump)['jog_queue']
      parsed = b1['parse_dump'](dump)['tables'].get('jog_queue', {})
      result = ns['run_jog_post_merge_land'](1102, Root())
      print('reason=', repr(reason),
          'canonical942=', sum(r['gh_number'] == '942' for r in canonical),
          'hook942=', sum(r['gh_number'] == '942' for r in parsed.values()),
          'hook_result=', result, 'land_calls=', len(events))
  ```

  Decisive output:
  ```text
  reason= 'gate failed' canonical942= 1 hook942= 1 hook_result= True land_calls= 1
  reason= 'gate failed\nretry required' canonical942= 1 hook942= 0 hook_result= True land_calls= 0
  ```

- [Pass] **Prior interactive-merge and target-lock findings are closed at the supervisor seam.** `utils/py/jog_run.py:1993–2001` parks real legacy execution without entering `handle_landing_boundary`; `:1559–1565` removes `RELAY_DRIVER_LOCKED` and pins the target environment. `TESTS-RESULTS/2026-10-17+GH-1108/legacy-boundary-manual.log.txt` retains the prior merge/completion versus fixed park, and live/stale/absent target-lock controls. This closes those concrete findings, not all legacy compatibility claims.

- [Pass] **The three supplemental fixes have source and retained red/green support.** `merge_cleanup.py:1512–1514` calls the existing final publisher after executed recovery; `:632–633` limits mapping to actionable statuses; `:651–655` checks capability beside the exact resolved releases CLI. `merge-hook-review-manual.log.txt` records old recovery exit0/dirty versus fixed clean-at-origin publication, terminal follow-up skips, and old-runtime pre-writer refusal. These passes are limited to those controls and do not establish the multiline mapping case above.

- [Pass] **Retained evidence integrity checks pass.** A read-only Python probe (exit 0) read each provenance JSON line, loaded its named nonempty artifact, decompressed where `sha256_uncompressed` was specified, and asserted SHA-256 equality for `sha256_output`/`sha256_uncompressed`/`sha256`; it also compared the focused identity JSON objects. Output: `nonempty retained provenance hashes matched: 13`; `focused identity snapshots equal`. Citations: `TESTS-RESULTS/2026-10-17+GH-1108/provenance.jsonl`, `final-focused-identity-before.json`, `final-focused-identity-after.json`. This is retained-byte consistency, not a new gate or original-source equality claim.

- [Unverified — needs clone run] Full final-source push qualification and machine-primary historical recovery remain pending, as the canonical plan/SUMMARY explicitly state. The retained focused suites ran at 7551ca55; later manual controls do not substitute for final full qualification. No gate was run here and no merge readiness is asserted.

Handing off to codex-producer — the relay is Escalated at the three-round cap. Address the concrete canonical-reader mismatch with recorded red/green evidence, then obtain an authorized continuation/new independent review to finish the outstanding sweep and qualification. No approval or merge authorization is given.

### Producer · Operator-authorized Round4

Operator instruction: "Round 4 authorized by the operator as an exception to the three-round cap, scoped to the multiline queue-reader defect from round 3." The exact same sentence is committed in the capture doc. User explicitly says: one additional Codex final-review round; if not Approved, stop and hand off, no fifth. We retain this same relay/token and all prior findings; this is an explicit exception, not a reset/relabel of the budget.

Accepted Round3's concrete defect. At e088456e, run_jog_post_merge_land uses existing root-bound releases CLI `--root <primary> jog list --all --json` as its canonical reader. No new parser, SQLite connection, writer or test suite. Actionable pending/running/failed/parked rows are mapped; terminal and unrelated PRs skip. Failed/malformed extraction refuses instead of treating it as an empty queue. The exact selected runtime's capability check remains before land.

Red/green control in round4-canonical-reader-manual.{py,log}.txt uses actual canonical writer-generated failure reasons. Prior B1 parser skips newline row (returns success with0 land calls); fixed reader reaches land for both single-line and newline rows and refuses missing approval, with unchanged DB bytes. Terminal904/completed275/unrelated999980 skip; malformed object/nonJSON/failed reader refuse. Actual mapped recovery, releases check, committed landing and existing final publisher are repeated through the canonical reader in round4-merge-hook-manual: clean at origin, disposable primary/local bare remote; fixture GH and unrelated issue-doc-sync only are stubbed.

The two discussed existing fixtures were updated: gh436 mocks/asserts the required final publisher, gh605 uses a real pinned development primary. The diagnostic gate had also revealed gh290/gh291's older primary/cache assumptions; those existing contract fixtures now use the primary pin/committed bundle and truthful first-failing evidence boundary. No new files or registry entries; no assertions waived. gh60528tests, gh29037checks (including115 loader variations), gh29120checks pass. At7dc gh436 ran180:179 pass, one macOS /var vs /private assertion fails; test-only007a14ad corrects that to primary.resolve(), and the actual same existing case passes on current gate clone. This is179+corrected-case evidence, not a claimed180/180 run. Before/after clone identity is unchanged. Inventory clean.

Final source through007a14ad (later commits only review/evidence metadata). Scope of this exceptional fourth review is the operator's concrete multiline-reader closure and directly affected caller/fixture regressions, assessed against existing requirements and retained prior passes. Do not expand it into a new exhaustive audit of unchanged Marathon modules. Preserve truthful coverage limits rather than claiming unseen files were swept. Read whole affected mapping/caller functions, canonical JSON producer, and fixture changes. Confirm failure remains closed and tests substantiate the fix; issue concrete final findings or Approved within this single authorized turn.

Full final-source gate and actual machine-primary historical re-land remain pending until approval/qualification, not claimed. Original bundles, stripped-merge mechanical proof, qualified plan QA and earlier source/evidence remain under review context. Operator also authorizes PR2 as a draft stack targeting development, depends on PR1; rebase after PR1 lands before any PR review. No merges.

Handing off to codex for exactly Round4. On approval tick done as specified, not release. No fifth turn is authorized.

### Producer · Final Round4 input supplement

We waited for the last configured Opus round before dispatching this unique Codex4 turn. Opus3 confirmed the multiline closure and S4 fixture but observed B5 in actual pre-Jog consumers: DB exists but old CLI has no jog command, so the replacement reader would stop unrelated merge-cleanup runs. At5f223ca3 the bounded reader fix preserves them: require a nonempty qualified dump, skip only when neither canonical `-- table: jog_queue` marker nor `INSERT INTO jog_queue(` surface exists. This is a presence check only, NOT an incomplete parsed row-count test; newline rows still go through the canonical JSON reader and failures still refuse.

round4-pre-jog-compat-manual.{py,log}.txt copies the actual pre-Jog firebase-AI-reports DB/dump/CLI into a disposable root: prior reader refuses, fixed hook succeeds without invoking CLI or changing any bytes. A declared queue with unsupported reader still refuses, and an empty dump refuses before absence is claimed. Original consumer untouched. round4-canonical-reader-final.log.txt repeats actual single/newline routing, terminal/unrelated skip and malformed/failed-reader refusal at5f; all pass. This is directly the compatibility seam of the replacement reader, not unrelated scope expansion.

Opus3 is Escalated at its own cap; model receipts and full graded findings retained, no approval claimed. We implemented its B5 before this authorized Codex round instead of taking another Opus turn. Current final runtime is5f223ca3 (later commits only relay/evidence/capture metadata). No new suites/files/registry, no writer duplication. Please assess this final complete bounded closure and existing fixture controls in your one authorized Round4; Approved or concrete failure, then stop. No fifth is authorized.

Handing off to codex for the single operator-authorized Round4. Tick done on approval, not release.

### Reviewer · Round 4

VERDICT: PASS

Basis: Ship with the already scheduled qualification still pending. The operator-authorized bounded continuation closes Round3's multiline-reader defect and the replacement reader's pre-Jog compatibility regression. No further Blocker or Should was found in the affected functions and fixture changes examined. Approved applies to this explicitly bounded final review, using the retained earlier dispositions; it is not a new exhaustive audit or merge authorization.

swept file: no

Coverage: read the complete current `run_jog_post_merge_land`, `run_post_merge_reconcile`, `commit_and_push_phase5_writes`, canonical `cmd_jog_list` and connection helper; inspected both normal and recovery caller paths, linked-issue mapping, gh436's affected publisher fixture, gh605's lifecycle fixture, gh290's primary/bundle setup and refusal assertions, and gh291's primary/future-schema control. Read the retained Round4 manual sources/logs, focused results and provenance. No additional pre-existing defect was found within those inspected functions. The earlier outstanding whole releases_app.py / marathon_drive.py sweeps and independently complete inventory remain unperformed; the explicit Round4 scope does not reopen them or claim they happened. Graph project XYZ-forge is rooted in another checkout, generation 2026-09-01T15:54:30Z; symbol lookup and coverage were used, but current source fallback supports this review because material paths are metadata_changed/not_tracked. No graph completeness claim.

- [Pass] **Multiline actionable rows reach the committed-receipt landing boundary.** `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:639–652` uses the existing root-bound `jog list --all --json` reader, checks extraction, and selects actionable statuses. `utils/py/releases_app.py:4574–4615` queries complete SQLite row values and JSON-encodes them without splitting SQL lines. `round4-canonical-reader-final.log.txt` retains the actual canonical writer/reader red-green at5f223ca3: prior newline input returns success with0 land calls, fixed single-line and newline inputs each reach land and refuse missing approval, with unchanged DB bytes. The correction reuses the existing reader and writer rather than extending B1's deliberately conservative classifier. No further fix requested.

- [Pass] **Pre-Jog compatibility and failed extraction remain distinct.** `merge_cleanup.py:629–638` requires nonempty dump bytes and skips only when both canonical Jog surfaces are absent; this presence check does not count parsed rows. `round4-pre-jog-compat-manual.py.txt` and `.log.txt` retain the actual old-consumer-copy red/green: old hook refuses unsupported Jog, fixed hook invokes no CLI and changes no bytes; a declared queue with that unsupported reader still refuses, and empty dump refuses. Terminal/unrelated skip and nonJSON/object/failed-reader refusal are retained in `round4-canonical-reader-final.log.txt`. No blanket error suppression was introduced. No further fix requested.

- [Pass] **Both caller paths retain the publication boundary.** Normal processing gates reconciliation before publication and next-PR advancement (`merge_cleanup.py:1304–1316`); executed recovery calls the same publisher (`:1521–1530`). `round4-merge-hook-manual.log.txt` records real disposable-primary queue completion and clean-at-origin publication through the replacement reader, using fixture GH and a stub for unrelated issue-doc-sync. It also retains the old recovery's dirty exit0 control. `test/gh436-merge-cleanup.py:375–384` now mocks and asserts the required publisher call with the resolved primary instead of accidentally pushing its synthetic primary. No further fix requested.

- [Pass] **Fixture adaptations preserve meaningful failure assertions.** `test/test_gh605_work_state.py:373–384` establishes a real development primary; `test/gh290-ate-variation-grid.sh:453–460,494–522` pins the primary and commits evidence for the hostile landing variations, with refusal/untouched-row assertions still present; `test/gh291-contract-goldens.sh:283–320` preserves future-schema refusal, zero Tick mutation and parked bookkeeping. Retained focused logs report28 tests OK,37 pass/0 fail and20 pass/0 fail respectively. The gh436 evidence remains179 of180 plus the corrected existing case passing, not a claimed180/180 final run. No new suite or registry is needed for this closure. No further fix requested.

- [Pass] **Independent non-mutating routing probe agrees with retained controls.** Command: `export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; mkdir -p "$TMPDIR"; python3 - <<'PY'` using the following in-memory AST probe; exit **0**. It executes only the seeded hook function with substituted filesystem, runtime policy, GitHub and subprocess dependencies, not a real CLI/writer/merge. Its newline case is routing evidence, complemented by the retained actual canonical-reader controls above.

```python
import ast,json,pathlib,re,sys,types
p=pathlib.Path('skills/2-daily/merge-cleanup/scripts/merge_cleanup.py')
f=next(n for n in ast.parse(p.read_text()).body
       if isinstance(n,ast.FunctionDef) and n.name=='run_jog_post_merge_land')
class Root:
 def __truediv__(self,k): return self
 def is_file(self): return True
 def read_text(self,**kw): return dump
 def __str__(self): return '/probe/primary'
calls=[]
def run(argv,**kw):
 calls.append(argv)
 return types.SimpleNamespace(returncode=0 if 'list' in argv else 2,
     stdout=payload if 'list' in argv else '',stderr='missing approval')
policy=types.SimpleNamespace(github_slug_from_origin=lambda r:'owner/repo',
                             require_primary=lambda r:None)
ns=dict(Path=pathlib.Path,LEDGER_DUMP='releases.sql',sys=sys,json=json,re=re,
 subprocess=types.SimpleNamespace(run=run,TimeoutExpired=TimeoutError),
 tool_path=lambda *a:pathlib.Path('/runtime/releases_app.py'),
 ledger_merge=types.SimpleNamespace(harness_paths_module=lambda *a,**kw:policy),
 _gh=lambda *a:types.SimpleNamespace(returncode=0,
                                    stdout=json.dumps({'body':'Fixes #942'})),
 linked_issues=lambda p:[942],log=lambda x:None,log_err=lambda x:None)
exec(compile(ast.Module(body=[f],type_ignores=[]),str(p),'exec'),ns)
for label,dump,payload,want,lands in [
 ('newline actionable','-- table: jog_queue',json.dumps([{'gh_number':942,
   'status':'failed','failure_reason':'gate failed\nretry required'}]),False,1),
 ('terminal','-- table: jog_queue',json.dumps([{'gh_number':942,
   'status':'completed'}]),True,0),
 ('malformed reader','-- table: jog_queue','{}',False,0),
 ('pre-Jog','-- table: repos','unused',True,0),
 ('empty dump','','unused',False,0)]:
 calls.clear(); result=ns['run_jog_post_merge_land'](1102,Root())
 n=sum('land' in a for a in calls)
 assert (result,n)==(want,lands),(label,result,n)
 print(label,': result=',result,'land_calls=',n,
       'reader_calls=',sum('list' in a for a in calls))
```

Decisive output:
```text
newline actionable : result= False land_calls= 1 reader_calls= 1
terminal : result= True land_calls= 0 reader_calls= 1
malformed reader : result= False land_calls= 0 reader_calls= 1
pre-Jog : result= True land_calls= 0 reader_calls= 0
empty dump : result= False land_calls= 0 reader_calls= 0
```

- [Pass] **Retained evidence integrity.** Read-only command `python3 - <<'PY'` loaded every JSONL provenance row, read its named artifact, asserted nonempty bytes, decompressed for sha256_uncompressed, compared hashlib.sha256 to sha256_output/sha256_uncompressed/sha256, and compared the two Round4 focused identity JSON objects; exit **0**. Decisive output: `nonempty retained provenance hashes matched: 25`; `round4 focused identity snapshots equal`. Citations: `TESTS-RESULTS/2026-10-17+GH-1108/provenance.jsonl` and `round4-focused-identity-{before,after}.json`. This establishes retained-byte consistency, not a new gate run or independent historical source equality.

- [Unverified — needs clone run] Full final-source qualification and actual machine-primary historical recovery remain pending as recorded in SUMMARY and the Producer handoff. No suite, pytest, executable fixture or Git command ran in this reviewer worktree. Only this relay was edited; no source or artifact was changed. Approved closes the authorized review; it does not waive those remaining steps, establish whole-artifact coverage, or authorize a merge.

Relay closed (Approved), no further reviewer turn needed. Producer proceeds with the already required disposable-clone qualification and authorized downstream work; no fifth review turn is authorized.


### Attestation · relay-drive — 2026-10-17T15:03:27Z
task: RELAY-gh1108-one-writer-final
reviewer: codex
status: Approved
reviewed-head: 64c02e8de2c6fc28cf13498951bacc57c92ca6e2
added-range: 43157+8654
added-sha256: 2e826aab2080243e5da500ccf03caccd34f31e716608abe427db811b01fbb96c
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
