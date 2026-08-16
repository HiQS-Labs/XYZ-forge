# PDDA sync review policy

## Purpose and scope

This is the review policy for a dependency sync that changes `utils/pdda/**` or another
imported PDDA surface. It applies to every such sync — one that **adds, modifies, or deletes**
files, not only one whose diff is obviously destructive, because the incident that produced this
policy arrived inside a sync that looked like an ordinary update. It protects repo-owned behaviour
from being mistaken for a stale upstream artifact.

This file is deliberately repo-owned. Neither `PROJECT/PDDA.md` nor anything under `utils/pdda/**`
can be the durable home for a policy about reviewing a sync: both are sync **inputs** and may be
replaced wholesale by the next one. That is not hypothetical — `cfd56b0` replaced the sync-managed
`utils/pdda/**` tree in exactly that way, which is how the guardrails went missing.

## Before a sync is approved

The author supplies a deletion inventory for the sync footprint: every removed path, its previous
purpose, and its classification below. The reviewer reads that inventory against the actual diff;
a rename or a replacement still counts as a deletion until the replacement is identified.

1. A deletion may proceed without explicit local sign-off only when it is demonstrably
   sync-owned: it is an upstream-managed/generated artifact, the imported upstream manifest or
   generator no longer produces it, and the local-history and registration checks below show no
   local behaviour attached to it.
2. A deletion requires explicit maintainer sign-off in the pull request when it removes or changes
   a repo-owned guardrail, local check, test, workflow/validation registration, policy, or
   documentation that records local behaviour. The sign-off records the path, why it is safe to
   remove, the replacement (or why none is needed), and the verification to run.
3. A sync must not delete repo-owned checks merely because they sit near an imported tree. In
   particular, `utils/pdda-local-checks.sh` and `test/pdda-local-checks.sh` are local seams, not
   sync input. New local behaviour belongs outside `utils/pdda/**` so a later sync cannot silently
   remove it.

## Classifying a deletion

For each removed path, the reviewer checks these concrete signals before accepting the
"sync-owned" classification:

- **Registration:** search `validate.sh`, CI workflows, dispatchers, and documentation for the
  path or its command. A registered validation path is a guardrail candidate, not disposable
  generated output.
- **Coverage:** check whether a repository test exercises the path, and whether any repo-owned
  script calls it. Either makes it repo-owned regardless of where it sits in the tree — a file can
  be unregistered in `validate.sh` and still be load-bearing for something that is.
- **Issue provenance:** look for a `GH-<number>` reference in the file, adjacent docs, and commit
  history. A file added to fix a tracked defect is local behaviour unless the owner explicitly
  retires it.
- **History:** inspect the commit that introduced the path. A fix or feature commit is evidence of
  deliberate local intent; a prior dependency-sync commit plus the upstream manifest/generator is
  evidence that it is imported.
- **Replacement:** if the sync changes rather than simply removes behaviour, identify the new path
  and verify that it preserves the local contract. A filename move alone is not evidence.

Any positive local signal makes the deletion a guardrail candidate and triggers explicit sign-off.
No signal is not permission to assume a file is stale: if the manifest, provenance, or replacement
is unclear, classify it as ambiguous, stop approval, and ask the PDDA maintainer or the owner of
the originating issue. Resolve the classification in the pull-request discussion before merge.

## Evidence that is insufficient

A green suite after follow-up fixups is not evidence that a deletion was safe. Fixups can restore
only the failures that happened to be visible, while a deleted check can hide the condition it was
meant to detect. The review needs the deletion inventory and the classification evidence above;
test results verify the chosen outcome, not the deletion's intent.

## Enforcement and exceptions

The sync author owns the inventory. The reviewing maintainer enforces this policy by blocking the
pull request until every deletion is classified and every guardrail candidate has recorded
sign-off. CI and `validate.sh` enforce mechanical contracts and remain required verification, but
they do not replace the human intent review.

If the policy was skipped, do not merge on the strength of a green suite. Request changes before
merge; if it is discovered after merge, treat it as a release-blocking review defect: restore or
otherwise contain the affected behaviour, record the missed classification in the follow-up issue,
and review the sync deletion inventory before considering the incident closed.
