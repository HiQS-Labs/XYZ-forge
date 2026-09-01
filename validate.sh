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

# ── GH-45: REFUSE to run from a linked git worktree ─────────────────────────────────────────────
# A linked worktree shares the parent clone's .git common directory — config, refs, and object
# store alike. A suite that escapes its fixture (or resolves one to an empty string) therefore
# reaches the PARENT clone, not a sandbox: the observed 2026-08-19 run set core.bare=true,
# repointed origin at a deleted temp path, deleted every refs/remotes/origin/*, and overwrote
# development with fixture commits (GH-564's class, firing for real). The detection is the same
# --git-common-dir idiom the GH-448 driver-lock resolver uses: in the main checkout the absolute
# git dir IS the common dir; in a linked worktree it is <common>/worktrees/<name> and differs.
# Fail closed for every mode — tiers 1 and 2 run fixture-driven suites too. BOTH the invocation
# CWD (where a suite's `git -C ""` escape lands) and HERE (whose clone the identity bracket
# asserts) are checked, so invoking the script by absolute path from outside cannot slip past.
_wt_refuses() {  # <dir>... -> exit 2 if any dir lives in a linked worktree
  local d a c ca
  for d in "$@"; do
    a="$( cd "$d" 2>/dev/null && git rev-parse --absolute-git-dir 2>/dev/null )" || continue
    c="$( cd "$d" 2>/dev/null && git rev-parse --git-common-dir 2>/dev/null )" || continue
    [ -n "$a" ] && [ -n "$c" ] || continue
    ca="$( cd "$d" 2>/dev/null && cd "$c" 2>/dev/null && pwd -P )" || continue
    [ -n "$ca" ] || continue
    if [ "$a" != "$ca" ]; then
      cat >&2 <<WTREFUSE
validate.sh: REFUSING — '$d' is a linked git worktree, which shares the parent clone's
  .git (config, refs, objects). Suites that write to 'the repo' reach the PARENT, not a
  fixture: an observed run set core.bare=true, repointed origin at a deleted temp path,
  deleted every refs/remotes/origin/*, and overwrote development with fixture commits.
  Run the gate from a normal clone. Override with XYZ_ALLOW_WORKTREE_GATE=1 only if you
  accept that blast radius.
WTREFUSE
      exit 2
    fi
  done
}
if [ "${XYZ_ALLOW_WORKTREE_GATE:-0}" != "1" ]; then
  _wt_refuses "$HERE" "${PWD:-.}"
else
  # Announced, never silent — a bypass that says nothing is indistinguishable from no guard.
  echo "validate.sh: XYZ_ALLOW_WORKTREE_GATE=1 — running from a linked worktree at the operator's explicit request; the parent clone's .git is exposed (GH-45)." >&2
fi

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
  "write-ops-log.sh"
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
  "gh245-agy-probe-verb-invariant.sh" # GH-245 (agy auth probe verb must agree across utils/py call sites and not be a removed subcommand)
  "gh267-express-skill.sh"     # GH-267 (/express hotfix lane: refusal predicates, born-complete docs, tick telemetry)
  "ate-run-variations.sh"       # GH-195 (ATE fuzzer git helpers: base-commit/disposable-guard/reset/detect-edit)
  "model-alias.sh"              # GH-120 (OpenRouter model-alias fuzzy lookup)
  "swe-diagram.sh"              # GH-146 (hub-ring layout ring-balance math + search/filter matching)
  "claude-turn.sh"             # GH-58
  "commandcode-turn.sh"        # GH-42 (Commandcode headless turn-taker)
  "worktree-isolation.sh"
  "shim-worktree.sh"
  "marathon-yaml.sh"
  "gh391-emit-marathon-yaml.sh" # GH-391 (ranked plan + packets -> runnable MARATHON.yaml; missing-packet control)
  "marathon-drive.sh"
  "gh284-runlog-heartbeat.sh"   # GH-284 (driver heartbeat + opt-in idempotent run log)
  "gh115-round-cap.sh"
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
  "gh90-allowlist-directory.sh" # GH-90 (a DIRECTORY on ALLOW_PATHS was unmatchable by construction, so a valid lane surfaced as a containment violation) — 19/0; control: pre-fix replay 10/9. The nine that pass pre-fix are the point — C3/C5 are GH-59's own rules, which this fix had to leave intact, and C7 executes a real off-lane write, so the suite still goes red against a build with containment removed
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
  "gh218-synthetic-nested-driver-lock.sh" # GH-218 (synthetic suites must not contend for the harness clone's driver lock: static sweep rejects RELAY_DRIVER_LOCKED=0 on/above any relay_drive/marathon_drive invocation in test/synthetic; dynamic repro holds the real lock dir+live pid and runs gh101 green — the live marathon pre-advance incident shape) — 2/0; negative control: detector flags the pre-fix gh101 line 101
  "gh217-gate-env-plan-outside.sh"    # GH-217 (MARATHON_ALLOW_PLAN_OUTSIDE_WORKING classified SCRUB in the gate_env registry + mirrored in the driver literal; test/marathon.sh unsets it defensively; the issue's literal repro — full marathon suite under the ambient leak — is green, GH-212 refusal specifically not vacuous) — 4/0
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
  "ballast-release.sh"           # Ballast 0.7.0 POST-LAUNCH-HARDENING goalpost — the launched repo holds up under a stranger's first run and an outside contributor's first push. Suite mode fails ONLY on a false completion claim or a ledger disagreement; remaining work is INFO. The goalpost itself is `--release-gate` (red until every manifest member — #14 #15 #4 #3, post-#10-cut — is complete AND the stranger's path is executed fresh in a clone named by XYZ_BALLAST_STRANGER_CLONE: ten consecutive parallel runs, an ungated clone's in-band warning, a forced-red push refused, and #14's cross-process stress case). Control: `--mutate-evidence` 7/0 — NOT run by this suite; run it by hand when touching audit_manifest or the cross-check
  "gh402-branch-enforcement.sh"   # GH-402 (a marathon refuses to commit to the RECEIVING repo's shared trunk; --allow-trunk-commit and preflight's risk=1 carve-out are the two documented ways past) — 13/0; control in test/baselines/GH-402-negative-control.md: 8 red pre-fix, with the pre-fix run observed COMMITTING to trunk. Fires only when origin/HEAD resolves — a repo with no remote shares nothing and `git reset` undoes it, asserted as an explicit non-block
  "gh386-turn-budget-honesty.sh"  # GH-386 (one wall-clock default across all five builders on both lanes; the packet's budget names turn_timeout_s, the field marathon.sh actually reads) — 10/0; control in test/baselines/GH-386-negative-control.md: 9 red pre-fix. Part C EXERCISES the shipped sizing ladder and requires every suggestion to be >= the default — the assertion a partial fix (raise the cap, forget the ladder) fails
  "gh514-write-set-trackable.sh"  # GH-514 (the target is proven able to TRACK the run's write-set before dispatch; a hostile ignore rule gets an actionable refusal naming the rule and the remedy, not an unhandled CalledProcessError traceback) — 12/0; control in test/baselines/GH-514-negative-control.md: 6 red pre-fix. Note the corrected framing recorded there: "no dispatch" does NOT discriminate (the render's own git add already dies first) — the traceback assertion does
  "gh255-remedy-ordering.sh"  # GH-255 (the blocked-before-dispatch refusal offers the remedy that FITS what is blocked: XYZ_ARCHIVE_ROOT leads for a transcripts-only block, --target-root leads when a phase file is blocked because the archive knob cannot clear that) — 6/0; control: force only_transcripts=False → 2 red
  "gh256-target-root-guard-root.sh"  # GH-256 (under --target-root the turn shim guards the same repo the worktree is cut from: marathon-drive exports AGY_/CODEX_/COMMANDCODE_TURN_ROOT, and an unseeded artifact warns on stderr instead of silently handing the agent a worktree without its own files) — 6/0; control: drop the export + the warn → 5 red
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
  "gh35-test-tiers.sh"                 # GH-35 (tiered test selection + CPU governance) — 56/0; pins the registry contract (every registered suite exists AND is in TESTS), the fail-closed tier boundaries, the balanced cores/2 default + --throttle/--burst/env levers, nice -n 10 on the workers, and the tier-1/tier-2 execution paths against fixture clones whose suites are stubs (real runner, real pool, real summary math)
  "gh1-fixture-guard.sh"               # GH-1 (shared require_fixture resolved-containment + clone-identity invariant gate; covers the GH-567 lexical-check residual)
  "gh1-adoption-guard.sh"             # GH-10 (every fixture-creating suite carries require_fixture adoption — derivation computed from source, exemptions declared in-file; controls prove the guard fires on an unguarded new suite, a stripped adoption, and a removed exemption marker)
  "gh314-transcript-writeset.sh"       # GH-314 (the write set is THREE paths: the transcript's git add was outside GH-514's preflight, so an ignored relay-system/ was discovered only after paid turns) — 5/0; control: dropping the transcript path spends 2 builder turns before the same refusal (test/baselines/GH-314-negative-control.md)
  "gh520-default-reviewer-stub.sh"     # GH-520 (test/_setup.sh gives every fixture a default CODEX_BIN, so a suite tests its subject rather than the reviewer probe) — 11/0; control: with gh402's own stub removed AND this default removed, gh402 fails with the probe's message verbatim (test/baselines/GH-520-default-stub-control.md)
  "gh527-destructive-git-guard.sh"     # GH-527 (a tree-overwriting git command snapshots the tracked files it destroys into .tick/orphan-backups/ first) — 26/0; controls: a no-op guard drops 9 assertions, and a blanket that fires on a CLEAN tree drops exactly the control assertion. Clean-tree silence is defended by TWO conditions, so it takes a combined mutation to falsify — recorded in test/baselines/GH-527-negative-control.md
  "gh50-sandboxed-git-guard.sh"        # GH-50 (config writability is proven before a tracking switch can rewrite the tree; writable-config control proves the wrapper is not a blanket ban)
  "marathon.sh"
  "marathon-closeout.sh"
  "gh484-phase-dir-default.sh"   # GH-484 (phase-output default is marathon-system/; --phases-dir still overrides; the dirty-tree exclusion tracks the CONFIGURED dir) — 10/0; controls: pre-fix red on both defaults and both containment cases, plus a stray-file control proving the clean check actually ran. Forces XYZ_PYTHON=0 so the Bash twin is really exercised
  "marathon-root-audit.sh"       # GH-209 (static audit: every test/marathon*.sh invocation is MARATHON_ROOT-scoped)
  "rtl-orphan-backup.sh"         # GH-141 (concurrent peer-edit race: revert unchanged, content recoverable)
  "gh2-orphan-backup-repro.sh"   # GH-2 (mktemp failure cannot redirect orphan-backup relocation onto caller content; guard-stub control reproduces it)
  "gh91-relay-scratch.sh"          # GH-91 (sanctioned .relay-scratch/ for builder verification output: exempted in rtl_check + rtl_worktree_end, pre-created by begin, named in the turn prompt; never copied back, discarded under ROOT; controls pin that stray writes and lookalike prefixes still go off-lane) — 15/0, driven at the lib-function level, no builder binary needed
  "gh113-headless-scratch.sh"    # GH-113 (headless builder's root-level scratch tmp.json/fix_*/test_* RELOCATES to .tick/scratch/ instead of failing exit 6, on BOTH rtl_check and rtl_worktree_end; controls pin the amnesty line: non-scratch names, nested paths, dotfiles, and TRACKED off-lane edits still violate) — 17/0, lib-function level, no builder binary needed
  "gh114-headless-tty.sh"        # GH-114 (agy -p runs under a pty by default so a no-controlling-TTY turn never logs the bubbletea error; an idle kill runs _probe_idle_blocker BEFORE the kill and emits blocker=tty|lock|network|unknown to stderr + transcript; lsof branches faked on PATH) — 10/0
  "gh124-closeout.sh"            # GH-124 (closeout automation, on-disk gate receipts, workspace sweep GC, and early drift alert)
  "gh129-relay-tick-root.sh"     # #129/#136 (relay-drive self-resolves TICK_REPO_ROOT ahead of the lane-attempt gate, NOTE prints after the lock for gh376 parity; not-found names the root+dir searched; escalate exits 4 never 0; attempts land beside the token) — 17/0; negative control: pre-fix red on self-resolution (recorded in PR #134 + #136's fix PR)
  "gh130-agy-auth-whoami.sh"     # #130/#135 (agy auth preflight three-state verdict on BOTH agy-turn.py and consult.py: usage-error probes unverifiable+non-blocking, credentials/silent non-zero still fatal) — 11/0
  "gh131-marathon-target-root.sh" # #131 (cross-repo --target-root + target --phases-dir: render and escalation commits land in the TARGET repo; in-repo control byte-identical; phase_commit_root unit) — 12/0; pool-safe: marathon's fixture-rooted lock + the relay-drive child inherits RELAY_DRIVER_LOCKED=1
  "gh139-pipe-grep-guard.sh"     # #139 (static inventory guard: no NEW `| grep -q` pipes in test/ — the GH-460 SIGPIPE shape; baseline of unconverted stragglers beside it)
  # #141 Phase 1: every test/synthetic/ suite is owned by THIS registry (single selector).
  # Direct entries — the runner invokes bash test/<entry>, wrappers would only add indirection.
  "synthetic/gh101-consult-programmatic.sh"   # GH-101 (programmatic tool mode: consult adapters fail closed without a sandbox backend)
  "synthetic/gh101-relay-programmatic-stress.sh" # GH-101 (relay-drive PGID process cleanup + fail-closed sandbox checks under --tool-mode programmatic)
  "synthetic/gh102-telemetry-schema.sh"       # GH-102 (Telemetry 1.0 shared schema invariants across fuzz-loop and ATE emitters; #141 Phase 2 extends it with mixed-outcome fixtures + rendered-group assertions)
  "synthetic/gh94-containment-invariants.sh"  # GH-94 (AST serialization normalization + sandbox containment invariants for script_runner)
  "synthetic/gh94-script-serialization.sh"    # GH-94 (script_runner serialization round-trip fidelity)
  "synthetic/synthetic-claude-target-root.sh" # cross-repo claude-turn target-root wiring
  "synthetic/synthetic-marathon-env-leak.sh"  # marathon child env hygiene (no run-identity tags leak into phases)
  "synthetic/synthetic-marathon-worktree-guard.sh" # marathon worktree containment guard
  "synthetic/synthetic-pi-model-unset.sh"     # pi-turn: unset model handled, not silently defaulted
  "synthetic/synthetic-pi-provider-unsupported.sh" # pi-turn: unsupported provider exits clean, not fake-success
  "gh141-synthetic-registry.sh"  # #141 Phase 1 (single selector: every test/synthetic suite is registry-reachable AND fuzz-loop's derived selection matches — no suite selectable by one path but not the other; a dropped-in unregistered suite is CAUGHT)
  "gh141-fuzz-inputs.sh"         # #141 Phase 3 (fuzz_inputs.py parser-only slice positive/negative controls)
  "gh142-ate-exit-contract.sh"   # #142 (ATE filing exit contract: 0 filed/dry-run · 3 no-records · 1 gh-failed, propagated through run_variations; hermetic stub gh; also #141 Phase 4's three outcomes + dedup seen-Nx)
  "gh148-deepseek-turn.sh"       # #148 (DeepSeek Harness integration & deepseek-turn shim with OpenRouter route, 11/11 assertions)
  "gh156-turn-shims-help.sh"     # #156 (All 7 turn shims cleanly handle --help and -h before requiring RELAY_AGENT, 14/14 assertions)
  "gh155-phase1-metamorphic-invariants.sh" # #155 Phase 1 (Metamorphic Invariant Assertions & Sandbox Hardening: zero-mutation, idempotence, realpath containment)
  "gh155-phase2-differential-oracle.sh" # #155 Phase 2 (Differential Multi-Harness Cross-Testing Oracle across all 7 turn shims)
  "gh155-phase3-repro-builder.sh"       # #155 Phase 3 (Hermetic Reproducer & Hierarchical Delta Minimization engine)
  "gh155-phase4-self-healer.sh"         # #155 Phase 4 (Gated Autonomous Self-Healing Builder Loop)
  "gh155-phase5-active-explorer.sh"     # #155 Phase 5 (4-Family Generative Active Explorer Agent)
  "gh168-wave-reconcile-scope.sh"       # #168 (PR-attributed planner drift stays fatal; unrelated drift warns; ROADMAP move is idempotent)
  "gh174-harness-registry.sh"           # #174 (Harness & Models SQLite Registry with Per-Device Config, Reasoning Levels, Grading Hooks & Blog Gen)
  "gh180-repro-timeout-crash.sh"        # #180 (repro_builder ingests null-exit timeout telemetry without crashing; no fabricated timeout repros)
  "gh181-repro-adapter-fidelity.sh"     # #181 (telemetry->reproducer fidelity: spaced-path tokenization, signature matching, live-record E2E)
  "gh182-healer-facade-safety.sh"       # #182 (self_healer fail-fast sandbox requirements, mandatory regression gate, restore on exit)
  "gh183-explorer-env-soundness.sh"     # #183 (explorer env mutations from a declared base over a clean env; ambient runner vars cannot satisfy them)
  "gh184-no-tracked-scratch.sh"         # #184 (derived guard: nothing under the disposable .relay-scratch/ lane is ever tracked)
  "gh202-wave-reconcile-issue-state.sh" # #202 (reconciler tolerates items-held exit 5; OPEN-issue docs stay active with merge evidence)
  "gh232-wave-reconcile-multiphase.sh"  # #232 (wave_reconcile honors linked issue state & frontmatter umbrella/multiphase sentinels; --force-promote)
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
  "gh103-timeline-exporter.sh"   # GH-103/109/110/111/108: the READ-ONLY projection of releases.db
                                 #   onto the timeline viewer. The exporter had NO suite before this,
                                 #   which is how #109 survived — it asserted a marathon membership the
                                 #   data never claimed, latent until a non-marathon item joined a
                                 #   marathon release. Pins grouping by manifest_items.marathon_id,
                                 #   the dialed_in+shipped denominator, baseline/growth emission, the
                                 #   rating metrics + effectiveScore precedence, and the leaderboard's
                                 #   one-scorer property (script ranking == --json ordering).
  "gh75-dashboard.sh"            # GH-75 (releases dashboard verb renders one self-contained read-only HTML page)
  "gh32-releases-app.sh"         # GH-32 Phase 0+1 (SQLite RELEASES ledger CLI: schema/GID shape,
                                 #   writer-lock + journal protocol, canonical dump, receipt chain,
                                 #   import grandfathering, side-by-side gen) — 81/0; registered in the
                                 #   same commit as utils/py/releases_app.py per the lesson above. The
                                 #   four check-failure negative controls, the five crash boundaries,
                                 #   and the refused-writer-changes-nothing control are the point; the
                                 #   revert-and-replay transcript is test/baselines/GH-32-negative-control.md
  "gh32-releases-artifacts.sh"   # #52 (the COMMITTED releases.db/releases.sql pair actually agrees —
                                 #   gh32-releases-app.sh only proves the CLI works in fixtures). The
                                 #   documented merge procedure has a human step (`check --rebuild`);
                                 #   skip it and the committed DB disagrees with the dump silently,
                                 #   and the DB is what every reader trusts at runtime. Read-only and
                                 #   NEVER --rebuild: a gate that repairs destroys the evidence that a
                                 #   merge was mis-resolved. Runs against a COPY (plain `check` writes
                                 #   when an intent journal is live) and hashes the clone's artifacts
                                 #   before/after to prove it. 10/0; control in
                                 #   test/baselines/GH-52-negative-control.md
  "gh53-releases-merge-resolve.sh" # #53 (derived-artifact attributes + the one-command ledger merge
                                 #   resolution). Pins that releases.db stays -diff +
                                 #   linguist-generated and keeps NO merge driver — measured:
                                 #   only a driver defined in .git/config auto-merges it, and
                                 #   auto-merging is the wrong outcome anyway (it lets a merge finish
                                 #   with a DB holding one side's rows). The refusals are the point:
                                 #   a two-header dump (what a naive merge=union leaves) and a dump
                                 #   with conflict markers are both refused, not rebuilt. 18/0
  "gh54-merged-dump-refusals.sh" # #54 (check --rebuild must REFUSE merge damage by name, not throw).
                                 #   Every fixture is built by really merging two divergent branches
                                 #   and mangling the dump the way a union would — a refusal test
                                 #   whose fixture cannot occur proves nothing. Covers the two-header
                                 #   dump, the duplicated settings row (needs UNEQUAL write counts;
                                 #   equal counts dedupe to a deceptively clean union), and the same
                                 #   global_id twice — the one case no union can settle. Carries a
                                 #   POSITIVE control so the refusals cannot go blanket. 19/0
  "gh57-releases-fuzz.sh"        # GH-57 (generated SQLite RELEASES scenarios: divergent GID merges,
                                 #   unequal generation headers, dump collisions, all journal crash
                                 #   boundaries, common-dir lock contention, torn dumps, and Markdown drift)
  "gh57-live-merge-resolve.sh"   # GH-57 (the merge contract driven by an ACTUAL `git merge`, not a hand-built
                                 #   union): the real conflict shape (BOTH artifacts, markers, two headers), the
                                 #   resolver's refusals against a genuinely unmerged index, the full operator path
                                 #   through `git merge --continue`, and four edge cases that were REAL defects on
                                 #   first run — a failed resolve left the merge half-closed, a rewound generation
                                 #   header was accepted silently, releases.db.bak was committable, and `--root ""`
                                 #   retargeted the resolver at the current repo. 27/0
  "gh69-roadmap-shadow.sh"        # GH-69 (roadmap ledger: `releases roadmap sync` mirrors the ledger into
                                 #   roadmap_items, GH-32 Phase-0 pattern) — 24/0; pins that the shadow never
                                 #   writes the markdown, a no-change sync is a NO-OP (no generation bump, no
                                 #   dump churn), GIDs are stable across edits, rows ride check --rebuild, and
                                 #   a duplicate GH key in the markdown is refused by name
  "gh77-standup-triage.sh"        # GH-77 (`skills/standup/triage.py`, the deterministic half of /standup) — 29/0.
                                 #   Its PRD escalated at a 4-round review cap with a FLAT finding rate
                                 #   (11/13/10/10) because a state machine was being specified in prose. The
                                 #   properties four rounds argued about are pinned here instead: a tier-1..3
                                 #   item is never silent (rendered, or counted with a paging escape hatch);
                                 #   corruption reaches tier 1 through BOTH `FAIL: rule=` and `warn: rule=`
                                 #   (matching only `warn:` made the founding incident class invisible);
                                 #   suppression hashes a lens-sorted live-state map so a deduped item has one
                                 #   fingerprint and an escalation re-raises; writes stay inside PARKED/ and an
                                 #   unchanged rerun is a byte no-op
  "gh32-release-target-advisory.sh" # GH-32 (`check`'s warn-only target-date advisories) — 17/0; `ship` is a human
                                 #   verb on purpose, so an already-satisfied release can sit `active` unnoticed
                                 #   (0.7.1 Bulwark did, for a day). Pins that the advisory WARNS and never
                                 #   refuses, names the release and the day count, distinguishes a stuck active
                                 #   release from a stale draft, and — the falsifiable half — stays silent for a
                                 #   release whose target has not passed
  "gh39-releases-project-sync.sh" # GH-39 (idempotent, explicit-apply RELEASES.DB -> GitHub Project card projection;
                                 #   mock GH covers dry run, create, repeat update/no duplicate, and schema refusal)
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
  "agent-chorus.sh"             # GH-497 (compact six-digit rendezvous + serialized 2+ agent routing)
  "gh233-agent-chorus-concurrency.sh" # GH-233 (AgentChorus Gen 2 Phase 2: concurrency, mutex, and supersession stress)
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
  "gh123-lock-progress-bound.sh" # GH-123 (XYZ_LOCK_WAIT_S bounds one holder, not the queue; progress re-arms)
  "gh14-atomic-append.sh"        # GH-14 (appendEvent publishes via a .tmp name + atomic rename; concurrent readers never see a torn .jsonl)
  "gh23-path-overlap-enforcement.sh" # GH-23 (enforce path overlap rejection on direct tick claim and tick scope under withClaimLock; --force bypass)
  "gh4-ungated-clone-warning.sh" # GH-4 (validate.sh warns non-fatally when the push gate is not installed; silent when gated)
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
  "gh238-hq-releases-mode.sh"    # GH-238 (releases-mode park: roadmap add verb + hq park DB sink + sync no-op)
  "gh239-hq-status-releases-mode.sh"  # GH-239 (releases-mode status + rollup read from the releases DB)
  "gh243-dashboard-staleness-guard.sh" # GH-243 (push guard: ledger write without dashboard regen is refused)
  "gh257-roadmap-ledger-fixes.sh"     # GH-257 (roadmap ledger validation, dropped-row warnings, update subcommand, staleness diagnosis)
  "gh353-vendored-router-audit.sh"    # GH-353 (audit and prompt for target ROUTER.md ROADMAP.md frozen status during vendored updates)
  "jog-queue.sh"                      # GH-259 (Jog serial queue schema, CRUD operations, lease recovery, and execution runner)
  "gh290-ate-variation-grid.sh"       # GH-290 (ATE variation grid: contract loaders, land verification,
                                     #   receipt-writer robustness — deterministic hostile-input matrix)
  "gh291-contract-goldens.sh"         # GH-291 Scope 2 (golden @1 conformance: producer fidelity vs
                                     #   committed fixtures, loader accept/refuse matrix, future-schema
                                     #   refusal with zero Tick mutation)
  "gh280-jog-marathon-adapter.sh"     # GH-280 (Jog↔Marathon machine contracts: invocation/result@1 artifacts, executor
                                     #   E2E in root + vendored installs with stubbed agents/GitHub, resume/retry/land
                                     #   semantics; registered per PR #281 review B3 — the one-directional registry
                                     #   guard had let it ship unregistered, running only when invoked by hand)
  "gh205-gate-idempotency.sh"    # GH-205 (telemetry writes land off-tree; the gate never dirties tracked files)
  "gh204-sed-portability.sh"     # GH-204 (in-place edits portable AND content-asserted; exit code masks the loss)
  "gh153-releases-sidebar-rollup.sh"   # GH-153 (dashboard sidebar spike: releases_cycle module contract,
                                 #   exporter payload keys + baked chrome in both artifacts; the rollup
                                 #   embed itself lives in hq-rollup.sh cases A/F/G)
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
  # GH-306: the bidirectional registry audit found these ten suites green on disk but in neither
  # TESTS nor the subsystem registry — every one a B3-shaped coverage hole (the gh280 lesson:
  # unregistered means the gate never runs it, green or not). Registered as one block so the
  # block itself documents the audit; gh306-registry-bidirectional.sh keeps the reverse
  # direction closed from here on.
  "agy-tui-takeover-verdict.sh"     # GH-375 follow-up (agy 1.1.16 mute terminal-takeover verdict; pre-fix replay in-suite)
  "gh105-vendor-releases-addon.sh"  # GH-105 (Tier-2 releases addon vendoring + sticky tier detection)
  "gh107-timeline-json-seam.sh"     # GH-107 (export_timeline.py --json seam)
  "gh132-review-xyz-skill.sh"       # GH-132 (/review-xyz skill + multi-model review harness)
  "gh165-governance-canonical-paths-guard.sh" # GH-165 (canonical wave-reconciler paths + GH-551 anti-sprawl static guard)
  "gh197-vendor-tier-split.sh"      # GH-197 (two-tier vendor: core default + opt-in RELEASES overlay)
  "gh273-marathon-root-audit-python-shape.sh" # GH-273 (root audit matches python3-spelled driver calls — the GH-195 blind spot)
  "gh312-vendor-preserves-state.sh" # GH-312 (vendor/sync must not destroy the target's runtime state)
  "relay-uncited-findings.sh"       # GH-173 B3 (rtl_check_uncited_findings downgrades uncited review claims)
  "wave-reconcile.sh"               # GH-165 (canonical post-merge reconciler behavior)
  "gh306-registry-bidirectional.sh" # GH-306 (exists→registered registry half; self-demonstrating — see the suite header)
  "gh298-ate-gen4-ci-smoke.sh"      # GH-298 (ATE Gen 4 CI smoke — fuzz/oracle wiring against the real runner)
)

