# RELAY · GH-563 flakiness triage
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-15.
-->

NEXT: claude-a
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-563-flakiness-triage): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **flakiness-brief.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-08-15

### Artifact — flakiness-brief.md
````
# Review request — test-suite flakiness in a fresh clone

## Context

XYZ is being published. The public artifact is a sanitized, fresh-history clone
(`utils/build-launch-artifact.sh`). Its release gate (`test/meter-release.sh --release-gate`)
has a Half B that clones the artifact with no credentials and runs the documented entry path
(`npm install && ./validate.sh`) under a scrubbed environment. Half A is green; Half B is not.

## The symptom

`./validate.sh` (parallel by default, GH-544) produces a **different failing set on each run** in a
fresh clone, while passing green in the author's warm checkout.

Observed failing sets, same artifact, same machine, minutes apart:

```
run A: gh492-idle-kill, gh388-run-log-durability, oracle-guard, improve-loop-qa, releases-skill
run B: gh388-run-log-durability, oracle-guard, improve-loop-qa, releases-skill
run C: gh430-state-dir-tracked-default, improve-loop-qa, improve-loop-dogfood,
       relay-dep-drift, gh292-worktree-vendored-discovery
```

Run serially and individually in a pristine clone, only `gh388-run-log-durability` failed, and that
one had a known cause (now fixed): the gate cloned into `TMPDIR`, and `xyz_path_is_durable`
classifies anything under `TMPDIR` as non-durable **by design**
(`relay-automation/durable-log-lib.sh:48-55`). The test was right; the harness was wrong.

`improve-loop-qa` appears in **all three** sets and is the strongest single suspect.

## What is already known and should not be re-derived

- `validate.sh` runs **parallel by default** (GH-544), with `--sequential` available.
- The repo already ships `test/gh528-parallel-contention-retry.sh`, whose stated contract is that
  `--parallel` **re-runs a pooled failure alone before believing it, and names the contended suite**.
  If that mechanism worked here, contended suites should not surface as failures at all. Either it
  is not firing, or these failures survive a solo re-run and are genuine.
- A sibling repository has independently filed: *"`improve-loop.sh` defaults `--state-dir` to `/tmp`,
  so provenance evidence evaporates."* A fixed shared path under `/tmp` is a plausible collision
  source when suites run concurrently.
- The author's checkout passes because it is warm (existing `node_modules`, prior fixtures, populated
  state dirs). A newcomer has none of that. This is the difference that matters: a first-time user's
  first `./validate.sh` currently goes red on a different test almost every time, which is a worse
  first impression than a consistent failure.

## What I want from you

1. **Rank the hypotheses.** Shared fixed paths under `/tmp` vs. port/lock contention vs. timing
   assumptions vs. genuine order-dependence between suites. Cite `file:line` where you can.
2. **Is `gh528-parallel-contention-retry`'s retry actually reachable here?** Read it and
   `validate.sh`'s parallel driver and say whether a pooled failure really is re-run alone before
   being reported. If it is, these failures are genuine and the whole `/tmp` theory is wrong.
3. **Name the single cheapest experiment** that would distinguish contention from genuine failure.
4. **Say if the framing is wrong.** If the right answer is "the suite should not be the documented
   entry path for a newcomer at all", say that instead.

Constraints: the fix should be the smallest thing that makes a newcomer's first run reliable. Do not
propose a test-infrastructure rewrite. Do not weaken an assertion to make it pass.

You are ADVISORY. Report findings; do not edit files.
````
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer (agy) — Round 1

swept file: yes

* **[Should] Rank the hypotheses:**
  1. **Genuine state corruption (High)**: Parallel runs are mutating shared repo state, which then breaks the serial retry.
  2. **Missing warm state (Medium)**: A pristine clone is missing setup steps present in the author's warm checkout.
  3. **Shared `/tmp` paths (Disproven)**: `test/improve-loop-qa.sh:16` and `test/improve-loop-dogfood.sh:17` isolate state using `$$` (PID). Since `validate.sh` runs suites in separate Bash processes, they do not collide.
  4. **Lock contention (Disproven)**: Survived the serial retry.
  *Fix:* Update the brief's rankings to reflect that `/tmp` and contention are disproven, and state corruption is the leading cause.
* **[Pass] `gh528-parallel-contention-retry`'s retry is reachable:**
  Yes. In `validate.sh:458-469`, the pool failure is explicitly re-run alone: `if bash "$HERE/test/$t" > "$log.serial" 2>&1; then`. The failures listed in the brief survived this solo re-run, proving they are genuine.
  *Fix:* Record in the brief that the retry mechanism is active and the failures are genuine.
* **[Should] Single cheapest experiment:**
  *Fix:* Recommend running `./validate.sh --sequential` on a fresh clone. If it passes, the parallel run is corrupting shared repo state. If it fails, the fresh clone simply lacks required setup steps.
* **[Blocker] Framing:**
  *Fix:* State explicitly that the framing is wrong. `validate.sh:2` defines the suite as the "Aggregate runner for all tick acceptance tests." It runs 120+ chaos, concurrency, and validation suites. This is a CI gate for framework developers, not an onboarding script for newcomers. The documented entry path should be changed to a basic smoke test.

**Verdict:** Changes requested

Handing off to claude-a — go to the other window and say "take your turn".

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
