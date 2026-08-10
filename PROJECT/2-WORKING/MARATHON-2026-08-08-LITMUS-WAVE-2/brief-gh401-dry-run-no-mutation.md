---
title: "Phase brief: GH-401 gh401-dry-run-no-mutation (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-08-08
updated: 2026-08-08
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh401-dry-run-no-mutation
  phase of MARATHON-2026-08-08-LITMUS-WAVE-2 — not itself an active-doc capture; the canonical
  capture doc is GH-401-DRY-RUN-MUTATES-REPO.md two levels up.
roadmap_exempt: true
---

# Brief — GH-401: `--dry-run` must not write into a repo it was not pointed at

## Status

| What was just completed | What's next |
|---|---|
| Contract authored and verified READY. Acceptance criteria authored onto the issue (it had none) and **revised after an adversarial codex+agy review that caught a first wording which would have broken a legitimate existing test**. Observed live twice. | Fire as phase 2 of 3, after gh416. |

**Parent doc:** `PROJECT/2-WORKING/GH-401-DRY-RUN-MUTATES-REPO.md`
**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/401

## Acceptance

**Read the acceptance criteria from the parent capture doc's `## Acceptance` block**, copied verbatim
from the issue. Do not work from a paraphrase — see GH-400.

## The defect

`marathon-drive --dry-run` renders into the **harness's own tracked** `phases/p1/RELAY.md` when it is
invoked with no phases directory and no marathon root. Two kinds of change land in that tracked file:
the debug-mantra block is dropped (a freshly rendered relay has no prior attempt), and every embedded
tick path is rewritten to whatever absolute path the current checkout has. The diff therefore churns
to a different value for every machine and reverts for whoever committed last.

**This is not a historical report.** Two full `validate.sh` runs, on 2026-08-05 and 2026-08-06, each
left `phases/p1/RELAY.md` modified and had to be reverted by hand. The second time it appeared in a
`git status` next to a PR branch and was very nearly swept into a commit.

**The existing guard does not cover it.** `test/marathon-root-audit.sh` exists for exactly this class
— *"every marathon invocation is root-scoped"* — but its scope is **two hardcoded filenames**. The
offending test is out of reach because of its *filename*, not because it is safe. That is the #419
shape: a guard reporting a clean verdict on a question it never asked.

## The correction that already cost one round — do not re-make it

The first version of criterion 1 read *"`--dry-run` writes nothing into any git repository."* Codex
found that this **contradicts a legitimate existing test**: `test/marathon-drive.sh` asserts
*"dry-run renders phases/p1/RELAY.md"* against a fixture root the caller supplied, which is correct
behaviour and must keep passing.

The criterion now says **outside the root it was given**. The defect is writing into the *harness*
when no root was supplied — not rendering at all. **If `test/marathon-drive.sh`'s fixture-root
assertion breaks, the lane has over-corrected and the turn has failed**, even if everything else is
green.

## What to build

- **Phase 1 — non-mutating dry run.** `--dry-run` writes nothing outside the root it was given. If a
  render is genuinely needed to validate a phase, render to a temporary path and discard it. Point
  the unscoped driver invocations in `test/gh268-relay-cue-and-target-checks.sh` at a temp root, as
  every other driver test already does.
- **Phase 2 — recurrence and the artifact question.** Widen `test/marathon-root-audit.sh` so it
  catches an unscoped invocation **by content**, and prove it with a fixture: an unscoped invocation
  in a test whose filename does **not** match the audit's current two-name pattern. Then settle
  whether `phases/p1/RELAY.md` should be tracked at all — a tracked copy is retained only if a named
  consumer of the committed file is identified, and it must contain no machine-specific absolute
  paths.
- Register `test/gh401-dry-run-no-mutation.sh` in `validate.sh`.

## Litmus tests for this lane

- **Cleanliness must be byte-identical, not merely clean.** Running the full suite must leave
  `git status --porcelain` byte-identical to before, **including a pre-existing untracked sentinel
  file the suite did not create**. A suite that reaches a clean tree by deleting things it did not
  create has made this worse, and the sentinel is the assertion that catches it.
- **The audit must be proven by a fixture, not by its shape.** "Discovers by content" is *how*, not
  *whether*. The evidence is the fixture going red before the widening and green after.
- **The negative control is recorded, not asserted.** Per #419 and GH-419's principle 13, the new
  suite carries a `# gate-evidence:` declaration naming form, observation and result, and states the
  reproducer command, the pre-fix revision, the pre-fix result and the post-fix result. A sentence
  claiming a control happened is not the record.

## Scope

`utils/py/marathon_drive.py`, `test/gh268-relay-cue-and-target-checks.sh`,
`test/marathon-root-audit.sh`, `test/gh401-dry-run-no-mutation.sh` (new), `validate.sh`.

**Python only.** `relay-automation/marathon-drive.sh` is a GH-308 frozen twin — do not touch it. A
behaviour change there requires a declared `Frozen-twin-exception:` commit trailer, which this lane
does not have and does not need.

**Sequencing note you are entitled to know:** this phase runs *inside* a live marathon, and the file
you are changing is the same `utils/py/marathon_drive.py` that drives the phase after this one. Keep
the change confined to the `--dry-run` path, which a real run never takes. Do not refactor shared
helpers on the live path to make the dry-run path tidier — that is how this lane would wedge the rest
of the chain.
