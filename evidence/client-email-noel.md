# Draft email to Noel

**Subject:** Testing update — the system held up, and we found nine issues

---

Hi Noel,

Quick update on the testing work.

**The short version:** it works, and it held up under sustained load. We also found nine
problems along the way, which is the point of doing this — one of them would have stopped
the system from running at all on a fresh machine.

**What we did**

We set the system up from scratch on a Linux machine, the way a new engineer joining the
project would have to, and wrote down every step that didn't go as the documentation said
it would.

Then we ran it for real. Three long unattended sessions, where one AI writes the code and a
second AI reviews it, back and forth, until the reviewer is satisfied. No one supervising.
Twelve pieces of work in total, each one a genuine task rather than a toy example.

**How it went**

- Every piece of work the system completed passed its checks.
- The demo project went from 8 automated checks to 96, all passing.
- The AI agents stayed strictly inside the files they were allowed to touch — every single
  time. Nothing was published or sent anywhere without permission.
- Roughly thirty back-and-forth exchanges between the two AIs, all recorded in full.

The part I'd highlight: the reviewing AI is genuinely doing its job, not rubber-stamping.
In one case it rejected the work three times before accepting it, and it caught a real
money-handling bug — amounts above a certain size were quietly losing a penny. The tests
that had been written for that code passed. The reviewer caught it anyway.

**What we found**

Nine issues. The most serious one meant the system simply refused to start a work session
at all — a compatibility problem with an updated third-party tool. We've fixed that and
verified the fix, and the last two sessions ran on the fixed version.

Another one is worth knowing about for planning: when one of the AI services runs out of
its monthly allowance, the system reports it as a login problem and tells you to log in
again. It isn't a login problem, and logging in again won't help — the allowance simply
resets on a date. Someone could lose a day chasing that. It's now documented.

The rest are smaller: documentation that doesn't match what the software does, and setup
steps that a newcomer needs but which aren't written down anywhere.

**Where that leaves us**

Everything is written up — the setup guide that actually works, the full list of issues,
and a script that re-checks every finding so nothing rests on our word for it. The critical
fix is ready for review and I'm submitting it now.

Happy to walk through any of it if useful.

Best,
Arnold
