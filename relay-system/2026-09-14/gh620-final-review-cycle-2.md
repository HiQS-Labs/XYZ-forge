---
Goal: Fresh final QA of GH-620 after the original implementation-review cap
Date: 2026-09-14
NEXT: codex
STATUS: Open
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

