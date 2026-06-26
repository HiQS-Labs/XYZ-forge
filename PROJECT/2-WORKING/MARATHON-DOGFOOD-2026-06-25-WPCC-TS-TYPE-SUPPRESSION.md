---
title: Marathon Dogfood — Headless Relay builds WPCC "TS type-suppression" detector
status: Phase 0 — pre-registration (locked before any turn fires)
created: 2026-06-25
updated: 2026-06-25
owner: Noel (with Claude Code, Opus 4.8)
harness_repo: xyz-3-agents-swarm (relay-automation/ Marathon stack)
substrate_repo: WP-Code-Check (bash scanner; grep-based JSON pattern library)
substrate_branch: marathon-dogfood/ts-type-suppression (to cut off origin/development @ clean)
executes_issue: Hypercart-Dev-Tools/WP-Code-Check#129 (Add TypeScript antipattern detection) — first "lite" slice
supersedes_substrate: >
  MARATHON-DOGFOOD-2026-06-24-SLEUTH-NEARMISS-2LITE.md (Sleuth substrate retired — the near-miss tier
  was hand-shipped in sleuth-app 77a95a7 on 2026-06-24, the same day it was pre-registered) and
  MARATHON-DOGFOOD-2026-06-18-WPCC-PHASE2.md (original WPCC backlog already shipped).
goal: >
  Dogfood the Marathon headless-relay harness against a REAL, maintainer-wanted target — building the
  first "lite" slice of WPCC issue #129: a single new grep-based detector pattern, ts-type-suppression,
  that flags TypeScript type-system suppression directives (@ts-ignore, @ts-nocheck, and bare
  @ts-expect-error with no explanation). HARNESS EXPERIMENT: the deliverable is data + a
  graduate/iterate/abandon verdict; a clean, mergeable WPCC pattern is the realistic bonus, not a
  throwaway, because the slice is additive (new pattern + fixture), advisory-severity, and .ts/.tsx-scoped.
---

# Marathon Dogfood: Headless Relay builds WPCC "TS type-suppression"

A controlled experiment. The harness drives ONE bounded, additive slice — a new grep detector pattern
inserted into WPCC's JSON pattern library — with WPCC's own per-fixture scanner output as the objective
gate. agy builds, Codex reviews, this session orchestrates.

