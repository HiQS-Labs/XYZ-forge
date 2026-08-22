---
gh_issue: 141
source: https://github.com/HiQS-Suite/XYZ-forge/issues/141
title: "Make Fuzzing and ATE actually useful: neither currently fuzzes"
status: Active (2-WORKING — plan ratified 2026-08-22, execution started)
created: 2026-08-22
updated: 2026-08-22
owner: noelsaw1
doc_type: plan
effort: 3
complexity: 3
risk: 3
phases: 4
rating: "pri/sev/appeal/effort 80/65/85/55 · calc 285"
related:
  - https://github.com/HiQS-Suite/XYZ-forge/issues/142
  - https://github.com/HiQS-Suite/XYZ-forge/issues/143
  - https://github.com/HiQS-Suite/XYZ-forge/issues/146
goal: >
  Execute #141's Phases 1, 2, 4, and 5: one selector owns the synthetic suites, telemetry
  carries no aliased field, the ATE chain fails loudly and hermetically, and ATE's labels,
  classifier prompt, and docs stop being Aider-specific. Phase 3 (generative fuzzing) is
  deferred per the issue's own recommendation until #143's incidence comparison is run.
---

# GH-141: make the fuzzing and ATE subsystems actually useful

## Status

| What was just completed | What's next |
|---|---|
| **BUILT 2026-08-22 on branch `gh141-fuzz-ate-utility`** — all in-scope phases landed: **#142** exit contract (0/3/1 + propagation; SKILL.md documents it) with `gh142-ate-exit-contract.sh` **23/0** (which also carries Phase 4's three outcomes + dedup, replacing the original live-run phase); **Phase 1** single selector (`validate.sh --list`, 14/14 synthetic suites registry-reachable, fuzz-loop consumes the registry) with `gh141-synthetic-registry.sh` **6/0**; **Phase 2** de-aliased telemetry (nested `classification.status` removed; severity grades exit classes; cause classifies output; both consumer shapes coexist) pinned by the extended `gh102` suite over a five-outcome corpus; **Phase 5** Aider decoupling (neutral labels end-to-end with preset opt-back-in, `expects_edits` oracle key — the #146 fix, `variations.turn-shims.yaml`, SKILL.md generalized). | Full gate green → PR into `development` → merge closes #141 (Phases 1/2/4/5 + #142; Phase 3 remains deferred to #143's comparison). If the gate leaves `.relay-scratch/` at the harness root again (observed once after the gh101 suite runs), file the suite-hygiene follow-up. |

## Assumptions (the bets, made explicit)

1. **PR #145 merges first.** Phase 1 edits `validate.sh`'s TESTS registry, which #145 also
   edited; building on the merged state avoids a known conflict. DONE — merged as `9c07f0cc`.
2. **Phase 3 is deferred, not sliced.** The issue's own text: the #143 incidence comparison
   should run "before Phase 3 is scheduled" because ranking the targets without it repeats the
   over-claim round 1 caught. Shipping the parser-only slice now would still be scheduling
   Phase 3. The comparison is #143's Phase C, not this branch's work.
3. **RELEASES.md is not touched.** Its own contract makes it an optional planning ledger edited
   only on an explicit operator release-planning request; none was made. Ship-time record goes
   to CHANGELOG.md; `releases roadmap sync` runs after ROADMAP ledger edits only.
4. **Phase 5 does not archive the Aider presets.** The issue's archive recommendation is
   conditioned on "no named owner commits to reading a recurring soak" — the #146 live soak
   (60 min, 24 iterations, #141 comment 3) is evidence of active use, so the condition's premise
   changed after the issue was written. What the soak DID prove broken is the Aider-coupled
   oracle (17 false HIGH `no_edit` failures on non-Aider probes) — so this branch implements the
   decoupling (labels, classifier prompt, docs) and leaves the archive decision to the operator
   timebox the issue names. Reversibility: Easy (nothing is deleted).

## Execution order and acceptance

### Step 0 — #142: the ATE exit-code contract (prerequisite, own issue)

Sites and fix exactly as #142 specifies:

- `compile_issue.py`: `main()` returns an int; `__main__` does `sys.exit(main())`. Exit codes,
  deliberate and documented in `utils/ate/SKILL.md`: **0** filed or dry-run rendered, **3** no
  records to file (distinct, non-error, machine-branchable), **1** `gh issue create` failed
  (body preserved). The failure branch also returns, not falls through.
- `run_variations.py`: `file_issue()` returns the child's return code (drop `-> None`);
  `main()` propagates it (its tail is already `sys.exit(main())`). A failing chain no longer
  ends a multi-hour run at exit 0.
- Regression: `test/gh142-ate-exit-contract.sh` — hermetic, stub `gh` on PATH; asserts all
  three terminal codes through `compile_issue.py` AND propagation through `run_variations.py`
  (`--mock-classifier`, tiny grid, `command_template` stub so nothing real runs).

Acceptance: #142's repro (failing stub `gh` → exit 0) flips to nonzero; no-records and
filed/dry-run are distinguishable; SKILL.md documents the contract.

### Phase 1 — one selector owns the synthetic suites

- `validate.sh` gains a `--list` mode printing the registry's suite paths (`test/<entry>`, one
  per line) and changing nothing else. The registry (TESTS array) is already the authoritative
  gate owner; this exposes it as the shared manifest the issue asks for.
