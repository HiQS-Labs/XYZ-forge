# Canary tier

`./canary.sh` is the first rung of the gate: a clean-room, network-free, model-free smoke tier that
proves the core XYZ surfaces still start, parse, and coordinate. It runs in seconds and never writes
inside the repo tree (the last check diffs the working tree and the clone's `.git` state — config,
remotes, HEAD — before and after).

| Surface | Check | Both runtimes? |
|---|---|---|
| static floor | `bash -n` every shell entry point, `node --check` `bin/`+`src/`, `py_compile` (sandbox copy) + import `utils/py` | n/a |
| tick kernel | init → claim → contended claim loses → release `--to` → take → done → project → analyze in a throwaway repo (`TICK_REPO_ROOT` pinned) | n/a (Node) |
| tick kernel | `bin/validate-relay-block` deterministic refusals (exit 1 missing file, exit 8 missing `STATUS:`) | n/a |
| relay | `relay-drive.sh --help`, `poll.sh --help`, `skills/relay-xyz/find-harness.sh --check` | yes |
| consult | `consult.sh --help` | yes |
| marathon | `bin/marathon-yaml` parses the canary plan; `marathon.sh --help`; `marathon-drive.sh --help`; `marathon.sh --dry-run` renders the relay file + tick seed with inert builder stubs | yes |
| jog | `utils/py/jog_run.py --help`; `--dry-run` against a copy of the committed releases ledger, asserting no ledger mutation | n/a (Python) |
| containment | repo tree and `.git` state unchanged after the run; the sandbox is ALWAYS a fresh, run-owned `mktemp` child — a caller-supplied `XYZ_CANARY_SANDBOX` names only the parent it is created under (validated: existing dir, outside the harness, not its ancestor, not `/` or home) — so caller input never becomes the deletion target | n/a |

"Both runtimes" = the Python default and the `XYZ_PYTHON=0` Bash twin. Jog is the serial
(lanes-off) supervisor over marathon; the canary exercises its queue simulation, never a drive.

## What it is not

Not a replacement for `./validate.sh` (the gate) or `ci-local.sh` (the qualifying run). A green
canary means "worth running the gate", not "done".

## Hosted CI

`.github/workflows/canary.yml` runs this script but is `workflow_dispatch`-only until the tier is
accepted. To arm it, add `push:` and `pull_request:` triggers in that file. Nothing in `canary.sh`
changes. Tracked in GH-928.

## Fixtures

- `fixtures/MARATHON.canary.yaml` — one-phase plan, dry-run only.
- `fixtures/briefs/p1.md` — the brief it renders; copied into the sandbox target repo.
