---
gh_issue: 3
source: https://github.com/HiQS-Suite/XYZ-forge/issues/3
title: "GH-3: improve-loop.sh --state-dir durability — provenance evidence must not evaporate"
status: active
created: 2026-08-16
updated: 2026-08-16
owner: orchestrator (Claude Code)
doc_type: bugfix
complexity: 1
risk: 1
effort: 1
ratings_provisional: true
goal: >
  A run's provenance.jsonl survives: the --state-dir default is durable and tracked-eligible, and
  the run's evidence can be named and committed by any claim that cites it.
---

# GH-3 — improve-loop state-dir durability

## Status

| What was just completed | What's next |
|---|---|
| Capture promoted to 2-WORKING; contract authored; Ballast 0.7.0 manifest frozen | Preflight (expected STALE on the /tmp criterion — see the capture note), operator decision on the manifest slot |

## Capture note — read before firing anything

**The issue's stated defect appears ALREADY LANDED on `main`.**
`relay-automation/improve-loop.sh:75` reads
`STATE_DIR="${STATE_DIR:-$HERE/state/improve-loop.$$}"` — a tracked in-repo path, not
`${TMPDIR:-/tmp}` — and `test/gh430-state-dir-tracked-default.sh` pins exactly this (default
inside the repo, not under `/tmp` or `$TMPDIR`, not gitignored). That fix landed in the private
repository as GH-430 and shipped in the launch cut; the issue text predates it. The contract
below therefore probes the bug-marker honestly (`grep_present` of a `/tmp`-rooted default), and
**preflight is expected to report exit 4 (stale / already-landed) for this lane.** That is the
machinery telling the truth, not a defect in the lane. The remaining verifiable ask in the issue
is the evidence-policy half (provenance committed alongside claims that cite it), which is a
policy enforcement question, not the evaporating-default defect this manifest slot was frozen
around. The Ballast block records this flag at freeze; the operator decides: re-scope the slot,
swap it, or close #3 as already-landed.

## Source of truth

- GitHub issue: [HiQS-Suite/XYZ-forge#3](https://github.com/HiQS-Suite/XYZ-forge/issues/3)

## Acceptance

- [ ] `improve-loop.sh`'s `--state-dir` default is a durable, repo-adjacent location rather than `${TMPDIR:-/tmp}`, so a run's `provenance.jsonl` survives macOS tmp purges (~3 days).
- [ ] A claim citing a run can name the provenance that substantiates it: the default state directory is tracked-eligible (not gitignored), and the run prints the `provenance.jsonl` path.
- [ ] A recorded negative control (under `test/baselines/`) demonstrates the durability check failing when the fix is reverted, per the standing rule.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_present", "path": "relay-automation/improve-loop.sh", "pattern": "STATE_DIR=.*(TMPDIR|/tmp)" } ],
  "artifacts":   [ "relay-automation/improve-loop.sh", "test/gh430-state-dir-tracked-default.sh" ],
  "remediation": { "source": "issue#3", "criteria": "provenance.jsonl survives: durable tracked-eligible default, path printed" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```

Probe polarity: `grep_present` carries the BUG marker — a `/tmp`- or `TMPDIR`-rooted STATE_DIR
default. On current `main` that marker is absent (see the capture note), so this probe evaluates
**landed** and the expected preflight verdict for this lane is exit 4 (stale / already-landed).

## Verification

- `bash test/gh430-state-dir-tracked-default.sh` green (already on main — re-run, not re-earn).
- If the operator re-scopes the slot to the provenance-policy half, this doc and the issue gain a
  dated deviation note before any lane fires.
