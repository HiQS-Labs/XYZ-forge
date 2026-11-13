# GH-1137 verification receipt — 2026-11-12

Change: `relay-automation/relay-turn-lib.sh` — the two `.relay-scratch` discard sites use
`git -C "$RTL_ROOT" clean -ffdxq -- .relay-scratch` instead of `rm -rf`, and `rtl_check` exempts a
`.relay-scratch` path only when it is not tracked. No test file or `validate.sh` entry was added (GH-831).

Environment: macOS (darwin), bash 3.2/5 via `/usr/bin/env bash`, git 2.x. "Unchanged lib" is
`relay-turn-lib.sh` at `origin/development` (`edcb39a6e`); "fixed lib" is this branch.

## Existing suites (task clone, hermetic temp fixtures)

| Suite | Result |
|---|---|
| `test/gh91-relay-scratch.sh` | 22 pass, 0 fail (sections 1 and 6 still see turn scratch removed, folder included) |
| `test/gh113-headless-scratch.sh` | 27 passed, 0 failed |
| `test/gh184-no-tracked-scratch.sh` | 2 pass, 0 fail |
| `test/gh654-offlane-log.sh` | OK |

## Manual checks (throwaway repos under `$TMPDIR`, lib sourced directly; no model call)

Each fixture repo commits `.relay-scratch/pdf/tracked.json` (`keep`) and `README.md` or `lane.md`.

| Case | Lib | Action | Observed | Verdict |
|---|---|---|---|---|
| A | unchanged | `rtl_check .relay-scratch/pdf/tracked.json` (the #1137 repro) | `rc=0 violation=0`, then ` D .relay-scratch/pdf/tracked.json` | Red control reproduces the bug |
| B | fixed | same call on the unmodified tracked file (artificial: a real turn only checks porcelain-dirty paths) | file kept (`keep`); path treated as host content (`violation=1`, orphan backup under `.tick/`) | No deletion |
| C | fixed | turn creates `.relay-scratch/tmp/p.json` and a nested repo `.relay-scratch/probe/`; `rtl_check .relay-scratch/tmp/` | `violation=0`; only `.relay-scratch/pdf/tracked.json` remains; `git status` empty | Turn scratch and nested repo removed, tracked kept |
| D | fixed | turn overwrites the tracked file; `rtl_check` on it | `violation=1`; file restored to `keep` | Normal containment |
| E | fixed | turn deletes the tracked file; `rtl_check` on it | `violation=1`; file restored to `keep` (from git; no orphan backup for a deleted file) | Normal containment |
| F | unchanged | full end-of-turn path: `rtl_before`; allowlisted `lane.md` edit; turn writes `.relay-scratch/tmp/out.json`; `rtl_enforce TASK builder "" test` | `enforce rc=0`; status ` D .relay-scratch/pdf/tracked.json`; last commit `lane.md` | Red control: the turn deletes the host file |
| F | fixed | same | `enforce rc=0`; tracked file `keep`; turn scratch gone; status clean (besides `.tick/`); last commit `lane.md` | Fixed |

Known inherited limits (not changed): `git checkout -- "$p"` restores from the index, so a staged
rename or staged edit under `.relay-scratch` is not fully undone; a deleted tracked file has no orphan backup.

## Gate

Tier-3 `validate.sh` result: see `provenance.jsonl` in this folder.
