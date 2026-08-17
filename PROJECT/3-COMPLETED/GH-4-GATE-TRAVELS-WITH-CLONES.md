---
gh_issue: 4
source: https://github.com/HiQS-Suite/XYZ-forge/issues/4
title: "GH-4: the pre-push gate does not travel with clones — fresh clones push unverified"
status: active
created: 2026-08-16
updated: 2026-08-17
owner: orchestrator (Claude Code)
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  A fresh clone that has not run githooks/install.sh is loudly surfaced as ungated, in-band, on
  the documented first-run path — the missing gate stops being invisible — and the README
  quickstart names the install step as a correctness requirement.
---

# GH-4 — the gate travels with the repo, not just with the clone

## Status

| What was just completed | What's next |
|---|---|
| Landed 2026-08-17, orchestrator-authored directly (a prior driven-marathon attempt escalated after 5 rounds without landing — see the negative-control doc's design note). `validate.sh` now warns, non-fatally, when the clone is ungated; README documents the install step as a correctness requirement; negative control recorded (both directions verified: fires when ungated, silent when gated). | Closed |

## Bug

Hosted CI fires on nothing in this repo (`ci.yml` carries only `workflow_dispatch`), so the only
gate is the local pre-push hook — and that hook is wired **per clone** by
`githooks/install.sh`. A fresh clone, a second machine, or an outside contributor who never ran
the installer has **no gate at all**: their pushes land unverified with nothing downstream to
catch what was skipped. The repo going public made this strictly worse — every outside
contributor is now in the ungated population by default.

Scope note (Ballast): the fix here is LOCAL. Re-arming hosted CI is #16, an explicit Ballast
non-goal — with CI off, an outside contributor has no gate at all, which is precisely why the
local surface has to carry the warning. A push cannot be locally refused with no hook installed
(git reads hooks from `.git/hooks`, which does not travel with a clone); the deliverable is that
the ungated state stops being invisible.

## Source of truth

- GitHub issue: [HiQS-Suite/XYZ-forge#4](https://github.com/HiQS-Suite/XYZ-forge/issues/4)

## Acceptance

- [x] Surface the gate status in-band: something that travels with the repo content itself (e.g. a committed marker or a first-run check that warns when the hook wiring is absent) reports an ungated clone, rather than relying on the contributor having read the README.
- [x] A fresh clone that has not run the installer produces a visible, in-band warning (or refusal) naming the missing gate and the one-command fix, on the documented first-run path; with the gate installed the push path behaves exactly as today.
- [x] Document prominently in the README quickstart that the install step is a correctness requirement, not optional setup.
- [x] A recorded negative control (under `test/baselines/`) demonstrates the new check failing when the fix is reverted, per the standing rule that a check never observed failing is not evidence.
- [x] A recorded negative control exists at `test/baselines/GH-4-negative-control.md`

## Acceptance — deviations from the issue

- [added] A recorded negative control exists at `test/baselines/GH-4-negative-control.md` — reason: pins this contract's staleness probe and the issue's negative-control criterion at the same file, so the acceptance and the probe cannot drift apart.

**Implementation note (not an acceptance-text deviation):** the fix touches `validate.sh`, outside
the original artifact list (which was scoped to avoid a merge conflict with lane #10's own
`validate.sh` edits if both were driven concurrently through the harness). #10 was cut from
Ballast the same day this landed — see `PROJECT/2-WORKING/GH-10-REQUIRE-FIXTURE-ADOPTION.md` —
so that conflict no longer applies. Full design rationale and both-directions verification are in
`test/baselines/GH-4-negative-control.md`'s design note.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash validate.sh",
  "fix_probes":  [
    { "type": "path_absent", "path": "test/baselines/GH-4-negative-control.md" },
    { "type": "grep_absent", "path": "README.md", "pattern": "githooks/install\\.sh[^\\n]*correctness requirement" }
  ],
  "artifacts":   [ "README.md", "githooks/install.sh", "test/baselines/GH-4-negative-control.md" ],
  "artifacts_new": ["test/baselines/GH-4-negative-control.md"],
  "remediation": { "source": "issue#4", "criteria": "an ungated fresh clone is surfaced in-band; install documented as a correctness requirement" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```

Probe polarity: both probes carry FIX markers (the mandated negative-control record, and the
README quickstart line naming the install a correctness requirement). The lane is ready while
both are absent and reports stale (exit 4) once either lands. If the lane's fix legitimately
needs to touch `validate.sh` or `ci-local.sh` (not in `artifacts`), say so in the lane brief —
those paths overlap lanes #15 and #10 and force serialization.

## Verification

- Fresh clone (no installer run): the documented first-run path warns/refuses naming the gate and
  the one-command fix. After `bash githooks/install.sh`: push path identical to today.
- `bash test/gh308-frozen-twin-guard.sh --check --staged` clean (no twins touched).
- Negative control recorded under `test/baselines/GH-4-negative-control.md`.
