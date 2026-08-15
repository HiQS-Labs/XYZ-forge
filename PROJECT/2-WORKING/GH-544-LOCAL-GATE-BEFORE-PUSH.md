---
gh_issue: 544
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/544
title: "Local-gate-before-push: retire hosted CI for the private phase, enforce the gate at the push boundary"
status: 2-WORKING
created: 2026-08-14
updated: 2026-08-14
owner: unassigned
doc_type: capture
complexity: 2
risk: 3
effort: 2
ratings_provisional: true
related:
  - "https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/509 — CI minute burn; the boundary this decision sets aside"
  - "https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/528 — suite recalibration; established the coverage is NOT the problem"
goal: >
  Move the gate from hosted CI to the push boundary for as long as the repo is private, without
  losing coverage and without pretending the lost attestation does not matter.
---

## Status

| What was just completed | What's next |
|---|---|
| **BUILT 2026-08-14, both halves.** Parallel default + host detection + announced fallback (`gh544-parallel-default` 29/0). Pre-push gate, `ci.yml` triggers removed, `marathon-closeout.sh` no-checks fix (`gh544-pre-push-gate` 38/0). Codex QA run and adjudicated — **3 Blockers found, all real, all fixed**; one of them was a bug in this lane's own test methodology. | Operator review and merge. One item is deliberately owed: the bare `gh pr checks` exit code on a genuinely check-less PR is stubbed, not observed — this PR is the natural experiment and the result belongs in the baseline. |

## QA — Codex consult, adjudicated

Transcript: `relay-system/2026-08-14/gh544-qa-162122/`. Every finding was verified against the repo
before acting; none was accepted on the reviewer's say-so.

**[Blocker] `test/ci-workflow.sh` still required the removed triggers — CONFIRMED, fixed.**
Reproduced: the full gate came back `EXIT=1, failed: ci-workflow.sh`. That suite is registered, so
the change made the gate red — i.e. the pre-push hook would have blocked every push, including its
own. The two assertions are **inverted** rather than deleted (absence of `push:`/`pull_request:` is
now the assertion), because an accidental re-arm is a two-line edit and the invoice arrives weeks
later. The original assertions are preserved verbatim in a comment so the re-arm is a copy, not a
reconstruction.

**[Blocker] The closeout fix was dead code under `set -e` — CONFIRMED, fixed, and it had FALSE-GREENED.**
The script runs `set -euo pipefail`, so `_checks_out="$(gh pr checks ...)"` on a failing command exits
before `_checks_rc=$?`. Verified independently:
`bash -c 'set -euo pipefail; _o="$(bash -c "exit 1")"; _r=$?; echo REACHED'` prints nothing.
**The suite reported 35/0 against that broken code**, because the harness `eval`'d the block without
`set -e` — running the code under gentler options than production. The capture now sits inside the
`if`; the harness now runs the block under the production shell options; and the regression is pinned
by its own control (9 failures against the old shape). The lesson is recorded in the baseline because
it generalises: **a green suite is evidence only about the environment the suite creates.**

**[Blocker] Hook, test and baseline were untracked while `validate.sh` referenced them — CONFIRMED, fixed.**
Procedural but real: committing `validate.sh` without them would have broken the gate for every other
clone. All ship in one commit.

**[Should] Match structured output, not gh's prose — ADOPTED.** `--json bucket` is now the primary
signal with the prose match retained as a fallback, so a gh wording change degrades to one signal
rather than to silence. Two new cases pin it, including a non-empty bucket that must still refuse.

**[Should] Fail closed, and put the installer in onboarding — ADOPTED.** The hook refused to resolve
the repo root by exiting 0; it now refuses the push, and also refuses when `validate.sh` is missing or
non-executable — a gate that cannot run is not a gate that passed. README Quickstart now carries
`bash githooks/install.sh`.

**[Pass] x3, independently checked and worth keeping:** the delete-parse is correct for SHA-1 and
SHA-256 and gates a mixed push; the parallel default does not leak into qualifying evidence
(`ci-local.sh` loops `TESTS` itself, the macOS boundary pins `--sequential`); and no third automatic
trigger exists (no `schedule`, no `workflow_call`, and branch protection cannot start a workflow).

## Release placement

**Nightwatch 0.3.x band, in-band backlog — NOT a manifest entry** (operator decision 2026-08-14).
Nightwatch's manifest stays FROZEN at eight and its RC evidence is untouched; this work is covered by
that block's existing "anything filed during execution ... none of them gates the release" clause, so
**no `RELEASES.md` edit was made** — a line added to a frozen block is how a manifest grows quietly.

