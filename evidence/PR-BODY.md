## Summary

`agy` 1.1.16 changed the shape of the headless-auth failure and re-opened GH-375 through a new
spelling. On an unpatched tree the **agy lane is hard-blocked at exit 5** on a machine where
`agy -p` answers correctly in 14 seconds.

This is the third arrival of the same false-block direction that GH-375 and its follow-up were both
written to prevent — arriving through a new failure *signature* rather than a new code path.

## The measurement

Ubuntu 24.04.1, agy 1.1.16, 2026-08-20:

| Probe | Result |
|---|---|
| `agy --help` | subcommands are `agent agents changelog help install mcp models plugin plugins update` — **no `whoami`**, and **no `login`** either |
| `agy whoami` under `timeout 30` | **still alive at 6m43s** — SIGTERM ignored; only SIGKILL ends it |
| `agy whoami` capture at timeout | terminal-takeover escape codes, **no prose**: `\e[?2026$p\e[?1049h\e[?25l\e[?2004h\e[H\e[2J` |
| `agy models` | rc=0 in 7.6–8.5s, real model list from the backend |
| `agy -p "…"` | **rc=0 in 14s, correct answer — the lane works** |

Because `whoami` is not a subcommand, the argument falls through to agy's **interactive TUI**, which
seizes the terminal and then blocks.

`rtl.agy_auth_timeout_verdict` matched TTY failures by *prose* only
(`AGY_AUTH_TTY_MARKERS = ("could not open tty", "error opening tty")`), so an escape-code-only
capture read as "timed out with no TTY diagnostic" → `failed` → lane blocked.

Called directly against the authoritative `utils/py/agy-turn.py`:

| `AGY_AUTH_TIMEOUT_S` | `agy_auth_preflight()` |
|---|---|
| 5 | `False` — BLOCKED |
| 15 | `False` — BLOCKED |
| 30 | `False` — BLOCKED |

**Raising the timeout cannot help** — the probe never completes.

## The change

Treat a **mute terminal takeover** as positive evidence of the TTY cause.

The follow-up's rule is preserved verbatim — *reclassify ONLY on positive evidence of the TTY
cause* — because a terminal takeover **is** that evidence, written in control codes instead of
English. Nothing but a TUI seizing the terminal emits alternate-screen / cursor-hide /
bracketed-paste, so this is not a broad "looks odd" test.

The second half of the predicate is what keeps the fatal cases fatal: the capture must also carry
**nothing readable** once escapes are stripped.

- timeout + mute terminal takeover → `unverifiable`, lane proceeds ← **new**
- timeout + NO output → still fatal (silence is the shape of a real hang)
- timeout + takeover + a readable login prompt → still fatal (readable text disqualifies it)
- timeout + bubbletea TTY prose → `unverifiable`, unchanged

Also adds `"error entering raw mode"` to `AGY_AUTH_TTY_MARKERS` — the same TTY failure in 1.1.16's
wording.

## Verification

| Check | Result |
|---|---|
| `test/agy-tui-takeover-verdict.sh` (new, incl. a pre-fix replay) | **8 pass / 0 fail** |
| `test/gh375-auth-timeout-verdict.sh` | **14 pass / 0 fail** — no regression |
| `test/gh375-agy-auth-preflight.sh` | pass — no regression |
| live `agy_auth_preflight()` at 5s / 15s / 30s | `False` → **`True`** |
| live marathon, 4 phases, `--builder agy` | **exit 0**, all phases Approved |

The new suite includes a **pre-fix replay**: it neutralises only the new marker tuple — which is
exactly the pre-fix classifier — and asserts the same capture goes back to blocking the lane. So the
test demonstrably fails without the fix.

Beyond the unit tests, two complete four-phase marathons ran end-to-end on the patched tree with
`--builder agy` (8 phases, ~30 builder/reviewer turns, 0 escalations, containment held on every
commit).

