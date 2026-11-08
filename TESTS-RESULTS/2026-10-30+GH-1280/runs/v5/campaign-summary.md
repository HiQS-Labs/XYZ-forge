# GH-299 Gen 4 campaign — 2026-10-30T19:21:46-0700 → 2026-10-30T19:22:27-0700

- sandbox: `/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/sb-v5/clone` (disposable full clone of `/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30`)
- elapsed: 40.3s · batches: 4 · **mutations: 100** (148.9/min)
- tier-1 counts: {'pass': 14, 'fail': 76, 'anomaly': 10} · handled rejections: 76 · counterexamples: 10 · parity divergences: 0
- clusters: 2 · synthesized suites: 0 · false positives: 1
- **zero host violations: True** (host violations 0) · **zero sandbox contamination: False** (events 1 — each one is a mutant that wrote into the tree, reset and recorded)
- **zero false positives: False** · telemetry line-valid: True

## Per target

| target | batches | mutations | counterexamples | parity divergences |
|---|---:|---:|---:|---:|
| fp-help | 1 | 25 | 0 | 0 |
| fp-genman | 1 | 25 | 0 | 0 |
| fp-status | 1 | 25 | 6 | 0 |
| fp-init | 1 | 25 | 4 | 0 |

## Counterexample clusters

- `c0cfa89b249b9917` × 9 rc=2 anomaly — 'factory-primitive: run root must stay under /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090'
- `21aaae4bb9057c38` × 1 rc=2 anomaly — 'factory-primitive: instance already initialized; use a new run root\n'

## False positives (did not reproduce on replay)

- `21aaae4bb9057c38` × 1 recorded rc=2 replay rc=0

## Contamination events

- round 2 target fp-genman seed 1282: ['?? " "']
