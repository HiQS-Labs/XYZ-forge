# RELAY · GH-141 fuzzing + ATE overhaul — plan QA & brainstorm
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-21.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

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
````
## Why

The repo has two subsystems named for fuzzing. Neither fuzzes.

`utils/fuzzing/fuzz-loop.sh` is a second test runner: it `find`s `test/synthetic/*.sh`, runs each with `bash`, and emits JSONL. There is no random input generation, no seed, no corpus, no mutation, no shrinking, and no coverage feedback. `grep -rn 'RANDOM\|shuf\|seed\|urandom' test/synthetic/` returns **0 matches** — every input in the suite is hardcoded.

`utils/ate/` (ATE) is a deterministic Cartesian-product walk over Aider CLI flags, driven by a local Gemma model. `SKILL.md` explicitly instructs keeping the task message "short and deterministic." That is combinatorial variation testing — a legitimate technique, but not fuzzing, and it is aimed at a third-party tool rather than at this harness.

This matters because the repo's actual bug history is fuzz-shaped. Bugs found by hand that a real fuzzer would have found mechanically:

| Issue | Bug class | Fuzzable input |
|---|---|---|
| GH-319 | gate path containing a space | path strings |
| GH-417 | turn-root symlink prefix | path strings |
| GH-307 | gate env scrub leak | environment variables |
| GH-322 | unknown-arg not rejected | argv |
| GH-460 | pipe buffer / SIGPIPE | stream sizes |

Every one of those is "the harness receives a hostile string in argv, env, or a path." That is the single highest-value fuzz surface in this repo, and it is the one surface not being fuzzed.

## Key Concepts

**Fuzzing** — generating semi-random inputs to find crashes and invariant violations, with a seed so any finding is replayable.

**Invariant assertion** — the property a fuzzer checks. For this harness the invariants already exist as GH-94 containment sentinels: never write outside the declared write-set, never exit 0 on an unknown arg, never orphan a process or worktree, never leak a scrubbed env var to stderr.

**Variation testing (ATE)** — walking a defined grid of configurations. Complementary to fuzzing, not a substitute.

**Signal-bearing telemetry** — a field whose value varies with the observation. A constant-valued field is worse than an absent one, because downstream tooling (`checkin.py` percentiles) presents it as if it were signal.

## Current State (evidence)

- `utils/fuzzing/fuzz-loop.sh:1-113` — the whole runner. `find test/synthetic -type f -name '*.sh'` at line 111.
- Not in CI. `.github/workflows/ci.yml` runs `bash "test/$t"` over an explicit list (lines 430, 472). `fuzz-loop.sh` appears in `ci.yml` only inside a comment at line 50, about a previously missing shebang. Its one live caller is a manual step at `SOP.md:68`.
- Scope mismatch: `test/` holds ~230 suites; `test/synthetic/` holds 11; the runner scans only the latter. `test/gh57-releases-fuzz.sh` — the 42-assertion suite whose name is "fuzz", built for GH-57 per `HARNESS-MODELS-REGISTRY.md:28` — lives in `test/` and is therefore **never run by fuzz-loop**. Two things named "fuzz" that do not touch each other.
- Classification is constant. `fuzz-loop.sh:70-76` sets unconditionally: pass → `severity: "none"`; fail → `severity: "high"`, `likely_cause: "synthetic_invariant_failure"`, `category: "deterministic_synthetic_fuzz"`. `category` is the same string on every record; `severity` restates the exit code; `likely_cause` restates `status`. Token fields are always `null` with `tokens_source: "unsupported"`. Of 12 fields, ~4 carry information.
- Corpus volume: **27 JSONL rows total** on disk, across `TESTS-RESULTS/2026-08-20+GH-101/` and `TESTS-RESULTS/2026-08-20+GH-102/`. Not enough for the percentile tooling GH-102 shipped to say anything.
- ATE has never produced its output. `grep -rn 'ATE - \['` across the repo: **0 matches**. `compile_issue.py` has never filed an issue. The one `error_log.jsonl` receipt (`TESTS-RESULTS/2026-08-20+GH-94/`) is from telemetry-schema work, not from a real overnight run. Activation cost is high — LM Studio + a 31B local model + an OpenRouter key + aider + hours of wall clock — for output nobody has consumed.

To be explicit about what is *good* here: the GH-102 telemetry schema is sound, and ATE's design (drift triggers, check-in loop, auto-chained severity-ranked issue, the GH-195 destructive-reset guards) is genuinely well thought out. The problem is not build quality. It is that the fuzz side has no signal flowing through a good schema, and the ATE side has a good engine pointed at the wrong target.

## Proposed Work

Ordered by value/effort. Phases 1–2 are the honesty fixes; Phase 3 is the capability; Phases 4–5 are the ATE decision.

