---
title: Timeout diagnostics overclaim lock waits and useful progress
status: active
created: 2026-11-16
updated: 2026-11-16
owner: noel
gh_issue: 1506
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1506
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: false
reported_from: XYZ-forge
harness_commit: 0d1dc0fe8395b4f0fc58280fc32b86d4957d47d9
non_goals:
  - Change PR 1491 or claim independent review approval
  - Raise time limits or run live inference
goal: Report observed activity and timeout causes without inferring contention or useful progress from filenames, logging or static dirty state.
---

# GH-1506 — Timeout diagnostic overclaims

## Status

| Phase | Status |
| --- | --- |
| Plan QA | Approved, Claude round 2 |
| Implementation and verification | In progress |
| Final QA and publication | Pending |

Unstarted intake; no ledger row or execution admission. Runtime: Python.

## Summary
Timeout diagnostics overstate what their signals prove: an open filename is reported as lock contention, log-only writes are called useful agent progress, and a static dirty-file count is labelled progress. This is a separate diagnostic defect report, discovered during PR #1491 review; it is not a supervisor defect or review verdict.

## Observed
Model-free component reproduction ran twice on macOS on 2026-11-16; both repetitions passed all assertions. No inference, network effects from fixtures, real queue, or runtime source mutations.

| Claim / probe | Observed |
|---|---|
| Actual `_probe_idle_blocker` extracted unchanged from AST; real child opens `innocent.lock` without flock/fcntl or any competing process | Returns `lock` and asserts it was waiting on someone else's lock, not working |
| Actual `TurnDiagnostics.classify`, controlled zero-CPU samples; unchanged source and no log update | `timeout-unclassified`, `worktree-progress=no` |
| Same classifier with only `temp/transport.log` written, mtime advanced explicitly | `timeout-slow-but-progressing`, `worktree-progress=yes`, recommends raising budget |
| Real git status in disposable repository containing two unchanged untracked scaffolds; sampled twice | Counts `[2, 2]`; source emits these counts as `GH-370 progress` without temporal comparison |

Tested head: `0d1dc0fe8395b4f0fc58280fc32b86d4957d47d9`. All three diagnostic source files were independently fetched from development `f346d8908a42cd6e7e92f80657f9e7a21208e0ae` and are byte-identical to tested files. Thus this is not introduced by PR #1491.

