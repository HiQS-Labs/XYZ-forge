# Audit repro tooling

Two standalone probe scripts. They produced the evidence in the
[Windows/MSYS2 audit](https://github.com/HiQS-Suite/XYZ-forge/pull/29); this PR is the tooling only,
split out so the executable half can be reviewed on its own merits.

| Script | What it probes |
|---|---|
| `repro.sh` | Kernel probes P1–P7 — lane overlap on claim, input coercion, id sanitisation, cwd independence, corrupt-event blast radius, same-ms append collision, stale-epoch fence. |
| `repro-containment.sh` | Containment probes D1 + C0–C8 — hostile fake agents injected through the real shims via `CODEX_BIN`, asserting the harness's documented response to each. |

**Neither needs agent credentials, network access, or token spend.** Both exit non-zero only if the
*script* breaks; findings are reported in the summary and do not fail the run.

```bash
bash audit/repro.sh
bash audit/repro-containment.sh --help
bash audit/repro-containment.sh --out /tmp/probe-out --lane bash
```

## Boundaries these scripts hold to

Written after review feedback on the evidence PR. Each is a property the scripts are meant to keep,
and each is checkable by reading the top 90 lines.

- **No machine-specific paths.** The harness root resolves from the script's own location
  (`XYZ_UNDER_TEST` overrides). Nothing is hard-coded to a developer's profile directory.
- **No fixed directory is ever deleted.** Scratch space is a fresh `mktemp -d`. A caller-supplied
  `PROBE_TMP` must be absolute and either missing or empty, and cleanup only removes a directory
  *this run created* — a pre-existing one is adopted read-only and left behind. `mk_fixture` asserts
  its target is under the scratch dir before any `rm -rf`.
- **No network.** `repro.sh` refuses to run `npm install`; if `node_modules` is missing it says so and
  exits 3, because a script that promises no network must not quietly fetch packages.
- **Nothing is written into the repo.** Logs, screenshots and the results table go to `--out`
  (default: inside the scratch dir). Regenerating evidence cannot overwrite committed evidence.
- **Windows-safe path handling.** Anything handed to `node` goes through `nativep()`, since on
  MSYS/Git-Bash the bundled node is a native Windows build that cannot resolve `/c/...`. On
  Linux/macOS `nativep()` is the identity function.

## Verified from a separate full clone

Run on 2026-08-19 from this branch, pointed at a fresh `git clone` of `development` at `5746369`
(a different commit from the `911878c` the original audit measured):

```
XYZ_UNDER_TEST=/c/tmp/xyz-verify bash audit/repro-containment.sh --out /c/tmp/probe-out --lane bash
```

| | |
|---|---|
| Invariants confirmed | 8 (C0–C7) |
| Findings | 2 — D1 exit 1 (F7), C8 child survived the kill (F9) |
| Blocked | 0 |
| Script exit | 0 |
| Scratch dir | `mktemp -d`, removed on exit |
| Output | `/c/tmp/probe-out` — 42 logs, 42 screens, results table |
| Clone afterwards | `git status --porcelain` clean; no `audit/` directory created in it |

`repro.sh` was run against the same clone: exit 0, 3 invariants held, F1 and F5 reproduced, plus BUG-1
(1 of 50 same-ms events survived) — expected, since that clone does not carry the uniqueness-suffix fix.

**Not covered by this run:** the Python lane. It crashes before any turn starts on this host (F7), so
C0–C8 under `XYZ_PYTHON=1` are reported `BLOCKED` rather than passing — a control turn that never ran
proves nothing. A Linux or macOS reviewer running `--lane python` would close that gap.
