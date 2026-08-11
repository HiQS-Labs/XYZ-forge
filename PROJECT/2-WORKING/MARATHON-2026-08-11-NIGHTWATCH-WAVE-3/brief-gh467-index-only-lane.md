---
title: "Phase brief: GH-467 gh467-index-only-lane (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-08-11
updated: 2026-08-11
owner: noel
goal: >
  Phase-brief input consumed by the marathon driver for the gh467-index-only-lane phase of
  MARATHON-2026-08-11-NIGHTWATCH-WAVE-3 — not itself an active-doc capture; the canonical capture doc
  is GH-467-INDEX-ONLY-LANE-GIT-BAN.md two levels up.
roadmap_exempt: true
---

# Brief — GH-467: refuse an index-only lane at preflight instead of dispatching it to fail

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-10 in the Nightwatch batch-2 doc fan-out. The issue deliberately declines to pick a shape ("Not choosing here"), so criteria were authored for **option 3 only** and the reasoning recorded. The contract was **rejected by preflight on 2026-08-11** and fixed — see "The contract was wrong". Preflight after the fix: **ready (exit 0)**, issue **OPEN**. | Fire as phase 3 of 3, LAST, because it modifies the preflight tool that gates future waves. |

**Parent capture doc:** `PROJECT/2-WORKING/GH-467-INDEX-ONLY-LANE-GIT-BAN.md`
**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/467

## Acceptance

**Read the acceptance criteria from the parent capture doc's authored acceptance block**, which is
scoped to **option 3 only**. The issue lists three options and picks none.

## The defect

Every builder packet says **"Do NOT run git"**, verbatim at `relay-automation/marathon-drive.sh:1017,1023`
and `utils/py/marathon_drive.py:1757,1772`. So a lane whose *deliverable is an index change* — untrack
a file, change what is staged — is dispatched to a builder that is forbidden from performing its own
work. It cannot succeed, and nothing says so until it fails.

## The ban is PROTECTIVE. Do not remove it.

This is the single most important line in this brief. The rationale is real and documented
(`relay-automation/relay-turn-lib.sh:1026-1053`,
`PROJECT/3-COMPLETED/RELAY-CONTAINMENT-HARDENING.md:31`): the harness performs the commit itself, and
a builder that commits mid-turn has previously **reset HEAD and orphaned a peer agent's commit**.

Any change that lifts, weakens, or conditionally bypasses the ban is out of scope and should be
treated as a mis-scoped lane. The fix is to **refuse the lane early**, not to let the builder do git.

## Why option 3, and not 1 or 2

| option | write-set | why not |
|---|---|---|
| 1 — driver grants a narrow git verb | `marathon_drive.py` | **the running driver** — can never be a marathon lane |
| 2 — allowlist verb in `rtl_enforce` | `relay-turn-lib.sh` / `rtl.py` | **the turn kernel** — the most protected file in the repo; "a narrow allowlist verb" understates it badly |
| **3 — declare intent, preflight refuses** | `utils/py/swarm_preflight.py` | ✅ no driver, no kernel — the only one that is fireable |

## The fact the issue omits, and it changes the size of the job

`lanes.orchestrator_only` **already exists** in `utils/py/swarm_preflight.py:199-234` (`lane_plan()`).
But it is **advisory only — nothing outside that file reads `orchestrator_owned`**. Verified.

So "preflight refuses to dispatch" is **new behaviour**, not wiring up something that already works.
Do not assume the plumbing exists because the field does.

## The contract was wrong, and preflight caught it

On 2026-08-11 this lane's own contract was **rejected outright**:

```
CONTRACT ERROR: artifacts_new entry 'test/gh467-index-only-lane-blocked.sh'
has no matching fix_probes entry of type path_absent on the same path
```

A `path_absent` probe was added and the lane went ready. Worth knowing as a builder: the new test
file you are expected to create is itself a probe target, so **the lane is only satisfied once that
file exists**. Not creating it leaves the bug reported as still-present.

## Also missing, and part of the job

**No test asserts the "Do NOT run git" string is present.** So the ban could be silently weakened by a
future change with nothing going red. Add a regression guard for it alongside the new refusal test —
a protective instruction with no test is one edit away from disappearing.

## Write-set

- `utils/py/swarm_preflight.py`
- `test/gh467-index-only-lane-blocked.sh` — **NEW**
- `validate.sh` — register the new test

`utils/py/swarm_preflight.py` is the **authoritative (Python)** half of a frozen twin pair; the Bash
twin `utils/swarm-preflight.sh` is **out of scope** and must not be touched — doing so would need a
`Frozen-twin-exception:` trailer.

## Containment note — read before you start

This lane modifies **the preflight tool itself**, which is what verdicts future marathon waves. It is
sequenced LAST for that reason: a defect lands on its own gate with no phase after it to damage.
Preflight for *this* wave already ran and is recorded, so nothing in this run depends on the tool you
are changing.
