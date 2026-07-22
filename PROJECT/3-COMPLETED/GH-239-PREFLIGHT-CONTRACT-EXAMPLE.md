---
gh_issue: 239
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/239
title: "swarm-preflight: no contract example ships — consumers hit exit 3 with nothing to copy, so the gate gets bypassed"
status: "SHIPPED — closed 2026-07-21, see GitHub issue comment for evidence (merged PR #243)."
created: 2026-07-18
updated: 2026-07-18
owner: noel
doc_type: bug
complexity: 1
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Not adding new CLI surface (`--emit-contract-skeleton`) — two docs solve this; revisit only if
    the shipped example fails to change consumer behaviour
  - Not changing the vendor boundary so `PROJECT/**` ships — larger call, made unnecessary by a
    shipped example
  - Not loosening the exit-3 gate itself; the gate is correct, only its on-ramp is missing
related:
  - utils/swarm-preflight.sh
  - relay-automation/MARATHON.example.yaml
  - PROJECT/2-WORKING/MARATHON-PLAN-2026-07-18-J-VENDORED-CONSUMER-DX.md
goal: >
  Ship a consumer-facing `CONTRACT.example.md` alongside `MARATHON.example.yaml`, and make the
  exit-3 error print the minimal valid contract skeleton and its target file — so satisfying the
  preflight gate stops being more expensive than routing around it.
roadmap_exempt: false
---

# GH-239 · no preflight-contract example ships to consumers

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-07-18 from an external field report filed against a vendored `.xyz/` consumer (`Hypercart-Dev-Tools/rebalance-OS`). Promoted to `2-WORKING` with a Swarm Preflight Contract. Claims verified — and the situation is slightly worse than filed (see below). Not yet fixed. | Fire as lane J2 of [MARATHON-PLAN-2026-07-18-J](MARATHON-PLAN-2026-07-18-J-VENDORED-CONSUMER-DX.md), in parallel with GH-238 (disjoint write-sets). |
| **2026-07-21:** shipped via merged PR [#243](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/243); issue #239 closed on GitHub. | Promoted to `3-COMPLETED`. Nothing further for this doc. |

## The gap (verified)

`swarm-preflight.sh` refuses any `--gh-issue` whose capture doc lacks a machine-readable preflight
contract (exit 3). That gate is correct. But no example contract ships anywhere in the install, so
a new consumer hits exit 3 as their very first interaction with nothing to copy from.

| Claim | Evidence |
|---|---|
| Schema lives only in the script's own header | `utils/swarm-preflight.sh:24-36` — a comment block, the sole source |
| Exit 3 on missing/invalid contract | header `:44`, plus `emit "CONTRACT ERROR ($doc): see message above."` at `:527` |
| No consumer-facing example ships | `relay-automation/MARATHON.example.yaml` is the only shipped worked example; there is no contract equivalent |

## Worse than reported

Real, filled-in contracts **do** exist in this repo — a dozen-plus `PROJECT/**/GH-*.md` capture docs
carry them. But `PROJECT/**` is **not part of a vendored `.xyz/` install**. So every working example
is structurally invisible to exactly the audience that needs one. The knowledge exists and is
currently non-shippable under the vendor boundary.

## Why it bites — the gate is being routed around

The path of least resistance for a consumer is to skip `swarm-preflight.sh` entirely and
hand-author a `MARATHON.yaml`, because *that* format ships an example. The reporter confirms this
is what previous marathons in their repo did. The consequence is that the preflight gate — branch
freshness, fix-still-required probes, lane assignment, collision scoping — is routinely bypassed,
not because it isn't wanted but because the plan format has an on-ramp and the contract format
doesn't.

A safety gate that is cheaper to route around than to satisfy is not a working gate.

## `fix_probes` is the field that needs the most annotation

Probe polarity is the trap, and getting it wrong is worse than failing: probes detect the **bug**,
not the fix. `grep_present` means bug evidence is still there; `grep_absent` means the fix marker
has not landed yet. Author them backwards and preflight returns STALE (exit 4), which reads like
"the work is already done" — a *false completion signal*, the most dangerous failure mode this tool
has. The example must state this inline and unmistakably.

## Fix direction

1. **Ship `relay-automation/CONTRACT.example.md`** — a complete capture doc with a filled-in
   contract, annotated per field, mirroring how `MARATHON.example.yaml` earns its keep. Must call
   out probe polarity explicitly and name the STALE/exit-4 false-completion consequence.
2. **Improve the exit-3 message** to print the minimal valid contract skeleton and the file it
   belongs in. The tool already knows exactly what's missing; it should say so.

## Definition of done

- [ ] `relay-automation/CONTRACT.example.md` ships with a complete, per-field-annotated contract.
- [ ] It documents `fix_probes` polarity explicitly, including the exit-4 false-completion trap.
- [ ] `swarm-preflight.sh`'s exit-3 path prints the minimal valid skeleton and the target file path.
- [ ] `bash validate.sh` no worse than baseline.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "path_absent", "path": "relay-automation/CONTRACT.example.md" },
    { "type": "grep_absent", "path": "utils/swarm-preflight.sh", "pattern": "minimal valid contract" }
  ],
  "artifacts": [ "relay-automation/CONTRACT.example.md", "utils/swarm-preflight.sh", "test/swarm-preflight.sh" ],
  "remediation": {
    "source": "issue#239",
    "criteria": "relay-automation/CONTRACT.example.md exists and contains a complete, per-field-annotated preflight contract, including an explicit statement of fix_probes polarity (probes detect the bug, not the fix: grep_present = bug evidence, grep_absent = fix marker absent) and the exit-4 STALE false-completion consequence of inverting it. utils/swarm-preflight.sh's exit-3 path prints a minimal valid contract skeleton (message contains the phrase 'minimal valid contract') and names the file it belongs in. bash validate.sh green, no worse than pre-existing environmental reds."
  },
  "lanes": {
    "agy_safe": [ "relay-automation/CONTRACT.example.md" ],
    "orchestrator_only": [ "utils/swarm-preflight.sh", "test/swarm-preflight.sh" ]
  }
}
```
