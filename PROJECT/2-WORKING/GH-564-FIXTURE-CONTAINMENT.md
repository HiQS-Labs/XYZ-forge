---
gh_issue: 564
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/564
title: "A test suite can rewrite the REAL clone's git remote — git -C \"\" and cd \"\" are silent no-ops"
status: 2-WORKING
created: 2026-08-15
updated: 2026-08-15
owner: unassigned
doc_type: capture
complexity: 2
risk: 5
effort: 2
ratings_provisional: true
related:
  - "https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/177 — mktemp failure resolving to the repo root; same family"
  - "https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/559 — a suite run removing an untracked file; same family"
goal: >
  Make it impossible for a test suite to operate on the repository it was invoked from, rather than
  on its own fixture.
---

## Status

| What was just completed | What's next |
|---|---|
| `gh544-pre-push-gate.sh` guarded and green at 78/0; control recorded at 72 pass / 6 fail pre-fix. | Audit the other 31 files that pass a variable into `git -C "$…"`, and add a suite-wide invariant gate. Tracked in #564. |

## The defect

Every call already passed `-C "$r"`. Both escapes are silent no-ops on an EMPTY string, and these
suites run without `set -e`:

- `git -C ""` — documented: *"if `<path>` is present but empty … the current working directory is
  left unchanged"*
- `( cd "" && … )` — a bash no-op; the subshell stays in the caller's directory

One unguarded `r="$(mktemp -d "$WORK/repo.XXXXXX")"` therefore turns every fixture operation into an
operation on the real clone. `$WORK` was guarded on the line above since day one; the per-repo
mktemps were not.

Reported from a live incident: the shared clone's `origin` was found pointing at
`$TMPDIR/gh544-prepush.*/bare.*`.

## Acceptance

Carried in full on the issue (#564). This lane delivers the `gh544-pre-push-gate.sh` half; the
suite-wide audit and invariant gate remain open there.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "test/gh544-pre-push-gate.sh", "pattern": "require_fixture" } ],
  "artifacts":   [
    "test/gh544-pre-push-gate.sh",
    "test/baselines/GH-564-negative-control.md"
  ],
  "remediation": { "source": "issue#564", "criteria": "a suite cannot operate on the repository it was invoked from" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
