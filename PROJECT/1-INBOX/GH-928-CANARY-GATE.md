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
2. It never writes inside the repo tree. -> expect the closing `tree-clean` check to diff the
   working tree AND the clone's `.git` state (full local git config + `HEAD`) before/after and
   fail on any delta; the jog check additionally asserts its sandbox ledger is unchanged.
3. A deliberate break fails it. -> verified 2026-10-02: renaming the `claim` import in `bin/tick`
   fails `tick-lifecycle`; breaking an import in `utils/py/jog_run.py` fails `python-ports`,
   `jog-help`, and `jog-dry-run`; restoring returns 21/21.
4. Hosted CI stays dormant: `.github/workflows/canary.yml` is `workflow_dispatch`-only; arming it is
   adding `push:`/`pull_request:` triggers, nothing in `canary.sh` changes.

## Open items

- Decide whether `canary.sh` becomes the pre-push hook's first stage (fail fast before the tiered
  gate). Easy to reverse; not done here to keep the change additive.
- Decide whether to arm the workflow on push/PR once the tier has been seen green for a while.

## Review round 1 (2026-10-02) — findings and fixes

The PR review (HiQS-Labs/XYZ-forge#930) found two must-fix items; both are fixed in this branch.

- **[P1] Teardown `rm -rf` ran on an unproven caller-supplied path.** `XYZ_CANARY_SANDBOX` was
  validated only at derivation, then deleted unconditionally — `XYZ_CANARY_SANDBOX=~ ./canary.sh`
  would have removed the home directory. Fixed with `sandbox_resolve` / `sandbox_deletable`
  (GH-567 use-boundary discipline): every dangerous use re-proves the sandbox, setup refuses `/`
  and the resolved home, the teardown removes only a directory carrying this run's `logs/` marker
  (otherwise the sandbox is kept, never deleted), and each check's `cd` fails closed (`cd ""` is
  a silent no-op — the exact GH-567 trap).
- **[P2] Containment was `git status`-only, and the "never writes in-tree" claim was technically
  false.** `git status` cannot see `.git/config`, refs, or hooks — the GH-564 contamination class.
  `tree-clean` now also diffs the clone's full local git config plus `HEAD`; the first draft of
  that fingerprint keyed on four config telltales and **failed its own red control** (an unrelated
  local config write did not fire it) — it was hardened to the full config list and re-witnessed
  against both an unrelated write and a remote repoint before commit. `python-ports` compiles a
  sandbox copy and imports with `PYTHONDONTWRITEBYTECODE=1`, so the claim is literally true.
  Evidence for the fixes: `TESTS-RESULTS/2026-10-02+GH-928/`.

Non-blocking, deferred: a canary-coverage drift assertion (a new Tier-A entry point would get
static-floor coverage but no smoke coverage, silently — the GH-379 inline-runner lesson in
miniature); a comment documenting the PATH-stub limitation shipped with this round.

## Lessons for GH-884 (clean-room CI rebuild contingency)

Recorded as evidence only — this claims no trigger and proposes no work (GH-884's header stands).
PR #930 was a live miniature of GH-884's clean-room method, and three observations transfer:

1. **The clean room re-derived the surfaces but re-made the repo's known containment mistakes.**
   All 21 smoke checks passed on first run — no new surface defects — while every real finding was
   a containment/evidence failure in the NEW machinery itself (unproven `rm -rf`; git-status-only
   containment; missing provenance). Those lessons live in AGENTS.md's incident rails, not in the
   CI the clean room deliberately avoided reading. A rebuild's clean room must therefore carry
   GH-884's "keep these primitives" list (runner-envelope, fixture-guard, the containment suite
   family) in as constraints from day one, not as things to re-earn later.
2. **The canary is seed material for R1's shadow lane.** Its scope — tick, the relay-automation
   shims, marathon, jog; sub-minute; offline; both runtimes — is a smoke-tier preview of the
   critical-core list. If a trigger ever fires, the first shadow artifact already exists.
3. **The landing pattern is a working precedent for shadow mode under the #831 freeze.** Own
   issue-first authorization, NOT in the `validate.sh` TESTS registry, `workflow_dispatch`-only
   dormant workflow, arming explicitly deferred to a separate decision. That is the shape any new
   shadow lane would need to take to coexist with the freeze.
