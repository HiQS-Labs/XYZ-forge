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
  "gh397-reviewer-turn-role.sh"  # GH-397 (reviewer scope derived from the tick token + role directive, not agent-maintained NEXT:) — 11/0; control: pre-fix red on the un-flipped-NEXT case
  "gh401-dry-run-no-mutation.sh" # GH-401 (--dry-run writes nothing; render goes to stdout) — 4/0; control: pre-fix red on directory creation. Static half: marathon-root-audit.sh
  "gh375-agy-auth-preflight.sh"  # GH-375 (agy whoami exits 0 without a TTY, so output decides) — 14/0; controls: 5 legitimate auth outputs containing "error" must NOT be rejected
  "gh375-auth-timeout-verdict.sh" # GH-375 follow-up (a timed-out probe is reclassified ONLY on positive evidence of the TTY cause; silence and a login prompt stay fatal) — 11/0; control: pre-fix replay of BOTH callers blocks the TTY-diagnosed timeout, and each replay is compile-checked
  "gh385-retry-token-satisfied.sh" # GH-385 (a phase completed on a --retry suffixed token is satisfied) + GH-491 (--retry on an already-satisfied lane says a plain re-fire would have been gate-only) — 19/0; controls: un-completed recorded token must still rebuild; GH-491 advisory must NOT fire when the recorded token is not done, and must not change --retry's behaviour
  "gh438-removal-is-progress.sh" # GH-438 PARTIAL (a removal counts as a phase delta) — 6/0; controls: untouched artifact + newly empty file still rejected. fix_probe re-evaluation NOT covered; issue stays open
  "gh438-acceptance-recheck.sh" # GH-438 P2 (the lane's own fix_probes re-read after the build; a still-unfixed probe escalates) — 14/0; controls: fix-really-lands completes, no-contract byte-identical, --dry-run runs none, builder cannot rewrite its own criteria
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
  "marathon.sh"
  "gh484-phase-dir-default.sh"   # GH-484 (phase-output default is marathon-system/; --phases-dir still overrides; the dirty-tree exclusion tracks the CONFIGURED dir) — 10/0; controls: pre-fix red on both defaults and both containment cases, plus a stray-file control proving the clean check actually ran. Forces XYZ_PYTHON=0 so the Bash twin is really exercised
  "marathon-root-audit.sh"       # GH-209 (static audit: every test/marathon*.sh invocation is MARATHON_ROOT-scoped)
  "rtl-orphan-backup.sh"         # GH-141 (concurrent peer-edit race: revert unchanged, content recoverable)
  "consult.sh"
  "deep-research.sh"             # GH-87 (provider-agnostic grounded-search adapter)
  "relay-pkg-freshness.sh"
  "skill-extract.sh"
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

echo
echo "==============================="
echo "Running python3 -m pytest test/test_python_layer.py"
echo "==============================="
if python3 -m pytest "$HERE/test/test_python_layer.py"; then
  PASSED+=("python:test_python_layer.py")
else
  FAILED+=("python:test_python_layer.py")
fi

echo
echo "==============================="
echo "Summary"
echo "==============================="
TOTAL=$(( ${#TESTS[@]} + 1 ))
echo "passed: ${#PASSED[@]} / ${TOTAL}"
for t in "${PASSED[@]}"; do echo "  + $t"; done
if [ "${#FAILED[@]}" -gt 0 ]; then
  echo "failed:"
  for t in "${FAILED[@]}"; do echo "  - $t"; done
  exit 1
fi
exit 0
