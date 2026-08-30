---
name: dry
description: >-
  Find the subsystems that should be one subsystem. Traces a codebase resource-first
  instead of subject-first, then reports every place N independent paths reach the same
  table, file, env var, endpoint, binary, or config key without ever meeting — the
  "we built four of these and none of them know about each other" failure that stays
  invisible until the bug count spikes. Produces a ranked Convergence Map naming the
  single gateway each cluster is missing. Trigger on /dry, and on "do we have duplicate
  subsystems", "why are there four of these", "these should go through one place",
  "find the near-duplicates", "is this already implemented somewhere", "we keep
  reimplementing this", "these paths should share a gateway", "DRY audit". Do NOT fire
  to grade one diff (that is /code-review), to trace one subject's blast radius (that
  is /recon), or to cluster recurring defects (that is /radar).
argument-hint: "[path or subsystem] [--depth quick|full]"
---

# DRY

Most duplication that hurts is not duplicated text. It is **duplicated knowledge**: four code
paths that each know how to reach the same resource, none of which know about the other three.
Text-similarity tools miss it — the four rarely look alike — and they drown the real finding in
near-miss noise until people stop reading the report.

This skill inverts the usual trace. Recon asks *"what does my subject touch?"* DRY asks the same
question backwards: **"for each resource, who touches it, and do those touchers ever meet?"**

## The one rule

**A finding must name a shared *resource*, never a shared *shape*.** Two functions that look alike
are not a finding. Two functions that both write `users.credits` by different paths are, whether or
not they share a single line of text.

## When NOT to fire

- Grading one diff or PR → `/code-review`.
- Tracing one subject's blast radius before a change → [recon](../recon/SKILL.md).
- Clustering recurring *defects* rather than structures → [radar](../radar/SKILL.md).
- A repo under ~30 source files. Read it; you do not need a report to see four of anything.
- Deliberate parallelism: N adapters behind one interface, N drivers registered to one registry,
  N tests of one unit. **That is the gateway pattern working.** Report it only if the adapters
  bypass their own interface.

## Step 1 — Scope and resource classes

Name the root and the change budget in one line. Then pick which resource classes to index — all
of them for a full audit, two or three for a quick pass:

| Class | What to extract |
|---|---|
| **Store** | table/collection names, SQL targets, ORM models, key prefixes, bucket names |
| **File** | concrete paths and path-building patterns, lockfiles, state dirs, log destinations |
| **Config** | env vars, config keys, feature flags, secrets names |
| **Network** | hosts, base URLs, endpoint paths, queue/topic names |
| **Process** | external binaries invoked, subprocess/`exec` targets, CLI names |

Language does not matter — every class above is a *literal* in almost every language, which is why
this works on a polyglot tree with no parser, no index, and no git history.

## Step 2 — Build the resource index (the recon half, inverted)

Sweep the tree once and emit `resource -> [file:line, ...]`. Exclude vendor, build, and dependency
directories, and say which you excluded.

Do it with the cheapest tool that holds: `rg` with a pattern per class, one pass each. If a
`codebase-memory` graph is installed, seed from it — but every edge a finding rests on is confirmed
by reading the file, exactly as in [recon](../recon/SKILL.md). Graph-only edges are marked and never ranked.

An empty class is a finding, not a failure: a repo with no config-key duplication should say so.

## Step 3 — Pivot: group, then test for disjointness

For each resource with **≥3 touching files** (**≥2** if any toucher *writes* it — write paths
diverge faster and hurt sooner), ask the question that separates a finding from a coincidence:

> **Do these files ever meet?**

They meet if they share an import, extend a common base, or route through a common module. Resolve
it by reading the imports of each toucher — not by proximity in the tree.

- **They meet** → not a finding. One gateway already exists; note it and move on.
- **They do not meet** → **convergence target.** N independent paths to one resource is the shape
  the user feels as "these should all go through one place."

## Step 4 — Corroborate — two signals or it is not reported

Disjoint-touchers alone over-reports. A target ships only with a **second independent signal**:

1. **Parallel vocabulary** — same noun, different qualifier: `*-turn.sh` ×8, `fooV2`, `new_foo`,
   `enhanced_foo`, `foo_helper` beside `foo_utils`. High signal in LLM-built trees specifically,
   because a model names the sixth implementation rather than finding the first.
2. **Literal constellation** — the same 2–3 literals (a URL *and* a magic key *and* a field name)
   co-occurring in files that do not import each other. That is copied knowledge, not coincidence.
3. **Same-shape entry** — N callables with near-identical parameters and the same output contract.
4. **Divergence evidence** — the touchers already disagree: different retry counts, different
   timeouts, one validates and the others do not. This is the strongest corroborator, because it
   is the bug the cluster will produce, already visible.

Signal 4 promotes a target to the top of the ranking on its own.

## Step 5 — Rank by what one fix retires

For each surviving target: **how many call sites collapse into the gateway, and what breaks today
because they have not?** Rank by that, not by cluster size — a 3-file cluster that already
disagrees on validation outranks an 8-file cluster that agrees on everything.

Mark each target's cost honestly: introducing a gateway is a **crossing** change, and if any
toucher is consumed by another repo it is **irreversible**. Hand the classification to
[triangulate](../triangulate/SKILL.md) rather than deciding the fix's size here.

## Step 6 — Write the Convergence Map

Long output belongs in a file: write `convergence-<repo-or-subsystem>.md` at the root of what you
scanned. Chat gets the verdict line, the path, and the top target.

```markdown
# Convergence Map — <scope>
Scanned: <N files, M excluded dirs> · Mode: <rg-only | graph+read> · Classes: <which>

## Verdict
<N convergence targets, ranked. The one-line headline.>

## Targets
### T1 — <resource> · <N paths, disjoint> · retires <M call sites>
| Path | Where | Reads/Writes | Disagrees on |
|---|---|---|---|
| <name> | file:line | W | retry=3 |
**Missing gateway:** <the one module these should route through, and where it should live>
**Evidence:** <which corroborating signals fired>
**Cost:** <contained|crossing> x <reversible|irreversible> — hand to /triangulate

## Already converged
<resources with ≥3 touchers that DO meet — proof the audit is not trigger-happy>

## Unknowns
| Unknown | Why it matters | What would settle it |
```

The **Already converged** section is load-bearing. An audit that only reports sins reads as a tool
with its thumb on the scale, and it is the section that tells you whether the sweep was honest.

## Honesty rules

- Every path in a target cites `file:line`. No `file:line`, no row.
- Never claim two files "don't talk" without having read both import blocks. Say `unverified`.
- Zero targets is a real result on a small or well-factored tree. Say which, rather than
  manufacturing a cluster to look thorough.
- Do not propose the gateway's implementation. DRY names what should converge and stops;
  [triangulate](../triangulate/SKILL.md) sizes the change and `/ponytail` shrinks it.

## Neighbors

- [recon](../recon/SKILL.md) — traces one subject outward. DRY runs the same trace resource-first.
- [triangulate](../triangulate/SKILL.md) — sizes and paces the convergence work this skill finds.
- [radar](../radar/SKILL.md) — clusters recurring defects; DRY clusters structures. A repo that keeps producing the
  same bug class is often a DRY target radar has already noticed from the other end.
- [ponytail](../ponytail/SKILL.md) — a gateway is machinery; make it the smallest one that works.
