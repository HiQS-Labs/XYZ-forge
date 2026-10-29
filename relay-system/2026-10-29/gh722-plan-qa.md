---
Goal: Plan QA — GH-722 merge-cleanup sibling safe root for the default scan and Phase 6
Date: 2026-10-29
NEXT: codex
STATUS: Approved
---

# Context

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/722. The plan is the `## Plan (2026-10-29, /start-task)` section at the end of `PROJECT/2-WORKING/GH-722-MERGE-CLEANUP-SAFE-ROOTS-PARENT.md` (commit f8b1440b; base 0628da70). Read the issue's Ask, the doc's Acceptance list and the plan, then check them against the source:

- `skills/2-daily/merge-cleanup/scripts/scan_clones.py` (`DEFAULT_SAFE_ROOTS` :26, `DEFAULT_NEVER_DELETE`, `published_retirement_roots` :53, `is_safe_deletable_path` :74, `_normalize_remote` :387, `inspect_checkout` safe-root check :945-948 and disposition ladder :1036-1130, `scan_directories` :1133, `main` :1421)
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (`refresh_for_teardown` :999, `teardown_checkout` :1018, `retire_published_checkouts` :1683-1725, `main` search roots :1818, Phase 1 header :1946, Phase 6 teardown :2178)
- `test/gh436-merge-cleanup.py:711`, `test/gh534_phase_a_tests.py:123-129` (parity pin)
- `WORKTREE-SAFETY.md` §16.1 (:790-830), `skills/2-daily/merge-cleanup/SKILL.md` :200 and :584
- Prior fix #1198 (GH-1193, `PROJECT/3-COMPLETED/GH-1193-RETIRE-SIBLING-ROOTS.md`) covered retire mode only.

Live motivating case: three LTVera-Pandas clones beside the primary in `~/Documents/GitHub Repos`; two have PR branches deleted on merge, one is a landing clone with no PR, so retire mode cannot take them and the default teardown refuses them as outside SAFE_ROOTS.

Repo rules: `AGENTS.md` *No new tests* (GH-831): verification uses existing suites or a manual check under `TESTS-RESULTS/`; editing an existing assertion to keep it truthful is allowed.

Operational envelope: a single-operator local cleanup tool on a Mac. Grade against the issue, the acceptance list and data-loss safety, not hypothetical multi-tenant threat models.

Questions:
1. Are the plan's claims grounded in the cited lines? Is anything the issue asks for missing?
2. Is the same-origin gate on the parent root sufficient and placed correctly to stop a foreign project's clean, landed checkout from becoming SAFE_REMOVE_CLONE, in the default scan, `--root` scans, refresh_for_teardown and Phase 6? Any path where the widened roots reach teardown without that gate?
3. Does the plan extend the existing helpers (`published_retirement_roots`, `_normalize_remote`, `is_safe_deletable_path`) rather than adding a parallel mechanism? Is the rename safe for every caller?
4. Is skipping foreign-origin entries of the derived root during the scan correct, and does it leave explicit `--root` behaviour unchanged?
5. Are the verification steps (existing suites, smoke with red control, NEVER_DELETE skip via a temp HOME) falsifiable and sufficient without a new test?
6. Anything simpler that meets the acceptance list?

Cite file:line. Use `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`. Do not edit source files; write only to this thread.

**Required output format:** append one block under `## Log` containing a line `VERDICT: PASS` or `VERDICT: FAIL` (exactly), a one-line `Basis:` line, then your findings. Set STATUS to Approved on PASS.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log

### Codex — plan QA, 2026-10-29

VERDICT: FAIL
Basis: The core reuse and fresh-inspection design is sound, but the plan misses an existing caller adaptation and does not verify the new deletion boundary.

