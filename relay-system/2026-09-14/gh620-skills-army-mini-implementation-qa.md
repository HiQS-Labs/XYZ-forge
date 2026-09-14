---
Goal: QA GH-620 implementation against its approved plan and issue
Date: 2026-09-14
NEXT: claude
STATUS: Changes requested
---

# Context

Review the complete branch diff `origin/development...HEAD`, issue #620, and
`PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md`. Important implementation paths are
`utils/py/xyz_mini_sync.py`, `test/gh620-skills-army-mini-sync.sh`,
`skills/skills-army-hq/README.md`, `mini/skills-army-*`,
`skills/push-to-skills-army-mini/SKILL.md`, and `docs/SPIN-OFF-REPOSITORY-PLAYBOOK.md`.

Operational envelope: manual, local publisher for one public generated child. Forge remains the
only authority. Apply commensurate MVP complexity: reject duplicate engines and speculative
frameworks, schedulers, recovery machinery, fuzzers, matrices, or mirrored child suites.

Producer evidence:

- Missing required manifest entry witnessed red: `rc=1`, literal-set and manifest assertions failed.
- Restored GH-620 suite: 15/15.
- Existing XYZ-mini publisher: 18/18.
- Existing Skills Army suite: 25 tests + 4 subtests passed.
- CI routing: 76/76; bidirectional test registry: 10/10.

Questions:

1. Does the fixed target profile preserve default XYZ-mini behavior and avoid a second publisher?
2. Does the live origin/main preflight refuse arbitrary wrong-branch/ahead/behind/divergent state before writes while permitting only unborn, exact, or exact retained-publisher retry state?
3. Is the generated Skills Army payload exactly closed and free of machine/operator state, with a child-valid init path?
4. Do the literal oracle, mutant, detached init/add/target/sync smoke, idempotence, provenance, and stale-remote case substantiate the issue without excess tests?
5. Does the playbook cover all seven reusable recipe phases while preserving one authority and rollback path?
6. Are any acceptance criteria missing, claims false, or changes unrelated? Sweep every changed implementation file.

Append a concise review with file:line citations. End with exactly `VERDICT: PASS`, `FAIL`, or
`PARKED` and a non-empty `Basis:`. Set `STATUS: Approved` only on PASS.

## Log

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex implementation review — changes requested

The shared two-profile publisher, literal payload oracle, detached smoke, routing, wrapper, and
seven-section recipe are appropriately bounded, but two acceptance claims are not yet true.

1. **Child-valid quick start — fail.** The package README says its commands work from either the
   child repository root or the package directory, then invokes `./scripts/intake.py`
   (`skills/skills-army-hq/README.md:64-73`). In the generated child, the script is actually at
   `./skills-army-hq/scripts/intake.py` (`utils/py/xyz_mini_sync.py:59-64`), as the landing README
   correctly shows (`mini/skills-army-README.md:12-18`). A cold child-root operator following the
   package README gets a missing-file error, so the required child-valid init path is not satisfied.
2. **Exact retained-publisher retry — fail.** The preflight accepts any one-commit-ahead HEAD whose
   parent, subject, `MANIFEST.txt`, and revision marker match (`utils/py/xyz_mini_sync.py:149-158`).
   It does not compare the retained commit's full tree/diff to the payload that this run would
   generate. Consequently, a commit with the expected metadata plus an unrelated tracked file is
   treated as the exact publisher retry and can be pushed, contradicting the claim that arbitrary
   ahead state is refused. The new suite covers an independently advanced remote, but never the
   allowed-retry path or a matching-metadata/extra-file mutant
   (`test/gh620-skills-army-mini-sync.sh:64-68`, `test/gh620-skills-army-mini-sync.sh:104-109`).

Everything else reviewed is consistent with the MVP envelope: the target defaults to `xyz-mini`,
the Skills Army manifest closes over the six package files plus landing files/licenses, generated
state is excluded, the detached init/add/target/sync workflow is exercised, CI routing is registered,
and the playbook covers qualify/manifest/bootstrap/test/land/maintain/rollback without introducing a
second engine or scheduler (`utils/py/xyz_mini_sync.py:29-79`,
`test/gh620-skills-army-mini-sync.sh:49-102`, `docs/SPIN-OFF-REPOSITORY-PLAYBOOK.md:1-47`,
`utils/ci-route.sh:33-45`). Graph coverage for the new branch files was unavailable/stale, so these
findings use direct source reads; no project gate was run in this reviewer turn.

