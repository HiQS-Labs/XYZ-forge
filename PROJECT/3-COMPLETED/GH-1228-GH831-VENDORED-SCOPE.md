---
gh_issue: 1228
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1228
title: "Scope the three unscoped GH-831 skill lines to XYZ-forge so vendored repos keep their own test policy"
status: Complete
created: 2026-10-26
updated: 2026-10-27
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
| Plan approved (Codex round 4, attested; round 4 operator-authorized for format only). Implemented the three scoping edits and the CHANGELOG entry; docs gate, red control and vendor smoke in `TESTS-RESULTS/2026-10-26+GH-1228/` | Final Codex QA, then PR |

## Problem

Captured from https://github.com/HiQS-Labs/XYZ-forge/issues/1228. Three skill lines state GH-831 with no
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

- `skills/2-daily/express/SKILL.md:28` (the recited Express Discipline): "Do not add a suite (GH-831)." (found by plan QA round 1)
- `skills/2-daily/express/SKILL.md:173`: "Do not add a new suite to get one (GH-831: no new tests)"
- `skills/4-occasional/ci-suite-audit/SKILL.md:342`: "Under the repository test freeze, no new test files may be added"
- `utils/py/express.py:603`: the `suite-missing` refusal message ends "(GH-831: no new suites)"

Unscoped in wording, but scoped by what they govern (no change):

- `utils/py/express.py:603` and `:639`: the express lane's refusal and acceptance text. Express requires an
  existing registered covering suite in every repo. A host that wants new tests uses `/start-task` under its own policy.
- `relay-automation/README.md:40`: instructions for adding a consult advisor to the harness itself
  (`utils/py/consult.py`, `test/consult.sh`). A host never edits its vendored `.xyz/` copy, which is
  gitignored and overwritten on every sync, so this governs XYZ-forge development only.
  `utils/ci-route.sh push` routes it to `route=full tier=3`.

`utils/ci-route.sh push` routes the two SKILL.md files to `route=docs tier=1`, and `utils/py/express.py` to `route=full tier=3`.
No suite under `test/` asserts any of the three strings.

## Plan

**Outcome sought:** a vendored repo's agents read its own test policy, not GH-831.
**Smallest bet:** reword the three SKILL.md lines (two in express, one in ci-suite-audit).
**Rejected (Ponytail):** editing `express.py`'s refusal message. The refusal is correct in any repo
(express always needs an existing covering suite). Rewording one parenthesis would move the PR from
the docs gate to the full gate (about 60 to 80 minutes). Not done.
**Rejected:** a generic "host repo test policy" section in every skill. The 14 scoped skills already
work; adding one would be a change for its own sake.
**Rollback:** revert the PR.

1. `skills/2-daily/express/SKILL.md:28`: "Do not add a suite in this lane; an uncovered fix goes through
   `/start-task` under the host repo's own test policy (XYZ-forge: GH-831)."
   `skills/2-daily/express/SKILL.md` step 4: "Do not add a new suite to get one; an uncovered code fix goes
   through `/start-task` under the host repo's own test policy (in XYZ-forge: `AGENTS.md` *No new tests*, GH-831)."
2. `skills/4-occasional/ci-suite-audit/SKILL.md:342`: "Where the repository forbids new tests (XYZ-forge:
   `AGENTS.md` *No new tests*, GH-831), no new test files may be added; elsewhere the host repo's own test
   policy applies."
3. CHANGELOG entry.
4. Verify: `utils/pdda/pdda.sh run` (the routed docs gate). Re-run the recon grep; all three lines now name
   XYZ-forge. Red control: the grep shows them unscoped on base `1f5b0508`. Smoke: read both lines from
   the vendored-repo entry point (LTVera `.xyz/` after re-vendor). Manual check under `TESTS-RESULTS/2026-10-26+GH-1228/`.

**Test scope:** no new tests (GH-831). Docs gate only.

## Plan QA dispositions

- Round 1 (Codex, `relay-system/2026-10-26/gh1228-plan-qa.md`): [Blocker] missed `express/SKILL.md:28`. **Accepted**, added to steps and verification.
  [Should] rating evidence not independently verified (reviewer had no GitHub access). **Accepted**: the LTVera incident is cited as captured evidence from BinoidCBD/LTVera-Pandas#845, not as an independent check.
  [Pass] on keeping `express.py` unchanged, on the wording, and on verification.
- Round 2 (Codex): [Blocker] `relay-automation/README.md:40`. **Declined (out of scope / Ponytail):** it governs
  changes to the harness's own code, which a host never makes in its overwritten `.xyz/` copy. Editing it would move the
  PR to the full gate for no change in host behaviour. Recorded in Recon. [Should] account for `express.py:639`.
  **Accepted** as a recon entry; no change, for the same reason as `:603`. The title count is fixed to three.
