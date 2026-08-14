# GH-314 — recorded negative control

Change: `utils/py/marathon_drive.py` passes the transcript path to `preflight_write_set_trackable`.
Suite: `test/gh314-transcript-writeset.sh` (5 pass / 0 fail unmutated)
Recorded: 2026-08-14, macOS, branch `fix/critical-2026-08-14`

## Mutation

Revert the write-set list to the GH-514 pair, i.e. drop the transcript path:

```python
preflight_write_set_trackable(root, [relay_file, os.path.join(phase_dir, "ESCALATION.md")])
```

Result against a target whose `.gitignore` contains only `relay-system/`:

```
PASS: a target that cannot track the transcript is refused (exit 4)
PASS: refuses cleanly — no unhandled traceback on the transcript path
PASS: the refusal names the transcript path that cannot be tracked
FAIL: GH-314: 2 builder turn(s) were spent before the transcript refusal
```

Exactly one assertion fails. Restored: 5/0.

## The assumption this control falsified

The suite's first draft assumed the pre-fix tree dies in an unhandled `CalledProcessError` from
`save_transcript`'s `git add`, mirroring what GH-514 observed on its own paths — so "no traceback"
would be the discriminating assertion.

**It is not.** Pre-fix the run still refuses cleanly, still names `relay-system`, and still emits
no traceback; it exits 4 instead of 2 because a later layer catches it. Every assertion except one
passes in both directions.

What changes is **the cost**: two builder turns are spent before the refusal that the driver could
have issued before spending anything. That is #314's report almost verbatim — un-ignore one path,
burn a full phase, crash on the next, roughly 1.5h per landmine, discovered serially.

So the dispatch count is the proof here and the traceback assertion is a guard. Recorded because
the reverse — keeping the traceback assertion as "the" proof — would have shipped a suite that
looks rigorous and cannot tell the two trees apart.

## Why this is not already covered by GH-514

`preflight_write_set_trackable` cites #314 in its own comment, which reads as if it closed it. It
checked two of the three paths the run commits. `save_transcript()` performs a third `git add --`
with `check=True` under the transcript root, and that path was never passed in. The transcript is
also the **latest** of the three, so it is the one whose omission costs the most.

## Honest limit

The transcript root is resolved by sourcing `relay-turn-lib.sh` and calling `rtl_transcript_root`.
If that resolution fails the path is not added and the guard is narrower — the same fail-open
contract `preflight_write_set_trackable`'s docstring already sets, and for the same reason (this
must not invent a new way for a healthy run to fail). No test covers the resolution-failure branch.

**Superseded in part — see Round 2 below.** This originally read "*silently* narrower". It is no
longer silent: the branch now logs which paths the check covered. The uncovered-by-a-test part
still stands.

---

## Round 2 — the probe path, from an agy review

The first draft probed a synthetic `<transcript_root>/probe/transcript.md`. An agy review pointed
out that an ignore rule keyed on the dated directory — `relay-system/2026-*/`, the shape a repo
would actually write to exclude transcripts — does not match that path, so such a repo would sail
through preflight and fail later on the real filename.

Correct, and now observed. The probe mimics the real structure
(`<root>/<YYYY-MM-DD>/marathon-<phase>-<HHMMSS>.md`), and suite case 3 drives a target ignoring
`relay-system/2026-*/`.

**Control** — revert the probe to the synthetic path and re-run case 3:

```
PASS: a date-keyed transcript ignore rule is caught (exit 4)
FAIL: GH-314: 2 builder turn(s) spent before the date-keyed refusal
```

The refusal still happens, but only after two paid turns — the same signature as the original
defect, which is what makes the dated probe load-bearing rather than cosmetic. Restored: 7/0.

## Round 2 — the fail-open, and why it stayed

The same review called the silent fail-open a Blocker: if `rtl_transcript_root` cannot be resolved
the transcript goes unchecked, allegedly risking the same expensive halt.

**That premise does not hold.** `save_transcript()` resolves the root the same way and returns
`False` on failure (`marathon_drive.py:1412-1413`) — it never reaches its `git add`. A resolution
failure therefore produces no transcript and no halt, so failing closed would refuse healthy runs
for a harmless condition, which `preflight_write_set_trackable`'s own docstring forbids.

The legitimate half was that it was **silent**. It now logs which paths the check actually covered,
so a green preflight cannot be read as covering three paths when it covered two.

A separate bug was caught while making that change, and is worth recording because the fix would
have masked it: the new code used `datetime.datetime.utcnow()`, but module scope imports it as
`_dt` and the bare `import datetime` is local to `save_transcript()`. The resulting `NameError`
would have been swallowed by this block's own `except Exception`, silently disabling the whole
GH-314 check while every test still passed.