VERDICT: FAIL
Basis: the child-root quick start is broken and the retained-retry exception can admit unrelated ahead content

## Producer disposition — round 1

Both findings are accepted. The package README now scopes `./scripts/...` commands to the package
folder and tells child-root users to enter that folder or follow the landing README. Retry eligibility
now requires the commit's changed paths to be contained in current/previous managed paths plus the
two controls, and every current managed payload byte and executable mode to match the parent source.
The focused test adds an allowed exact-retry push and a same-metadata amended-extra-file refusal.

Handing back to Codex for implementation re-review.

## Codex implementation re-review — changes requested

The child-root quick-start finding is resolved: the package README now scopes `./scripts/...` to the
package directory and explicitly directs a child-root operator to enter it or use the landing README
(`skills/skills-army-hq/README.md:64-74`; `mini/skills-army-README.md:12-20`). The retained-retry
finding is only partially resolved.

1. **Exact retained-publisher retry — still fail.** The guard allows every path in the previous
   manifest, but validates bytes and executable mode only for files in the *current* managed payload
   (`utils/py/xyz_mini_sync.py:160-178`). A matching-parent/subject/manifest/revision commit can
   therefore retain or arbitrarily alter a previously managed path that the current manifest dropped
   and still be accepted, even though the publisher itself would delete that path
   (`utils/py/xyz_mini_sync.py:224-240`). That state is not the exact commit this run would generate.
   The added mutant proves refusal only for a never-managed `UNRELATED.md`; it does not exercise a
   dropped previously managed path (`test/gh620-skills-army-mini-sync.sh:70-84`). The same allowlist
   also omits seed paths, so the default XYZ-mini profile can reject an otherwise exact retry when it
   newly restores an absent seed such as `TODO.md` (`utils/py/xyz_mini_sync.py:55,161,225`). Compare
   the retained commit's complete managed/seed result to the publication plan: current managed files
   must match, previous-only managed files must be absent, and a seed changed by this publication must
   match the generated commit.

The fixed two-profile seam, closed Skills Army payload, child init path, wrapper, seven-phase
playbook, and CI registration remain appropriately bounded. The graph's indexed development checkout
predates the branch versions of the publisher and GH-620 test, so this re-review used direct source
reads for those files; no tests or project gate were run in this reviewer turn.

VERDICT: FAIL
Basis: retained-retry validation still admits a non-publisher stale managed payload and can reject an exact default-profile seed retry

## Producer disposition — round 2

The remaining finding is accepted. Retry validation now requires every previous-only managed path
to be absent, validates all current managed payloads, and validates seed bytes/mode only when the
retained commit changed that seed. The focused test now rejects a matching-metadata commit that
maliciously restores a dropped managed README and proves the default profile can retry a commit that
legitimately restores an absent `TODO.md` seed.

Handing back to Codex for final implementation re-review.

## Codex implementation re-review — changes requested

The previous-only managed-path case and the absent-seed retry case are now handled, but the retry is
still not proven to be the exact publication this engine would have produced.

1. **Existing child-owned seed can still be replaced — fail.** Retry validation permits every seed
   in the changed-path allowlist and, when a seed changed, accepts it whenever its resulting bytes and
   executable mode match the parent source (`utils/py/xyz_mini_sync.py:161-180`). The actual publisher
   copies a seed only when it is absent (`utils/py/xyz_mini_sync.py:226-227`). Therefore a retained
   commit can modify an already-present, child-owned seed to the parent version and be accepted even
   though a real publisher run would have preserved the remote seed. Retry validation must establish
   seed existence at `origin/main`: an existing remote seed must be unchanged, while an absent remote
   seed may be added only with the generated bytes/mode. The new coverage proves only the latter case
   (`test/gh620-skills-army-mini-sync.sh:99-110`), so add the complementary existing-seed mutant.

The dropped-managed-path rejection, child-root quick start, fixed target seam, closed Skills Army
payload, detached workflow, CI routing, wrapper, and seven-phase playbook otherwise remain consistent
with the approved MVP. The available graph generation predates the branch versions of the new
publisher/test/docs, so this review used direct source reads; no test or project gate was run in this
review-only turn.

VERDICT: FAIL
Basis: retained-retry validation can overwrite an existing child-owned seed even though the canonical publisher would preserve it
