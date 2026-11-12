---
title: Reviewer approves without running the gate after builder flags unverified assertions; Codex builder sandbox blocks localhost
status: Proposed (1-INBOX — not yet active)
created: 2026-11-11
owner: Noel Saw
gh_issue: 1428
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1428
doc_type: bugfix
complexity: 3
risk: 4
effort: 3
phases: 1
ratings_provisional: true
reported_from: LTVera-Pandas
harness_commit: 046b41538
non_goals:
  - Changing gate selection or the pre-advance gate itself
related:
  - "#1426"
  - "#1427"
goal: >
  A reviewer cannot attest Approved without running (or explaining why it cannot run) the phase gate,
  especially after the builder records unverified gate assertions; Codex builders have an opt-in path to
  localhost services or a preflight warning when they lack one.
---

# GH-1428 — Reviewer approves unverified work; Codex builder cannot reach localhost

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward.

## Environment
- **Observed from:** `LTVera-Pandas` (vendored `.xyz/`)
- **Harness commit:** `046b41538`
- **Worker/CLI:** codex-cli 0.167.0-alpha.3.2 (builder), claude 2.1.322 claude-sonnet-4-6 (reviewer)
- **Runtime:** Python (default)
- **Sandbox:** off for the driver; Codex workspace-write sandbox for the builder

## Symptom

Marathon relay `--builder codex --reviewer claude-reviewer`: the builder wrote in RELAY.md that its DB-backed assertions were **unverified** because "sandbox access to `localhost:55461` was denied … harness must run the specified gate with database access". The Claude reviewer then **Approved** after 13 Bash calls that were all `ls`/`grep`/`tick`, with no test execution, although it had Bash and a reachable DB. The pre-advance gate failed on the exact assertion the builder had flagged. This happened twice on the same item (once without a DB, once with one).

## Observed

| Claim | Source | Observed |
|---|---|---|
| Builder flagged unverified work | builder round-1 entry in RELAY.md | "Persisted-row/KPI assertions remain unverified here; harness must run the specified gate with database access." |
| Reviewer did not run the gate | reviewer `claude -p` session transcript | 13 Bash calls, 0 pytest; `tick done` → attested Approved |
| Gate then failed on the flagged path | marathon-drive pre-advance gate | `FAILED …::test_refresh_skips_inactive_and_bigquery_only_tenants` (CheckViolation) |
| Codex builder can't reach localhost services | builder report | sandbox denied `localhost:55461` (Codex workspace-write sandbox has network off) |

## Root cause

Root cause: the reviewer turn has no obligation to execute the phase gate (or the builder's named verification) before Approved, and nothing blocks an Approved after the builder explicitly records unverified gate assertions. Separately, the Codex builder's sandbox has no network, so it cannot run localhost-DB tests. Fix site: the reviewer prompt/attestation contract in the relay/marathon turn rendering, plus a documented Codex network knob for marathon builders. Why not downstream: the gate catches it, but only after a full approved relay, and each round costs a Jog slot.

## Acceptance

- [ ] The reviewer's TAKE YOUR TURN steps require running the phase's pre-advance gate (or naming why it can't) before writing Approved; attestation records whether the gate ran. Red control: this transcript (Approved, 0 test runs).
- [ ] When the builder's entry declares unverified gate assertions, an Approved without reviewer-run evidence is refused or downgraded. Red control: the RELAY.md + Approved pair above.
- [ ] A documented, opt-in way to give a Codex marathon builder localhost network (e.g. sandbox network access), or a preflight warning when the gate needs a local service and the builder lane can't reach it.
- [ ] Existing relay/marathon suites pass; evidence under `TESTS-RESULTS/` (GH-831).

## PRS proposal

pri 70: review approvals aren't evidence when the reviewer never executes anything; it cost two Jog rounds on one item.
sev 60: wrong code reaches PR-ready state if a gate is weak; here the gate caught it.
appeal 60: makes Codex-build/Claude-review lanes trustworthy.
effort 55: prompt/attestation contract plus one Codex config knob.

## Phase 0 — Diagnose & scope

### Checklist
- [ ] Reproduce: a relay where the builder records unverified gate assertions, then the reviewer approves without running tests
- [ ] Locate the reviewer TAKE YOUR TURN rendering and attestation write-set
- [ ] Find the existing Codex sandbox config seam for network access (`/ponytail`: reuse, don't add)
- [ ] Set real ratings; clear `ratings_provisional`

### QA checklist — Phase 0
- [ ] Repro confirmed from the report, not assumed
- [ ] Existing suite or recorded manual check covers the failure path before the fix lands (GH-831)
- [ ] Fix composes with the existing harness rather than adding a parallel path
