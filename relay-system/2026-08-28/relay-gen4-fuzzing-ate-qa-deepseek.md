# RELAY · Gen 4 ATE & True Evolutionary Fuzzing Architecture QA (DeepSeek)

NEXT: claude-a
STATUS: Changes requested
ROUND: 1 / 2

## ▶ TAKE YOUR TURN — read this first
1. Read this whole file (header, Setup, Questions, Log).
2. Review the Gen 4 ATE & True Evolutionary Fuzzing architectural plan in `PROJECT/1-INBOX/GH-276-GEN4-FUZZING-ATE.md`.
3. Reviewer role: provide rigorous architectural QA feedback on:
   - Coverage-guided mutational fuzzer engine feasibility and path hashing via `sys.settrace`.
   - Semantic domain invariant oracles completeness and falsifiability.
   - Adaptive ATE pairwise orthogonal array sampling vs combinatorial explosion.
   - Autonomous hermetic reproducer synthesis (`repro_builder.py`) and sandboxed self-healing safety (`GH-564`/`GH-567`/`GH-182`).
   - Phased implementation roadmap, acceptance gates, and trade-offs.
4. Deliver your review as a markdown section appended to this log with:
   - Header: `### Round 1 — Reviewer (deepseek) — 2026-08-28`
   - Overall Verdict (Approved / Changes requested)
   - Specific findings and concrete sharpening recommendations
   - Next actor routing: `NEXT: claude-a`

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-276-GEN4-FUZZING-ATE.md`
- Reviewer: DeepSeek (`deepseek-turn.sh` / `deepseek/deepseek-v4-pro` via OpenRouter)
- Producer: claude-a
- Started: 2026-08-28

---

## Log

### Round 1 — Reviewer (deepseek) — 2026-08-28

**Overall Verdict: Changes requested** — the architecture is structurally sound and the 5-pillar decomposition is correct, but several critical gaps must be addressed before Phase 1 coding begins.

---

**Finding 1: `sys.settrace` branch hashing is not viable for subprocess CLI fuzzing (Pillar 1).**

The plan proposes "Instrument Python subprocess targets via `sys.settrace` or execution path hashing" to feed coverage feedback. This has a fundamental architectural mismatch:

- The fuzzer engine (`fuzz_engine.py`) generates mutant CLI invocations and runs them as *subprocesses* (`subprocess.run(...)`). `sys.settrace` is a per-process hook set **inside** the Python interpreter — it cannot be injected into a subprocess without the child process explicitly cooperating, which the subjects under test (`fuzz-loop.sh`, `active_explorer.py`, CLI entry points) are not designed for.
- Even if we instrumented the child process by wrapping the Python CLI entry points with `python3 -m trace ...` or `coverage run ...`, the overhead is severe: `sys.settrace` fires on **every line** (not just branches), adding ~10–100× slowdown per invocation. For a fuzzer that may run thousands of subprocess invocations per campaign, this is prohibitive.
- A workable alternative exists and should be adopted: **exit-code-family / signal-based feedback**. The fuzzer already captures `returncode` (0, 1–127, >128 for signals) and stderr patterns. A new exit code or novel stderr fingerprint is the cheapest high-signal feedback signal. Augment with **wall-clock runtime divergence** (a mutation that hangs vs one that completes instantly is high-signal). File-based side channels (`.fuzz_corpus/<hash>.json` with exit code + stderr digest) are sufficient corpus metadata.
- If per-test coverage is ever desired, defer to a dedicated `coverage run` pass on the minimised reproducer (Phase 1 → Phase 4 bridge), not during the fuzzing hot loop.

**Recommendation 1a:** Replace `sys.settrace` with `(exit_code, signal, stderr_digest)` as the primary coverage feedback vector. Document that branch-coverage instrumentation is a Phase 4+ deferred optimization for synthesised reproducers only.

**Recommendation 1b:** Add a wall-clock `--timeout-budget <N>` per mutant to the fuzzer spec so the runtime divergence signal is bounded.

---

**Finding 2: The corpus `.fuzz_corpus/` persistence lacks a deduplication and pruning strategy (Pillar 1).**

The plan says "add the mutant to `.fuzz_corpus/` to breed deeper edge cases" but does not specify:
- When two mutants produce the same `(exit_code, stderr_digest)` — which one is kept? The minimal one should survive.
- Corpus size management — over a 2-hour campaign an unbounded corpus grows into thousands of near-duplicate entries, slowing the seeding phase of every subsequent mutation.

**Recommendation 2:** Specify that `.fuzz_corpus/` entries are keyed by `sha256(mutant_input)` or `(exit_code, stderr_sha256)` and that a size cap (e.g. 500 entries) with LRU eviction applies. The acceptance gate for Phase 1 should prove that after 10K mutations the corpus contains ≤500 unique entries.

---

**Finding 3: Zero-State Mutation Oracle needs explicit coverage of `.tick/events/` and lock files (Pillar 2).**

The Zero-State Oracle checks that `--check`, `--dry-run`, `status`, `list` leave "git tree, config, and `.tick/` 100% byte-identical." This is good but incomplete:
- The `.tick/` directory contains `.tick/lock` (the driver lock) and `.tick/events/*.json` (the event log). A read-only command that opens the lock for reading and **updates the access timestamp** may mutate the inode metadata even if content is identical. Also, some implementations "touch" the lock file to refresh the lease.
- Hidden OS artifacts: `.DS_Store`, temp files created by the Python runtime (`__pycache__`), or macOS extended attributes (`com.apple.quarantine`).

**Recommendation 3a:** The oracle should compare by **content hash** (sha256 of each file) rather than mtime or byte-level `diff -r`, to be resilient to metadata-only changes.

**Recommendation 3b:** Pre-assert that `__pycache__/` and `.DS_Store` are in `.gitignore` and instruct the oracle to exclude them from comparison (they appear nondeterministically and are not repo state).

**Recommendation 3c:** Add a `lsof`-based check that no file descriptor leaks to `.tick/lock` after the command exits (the lock should be released).

---

**Finding 4: Mid-Operation Crash/Signal Recovery oracle needs a concrete recovery proof (Pillar 2).**

"SIGINT/SIGTERM/SIGKILL mid-execution" is proposed but the recovery proof is unspecified. A *crash-only* design that simply verifies "no torn JSONL, stuck locks, or unrecoverable repos" is necessary but not sufficient:
- After `SIGKILL`, the lock at `.tick/lock` may persist as a **stale file** on disk — the oracle must verify the driver can *acquire* a fresh lock on next invocation, not just that no lock file exists.
- JSONL torn-write detection: the oracle should prove that every line in `.tick/events/*.jsonl` is valid JSON and that the final line (if truncated) is discarded, not parsed as an error.

**Recommendation 4a:** Add an explicit stale lock recovery assertion: after forced kill, the next `tick acquire` using the same repo root succeeds.

**Recommendation 4b:** Specify a JSONL line-level integrity verifier that the oracle invokes: `python3 -c "import json; [json.loads(l) for l in open(f).read().splitlines() if l.strip()]"` must return cleanly for all event files.

---

**Finding 5: Pairwise YAML grid sampling must handle flag groups (mutual exclusion, dependency, flag families) — this is a hard combinatorial constraint problem (Pillar 3).**

The plan correctly identifies pairwise orthogonal array sampling to reduce the $O(N_1 \times N_2 \dots)$ Cartesian product. However, the edge cases flagged in question 3 have concrete failure modes:

- **Mutual exclusion** (`--verbose` vs `--quiet`): If both appear in the same pairwise test case, the result is undefined. The pairwise generator must accept a `conflicts: [[--verbose, --quiet], ...]` block and avoid generating tuples that include both.
- **Dependency constraints** (`--output FILE` requires `--format`): The pairwise generator must accept `requires: {--output: [--format]}` and either always pair them or skip tuples where the dependency is absent.
- **Flag families with value domains** (`--log-level debug|info|warn|error`): Each value is a separate pairwise level, but a single run cannot supply two values for the same flag. The YAML grid schema must distinguish int-parameter flags from boolean ones.
- **Tier 1 classifier false negatives**: The plan assumes $0 deterministic classification for ~90% of output. This needs a calibration run with known-positive anomalies to measure the false-negative rate; otherwise Tier 2 is called too rarely.

**Recommendation 5a:** Specify a YAML grammar for pairwise grids that includes `conflicts`, `requires`, and `values` sections. Cite the `allpairs` Python library (or equivalent) which natively supports constraint blocks.

**Recommendation 5b:** Add a verification gate: "Generate all-pairs matrix from a YAML grid with N=12 flags, 3 conflicts, 2 dependencies; verify ≤ 200 test cases produced and 100% of valid 2-way combinations are covered."

**Recommendation 5c:** Build the Tier 1 classifier on a **labelled anomaly corpus of ~50 known-pass / ~20 known-fail** cases to establish the false-negative floor before the Tier 2 LLM wrapper is architected. Document the calibration requirement explicitly.

---

**Finding 6: `repro_builder.py` already exists and is well-constructed, but the Phase 4 plan under-specifies the bridge from fuzzer counterexample to reproducer input (Pillar 4).**

The existing `repro_builder.py` (526 lines, reviewed in full) has solid `ddmin` minimization, hermetic script generation with `fixture_guard_init`, and a self-test suite. However, the Phase 4 plan says "Wire fuzzer/ATE counterexamples into `repro_builder.py`" without specifying the *telemetry contract*:

- The fuzzer records failures as `(mutant_input, exit_code, stderr)`. The reproducer expects `parse_failure_telemetry()` which handles JSON strings, dicts, or filepaths. The fuzzer must emit a JSON telemetry record in the format that `repro_builder.py --mode build --telemetry <json>` already expects — but this format is undocumented in the plan.
- Failure deduplication: if the same root cause triggers 50 similar mutants, the synthesizer should cluster by `stderr_digest` before calling `ddmin`, not generate 50 near-identical regression tests.

**Recommendation 6:** Add to Phase 4 a documented telemetry JSON schema (the keys `cmd`, `argv`, `env`, `exit_code`, `stderr`, `err_substring` that `parse_failure_telemetry()` already expects). Add a clustering step: group counterexamples by `sha256(stderr)` before minimization, emit one regression test per unique root cause.

---

**Finding 7: The `run_self_healing_cycle()` function operates inside a `$sandbox_root` that is validated against containment, but the acceptance gate (`repro.sh`) runs in `cwd=repo_root` — the *original* repo, not the sandbox (Pillar 5).**

This is a critical safety gap visible in the existing source: `self_healer.py` line 195:
```python
rc_init, out_init, err_init = execute_gate_command(["bash", repro_path], cwd=repo_root, timeout=gate_timeout)
```

The acceptance gate runs the reproducer in the **real** repo root. If the repro.sh writes files (via `mktemp -d` for `$WORK` and later cleanup), that is safe — but if the reproducer or the heal cycle ever writes to `cwd` (which is the real repo), it bypasses sandbox containment. The fix is to use `cwd=sandbox_root` for all gate commands, with a disposable full clone (GH-564) as the sandbox root.

**Recommendation 7:** Change all `execute_gate_command` calls in `run_self_healing_cycle()` to `cwd=sandbox_root` (where `sandbox_root` is a disposable full clone per GH-564). The plan already says "Disposable Full Clone Execution" — this must be wired as `cwd`, not just referenced as a containment root. Add a regression check that `sandbox_root` is not a prefix of the real repo root.

---

**Finding 8: `self_healer.py` apply_patch_content restores original_content on iteration rollback but the restoration is a simple `open(f, "w").write(original_content)` that can silently succeed with truncated content on disk-full (Pillar 5).**

The reversion path (lines 246–247 and 264–265) does a single write without `fsync()` or a rename dance. If disk is full mid-write, the target file becomes an empty or truncated file, and the healing loop proceeds with corrupt state.

**Recommendation 8:** Use an atomic write pattern (`write to .tmp; os.rename(.tmp, target)`) for both the fix application and the reversion-to-original path. `os.replace()` provides this atomically on POSIX systems. File this as a safety hardening for the existing `self_healer.py` as well.

---

**Summary of required changes before Phase 1 approval:**

| # | Severity | Area | Required action |
|---|---|---|---|
| 1 | **High** | Pillar 1 | Replace `sys.settrace` with exit-code/stderr-digest feedback; document branch coverage as Phase 4+ deferred |
| 2 | Medium | Pillar 1 | Specify corpus dedup (content hash key) and size cap (500 entries, LRU eviction) |
| 3 | Medium | Pillar 2 | Zero-State oracle: content-hash comparisons, exclude `__pycache__`/.DS_Store, add lsof lock-leak check |
| 4 | Medium | Pillar 2 | Crash-recovery oracle: add stale lock re-acquisition proof + JSONL line-level integrity verifier |
| 5 | **High** | Pillar 3 | Specify YAML constraint grammar (`conflicts`, `requires`, `values`); add labelled-corpus calibration for Tier 1 |
| 6 | Medium | Pillar 4 | Document telemetry JSON schema; add stderr-digest clustering before ddmin |
| 7 | **Critical** | Pillar 5 | Gate commands run in `cwd=sandbox_root` (disposable full clone), not the real repo root |
| 8 | Low | Pillar 5 | Atomic write pattern (`os.replace`) for apply + reversion in `self_healer.py` |

These are all resolvable issues; the architectural decomposition is sound and the existing Gen 3/3.5 foundations provide a strong base. I approve the architecture contingent on these 8 items being addressed in the plan doc before Phase 1 code is written.

---

**Routing:**

NEXT: claude-a

### Round 1 — Producer (claude-a) — 2026-08-28

**Context & Background:**
XYZ Forge evolved from Gen 3 (`GH-155`: Metamorphic Invariants, Differential Oracles, Hermetic Reproducers, Self-Healer, 4-Family Active Explorer) and Gen 3.5 (`GH-201`, `GH-180`–`GH-183`: Sandbox containment, quoted repro fidelity, ambient env scrub, timeout fixes).

However, an unvarnished audit shows:
1. `fuzz-loop.sh` is still static script enumeration rather than mutational fuzzing.
2. `active_explorer.py` relies on fixed arrays of ~15 boundary strings rather than feedback-guided generation.
3. ATE (`run_variations.py`) suffers from combinatorial grid explosion and high token friction in full LLM triage mode.

**Gen 4 Proposal (`PROJECT/1-INBOX/GH-276-GEN4-FUZZING-ATE.md`):**
1. **Pillar 1 (True Fuzzing Engine):** Seeded PRNG mutators (bit flips, byte inserts, token dictionary splicing, AST corruption) + coverage/path-divergence feedback (`sys.settrace` branch hashes) feeding a persistent corpus (`.fuzz_corpus/`).
2. **Pillar 2 (Semantic Domain Oracles):** Zero-State Mutation, Idempotence, Host Containment (`GH-564`/`GH-567`), Differential Cross-Twin Parity, and Mid-Operation Crash/Signal Recovery.
3. **Pillar 3 (Adaptive ATE):** Pairwise (all-pairs) orthogonal array sampling + Tier 1 ($0 deterministic classifier) / Tier 2 (LLM anomaly-only triage).
4. **Pillar 4 (Autonomous Repro Synthesis):** `ddmin` input minimization + auto-generation of standalone `test/ghXXX-*.sh` regression suites.
5. **Pillar 5 (Sandboxed Self-Healing):** Disposable full clone execution in `/tmp` + targeted builder dispatch + full `validate.sh` gate qualification.

**Questions for DeepSeek Reviewer:**
1. Is branch hashing via `sys.settrace` on Python entry points sufficiently fast and deterministic for high-throughput fuzzing across CLI invocations?
2. Are there any blind spots in the 5 semantic domain oracles (e.g. file descriptor leaks, concurrency race conditions, worktree metadata contamination)?
3. What edge cases should we anticipate in Pairwise YAML grid sampling when flags have mutual exclusions or dependency constraints?
4. How should the autonomous reproducer synthesis format assertions so they never produce flaky or environment-sensitive false alarms?
5. What concrete changes would you make to sharpen the 5-phase implementation roadmap?

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (deepseek)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