PASSED=()
FAILED=()

# ── GH-528 / GH-544 / GH-35: parallel by default, BALANCED width, and tiered selection ──────────
# `./validate.sh` (no args) runs N-wide, where N is detected from the host. It runs the SAME
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
# GH-35 (2026-08-18) REBALANCED THE DEFAULT: cores−2 (up to 8 workers) saturated developer
# machines badly enough to wedge the editor and spin fans for the whole gate. The default is now
# cores/2 capped at 4 (floor 2) — half the machine, not all but two of it — and every worker runs
# under `nice -n 10` so interactive use keeps scheduling priority. `--burst` restores the old
# full-core width for unattended runs; `--throttle` goes further down to 2 workers. Tiers are
# orthogonal to width and never change WHICH tests run — only how many.
#
# WHAT DID NOT CHANGE, and must not: `ci-local.sh` does NOT call this script. It parses the TESTS
# array and runs each suite in its own sequential loop, and it is the path that writes the gate
# record. So "sequential is the only form that qualifies a claim" (GH-528 Phase 2, GH-509) is still
# true and is still what the record attests. Likewise the macOS promotion boundary in ci.yml pins
# `--sequential` explicitly, so a re-armed boundary cannot silently promote on parallel evidence.
# Tiers 1 and 2 are pre-push speed, NEVER promotion evidence (GH-35 / GH-509).
#
# THE FALLBACK IS ANNOUNCED, NEVER SILENT. A gate that quietly downgrades itself teaches you to trust
# a number that is not the one you are getting, so every run prints which mode it chose and why.
#
# Precedence, highest first: flags > XYZ_VALIDATE_MAX_JOBS > XYZ_VALIDATE_THROTTLE >
# XYZ_VALIDATE_PARALLEL > host detection.
PARALLEL_JOBS=""
PARALLEL_WHY=""
FORCE_SEQUENTIAL=0
TIER=3
SUBSYSTEM=""
AUTO_REQUESTED=0
AUTO_RANGE=""
PATHS_FILE=""
THROTTLE=0
BURST=0
MODE_FLAGS=0
PRINT_MODE_ONLY=0
NICE_CMD="nice -n 10"   # GH-35: workers run as a scheduling HINT below interactive use
command -v nice >/dev/null 2>&1 || NICE_CMD=""
_usage() {
  cat >&2 <<'USAGE'
usage: ./validate.sh [--parallel N | --sequential | --print-mode]
       ./validate.sh [--tier 1|2|3] [--subsystem <name>] [--auto [base[.. head]]] [--paths-file <file>]
       ./validate.sh [--throttle|--quiet-cpu] [--burst]

  concurrency   --parallel N | --max-parallel N   pin the worker count
                --sequential                      one suite at a time (the qualifying form)
                --throttle | --quiet-cpu          2 workers under nice — quiet-machine mode (GH-35)
                --burst                           full-core width, cores-2 capped 8 — unattended speed
  tiers (GH-35) --tier 1|2|3                      1 = docs gate · 2 = subsystem suites · 3 = full (default)
                --subsystem <name>                tier 2 for one subsystem (utils/ci-route.sh subsystems)
                --auto [base[.. head]]            classify the git diff, run the minimal safe tier
                --paths-file <file>               tier 2 from a path list — what pre-push hands over
  environment   XYZ_VALIDATE_THROTTLE=1 · XYZ_VALIDATE_MAX_JOBS=N · XYZ_VALIDATE_PARALLEL=N|0
                (an explicit flag always beats the environment; a width lever beats a throttle lever)
  introspection --list                             print the registry this gate runs (test/<entry>
                per line) and exit 0 — the shared manifest #141 Phase 1 points secondary
                selectors (fuzz-loop.sh) at, so suite ownership has ONE source of truth
USAGE
}
_err2() { echo "validate.sh: $*" >&2; _usage; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    --list)
      # #141 Phase 1: expose the authoritative registry as a manifest. Prints test/<entry> for
      # every TESTS member, one per line, before any gate machinery runs. Read-only.
      for _t in "${TESTS[@]}"; do printf 'test/%s\n' "$_t"; done
      exit 0 ;;
    --print-mode) PRINT_MODE_ONLY=1; shift ;;
    --parallel|--max-parallel)
      [ $# -ge 2 ] || _err2 "$1 requires an integer >= 1"
      case "$2" in ''|*[!0-9]*) _err2 "$1 requires an integer >= 1" ;; esac
      [ "$2" -ge 1 ] || _err2 "$1 requires an integer >= 1"
      MODE_FLAGS=$((MODE_FLAGS + 1)); [ "$MODE_FLAGS" -le 1 ] || _err2 "conflicting concurrency flags — pick one of --parallel/--max-parallel/--sequential/--throttle/--burst"
      PARALLEL_JOBS="$2"; PARALLEL_WHY="explicit $1 $2"
      shift 2 ;;
    --sequential)
      MODE_FLAGS=$((MODE_FLAGS + 1)); [ "$MODE_FLAGS" -le 1 ] || _err2 "conflicting concurrency flags — pick one of --parallel/--max-parallel/--sequential/--throttle/--burst"
      FORCE_SEQUENTIAL=1; PARALLEL_WHY="explicit --sequential"
      shift ;;
    --throttle|--quiet-cpu)
      MODE_FLAGS=$((MODE_FLAGS + 1)); [ "$MODE_FLAGS" -le 1 ] || _err2 "conflicting concurrency flags — pick one of --parallel/--max-parallel/--sequential/--throttle/--burst"
      THROTTLE=1; PARALLEL_WHY="explicit $1"
      shift ;;
    --burst)
      MODE_FLAGS=$((MODE_FLAGS + 1)); [ "$MODE_FLAGS" -le 1 ] || _err2 "conflicting concurrency flags — pick one of --parallel/--max-parallel/--sequential/--throttle/--burst"
      BURST=1; PARALLEL_WHY="explicit --burst"
      shift ;;
    --tier)
      [ $# -ge 2 ] || _err2 "--tier requires 1, 2, or 3"
      case "$2" in 1|2|3) TIER="$2" ;; *) _err2 "--tier requires 1, 2, or 3" ;; esac
      shift 2 ;;
    --subsystem)
      [ $# -ge 2 ] || _err2 "--subsystem requires a name (utils/ci-route.sh subsystems lists them)"
      SUBSYSTEM="$2"; shift 2 ;;
    --auto)
      AUTO_REQUESTED=1; shift
      # An optional range follows unless the next token is another flag.
      if [ $# -gt 0 ]; then case "$1" in -*) ;; *) AUTO_RANGE="$1"; shift ;; esac; fi ;;
    --paths-file)
      [ $# -ge 2 ] || _err2 "--paths-file requires a path"
      PATHS_FILE="$2"; shift 2 ;;
    *) _err2 "unknown argument: $1" ;;
  esac
