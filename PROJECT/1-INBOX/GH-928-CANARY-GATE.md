---
gh_issue: 928
source: https://github.com/HiQS-Labs/XYZ-forge/issues/928
title: "Canary gate: a clean-room, sub-minute top-level smoke tier for the core XYZ surfaces"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-02
updated: 2026-10-02
owner: noel
goal: A first rung before the gate that proves tick, relay, consult, marathon, and jog still start, parse, and coordinate — in seconds, offline, in both runtimes.
doc_type: feedback
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: false
non_goals:
  - Not a replacement for ./validate.sh (the gate), the tiered selection, or ci-local.sh (the qualifying run)
  - Not arming hosted Actions on push — the workflow ships workflow_dispatch-only until the tier is accepted
  - Not a parity suite — the twins are smoke-tested side by side, not diffed
related:
  - canary.sh
  - canary/README.md
  - canary/fixtures/MARATHON.canary.yaml
  - .github/workflows/canary.yml
  - bin/tick
  - relay-automation/relay-drive.sh
  - relay-automation/consult.sh
  - relay-automation/marathon.sh
  - utils/py/jog_run.py
  - skills/1-hourly/relay-xyz/find-harness.sh
roadmap_exempt: false
---

# GH-928 · Canary gate — a clean-room, sub-minute top-level smoke tier

**Why:** the gate is the full suite (minutes, tiered). Nothing cheaper answers the question every
push should answer first: *do the core XYZ surfaces still start, parse, and coordinate?* A broken
shim header, a Python port that no longer imports, or a tick kernel that cannot hand off a token
should be caught in seconds, before the gate is paid for.

**Clean-room constraint:** written from the core entry points only (tick, relay-drive/poll, the
relay-xyz locator, consult, marathon, jog), deliberately without reading the existing CI, so it
reflects what the surfaces actually do rather than what the gate already assumes.

## Asks / acceptance

1. `./canary.sh` exercises, offline and model-free, in BOTH runtimes (Python default + `XYZ_PYTHON=0`):
   static floor (`bash -n`, `node --check`, `py_compile` + import of every `utils/py` module), the
   tick lifecycle in a throwaway repo (claim → contended claim loses → release `--to` → take → done
   → project → analyze), the relay-block validator's refusals, `relay-drive`/`poll`/`consult`/
   `marathon-drive` `--help`, the relay-xyz locator, `marathon-yaml`, `marathon.sh --dry-run` on a
   canary-owned one-phase plan, and jog's `--help` plus `--dry-run` against a sandbox copy of the
   committed releases ledger. -> expect **21 checks, ~2.5 s** on a 4-core host; exit 0 on a clean tree.
2. It never writes inside the repo tree. -> expect the closing `tree-clean` check to diff `git status`
   before/after and fail on any delta; the jog check additionally asserts its sandbox ledger is unchanged.
3. A deliberate break fails it. -> verified 2026-10-02: renaming the `claim` import in `bin/tick`
   fails `tick-lifecycle`; breaking an import in `utils/py/jog_run.py` fails `python-ports`,
   `jog-help`, and `jog-dry-run`; restoring returns 21/21.
4. Hosted CI stays dormant: `.github/workflows/canary.yml` is `workflow_dispatch`-only; arming it is
   adding `push:`/`pull_request:` triggers, nothing in `canary.sh` changes.

## Open items

- Decide whether `canary.sh` becomes the pre-push hook's first stage (fail fast before the tiered
  gate). Easy to reverse; not done here to keep the change additive.
- Decide whether to arm the workflow on push/PR once the tier has been seen green for a while.
