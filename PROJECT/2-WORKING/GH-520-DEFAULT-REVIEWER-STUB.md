---
gh_issue: 520
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/520
title: "A marathon fixture that does not stub CODEX_BIN tests the reviewer-binary probe instead of the code under test"
status: 2-WORKING
created: 2026-08-14
updated: 2026-08-14
owner: unassigned
doc_type: capture
complexity: 1
risk: 2
effort: 1
ratings_provisional: true
goal: >
  Give every marathon fixture a default reviewer binary in the one file they all source, so a
  suite exercises its own subject rather than the reviewer probe, and stop a green local run
  from meaning something different than a green CI run.
---

## Status

| What was just completed | What's next |
|---|---|
| **BUILT 2026-08-14** on `fix/critical-2026-08-14`. `test/_setup.sh` exports a default `CODEX_BIN` stub, declared once and in the same place and idiom as the GH-402 `MARATHON_ALLOW_TRUNK_COMMIT` line. `test/gh520-default-reviewer-stub.sh` is **11/0** and registered. The control is **observed and reproduces the issue's evidence verbatim** — see below. | Operator review. The issue self-parked as "Parked. Not built." pending a scope decision between three cost-ordered options; this lane took **option 1 (default stub in `test/_setup.sh`)**, the cheapest, on the grounds that the issue's own finding is that a *comment* failed to prevent recurrence and only a default can. |

## Why

`marathon_drive.py`'s `_probe_agent_bin` runs before the guards, the preflight and the dispatch,
and `--reviewer codex` is the default in essentially every marathon fixture. Stubbing the
*builder* is the obvious half — it is the thing the test drives — so the reviewer stays invisible
until a machine without `codex` runs the suite. Then the run dies at the probe and the fixture's
assertions read the probe's message instead of the behaviour they were written for.

**Third recorded instance.** GH-232 wrote it into a `ci.yml` comment. On 2026-08-11/12 three more
suites — `gh402`, `gh514`, `gh388` — shipped green locally and were red on every ubuntu run for a
whole session. The comment did not prevent the recurrence, which is the actual finding.

**Worse than a flake:** a fail-fast can satisfy an *absence* assertion for the wrong reason.
`gh514` asserts on the absence of a Python traceback — which a run that dies at the probe also
produces. Those three happened to fail closed; nothing in the design guarantees the next will.

## Key concepts

- The default must not disable the GH-117 protection it resembles. A default stub is otherwise
  indistinguishable from deleting the probe, so the suite asserts in both directions: the default
  exists and is inherited, **and** an explicitly missing binary still fails fast.
- `${CODEX_BIN:-...}` so a fixture with its own reviewer behaviour still overrides inline, exactly
  as the shim suites already do.

## Acceptance

Authored by this lane — the tracking issue has no `## Acceptance` section, so there is no block to
copy verbatim. Derived from the issue's "Options, roughly in order of cost", item 1.

1. `test/_setup.sh` exports a default `CODEX_BIN` pointing at an executable no-op stub. **[met]**
2. An explicitly set `CODEX_BIN` still wins. **[met]**
3. A fixture that sources `_setup.sh` inherits a usable stub. **[met]**
4. The GH-117 probe still fails fast on a genuinely missing binary — the protection is intact and
   still has a suite proving it fires. **[met]**
5. The control is observed, not asserted. **[met — see below]**

## Acceptance — deviations from the issue

- [changed] The issue offers three cost-ordered options and settles on none -> this lane implements
  **option 1 only** — reason: the issue's own evidence is that a written warning failed three
  times, which argues for the cheapest *mechanical* default rather than a larger design; options 2
  and 3 remain available and are not foreclosed by this.

## The control, and why it was hard to get

Recorded in full at `test/baselines/GH-520-default-stub-control.md`. The short version, because it
is the interesting part: the obvious control **does not fire**. All three suites GH-520 names were
individually stubbed by `6ae068b8`, so with `codex` stripped from PATH they pass with or without
the new default. A default that protects *future* fixtures cannot be observed on today's suites.

The control that works removes `gh402`'s **own** stub so it depends on the shared default:

- default present, `codex` absent -> `gh402-branch-enforcement: 13 passed, 0 failed`
- default also removed -> `FAIL: GH-402: the refusal does not name the branch — got:
  marathon-drive: reviewer binary 'codex' not found on PATH`

That failure is character-for-character the one the issue records from CI.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [
    { "type": "grep_absent", "path": "test/_setup.sh", "pattern": "export CODEX_BIN=" }
  ],
  "artifacts":   [ "test/", "validate.sh" ],
  "remediation": { "source": "issue#520", "criteria": "Default CODEX_BIN in test/_setup.sh so fixtures test their subject, not the reviewer probe" },
  "lanes":       { "agy_safe": [ "test/" ], "orchestrator_only": [ "validate.sh" ] }
}
```

Contract auto-drafted by the 2026-08-14 fix-now pass — artifacts/lanes not yet operator-verified.