done

# GH-4: an ungated clone pushes unverified and nothing downstream notices — the local pre-push
# gate is the only gate while this repo is private (GH-544), and the hook lives in `.git/hooks/`,
# which does not travel with a clone. Surface that state loudly but NON-FATALLY, in-band, on the
# documented first-run path (this file), rather than relying on a contributor separately knowing
# to run `githooks/install.sh --check`. Deliberately after argument parsing (so a bad flag still
# reports its own usage error first) and deliberately a warning, not a refusal: this file's job is
# local validation, which an ungated clone can still do correctly — only pushing is affected.
if ! _gh4_hook_check="$(bash "$HERE/githooks/install.sh" --check 2>&1)"; then
  echo "$_gh4_hook_check" >&2
  echo "validate.sh: continuing WITHOUT the push gate installed — this run is unaffected, but a future push from this clone will not be verified." >&2
fi

# ── GH-35: tier resolution — WHICH tests run, never HOW MANY AT ONCE ────────────────────────────
# Tiers select a test SET from the one registry in utils/ci-route.sh; width/nice select a
# resource policy. A tier below 3 is a pre-push convenience and is labelled NOT promotion
# evidence on every path (GH-509: only ci-local.sh's sequential full run writes a record).
T2_TESTS=""      # space-separated suite list for tier 2
T2_PDDA=0        # 1 when the classifier says docs were touched too
T2_PYTEST=0      # 1 when a *.py path is in play (test_python_layer.py covers utils/py)
T2_PATHS=""      # newline list of changed paths (static checks + pytest hint)

