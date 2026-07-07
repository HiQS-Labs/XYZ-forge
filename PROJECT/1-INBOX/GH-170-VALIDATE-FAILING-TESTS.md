---
gh_issue: 170
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/170
title: "validate.sh: 9 pre-existing failing tests (analyze/cost/watchdog-relay/deep-research/relay-token-collision/new-relay/find-harness/transcript-audit/marathon-plan)"
status: Queued (1-INBOX) — queued for today's marathon (Marathon Plan F)
created: 2026-07-07
updated: 2026-07-07
owner: noel
doc_type: bug
complexity: 3
risk: 2
effort: 4
phases: 1
ratings_provisional: true
non_goals:
  - Not a claim all 9 share one root cause — items 1 and 5 are the same flake *class* (state leak
    across test runs) but different mechanisms; the rest look mutually independent
  - Not scoping a rewrite of any touched subsystem — narrow, targeted fixes only
related:
  - test/analyze.sh
  - test/cost.sh
  - test/watchdog-relay.sh
  - test/deep-research.sh
  - test/relay-token-collision.sh
  - test/new-relay.sh
  - test/find-harness.sh
  - test/transcript-audit.sh
  - test/marathon-plan.sh
  - PROJECT/3-COMPLETED/GH-133-RELAY-DEP-DRIFT-FLAKE.md
  - PROJECT/3-COMPLETED/GH-150-MARATHON-PLAN-DOCOF-POINTER.md
goal: >
  Triage-then-fix validate.sh's 9 pre-existing failing gates, confirmed unrelated to any recent
  change (reproduced identically against a parent-commit worktree during GH-165 review, and again
  via git stash during the 2026-07-07 GH-158/161/162/164 housekeeping pass). Each item below is an
  independent, parallel-safe fix lane — no shared write-set between them.
roadmap_exempt: false
---

## Key concepts

- `validate.sh` currently reports 9 failures out of ~104 gates. None are new — all 9 were confirmed
  pre-existing before today's housekeeping/merge work touched the repo.
- Two items (1, 5) are confirmed FLAKY (non-deterministic across repeated local runs) and share the
  same general "state leaks across test-fixture runs" family as the already-fixed GH-133, though
  via different mechanisms (SIGPIPE vs. fixture task-name collision).
- The other 7 are deterministic single- or few-assertion failures, each isolated to one test file /
  one code path — no evidence of a shared root cause across them.
- Item 9 (marathon-plan.sh) touches the same file GH-150 already fixed once (`docOf()` pointer
  logic) — worth checking whether this is an adjacent gap in the same detection code, not a
  reintroduction of GH-150's own bug.

# GH-170 · validate.sh's 9 pre-existing failing tests

## Status

| What was just completed | What's next |
|---|---|
| Triaged all 9 failures 2026-07-07 to concrete failure signatures (see Findings below); none root-caused or fixed yet. Doc authored and queued into [Marathon Plan F](../2-WORKING/MARATHON-PLAN-2026-07-07-F-VALIDATE-FIXES.md) as 9 independent lanes. | Fire the marathon: each lane root-causes and fixes its one test file, in isolation (own `ALLOW_PATHS`), then confirms `validate.sh` gains that gate back without regressing any other. |

## Findings (2026-07-07 triage)

### 1. `test/analyze.sh` — SIGPIPE-class flake
`echo: write error: Broken pipe` then `FAIL: expected created:3` / `FAIL: expected claimed:3`.
Same flake class as the already-fixed [GH-133](../3-COMPLETED/GH-133-RELAY-DEP-DRIFT-FLAKE.md): a
piped command closing early cuts off `analyze`'s own stdout mid-write.
**Fix direction:** capture-then-match instead of pipe-and-quit, same pattern GH-133 used
(`git log ... | grep -q` → capture the log, then `[[ "$log" == *pattern* ]]`).

### 2. `test/cost.sh` — cost-only agent leak
`FAIL: cost-only agent leaked into agents[]`. Deterministic. A cost-only/no-work agent is appearing
in a list it should be filtered out of.
**Fix direction:** find the `agents[]` builder in the cost-tracking source and add/fix the filter
that should exclude cost-only (no actual work) entries.

### 3. `test/watchdog-relay.sh` — malformed self-generated JSON
`FAIL: stalled RELAY-TURN not escalated: watchdog: analysis is not valid JSON: Unterminated string
in JSON at position 512 (line 21 column 13)`. The watchdog's own generated "analysis" JSON is
malformed — likely an unescaped multiline string embedded into hand-built JSON — which then fails
the downstream escalation check.
**Fix direction:** find where the watchdog serializes its analysis object and use a real JSON
encoder (or properly escape embedded strings) instead of string concatenation.

