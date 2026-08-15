---
gh_issue: 551
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/551
title: "One root cause under 9 open issues: a resolver that can't determine its answer returns a plausible default instead of refusing"
status: 2-WORKING
created: 2026-08-15
updated: 2026-08-15
owner: unassigned
doc_type: capture
complexity: 2
risk: 3
effort: 2
ratings_provisional: true
related:
  - "https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/555 — Meter's exit criterion; every other Meter entry is unverifiable until it exists"
goal: >
  Adopt one contract — a resolver that cannot determine its answer raises, never defaults — and apply it per seam.
---

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-15. RE-SCOPED 2026-08-14 after a Fable review and an operator correction: the cluster is ~3 open members, not nine, and the fix is Python-only with no Bash twin. Enforcement half already in flight on `development` (gh308 guard now rejects NEW Bash under utils/ and relay-automation/). | Apply the contract per seam. NOTE: contended — another session is building the guard half. |

## Why this is a Meter entry

A resolver that returns a plausible default instead of refusing is a **precondition** failure — the
run proceeds without having checked what it required. That is Meter's half of the Meter/Lantern
boundary: Lantern owns how a failure is *described*, Meter owns what a run *consumed and required*.

## Scope correction carried from the issue

The original claimed nine members and a Python+Bash twin build. Both were wrong. Three of the nine
(#310 citation semantics, #365 a file missing from `VENDOR_DIRS`, #504 an untested premise) do not
reduce to a resolver defaulting. And per `AGENTS.md:131-137` the frozen-twin set is a **closed list of
twelve legacy Tier-A entry points** — new code carries no twin obligation, and a new Bash resolver
would be dead on arrival because its only possible consumers are the frozen `.sh` fallbacks.

**Contention warning for the lane:** `rescue/gh344-gh329-path-resolution` already carries a fix for
#329, and another session is building the enforcement guard. Check both before starting.

## Acceptance

*(Rewritten 2026-08-14 — the original is preserved at the bottom of this issue.)*

- [ ] Adopt the contract, written down where resolvers are authored: **a resolver that cannot determine its answer raises. It never returns a default.**
- [ ] Apply it **per seam** to the members above. #395 is likely a delete-the-hardcoded-path one-liner; #329 is a caller fixing its error classification, not a resolver change at all.
- [ ] **Each fix ships a negative control that observes the REFUSAL** — not merely a correct answer. A resolver only ever seen succeeding is exactly the #419 problem.
- [ ] Extract a shared helper **only if two fixes turn out to be literally the same code** — after, not before.

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
      "kind": "grep_absent",
      "path": "test/gh551-resolver-refuses.sh",
      "pattern": "REFUS",
      "why": "fix marker: a control that observes the resolver REFUSING, not merely succeeding"
    }
  ],
  "artifacts": [
    "utils/py/marathon_drive.py",
    "test/gh551-resolver-refuses.sh"
  ],
  "remediation": {
    "source": "issue#551",
    "criteria": "SUMMARY FOR RANKING ONLY \u2014 the definition of done is the verbatim ## Acceptance block above"
  },
  "lanes": {
    "agy_safe": [],
    "orchestrator_only": [
      "utils/py/marathon_drive.py"
    ]
  }
}
```

Contract auto-drafted from the issue text — artifacts/lanes not yet operator-verified.
