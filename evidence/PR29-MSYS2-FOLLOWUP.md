# PR #29 — Windows/MSYS2 follow-up evidence

**Status:** the follow-up that was asked for and never landed.
**Date:** 2026-08-24 · **Checkout audited:** `713ba6d1` · **Author:** arnoldadero

## Why this exists

`ROADMAP.md` still records the gap in its own words:

> PR #29 closed — its tooling half landed as #51, but its Windows/MSYS2 evidence half never
> landed anywhere and was requested as a follow-up, so that platform still has no coverage.

PR #29 (`audit: external Windows/MSYS2 audit — containment holds, default lane and gate do not`,
closed 2026-08-21) audited commit `911878c`. The repo is now ~95 commits further on. A follow-up
that just re-posts the old report would be worth little. The question worth answering is the one
nobody has answered since:

**Do PR #29's findings still reproduce on Windows today, and did any of them get fixed?**

Answer: **four of five still reproduce at `713ba6d1`.** One of them is worse than #29 described,
because the code that looks like it handles that case cannot.

## Environment

Same physical machine and same Windows build as PR #29 (Windows 11 build 22631).

```
uname     : MINGW64_NT-10.0-22631 DESKTOP-NVQQIAE 3.5.4-395fda67.x86_64 x86_64 Msys
windows   : Microsoft Windows [Version 10.0.22631.6199]
bash      : GNU bash 5.2.37(1)-release (x86_64-pc-msys)
git       : git version 2.47.1.windows.1
node      : v22.12.0
python    : Python 3.12.2   (native Windows build, C:\Users\<user>\AppData\Local\Programs\Python\Python312)
head      : 713ba6d11d3d7d762dcdfe2f98e6991176de2dca
```

Full stamp: [`evidence/msys2/logs/env-stamp.log`](msys2/logs/env-stamp.log).

**Method.** A pristine `git clone` of the repo onto the Windows filesystem at `C:/xyz-msys2-probe/repo`,
verified at `713ba6d1` with a clean `git status` — deliberately not a working tree, so no finding
depends on a local patch. Probes were then run by `bash.exe` from Git for Windows, under both
`MSYSTEM=MSYS` and `MSYSTEM=MINGW64`. **Verdicts were identical under both**; the MINGW64 transcript is
the one cited here, since MINGW64 is what PR #29 audited.

**One caveat about invocation, stated rather than buried.** The probes were launched by invoking
`bash.exe` through WSL interop rather than by typing into a Git-Bash terminal window. The process
itself is genuine MSYS2 — `uname` reports `MINGW64_NT-10.0-22631`, and F7 fails with a real
`[WinError 193]` from `CreateProcess`, which is not something a Linux process can produce. What this
shape does *not* exercise is terminal/TTY behaviour specific to a Git-Bash console window. No finding
below depends on that, but F9 (below) is not probed here partly for this reason.

**Reproduce it:** [`evidence/msys2/probe-msys2.sh`](msys2/probe-msys2.sh). No credentials, no network,
no token spend, writes nothing outside its `--out` directory.

```bash
bash evidence/msys2/probe-msys2.sh --out /c/some/dir
```

## Results at `713ba6d1`

| # | Finding | PR #29 | Today | Note |
|---|---|---|---|---|
| **F7** | Python lane cannot exec `bin/tick` | HIGH | **OPEN** | identical `[WinError 193]` |
| **F8** | `case "$x" in /*)` misreads a Windows absolute path | MEDIUM | **OPEN** | call sites grew 20+ → **27** |
| **F9** | watchdog kill is PID-scoped; forked child outlives it | MEDIUM | **not probed** | see below |
| **F10** | unconditional `signal.SIGHUP` | MEDIUM | **OPEN — and mis-guarded** | headline; see below |
| **F11** | `validate.sh` recurses through `githooks/pre-push` | HIGH | **OPEN** | proposed guard never added |

---

### F10 — the guard that cannot fire

This is the one finding worth reading in full, because the repo *looks* like it handles this case.

`utils/py/marathon_drive.py:2862`:

```python
for _sig in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
    try:
        signal.signal(_sig, _terminate)
    except (ValueError, OSError, AttributeError):
        pass    # not the main thread, or the platform has no such signal — best effort
```

The comment says *"or the platform has no such signal"*, and `AttributeError` is caught — so a reader
concludes Windows is covered. It is not. **`signal.SIGHUP` is dereferenced while building the tuple,
which is evaluated once, before the loop body runs and therefore outside the `try`.** On a platform
with no `SIGHUP` the `AttributeError` is raised constructing the tuple and escapes uncaught.

Measured, on Windows Python 3.12.2:

