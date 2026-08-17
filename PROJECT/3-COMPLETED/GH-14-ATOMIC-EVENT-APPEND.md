---
gh_issue: 14
source: https://github.com/HiQS-Suite/XYZ-forge/issues/14
title: "GH-14: appendEvent writes non-atomically; concurrent readers can observe torn event files"
status: active
created: 2026-08-16
updated: 2026-08-17
owner: orchestrator (Claude Code)
doc_type: bugfix
complexity: 2
risk: 3
effort: 2
ratings_provisional: true
goal: >
  Make a `.jsonl` file that exists always complete: appendEvent writes to a temp name the reader
  cannot select and renames into place, so the torn-read class is gone at the source and any
  quarantine applied on top is safe rather than destructive.
---

# GH-14 — atomic event append

## Status

| What was just completed | What's next |
|---|---|
| Atomic write (temp+rename) landed 2026-08-17 via PR #21 (outside-of-harness lane, orchestrator-reviewed and merged as `e49bdcd`); `test/gh14-atomic-append.sh` registered in `validate.sh`; negative control recorded at `test/baselines/GH-14-negative-control.md` (5 pass/1 fail pre-fix, 6/0 post-fix) | **Waiver recorded below**: the two `test/unit/events.test.js` cases deferred from PR #7 (quarantine, empty-file skip) were NOT re-authored by PR #21. #5 stays open on this gap. |

## Waiver — deferred PR #7 unit tests not re-authored

- **Failed criterion**: acceptance criterion 4 ("#5's quarantine, if retained, is applied only on
  top of atomic writes, and its own test distinguishes a genuinely corrupt file from a young
  one") and the contract note directing the two PR #7-deferred tests (quarantine, empty-file
  skip) to be re-authored here.
- **Owner**: orchestrator (Claude Code), pending operator direction.
- **Reason**: PR #21 shipped only the atomic-write half; `src/events.js` carries zero quarantine
  logic (confirmed: no matches for "quarantine"). Criterion 4 is conditional on quarantine being
  *retained* — since it was dropped (per the #5 correction, d99e00d), it is vacuously satisfied.
  But the two deferred tests were never re-authored against the new atomic-write behavior either,
  and inventing quarantine/empty-file-skip production logic now, un-reviewed, would be scope
  creep beyond this PR's adjudication. `readAllEvents` still has no defensive handling for a
  foreign corrupt/empty file dropped at a final `.jsonl` path (it would throw uncaught on
  `JSON.parse`) — a real but pre-existing gap, not introduced by this fix.
- **Follow-up**: tracked under #5, which stays open per the standing rule ("#5 stays open until
  these tests and #14's atomic write have both landed" — d99e00d). #14's acceptance criteria 1,
  2, 3, 5 are otherwise landed and verified; criterion 4 is closed vacuously with this waiver on
  file.

## Bug

`appendEvent` (`src/events.js:163`) writes the event file with a single non-atomic
`fs.writeFileSync(fpath, ...)` — the file exists at its final `.jsonl` name while holding zero
bytes or a truncated prefix. `readAllEvents` selects on `f.endsWith('.jsonl')`
(`src/events.js:176`), so any concurrent reader — every `tick` verb, including read-only ones —
can select and parse a partial document. This is the multi-agent concurrent path the kernel exists
to coordinate; the window is reached in normal operation.

This is also why PR #7's quarantine half was rejected and re-routed here: quarantining a torn read
renames a **valid in-flight event** permanently out of the log, silently. Correct order is atomic
write first, quarantine layered on top only after.

## Source of truth

- GitHub issue: [HiQS-Suite/XYZ-forge#14](https://github.com/HiQS-Suite/XYZ-forge/issues/14)
- Correction context: [#5 correction comment](https://github.com/HiQS-Suite/XYZ-forge/issues/5) (2026-08-15)

## Acceptance

- [x] `appendEvent` writes via a temp name and renames into place; no reader-visible path ever holds a
  partial document.
- [x] A unit test asserts that no file matching the reader's selection filter is ever observable in a
  partial state — e.g. by asserting the temp name does not match the filter, and that a directory
  listing taken between write and rename yields no selectable partial file.
- [x] A regression test covers the concurrent shape directly: interleaved append and `readAllEvents`
  never loses an event and never quarantines one.
- [x] `#5`'s quarantine, if retained, is applied only on top of atomic writes, and its own test
  distinguishes a genuinely corrupt file from a young one.
- [x] The healthy-path event bytes are unchanged.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_present", "path": "src/events.js", "pattern": "writeFileSync\\(fpath, JSON" },
                 { "type": "path_absent", "path": "test/baselines/GH-14-negative-control.md" } ],
  "artifacts":   [ "src/events.js", "test/unit/events.test.js", "test/baselines/GH-14-negative-control.md" ],
  "artifacts_new": ["test/baselines/GH-14-negative-control.md"],
  "remediation": { "source": "issue#14", "criteria": "a .jsonl that exists is always complete; torn-read class removed at the source" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```

Probe polarity: `grep_present` carries the BUG marker — the direct non-atomic
`writeFileSync(fpath, JSON.stringify(event))` call. The lane is ready while that line exists and
reports stale (exit 4) once the temp+rename fix replaces it. The two `test/unit/events.test.js`
cases deferred from PR #7 (quarantine, empty-file skip) are re-authored here against atomic
writes, per the acceptance above.

## Verification

- `npm run test:unit` green including the new atomicity tests.
- Full `./validate.sh` green in a disposable full clone (durable location — a clone under /tmp
  fails `gh388-run-log-durability`'s own-root durability classification).
- Recorded negative control under `test/baselines/GH-14-negative-control.md`: reverting to the
  bare `writeFileSync(fpath, ...)` makes the new tests fail.