- [Should — required] Update the existing Phase A teardown double as well as the exact-call assertion. Plan step 4 (`PROJECT/2-WORKING/GH-722-MERGE-CLEANUP-SAFE-ROOTS-PARENT.md:124`) names only `test/gh436-merge-cleanup.py:711`. `test/gh534_phase_a_tests.py:569` defines `fake_teardown(c, dry_run=True)` and installs it as the teardown side effect at :585. The planned `safe_roots=` call will raise TypeError whenever that double is reached. Narrow read-only probe (exit 0): parse that file with `ast.parse`, locate `fake_teardown`, construct `inspect.Signature` from its positional parameters, then call `sig.bind({}, dry_run=True, safe_roots=[])`, catching TypeError. Decisive output: `parameters=['c', 'dry_run'], kwargs=None`; `Planned Phase 6 call: TypeError: got an unexpected keyword argument 'safe_roots'`. Adapt this existing double to the changed interface; no new test needed.

- [Should — required] Extend the planned manual evidence beyond discovery. The smoke at plan :132 uses `--scan-only`, which returns at `merge_cleanup.py:1972`, before refresh (:2152) and teardown (:2178). A missing Phase 6 roots argument or a missing inspection origin gate could therefore escape that smoke; default scan filtering alone hides the foreign checkout. In a disposable full clone, record a same-origin sibling outside DEFAULT_SAFE_ROOTS reaching successful dry-run teardown, and an explicitly scanned foreign-origin sibling remaining preserved through refresh with teardown refused. Include failed/empty origin lookup as a fail-closed case for `same_origin`, and a red control that removes the inspection origin condition so the foreign-origin assertion actually fails. Preserve the current NEVER_DELETE smoke and pre-fix discovery control. Record commands, statuses, decisive output and provenance under the planned TESTS-RESULTS directory. [Unverified — needs clone run]: no suites or executable fixtures were run in this review.

- [Should] Resolve the overlap ambiguity in acceptance :54 versus plan step 2 (:122). Falling back to DEFAULT_SAFE_ROOTS preserves foreign checkouts outside that list, but does not yield PRESERVE_UNSAFE_ROOT when the primary parent is itself an existing safe root (for example `~/marathon-clones`). That follows directly from `scan_clones.py:26-31`, :74-95 and :1119-1130. Since preserving explicit `--root` behavior is a stated non-goal, the smallest consistent contract is to scope the new foreign-origin protection to eligibility granted by the added parent root; do not promise universal foreign-origin preservation while retaining existing-root behavior. Specify how derived-root filtering interacts with an already-listed default root and explicit roots, rather than identifying a root's provenance from path equality alone.

- [Pass] For siblings outside DEFAULT_SAFE_ROOTS, placing the matching-origin condition in `inspect_checkout` (:945-948) protects explicit scans and refresh, not just discovery: `refresh_for_teardown` calls inspection again (:1008), Phase 6 selects only fresh SAFE_REMOVE dispositions (:2152-2153), and teardown rejects other dispositions (:1033). Passing the expanded roots to teardown therefore does not independently authorize a preserved checkout. Require successful, nonempty origin queries before normalized comparison; equality of two empty strings is not identity proof.

- [Pass] Reusing the existing roots helper, normalizer and containment check is the smallest suitable design. Rename inventory from `rg -n 'published_retirement_roots' skills test` (exit 0): definition `scan_clones.py:53`, inspection :945, import `merge_cleanup.py:28`, retire caller :1690. Update all four and the stale teardown docstring at :1023; retire mode already checks origin at :1711-1713. Keep the pinned list unchanged (`test/gh534_phase_a_tests.py:123-129`), and update the existing prose at `WORKTREE-SAFETY.md:830` and skill Phase 1/retire sections. Keep `scan_clones.py --json` stdout machine-readable when adding the roots header (:1426-1429).

- [Pass / limitation] The seeded acceptance and source confirm the default-scan/Phase 6 gap and the retire-only prior fix. Live issue verification was attempted with `gh issue view 722 --repo HiQS-Labs/XYZ-forge --json body,title`; exit 1, `error connecting to api.github.com`. The live Ask was therefore not independently fetched. This review uses the seeded issue transcription, not an asserted live issue read.

Revise the plan's verification, existing-double adaptation and overlap contract, then return for plan approval. Only this relay file was edited; no Git commands or test suites were run.

### Claude — revision 1, 2026-10-29

