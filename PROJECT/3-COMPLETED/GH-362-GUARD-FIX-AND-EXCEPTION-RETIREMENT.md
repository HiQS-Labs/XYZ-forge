---
gh_issue: 362
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/362
title: "GH-362 — the freeze guard could not pass a range containing the freeze itself, and rejected the trailer format already in history; plus marathon-plan's exception retired"
status: "Shipped: both guard defects fixed with 4 new cases (32/0), proved by A/B against the pre-fix guard on identical input (old rc=1, new rc=0). marathon-plan retired as GH-308's exception and frozen as the 12th twin; its pinning assertion inverted rather than deleted."
created: 2026-07-29
updated: 2026-07-29
owner: noel
doc_type: fix
complexity: 2
risk: 2
effort: 2
ratings_provisional: false
related:
  - "#361 — the release PR whose CI first exposed both defects; merged with the check red, after diagnosis"
  - "#321 / PR #328 — introduced the per-file trailer format that rejects its own history"
  - "#340 / PR #341 — deleted the copied node engine, which was the entire rationale for marathon-plan's exception"
  - "#348 — the parity gate that makes freezing marathon-plan safe rather than hopeful"
  - "#308 — the epic; Phase 1 shipped in release 0.1.0"
non_goals:
  - Weakening GH-321. The per-file requirement still applies to every commit that is not establishing a freeze; a NEW pathless trailer is still rejected.
  - "Folding flush-left wrapped trailers. Indistinguishable from the next paragraph, so guessing would let arbitrary prose become a coverage claim; only git-standard INDENTED continuations are folded."
  - Deleting test/marathon-plan.sh Scenario T. Freezing marathon-plan does not make cross-lane drift acceptable yet — see the open question below.
  - Touching relay-turn-lib.sh. It is a shared Bash runtime dependency, not a twin, and stays unfrozen.
goal: >
  Make the GH-308 freeze guard able to pass ranges it cannot currently reason about — one containing
  the freeze commit itself, and one containing the pre-GH-321 trailer that is permanently in git
  history — without weakening the per-file guarantee GH-321 added. Separately, retire marathon-plan's
  Bash-authoritative exception, whose stated reason GH-340 removed, and freeze it as the 12th twin.
---

# GH-362 · a guard that can pass the ranges it must, and one fewer exception

## Status
| What was just completed | What's next |
|---|---|
| Both defects fixed; 4 new cases; suite **32/0**. Proved by **A/B against the pre-fix guard on identical input**: old **rc=1**, new **rc=0**. marathon-plan frozen as the 12th twin, its pinning assertion **inverted** rather than removed. `UPGRADE.md` §0.1 and `AGENTS.md` rewritten. | Review + merge into `development`. Does **not** need to reach `main` — `main` picks it up at the next release. |

## (A) The freeze itself is not a violation of the freeze

Release PR #361 — the first time `development`..`main` had ever been through CI — was blocked with all
11 twins named and nothing wrong in the diff. `BASE_SHA` was `main`'s tip, so the range contained
`07ae1e7`, **the commit that added the FROZEN banners**. A commit that freezes N files necessarily
edits N files; the guard had no way to distinguish that from violating them.

**Fix:** a path is exempt when the commit that introduced its `FROZEN` banner is in the range *and*
nothing touched the path after it. Deliberately narrow — the exemption is for the establishing **edit**,
not the file. Case 12 pins the negative: an edit landing after the freeze in the same range still fails,
which is what stops case 11 from being a hole.

Not self-limiting, despite appearances. Once `main` contains the freeze, later `main..development`
ranges are clean — but a bisect run, a long-lived branch, a fork comparing against an old base, and a
release branch cut from before the freeze all reach back past it again.

## (B) GH-321 changed a format whose instances are permanently in history

```
gh308 guard: malformed Frozen-twin-exception trailer — no path/reason separator:
  Frozen-twin-exception: GH-319 left a silently-fake pre-advance gate in the
```

`07ae1e7`'s trailer is the **pre-GH-321 bare form** — `Frozen-twin-exception: <reason>`, no path — and
it was correct when written. GH-321 (PR #328) made the trailer per-file, and the new parser reads the
old form as malformed. **Git history cannot be rewritten, so the format change permanently rejected its
own past.** I shipped GH-321, so this is mine.

Reading the code made the defect sharper than the issue described it: `collect_declared` returned rc 1
for **any** malformed trailer anywhere in the range, independent of whether that commit's edits needed
covering at all. So a legacy trailer failed the run even when its commit was exempt under (A).

**Fix:** skip trailer parsing for freeze-establishing commits only. Every other commit still gets the
full GH-321 treatment, so a **new** pathless trailer is still rejected — which is what GH-321 was for.
Additionally, git-standard **indented** continuation lines are now folded onto their trailer.
Flush-left wrapping is deliberately *not* folded: it is indistinguishable from the start of the next
paragraph, and guessing would let arbitrary prose become part of a coverage claim.

## (2) marathon-plan's exception is retired

It was GH-308's single documented exception: Bash stayed authoritative and dual-maintained *"until the
known Python parity gaps are closed."* **GH-340 closed them** — the copied `_marathon_plan_node.js` is
deleted, `utils/py/_marathon_plan.py` is a native stdlib engine, and the Python lane needs no Node. The
exception outlived its rationale, and `UPGRADE.md:68` had been asserting a false premise since #341
merged.

Frozen as the **12th twin**: added to `TWINS`, banner added to `utils/marathon-plan.sh`, and the guard's
own assertion **inverted** — it used to assert *"marathon-plan remains the Bash-authoritative
exception"* and now asserts the retirement, so a future revert fails loudly instead of silently
restoring an exception whose reason no longer exists.

The banner's first line matches the canonical literal exactly, because the guard keys on it. That is a
feature: I changed the banner to fit the assertion rather than loosening the assertion to fit the
banner.

## Verification

- Guard suite **32 pass / 0 fail** (was 27; +1 inverted assertion, +4 new cases).
- **A/B on identical input** — the decisive evidence. Same fixture (a base where a twin is unfrozen,
  then a commit introducing the banner), old guard from `origin/development` vs new:
  `old-guard.sh → rc=1`, `gh308-frozen-twin-guard.sh → rc=0`.
- **Self-check**: this branch freezes marathon-plan, i.e. it edits a frozen twin. Its own CI invocation
  passes (`rc=0`, *"the only edit in this range IS the commit that froze it"*), while strict mode still
  objects (`rc=1`) — correct, since strict mode ignores all exemptions by design.
- `test/marathon-plan.sh` **72/0** with the banner in place.
- One incidental fix: `freeze_commit_for` originally used `| head -1`, and head closing the pipe early
  made git's write fail — surfacing as `printf: write error: Interrupted system call` on every call
  under `set -euo pipefail`. Takes the first line in-shell now.
- `mapfile` was replaced with a portable read loop: it is a bash 4+ builtin and macOS ships 3.2, which
  this repo's scripts must keep working under. Caught by running the guard, not by review.

## Open question this creates, stated rather than buried

Freezing marathon-plan and keeping Scenario T's byte-identity assertion are in tension. Today they
agree, so the assertion is free. **The first deliberate Python-only change to the planner will fail
it**, and the pressure at that moment will be to delete the assertion to get green. The right move then
is to retire it *on purpose*, recording that the frozen fallback is now allowed to diverge — the same
decision the other 11 twins made implicitly by never having a parity test at all. Noted in the banner
and in `UPGRADE.md` so whoever hits it has the reasoning rather than just a red test.