_cls_get() {  # <classifier-output> <key> -> value — first match only
  printf '%s\n' "$1" | sed -n "s/^$2=//p" | head -1
}

classify_paths() {  # paths on stdin -> classifier key=value block on stdout; rc 1 if unavailable
  [ -x "$HERE/utils/ci-route.sh" ] || return 1
  bash "$HERE/utils/ci-route.sh" push || return 1
}

apply_classification() {  # <key=value block> — sets TIER/T2_*/TIER_REASON; fail-closed to tier 3
  local cls="$1" t tests
  cls="$1"
  t="$(_cls_get "$cls" tier)"
  tests="$(_cls_get "$cls" tier2_tests)"
  case "$t" in
    1) TIER=1 ;;
    2) TIER=2; T2_TESTS="${tests//,/ }" ;;
    *) TIER=3 ;;
  esac
  if [ "$(_cls_get "$cls" pdda_needed)" = "true" ]; then T2_PDDA=1; fi
  TIER_REASON="$(_cls_get "$cls" tier_reason)"
}

TIER_REQUESTED=0
[ "$TIER" -ne 3 ] && TIER_REQUESTED="$TIER"
if [ "$AUTO_REQUESTED" -eq 1 ] || [ -n "$PATHS_FILE" ] || [ -n "$SUBSYSTEM" ]; then
  # The selector flags are mutually exclusive: each of them fully determines the tier, so
  # combining two answers the question twice and one of them is being silently ignored.
  if [ "$AUTO_REQUESTED" -eq 1 ] && { [ -n "$PATHS_FILE" ] || [ -n "$SUBSYSTEM" ]; }; then
    _err2 "--auto cannot be combined with --paths-file/--subsystem"
  fi
  [ -n "$PATHS_FILE" ] && [ -n "$SUBSYSTEM" ] \
    && _err2 "--paths-file cannot be combined with --subsystem"
