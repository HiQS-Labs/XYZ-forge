# Marathon Phase gh358-lock-flake-instrumentation
STATUS: Open
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-GH358-LOCK-FLAKE-INSTRUMENTATION-TURN-2 builder=codex reviewer=agy round-cap=7 -->

## Phase Brief

---
title: "Phase brief: GH-358 gh358-lock-flake-instrumentation (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-08-10
updated: 2026-08-10
owner: noel
goal: >
  Phase-brief input consumed by the marathon driver for the gh358-lock-flake-instrumentation phase of
  MARATHON-2026-08-10-NIGHTWATCH — not itself an active-doc capture; the canonical capture doc is
  GH-358-LOCK-FLAKE-INSTRUMENTATION.md two levels up.
roadmap_exempt: true
---

# Brief — GH-358 Phase 1: make the lock test able to say *which* failure it saw

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-06 for release 0.2.0 Litmus; moved to the 0.3.0 Nightwatch manifest 2026-08-08. Acceptance authored onto the issue (it had none) and revised after an adversarial codex+agy review. Preflight re-run 2026-08-10 against `development` @ `e25c064`: **ready (exit 0)**, acceptance **7/7 verbatim**, issue **OPEN**. | Fire as the **only** phase of this wave. Phase 2 (disposition) is deliberately excluded — see "Phase 2 is not yours" below. |

**Parent capture doc:** `PROJECT/2-WORKING/GH-358-LOCK-FLAKE-INSTRUMENTATION.md`
**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/358

## Acceptance

**Read the acceptance criteria from the parent capture doc's `## Acceptance` block.** All seven are
carried **verbatim** from the issue — the doc's `## Acceptance — deviations from the issue` section
records "None." Work from those seven.

Two of them came from *reading the test*, not from the issue as originally filed, and they are the
ones most easily missed:

- **Every appender's exit status is discarded today.** The harvest loop is
  `for p in $pids; do wait "$p" 2>/dev/null || true; done`, in **two** places. Both must change. A
  crashed or killed appender is currently indistinguishable from one that took the lock and lost its
  record.
- **Two different lock bounds are in play.** The test waits on one budget; the writer defaults to
  `XYZ_LOCK_WAIT_S` at a smaller one. Naming "the timeout" without saying *which* is not actionable.

## The defect, stated as the thing you must fix

`test/xyz-completion.sh`'s 16-way concurrent-append case intermittently loses one record on the
shared CI runner. It passes locally and passed on re-run; the originating PR touched neither the test
nor the appender.

