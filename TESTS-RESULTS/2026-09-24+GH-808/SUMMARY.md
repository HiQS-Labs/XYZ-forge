# GH-808 — gh251 scope-down: matched before/after timing + red control

Suite: `test/gh251-validate-pytest-skip.sh` (registered, GH-251 contract). All runs standalone,
same host (`noels-MacBook-Pro-14`), same disposable full clone (`/tmp/xyzforge-gh808.gate`),
un-sandboxed. Pre/post clone-identity checks clean (`core.bare=false`, origin unchanged, HEAD
expected, no injected local identity).

| Run | Commit | Wall | Assertions | rc |
|---|---|---:|---|---|
| BEFORE (base) | `0ae3452a5774` (origin/development) | **1050.6 s** (17:30.60) | 6 pass, 0 fail | 0 |
| AFTER (fix) | `0f1b811e5ddf` | **67.5 s** (1:07.46) | 6 pass, 0 fail | 0 |
| Red control (SKIPPED msg mutated in `validate.sh`) | fix + uncommitted mutation | — | FAIL + exit 1 | 1 |
| Restore control (mutation reverted from backup) | fix | — | 6 pass, 0 fail | 0 |

**Reduction: −93.6%** (1050.6 → 67.5 s), assertions identical. Corroborating committed telemetry:
hosted sequential 1044.4 s / 4809.3 s gate wall = 21.7%
(`TESTS-RESULTS/2026-09-24+GH-591/wave-326e48121a6ac3e28362d25c0964dae99bbb203c/validation.jsonl`);
local 4-wide pool pole 705.8 s (`TESTS-RESULTS/2026-09-21+GH-740/validation.jsonl`).

The red-control failure output also confirms the routing in-band:
`validate.sh: classified tier 2 — subsystems: skills-army-hq (GH-35)`.

Change: `PATHS_FILE` content `utils/py/releases_app.py` → `skills/3-weekly/skills-army-hq/scripts/sync.py`
(smallest measured `.py`-bearing tier-2 lane: 2 suites, 34.8 s hosted). The suite only needs
`--paths-file` to classify tier 2 with `T2_PYTEST=1`; the pytest lane itself is 20.9 s hosted.

Files: `before.log`, `after.log`, `red-control.log`, `red-control-restore.log`, `provenance.jsonl`.
