# GH-509 Phase 4 — recorded negative control: the macOS promotion boundary

Per #419, a check never observed failing is not evidence. Four mutations, four assertions, **one
failure each**, restoring to 37/0 with a clean `git diff --stat`.

One failure each is the part worth reading. A mutation that reddens several checks at once cannot
distinguish a precise assertion from a blunt one, and blunt assertions are what let a real regression
hide inside expected noise.

| Mutation | Assertion that fired | Result |
|---|---|---|
| `runs-on: macos-latest` → `ubuntu-latest` | boundary must run on macOS | 36 pass / 1 fail |
| `if:` changed to `github.event_name == 'pull_request'` | boundary must never run on PRs | 36 / 1 |
| `run: ./validate.sh` → `run: bash test/tick-basic.sh` | boundary must invoke the validator directly | 36 / 1 |
| `timeout-minutes: 45` deleted | boundary must bound its runtime | 36 / 1 |
| `SKIP_TESTS=("registry-lock-concurrency.sh")` injected into the boundary run block | boundary must carry no skip list | 35 / **2** |
| *(none — restored)* | — | **37 / 0** |

The fifth row is the honest exception to "one failure each", and it is recorded rather than tidied:
injecting a `SKIP_TESTS=(` block also trips the **pre-existing** *"full gate must retain PDDA
fixture/negative-control tests"* check, which scans for that block anywhere in the workflow. Both
failures are correct — the mutation really does introduce a skip list, and both assertions really do
object to it. It is reported as 2 because the mutation is broader than the assertion, not because the
assertion is blunt.

## Why each of these is worth a test rather than a comment

**macOS, not Linux.** This is the only job whose green says anything about what users experience. XYZ
ships to macOS developers; Linux and Windows are on the roadmap and not here yet. A boundary job that
silently drifted to `ubuntu-latest` would look identical in every dashboard and would qualify commits
against a platform with no users.

**Never on pull requests.** Hosted macOS runners bill at roughly 10× Linux. In one 24-hour sample this
repo produced 37 pushes to `development`; putting a 10× runner on routine traffic restores the original
spend at ten times the rate, which is the exact failure GH-509 exists to prevent. The boundary is
affordable *because* it is rare — `main` sees almost no direct pushes, so in practice this fires on
`workflow_dispatch`, well under a dollar a handful of times a month.

**Invokes the validator, does not copy it.** The canary job builds its list by scraping `TESTS` out of
`validate.sh` with a `.sh`-only expression. That is precisely how `test/test_python_layer.py` — 20
tests over the **authoritative** implementation since GH-264 — went unexercised in CI for months while
the job still called itself "full". A second list is a second thing to keep honest. There is no second
list here, and the assertion fails if one appears.

**Bounded runtime.** The suite takes ~13-15 minutes locally. On a 10× runner an unbounded hang is the
expensive failure, and it is the kind of thing discovered on an invoice rather than in a log.

## The limit of this control, stated

These assertions prove the workflow **declares** the boundary. They do not prove a hosted macOS run
passes — no such run has happened yet. That witness is a separate, still-open acceptance criterion in
`PROJECT/2-WORKING/GH-509-CI-MINUTE-BURN.md`, and it is the one that matters most, because the entire
promotion rule rests on it.

There is also a precision limit in the mechanism itself, encoded in the job's own comment rather than
discovered later: **`workflow_dispatch` targets a ref, not an arbitrary commit.** GitHub resolves the
ref's current HEAD, so this job cannot be pointed at an older commit — it qualifies whatever that ref
points at when dispatched. That is why the job prints its resolved SHA into the summary: the promotion
rule compares against a *recorded commit*, not against "the run I remember starting".
