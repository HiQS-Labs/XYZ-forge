# GH-299 Gen 4 campaign — 2026-10-30T19:25:15-0700 → 2026-10-30T20:40:08-0700

- sandbox: `/private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090-fa64-4928-a8ed-121f037d42bd/scratchpad/gh1280/sb-long/clone` (disposable full clone of `/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30`)
- elapsed: 4491.9s · batches: 200 · **mutations: 10000** (133.6/min)
- tier-1 counts: {'pass': 773, 'fail': 8949, 'anomaly': 278} · handled rejections: 8949 · counterexamples: 278 · parity divergences: 0
- clusters: 6 · synthesized suites: 0 · false positives: 6
- **zero host violations: True** (host violations 0) · **zero sandbox contamination: False** (events 41 — each one is a mutant that wrote into the tree, reset and recorded)
- **zero false positives: False** · telemetry line-valid: True

## Per target

| target | batches | mutations | counterexamples | parity divergences |
|---|---:|---:|---:|---:|
| fp-help | 50 | 2500 | 0 | 0 |
| fp-genman | 50 | 2500 | 5 | 0 |
| fp-status | 50 | 2500 | 171 | 0 |
| fp-init | 50 | 2500 | 102 | 0 |

## Counterexample clusters

- `c0cfa89b249b9917` × 234 rc=2 anomaly — 'factory-primitive: run root must stay under /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/3b1ff090'
- `30b5c54c6ea7ea7a` × 21 rc=2 anomaly — 'factory-primitive: invalid daily cap or maximum call cost\n'
- `21aaae4bb9057c38` × 18 rc=2 anomaly — 'factory-primitive: instance already initialized; use a new run root\n'
- `321cec116e1953ab` × 2 rc=2 anomaly — "factory-primitive: [Errno 21] Is a directory: '.'\n"
- `a28272a437ce022f` × 2 rc=2 anomaly — "factory-primitive: [Errno 1] Operation not permitted: '../../etc'\n"
- `668fd9ab3c65838c` × 1 rc=2 anomaly — "factory-primitive: [Errno 20] Not a directory: 'temp/factory-primitive/ate-smoke'\n"

## False positives (did not reproduce on replay)

- `c0cfa89b249b9917` × 234 recorded rc=2 replay rc=125
- `30b5c54c6ea7ea7a` × 21 recorded rc=2 replay rc=125
- `21aaae4bb9057c38` × 18 recorded rc=2 replay rc=125
- `321cec116e1953ab` × 2 recorded rc=2 replay rc=125
- `a28272a437ce022f` × 2 recorded rc=2 replay rc=125
- `668fd9ab3c65838c` × 1 recorded rc=2 replay rc=125

## Contamination events

- round 2 target fp-genman seed 12802: ['?? " "']
- round 6 target fp-genman seed 12806: ['?? -1', '?? [1,2']
- round 10 target fp-genman seed 12810: ['?? NaN']
- round 14 target fp-genman seed 12814: ['?? -1', '?? 0x7fffffff']
- round 18 target fp-genman seed 12818: ['?? tabcemp/']
- round 22 target fp-genman seed 12822: ['?? 9999999999999999999999999999999999999999999999999999999999999999', '?? "temp\\342\\200\\213/"']
- round 26 target fp-genman seed 12826: ['?? ?']
- round 34 target fp-genman seed 12834: ['?? "\'\\""', '?? 0', '?? "\\303\\251\'"']
- round 38 target fp-genman seed 12838: ['?? -1', '?? `true`']
- round 46 target fp-genman seed 12846: ['?? 2147483647', '?? `true`']
- round 50 target fp-genman seed 12850: ['?? 9999999999999999999999999999999999999999999999999999999999999999', '?? "{\\"a\\":"']
- round 54 target fp-genman seed 12854: ['?? -', '?? ~']
- round 58 target fp-genman seed 12858: ['?? -', '?? a=b=c']
- round 66 target fp-genman seed 12866: ['?? -', '?? 2147483647', '?? NaN']
- round 70 target fp-genman seed 12870: ['?? 1']
- round 74 target fp-genman seed 12874: ['?? " "', '?? $(true)', '?? 1']
- round 78 target fp-genman seed 12878: ['?? -', '?? "t\\342\\200\\250emp/"']
- round 82 target fp-genman seed 12882: ['?? "path with spaces/"', '?? "te\\342\\200\\250mp/"']
- round 90 target fp-genman seed 12890: ['?? `true`']
- round 94 target fp-genman seed 12894: ['?? 2147483647', '?? 2147483648']
- round 98 target fp-genman seed 12898: ['?? " "', '?? "temp\\341\\232\\200/"']
- round 102 target fp-genman seed 12902: ['?? []']
- round 114 target fp-genman seed 12914: ['?? 0x7fffffff', '?? `true`', '?? null']
- round 118 target fp-genman seed 12918: ['?? -9223372036854775808']
- round 122 target fp-genman seed 12922: ['?? 9999999999999999999999999999999999999999999999999999999999999999', '?? NaN']
- round 126 target fp-genman seed 12926: ["?? '", '?? 2147483648', '?? "tem\\341\\271\\225/"']
- round 130 target fp-genman seed 12930: ['?? %s%s%n', '?? 1', '?? 9999999999999999999999999999999999999999999999999999999999999999']
- round 138 target fp-genman seed 12938: ['?? `true`']
- round 142 target fp-genman seed 12942: ['?? ?']
- round 146 target fp-genman seed 12946: ['?? -', '?? 0', '?? {}']
- round 150 target fp-genman seed 12950: ['?? "\\t"']
- round 154 target fp-genman seed 12954: ['?? temabcp/']
- round 158 target fp-genman seed 12958: ['?? %s%s%n']
- round 162 target fp-genman seed 12962: ['?? " "', '?? `true`', '?? "path with spaces/"']
- round 166 target fp-genman seed 12966: ['?? 0']
- round 170 target fp-genman seed 12970: ['?? 1', '?? 2147483647', '?? ~']
- round 174 target fp-genman seed 12974: ['?? 2147483647']
- round 178 target fp-genman seed 12978: ['?? %s%s%n', '?? -', '?? {}']
- round 186 target fp-genman seed 12986: ['?? "\'\\""', '?? -9223372036854775808', '?? 0']
- round 194 target fp-genman seed 12994: ['?? %s%s%n', '?? =', '?? t']
- round 198 target fp-genman seed 12998: ['?? 0x7fffffff', '?? "{\\"a\\":"']
