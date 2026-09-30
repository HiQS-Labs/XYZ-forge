# GH-886 — three Linux portability-canary reds (gh153, gh478, gh425)

Landing 2 of the #854 window (D7), on `staging/stabilize-2026-10`, based on `development` `c7ea57fd`.

**Linux environment for red and green controls:** Ubuntu 24.04 container (Colima, aarch64), GNU bash 5.2.21, Python 3.12,
with the canary's git preparation. macOS (bash 3.2) was the other side of each difference. The hosted confirmation is a
`workflow_dispatch` of CI on this branch; its canary result is recorded on #886.

| Suite | Cause (confirmed) | Fix | Linux before → after | macOS after |
|---|---|---|---|---|
| `gh153-releases-sidebar-rollup` | The exporter JSON (about 134 KB, growing with each ledger row) went to Python as one argv element, over Linux's 128 KB `MAX_ARG_STRLEN`: `Argument list too long`. | Write it to `$WORK/export.json` and pass the path. | rc 1 → rc 0, 40/0 | green |
| `gh478-runaway-guard` | (a) bash 5 shows the parent's EXIT-trap text inside a `( … )` subshell even though it will not fire there, so `runaway_guard_init` refused in cases 4, 7 and 8: `REFUSING — the sourcing suite already owns the EXIT trap`. bash 3.2 shows nothing (probe below). (b) Hidden behind (a) because `fail()` exits: case 18 read `$TMPDIR` under `set -u`, and Linux leaves it unset. | (a) `trap - EXIT` at the top of the four subshells that model a trap-free suite; case 8's refusal subshell sets its own trap and is unchanged. (b) `${TMPDIR:-}`. Shared `test/lib/runaway-guard.sh` is not changed. | rc 1 → rc 0, 43/0 | green (21 s) |
| `gh425-gate-provenance-pr` | `canary-ubuntu` installs no pytest, so `wave_reconcile` qualification refuses by design (#750): `Command '['python3', '-c', 'import pytest']' returned non-zero exit status 1`. | `ci.yml` `canary-ubuntu`: the same `pip install … pytest requests PyYAML` step as the promotion-boundary job (operator OK for the `.github/` edit, 2026-09-28). | without pytest rc 1 → with pytest rc 0, 23 tests OK | green |

**Trap probe** (the gh478 mechanism): `trap "echo parent-trap" EXIT; ( echo "[$(trap -p EXIT)]" )`
- bash 5.2 (Linux): `[trap -- 'echo parent-trap' EXIT]`; after `trap - EXIT`: `[]`
- bash 3.2 (macOS): `[]`

**Suites run on macOS after the change:** the three above, `gh139-pipe-grep-guard`, `relay-pkg-freshness`, and every
registered suite that reads `ci.yml`: ci-route, ci-workflow, gh308, gh365-shellcheck-parallel, gh379-canary-uses-validate,
gh388, gh402, gh421, gh509-gate-evidence, gh514, gh544-parallel-default, gh544-pre-push-gate, relay-self-sufficiency.
All exited 0.

No new tests, no registry change, no change to shared test libraries.
