# Marathon Phase gh-1295-injected-text-in-briefs
STATUS: Open
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-1295-INJECTED-TEXT-IN-BRIEFS-TURN-2 builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-1295-injected-text-in-briefs

- Generated: 2026-11-08T09:54:46Z
- Mode: gh-bundle
- Sources: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/PROJECT/2-WORKING/GH-1295-INJECTED-TEXT-IN-BRIEFS.md 
- Target root: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner (development @ e9d676e42)
- Suggested branch: `marathon/gh-1295-injected-text-in-briefs-2026-11-08` (branch_ready=true — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `python3 -c 'import os,sys,subprocess,tempfile,pathlib,shutil,json
root=pathlib.Path.cwd().resolve()
assert root==pathlib.Path('"'"'/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner'"'"').resolve()
env={k:v for k,v in os.environ.items() if k in ('"'"'PATH'"'"','"'"'HOME'"'"','"'"'USER'"'"','"'"'LOGNAME'"'"','"'"'SHELL'"'"','"'"'TMPDIR'"'"','"'"'LANG'"'"','"'"'LC_ALL'"'"','"'"'TERM'"'"','"'"'SSH_AUTH_SOCK'"'"','"'"'GH_TOKEN'"'"','"'"'GITHUB_TOKEN'"'"')}
def git(where,*args):return subprocess.check_output(['"'"'git'"'"','"'"'-C'"'"',str(where),*args],text=True,env=env).strip()
sha=git(root,'"'"'rev-parse'"'"','"'"'HEAD'"'"');branch=git(root,'"'"'symbolic-ref'"'"','"'"'--short'"'"','"'"'HEAD'"'"');origin=git(root,'"'"'remote'"'"','"'"'get-url'"'"','"'"'origin'"'"')
assert branch.startswith('"'"'marathon/'"'"') and origin=='"'"'https://github.com/HiQS-Labs/XYZ-forge.git'"'"'
clone=pathlib.Path(tempfile.mkdtemp(prefix='"'"'gh1358-lane-gate-'"'"')).resolve()
print('"'"'GH1358 isolated existing gate/push:'"'"',clone,'"'"'candidate'"'"',sha,flush=True)
def run(args):subprocess.run(args,cwd=clone,env=env,check=True)
run(['"'"'git'"'"','"'"'clone'"'"','"'"'--no-local'"'"','"'"'--no-hardlinks'"'"',str(root),str(clone)])
run(['"'"'git'"'"','"'"'remote'"'"','"'"'set-url'"'"','"'"'origin'"'"',origin]);run(['"'"'bash'"'"','"'"'githooks/install.sh'"'"']);run(['"'"'bash'"'"','"'"'githooks/install.sh'"'"','"'"'--check'"'"'])
run([sys.executable,'"'"'-m'"'"','"'"'pytest'"'"','"'"'test/test_python_layer.py'"'"']);run(['"'"'bash'"'"','"'"'test/synthetic/gh94-containment-invariants.sh'"'"'])
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

- Artifacts: utils/py/harness.py,test/gh174-harness-registry.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 1902 LOC across 2 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh174-harness-registry.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/PROJECT/2-WORKING/GH-1295-INJECTED-TEXT-IN-BRIEFS.md` (its `## Acceptance` section, 3 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #1295 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*
- [ ] The six override canaries are held or fenced in both the proposal and emitted brief.md.
- [ ] Ordinary issues render unchanged.
- [ ] Verify with the recorded round-trip; no new test file or suite (GH-831).

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/py/harness.py,test/gh174-harness-registry.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `python3 -c 'import os,sys,subprocess,tempfile,pathlib,shutil,json
root=pathlib.Path.cwd().resolve()
assert root==pathlib.Path('"'"'/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner'"'"').resolve()
env={k:v for k,v in os.environ.items() if k in ('"'"'PATH'"'"','"'"'HOME'"'"','"'"'USER'"'"','"'"'LOGNAME'"'"','"'"'SHELL'"'"','"'"'TMPDIR'"'"','"'"'LANG'"'"','"'"'LC_ALL'"'"','"'"'TERM'"'"','"'"'SSH_AUTH_SOCK'"'"','"'"'GH_TOKEN'"'"','"'"'GITHUB_TOKEN'"'"')}
def git(where,*args):return subprocess.check_output(['"'"'git'"'"','"'"'-C'"'"',str(where),*args],text=True,env=env).strip()
sha=git(root,'"'"'rev-parse'"'"','"'"'HEAD'"'"');branch=git(root,'"'"'symbolic-ref'"'"','"'"'--short'"'"','"'"'HEAD'"'"');origin=git(root,'"'"'remote'"'"','"'"'get-url'"'"','"'"'origin'"'"')
assert branch.startswith('"'"'marathon/'"'"') and origin=='"'"'https://github.com/HiQS-Labs/XYZ-forge.git'"'"'
clone=pathlib.Path(tempfile.mkdtemp(prefix='"'"'gh1358-lane-gate-'"'"')).resolve()
print('"'"'GH1358 isolated existing gate/push:'"'"',clone,'"'"'candidate'"'"',sha,flush=True)
def run(args):subprocess.run(args,cwd=clone,env=env,check=True)
run(['"'"'git'"'"','"'"'clone'"'"','"'"'--no-local'"'"','"'"'--no-hardlinks'"'"',str(root),str(clone)])
run(['"'"'git'"'"','"'"'remote'"'"','"'"'set-url'"'"','"'"'origin'"'"',origin]);run(['"'"'bash'"'"','"'"'githooks/install.sh'"'"']);run(['"'"'bash'"'"','"'"'githooks/install.sh'"'"','"'"'--check'"'"'])
run([sys.executable,'"'"'-m'"'"','"'"'pytest'"'"','"'"'test/test_python_layer.py'"'"']);run(['"'"'bash'"'"','"'"'test/synthetic/gh94-containment-invariants.sh'"'"'])
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
'`, and NOT `test/gh174-harness-registry.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1295-injected-text-in-briefs RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/py/harness.py,test/gh174-harness-registry.sh \
  --pre-advance-cmd 'python3 -c 'import os,sys,subprocess,tempfile,pathlib,shutil,json
root=pathlib.Path.cwd().resolve()
assert root==pathlib.Path('"'"'/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner'"'"').resolve()
env={k:v for k,v in os.environ.items() if k in ('"'"'PATH'"'"','"'"'HOME'"'"','"'"'USER'"'"','"'"'LOGNAME'"'"','"'"'SHELL'"'"','"'"'TMPDIR'"'"','"'"'LANG'"'"','"'"'LC_ALL'"'"','"'"'TERM'"'"','"'"'SSH_AUTH_SOCK'"'"','"'"'GH_TOKEN'"'"','"'"'GITHUB_TOKEN'"'"')}
def git(where,*args):return subprocess.check_output(['"'"'git'"'"','"'"'-C'"'"',str(where),*args],text=True,env=env).strip()
sha=git(root,'"'"'rev-parse'"'"','"'"'HEAD'"'"');branch=git(root,'"'"'symbolic-ref'"'"','"'"'--short'"'"','"'"'HEAD'"'"');origin=git(root,'"'"'remote'"'"','"'"'get-url'"'"','"'"'origin'"'"')
assert branch.startswith('"'"'marathon/'"'"') and origin=='"'"'https://github.com/HiQS-Labs/XYZ-forge.git'"'"'
clone=pathlib.Path(tempfile.mkdtemp(prefix='"'"'gh1358-lane-gate-'"'"')).resolve()
print('"'"'GH1358 isolated existing gate/push:'"'"',clone,'"'"'candidate'"'"',sha,flush=True)
def run(args):subprocess.run(args,cwd=clone,env=env,check=True)
run(['"'"'git'"'"','"'"'clone'"'"','"'"'--no-local'"'"','"'"'--no-hardlinks'"'"',str(root),str(clone)])
run(['"'"'git'"'"','"'"'remote'"'"','"'"'set-url'"'"','"'"'origin'"'"',origin]);run(['"'"'bash'"'"','"'"'githooks/install.sh'"'"']);run(['"'"'bash'"'"','"'"'githooks/install.sh'"'"','"'"'--check'"'"'])
run([sys.executable,'"'"'-m'"'"','"'"'pytest'"'"','"'"'test/test_python_layer.py'"'"']);run(['"'"'bash'"'"','"'"'test/synthetic/gh94-containment-invariants.sh'"'"'])
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


## Debug mantra (auto-triggered — 1 prior attempt(s) on this phase did not reach Approved)

Before trying again, read `relay-automation/DEBUG-MANTRA.md` (relative to the harness root) and follow its four-step discipline: reproduce reliably, know the fail path, question the hypothesis, treat this round as a breadcrumb for the next one.

---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): utils/py/harness.py,test/gh174-harness-registry.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick
   - /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick claim MARATHON-GH-1295-INJECTED-TEXT-IN-BRIEFS-TURN-2 --agent codex --paths "marathon-system/gh-1295-injected-text-in-briefs/RELAY.md,utils/py/harness.py,test/gh174-harness-registry.sh"
   - /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick ping MARATHON-GH-1295-INJECTED-TEXT-IN-BRIEFS-TURN-2 --agent codex
   - /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick release MARATHON-GH-1295-INJECTED-TEXT-IN-BRIEFS-TURN-2 --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh-1295-injected-text-in-briefs/RELAY.md and utils/py/harness.py,test/gh174-harness-registry.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/harness.py,test/gh174-harness-registry.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick release MARATHON-GH-1295-INJECTED-TEXT-IN-BRIEFS-TURN-2 --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick done MARATHON-GH-1295-INJECTED-TEXT-IN-BRIEFS-TURN-2 --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick
   Edit ONLY marathon-system/gh-1295-injected-text-in-briefs/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

### Round 1 · Builder · codex

Implemented GH-1295 in utils/py/harness.py and extended the existing test/gh174-harness-registry.sh only.

- Recognize the six recorded instruction-override forms in issue title/body, capture text, and authored additions. Matching drafts are held with a fixed review reason; _build_proposal excludes them from provisional waves, preventing launch packet admission.
- Preserve matching brief text as explicitly untrusted data, fenced with more backticks than any embedded run. Renderer fallback also recognizes override text in older brief dictionaries. Ordinary briefs retain their previous rendering and schema.
- Extended the existing suite with a draft-to-proposal round-trip using all six frozen override canaries, an ordinary ready control, and a 20-backtick escape input. No new suite, gate, or test file.
- Verification: Python AST parsing of harness.py and embedded round-trip code passed; bash -n of the existing suite passed after correcting shell quoting in the added fixture. No behavioral tests or full gate executed, following the packet's explicit no-test scope lock; harness verification remains required. Failure sensitivity is not yet witnessed.
- Prior escalation inspected: timeout-no-artifact (exit 7), gate not run; no previous patch to preserve.
- Reversibility: Easy; no persistent schema/state changes. This is bounded recognition of recorded override forms, not a general classifier or a model-safety guarantee.

NEXT actor: agy (Reviewer). Please review the implementation and run the authorized verification through the harness.
