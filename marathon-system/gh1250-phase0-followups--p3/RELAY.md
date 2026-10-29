# Marathon Phase p3
STATUS: Open
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-P3-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

---
gh_issue: 1251
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1251
title: "GH-522 slice 1: marathon planner fails closed on unknown preflight exits, missing dependencies and unplaceable lanes"
status: Active
created: 2026-10-29
updated: 2026-10-29
owner: noelsaw1
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
phases: 1
goal: "Every planner outcome that is not a positive readiness signal holds the item with a named reason; nothing unknown, unresolved or unplaceable is packed into an active wave."
non_goals:
  - "#522's model spike, hourly monitor, plan-in-GitHub gate and automatic membership writes."
  - "The frozen Bash planner twin (GH-362); Python is authoritative."
related:
  - "Parent umbrella #522 (stays open; this slice Refs it)"
  - "Marathon umbrella #1250 (lane L4)"
  - "GH-1175 Phase 0 evidence: ledger fields admitted 5 issues that all failed live checks"
---

# GH-1251: marathon planner fails closed (GH-522 slice 1)

## Status

| What was just completed | What's next |
|---|---|
| Promoted for marathon #1250 (lane L4) with plan, acceptance and contract | Codex plan QA, then build |

## Observed (development 93f41cb8, `utils/py/_marathon_plan.py`)

1. **Deep delegation** (`:1021-1048`) maps preflight exits 4 to already-landed, 5 to not-ready, and 6/7 to blocked. Any other nonzero exit (1 from `OSError`, 2 usage, 3 invalid contract, 127, signals) leaves `state == "ready"`, so the item is waved.
2. **A dependency not in the ledger** (`:1052-1057`) gets only an info flag, `dep-not-found`. The dependent stays ready because the resolution loop skips a missing dep (`:1061`, `if not dep … continue`), and so does wave packing (`:1147`).
3. **The no-progress wave fallback** (`:1163-1168`): when nothing in `pending` can be placed, every deferred lane is appended as **one** wave. The demonstrated triggers are a ready dependency cycle (resolution allows ready deps at `:1061`, but neither is in `placed_issue` at packing, `:1145-1151`) and a zero zone cap. Ordinary collisions and positive caps do not trigger it, because the first lane always enters an empty wave.

Held states feed the exit code at `:1194-1203` (`held` → 5).

## Plan (one phase)
All changes are in `utils/py/_marathon_plan.py`:
1. **Deep delegation:** add `elif code == 3: state "needs-contract"` with the reason "swarm-preflight --dry-run → invalid contract (exit 3)". Then add `elif code != 0: state "preflight-error"` with a flag naming the code ("unknown/failed preflight exit N — hold; rerun swarm-preflight directly").
2. **Missing dependency:** in the resolution loop, treat a dep with no ledger row (`not dep`) as blocking. `blocked_by` includes it, so the dependent becomes `blocked-dep`. The existing `dep-not-found` flag keeps its message.
3. **No-progress fallback:** replace the packing at `:1163-1168` with holding. Each remaining deferred lane gets the held state `unplaceable`, with a flag ("could not be placed in any wave (dependency cycle / zero zone cap) — hold, do not co-wave"). Then `break`. After packing, recompute `active` (captured at `:1131`) as the lanes actually placed, so the summary counts (`:1262-1274`) and the scoring table (`:1373`) do not report a lane as both active and held.
4. **Held set and rendering:**
   - add `"preflight-error"` and `"unplaceable"` to the `held` tuple (`:1196-1197`);
   - add them to the existing "⚠️ Not yet sequenceable" bucket at `:1425-1432`, since it has explicit buckets rather than generic rendering;
   - keep exit precedence: drift (4) still outranks held (5), so exit 5 is expected only when there is no drift.

