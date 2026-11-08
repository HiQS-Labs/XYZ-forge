# Marathon Phase gh-1254-outer-loop-borrow-decl
STATUS: Open
NEXT: codex (Builder)

<!-- marathon-drive: task=MARATHON-GH-1254-OUTER-LOOP-BORROW-DECL-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-1254-outer-loop-borrow-decl

- Generated: 2026-11-08T18:32:56Z
- Mode: gh-bundle
- Sources: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/PROJECT/2-WORKING/GH-1254-OUTER-LOOP-BORROW-DECL.md 
- Target root: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner (development @ a11e67a69)
- Suggested branch: `marathon/gh-1254-outer-loop-borrow-decl-2026-11-08` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `python3 -c 'import os,sys,subprocess,tempfile,pathlib,shutil,json,datetime,re
deadline=datetime.datetime.fromisoformat('"'"'2026-11-08T19:06:18+00:00'"'"').timestamp()
gate_started=datetime.datetime.now(datetime.timezone.utc).timestamp()
assert deadline-gate_started>=1800, '"'"'fixed preparation deadline leaves less than existing 1800s gate cap; preserve candidate without starting gate'"'"'
root=pathlib.Path.cwd().resolve()
assert root==pathlib.Path(os.environ['"'"'MARATHON_ROOT'"'"']).resolve()
env={k:v for k,v in os.environ.items() if k in ('"'"'PATH'"'"','"'"'HOME'"'"','"'"'USER'"'"','"'"'LOGNAME'"'"','"'"'SHELL'"'"','"'"'TMPDIR'"'"','"'"'LANG'"'"','"'"'LC_ALL'"'"','"'"'TERM'"'"','"'"'SSH_AUTH_SOCK'"'"','"'"'GH_TOKEN'"'"','"'"'GITHUB_TOKEN'"'"')}
def git(where,*args):return subprocess.check_output(['"'"'git'"'"','"'"'-C'"'"',str(where),*args],text=True,env=env).strip()
sha=git(root,'"'"'rev-parse'"'"','"'"'HEAD'"'"');branch=git(root,'"'"'symbolic-ref'"'"','"'"'--short'"'"','"'"'HEAD'"'"');origin=git(root,'"'"'remote'"'"','"'"'get-url'"'"','"'"'origin'"'"')
assert branch.startswith('"'"'marathon/'"'"') and origin=='"'"'https://github.com/HiQS-Labs/XYZ-forge.git'"'"'
clone=pathlib.Path(tempfile.mkdtemp(prefix='"'"'gh1358-lane-gate-'"'"')).resolve()
print('"'"'GH1358 isolated existing gate/push:'"'"',clone,'"'"'candidate'"'"',sha,flush=True)
def run(args):subprocess.run(args,cwd=clone,env=env,check=True)
run(['"'"'git'"'"','"'"'clone'"'"','"'"'--no-local'"'"','"'"'--no-hardlinks'"'"',str(root),str(clone)])
run(['"'"'git'"'"','"'"'remote'"'"','"'"'set-url'"'"','"'"'origin'"'"',origin]);run(['"'"'bash'"'"','"'"'githooks/install.sh'"'"']);run(['"'"'bash'"'"','"'"'githooks/install.sh'"'"','"'"'--check'"'"'])
run(['"'"'python3'"'"','"'"'TESTS-RESULTS/2026-11-08+GH-1358-rehearsal/clock/controls.py'"'"','"'"'utils/py/marathon_drive.py'"'"'])
run(['"'"'bash'"'"','"'"'test/gh390-gate-guard.sh'"'"'])
run(['"'"'bash'"'"','"'"'test/gh280-jog-marathon-adapter.sh'"'"'])
assert git(clone,'"'"'rev-parse'"'"','"'"'HEAD'"'"')==sha and git(root,'"'"'rev-parse'"'"','"'"'HEAD'"'"')==sha
assert git(clone,'"'"'remote'"'"','"'"'get-url'"'"','"'"'origin'"'"')==origin
assert git(clone,'"'"'remote'"'"','"'"'get-url'"'"','"'"'--push'"'"','"'"'--all'"'"','"'"'origin'"'"')==origin
assert git(clone,'"'"'config'"'"','"'"'--get'"'"','"'"'core.bare'"'"')=='"'"'false'"'"' and not git(clone,'"'"'status'"'"','"'"'--porcelain'"'"')
run(['"'"'bash'"'"','"'"'githooks/install.sh'"'"','"'"'--check'"'"'])
live=subprocess.check_output(['"'"'ps'"'"','"'"'-axo'"'"','"'"'pid=,command='"'"'],text=True)
other_gates=[line for line in live.splitlines() if re.match(r'"'"'^\s*\d+\s+(?:/\S*/)?bash\s+(?:\S*/)?(?:validate|ci-local)\.sh(?:\s|$)'"'"',line)]
print('"'"'pre-push live host gate check:'"'"',other_gates,flush=True)
assert not other_gates, '"'"'another host full gate is active; no peer was stopped'"'"'
assert datetime.datetime.now(datetime.timezone.utc).timestamp()<deadline, '"'"'fixed preparation deadline reached before push'"'"'
run(['"'"'git'"'"','"'"'push'"'"','"'"'--set-upstream'"'"','"'"'origin'"'"','"'"'HEAD:refs/heads/'"'"'+branch])
assert git(clone,'"'"'rev-parse'"'"','"'"'HEAD'"'"')==sha and git(root,'"'"'rev-parse'"'"','"'"'HEAD'"'"')==sha
assert git(clone,'"'"'remote'"'"','"'"'get-url'"'"','"'"'origin'"'"')==origin and git(clone,'"'"'config'"'"','"'"'--get'"'"','"'"'core.bare'"'"')=='"'"'false'"'"'
assert not git(clone,'"'"'status'"'"','"'"'--porcelain'"'"')
receipt=clone/'"'"'.xyz/receipts'"'"'/f'"'"'{sha}.json'"'"';data=json.loads(receipt.read_text())
assert data['"'"'sha'"'"']==sha and data['"'"'exit_code'"'"']==0 and data.get('"'"'scope'"'"')=='"'"'full'"'"'
dest=root/'"'"'.xyz/receipts'"'"';dest.mkdir(parents=True,exist_ok=True);shutil.copy2(receipt,dest/receipt.name)
print('"'"'GH1358 normal gated candidate publication complete; final transcript tail uses normal docs push'"'"',flush=True)
'`

