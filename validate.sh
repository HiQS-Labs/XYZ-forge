#!/usr/bin/env bash
# Aggregate runner for all tick acceptance tests.
# Exit 0 = all pass; Exit 1 = at least one failed.
set -u

# GH-441 Phase 2: clean the ambient variables a live marathon exports, via the shared contract rather
# than a list copied here. This file used to hardcode six names; the driver popped three DIFFERENT
# ones, and any other --pre-advance-cmd that forgot the prologue was silently wrong. One did, on
# 2026-08-07, and cost two marathon rounds. utils/py/gate_env.py is now the single registry, and
# test/gh441-gate-env-contract.sh fails if a new driver export is left unclassified.
# NOTE: RELAY_DRIVER_LOCKED is deliberately NOT scrubbed — see gate_env.py's docstring.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/relay-automation/gate-env.sh"

HERE="$(cd "$(dirname "$0")" && pwd)"
TESTS=(
  "projection-idempotent.sh"
  "concurrent-claim.sh"
  "chaos-stale-writer.sh"
  "chaos-concurrent-pollers.sh"
  "chaos-midturn-kill.sh"
  "path-overlap.sh"
  "scope-change.sh"
  "tick-foreign-cwd.sh"
  "handoff.sh"
  "handoff-exclusive.sh"
  "circuit-break.sh"
  "terminality-seal.sh"          # GH-41 (terminal seal edge cases — cross-model review of PR #99)
  "auto-sync.sh"
  "analyze.sh"
  "workstealing-verdict.sh"      # GH-4 (work-stealing via take + lane-count-independent verdict)
  "verdict-edge.sh"              # GH-4 (verdict/collision edge cases — cross-model review of PR #101)
  "claim-cap.sh"
  "reap.sh"
  "heartbeat.sh"
  "cost.sh"
  "take.sh"
  "watchdog-liveness.sh"
  "runner-loop.sh"
  "poll-driver.sh"
  "relay-loop.sh"
  "poll-relay.sh"
  "watchdog-relay.sh"
  "codex-turn.sh"
  "agy-turn.sh"
  "pi-turn.sh"                   # GH-295 (Pi/pi.dev headless turn-taker: PI_MODEL safety + cost capture)
  "relay-turn-trace.sh"          # GH-161 (rtl_trace/rtl_log_always/rtl_default_log instrumentation)
  "aider-turn.sh"
  "gh278-turn-timeout-parity.sh" # GH-278 (Aider Python/Bash/doc timeout default must stay aligned)
  "gh308-frozen-twin-guard.sh"  # GH-308 (Python-authoritative twins: banner + committed-change guard)
  "ate-run-variations.sh"       # GH-195 (ATE fuzzer git helpers: base-commit/disposable-guard/reset/detect-edit)
  "model-alias.sh"              # GH-120 (OpenRouter model-alias fuzzy lookup)
  "swe-diagram.sh"              # GH-146 (hub-ring layout ring-balance math + search/filter matching)
  "claude-turn.sh"             # GH-58
  "worktree-isolation.sh"
  "shim-worktree.sh"
  "marathon-yaml.sh"
  "gh391-emit-marathon-yaml.sh" # GH-391 (ranked plan + packets -> runnable MARATHON.yaml; missing-packet control)
  "marathon-drive.sh"
  "gh284-runlog-heartbeat.sh"   # GH-284 (driver heartbeat + opt-in idempotent run log)
  "gh307-gate-env-scrub.sh"      # GH-307 (pre-advance gate must not inherit run-identity tags)
  "gh319-gate-path-with-space.sh" # GH-319 (default gate must not word-split a spaced repo path)
  "gh320-twin-timeout-parity.sh" # GH-320 (Python twin turn-timeout defaults must match Bash + docs)
  "gh322-unknown-arg-rejection.sh" # GH-322 (Python lane must reject unknown flags, not discard them)
  "gh322-runlog-python-lane.sh"  # GH-322 (GH-284 P2 heartbeat + run log on the lane that actually runs)
  "gh331-cost-summary.sh"        # GH-331/GH-308 (end-of-run tick-analyze cost summary on the default Python lane)
  "gh308-poll-guards.sh"         # GH-308 (poll.py: --help/--mode/--turn-source/positional guards, GH-92 warning, watchdog default)
  "gh308-swarm-gate-path.sh"     # GH-308 (swarm_preflight.py: uninstalled node/npm/python3 gate program → NOT-READY)
  "gh343-gate-program-target-root.sh" # GH-343 (target-relative direct gate programs resolve from target_root)
  "gh308-consult-guards.sh"      # GH-308 (consult.py: agy isolation-breach detector + codex ATTESTATION header)
  "gh308-turn-shim-parity.sh"    # GH-308 (claude drift brief + turn-shim ROOT resolution + agy TICK_REPO_ROOT propagation)
  "gh342-sentinel-debug-log-python.sh" # GH-342/GH-281 (Sentinel Tier-1 XYZ_DEBUG_LOG capture on the default Python lane)
  "gh369-find-doc-root-resolution.sh"  # GH-369/GH-344 (find-doc.sh resolves PROJECT/** from the SWEPT repo; --root arg-parse guards)
  "gh400-acceptance-fidelity.sh" # GH-400 (a capture doc's acceptance block must be the issue's, or declare each deviation)
  "gh557-unknown-blocks-manifest.sh" # GH-557 (an `unknown` acceptance verdict blocks on a FROZEN MANIFEST member when the cause is structural — the issue states no criteria — and stays advisory everywhere else) — 16/0; control in test/baselines/GH-557-negative-control.md: 5 pass / 11 fail pre-fix, with the pin observed as `expected exit 5, got 0`. The three assertions that PASS pre-fix are the point: a detector that refused every acceptance-less issue would satisfy the pin and break ordinary lanes, and an outage must never block
  "gh400-source-url.sh"          # GH-400 criterion 2 (a capture doc must cite its issue's URL) — 13/0 post-fix, observed 2/11 pre-fix
  "gh419-gate-inventory.sh"      # GH-419 (generated decision-gate inventory; declared negative-control evidence)
  "litmus-release.sh"            # Litmus 0.2.0 frozen-manifest audit. Suite mode fails ONLY on a false completion claim (a CLOSED manifest issue whose gate is missing/unregistered/undeclared); remaining work is INFO. The goalpost itself is `--release-gate` (red until done). Control: `--mutate-evidence` 9/0 — NOT run by this suite; run it by hand when touching audit_entry
  "gh418-issue-state-frozen.sh"  # GH-418 (issue state is advisory; on-disk GH-308 FROZEN banner blocks writes)
  "gh422-backfill-source-url.sh" # GH-422 (self-remediating message + bulk backfill) — 18/0; controls: pre-fix replay 15/3, conflict-guard mutation 16/2
  "gh425-source-url-slug.sh" # GH-425 (source URL validates tracking repository + issue number; `related:` preserves foreign origin)
  "gh410-containment-advisory.sh" # GH-410 (prose scan demoted to advisory; worktree_end stays the verdict) — 11/0; controls: pre-fix replay 7/4, containment-deleted mutation 9/2
  "gh399-packet-acceptance-continuation.sh" # GH-399 (the packet's acceptance block is a lossless copy: continuations, scope, cap)
  "gh417-turn-root-symlink-prefix.sh" # GH-417 (--show-toplevel is safe as resolve_turn_root's default: a Python turn with *_TURN_ROOT unset, from a repo behind a symlinked prefix, is not reverted) — 13/0; control: reverting GH-261's canonicalization brings exit 6 back, and the same reverted tree passes with a logical-form ROOT
  "gh390-gate-guard.sh"          # GH-390/GH-382 (gate resource guard: wall/CPU/RSS caps, gate-killed escalation, off switch)
  "gh457-gate-tiers.sh"         # GH-457 (the gate's caps come from a declared TIER; the default tier must exceed the worst observed real gate runtime) — 10/0; control: mutating the registry moves the resolved cap, restoring it moves back
  "gh407-gate-ran-attribution.sh" # GH-407 (pre-advance-failed is reserved for a gate that RAN; every escalation records gate: not-run|green|red) — 7/0; control: pre-fix replay reproduces the mislabel inside the fixture
  "gh390-timeout-attribution.sh" # GH-390 (exit-7 attribution: dialog vs runaway vs slow vs wedged)
  "gh387-gate-not-first-executor.sh" # GH-387 (a timed-out turn's artifact is reviewed BEFORE any gate
                                 #   executes it) — 9/0. The gate LOGS every invocation, because the
                                 #   outcome alone cannot distinguish the fix: with a green gate the
                                 #   phase completes either way. Pre-fix replay: restoring the probe
                                 #   makes the gate run TWICE and the pin fails 7/2.
                                 #   test/marathon.sh's GH-205 cases are the non-regression CONTROL,
                                 #   not the pin — they pass with OR without the probe, which is
                                 #   exactly why this file exists.
  "gh492-idle-kill.sh"           # GH-492 (a blocked turn is killed on an IDLE threshold, not only at the
                                 #   wall cap) — 16/0, covering both surfaces: agy-turn.py and consult.py.
                                 #   The NEGATIVE CONTROLS are the point, because a trigger-happy bound is
                                 #   worse than the hang it replaces — it kills reviewer turns, and a dead
                                 #   reviewer turn takes a VERDICT with it. (1) a slow-but-progressing turn
                                 #   must NOT be killed: measured 0.06s idle vs the blocked turn's 4.09s.
                                 #   (2) consult scoping is pinned BOTH ways — a hung advisor reads 2.99s
                                 #   idle scoped to its own pid and 0.14s under the shared parent, so the
                                 #   case cannot pass on a build where scoping does nothing.
                                 #   Behavioural mutation (not just a missing symbol): dropping worktree
                                 #   progress from the idle signal makes the control fail, which is exactly
                                 #   what a trigger-happy bound looks like.
  "gh432-failed-turn-persist.sh" # GH-432 (a failed turn still reaches rtl_enforce: commit + token handoff; both routes) — 12/0 post-fix, control 5/4 pre-fix
  "gh441-gate-env-contract.sh"   # GH-441 P2 (every driver export is classified scrub-or-pass; custom gates get the same clean env) — 13/0; controls: unhelped gate contaminated, orphaned helper fails loud
  "gh448-driver-lock-resolver.sh" # GH-448 (shared driver-lock resolver: bash/python parity + linked-worktree LIVE, real worktree fixture; negative control: pre-fix 2-branch logic misses the lock)
  "gh376-relay-drive-lock-parity.sh" # GH-376 (the DRIVER-side half of #448: relay-drive's own two twins
                                 #   now resolve the lock through that shared resolver, so a relay driver
                                 #   and a marathon driver actually exclude from a linked worktree — the
                                 #   thing marathon-drive.sh:195-196 already claimed in prose) — 18/0.
                                 #   Observable is "does it REFUSE against a lock held at marathon-drive's
                                 #   path", run end-to-end through the real scripts against a real
                                 #   `git worktree add`; the drivers never print the path and the EXIT
                                 #   trap removes the lock, so no filesystem probe can see it.
                                 #   Controls: pre-fix resolution replayed on BOTH lanes sails past the
                                 #   held lock; normal-clone and vendored (no .git) cases unchanged;
                                 #   source guards pin that the resolver is CALLED, never re-inlined.
  "gh397-reviewer-turn-role.sh"  # GH-397 (reviewer scope derived from the tick token + role directive, not agent-maintained NEXT:) — 11/0; control: pre-fix red on the un-flipped-NEXT case
  "gh401-dry-run-no-mutation.sh" # GH-401 (--dry-run writes nothing; render goes to stdout) — 4/0; control: pre-fix red on directory creation. Static half: marathon-root-audit.sh
  "gh375-agy-auth-preflight.sh"  # GH-375 (agy whoami exits 0 without a TTY, so output decides) — 14/0; controls: 5 legitimate auth outputs containing "error" must NOT be rejected
  "gh375-auth-timeout-verdict.sh" # GH-375 follow-up (a timed-out probe is reclassified ONLY on positive evidence of the TTY cause; silence and a login prompt stay fatal) — 11/0; control: pre-fix replay of BOTH callers blocks the TTY-diagnosed timeout, and each replay is compile-checked
  "gh385-retry-token-satisfied.sh" # GH-385 (a phase completed on a --retry suffixed token is satisfied) + GH-491 (--retry on an already-satisfied lane says a plain re-fire would have been gate-only) — 19/0; controls: un-completed recorded token must still rebuild; GH-491 advisory must NOT fire when the recorded token is not done, and must not change --retry's behaviour
  "gh408-tick-failure-visibility.sh" # GH-408 + GH-409 P1 (a failed `tick claim` is detectable by exit status AND readable in the output, at both discard sites) — 22/0; control recorded in test/baselines/GH-408-negative-control.md: 12 red pre-fix. Guards the two directions a naive fix breaks: an idempotent re-claim by the holder must stay exit 0, and a successful tick call must stay silent
  "nightwatch-release.sh"        # Nightwatch 0.3.0 frozen-manifest goalpost. Suite mode fails ONLY on a false completion claim (a CLOSED manifest issue whose gate is missing/unregistered/uncontrolled) or a disagreement with RELEASES.md; remaining work is INFO. The goalpost itself is `--release-gate` (red until done, and it EXECUTES the lifecycle suites rather than auditing them). Control: `--mutate-evidence` 34/0 — NOT run by this suite; run it by hand when touching audit_manifest
  "gh378-gate-requires-green-suite.sh" # GH-378 (pre-advance gate baseline allowance for non-green suites)
  "gh379-claude-builder-diagnosis.sh" # GH-379 (Claude builder failure diagnostics surface in ESCALATION.md)
  "gh380-claude-trust.sh"        # GH-380 (Claude builder warns when target workspace lacks Claude Code trust)
  "gh382-marathon-memory-telemetry.sh" # GH-382 (marathon memory telemetry sampled at phase boundaries and end-of-run)
  "gh491-gate-only-refire.sh"    # GH-491 (gate-only re-fire discoverability under --retry)
  "gh551-resolver-refuses.sh"    # GH-551 (resolver refusal contract: raises instead of defaulting)
  "meter-release.sh"             # Meter 0.6.0 PUBLIC-LAUNCH goalpost (RE-POINTED 2026-08-15; the metering manifest moved to Sundown). Suite mode fails ONLY on a false completion claim (a CLOSED manifest issue whose gate is missing/unregistered/uncontrolled) or a ledger disagreement; remaining work is INFO. The goalpost itself is `--release-gate` (red until the sanitized artifact exists AND a credential-free clone completes the documented happy path; the artifact is named by XYZ_LAUNCH_ARTIFACT). Membership is read from RELEASES.md's machine-readable `Manifest-Members:` field and compared in BOTH directions — the prose `Manifest:` paragraph names RETIRED members and must never be parsed, which is the defect that made the pre-2026-08-15 version report a false GOALPOST MET. Control: `--mutate-evidence` — NOT run by this suite; run it by hand when touching audit_artifact or the cross-check
  "gh402-branch-enforcement.sh"   # GH-402 (a marathon refuses to commit to the RECEIVING repo's shared trunk; --allow-trunk-commit and preflight's risk=1 carve-out are the two documented ways past) — 13/0; control in test/baselines/GH-402-negative-control.md: 8 red pre-fix, with the pre-fix run observed COMMITTING to trunk. Fires only when origin/HEAD resolves — a repo with no remote shares nothing and `git reset` undoes it, asserted as an explicit non-block
  "gh386-turn-budget-honesty.sh"  # GH-386 (one wall-clock default across all five builders on both lanes; the packet's budget names turn_timeout_s, the field marathon.sh actually reads) — 10/0; control in test/baselines/GH-386-negative-control.md: 9 red pre-fix. Part C EXERCISES the shipped sizing ladder and requires every suggestion to be >= the default — the assertion a partial fix (raise the cap, forget the ladder) fails
  "gh514-write-set-trackable.sh"  # GH-514 (the target is proven able to TRACK the run's write-set before dispatch; a hostile ignore rule gets an actionable refusal naming the rule and the remedy, not an unhandled CalledProcessError traceback) — 12/0; control in test/baselines/GH-514-negative-control.md: 6 red pre-fix. Note the corrected framing recorded there: "no dispatch" does NOT discriminate (the render's own git add already dies first) — the traceback assertion does
  "gh426-worktree-leak.sh"       # GH-426 (an isolated turn's creation is absent from BOTH the target and the harness) — 7/0; control in test/baselines/GH-426-negative-control.md: 2 red here + 1 red in gh410's C4c. The reported cause (worktree teardown) is FALSIFIED and the suite pins the real one: the agent binary is invoked twice, and the GH-375 auth probe ran with the caller's CWD, outside containment
  "gh384-crash-recovery.sh"      # GH-384 (marathon-recover.sh actually DISTINGUISHES a gated phase from an ungated one, in one repo, one run) — 19/0; control in test/baselines/GH-384-negative-control.md is a MUTATION pair (the tool already shipped, so there is no pre-fix revision): detection removed → 2 red, verdict decoupled from the approval event → 1 red. Also pins read-only (tree byte-identical) and the STALE/LIVE lock distinction
  "gh388-run-log-durability.sh"  # GH-388 (the harness owns a durable chain run log; a phase KILLED mid-run leaves a content-bearing record; rtl_default_log refuses rather than silently relocating to volatile storage) — 24/0; control in test/baselines/GH-388-negative-control.md: 9 red pre-fix. Part C/D actually kill a running phase and a running chain — a green success path proves nothing on this issue
  "gh409-claim-leak.sh"          # GH-409 P2 (a turn that fails releases its claim, on the three paths that never reach rtl_enforce) — 8/0; control in test/baselines/GH-409-negative-control.md: 4 red pre-fix. Every case fails TWICE before asserting, because the cap is 2 and one leak is invisible
  "gh438-removal-is-progress.sh" # GH-438 PARTIAL (a removal counts as a phase delta) — 6/0; controls: untouched artifact + newly empty file still rejected. fix_probe re-evaluation NOT covered; issue stays open
  "gh438-acceptance-recheck.sh" # GH-438 P2 (the lane's own fix_probes re-read after the build; a still-unfixed probe escalates) — 14/0; controls: fix-really-lands completes, no-contract byte-identical, --dry-run runs none, builder cannot rewrite its own criteria
  "gh467-index-only-lane-blocked.sh" # GH-467 (an undeclared index-only lane BLOCKS before dispatch; the builder git ban stays explicit)
  "hq-marathon-live.sh"          # GH-218 (cross-repo live marathon status)
  "debug-mantra.sh"              # GH-162 (debug-mantra auto-trigger note on a phase's prior attempt)
  "lane-attempt-cap.sh"
  "driver-lock.sh"
  "measure.sh"
  "loop-stop.sh"
  "oracle-guard.sh"
  "champion.sh"
  "heldout-check.sh"
  "loop-cost.sh"
  "improve-loop.sh"
  "improve-loop-qa.sh"
  "improve-loop-dogfood.sh"
  "gh430-state-dir-tracked-default.sh" # GH-430 (STATE_DIR default is a tracked in-repo path, not ${TMPDIR:-/tmp})
  "gh536-evidence-detail.sh"           # GH-536 (the gate-evidence record carries an output hash + per-suite verdicts, so a reader can tell a real run from a stamped one) — 19/0; pins that the NOT-promotion-evidence disclaimer STAYS: a self-computed hash is tamper-evident, not attested
  "gh544-parallel-default.sh"          # GH-544 (parallel is the default; every decline to it is ANNOUNCED with a reason) — 29/0; uses --print-mode so it cannot recurse into the gate it belongs to, and pins the two invariants nothing else pins: ci-local.sh never inherits the default, and ci.yml's macOS boundary passes --sequential explicitly
  "gh544-pre-push-gate.sh"             # GH-544 (the gate moved to the push boundary; hosted CI fires on nothing) — 78/0; drives githooks/pre-push against a STUB validate.sh so it cannot recurse, and stubs `gh` to pin the one state nothing else can produce: a PR with ZERO configured checks must not read as "checks failed"
  "gh1-fixture-guard.sh"               # GH-1 (shared require_fixture resolved-containment + clone-identity invariant gate; covers the GH-567 lexical-check residual)
  "gh314-transcript-writeset.sh"       # GH-314 (the write set is THREE paths: the transcript's git add was outside GH-514's preflight, so an ignored relay-system/ was discovered only after paid turns) — 5/0; control: dropping the transcript path spends 2 builder turns before the same refusal (test/baselines/GH-314-negative-control.md)
  "gh520-default-reviewer-stub.sh"     # GH-520 (test/_setup.sh gives every fixture a default CODEX_BIN, so a suite tests its subject rather than the reviewer probe) — 11/0; control: with gh402's own stub removed AND this default removed, gh402 fails with the probe's message verbatim (test/baselines/GH-520-default-stub-control.md)
  "gh527-destructive-git-guard.sh"     # GH-527 (a tree-overwriting git command snapshots the tracked files it destroys into .tick/orphan-backups/ first) — 26/0; controls: a no-op guard drops 9 assertions, and a blanket that fires on a CLEAN tree drops exactly the control assertion. Clean-tree silence is defended by TWO conditions, so it takes a combined mutation to falsify — recorded in test/baselines/GH-527-negative-control.md
  "marathon.sh"
  "gh484-phase-dir-default.sh"   # GH-484 (phase-output default is marathon-system/; --phases-dir still overrides; the dirty-tree exclusion tracks the CONFIGURED dir) — 10/0; controls: pre-fix red on both defaults and both containment cases, plus a stray-file control proving the clean check actually ran. Forces XYZ_PYTHON=0 so the Bash twin is really exercised
  "marathon-root-audit.sh"       # GH-209 (static audit: every test/marathon*.sh invocation is MARATHON_ROOT-scoped)
  "rtl-orphan-backup.sh"         # GH-141 (concurrent peer-edit race: revert unchanged, content recoverable)
  "consult.sh"
  "deep-research.sh"             # GH-87 (provider-agnostic grounded-search adapter)
  "relay-pkg-freshness.sh"
  "skill-extract.sh"
  "releases-skill.sh"            # consolidated /releases router + Claude-only symlink migration — 26/0.
                                 # RE-REGISTERED 2026-08-15 in the same commit that lands the gate file,
                                 # which is the condition its brief unregistration was waiting on. It was
                                 # disabled for ~2h because the registration reached `development` while
                                 # the file did not, so every clone that did not happen to hold the
                                 # author's uncommitted copy failed the suite with rc=127 — red for
                                 # everyone except the one session that could not see it, and, since
                                 # GH-544 put the suite on the push boundary, refusing every push.
                                 # #461 in mirror image: a gate that exists but is unregistered is
                                 # invisible; a registration with no gate is a permanent red that says
                                 # nothing about the code. Register the two together or neither.
  "path-integrity.sh"
  "relay-turn-timeout.sh"
  "relay-target-root.sh"
  "relay-target-root-paths.sh"
  "relay-target-root-relayfile.sh"
  "relay-target-root-newfile.sh"
  "gh289-target-root-build-turn.sh"  # GH-289 (foreign relay Log: BUILD refuses before discarding it)
  "archive-root.sh"              # GH-30 Phase 1 (transcript-root resolver: unset/set/missing/non-git)
  "archive-writers.sh"           # GH-30 Phase 2 (writers honor the resolver: consult e2e + structural)
  "archive-commit.sh"            # GH-30 Phase 3 (Model A: transcript → archive repo, code+.tick → target)
  "archive-telemetry.sh"         # GH-30 Phase 4 (telemetry reads the resolver: archive aggregation + unset)
  "relay-token-collision.sh"
  "relay-escalation-not-stall.sh"
  "relay-untracked-file-warn.sh"
  "relay-file-seeding-visibility.sh"  # GH-178 B2
  "gh304-vendored-relay-path.sh"      # GH-304 (vendored-.xyz relay path: prompt + seeding + gitignored-file message)
  "relay-review-once.sh"
  "relay-artifact-file.sh"
  "relay-turn-handoff.sh"
  "relay-dep-drift.sh"
  "new-relay.sh"
  "agent2agent.sh"              # GH-497 (compact six-digit rendezvous + serialized 2+ agent routing)
  "gh268-relay-cue-and-target-checks.sh" # GH-268 items 7+8 (handoff cue every turn, reviewer file sweep, target-repo gate)
  "xyz-vendor.sh"
  "xyz-sync-check.sh"            # GH-96 (xyz-sync check: tick_version/source_commit drift report)
  "gh293-vendored-guard-drift.sh" # GH-293 (safety-guard manifest + safe fleet-update source gate)
  "relay-concurrent-commit.sh"
  "relay-commit-pathspec.sh"     # GH-198 (rtl_enforce commit is file-scoped, no pathspec regression)
  "relay-case-insensitive.sh"
  "relay-xyz-skill-guard.sh"
  "find-harness.sh"
  "gh292-worktree-vendored-discovery.sh"  # GH-292 (linked worktree resolves main-checkout .xyz/)
  "pdda-roadmap-coverage.sh"
  "pdda-repo-contract.sh"       # GH-311 (real-repository PDDA deterministic contract)
  "pdda-local-checks.sh"        # the checks the 2026-08-03 PDDA sync deleted, restored outside the sync surface
  "gh460-pipe-buffer-sigpipe.sh" # GH-460 (the tier1 "flake" was a SIGPIPE race against the pipe buffer under pipefail, not a flaky assertion) — 8/0; control: the pre-fix shape exits 141 on a >64KB payload whose marker IS present, and passes on a payload that fits
  "gh284-p3-release-milestone.sh" # GH-284 P3 (RELEASES.md Milestone: join key + the releases check's first test)
  "gh284-p4-release-lanes.sh"   # GH-284 P4 (milestone seed + landed-on-trunk rollup: scope-claim matcher)
  "swarm-preflight.sh"
  "ci-workflow.sh"
  "ci-route.sh"                  # GH-509 (docs/fast/full routing + changed-area test selection)
  "gh509-gate-evidence.sh"       # GH-509 (per-commit local gate record + the operator surface)
  "gh528-parallel-contention-retry.sh" # GH-528 (--parallel re-runs a pooled failure alone before believing it, and names the contended suite; the driver-lock lane list cannot be validated by reading it)
  "xyz-completion.sh"
  "gh358-lock-instrumentation.sh" # GH-358 (concurrent append reports lost writes vs lock starvation)
  "xyz-harness-hooks.sh"
  "preflight-docs.sh"
  "roadmap-dashboard.sh"
  "marathon-plan.sh"
  "hq.sh"                        # GH-128 Phase 1 (HQ resolver + read-only project card)
  "hq-park.sh"                   # GH-128 Phase 2 (HQ issue-first intake writer: preview + --create)
  "hq-park-synthesis.sh"         # GH-164 Phase 1 (fuller PDDA skeleton template + synthesis passthrough + dashboard regen)
  "hq-dispatch.sh"               # GH-128 Phase 3 (HQ queue: append lane · fire: gated hand-off)
  "hq-next.sh"                   # GH-128 Phase 4 (HQ next: Rebalance-priority project board)
  "hq-locator.sh"                # GH-128 Phase 4 (find-hq.sh: device-agnostic locator, user-level /hq)
  "hq-hardening.sh"              # GH-132 (resolution/dispatch hardening: owner/repo, stale-path, YAML, glob)
  "hq-promote.sh"                # GH-138 (HQ promote: 1-INBOX→2-WORKING scaffolder + marathon glob broadening)
  "mktemp-trap-guard.sh"         # GH-177 (static audit: no unguarded mktemp-into-destructive-rm-rf/cd-recapture pattern anywhere in the repo)
  "hq-marathon-scan.sh"          # GH-158 (cross-repo marathon aggregation + preflight — written, never registered until GH-192)
  "hq-rollup.sh"                 # GH-192 (marathon-scan.sh bridged verbatim into the Obsidian daily rollup)
  "transcript-audit.sh"
  "security-scan.sh"
  "sentinel-tier1.sh"           # GH-281 (Tier-1 JSONL finding capture)
  "sentinel-network-guard.sh"   # GH-281 (bundled scripts stay zero-network)
  "sentinel-driver-hooks.sh"    # GH-281 (marathon-drive.sh Tier-1 hooks: default-off + on-mode append)
  "sentinel-overlay.sh"         # GH-281 (Tier-2 overlay: static egress guard + inert-by-default proof)
  "checkjs.sh"
  "acorn-extract.sh"             # GH-169
  "registry-lock-concurrency.sh"
  "marathon-monitor.sh"          # GH-88 (cross-repo marathon monitor)
  "signal-triage.sh"             # GH-63 (signal triage stage)
  # GH-40 double-blind Reviewer canaries — each verify-fixture.sh drives the real kernel and exits
  # 0/1, so it plugs straight in. ponytail: the Gamma canary (test/fixtures/gamma-poison/) is
  # deliberately NOT here — it runs the whole validate.sh itself, so nesting it would recurse; it
  # stays a manual check.
  "fixtures/canary-token-reuse/verify-fixture.sh"
  "fixtures/canary-peer-orphan/verify-fixture.sh"
  "fixtures/canary-reviewer-overstep/verify-fixture.sh"
  "phase3-signoff-guard.sh"
  # Live-agent test — auto-skips when agy/codex not on PATH or RELAY_SELF_SUFFICIENCY_SKIP=1.
  # Set RELAY_SELF_SUFFICIENCY_SKIP=1 in CI / keyless environments to avoid the real API call.
  "relay-self-sufficiency.sh"
)

