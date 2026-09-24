---
gh_issue: 742
source: https://github.com/HiQS-Labs/XYZ-forge/issues/742
title: "xyz-vendor.sh: vendored .xyz/ ships no package.json, so every Node entry point breaks on a `'type':'module'` target"
status: Complete
created: 2026-09-21
updated: 2026-09-24
owner: unassigned
doc_type: capture
complexity: 1
risk: 1
effort: 1
rating: "pri/sev/appeal/effort 70/90/90/80 · calc 330"
rating_ovr: null
is_manual_override: false
ratings_provisional: true
goal: >
  A vendored .xyz/ carries its own package.json declaring CommonJS so tick and every Node entry
  point start on an ESM target.
---

# GH-742 — xyz-vendor.sh: vendored .xyz/ ships no package.json, so every Node entry point breaks on a `"type":"module"` target

## Status

| What was just completed | What's next |
|---|---|
| Queued by the 2026-09-21 `/10days` sweep: validity, reproducibility and not-already-done verified against HEAD e565c0fe (see Why); contract auto-drafted. | Marathon lane fires from `marathon/10days-2026-09-21` via `swarm-preflight → marathon-drive`, scoped by the contract's `artifacts`. |

## Why

`relay-automation/xyz-vendor.sh` has zero references to `package.json`; `materialize_vendor()`
(`:435-500`) writes only `VENDOR_DIRS` + `VERSION`. Node resolves module type from the nearest
package.json, so a target whose root declares `"type": "module"` makes `.xyz/bin/tick` (`require()`
at `bin/tick:4`) die with `ReferenceError: require is not defined in ES module scope`. Falsified by
the reporter: dropping `.xyz/package.json` = `{"type":"commonjs"}` fixes it. No fix commit or PR
references #742.

## Acceptance

Authored by `/10days` — the tracking issue has no `## Acceptance` section swarm-preflight recognises, so there is no block to copy verbatim. These criteria transcribe the issue's fix / expected-behaviour text.

- [ ] `materialize_vendor()` in `relay-automation/xyz-vendor.sh` writes `.xyz/package.json` containing
      `"type": "commonjs"` on every vendor/update.
- [ ] `test/xyz-vendor.sh` gains a fixture whose root `package.json` declares `"type": "module"`;
      after vendoring, `TICK_REPO_ROOT=<target> .xyz/bin/tick --help` exits 0. Red control: with
      `.xyz/package.json` removed the same invocation fails.
- [ ] `bash validate.sh` exits 0.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh",
  "fix_probes": [
    {
      "type": "grep_absent",
      "path": "relay-automation/xyz-vendor.sh",
      "pattern": "package\\.json"
    }
  ],
  "artifacts": [
    "relay-automation/xyz-vendor.sh",
    "test/xyz-vendor.sh"
  ],
  "remediation": {
    "source": "issue#742",
    "criteria": "Write .xyz/package.json {\"type\":\"commonjs\"} in materialize_vendor and pin it with an ESM-target fixture"
  },
  "lanes": {
    "agy_safe": [
      "relay-automation/xyz-vendor.sh",
      "test/xyz-vendor.sh"
    ],
    "orchestrator_only": []
  }
}
```

Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified. Fix probes detect the BUG (`grep_present` = bug still there, `grep_absent` = fix landed), per swarm-preflight polarity.
