# Round 2 — MSYS2 follow-up for PR #29, and eight suites that were failing for real reasons

Two separate pieces of work. The first is the follow-up that was requested and never landed. The
second started as "why does the local gate refuse on Linux" and turned into eight fixes.

---

## ⚠️ Gate status, stated plainly

This branch is **not** backed by a fully green local gate, and I am not implying otherwise.

**Before this branch**, a full `validate.sh` on a pristine `--ff-only` checkout of `development` at
`713ba6d1` — containing none of my changes — failed **9 suites** while hosted CI was green at the
same SHA.

**After this branch**, that is down to **1**, and the remaining one is not fixable here:

| Suite | Status |
|---|---|
| `relay-self-sufficiency.sh` | ❌ agy individual quota exhausted — resets ≈2026-08-27 15:30 |

The agy CLI prints the reason verbatim: `Error: Individual quota reached. Please upgrade your
subscription to increase your limits. Resets in 75h40m54s.` No code change can clear it; it wants a
re-run after the reset.

Everything else is green. The eight suites this branch fixes are listed below with their root causes.

**How that number was arrived at, since it moved once.** An earlier full run of mine reported *three*
failures — the one above plus `roadmap-dashboard.sh` and `clone-identity-invariant`. Both extras were
self-inflicted: I edited `ROADMAP.md` and committed **while the gate was running**, which is exactly
the hazard the repo documents (GH-141 — never hand-edit a clone while a run is in flight).
`roadmap-dashboard` was a real drift I had just introduced and is fixed in this branch;
`clone-identity-invariant` is the GH-1 identity bracket correctly noticing a tree that changed
underneath it. The **1** above is from a clean re-run on an untouched tree: **260 suites, one
failure**, with `clone-identity-invariant` passing. CI is green on this PR.

---

## Part 1 — the PR #29 follow-up (`evidence/PR29-MSYS2-FOLLOWUP.md`)

`ROADMAP.md` still records the gap in its own words: *"PR #29 closed — its tooling half landed as
#51, but its Windows/MSYS2 evidence half never landed anywhere and was requested as a follow-up, so
that platform still has no coverage."*

