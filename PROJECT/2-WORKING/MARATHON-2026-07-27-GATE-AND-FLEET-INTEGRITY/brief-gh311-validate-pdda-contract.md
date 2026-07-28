---
title: "Phase brief: GH-311 gh311-validate-pdda-contract (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-07-27
updated: 2026-07-27
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh311-validate-pdda-contract phase of
  MARATHON-2026-07-27-GATE-AND-FLEET-INTEGRITY — not itself an active-doc capture; the canonical
  capture doc is GH-311-VALIDATE-MISSES-REPO-PDDA-CONTRACT.md one level up.
roadmap_exempt: true
---

# Brief — GH-311: make `validate.sh` a superset of tier1's PDDA doc contract

## Status

| What was just completed | What's next |
|---|---|
| Contract authored and preflighted by the 2026-07-27 /10days sweep — `swarm-preflight --gh-issue` exit 0 (READY). Not yet fired. | Fire as marathon phase 1 of 4. |

**Parent doc:** `PROJECT/2-WORKING/GH-311-VALIDATE-MISSES-REPO-PDDA-CONTRACT.md`
**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/311
**Runs FIRST in this marathon — it repairs the gate every later phase advances on.**

## The gap (verified in source, not assumed)

- `validate.sh:101` registers only `pdda-roadmap-coverage.sh`.
- `test/pdda-roadmap-coverage.sh` builds **synthetic** fixture `PROJECT/` trees under `$WORK` and
  runs the checker against those. It verifies *the checker works*.
- `grep -n 'pdda.sh run' validate.sh` → **0 matches**.
- `.github/workflows/ci.yml:74` runs `utils/pdda/pdda.sh run` against the repo's **real**
  `PROJECT/` + `ROADMAP.md`. It verifies *the repo's docs comply*.

Passing the first says nothing about the second. PR #309 was locally green and hit **7 real
errors** in CI (missing `## Status` tables, working docs with no ROADMAP pointer).

## What to build

Add a thin named test — `test/pdda-repo-contract.sh` — that runs `utils/pdda/pdda.sh run` against
the repo's real content, and register it in `validate.sh`'s `TESTS` array.

Prefer the named wrapper over registering `pdda.sh run` directly so a failure attributes to a named
test in the suite output rather than a bare script invocation.

## Acceptance criteria

- `bash validate.sh` exercises the real-content PDDA contract, so tier1's deterministic doc errors
  are caught locally first.
- **Proven by deliberate violation**: introduce a doc-contract breach (e.g. strip a `## Status`
  table from a scratch doc), confirm `validate.sh` goes RED, then revert. Do not assume — the whole
  point of this issue is a gate that looked green while being blind.
- `test/pdda-roadmap-coverage.sh` is **retained unchanged** — it tests the checker, which is still
  worth testing. This is additive.
- The new test must not mutate the repo's real `PROJECT/` content when it runs.
- Advisory-vs-blocking semantics of PDDA findings are unchanged.

## Do not

- Touch `utils/pdda/pdda.sh` or any individual check.
- Touch `.github/workflows/ci.yml` — CI is already correct; the local gate is the gap.
- Promote currently-advisory findings into hard blockers.

## Gate

`bash validate.sh`
