#!/usr/bin/env bash
# Aggregate runner for all tick acceptance tests.
# Exit 0 = all pass; Exit 1 = at least one failed.
set -u

# Clean ambient variables that might interfere with tests inside the harness.
unset ALLOW_PATHS RELAY_FILE RELAY_TASK RELAY_AGENT RELAY_PEER RELAY_WORKTREE_ISOLATION

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
  "gh418-issue-state-frozen.sh"  # GH-418 (issue state is advisory; on-disk GH-308 FROZEN banner blocks writes)
  "gh422-backfill-source-url.sh" # GH-422 (self-remediating message + bulk backfill) — 18/0; controls: pre-fix replay 15/3, conflict-guard mutation 16/2
  "gh425-source-url-slug.sh" # GH-425 (source URL validates tracking repository + issue number; `related:` preserves foreign origin)
  "gh410-containment-advisory.sh" # GH-410 (prose scan demoted to advisory; worktree_end stays the verdict) — 11/0; controls: pre-fix replay 7/4, containment-deleted mutation 9/2
  "gh399-packet-acceptance-continuation.sh" # GH-399 (the packet's acceptance block is a lossless copy: continuations, scope, cap)
  "gh390-gate-guard.sh"          # GH-390/GH-382 (gate resource guard: wall/CPU/RSS caps, gate-killed escalation, off switch)
  "gh390-timeout-attribution.sh" # GH-390 (exit-7 attribution: dialog vs runaway vs slow vs wedged)
  "gh432-failed-turn-persist.sh" # GH-432 (a failed turn still reaches rtl_enforce: commit + token handoff; both routes) — 12/0 post-fix, control 5/4 pre-fix
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
  "gh284-p3-release-milestone.sh" # GH-284 P3 (RELEASES.md Milestone: join key + the releases check's first test)
  "gh284-p4-release-lanes.sh"   # GH-284 P4 (milestone seed + landed-on-trunk rollup: scope-claim matcher)
  "swarm-preflight.sh"
  "ci-workflow.sh"
  "xyz-completion.sh"
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