PASSED=()
FAILED=()

# ── GH-528 / GH-544: parallel is the DEFAULT, with detection and an ANNOUNCED fallback ────────────
# `./validate.sh` (no args) now runs N-wide, where N is detected from the host. It runs the SAME
# TESTS array, with one exception: the suites that execute the REAL relay-automation/relay-drive.sh
# contend on this clone's .git/relay-driver.lock (GH-42 exclusion working as designed —
# "--target-root moves the build, not the lock", see test/gh331-cost-summary.sh), so those run
# sequentially in ONE lane while everything else pools.
#
# Spike numbers (GH-528, 2026-08-13, M-series macOS): sequential 950.3s → 8-wide 167.4s, byte-identical
# pass/fail set. Flipped to the default 2026-08-14 by operator decision (GH-544), because the local
# gate is now the ONLY gate during the private phase and a 16-minute one does not get run — it gets
# skipped, which is a worse outcome than a 3-minute one.
#
# WHAT DID NOT CHANGE, and must not: `ci-local.sh` does NOT call this script. It parses the TESTS
# array and runs each suite in its own sequential loop, and it is the path that writes the gate
# record. So "sequential is the only form that qualifies a claim" (GH-528 Phase 2, GH-509) is still
# true and is still what the record attests. Likewise the macOS promotion boundary in ci.yml pins
# `--sequential` explicitly, so a re-armed boundary cannot silently promote on parallel evidence.
#
# THE FALLBACK IS ANNOUNCED, NEVER SILENT. A gate that quietly downgrades itself teaches you to trust
# a number that is not the one you are getting, so every run prints which mode it chose and why.
#
# Precedence, highest first: --parallel N / --sequential  >  XYZ_VALIDATE_PARALLEL  >  host detection.
PARALLEL_JOBS=""
PARALLEL_WHY=""
FORCE_SEQUENTIAL=0
_usage() { echo "usage: ./validate.sh [--parallel N | --sequential | --print-mode]" >&2; }
PRINT_MODE_ONLY=0
if [ "${1:-}" = "--print-mode" ]; then
  # Resolve the mode, print it, run nothing. Exists so the decision is observable without paying for
  # a gate run — both for test/gh544-parallel-default.sh (which must never execute the real suite)
  # and for a pre-push hook that wants to tell the operator what it is about to do.
  PRINT_MODE_ONLY=1; shift
