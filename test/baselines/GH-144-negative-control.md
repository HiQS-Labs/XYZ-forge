# GH-144 negative control — multi-seat onboarding and read-only status

Recorded 2026-08-21 against the pre-fix `skills/agent2agent/scripts/agent2agent.py` on
`origin/development`, before the GH-144 implementation was applied.

## Probe

A four-seat discussion was created with deterministic ID `744144`, then the number of printed
`Join XYZ agent2agent` lines was counted and the proposed `status --id 744144` command was invoked.

## Observed red control

```text
PRE-FIX start_rc=0 invitation_count=1
PRE-FIX status_rc=2
usage: agent2agent [-h] [--root ROOT] {start,join,watch,send,close,drive} ...
agent2agent: error: argument command: invalid choice: 'status'
```

The post-fix focused suite therefore has two falsifiable claims: a four-seat start must print three
non-initiator invitations, and `status` must exist and remain byte-preserving.
