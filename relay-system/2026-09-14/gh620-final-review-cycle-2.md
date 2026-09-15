---
Goal: Fresh final QA of GH-620 after the original implementation-review cap
Date: 2026-09-14
NEXT: codex
STATUS: Approved
---

# Context

This fresh review cycle is explicitly authorized by the operator after the original three-round
implementation review reached its binding cap. Review issue #620, the complete branch diff
`origin/development...HEAD`, `PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md`, and the prior review record
`relay-system/2026-09-14/gh620-skills-army-mini-implementation-qa.md`.

Focus particularly on the two fixes applied after the old cap:

- `utils/py/xyz_mini_sync.py`: remote seed existence now distinguishes an existing child-owned seed
  (must be unchanged) from an absent seed (must be added with parent bytes/mode).
- `test/gh620-skills-army-mini-sync.sh`: complementary existing-seed replacement refusal plus the
  fail-closed mktemp/path recapture guard required by the repository safety suite.

Operational envelope: manual local publisher for one public generated child; XYZ Forge is the only
authority. Keep review/test demands commensurate with this MVP—no generic plugin system, scheduler,
mirrored child battery, fuzz campaign, or speculative recovery layer.

Current producer evidence:

- GH-620 publisher/detached smoke: 20/20.
- Original XYZ-mini publisher: 18/18.
- Skills Army: 25 tests + 4 subtests.
- CI route: 76/76; registry: 10/10; mktemp trap guard: 1/1.
- Full pre-push run: 381/383. The GH-615 failure reproduces on `origin/development`; the other failure
  was the new fixture recapture and is now fixed with its focused guard green.

Questions:

1. Does the final seed logic exactly preserve a seed present at live `origin/main` and add only an absent seed with matching parent bytes/mode?
2. Do the added tests independently prove both seed cases and fail before unsafe or divergent writes?
3. Is the temporary fixture guard now fail-closed and compliant with the repository's GH-177 safety contract?
4. Re-sweep every changed implementation file: is the two-profile publisher still DRY, default-compatible, inclusion-only, and bounded to the approved ownership map?
5. Are the playbook, wrapper, child landing docs, ledger/plan, routing, and acceptance evidence truthful and complete for issue #620?
6. Is the branch ready for one exact-SHA qualifying gate and a PR into `development`?

Append concise findings with file:line citations. End with exactly `VERDICT: PASS`, `FAIL`, or
`PARKED` and a non-empty `Basis:`. Set `STATUS: Approved` only on PASS.

## Log

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex final review cycle 2 — changes requested

1. **Final seed logic and focused cases — pass.** Retry validation reads each seed at the live
   remote commit: a seed present there makes any retry diff at that path ineligible, while an absent
   seed must be added and then match the parent bytes and executable mode
   (`utils/py/xyz_mini_sync.py:140-145`, `utils/py/xyz_mini_sync.py:161-188`). The focused suite
   independently exercises the allowed absent-seed addition and refused existing child-owned seed
   replacement (`test/gh620-skills-army-mini-sync.sh:100-122`). The preflight runs before the first
   publication write (`utils/py/xyz_mini_sync.py:226-247`).
2. **Temporary fixture guard — pass.** The suite rejects an empty/invalid `mktemp` result, physically
   recaptures it, and then pins it through the shared fail-closed guard before passing it to the
   Python fixture (`test/gh620-skills-army-mini-sync.sh:6-15`; `test/lib/fixture-guard.sh:25-33`).
   Cleanup also refuses an empty or missing root (`test/gh620-skills-army-mini-sync.sh:9-10`).
3. **Exact retry still bypasses the publisher's ownership guard — fail.** Retry validation permits
   any current managed path when its final bytes/mode match the parent, but does not prove that a
   managed destination absent from the remote `MANIFEST.txt` was itself absent at the remote commit
   (`utils/py/xyz_mini_sync.py:154-189`). An operator-owned `README.md` (or other future managed
   destination) present on remote but omitted from its manifest could therefore be replaced in a
   manually forged matching-metadata ahead commit and accepted as an “exact retry.” After that
   acceptance, the ordinary ownership guard reads the ahead commit's new manifest, so it now treats
   the replacement as owned and cannot catch the bypass (`utils/py/xyz_mini_sync.py:227-234`). This
   contradicts both the one-ownership-guard contract and the claim that only a commit the publisher
   could have produced is retryable. Require every current managed destination not in the remote
   manifest to be absent at the remote commit, and add the complementary retained-retry mutant. The
   existing normal-flow ownership test and retry mutants do not combine these states
   (`test/gh589-xyz-mini-sync.sh:86-89`; `test/gh620-skills-army-mini-sync.sh:71-122`).
4. **Remaining MVP surface and records — pass.** The second profile remains a fixed data seam with
   the original profile as the default, the Skills Army payload is literal and inclusion-only, and
   routing registers the two focused suites (`utils/py/xyz_mini_sync.py:29-79`,
   `test/gh620-skills-army-mini-sync.sh:50-69`, `utils/ci-route.sh:24-45`). The child/package quick
   starts agree, the wrapper remains manual, and the playbook covers the seven required phases
   (`skills/skills-army-hq/README.md:64-74`, `mini/skills-army-README.md:12-20`,
   `skills/push-to-skills-army-mini/SKILL.md:9-25`,
   `docs/SPIN-OFF-REPOSITORY-PLAYBOOK.md:1-47`). The plan, ledger, architecture route, and changelog
   remain consistent with approval still pending (`PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:24-42`,
   `PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:121-138`, `ARCHITECTURE.md:65-66`,
   `CHANGELOG.md:5-7`, `releases.sql:593`).

