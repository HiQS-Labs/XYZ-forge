# ENVIRONMENT.md — audit environment stamp

> The harness changes behaviour with detected core count, host OS, and which language lane is
> reachable. A finding without this stamp is unverifiable — so this stamp is itself measured, not
> recalled. Every value below was captured by the containment probe run into
> `audit/logs/env-stamp.log`; that log is the primary record and this file is its transcription.
>
> **Corrections to the previous revision of this file** (it was written from assumption on three
> points, and one of them changed a conclusion):
> - OS was recorded as *Windows 10 Pro*. It is **Windows 11 Pro**, build 22631.
> - Node was recorded as *v22.23.2*. It is **v22.12.0**.
> - `python3` was recorded as a *Microsoft Store stub only*, from which the previous pass concluded
>   the Python lane "was not exercised" and would harmlessly degrade to Bash. **That was wrong.**
>   `python3` resolves to a real **Python 3.13.14**, the version guard at `codex-turn.sh:13-14`
>   **passes**, and the Python lane is therefore the one this host actually takes by default — where
>   it crashes (finding F7). The earlier "safe degradation" reading inverted the real risk.

## Host

| Property | Value |
|---|---|
| OS | **Microsoft Windows 11 Pro**, version 10.0.**22631** (23H2) |
| Kernel (as MSYS reports it) | `MINGW64_NT-10.0-22631 ... x86_64 Msys` |
| Shell | GNU **bash 5.2.37(1)-release** (MSYS2 / Git-Bash) |
| **Not WSL** | Native Windows + MSYS2, *not* Windows Subsystem for Linux. A **third environment**, distinct from the maintainer's macOS measurements and from the open Linux canary. |
| Terminal sandbox | Probes ran in a **persistent, un-sandboxed** native shell. The repo's own GH-177 guard refuses `validate.sh` under a sandboxed shell — see the friction log. |

## Toolchain

| Property | Value |
|---|---|
| Node.js | **v22.12.0** — a **native Windows** build. Resolves `C:/...`, not `/c/...` (see F-ENV-1) |
| npm | 10.9.0 |
| git | 2.47.1.windows.1 — returns **`C:/...`-style absolute paths**, which is what triggers F8 |
| `python3` (bare PATH) | **Python 3.13.14** via `.../WindowsApps/python3` — **the guard passes, so the Python lane is live** |
| `python` (bare PATH) | Python 3.12.2 |
| acorn / acorn-walk | installed by `npm install` (2 packages, ~2s) |
| Headless browser | Google Chrome (used by the probe run for local mermaid rendering) |

## Compute

| Property | Value |
|---|---|
| Logical CPUs | **4** (`nproc`) |
| RAM | **23.9 GB** (25,643,622,400 bytes) |
| Disk | local NVMe/SSD, NTFS |

## Harness state at audit time

| Property | Value |
|---|---|
| Harness commit | `911878c` on `development` |
| Probe target | a **pristine `git worktree add --detach origin/development`** at `C:/tmp/xyz-pristine` — so no finding depends on the uncommitted BUG-1 patch in the main working tree |
| `node_modules` | absent after clone; `npm install` required (not foregrounded in the README happy path) |
| Git hooks | not wired until `bash githooks/install.sh`; **in a worktree on Windows the check reports a mangled path and always says NOT INSTALLED** (F8) |
| Default language lane | **Python** — `codex-turn.sh:9` reads `${XYZ_PYTHON-1}`, and an unset variable substitutes `1` |
| Line endings | CRLF throughout `.sh`/`.js` (portability hygiene, G1) |

## Why this matters for the findings

- **Core count (4).** `validate.sh` auto-sizes parallelism to host cores; this audit ran it with an
  explicit `--sequential`, so no core-dependent behaviour is being asserted either way. The maintainer's
  8-wide spike numbers (950s → 167s on an M-series mac) are not comparable to anything measured here.
- **Native-Windows node.** `/c/...` → `C:\c\...` mangling is an MSYS↔native-node artifact (F-ENV-1),
  worked around in the probe scripts by forcing `C:/...` form via `cygpath -m`. Not a harness logic bug.
- **git returning `C:/...`.** This is the precondition for F8: a POSIX-only `case "$x" in /*)` test reads
  a Windows absolute path as relative.
- **A live `python3`.** This is the precondition for F7, and it is the difference between "the Python lane
  is untested here" and "the Python lane is what this host runs, and it crashes."
- **Separation of concerns.** F9 (PID-scoped kill) reproduces on any OS. F7, F8, F10 are harness bugs whose
  *manifestation* is Windows-only. F-ENV-1 and F-ENV-2 are environment notes, not harness defects. Nothing
  in the findings file blends these categories.
