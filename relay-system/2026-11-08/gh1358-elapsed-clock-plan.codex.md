# Independent Codex plan QA

Reviewer: native Codex agent /root/elapsed_clock_plan. Plan d8405cc02.
Verdict: Approved for bounded implementation; no full qualification claim.

Check expiry before both initial poll completion and group-missing recheck. A reaped
child must receive exit108 refusal without signalling its PID/group; terminate only a
still-running child. Enforcement and duration use identical elapsed calculation. Preserve
disabled caps and genuine nonexpired failures. Existing gh390/gh280 plus controlled
actual-function oldred/newgreen are proportionate. No extra suites or machinery.
