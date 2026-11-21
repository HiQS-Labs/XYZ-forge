---
gh_issue: 1295
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1295
title: "factory-primitive plan-draft: injected instruction text in an issue body is carried into briefs and launch packets"
status: Active
created: 2026-10-31
owner: noelsaw1
doc_type: feedback
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - no model-based classifier
  - no new tests (GH-831)
related:
  - #1279
  - #1248
  - #1294
goal: >
  Issue text reaches briefs and launch packets only as quoted data that a builder prompt cannot read as an instruction; a recorded manual round trip on the injection canaries shows it.
updated: 2026-11-08
---

## Key concepts

- text from issue bodies is copied into briefs
- decide fence-as-data versus strip
- human approval is the only barrier today

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# factory-primitive plan-draft: injected instruction text in an issue body is carried into briefs and launch packets

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

Instruction text injected in an issue body is carried verbatim into plan-draft briefs and launch packets. See the issue for evidence and the proposed fix.

## Why

Found by the #1279 window: injection-canary lanes passed the structure and Marathon dry runs. Nothing executes automatically, but the text reaches future builder prompts and a human approves launch by copying a folder.

## Phase 0 — Explore & scope

### Checklist

- [ ] Inspect `_sections` and `render_brief` in `utils/py/harness.py`.
- [ ] Evaluate fencing options: wrap sourced scope in explicit Markdown code fence or quote block with untrusted data disclaimer.
- [ ] Evaluate pattern filter for common override strings (`IGNORE ALL PREVIOUS INSTRUCTIONS`, `SYSTEM OVERRIDE`).

### QA checklist — Phase 0

- [ ] Sourced issue body instructions cannot be read as instructions by builder prompts in generated briefs.
- [ ] Normal issue bodies render unchanged without regression.
- [ ] No new test files (GH-831).

## Ratings rationale

pri 60 / sev 60 / appeal 50 / effort 70 (deferred by operator until factory-primitive generated packets are run live; preparation unblocks evaluation).

## Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "python3 -c 'import os,sys,subprocess,tempfile,pathlib,shutil,json\nroot=pathlib.Path.cwd().resolve()\nassert root==pathlib.Path('\"'\"'/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner'\"'\"').resolve()\nenv={k:v for k,v in os.environ.items() if k in ('\"'\"'PATH'\"'\"','\"'\"'HOME'\"'\"','\"'\"'USER'\"'\"','\"'\"'LOGNAME'\"'\"','\"'\"'SHELL'\"'\"','\"'\"'TMPDIR'\"'\"','\"'\"'LANG'\"'\"','\"'\"'LC_ALL'\"'\"','\"'\"'TERM'\"'\"','\"'\"'SSH_AUTH_SOCK'\"'\"','\"'\"'GH_TOKEN'\"'\"','\"'\"'GITHUB_TOKEN'\"'\"')}\ndef git(where,*args):return subprocess.check_output(['\"'\"'git'\"'\"','\"'\"'-C'\"'\"',str(where),*args],text=True,env=env).strip()\nsha=git(root,'\"'\"'rev-parse'\"'\"','\"'\"'HEAD'\"'\"');branch=git(root,'\"'\"'symbolic-ref'\"'\"','\"'\"'--short'\"'\"','\"'\"'HEAD'\"'\"');origin=git(root,'\"'\"'remote'\"'\"','\"'\"'get-url'\"'\"','\"'\"'origin'\"'\"')\nassert branch.startswith('\"'\"'marathon/'\"'\"') and origin=='\"'\"'https://github.com/HiQS-Labs/XYZ-forge.git'\"'\"'\nclone=pathlib.Path(tempfile.mkdtemp(prefix='\"'\"'gh1358-lane-gate-'\"'\"')).resolve()\nprint('\"'\"'GH1358 isolated existing gate/push:'\"'\"',clone,'\"'\"'candidate'\"'\"',sha,flush=True)\ndef run(args):subprocess.run(args,cwd=clone,env=env,check=True)\nrun(['\"'\"'git'\"'\"','\"'\"'clone'\"'\"','\"'\"'--no-local'\"'\"','\"'\"'--no-hardlinks'\"'\"',str(root),str(clone)])\nrun(['\"'\"'git'\"'\"','\"'\"'remote'\"'\"','\"'\"'set-url'\"'\"','\"'\"'origin'\"'\"',origin]);run(['\"'\"'bash'\"'\"','\"'\"'githooks/install.sh'\"'\"']);run(['\"'\"'bash'\"'\"','\"'\"'githooks/install.sh'\"'\"','\"'\"'--check'\"'\"'])\nrun([sys.executable,'\"'\"'-m'\"'\"','\"'\"'pytest'\"'\"','\"'\"'test/test_python_layer.py'\"'\"']);run(['\"'\"'bash'\"'\"','\"'\"'test/synthetic/gh94-containment-invariants.sh'\"'\"'])\nassert git(clone,'\"'\"'rev-parse'\"'\"','\"'\"'HEAD'\"'\"')==sha and git(root,'\"'\"'rev-parse'\"'\"','\"'\"'HEAD'\"'\"')==sha\nassert git(clone,'\"'\"'remote'\"'\"','\"'\"'get-url'\"'\"','\"'\"'origin'\"'\"')==origin\nassert git(clone,'\"'\"'remote'\"'\"','\"'\"'get-url'\"'\"','\"'\"'--push'\"'\"','\"'\"'--all'\"'\"','\"'\"'origin'\"'\"')==origin\nassert git(clone,'\"'\"'config'\"'\"','\"'\"'--get'\"'\"','\"'\"'core.bare'\"'\"')=='\"'\"'false'\"'\"' and not git(clone,'\"'\"'status'\"'\"','\"'\"'--porcelain'\"'\"')\nrun(['\"'\"'bash'\"'\"','\"'\"'githooks/install.sh'\"'\"','\"'\"'--check'\"'\"'])\nrun(['\"'\"'git'\"'\"','\"'\"'push'\"'\"','\"'\"'--set-upstream'\"'\"','\"'\"'origin'\"'\"','\"'\"'HEAD:refs/heads/'\"'\"'+branch])\nassert git(clone,'\"'\"'rev-parse'\"'\"','\"'\"'HEAD'\"'\"')==sha and git(root,'\"'\"'rev-parse'\"'\"','\"'\"'HEAD'\"'\"')==sha\nassert git(clone,'\"'\"'remote'\"'\"','\"'\"'get-url'\"'\"','\"'\"'origin'\"'\"')==origin and git(clone,'\"'\"'config'\"'\"','\"'\"'--get'\"'\"','\"'\"'core.bare'\"'\"')=='\"'\"'false'\"'\"'\nassert not git(clone,'\"'\"'status'\"'\"','\"'\"'--porcelain'\"'\"')\nreceipt=clone/'\"'\"'.xyz/receipts'\"'\"'/f'\"'\"'{sha}.json'\"'\"';data=json.loads(receipt.read_text())\nassert data['\"'\"'sha'\"'\"']==sha and data['\"'\"'exit_code'\"'\"']==0 and data.get('\"'\"'scope'\"'\"')=='\"'\"'full'\"'\"'\ndest=root/'\"'\"'.xyz/receipts'\"'\"';dest.mkdir(parents=True,exist_ok=True);shutil.copy2(receipt,dest/receipt.name)\nprint('\"'\"'GH1358 normal gated candidate publication complete; final transcript tail uses normal docs push'\"'\"',flush=True)\n'",
  "fix_probes": [
    {
      "type": "grep_absent",
      "path": "utils/py/harness.py",
      "pattern": "untrusted_issue_text|sanitize_brief_scope",
      "note": "pre-fix: harness.py does not fence untrusted scope text in briefs"
    }
  ],
  "artifacts": [
    "utils/py/harness.py"
  ],
  "remediation": {
    "source": "issue#1295",
    "criteria": "Render sourced issue scope inside explicit untrusted fences or hold brief when instruction patterns match; no new tests (GH-831)."
  }
}
```

## Merge evidence

- PR #1302 merged 2026-10-31 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #1304 merged 2026-10-31 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #1324 merged 2026-11-08 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Acceptance

Copied from the live issue's explicit inline Acceptance paragraph (2026-11-08).
The issue does have criteria despite the older preflight heading-only warning.

- [ ] The six override canaries are held or fenced in both the proposal and emitted brief.md.
- [ ] Ordinary issues render unchanged.
- [ ] Verify with the recorded round-trip; no new test file or suite (GH-831).

## Bounded retry implementation decision

Use the issue's existing renderer-fencing option, restricted to recognized
instruction-override text so ordinary briefs stay byte-for-byte unchanged. Keep
the rule small in harness.py; do not build a general classifier or scan the whole
backlog. The six recorded inputs are in
utils/py/factory_primitive/scenarios/gh1279-canaries.jsonl; prior outputs under
TESTS-RESULTS/2026-10-31+GH-1279-stageb/window/rules/. Existing missing-scope or
needs-recon holds remain holds. Preserve sourced text as data; use a fence that
cannot be closed by embedded backticks. A wrapper does not guarantee model safety.

This is the second and final allowed Marathon lane attempt (cap2, prior fire
retained), with builder codex/reviewer agy, worker wall/idle900 seconds and relay
round cap5 unchanged. No force, budget reset, new suite or automated merge.
The first Agy attempt spent its cap without a patch; do not repeat broad regex
tuning across unrelated documents. Verification scratch belongs outside the tree.
