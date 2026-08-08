---
gh_issue: 409
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/409
also_covers: 408
title: "GH-409 + GH-408 — a leaked tick claim wedges the next turn, and every layer that could have named the cause discards it"
status: "Intake (2-WORKING) — captured 2026-08-08 for release 0.2.0 Litmus. NOT a reasoned claim: both issues fired LIVE during the Litmus marathon on 2026-08-07 and together cost ~2h of a session. Combined into one lane because the second is why the first is expensive. Not yet preflighted, not yet fired."
created: 2026-08-08
updated: 2026-08-08
owner: noel
doc_type: project
release: "0.2.0 Litmus"
complexity: 2
risk: 2
effort: 3
phases: 3
ratings_provisional: true
related:
  - "#408 — the silent-discard half, folded into this lane. Filed separately; the same defect class has a SECOND instance this doc names."
  - "#419 — the release theme. Three checks here return a confident verdict on a question they never asked."
  - "#407 — the mislabel that made this expensive: relay-drive exit 5 reported as `pre-advance-failed` on a phase whose gate never ran."
  - "#432 — SHIPPED 2026-08-07. Fixed the persistence half (a failed turn now reaches rtl_enforce). It did NOT fix the leak: the claim is still held when the turn dies before that point."
non_goals:
  - "Raising the claim cap. Two concurrent claims is a deliberate bound; the defect is claims outliving their turn, not the number allowed."
  - "Auto-reaping on any claim-cap error. A cap hit is sometimes correct (a genuinely busy agent); silently stealing a live claim would trade a loud stall for a race."
  - "Re-fixing what #432 already shipped. That covered the commit + handoff on a failed turn. This covers the claim that is never released, and the messages that hide it."
goal: >
  A turn shim claims its token before running the agent and does not release it when the agent fails,
  so two failed turns wedge that agent at its claim cap. Every layer that could name the cause throws
  it away: rtl.claim_task_or_exit sends the claim's stdout AND stderr to DEVNULL, `tick claim` prints
  the failure and exits 0, and marathon-drive then reports the resulting exit 5 as `pre-advance-failed`
  on a phase whose gate never ran. The operator is pointed at the gate; the cause is a leaked claim
  from two phases earlier.
---

# GH-409 + GH-408 · the claim outlives the turn, and nothing will tell you

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-08 after both issues fired **live** during the Litmus 0.2.0 marathon and halted it twice. Neither had a capture doc, which is why both had drifted since 2026-08-02. Combined into one lane: #408 is not merely adjacent to #409, it is the reason #409 costs hours instead of minutes. This doc adds a **second instance** of #408's defect that the issue does not name, and a **second producer** of leaked claims that #409 does not name. | Operator go, then the three phases below. Needs a preflight contract before it can be fired. |

## The defect, in the order an operator actually meets it

