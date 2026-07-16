---
title: "Phase brief: GH-209 marathon-root leak audit (marathon builder input, not a capture doc)"
status: consumed 2026-07-16 (phase built and Approved — see PROJECT/2-WORKING/GH-209-MARATHON-ROOT-LEAK-AUDIT.md)
created: 2026-07-16
updated: 2026-07-16
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh209 phase — not itself
  an active-doc capture; the canonical capture doc is GH-209-MARATHON-ROOT-LEAK-AUDIT.md one level up.
roadmap_exempt: true
---

## Status

| What was just completed | What's next |
|---|---|
| Phase built and Approved 2026-07-16 (see the canonical capture doc's own Status table). | None — this brief's job (feeding the marathon builder turn) is done. |

## Phase: GH-209 — static audit that every test/marathon*.sh invocation scopes MARATHON_ROOT

Full context: [GH-209-MARATHON-ROOT-LEAK-AUDIT.md](../GH-209-MARATHON-ROOT-LEAK-AUDIT.md).
GitHub issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/209

### Important scope boundary — read this first

The GitHub issue asks for two things. You are building ONLY the second, mechanical one. Do **not**
attempt the first:

1. ~~Make `marathon.sh`'s PWD-based `MARATHON_ROOT` fallback refuse to resolve to "the wrong
   repo"~~ — **OUT OF SCOPE.** This conflicts with GH-206's own explicit goal (a vendored install
   must resolve `ROOT` from `$PWD` with ZERO required env vars), and there is no reliable code-level
   signal today that distinguishes a legitimate bare run from a stray background invocation. Do not
   edit `relay-automation/marathon.sh` or `relay-automation/marathon-drive.sh` for this phase.
2. **IN SCOPE:** add a static audit (a new test/check) proving every invocation of the real
   `marathon.sh`/`marathon-drive.sh` inside this repo's own test suite (`test/marathon.sh`,
   `test/marathon-drive.sh`) either sets `MARATHON_ROOT` explicitly, or runs with its CWD inside an
   isolated fixture directory (never the real repo checkout with an unset/ambient root) — and that
   this stays true going forward (a future test edit that reintroduces the gap must fail the check
   loudly, not silently).

### What to build

A new test case (either a new small test file, e.g. `test/marathon-root-audit.sh`, or a new case
appended to `test/marathon.sh` — your call, whichever fits the existing test-file conventions in this
repo better) that:

1. Greps `test/marathon.sh` and `test/marathon-drive.sh` for every line that invokes
   `relay-automation/marathon.sh` or `relay-automation/marathon-drive.sh` directly (e.g. `bash
   "$MSH"`, `bash "$DRIVER"`, `./.xyz/relay-automation/marathon.sh`-style calls) — NOT the stubbed
   `MARATHON_DRIVE`/`STUB` plumbing those tests use to avoid invoking the real driver.
2. For each such invocation, confirms its surrounding shell context sets `MARATHON_ROOT` explicitly
   (grep the same line or the enclosing function/block for `MARATHON_ROOT=`), OR confirms the
   invocation's CWD is inside an isolated fixture dir created by `_setup.sh` (the `$A`/`$B`/`$V`-style
   variables this repo's test harness already uses — never the real repo root).
3. Fails loudly, naming the offending file:line, if any invocation has neither signal.

You will find that, as of today, every existing invocation in both files already satisfies this
(verified before this brief was written) — this phase is about making that a CHECKED, enforced
invariant, not about fixing a currently-broken test. If your audit finds a genuine gap, fix that one
specific invocation to set `MARATHON_ROOT` explicitly rather than expanding scope elsewhere.

### Acceptance / done means

- The new audit test exists, runs, and passes against the current (already-compliant) test suite.
- `bash test/marathon.sh` and `bash test/marathon-drive.sh` still both green (unchanged behavior).
- Full `validate.sh` green (or unchanged from before your change — the pre-existing `#208`
  environment red is expected and not yours to fix).
- Do NOT touch `relay-automation/marathon.sh` or `relay-automation/marathon-drive.sh` at all.
