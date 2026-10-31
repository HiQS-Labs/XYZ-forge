# GH-1284 — factory-primitive read commands no longer create state

Manual check (no new tests, GH-831). Ran in the disposable clone
`XYZ-forge-gh1284-status-creates-state-2026-10-31-verify` with `smoke.sh`; output in `smoke.txt`.

| Path | Before (origin/development) | After |
|---|---|---|
| `status` on a fresh root | rc 0, creates `state.db` | rc 2 `instance not initialized; run init first`, no `state.db` |
| `init` after that `status` | rc 2 `instance already initialized` | rc 0 |
| `tick` / `packet` on a fresh root | open and create `state.db` | rc 2, no `state.db`; a later `init` is rc 0 |
| `init` → `status` → `tick --slot 1` (and the same tick again) | unchanged | rc 0 each |

Red control: the same `status` → `init` pair on the unpatched harness reproduces the bug
(rc 0 with `state.db` created, then rc 2), so the check detects the failure.

Limits: covers the three guarded entry points only; `init` paths are unchanged by design. No
sandbox; GH-1280 D1 had already shown the bug reproduces unsandboxed.