## Source and interpretation
- [agy-turn.py probe](https://github.com/HiQS-Labs/XYZ-forge/blob/f346d8908a42cd6e7e92f80657f9e7a21208e0ae/utils/py/agy-turn.py#L95): substring `.lock` in lsof output is treated as proof of contention. A filename, including a known harness path, does not prove waiting or ownership.
- [wall-cap branch](https://github.com/HiQS-Labs/XYZ-forge/blob/f346d8908a42cd6e7e92f80657f9e7a21208e0ae/utils/py/agy-turn.py#L516) invokes the probe even for wall timeout, then prints both attributions at lines 600–623. This connection is source-inspected, not a new end-to-end stub CLI reproduction.
- [mtime scan](https://github.com/HiQS-Labs/XYZ-forge/blob/f346d8908a42cd6e7e92f80657f9e7a21208e0ae/utils/py/turn_diagnostics.py#L309) includes log/scratch paths; classifier at line 511 interprets their timestamps as useful writing. Controlled samples prove this classification, not that an actual idle watchdog was bypassed. Intentional transcript-progress callers must retain their semantics.
- [driver dirty count](https://github.com/HiQS-Labs/XYZ-forge/blob/f346d8908a42cd6e7e92f80657f9e7a21208e0ae/utils/py/relay_drive.py#L958) reports a snapshot as progress. A dirty count can be useful state but is not activity evidence.

The real Agy review logs contained contradictory lock/slow-progress assertions. Recorded tool calls establish that Agy was reading and checking evidence until its cap; they do not establish review completeness. The matched lsof path was not retained, so this report does not identify which file triggered that historical lock message.

## Impact and scope
Medium operational severity: misleading diagnosis can send operators into unnecessary lock cleanup, authentication changes or budget increases. No data loss, actual deadlock, production supervisor defect, or budget-limit bypass is demonstrated. Keep wall-time limits intact. This report authorizes no implementation or new live-model experiment.

Related prior art: #114 (original blocker attribution), #608 (active remote work can look locally idle), #648 (timeout family), #1126 (deterministic timeout sampling). These existing records address adjacent behavior; this report supplies the benign-open-file, log-only-write and static-dirty-count witnesses.

## Acceptance
- [ ] An open `.lock` file alone never asserts contention or inactivity; retain bounded sanitized observation metadata and uncertainty.
- [ ] Distinguish which limit fired from what activity was actually observed; do not emit incompatible unsupported causes.
- [ ] Harness logging alone cannot establish useful work progress or justify increasing a budget; preserve intentional per-transcript progress inputs.
- [ ] Static dirty-file counts are labelled as state, or activity claims use a measured change with declared limitations.
- [ ] Repeat model-free positive/negative controls through existing coverage or recorded manual probes; retain normal timeout and process cleanup behavior.

## Preflight Contract
Draft intake only; not execution-ready. Exact repair/gate contract requires pickup and scoped recon.
```json
{"target":"HiQS-Labs/XYZ-forge","gate":null,"fix_probes":[],"artifacts":["utils/py/agy-turn.py","utils/py/turn_diagnostics.py","utils/py/relay_drive.py"],"ready":false}
```

## PRS proposal
pri 55: repeated review recovery was misdirected by diagnostics
sev 45: operational misdiagnosis, no demonstrated data loss
appeal 50: provisional, no operator preference inferred
effort 65: provisional focused diagnostic correction; confirm callers before pickup

## Reproduction
Save as `repro.py`, then run `python3 repro.py /path/to/Forge`. Uses only Python standard library, git and local lsof. Controlled CPU samples and explicit fixture mtime make this a component witness, not a timing benchmark or full CLI trial. Temporary fixtures clean up their own child and files.

```python
import ast, importlib.util, json, os, pathlib, subprocess, sys, tempfile, time
root=pathlib.Path(sys.argv[1]).resolve()
sys.dont_write_bytecode=True
sys.path.insert(0,str(root/'utils/py'))
import turn_diagnostics as td
source=(root/'utils/py/agy-turn.py').read_text()
node=next(n for n in ast.parse(source).body if isinstance(n,ast.FunctionDef) and n.name=='_probe_idle_blocker')
ns={'subprocess':subprocess}
exec(compile(ast.Module(body=[node],type_ignores=[]),'actual-probe','exec'),ns)
results=[]
for trial in range(2):
 with tempfile.TemporaryDirectory(prefix='forge-diag-control-') as tmp:
  p=pathlib.Path(tmp); log=p/'empty.log';log.write_text('')
  worker=subprocess.Popen([sys.executable,'-c',"import sys,time; f=open(sys.argv[1],'w'); print('READY',flush=True); time.sleep(30)",str(p/'innocent.lock')],stdout=subprocess.PIPE,text=True,start_new_session=True)
  try:
   assert worker.stdout.readline().strip()=='READY'
   lock=ns['_probe_idle_blocker'](worker,str(log))
   assert lock[0]=='lock',lock
  finally:
   worker.terminate();worker.wait(timeout=5)
  # No fcntl/flock calls or competing owner exist in this controlled worker.
  tree=p/'tree';tree.mkdir();(tree/'source.txt').write_text('unchanged')
  baseline=td._newest_mtime(str(tree))
  d=td.TurnDiagnostics(worktree=str(tree));d.samples=[(0.,0.,1),(1.,0.,1)];d.mtime_start=baseline;d.mtime_last=baseline
  clean=d.classify()
  (tree/'temp').mkdir();onlylog=tree/'temp/transport.log';onlylog.write_text('harness log only')
  os.utime(onlylog,(baseline+2,baseline+2))
  d.mtime_last=td._newest_mtime(str(tree)); contaminated=d.classify()
  assert clean[0]!=td.REASON_SLOW_PROGRESS
  assert contaminated[0]==td.REASON_SLOW_PROGRESS
  assert (tree/'source.txt').read_text()=='unchanged'
  git=p/'git';git.mkdir();subprocess.run(['git','init','-q',str(git)],check=True)
  (git/'request-a.md').write_text('scaffold');(git/'request-b.md').write_text('scaffold')
  counts=[len(subprocess.check_output(['git','-C',str(git),'status','--porcelain'],text=True).splitlines()) for _ in range(2)]
  assert counts==[2,2]
  results.append({'trial':trial+1,'benign_open_file_probe':lock,'no_log_control':clean,'log_only_classification':contaminated,'unchanged_dirty_tree_counts':counts})
print(json.dumps({'scope':'component reproduction: exact AST-extracted probe, imported classifier with controlled CPU samples, real git status; NOT full agy-turn CLI','source_head':subprocess.check_output(['git','-C',str(root),'rev-parse','HEAD'],text=True).strip(),'results':results},indent=2))

```

## Recorded output
```json
{
  "scope": "component reproduction: exact AST-extracted probe, imported classifier with controlled CPU samples, real git status; NOT full agy-turn CLI",
  "source_head": "0d1dc0fe8395b4f0fc58280fc32b86d4957d47d9",
  "results": [
    {
      "trial": 1,
      "benign_open_file_probe": [
        "lock",
        "the process tree held a .lock file open (e.g. a git index or harness driver lock) \u2014 it was waiting on a lock held by someone else, not working."
      ],
      "no_log_control": [
        "timeout-unclassified",
        "live sampling never established a safe idle window for the network probe [cpu=0.00s/s, samples=2, worktree-progress=no]"
      ],
      "log_only_classification": [
        "timeout-slow-but-progressing",
        "the agent was writing files but did not finish \u2014 genuinely slow; raising the turn budget is the appropriate response. [cpu=0.00s/s, samples=2, worktree-progress=yes]"
      ],
      "unchanged_dirty_tree_counts": [
        2,
        2
      ]
    },
    {
      "trial": 2,
      "benign_open_file_probe": [
        "lock",
        "the process tree held a .lock file open (e.g. a git index or harness driver lock) \u2014 it was waiting on a lock held by someone else, not working."
      ],
      "no_log_control": [
        "timeout-unclassified",
        "live sampling never established a safe idle window for the network probe [cpu=0.00s/s, samples=2, worktree-progress=no]"
      ],
      "log_only_classification": [
        "timeout-slow-but-progressing",
        "the agent was writing files but did not finish \u2014 genuinely slow; raising the turn budget is the appropriate response. [cpu=0.00s/s, samples=2, worktree-progress=yes]"
      ],
      "unchanged_dirty_tree_counts": [
        2,
        2
      ]
    }
  ]
}

```

## Implementation plan — 2026-11-16

Outcome: truthful diagnostic claims, while preserving existing timeout bounds, idle sampling and process-group cleanup. This is a message/diagnostic-label repair, not an idle-oracle redesign.

1. In agy-turn.py keep probe timing and kill behavior unchanged. Describe TTY errors, open lock-named files and open sockets as observations, explicitly stating that file/socket presence does not establish waiting or inactivity. Rename printed attribution headings to timeout observations; preserve probe tuple categories for compatibility. Do not print raw paths or credentials.
2. In turn_diagnostics.py keep sampling, mtime comparisons, idle_seconds, classifier ordering and security/CPU handling unchanged. Preserve both REASON_SLOW_PROGRESS and its existing machine-readable value for compatibility. Replace the human prose with a neutral file-activity observation and explicitly describe the retained reason code as a legacy category, not proof of useful progress. Rename worktree-progress output to file-activity. Explicitly state that logs/scratch can contribute and useful progress/budget justification are not established. Do not exclude directories here: that would change idle-kill behavior and intentional transcript signals beyond this request.
3. In relay_drive.py label the existing changed-file count as worktree state, not progress. Keep interval and process behavior unchanged. Update only existing assertions/help text affected by output changes; no new suites/registry entries.
4. Record model-free before/after controls under TESTS-RESULTS with provenance: benign open lock file, log-only writes with flat CPU, unchanged dirty scaffolds; positive real file/transcript activity still sampled; unchanged wall/idle exit and descendant cleanup using existing relevant suites in disposable full clone. Smoke actual stubbed shim main and adjacent timeout cases, no live model.
5. Independent plan/final review and applicable classified final gate; dedicated PR Closes #1506, never change PR1491.

Alternative rejected: exclusions for temp/log directories would change liveness decisions and still not prove useful progress; a new stream detector is outside this repair. Existing observations remain available with honest uncertainty.

Blast radius: diagnostic consumers across turn shims and relay output assertions; not queue, ledger schema, ownership locks, auth, budgets or signal dispatch. Keep the machine-readable reason value unchanged. Update the known detail-key assertion in test/gh648-l1-turn-termination.sh:63 and existing GH114/GH370 output expectations; inspect GH390/GH492/GH505 consumers for affected wording. No new test suites.

Rollback: one isolated task-branch change, reversible by reverting its commit. Original reproduction and PR1491 work remain untouched.

Rating: 55/45/50/65, consequence is operational misdiagnosis, appeal neutral, focused repair. Historical #114/#608/#648/#1126 establish related prior art, not a measured increase in incident rate; 14-day trend unknown.

QA: pending. Review should test whether neutral wording satisfies #1506 without changing watchdog behavior, and whether any label consumer requires compatibility treatment.

## Plan QA round 1 disposition

Accepted the Should: name and update test/gh648-l1-turn-termination.sh:63 for file-activity=. Resolved reason compatibility by retaining the existing constant and value, with explicit legacy-category qualification in human output. The reviewer PASS was substantive but STATUS remained Open; approval attestation is still pending. The controller correctly noted only part of relay_drive.py was inspected; no exhaustive driver sweep is claimed. Scope remains diagnostic output only, not liveness policy.