**1. The claim outlives the turn (#409).** A shim claims its token, runs the agent, and does not
release on failure. An agent may hold two claims, so **two failed turns wedge it permanently**. It is
self-inflicted and does not clear itself.

**2. The message names the wrong thing (#409).** The third turn fails with:

```
agy-turn: could not establish token ownership of MARATHON-GH343-GATE-PROGRAM-TARGET-ROOT-TURN-2
  (claimer=none, expected agy) — refusing to run so the turn cannot commit with the token open
  under the old owner; inspect `tick info MARATHON-GH343-GATE-PROGRAM-TARGET-ROOT-TURN-2`
```

The suggested command shows a **healthy** token — `status: open, handoff-to: agy`. So the diagnostic
the error hands you actively argues against the real cause.

**3. The cause is discarded (#408).** It is only visible by re-running the claim by hand:

```
$ bin/tick claim MARATHON-GH343-...-TURN-2 --agent agy --paths ...
lost: claim limit reached (holding T-cite, T-offlane) — finish or release first
rc=0
```

Two things there. The line names both culprits exactly — and `rtl.py:74` throws it away:

```python
subprocess.run([tick_bin, "claim", task, "--agent", agent, "--paths", claim_paths],
               env=tick_env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
```

**And `tick claim` exits 0 on that failure**, so a caller checking the exit status learns nothing
either. Both belts are cut.

**4. The verdict is mislabelled (#407).** `marathon-drive` reports the resulting `relay-drive` exit 5
as `reason: pre-advance-failed` — on a phase **whose gate never ran**. On 2026-08-07 that pointed the
investigation at the gate, which was the one component that had just been changed, and cost two
rounds of re-verifying a correct fix.

## What this doc adds to the two issues

**A second instance of #408's defect.** #408 names `_run_tick_loud`
(`utils/py/marathon_drive.py:1509`). That one is real and still present — and it is used on the
leaked-handoff reconciliation path (`:1497-1499`), so the two issues already touch. But the instance
that actually hid the cause on 2026-08-07 is **`rtl.claim_task_or_exit` (`utils/py/rtl.py:74`)**,
which is on the path **every single turn takes**. Fixing only the reported site leaves the expensive
one live.

**A second producer of leaked claims.** #409 attributes the leak to failed *builder turns*. On
2026-08-07 the actual producer was a **test suite**: `test/gh410-containment-advisory.sh` ran real
shims with `AGY_TURN_ROOT="$A"` but no `TICK_REPO_ROOT`, so it claimed `T-cite`/`T-offlane` as agent
`agy` in the **production** `.tick/` log and never released them — the turns under test are *expected*
to fail. `validate.sh` runs that suite, so **every gate run re-poisoned the reviewer's cap.** That
specific leak is FIXED (`7785c2a`, control: ambient event count 95 before the suite, 95 after), but
it proves the class is wider than "a builder turn crashed" and that a leak can be manufactured by
anything that runs a shim.

**Why one lane and not two.** #409 alone is a stall that clears with a `reap`. #408 alone is a
missing message. Together they are a two-hour misdiagnosis, and the fix for each is worthless without
the other: releasing the claim without surfacing the error leaves the next unrelated failure equally
blind, and surfacing the error without releasing the claim just narrates a wedge.

## Acceptance

Derived, per the GH-400 contract for a lane authored from a live incident. Neither issue carries an
`## Acceptance` block; if one is added upstream, this block must be replaced by a verbatim copy.

1. A turn that fails for any reason releases or reaps its claim, so N consecutive failures never
   reduce the agent's remaining capacity. The control is two deliberately-failed turns followed by a
   successful third.
2. A failed `tick` invocation inside a shim surfaces the tool's own message — the `claim limit
   reached (holding …)` line reaches the operator's output, naming the held tasks.
3. `tick claim` **fails non-zero** when it does not acquire the claim, so an exit-status check is
   sufficient. Today it prints `lost:` and exits 0.
4. `rtl.claim_task_or_exit` no longer discards the claim's stderr, and neither does `_run_tick_loud`.
   Both sites, or the fix is partial by construction.
5. The ownership-failure message distinguishes "the token is owned by someone else" from "you are at
   your claim cap", and does not suggest a diagnostic that contradicts the cause.
6. A resource/coordination failure is never reported as `pre-advance-failed` when the gate did not
   run. Shared with #407; satisfied here or explicitly deferred to it.
7. Each of the above is observed FAILING against the pre-fix revision, with the reproducer, revision
   and both results recorded — per #419. A sentence asserting a control happened is not the record.

## Phases

| Phase | Deliverable | Artifacts | cx/risk/eff |
|---|---|---|---|
| 1 | **Make the cause visible.** Stop discarding tick's stderr at BOTH sites; make `tick claim` exit non-zero when it does not win; split the ownership message so a cap hit reads as one. | `utils/py/rtl.py`, `utils/py/marathon_drive.py`, `src/*.js` (tick claim exit), `test/gh408-tick-failure-visibility.sh`, `validate.sh` | 2/2/2 |
| 2 | **Stop the leak.** A failed turn releases or reaps its claim on every exit path, including the ones #432 taught us are easy to miss. Regression: N failures do not reduce capacity. | `utils/py/rtl.py`, the five `utils/py/*-turn.py` shims, `test/gh409-claim-leak.sh`, `validate.sh` | 3/3/3 |
| 3 | **The negative controls, recorded.** Two failed turns then a successful third, on the pre-fix and post-fix revisions, with both transcripts committed as the durable baseline. | `test/gh409-claim-leak.sh`, a baseline artifact | 1/1/2 |

## Litmus tests

- **The exit-0 failure is the sharpest item here.** `tick claim` printing `lost:` and exiting 0 means
  *no* caller can detect it correctly, including callers that do everything right. A fix that only
  un-silences `rtl.py` leaves that trap armed for the next author.
- **Both discard sites or neither.** `_run_tick_loud` is the reported one; `rtl.py:74` is the one on
  every turn's path. Fixing the famous one and leaving the common one is the shape this release exists
  to stop.
- **"It worked" is not evidence the leak is gone.** A cap hit only manifests on the *second* failure,
  so a suite that fails one turn and then passes proves nothing. The control must be two.
- **Do not assert the control happened — record it.** Both prior sessions' notes on these issues said
  the cause was "recovered later by re-running the command by hand", which is exactly the evidence
  that should have been in the test.

## Provenance

Both issues were filed 2026-08-02 from a 10-lane marathon. Neither got a capture doc, so neither was
preflightable and both drifted. They fired again on 2026-08-07 during the Litmus marathon — #409's
transcript reproduced character-for-character with `agy` in place of `claude` — and were root-caused
by re-running the discarded command by hand, the same recovery the original reports describe. The
`gh410` leak producer and the `rtl.py:74` second instance were found in that session and are recorded
here because neither appears on either issue.