fi

if [ "$AUTO_REQUESTED" -eq 1 ]; then
  _auto_base="" _auto_head=""
  if [ -n "$AUTO_RANGE" ]; then
    _auto_base="${AUTO_RANGE%%..*}"
    _auto_head="${AUTO_RANGE#*..}"
    [ "$_auto_head" = "$AUTO_RANGE" ] && _auto_head=""
  else
    # Default range: everything this clone has over its upstream, INCLUDING uncommitted work
    # (diff against the working tree, not HEAD). No upstream -> compare against HEAD's parent.
    _auto_base="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)"
    [ -n "$_auto_base" ] || _auto_base="HEAD^"
    _auto_head=""
  fi
  _auto_paths() {
    if [ -n "$_auto_head" ]; then git diff --no-renames --name-only "$_auto_base" "$_auto_head"
    else git diff --no-renames --name-only "$_auto_base"; fi
  }
  if _cls="$(_auto_paths 2>/dev/null | classify_paths)"; then
    apply_classification "$_cls"
    T2_PATHS="$(_auto_paths 2>/dev/null)"
    echo "validate.sh: --auto classified tier $TIER — ${TIER_REASON:-unspecified} (GH-35)"
    case "$T2_PATHS" in *.py|*.py$'\n'*) T2_PYTEST=1 ;; esac
  else
    echo "validate.sh: --auto could not classify the diff — failing closed to tier 3 (GH-35)" >&2
    TIER=3
  fi
fi

