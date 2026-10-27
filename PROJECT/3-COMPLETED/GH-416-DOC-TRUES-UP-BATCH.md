---
title: Documentation trues-ups (narrowed to items 1 and 3) — acorn deps classification, CODEX_FLAGS default and dead escalation rung
status: Complete
created: 2026-09-03
updated: 2026-10-27
owner: noelsaw1
gh_issue: 416
source: https://github.com/HiQS-Labs/XYZ-forge/issues/416
doc_type: chore
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - Removing acorn; it is real tooling. The fix is classifying it as devDependencies.
  - Renumbering any GH reference. Upstream numbers are mirrored, not rewritten.
related:
  - GH-406 (umbrella — external review by Russ K.)
  - GH-414 (the dead-reference class this batch's items 2 and 4 belong to)
goal: >
  Make the tree match its documents for the two items still open: acorn and acorn-walk classified
  as devDependencies (package.json + package-lock.json), and relay-xyz SKILL.md stating the real
  CODEX_FLAGS default and a real escalation rung. Items 2 and 4 were already true at a3450a2c.
---
## Status

| What was just completed | What's next |
|---|---|
| Scope narrowed to items 1 and 3; contract refreshed; promoted to 2-WORKING by SOP Step 1b (2026-10-25, GH-1175 Phase 0) | Jog run: Marathon one-phase build of items 1 and 3, then landing |


# GH-416: documentation trues-ups

## Why batched

None has a sequencing constraint and each is a few lines. Every one is the umbrella's own class at
nit severity: a document stating something not literally true of the tree.

| # | Claim | Reality |
|---|---|---|
| 1 | §7: "Node standard library only — no deps, no lockfile" | `package.json:18-21` carries `acorn` + `acorn-walk` under `dependencies`, with a lockfile |
| 2 | README `:71`, `:572`, `:573` reference `PROJECT/4-MISC/…` and `RECAP.md` | none exist; already in the PDDA warning stream |
| 3 | `SKILL.md:515` default `-s workspace-write`; `:519-520` offers `-c approval_policy=never` as the escalation rung | the real default is `-s workspace-write -c approval_policy=never`, so the escalation advice is a **no-op**; the real next rung is `--dangerously-bypass-approvals-and-sandbox` |
| 4 | ROUTER pointer to `docs/ROADMAP-UPSTREAM-ARCHIVE.md` reported done | exists only as an uncommitted working-tree change; `git show HEAD:ROUTER.md` carries no pointer |

Item 3 has two halves and the second was missed on first read — the doc does not merely omit the
default, its remediation advice is dead. Item 4 is a correction to this umbrella's own earlier
claim of completion.

## Scope narrowed (2026-10-25)

Re-checked at `development` `a3450a2c` ([issue comment](https://github.com/HiQS-Labs/XYZ-forge/issues/416#issuecomment-6407209414)).
Items 2 and 4 are already true of the tree. Item 1's §7 wording is already true
(GUIDING-PRINCIPLES.md:73); its classification fix is still open. Item 3 is still open
(`skills/1-hourly/relay-xyz/SKILL.md:597` and `:602`). The operator narrowed this capture to items 1 and 3.

## Phase

Single phase, one PR. Move `acorn` and `acorn-walk` from `dependencies` to `devDependencies` in
`package.json` (same versions) and mirror it in `package-lock.json` (root `packages[""]`
`devDependencies`; `"dev": true` on each acorn entry). In `skills/1-hourly/relay-xyz/SKILL.md`,
state the real `CODEX_FLAGS` default `-s workspace-write -c approval_policy=never` and make the
escalation advice name only `--dangerously-bypass-approvals-and-sandbox`. No other paths.

## Acceptance

- [ ] `acorn` / `acorn-walk` under `devDependencies`; §7 reads true.
- [ ] `SKILL.md` states the real `CODEX_FLAGS` default **and** a real escalation rung.

## Acceptance — deviations from the issue

- [dropped] No dead `PROJECT/4-MISC/` or `RECAP.md` reference in the README. — reason: already true at `a3450a2c`; scope narrowed by the operator 2026-10-25
- [dropped] `ROUTER.md` at HEAD carries the upstream-numbering pointer. — reason: already true at `a3450a2c` (ROUTER.md:51); scope narrowed by the operator 2026-10-25

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [
    { "type": "grep_present", "path": "package.json", "pattern": "\"dependencies\"", "note": "pre-fix: acorn deps under runtime dependencies; landed when only devDependencies remain" },
    { "type": "grep_present", "path": "skills/1-hourly/relay-xyz/SKILL.md", "pattern": "default `-s workspace-write`\\)", "note": "pre-fix: env table omits the approval half of the default" },
    { "type": "grep_present", "path": "skills/1-hourly/relay-xyz/SKILL.md", "pattern": "or `-c approval_policy=never`", "note": "pre-fix: escalation rung is a no-op" }
  ],
  "artifacts":   [
    "package.json",
    "package-lock.json",
    "skills/1-hourly/relay-xyz/SKILL.md"
  ],
  "remediation": { "source": "issue#416", "criteria": "acorn and acorn-walk classified as devDependencies in package.json and package-lock.json; relay-xyz SKILL.md states the real CODEX_FLAGS default and names only --dangerously-bypass-approvals-and-sandbox as the escalation; touch only the three artifacts" },
  "lanes":       { "agy_safe": [ "package.json", "package-lock.json", "skills/1-hourly/relay-xyz/SKILL.md" ], "orchestrator_only": [] }
}
```