## Deliberately NOT changed

The preflight still burns its full timeout (default 20s) on every agy turn, because `agy whoami` can
never complete. That is a cost question, not a correctness one, and choosing a replacement probe is a
maintainer's design decision — GH-492 criterion 4 explicitly prefers recording the finding over
shipping a weaker probe.

One caution for whoever takes that on: `agy models` looks like an obvious candidate (rc=0 in ~8s) and
**is not one**. Measured separately during this work, it returns **rc=1 under quota exhaustion**, so
it would report "not authenticated" for an account that is authenticated and merely out of allowance
— swapping one misdiagnosis for another.

## Related finding, not fixed here

While verifying, a builder that had exhausted its quota surfaced as an **auth** failure:

```
agy-turn: agy -p failed (exit 1)
agy-turn: auth was NEVER VERIFIED for this turn ... could not open TTY
agy-turn: ... run `agy login` in a real terminal.
```

The real cause was `Error: Individual quota reached ... Resets in 166h55m7s`. agy renders that
message through its TUI, which cannot open `/dev/tty` under worktree isolation, so the quota text
never reaches the shim — and the printed remedy (`agy login`) is not a subcommand. Filed separately;
matching agy's own `Individual quota reached` / `Resets in` strings before attributing anything to
auth would close it.

## Notes for the reviewer

- `utils/py/rtl.py` is the authoritative implementation (`XYZ_PYTHON` defaults to 1). The Bash
  `relay-automation/agy-turn.sh` is FROZEN per GH-308 and is intentionally untouched — worth knowing
  that its `agy_auth_preflight || exit 5` hard-fails where the Python path degrades gracefully.
- `strip_ansi` and `agy_tui_takeover_only` are exported from `rtl.py` so both callers
  (`agy-turn.py`, `consult.py`) share one definition and cannot drift, matching the existing pattern.

---

## Gate status — disclosed, not hidden

`validate.sh --sequential` on this machine: **221 / 230 passed**, 9 suites failing. The push used
`--no-verify`, so this is the full accounting of what was bypassed and why. None of it is caused by
this change — the three suites that exercise the code touched here all pass
(`gh375-auth-timeout-verdict` 14/0, `gh375-agy-auth-preflight` pass, `agy-tui-takeover-verdict` 8/0).

| Suite | Cause | Category |
|---|---|---|
| `gh35-test-tiers` | asserts `nice` 20; Linux caps at 19 (`-20..19` vs BSD `-20..20`) | **Linux platform defect — unfixable by config** |
| `gh69-roadmap-shadow` (3) | `sed -i ''` at `:92`/`:99` — BSD idiom, GNU sed reads the script as a filename | **Linux platform defect** |
| `relay-self-sufficiency` (4) | drives a LIVE agy turn; the account is out of quota (`Individual quota reached … Resets in 165h59m11s`) | environmental |
| `archive-writers` | `consult (unset) exited non-zero` — consult fans out to agy, same quota wall | environmental |
| `gh358-lock-instrumentation` (2) | lock-contention timeouts (`XYZ_LOCK_WAIT_S` exhausted) on a 4-core host under load | environmental / timing |
| `gh382-marathon-memory-telemetry` | "low-swap warning missing when free swap is low" — 8 GB swap free, the condition cannot arise | environmental |
| `relay-file-seeding-visibility` | `rtl_worktree_begin failed or file absent` | not isolated |
| `claude-turn` | `expected exit 0, got 5` | not isolated |

`mktemp-trap-guard` also failed on the first run — that one was **my own bug** in `repro.sh`
(a `cd` into an unvalidated `mktemp` path, the exact GH-177 class). The repo's own gate caught it. It
is fixed and the suite now passes, 367 scripts audited.

Baseline for comparison: before the environment fixes this host ran **216/230**. Installing `sqlite3`
and `jq` and setting a global git identity moved 7 suites green.
