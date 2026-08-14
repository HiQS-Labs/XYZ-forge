---
schema: finish-line/parked/v2
created_local: 2026-08-14T08:19
repo: xyz-3-agents-swarm
---

# Parked — 2026-08-14 08:19 — xyz-3-agents-swarm

## Runs

### R-001 — 2026-08-14T08:19
- frozen_items: 9
- parked_items: 12

#### P-001 — Unreviewed CI push cleanup
- claimed_severity: valid unfired sweep item
- exclusion_rule: X4
- evidence: skills/ponytail-refined/SKILL.md:1
- summary: Byte-duplicate skill directory still present on main and development, plus a hardcoded absolute tick path across generated RELAY.md files; branch-protection half is operator-only.
- remediation: Delete the duplicate directory; template the tick path.
- issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/395
- revisit_when: an operator decides the branch-protection and access-audit half

#### P-002 — Prompt-stack visibility probe
- claimed_severity: valid unfired sweep item
- exclusion_rule: X4
- evidence: relay-automation/relay-turn-lib.sh:1
- summary: Roughly 35 KB of auto-loaded operator- and target-authored instruction reaches every turn unrecorded; the named cheap fix is a turn-start probe logging the layers.
- remediation: Record loaded instruction layers into the run log.
- issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/398
- revisit_when: a turn misbehaves in a way traced to an unseen instruction layer

#### P-003 — Validate three-plus agent swarm support
- claimed_severity: valid unfired sweep item
- exclusion_rule: X4
- evidence: skills/xyz/SKILL.md:57
- summary: README claims "two or more" agents while the skill records the cap as unvalidated above two; six checkable acceptance items exist but need real multi-agent runs.
- remediation: Reconcile the docs or measure above two.
- issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/423
- revisit_when: someone attempts a swarm with more than two agents

#### P-004 — Reviewer qualification measured only once
- claimed_severity: valid unfired sweep item
- exclusion_rule: X4
- evidence: test/fixtures/gamma-poison/README.md:1
- summary: The GH-40 double-blind Reviewer was qualified on a single blind run with no committed transcripts; a nondeterministic gate needs a measured pass rate per model version.
- remediation: Define N-of-M runs and commit the transcripts.
- issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/429
- revisit_when: the Reviewer is relied on for a qualification decision

#### P-005 — Lantern epic blocked on exit criterion
- claimed_severity: valid unfired sweep item
- exclusion_rule: X4
- evidence: RELEASES.md:148
- summary: Release 0.5.0 Lantern's manifest is frozen at this epic plus GH-358 Phase 2, but its own block records the exit criterion as NOT BUILT and required first.
- remediation: Write test/lantern-release.sh before any member.
- issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/499
- revisit_when: the operator starts release 0.5.0

#### P-006 — Fuzzing PR target and gate guards
- claimed_severity: valid unfired sweep item
- exclusion_rule: X4
- evidence: fuzz-agy-plan.sh:78
- summary: The fuzzing loop creates PRs with no --base development and uses skip-ci with no local gate fallback, but the issue lists option groups rather than a decided scope.
- remediation: Operator picks which of the three groups ships.
- issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/518
- revisit_when: the next automated fuzzing wave is dispatched

#### P-007 — Reviewer-binary stub missing from fixtures
- claimed_severity: valid unfired sweep item
- exclusion_rule: X4
- evidence: test/_setup.sh:113
- summary: Marathon fixtures that do not stub CODEX_BIN assert on the reviewer probe instead of the code under test; the issue offers cost-ordered options and self-parks as not built.
- remediation: Operator picks an option; default stub is cheapest.
- issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/520
- revisit_when: another fixture passes locally and fails only on CI

#### P-008 — Guard for destructive git commands
- claimed_severity: valid unfired sweep item
- exclusion_rule: X4
- evidence: relay-automation/hooks/gh177-sandbox-test-guard.sh:1
- summary: Three destructive incidents in one session; a history-rewriting command used to undo a working-tree experiment has no mechanical guard, and the issue shows prose rails demonstrably failed.
- remediation: Add a PreToolUse guard beside the existing hooks.
- issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/527
- revisit_when: a fourth destructive incident occurs

#### P-009 — Nineteen verified-done issues still open
- claimed_severity: closure bookkeeping
- exclusion_rule: X4
- evidence: none
- summary: Issues 178, 334, 386, 392, 402, 425, 435, 440, 442, 451, 460, 467, 480, 485, 491, 509, 510, 514 and 528 were verified shipped with commit or PR evidence but remain open.
- remediation: Operator verifies and closes each on GitHub.
- issue: none
- revisit_when: the operator next reconciles issue state

#### P-010 — Residual vendor string in find-harness
- claimed_severity: robustness gap
- exclusion_rule: X1
- evidence: skills/relay-xyz/find-harness.sh:255
- summary: The same nonexistent vendor subcommand the GH-421 lane fixed in SKILL.md is still printed by a hint string here; pre-existing on main and not worsened by this branch.
- remediation: Apply the same single-positional form here.
- issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/421
- revisit_when: an operator follows the printed hint and it fails

#### P-011 — Duplicate Grok fuzzer spike logs
- claimed_severity: duplicate tracking item
- exclusion_rule: X4
- evidence: none
- summary: Issues 533 and 534 record the same Aider plus Grok 4.6 OpenRouter spike; 534's body is titled for 533, making 533 canonical and 534 the fuller record.
- remediation: Close one and keep the fuller record.
- issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/534
- revisit_when: the operator next reconciles issue state

#### P-012 — GH-314 fix stranded in stash
- claimed_severity: valid unfired sweep item
- exclusion_rule: X4
- evidence: relay-automation/xyz-vendor.sh:211
- summary: A commit fixing the vendored ignore-rule halt is reachable only from refs/stash and sits on no branch, so both main and development still ship the unfixed ensure_gitignore.
- remediation: Recover the stashed commit or rebuild the fix.
- issue: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/314
- revisit_when: a vendored install halts on a pre-existing ignore rule