fi
if [ $# -gt 0 ]; then
  case "$1" in
    --parallel)
      case "${2:-}" in
        ''|*[!0-9]*) echo "validate.sh: --parallel requires an integer >= 1" >&2; exit 2 ;;
      esac
      [ "$2" -ge 1 ] || { echo "validate.sh: --parallel requires an integer >= 1" >&2; exit 2; }
      [ $# -eq 2 ] || { _usage; exit 2; }
      PARALLEL_JOBS="$2"; PARALLEL_WHY="explicit --parallel $2"
      ;;
    --sequential)
      [ $# -eq 1 ] || { _usage; exit 2; }
      FORCE_SEQUENTIAL=1; PARALLEL_WHY="explicit --sequential"
      ;;
    *) _usage; exit 2 ;;
  esac
fi

# XYZ_VALIDATE_PARALLEL=0 forces sequential; a positive integer pins the width. Only consulted when
# no flag was given, so a flag always wins over ambient environment.
if [ "$FORCE_SEQUENTIAL" -eq 0 ] && [ -z "$PARALLEL_JOBS" ]; then
  case "${XYZ_VALIDATE_PARALLEL:-}" in
    '')        : ;;
    0)         FORCE_SEQUENTIAL=1; PARALLEL_WHY="XYZ_VALIDATE_PARALLEL=0" ;;
    *[!0-9]*)  echo "validate.sh: XYZ_VALIDATE_PARALLEL must be an integer >= 0" >&2; exit 2 ;;
    *)         PARALLEL_JOBS="$XYZ_VALIDATE_PARALLEL"
               PARALLEL_WHY="XYZ_VALIDATE_PARALLEL=$XYZ_VALIDATE_PARALLEL" ;;
  esac
