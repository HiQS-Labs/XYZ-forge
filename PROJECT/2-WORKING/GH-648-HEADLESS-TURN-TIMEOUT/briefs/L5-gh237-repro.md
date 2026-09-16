---
title: "L5 brief — #237 consult agy lane repro after the oracle fix"
status: "Brief (input to the GH-648 headless turn-timeout marathon — not a tracked plan)"
created: 2026-09-16
updated: 2026-09-16
owner: Noel Saw
goal: >
  Re-run the consult agy scenario: completes, or fails with a specific truthful attribution — never a silent idle-kill.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/648
---

# L5 — #237: consult agy lane repro after the oracle fix

## Status

| What was just completed | What's next |
|---|---|
| Brief authored at marathon plan time (2026-09-16) | Lane fires when the marathon chain reaches this phase |

Umbrella: #648 · Issue: #237 · Wave 1 · depends_on L4

## Goal
Re-run #237's scenario shape against the post-L1/L3 consult: an agy advisor given a substantial prompt inside consult's throwaway worktree. Expected after the umbrella's foundation lanes: the lane **completes**, or fails with a **specific, truthful attribution** — `idle-unknown`/in-flight, or the actual startup blocker named (what fd/prompt it waits on) — never a silent idle-kill labeled "no progress".

#237's operator note is the spec for "truthful": 0 CPU + no transcript growth is NORMAL for an LLM CLI awaiting a first token from a slow/queued backend; the old label conflated that with locally stuck.

If the repro exposes a real startup blocker (e.g. an interactive prompt the worktree path raises that `-p` + skip-permissions doesn't suppress), surface it in consult's failure output — that surfacing is the deliverable, not a workaround.

## Rules
Write-set: `utils/py/consult.py` (failure-attribution surfacing only — cap policy landed in L3). The SUITE must stub the advisor (no real agy tokens in `test/`); run the real-advisor probe once by hand and record the receipt in the PR description instead. Register the suite in `validate.sh` TESTS. `bash validate.sh` green.

## Acceptance / Guard
`test/gh648-l5-gh237-repro.sh`: a stubbed slow-backend advisor (0 CPU, no output growth, open socket) is NOT idle-killed with the old label; either completes or fails with the truthful attribution string. Hand-run receipt of the real agy repro attached to the PR.