> **Why this substrate survives where two prior ones didn't.** WPCC's original 3-rule backlog and
> Sleuth's Near-Miss 2-lite were both **hand-built before the marathon could fire** (substrate
> starvation — see the Phase 6 ledger entry). This slice was chosen *after* verifying it is unbuilt on
> the **freshest** WPCC branch (`origin/development`, last commit 2026-06-18), not just on the stale
> `main` (v2.2.9, March). It is a maintainer-filed open issue (#129), so building it is wanted, not
> speculative.

---

## Status

| What was just completed | What's next |
|---|---|
| **Phase 0 discovery + design ✅ 2026-06-25** — live WPCC clone located (`WP-Code-Check`, v2.2.9 on `main`; freshest work on `origin/development` @ 2026-06-18). Target `ts-type-suppression` confirmed **unbuilt on the freshest branch** (no `ts-*` pattern, no `typescript` category, no `@ts-ignore`/`as any` check). Gate designed **narrow** after the full `run-fixture-tests.sh` suite was found **7/10 red at baseline on `development`** (pre-existing expected-count drift — NOT caused by this build). Schema template + registry + validator paths pinned below. | **Operator GO to fire**, then: cut `marathon-dogfood/ts-type-suppression` off `origin/development`, capture the narrow-gate baseline (new fixture absent ⇒ 0 findings), and run the single-phase build (agy builder + Codex reviewer) via `marathon-drive.sh --target-root <WP-Code-Check>` with `RELAY_WORKTREE_ISOLATION=1`. |

---

## Pre-flight verification (2026-06-25)

- **Live clone + freshest branch.** `WP-Code-Check` is the live clone (v2.2.9); `…/AI-DDTK-Fix-Iterate-Loop/tools/wp-code-check` is a stale v1.3.14 and is NOT the substrate. The freshest branches are `origin/development` and `origin/rules/issue-61-detection-gaps`, both 2026-06-18. `origin/development` is the integration target and the cut point.
- **Target unbuilt-delta confirmed (on `origin/development`, not just `main`):** no `dist/patterns/ts-*.json`; no pattern with `"category": "typescript"`; no `@ts-ignore` / `@ts-nocheck` / `@ts-expect-error` detection anywhere in `dist/`. The `.ts`/`.tsx` globs that DO exist are pre-existing language-agnostic JS/headless patterns (exactly as issue #129 notes). Candidate 1 from the Launchpad proposal (`nonstandard-wordpress-translation-alias`) is already built + `enabled: true` (exhausted); this slice is a different, genuinely-absent rule.
- **Gate is narrow by necessity (verified):** the full suite `dist/tests/run-fixture-tests.sh` is **7/10 FAILED at baseline** on `origin/development` (e.g. `clean-code.php` expected 1 error / got 4; `antipatterns.php` expected 4 warnings / got 2), with fully-populated JSON output — i.e. pre-existing expected-count drift, independent of this experiment. Therefore the objective gate is scoped to the **new fixture only** (Q2 below), not the suite. The marathon must NOT gate on `run-fixture-tests.sh` wholesale.
- **Schema template:** `dist/patterns/headless/api-key-exposure.json` is the canonical grep-pattern shape (`detection_type: "direct"`, `detection.type: "grep"`, `patterns[]` with `id`/`pattern`/`description`, `exclude_patterns`, `exclude_files`) and already includes `*.ts`/`*.tsx` in `file_patterns`. The builder mirrors it.
- **Registry + validator:** the canonical registry `dist/PATTERN-LIBRARY.json` is **generated** by `dist/bin/pattern-library-manager.sh`; schema is checked by `dist/bin/check-pattern-library-json.sh`. Acceptance criterion "PATTERN-LIBRARY.json updated" ⇒ regenerate via the manager, do not hand-edit.
- **Workers:** agy + Codex both run **sandbox-OFF** (agy keychain/backend, codex keychain). agy lane is **cost-blind** (no token output) — this run claims no cost figure.

---

## Experiment Design (pre-registered questions — lock before Phase 1)

- **Q1 — Feasibility at fixed caps:** Can a headless **agy** builder add a *correct, surgical* new grep
  pattern (`ts-type-suppression.json`) + a `.ts` fixture + a regenerated `PATTERN-LIBRARY.json`, following
  WPCC's CONTRIBUTING add-a-pattern process, within the caps below? Feasibility at THESE caps only.
- **Q2 — Objective correctness (the gate):** After the build, on the **new fixture only**:
  1. `bin/check-pattern-library-json.sh` passes (the new JSON is schema-valid + registered), AND
  2. the bad fixture (`tests/fixtures/ts-type-suppression.ts`) produces **exactly the expected count** of
     `ts-type-suppression` findings (each of `@ts-ignore`, `@ts-nocheck`, bare `@ts-expect-error` flagged), AND
  3. the good cases (a documented `@ts-expect-error // reason`, normal `.ts` code) produce **zero**
     `ts-type-suppression` findings. (Falsifiable; isolated from the pre-existing red suite.)
- **Q3 — Containment (tracked-allowlist scope):** Does the builder mutate **only** `ALLOW_PATHS`? Worktree
  isolation ON (`RELAY_WORKTREE_ISOLATION=1`); post-turn dirty/untracked sweep. The pattern is advisory +
  `.ts`/`.tsx`-scoped, so even if mis-tuned it cannot change any existing PHP/JS scan result — containment
  has a second floor beyond the allowlist.
- **Q4 — Reviewer value (Codex):** scored by the rubric below — falsifiable.
- **Q5 — New worker (agy-as-reviewer, optional):** if time permits, agy reviews the SAME frozen post-build
  artifact under the same rubric for a Codex-vs-agy head-to-head. Optional; its absence does not weaken Q1–Q4.
- **Q6 — Chain cleanliness:** N/A for this single-phase run — declared inconclusive.

### Reviewer scoring rubric (Q4/Q5)
True positives / false positives · effect on outcome (did a requested change alter the final diff or
gate?) · seeded-defect catch (binary — plant an over-broad pattern that flags a documented
`@ts-expect-error // reason`, or a `file_patterns` typo that stops the pattern loading; did the reviewer
catch it?) · false approval (hard fail — `Approved` while the narrow gate or a seeded defect remained).

> **Honest blind spot:** Q-cost is unanswerable — both agy and Codex are cost-blind. No "cost of an AI
> build" figure is claimed for this run.

---

## Run parameters (lock these)

- **ALLOW_PATHS (minimal, target-relative):**
  - `dist/patterns/ts-type-suppression.json` — NEW grep pattern (top-level `dist/patterns/` so the loader
    definitely picks it up; `category: "typescript"`, advisory severity = `LOW`, `file_patterns: ["*.ts","*.tsx"]`).
  - `dist/tests/fixtures/ts-type-suppression.ts` — NEW fixture (bad + good cases; the proof + the gate).
  - `dist/PATTERN-LIBRARY.json` — REGENERATED via `dist/bin/pattern-library-manager.sh`.
  - `dist/tests/run-fixture-tests.sh` — add the new fixture's expected-count row (optional; the gate runs
    the fixture directly, so this is for suite hygiene only, not the gate).
- **Objective gate (`--pre-advance-cmd`, run with cwd = `<WP-Code-Check>/dist`):**
  ```
  bash bin/check-pattern-library-json.sh \
  && ./bin/check-performance.sh --format json --paths tests/fixtures/ts-type-suppression.ts --no-log \
       | jq -e '([.findings[]|select(.id=="ts-type-suppression")]|length) >= 3'
  ```
  (Bad-case floor ≥3 = the three suppression forms flagged. The good-case zero-assertion is a second gate
  line if the good cases live in a separate `*-clean.ts` fixture; if bad+good share one fixture, assert the
  **exact** expected count instead of `>=3`.) The full `run-fixture-tests.sh` suite is **out of scope** —
  it is 7/10 red at baseline for unrelated reasons.
- **Flag/severity contract:** `category: "typescript"`, `severity: "LOW"` (advisory). The pattern emits a
  **warning**, never an error, and only on `.ts`/`.tsx` — so it cannot regress any existing scan. (No env
  flag needed; the `.ts`-scope + advisory-severity IS the containment, equivalent to Sleuth's default-OFF.)
- **Caps (pre-registered):** `--max-turns 12` · `RELAY_TURN_TIMEOUT_S 900` · `--round-cap 5`
  (= 2×2 review rounds + 1) · `--require-clean` ON · `RELAY_WORKTREE_ISOLATION=1` ·
  `--target-root <WP-Code-Check>`. Budget cap N/A (cost-blind agy builder).
- **Invalidation rule:** if brief, caps, harness scripts, or the substrate baseline change between the
  Phase-1 build and any Phase-2 (agy) reviewer comparison, the comparison is INVALID — restart both
  reviewers from the frozen baseline + patch. No mid-experiment goalpost moves.

---

## Builder brief
→ [briefs/wpcc-ts-type-suppression-brief.md](briefs/wpcc-ts-type-suppression-brief.md) (the single-phase
`--phase-brief` the harness feeds the headless builder).

## Out of scope / deferred
- The remaining #129 TS patterns (`as any`, `<any>`, `: any`, broad `eslint-disable`, non-null-assertion
  abuse) — follow-on "lite" slices if this one graduates.
- Fixing WPCC's pre-existing 7/10 `run-fixture-tests.sh` baseline drift — a separate WPCC maintenance
  task, not this experiment.
- Merging the pattern to `origin/development` — a separate human/maintainer review (and likely an upstream
  PR against #129), not this experiment.
- WPCC issue #132 (`--help` literal `$SCRIPT_VERSION`) — a real 1-line bug, but wrong shape for a marathon
  (trivial, modifies the scanner core); hand-fix separately.