All three findings accepted; plan section revised in `PROJECT/2-WORKING/GH-722-MERGE-CLEANUP-SAFE-ROOTS-PARENT.md`.
- Phase A double: step 4 now also updates `fake_teardown` at `test/gh534_phase_a_tests.py:569` (`safe_roots=None`). Disposition: Accepted.
- Verification: smoke now covers dry-run teardown for a same-origin sibling, a foreign-origin sibling under explicit `--root` through refresh, a failed origin lookup, NEVER_DELETE, plus red controls for discovery (base) and the origin gate (condition removed). Disposition: Accepted.
- Overlap contract: step 2 states that the parent root grants eligibility only to same-origin checkouts and existing-root behaviour is unchanged; step 3 passes the derived root as a separate `sibling_root` argument (not path equality) and omits it when the parent is NEVER_DELETE or already a default root. `same_origin` fails closed on failed or empty lookups. `--json` header goes to stderr. Disposition: Accepted.

Please re-review the revised plan section for approval.

### Codex — revision 1 plan QA, 2026-10-29

VERDICT: PASS
Basis: The revised plan resolves the three previous findings and is ready for implementation; this approves the design, not unexecuted runtime verification.

- [Pass] The added-root origin boundary is now explicit in plan steps 1–3 (`PROJECT/2-WORKING/GH-722-MERGE-CLEANUP-SAFE-ROOTS-PARENT.md:121-123`). Successful, nonempty origin lookups precede normalized comparison; foreign candidates retain only the existing default-root eligibility. Putting that decision in `inspect_checkout` (`skills/2-daily/merge-cleanup/scripts/scan_clones.py:945`) covers both explicit scans and `refresh_for_teardown` (`skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:1008`). Phase 6 selects only fresh removable dispositions (:2152-2153), and `teardown_checkout` refuses other dispositions (:1033). Within the stated contract, no reviewed caller bypasses the planned origin condition to gain eligibility from the added parent root.

- [Pass] The separate optional `sibling_root` in step 3 preserves explicit-root discovery and avoids confusing an already-default root with newly granted scope. Apply its filtering before `inspect_checkout` in the walk (`scan_clones.py:1152`), as the plan requires, to avoid fetching foreign sibling repositories. Existing callers without a primary must retain default-root behavior; the current optional-primary signature at :1133 supports that compatibility. Step 5 preserves JSON stdout, and step 6 updates the existing documentation without changing the pinned roots list.

- [Pass] The rename and caller adaptation are complete at plan level. Read-only inventory command `rg -n 'published_retirement_roots' skills test` exited 0 with exactly four matches: `scan_clones.py:53`, :945, `merge_cleanup.py:28`, :1690 (paths under `skills/2-daily/merge-cleanup/scripts/`). Step 4 now names both the exact-call assertion (`test/gh436-merge-cleanup.py:711`) and the installed `fake_teardown` side effect (`test/gh534_phase_a_tests.py:569`, :585). Reusing the existing roots helper, remote normalizer, containment check and teardown writer is appropriately small; no parallel subsystem is needed.

- [Pass / Unverified — needs clone run] Plan :132-136 now covers discovery, same-origin dry-run removal, explicit foreign-origin scanning through refresh, failed origin lookup and NEVER_DELETE. Its pre-fix discovery control and removal of the inspection origin condition are falsifiable controls for the two new behaviors. Execute these and the named existing suites in a disposable full clone, recording nonempty results, exit statuses and committed provenance as planned. A missing-origin case must actually reach the explicit scan/inspection boundary rather than pass merely because default discovery omitted it. No suites, executable fixtures or Git commands were run in this turn.

- [Nit] Align acceptance :54 and outcome :118 with the precise scoped contract at :122 when implementing the planned docs update: foreign-origin preservation is guaranteed for eligibility newly granted by the parent root, not for all existing safe roots. The explicit step-2 contract resolves the design ambiguity, so this remaining prose inconsistency does not block plan approval.

- [Pass / limitation] Live issue read command `gh issue view 722 --repo HiQS-Labs/XYZ-forge --json body,title` exited 1: `error connecting to api.github.com`. Issue coverage is assessed against the seeded transcription and acceptance list, not a successful live issue read. Source inspection confirms the prior retire-only helper and the default-scan/Phase 6 gap. Only this relay file was edited; implementation and runtime evidence remain the builder's next work.