fi

# Host detection. Each branch that declines parallelism states its reason, because "it ran
# sequentially" and "it ran sequentially BECAUSE this host has two cores" are different facts.
_detect_cores() {
  if command -v sysctl >/dev/null 2>&1 && sysctl -n hw.ncpu 2>/dev/null; then return 0; fi
  if command -v nproc >/dev/null 2>&1 && nproc 2>/dev/null; then return 0; fi
  if command -v getconf >/dev/null 2>&1 && getconf _NPROCESSORS_ONLN 2>/dev/null; then return 0; fi
  echo 0
}
if [ "$FORCE_SEQUENTIAL" -eq 0 ] && [ -z "$PARALLEL_JOBS" ]; then
  _cores="$(_detect_cores 2>/dev/null | head -1)"
  case "$_cores" in ''|*[!0-9]*) _cores=0 ;; esac
  if ! printf '' | xargs -P 2 -I{} true >/dev/null 2>&1; then
    # Not every xargs implements -P. Falling back is correct; failing here would make the gate
    # unrunnable on a host where the sequential path works perfectly well.
    FORCE_SEQUENTIAL=1; PARALLEL_WHY="this host's xargs does not support -P"
  elif [ "$_cores" -lt 4 ]; then
    # Below 4 cores the pool cannot outrun the serialized driver-lock lane, so parallelism buys
    # contention risk and no wall-clock. Detected, not assumed.
    FORCE_SEQUENTIAL=1
    if [ "$_cores" -eq 0 ]; then PARALLEL_WHY="could not detect a core count on this host"
    else PARALLEL_WHY="only $_cores core(s) detected (parallel needs >= 4)"; fi
  else
    # Leave two cores for the driver-lock lane and the shell itself; cap at 8, the width the GH-528
    # spike actually measured. A wider run is available explicitly, but is not the unattended default.
    _w=$((_cores - 2))
    if [ "$_w" -gt 8 ]; then _w=8; fi
    PARALLEL_JOBS="$_w"; PARALLEL_WHY="auto-detected $_cores cores"
  fi
