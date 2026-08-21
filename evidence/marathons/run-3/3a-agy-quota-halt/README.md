# Run 3a — agy quota exhaustion mid-campaign

Not a planned run. This is what the harness does when a builder runs out of quota
part-way through a campaign, captured intact.

## What happened

Runs 1 and 2 (8 phases, ~30 turns) consumed the agy individual quota. Run 3's first
builder turn then failed:

    agy-turn: agy -p failed (exit 1)
    agy-turn: auth was NEVER VERIFIED for this turn, and the turn failed — agy could not
      run headless, so auth was not verified: CLI error: bubbletea: error opening TTY:
      bubbletea: could not open TTY: open /dev/tty: no such device or address
    marathon-drive: relay escalated: relay-failed-before-gate (gate: not-run)
    marathon: HALT: phase r3p1 failed (marathon-drive exit 5) — chain stops; later phases NOT started

marathon-drive exit **5**, reason `relay-failed-before-gate`, gate `not-run`, 0 rounds.

## The actual cause

Probed directly, three consecutive attempts (`02-agy-p-retest.log`):

    Error: Individual quota reached. Please upgrade your subscription to increase
    your limits. Resets in 166h55m7s.

Nothing to do with a TTY, and nothing to do with auth.

## Why it presented as a TTY error

agy renders that quota message through its interactive TUI. Under worktree isolation
the turn has no openable `/dev/tty`, so bubbletea fails first and its TTY error is the
only thing that reaches the shim. The shim then attributes the failure to auth and tells
the operator to run `agy login` — which is not a subcommand of agy 1.1.16 at all (F-015).

Three layers between the operator and the real cause: quota -> TUI/TTY failure -> "auth".
An operator following the printed remedy would run a non-existent command, and would have
no reason to suspect a quota limit resetting seven days out.

## What the harness got RIGHT

- It refused to advance: `gate: not-run`. It did not run the gate against an unbuilt artifact.
- It halted the chain on the first failure and did not start r3p2-r3p4, exactly as documented.
- It wrote ESCALATION.md with the relay-drive exit code and reason.
- It saved a transcript anyway, so the failed turn is inspectable.
- It reported "auth was NEVER VERIFIED for this turn" — hedged correctly rather than asserting
  auth was bad. The GH-492 design (record the finding, do not over-claim) is doing real work
  here; it is the layer above that turns the hedge into a confident wrong remedy.

## Consequence for F-015

The F-015 write-up floated `agy models` as a candidate replacement auth probe (rc=0 in ~8s).
This run disproves that: under quota exhaustion `agy models` also returns **rc=1**, so it
would report "not authenticated" for an account that is authenticated and merely out of
quota. That suggestion is withdrawn.