```
has SIGHUP: False
RESULT: AttributeError escaped the guard -> module 'signal' has no attribute 'SIGHUP'
```

`git log -S` dates this construct to `1f0a5bf1` (2026-08-15, *"XYZ: initial public release"*) — it
**predates PR #29 and was never a response to it.** So the defensive `except AttributeError` has never
protected the platform its own comment names.

The fix is a one-line move — resolve the signals defensively, then loop:

```python
_sigs = [s for s in ("SIGTERM", "SIGINT", "SIGHUP") if hasattr(signal, s)]
for _name in _sigs:
    try:
        signal.signal(getattr(signal, _name), _terminate)
    except (ValueError, OSError):
        pass
```

**Why this matters beyond Windows:** the same pattern — a guard placed inside a loop whose *iterable*
contains the thing that fails — is the kind of defect a test suite on a POSIX host can never catch,
because the tuple always builds there. This is exactly the argument PR #29 made for the environment
existing at all, and it is now demonstrated rather than asserted.

### F7 — `subprocess` cannot exec a shebang script

`utils/py/rtl.py:316` (and 4 sibling call sites) run `bin/tick` as `subprocess.run([tick_bin, ...])`.
`bin/tick` opens `#!/usr/bin/env node`. `CreateProcess` does not honour shebang lines, so:

```
tick path: C:/xyz-msys2-probe/repo/bin/tick
isfile: True X_OK: True
RESULT: OSError -> OSError 193 [WinError 193] %1 is not a valid Win32 application
```

`os.access(..., X_OK)` returns `True`, so `resolve_tick_bin()` (`rtl.py:272-285`) accepts the path and
hands downstream a binary that cannot be executed. The failure surfaces as a bare `OSError`, which is
not in the shim's documented exit menu, so `relay-drive` cannot classify it — unchanged from #29.

### F8 — a drive-letter path is not "absolute" to `case`

```
input=C:/Users/example/hooks     -> C:/tmp/repo/C:/Users/example/hooks
input=/c/Users/example/hooks     -> /c/Users/example/hooks
input=relative/hooks             -> C:/tmp/repo/relative/hooks
```

The construct `case "$x" in /*) ;; *) x="$REPO/$x" ;; esac` classifies `C:/...` as relative and
concatenates it. PR #29 counted "20+ call sites"; at `713ba6d1` the count is **27**, so the class is
growing, not shrinking. `githooks/install.sh:53` — the site #29 named — is unchanged.

### F11 — the recursion guard was never added

PR #29's closing note called an explicit re-entrancy guard in `validate.sh` its *"cheapest high-value
fix"*: set `XYZ_VALIDATE_ACTIVE=1` on entry, refuse loudly if already set, and the whole recursion
class closes regardless of root cause. `validate.sh` at `713ba6d1` contains no such guard.

This probe checks that **statically and does not run the gate**, deliberately: the failure mode being
described is a 47-minute non-terminating hang, and re-triggering it proves nothing that #29 has not
already recorded.

### F9 — deliberately not claimed

Not probed. It needs a forked child outliving a PID-scoped watchdog kill, which is a timing-sensitive
race rather than a static property, and the WSL-interop invocation shape above is the wrong harness for
a clean measurement. **It is unverified today, not fixed** — `relay-turn-lib.sh:467-469` still carries
the comment #29 cited. Anyone re-running this should probe F9 from a real Git-Bash window.

## What this does and does not establish

- **Does:** four findings from a closed PR are still live on Windows at today's HEAD, with a
  re-runnable probe and per-finding transcripts. F10 is materially worse than #29 reported.
- **Does not:** claim a green suite on this host. It was not run — PR #29 already established the full
  gate cannot go green here (F7/F8/F10 fail it by construction), and F11 means it may not terminate.
  Nothing below is gate-backed, and nothing here says otherwise.
- **Does not:** claim F9 either way.

## Suggested disposition

One issue, or three. F10 is the one to file first — it is a two-line fix, it is currently disguised as
handled, and it is the only one of the four that a reader of the source would actively conclude was
already solved.

## Artefacts

| Path | What |
|---|---|
| [`evidence/msys2/probe-msys2.sh`](msys2/probe-msys2.sh) | the re-runnable probe |
| [`evidence/msys2/logs/env-stamp.log`](msys2/logs/env-stamp.log) | environment stamp |
| [`evidence/msys2/logs/probe-run-mingw64.log`](msys2/logs/probe-run-mingw64.log) | full transcript, `MSYSTEM=MINGW64` |
| [`evidence/msys2/logs/probe-run.log`](msys2/logs/probe-run.log) | full transcript, `MSYSTEM=MSYS` |
| `evidence/msys2/logs/f7.log`, `f8.log`, `f10.log` | per-finding raw output |