if [ -n "$PATHS_FILE" ]; then
  [ -s "$PATHS_FILE" ] || _err2 "--paths-file must name a non-empty file"
  _cls="$(classify_paths < "$PATHS_FILE")" || _err2 "the classifier could not run — refusing to guess a tier"
  apply_classification "$_cls"
  if [ "$TIER" -ne 2 ]; then
    # A caller hands over a path list precisely because it wants the narrow gate. If those
    # paths classify as anything but tier 2, saying so and failing is the honest move — a
    # quiet escalation to a 4-minute full gate from inside a hook looks like a hang.
    echo "validate.sh: --paths-file classified tier $TIER — ${TIER_REASON:-unspecified}." >&2
    echo "validate.sh: refusing the narrow gate; run the full ./validate.sh (or push, which will)." >&2
    exit 2
  fi
  T2_PATHS="$(cat "$PATHS_FILE")"
  case "$T2_PATHS" in *.py|*.py$'\n'*) T2_PYTEST=1 ;; esac
  echo "validate.sh: classified tier 2 — ${TIER_REASON:-unspecified} (GH-35)"
fi

if [ -n "$SUBSYSTEM" ]; then
  T2_TESTS="$(bash "$HERE/utils/ci-route.sh" subsystems "$SUBSYSTEM" 2>/dev/null)" \
    || _err2 "unknown subsystem '$SUBSYSTEM' (utils/ci-route.sh subsystems lists them)"
  [ -n "$T2_TESTS" ] || _err2 "subsystem '$SUBSYSTEM' resolved to no suites — refusing a zero-test gate"
  TIER=2
  case "$SUBSYSTEM" in releases|pdda) T2_PYTEST=1 ;; esac
  echo "validate.sh: tier 2 — subsystem $SUBSYSTEM (GH-35)"
fi

# A selector flag decides the tier; an explicit --tier is allowed only as CONFIRMATION
# (PR #55 review, finding 1: --tier 2 --subsystem hq is the natural spelling and is what
# ROUTER.md documents). A contradicting --tier is an error, not a silent override.
if [ "$TIER_REQUESTED" -ne 0 ] && [ "$TIER_REQUESTED" -ne "$TIER" ]; then
  _err2 "--tier $TIER_REQUESTED contradicts the selector flag's tier $TIER — drop --tier, or pass --tier $TIER"
fi

# ── GH-35: ambient concurrency levers (consulted only when no flag was given) ───────────────────
if [ "$MODE_FLAGS" -eq 0 ] && [ "$FORCE_SEQUENTIAL" -eq 0 ] && [ -z "$PARALLEL_JOBS" ]; then
  case "${XYZ_VALIDATE_MAX_JOBS:-}" in
    '') ;;
    *[!0-9]*|'0') echo "validate.sh: XYZ_VALIDATE_MAX_JOBS must be an integer >= 1" >&2; exit 2 ;;
    *) PARALLEL_JOBS="$XYZ_VALIDATE_MAX_JOBS"; PARALLEL_WHY="XYZ_VALIDATE_MAX_JOBS=$XYZ_VALIDATE_MAX_JOBS" ;;
  esac
fi
_throttle_env=0
case "${XYZ_VALIDATE_THROTTLE:-}" in
  ''|0) ;;
  1) _throttle_env=1 ;;
  *) echo "validate.sh: XYZ_VALIDATE_THROTTLE must be 0 or 1" >&2; exit 2 ;;
esac
if [ "$MODE_FLAGS" -eq 0 ] && [ "$FORCE_SEQUENTIAL" -eq 0 ] && [ -z "$PARALLEL_JOBS" ] && [ "$_throttle_env" -eq 1 ]; then
  THROTTLE=1; PARALLEL_WHY="XYZ_VALIDATE_THROTTLE=1"
fi
if [ "$MODE_FLAGS" -eq 0 ] && [ "$FORCE_SEQUENTIAL" -eq 0 ] && [ -z "$PARALLEL_JOBS" ] && [ "$THROTTLE" -eq 0 ]; then
  case "${XYZ_VALIDATE_PARALLEL:-}" in
    '') ;;
    0) FORCE_SEQUENTIAL=1; PARALLEL_WHY="XYZ_VALIDATE_PARALLEL=0" ;;
    *[!0-9]*) echo "validate.sh: XYZ_VALIDATE_PARALLEL must be an integer >= 0" >&2; exit 2 ;;
    *) PARALLEL_JOBS="$XYZ_VALIDATE_PARALLEL"; PARALLEL_WHY="XYZ_VALIDATE_PARALLEL=$XYZ_VALIDATE_PARALLEL" ;;
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
_cores="$(_detect_cores 2>/dev/null | head -1)"
case "$_cores" in ''|*[!0-9]*) _cores=0 ;; esac

# Capability first, whatever else was asked: without xargs -P there is no pool at all, and an
# explicit --parallel that silently degraded to sequential would be exactly the quiet
# substitution GH-544 exists to prevent.
if ! printf '' | xargs -P 2 -I{} true >/dev/null 2>&1; then
  # Not every xargs implements -P. Falling back is correct; failing here would make the gate
  # unrunnable on a host where the sequential path works perfectly well.
  FORCE_SEQUENTIAL=1
  if [ -n "$PARALLEL_WHY" ]; then PARALLEL_WHY="$PARALLEL_WHY — overridden: this host's xargs does not support -P"
  else PARALLEL_WHY="this host's xargs does not support -P"; fi
elif [ "$FORCE_SEQUENTIAL" -eq 0 ] && [ -z "$PARALLEL_JOBS" ]; then
  if [ "$THROTTLE" -eq 1 ]; then
    # Explicit quiet-machine mode is an explicit width: 2 workers, any host that has a pool.
    PARALLEL_JOBS=2
    PARALLEL_WHY="$PARALLEL_WHY — 2 workers under nice (quiet-CPU, GH-35)"
  elif [ "$BURST" -eq 1 ]; then
    # The pre-GH-35 aggressive width, now opt-in only: leave two cores for the driver-lock lane
    # and the shell; cap at 8, the width the GH-528 spike actually measured.
    _w=$((_cores - 2)); [ "$_w" -gt 8 ] && _w=8; [ "$_w" -lt 1 ] && _w=1
    PARALLEL_JOBS="$_w"
    PARALLEL_WHY="$PARALLEL_WHY — full-core width cores-2 capped 8 (GH-35)"
  elif [ "$_cores" -lt 4 ]; then
    # Below 4 cores the pool cannot outrun the serialized driver-lock lane, so parallelism buys
    # contention risk and no wall-clock. Detected, not assumed.
    FORCE_SEQUENTIAL=1
    if [ "$_cores" -eq 0 ]; then PARALLEL_WHY="could not detect a core count on this host"
    else PARALLEL_WHY="only $_cores core(s) detected (parallel needs >= 4)"; fi
  elif [ "$TIER" -eq 2 ]; then
    # Tier 2 runs a handful of suites; 2 throttled workers is the whole point of the fast lane.
    PARALLEL_JOBS=2
    PARALLEL_WHY="tier 2 default — 2 workers under nice (GH-35)"
  else
    # GH-35 balanced default: half the machine (floor 2, cap 4) instead of all-but-two of it.
    # The old cores-2 width pegged 8-core+ hosts at 100% for the whole gate and cost more
    # operator attention than it saved wall-clock; --burst buys it back when unattended.
    _w=$((_cores / 2)); [ "$_w" -gt 4 ] && _w=4; [ "$_w" -lt 2 ] && _w=2
    PARALLEL_JOBS="$_w"
    PARALLEL_WHY="auto-detected $_cores cores — balanced default cores/2 (floor 2, cap 4; --burst restores full width, GH-35)"
  fi
fi
if [ "$FORCE_SEQUENTIAL" -eq 1 ]; then PARALLEL_JOBS=""; fi
if [ -z "$PARALLEL_JOBS" ]; then
  echo "validate.sh: SEQUENTIAL mode — $PARALLEL_WHY"
fi
if [ -n "$NICE_CMD" ]; then
  export NICE_CMD
  echo "validate.sh: suite workers run under $NICE_CMD — an interactive-session hint, not a CPU limit (GH-35)"
