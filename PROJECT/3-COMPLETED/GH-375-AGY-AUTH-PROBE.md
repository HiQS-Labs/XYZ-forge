---
gh_issue: 375
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/375
title: "GH-375 — agy auth pre-flight passes on exit status alone, so the probe cannot fail in the headless context it exists for"
status: 3-COMPLETED
created: 2026-08-06
updated: 2026-08-06
owner: noel
doc_type: project
release: "0.2.0 Litmus"
complexity: 2
risk: 1
effort: 2
phases: 2
ratings_provisional: true
related:
  - "#419 — the class in its sharpest form: the guard is structurally incapable of failing in the one context it exists for, so no green run has ever meant anything."
  - "#308 — relay-automation/agy-turn.sh is frozen; the fix lands in utils/py/agy-turn.py."
non_goals:
  - "Establishing whether an EXPIRED session also exits 0 headlessly. The defect does not depend on it — the probe already cannot distinguish 'ran and confirmed auth' from 'did not run'."
  - "Changing swarm-preflight's `agy=present` reporting. That is a PATH check and is correctly labelled; it is simply not an auth check."
  - "Editing relay-automation/agy-turn.sh. Frozen under GH-308."
goal: >
  The probe decides pass/fail on exit status alone and deletes the command's output on success. Under
  automation `agy whoami` exits 0 while printing a TTY error, so the probe reports auth OK without
  having established anything. The protection depends on a hang that only occurs in the environment
  the probe is not used in — attended runs are protected, unattended runs are not.
---

# GH-375 · a guard that cannot fail where it is used

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-06 as a lane of release 0.2.0 Litmus. Acceptance criteria authored on the issue (it had none) and revised after an adversarial codex+agy review, which found the original "positive assertion on an expected identity field" left both the field and a valid response unspecified. | Operator go. Then Phase 1 (verify the probe produced a result; retain the evidence) and Phase 2 (the two-stub regression with a recorded baseline). |

## The defect

Three things combine:

1. `check=True` raises only on a **non-zero** exit, and `agy whoami` returns 0 on the TTY error.
2. `stdin` is `DEVNULL`, which guarantees there is no TTY — so the error path is the **normal** path
   under automation, not an edge case.
3. The captured output, the only place the failure is visible, is **deleted** on the success branch,
   so nothing downstream can notice.

**The design's safety net cannot reach it.** The timeout branch names the intended failure mode
correctly — expired auth opens an interactive login, the login blocks, the timeout fires — and that
works when a TTY exists. Without one it never happens: `agy` cannot open the login, so it errors
immediately and exits 0. **The result is inverted from the intent.**

`swarm-preflight` separately reports `agy=present`, which is a PATH check. Both signals can read
green with no working credentials.

## What was and was not established

**Established:** `agy whoami` exits 0 while printing a TTY error under a null stdin, and the probe's
logic cannot distinguish that from success.

**Not established:** whether an *expired* session also exits 0 in that context. Testing it would
require deliberately expiring auth. **The defect does not depend on it** — the probe already cannot
distinguish "ran and confirmed auth" from "did not run", so it is not a check regardless of which
value the expired case returns. That distinction is carried here deliberately: a lane that overclaims
what was measured is the failure this release is about.

## Acceptance