fi
if [ "$FORCE_SEQUENTIAL" -eq 1 ]; then PARALLEL_JOBS=""; fi
if [ -z "$PARALLEL_JOBS" ]; then
  echo "validate.sh: SEQUENTIAL mode — $PARALLEL_WHY"
fi
if [ "$PRINT_MODE_ONLY" -eq 1 ]; then
  if [ -n "$PARALLEL_JOBS" ]; then
    echo "validate.sh: PARALLEL mode ${PARALLEL_JOBS}-wide — $PARALLEL_WHY"
    echo "  NOT promotion evidence: the qualifying gate is ci-local.sh's sequential run (GH-509)."
  fi
  exit 0
fi

# GH-1: suite-wide clone-identity invariant gate. Captured before any suite runs and asserted after
# the last one — a suite that escapes its fixture sandbox and rewrites this clone's git identity
# (the GH-564 incident: core.bare / origin / user identity / HEAD) fails the run HERE, detectably,
# instead of leaving a clone whose every subsequent green run is unattributable (GH-567). Covers
# the suites that have not yet adopted require_fixture; it detects rather than prevents.
IDENTITY_SNAPSHOT="$(mktemp "${TMPDIR:-/tmp}/validate-identity.XXXXXX")"
[ -n "$IDENTITY_SNAPSHOT" ] && [ -f "$IDENTITY_SNAPSHOT" ] || { echo "validate.sh: mktemp for identity snapshot failed" >&2; exit 1; }
trap 'rm -f "$IDENTITY_SNAPSHOT"' EXIT
bash "$HERE/test/lib/clone-identity.sh" capture "$IDENTITY_SNAPSHOT" "$HERE" || {
  echo "validate.sh: could not capture clone identity — refusing to run the suite blind (GH-1)" >&2
  exit 1
}