Meter 0.6.0 was the near-exact subject fit (#509 is already a member and this is its successor) and
was rejected anyway: this is a live posture change, not a deliverable to schedule two releases out.
Plumbline 0.4.0 is next by sequence but has no exit criterion, no manifest, and no milestone — and
admitting a member before the exit criterion is written inverts the ordering that made Litmus and
Nightwatch measurable.

## Why

Hosted CI cost $10.00 billed in fourteen days and is **currently blocked** at the spending limit, so
this is not a hypothetical optimisation — CI is already off, and the choice is between restoring it
and replacing it.

The decision is an **exec call about where the bill lands, not a judgement about the tests.** #528
already settled the test question in the opposite direction: zero redundant suites, the wait-time
hypothesis falsified, the slow suites earning their time by proving real containment failures. The
coverage stays exactly as it is. What changes is that it runs on the operator's machine at push time
instead of on a rented one at push time.

**The cost basis is temporary and its expiry is known.** Actions is free and unmetered on public
repositories, so this posture is scoped to the private phase by construction. That is why the re-arm
trigger is an event ("the repo goes public") rather than a date or a budget review — there is nothing
to review, the constraint simply ceases to exist.

## Key concepts

- **A gate that gets bypassed is worth less than no gate.** This is the reasoning behind running
  `validate.sh --parallel 8` (~167s) rather than the sequential gate (~950s) in the hook. Sixteen
  minutes on every push does not produce sixteen minutes of testing; it produces `--no-verify` as a
  reflex and a false belief that the gate is running. Three minutes is a cost that actually gets
  paid. #528 Phase 1 measured `--parallel 8` as byte-identical in pass/fail set to sequential, so
  this buys speed without buying a different answer. Sequential `ci-local.sh` is untouched and
  remains the only thing that qualifies a claim.

- **Setting a principle aside is not the same as disproving it.** GH-509's position — self-reported
  local evidence is circular, promotion needs a machine that is not yours — is correct, and this
  issue does not argue otherwise. It knowingly accepts an unattested private phase and writes down
  the debt. `gate-record.sh`'s `NOT-promotion-evidence: self-reported` line becomes permanently true
  and undischargeable until the repo is public. That line was already pinned by a test (GH-536); it
  now describes the steady state rather than a caveat.

- **Turning off a check turns off everything downstream of it.** `marathon-closeout.sh:162` refuses
  to merge unless `gh pr checks` passes. With no workflows firing, PRs have zero checks — a state the
  script has never seen and does not distinguish from failure. The break is in automation nobody
  would think to look at when editing a workflow file, which is the whole reason it belongs in this
  doc.

- **Linux drift will accumulate silently.** The local gate is macOS, which is the platform we ship
  to, so the *platform* stays covered. What disappears is the ubuntu portability canary. Drift will
  not stop happening; it will stop being reported, and will surface as a batch on the first run after
  re-arm. Naming it here makes it a scheduled cost at re-arm instead of a surprise.

## Acceptance

Copied verbatim from issue #544.

- [ ] A `pre-push` hook ships in-repo and is installed by a documented, idempotent command.
- [ ] Pushing with a red gate is **blocked**, and the failure names the failing suite.
- [ ] Pushing with a green gate succeeds, and the gate's wall-clock is printed.
- [ ] Both escape hatches work and both announce themselves on stderr.
- [ ] A branch delete (`git push --delete`) does not run the gate.
- [ ] `ci.yml` no longer fires on `push` or `pull_request`; the file and its reasoning survive intact.
- [ ] The macOS job has no `workflow_dispatch` trigger.
- [ ] `marathon-closeout.sh` distinguishes *no checks configured* from *checks failed*, with the bare
      `gh pr checks` exit code verified against a real check-less PR rather than assumed.
- [ ] A recorded negative control per #419: the hook observed **red** against a deliberately failing
      suite, not merely observed green.
- [ ] `AGENTS.md` and `ROUTER.md` carry the rail: local gate before push, hosted CI off, re-arm when public.
- [ ] The re-arm conditions are written down where the person flipping the repo public will find them.

## Measurements this lane inherits (do not re-derive)

| Fact | Value | Source |
|---|---|---|
| Aug 1-14 spend | $21.99 gross / $10.00 billed | invoice + Actions API |
| Included allowance | 2,000 min/mo, exhausted Aug 11 | #528, independently confirmed in #509 |
| Spending limit | $10, hit Aug 14 — Actions blocked | check-run annotation |
| Sequential gate | ~950s, 190 suites | #528 spike |
| `--parallel 8` | 167-184s, pass/fail set byte-identical | #528 Phase 1 |
| Branch protection | **unavailable** (Free tier, HTTP 403) | measured 2026-08-14 |
| Harness auto-push sites | exactly one: `marathon-closeout.sh:141` | grep, comments excluded |

## Risks

1. **The hook is per-clone, not per-repo.** `core.hooksPath` lives in `.git/config`, which is not
   version-controlled and does not propagate. A fresh clone, a second machine, or a linked worktree
   cut before installation has **no gate at all** and will push unverified. The installer must be in
   the onboarding path, and its absence should be detectable rather than silent.
2. **`--no-verify` is unremovable.** Native git, cannot be disabled. The mitigation is that it is a
   deliberate keystroke rather than an accident, and that the hook is fast enough not to invite it.
3. **A three-minute gate on `marathon-closeout.sh`** changes automated closeout timing. Recommended
   resolution: let it run (closeout is the moment work reaches the remote, and the in-phase gate ran
   against a different tree), but this is a decision to make explicitly rather than by default.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [
    { "kind": "grep_present", "path": ".github/workflows/ci.yml",
      "pattern": "^  push:",
      "note": "bug evidence: ci.yml still fires automatically on push" },
    { "kind": "grep_present", "path": "relay-automation/marathon-closeout.sh",
      "pattern": "if ! gh pr checks",
      "note": "bug evidence: closeout cannot tell no-checks-configured from checks-failed" }
  ],
  "artifacts":   [
    "githooks/pre-push",
    "githooks/install.sh",
    ".github/workflows/ci.yml",
    "relay-automation/marathon-closeout.sh",
    "test/gh544-pre-push-gate.sh",
    "validate.sh",
    "AGENTS.md",
    "ROUTER.md"
  ],
  "remediation": {
    "source": "issue#544",
    "criteria": "Gate enforced at the push boundary by an in-repo hook; hosted CI triggers removed without losing the file or its reasoning; closeout's check gate made no-checks-aware."
  },
  "lanes":       { "agy_safe": [], "orchestrator_only": [".github/workflows/ci.yml", "githooks/pre-push"] }
}
```

Contract authored by hand from the issue text, not auto-drafted. `orchestrator_only` covers the two
paths where a wrong edit is expensive: the workflow file (silently re-arms billing) and the hook
(silently stops gating).
