# GH-358 — recorded negative control (#419)

Test:     `test/gh358-lock-instrumentation.sh` (Phase 1: instrumentation)
Revision: `b4f98ce27ead37cd380ffd0e13589abe27c967ac`
Date:     2026-08-11

Unlike the other Nightwatch entries, this control is **self-contained**: the suite constructs both
failure shapes itself and requires the instrumentation to tell them apart. The two `FAIL:` lines
below are the controls firing on purpose — a clobbered record and a starved appender — and the
point is that they read DIFFERENTLY. Before Phase 1 both produced the same bare mismatch, which
is why the flake was never dispositioned: nobody could say whether the record was lost under a
held lock or never written because the lock was never acquired.

## OBSERVED — both controls fire, and are distinguishable

```
== test: gh358-lock-instrumentation ==
  PASS: clobbered-record control fails as intended
  PASS: clobber names the missing successful session
  PASS: clobber reports both normal lock bounds
  PASS: clobber remains distinct from starvation
  clobber diagnostic (observed failure):
      FAIL: concurrent mismatch: missing sessionId=conc-1; terminal state=lock acquired, record lost. test wait=60s; writer XYZ_LOCK_WAIT_S=30s (default=30s)
  PASS: starved-appender control fails as intended
  PASS: starvation identifies the terminal lock state
  PASS: starvation identifies the exhausted writer bound
  PASS: starvation reports both effective lock bounds
  PASS: starvation remains distinct from a lost record
  starvation diagnostic (observed failure):
      FAIL: appender sessionId=conc-1; terminal state=lock never acquired; writer XYZ_LOCK_WAIT_S=1s exhausted. test wait=60s; writer XYZ_LOCK_WAIT_S=1s (default=30s)
  gh358-lock-instrumentation: 9 pass, 0 fail
```

## Phase 2 is BLOCKED ON AN OBSERVATION, not on work

Phase 2 is "disposition, on that evidence" — raise the bound, retry the assertion, or exclude with
a stated reason. That decision needs a real CI failure carrying the new instrumentation, and the
capture doc is explicit that it must not be pre-committed: *"a builder told which disposition to
apply will produce instrumentation that agrees with the instruction."* The suite DOES run on the
shared runner (`.github/workflows/ci.yml` runs the full `validate.sh` minus two documented skips,
and `xyz-completion.sh` is not one of them), so the exposure is live — it simply has not fired
since the instrumentation landed. Choosing a disposition now would be guessing with extra steps.
