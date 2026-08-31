# Sleep-vs-readiness audit — the whole tree, mutation-proved

**Date:** 2026-08-31 · **Tree:** `development` @ `7c4a44d2` · **Motivation:** #123 / #344
(StarSling's paid "Test Reliability" optimization replaces hardcoded `sleep` with readiness
checks; #344 concluded that is the one paid feature directly relevant to us. This audit does it
by hand, free, and answers whether the feature would buy us anything.)

**Box:** idle 10-core Apple-silicon Mac. Every margin below is measured on that box, which is
faster than `starsling-ubuntu-24.04-8` under load. **Treat every margin as an upper bound.**

---

## Verdict

**One confirmed defect, five sleeps that are load-bearing-but-correct, and a large clean
majority.** 160 `sleep` occurrences in executable files across 54 files. After removing
documentation, usage strings and fixtures-that-must-be-slow, **19 were candidate
sleep-as-synchronization sites**. Mutation testing settled every one.

The single defect worth fixing is [test/agent-chorus.sh:611](test/agent-chorus.sh#L611), and it is
worth fixing because **the same file already contains the correct pattern twice**.

StarSling's paid Test Reliability feature would have found at most this one site, and the fix is
four lines. **Do not buy the tier for it.**

---

## Method — mutation, not inspection

Reading a `sleep` cannot tell you whether it is synchronizing something. Setting it to `0` can.

For each candidate: rewrite that one line's sleep literal, run the suite, record the pass/fail
delta, `git checkout --` the file. The harness is ten lines of shell: read
`file|line|new_sleep_value|suite` records on stdin, rewrite the one line with
`sed -E 's/sleep ([0-9.]+)/sleep $newval/'`, run the suite, restore, print the exit code. Suites
must be run with the Bash sandbox disabled (the GH-177 guard refuses otherwise).

- **`sleep 0` still green** ⇒ the sleep is not the synchronization mechanism. Something else
  orders the events; the sleep is decoration and cannot flake.
- **`sleep 0` goes red** ⇒ the sleep *is* the mechanism. Its margin is the only thing standing
  between the suite and a red canary. Then binary-search the real requirement to size the margin.

A prior load experiment (40 spinners on 10 cores, 4x oversubscription, 3 repeats of the three
densest suites) produced **9/9 green** at ~2.2x wall-clock. That is a real negative result and it
is why this audit uses mutation instead: 2.2x contention does not reach these margins, so a load
test would have reported "no problem" and been wrong.

---

## Finding 1 — BLOCKING for the Linux canary

### `test/agent-chorus.sh:611` — `sleep 0.3` is the only thing making the doorbell-liveness assertion pass

```
609| a2a watch --agent 2 --interval 0.05 --timeout 1 >/dev/null 2>&1 &
610| G38_WATCH_PID=$!
611| sleep 0.3
612| [ -f "$(dirname "$G38_FILE")/runtime/agent2.watch" ] && pass "watch records its liveness ..."
613|   || fail "no watch sidecar written"
```

The assertion needs a backgrounded `python3` to start, parse args, open the discussion, and stamp
`runtime/agent2.watch` — all inside 0.3 s.

**Measured margin, idle 10-core Mac:**

| `sleep` | result |
|---|---|
| `0` | **red** — 181 pass, 1 fail |
| `0.05` | **red** |
| `0.1` | **red** |
| `0.15` | **red** |
| `0.2` | **red** — 181 pass, 1 fail |
| `0.3` (shipped) | green — 182 pass, 0 fail |

The requirement sits between 0.2 s and 0.3 s **on an idle machine with nothing else running**.
That is **under 1.5x headroom**. `agent_chorus.py --help` alone costs 0.06 s here; on a shared
8-core Linux runner executing 190 suites the same startup is routinely 3–5x that. This assertion
is one scheduling hiccup from red, and it is exactly the shape of failure #123 was opened for.

It also has a second, narrower race: the watch is launched with `--timeout 1`, so if startup ever
exceeded 1 s the process would be *gone* by the time line 612 looks for its marker. The window is
bounded on both sides.

**The fix is already written elsewhere in this same file.** Line 235 does it correctly and says so:

```
235| # Wait for the holder to actually own the flock before contending (no fixed sleep).
238|   sleep 0.1
```

and again at line 497:

```
497| for _ in $(seq 1 100); do grep -q "held-since=live" "$G38_LOCK" 2>/dev/null && break; sleep 0.1; done
```

So the repo knows the idiom, applies it deliberately, comments on why — and then two hundred lines
later reaches for a bare sleep. Replace 611 with:

```bash
SIDE="$(dirname "$G38_FILE")/runtime/agent2.watch"
for _ in $(seq 1 100); do [ -f "$SIDE" ] && break; sleep 0.02; done
```

This is strictly better than the current line on both axes: it returns in ~0.06 s when the box is
fast (the suite gets quicker) and tolerates 2 s when the box is slow.

**Caveat, stated because it matters:** the neighbouring assertion at 635 (`sleep 2.5`, verifying
the marker *refreshes*) is a genuine measurement window and must stay a sleep — you cannot poll
for "still fresh after a long wait." Mutation confirms it is not fragile: it survives being cut to
`0.5`. Do not "fix" it.

---

## Finding 2 — five load-bearing sleeps that are correct as written

These go red at `sleep 0`, so they are load-bearing. None is a readiness check in disguise, and
**none should be converted to one.**

| Site | Sleep | Why it is not a readiness bug |
|---|---|---|
| [test/gh239-hq-status-releases-mode.sh:31](test/gh239-hq-status-releases-mode.sh#L31) | `1` | Forces `ROADMAP-DASHBOARD.md` mtime strictly newer than `releases.db`. Filesystem clock granularity — a poll cannot make the second tick. |
| [test/gh388-run-log-durability.sh:234](test/gh388-run-log-durability.sh#L234) | `1.5` | Same class; documented in-line at 230–233 (bash 3.2 `-nt` compares whole seconds). |
| [test/marathon-monitor.sh:143](test/marathon-monitor.sh#L143) | `1` | Same class; documented in-line. |
| [test/relay-loop.sh:71](test/relay-loop.sh#L71) | `2` | Inside a *runner stub*. The 2 s is the fixture's whole purpose — it proves dispatch returns before the runner finishes. |
| [test/gh123-lock-progress-bound.sh:58](test/gh123-lock-progress-bound.sh#L58) | `1` | Drives six ~1 s lock handovers against a 2 s per-holder bound. The duration *is* the test. |

The three mtime sites cost ~3.5 s of gate wall-clock between them and could use explicit
timestamps (`touch -t`) instead. That is tidying, not reliability. **Optional, low value.**

`gh123-lock-progress-bound.sh:58` deserves one line of honesty: it is wall-clock-ratio-dependent
by construction (6 s of handover vs a 2 s bound), which is the same family as the CPU-starvation
failure #123 exists to fix. It has 3x margin, better than Finding 1, and driving the handovers by
signal file instead of clock would remove the dependency entirely. Parked, not urgent.

---

## Finding 3 — eight candidate sites that are NOT synchronizing anything

Each stayed green with `sleep 0`. They cannot flake on a slow runner because they are not what
orders the events.

| Site | Sleep | Suite result at `sleep 0` |
|---|---|---|
| [test/agent-chorus.sh:255](test/agent-chorus.sh#L255) | `0.1` | green |
| [test/agent-chorus.sh:374](test/agent-chorus.sh#L374) | `0.1` | green |
| [test/agent-chorus.sh:635](test/agent-chorus.sh#L635) | `2.5`→`0.5` | green |
| [test/gh233-agent-chorus-concurrency.sh:69](test/gh233-agent-chorus-concurrency.sh#L69) | `0.5` | green |
| [test/gh233-agent-chorus-concurrency.sh:93](test/gh233-agent-chorus-concurrency.sh#L93) | `0.5` | green |
| [test/gh32-releases-app.sh:244](test/gh32-releases-app.sh#L244) | `1` | green |
| [test/worktree-isolation.sh:69](test/worktree-isolation.sh#L69) | `2` | green |
| [test/worktree-isolation.sh:115](test/worktree-isolation.sh#L115) | `2` | green |

**Two of these are worth a second look for a different reason — not flakiness, assertion strength:**

- `agent-chorus.sh:374` asserts "a second drive for the same participant is refused (exit 2)". With
  the wait removed the first drive cannot reliably hold the lock yet, and the assertion **still
  passes** — so the refusal is probably not coming from lock contention at all. Either the
  assertion is proving something weaker than its message claims, or the sleep is redundant. Worth
  30 minutes; not a reliability defect.
- `gh32-releases-app.sh:244` asserts a write under a held `flock` is refused with exit 4, having
  backgrounded the holder 1 s earlier. Green at `sleep 0` most likely means Python wins the race
  anyway at 0.02 s startup — but the same reasoning as above applies, and on a slow runner this is
  the site most likely to invert. It is the one entry in this table that should be *converted to a
  readiness poll defensively* even though mutation did not convict it, because the correct pattern
  is three lines and the failure mode is a confusing red on a shared runner.

Everything else in this table can be left alone or have its sleep deleted for speed.

---

## What this says about #344 and the paid tier

`.github/workflows/ci.yml` contains **zero** `sleep` calls — the CI configuration itself has
nothing for a workflow-level optimizer to fix. Every finding above is inside the shell test
suites, which is not where a `ci.yml` optimizer looks.

GH-528's spike already falsified the sleep hypothesis for *wall-clock*: "the top-10 wall-clock
owners contain essentially zero executed sleep." This audit is the *reliability* counterpart and
lands in the same place: **one real site, four lines to fix.**

The recommendation from #344 stands and is now evidenced: run the free vendored tooling, fix
Finding 1 by hand, and do not buy the optimization tier for a feature whose entire yield here is
one line of a test file.

---

## Coverage and limits

- **Swept:** every `sleep` / `time.sleep` in `*.sh`, `*.py`, `*.yml`, `*.yaml`, excluding
  `CHANGELOG.md` and `docs/`. 160 occurrences, 54 files.
- **Mutation-tested:** 19 sites across 11 suites. Every candidate that could plausibly be
  synchronizing an event.
- **Not mutation-tested:** sleeps inside `relay-automation/` watchdogs (`consult.sh:164`,
  `relay-turn-lib.sh:541`) and poll loops (`runner.sh:123`, `marathon-drive.sh:277`,
  `relay-loop.sh:237`). These are production pacing/timeout mechanisms, not test synchronization,
  and mutating them tests the watchdog rather than the flake. Out of scope by design, named here
  so the gap is visible.
- **Not covered:** Windows. Not a target yet.
- **Honest limit:** every margin is from an idle Apple-silicon box. The hosted Ubuntu canary is
  the only place these numbers can be confirmed, and the canary is advisory
  (`continue-on-error: true`, [ci.yml:236](.github/workflows/ci.yml#L236)). Finding 1's fix is
  worth landing without waiting for that confirmation — it makes the suite faster *and* more
  robust, so there is no version of the canary result that argues against it.
