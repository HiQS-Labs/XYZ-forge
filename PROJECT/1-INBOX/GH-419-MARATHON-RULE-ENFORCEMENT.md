---
title: Make the three marathon process rules deterministic by extending marathon.sh's existing --plan refusal
status: Proposed (1-INBOX — not yet active)
created: 2026-09-03
owner: noelsaw1
gh_issue: 419
source: https://github.com/HiQS-Labs/XYZ-forge/issues/419
doc_type: feature
complexity: 2
risk: 2
effort: 2
phases: 2
ratings_provisional: true
non_goals:
  - Any new script, module, config file, or write path. If it needs a new file other than its test, the design is wrong.
  - A GitHub API call inside the gate. It must work offline; existence-checking is the ledger's job.
  - Enforcement inside marathon_drive.py — it is a single-phase driver; marathon-wide rules belong at the orchestrator, once.
  - Clone-creation automation. The gate validates the name; the operator still runs git clone.
  - Retiring ROADMAP.md (GH-269) or fixing the planner source (GH-418).
related:
  - GH-212 (plan-location refusal — the existing gate this extends)
  - GH-45 (linked-worktree refusal + announced override — the pattern to reuse)
  - GH-417 (marathon umbrella whose process this hardens)
  - GH-418 (planner ledger source — separate defect, same arc)
goal: >
  Turn three documented-only marathon rules — umbrella issue, full clone, derived clone folder
  name — into deterministic refusals, by adding three conditions to a refusal block that already
  exists in marathon.sh, introducing exactly one new input and no new files.
---

# GH-419: three marathon rules, one existing gate

> **1-INBOX capture**, not an active-work doc. On promotion, create the status table.

## Why this is cheap

The instinct on reading "make three process rules deterministic" is to build a preflight module.
That would be wrong here, because **the gate already exists**.

GUIDING-PRINCIPLES §"Marathon builder default & plan location (GH-212)" records that
`marathon.sh --plan` **already refuses (exit 2)** a plan resolving outside `PROJECT/2-WORKING/`,
with a documented env override and an exemption for shipped reference examples. That is a
plan-validation refusal block with exactly the shape these three rules need.

So the whole change is **three more conditions in one existing block**, plus one new YAML key.

`relay-automation/marathon.sh` carries no frozen-twin banner and has no Python twin, so no
`Frozen-twin-exception:` trailer is required.

## The one new input

```yaml
umbrella: https://github.com/HiQS-Labs/XYZ-forge/issues/417
name: gh417-remediation          # cosmetic label only — never parsed for identity
phases: [...]
```

`umbrella:` is the **single canonical source** of the marathon's identity. The folder name derives
from it alone; `name:` is never parsed for an issue number. That is the point agy's DRY finding
forced (see "Consult outcome"), and it is why two fields cannot drift.

## The three conditions — as adjudicated

| Rule | Check | Reuses |
|---|---|---|
| 1. Umbrella present | `umbrella:` matches the issue-URL shape. **No network call. `TMP-XXXXXX` is NOT accepted** — see below. | the `check_tracking_token` posture (`releases_app.py:1675-1694`) |
| 2. Full clone | refuse a **linked worktree** only. The primary-checkout half is **dropped**. | the `--git-common-dir` idiom already written twice (`validate.sh:16-53`, `driver-lock-lib.sh:20-35`) — do not write a third |
| 3. Derived name | `basename` of the **execution clone root** equals `marathon-gh-<n>-<slug>`, `<n>` from rule 1 | nothing new |

**Execution clone root = `TARGET_ROOT` when `--target-root` is supplied, else `ROOT`. Never
`$PWD`.** `marathon.sh` has a deliberate two-root model (`:54-60`, `:95-106`, `:157-162`); a `$PWD`
check would validate the harness clone instead of the clone receiving the work, and would refuse a
legitimate run invoked from a subdirectory.

**`TMP-XXXXXX` is disallowed for an executable marathon.** It stays valid for a ledger row parked
offline, but a TMP token has no issue number, so rule 3's name cannot be derived from it. A
marathon that cannot name its umbrella issue is not ready to run — which is what SOP §0b already
says in prose.

Escape hatch: one env override per rule, **announced on stderr, never silent** — the GH-45 pattern
verbatim. A bypass that says nothing is indistinguishable from no guard.

## Phases

1. **Parser + the two conditions.** Add `umbrella` to `bin/marathon-yaml`'s top-level schema
   (`parseMarathonYaml` currently accepts only `name` and `phases` at indent 0 and otherwise throws
   `unexpected top-level line`, `bin/marathon-yaml:56-57`), then add the conditions to the existing
   refusal block. **The parser change is real work that the first draft of this plan did not
   count.**
2. **Controls.** Reds — a plan with no `umbrella:`, a linked worktree, a wrongly-named clone — each
   fired against a fixture, plus a green: a correctly-shaped marathon still runs. Recorded in
   `test/baselines/`. Per §13 a green gate with no witnessed red is not evidence, and the **green**
   matters most here: an over-strict name regex would refuse every real marathon while looking like
   a working guard. Accept `[a-z0-9-]+` plus a `-r2`-style retry suffix, and print the expected
   name in the refusal.

## Consult outcome (2026-09-03)

Codex (`gpt-5.6-terra`) and agy both voted **REVISE**. Transcripts:
`relay-system/2026-09-03/gh419-enforcement-120203/`.

**Unanimous, and adopted:** drop the primary-checkout half of rule 2. Codex — git cannot identify a
semantically "primary" clone without adding state, and the two-root model explicitly supports
development-checkout use. agy — rule 3's name check already refuses a primary checkout implicitly,
so a detector is redundant. Two different arguments, same verdict.

**Codex's blocker, confirmed by independent read and adopted:** `bin/marathon-yaml` rejects unknown
top-level keys, so `umbrella:` would have made every compliant plan unparsable. The feature would
have shipped with a plausible-looking guard that nothing could reach.

**Where they split, and the tie-break:** agy wanted `umbrella:` dropped as a DRY violation
(`GUIDING-PRINCIPLES.md:15`), deriving the number from `name:` instead — and its evidence was this
plan's own first draft, which had `umbrella: …/417` beside `name: gh406-remediation`. Real drift,
before any code. But deriving from `name:` is a *breaking constraint* on an existing field: the only
real plan in the tree is `2026-09-01-xyz-harness-quickwins`, which carries no issue number and would
be refused. **Kept `umbrella:`, made it the sole identity source, and left `name:` cosmetic** — one
canonical location, which is what the DRY principle actually asks for, at the cost of one parser
line.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "relay-automation/marathon.sh", "pattern": "umbrella" } ],
  "artifacts":   [
    "relay-automation/marathon.sh",
    "bin/marathon-yaml",
    "test/gh419-marathon-rule-enforcement.sh",
    "test/baselines/GH-419-negative-control.md"
  ],
  "remediation": { "source": "issue#419", "criteria": "a marathon without a valid umbrella key, from a linked worktree, or in a wrongly-named clone is refused exit 2; the name derives from umbrella against TARGET_ROOT-else-ROOT; each refusal is overridable by one announced env var; a correctly-shaped marathon still runs" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
