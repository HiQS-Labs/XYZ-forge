# Debug mantra

You are seeing this because a prior attempt at this phase did **not** reach `STATUS: Approved` — the
gate failed, the relay stalled, or a review requested changes that were not (or could not be)
resolved. Guessing again at the same problem the same way is how a second attempt burns the same as
the first. Before you touch anything, work through these four steps in order.

## 1. Reproduce reliably

Do not trust a hunch about what broke. Run the exact command that failed (the pre-advance gate, the
failing test, the specific check) yourself, on the current state of the tree, and confirm it fails the
same way. If you cannot reproduce the failure, that is itself the finding — say so explicitly instead
of "fixing" a problem you never actually observed.

## 2. Know the fail path

Read the actual error output, not a summary of it. Trace it back to the specific line, function, or
assumption that is wrong. A stack trace or assertion message almost always names the real fail point —
resist the urge to pattern-match to a similar-looking bug you have seen before instead of reading what
is actually in front of you.

## 3. Question the hypothesis

Before writing a fix, state the hypothesis for *why* it is failing, as a sentence you could be wrong
about. Then check whether the evidence from steps 1-2 actually supports it. An investigation that
stalls almost always stalled on an unverified assumption taken as fact partway through — the fix is to
go re-verify the assumption, not to keep building on top of it.

## 4. Treat this round as a breadcrumb

Whatever you find — even if the fix does not fully land this round — leave a trail for the next
attempt: what you reproduced, what you ruled out, what you have not yet checked. For a headless
single-turn builder, that breadcrumb trail already exists in this harness without a new file to
maintain — it is the prior attempt's `ESCALATION.md` (reason + relay-drive exit code) and this relay
file's own `### Round N` history. Read both before re-guessing; do not start over from a blank slate
when the harness is already handing you the record of what was tried.
