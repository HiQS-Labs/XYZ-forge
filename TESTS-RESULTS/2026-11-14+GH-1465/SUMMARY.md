# GH-1465 verification receipts (2026-11-14)

Manual checks for #1465. No suite or registry entry was added (GH-831). Code under test:
`f1ed1fddb` (fix) vs `e0586fc30` (base, `origin/development`). Paths in logs are redacted to
`<clones>`, `<scratch>` and `<home>`.

| Check | Command / script | Result |
|---|---|---|
| **Red control** (real GH-955 builder and reviewer blocks from `TESTS-RESULTS/2026-11-11+GH-1428/`; scripted reviewer turn; gate is a script in the target repo that prints its cwd and exits as told) | `gh1465-red-control.sh <clone> e0586fc30 f1ed1fddb gh955-builder.md gh955-reviewer.md` | Base: reviewer declares `gate run: yes — exit 0`, gate would exit 1, **attested rc 0** (the bug; nothing ran). Fix, same input: driver runs the gate, exit 1, **refused rc 4 `unverified-approval`**. Builder block with nothing unverified, gate exit 1: **refused `gate-failed`**. Gate exit 0 with no declaration: attested, record `gate_exit: 0` + `gate_cmd`, trailer `driver-gate: exit 0 — bash gate.sh 0`, `relay_attest.load` ok. Gate not runnable: exit 127, refused. Unarmed: attested as before, no gate fields (`red-control.out`) |
| Where it runs | same run | The gate printed the target repo as its cwd and `RELAY_ROLE=scrubbed` (harness env removed by `gate_env`) |
| Residue | `fix-gate-green-leaves-file` row | A gate that leaves an untracked file in the target checkout does not fail the driver (rc 0, attested); the file stays, as it would after the pre-advance gate |
| Existing focused suites (disposable `-verify` full clone of `6e64411e2`, Python 3.14.7) | `for s in gh505-relay-attest gh681-reviewer-probe-rules gh268-relay-cue-and-target-checks new-relay relay-pkg-freshness gh307-gate-env-scrub gh441-gate-env-contract debug-mantra; do bash test/$s.sh; done` (one process per suite) | all rc=0: 63, 27, 35, 17, 3, 12, 18, 17 pass, 0 fail (`focused-*.log`) |

Not measured: the 900-second timeout path (exit 124); a live reviewer turn; a real host gate
(for example a DB-backed pytest file) run by the driver.

Known gap (PR #1467 review): the driver-run gate has a wall-clock cap only. It does not carry the
marathon pre-advance gate's memory and CPU guard (GH-390), and it runs before that guarded gate.

## Full gate (pre-push, disposable `-verify` full clone)

- **GREEN.** Head `4f3569a55`, `python3` = 3.12.14 (throwaway uv venv with `pytest requests pyyaml`
  first on PATH), `githooks/pre-push` → full `validate.sh` route: `passed: 408 / 408`, Python layer
  `21 passed`, `full gate GREEN in 621s` (`full-gate-py312.log`). The push to `origin` happened from
  that clone. `HEAD`, `core.bare`, remotes and local `user.email` were identical before and after.
- A local run is self-reported and is not promotion qualification (AGENTS.md, GH-509).
