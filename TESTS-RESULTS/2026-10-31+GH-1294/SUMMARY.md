# GH-1294: delivered issues with a draft brief are held, not scheduled

- **Change:** `utils/py/harness.py`. `_build_proposal` applied the "possibly delivered" hold only in its loop over planner-active lanes; the second loop, over accepted draft briefs, packed every `draft` brief. The reason string moves into `_delivered_hold` and both loops use it.
- **Manual check (red/green, no test file, GH-831):** `gh1294-check.py` calls `_build_proposal` with a stub planner engine, a draft brief for #384 (delivered by PR #386) and one for #777. Output: `gh1294-check-output.txt`.

| Run | Scheduled | Held |
|---|---|---|
| origin/development `b81f4205` (red) | #384, #777 | none |
| fixed branch (green) | #777 | #384: possibly delivered: closed by merged PR #386; issue still open |

- **Limit:** the original canary round trip (`stageb_controls.py roundtrip`, which found this in the #1279 window) is not reproducible today. `init` freezes the 300 most recent merged PRs, #384's PR has dropped out of that window, and `init` refuses the canary row (`roundtrip-attempt-output.txt`). The stub check exercises the same function with the same `delivered` shape. That real-state canary drift is a finding for any future soak, not fixed here.
- **Not in this change:** #1295 (injected text) and the empty-`reason` check are deferred until a generated launch packet is first launched (see #1298); #1296 belongs to the admission experiment.
