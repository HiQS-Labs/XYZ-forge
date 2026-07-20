---
title: MARATHON.example.yaml understates sequencing and depends_on's scalar-only shape
status: "Shipped on branch (2-WORKING) — fix (3) landed 500dd87 on marathon/plan-l-followup-2026-07-19 (flow-sequence guard + test/marathon-yaml.sh case); docs (1)(2)(4) shipped 2026-07-18. Pending PR into development, then 3-COMPLETED."
created: 2026-07-18
updated: 2026-07-20
owner: noelsaw1
gh_issue: 241
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/241
doc_type: bugfix
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: false
reported_from: rebalance-OS
harness_commit: 3488c63
non_goals:
  - Adding concurrent phase execution to marathon.sh. This capture is about
    documenting the sequential behavior that exists, not changing it.
  - Reworking the depends_on schema to accept multiple dependencies. If that is
    wanted it is a separate feature; here the fix is to reject and explain the
    list form, not to support it.
related:
  - "#238 — marathon-drive pre-advance gate default halts consuming repos after approval"
  - "#239 — no preflight contract example ships"
goal: >
  A first-time plan author reading only MARATHON.example.yaml comes away knowing
  that phases run one at a time in depends_on order and halt on first failure,
  and that depends_on takes a single phase id. A bracketed list fails with a
  message naming the real problem rather than an unknown-phase lookup.
---

# GH-241 — MARATHON.example.yaml understates sequencing and depends_on's scalar-only shape

## Status
| What was just completed | What's next |
|---|---|
| **Fix (3) shipped `500dd87`** on `marathon/plan-l-followup-2026-07-19` (Plan L lane): `bin/marathon-yaml` now rejects the `depends_on` flow-sequence form (`[p1]`) with a shape-specific "flow sequence" error naming the field's shape, guarded before the phase-id lookup at `bin/marathon-yaml:102-105`; `test/marathon-yaml.sh` gains a regression case (list form → shape error; scalar still parses). 14/14 marathon-yaml tests pass. Docs fixes (1)(2)(4) shipped 2026-07-18. | Open a PR into `development`. On merge (`Closes #241`), move this doc to `3-COMPLETED`. |

## Symptom

`MARATHON.example.yaml` gives plan authors no signal that phases run strictly sequentially, and
does not state that `depends_on` must be a scalar — the bracketed list form parses as a literal
phase name and aborts the run.

## Environment

- **Observed from:** `rebalance-OS` (vendored `.xyz/` install — `source_commit=07faedfe`,
  `tick_version=0.2.0`, vendored 2026-07-18T00:36:45Z)
- **Harness commit:** `3488c63` (intake repo at report time)
- **Worker/CLI:** n/a — failure is in `bin/marathon-yaml` at plan parse, before any turn
- **Sandbox:** on (irrelevant to this failure — no network or keychain involved)

## Reproduction

1. Author a multi-phase `MARATHON.yaml` using `relay-automation/MARATHON.example.yaml` as the
   only reference.
2. Give one phase a dependency using the ordinary YAML sequence form:
   ```yaml
   depends_on: [coll-p3-138-job-liveness]
   ```
3. Run:
   ```bash
   .xyz/relay-automation/marathon.sh --plan PROJECT/2-WORKING/<slug>/MARATHON.yaml --dry-run
   ```

**Expected:** either the list form is accepted, or it is rejected with a message identifying the
field's shape as the problem.

**Observed:** parsed as the literal string `"[coll-p3-138-job-liveness]"` and looked up as a phase
id, so the failure presents as a missing phase. Exit 2 (usage/parse error).

**Frequency:** every time — deterministic parse behavior.

```text
marathon-yaml: phase coll-p4-127-health-predicate: depends_on unknown phase '[coll-p3-138-job-liveness]'
marathon: plan parse failed (see above)
```

The second half of the report has no error output — it is an absence:

```text
$ grep -in "sequential\|one at a time\|in order\|concurrent\|parallel" relay-automation/MARATHON.example.yaml
(no output — 0 matches)
```

## Impact

Non-blocking. `--dry-run` catches both problems at zero cost before any builder turn is spent, and
the reporting session did exactly that. The cost was one plan-authoring cycle plus a plan header
that had to be corrected rather than deleted.

The sequencing half has the longer tail. Every phase in the example except `p1` carries a
`depends_on`, so an author generalizing from it concludes the field *creates* ordering and that
phases lacking it are unordered — i.e. concurrent. The reporting session authored a plan whose
header claimed "p1..p3 are disjoint and safe to run concurrently — 3 lanes, then 1", backed by a
verified disjoint write-set analysis. The write-set analysis was sound and load-bearing (it is why
only p4 needs `depends_on`); the concurrency conclusion drawn from it was fiction. A misconception
that changes how an author scopes and orders an entire plan is worth one line of docs.

No workaround needed beyond knowing the constraint — which is the point.

## Phase 0 — Diagnose & scope

> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist

- [x] Reproduce in the intake repo — confirm `bin/marathon-yaml` treats a flow sequence as a string
      here too, not only under the vendored install