The available graph generation predates the branch implementation and reports missing freshness for
the publisher, GH-620 test, and new docs, so this review used direct source reads for those paths. Per
the review-turn constraints, no Git command, test, or project gate was run. The branch is not ready
for its exact-SHA qualifying gate or PR until the ownership-retry bypass is closed.

VERDICT: FAIL
Basis: the retained-retry exception can still replace an unmanifested operator-owned remote path that the canonical publisher would have refused to overwrite

## Producer response — ownership retry closed

Agreed. Commit `674a6fcc` keeps the correction deliberately narrow:

- `utils/py/xyz_mini_sync.py` now rejects an exact-retry candidate when a current managed path is
  absent from the live remote manifest but present in the live remote tree. This is the same
  ownership fact the ordinary path would enforce; no new policy layer or abstraction was added.
- `test/gh620-skills-army-mini-sync.sh` adds one complementary end-to-end mutant: remote `README.md`
  is operator-owned and unmanifested, an ahead commit forges matching publisher metadata and bytes,
  and the rerun must return 2 without changing its commit.

Debug breadcrumb: before the fix the focused suite was 20 pass / 1 fail and the forged retry returned
success. After the fix it is 21/21. The existing required-payload red control still fails (1 pass / 2
fail), original XYZ-mini compatibility is 18/18, and the shared mktemp guard is 1/1.

Please re-review this finding and the resulting final branch state. End with the required verdict and
set `STATUS: Approved` only on PASS.

## Codex final review cycle 2 — approved

1. **Retained-retry ownership is now exact — pass.** For every current managed destination absent
   from the live remote manifest, retry validation now refuses if that destination nevertheless
   exists in the live remote tree (`utils/py/xyz_mini_sync.py:154-180`). That restores the ordinary
   publisher's ownership fact before the ahead commit's replacement manifest can grant ownership;
   the retry is accepted only when its changed-path allowlist and all managed/seed bytes and modes
   also match the publication plan (`utils/py/xyz_mini_sync.py:160-193`). Existing remote seeds must
   remain unchanged, while absent remote seeds must be newly added and match the parent
   (`utils/py/xyz_mini_sync.py:166-190`).
2. **The focused mutants cover both ownership and seed branches — pass.** The new operator-owned
   README case removes the path from the remote manifest, leaves it present in the remote tree,
   forges the publisher's manifest/message/payload, and requires refusal without advancing HEAD
   (`test/gh620-skills-army-mini-sync.sh:100-116`). The default-profile cases separately prove an
   absent seed can be restored by an exact retained publication and an existing child-owned seed
   cannot be replaced (`test/gh620-skills-army-mini-sync.sh:118-140`). Preflight remains before the
   ownership guard and every publication write (`utils/py/xyz_mini_sync.py:225-253`).
3. **Fixture containment and final MVP sweep — pass.** The test validates the `mktemp` result,
   physically recaptures it, and pins it through the shared fail-closed fixture guard before any
   fixture operation (`test/gh620-skills-army-mini-sync.sh:6-15`;
   `test/lib/fixture-guard.sh:25-33`). The publisher remains one fixed two-profile engine with
   `xyz-mini` as the default and the Skills Army export limited to the approved closed package,
   landing files, and licenses (`utils/py/xyz_mini_sync.py:29-79`; `PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:68-85`).
   The child/package quick starts, manual wrapper, seven-phase playbook, CI registration, ledger,
   architecture index, and changelog remain aligned with issue #620
   (`skills/skills-army-hq/README.md:64-74`; `mini/skills-army-README.md:7-20`;
   `skills/push-to-skills-army-mini/SKILL.md:11-25`;
   `docs/SPIN-OFF-REPOSITORY-PLAYBOOK.md:1-47`; `utils/ci-route.sh:24-45`;
   `validate.sh:494-497`; `ARCHITECTURE.md:65-66`; `CHANGELOG.md:5-7`; `releases.sql:593`).

The graph generation reports changed metadata for the publisher and GH-620 test and excludes the
new docs, so current direct source reads were authoritative for this review. Per the review-turn
constraints, no Git command, focused test, or project gate was run. Reviewer approval clears the
branch to run the required exact-SHA qualifying gate; the PR into `development` remains contingent
on that gate passing.

VERDICT: PASS
Basis: the live-remote ownership check closes the final retained-retry bypass, its red-control mutant covers the previously accepted forged state, and the final bounded implementation and records satisfy issue #620

### Attestation · relay-drive — 2026-09-14T18:09:30Z
task: RELAY-gh620-final-review-cycle-2
reviewer: codex
status: Approved
reviewed-head: 99e9eebfaceb204cc2582473812befa4f8f75d96
added-range: 7588+3121
added-sha256: 2bc614f09e3825f06e72a425e85f555d4274f62e0f2a49e772a9f50a7465e618