- Register ALL synthetic suites: 14 exist today (the issue's 11 + the three Wave-1 suites #145
  registered). Wrappers at `test/<name>.sh` (GH-124 pattern) + TESTS entries for the 10 not yet
  registered: `gh101-consult-programmatic`, `gh101-relay-programmatic-stress`,
  `gh102-telemetry-schema`, `gh94-containment-invariants`, `gh94-script-serialization`,
  `synthetic-claude-target-root`, `synthetic-marathon-env-leak`,
  `synthetic-marathon-worktree-guard`, `synthetic-pi-model-unset`,
  `synthetic-pi-provider-unsupported`.
- `fuzz-loop.sh` CONSUMES the registry instead of its own `find`: default membership =
  `validate.sh --list` filtered to `synthetic/` (fallback to the old `find` only if `--list` is
  unavailable, announced). `--test-dir` still overrides for ad-hoc runs. Default root stays the
  synthetic subset — NOT all 237 (two python3 timestamps per suite is fine at 14, not at 237).
- Regression: `test/gh141-synthetic-registry.sh` — (a) every `test/synthetic/*.sh` is
  registry-reachable via `validate.sh --list`; (b) fuzz-loop's default selection equals the
  registry's synthetic subset (no suite selectable by one path but not the other); (c) a new
  synthetic suite dropped in place is CAUGHT as unregistered (the divergence the issue says
  must be impossible to miss).

Acceptance: single ownership, proven by the regression; telemetry stays opt-in.

### Phase 2 — remove redundancy, keep metadata (consumer-coupled)

- The nested `classification.status` alias is REMOVED (the issue's explicit inclusion).
  `severity` and `likely_cause` stop being pass/fail aliases and become DERIVED signal:
  `severity` maps the documented harness exit classes (2 usage · 3 stall · 4 escalate · 5 env ·
  6 containment · 7 timeout → graded severities; other nonzero → high), and `likely_cause`
  classifies the captured output (traceback → `unhandled_traceback`, timeout markers →
  `timeout`, else the existing invariant label). Passes keep `severity: none`/null cause —
  schema metadata (`schema_version`, `engine`) untouched.
- Consumers updated in the SAME phase (the coupling the first two drafts missed):
  `compile_issue.py`'s skip logic keys on top-level `status` + severity (no nested status);
  `checkin.py` continues to render `category`/`likely_cause`, which survive.
- `test/synthetic/gh102-telemetry-schema.sh` extended: mixed-outcome fixtures (pass, assertion
  fail, timeout-class exit, usage-class exit) and assertions on `checkin.py`'s RENDERED groups,
  not just JSON keys; plus the negative: no analytic field equals a pure function of `status`
  across a mixed corpus.

Acceptance: "no analytic field is a pure alias of another field", proven over a mixed corpus,
with consumers green.

### Phase 4 — hermetic ATE chain test (after #142)

- `test/gh141-ate-chain-hermetic.sh`: stub `gh` (records invocations, scriptable rc), tiny
  variations.yaml with `command_template` stubs, `--mock-classifier`. Asserts the three
  outcomes the issue names: (1) no records → no `gh` invocation + exit 3; (2) failing `gh` →
  nonzero propagates through BOTH `compile_issue.py` and `run_variations.py`; (3) dedup —
  repeated `category :: likely_cause[:60]` signatures collapse to one bucket with the correct
  `seen Nx` count. No network, no issue created, seconds to run.

Acceptance: the regression is deterministic and observes all three outcomes.

### Phase 5 — ATE disposition: decouple from Aider (no new capability)

- Labels: `compile_issue.py` default becomes `["bug"]` (neutral); the Aider preset opts back in
  explicitly; `run_variations.py` gains `--issue-label` (repeatable) passed through.
- Classifier prompt: `CLASSIFY_PROMPT`'s "always an edit task" premise becomes conditional on an
  `expects_edits: true|false` grid key (default true = stock Aider grid unchanged); the #146
  soak's 17 false HIGH `no_edit` verdicts are the documented motivation.
- New `utils/ate/variations.turn-shims.yaml`: a declared turn-shim grid via `command_template`
  (argv-list form), with the safe execution profile written into it (stub builder binaries or a
  disposable full clone — GH-564), NOT wired to any runner by default.
- `utils/ate/SKILL.md` generalized off Aider (the generic matrix runner is the subject; Aider
  is one preset), including the Step-0 exit-code contract.

Acceptance: labels default-neutral end-to-end; a non-edit probe grid classifies a no-edit exit-0
run as pass; docs describe the engine, not one pipeline.

## Anti-goals (inherited from the issue)

No coverage-guided fuzzer; no LLM-content fuzzing; no second test runner (Phase 1 consolidates);
no GitHub issues as a test oracle; no ATE deletion; no schema expansion (Phase 2 only removes);
no Phase 3 on this branch.

## Verification ladder

1. Per-step suites green (`gh142-ate-exit-contract.sh`, `gh141-synthetic-registry.sh`,
   extended `gh102-telemetry-schema.sh`, `gh141-ate-chain-hermetic.sh`, plus
   `ate-run-variations.sh` and `gh124-closeout.sh` as containment neighbors).
2. `./validate.sh` full gate green on the final tree.
3. `utils/pdda/pdda.sh run` — 0 errors.
4. `releases roadmap sync` after ROADMAP edits; CHANGELOG entry at ship time.
5. Negative controls recorded per phase (pre-fix behavior pinned in each suite's header).