- [x] Confirm the write-set: `relay-automation/MARATHON.example.yaml` (docs) and, if fix (3) is
      taken, `bin/marathon-yaml` around the `depends_on` validation at ~L102
- [x] Decide fix vs. guard-and-document. Options, cheapest first:
      1. one header line in the example stating sequential execution + halt-on-first-failure
      2. mark the field `(optional, scalar — a single phase id, not a list)` in the field table
      3. reject `^\[.*\]$` in `marathon-yaml` with a message naming the shape
      4. recommend `--dry-run` in the example header as the standard pre-fire step
- [x] Check whether any other plan field has the same undocumented-scalar ambiguity (`artifact` is
      documented as comma-separated, which is a *different* convention in the same file — worth a
      consistency pass)
- [x] Set/correct triage ratings; clear `ratings_provisional`

### Phase 0 findings (2026-07-18)

**Half of the report's claim (1) does not hold as filed.** The example was *not* silent on ordering:
`MARATHON.example.yaml:3` already read "Each phase runs through marathon-drive.sh **in depends_on
order**; the chain **HALTS** on the first phase that fails its review/gate." The report's evidence
— a grep returning 0 matches — was a **false negative**: the pattern searched for the literal
`"in order"`, which does not match the string `"in depends_on order"`.

The underlying DX complaint survives the correction, in a narrower and more precise form: the line
documents *ordering* but not *exclusivity*. "In `depends_on` order" is exactly how a dependency-
ordered **parallel** scheduler (`make -j`) describes itself, so it does not rule out the concurrency
reading — and the example's shape (every phase but `p1` carrying a `depends_on`) actively encourages
it. The fix therefore had to state that execution is *strictly one at a time* and that `depends_on`
**constrains** ordering rather than **creating** it; restating "runs in order" would not have moved
a reader who already read that line and still concluded concurrency.

**Claim (2) reproduced exactly, in the intake repo, unvendored.** Confirmed against `bin/marathon-yaml`
with a two-phase fixture: `depends_on: [p1]` → `marathon-yaml: phase p2: depends_on unknown phase
'[p1]'`; `depends_on: p1` parses correctly. Root cause is the hand-rolled YAML reader — it does not
implement flow sequences, so `[p1]` survives as a literal scalar and reaches the phase-id lookup at
`bin/marathon-yaml:102-105`. Deterministic, every time.

**Also found (answers the consistency checklist item, and it is worse than the issue suggests).**
`depends_on` is scalar-and-single; `artifact` on the adjacent line is *comma-separated multi-value*.
Two different multiplicity conventions, two adjacent rows of the same field table, neither previously
marked. The `artifact` row does say "comma-separated", so it is documented; `depends_on` was not. The
field table now marks `depends_on` explicitly rather than leaving the reader to infer the convention
from its neighbour.

**Scope decision — fixes (1), (2) and (4) taken as docs-only; fix (3) deliberately deferred.**
(1)/(2)/(4) are one file, comments only, no runtime behavior change — verified by re-parsing the
example (`node bin/marathon-yaml relay-automation/MARATHON.example.yaml` → byte-identical phase
table before and after). Fix (3) is a *code* change to `bin/marathon-yaml` plus a regression test,
so it is not doc-only and is not in this change. It remains worth doing as defence-in-depth — the
docs fix prevents an author from writing the list form, while (3) would catch the one who writes it
anyway — but the misleading error is now documented at the exact place the mistake is made.

### QA checklist — Phase 0

- [x] The repro is confirmed from the report, not assumed — claim (2) reproduced against a local
      fixture; claim (1) checked and **partially falsified** (see findings), fix re-scoped as a
      result rather than applied as filed
- [x] A regression test covers the failure path before the fix lands — **N/A for this docs-only
      change** (no runtime behavior is modified). This gate becomes live if fix (3) is taken: it
      would need a `marathon-yaml` case asserting the list form fails with the shape-specific message
- [x] The fix composes with the existing harness rather than adding a parallel path — both edits land
      in the existing header and field table; no new doc, no new file

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "bin/marathon-yaml", "pattern": "flow sequence" }
  ],
  "artifacts": [ "bin/marathon-yaml", "test/marathon-yaml.sh" ],
  "remediation": {
    "source": "issue#241",
    "criteria": "bin/marathon-yaml rejects a depends_on YAML flow-sequence ('[...]') form with a message naming the field's shape (scalar / single phase id), instead of the generic 'depends_on unknown phase' lookup at ~L102-105; a test/marathon-yaml.sh case asserts the list form fails with the shape-specific message and that a scalar depends_on still parses; bash validate.sh no worse than baseline."
  },
  "lanes": { "agy_safe": [ "bin/marathon-yaml", "test/marathon-yaml.sh" ], "orchestrator_only": [] }
}
```

> **Contract auto-drafted 2026-07-20 (flagged for operator verification).** The `fix_probes` pattern
> `flow sequence` is a best-effort bug-present marker (currently absent in `bin/marathon-yaml`, so the
> lane reads ready); reconcile it with the actual error string the fix introduces before relying on the
> stale/exit-4 verdict.
