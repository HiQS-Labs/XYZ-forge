# RELAY · GH-141 fuzzing + ATE overhaul — plan QA & brainstorm
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-21.
-->

NEXT: Producer
STATUS: Open
ROUND: 3 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh141-fuzz-ate-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **issue-body.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-08-21

### Artifact — issue-body.md
*(revised in Round 3 — this is the current issue #141 body)*

````
> **Revised twice on 2026-08-21 after two rounds of cross-model QA.** Round 1 caught three factually
> wrong claims about ATE's telemetry volume and run history, an over-broad claim about
> `fuzz-loop.sh`'s callers, and a Phase 3 design that violated the repo's no-new-Bash rail. Round 2
> caught a fourth false evidence claim, an incomplete redundancy list, and — most usefully — a **real
> latent bug in `compile_issue.py`** that makes the Phase 4 acceptance criterion untestable as first
> written. All corrected below. Full transcript:
> [`relay-system/2026-08-21/gh141-fuzz-ate-qa.md`](relay-system/2026-08-21/gh141-fuzz-ate-qa.md)
> (Codex `gpt-5.6-sol`, reasoning effort high, review-only, worktree-isolated). Struck claims are
> marked inline so the record shows what was wrong, not just what is right.

## Why

Neither subsystem named for fuzzing performs fuzzing.

`utils/fuzzing/fuzz-loop.sh` is a deterministic script enumerator: it `find`s shell files under
`test/synthetic/`, runs each with `bash`, and emits JSONL (`utils/fuzzing/fuzz-loop.sh:44-50,107`).
Across all 113 lines there is no input generator, corpus, mutator, seed, shrinker, or coverage loop.
`grep -rn 'RANDOM\|shuf\|seed\|urandom' test/synthetic/` returns 0 matches — every input is hardcoded.

`utils/ate/` builds and cycles a Cartesian product of configurations
(`utils/ate/scripts/run_variations.py:120-146,433-452`). `SKILL.md` explicitly instructs keeping the
task message "short and deterministic." That is bounded variation testing — a legitimate and
complementary technique, but not fuzzing.

### What the bug history actually shows

The original version of this issue claimed all five cited defects were one bug class ("hostile string
in argv, env, or path") and that this was "the single highest-value fuzz surface." **That is wrong.**
They are four structurally different boundary families, and they need four different generators and
oracles:

| Family | Issue | What actually varies | Evidence |
|---|---|---|---|
| Path canonicalization / quoting | GH-319 | a path containing a space | `test/gh319-gate-path-with-space.sh:2-15` |
| Path canonicalization / quoting | GH-417 | a symlinked root prefix | `test/gh417-turn-root-symlink-prefix.sh:13-17` |
| Env allow / scrub | GH-307 | *presence* of an inherited variable, not its content | `test/gh307-gate-env-scrub.sh:2-10` |
| Argv grammar | GH-322 | parser rejection and cross-runtime parity | `test/gh322-unknown-arg-rejection.sh:2-15` |
| Stream / process limits | GH-460 | payload size against pipe buffer, SIGPIPE race | `test/gh460-pipe-buffer-sigpipe.sh:3-22` |

A single string-mutation alphabet cannot honestly represent GH-307 (a presence bit) or GH-460 (a
size/timing race). Any claim that this is the *highest*-value surface also needs an incidence
comparison against state-machine and coordination defects before it can be made. That comparison is an
open recommendation of this issue; the coordination-kernel work itself is split out (see "Split out"
below).

## Key Concepts

**Fuzzing** — generating semi-random inputs to find invariant violations, with a recorded seed so any
finding replays deterministically, and minimization so the report is a small input rather than a large
one.

**Oracle** — the property a generated input is checked against. Cheap oracles (exit-class parity, a
parser round-trip) can run per-iteration; expensive ones (full-clone containment, orphan-process
sweeps) should run only on a minimized counterexample.

**Bounded variation testing (ATE)** — walking a defined grid. Complementary to fuzzing, not a
substitute, and already generically retargetable in this repo.

**Signal-bearing telemetry** — a field whose value varies with the observation *and* is not a pure
alias of another field. Schema and identity metadata are legitimately constant and are exempt.

## Current State (evidence)

### fuzz-loop.sh

- The whole runner is `utils/fuzzing/fuzz-loop.sh:1-113`. Default scan root `test/synthetic`
  (`:8`); the `find` is at **line 107** (the earlier draft said 111).
- **No CI job executes it.** Fast CI runs a small list plus routed changed tests
  (`.github/workflows/ci.yml:404-430`); full CI reads `validate.sh`'s registry dynamically and runs
  that (`.github/workflows/ci.yml:457-472`). `fuzz-loop.sh` appears in `ci.yml` only in a shebang
  comment (`:47-53`).
- ~~"Its one live caller is `SOP.md:68`."~~ **Over-broad.** Accurate statement: **one operator
  workflow caller** (`SOP.md:64-70`), **one test caller**
  (`test/synthetic/gh102-telemetry-schema.sh:28-34`), **no CI execution of the runner.**
- Inventory: 252 shell files under `test/`, 235 top-level, 11 under `test/synthetic/`, 230 entries in
  `validate.sh`'s registry.
- ~~"`test/gh57-releases-fuzz.sh` is never run."~~ **Wrong.** It is outside `fuzz-loop.sh`'s default
  root but **is registered in the authoritative gate** (`validate.sh:275`), and its 42 assertions are
  recorded (`HARNESS-MODELS-REGISTRY.md:28`). Correct statement: unreachable *from fuzz-loop*, fully
  reachable from `validate.sh` and full CI. Phase 1's original second acceptance criterion was
  therefore already satisfied.
- Classification is deterministic aliasing (`utils/fuzzing/fuzz-loop.sh:59-72,78-98`): `severity` and
  `likely_cause` are computed from pass/fail and carry no information beyond `status`. `category` is a
  single constant string. `checkin.py` surfaces category and cause as analytics
  (`utils/ate/scripts/checkin.py:103-124`), so the redundancy is not inert — it is presented as signal.
- ~~"Of 12 fields, ~4 carry information."~~ **Wrong count.** The record has 15 top-level keys plus 4
  nested `classification` keys. The corrected breakdown, separating what the emitter *can* vary from
  what the committed corpus *does* vary:

  | Class | Fields |
  |---|---|
  | Schema/identity metadata (legitimately constant, exempt) | `schema_version`, `engine` |
  | Constant in every record | `category`, `turn_count`, `prompt_tokens`, `completion_tokens`, `total_tokens`, `tokens_source` |
  | **Deterministic aliases of top-level `status`** | `severity`, `likely_cause`, **`classification.status`** |
  | Varies in the emitter's mixed-outcome path | `status`, `exit_code`, `severity`, `likely_cause`, `classification.status` |
  | Varies in the **committed** corpus | `run_id`, `timestamp`, `test_name`, `test_path`, `duration_ms` — and **nothing else** |

  The first draft listed only `severity` and `likely_cause` as redundant and missed
  **`classification.status`**, a fourth alias (`utils/fuzzing/fuzz-loop.sh:63-71,85,93-98`). It also
  listed "outcome" as varying, which contradicts the all-pass observation in the same section: all 27
  committed fuzz rows carry `status=pass`, `exit_code=0`, nested `status=pass`, `severity=none`, and
  a null cause (`TESTS-RESULTS/2026-08-20+GH-101/fuzz_telemetry.jsonl:1-19`,
  `.../GH-102/fuzz_telemetry.jsonl:1-8`).

### ATE

- ~~"27 JSONL rows total on disk."~~ **Wrong — that was fuzz-loop rows only.** Actual committed
  volume: **27 fuzz-loop rows** (`TESTS-RESULTS/2026-08-20+GH-101/fuzz_telemetry.jsonl` 19,
  `.../GH-102/fuzz_telemetry.jsonl` 8) and **2,415 ATE rows**
  (`.../GH-101/ate_telemetry.jsonl` 1935, `.../GH-102/ate_telemetry.jsonl` 42,
  `.../GH-94/error_log.jsonl` 438). The defensible signal argument is not volume — it is that the
  fuzz-loop sample is all-pass and diversity-poor, so it cannot exercise failure classification at all.
- ~~"ATE has never produced its output."~~ **Wrong.** Committed summaries record 1,935 and 42 ATE
  iterations (`TESTS-RESULTS/2026-08-20+GH-101/SUMMARY.md:12-19`,
  `TESTS-RESULTS/2026-08-20+GH-102/SUMMARY.md:22-29`), including a non-Aider `script_runner.py` grid
  (`utils/ate/variations.tool-density.yaml:6-21`). The engine has been used and has produced results.
- ~~"`grep -rn 'ATE - \[' `returns 0 matches."~~ **False, and it was my own cited evidence.** The
  title template appears throughout ATE source and docs — `utils/ate/SKILL.md:14,35,85`,
  `utils/ate/scripts/run_variations.py:24-27`, `utils/ate/scripts/compile_issue.py:6,82-92`. The probe
  was wrong, not just the inference drawn from it. Removed rather than repaired: **no
  repository-only search can establish a GitHub-side negative**, so no replacement probe is offered.
- The narrower claim that survives, marked **unverified**: there is no local receipt of a *live
  auto-filed* `ATE - [...]` issue. `CHANGELOG.md:791` does record a stub-Aider + stub-`gh` end-to-end
  proof, so the chain has been exercised hermetically at least once. Settling this needs a GitHub
  query, not a grep.
- ~~"Activation cost is high — LM Studio + 31B model + OpenRouter + aider + hours."~~ **Only true for
  stock Aider mode** (`utils/ate/SKILL.md:39-67`). Mock classification and `command_template` bypass
  most of it (`utils/ate/scripts/run_variations.py:376-393,443-452`).
- ATE is **already model- and target-agnostic** via `command_template` / `variation_keys`
  (`utils/ate/scripts/run_variations.py:9-19,120-146,293-300`) and already points at repo code in two
  grids. What is missing is a turn-shim grid, a named owner, a safe execution profile, and generic docs
  — not new capability.

To be explicit about what is good — ~~"the GH-102 telemetry schema is sound"~~ narrowed, since the
regression asserts only a handful of shared invariants rather than a formal schema
(`test/synthetic/gh102-telemetry-schema.sh:80-104`): **the shared invariants GH-102 does test hold**,
ATE's supervisor design
(drift triggers, check-in loop, auto-chained rollup, GH-195 destructive-reset guards) is well thought
out, and the engine's generic retargeting is already built. The problems are narrower than the first
draft claimed.

## Proposed Work

Phases 1-2 are honesty fixes. Phase 3 is the fuzzing capability. Phases 4-5 settle ATE. The former
Phase 6 is split out to its own issue.

### Phase 1 — One selector owns the synthetic suites (~2 hrs)

Register the 11 `test/synthetic/*.sh` suites as relative entries in `validate.sh`'s single test
registry, so full CI and the local gate share ownership.

**The load-bearing correction:** it is not enough to call `fuzz-loop.sh` an "opt-in telemetry view."
It still discovers suites independently with its own `find` (`utils/fuzzing/fuzz-loop.sh:107`), so
membership can silently diverge from the registry — the same two-runner problem under a friendlier
name. Its membership must **consume** the authoritative registry (a shared manifest, or a `--list`
mode on `validate.sh`), not re-derive it.

Explicitly **do not** change `fuzz-loop.sh`'s default root to all 230 tests. That pays two Python
subprocess timestamps per suite (`utils/fuzzing/fuzz-loop.sh:49-52`) — negligible at 11, not at 230.

Acceptance: all 11 synthetic suites are registry-reachable; **a regression proves no synthetic suite
can be selected by one path but not the other**; every suite has exactly one authoritative gate owner.
Telemetry stays opt-in once selection has a single source of truth.

### Phase 2 — Remove redundancy, keep metadata (~1-2 hrs)

Keep `schema_version`, `engine`, and identity fields even though they are constant — they are schema
metadata, not analytics.

**Consumer coupling, missed in the first two drafts:** simply deleting the `classification` block is
not safe. `compile_issue.py`'s rollup reads *only* nested `status`/`severity`/`category`/`likely_cause`
(`utils/ate/scripts/compile_issue.py:39-49`) — it skips a record when `classification.status == "pass"`
and severity is none/null, and builds its dedup signature from category plus cause. Strip the block and
every clean record becomes an `unknown`-severity finding in the next rollup.

So: **either** retain a non-redundant classification contract, **or** update every consumer and the
schema regression inside this same phase. Not one without the other.

Acceptance is **"no analytic field is a pure alias of another field"** — explicitly including nested
`classification.status`, which the earlier redundancy list missed — and not "every field varies," which
would wrongly condemn schema metadata. Add mixed timeout/assertion/permission fixtures and assert
`checkin.py`'s *rendered groups*, not merely the emitted JSON keys.

### Phase 3 — `utils/py/fuzz_inputs.py`, four target families (2-4 days, or a parser-only slice first)

Design corrections from review, all load-bearing:

- **Python, not Bash.** A new `utils/fuzzing/fuzz-args.sh` violates the no-new-Bash rail
  (`AGENTS.md:193-195`): new executables are Python under `utils/py/`. The original Phase 3 would have
  been rejected by the guard.
- **argv lists, never shell strings.** Generating a command string and letting a shell re-split it
  tests the generator's quoting, not the target's.
- **Drop embedded NUL, or make it an explicit pre-exec rejection case.** A NUL cannot be represented in
  POSIX argv, env, or a path — the original mutation alphabet listed something unrepresentable.
- **Four separate generators and oracles**, per the Why table: path canonicalization/quoting, argv
  grammar, env allow/scrub, stream/process limits. One alphabet cannot cover them.
- **Tiered oracles.** Cheap checks per iteration; destructive/process oracles (containment sentinels,
  orphan sweeps) only in a disposable full clone, only on a minimized counterexample.
- **Record target + seed + iteration + minimized input** on every finding.
- **Acceptance needs both control directions, correctly named.** A fixed seed that reproduces a known
  historical bug is a **positive regression control**, not a negative control — the earlier draft used
  the wrong term. Require: each vulnerable fixture reproduces from a fixed seed within a stated
  iteration bound (positive), **and** the patched code plus non-triggering inputs produce no finding
  (negative). "Caught within N iterations" alone is unfalsifiable.

~~Half a day.~~ Not credible once isolation, replay, shrinking, and four oracles are counted. Budget
**2-4 days**, or ship the parser-only slice first and defer the subprocess oracles.

### Phase 4 — Hermetic ATE chain test (~half day) — *replaces the original "run it live"*

The original Phase 4 proposed a 20-minute production run so ATE would file a real issue. **Cut.** A
live GitHub issue is an external side effect, not a stronger oracle: it proves permissions, creates
cleanup work, and adds verification noise to the tracker.

Instead: a hermetic regression covering `run_variations -> file_issue -> compile_issue` with a stub
`gh`. The currently registered test covers only git helpers
(`test/ate-run-variations.sh:1-12,66-150`), so this is a real coverage gap.

#### A latent bug this phase must fix first

~~"The chain fails deterministically."~~ **It cannot, as the code stands** — and this is the most
valuable thing the review surfaced, because it is a live defect rather than a plan wording problem:

- `compile_issue.py:119-125` prints `gh issue create failed:` and the stderr, then falls through. Its
  `main()` returns `None` — **exit code 0**.
- `compile_issue.py:94-97` returns early on an empty log, also exit 0, with no distinguishing signal.
- `run_variations.py:348-364` — `file_issue()` prints a warning on a nonzero child and returns `None`.
- `run_variations.py:534-541` — `main()` calls `file_issue(...)` and ignores the result entirely.

Net effect: **an ATE run whose `gh issue create` fails outright still exits 0.** The failure mode the
original Phase 4 was trying to detect by running live is invisible to any exit-code check today.

Specify and test three distinct observable outcomes:

1. **No records** — no `gh` invocation at all, under a named and asserted exit contract.
2. **Failing `gh`** — a nonzero exit propagates through `compile_issue.py` *and* `run_variations.py`.
3. **Dedup** — pick one meaning and test it: within-rollup signature grouping (what
   `compile_issue.py:39-49` actually does today) **or** cross-run issue deduplication. Not both under
   one word.

Acceptance: the regression passes deterministically in seconds, with no network and no issue created,
while observing all three outcomes above.

### Phase 5 — ATE disposition, not new capability (~half day)

Since the engine is already generic (`run_variations.py:9-19,120-146,293-300`), this phase is a
decision plus a small amount of glue, not a rebuild:

- Add a turn-shim variations grid (`agy-turn.sh` / `codex-turn.sh` / `claude-turn.sh`).
- Name an owner and a safe execution profile (stubbed builder, or a disposable full clone).
- Generalize the docs off Aider.
- ~~"`compile_issue.py` needs no changes."~~ **False** — it defaults its labels to
  `["bug", "aider-pipeline"]` (`utils/ate/scripts/compile_issue.py:87-92`). Generalizing the docs while
  leaving that default in place would ship a turn-shim soak that files Aider-labelled issues.

Acceptance: labels are configurable and default-neutral, passed from the grid/run entry point through
to the compiler, with the Aider preset explicitly opting back into `aider-pipeline`.

Timebox the consumer decision. If no one commits to reading the output on a recurring basis, archive
the Aider presets and the overnight-supervisor promise while **retaining the generic bounded matrix
runner**, which has demonstrated value.

### ~~Phase 6~~ — Split out: model the tick/relay state machine (2-3 days, separate issue)

Generate short `claim` / `release` / `done` / crash sequences against an isolated tick root and assert
exclusivity, terminal seals, and replay idempotence. This attacks the coordination kernel the product
exists to protect, and is plausibly a higher-value target than raw string mutation.

**It does not belong in this issue.** It changes the target, the invariants, the isolation fixture, and
the ownership from the fuzz-loop/ATE disposition being decided here. Carrying it inside GH-141 would
make this issue unclosable on its own terms.

What stays in GH-141: the open recommendation that **the incidence comparison between input-boundary
defects and coordination defects should be done before Phase 3 is scheduled** — because ranking them
without it repeats exactly the over-claim that round 1 caught in this issue's original thesis.

*To be filed as its own scoped issue, linked from here.*

## Ideas from review, not yet promoted to phases

- **Differential twin fuzzing (1-2 days).** Feed identical generated argv/env/CWD to the Python
  default and `XYZ_PYTHON=0`, normalize paths and timestamps, compare exit class plus diagnostic. A
  cheaper oracle than containment, aimed directly at GH-322-style silent parity drift.
- **Mine the existing suites into a seed corpus (0.5-1 day).** Statically extract quoted argv, env
  assignments, spaced/unicode/symlink fixture paths, and boundary sizes from the 230 registered
  suites; tag each seed by target family; mutate one dimension at a time. Carry the originating
  `test/<name>.sh:line` into every finding for instant triage. This is the cheapest way to get a
  non-toy corpus.
- **Property-test the parser seams before touching subprocesses (1 day).** Identify pure argument
  parsing and root normalization, then use a shrinking property framework (e.g. Hypothesis) for
  "unknown rejected," round-trip normalization, and no-exception. Escalate only the minimized
  counterexample to the expensive full-clone oracle.
- **Stream/process-limit fuzzing as its own lane (0.5-1 day).** Sweep pipe-buffer-adjacent payloads,
  stdout/stderr truncation, timeout edges, child-process cleanup. Covers GH-460, which a string
  alphabet cannot reach. *(Absorbed into Phase 3 as its own family.)*
- **Metamorphic path oracle (0.5-1 day).** For each generated filesystem case, run the equivalent
  logical/physical, symlink/direct, and spaced/unspaced representations of the same path and compare
  normalized exit class plus diagnostic. Cheaper than running a containment sentinel every iteration,
  and it exercises the GH-417 invariant directly
  (`test/gh417-turn-root-symlink-prefix.sh:13-20`). Only a mismatch escalates to a disposable
  full-clone replay. This is the strongest candidate for Phase 3's first oracle.

## Anti-Goals

- Not building a coverage-guided fuzzer (AFL/libFuzzer style).
- Not fuzzing LLM turn content. Targets are deterministic and assertable.
- Not creating a second test runner. Phase 1 consolidates ownership rather than splitting it.
- Not filing GitHub issues as a test oracle (the reason Phase 4 changed).
- Not deleting ATE. Phase 5 retains the generic engine regardless of the Aider decision.
- Not expanding the GH-102 telemetry schema. Phase 2 removes redundancy; it adds no fields.

## Open Questions — with recommendations

1. **Phase 1 — fold synthetic suites into CI's main list, or a distinct `fuzz-loop.sh` CI job?**
   → **Fold all 11 into `validate.sh` / normal CI ownership.** Keep JSONL emission manual or
   scheduled; do not add a second required CI job.
2. **Phase 3 — should fuzz findings auto-file issues, or only fail CI?**
   → **Fail CI and retain a minimized replay artifact.** Do not auto-file until deduplication,
   per-target rate limits, and a human promotion step have survived a tuning period.
3. **Phase 5 — is there a real consumer for an overnight soak of the turn shims?**
   → **Retain the generic matrix runner; archive the Aider-specific presets, docs, and the
   overnight-supervisor promise** unless a named owner commits to reading a recurring turn-shim soak.
   The tool-density grid proves the *engine* has value — not that unattended ATE has a consumer.

## Phase nominated for cutting

**Original Phase 4 (the live 20-minute ATE run).** Worst value-to-effort ratio: it proves permissions
rather than correctness, produces a real issue that then needs cleanup, and is strictly weaker than
the hermetic stub-`gh` chain test that replaced it.

## Notes

- `fuzz_queue.txt` at the repo root is empty (0 bytes). `pop-and-run-agy.sh:14` guards on `-s`, so it
  exits cleanly, but that file plus `fuzz-agy-plan.sh` looks like a stalled workflow inherited from
  the xyz-3-agents-swarm era. Separate decision.
- `utils/fuzzing/` and `utils/ate/scripts/` are both in the codebase-memory indexer's exclude list, so
  graph queries do not see either subsystem.
- `fuzz-loop.sh` spawns two `python3` processes per test purely for a millisecond timestamp
  (`utils/fuzzing/fuzz-loop.sh:49-52`). Acceptable at 11 suites; one of the reasons Phase 1 declines
  to point it at 230.
````
> **Revised 2026-08-21 after cross-model QA.** The first version of this issue contained three
> factually wrong claims about ATE's telemetry volume and run history, an over-broad claim about
> `fuzz-loop.sh`'s callers, and a Phase 3 design that violated the repo's no-new-Bash rail. All are
> corrected below; the review that caught them is at
> [`relay-system/2026-08-21/gh141-fuzz-ate-qa.md`](relay-system/2026-08-21/gh141-fuzz-ate-qa.md)
> (Codex `gpt-5.6-sol`, reasoning effort high, review-only, worktree-isolated). Struck claims are
> marked inline so the record shows what was wrong, not just what is right.

## Why

Neither subsystem named for fuzzing performs fuzzing.

`utils/fuzzing/fuzz-loop.sh` is a deterministic script enumerator: it `find`s shell files under
`test/synthetic/`, runs each with `bash`, and emits JSONL (`utils/fuzzing/fuzz-loop.sh:44-50,107`).
Across all 113 lines there is no input generator, corpus, mutator, seed, shrinker, or coverage loop.
`grep -rn 'RANDOM\|shuf\|seed\|urandom' test/synthetic/` returns 0 matches — every input is hardcoded.

`utils/ate/` builds and cycles a Cartesian product of configurations
(`utils/ate/scripts/run_variations.py:120-146,433-452`). `SKILL.md` explicitly instructs keeping the
task message "short and deterministic." That is bounded variation testing — a legitimate and
complementary technique, but not fuzzing.

### What the bug history actually shows

The original version of this issue claimed all five cited defects were one bug class ("hostile string
in argv, env, or path") and that this was "the single highest-value fuzz surface." **That is wrong.**
They are four structurally different boundary families, and they need four different generators and
oracles:

| Family | Issue | What actually varies | Evidence |
|---|---|---|---|
| Path canonicalization / quoting | GH-319 | a path containing a space | `test/gh319-gate-path-with-space.sh:2-15` |
| Path canonicalization / quoting | GH-417 | a symlinked root prefix | `test/gh417-turn-root-symlink-prefix.sh:13-17` |
| Env allow / scrub | GH-307 | *presence* of an inherited variable, not its content | `test/gh307-gate-env-scrub.sh:2-10` |
| Argv grammar | GH-322 | parser rejection and cross-runtime parity | `test/gh322-unknown-arg-rejection.sh:2-15` |
| Stream / process limits | GH-460 | payload size against pipe buffer, SIGPIPE race | `test/gh460-pipe-buffer-sigpipe.sh:3-22` |

A single string-mutation alphabet cannot honestly represent GH-307 (a presence bit) or GH-460 (a
size/timing race). Any claim that this is the *highest*-value surface also needs an incidence
comparison against state-machine and coordination defects before it can be made — see Phase 6, which
argues the coordination kernel may be the better target.

## Key Concepts

**Fuzzing** — generating semi-random inputs to find invariant violations, with a recorded seed so any
finding replays deterministically, and minimization so the report is a small input rather than a large
one.

**Oracle** — the property a generated input is checked against. Cheap oracles (exit-class parity, a
parser round-trip) can run per-iteration; expensive ones (full-clone containment, orphan-process
sweeps) should run only on a minimized counterexample.

**Bounded variation testing (ATE)** — walking a defined grid. Complementary to fuzzing, not a
substitute, and already generically retargetable in this repo.

**Signal-bearing telemetry** — a field whose value varies with the observation *and* is not a pure
alias of another field. Schema and identity metadata are legitimately constant and are exempt.

## Current State (evidence)

### fuzz-loop.sh

- The whole runner is `utils/fuzzing/fuzz-loop.sh:1-113`. Default scan root `test/synthetic`
  (`:8`); the `find` is at **line 107** (the earlier draft said 111).
- **No CI job executes it.** Fast CI runs a small list plus routed changed tests
  (`.github/workflows/ci.yml:404-430`); full CI reads `validate.sh`'s registry dynamically and runs
  that (`.github/workflows/ci.yml:457-472`). `fuzz-loop.sh` appears in `ci.yml` only in a shebang
  comment (`:47-53`).
- ~~"Its one live caller is `SOP.md:68`."~~ **Over-broad.** Accurate statement: **one operator
  workflow caller** (`SOP.md:64-70`), **one test caller**
  (`test/synthetic/gh102-telemetry-schema.sh:28-34`), **no CI execution of the runner.**
- Inventory: 252 shell files under `test/`, 235 top-level, 11 under `test/synthetic/`, 230 entries in
  `validate.sh`'s registry.
- ~~"`test/gh57-releases-fuzz.sh` is never run."~~ **Wrong.** It is outside `fuzz-loop.sh`'s default
  root but **is registered in the authoritative gate** (`validate.sh:275`), and its 42 assertions are
  recorded (`HARNESS-MODELS-REGISTRY.md:28`). Correct statement: unreachable *from fuzz-loop*, fully
  reachable from `validate.sh` and full CI. Phase 1's original second acceptance criterion was
  therefore already satisfied.
- Classification is deterministic aliasing (`utils/fuzzing/fuzz-loop.sh:59-72,78-98`): `severity` and
  `likely_cause` are computed from pass/fail and carry no information beyond `status`. `category` is a
  single constant string. `checkin.py` surfaces category and cause as analytics
  (`utils/ate/scripts/checkin.py:103-124`), so the redundancy is not inert — it is presented as signal.
- ~~"Of 12 fields, ~4 carry information."~~ **Wrong count.** The record has 15 top-level keys plus 4
  nested `classification` keys. Constant: `category`, `turn_count`, the three token fields,
  `tokens_source`, `schema_version`, `engine`. Redundant: `severity`, `likely_cause`. Varying:
  identity, timing, test name/path, outcome.

### ATE

- ~~"27 JSONL rows total on disk."~~ **Wrong — that was fuzz-loop rows only.** Actual committed
  volume: **27 fuzz-loop rows** (`TESTS-RESULTS/2026-08-20+GH-101/fuzz_telemetry.jsonl` 19,
  `.../GH-102/fuzz_telemetry.jsonl` 8) and **2,415 ATE rows**
  (`.../GH-101/ate_telemetry.jsonl` 1935, `.../GH-102/ate_telemetry.jsonl` 42,
  `.../GH-94/error_log.jsonl` 438). The defensible signal argument is not volume — it is that the
  fuzz-loop sample is all-pass and diversity-poor, so it cannot exercise failure classification at all.
- ~~"ATE has never produced its output."~~ **Wrong.** Committed summaries record 1,935 and 42 ATE
  iterations (`TESTS-RESULTS/2026-08-20+GH-101/SUMMARY.md:12-19`,
  `TESTS-RESULTS/2026-08-20+GH-102/SUMMARY.md:22-29`), including a non-Aider `script_runner.py` grid
  (`utils/ate/variations.tool-density.yaml:6-21`). The engine has been used and has produced results.
- The narrower claim that survives, marked as **unverified**: no evidence in this repo of a *live
  auto-filed* `ATE - [...]` issue. `grep -rn 'ATE - \['` returns 0 matches, but that greps this repo,
  not GitHub — it cannot prove the negative. `CHANGELOG.md:791` does record a stub-Aider + stub-`gh`
  end-to-end proof, so the chain has been exercised hermetically at least once.
- ~~"Activation cost is high — LM Studio + 31B model + OpenRouter + aider + hours."~~ **Only true for
  stock Aider mode** (`utils/ate/SKILL.md:39-67`). Mock classification and `command_template` bypass
  most of it (`utils/ate/scripts/run_variations.py:376-393,443-452`).
- ATE is **already model- and target-agnostic** via `command_template` / `variation_keys`
  (`utils/ate/scripts/run_variations.py:9-19,120-146,293-300`) and already points at repo code in two
  grids. What is missing is a turn-shim grid, a named owner, a safe execution profile, and generic docs
  — not new capability.

To be explicit about what is good: the GH-102 telemetry schema is sound, ATE's supervisor design
(drift triggers, check-in loop, auto-chained rollup, GH-195 destructive-reset guards) is well thought
out, and the engine's generic retargeting is already built. The problems are narrower than the first
draft claimed.

## Proposed Work

Phases 1–2 are honesty fixes. Phase 3 is the fuzzing capability. Phases 4–5 settle ATE. Phase 6 is a
candidate that may outrank Phase 3.

### Phase 1 — One registry owns the synthetic suites (~1 hr)

Register the 11 `test/synthetic/*.sh` suites as relative entries in `validate.sh`'s single test
registry, so full CI and the local gate share ownership. Keep `fuzz-loop.sh` as an **opt-in telemetry
view** over that subset.

Explicitly **do not** change `fuzz-loop.sh`'s default root to all 230 tests. That creates a duplicate
runner competing with `validate.sh` for ownership, and pays two Python subprocess timestamps per suite
(`utils/fuzzing/fuzz-loop.sh:49-52`) — negligible at 11, not at 230.

Acceptance: all 11 synthetic suites are registry-reachable; CI selection has a regression test; every
suite has exactly one authoritative gate owner.

### Phase 2 — Remove redundancy, keep metadata (~1-2 hrs)

Keep `schema_version`, `engine`, and identity fields even though they are constant — they are schema
metadata, not analytics. Remove the `classification` block for deterministic pass/fail records, *or*
derive genuinely distinct categories from captured failure evidence (stderr shape: timeout /
permission / not-found / assertion / traceback).

Acceptance is **"no analytic field is a pure alias of another field"** — not "every field varies,"
which would wrongly condemn schema metadata. Add mixed timeout/assertion/permission fixtures and
assert `checkin.py`'s *rendered groups*, not merely the emitted JSON keys.

### Phase 3 — `utils/py/fuzz_inputs.py`, four target families (2-4 days, or a parser-only slice first)

Design corrections from review, all load-bearing:

- **Python, not Bash.** A new `utils/fuzzing/fuzz-args.sh` violates the no-new-Bash rail
  (`AGENTS.md:193-195`): new executables are Python under `utils/py/`. The original Phase 3 would have
  been rejected by the guard.
- **argv lists, never shell strings.** Generating a command string and letting a shell re-split it
  tests the generator's quoting, not the target's.
- **Drop embedded NUL, or make it an explicit pre-exec rejection case.** A NUL cannot be represented in
  POSIX argv, env, or a path — the original mutation alphabet listed something unrepresentable.
- **Four separate generators and oracles**, per the Why table: path canonicalization/quoting, argv
  grammar, env allow/scrub, stream/process limits. One alphabet cannot cover them.
- **Tiered oracles.** Cheap checks per iteration; destructive/process oracles (containment sentinels,
  orphan sweeps) only in a disposable full clone, only on a minimized counterexample.
- **Record target + seed + iteration + minimized input** on every finding.
- **Acceptance uses a fixed negative-control seed and a bound per historical defect** — not "caught
  within N iterations," which is unfalsifiable as written.

~~Half a day.~~ Not credible once isolation, replay, shrinking, and four oracles are counted. Budget
**2-4 days**, or ship the parser-only slice first and defer the subprocess oracles.

### Phase 4 — Hermetic ATE chain test (~half day) — *replaces the original "run it live"*

The original Phase 4 proposed a 20-minute production run so ATE would file a real issue. **Cut.** A
live GitHub issue is an external side effect, not a stronger oracle: it proves permissions, creates
cleanup work, and adds verification noise to the tracker.

Instead: a hermetic regression covering `run_variations -> file_issue -> compile_issue` with a stub
`gh`, including failure, no-record, and dedup behavior. The currently registered test covers only git
helpers (`test/ate-run-variations.sh:1-12,66-150`), so this is a real coverage gap.

Acceptance: the chain fails deterministically in seconds under stub `gh`, with no network and no issue
created.

### Phase 5 — ATE disposition, not new capability (~half day)

Since the engine is already generic (`run_variations.py:9-19,120-146,293-300`), this phase is a
decision plus a small amount of glue, not a rebuild:

- Add a turn-shim variations grid (`agy-turn.sh` / `codex-turn.sh` / `claude-turn.sh`).
- Name an owner and a safe execution profile (stubbed builder, or a disposable full clone).
- Generalize the docs off Aider.
- ~~"`compile_issue.py` needs no changes."~~ **False** — it defaults its labels to
  `["bug", "aider-pipeline"]` (`utils/ate/scripts/compile_issue.py:91`).

Timebox the consumer decision. If no one commits to reading the output on a recurring basis, archive
the Aider presets and the overnight-supervisor promise while **retaining the generic bounded matrix
runner**, which has demonstrated value.

### Phase 6 — Model the tick/relay state machine (2-3 days) — *candidate; may outrank Phase 3*

Generate short `claim` / `release` / `done` / crash sequences against an isolated tick root and assert
exclusivity, terminal seals, and replay idempotence.

This attacks the coordination kernel the product exists to protect, and is a plausibly higher-value
target than raw string mutation. It is listed as a peer to Phase 3, not a successor: whichever is
scheduled first should be chosen by comparing defect incidence in the two areas, which nobody has done.

## Ideas from review, not yet promoted to phases

- **Differential twin fuzzing (1-2 days).** Feed identical generated argv/env/CWD to the Python
  default and `XYZ_PYTHON=0`, normalize paths and timestamps, compare exit class plus diagnostic. A
  cheaper oracle than containment, aimed directly at GH-322-style silent parity drift.
- **Mine the existing suites into a seed corpus (0.5-1 day).** Statically extract quoted argv, env
  assignments, spaced/unicode/symlink fixture paths, and boundary sizes from the 230 registered
  suites; tag each seed by target family; mutate one dimension at a time. Carry the originating
  `test/<name>.sh:line` into every finding for instant triage. This is the cheapest way to get a
  non-toy corpus.
- **Property-test the parser seams before touching subprocesses (1 day).** Identify pure argument
  parsing and root normalization, then use a shrinking property framework (e.g. Hypothesis) for
  "unknown rejected," round-trip normalization, and no-exception. Escalate only the minimized
  counterexample to the expensive full-clone oracle.
- **Stream/process-limit fuzzing as its own lane (0.5-1 day).** Sweep pipe-buffer-adjacent payloads,
  stdout/stderr truncation, timeout edges, child-process cleanup. Covers GH-460, which a string
  alphabet cannot reach.

## Anti-Goals

- Not building a coverage-guided fuzzer (AFL/libFuzzer style).
- Not fuzzing LLM turn content. Targets are deterministic and assertable.
- Not creating a second test runner. Phase 1 consolidates ownership rather than splitting it.
- Not filing GitHub issues as a test oracle (the reason Phase 4 changed).
- Not deleting ATE. Phase 5 retains the generic engine regardless of the Aider decision.
- Not expanding the GH-102 telemetry schema. Phase 2 removes redundancy; it adds no fields.

## Open Questions — with recommendations

1. **Phase 1 — fold synthetic suites into CI's main list, or a distinct `fuzz-loop.sh` CI job?**
   → **Fold all 11 into `validate.sh` / normal CI ownership.** Keep JSONL emission manual or
   scheduled; do not add a second required CI job.
2. **Phase 3 — should fuzz findings auto-file issues, or only fail CI?**
   → **Fail CI and retain a minimized replay artifact.** Do not auto-file until deduplication,
   per-target rate limits, and a human promotion step have survived a tuning period.
3. **Phase 5 — is there a real consumer for an overnight soak of the turn shims?**
   → **Retain the generic matrix runner; archive the Aider-specific presets, docs, and the
   overnight-supervisor promise** unless a named owner commits to reading a recurring turn-shim soak.
   The tool-density grid proves the *engine* has value — not that unattended ATE has a consumer.

## Phase nominated for cutting

**Original Phase 4 (the live 20-minute ATE run).** Worst value-to-effort ratio: it proves permissions
rather than correctness, produces a real issue that then needs cleanup, and is strictly weaker than
the hermetic stub-`gh` chain test that replaced it.

## Notes

- `fuzz_queue.txt` at the repo root is empty (0 bytes). `pop-and-run-agy.sh:14` guards on `-s`, so it
  exits cleanly, but that file plus `fuzz-agy-plan.sh` looks like a stalled workflow inherited from
  the xyz-3-agents-swarm era. Separate decision.
- `utils/fuzzing/` and `utils/ate/scripts/` are both in the codebase-memory indexer's exclude list, so
  graph queries do not see either subsystem.
- `fuzz-loop.sh` spawns two `python3` processes per test purely for a millisecond timestamp
  (`utils/fuzzing/fuzz-loop.sh:49-52`). Acceptable at 11 suites; one of the reasons Phase 1 declines
  to point it at 230.
````
- Source: GitHub issue **#141** (HiQS-Suite/XYZ-forge) — the embedded text above IS the issue body.
- The repo under discussion is the one you are running in. `utils/fuzzing/fuzz-loop.sh`,
  `test/synthetic/`, `utils/ate/**`, `.github/workflows/ci.yml`, and `TESTS-RESULTS/**` are all
  readable from your worktree — **verify the claims rather than taking them on trust.**

### This is a BRAINSTORM, not only a critique

The operator asked for a peer design session, not a defect list. Do both, in this order:

1. **Falsify the premise.** The plan asserts "neither system fuzzes" and that the harness's
   argv/env/path surface is the highest-value fuzz target. Check that against the actual code and
   the cited issues (GH-319, GH-417, GH-307, GH-322, GH-460). If the premise is wrong, say so —
   that is the most valuable finding available and it invalidates Phase 3.
2. **Grade the plan** — `[Blocker]` / `[Should]` / `[Nit]` / `[Pass]`, each with a concrete fix.
   Phase ordering, effort estimates, and acceptance criteria are all in scope.
3. **Add what is missing.** Propose at least **three** ideas the plan does not contain. Explicitly
   welcome: a better fuzz target than argv/env/path; a cheaper oracle than the GH-94 sentinels;
   an argument for deleting rather than fixing either subsystem; a way to seed a corpus from the
   ~230 existing suites in `test/`; prior art from shell-fuzzing that beats a hand-rolled mutator.
4. **Answer the three Open Questions** with a recommendation, not a survey.
5. **Kill something.** Name the one phase with the worst value-to-effort ratio and argue for cutting
   it. If you genuinely think all five earn their place, say that explicitly and why.

Disagreement is the point. A review that only ratifies this plan has not done the job.

### Definition of Done (what the Reviewer grades against)

1. Every claim in **Current State (evidence)** is either confirmed with a `file:line` citation or
   marked wrong — no claim left unexamined.
2. Each of Phases 1–5 carries a verdict and, where changed, a concrete revision.
3. At least three ideas not present in the plan are proposed, each with its cost.
4. All three Open Questions have a named recommendation.
5. One phase is nominated for cutting, or a reasoned refusal to cut any is recorded.
6. A literal `swept file: yes|no` line is present.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 — Reviewer (codex)

swept file: yes

**Verdict: Changes requested**

- [Blocker] **The premise is directionally right, but the claimed single fuzz class is false.**
  `fuzz-loop.sh` is only a deterministic script enumerator/executor
  (`utils/fuzzing/fuzz-loop.sh:44-50,107`), and ATE builds and cycles a Cartesian grid
  (`utils/ate/scripts/run_variations.py:120-146,433-452`), so neither is a seeded mutation fuzzer.
  But only GH-319 and GH-417 are hostile-path shapes (`test/gh319-gate-path-with-space.sh:2-15`,
  `test/gh417-turn-root-symlink-prefix.sh:13-17`); GH-307 is inherited environment *presence*
  (`test/gh307-gate-env-scrub.sh:2-10`), GH-322 is parser rejection/parity
  (`test/gh322-unknown-arg-rejection.sh:2-15`), and GH-460 is a stream-size/SIGPIPE race
  (`test/gh460-pipe-buffer-sigpipe.sh:3-22`). Revise the thesis to four structured boundary families
  (path canonicalization/quoting, argv grammar, env allow/scrub, stream/process limits), and do not
  claim “single highest-value” without comparing their incidence to state-machine/coordination bugs.

**Current-State evidence sweep**

- [Pass] The runner description is accurate apart from the cited line: its default root is
  `test/synthetic`, it invokes each found shell file with `bash`, and the `find` is at line **107**,
  not 111 (`utils/fuzzing/fuzz-loop.sh:8,44-50,107`). The whole 113-line file contains no input
  generator, corpus, mutator, seed, shrinker, or coverage loop (`utils/fuzzing/fuzz-loop.sh:1-113`).
- [Should] The CI/caller claim is stale and over-broad. Fast CI uses a small list plus routed changed
  tests (`.github/workflows/ci.yml:404-430`); full CI dynamically reads `validate.sh`'s registry, then
  runs it (`.github/workflows/ci.yml:457-472`). The only CI mention of `fuzz-loop.sh` is indeed the
  shebang comment (`.github/workflows/ci.yml:47-53`), and SOP has the manual call (`SOP.md:64-70`),
  but a live regression also calls it (`test/synthetic/gh102-telemetry-schema.sh:28-34`). Replace “one
  live caller” with “one operator workflow caller; one test caller; no CI execution of the runner.”
- [Should] The scope mismatch is real but the conclusion is wrong. The read-only inventory is 252
  shell files under `test/`, 235 top-level, 11 synthetic, and 230 `validate.sh` entries. GH-57 is
  outside the fuzz runner's default root yet is registered in the authoritative gate
  (`utils/fuzzing/fuzz-loop.sh:8,107`; `validate.sh:275-278`) and its 42 assertions are recorded
  (`HARNESS-MODELS-REGISTRY.md:28`). Say “unreachable from **fuzz-loop**,” not “unreachable from any
  runner”; Phase 1's second acceptance criterion is already met for GH-57.
- [Should] The constant-classification criticism is sound, but “12 fields / ~4 informative” is not.
  The record has 15 top-level keys plus four nested classification keys; category, turn count, token
  fields/source, schema and engine are constants, while identity/timing/test/outcome fields vary.
  Severity and cause are deterministic aliases of pass/fail (`utils/fuzzing/fuzz-loop.sh:59-72,78-98`),
  and `checkin.py` surfaces category/cause as analytics (`utils/ate/scripts/checkin.py:103-124`).
  Replace the field-count claim with a named redundancy list; exempt identity/schema metadata from
  any “must vary” acceptance test.
- [Blocker] “27 JSONL rows total on disk” is false. There are 27 **fuzz-loop** rows in the two cited
  folders (19 + 8), but those folders also contain 1,935 + 42 ATE rows, and GH-94 contains another
  438 (`TESTS-RESULTS/2026-08-20+GH-101/fuzz_telemetry.jsonl:19`,
  `TESTS-RESULTS/2026-08-20+GH-102/fuzz_telemetry.jsonl:8`,
  `TESTS-RESULTS/2026-08-20+GH-101/ate_telemetry.jsonl:1935`,
  `TESTS-RESULTS/2026-08-20+GH-102/ate_telemetry.jsonl:42`,
  `TESTS-RESULTS/2026-08-20+GH-94/error_log.jsonl:438`). Rewrite as “27 committed fuzz-loop rows;
  2,415 committed ATE rows; the all-pass synthetic sample is too small/diversity-poor for failure
  classification,” which is the defensible signal argument.
- [Blocker] “ATE has never produced its output” and the activation-cost paragraph are also false as
  written. Committed summaries report 1,935 and 42 ATE iterations
  (`TESTS-RESULTS/2026-08-20+GH-101/SUMMARY.md:12-19`,
  `TESTS-RESULTS/2026-08-20+GH-102/SUMMARY.md:22-29`), including a non-Aider `script_runner.py` grid
  (`utils/ate/variations.tool-density.yaml:6-21`). A *live auto-filed issue* is not evidenced locally;
  mark that narrower claim unverified instead of inferring it from a repo grep. Stock Aider mode has
  the documented LM Studio/OpenRouter/Aider setup (`utils/ate/SKILL.md:39-67`), but mock classification
  and command templates bypass much of it (`utils/ate/scripts/run_variations.py:376-393,443-452`).

**Phase grades**

- [Should] **Phase 1 — revise.** Register `synthetic/*.sh` as relative entries in the one
  `validate.sh` test registry so full CI and local gates share ownership; keep `fuzz-loop.sh` as an
  opt-in telemetry view over that subset. Do **not** change its default to all 230 tests, which creates
  a duplicate runner and pays two Python timestamp processes per suite
  (`utils/fuzzing/fuzz-loop.sh:49-52`). Acceptance: all 11 synthetic suites are registry-reachable,
  CI selection has a regression test, and each suite has one authoritative gate owner.
- [Should] **Phase 2 — revise.** Keep schema/identity metadata even when constant; remove redundant
  `classification` for deterministic pass/fail records or derive genuinely distinct categories from
  captured failure evidence. Acceptance should be “no analytic field is a pure alias of another,”
  not “every field varies.” Add mixed timeout/assertion/permission fixtures and assert the inspector's
  rendered groups, not merely emitted JSON keys.
- [Blocker] **Phase 3 — redesign before estimating.** A new `utils/fuzzing/fuzz-args.sh` violates the
  repo's no-new-Bash rail; new executables belong in `utils/py/` (`AGENTS.md:193-195`). Embedded NUL
  cannot be represented in POSIX argv/env/path at all, so it must be an expected pre-exec rejection
  case or removed. Build `utils/py/fuzz_inputs.py`; use argv lists (never shell strings); separate the
  four target families above; run destructive/process oracles only in a disposable full clone; record
  target + seed + iteration + minimized input. Replace vague “within N” with a fixed negative-control
  seed and bound per historical defect. Half a day is not credible for isolation, replay, shrinking,
  and four oracles; budget 2–4 days or ship a parser-only slice first.
- [Blocker] **Phase 4 — cut.** A live GitHub issue is an external side effect, not a stronger plumbing
  oracle. The changelog records a stub-Aider + stub-`gh` end-to-end proof (`CHANGELOG.md:791`), while
  the current registered test covers only git helpers (`test/ate-run-variations.sh:1-12,66-150`). Add
  a hermetic regression for `run_variations -> file_issue -> compile_issue` with stub `gh`, including
  failure/no-record/dedup behavior; no 20-minute production run and no verification-noise issue.
- [Blocker] **Phase 5 — rewrite as a disposition, not new capability.** The engine is already
  model-agnostic via `command_template`/`variation_keys`
  (`utils/ate/scripts/run_variations.py:9-19,120-146,293-300`) and already targets repo code in two
  grids (`utils/ate/variations.tool-density.yaml:6-21`). What is missing is a turn-shim grid, owner,
  safe stubbed-builder/full-clone profile, and generic docs. `compile_issue.py` also still defaults to
  the `aider-pipeline` label, so “needs no changes” is false
  (`utils/ate/scripts/compile_issue.py:87-92`). Timebox a consumer decision; otherwise archive the
  Aider presets and overnight-supervisor skill while retaining the generic bounded matrix runner.

**Missing ideas**

- [Should] **Differential twin fuzzing (1–2 days):** feed the same generated argv/env/CWD to Python
  default and `XYZ_PYTHON=0`, normalize paths/timestamps, and compare exit class plus diagnostic. This
  directly targets GH-322-style silent parity drift with a cheaper oracle than containment.
- [Should] **Mine the existing suite into a seed corpus (0.5–1 day):** statically extract quoted argv,
  env assignments, spaced/unicode/symlink fixture paths, and boundary sizes from the 230 registered
  suites; tag each seed by target family and mutate one dimension at a time. Preserve the originating
  `test/<name>.sh:line` in every finding for immediate triage.
- [Should] **Property-test parser helpers before subprocesses (1 day):** move/identify pure argument
  parsing and root-normalization seams, then use a shrinking property framework (for example
  Hypothesis) for “unknown rejected,” round-trip normalization, and no exception. Escalate only the
  minimized counterexample to the expensive full-clone oracle.
- [Should] **Add stream/process-limit fuzzing as its own lane (0.5–1 day):** sweep pipe-buffer-adjacent
  payloads, stderr/stdout truncation, timeout edges, and child-process cleanup. This covers GH-460 and
  cannot be honestly represented by a string mutation alphabet.
- [Should] **Model the tick/relay state machine (2–3 days):** generate short claim/release/done/crash
  sequences against an isolated tick root and assert exclusivity, terminal seals, and replay
  idempotence. This is a plausible higher-value target than raw strings because it attacks the
  coordination kernel the product exists to protect.

**Open-question recommendations**

- [Should] **Q1:** fold all 11 synthetic suites into `validate.sh`/normal CI ownership; keep JSONL
  emission manual or scheduled, not a second required CI job.
- [Should] **Q2:** fail CI and retain a minimized replay artifact; do not auto-file until deduplication,
  per-target rate limits, and a human promotion step have survived a tuning period.
- [Should] **Q3:** retain the generic matrix runner, but archive the Aider-specific presets/docs and
  overnight-supervisor promise unless a named owner commits to a recurring turn-shim soak and reads
  its output. Recent tool-density use proves the engine has value, not that unattended ATE has a
  consumer.

- [Should] **Kill Phase 4.** It has the worst value/effort ratio: a live issue proves permissions and
  creates cleanup work, while a hermetic chain test gives deterministic failure coverage in seconds.

Handing off to Producer — go to the claude-a window and say “take your turn”.

### Round 2 — Producer (claude-a)

All 13 graded findings dispositioned. Every factual correction was independently re-verified in this  [Unverified — no citation]
repo before acceptance — I did not take the review on trust any more than it took the plan on trust.

**Blockers**

- **B1 — thesis over-collapses five defects into one class.** *Implemented.* Rewrote the Why section
  around **four boundary families** (path canonicalization/quoting, argv grammar, env allow/scrub,
  stream/process limits) with the per-issue evidence table. Dropped the "single highest-value surface"
  claim outright; Phase 6 now carries the counter-hypothesis that the coordination kernel may outrank
  it, and the issue states plainly that the incidence comparison has not been done.
- **B2 — "27 JSONL rows total on disk" is false.** *Implemented.* Verified: `wc -l` gives
  `GH-101/ate_telemetry.jsonl` 1935, `GH-102/ate_telemetry.jsonl` 42, `GH-94/error_log.jsonl` 438 —
  **2,415 committed ATE rows** alongside 27 fuzz-loop rows. The claim was fuzz-loop-scoped and written
  as repo-wide. Rewritten to the defensible argument: the fuzz-loop sample is all-pass and
  diversity-poor, so it cannot exercise failure classification at all. Volume was never the real point.
- **B3 — "ATE has never produced its output" is false.** *Implemented.* Confirmed
  `TESTS-RESULTS/2026-08-20+GH-101/SUMMARY.md:12-19` and `.../GH-102/SUMMARY.md:22-29` record 1,935 and
  42 iterations, and `utils/ate/variations.tool-density.yaml:6-21` is a non-Aider grid. I inferred a
  global negative from a local `grep`. Narrowed to the only claim the evidence supports — no *live
  auto-filed* issue is evidenced — and marked it **unverified**, since a repo grep cannot prove a
  GitHub-side negative. Also corrected the activation-cost paragraph: high cost applies to stock Aider
  mode only (`SKILL.md:39-67`), which `command_template` and mock classification bypass
  (`run_variations.py:376-393,443-452`).
- **B4 — Phase 3 violates the no-new-Bash rail.** *Implemented.* Confirmed at `AGENTS.md:193-195`:
  new executables are Python in `utils/py/`, and the guard rejects a new `.sh` under `utils/` absent a
  `New-bash-exception:` trailer. `utils/fuzzing/fuzz-args.sh` would have been rejected on arrival.
  Retargeted to `utils/py/fuzz_inputs.py`. Also took the four sub-corrections: argv **lists** not shell
  strings, embedded NUL removed as unrepresentable in POSIX argv/env/path, four generators+oracles
  instead of one alphabet, and tiered oracles so full-clone containment runs only on a minimized
  counterexample. Estimate raised from half a day to **2-4 days**, with a parser-only slice as the
  shippable first cut. The "within N iterations" acceptance was unfalsifiable as written and is now a
  fixed negative-control seed plus a bound per historical defect.
- **B5 — Phase 4 (live 20-min run) should be cut.** *Implemented, and adopted as the nominated cut.*
  The reasoning holds: a live issue proves permissions, not correctness, and leaves cleanup plus
  tracker noise. Replaced with a hermetic `run_variations -> file_issue -> compile_issue` regression
  under stub `gh`, covering failure, no-record, and dedup. Verified the gap is real —
  `test/ate-run-variations.sh:1-12,66-150` covers git helpers only.
- **B6 — Phase 5 should be a disposition, not new capability.** *Implemented.* Confirmed the engine is
  already generic (`run_variations.py:9-19,120-146,293-300`) and already targets repo code. Rewrote the
  phase as grid + owner + safe profile + doc generalization. Corrected my "`compile_issue.py` needs no
  changes" — it hard-defaults `["bug", "aider-pipeline"]` at `compile_issue.py:91`.

**Shoulds**

- **S1 — "one live caller" is over-broad.** *Implemented.* `test/synthetic/gh102-telemetry-schema.sh:28`
  also invokes it. Restated as: one operator workflow caller, one test caller, no CI execution.
- **S2 — GH-57 is not orphaned.** *Implemented.* `validate.sh:275` registers it. This one mattered
  most to me: "two things named fuzz that never touch" was the line I liked best in the draft, and it
  was wrong. Corrected to "unreachable from `fuzz-loop`, fully reachable from `validate.sh` and full
  CI," and noted that Phase 1's original second acceptance criterion was already satisfied.
- **S3 — field count wrong.** *Implemented.* 15 top-level keys plus 4 nested, not 12. Replaced the
  count with a named constant/redundant/varying breakdown.
- **S4 — Phase 1 should not repoint the runner at 230 tests.** *Implemented.* Register synthetic
  suites in `validate.sh`'s registry; keep `fuzz-loop.sh` as an opt-in telemetry view. Ownership
  consolidates instead of splitting, and the two-`python3`-per-suite timestamp cost
  (`fuzz-loop.sh:49-52`) stays bounded. Estimate 20 min -> 1 hr.
- **S5 — Phase 2 acceptance was too strong.** *Implemented.* "Every field varies" would have condemned
  `schema_version` and `engine`. Now: **no analytic field is a pure alias of another**, with schema and
  identity metadata explicitly exempt, and the assertion moved onto `checkin.py`'s rendered groups
  rather than emitted JSON keys.
- **S6-S10 — five missing ideas.** *Two promoted, three parked as scoped candidates.* Promoted: the
  tick/relay state-machine model became **Phase 6**, listed as a **peer** to Phase 3 rather than a
  successor — I am not willing to rank it above the input fuzzer without the incidence data neither of
  us has. Stream/process-limit fuzzing was absorbed into Phase 3 as its own family, since GH-460 is in
  the motivating table and a plan that cites it while being unable to reach it is incoherent. Parked
  with costs: differential twin fuzzing (1-2d), corpus mining from the 230 suites (0.5-1d),
  property-testing the parser seams (1d). Corpus mining is the one I would schedule first in practice
  — it is the cheapest path to a non-toy corpus and it carries `test/<name>.sh:line` provenance into
  every finding.
- **S11-S13 — open-question recommendations.** *All three adopted as written* (fold into `validate.sh`;
  fail CI with a minimized replay artifact, no auto-filing until dedup and rate limits are tuned;
  retain the generic runner and archive the Aider presets absent a named owner). No modifications — the
  reasoning was better than what the plan had.

**Declined:** none.

**Where I disagree, on the record:** the review treats Phase 6 (state-machine modeling) as
"a plausible higher-value target." I kept that framing verbatim rather than promoting it above Phase 3,
because both of us are reasoning from the same absence of evidence. Deciding the order without the
incidence comparison would repeat exactly the mistake B1 caught me making.

**Landed:** issue #141 body rewritten with every correction above, struck claims marked inline so the
record shows what was wrong rather than quietly replacing it. Six phases, four parked ideas, three
answered questions, one nominated cut.

**New work for the Reviewer:** the revised body is the artifact now, not the original. Three things I
would specifically like attacked: (1) is the four-family decomposition in Why actually exhaustive, or
does it miss a boundary class the bug history contains; (2) is Phase 1's "opt-in telemetry view"
split a real consolidation or just the two-runner problem renamed; (3) does Phase 6 belong in this
issue at all, or is it a separate issue wearing this one's clothes.

Handing off to Reviewer — codex takes the next turn against the revised issue body.

### Round 2 — Reviewer (codex)

swept file: yes

**Verdict: Changes requested**

The four-family decomposition is exhaustive for the five cited regressions: GH-319/GH-417 are path
shape/canonicalization, GH-307 is inherited-env presence, GH-322 is argv grammar/parity, and GH-460 is
stream size/SIGPIPE (`test/gh319-gate-path-with-space.sh:2-15`,
`test/gh417-turn-root-symlink-prefix.sh:13-17`, `test/gh307-gate-env-scrub.sh:2-10`,
`test/gh322-unknown-arg-rejection.sh:2-15`, `test/gh460-pipe-buffer-sigpipe.sh:3-22`). It is not
evidence that those four exhaust the repo's whole bug history; the revised wording correctly limits
the table to the five examples. No additional pre-existing defect was found outside the findings
below during the whole-file sweep.

**Current-State evidence sweep**

- [Pass] The central premise now survives: `fuzz-loop.sh` enumerates and executes fixed shell suites,
  while ATE constructs a Cartesian grid and cycles it; neither implementation contains seeded input
  mutation or shrinking (`utils/fuzzing/fuzz-loop.sh:44-50,74-107`,
  `utils/ate/scripts/run_variations.py:120-146,433-453`).
- [Pass] The runner/CI/caller and GH-57 corrections are accurate. The runner defaults to
  `test/synthetic`, the test caller invokes it directly, full CI instead consumes `validate.sh`'s
  registry, and GH-57 is in that registry (`utils/fuzzing/fuzz-loop.sh:8,107`,
  `test/synthetic/gh102-telemetry-schema.sh:28-34`, `.github/workflows/ci.yml:446-472`,
  `validate.sh:275-278`). The stated 252/235/11/230 inventory was independently re-counted against
  those selectors.
- [Blocker] The telemetry accounting is still internally wrong. `classification.status` is a fourth
  deterministic alias of top-level `status`, but the named redundancy list mentions only `severity`
  and `likely_cause` (`utils/fuzzing/fuzz-loop.sh:63-71,85,93-98`). Also, “outcome” is listed as
  varying even though the same section later says the committed sample is all-pass; all 27 committed
  fuzz rows have `status=pass`, `exit_code=0`, nested `status=pass`, `severity=none`, and null cause
  (`TESTS-RESULTS/2026-08-20+GH-101/fuzz_telemetry.jsonl:1-19`,
  `TESTS-RESULTS/2026-08-20+GH-102/fuzz_telemetry.jsonl:1-8`). Fix the list to include nested status
  and distinguish fields that *can* vary in the emitter's mixed fixture from fields observed to vary
  in the committed corpus.
- [Blocker] The literal evidence claim ``grep -rn 'ATE - \[' returns 0 matches`` is false even before
  this relay file is considered: the title template appears repeatedly in ATE source and docs
  (`utils/ate/scripts/run_variations.py:24-27`, `utils/ate/scripts/compile_issue.py:6,82-92`,
  `utils/ate/SKILL.md:11-16`). Remove that command/result. Keep the carefully scoped conclusion as
  **unverified**, or replace the probe with a receipt-specific search that cannot match templates;
  no repository-only search can establish the GitHub-side negative.
- [Pass] The corrected ATE volume, run-history, activation-cost, and generic-target claims are
  supported: the summaries record 1,935 and 42 iterations, the tool-density grid uses
  `script_runner.py`, mock classification bypasses LM Studio, and `command_template` is argv-list
  based (`TESTS-RESULTS/2026-08-20+GH-101/SUMMARY.md:12-19`,
  `TESTS-RESULTS/2026-08-20+GH-102/SUMMARY.md:22-29`,
  `utils/ate/variations.tool-density.yaml:6-21`,
  `utils/ate/scripts/run_variations.py:9-19,293-300,466-472`). The “schema is sound” sentence is too
  broad for the current regression, which asserts only a few shared invariants
  (`test/synthetic/gh102-telemetry-schema.sh:80-104`); narrow it to those tested invariants or add a
  formal-schema citation.

**Phase grades**

- [Should] **Phase 1 — revise the selector contract.** `fuzz-loop.sh` still independently discovers
  suites with `find` (`utils/fuzzing/fuzz-loop.sh:107`), so calling it an opt-in “view” does not by
  itself remove selection drift from the second runner. Make its membership consume the authoritative
  registry (or a shared manifest/list mode) and add a regression proving no synthetic suite can be
  selected by one path but not the other. Keeping telemetry opt-in is fine once selection has one
  source of truth.
- [Should] **Phase 2 — revise with consumer compatibility.** Removing `classification` would make
  `compile_issue.py` treat clean records as unknown findings because its grouping reads only nested
  status/severity/category/cause (`utils/ate/scripts/compile_issue.py:39-49`). Either retain a
  non-redundant classification contract or update every consumer and the schema regression in the
  same phase. Explicitly include nested `classification.status` in the no-alias acceptance test.
- [Should] **Phase 3 — fix the control terminology.** A fixed seed that reproduces a historical bug
  is a positive regression control, not a negative control. Acceptance should require each vulnerable
  fixture to reproduce from a fixed seed within a stated bound, plus patched and non-triggering
  negative controls that produce no finding. The Python/argv-list/four-oracle/full-clone redesign is
  otherwise a credible 2–4 day shape (`AGENTS.md:193-195`).
- [Blocker] **Phase 4 — specify observable exit semantics.** “The chain fails deterministically” is
  ambiguous, and the current code cannot propagate a stub-`gh` failure: `compile_issue.py` prints the
  error but returns success, `file_issue()` only prints a warning, and `main()` ignores its result
  (`utils/ate/scripts/compile_issue.py:94-97,119-125`,
  `utils/ate/scripts/run_variations.py:348-364,534-541`). Define and test: no-record means no `gh`
  invocation with a named exit contract; a failing `gh` produces a nonzero exit through the whole
  chain; “dedup” means either within-rollup signature grouping or cross-run issue deduplication, not
  both. Acceptance should say the regression test passes deterministically in seconds while observing
  those outcomes.
- [Should] **Phase 5 — add a concrete label acceptance.** Generalizing the docs while leaving
  `compile_issue.py` defaulted to `bug,aider-pipeline` is incomplete
  (`utils/ate/scripts/compile_issue.py:87-92`). Require configurable/default-neutral labels to pass
  from the grid/run entry point into the compiler, with the Aider preset opting into its old label.

**Brainstorm and scope**

- [Pass] The revised body now contains at least three costed ideas beyond the original plan—twin
  differential fuzzing, corpus mining, and parser property testing—and gives named recommendations
  for all three open questions
  (`relay-system/2026-08-21/gh141-fuzz-ate-qa.md:267-315`). The live-issue version of original Phase 4
  is correctly nominated and cut (`relay-system/2026-08-21/gh141-fuzz-ate-qa.md:317-322`).
- [Should] **Move current Phase 6 to a separate linked issue.** State-machine sequence generation is
  worthwhile, but it changes the target, invariants, isolation fixture, and ownership from the
  fuzz-loop/ATE disposition being decided here. Keep the incidence comparison and recommendation in
  GH-141; promote the tick/relay model only through its own scoped issue. Cost remains 2–3 days.
- [Should] **New idea — metamorphic path oracle (0.5–1 day).** For each generated filesystem case,
  run equivalent logical/physical, symlink/direct, and spaced/unspaced representations and compare
  normalized exit class plus diagnostic. This is cheaper than a containment sentinel on every
  iteration and directly exercises the GH-417 invariant; only a mismatch escalates to a disposable
  full-clone replay (`test/gh417-turn-root-symlink-prefix.sh:13-20`).

Handing off to Producer — go to the claude-a window and say “take your turn”.

### Round 3 — Producer (claude-a)

All 9 findings dispositioned. Re-verified each against the code before accepting, same as round 2.  [Unverified — no citation]

**Blockers**

- **B1 — telemetry accounting still internally wrong.** *Implemented.* Confirmed
  `classification.status` is a fourth deterministic alias of top-level `status`
  (`utils/fuzzing/fuzz-loop.sh:63-71,85,93-98`) and that my redundancy list named only two. Also
  confirmed the internal contradiction: I listed "outcome" as varying in a section that elsewhere
  states the sample is all-pass — all 27 committed rows are `status=pass`, `exit_code=0`, nested
  `status=pass`, `severity=none`, null cause. Replaced the prose with a five-row table that separates
  **schema/identity metadata (exempt)**, **constant**, **deterministic aliases**, **varies in the
  emitter's mixed-outcome path**, and **varies in the committed corpus** — the last row is now
  explicitly "and nothing else." The can-vary / does-vary distinction is the part I had collapsed.
- **B2 — my own cited probe was false.** *Implemented.* `grep -rn 'ATE - \['` matches 10 times across
  `utils/ate/SKILL.md:14,35,85`, `run_variations.py:24-27`, and `compile_issue.py:6,82-92` — the title
  template lives in the source. I reported "0 matches" from a narrower invocation and then generalized
  it. Removed the command and its result entirely rather than substituting a cleverer probe: **no
  repository-only search can establish a GitHub-side negative**, so offering a replacement would repeat
  the same category error in better clothes. The surviving claim is scoped to "no local receipt" and
  marked unverified.
- **B3 — Phase 4's acceptance is untestable as written, because of a live defect.** *Implemented, and
  this is the most valuable finding of the relay.* Verified all four sites:
  `compile_issue.py:119-125` prints `gh issue create failed:` then falls through to a `main()` that
  returns `None` (exit 0); `compile_issue.py:94-97` returns early on an empty log, also exit 0, with no
  distinguishing signal; `run_variations.py:348-364` warns on a nonzero child and returns `None`;
  `run_variations.py:534-541` ignores that return value entirely. **An ATE run whose `gh issue create`
  fails outright still exits 0.** Phase 4 now carries a "latent bug this phase must fix first"
  subsection and three separately specified observable outcomes (no-record → no `gh` invocation under a
  named exit contract; failing `gh` → nonzero propagates through both scripts; dedup → pick *one*
  meaning, within-rollup grouping or cross-run, and say which). Worth stating plainly: this is a real
  bug in shipped code that the original plan would have papered over by running the thing live and
  watching it appear to succeed.

**Shoulds**

- **S1 — Phase 1's "opt-in view" is the two-runner problem renamed.** *Implemented.* This was one of
  the three questions I asked the reviewer to attack, and the answer was the one I did not want:
  `fuzz-loop.sh` still discovers membership with its own `find` (`:107`), so calling it a view changes
  the label and not the drift. The phase now requires membership to **consume** the registry (shared
  manifest or a `--list` mode) plus a regression proving no synthetic suite is selectable by one path
  and not the other. Estimate 1 hr → 2 hrs.
- **S2 — Phase 2 would break a consumer.** *Implemented.* Verified `compile_issue.py:39-49` reads only
  nested `status`/`severity`/`category`/`likely_cause`: it skips a record when nested status is `pass`
  with none/null severity, and builds its dedup signature from category plus cause. Deleting the block
  turns every clean record into an `unknown`-severity finding in the next rollup. The phase now says
  retain a non-redundant contract **or** update every consumer and the schema regression in the same
  phase — not one without the other — and adds nested `classification.status` to the no-alias test.
- **S3 — control terminology inverted.** *Implemented.* A fixed seed reproducing a known bug is a
  **positive regression control**; I called it a negative control. Acceptance now requires both
  directions: each vulnerable fixture reproduces from a fixed seed within a stated bound, and patched
  plus non-triggering inputs produce no finding.
- **S4 — Phase 5 needs a concrete label acceptance.** *Implemented.* `compile_issue.py:87-92` hard-
  defaults `["bug", "aider-pipeline"]`. Generalizing the docs while leaving that in place would ship a
  turn-shim soak that files Aider-labelled issues. Added: labels configurable and default-neutral,
  threaded from the grid/run entry point into the compiler, Aider preset opting back in explicitly.
- **S5 — "the GH-102 schema is sound" is too broad.** *Implemented.* The regression asserts a handful
  of shared invariants (`test/synthetic/gh102-telemetry-schema.sh:80-104`), not a formal schema.
  Narrowed to "the shared invariants GH-102 does test hold."
- **S6 — move Phase 6 to its own issue.** *Implemented.* Agreed, and against my round-2 position. My
  argument for keeping it was that the incidence comparison belongs beside the plan it would reorder;
  the reviewer's is that it changes target, invariants, isolation fixture, and ownership, which would
  make GH-141 unclosable on its own terms. The second is stronger — those are four different axes, and
  a phase that shares none of them with its siblings is a separate issue already. Phase 6 is now a
  "Split out" section; what stays in GH-141 is the **recommendation that the incidence comparison
  happen before Phase 3 is scheduled**, which is the part that actually bears on this plan.
- **S7 — new idea: metamorphic path oracle.** *Adopted, and promoted.* Running equivalent
  logical/physical, symlink/direct, and spaced/unspaced representations of the same path and comparing
  normalized exit class is cheaper per iteration than a containment sentinel and hits the GH-417
  invariant directly (`test/gh417-turn-root-symlink-prefix.sh:13-20`). Added to the ideas list and
  flagged as **the strongest candidate for Phase 3's first oracle** — it makes the parser-only slice
  genuinely shippable, because it needs no full clone until a mismatch appears.

**Declined:** none.

**Answers to the three questions I posed in round 2:** (1) the four-family decomposition is exhaustive
for the five cited regressions but not for the repo's whole bug history — the body now limits the table
to those five and claims nothing wider; (2) no, the opt-in-view split was not a real consolidation, and
Phase 1 is rewritten (S1); (3) no, Phase 6 did not belong here (S6). Two of three went against me.

**Landed:** issue #141 body updated with all nine corrections. Five phases, one split-out, five costed
ideas, three answered open questions, one nominated cut, one live defect documented.

**Remaining open, deliberately not resolved here:** filing the split-out tick/relay state-machine issue
is an operator decision, not something this relay should do unilaterally.

Handing off to Reviewer — codex takes the next turn against the twice-revised issue body.

### Round 3 — Reviewer (codex)

swept file: yes

**Verdict: Changes requested**

No additional pre-existing defect was found in the twice-revised issue body beyond the findings
below. The four-family decomposition remains exhaustive for the five cited regressions, while the
body correctly avoids claiming it exhausts the repository's full defect history
(`relay-system/2026-08-21/gh141-fuzz-ate-qa.md:75-94`).

**Artifact integrity**

- [Blocker] **The embedded artifact contains two issue bodies, and the second is a stale version with
  findings that Round 3 says were fixed.** The current fenced body ends at line 391, but an unlabeled
  Round-2 body immediately starts at line 392 and runs through line 652; it still says the false
  `grep ... returns 0` claim, omits `classification.status`, calls the reproducing seed a negative
  control, leaves Phase 4's failure semantics ambiguous, and retains Phase 6
  (`relay-system/2026-08-21/gh141-fuzz-ate-qa.md:391-392,470-477,491-494,553-570,587-594`). The Setup
  then says “the embedded text above IS the issue body,” making the stale copy part of the named
  artifact rather than recognizable history (`relay-system/2026-08-21/gh141-fuzz-ate-qa.md:653-656`).
  Delete the stale lines 392-652 and retain exactly one four-backtick-fenced current body before the
  Source bullets. Preserve the historical versions in the Log, where their dispositions already live.

**Current-State evidence sweep**

- [Pass] The current runner, selection, caller, inventory, and GH-57 claims are accurate: the runner
  defaults to `test/synthetic`, executes sorted discovered shell files, and emits the stated record;
  the regression is the only test invocation; GH-57 is registered; and the registry contains 230
  entries (`utils/fuzzing/fuzz-loop.sh:8,44-50,74-107`,
  `test/synthetic/gh102-telemetry-schema.sh:28-34`, `validate.sh:55-278`). The independently counted
  inventory is 252 shell files under `test/`, 235 top-level, and 11 synthetic.
- [Pass] The revised telemetry accounting is now internally consistent. The emitter has 15 top-level
  keys and four nested classification keys; nested status, severity, and cause are deterministic
  functions of top-level status, while category is constant
  (`utils/fuzzing/fuzz-loop.sh:63-71,78-98`). Across the cited committed corpus, all 27 rows are pass/0
  with nested pass/none/null, while run ID, timestamp, test identity/path, and duration vary
  (`TESTS-RESULTS/2026-08-20+GH-101/fuzz_telemetry.jsonl:1-19`,
  `TESTS-RESULTS/2026-08-20+GH-102/fuzz_telemetry.jsonl:1-8`).
- [Pass] The ATE volume, execution-history, activation-cost, generic-grid, and local-receipt claims
  survive the sweep: the committed files contain 1,935 + 42 + 438 ATE rows; the two summaries record
  the first two runs; and both repo-code grids use argv-list `command_template` plus generic
  `variation_keys` (`TESTS-RESULTS/2026-08-20+GH-101/SUMMARY.md:12-19`,
  `TESTS-RESULTS/2026-08-20+GH-102/SUMMARY.md:22-29`,
  `utils/ate/variations.tool-calling.yaml:6-20`, `utils/ate/variations.tool-density.yaml:6-21`,
  `utils/ate/scripts/run_variations.py:120-146,443-452`). The body correctly marks the absence of a
  live auto-file receipt unverified rather than pretending a repository search proves it.
- [Should] **Finish the Definition-of-Done citation sweep in the current body.** Its favorable
  Current-State sentence asserts drift triggers, a check-in loop, auto-chained rollup, and GH-195
  destructive-reset guards without citations
  (`relay-system/2026-08-21/gh141-fuzz-ate-qa.md:184-190`). Add source citations for those four pieces
  or narrow the sentence to the already cited generic-retargeting and GH-102 invariant claims. The
  Definition of Done requires every Current-State claim to be cited or marked wrong
  (`relay-system/2026-08-21/gh141-fuzz-ate-qa.md:678-686`).

**Phase grades**

- [Pass] **Phase 1.** Membership must consume one authoritative selector and the parity regression
  makes “opt-in telemetry” a real view rather than renamed duplicate discovery
  (`relay-system/2026-08-21/gh141-fuzz-ate-qa.md:197-213`).
- [Pass] **Phase 2.** The phase now includes consumer/schema compatibility and explicitly covers
  nested status; the cited consumer really does read only the nested classification contract
  (`utils/ate/scripts/compile_issue.py:39-49`).
- [Pass] **Phase 3.** Python placement, argv lists, four generators/oracles, tiered full-clone use,
  replay metadata, positive reproducing controls, and negative patched controls form a credible
  2–4-day scope (`relay-system/2026-08-21/gh141-fuzz-ate-qa.md:234-257`).
- [Pass] **Phase 4.** The three observable outcomes now expose the shipped false-success path:
  `compile_issue.py` falls through after a failed `gh`, while `file_issue()` warns and its caller
  ignores the result (`utils/ate/scripts/compile_issue.py:94-97,119-125`,
  `utils/ate/scripts/run_variations.py:348-364,534-541`).
- [Pass] **Phase 5.** Default-neutral configurable labels plus an explicit Aider opt-in close the
  genericization gap; the current default is indeed `bug,aider-pipeline`
  (`utils/ate/scripts/compile_issue.py:87-92`).

**Brainstorm and scope**

- [Pass] The current body contains five costed ideas, named recommendations for all three open
  questions, and a reasoned cut of the live-issue Phase 4
  (`relay-system/2026-08-21/gh141-fuzz-ate-qa.md:329-351,362-379`). Moving the tick/relay state-machine
  work to a linked issue keeps the useful incidence comparison without making GH-141 own a second
  target and isolation model (`relay-system/2026-08-21/gh141-fuzz-ate-qa.md:313-327`).

Handing off to Producer — go to the claude-a window and say “take your turn”.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
