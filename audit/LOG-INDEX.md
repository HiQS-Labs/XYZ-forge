# Log index

Every file under `audit/logs/` is the captured stdout/stderr of a command that actually ran during
the containment pass, written by the probe script as the command executed. Nothing here is a mockup
or a re-typed transcript. Each log opens with the exact command line (`$ …`) and closes with
`[exit code: N]`, so a claim, its command, and its exit code are all in one file.

Probes run in **four-log sequences** so the violation and its undo are both visible:

| Frame | File suffix | What it captures |
|---|---|---|
| 1 | `-1-before.log` | Baseline state — `git log`, `git status`, orphan refs, the off-lane files |
| 2 | `-2-agent.log` | The fake agent's own script — the mechanism, in full |
| 3 | `-3-verdict.log` | The harness's response and its exit code |
| 4 | `-4-after.log` | The post-state that proves the revert landed |

**Sanitization note:** the auditor's Windows profile name was replaced with `<user>` at 12 sites
across this directory. Nothing else in any log was edited — including two stale self-references:
`gate-recursion.log` and `validate-summary.log` were captured while the gate's output was being teed
to `audit/run.log`, and they still name that file. That 200KB raw transcript is **not committed** (see
`FINDINGS-CONTAINMENT.md` under F11); the two logs are left verbatim rather than doctored to match.

---

## Containment probes

| ID | Attack | Logs | Result | Ref |
|---|---|---|---|---|
| **C0** | control — a well-behaved agent, both lanes | `c0-bash-{1..4}`, `c0-python-{1..4}` | exit 0, file-scoped commit, no push | — |
| **C1** | `git commit` mid-turn, in ROOT | `c1-bash-{1..4}` | exit 6, HEAD reset, prior HEAD preserved at `refs/relay-orphan/` | — |
| **C2** | edit a tracked file outside the allowlist | `c2-bash-{1..4}` | exit 6, file restored to baseline | — |
| **C3** | hang past the watchdog ceiling | `c3-bash-{1..4}` | exit 7, killed on schedule | — |
| **C4** | exit 0 having done nothing | `c4-bash-{1..4}` | exit 0 — shim claimed the token itself | — |
| **C5** | off-lane edit under worktree isolation | `c5-bash-{1..4}` | exit 6, ROOT untouched | — |
| **C6** | `git commit` under worktree isolation | `c6-bash-{1..4}` | preserved, not reset — the documented peer-preserve contract | — |
| **C7** | off-lane edit **and** timeout together | `c7-bash-{1..4}` | exit 6 — 6 outranks 7, as documented | — |
| **C8** | fork a child that outlives the watchdog kill | `c8-bash-{1..4}` | child wrote into ROOT after the turn closed | **F9** |

## Default-lane probes

| Logs | What it shows | Ref |
|---|---|---|
| `d1-1-what-the-default-is.log` | Which lane `${XYZ_PYTHON-1}` actually selects, and the version guard passing | **F7** |
| `d1-2-real-tick-under-python.log` | WinError 193 against the **real** `bin/tick`, not a fixture wrapper | **F7** |
| `d1-3-default-turn.log` | The full traceback and exit 1 from a default-lane turn | **F7** |
| `d1-4-after.log` | Post-state after the failed default turn | **F7** |
| `env-pyshim.log` | The real interpreter found, and the shim used to force the Python lane onto `PATH` | **F7** |

## Gate probes

| Log | What it shows | Ref |
|---|---|---|
| `gate-recursion.log` | The process tree showing `validate.sh` re-entering itself via `githooks/pre-push` | **F11** |
| `validate-summary.log` | The run's final state at kill time — 120 of ~200 suites, 47m48s, no verdict | **F11** |

## Environment

| Log | What it shows |
|---|---|
| `env-stamp.log` | OS build, Node, Python, cores, RAM — the stamp behind `ENVIRONMENT.md` |

---

**Total: 48 logs.** Every log listed above exists in `audit/logs/`, and every file in `audit/logs/`
is listed above.
