---
gh_issue: 110
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/110
title: "Fable 5 Max audit: shellcheck + vendor integrity + strict-mode hardening"
status: Active (2-WORKING) — P1 + P2a shipped (`073857a`); P3b (strict-mode policy) shipped 2026-07-06; P2b partial (oracle-guard skip-guard landed; roadmap-dashboard skip-guard + run-tests.sh remain — re-scoped as this doc's fireable contract 2026-07-17); P3a RE-SCOPED → tracked as #154 (excluded from the 2026-07-17 /10days sweep — claimed by a concurrently-running marathon)
created: 2026-07-03
updated: 2026-07-17
owner: noel
doc_type: bug-fix-and-hardening
complexity: 3
risk: 2
effort: 3
phases: 3
ratings_provisional: false
non_goals:
  - Not rebuilding the test runner or changing the 85-test suite structure
  - Not touching the tick kernel, relay-turn-lib, or projection logic (all rated clean)
  - Not adding CI runners — that is GH-61's scope
related:
  - test/xyz-vendor.sh
  - skills/relay-automation/relay-pkg.tar.gz
  - utils/marathon-plan.sh
  - checkjs.sh
  - PROJECT/1-INBOX/GH-61-CI-GITHUB-ACTIONS.md
  - ROADMAP.md (GH-104 note: install.sh/relay-pkg.tar.gz stale — Phase 2 here closes it)
goal: >
  Land the five concrete defects from the Fable 5 Max audit (broken test assertion, stale
  safety-critical vendor tarball, vendored-copy self-test failures, an uncheckable JS heredoc, and
  an undocumented strict-mode convention) as small, independently-shippable hardening slices — with
  no behavior change to the tick kernel, relay-turn-lib, or projection logic.
roadmap_exempt: false
---

# GH-110 · Fable 5 Max audit — shellcheck + vendor integrity + strict-mode hardening

**Why:** Fable 5 Max ran a full shellcheck pass (63 findings across 146 scripts), executed all 85
tests in a clean Linux container, and diffed the vendor tarball against live sources. Verdict:
overall quality high (77/85 pass hermetically, no findings on the core kernel). Five concrete
defects identified — one broken test assertion, a stale safety-critical tarball, vendor self-test
failures, an uncheckable 788-line JS heredoc, and an undocumented strict-mode convention.

**Note on GH-104 overlap:** The ROADMAP GH-104 entry explicitly flags `install.sh`/`relay-pkg.tar.gz`
as "remaining follow-up." Phase 2 of this doc closes that gap.

## Status

| What was just completed | What's next |
|---|---|
| GH-110 captured 2026-07-03; all 5 findings evaluated as valid. | Phase 1 quick fixes (broken assertion + cosmetic vendor payload issues). |

## Table of contents

- [Phase 1 — Quick fixes](#phase-1--quick-fixes-~1-hr)
- [Phase 2 — Vendor integrity](#phase-2--vendor-integrity-~2-3-hrs)
- [Phase 3 — Code quality hardening](#phase-3--code-quality-hardening-~1-day)

---

## Phase 1 — Quick fixes (~1 hr)

Three cosmetic/trivial issues from Fable's items 1 and 3 that can land as a single commit.

### Checklist

- [ ] **Fix broken assertion in `test/xyz-vendor.sh:140`** — `[ "$(cat ...)"= "app-util" ]` is
      missing the space before `=`, so the comparison always errors into the fail branch even when
      content is correct. The resulting SC1073 parse error also blocks shellcheck from checking the
      rest of the file. One-char fix.
- [ ] **Remove `.DS_Store` from the vendor payload** — `utils/.DS_Store` is currently materialized
      into the vendored copy via `materialize_vendor`. Add an exclusion in the relevant copy step
      (e.g., `rsync --exclude='.DS_Store'` or equivalent `find -not -name`).
- [ ] **Delete or fill `skills/swe/SKILL.md`** — currently 0 bytes; either populate with a stub
      directive or remove the file so it does not mislead consumers of the skill.

### QA gate — Phase 1

- [ ] `./validate.sh` stays green (all tests pass, none newly broken).
- [ ] `utils/pdda/pdda.sh run` reports 0 errors.
- [ ] `shellcheck test/xyz-vendor.sh` produces no SC1073 parse error.
- [ ] A fresh `materialize_vendor` run into a temp dir contains no `.DS_Store` files.

---

## Phase 2 — Vendor integrity (~2–3 hrs)

Addresses the two inter-related vendor issues from Fable's items 2 and 3: the stale tarball
(safety core ships outdated `relay-turn-lib.sh`) and the 8 vendored-copy test failures caused by
tests that assume repo-root files that don't travel.

### Checklist

#### 2a — Stale `skills/relay-automation/relay-pkg.tar.gz`

The tarball's `relay-turn-lib.sh` (39,052 bytes) and `relay-drive.sh` (21,206) differ from live
sources (39,892 / 24,286). Anyone installing via the skill gets an outdated containment boundary.

Choose one of two approaches (operator decision):

- [ ] **Option A (preferred — remove binary):** Stop committing the tarball. Have `install.sh`
      build it on demand from live sources (`make-pkg.sh && install`). Add a `--dry-run` check in
      `install.sh` that verifies the build is possible before proceeding.
- [ ] **Option B (keep binary + freshness gate):** Add a test to `validate.sh` that extracts the
      tarball into a temp dir and `cmp`s `relay-turn-lib.sh` and `relay-drive.sh` against live
      sources — fails if they drift. This is the pattern Fable explicitly recommended.

#### 2b — Vendored-copy test failures (8/85 tests)

These tests assume repo-root files that don't travel with the vendor payload:
`validate.sh`, `.github/workflows/ci.yml`, `ROADMAP-DASHBOARD.md`, and the `oracle-guard` symlink
test that dangles without `validate.sh`. Three others require >60s budgets.

- [ ] Add `skip()` guards (using the guard pattern already in `test/ci-workflow.sh`) to each
      root-dependent test — skip when the required file is absent, not error. **Partial:** the
      root-dependent tests are `test/oracle-guard.sh` (validate.sh symlink target), `test/roadmap-dashboard.sh`
      (ROADMAP-DASHBOARD.md), and `test/ci-workflow.sh` (.github/workflows/ci.yml — already guarded).
      roadmap-dashboard still needs a guard.
- [ ] Add a lightweight `run-tests.sh` entry point to the vendor payload so consumers have a clear
      "how to self-verify" path without discovering the suite manually. **(remaining)**
- [x] Confirm the `oracle-guard` symlink test either resolves gracefully without `validate.sh` or
      gets its own skip guard. → **done 2026-07-06**: `test/oracle-guard.sh` now `skip()`s the
      symlink-to-oracle sub-test when `$ROOT/validate.sh` is absent. Verified both ways (present →
      11 pass/0 skip; validate.sh hidden → 10 pass/1 skip/0 fail; previously a dangling fail).

### QA gate — Phase 2

- [ ] `./validate.sh` green (all tests pass).
- [ ] A fresh vendor install (into a clean temp dir, simulating a foreign repo) runs `run-tests.sh`
      and passes ≥77/85 tests (the pre-fix baseline) with 0 unexpected errors (only expected skips).
- [ ] If Option B chosen: `validate.sh` freshness gate catches a hand-corrupted `relay-pkg.tar.gz`
      and fails with a clear message.
- [ ] No `.DS_Store` or 0-byte stubs in the fresh vendor install.

---

## Phase 3 — Code quality hardening (~1 day)

Two structural improvements from Fable's items 4 and 5. Each is a zero-behavior-change hardening
move; either can land independently.

### Checklist

#### 3a — Extract marathon-plan's JS heredoc — ⚠️ RE-SCOPED (port drift) → DEFERRED

**Blocked by a finding discovered 2026-07-06 while scoping this task.** The premise ("extract the
heredoc into a fresh `src/marathon-plan.js`") is no longer correct, because the extraction *already
partly exists* — and the two copies have **diverged**:

- The shell heredoc in `utils/marathon-plan.sh` (`node - <<'NODE'`, ~940 lines) is the **current**
  logic: it carries GH-48's **configurable zone model** (`QP_ZONES_CONFIG`, `compileZoneConfig`,
  `EXPLICIT_ZONES_CONFIG`).
- `utils/py/_marathon_plan_node.js` (778 lines), which the `XYZ_PYTHON=1` port
  (`utils/py/marathon_plan.py`) invokes via `node _marathon_plan_node.js`, is a **stale pre-GH-48
  copy**: it still hardcodes `const KERNEL_PATHS = [...]` and has **no** zone-config support (`grep`
  count: shell 8 / extracted 0). GH-48 is CLOSED, so the Python port silently runs superseded zone
  logic.

Blindly extracting the shell heredoc into a *new* `src/marathon-plan.js` would create a **third**
copy of an 800-line program alongside a divergent twin — the opposite of the DRY intent. The correct
move is a **reconciliation**: promote the current (940-line) logic to one canonical JS module, point
**both** the shell wrapper and the Python port at it, delete the stale `_marathon_plan_node.js`, and
add a `test/marathon-plan.sh` parity assertion that the two entry points produce identical output.

That is a larger, higher-blast-radius change than GH-110's original P3a (it touches the Python port
and its test seams) and deserves its **own issue** — filed as
**[#154](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/154)**. Not
doing a partial/blind extraction under GH-110.

- [ ] *(tracked in [#154](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/154))*
      Reconcile the divergence into one canonical JS module used by both the shell wrapper and the
      Python port; delete the stale extracted copy; add a parity test.

#### 3b — Declare a strict-mode policy

36/146 scripts set `set -e*`; the three largest scripts (`utils/pdda/`, `marathon-plan.sh`,
`swarm-preflight.sh`) run without it, while all relay-automation drivers have `set -euo pipefail`.
Some exemptions are deliberate (hooks shouldn't hard-fail) but none are documented.

- [x] Decide the policy: either (a) default-strict with explicit per-script `# strict-mode: exempt
      — <reason>` header, or (b) strict-mode is per-subsystem (relay-automation strict,
      utils/ exempt by default with rationale). Document the decision in one place
      (e.g., `GUIDING-PRINCIPLES.md` or a `decisions/` record). → **Chose (b)**, documented in
      `GUIDING-PRINCIPLES.md` under **Conventions → Strict-mode policy** (relay-automation drivers
      `set -euo pipefail`; utils/ analysis tools `set -uo pipefail`/`set -u` deliberately without `-e`).
- [x] Add a header comment to each currently-exempt script that either states the exemption reason
      or adds `set -euo pipefail` if it was just never set. → Added a one-line `# strict-mode: -e
      exempt — …` header to all 9 exempt scripts (`utils/pdda/*.sh` ×7, `utils/marathon-plan.sh`,
      `utils/swarm-preflight.sh`). All 9 pass `bash -n`.
- [ ] Optional enforcement: add a `pdda.sh strict-mode` check (or extend `pdda.sh frontmatter`) to
      flag scripts with neither `set -e*` nor an explicit exemption comment. **(optional — deferred)**

### QA gate — Phase 3

- [ ] `./validate.sh` green after each sub-task (3a and 3b independently).
- [ ] `node --check src/marathon-plan.js` passes (3a).
- [ ] `checkjs.sh` run against `src/` includes `marathon-plan.js` in its check scope (3a).
- [ ] Every script in `utils/pdda/`, `marathon-plan.sh`, `swarm-preflight.sh` either has
      `set -euo pipefail` or a one-line exemption comment explaining why (3b).
- [ ] No regression in `test/marathon-plan.sh` (functional parity after heredoc extraction) (3a).

---

## Passing notes (not actionable — logged for awareness)

- **Exit-code 5 collision:** exit code `5` means "gemini failed" in one shim and "review-once
  success" in `relay-drive`. Each is documented at its declaration and callers map correctly; not
  a current bug, but a future-consumer hazard. No action taken — logged here.
- **`skills/xyz/SKILL.md` at 84KB:** large context load for a skill. Fable suggests progressive
  disclosure / split into reference files. Deferred; no issue opened yet.

## Swarm Preflight Contract

> **Re-scoped 2026-07-17 by `/10days`** (11-14 day sweep): Phase 2a already shipped (`073857a`,
> confirmed live — `test/relay-pkg-freshness.sh` exists and passes) and Phase 3a was split to its
> own issue (#154, itself excluded from this sweep as claimed by a concurrently-running marathon).
> The old contract above was scoped to 2a and is now stale/satisfied — it would never fire again.
> Re-scoped to the two genuinely-unshipped **Phase 2b** items: a `skip()` guard for
> `test/roadmap-dashboard.sh` (mirroring the pattern already landed in `test/oracle-guard.sh` and
> `test/ci-workflow.sh` — `skip(){ echo "  SKIP: $*"; SKIP=$((SKIP+1)); }`, confirmed absent from
> `test/roadmap-dashboard.sh` today) and a new top-level `run-tests.sh` entry point (confirmed
> absent anywhere in the repo today).

```json
{"target":{"repo":".","ref":"main"},"gate":"bash validate.sh","fix_probes":[{"type":"grep_absent","path":"test/roadmap-dashboard.sh","pattern":"skip\\(\\)"},{"type":"path_absent","path":"run-tests.sh"}],"artifacts":["test/roadmap-dashboard.sh","run-tests.sh"],"artifacts_new":["run-tests.sh"],"remediation":{"source":"issue#110","criteria":"test/roadmap-dashboard.sh skip()s its ROADMAP-DASHBOARD.md-dependent case when that file is absent, matching the skip() pattern already landed in test/oracle-guard.sh and test/ci-workflow.sh; a new top-level run-tests.sh entry point runs the full suite for a vendored install (no root-file assumptions); a fresh vendor install passes >=77/85 with only expected skips; validate.sh stays green."},"lanes":{"agy_safe":["test/roadmap-dashboard.sh","run-tests.sh"],"orchestrator_only":[]}}
```

*Contract auto-drafted by /10days from the issue text and the doc's own P2b checklist —
artifacts/lanes not yet operator-verified.*