- Artifacts: utils/py/marathon_drive.py,test/gh115-round-cap.sh,test/gh217-gate-env-plan-outside.sh,test/gh256-target-root-guard-root.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh307-gate-env-scrub.sh,test/gh322-runlog-python-lane.sh,test/gh342-sentinel-debug-log-python.sh,test/gh346-gateway-allowlists.sh,test/gh365-driver-lane-registry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh378-gate-requires-green-suite.sh,test/gh379-claude-builder-diagnosis.sh,test/gh382-marathon-memory-telemetry.sh,test/gh385-retry-token-satisfied.sh,test/gh390-gate-guard.sh,test/gh399-packet-acceptance-continuation.sh,test/gh407-gate-ran-attribution.sh,test/gh438-acceptance-recheck.sh,test/gh438-removal-is-progress.sh,test/gh441-gate-env-contract.sh,test/gh457-gate-tiers.sh,test/gh467-index-only-lane-blocked.sh,test/gh491-gate-only-refire.sh,test/gh520-default-reviewer-stub.sh,test/gh642-consumer-fruit.sh,test/baselines/GH-402-negative-control.md,test/baselines/GH-514-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 3787 LOC across 33 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh115-round-cap.sh,test/gh217-gate-env-plan-outside.sh,test/gh256-target-root-guard-root.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh307-gate-env-scrub.sh,test/gh322-runlog-python-lane.sh,test/gh342-sentinel-debug-log-python.sh,test/gh346-gateway-allowlists.sh,test/gh365-driver-lane-registry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh378-gate-requires-green-suite.sh,test/gh379-claude-builder-diagnosis.sh,test/gh382-marathon-memory-telemetry.sh,test/gh385-retry-token-satisfied.sh,test/gh390-gate-guard.sh,test/gh399-packet-acceptance-continuation.sh,test/gh407-gate-ran-attribution.sh,test/gh438-acceptance-recheck.sh,test/gh438-removal-is-progress.sh,test/gh441-gate-env-contract.sh,test/gh457-gate-tiers.sh,test/gh467-index-only-lane-blocked.sh,test/gh491-gate-only-refire.sh,test/gh520-default-reviewer-stub.sh,test/gh642-consumer-fruit.sh,test/baselines/GH-402-negative-control.md,test/baselines/GH-514-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/PROJECT/2-WORKING/GH-1254-OUTER-LOOP-BORROW-DECL.md` (its `## Acceptance` section, 4 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*Verified against [issue #1254](https://github.com/HiQS-Labs/XYZ-forge/issues/1254) — 4/4 criteria copied verbatim from issue #1254.*
- [ ] The existing Marathon gate counts sleep-inclusive wall elapsed without subtracting monotonic elapsed after a backward clock adjustment.
- [ ] Late running or completed children are refused with exit 108 before accepting success; a reaped child is never signalled.
- [ ] Normal success, genuine non-expired failure, disabled wall caps and existing CPU/RSS behavior are preserved.
- [ ] Recorded old-code red/new-code green controls and existing gh390/gh280 checks pass in a disposable full clone, followed by the normal full push gate; no new suite or gate machinery.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/py/marathon_drive.py,test/gh115-round-cap.sh,test/gh217-gate-env-plan-outside.sh,test/gh256-target-root-guard-root.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh307-gate-env-scrub.sh,test/gh322-runlog-python-lane.sh,test/gh342-sentinel-debug-log-python.sh,test/gh346-gateway-allowlists.sh,test/gh365-driver-lane-registry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh378-gate-requires-green-suite.sh,test/gh379-claude-builder-diagnosis.sh,test/gh382-marathon-memory-telemetry.sh,test/gh385-retry-token-satisfied.sh,test/gh390-gate-guard.sh,test/gh399-packet-acceptance-continuation.sh,test/gh407-gate-ran-attribution.sh,test/gh438-acceptance-recheck.sh,test/gh438-removal-is-progress.sh,test/gh441-gate-env-contract.sh,test/gh457-gate-tiers.sh,test/gh467-index-only-lane-blocked.sh,test/gh491-gate-only-refire.sh,test/gh520-default-reviewer-stub.sh,test/gh642-consumer-fruit.sh,test/baselines/GH-402-negative-control.md,test/baselines/GH-514-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `python3 -c 'import os,sys,subprocess,tempfile,pathlib,shutil,json,datetime,re
deadline=datetime.datetime.fromisoformat('"'"'2026-11-08T19:06:18+00:00'"'"').timestamp()
gate_started=datetime.datetime.now(datetime.timezone.utc).timestamp()
assert deadline-gate_started>=1800, '"'"'fixed preparation deadline leaves less than existing 1800s gate cap; preserve candidate without starting gate'"'"'
root=pathlib.Path.cwd().resolve()
assert root==pathlib.Path(os.environ['"'"'MARATHON_ROOT'"'"']).resolve()
env={k:v for k,v in os.environ.items() if k in ('"'"'PATH'"'"','"'"'HOME'"'"','"'"'USER'"'"','"'"'LOGNAME'"'"','"'"'SHELL'"'"','"'"'TMPDIR'"'"','"'"'LANG'"'"','"'"'LC_ALL'"'"','"'"'TERM'"'"','"'"'SSH_AUTH_SOCK'"'"','"'"'GH_TOKEN'"'"','"'"'GITHUB_TOKEN'"'"')}
def git(where,*args):return subprocess.check_output(['"'"'git'"'"','"'"'-C'"'"',str(where),*args],text=True,env=env).strip()
sha=git(root,'"'"'rev-parse'"'"','"'"'HEAD'"'"');branch=git(root,'"'"'symbolic-ref'"'"','"'"'--short'"'"','"'"'HEAD'"'"');origin=git(root,'"'"'remote'"'"','"'"'get-url'"'"','"'"'origin'"'"')
assert branch.startswith('"'"'marathon/'"'"') and origin=='"'"'https://github.com/HiQS-Labs/XYZ-forge.git'"'"'
clone=pathlib.Path(tempfile.mkdtemp(prefix='"'"'gh1358-lane-gate-'"'"')).resolve()
print('"'"'GH1358 isolated existing gate/push:'"'"',clone,'"'"'candidate'"'"',sha,flush=True)
def run(args):subprocess.run(args,cwd=clone,env=env,check=True)
run(['"'"'git'"'"','"'"'clone'"'"','"'"'--no-local'"'"','"'"'--no-hardlinks'"'"',str(root),str(clone)])
run(['"'"'git'"'"','"'"'remote'"'"','"'"'set-url'"'"','"'"'origin'"'"',origin]);run(['"'"'bash'"'"','"'"'githooks/install.sh'"'"']);run(['"'"'bash'"'"','"'"'githooks/install.sh'"'"','"'"'--check'"'"'])
run(['"'"'python3'"'"','"'"'TESTS-RESULTS/2026-11-08+GH-1358-rehearsal/clock/controls.py'"'"','"'"'utils/py/marathon_drive.py'"'"'])
run(['"'"'bash'"'"','"'"'test/gh390-gate-guard.sh'"'"'])
run(['"'"'bash'"'"','"'"'test/gh280-jog-marathon-adapter.sh'"'"'])
assert git(clone,'"'"'rev-parse'"'"','"'"'HEAD'"'"')==sha and git(root,'"'"'rev-parse'"'"','"'"'HEAD'"'"')==sha
assert git(clone,'"'"'remote'"'"','"'"'get-url'"'"','"'"'origin'"'"')==origin
assert git(clone,'"'"'remote'"'"','"'"'get-url'"'"','"'"'--push'"'"','"'"'--all'"'"','"'"'origin'"'"')==origin
assert git(clone,'"'"'config'"'"','"'"'--get'"'"','"'"'core.bare'"'"')=='"'"'false'"'"' and not git(clone,'"'"'status'"'"','"'"'--porcelain'"'"')
run(['"'"'bash'"'"','"'"'githooks/install.sh'"'"','"'"'--check'"'"'])
live=subprocess.check_output(['"'"'ps'"'"','"'"'-axo'"'"','"'"'pid=,command='"'"'],text=True)
other_gates=[line for line in live.splitlines() if re.match(r'"'"'^\s*\d+\s+(?:/\S*/)?bash\s+(?:\S*/)?(?:validate|ci-local)\.sh(?:\s|$)'"'"',line)]
print('"'"'pre-push live host gate check:'"'"',other_gates,flush=True)
assert not other_gates, '"'"'another host full gate is active; no peer was stopped'"'"'
assert datetime.datetime.now(datetime.timezone.utc).timestamp()<deadline, '"'"'fixed preparation deadline reached before push'"'"'
run(['"'"'git'"'"','"'"'push'"'"','"'"'--set-upstream'"'"','"'"'origin'"'"','"'"'HEAD:refs/heads/'"'"'+branch])
assert git(clone,'"'"'rev-parse'"'"','"'"'HEAD'"'"')==sha and git(root,'"'"'rev-parse'"'"','"'"'HEAD'"'"')==sha
assert git(clone,'"'"'remote'"'"','"'"'get-url'"'"','"'"'origin'"'"')==origin and git(clone,'"'"'config'"'"','"'"'--get'"'"','"'"'core.bare'"'"')=='"'"'false'"'"'
assert not git(clone,'"'"'status'"'"','"'"'--porcelain'"'"')
receipt=clone/'"'"'.xyz/receipts'"'"'/f'"'"'{sha}.json'"'"';data=json.loads(receipt.read_text())
assert data['"'"'sha'"'"']==sha and data['"'"'exit_code'"'"']==0 and data.get('"'"'scope'"'"')=='"'"'full'"'"'
dest=root/'"'"'.xyz/receipts'"'"';dest.mkdir(parents=True,exist_ok=True);shutil.copy2(receipt,dest/receipt.name)
print('"'"'GH1358 normal gated candidate publication complete; final transcript tail uses normal docs push'"'"',flush=True)
'`, and NOT `test/gh115-round-cap.sh,test/gh217-gate-env-plan-outside.sh,test/gh256-target-root-guard-root.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh322-runlog-python-lane.sh,test/gh342-sentinel-debug-log-python.sh,test/gh346-gateway-allowlists.sh,test/gh365-driver-lane-registry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh378-gate-requires-green-suite.sh,test/gh379-claude-builder-diagnosis.sh,test/gh382-marathon-memory-telemetry.sh,test/gh385-retry-token-satisfied.sh,test/gh390-gate-guard.sh,test/gh399-packet-acceptance-continuation.sh,test/gh407-gate-ran-attribution.sh,test/gh438-acceptance-recheck.sh,test/gh438-removal-is-progress.sh,test/gh441-gate-env-contract.sh,test/gh457-gate-tiers.sh,test/gh467-index-only-lane-blocked.sh,test/gh491-gate-only-refire.sh,test/gh520-default-reviewer-stub.sh,test/gh642-consumer-fruit.sh,test/_setup.sh,test/lib/fixture-guard.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1254-outer-loop-borrow-decl RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/py/marathon_drive.py,test/gh115-round-cap.sh,test/gh217-gate-env-plan-outside.sh,test/gh256-target-root-guard-root.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh307-gate-env-scrub.sh,test/gh322-runlog-python-lane.sh,test/gh342-sentinel-debug-log-python.sh,test/gh346-gateway-allowlists.sh,test/gh365-driver-lane-registry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh378-gate-requires-green-suite.sh,test/gh379-claude-builder-diagnosis.sh,test/gh382-marathon-memory-telemetry.sh,test/gh385-retry-token-satisfied.sh,test/gh390-gate-guard.sh,test/gh399-packet-acceptance-continuation.sh,test/gh407-gate-ran-attribution.sh,test/gh438-acceptance-recheck.sh,test/gh438-removal-is-progress.sh,test/gh441-gate-env-contract.sh,test/gh457-gate-tiers.sh,test/gh467-index-only-lane-blocked.sh,test/gh491-gate-only-refire.sh,test/gh520-default-reviewer-stub.sh,test/gh642-consumer-fruit.sh,test/baselines/GH-402-negative-control.md,test/baselines/GH-514-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh \
  --pre-advance-cmd 'python3 -c 'import os,sys,subprocess,tempfile,pathlib,shutil,json,datetime,re
deadline=datetime.datetime.fromisoformat('"'"'2026-11-08T19:06:18+00:00'"'"').timestamp()
gate_started=datetime.datetime.now(datetime.timezone.utc).timestamp()
assert deadline-gate_started>=1800, '"'"'fixed preparation deadline leaves less than existing 1800s gate cap; preserve candidate without starting gate'"'"'
root=pathlib.Path.cwd().resolve()
assert root==pathlib.Path(os.environ['"'"'MARATHON_ROOT'"'"']).resolve()
env={k:v for k,v in os.environ.items() if k in ('"'"'PATH'"'"','"'"'HOME'"'"','"'"'USER'"'"','"'"'LOGNAME'"'"','"'"'SHELL'"'"','"'"'TMPDIR'"'"','"'"'LANG'"'"','"'"'LC_ALL'"'"','"'"'TERM'"'"','"'"'SSH_AUTH_SOCK'"'"','"'"'GH_TOKEN'"'"','"'"'GITHUB_TOKEN'"'"')}
def git(where,*args):return subprocess.check_output(['"'"'git'"'"','"'"'-C'"'"',str(where),*args],text=True,env=env).strip()
sha=git(root,'"'"'rev-parse'"'"','"'"'HEAD'"'"');branch=git(root,'"'"'symbolic-ref'"'"','"'"'--short'"'"','"'"'HEAD'"'"');origin=git(root,'"'"'remote'"'"','"'"'get-url'"'"','"'"'origin'"'"')
assert branch.startswith('"'"'marathon/'"'"') and origin=='"'"'https://github.com/HiQS-Labs/XYZ-forge.git'"'"'
clone=pathlib.Path(tempfile.mkdtemp(prefix='"'"'gh1358-lane-gate-'"'"')).resolve()
print('"'"'GH1358 isolated existing gate/push:'"'"',clone,'"'"'candidate'"'"',sha,flush=True)
def run(args):subprocess.run(args,cwd=clone,env=env,check=True)
run(['"'"'git'"'"','"'"'clone'"'"','"'"'--no-local'"'"','"'"'--no-hardlinks'"'"',str(root),str(clone)])
run(['"'"'git'"'"','"'"'remote'"'"','"'"'set-url'"'"','"'"'origin'"'"',origin]);run(['"'"'bash'"'"','"'"'githooks/install.sh'"'"']);run(['"'"'bash'"'"','"'"'githooks/install.sh'"'"','"'"'--check'"'"'])
run(['"'"'python3'"'"','"'"'TESTS-RESULTS/2026-11-08+GH-1358-rehearsal/clock/controls.py'"'"','"'"'utils/py/marathon_drive.py'"'"'])
run(['"'"'bash'"'"','"'"'test/gh390-gate-guard.sh'"'"'])
run(['"'"'bash'"'"','"'"'test/gh280-jog-marathon-adapter.sh'"'"'])
assert git(clone,'"'"'rev-parse'"'"','"'"'HEAD'"'"')==sha and git(root,'"'"'rev-parse'"'"','"'"'HEAD'"'"')==sha
assert git(clone,'"'"'remote'"'"','"'"'get-url'"'"','"'"'origin'"'"')==origin
assert git(clone,'"'"'remote'"'"','"'"'get-url'"'"','"'"'--push'"'"','"'"'--all'"'"','"'"'origin'"'"')==origin
assert git(clone,'"'"'config'"'"','"'"'--get'"'"','"'"'core.bare'"'"')=='"'"'false'"'"' and not git(clone,'"'"'status'"'"','"'"'--porcelain'"'"')
run(['"'"'bash'"'"','"'"'githooks/install.sh'"'"','"'"'--check'"'"'])
live=subprocess.check_output(['"'"'ps'"'"','"'"'-axo'"'"','"'"'pid=,command='"'"'],text=True)
other_gates=[line for line in live.splitlines() if re.match(r'"'"'^\s*\d+\s+(?:/\S*/)?bash\s+(?:\S*/)?(?:validate|ci-local)\.sh(?:\s|$)'"'"',line)]
print('"'"'pre-push live host gate check:'"'"',other_gates,flush=True)
assert not other_gates, '"'"'another host full gate is active; no peer was stopped'"'"'
assert datetime.datetime.now(datetime.timezone.utc).timestamp()<deadline, '"'"'fixed preparation deadline reached before push'"'"'
run(['"'"'git'"'"','"'"'push'"'"','"'"'--set-upstream'"'"','"'"'origin'"'"','"'"'HEAD:refs/heads/'"'"'+branch])
assert git(clone,'"'"'rev-parse'"'"','"'"'HEAD'"'"')==sha and git(root,'"'"'rev-parse'"'"','"'"'HEAD'"'"')==sha
assert git(clone,'"'"'remote'"'"','"'"'get-url'"'"','"'"'origin'"'"')==origin and git(clone,'"'"'config'"'"','"'"'--get'"'"','"'"'core.bare'"'"')=='"'"'false'"'"'
assert not git(clone,'"'"'status'"'"','"'"'--porcelain'"'"')
receipt=clone/'"'"'.xyz/receipts'"'"'/f'"'"'{sha}.json'"'"';data=json.loads(receipt.read_text())
assert data['"'"'sha'"'"']==sha and data['"'"'exit_code'"'"']==0 and data.get('"'"'scope'"'"')=='"'"'full'"'"'
dest=root/'"'"'.xyz/receipts'"'"';dest.mkdir(parents=True,exist_ok=True);shutil.copy2(receipt,dest/receipt.name)
print('"'"'GH1358 normal gated candidate publication complete; final transcript tail uses normal docs push'"'"',flush=True)
'' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
- `marathon-invocation.json` — the same invocation as structured data (`swarm-preflight/marathon-invocation@1`, GH-280); supervisors consume this, never the shell text


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): utils/py/marathon_drive.py,test/gh115-round-cap.sh,test/gh217-gate-env-plan-outside.sh,test/gh256-target-root-guard-root.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh307-gate-env-scrub.sh,test/gh322-runlog-python-lane.sh,test/gh342-sentinel-debug-log-python.sh,test/gh346-gateway-allowlists.sh,test/gh365-driver-lane-registry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh378-gate-requires-green-suite.sh,test/gh379-claude-builder-diagnosis.sh,test/gh382-marathon-memory-telemetry.sh,test/gh385-retry-token-satisfied.sh,test/gh390-gate-guard.sh,test/gh399-packet-acceptance-continuation.sh,test/gh407-gate-ran-attribution.sh,test/gh438-acceptance-recheck.sh,test/gh438-removal-is-progress.sh,test/gh441-gate-env-contract.sh,test/gh457-gate-tiers.sh,test/gh467-index-only-lane-blocked.sh,test/gh491-gate-only-refire.sh,test/gh520-default-reviewer-stub.sh,test/gh642-consumer-fruit.sh,test/baselines/GH-402-negative-control.md,test/baselines/GH-514-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick
   - /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick claim MARATHON-GH-1254-OUTER-LOOP-BORROW-DECL-TURN --agent codex --paths "marathon-system/gh-1254-outer-loop-borrow-decl/RELAY.md,utils/py/marathon_drive.py,test/gh115-round-cap.sh,test/gh217-gate-env-plan-outside.sh,test/gh256-target-root-guard-root.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh307-gate-env-scrub.sh,test/gh322-runlog-python-lane.sh,test/gh342-sentinel-debug-log-python.sh,test/gh346-gateway-allowlists.sh,test/gh365-driver-lane-registry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh378-gate-requires-green-suite.sh,test/gh379-claude-builder-diagnosis.sh,test/gh382-marathon-memory-telemetry.sh,test/gh385-retry-token-satisfied.sh,test/gh390-gate-guard.sh,test/gh399-packet-acceptance-continuation.sh,test/gh407-gate-ran-attribution.sh,test/gh438-acceptance-recheck.sh,test/gh438-removal-is-progress.sh,test/gh441-gate-env-contract.sh,test/gh457-gate-tiers.sh,test/gh467-index-only-lane-blocked.sh,test/gh491-gate-only-refire.sh,test/gh520-default-reviewer-stub.sh,test/gh642-consumer-fruit.sh,test/baselines/GH-402-negative-control.md,test/baselines/GH-514-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh"
   - /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick ping MARATHON-GH-1254-OUTER-LOOP-BORROW-DECL-TURN --agent codex
   - /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick release MARATHON-GH-1254-OUTER-LOOP-BORROW-DECL-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh-1254-outer-loop-borrow-decl/RELAY.md and utils/py/marathon_drive.py,test/gh115-round-cap.sh,test/gh217-gate-env-plan-outside.sh,test/gh256-target-root-guard-root.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh307-gate-env-scrub.sh,test/gh322-runlog-python-lane.sh,test/gh342-sentinel-debug-log-python.sh,test/gh346-gateway-allowlists.sh,test/gh365-driver-lane-registry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh378-gate-requires-green-suite.sh,test/gh379-claude-builder-diagnosis.sh,test/gh382-marathon-memory-telemetry.sh,test/gh385-retry-token-satisfied.sh,test/gh390-gate-guard.sh,test/gh399-packet-acceptance-continuation.sh,test/gh407-gate-ran-attribution.sh,test/gh438-acceptance-recheck.sh,test/gh438-removal-is-progress.sh,test/gh441-gate-env-contract.sh,test/gh457-gate-tiers.sh,test/gh467-index-only-lane-blocked.sh,test/gh491-gate-only-refire.sh,test/gh520-default-reviewer-stub.sh,test/gh642-consumer-fruit.sh,test/baselines/GH-402-negative-control.md,test/baselines/GH-514-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/marathon_drive.py,test/gh115-round-cap.sh,test/gh217-gate-env-plan-outside.sh,test/gh256-target-root-guard-root.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh307-gate-env-scrub.sh,test/gh322-runlog-python-lane.sh,test/gh342-sentinel-debug-log-python.sh,test/gh346-gateway-allowlists.sh,test/gh365-driver-lane-registry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh378-gate-requires-green-suite.sh,test/gh379-claude-builder-diagnosis.sh,test/gh382-marathon-memory-telemetry.sh,test/gh385-retry-token-satisfied.sh,test/gh390-gate-guard.sh,test/gh399-packet-acceptance-continuation.sh,test/gh407-gate-ran-attribution.sh,test/gh438-acceptance-recheck.sh,test/gh438-removal-is-progress.sh,test/gh441-gate-env-contract.sh,test/gh457-gate-tiers.sh,test/gh467-index-only-lane-blocked.sh,test/gh491-gate-only-refire.sh,test/gh520-default-reviewer-stub.sh,test/gh642-consumer-fruit.sh,test/baselines/GH-402-negative-control.md,test/baselines/GH-514-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick release MARATHON-GH-1254-OUTER-LOOP-BORROW-DECL-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick done MARATHON-GH-1254-OUTER-LOOP-BORROW-DECL-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick
   Edit ONLY marathon-system/gh-1254-outer-loop-borrow-decl/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
4c. A finding that asks for a behaviour change is a generalization unless you can paste the concrete
   input — a row, a value, a `file:line` — that fails under the current code (GH-681). Every
   `[Blocker]` or `[Should]` requesting a behaviour change MUST carry `Observed input:`,
   `Affected scope:` and `Falsifier:` lines; a `[Blocker]` must cite an observed failure. The Builder
   may disposition a request lacking these as `Declined — unproven generalization`.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.