# The suites that execute the real relay-drive.sh (not a stub or fixture copy). Membership was
# derived in the GH-528 spike: every suite whose $DRIVE/$DRIVER/$RD resolves to the shipped
# relay-automation/relay-drive.sh. If you add such a suite, add it here too — at 2+ jobs the
# driver lock turns the omission into a deterministic-looking refusal failure, not a flake.
#
# gh322-unknown-arg-rejection.sh was MISSED by that derivation and is the reason the serialized
# re-run below exists. It never "drives" anything — it passes a bogus flag and asserts both twins
# exit 2. But relay-drive.sh acquires the lock at line ~142, BEFORE `usage()` and before it parses
# any argument, so under contention the Bash twin exits 1 (lock refusal) while the Python twin,
# which parses first, still exits 2. The suite then reports "exit codes diverge — Python 2, Bash 1":
# a plausible, on-topic, entirely false parity failure. **Invoking a driver at all is what puts a
# suite in this lane — not invoking it to do work.** That is the trap this list cannot be trusted
# to catch by inspection, which is why an omission must not be able to fail silently.
#
# gh391-emit-marathon-yaml.sh was then found by that safety net rather than by inspection, on the
# first clean run after it was added: it drives `marathon.sh --dry-run`, which reaches marathon-drive
# and the same lock. The net named it, and the run still returned the correct verdict — which is the
# mechanism working as intended, and also the honest reason this list is not trusted on its own.
DRIVER_LOCK_LANE=" gh289-target-root-build-turn.sh gh322-unknown-arg-rejection.sh gh331-cost-summary.sh gh391-emit-marathon-yaml.sh poll-relay.sh relay-artifact-file.sh relay-escalation-not-stall.sh relay-review-once.sh relay-target-root-newfile.sh relay-target-root-paths.sh relay-target-root-relayfile.sh relay-target-root.sh relay-token-collision.sh relay-untracked-file-warn.sh relay-xyz-skill-guard.sh "

