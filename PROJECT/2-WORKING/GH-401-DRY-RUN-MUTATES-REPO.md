---
gh_issue: 401
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/401
title: "GH-401 — marathon-drive --dry-run writes to the harness's own tracked phases/p1/RELAY.md"
status: "In flight (2-WORKING) — captured 2026-08-06 for release 0.2.0 Litmus. Preflight READY (5/5 acceptance verbatim, re-verified 2026-08-08); operator go given; queued as phase 2 of 3 in MARATHON-2026-08-08-LITMUS-WAVE-2. Previously deferred to 0.3.0 Nightwatch on theme; that deferral was reversed because the issue is on the Litmus MILESTONE."
created: 2026-08-06
updated: 2026-08-08
owner: noel
doc_type: project
release: "0.2.0 Litmus"
complexity: 2
risk: 2
effort: 2
phases: 2
ratings_provisional: true
related:
  - "#419 — the class. An existing guard (marathon-root-audit) reads as covering this and does not, because its scope is two hardcoded filenames."
  - "#209 — that audit, whose filename-based scope leaves this uncovered."
  - "#325 — added the test, and committed the rendered artifact that has been churning since."
non_goals:
  - "Changing what --dry-run renders when it is correctly scoped. Rendering into a caller-supplied fixture root is legitimate and an existing test asserts it."
  - "Removing the driver test. Its coverage is wanted; only its scoping is wrong."
goal: >
  A dry run mutates the working tree. `marathon-drive.sh --dry-run`, invoked without a marathon root
  or phases dir, renders and writes a **tracked** file in the harness repo itself, and a test invokes
  it that way twice — so a plain `validate.sh` leaves the repo dirty. The diff is machine-dependent,
  so it churns to a different value for every person who runs the suite.
---

# GH-401 · a dry run that mutates the repo

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-06 as a lane of release 0.2.0 Litmus. Acceptance criteria authored on the issue (it had none) and revised after an adversarial codex+agy review, which caught that my first wording would have broken a legitimate existing test. **Observed live during this session's own suite runs**, twice. | Operator go. Then Phase 1 (non-mutating dry run + scoped test invocations) and Phase 2 (the audit widened by coverage, and the tracked-artifact question settled). |

## The defect

Two kinds of change land in a tracked file: the debug-mantra block is dropped, because a freshly
rendered relay file has no prior attempt; and every embedded tick path is rewritten from whatever
absolute path was baked into the committed version to whatever checkout ran it. So the diff churns
to a different value for every person who runs the suite, and reverts for whoever last committed it.

**Why it matters:**

- **A dry run is expected to be side-effect free.** That is the entire contract of the flag, and it
  is the flag most likely to be reached for when someone is unsure what a command will do.
- **`validate.sh` leaves the tree dirty**, so "run the suite" and "check nothing changed" conflict.
- **The pollution is easy to commit by accident**, and once committed it re-dirties for the next
  person on a different machine. That has already happened.
- **It interacts badly with containment.** A relay turn that finds the file modified sees a file it
  did not touch inside the repo it is working in.

**The existing guard does not cover it.** `test/marathon-root-audit.sh` exists for exactly this class
— *"every marathon invocation is root-scoped"* — but its scope is two hardcoded filenames. The
offending test is out of reach because of its **filename**, not because it is safe.

## Observed live, twice, during this session

This is not a historical report. Two full `validate.sh` runs on 2026-08-05 and 2026-08-06 each left
`phases/p1/RELAY.md` modified in the working tree, and both had to be reverted by hand before
committing unrelated work. The second time it appeared in a `git status` alongside a PR branch and
was very nearly swept into a commit.

## A correction the review produced

My first criterion read *"`--dry-run` writes nothing into any git repository."* Codex found that this
**contradicts a legitimate existing test**: `test/marathon-drive.sh` asserts *"dry-run renders
phases/p1/RELAY.md"* against a fixture root supplied by the caller, which is correct behaviour and
should keep passing. The criterion now says *outside the root it was given* — the defect is writing
into the **harness** when no root was supplied, not rendering at all.

## Acceptance

