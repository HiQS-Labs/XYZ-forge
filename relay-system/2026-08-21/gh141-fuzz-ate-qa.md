# RELAY · GH-141 fuzzing + ATE overhaul — plan QA & brainstorm
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-21.
-->

NEXT: Reviewer
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