**Phase 0 inside the lane** (record findings in a `## Phase 0` section of the lane's `smoke.md` before building; the orchestrator copies them into this doc):
- grep the planner fixtures for missing-dependency and cycle cases. Plan QA found that scenario G covers a present-but-held dependency (`test/marathon-plan.sh:234`), not a missing row, and that scenario T has neither a cycle nor deep delegation (`:629-685`), so its parity should not change;
- update only an assertion that truly pins the old behaviour, adding no scenario (GH-831);
- do not broaden the GH-698 rendered-table skip (`:688-697`) to hide any other failure.

Write-set:
- `utils/py/_marathon_plan.py`;
- existing planner test files only where Phase 0 shows an assertion pins old behaviour;
- the evidence bundle, `TESTS-RESULTS/2026-10-29+GH-1251/smoke.md` and `provenance.jsonl`;

This doc (Phase 0 findings copied from `smoke.md`, and the Status row) is updated by the orchestrator.

Full route.

## Acceptance

- [ ] A deep-preflight exit other than 0, 4, 5, 6 or 7 (including 1, 2, 3, 127 and signals) holds the item with a named reason and planner exit 5 instead of leaving it ready.
- [ ] A dependency that is not in the ledger holds the dependent item (`blocked-dep`) instead of only warning.
- [ ] When no ready lane can be placed in a wave, the remaining lanes are held with a named reason instead of being packed together into one wave.
- [ ] Existing planner suites stay green, changed only where they pin the old advisory behaviour, and a manual smoke receipt under `TESTS-RESULTS/` shows each seam with a base red control; no new tests (GH-831).

## Verification

- **Existing suites:** `test/marathon-plan.sh`, `test/gh418-planner-ledger-source.sh`, `test/gh308-frozen-twin-guard.sh`, `test/gh362-marathon-plan-link-bullets.sh`, `test/gh423-roadmap-render.sh`, and the routed full gate, in a disposable full clone.
- **Manual smoke** (`TESTS-RESULTS/<date>+GH-1251/`): run `marathon_plan.py --dry-run --deep` against a fixture ledger with three cases, on the fix and at base `93f41cb8`:
  - a stub `SWARM_PREFLIGHT` exiting 2, then 3, then 127: held with a named reason and exit 5 on the fix; at base the item is waved;
  - a dependency on a missing issue: held on the fix; waved at base;
  - two ready items that depend on each other (a cycle), so neither can ever be placed first: held as `unplaceable` on the fix; co-waved in one wave at base.

Rollback: revert one commit. The planner returns to advisory behaviour.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh --auto development",
  "fix_probes": [
    {
      "type": "grep_absent",
      "path": "utils/py/_marathon_plan.py",
      "pattern": "preflight-error"
    },
    {
      "type": "grep_absent",
      "path": "utils/py/_marathon_plan.py",
      "pattern": "unplaceable"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-29+GH-1251/smoke.md"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-29+GH-1251/provenance.jsonl"
    }
  ],
  "artifacts": [
    "utils/py/_marathon_plan.py",
    "TESTS-RESULTS/2026-10-29+GH-1251/smoke.md",
    "TESTS-RESULTS/2026-10-29+GH-1251/provenance.jsonl"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-10-29+GH-1251/smoke.md",
    "TESTS-RESULTS/2026-10-29+GH-1251/provenance.jsonl"
  ],
  "remediation": {
    "source": "issue#1251",
    "criteria": "Unknown deep-preflight exits hold (preflight-error), missing deps block, no-progress lanes hold (unplaceable); held feeds exit 5."
  },
  "lanes": {
    "agy_safe": [
      "utils/py/_marathon_plan.py",
      "TESTS-RESULTS/2026-10-29+GH-1251/smoke.md",
      "TESTS-RESULTS/2026-10-29+GH-1251/provenance.jsonl"
    ],
    "orchestrator_only": []
  }
}
```


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): utils/py/_marathon_plan.py, TESTS-RESULTS/2026-10-29+GH-1251/smoke.md, TESTS-RESULTS/2026-10-29+GH-1251/provenance.jsonl
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick
   - /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick claim MARATHON-P3-TURN --agent agy --paths "marathon-system/gh1250-phase0-followups--p3/RELAY.md,utils/py/_marathon_plan.py, TESTS-RESULTS/2026-10-29+GH-1251/smoke.md, TESTS-RESULTS/2026-10-29+GH-1251/provenance.jsonl"
   - /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick ping MARATHON-P3-TURN --agent agy
   - /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick release MARATHON-P3-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh1250-phase0-followups--p3/RELAY.md and utils/py/_marathon_plan.py, TESTS-RESULTS/2026-10-29+GH-1251/smoke.md, TESTS-RESULTS/2026-10-29+GH-1251/provenance.jsonl. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/_marathon_plan.py, TESTS-RESULTS/2026-10-29+GH-1251/smoke.md, TESTS-RESULTS/2026-10-29+GH-1251/provenance.jsonl. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick release MARATHON-P3-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick done MARATHON-P3-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick
   Edit ONLY marathon-system/gh1250-phase0-followups--p3/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
4c. A finding that asks for a behaviour change is a generalization unless you can paste the concrete
   input — a row, a value, a `file:line` — that fails under the current code (GH-681). Every
   `[Blocker]` or `[Should]` requesting a behaviour change MUST carry `Observed input:`,
   `Affected scope:` and `Falsifier:` lines; a `[Blocker]` must cite an observed failure. The Builder
   may disposition a request lacking these as `Declined — unproven generalization`.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to agy —
   agy, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.


### Round 1 · Builder · agy

- **Files touched:**
  - `utils/py/_marathon_plan.py`
  - `TESTS-RESULTS/2026-10-29+GH-1251/smoke.md`
  - `TESTS-RESULTS/2026-10-29+GH-1251/provenance.jsonl`
  - `marathon-system/gh1250-phase0-followups--p3/RELAY.md`
- **Key decisions & implementation:**
  1. **Phase 0 fixture check (`smoke.md`):** Grepped all planner suites (`test/marathon-plan.sh`, `test/gh418-planner-ledger-source.sh`, `test/gh362-marathon-plan-link-bullets.sh`, `test/gh423-roadmap-render.sh`). Confirmed Scenario G tests a present-but-held dependency, Scenario T has neither a cycle, missing dep, nor `--deep`, and no existing test assertion pins the old advisory behaviour on missing deps, unknown preflight exits, or unplaceable cycles. Zero test files needed edits (GH-831).
  2. **Deep delegation (`utils/py/_marathon_plan.py`):** Added `code == 3` → `state = "needs-contract"` (`"swarm-preflight --dry-run → invalid contract (exit 3)"`) and `elif code != 0:` → `state = "preflight-error"` (`"unknown/failed preflight exit %d — hold; rerun swarm-preflight directly" % code`).
  3. **Missing dependency resolution (`utils/py/_marathon_plan.py`):** Changed `if not dep or dep["state"] in DEP_RESOLVED or dep["state"] == "ready":` to `if dep and (dep["state"] in DEP_RESOLVED or dep["state"] == "ready"):` so a missing ledger dependency (`not dep`) is appended to `blocked_by` and transitions the dependent item to `blocked-dep` while retaining the `dep-not-found` flag.
  4. **No-progress wave fallback (`utils/py/_marathon_plan.py`):** Replaced the `len(wave) == 0` co-waving fallback with holding each remaining deferred lane as `state = "unplaceable"` (`"could not be placed in any wave (dependency cycle / zero zone cap) — hold, do not co-wave"`), then `break`. Recomputed `active = [r for w in waves for r in w]` after packing so summary counts and the per-item scoring table only include placed lanes.
  5. **Held set & rendering (`utils/py/_marathon_plan.py`):** Added `"preflight-error"` and `"unplaceable"` to the `held` tuple (feeding exit code `5` when `has_drift` is false) and to the `"⚠️ Not yet sequenceable — rate / add doc / add contract"` bucket in `_render_queue_doc`.
  6. **Verification:** Targeted suites (`test/marathon-plan.sh`, `test/gh418-planner-ledger-source.sh`, `test/gh362-marathon-plan-link-bullets.sh`, `test/gh423-roadmap-render.sh`, `test/gh308-frozen-twin-guard.sh --check --base development`) all pass, and manual smoke with base `93f41cb8` red controls is recorded in `TESTS-RESULTS/2026-10-29+GH-1251/smoke.md` and `provenance.jsonl`.
