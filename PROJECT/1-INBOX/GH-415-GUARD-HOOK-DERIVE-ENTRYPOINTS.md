---
title: The skill-first guard hook covers 6 of 12 Tier-A entrypoints — derive the set from AGENTS.md instead of hardcoding it
status: Proposed (1-INBOX — not yet active)
created: 2026-09-03
owner: noelsaw1
gh_issue: 415
source: https://github.com/HiQS-Labs/XYZ-forge/issues/415
doc_type: bug
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - A wider glob alone; relay-loop.sh, runner.sh and consult.sh are still missed by *-turn.sh.
  - Maintaining a third hand-written entrypoint list anywhere.
related:
  - GH-406 (umbrella — external review by Russ K.)
  - GH-308 (frozen Bash twins — source of the authoritative Tier-A enumeration)
goal: >
  Make the guard hook's expected set derive from AGENTS.md's Tier-A enumeration plus the
  *-turn.sh glob, so a new shim or loop wrapper is guarded by construction, and stop the hook
  false-positiving on commands that merely mention a driver path.
---

# GH-415: guard hook covers half the entrypoints

> **1-INBOX capture**, not an active-work doc. On promotion, create the status table.

## Why this is R6 and not higher

The mitigation is real: the Bash shims `exec` the Python twins, so the common path is genuinely
guarded. The bypass is direct Python or an unlisted shim. But §4 states the hook "enforces this by
blocking driver calls," and it lists six literal filenames against a surface of twelve.

Unmatched: `claude`, `aider`, `pi`, `deepseek`, `commandcode`, `smallcode` turn shims, plus
`relay-loop.sh`, `runner.sh`, `consult.sh` and direct `python3` driver invocations.

## The manifest already exists and was not used

`AGENTS.md:230-232` enumerates the eleven Tier-A entry points, with `marathon-plan` added as the
12th frozen twin at `:252-256`. This is Radar T3's open checklist item — *"generalize the
derive-from-source pattern into a reusable helper"* — on a third guard Radar had not named.

## Second defect, observed twice while writing this

The hook matches against the **whole command string**, so a command that merely *mentions* a
driver path — a grep, a heredoc, an issue body quoting a file and line — is blocked as though it
were driving the harness. A false positive that trains operators to work around the guard is a
slow way to lose it.

## Phase

Single phase: derive the expected set; add an enumeration test that walks the tree; fix the
substring match to target the executed command rather than any occurrence.

Red control: the pre-fix hook lets `deepseek-turn.sh` and `consult.sh` through.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "relay-automation/hooks/relay-xyz-guard.sh", "pattern": "TIER_A" } ],
  "artifacts":   [
    "relay-automation/hooks/relay-xyz-guard.sh",
    "test/gh415-guard-hook-entrypoints.sh",
    "test/baselines/GH-415-negative-control.md"
  ],
  "remediation": { "source": "issue#415", "criteria": "every Tier-A entrypoint enumerated from the tree is blocked, and a command merely referencing a driver path is not" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