if [ -n "$PARALLEL_JOBS" ]; then
  RUN_DIR="$(mktemp -d -t validate-parallel.XXXXXX)"
  # GH-177: mktemp is verified before use, nothing ever cd's into it, and the EXIT trap only
  # removes a re-verified non-empty directory path.
  [ -n "$RUN_DIR" ] && [ -d "$RUN_DIR" ] || { echo "validate.sh: mktemp -d failed" >&2; exit 1; }
  # Covers both this branch's mktemp and the GH-1 identity snapshot (a bare second trap would
  # silently replace the first — bash keeps one EXIT trap).
  trap '[ -n "$RUN_DIR" ] && [ -d "$RUN_DIR" ] && rm -rf "$RUN_DIR"; rm -f "$IDENTITY_SNAPSHOT"' EXIT
  RESULTS="$RUN_DIR/results"
  : > "$RESULTS"
  export VALIDATE_HERE="$HERE" VALIDATE_LOG_DIR="$RUN_DIR" VALIDATE_RESULTS="$RESULTS"

  vp_run_one() {  # <suite> — run one suite against its own log; append "rc suite" to the results file
    local t="$1" log rc
    log="$VALIDATE_LOG_DIR/$(printf '%s' "$t" | tr '/' '_').log"
    if bash "$VALIDATE_HERE/test/$t" >"$log" 2>&1; then rc=0; else rc=$?; fi
    printf '%s %s\n' "$rc" "$t" >> "$VALIDATE_RESULTS"
    echo "[parallel] $t rc=$rc"
  }
  export -f vp_run_one

  # Both lists are derived FROM $TESTS, so the two paths run exactly the same set of suites. The
  # lane is an intersection, not the literal above: iterating $DRIVER_LOCK_LANE directly would run a
  # lane suite even when TESTS does not contain it, so `--parallel` could execute suites the
  # sequential path skips — and the summary would count more results than TOTAL.
  POOL=()
  LANE=()
  for t in "${TESTS[@]}"; do
    case "$DRIVER_LOCK_LANE" in
      *" $t "*) LANE+=("$t") ;;
      *) POOL+=("$t") ;;
    esac
  done

  echo "validate.sh: PARALLEL mode ${PARALLEL_JOBS}-wide — $PARALLEL_WHY"
  echo "  ${#POOL[@]} pooled suites + ${#LANE[@]} in the sequential driver-lock lane (GH-528)"
  echo "  NOT promotion evidence: the qualifying gate is ci-local.sh's sequential run (GH-509)."
  (
    for t in ${LANE[@]+"${LANE[@]}"}; do vp_run_one "$t"; done
  ) &
  LANE_PID=$!
  # `${POOL[@]+...}`: bash 3.2 (what macOS ships) errors on an empty array under `set -u`.
  [ "${#POOL[@]}" -eq 0 ] || printf '%s\n' ${POOL[@]+"${POOL[@]}"} | xargs -P "$PARALLEL_JOBS" -I{} bash -c 'vp_run_one "$@"' _ {}
  wait "$LANE_PID"

  # Every failure is RE-RUN SEQUENTIALLY before it is believed, with the pool drained and the lock
  # lane finished — so the driver lock is free and nothing else is competing for CPU.
  #
  # This exists because the lane list above cannot be verified by reading it. A suite that merely
  # *touches* a driver contends, and its refusal surfaces as whatever assertion happened to be
  # downstream — for gh322 that was a parity mismatch naming two exit codes, which reads exactly like
  # a real product bug. Without this pass, an incomplete lane list makes `--parallel` report failures
  # that sequential does not have, which would destroy the one property the flag is supposed to have:
  # the same answer as the sequential gate, faster. A suite that fails here and passes alone is not
  # "flaky" and is not dismissed — it is named as a lane-list gap to fix.
  CONTENDED=()
  while IFS=' ' read -r rc t; do
    if [ "$rc" = "0" ]; then
      PASSED+=("$t")
      continue
    fi
    log="$RUN_DIR/$(printf '%s' "$t" | tr '/' '_').log"
    echo
    echo "==============================="
    echo "FAILED in parallel: $t (rc=$rc) — re-running it alone to see if that verdict survives"
    echo "==============================="
    if bash "$HERE/test/$t" > "$log.serial" 2>&1; then
      PASSED+=("$t")
      CONTENDED+=("$t")
      echo "  ... PASSES when run alone. Counting it as passed (sequential is the source of truth)."
      echo "  ... This means \$DRIVER_LOCK_LANE is INCOMPLETE — see the warning at the end of this run."
    else
      FAILED+=("$t")
      echo "  ... fails alone too. Real failure; last 40 lines of the SERIAL run:"
      tail -40 "$log.serial"
    fi
  done < "$RESULTS"

  if [ "${#CONTENDED[@]}" -gt 0 ]; then
    echo
    echo "==============================================================================="
    echo "WARNING (GH-528): ${#CONTENDED[@]} suite(s) failed in parallel and passed alone."
    echo "These are almost certainly contending on the driver lock. Add them to"
    echo "DRIVER_LOCK_LANE in validate.sh:"
    for t in "${CONTENDED[@]}"; do echo "    $t"; done
    echo "Until then --parallel is doing extra serial work and this run took longer than it should."
    echo "==============================================================================="
  fi
