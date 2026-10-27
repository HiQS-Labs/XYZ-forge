---
Goal: Plan QA — GH-1228 scope two unscoped GH-831 skill lines to XYZ-forge
Date: 2026-10-26
NEXT: codex
STATUS: Open
---

# Context

Review the plan in `PROJECT/2-WORKING/GH-1228-GH831-VENDORED-SCOPE.md` (issue https://github.com/HiQS-Labs/XYZ-forge/issues/1228) before implementation. Base `1f5b0508`.

Requirement (operator): a vendored `.xyz/` copy of this harness must not tell a host repo it may not add tests. XYZ-forge's own GH-831 rule (`AGENTS.md` *No new tests*) stays in force here. The host repo (BinoidCBD/LTVera-Pandas, issue #845) now has its own policy: new tests allowed with prior operator approval.

Operational envelope: two sentences of skill text. Docs-route change. Do not ask for new tests (GH-831), new suites, gates or machinery.

Read:
- the plan doc in full
- `skills/2-daily/express/SKILL.md` (step 4, around line 173)
- `skills/4-occasional/ci-suite-audit/SKILL.md` (around lines 28–31 and 338–345)
- `utils/py/express.py` lines 598–604
- `relay-automation/xyz-vendor.sh` `VENDOR_DIRS` (around line 432)
- `utils/ci-route.sh` (the docs/full routing precedence, lines 55–70)

Questions:

1. Is the recon complete? Search the vendored directories (`relay-automation bin src utils test skills`) for any other GH-831 / "no new tests" / "test freeze" text that, read inside a different host repo, would forbid that repo's tests. Cite file:line for any the plan misses.
2. Is the proposed wording for the two lines correct and consistent with how the other skills already scope it ("XYZ-forge: `AGENTS.md` *No new tests*, GH-831")? Does it keep XYZ-forge's own rule fully in force?
3. Is rejecting the `utils/py/express.py:603` message change sound (correct refusal in any repo; edit would route the PR to the full gate)? Or does the message actively mislead a vendored user enough to require it?
4. Are the rating (60/45/50/92) and its rationale grounded?
5. Is the verification (docs gate `utils/pdda/pdda.sh run`, recon grep as red control, manual check under TESTS-RESULTS) sufficient and commensurate?

Flag anything wrong, missing, or over/under-scoped, citing file:line. Use `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`. Write your verdict below and set STATUS to Approved if the plan can proceed.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log
