# GH-1 Adoption Ledger

Status: 73 suites pending adoption.

## Legacy Suites (Pending Mechanical Adoption)

The following suites use `mktemp` and `git` but have not yet been migrated to use `require_fixture`. They have been audited and queued for mechanical adoption.
- test/_setup.sh
- test/acorn-extract.sh
- test/agent2agent.sh
- test/aider-turn.sh
- test/ate-run-variations.sh
- test/checkjs.sh
- test/deep-research.sh
- test/find-harness.sh
- test/gh292-worktree-vendored-discovery.sh
- test/gh308-consult-guards.sh
- test/gh308-frozen-twin-guard.sh
- test/gh308-swarm-gate-path.sh
- test/gh331-cost-summary.sh
- test/gh343-gate-program-target-root.sh
- test/gh358-lock-instrumentation.sh
- test/gh369-find-doc-root-resolution.sh
- test/gh376-relay-drive-lock-parity.sh
- test/gh387-gate-not-first-executor.sh
- test/gh390-timeout-attribution.sh
- test/gh399-packet-acceptance-continuation.sh
- test/gh400-acceptance-fidelity.sh
- test/gh400-source-url.sh
- test/gh410-containment-advisory.sh
- test/gh418-issue-state-frozen.sh
- test/gh419-gate-inventory.sh
- test/gh422-backfill-source-url.sh
- test/gh425-source-url-slug.sh
- test/gh448-driver-lock-resolver.sh
- test/gh467-index-only-lane-blocked.sh
- test/gh492-idle-kill.sh
- test/gh520-default-reviewer-stub.sh
- test/gh527-destructive-git-guard.sh
- test/gh536-evidence-detail.sh
- test/gh557-unknown-blocks-manifest.sh
- test/hq-dispatch.sh
- test/hq-hardening.sh
- test/hq-locator.sh
- test/hq-marathon-live.sh
- test/hq-marathon-scan.sh
- test/hq-next.sh
- test/hq-park-synthesis.sh
- test/hq-park.sh
- test/hq-promote.sh
- test/hq-rollup.sh
- test/hq.sh
- test/lane-attempt-cap.sh
- test/marathon-closeout.sh
- test/marathon-plan.sh
- test/meter-release.sh
- test/mktemp-trap-guard.sh
- test/nightwatch-release.sh
- test/path-integrity.sh
- test/registry-lock-concurrency.sh
- test/relay-dep-drift.sh
- test/relay-escalation-not-stall.sh
- test/relay-review-once.sh
- test/relay-self-sufficiency.sh
- test/relay-turn-handoff.sh
- test/releases-skill.sh
- test/roadmap-dashboard.sh
- test/rtl-orphan-backup.sh
- test/security-scan.sh
- test/sentinel-driver-hooks.sh
- test/sentinel-network-guard.sh
- test/sentinel-overlay.sh
- test/sentinel-tier1.sh
- test/signal-triage.sh
- test/swarm-preflight.sh
- test/swe-diagram.sh
- test/transcript-audit.sh
- test/xyz-completion.sh
- test/xyz-harness-hooks.sh
- test/xyz-vendor.sh

## Negative Control

To verify the guard works, three cases were tested:

1. **Removed guard**: A suite that currently has `require_fixture` (`test/gh544-pre-push-gate.sh`) was added to the ledger, simulating that it lost its guard but remained in the system, or that it was adopted but not removed from the ledger.
   - Guard failed with: `gh1-adoption-guard: SUITE ADOPTED BUT STILL IN LEDGER: test/gh544-pre-push-gate.sh`

2. **Unguarded new suite**: A dummy test script `test/dummy-unguarded.sh` was created using `mktemp -d` and `git -C repo` without `require_fixture`, simulating a new unadopted test suite.
   - Guard failed with: `gh1-adoption-guard: UNGUARDED SUITE NOT IN LEDGER: test/dummy-unguarded.sh`

3. **Silent addition to the ledger**: A dummy entry `- test/dummy-unguarded.sh` was added to the ledger in an attempt to bypass check #2.
   - Guard failed with: `gh1-adoption-guard: LEDGER HASH MISMATCH. The list of pending suites was modified.`
