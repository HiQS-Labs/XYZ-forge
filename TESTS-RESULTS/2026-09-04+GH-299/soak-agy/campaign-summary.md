# GH-299 Gen 4 campaign — 2026-09-04T20:54:52-0700 → 2026-09-04T23:41:12-0700

- sandbox: `/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T//gen4-soak-2026-09-04/clone` (disposable full clone of `/Users/noelsaw/marathon-clones/gh299-gen4`)
- elapsed: 9900.4s · batches: 593 · **mutations: 14825** (89.8/min)
- tier-1 counts: {'pass': 617, 'fail': 12761, 'anomaly': 1447} · handled rejections: 12672 · counterexamples: 1455 · parity divergences: 1144
- clusters: 4 · synthesized suites: 3 · false positives: 0
- **zero host violations: True** (host violations 0) · **zero sandbox contamination: False** (events 57 — each one is a mutant that wrote into the tree, reset and recorded)
- **zero false positives: True** · telemetry line-valid: True

## Per target

| target | batches | mutations | counterexamples | parity divergences |
|---|---:|---:|---:|---:|
| ci-route | 66 | 1650 | 0 | 0 |
| releases-roadmap | 66 | 1650 | 0 | 0 |
| releases-check | 66 | 1650 | 0 | 0 |
| pdda-frontmatter | 66 | 1650 | 180 | 0 |
| domain-oracles-cli | 66 | 1650 | 3 | 0 |
| adaptive-ate-cli | 66 | 1650 | 5 | 0 |
| codex-turn-twins | 66 | 1650 | 568 | 568 |
| agy-turn-twins | 66 | 1650 | 576 | 576 |
| marathon-plan | 65 | 1625 | 123 | 0 |

## Counterexample clusters

- `e3b0c44298fc1c14` × 1405 rc=0 anomaly,fail — ''
- `738c4aa1f77b7a53` × 123 rc=4 anomaly — 'wrote PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md\n'
- `9553f3b817475f28` × 5 rc=1 fail — 'Traceback (most recent call last):\n  File "/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/gen4-soak-2026-09-04'
- `67702091c1b3d906` × 3 rc=1 fail — 'Traceback (most recent call last):\n  File "/private/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/gen4-soak-2026-09-04'

## Contamination events

- round 18 target marathon-plan seed 20260922: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 27 target marathon-plan seed 20260931: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 36 target marathon-plan seed 20260940: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 45 target marathon-plan seed 20260949: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 54 target marathon-plan seed 20260958: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 63 target marathon-plan seed 20260967: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 72 target marathon-plan seed 20260976: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 81 target marathon-plan seed 20260985: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 90 target marathon-plan seed 20260994: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 99 target marathon-plan seed 20261003: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 108 target marathon-plan seed 20261012: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 117 target marathon-plan seed 20261021: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 126 target marathon-plan seed 20261030: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 135 target marathon-plan seed 20261039: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 144 target marathon-plan seed 20261048: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 153 target marathon-plan seed 20261057: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 162 target marathon-plan seed 20261066: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 180 target marathon-plan seed 20261084: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 189 target marathon-plan seed 20261093: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 198 target marathon-plan seed 20261102: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 207 target marathon-plan seed 20261111: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 234 target marathon-plan seed 20261138: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 243 target marathon-plan seed 20261147: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 252 target marathon-plan seed 20261156: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 261 target marathon-plan seed 20261165: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 270 target marathon-plan seed 20261174: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 279 target marathon-plan seed 20261183: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 297 target marathon-plan seed 20261201: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 306 target marathon-plan seed 20261210: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 315 target marathon-plan seed 20261219: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 324 target marathon-plan seed 20261228: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 333 target marathon-plan seed 20261237: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 342 target marathon-plan seed 20261246: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 351 target marathon-plan seed 20261255: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 360 target marathon-plan seed 20261264: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 369 target marathon-plan seed 20261273: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 378 target marathon-plan seed 20261282: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 387 target marathon-plan seed 20261291: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 396 target marathon-plan seed 20261300: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 405 target marathon-plan seed 20261309: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 414 target marathon-plan seed 20261318: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 423 target marathon-plan seed 20261327: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 432 target marathon-plan seed 20261336: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 441 target marathon-plan seed 20261345: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 450 target marathon-plan seed 20261354: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 459 target marathon-plan seed 20261363: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 477 target marathon-plan seed 20261381: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 486 target marathon-plan seed 20261390: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 495 target marathon-plan seed 20261399: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 504 target marathon-plan seed 20261408: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 513 target marathon-plan seed 20261417: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 522 target marathon-plan seed 20261426: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 531 target marathon-plan seed 20261435: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 540 target marathon-plan seed 20261444: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 558 target marathon-plan seed 20261462: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 567 target marathon-plan seed 20261471: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
- round 585 target marathon-plan seed 20261489: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
