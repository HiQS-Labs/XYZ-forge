# Prepare a marathon

Treat `$ARGUMENTS` as optional scope for this run. Prepare and report a safe execution plan; do not
fire any marathon until the operator explicitly confirms the exact dry-run-approved plan and order.

1. Invoke the `start-marathon` skill and follow it for intake, contract and plan review, lane
   formation, YAML, preflight and the full-plan dry-run. Do not recreate that logic here.
2. In addition to the skill's report, inspect `PROJECT/2-WORKING`, `marathon-system/*/`, and legacy
   `phases/*/` (GH-484 moved the default; pre-flip runs stay where they are) for stale phase
   directories and orphaned `ESCALATION.md` files from earlier runs. Correlate each candidate with
   its plan, token state, and durable completion evidence. Report the proposed cleanup separately;
   do not delete or move anything without explicit operator confirmation.
3. For every plan classified `READY`, verify the skill's exact full-plan dry-run receipt is current;
   rerun it if inputs changed. A failed or ambiguous dry-run makes that plan non-fireable.
4. Report the ready plans in proposed execution order, including wave membership, write-set
   collisions, the exact live command that would be run, and each dry-run result. End by asking the
   operator to confirm the exact plan(s) and order.
5. Only after that confirmation, execute the confirmed live command(s). Never treat this command as
   permission to bypass `start-marathon`'s no-fire boundary, invent a branch, or expand the reviewed
   scope. Stop and report any drift between the confirmed plan and current state before firing.