### 4. `test/deep-research.sh` — missing config field
`FAIL: raw config missing searchContextSize` (44/45 pass otherwise). Narrow — looks like a
fixture/mock response missing a field the test now expects.
**Fix direction:** compare the fixture/mock against the current real response shape; add the
missing field or update the fixture to match.

### 5. `test/relay-token-collision.sh` — CONFIRMED FLAKY
1/3 local runs green. `'RELAY-custom' is spent from a prior relay; seed + drive with a fresh
--relay-task`. Smells like fixture task-name collision / leftover token state bleeding across test
cases in the same file.
**Fix direction:** audit the fixture setup for shared/reused task names across cases in this file;
give each case its own unique `--relay-task`, or add explicit teardown between cases.

### 6. `test/new-relay.sh` — possible stale assertion
`FAIL: missing NEXT (out: # RELAY · Review My PR ...)` but the captured output DOES contain
`NEXT: Reviewer`. Looks like the assertion is checking a stale exact string/position rather than a
real template regression.
**Fix direction:** diff the assertion's expected string against the actual current relay-file
template output before touching anything — confirm this is test drift, not a real regression, then
fix the assertion (or the template, if it turns out to be real).

### 7. `test/find-harness.sh` — 2 failures, vendor-detection path
"foreign no-.xyz: emits the concurrency warning" and "vendored .xyz: resolves to the local .xyz".
Touches the vendored `.xyz/` harness-copy detection path — may be environment/device-state-sensitive
(this device currently has several vendored `.xyz/` copies on disk elsewhere via `xyz-sync.sh`)
rather than a pure code bug.
**Fix direction:** first confirm whether the failure reproduces in a clean/isolated fixture
environment (no ambient vendored copies) — if it only fails here because of this device's local
vendor state, the test's fixture isolation is the actual bug, not the detection logic itself.

### 8. `test/transcript-audit.sh` — missing audit line
`FAIL: stale-ref: no 'AUDIT stale-ref' line found in output` (6/7 pass). Narrow, likely an
output-format/label drift between what the audit tool emits and what the test expects.
**Fix direction:** run the audit tool standalone against the test's fixture, compare actual output
against the expected string literally.

### 9. `test/marathon-plan.sh` — one shared root cause, 4 assertions
4 failures all inside one "B:" scenario group (`#220 not flagged partial`, `#230 not flagged
unrated`, `dead pointer not flagged`, `note-only not flagged`) — one shared root cause in a single
detection code path, not 4 separate bugs (54/58 pass otherwise). Same file as the already-shipped
[GH-150](../3-COMPLETED/GH-150-MARATHON-PLAN-DOCOF-POINTER.md) `docOf()` fix.
**Fix direction:** trace the "B:" scenario's detection path (partial/unrated/dead-pointer/note-only
flagging) in `utils/marathon-plan.sh`; check whether GH-150's fix narrowed the `docOf()` selection
in a way that also broke this adjacent flagging logic.

## Phase 0 — Fix and regression-verify (all 9, independent lanes)

### Checklist

- [ ] Lane 1 — analyze.sh: fix SIGPIPE flake (capture-then-match), confirm 5x clean runs
- [ ] Lane 2 — cost.sh: filter cost-only agents out of `agents[]`
- [ ] Lane 3 — watchdog-relay.sh: fix malformed self-generated analysis JSON
- [ ] Lane 4 — deep-research.sh: add missing `searchContextSize` to fixture/response
- [ ] Lane 5 — relay-token-collision.sh: fix fixture task-name collision, confirm 5x clean runs
- [ ] Lane 6 — new-relay.sh: confirm stale assertion vs. real regression, fix accordingly
- [ ] Lane 7 — find-harness.sh: confirm environment-sensitivity vs. real bug, fix accordingly
- [ ] Lane 8 — transcript-audit.sh: fix stale-ref output/assertion mismatch
- [ ] Lane 9 — marathon-plan.sh: root-cause the shared "B:" scenario detection gap

### QA checklist — Phase 0

- [ ] Each lane's fix is scoped to its own test + source file(s) — no shared write-set between lanes
- [ ] Flaky lanes (1, 5) verified across multiple repeated runs, not just one green run
- [ ] Full `validate.sh` re-run after all lanes land: 104/104 (or documents any gate still red with
      a reason)
- [ ] No lane's fix regresses a currently-passing gate
