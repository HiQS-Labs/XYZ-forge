#!/usr/bin/env python3
"""gate_env.py — GH-441 Phase 2: the contract for what a pre-advance gate may inherit.

WHY THIS FILE EXISTS
--------------------
`validate.sh` is `marathon-drive`'s DEFAULT `--pre-advance-cmd`, so it routinely runs as a child of a
live driver and inherits that driver's environment. Several of those variables silently flip suite
verdicts, so the gate reports failures belonging to its PARENT rather than to the change under review.
Every affected suite passes standalone, every time — which is what makes it expensive: a gate failure
that cannot be reproduced by hand. On 2026-08-07 this halted the Litmus marathon twice and was
misdiagnosed as flakiness both times.

Before this file, the boundary was defended from BOTH sides and governed from neither:

  * `marathon_drive.py` popped exactly three names (`XYZ_HARNESS_CONTEXT`, `XYZ_SESSION_ID`,
    `MARATHON_LANE_NS`) while the drivers export a dozen-plus;
  * `validate.sh` unset six MORE names in its own prologue — so any CUSTOM `--pre-advance-cmd` that
    did not copy that prologue was silently wrong. Observed live: a hand-written gate reproduced the
    `oracle-guard` failure for exactly that reason (ambient `ALLOW_PATHS` → 10 pass/1 fail; unset →
    11/0), and it cost two marathon rounds plus three clean standalone re-runs before the variable
    was found.

THE CONTRACT
------------
`HARNESS_ENV` below classifies EVERY variable the drivers export. There is no third state: a variable
is either `SCRUB` (must not cross into the gate) or `PASS` (must, with a stated reason). Adding a new
export to a driver without classifying it here makes `test/gh441-gate-env-contract.sh` FAIL — that
test greps the drivers for their assignments and diffs them against this registry, so the boundary
cannot be widened silently. That loud failure is the whole point; a denylist someone forgets to
update is how this defect existed in the first place.

WHAT THIS FILE DELIBERATELY DOES *NOT* DO
-----------------------------------------
It does not scrub `RELAY_DRIVER_LOCKED`. That was tried, landed, and REVERTED on 2026-08-07. The
variable is load-bearing in two opposing directions and no single value is correct for the whole gate:

    state                                        gh284   gh331   gh322   gh268
    clean — no flag, no lock                     20/0    8/0     29/0    34/0
    flag SET + lock HELD  (a real marathon)      15/5    5/3     29/0    34/0
    flag UNSET + lock HELD  (the reverted try)   fails   —       17/3    31/3

SET, a nested driver correctly skips a lock its parent holds, but suites asserting real
lock-acquisition measure the parent. UNSET, those assertions become honest and every nested driver
collides with the held lock instead. The fix for that is per-suite and already shipped (GH-441
Phase 1): the two suites that were ever wrong clear the flag for THEMSELVES, because each drives
against its own throwaway repo. See `test/driver-lock.sh:11`, which used that idiom first.

The lesson encoded here: a global answer to a per-suite question is what produced the reverted commit.
"""

import os
import sys

SCRUB = "scrub"
PASS = "pass"

