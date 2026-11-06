# RELAY · GH-1348 plan QA: express SKILL.md docs-only admission
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-05.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1348-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **GH-1348-EXPRESS-SKILL-DOCS.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: antigravity
- Started: 2026-11-05

### Artifact — GH-1348-EXPRESS-SKILL-DOCS.md
```
---
gh_issue: 1348
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1348
title: "feat(express): admit non-execution-authority skills/**/SKILL.md under --docs-only with relay attestation"
status: Active
created: 2026-11-05
updated: 2026-11-05
owner: Antigravity
goal: "Admit non-execution-authority SKILL.md under express --docs-only when backed by validated relay attestation"
branch: feat/XYZ-forge-gh1348-express-skill-docs-2026-11-05
doc_type: feature
effort: 2
complexity: 2
risk: 2
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Issue #1348 created; task clone provisioned; capture doc created in 1-INBOX | Park and rate in releases.db, promote to 2-WORKING, and conduct pre-implementation plan QA with Codex via relay-xyz |

## Observed problem and bet

- **Observed problem:** `skills/2-daily/express/SKILL.md` (lines 73–93) documents a risk-based review policy allowing bounded documentation-only skill edits to use `/express --docs-only` when appropriately reviewed, while keeping execution-authority and gate-bypass changes outside `--docs-only`. However, `utils/py/express.py` (`is_documentation_update()`, line 109) still hard-blocks every `SKILL.md` path unconditionally under `--docs-only`, forcing even reviewed markdown-only skill updates through full PR/merge/reconcile ceremony.
- **Outcome sought:** Allow non-execution-authority `skills/**/SKILL.md` files to be landed directly and safely via `/express --docs-only` from a fresh task clone off `origin/<base>`, provided the update is attested by an approved `relay-drive` review (`.git/relay-attest/*.json`), while maintaining strict hard refusals for execution-authority skills, scripts, and unstaged/post-review drift.
- **Smallest viable bet:**
  1. Update `is_documentation_update()` in `utils/py/express.py` to recognize `skills/**/SKILL.md` and `relay-system/*.md` as documentation, while strictly excluding `EXECUTION_AUTHORITY_SKILLS` (`express`, `merge-cleanup`, `merge-cleanup-deep`, `start-marathon`, `marathon-cleanup`, `start-task`, `relay`, `relay-xyz`, `relay-automation`, `jog`) and any non-`SKILL.md` file under `skills/`.
  2. In `cmd_check`, when `docs_only` is true and core paths include `skills/**/SKILL.md`, verify a valid `relay_attest` record (`.git/relay-attest/*.json`) with `status == "Approved"`, `candidate_ok(record, HEAD, root) == True`, and clean working tree diff on the skill path vs `HEAD`. Refuse with `rule=skill-unattested` if absent, malformed, or drifted.
  3. Exempt `relay-system/*.md` transcripts from insertion and file bounds in `insertions()` and `is_doc_path()`.
  4. Update `skills/2-daily/express/SKILL.md` to reflect that the driver now admits attested skill documentation.
  5. Add test coverage in `test/gh267-express-skill.sh` exercising both positive admission and negative refusals.
- **Alternatives rejected:**
  1. *Blanket exemption of all SKILL.md without review:* Rejected because skill instructions serve as autonomous agent control flow; unreviewed direct landings could compromise safety or introduce loops.
  2. *Adding synthetic test suites for skills:* Rejected by repo rail `No new tests` (GH-831).
- **Rollback / containment:** Reverting the changes in `utils/py/express.py` and `skills/2-daily/express/SKILL.md` immediately restores the prior strict refusal behavior.

## Implementation Plan

1. **Extend path classifiers in `utils/py/express.py`:**
   - Define `EXECUTION_AUTHORITY_SKILLS` and helpers `is_skill_path(path)`, `skill_name(path)`, and `is_execution_authority_skill(path)`.
   - Update `is_documentation_update()` to admit non-execution-authority `SKILL.md` and `relay-system/*.md`.
   - Update `is_doc_path()` to treat `relay-system/*.md` as paperwork exempt from product size bounds.
   -> expect non-execution-authority skill files and transcripts to pass docs-only path qualification, and execution-authority skills to refuse docs-only.

2. **Add attestation verification in `utils/py/express.py`:**
   - Implement `find_valid_skill_attestation(root, skill_paths)` using `relay_attest.git_common_dir`, `relay_attest.load(..., any_reviewer=True)`, `relay_attest.candidate_ok(record, head, root)`, and working-tree cleanliness checks.
   - In `cmd_check()`, if `docs_only` and any `skill_paths` are present, invoke `find_valid_skill_attestation()` and fail closed with `refuse(root, "skill-unattested", ...)` on any failure.
   -> expect unreviewed or post-review drifted skill edits to refuse with `skill-unattested`, and approved reviewed edits to pass.

3. **Update documentation in `skills/2-daily/express/SKILL.md`:**
   - Update the "Current driver compatibility" section to document the active support for non-execution-authority skill updates backed by relay attestation.
   -> expect policy and driver behavior to be fully aligned.

4. **Add regression controls in `test/gh267-express-skill.sh`:**
   - Add negative control: unattested skill edit under `--docs-only` refuses `skill-unattested`.
   - Add negative control: execution-authority skill edit under `--docs-only` refuses `docs-only`.
   - Add negative control: skill edit modified after attested revision refuses `skill-unattested`.
   - Add positive control: non-execution-authority skill edit with valid approved attestation passes `check --docs-only`.
   -> expect all controls in `bash test/gh267-express-skill.sh` to pass.

## Acceptance Criteria

- [ ] `utils/py/express.py` refuses `skills/2-daily/express/SKILL.md` and other execution-authority skills under `--docs-only` with `rule=docs-only`.
- [ ] `utils/py/express.py` refuses non-execution-authority `skills/**/SKILL.md` under `--docs-only` when no valid Approved `relay_attest` receipt exists with `rule=skill-unattested`.
- [ ] `utils/py/express.py` refuses non-execution-authority `skills/**/SKILL.md` under `--docs-only` when the skill file has drifted from the attested revision with `rule=skill-unattested`.
- [ ] `utils/py/express.py` passes `check --docs-only` when a non-execution-authority `skills/**/SKILL.md` is accompanied by a valid Approved `relay_attest` receipt for `HEAD`.
- [ ] `test/gh267-express-skill.sh` passes green with zero regressions.
- [ ] `skills/2-daily/express/SKILL.md` accurately documents the verified driver behavior.

## Lessons Learned (For Future Agents)

- (To be recorded at closeout)
```
- Definition of Done:
  1. **Surgical & DRY:** Extends existing `utils/py/express.py` and `utils/py/relay_attest.py` with zero parallel machinery, speculative abstractions, or new test suites (GH-831).
  2. **Strict containment:** All execution-authority skills (`express`, `merge-cleanup`, `start-marathon`, `start-task`, `relay*`, `jog`), non-`SKILL.md` scripts/executables, and policy docs (`AGENTS.md`, `CLAUDE.md`) remain hard-blocked under `--docs-only`.
  3. **Airtight attestation verification:** Requires a valid `relay_attest` record (`.git/relay-attest/*.json`) with `status == 'Approved'`, `candidate_ok(record, HEAD, root) == True` (ensuring no non-transcript commits post-review), and clean working tree diff on the skill path vs `HEAD`.
  4. **Falsifiable controls:** Specifies negative controls (unattested skill, execution-authority skill, drifted skill) and positive controls in `test/gh267-express-skill.sh`.
  5. **Operational envelope:** Commensurate complexity for an internal agent harness utility; reject out-of-scope enterprise multi-tenant threat models.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The plan is surgical, but its stated attestation predicate does not match the existing API. Correct that contract before implementation.
