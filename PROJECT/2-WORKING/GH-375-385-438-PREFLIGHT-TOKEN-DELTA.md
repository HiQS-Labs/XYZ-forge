---
gh_issue: 375
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/375
title: "GH-375 / GH-385 / GH-438 — three checks that could not fail, or read the wrong state"
status: "Active (2-WORKING). GH-375 and GH-385 are complete and independently tested. GH-438 is PARTIAL — the removal-delta half is fixed and tested; the fix_probe re-evaluation half, which is the one that produces a false Approved, is NOT implemented and #438 stays OPEN. Do not close #438 on this branch."
created: 2026-08-08
updated: 2026-08-08
owner: noel
doc_type: bugfix
goal: >
  Make three marathon-path checks report the truth: an agy auth pre-flight that cannot fail headless,
  a satisfied-lane test that reads the base token when completion was recorded on a --retry suffixed
  one, and a phase-delta test that cannot see a removal. Each fix ships with a negative control,
  because the failure mode of all three is a check that now always passes. GH-438's second defect —
  no post-build fix_probe re-evaluation, the one that yields a false Approved — is explicitly out of
  scope and that issue stays open.
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
related:
  - "#419 — the class, and this release's theme. A check that cannot fail is not evidence."
  - "#397 — same shape, fixed in #456: a safety decision reading state that nothing guarantees."
  - "#401 — same release; a guard whose scope silently stopped covering what it was written for."
  - "#116 — allocates the --retry suffixed tokens GH-385 is unable to see."
  - "#207 — the already-satisfied recovery path GH-438's delta check feeds."
non_goals: >
  Re-evaluating a lane's acceptance criteria after the build (GH-438's second defect), changing the
  builder's "Do NOT run git" scope rule, and the --round-cap default. Each is a design decision
  rather than a bug fix; see Deliberately not done.
---

# GH-375 / GH-385 / GH-438

## Status

| What was just completed | What's next |
|---|---|
| GH-375 and GH-385 fixed and tested; GH-438's removal-delta half fixed and tested, with its uncovered half stated in the test file itself | Operator decision on GH-438's fix_probe re-evaluation — it needs the driver to know about acceptance criteria, which today it does not at all |

## Quad Concepts

- A probe that cannot report failure in the context it exists for is not a guard — `agy whoami` exits 0 while failing to run, so exit status alone was never evidence of auth.
- Reading the *wrong* state is indistinguishable from reading *no* state: a phase Approved on a `--retry` token looked unfinished because only the base token was consulted.
- Narrowing a rule must preserve the case it was actually protecting — the existence test was really an emptiness test, and only the emptiness half earns its keep.
- A partial fix that is filed as complete is worse than an open issue, because it removes the signal that work remains.

## GH-375 — the auth pre-flight could not fail headless

`agy whoami` returns exit 0 while erroring out when there is no TTY, and the probe passes
`stdin=DEVNULL`, so the failing path is the *normal* path under automation. The captured output —
the only place the failure was visible — was then deleted on the success branch. The design's safety
net was a timeout, which fires only when a TTY exists and an interactive login blocks; so attended
runs were protected and unattended runs, the ones the guard exists for, were not.

The verdict now lives once in `utils/py/rtl.py` (`agy_auth_output_failure`) and both callers use it —
`agy-turn.py` and `consult.py` had the identical hole.

**Matching is deliberately narrow.** An earlier attempt matched a bare `"error"` substring anywhere
in the output. `whoami` prints account identity, so that rejects any handle, org, or banner
containing the letters — `terror-form-labs`, `org: error-budget-team`, `errors_last_24h: 0` all
fail — and a false failure stops the run outright, which is a worse outcome than the bug. The test
pins five such legitimate outputs as must-accept, next to the reported failure as must-reject.

## GH-385 — an Approved phase rebuilt because its completion lived on another token

`satisfied_lane_terminal()` read only the base token. A phase that failed once, was re-run with
`--retry`, and completed on `MARATHON-…-TURN-2` left the base name holding the dead attempt's state
forever, so a later run without `--retry` rebuilt a demonstrably Approved phase — a full builder +
reviewer cycle, real money on `--builder claude`, and observed re-introducing work that had been
reverted. Nothing in the log said why.

The relay file already records which task it was rendered for, in its own `marathon-drive` directive,
and that render is redone on every fire including the retry. `completed_relay_task()` reads it.
Preferred over walking suffixes because it answers "which token completed THIS relay" rather than
"did any token for this phase ever reach done" — the latter would wrongly satisfy a lane whose
suffixed token belonged to a different run.

## GH-438 — PARTIAL

**Fixed:** `path_has_nonempty_phase_delta()` tested existence-and-non-empty *first and
unconditionally*, so a lane whose deliverable is removing a path could never register progress. The
emptiness rule (a newly created empty file is not a deliverable) now applies only when the path still
exists, and git is trusted to report a deletion as the change it is.

**Not fixed, and the reason #438 stays open:** nothing re-evaluates the lane's `fix_probes` after the
build. That is the defect that produces the issue's headline — `STATUS: Approved, gate passed`,
exit 0, and the tracked file still tracked. The contract carried a perfect detector that read
`unfixed` before the run and still read `unfixed` after, and the harness never looked. Implementing
it means teaching `marathon_drive.py` about acceptance criteria, which it contains no reference to
today, and answering where the contract comes from, what happens when it is absent, and whether a
still-`unfixed` probe fails the phase or escalates. That is a design decision, not a bug fix.

## Deliberately not done

- **`--round-cap` default 5 → 10.** Present in the superseded `b156479`. It doubles the worst-case
  builder+reviewer rounds, and therefore cost, on every lane in the fleet; it belongs to no issue
  here and needs its own justification.
- **The frozen Bash twin.** `b156479` edited `relay-automation/marathon-drive.sh` with no
  `Frozen-twin-exception` trailer, which the GH-308 guard rejects. The Python twin is authoritative
  and carries the fix.

## Verification

Every test was confirmed RED against the pre-fix tree before being trusted green, on the
discriminating assertion rather than incidentally:

| Test | Post-fix | Pre-fix control |
|---|---|---|
| `test/gh375-agy-auth-preflight.sh` | 14/0 | the reported TTY output read as successful auth |
| `test/gh385-retry-token-satisfied.sh` | 6/0 | the Approved phase re-entered relay-drive (exit 2) |
| `test/gh438-removal-is-progress.sh` | 6/0 | removing the artifact read as no progress (exit 3) |

All three are registered in `validate.sh`. Each carries a negative control, because the failure mode
of every one of these fixes is a check that now always passes: an auth probe that rejects everything,
a satisfied test that skips every phase, a delta check that waves through lanes which did nothing.
