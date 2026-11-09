# GH1358 runner progression plan QA

STATUS: Approved
Reviewer: independent native Codex runner_progression_plan, 2026-11-08.

Approved with runner-lock and detached-HEAD corrections before implementation. Place after a pending row is found and before lease. Acquire existing JogSupervisorLock(target), require named clean branch, switch development, release before Marathon reacquires. Empty/recovery wakes do not switch. Preserve all lane refs; no pull/reset.