# Every variable the drivers export, and what the gate boundary does with it.
# Keep the reason strings — they are the argument for the classification, and the next person to add
# an export will read them to decide which side their variable belongs on.
HARNESS_ENV = {
    # ── SCRUB: proven to flip a suite's verdict, or in the same family as one that does ────────────
    "ALLOW_PATHS": (
        SCRUB,
        "MEASURED. test/oracle-guard.sh asserts a missing --allow exits 2 (usage); an inherited "
        "value satisfies the flag so the guard exits 0 instead. Ambient → 10/1, unset → 11/0. This "
        "is the one that cost two marathon rounds.",
    ),
    "RELAY_FILE": (SCRUB, "Names the parent's relay thread; a suite building its own relay must not see it."),
    "RELAY_TASK": (SCRUB, "The parent's tick token. Inherited, a suite's token assertions describe the parent."),
    "RELAY_AGENT": (SCRUB, "The parent's actor identity; ownership assertions would resolve to it."),
    "RELAY_PEER": (SCRUB, "Parent's handoff target. Scrubbed by validate.sh since before this contract."),
    "RELAY_WORKTREE_ISOLATION": (
        SCRUB,
        "Flips whether turns run in a worktree — changes what a suite is testing, not just where.",
    ),
    "RELAY_ARTIFACT_FILE": (
        SCRUB,
        "Seeds a read-only artifact into the worktree. A suite exercising --artifact-file would find "
        "the parent's already present. Same family as RELAY_FILE; classified rather than left "
        "ungoverned, which is the point of this registry.",
    ),
    "RELAY_TARGET_ROOT": (
        SCRUB,
        "Repoints writes at another repo. The target-root suites assert resolution behaviour and must "
        "start from an unset baseline.",
    ),
    "XYZ_HARNESS_CONTEXT": (SCRUB, "Read by test/xyz-harness-hooks.sh. Scrubbed since GH-307."),
    "XYZ_SESSION_ID": (SCRUB, "Read by test/xyz-harness-hooks.sh. Scrubbed since GH-307."),
    "MARATHON_LANE_NS": (SCRUB, "Read by test/debug-mantra.sh. Scrubbed since GH-307."),
    "MARATHON_BUILDER": (
        SCRUB,
        "Suites asserting default builder resolution would read the live marathon's choice as their "
        "own default.",
    ),
    "MARATHON_REVIEWER": (SCRUB, "Same reasoning as MARATHON_BUILDER, for the reviewer lane."),
    "CLAUDE_AGENT": (SCRUB, "Turn shims dispatch only when the token's actor matches; suites set this per-invocation."),
    "CODEX_AGENT": (SCRUB, "See CLAUDE_AGENT."),
    "AGY_AGENT": (SCRUB, "See CLAUDE_AGENT."),
    "AIDER_AGENT": (SCRUB, "See CLAUDE_AGENT."),
    "PI_AGENT": (SCRUB, "See CLAUDE_AGENT."),
    # ── PASS: load-bearing for the gate or for the drivers a suite legitimately spawns ─────────────
    "RELAY_DRIVER_LOCKED": (
        PASS,
        "MUST NOT BE SCRUBBED — see this module's docstring. Scrubbing it globally was landed and "
        "REVERTED (2026-08-07): ~40 gate suites spawn nested drivers that need it SET to skip a lock "
        "their parent holds, and unsetting it breaks them (gh322 17/3, gh268 31/3). The two suites "
        "that need it clear for THEMSELVES clear it themselves — GH-441 Phase 1, the idiom from "
        "test/driver-lock.sh:11. A per-suite question has no global answer.",
    ),
    "TICK_REPO_ROOT": (
        PASS,
        "Pins which clone's event log tick writes to. The gate genuinely needs this: a bare or "
        "worktree-relative tick silently no-ops and deadlocks a relay. Suites that need their own "
        "log set it to their fixture root — which is exactly the fix GH-441 made to "
        "test/gh410-containment-advisory.sh after it leaked agy claims into the production log.",
    ),
}

SCRUBBED_NAMES = tuple(sorted(n for n, (d, _) in HARNESS_ENV.items() if d == SCRUB))
PASSED_NAMES = tuple(sorted(n for n, (d, _) in HARNESS_ENV.items() if d == PASS))


def gate_env(base=None):
    """Return the environment a pre-advance gate should run with.

    This is the single enforcement point. `marathon_drive._gate_env()` delegates here so the driver
    side and the shell side (relay-automation/gate-env.sh) cannot drift apart.
    """
    env = dict(os.environ if base is None else base)
    for name in SCRUBBED_NAMES:
        env.pop(name, None)
    return env


def unset_command():
    """The equivalent `unset` line, for a gate written in shell.

    Emitted by `--sh` and consumed by relay-automation/gate-env.sh, so a custom --pre-advance-cmd can
    obtain the same clean environment without copying validate.sh's prologue — which is the failure
    mode this contract exists to remove.
    """
    return "unset " + " ".join(SCRUBBED_NAMES)


def main(argv):
    if "--sh" in argv:
        print(unset_command())
        return 0
    if "--list-scrubbed" in argv:
        print("\n".join(SCRUBBED_NAMES))
        return 0
    if "--list-passed" in argv:
        print("\n".join(PASSED_NAMES))
        return 0
    if "--explain" in argv:
        for name in sorted(HARNESS_ENV):
            disp, why = HARNESS_ENV[name]
            print(f"{disp:6} {name}\n       {why}\n")
        return 0
    sys.stderr.write(
        "gate_env.py — GH-441 pre-advance gate environment contract\n"
        "usage: gate_env.py [--sh | --list-scrubbed | --list-passed | --explain]\n"
    )
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
