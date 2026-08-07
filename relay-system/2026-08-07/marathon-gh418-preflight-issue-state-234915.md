# Marathon Phase gh418-preflight-issue-state
STATUS: Open
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH418-PREFLIGHT-ISSUE-STATE-TURN builder=codex reviewer=agy round-cap=7 -->

## Phase Brief

---
title: "Phase brief: GH-418 gh418-preflight-issue-state (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-08-06
updated: 2026-08-06
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the
  gh418-preflight-issue-state phase of MARATHON-2026-08-06-LITMUS — not itself an active-doc
  capture; the canonical capture doc is GH-418-PREFLIGHT-ISSUE-STATE-FROZEN.md two levels up.
roadmap_exempt: true
---

# Brief — GH-418: preflight must check issue state and the FROZEN banner

## Status

| What was just completed | What's next |
|---|---|
| Contract authored and verified READY via `--dry-run`; acceptance reads `match — 6/6 criteria copied verbatim from issue #418`. Designated FIRST CHILD of #419. | Fire as marathon phase 3 of 4, after gh419 (which builds the inventory this lane records into) and gh343 (same file). |

**Parent doc:** `PROJECT/2-WORKING/GH-418-PREFLIGHT-ISSUE-STATE-FROZEN.md`
**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/418

## Acceptance

**Read the acceptance criteria from the parent capture doc's `## Acceptance` block**, copied
verbatim from the issue (6/6, no deviations). Do not work from a paraphrase — see GH-400.

This lane closes **under #419's policy**, as its first child: its negative control must be recorded
in the gate inventory that phase 1 of this marathon builds. That is criterion 8 of #419 as well as
this lane's own requirement — demonstrating the contract on a real gate before anything is asked of
the rest of the tree.

## The gap

`swarm-preflight` decides whether a lane is fireable. It validates the contract's **internal
consistency** — artifacts exist, probes still detect the bug, the base is fresh — but never asks the
two questions that actually determine whether the work should run:

1. **Is the issue still open?** No issue-state check exists at all.
2. **Are the target files writable by policy?** No knowledge of the GH-308 `FROZEN` banner.

So a lane can read READY, emit a packet, and send a builder to edit a frozen Bash twin to close an
issue that closed two weeks ago. Every gate reports green.

### Measured cases

From the read-only triage of 2026-08-03 that retired four marathon plans:

| Plan | Lanes | Live state |
|---|---|---|
| J (2026-07-18) | #238, #239 | **both CLOSED** — shipped via PR #243 the next day |
| K (2026-07-19) | 17 lanes | **16 CLOSED**, only #191 open (self-described deferred backlog) |
| 2026-07-23 | #279, #280 | **#279 CLOSED**, #294 CLOSED, #280 open as bookkeeping only |
| M (2026-07-20) | #226 | #226 **CLOSED**; targets `relay-automation/consult.sh`, which is **FROZEN** |

Plan M is the sharpest: its Lane C gates on *"any stamp string added to `consult.sh` must appear in
`consult.py` and vice-versa"* — following that plan's own gate would violate GH-308.

### A ninth case, produced by this marathon

While this plan was being authored, **#368 was selected as a lane** on the strength of a capture doc
reading "not yet fired". It had already been fixed and merged (PR #433, `3a6ddfc`) and the issue
closed 2026-08-06T15:46:01Z. Preflight would have passed it READY. It was caught only by a
hand-check of the live issue state — the exact manual step this lane exists to remove. Use it as a
test case: it is fresher than the 2026-08-03 set and its artifacts are still on disk.

## Why the plumbing makes this cheap

Before #400, neither preflight twin invoked `gh` at all. #400 added an issue-body fetch to
`utils/py/swarm_preflight.py`:

```python
subprocess.run(["gh", "issue", "view", str(issue_number), "--json", "body", "-q", ".body"], ...)
```

Adding `state` to that same `--json` list is **one field on a call that already happens** — no new
network path and no new offline contract, since #400's degradation rules already cover the
unreachable case. The frozen-file check is a local read against artifacts the contract already
enumerates.

## What to build

**Phase 1 — issue state.** Fetch `state` on the existing call; record it in `run-candidate.json` on
**every** run, including when undeterminable. A CLOSED issue must not silently read READY: report it
prominently, and state in the emitted packet that the issue was closed and when, so the builder's
own context carries the fact.

**Phase 2 — the FROZEN banner.** An artifact path carrying the GH-308 banner sets NOT-READY with
**no packet written**, naming the file and pointing at its authoritative twin. Read the banner from
the file on disk — *not* a hardcoded list — so a newly frozen twin is covered without editing
preflight. (`utils/marathon-plan.sh` became the 12th frozen twin via GH-362; a hardcoded list would
already be stale.)

## Deliberate non-goals — do not exceed them

- **Do not block on undeterminable issue state.** No `gh`, unauthenticated, or offline reports
  `unknown` loudly and does not block, matching #400's degradation contract exactly. An unreachable
  network is not evidence of staleness.
- **Do not block on a CLOSED issue outright.** Some lanes legitimately follow up on a closed issue.
  The requirement is that the operator is *told*, not that the run is forbidden. Only the FROZEN
  check sets NOT-READY.
- **Do not auto-retire stale plan docs.** Reporting is in scope; filesystem mutation is not.
- **Do not touch `utils/swarm-preflight.sh`** — frozen by GH-308.

Register `test/gh418-issue-state-frozen.sh` in `validate.sh`'s `TESTS` array.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/py/swarm_preflight.py,test/gh418-issue-state-frozen.sh,validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick
   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick claim MARATHON-GH418-PREFLIGHT-ISSUE-STATE-TURN --agent codex --paths "phases/litmus-trustworthy-gates-2026-08-06--gh418-preflight-issue-state/RELAY.md,utils/py/swarm_preflight.py,test/gh418-issue-state-frozen.sh,validate.sh"
   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick ping MARATHON-GH418-PREFLIGHT-ISSUE-STATE-TURN --agent codex
   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick release MARATHON-GH418-PREFLIGHT-ISSUE-STATE-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/litmus-trustworthy-gates-2026-08-06--gh418-preflight-issue-state/RELAY.md and utils/py/swarm_preflight.py,test/gh418-issue-state-frozen.sh,validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/swarm_preflight.py,test/gh418-issue-state-frozen.sh,validate.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick release MARATHON-GH418-PREFLIGHT-ISSUE-STATE-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick done MARATHON-GH418-PREFLIGHT-ISSUE-STATE-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick
   Edit ONLY phases/litmus-trustworthy-gates-2026-08-06--gh418-preflight-issue-state/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.

### Round 1 · Builder · codex

Implemented GH-418 only in `utils/py/swarm_preflight.py`, `test/gh418-issue-state-frozen.sh`, and
`validate.sh`. The existing `gh issue view` request now retrieves `body,state,closedAt` together;
`readiness.issue_state` records `OPEN`, `CLOSED`, or advisory `unknown` in emitted candidates, and
CLOSED state plus its close time is surfaced in both the preflight output and builder packet without
blocking the lane. Declared artifacts are scanned at `target.ref` for the on-disk GH-308 `FROZEN`
banner; a match is NOT-READY, names the artifact and twin parsed from its banner, and emits no packet.
Registered a hermetic 5-assertion regression using the real `relay-automation/consult.sh` measured
case; it passed with `bash test/gh418-issue-state-frozen.sh` (5 pass, 0 fail).
