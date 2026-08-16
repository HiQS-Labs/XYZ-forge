# GH-557 — negative control

Recorded 2026-08-15. Per GH-419: a check never observed failing is not evidence.

## What was mutated

Nothing synthetic. The control is the **real pre-fix `utils/py/swarm_preflight.py`**, restored with
`git stash push utils/py/swarm_preflight.py`, with `test/gh557-unknown-blocks-manifest.sh` unchanged.
The fix was then restored with `git stash pop` and the suite re-run.

## Observed RED before the fix

```
$ git stash push -q utils/py/swarm_preflight.py
$ bash test/gh557-unknown-blocks-manifest.sh
  FAIL: manifest member expected exit 5, got 0: swarm-preflight · project-doc · slug=gh-700-fixture
  FAIL: refusal does not name frozen-manifest membership
  FAIL: refusal does not name the release goalpost
  FAIL: refusal states no remedy
  FAIL: acceptance line does not carry the cause
  FAIL: non-member run does not state its membership finding
  FAIL: outage not distinguished from the structural cause
  FAIL: structural cause wrong: unknown|None
  FAIL: transient cause wrong: unknown|None
  FAIL: manifest reader admitted a non-member cited only in RELEASES.md prose
  FAIL: structural provenance wording absent
  gh557-unknown-blocks-manifest: 5 pass, 11 fail
EXIT=1
```

The load-bearing line is the first one: **`expected exit 5, got 0`**. Pre-fix, a frozen manifest
member whose issue states no acceptance criteria was declared `ready` and a builder could be
dispatched against six criteria that came from nowhere.

## Observed GREEN after the fix

```
$ bash test/gh557-unknown-blocks-manifest.sh
  gh557-unknown-blocks-manifest: 16 pass, 0 fail
EXIT=0
```

## What makes this control discriminating rather than always-red

Three assertions **PASS in the pre-fix run** and must keep passing after it, because they assert
behaviour this change deliberately does NOT alter:

- `OVER-BLOCK CONTROL: non-member with no issue section still reaches ready (exit 0)`
- `OUTAGE CONTROL: manifest member + unreachable gh stays ready (exit 0)`
- `manifest member with verbatim-matching criteria reaches ready (exit 0)`

A detector that simply refused every acceptance-less issue would satisfy the PIN and fail all three.
That is the discrimination this repo has been burned on five recorded times (#348, #342, #351,
#362B, #369) — an assertion that cannot tell the bug from the fix — and it is why the pre-fix run is
recorded as `5 pass, 11 fail` rather than `0 pass, 16 fail`. A 16/16 red would have been the weaker
result.

Case 6 is the second half of the same concern in the other direction: it asserts the manifest reader
does **not** admit #509 (retired from Meter), or #272/#310/#329/#365/#504/#548 (cited in RELEASES.md
only as #551's root-cause siblings), while still finding all seven real Meter entries. Membership is
read from each goalpost's `MANIFEST=(...)` array — already cross-checked against RELEASES.md by the
goalpost itself — rather than by regexing RELEASES.md's prose, where every one of those numbers
appears and would have produced a false block on unrelated lanes.

## Field observation this was written from

Live run against Meter manifest member #382 on 2026-08-15, `gh` authenticated, network healthy:

```
  inlined-acc : 6 criterion(a) from the acceptance-section
  acceptance  : unknown — issue #382 has no '## Acceptance' section — nothing to copy from
  verdict     : ready (exit 0)
```

Six criteria in the capture doc, none on the issue, lane declared ready. The same output shape had
appeared the previous day for a completely different reason — `api.github.com` had stopped resolving
— and nothing distinguished the two, which is why the `cause` field exists and not merely a block.

Issue #382's acceptance section was authored onto the issue later the same day, so this exact
invocation no longer reproduces. The fixtures in the suite reproduce it deterministically instead.
