---
gh_issue: 1228
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1228
title: "Scope the two unscoped GH-831 skill lines to XYZ-forge so vendored repos keep their own test policy"
status: In Progress
created: 2026-10-26
updated: 2026-10-26
owner: operator
goal: "Vendored copies of the express and ci-suite-audit skills defer to the host repo's own test policy; in XYZ-forge they still cite GH-831."
complexity: 1
risk: 1
effort: 1
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Captured, parked, rated and promoted with plan | Codex plan QA, then implement |

## Problem

Captured from https://github.com/HiQS-Labs/XYZ-forge/issues/1228. Two skill lines state GH-831 with no
repo scope. Vendored into BinoidCBD/LTVera-Pandas they read as that repo's test ban (LTVera #845).

## Rating (2026-10-26)

`rated 60/45/50/92`, row `rmi-01M5XNK32GSHEE64XP74FA26CR`.

- **Severity 45:** nothing breaks at runtime. The two lines leak a governance rule into vendored repos.
  One did hold tests out of LTVera-Pandas (BinoidCBD/LTVera-Pandas#845, five held test sets), but
  LTVera's own unscoped docs carried most of that.
- **Priority 60:** asked for by the operator together with LTVera #845. It blocks re-vendoring
  LTVera's `.xyz/` cleanly.
- **Recurrence:** one incident (LTVera, Oct 20 to 26). Trend unknown; no other vendored repo was checked.
- **Appeal 50:** neutral. **Effort 92:** two sentences of skill text.

## Recon (base `1f5b0508`)

`git grep -n -i -E "no new test|GH-831|moratorium|forbids new tests"` over the vendored directories
(`relay-automation bin src utils test skills`, per `relay-automation/xyz-vendor.sh` `VENDOR_DIRS`):
nearly every hit scopes the rule by name ("XYZ-forge: `AGENTS.md` *No new tests*") or by context
(XYZ-forge's own `validate.sh`, `test/`, consult suite). Unscoped:

- `skills/2-daily/express/SKILL.md:173`: "Do not add a new suite to get one (GH-831: no new tests)"
- `skills/4-occasional/ci-suite-audit/SKILL.md:342`: "Under the repository test freeze, no new test files may be added"
- `utils/py/express.py:603`: the `suite-missing` refusal message ends "(GH-831: no new suites)"

`utils/ci-route.sh push` routes the two SKILL.md files to `route=docs tier=1`, and `utils/py/express.py` to `route=full tier=3`.
No suite under `test/` asserts any of the three strings.

## Plan

**Outcome sought:** a vendored repo's agents read its own test policy, not GH-831.
**Smallest bet:** reword the two SKILL.md lines.
**Rejected (Ponytail):** editing `express.py`'s refusal message. The refusal is correct in any repo
(express always needs an existing covering suite). Rewording one parenthesis would move the PR from
the docs gate to the full gate (about 60 to 80 minutes). Not done.
**Rejected:** a generic "host repo test policy" section in every skill. The 14 scoped skills already
work; adding one would be a change for its own sake.
**Rollback:** revert the PR.

1. `skills/2-daily/express/SKILL.md` step 4: "Do not add a new suite to get one; an uncovered code fix goes
   through `/start-task` under the host repo's own test policy (in XYZ-forge: `AGENTS.md` *No new tests*, GH-831)."
2. `skills/4-occasional/ci-suite-audit/SKILL.md:342`: "Where the repository forbids new tests (XYZ-forge:
   `AGENTS.md` *No new tests*, GH-831), no new test files may be added; elsewhere the host repo's own test
   policy applies."
3. CHANGELOG entry.
4. Verify: `utils/pdda/pdda.sh run` (the routed docs gate). Re-run the recon grep; the two lines now name
   XYZ-forge. Red control: the grep shows them unscoped on base `1f5b0508`. Smoke: read both lines from
   the vendored-repo entry point (LTVera `.xyz/` after re-vendor). Manual check under `TESTS-RESULTS/2026-10-26+GH-1228/`.

**Test scope:** no new tests (GH-831). Docs gate only.
