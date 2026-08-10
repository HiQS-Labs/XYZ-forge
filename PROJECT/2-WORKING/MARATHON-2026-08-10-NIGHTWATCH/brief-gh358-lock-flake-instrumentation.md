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