fi
if [ "$PRINT_MODE_ONLY" -eq 1 ]; then
  # Resolve the mode, print it, run nothing. Exists so the decision is observable without paying
  # for a gate run — both for test/gh544-parallel-default.sh (which must never execute the real
  # suite) and for a pre-push hook that wants to tell the operator what it is about to do.
  if [ -n "$PARALLEL_JOBS" ]; then
    echo "validate.sh: PARALLEL mode ${PARALLEL_JOBS}-wide — $PARALLEL_WHY"
    echo "  NOT promotion evidence: the qualifying gate is ci-local.sh's sequential run (GH-509)."
  fi
  if [ "$TIER" -lt 3 ]; then
    echo "validate.sh: tier $TIER — subsystem/docs selection is NEVER promotion evidence (GH-35/GH-509)."
  fi
  exit 0
fi

# ── GH-35 tier 1: the deterministic docs gate, and nothing else ─────────────────────────────────
# This is the same pair of checks githooks/pre-push runs for a route=docs push, so
# `./validate.sh --tier 1` and the hook cannot drift apart: one classifier, one docs gate.
# Tier 1 runs no fixtures, so the GH-1 identity bracket below does not apply to it.
if [ "$TIER" -eq 1 ]; then
  echo
  echo "==============================="
  echo "Tier 1 — docs & governance gate (GH-35)"
  echo "NOT promotion evidence: the qualifying gate is ci-local.sh's sequential full run (GH-509)."
  echo "==============================="
  _t1_rc=0
  if [ -x "$HERE/utils/pdda/pdda.sh" ]; then
    $NICE_CMD bash "$HERE/utils/pdda/pdda.sh" run || _t1_rc=1
  else
    echo "validate.sh: utils/pdda/pdda.sh is missing — a docs gate that cannot run has not passed." >&2
    _t1_rc=1
  fi
  if [ -x "$HERE/utils/pdda-local-checks.sh" ]; then
    # Repo-owned PDDA additions are warn-only by contract (same stance as pre-push).
    $NICE_CMD bash "$HERE/utils/pdda-local-checks.sh" run || true
  fi
  if [ "$_t1_rc" -eq 0 ]; then
    echo "tier 1: documentation gate GREEN"
    exit 0
  fi
  echo "tier 1: documentation gate RED" >&2
  exit 1
fi

# ── GH-35 tier 2: shrink the run set to the selected subsystem suites ───────────────────────────
# Tier 2 is the SAME machinery on a smaller list: same pool, same driver-lock lane, same
# identity bracket, same summary invariant — only the test SET changes (and it comes from the
# same registry the push hook uses, so the two cannot disagree about what "hq" covers).
RUN_TESTS=("${TESTS[@]}")
if [ "$TIER" -eq 2 ]; then
  echo
  echo "==============================="
  echo "Tier 2 — subsystem gate (GH-35): $T2_TESTS"
  echo "NOT promotion evidence: the qualifying gate is ci-local.sh's sequential full run (GH-509)."
  echo "==============================="
  RUN_TESTS=()
  for t in $T2_TESTS; do
    [ -f "$HERE/test/$t" ] || { echo "validate.sh: tier-2 suite test/$t is missing — a gate that cannot run has not passed." >&2; exit 1; }
    RUN_TESTS+=("$t")
  done
  [ "${#RUN_TESTS[@]}" -gt 0 ] || { echo "validate.sh: tier 2 resolved to zero suites — refusing a zero-test green." >&2; exit 1; }
  if [ "$T2_PDDA" -eq 1 ]; then
    echo
    echo "==============================="
    echo "Running tier-2 docs gate (docs paths in the change set)"
    echo "==============================="
    if [ -x "$HERE/utils/pdda/pdda.sh" ] && $NICE_CMD bash "$HERE/utils/pdda/pdda.sh" run; then
      PASSED+=("tier2:pdda")
    else
      FAILED+=("tier2:pdda")
    fi
  fi
  if [ -n "$T2_PATHS" ]; then
    echo
    echo "==============================="
    echo "Running tier-2 static syntax checks on changed files"
    echo "==============================="
    _t2s_rc=0
    while IFS= read -r _p; do
      [ -n "$_p" ] || continue
      # A deleted file rides a git-diff path list (PR #55 review, finding 2): there is
      # nothing to syntax-check, and bash -n on a missing path would 127 the whole gate.
      [ -f "$HERE/$_p" ] || { echo "  (gone — skipping $_p)"; continue; }
      case "$_p" in
        *.sh)
          echo "  bash -n $_p"
          $NICE_CMD bash -n "$HERE/$_p" || _t2s_rc=1 ;;
        *.js)
          command -v node >/dev/null 2>&1 || { echo "  (node unavailable — skipping $_p)"; continue; }
          echo "  node --check $_p"
          $NICE_CMD node --check "$HERE/$_p" || _t2s_rc=1 ;;
        *.py)
          echo "  python3 ast-parse $_p"
          $NICE_CMD python3 -c 'import ast,sys; ast.parse(open(sys.argv[1]).read())' "$HERE/$_p" || _t2s_rc=1 ;;
      esac
    done <<<"$T2_PATHS"
    [ "$_t2s_rc" -eq 0 ] && PASSED+=("tier2:static") || FAILED+=("tier2:static")
  fi
fi

# GH-1: suite-wide clone-identity invariant gate. Captured before any suite runs and asserted after
# the last one — a suite that escapes its fixture sandbox and rewrites this clone's git identity
# (the GH-564 incident: core.bare / origin / user identity / HEAD) fails the run HERE, detectably,
# instead of leaving a clone whose every subsequent green run is unattributable (GH-567). Covers
# the suites that have not yet adopted require_fixture; it detects rather than prevents.
# GH-205: the gate must be idempotent. Suites and shims append benchmark/telemetry rows through
# harness_app.py, whose every artifact path (db, dump, registry md, blog docs) follows
# XYZ_HARNESS_DB — so point the whole run at a throwaway COPY and the four tracked artifacts
# (harnesses.db/.sql, HARNESS-MODELS-REGISTRY.generated.md, docs/blog-*.md) stay untouched.
# Regenerating them is an explicit harness_app.py command, never a gate side effect. A pre-set
# XYZ_HARNESS_DB (an operator's or a hermetic suite's own) is respected and wins.
HARNESS_SCRATCH=""
if [ -z "${XYZ_HARNESS_DB:-}" ]; then
  HARNESS_SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/validate-harness.XXXXXX")"
  cp "$HERE/harnesses.db"  "$HARNESS_SCRATCH/harnesses.db"  2>/dev/null || true
  cp "$HERE/harnesses.sql" "$HARNESS_SCRATCH/harnesses.sql" 2>/dev/null || true
  export XYZ_HARNESS_DB="$HARNESS_SCRATCH/harnesses.db"
fi

