# ESCALATION — Marathon Phase gh278-timeout-drift

phase: gh278-timeout-drift
task: MARATHON-GH278-TIMEOUT-DRIFT-TURN
relay-drive-exit: 6
reason: containment-violation (off-lane edit reverted by a turn-taker)
relay-file: phases/vendored-lane-hardening-2026-07-26--gh278-timeout-drift/RELAY.md

---

## Resolution — 2026-07-27

**Status: RESOLVED at the defect level; the phase itself was never re-driven.**

The escalation was correct and the turn-taker's containment guard behaved as designed. Root cause
was in the phase's own test fixture, not the product:

Both shims probe `"$AIDER_BIN" --help` for flag support before the turn, and that probe is
deliberately NOT cwd-wrapped (`relay-automation/aider-turn.sh:228`) — it runs in the CALLER's cwd,
while the turn itself is correctly wrapped to the turn root. The fixture's stub CLI ignored its
arguments and wrote `tracked.md` / `untracked.md` unconditionally, so the probe scattered them into
whatever directory ran the suite. From the repo root that is an off-allowlist edit, so `agy-turn`
reverted them and failed the turn (exit 6).

Confirmed by instrumenting the stub to report `$PWD` — it runs twice per shim:

    [DBG-cwd] /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm      <- the --help probe
    [DBG-cwd] /private/var/folders/.../tick-gh278-cleanup.../agent-a    <- the real turn

Fixed in `7d1a341` (merged to `development` via PR #309): the stub answers `--help` with no side
effects, plus a new assertion that the fixtures never appear outside the turn root. That assertion
is load-bearing — with the stub fix reverted, all 9 original assertions still pass (9 pass / 2 fail),
so the pre-existing test was green WHILE leaking and could never have caught this.

Also recorded: the behavioural half of `test/gh278-turn-timeout-parity.sh` is a RECONSTRUCTION. The
original was destroyed before being staged by a `git checkout -- <path>` intended to revert a debug
probe. Behaviourally equivalent, not byte-identical. Written up as WORKTREE-SAFETY.md section 13 in
the rebalance-OS repo.

**Deliberately NOT done:** the phase was not re-fired. Re-driving it would have the builder
regenerate the fixture from scratch and likely reintroduce the same leak. The lane's actual
deliverable — 900s parity across both twins and the skill doc, plus the 0-byte-stub cleanup — is
merged and covered by `test/gh278-turn-timeout-parity.sh` (11 pass / 0 fail).
