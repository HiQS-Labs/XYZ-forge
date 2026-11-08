---
gh_issue: 1216
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1216
title: "Normalize named Aider OpenRouter profile exports"
status: Active
created: 2026-11-08
updated: 2026-11-08
owner: noelsaw1
doc_type: capture
complexity: 1
risk: 1
effort: 1
phases: 1
goal: Named Aider profiles emit the provider-native OpenRouter route without altering manual overrides.
---
## Status

| What was just completed | What's next |
|---|---|
| Promoted to active working contract via jog | Execute implementation and verify probes |

# GH1216 — named Aider OpenRouter export

## Scope and reviewed plan

The current CLI reproduces the live issue: a named Aider/OpenRouter profile emits
an unprefixed AIDER_MODEL. The issue is OPEN with no comments or defer decisions;
no primary roadmap row exists. This is real work discovered from the live backlog.

Independent Codex plan QA approved with one correction: restrict normalization to
named-profile tier2, because tier1 promises to preserve manual overrides. Implement
that one emit_env change; do not mutate the resolved profile/raw JSON. Keep an
already-prefixed model unchanged and preserve other gateways/lanes. Extend only
existing gh346 coverage if necessary. Reversibility Easy; no schema or access change.

Do not run mutation-heavy suites from this runner or a linked worker worktree.
Use isolated manual behavior checks if needed; the harness gate executes the
covering suite and normal full push gate in a separate disposable full clone.
No provider/Aider execution, no paid route, no new suite, and no merge.

## Acceptance

- [ ] A named Aider profile using gateway `openrouter` emits `AIDER_MODEL` with exactly one `openrouter/` prefix.
- [ ] Already-prefixed named profiles, explicit tier-1 environment overrides, other gateways/lanes, and raw JSON resolution remain unchanged.
- [ ] Existing covering checks pass in a disposable full clone; no provider execution or new test suite.

## Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "python3 -c 'import os,sys,subprocess,tempfile,pathlib,shutil,json\nroot=pathlib.Path.cwd().resolve()\nassert root==pathlib.Path(os.environ['\"'\"'MARATHON_ROOT'\"'\"']).resolve()\nenv={k:v for k,v in os.environ.items() if k in ('\"'\"'PATH'\"'\"','\"'\"'HOME'\"'\"','\"'\"'USER'\"'\"','\"'\"'LOGNAME'\"'\"','\"'\"'SHELL'\"'\"','\"'\"'TMPDIR'\"'\"','\"'\"'LANG'\"'\"','\"'\"'LC_ALL'\"'\"','\"'\"'TERM'\"'\"','\"'\"'SSH_AUTH_SOCK'\"'\"','\"'\"'GH_TOKEN'\"'\"','\"'\"'GITHUB_TOKEN'\"'\"')}\ndef git(where,*args):return subprocess.check_output(['\"'\"'git'\"'\"','\"'\"'-C'\"'\"',str(where),*args],text=True,env=env).strip()\nsha=git(root,'\"'\"'rev-parse'\"'\"','\"'\"'HEAD'\"'\"');branch=git(root,'\"'\"'symbolic-ref'\"'\"','\"'\"'--short'\"'\"','\"'\"'HEAD'\"'\"');origin=git(root,'\"'\"'remote'\"'\"','\"'\"'get-url'\"'\"','\"'\"'origin'\"'\"')\nassert branch.startswith('\"'\"'marathon/'\"'\"') and origin=='\"'\"'https://github.com/HiQS-Labs/XYZ-forge.git'\"'\"'\nclone=pathlib.Path(tempfile.mkdtemp(prefix='\"'\"'gh1358-lane-gate-'\"'\"')).resolve()\nprint('\"'\"'GH1358 isolated existing gate/push:'\"'\"',clone,'\"'\"'candidate'\"'\"',sha,flush=True)\ndef run(args):subprocess.run(args,cwd=clone,env=env,check=True)\nrun(['\"'\"'git'\"'\"','\"'\"'clone'\"'\"','\"'\"'--no-local'\"'\"','\"'\"'--no-hardlinks'\"'\"',str(root),str(clone)])\nrun(['\"'\"'git'\"'\"','\"'\"'remote'\"'\"','\"'\"'set-url'\"'\"','\"'\"'origin'\"'\"',origin]);run(['\"'\"'bash'\"'\"','\"'\"'githooks/install.sh'\"'\"']);run(['\"'\"'bash'\"'\"','\"'\"'githooks/install.sh'\"'\"','\"'\"'--check'\"'\"'])\nrun(['\"'\"'bash'\"'\"','\"'\"'test/gh346-profile-resolve.sh'\"'\"'])\nassert git(clone,'\"'\"'rev-parse'\"'\"','\"'\"'HEAD'\"'\"')==sha and git(root,'\"'\"'rev-parse'\"'\"','\"'\"'HEAD'\"'\"')==sha\nassert git(clone,'\"'\"'remote'\"'\"','\"'\"'get-url'\"'\"','\"'\"'origin'\"'\"')==origin\nassert git(clone,'\"'\"'remote'\"'\"','\"'\"'get-url'\"'\"','\"'\"'--push'\"'\"','\"'\"'--all'\"'\"','\"'\"'origin'\"'\"')==origin\nassert git(clone,'\"'\"'config'\"'\"','\"'\"'--get'\"'\"','\"'\"'core.bare'\"'\"')=='\"'\"'false'\"'\"' and not git(clone,'\"'\"'status'\"'\"','\"'\"'--porcelain'\"'\"')\nrun(['\"'\"'bash'\"'\"','\"'\"'githooks/install.sh'\"'\"','\"'\"'--check'\"'\"'])\nrun(['\"'\"'git'\"'\"','\"'\"'push'\"'\"','\"'\"'--set-upstream'\"'\"','\"'\"'origin'\"'\"','\"'\"'HEAD:refs/heads/'\"'\"'+branch])\nassert git(clone,'\"'\"'rev-parse'\"'\"','\"'\"'HEAD'\"'\"')==sha and git(root,'\"'\"'rev-parse'\"'\"','\"'\"'HEAD'\"'\"')==sha\nassert git(clone,'\"'\"'remote'\"'\"','\"'\"'get-url'\"'\"','\"'\"'origin'\"'\"')==origin and git(clone,'\"'\"'config'\"'\"','\"'\"'--get'\"'\"','\"'\"'core.bare'\"'\"')=='\"'\"'false'\"'\"'\nassert not git(clone,'\"'\"'status'\"'\"','\"'\"'--porcelain'\"'\"')\nreceipt=clone/'\"'\"'.xyz/receipts'\"'\"'/f'\"'\"'{sha}.json'\"'\"';data=json.loads(receipt.read_text())\nassert data['\"'\"'sha'\"'\"']==sha and data['\"'\"'exit_code'\"'\"']==0 and data.get('\"'\"'scope'\"'\"')=='\"'\"'full'\"'\"'\ndest=root/'\"'\"'.xyz/receipts'\"'\"';dest.mkdir(parents=True,exist_ok=True);shutil.copy2(receipt,dest/receipt.name)\nprint('\"'\"'GH1358 normal gated candidate publication complete; final transcript tail uses normal docs push'\"'\"',flush=True)\n'",
  "fix_probes": [
    {
      "type": "command",
      "cmd": "python3 /dev/stdin <<'GH1216_PROBE'\nimport os,sys\nsys.path.insert(0,'utils/py')\nimport profile_resolve as p\nroot=os.getcwd()\nfor spec in p.lanes(root).values():\n for key in ('agent_var','model_var'):os.environ.pop(spec[key],None)\np.load_profiles=lambda: {'gh1216':{'harness':'aider','gateway':'openrouter','model':'moonshotai/kimi-k3.1-pro'}}\nr=p.resolve('gh1216',root)\nout,rc=p.emit_env(r,root)\nassert rc==0 and \"export AIDER_MODEL='openrouter/moonshotai/kimi-k3.1-pro'\" in out,out\n\nGH1216_PROBE",
      "expect_nonzero": true
    }
  ],
  "artifacts": [
    "utils/py/profile_resolve.py",
    "test/gh346-profile-resolve.sh"
  ],
  "remediation": {
    "source": "issue#1216",
    "criteria": "Only named-profile tier2 Aider/OpenRouter export normalization. Preserve raw JSON and explicit tier1 overrides. Use existing covering suite; no provider call."
  }
}
```

The gate compares its working root with `MARATHON_ROOT`, supplied independently by
the validated Jog/Marathon invocation and preserved by the existing gate environment.
An absent or mismatched pin refuses; it is never derived from the gate working directory.
Historical relay and deployment receipts retain their original machine identities.

## Budget

Second bounded dispatch after attempt1 promotion refusal (no builder started); queue cap2 retained; Codex builder/Agy reviewer. Worker wall/idle
900s; existing relay base5/hardmax10 for qualifying progress, Marathon cap2 unchanged.
No automatic retry. Existing preadvance gate wall1800s. Preparation hard stop12:30Z
2026-11-08. Admission and scope preparation are agent-assisted, not a no-row
scheduled-discovery claim.

## PRS proposal

pri 55 / sev 40 / appeal 50 / effort 90 — reproduced routing defect, narrow export
normalization with no provider execution.
