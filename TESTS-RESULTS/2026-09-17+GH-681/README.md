# GH-681 evidence — reviewer probes and the generalization rule

Source: `fix/gh681-reviewer-probe-rules` at the SHA in `provenance.jsonl`. Every run below was
executed in a **disposable full clone** of that branch (`/tmp/xyz-gh681-disposable`), never in the
task clone (AGENTS.md: no `test/*.sh` from a clone whose state matters). Mutations for the red
controls were applied and restored there; the disposable clone's tracked diff returned empty after
each. No operator source, ledger, or deployed skill was touched.

## Positive

- `focused-suite.log` — `bash test/gh681-reviewer-probe-rules.sh`: 26 asserts, exit 0. Cases 1-6 pin
  wording (stated plainly in the suite header: prose can only be pinned by text). Case 7 is
  behavioural: a reviewer worktree that writes under `.relay-scratch/` is not off-lane; one that
  leaves `.pytest_cache/` is.
- `gh397.log`, `gh505.log` — the two neighbouring suites whose assertions ("You are the REVIEWER this
  turn"; the reviewer prompt says "set STATUS: Approved") the new wording keeps verbatim: 11/0 and
  63/0.
- `gh308-guard.log` — frozen-twin guard against `development`: no twin changed, no new Bash under
  `utils/` or `relay-automation/` (the lib is a shared runtime, not a twin; `marathon_drive.py` is the
  authoritative Python; `test/` is exempt).
- `validate-full.log` — the complete `validate.sh` gate in the disposable clone (see the tail for
  rc and wall time).

## Lane receipt

- `express-refusal.log` — `express.py check --dry-run` refused with `no-new-bash` on
  `relay-automation/new-relay.sh` (the first applicable refusal in path order; `shared-runtime` on
  `relay-turn-lib.sh` would follow). This is the driver's decision, kept as the reason this change
  rides the fresh-clone PR lane and not `/express`.

## Red controls (each exit 1, restored)

| control | mutation | first FAIL |
|---|---|---|
| 1 | revert S1 (`relay-turn-lib.sh` from `development`) | case 1: reviewer prompt lacks "MAY run narrow, non-mutating probes" |
| 2 | delete the done-handoff sentence from the reviewer note | case 1: lacks "hand the token off with done and set STATUS: Approved" — the consult-round-one Blocker, now mechanical |
| 3 | revert S2 (`new-relay.sh` from `development`) | case 4: scaffold lacks "Observed input:" |
| 4 | delete the `.relay-scratch` exemption in `rtl_worktree_end` | case 7: scratch-only probe output judged off-lane — while all 23 wording asserts in cases 1-6 still pass. This is the mutant both QA advisors named; only the behavioural case sees it. |

Not claimed: a live driven relay with a probing reviewer (post-merge smoke, to be recorded on #681),
or anything about #682 (harness-set env), which stays open.