else
for t in "${TESTS[@]}"; do
  echo
  echo "==============================="
  echo "Running $t"
  echo "==============================="
  if bash "$HERE/test/$t"; then
    PASSED+=("$t")
  else
    FAILED+=("$t")
  fi
done
fi

echo
echo "==============================="
echo "Running python3 -m pytest test/test_python_layer.py"
echo "==============================="
if python3 -m pytest "$HERE/test/test_python_layer.py"; then
  PASSED+=("python:test_python_layer.py")
else
  FAILED+=("python:test_python_layer.py")
fi

# GH-1: the identity bracket's assert half. Runs AFTER every suite and before the summary, so a
# sandbox escape anywhere in the run fails the run even when every suite reported green — the
# corruption incidents were only ever found because pushes started failing in confusing ways.
echo
echo "==============================="
echo "Running clone-identity invariant (GH-1)"
echo "==============================="
if bash "$HERE/test/lib/clone-identity.sh" assert "$IDENTITY_SNAPSHOT" "$HERE"; then
  PASSED+=("clone-identity-invariant")
else
  FAILED+=("clone-identity-invariant")
fi

# GH-428: non-recursive staleness probe for the gamma-poison fixture (does NOT run
# verify-fixture.sh — that runs this whole suite, so nesting it would recurse).
echo
echo "==============================="
echo "Running gamma-poison fixture staleness probe"
echo "==============================="
if git apply --check "$HERE/test/fixtures/gamma-poison/poison.patch" 2>/dev/null; then
  PASSED+=("gamma-poison-staleness-probe")
else
  FAILED+=("gamma-poison-staleness-probe")
fi

echo
echo "==============================="
echo "Summary"
echo "==============================="
TOTAL=$(( ${#TESTS[@]} + 3 ))
echo "passed: ${#PASSED[@]} / ${TOTAL}"
for t in "${PASSED[@]}"; do echo "  + $t"; done
if [ "${#FAILED[@]}" -gt 0 ]; then
  echo "failed:"
  for t in "${FAILED[@]}"; do echo "  - $t"; done
  exit 1
fi
exit 0
