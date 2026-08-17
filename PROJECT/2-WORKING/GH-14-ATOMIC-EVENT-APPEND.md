---
gh_issue: 14
source: https://github.com/HiQS-Suite/XYZ-forge/issues/14
title: "GH-14: appendEvent writes non-atomically; concurrent readers can observe torn event files"
status: active
created: 2026-08-16
updated: 2026-08-16
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
| Capture promoted to 2-WORKING; contract authored; Ballast 0.7.0 manifest frozen | Preflight, then fire as a marathon lane on operator go |

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

- [ ] `appendEvent` writes via a temp name and renames into place; no reader-visible path ever holds a
  partial document.
- [ ] A unit test asserts that no file matching the reader's selection filter is ever observable in a
  partial state — e.g. by asserting the temp name does not match the filter, and that a directory
  listing taken between write and rename yields no selectable partial file.
- [ ] A regression test covers the concurrent shape directly: interleaved append and `readAllEvents`
  never loses an event and never quarantines one.
- [ ] `#5`'s quarantine, if retained, is applied only on top of atomic writes, and its own test
  distinguishes a genuinely corrupt file from a young one.
- [ ] The healthy-path event bytes are unchanged.

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
