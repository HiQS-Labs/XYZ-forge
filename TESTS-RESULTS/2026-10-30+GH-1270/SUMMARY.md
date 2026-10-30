# GH-1270 — plan-draft launch packet and read-only readiness check

- **Source:** pilot and controls on `34edabb0`; smoke on `52406394`. The only change between them is the packet README naming a builder. Branch `feat/XYZ-forge-gh1270-launch-packet-readiness-2026-10-30`, based on `development` `2fa49d95`.
- **Where:** disposable full clone `XYZ-forge-gh1270-launch-packet-readiness-2026-10-30-verify`.
- **Platform:** macOS 15.6.1 arm64, Python 3.14.7, node, `/usr/bin/sandbox-exec`.
- **Result:**
  - The loop now freezes real issue state, holds delivered-but-open and partly landed issues, and writes one validated marathon per lane of a chosen wave.
  - #1075 (CLOSED) is in no wave.
  - #418 and #1098 were planner wave-1 lanes and are now held: each has 2 of 3 contract probes already landed.
  - The packet for wave 1 passed `bin/marathon-yaml` for all 5 lanes, and a copied lane passed `marathon.sh --dry-run`.
  - The ledger was byte-identical throughout. Nothing was launched.

## Pilot (`pilot-2c/`)

Ran `init --from-prs --limit 10 --unregistered 5`, then slots 1–15 (all completed), then `packet --wave 1`.

| Measure | Result |
|---|---|
| Requests | 15 seeded (10 ledger, 5 unregistered), 0 excluded |
| Planner waves | 5 lanes / 2 waves. Phase 2B had 6 / 2 with GitHub state off; this one uses frozen real state |
| Provisional waves | 10 lanes / 4 waves; 7 held |
| Held | #418 and #1098 `stale-contract: 2 of 3 fix_probes already landed`; 5 unregistered issues `missing-scope` |
| Closed section | #255, #1075, #1087 |
| Delivered map | 9 open issues that a merged PR claims to close: #1002 (#1004), #1012 (#1036, #1039), #1157 (#1161), #384 (#386), #470 (#638), #484 (#486), #777 (#783), #800 (#803), #879 (#895). None was a candidate in this run |
| Packet wave 1 | #722, #670, #1204, #216, #446: 5 folders, 0 skipped (`pilot-2c/launch-packet/wave-1/`) |
| Ledger | `releases.db` and `releases.sql` identical before the pilot, before the controls and after (`ledger-identity.txt`) |

## Controls (`controls.txt`; scripts `gh1270-controls.py`, `gh1270-controls.sh`)

| Control | Result |
|---|---|
| Frozen state | #1075 not in planner active; listed as already-closed |
| Red: Phase 2B state file (seeded issues only, all OPEN) | #1075 back in planner active |
| Closer vs mention | `Closes #722` → closer [722]; `see #722` → none |
| Delivered planner lane (manifest says a merged PR closes it) | held `possibly delivered: closed by merged PR #99999`, not in provisional |
| Delivered at init (gh shim: merged PR closes seeded #418) | #418 excluded at init with that reason |
| Unbriefed lane, one landed and one unfixed probe | held `stale-contract: 1 of 2`, not in provisional |
| Same lane, both probes unfixed (falsifier) | in provisional, not held |
| `command` probe | reported `unverified`, landed 0, marker file not created |
| Verifier, brief without `probe_results` | refused: `plan-draft brief missing keys: probe_results` |
| Packet after a clean completed tick | emits |
| Packet after a `fail-after-output` (uncertain) tick | exits 2, `not the verified output of the latest completed plan-draft tick`, writes nothing |

## Smoke (`smoke.txt`, GH-1088)

- **Main path:** `packet --wave 1` on the pilot.
- **Adjacent paths:**
  - A rerun gives an identical tree digest.
  - `--wave 9` exits 2 with `--wave must be in 1..4`.
  - All 5 `MARATHON.yaml` pass `node bin/marathon-yaml`.
  - A lane copied into `PROJECT/2-WORKING/` passes `marathon.sh --plan … --builder agy --dry-run`, reporting "1 phase(s) would run in order".
- **One defect found and fixed here:** without `--builder`, `marathon-drive` refuses builder == reviewer (both default codex). The README command now names the other agent (`52406394`).

## Limits

- Probes read the working tree of a clean clone. A dirty tree would skew them.
- The delivered check reads the last 300 merged PRs. An older delivering PR is missed, which is the conservative direction.
- Lanes in a wave are write-disjoint, but each still needs its own clone to run in parallel. The packet does not create clones.