The problem is **not** the flake. It is that *"flaky"* and *"the lock genuinely loses a write under
contention"* produce a **byte-identical symptom**. The test is a decision gate that cannot distinguish
the defect it exists to catch from noise — so neither of its verdicts is evidence (#419).

Your job is to make the two distinguishable in the output.

## Definition of done for THIS phase

On a mismatch, the report must name the missing `sessionId` **and its terminal state**, as one of:

| terminal state | meaning | priority if seen |
|---|---|---|
| lock acquired, record lost | a **real lock bug** | highest — stop and re-file |
| lock never acquired | starvation / bound exhausted | tune the bound |
| process failed | appender crashed or was killed | fix the appender |

…and it must state **which** of the two bounds was exhausted.

## The negative control is the deliverable, not a formality

**A green suite proves nothing here.** The failure is intermittent, so a passing run after your change
is fully consistent with the instrumentation never having executed. Criterion 7 is therefore the real
gate:

> a deliberately clobbered record and a deliberately starved appender produce **visibly different**
> reports.

Build those two controls in `test/gh358-lock-instrumentation.sh` and make them assert on the
*difference*. An instrumentation change with no observed failure output is not done — this repo has
shipped "a check nobody can see working" three times (#333, #348, #351) and it is the specific
mistake this lane exists to not repeat.

## Phase 2 is not yours — do not pre-empt it

The capture doc is explicit:

> **Phase 2 must not be pre-committed in the packet.** A builder told which disposition to apply will
> produce instrumentation that agrees with the instruction.

So:

- **Do not** touch `.github/workflows/ci.yml`.
- **Do not** add the test to any CI exclusion list.
- **Do not** raise a bound, add a retry, or otherwise *dispose* of the flake.

Ship the instrumentation and the controls. The disposition is chosen later, from the evidence your
change produces.

## Hard non-goals (from the capture doc)

- **`M` stays 16.** Lowering it makes the symptom vanish and leaves the safety property untested.
- **The distinctness check stays**, for the same reason.
- **Do not treat this as an ordinary flake.** A flaky *lock* test is the one kind that cannot be
  waved off.

## Write-set

| File | Note |
|---|---|
| `test/xyz-completion.sh` | the failing test — both `wait` loops |
| `utils/telemetry/append-xyz-completion.sh` | the writer; retain/propagate exit status |
| `test/gh358-lock-instrumentation.sh` | **new** — the two negative controls |
| `validate.sh` | register the new test in `TESTS=()`; it does **not** glob `test/` |

Nothing else. In particular `.github/workflows/ci.yml` is **out of scope for this phase**.

## One containment note you should know about

`utils/telemetry/append-xyz-completion.sh` is in your write-set **and** is invoked by the marathon
driver running this very phase (`relay-automation/marathon.sh:69`, `utils/py/marathon_drive.py:656`)
to write its end-of-run completion record. The run pins `XYZ_APPEND_BIN` to a **pre-run snapshot** of
that script, so your edits cannot affect the run that is building them.

That containment protects the run, not you: it does not license a change that breaks the appender's
normal contract. Keep the CLI signature and exit semantics compatible.


## Debug mantra (auto-triggered — 1 prior attempt(s) on this phase did not reach Approved)

Before trying again, read `relay-automation/DEBUG-MANTRA.md` (relative to the harness root) and follow its four-step discipline: reproduce reliably, know the fail path, question the hypothesis, treat this round as a breadcrumb for the next one.
Last recorded reason (`marathon-system/nightwatch-wave-1-2026-08-10--gh358-lock-flake-instrumentation/ESCALATION.md`): `pre-advance-failed`. Read it before re-guessing.

---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): test/xyz-completion.sh,utils/telemetry/append-xyz-completion.sh,test/gh358-lock-instrumentation.sh,validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH358-LOCK-FLAKE-INSTRUMENTATION-TURN-2 --agent codex --paths "marathon-system/nightwatch-wave-1-2026-08-10--gh358-lock-flake-instrumentation/RELAY.md,test/xyz-completion.sh,utils/telemetry/append-xyz-completion.sh,test/gh358-lock-instrumentation.sh,validate.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH358-LOCK-FLAKE-INSTRUMENTATION-TURN-2 --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH358-LOCK-FLAKE-INSTRUMENTATION-TURN-2 --agent codex --to agy
4. Edit ONLY these paths: marathon-system/nightwatch-wave-1-2026-08-10--gh358-lock-flake-instrumentation/RELAY.md and test/xyz-completion.sh,utils/telemetry/append-xyz-completion.sh,test/gh358-lock-instrumentation.sh,validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: test/xyz-completion.sh,utils/telemetry/append-xyz-completion.sh,test/gh358-lock-instrumentation.sh,validate.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH358-LOCK-FLAKE-INSTRUMENTATION-TURN-2 --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH358-LOCK-FLAKE-INSTRUMENTATION-TURN-2 --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY marathon-system/nightwatch-wave-1-2026-08-10--gh358-lock-flake-instrumentation/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.

### Round 1 · Builder · codex

Implemented and verified the GH-358 instrumentation within the declared write-set. The concurrent
test retains every appender status, distinguishes successful-but-lost records from lock starvation
and process failure, and reports both the outer test wait and writer lock bounds. The appender
continues to surface lock starvation as exit 75. `test/gh358-lock-instrumentation.sh` now prints the
two deliberately reproduced diagnostics as observed failure evidence, while asserting their distinct
terminal states and exhausted-bound attribution. `validate.sh` already registers that focused test.

Verification: `bash test/xyz-completion.sh` (44 pass, 0 fail); `bash test/gh358-lock-instrumentation.sh`
(9 pass, 0 fail); `bash -n test/xyz-completion.sh utils/telemetry/append-xyz-completion.sh
test/gh358-lock-instrumentation.sh validate.sh`. I did not rerun the prior full pre-advance gate because
this turn explicitly prohibits the full suite; the two focused tests reproduce and exercise its relevant
lock paths.
