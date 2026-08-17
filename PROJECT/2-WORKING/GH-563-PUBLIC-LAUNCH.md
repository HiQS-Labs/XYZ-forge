---
gh_issue: 563
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/563
title: "Public repository launch: release, security, front-door, and shakedown readiness"
status: 2-WORKING
created: 2026-08-15
updated: 2026-08-17
owner: unassigned
doc_type: capture
complexity: 4
risk: 4
effort: 4
ratings_provisional: true
related:
  - "https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/555 — Meter's exit criterion; the gate that measures this launch"
  - "https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/544 — hosted CI fires on nothing while private; going public is its re-arm trigger"
  - "https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/564 — 31 unaudited suites reachable through an empty fixture path; the shakedown runs the suite"
goal: >
  Publish XYZ through one auditable cutover: a sanitized, fresh-history artifact that an
  unauthenticated stranger can clone and use, with recorded evidence for the exact published commit.
---

## Status

| What was just completed | What's next |
| --- | --- |
| The public artifact is live; its documented stranger path completed 214/214 checks; `/front-door` and `/shakedown` were run; the installed `relay-xyz` locator was fixed; hosted CI triggers were restored | Push the audited commit, record its hosted macOS result and run the final exact-commit secret scan |

## Why this doc ships

This is one of four capture docs carried into the public artifact. `PROJECT/` is not emptied to a
bare scaffold: it keeps this release's own working documents, so a newcomer reading the method sees
it applied to real work rather than to a placeholder — and so the tree reflects the repository's
actual state on the day it was published.

## The decisions that shape the artifact

Taken by the operator on 2026-08-15 and recorded here because each one changes what the gate checks.

**Meter is the public-repository RC.** The release was re-scoped from its metering manifest; those
five entries moved intact to Sundown. The frozen manifest is #555 and #563, and scope is CLOSED to
further admission.

**Fresh history, one initial commit.** Chosen over carrying 2,147 commits for a stated reason: in a
carried history every document removed during sanitization stays reachable, so the required secret
scan becomes a scan of everything ever deleted rather than a scan of one tree. Fresh history makes
sanitization complete by construction.

**`CHANGELOG.md` is carried verbatim.** It is the public record of the project's history. Keeping the
project's story and keeping its commit history turned out to be separable, and only the first was the
goal. This also makes `CHANGELOG.md` the one internal document that ships unedited, which is why its
absolute home paths were redacted before anything else.

**`git archive`, not a clone.** A clone plus an orphan branch leaves the original object database
physically present in `.git` until a gc; `git archive HEAD` emits exactly the tracked files at one
commit, with no object database at all. The isolation is structural rather than maintained.

**The artifact is a build output, not a hand-sanitized folder.** `utils/build-launch-artifact.sh` is
re-runnable and always produces exactly one commit. This is what lets `/front-door` and `/shakedown`
review a real artifact early instead of waiting until the end.

## Acceptance

Carried from the issue. The executable form is `bash test/meter-release.sh --release-gate`.

- [x] An unauthenticated user can clone the published repository, follow its documented entry path,
      and exercise the supported happy path without private context.
- [ ] A secret scan of the published artifact is recorded, naming its exact tool version and the
      exact commit it covered.
- [x] The public license posture is internally consistent (`LICENSE`, `LICENSE-COMMERCIAL.md`).
- [ ] Hosted CI is re-armed per #544 with a green run for the exact published commit.
- [x] `/front-door` and `/shakedown` are run against the artifact, with blockers resolved or waived
      in writing.

Front-door verdict: **Bumpy but working.** A credential-free clone can follow the README through
installation, hook setup, and the complete local gate. Nine dead links from that canonical entry
page to the private source tracker were removed. Historical references remain in governance and
release records, but they are not prerequisites for the stranger path.

Shakedown verdict: the primary installed-skill path exposed a real portability defect: the mandatory
first command assumed the caller was standing in the harness repository. `relay-xyz` now locates its
installed helper explicitly, and the focused regression test passes. The dated report is recorded in
`SHAKEDOWN/2026-08-17/relay-xyz-1118.md`.

## Acceptance — deviations from the issue

- [changed] *"a clean full-history secret scan"* -> **a clean scan of the published artifact**, with
  a full-history scan of the private source tracked separately as credential-rotation hygiene —
  reason: with fresh history the artifact is one commit and one tree, and that is the entire public
  exposure. A credential ever committed to the private repository may still need rotating, but that
  is an internal security question and it does not gate a publication that cannot expose it.
  Conflating the two would let a dead credential in unpublished history block a clean release.

## Known open items — waived, not admitted

Scope is frozen, so neither joins the manifest. Each needs a written waiver or a fix before the gate
is called green; per the issue's rule, silence is not a waiver.

- **#564** — 31 unaudited suites can reach the caller's clone through an empty fixture path. Bears on
  the launch because both the shakedown and the exit criterion run the suite.
- **#544** — hosted CI fires on nothing while the repository is private, and going public is its own
  documented re-arm trigger.