*Copied verbatim from [issue #375](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/375)
(`## Acceptance`), fetched 2026-08-06. Deviations, if any, are recorded below this block.*

- [ ] Success requires extracting a documented, non-empty identity field from the `agy whoami` output. Blank output, unparseable output, and the TTY-error fixture each **fail** the probe. Exit status alone never establishes success.
- [ ] The accepted shape is pinned to a representative successful transcript, so "any non-error text" cannot be treated as an identity.
- [ ] The probe's captured output is **retained** under the run's log directory rather than deleted on the success branch. It is the only record of what the probe saw.
- [ ] A failed probe prints the actionable remedy — run `agy login` in a normal terminal — together with the captured evidence, and stops the lane before it spends a turn.
- [ ] A regression test pins the headless case with two stubs: one that exits 0 while emitting a TTY error must fail the probe, one emitting a valid identity must pass.
- [ ] The frozen Bash twin `relay-automation/agy-turn.sh` is byte-unchanged (GH-308).
- [ ] The regression test is observed failing against the pre-fix revision, and a durable record states the reproducer command, the pre-fix revision, the pre-fix result and the post-fix result. A sentence asserting a negative control happened is not the record, per #419.

## Acceptance — deviations from the issue

None. Every criterion is carried verbatim.

The criteria were **authored onto the issue on 2026-08-05** (it had none) and **revised on 2026-08-06**
after the codex+agy review. Codex's blocker was that *"a positive assertion on an expected identity
field"* named neither the field nor a valid response, so a builder could declare any non-error text
an identity — the criterion was satisfiable without fixing the defect. It now requires the accepted
shape to be pinned to a representative successful transcript.

## Phases

| Phase | Deliverable | Artifacts | cx/risk/eff |
|---|---|---|---|
| 1 | The check. Success requires extracting a documented, non-empty identity field; blank output, unparseable output and a CLI/TTY error each fail. The captured output is retained under the run's log directory rather than deleted, and a failure prints the remedy with the evidence. | `utils/py/agy-turn.py` | 2/1/2 |
| 2 | The pin. Two stubs — one exiting 0 while emitting a TTY error, one emitting a valid identity — with the pre-fix behaviour observed and recorded as a durable baseline artifact. | `test/gh375-agy-auth-probe.sh`, `validate.sh` | 1/1/2 |

## Litmus tests

- **The negative control is the whole lane.** This probe has never been observed failing; a suite
  that only shows the new check passing would leave it exactly as unevidenced as it is now.
- **Matching on the error text alone is not enough.** It works today and stops working silently the
  next time `agy` rewords its output. The assertion must be positive.
- **Deleting the evidence must not survive.** Retaining the transcript is what makes the *next*
  failure diagnosable, and it costs nothing.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "path_absent", "path": "test/gh375-agy-auth-probe.sh" },
    { "type": "grep_absent", "path": "utils/py/agy-turn.py", "pattern": "could not open TTY" }
  ],
  "artifacts":     [ "utils/py/agy-turn.py", "test/gh375-agy-auth-probe.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh375-agy-auth-probe.sh" ],
  "remediation":   { "source": "issue#375", "criteria": "the auth probe must verify it produced a result, not that the process exited 0 — ranking summary only, NOT the definition of done (that is the verbatim ## Acceptance block above)" },
  "lanes":         { "agy_safe": [], "orchestrator_only": [] }
}
```

**Probe polarity** (probes detect the **bug**, not the fix): `path_absent` reports `landed` when the
path *exists*; `grep_absent` reports `landed` when the pattern *is found*. Verified 2026-08-06:
`could not open TTY` occurs **0 times** in `utils/py/agy-turn.py`.

**Note the lane assignment.** `agy_safe` is empty deliberately: a lane whose subject is the agy auth
probe should not be built by an agy turn, because a broken probe is precisely what would let that
turn start and then fail in a form that reads as a turn failure.

## Observed failure — 2026-08-07, Litmus marathon phase 2

The defect stopped being a reasoned claim and became a measured one. It fired live during the
Litmus marathon and is what halted phase 2 (`gh343`) after codex had already built and committed
its turn:

```
$ agy whoami
CLI error: bubbletea: error opening TTY: bubbletea: could not open TTY: open /dev/tty: device not configured
$ echo $?
0
```

**Exit 0, with the failure printed to output.** That is the issue's central claim reproduced exactly:
a probe deciding on exit status alone reads this as auth OK. It is also the second half of the claim
— under `stdin=DEVNULL` automation the TTY error path IS the normal path, not an edge case.

What actually stopped the turn was `AGY_AUTH_TIMEOUT_S` (5s), the incidental safety net:

```
agy-turn: agy auth pre-flight timed out after 5s; likely expired auth opening an interactive login.
agy-turn: auth pre-flight: CLI error: bubbletea: error opening TTY: ...
```

So the run was protected by the timeout, not by the check — and the doc's `## Why it matters`
inversion (attended runs protected, unattended not) held in the one direction that mattered here:
the timeout only fires because the hang requires a TTY that automation does not have. Had `agy`
returned promptly instead of hanging, the probe would have passed and the reviewer turn would have
started against an unauthenticated CLI.

This satisfies the GH-419 evidence standard for this lane before it is built: the check has now been
**observed failing**, with the transcript above as the baseline any fix must flip.

## Method note

The measured `agy whoami` behaviour and the established/not-established split are carried from the
issue. The probe marker's absence was verified 2026-08-06 against `development` @ `3b37072`. No open
PR or branch touches this issue — checked before authoring. The live reproduction above was added
2026-08-07 from the Litmus marathon run, not from a re-reading of the issue.
