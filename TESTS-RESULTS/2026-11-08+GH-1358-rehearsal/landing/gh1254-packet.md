# Marathon preflight packet — gh-1254-outer-loop-borrow-decl

- Generated: 2026-11-08T18:21:53Z
- Mode: gh-bundle
- Sources: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/PROJECT/2-WORKING/GH-1254-OUTER-LOOP-BORROW-DECL.md 
- Target root: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner (development @ aee318d03)
- Suggested branch: `marathon/gh-1254-outer-loop-borrow-decl-2026-11-08` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `python3 -c 'import os,sys,subprocess,tempfile,pathlib,shutil,json
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
- Do NOT run ANY test or gate yourself — not `python3 -c 'import os,sys,subprocess,tempfile,pathlib,shutil,json
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
  --pre-advance-cmd 'python3 -c 'import os,sys,subprocess,tempfile,pathlib,shutil,json
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
