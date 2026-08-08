---
title: "Phase brief: GH-418 gh418-preflight-issue-state (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-08-06
updated: 2026-08-06
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the
  gh418-preflight-issue-state phase of MARATHON-2026-08-06-LITMUS — not itself an active-doc
  capture; the canonical capture doc is GH-418-PREFLIGHT-ISSUE-STATE-FROZEN.md two levels up.
roadmap_exempt: true
---

# Brief — GH-418: preflight must check issue state and the FROZEN banner

## Status

| What was just completed | What's next |
|---|---|
| Contract authored and verified READY via `--dry-run`; acceptance reads `match — 6/6 criteria copied verbatim from issue #418`. Designated FIRST CHILD of #419. | Fire as marathon phase 3 of 4, after gh419 (which builds the inventory this lane records into) and gh343 (same file). |

**Parent doc:** `PROJECT/2-WORKING/GH-418-PREFLIGHT-ISSUE-STATE-FROZEN.md`
**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/418

## Acceptance

**Read the acceptance criteria from the parent capture doc's `## Acceptance` block**, copied
verbatim from the issue (6/6, no deviations). Do not work from a paraphrase — see GH-400.

This lane closes **under #419's policy**, as its first child: its negative control must be recorded
in the gate inventory that phase 1 of this marathon builds. That is criterion 8 of #419 as well as
this lane's own requirement — demonstrating the contract on a real gate before anything is asked of
the rest of the tree.

## The gap

`swarm-preflight` decides whether a lane is fireable. It validates the contract's **internal
consistency** — artifacts exist, probes still detect the bug, the base is fresh — but never asks the
two questions that actually determine whether the work should run:

1. **Is the issue still open?** No issue-state check exists at all.
2. **Are the target files writable by policy?** No knowledge of the GH-308 `FROZEN` banner.

So a lane can read READY, emit a packet, and send a builder to edit a frozen Bash twin to close an
issue that closed two weeks ago. Every gate reports green.

### Measured cases

From the read-only triage of 2026-08-03 that retired four marathon plans:

| Plan | Lanes | Live state |
|---|---|---|
| J (2026-07-18) | #238, #239 | **both CLOSED** — shipped via PR #243 the next day |
| K (2026-07-19) | 17 lanes | **16 CLOSED**, only #191 open (self-described deferred backlog) |
| 2026-07-23 | #279, #280 | **#279 CLOSED**, #294 CLOSED, #280 open as bookkeeping only |
| M (2026-07-20) | #226 | #226 **CLOSED**; targets `relay-automation/consult.sh`, which is **FROZEN** |

Plan M is the sharpest: its Lane C gates on *"any stamp string added to `consult.sh` must appear in
`consult.py` and vice-versa"* — following that plan's own gate would violate GH-308.

### A ninth case, produced by this marathon

While this plan was being authored, **#368 was selected as a lane** on the strength of a capture doc
reading "not yet fired". It had already been fixed and merged (PR #433, `3a6ddfc`) and the issue
closed 2026-08-06T15:46:01Z. Preflight would have passed it READY. It was caught only by a
hand-check of the live issue state — the exact manual step this lane exists to remove. Use it as a
test case: it is fresher than the 2026-08-03 set and its artifacts are still on disk.

## Why the plumbing makes this cheap

Before #400, neither preflight twin invoked `gh` at all. #400 added an issue-body fetch to
`utils/py/swarm_preflight.py`:

```python
subprocess.run(["gh", "issue", "view", str(issue_number), "--json", "body", "-q", ".body"], ...)
```

Adding `state` to that same `--json` list is **one field on a call that already happens** — no new
network path and no new offline contract, since #400's degradation rules already cover the
unreachable case. The frozen-file check is a local read against artifacts the contract already
enumerates.

## What to build

**Phase 1 — issue state.** Fetch `state` on the existing call; record it in `run-candidate.json` on
**every** run, including when undeterminable. A CLOSED issue must not silently read READY: report it
prominently, and state in the emitted packet that the issue was closed and when, so the builder's
own context carries the fact.

**Phase 2 — the FROZEN banner.** An artifact path carrying the GH-308 banner sets NOT-READY with
**no packet written**, naming the file and pointing at its authoritative twin. Read the banner from
the file on disk — *not* a hardcoded list — so a newly frozen twin is covered without editing
preflight. (`utils/marathon-plan.sh` became the 12th frozen twin via GH-362; a hardcoded list would
already be stale.)

**Phase 3 — harden the sibling reader (added 2026-08-08, operator-approved scope addition).** This
came out of agy's Round-1 review of the first build of this lane, and it is a CONFIRMED live crash,
not a style note.

`expand_effective_artifacts`'s inner `read()` helper (`utils/py/swarm_preflight.py:366-370`) does
`open(os.path.join(root, rel_path), "r")` and catches **only** `OSError`. It walks the entire `test/`
directory to infer tests, so a single binary file there raises an uncaught `UnicodeDecodeError` and
kills preflight outright. Reproduced with one probe file:

```
UnicodeDecodeError: 'utf-8' codec can't decode byte 0xff in position 3: invalid start byte
  swarm_preflight.py:1049  in main -> expand_effective_artifacts
  swarm_preflight.py:385   raw = read(rel_path)
  swarm_preflight.py:369   return f.read()
```

The asymmetry is the whole argument: **your own new `find_frozen_artifacts` (`:631`) already gets
this right** — `open(..., "r", encoding="utf-8")` with `except (OSError, UnicodeError)`. The
pre-existing helper beside it does not. Bring `read()` up to the same standard: catch
`(OSError, UnicodeError)`, or pass `errors="ignore"`. Treat an undecodable file the same way the
existing code treats an unreadable one — skip it, do not crash.

**Pin it with a test**, in `test/gh418-issue-state-frozen.sh`: a binary fixture under `test/` must
leave preflight running normally rather than raising. Observe it FAILING first, per #419 — the
pre-fix tree gives the traceback above, and that traceback is the negative control.

Why this belongs in *this* lane rather than a separate issue: it is one line in a file already in
this lane's write-set, the fix is the same pattern you just wrote two hundred lines away, and
preflight is the tool the rest of this release is about. A hard crash on a routine repo state
outranks a wrong verdict — and `/10days` Step 6 treats any non-zero exit as "drop this issue", so
this silently removes work from sweeps.

## Deliberate non-goals — do not exceed them

- **Do not block on undeterminable issue state.** No `gh`, unauthenticated, or offline reports
  `unknown` loudly and does not block, matching #400's degradation contract exactly. An unreachable
  network is not evidence of staleness.
- **Do not block on a CLOSED issue outright.** Some lanes legitimately follow up on a closed issue.
  The requirement is that the operator is *told*, not that the run is forbidden. Only the FROZEN
  check sets NOT-READY.
- **Do not auto-retire stale plan docs.** Reporting is in scope; filesystem mutation is not.
- **Do not touch `utils/swarm-preflight.sh`** — frozen by GH-308.

Register `test/gh418-issue-state-frozen.sh` in `validate.sh`'s `TESTS` array.