*Copied verbatim from [issue #401](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/401)
(`## Acceptance`), fetched 2026-08-06. Deviations, if any, are recorded below this block.*

- [ ] `--dry-run` writes nothing outside the root it was given. In particular it never writes into the harness repository when invoked without a phases directory or marathon root. Rendering into a fixture root the caller supplied stays legitimate.
- [ ] Running the full suite leaves `git status --porcelain` **byte-identical** to before, including a pre-existing untracked sentinel file — the suite must not reach cleanliness by deleting things it did not create.
- [ ] The root-scoping audit fails on an unscoped driver invocation placed in a test whose filename does not match its current two-name pattern, and passes once that invocation is scoped. Coverage is proven by that fixture, not by the scanner's shape.
- [ ] A dry run never leaves `phases/p1/RELAY.md` inside a repository. A tracked copy is retained only if a named consumer of the committed file is identified, and it contains no machine-specific absolute paths.
- [ ] The regression test is observed failing against the pre-fix revision, and a durable record states the reproducer command, the pre-fix revision, the pre-fix result and the post-fix result. A sentence asserting a negative control happened is not the record, per #419.

## Acceptance — deviations from the issue

None. Every criterion is carried verbatim.

The criteria were **authored onto the issue on 2026-08-05** (it had none) and **revised on 2026-08-06**
after the codex+agy review — for the over-broad wording above, for *"leaves the working tree clean"*
(which permitted reaching cleanliness by deleting a user's pre-existing untracked files), and for
*"decided and the decision recorded"*, which any decision satisfied including "yes, no reason given".

## Phases

| Phase | Deliverable | Artifacts | cx/risk/eff |
|---|---|---|---|
| 1 | Non-mutating dry run. `--dry-run` writes nothing outside the root it was given; if a render is needed to validate the phase it goes to a temporary path and is discarded. The unscoped driver invocations are pointed at a temp root, as every other driver test already does. | `utils/py/marathon_drive.py`, `test/gh268-relay-cue-and-target-checks.sh` | 2/2/2 |
| 2 | Recurrence + the artifact question. The root-scoping audit is proven to catch an unscoped invocation in a differently-named test, and the tracked-artifact question is settled against a concrete state requirement rather than a recorded opinion. | `test/marathon-root-audit.sh`, `test/gh401-dry-run-no-mutation.sh`, `phases/p1/RELAY.md`, `validate.sh` | 2/1/2 |

## Litmus tests

- **Cleanliness must be byte-identical, not merely clean.** A suite that reaches a clean tree by
  deleting a pre-existing untracked file has made things worse. The sentinel file is the assertion.
- **The audit must be proven by a fixture, not by its shape.** "Discovers by content" is how, not
  whether; the test is an unscoped invocation in a file whose name does not match the old pattern.
- **The legitimate render must keep passing.** If `test/marathon-drive.sh`'s fixture-root assertion
  breaks, the lane over-corrected.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "path_absent", "path": "test/gh401-dry-run-no-mutation.sh" },
    { "type": "grep_present", "path": "test/marathon-root-audit.sh", "pattern": "HERE/marathon-drive.sh" }
  ],
  "artifacts":     [ "utils/py/marathon_drive.py", "test/gh268-relay-cue-and-target-checks.sh", "test/marathon-root-audit.sh", "test/gh401-dry-run-no-mutation.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh401-dry-run-no-mutation.sh" ],
  "remediation":   { "source": "issue#401", "criteria": "a dry run must not mutate a repo it was not pointed at, and the audit must catch the next one — ranking summary only, NOT the definition of done (that is the verbatim ## Acceptance block above)" },
  "lanes":         { "agy_safe": [], "orchestrator_only": [] }
}
```

**Probe polarity** (probes detect the **bug**, not the fix): `path_absent` reports `landed` when the
path *exists*; `grep_present` reports `landed` when the pattern is **no longer found**. The second
probe is the audit's two-filename scope itself — present today (verified 2026-08-06) and it flips to
`landed` exactly when the audit stops enumerating driver files by name.

## Method note

The reproduction, the machine-dependent diff and the audit's filename-scope finding are carried from
the issue. The conflict with `test/marathon-drive.sh`'s legitimate fixture-root assertion came from
the codex review and was verified before rewording. The dirty-tree behaviour was observed directly
twice during this session. No open PR or branch touches this issue — checked before authoring.