IDENTITY_SNAPSHOT="$(mktemp "${TMPDIR:-/tmp}/validate-identity.XXXXXX")"
[ -n "$IDENTITY_SNAPSHOT" ] && [ -f "$IDENTITY_SNAPSHOT" ] || { echo "validate.sh: mktemp for identity snapshot failed" >&2; exit 1; }
trap 'rm -f "$IDENTITY_SNAPSHOT"; [ -n "$HARNESS_SCRATCH" ] && rm -rf "$HARNESS_SCRATCH"' EXIT
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
    # GH-15: stdin is /dev/null on EVERY path. The pool's xargs already hands its workers
    # /dev/null, but this same function also runs the sequential driver-lock LANE, which would
    # otherwise inherit the caller's stdin (an operator's TTY in interactive use) — and any suite
    # that reads stdin would behave differently per lane, or hang on a terminal. One stdin regime
    # for every suite is what makes the pool/lane/serial-re-run verdicts comparable.
    # GH-35: $NICE_CMD (unquoted, a scheduling HINT) keeps workers below interactive priority.
    if $NICE_CMD bash "$VALIDATE_HERE/test/$t" >"$log" 2>&1 </dev/null; then rc=0; else rc=$?; fi
    printf '%s %s\n' "$rc" "$t" >> "$VALIDATE_RESULTS"
    echo "[parallel] $t rc=$rc"
  }
  export -f vp_run_one

  # Both lists are derived FROM the run set (all of TESTS on tier 3, the classified subset on
  # tier 2), so the two paths run exactly the same set of suites. The lane is an intersection,
  # not the literal above: iterating $DRIVER_LOCK_LANE directly would run a lane suite even
  # when the run set does not contain it, so `--parallel` could execute suites the sequential
  # path skips — and the summary would count more results than TOTAL.
  POOL=()
  LANE=()
  for t in "${RUN_TESTS[@]}"; do
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
  # "flaky" and is not dismissed — it is named as contention on a shared resource (a lane-list gap)
  # to fix, and NEVER counted as a failed run (GH-15).
  #
  # GH-15: two ways this pass was observed NOT honoring that contract, both fixed here.
  # (1) The serial re-run inherited THIS LOOP'S stdin — which is $RESULTS itself. A re-run suite
  #     that merely read stdin therefore swallowed every result line after it: the failures those
  #     lines recorded were never re-run, never reported, and the run exited GREEN with a short
  #     summary ("passed: 3 / 5" with a suite that always fails silently uncounted — reproduced
  #     deterministically in the GH-15 investigation). The re-run now gets </dev/null, which is
  #     ALSO the pool's stdin regime (xargs hands its workers /dev/null), so the re-run is the
  #     same experiment as the pooled attempt instead of a second, different one.
  # (2) A suite whose worker died without writing a result line was uncounted everywhere: neither
  #     re-run nor reported. The completeness catch-up below gives a missing line the same
  #     treatment as a nonzero rc — re-run alone before believing anything.
  CONTENDED=()
  vp_rerun_alone() {  # <suite> <why> — classify one suite by its ALONE verdict; never by the pool's
    local t="$1" why="$2" log
    log="$RUN_DIR/$(printf '%s' "$t" | tr '/' '_').log"
    echo
    echo "==============================="
    echo "$why: $t — re-running it alone to see if that verdict survives"
    echo "==============================="
    if bash "$HERE/test/$t" > "$log.serial" 2>&1 </dev/null; then
      PASSED+=("$t")
      CONTENDED+=("$t")
      echo "  ... PASSES when run alone. Counting it as passed (sequential is the source of truth)."
      echo "  ... This means a shared resource is contended — see the warning at the end of this run."
    else
      FAILED+=("$t")
      echo "  ... fails alone too. Real failure; last 40 lines of the SERIAL run:"
      tail -40 "$log.serial"
    fi
  }
  while IFS=' ' read -r rc t; do
    if [ "$rc" = "0" ]; then
      PASSED+=("$t")
      continue
    fi
    vp_rerun_alone "$t" "FAILED in parallel (rc=$rc)"
  done < "$RESULTS"

  # Completeness catch-up: every suite in the run set must appear in the results file exactly as
  # often as it was run (once). A missing line means the worker died before recording its verdict —
  # that is a pooled failure in every way that matters, so it gets the same serial re-run, never
  # silence.
  _vp_ran="$RUN_DIR/ran.txt"
  cut -d' ' -f2- "$RESULTS" | LC_ALL=C sort -u > "$_vp_ran"
  for t in "${RUN_TESTS[@]}"; do
    grep -Fxq "$t" "$_vp_ran" || vp_rerun_alone "$t" "NO RESULT recorded in parallel"
  done

  if [ "${#CONTENDED[@]}" -gt 0 ]; then
    echo
    echo "==============================================================================="
    echo "WARNING (GH-528): ${#CONTENDED[@]} suite(s) failed in parallel and passed alone."
    echo "These are CONTENTION, not product failure: each verdict flipped the moment the"
    echo "shared resource was free, so the suite is counted as PASSED and named here."
    echo "The contended resource is almost always THIS CLONE's .git/relay-driver.lock"
    echo "(GH-42): it is taken by the real relay-drive.sh BEFORE argument parsing, so a"
    echo "suite merely INVOKING a driver contends — add such suites to DRIVER_LOCK_LANE"
    echo "in validate.sh so they run in the serialized lane:"
    for t in "${CONTENDED[@]}"; do echo "    $t"; done
    echo "Until then --parallel is doing extra serial work and this run took longer than it should."
    echo "==============================================================================="
  fi
else
for t in "${RUN_TESTS[@]}"; do
  echo
  echo "==============================="
  echo "Running $t"
  echo "==============================="
  if $NICE_CMD bash "$HERE/test/$t"; then
    PASSED+=("$t")
  else
    FAILED+=("$t")
  fi
done
fi

# The Python layer follows the change set on tier 2 (a *.py path or a python-bearing subsystem
# pulls it in); on tier 3 it is unconditional, as it always was.
if [ "$TIER" -eq 3 ] || [ "$T2_PYTEST" -eq 1 ]; then
  echo
  echo "==============================="
  echo "Running python3 -m pytest test/test_python_layer.py"
  echo "==============================="
  if $NICE_CMD python3 -m pytest "$HERE/test/test_python_layer.py"; then
    PASSED+=("python:test_python_layer.py")
  else
    FAILED+=("python:test_python_layer.py")
  fi
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
# Tier 3 only: the probe guards full-suite fixture rot, not a subsystem lane.
if [ "$TIER" -eq 3 ]; then
  echo
  echo "==============================="
  echo "Running gamma-poison fixture staleness probe"
  echo "==============================="
  if git apply --check "$HERE/test/fixtures/gamma-poison/poison.patch" 2>/dev/null; then
    PASSED+=("gamma-poison-staleness-probe")
  else
    FAILED+=("gamma-poison-staleness-probe")
  fi
fi

echo
echo "==============================="
echo "Summary"
echo "==============================="
# GH-15/GH-35: TOTAL counts what THIS run owed — every suite in the run set plus exactly the
# fixed probes the tier selected. The pytest/identity/gamma conditions here are the same ones
# that gated execution above, so the tally cannot drift from what ran.
TOTAL=$(( ${#RUN_TESTS[@]} + 1 ))                       # suites + the identity bracket (always)
[ "$TIER" -eq 3 ] || [ "$T2_PYTEST" -eq 1 ] && TOTAL=$((TOTAL + 1))
if [ "$TIER" -eq 3 ]; then TOTAL=$((TOTAL + 1)); fi     # gamma-poison staleness probe
[ "$TIER" -eq 2 ] && [ "$T2_PDDA" -eq 1 ] && TOTAL=$((TOTAL + 1))
[ "$TIER" -eq 2 ] && [ -n "$T2_PATHS" ] && TOTAL=$((TOTAL + 1))
if [ "$TIER" -eq 2 ]; then
  echo "tier 2 run — ${#RUN_TESTS[@]} suite(s). NOT promotion evidence (GH-35/GH-509)."
fi
# GH-15: the verdict must rest on COMPLETE evidence — every suite plus the fixed probes, each
# classified exactly once. A tally that does not add up is an internal error (a swallowed result
# line, a suite classified twice); failing loud here is the difference between that defect being a
# red run and being a green lie.
if [ $(( ${#PASSED[@]} + ${#FAILED[@]} )) -ne "$TOTAL" ]; then
  echo "validate.sh: INTERNAL ERROR — classified ${#PASSED[@]} passed + ${#FAILED[@]} failed, expected $TOTAL (GH-15)." >&2
  echo "validate.sh: refusing a verdict on incomplete evidence; inspect $( [ -n "${RUN_DIR:-}" ] && printf '%s' "$RUN_DIR" || printf 'the run directory' )" >&2
  exit 1
fi
echo "passed: ${#PASSED[@]} / ${TOTAL}"
for t in "${PASSED[@]}"; do echo "  + $t"; done
if [ "${#FAILED[@]}" -gt 0 ]; then
  echo "failed:"
  for t in "${FAILED[@]}"; do echo "  - $t"; done
  exit 1
fi
if [ "${TIER:-3}" -eq 3 ] && [ -z "${SUBSYSTEM:-}" ] && [ -z "$(git status --porcelain 2>/dev/null)" ]; then
  _val_sha="$(git rev-parse --verify HEAD 2>/dev/null || true)"
  if [ -n "$_val_sha" ] && [ -f "$HERE/utils/py/gate_receipt.py" ]; then
    python3 "$HERE/utils/py/gate_receipt.py" write --repo "$HERE" --sha "$_val_sha" --gate "validate.sh" --mode "parallel" --exit-code 0 --passed "${#PASSED[@]}" --total "$TOTAL" >/dev/null 2>&1 || true
  fi
fi
exit 0
