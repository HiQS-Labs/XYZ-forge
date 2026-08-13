---
gh_issue: 421
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/421
title: "relay-xyz SKILL.md documents a `vendor` subcommand that does not exist"
status: 2-WORKING
created: 2026-08-13
updated: 2026-08-13
owner: unassigned
doc_type: capture
complexity: 1
risk: 1
effort: 1
ratings_provisional: true
goal: >
  Correct the documented xyz-vendor.sh invocation in skills/relay-xyz/SKILL.md so the first
  command a new operator runs from the vendoring section actually works, and sweep sibling
  skill docs for the same wrong form.
---

## Why

`skills/relay-xyz/SKILL.md` documents vendoring as `xyz-vendor.sh vendor <repo>`. There is no
`vendor` subcommand — the script takes the target repo as its sole positional, so the documented
form consumes `vendor` as the target and rejects the real target with
`xyz-vendor.sh: unexpected argument <repo>`.

This is a documentation defect only; `relay-automation/xyz-vendor.sh` behaves correctly. It
matters more than a typical doc nit because of where it sits: three lines below, the same table
concludes that `xyz-vendor.sh` (not `install.sh`) is *the* path to concurrent per-repo relay
isolation. So the documented entry point for per-repo vendoring fails on first use.

Verified still present on `origin/development` during the 2026-08-13 `/10days` sweep.

## Key concepts

- The real contract is `xyz-vendor.sh <target-repo> [--no-register]`.
- `xyz-vendor.sh` is bash-only (no `utils/py/` twin), so no `runtime:*` split applies.

## Acceptance

Authored by `/10days` — the tracking issue has no `## Acceptance` section, so there is no block
to copy verbatim. These criteria are derived from the issue's "Suggested fix" and Symptom sections.

1. `skills/relay-xyz/SKILL.md` documents the invocation as `xyz-vendor.sh <target-repo>
   [--no-register]`, with no `vendor` subcommand anywhere in the file.
2. A repo-wide grep for the string `xyz-vendor.sh vendor` returns zero matches across `skills/`,
   `README.md`, `AGENTS.md`, and `ROUTER.md`.
3. The surrounding prose still names `xyz-vendor.sh` (not `install.sh`) as the path to
   concurrent per-repo relay isolation — the conclusion the table draws is unchanged.
4. `bash validate.sh` exits 0.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [
    { "type": "grep_present", "path": "skills/relay-xyz/SKILL.md", "pattern": "xyz-vendor.sh vendor" }
  ],
  "artifacts":   [ "skills/relay-xyz/SKILL.md" ],
  "remediation": { "source": "issue#421", "criteria": "Document the real single-positional xyz-vendor.sh contract and remove the nonexistent vendor subcommand" },
  "lanes":       { "agy_safe": [ "skills/relay-xyz/SKILL.md" ], "orchestrator_only": [] }
}
```

Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified.
The `fix_probe` detects the BUG (the wrong string still present), per swarm-preflight polarity.
