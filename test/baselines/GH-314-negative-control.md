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
If that resolution fails the path is simply not added and the guard is silently narrower — the same
fail-open contract `preflight_write_set_trackable`'s docstring already sets, and for the same
reason (this must not invent a new way for a healthy run to fail). No test covers the
resolution-failure branch.
