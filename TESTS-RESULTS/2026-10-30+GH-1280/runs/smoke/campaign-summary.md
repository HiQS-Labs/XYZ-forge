# GH-299 Gen 4 campaign — 2026-10-30T19:10:54-0700 → 2026-10-30T19:12:12-0700

- sandbox: `/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/sb-smoke/clone` (disposable full clone of `/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30`)
- elapsed: 78.5s · batches: 8 · **mutations: 200** (152.9/min)
- tier-1 counts: {'pass': 21, 'fail': 166, 'anomaly': 13} · handled rejections: 166 · counterexamples: 13 · parity divergences: 0
- clusters: 2 · synthesized suites: 0 · false positives: 2
- **zero host violations: True** (host violations 0) · **zero sandbox contamination: False** (events 2 — each one is a mutant that wrote into the tree, reset and recorded)
- **zero false positives: False** · telemetry line-valid: True

## Per target

| target | batches | mutations | counterexamples | parity divergences |
|---|---:|---:|---:|---:|
| fp-help | 2 | 50 | 0 | 0 |
| fp-genman | 2 | 50 | 0 | 0 |
| fp-status | 2 | 50 | 8 | 0 |
| fp-init | 2 | 50 | 5 | 0 |

## Counterexample clusters

- `c0cfa89b249b9917` × 12 rc=2 anomaly — 'factory-primitive: run root must stay under /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090'
- `21aaae4bb9057c38` × 1 rc=2 anomaly — 'factory-primitive: instance already initialized; use a new run root\n'

## False positives (did not reproduce on replay)

- `c0cfa89b249b9917` × 12 recorded rc=2 replay rc=125
- `21aaae4bb9057c38` × 1 recorded rc=2 replay rc=125

## Contamination events

- round 2 target fp-genman seed 1282: ['?? " "']
- round 6 target fp-genman seed 1286: ['?? 0']
