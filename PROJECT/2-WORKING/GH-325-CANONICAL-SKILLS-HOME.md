---
title: Vendor legacy SWE skills and make skills/ canonical
status: Proposed (1-INBOX — not yet active)
created: 2026-08-30
updated: 2026-08-30
owner: noel
gh_issue: 325
source: https://github.com/HiQS-Labs/XYZ-forge/issues/325
doc_type: feature
complexity: 3
risk: 3
effort: 3
phases: 3
ratings_provisional: true
non_goals:
  - Importing the Giant Brains suite router or the dry/converge skills from PR #324.
  - Rewriting vendored skill prose beyond path, link, and frontmatter corrections required for XYZ-forge.
  - Merging the resulting pull request.
related:
  - PR #323 (stack base carrying recon and debug-mantra)
  - PR #324 (dry and converge, intentionally outside this lane)
goal: >
  Make XYZ-forge standalone for its legacy SWE skills and establish
  skills/<name>/SKILL.md as the only in-repo skill-interface location, with
  working implementation links and deterministic structural verification.
---

# GH-325 — Vendor legacy SWE skills and make `skills/` canonical

Bring the legacy SWE skills into XYZ-forge from `giant-brains-swe-skills`, using
the pinned pre-extraction Giant Brains commit only where the canonical repo has
no corresponding skill. Keep the flat `skills/<name>/` layout, preserve bodies
except for required path/link/frontmatter corrections, and make every shipped
skill independently resolvable from this repository.

The structural half moves the ATE and SWE diagram interfaces out of `utils/`
while leaving their implementation assets under `utils/<name>/`. The existing
HQ split is audited rather than guessed: `skills/hq` is already the interface
and locator, while `utils/hq` is the implementation.

## Acceptance criteria

- Vendor or verify every legacy skill named in issue #325, without importing a
  `MOVED to` stub or the Giant Brains router.
- Keep generic `relay` and `relay-xyz` as distinct protocol and driver layers.
- Move `utils/ate/SKILL.md` and `utils/swe-diagram/SKILL.md` to their canonical
  `skills/` homes and preserve executable implementation paths.
- Update README and architecture skill indexes.
- Prove there are no forbidden cross-repo references, dead relative links,
  stubs, or frontmatter/directory mismatches.
- Pass Tier 1, the bidirectional test registry check, and sequential validation
  in a disposable full clone.

## Status

| What was just completed | What's next |
|---|---|
| Issue opened; source and branch sequencing verified against PRs #323 and #324. | Vendor and re-path the skill interfaces, then run structural and full gates. |

## QA gates

1. Structural sweeps return no unexpected output: forbidden references, dead
   relative links, `MOVED to` stubs, and frontmatter/directory mismatches.
2. `bash validate.sh --tier 1` and
   `bash test/gh306-registry-bidirectional.sh` exit 0.
3. `bash validate.sh --sequential` exits 0 in a separate disposable full clone.
