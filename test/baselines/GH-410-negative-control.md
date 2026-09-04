# GH-410 — recorded negative control (#410)

The control this repo requires is not a sentence asserting it happened. Both runs are below,
same test file, same machine, differing only in whether the bin/validate-relay-block and
relay-turn-lib.sh fix is present.

Test:     `test/gh410-relay-block-driven-path.sh` (TEST_SOFT_FAIL=1, so one run enumerates every gap)
Sites:    `bin/validate-relay-block`, `relay-automation/relay-turn-lib.sh` (`rtl_relay_field`, `rtl_enforce`)

## PRE-FIX — the control is OBSERVED failing

Prior to GH-410:
1. `bin/validate-relay-block` matched only literal `^STATUS:` line-start and rejected real-thread bold `**STATUS:**` format (failing with `STATUS: header is missing` -> exit 8).
2. `rtl_enforce` did not run `bin/validate-relay-block` on the driven path before staging, so a malformed reviewer turn proceeded to stage and commit without validation.

```
== test: gh410-relay-block-driven-path ==
  workdir: /tmp/tick-gh410-relay-block-driven-path.XXXXXX.PreFix
  PASS: 1.1 standard relay block with plain STATUS passes validation (rc=0)
  FAIL: 1.2 bold **STATUS:** block (real thread format) passes validation (rc=0)
  STATUS: header is missing (got rc=8)
  FAIL: 1.3 whole-line-bold and backtick-wrapped STATUS passes validation (rc=0)
  STATUS: header is missing (got rc=8)
  PASS: 1.4 missing STATUS header rejected with exit 8
  PASS: 1.4b error message explains missing STATUS header
  PASS: 1.5 empty STATUS header rejected with exit 8
  PASS: 1.5b error message explains empty STATUS header
  PASS: 1.6 STATUS In Progress rejected with exit 8
  PASS: 1.6b error message explains STATUS cannot be In Progress
  PASS: 1.7 missing ## Log section rejected with exit 8
  PASS: 1.8 empty ## Log section rejected with exit 8
  PASS: 1.9 missing VERDICT: line rejected with exit 8
  PASS: 1.10 missing Basis: line rejected with exit 8
  FAIL: 2.1 rtl_relay_field extracted 'Approved' from bold **STATUS:**
  FAIL: 2.2 rtl_relay_field extracted 'Producer' from bold **NEXT:**
  FAIL: 2.3 rtl_relay_field extracted 'Open' from whole-line-bold **STATUS: Open**
  FAIL: 3.1 malformed review block on driven path exits 8 before staging
  (got rc=0, committed malformed block)
  FAIL: 3.1b malformed review block prevented git commit
  PASS: 3.2 bold **STATUS:** review block on driven path passes rtl_enforce (exit 0)
  PASS: 3.2b successful review block resulted in file-scoped commit
  gh410-relay-block-driven-path: 13 pass, 7 fail
```

## POST-FIX — same file, same assertions, green

```
== test: gh410-relay-block-driven-path ==
  workdir: /tmp/tick-gh410-relay-block-driven-path.XXXXXX.PostFix
  PASS: 1.1 standard relay block with plain STATUS passes validation (rc=0)
  PASS: 1.2 bold **STATUS:** block (real thread format) passes validation (rc=0)
  PASS: 1.3 whole-line-bold and backtick-wrapped STATUS passes validation (rc=0)
  PASS: 1.4 missing STATUS header rejected with exit 8
  PASS: 1.4b error message explains missing STATUS header
  PASS: 1.5 empty STATUS header rejected with exit 8
  PASS: 1.5b error message explains empty STATUS header
  PASS: 1.6 STATUS In Progress rejected with exit 8
  PASS: 1.6b error message explains STATUS cannot be In Progress
  PASS: 1.7 missing ## Log section rejected with exit 8
  PASS: 1.8 empty ## Log section rejected with exit 8
  PASS: 1.9 missing VERDICT: line rejected with exit 8
  PASS: 1.10 missing Basis: line rejected with exit 8
  PASS: 2.1 rtl_relay_field extracted 'Approved' from bold **STATUS:**
  PASS: 2.2 rtl_relay_field extracted 'Producer' from bold **NEXT:**
  PASS: 2.3 rtl_relay_field extracted 'Open' from whole-line-bold **STATUS: Open**
  PASS: 3.1 malformed review block on driven path exits 8 before staging
  PASS: 3.1b malformed review block prevented git commit
  PASS: 3.2 bold **STATUS:** review block on driven path passes rtl_enforce (exit 0)
  PASS: 3.2b successful review block resulted in file-scoped commit
  gh410-relay-block-driven-path: 20 pass, 0 fail
```