Rather than re-post the old report, I re-ran its findings against **today's** HEAD on real MSYS2
(Windows 11 build 22631, `MINGW64_NT`, same machine and build PR #29 used), from a pristine clone
verified at `713ba6d1` with a clean `git status`.

**Four of five still reproduce.**

| # | Finding | PR #29 | Today |
|---|---|---|---|
| F7 | Python lane cannot exec `bin/tick` | HIGH | **OPEN** — identical `[WinError 193]` |
| F8 | `case "$x" in /*)` misreads a Windows absolute path | MEDIUM | **OPEN** — call sites grew 20+ → **27** |
| F9 | PID-scoped watchdog kill | MEDIUM | **not probed** — claimed neither way |
| F10 | unconditional `signal.SIGHUP` | MEDIUM | **OPEN, and mis-guarded** |
| F11 | `validate.sh` recursion | HIGH | **OPEN** — the proposed guard was never added |

**F10 is the one worth reading** → filed as **#203**. `marathon_drive.py:2862` wraps
`signal.signal()` in `except (ValueError, OSError, AttributeError)` with a comment reading *"or the
platform has no such signal"* — but `signal.SIGHUP` is dereferenced building the loop's **tuple**,
which is evaluated once, before the body, and therefore outside the `try`. The guard cannot fire on
Windows. `git log -S` dates the construct to `1f0a5bf1` (2026-08-15), so it **predates #29 and was
never a response to it**. A POSIX-hosted suite can never catch it, because the tuple always builds
there.

Re-runnable probe at `evidence/msys2/probe-msys2.sh` — no credentials, no network, no token spend.
Transcripts under `evidence/msys2/logs/` for both `MSYSTEM=MSYS` and `MSYSTEM=MINGW64` (identical
verdicts).

**Stated, not buried:** the probes were launched by invoking `bash.exe` through WSL interop rather
than by typing into a Git-Bash window. The process is genuinely MSYS2 — `uname` reports
`MINGW64_NT-10.0-22631`, and F7 fails with a real `CreateProcess` `[WinError 193]`. What that shape
does not exercise is Git-Bash console TTY behaviour, which is part of why F9 is not claimed.

---

## Part 2 — eight suites, eight real causes

None of these were host quirks, and **two of my own first-pass attributions were wrong** (I had
guessed agy fallout for `archive-writers` and both GH-101 synthetics; all three were something else).
They were marked "not proven" at the time, which is the only reason the error was cheap to catch.

| Suite | Root cause | Result |
|---|---|---|
| `claude-turn.sh` | PATH filter strips `node` (**#206**) | 35/1 → **36/0** |
| `gh69-roadmap-shadow.sh` | `sed -i ''` ×2 (**#204**) + SQLite DQS misfeature | 49/4 → **53/0** |
| `gh103-timeline-exporter.sh` | BSD `md5` (**#207**) + SIGPIPE in `has()` + undocumented `rg` | 35/3 → **38/0** |
| `gh382-marathon-memory-telemetry.sh` | darwin-only feature asserted everywhere (**#208**) | → **skips honestly** |
| `relay-file-seeding-visibility.sh` | fixture remote HEAD dangles | 0/1 → **3/0** |
| `archive-writers.sh` | same fixture-HEAD bug | → **8/0** |
| `synthetic/gh101-consult-programmatic.sh` | no OS sandbox backend | → **skips honestly** |
| `synthetic/gh101-relay-programmatic-stress.sh` | same | → **skips honestly** |

### The two with the widest blast radius

**The fixture remote's HEAD names a branch that is never created.** `test/_setup.sh` built the shared
bare remote with plain `git init --bare`, so its HEAD followed the machine's `init.defaultBranch` —
which git still defaults to `master` when unset — while the seed pushes only `main`. On such a host
every clone lands with an **unborn HEAD and no commits**, and `rtl_worktree_begin`'s
`git worktree add --detach <path> HEAD` dies with `fatal: invalid reference: HEAD`. The suite then
reports a worktree-seeding defect *in the harness*, which is not what happened. One line
(`-b main`), two suites. It also removes a silent dependency on a global git setting no doc mentions.

**`has()` was unsound under its own `pipefail`.** `gh103` defined
`has(){ printf '%s' "$1" | grep -Fq -- "$2"; }` under `set -uo pipefail`. `grep -q` exits the instant
it matches, closing the pipe while `printf` is still writing; printf dies of **SIGPIPE** and pipefail
reports the pipeline as **141** — indistinguishable from "not found" — for a string that is present:

```console
$ has "$TPL" "rel.baseline"; echo $?
141                        # while grep -Fc on the same input prints 4
```

Whether it fires depends on where the match sits and on scheduling, so it read as flaky rather than
broken. Now bash pattern matching, which needs no pipe and cannot race.

### Two false greens removed

Both of these were **passing**, for no reason:

- `gh103`'s read-only contract (*"the exporter wrote no DB bytes"*) compared `"" = ""` on Linux,
  because every `md5` call failed. The guarantee that the exporter never writes to the releases
  ledger was untested on every Linux host.
- `gh103`'s *"and NOT in #fbar"* assertion is negated and called `rg`; with ripgrep absent, `rg -q`
  returned 127 and `! rg -q` was trivially true.

That suite now runs **two more real assertions** than before, at 38/0 rather than 35/3.

### Deliberately not fixed here

The **production** `sed -i ''` sites — `relay-drive.sh:546` and `build-launch-artifact.sh:283` — are
untouched. They change driver behaviour and want their own review. `relay-drive.sh:546` is the
serious one: on the consult-verify divergence path the write is lost, the exit code is unchecked, and
the driver still prints `relay escalated` and exits 4 — so **a genuinely failed review can read as
still open**. Tracked in **#204**, along with the note that a regression test there must assert on
file content, since the exit code is the thing currently lying.

---

## Also in this branch

- `PROJECT/1-INBOX/GH-204-BSD-SED-IDIOM.md` — the sed bug promoted out of `evidence/` into the real
  ledger. It had existed only inside `evidence/`, which `marathon-plan.sh` does not read, so the
  planner could never schedule it.
- `evidence/FINDINGS.md` — F-002 **closed** with the `marathon-plan.sh` "the compute" mapping;
  F-013 **downgraded to latent** and routed to GH-35 Phase 3 rather than duplicated as a new issue;
  F-024 … F-032 added.
- **#205** — a full gate run mutates four *tracked* files and appends a benchmark row each time.
  `harnesses.sql` already carried three identical Qwen rows before my run and now carries four, so
  this is not specific to one machine.

## Issues filed

**#203** SIGHUP guard · **#204** BSD sed (5 call sites) · **#205** gate mutates tracked files ·
**#206** claude-turn PATH filter · **#207** BSD md5 vacuous pass · **#208** darwin-only assertion

Every number was verified against live GitHub with `gh issue view` before being referenced.
