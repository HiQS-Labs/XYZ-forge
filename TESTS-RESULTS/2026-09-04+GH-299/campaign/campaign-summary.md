# GH-299 Gen 4 campaign — 2026-09-04T20:34:16-0700 → 2026-09-04T20:40:04-0700

- sandbox: `/var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T/gen4-campaign._ige6pnh/clone` (disposable full clone of `/Users/noelsaw/marathon-clones/gh299-gen4`)
- elapsed: 259.3s · batches: 20 · **mutations: 400** (92.6/min)
- tier-1 counts: {'pass': 20, 'fail': 337, 'anomaly': 43} · handled rejections: 333 · counterexamples: 43 · parity divergences: 34
- clusters: 2 · synthesized suites: 1 · false positives: 0
- **zero host violations: True** (host violations 0) · **zero sandbox contamination: False** (events 1 — each one is a mutant that wrote into the tree, reset and recorded)
- **zero false positives: True** · telemetry line-valid: True

## Per target

| target | batches | mutations | counterexamples | parity divergences |
|---|---:|---:|---:|---:|
| ci-route | 3 | 60 | 0 | 0 |
| releases-roadmap | 3 | 60 | 0 | 0 |
| releases-check | 2 | 40 | 0 | 0 |
| pdda-frontmatter | 2 | 40 | 4 | 0 |
| domain-oracles-cli | 2 | 40 | 0 | 0 |
| adaptive-ate-cli | 2 | 40 | 0 | 0 |
| codex-turn-twins | 2 | 40 | 20 | 20 |
| agy-turn-twins | 2 | 40 | 14 | 14 |
| marathon-plan | 2 | 40 | 5 | 0 |

## Counterexample clusters

- `e3b0c44298fc1c14` × 42 rc=0 anomaly,fail — ''
- `738c4aa1f77b7a53` × 5 rc=4 anomaly — 'wrote PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md\n'

## Contamination events

- round 18 target marathon-plan seed 20260922: ['?? PROJECT/2-WORKING/MARATHON-PLAN-2026-09-05.md']