### Phase 1 — Stop the system misrepresenting itself (~20 min)

Wire the synthetic suites into CI or retire the separate runner. Recommended: add `test/synthetic/*.sh` to the existing CI test list next to the other 230 suites, and keep `fuzz-loop.sh` only as the JSONL emitter rather than as a parallel runner. If the runner is kept as-is, change its default scan root from `test/synthetic/` to `test/` so `test/gh57-releases-fuzz.sh` stops being orphaned.

Acceptance: synthetic suites run on every CI job; no suite named "fuzz" is unreachable from any runner.

### Phase 2 — Make classification real, or delete it (~1 hr)

Either derive `likely_cause` from stderr — `timeout`, `permission`, `not found`, `assertion`, `traceback` are five cheap regexes — or remove `likely_cause`, `category`, and `severity` from the fuzz record entirely. Do not keep constants in a schema that feeds percentile tooling.

Acceptance: every field in the emitted record either varies across a mixed pass/fail run, or is gone.

### Phase 3 — Build an actual fuzzer over the harness input surface (~half day)

New `utils/fuzzing/fuzz-args.sh`, reusing the GH-94 containment sentinels as its oracle.

```
utils/fuzzing/fuzz-args.sh --seed N --target agy-turn.sh --iterations 200
```

Mutation alphabet drawn from the repo's own bug history: spaces, unicode, `..`, `~`, `$(...)`, backticks, newlines, NUL bytes, very long strings, empty strings, leading dashes, symlinked paths.

Per-iteration invariants (assert properties, not "did it exit 0"):

- never writes outside the declared write-set
- never exits 0 on an unknown argument
- never leaves an orphaned process or worktree
- stderr never contains a scrubbed environment variable

The seed is printed on every failure so any finding replays with `--seed <n>`. Findings emit into the existing GH-102 schema, where `severity` and `likely_cause` will finally vary.

Acceptance: a deliberately reintroduced GH-319-class bug (space in path) is caught by the fuzzer within N iterations, and the failure replays deterministically from the printed seed.

### Phase 4 — Prove the ATE chain end to end (~20 min of wall clock)

Before changing ATE, run it once with `--minutes 20` against a scratch repo and let it file its issue. `run_variations.py` → `compile_issue.py` → `gh issue create` has never completed in production. This either produces the first `ATE - [...]` issue or exposes where the chain breaks.

Acceptance: one `ATE - [...]` issue exists, or a bug report on the chain does.

### Phase 5 — Re-point ATE at this harness, or archive it honestly (~half day)

The ATE machinery — grid, drift detection, check-in loop, auto-issue rollup — is model-agnostic and is the valuable part. Swap the grid from Aider flags to `agy-turn.sh` / `codex-turn.sh` / `claude-turn.sh` flag combinations and it becomes a long-running soak test for what this repo actually ships. `compile_issue.py` needs no changes.

If nobody intends to consume ATE's output, archive `utils/ate/` explicitly rather than letting 545 lines of `run_variations.py` decay in place. Either outcome is fine; leaving it ambiguous is not.

Acceptance: ATE either has a variations file targeting this repo's turn shims, or is archived with a note saying why.

## Anti-Goals

- Not building a coverage-guided fuzzer (AFL/libFuzzer style). These are shell scripts; a seeded mutation fuzzer with invariant oracles is the right tier.
- Not fuzzing the LLM turn content. The target is the harness's argv/env/path handling, which is deterministic and assertable.
- Not deleting ATE reflexively. Phase 4 exists specifically to test it before judging it.
- Not expanding the GH-102 telemetry schema. The schema is fine; the problem is the values.

## Open Questions

1. Phase 1 — fold the synthetic suites into CI's main list, or keep `fuzz-loop.sh` as a distinct CI job? Folding them in is simpler; a distinct job keeps the JSONL emission path clean.
2. Phase 3 — should fuzz findings auto-file issues (ATE-style rollup), or only fail CI? Auto-filing risks noise before the invariants are tuned.
3. Phase 5 — is there a real consumer for an overnight soak test of the turn shims, or is the honest answer to archive ATE?

## Notes

- `fuzz_queue.txt` at the repo root is empty (0 bytes). `pop-and-run-agy.sh:14` guards on `-s` so it exits cleanly, but that file plus `fuzz-agy-plan.sh` looks like a stalled workflow inherited from the xyz-3-agents-swarm era. Worth a separate decision.
- `utils/fuzzing/` and `utils/ate/scripts/` are both in the codebase-memory indexer's exclude list, so graph queries do not see either subsystem.
- `fuzz-loop.sh` shells out to `python3` twice per test purely to get a millisecond timestamp. Acceptable at 11 tests; not at 230, which Phase 1 may make relevant.
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