swept file: yes

- [Should] **Unpack the attestation APIs explicitly.** The embedded “Smallest viable bet” item 2 and Definition of Done item 3 require `candidate_ok(record, HEAD, root) == True`; the actual API returns `(bool, reason)` (`utils/py/relay_attest.py:385`). Equality with `True` always rejects a tuple, while testing tuple truthiness admits rejection tuples. Amend the plan to say `ok, reason = candidate_ok(...)` and require `ok is True`; likewise unpack `record, error = load(...)`, require a non-null validated record and explicitly require `record["status"] == "Approved"` because `load` also accepts Closed. Keep the existing validator rather than adding a second one.
  Observed input: `relay_attest.candidate_ok({'isolated': False}, 'HEAD', '.')` returns `(False, 'review ran without worktree isolation; its input was not a pinned revision')`.
  Affected scope: The proposed `find_valid_skill_attestation` decision on every candidate receipt, including rejected non-isolated/seeded reviews.
  Falsifier: A rejected result must refuse and an accepted `(True, None)` must admit after all other qualifications; an API returning a scalar Boolean would invalidate this finding, but the current function documents and returns a pair.
  Probe: `PYTHONDONTWRITEBYTECODE=1 python3` with `sys.path.insert(0, 'utils/py'); import relay_attest; r = relay_attest.candidate_ok({'isolated': False}, 'HEAD', '.'); print(repr(r)); print(bool(r)); print(r == True)`; exit 0; decisive output: `(False, 'review ran without worktree isolation; its input was not a pinned revision')`, `True`, `False`. This input returns before any git subprocess; no git command was run.
- [Nit] **Document the usable approval workflow in the positive control.** State that the skill change must be committed before an isolated target-tree review, with no seeded `--artifact`, and the candidate must remain within the existing two-commit budget. `utils/py/relay_attest.py:404` rejects non-isolated/seeded reviews, and `utils/py/express.py:553` enforces the commit budget. The positive control should model those constraints, rather than only describe a “valid approved attestation.” Do not relax either guard to make the example pass.
- [Pass] **Reuse and containment fit the requested scope.** The plan extends `utils/py/express.py`, reuses `relay_attest.load`/`candidate_ok`, and extends the existing `test/gh267-express-skill.sh`; its exclusion list explicitly includes `merge-cleanup-deep` and `marathon-cleanup` as well as the named core skills. These are appropriate existing owners and no new suite is proposed.
- [Unverified — needs clone run] The proposed positive admission and negative controls have not run. This turn reviewed the entire embedded artifact, including status, rollback, implementation sequence and acceptance criteria; no additional pre-existing defect in that artifact was identified beyond the API-contract issue above. Implementation and suite results remain future evidence.

Handing off to Producer (antigravity) — correct the predicate contract and clarify the positive-control workflow, then return for round 2.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
