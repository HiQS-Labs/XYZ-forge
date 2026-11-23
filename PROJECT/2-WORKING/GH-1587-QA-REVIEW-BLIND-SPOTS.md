---
title: "GH-1587: Close 6 Recurring High-Severity Review Blind Spots Across review-code-xyz, review-pr-xyz, and relay-xyz"
status: active
created: 2026-11-23
updated: 2026-11-23
owner: noelsaw
goal: "Close 6 recurring High-severity code review blind spots and the GH-681/GH-564 Catch-22 across review-code-xyz, review-pr-xyz, relay-xyz, relay, start-task, and relay-automation without duplicating skill ladders, adding new test files, or breaking parser/test pins."
gh_issue: 1587
branch: fix/XYZ-forge-gh1587-qa-review-blind-spots-2026-11-23
effort: 2
complexity: 2
risk: 2
phases: 2
context_tags: [qa, review-code-xyz, review-pr-xyz, relay-xyz, gh681, start-task]
non_goals:
  - "Do not duplicate review-code-xyz Phase 1/2/4 definitions into review-pr-xyz"
  - "Do not add new test files, test suites, or validate.sh entries (GH-831)"
  - "Do not edit frozen Bash twins such as relay-automation/marathon-drive.sh (GH-308)"
  - "Do not change canonical [Blocker]/[Should]/[Nit]/[Pass] tag syntax parsed by utils/py/review_xyz.py"
  - "Do not weaken GH-681's unproven-generalization guardrail or GH-564's relay worktree containment"
---

# GH-1587: Close 6 Recurring High-Severity Review Blind Spots Across `review-code-xyz`, `review-pr-xyz`, and `relay-xyz`

Tracking issue: [HiQS-Labs/XYZ-forge#1587](https://github.com/HiQS-Labs/XYZ-forge/issues/1587)
Consult dispositions: [#1587 comment](https://github.com/HiQS-Labs/XYZ-forge/issues/1587#issuecomment-7116016593)

## Status

| What was just completed | What's next |
|---|---|
| Created fresh task clone off `origin/development` (`14cb8a60d`), verified pre-push hook, ran prior-art recon, pinned exact lines across all 10 target files, and authored this surgical plan. | Register/rate GH-1587 in `releases.db`, run Codex Plan QA via `relay-xyz` (Step 6), admit via `--accepted-start`, and implement Phase 1. |

## Quad Concepts

- **Six recurring High-severity PR blind spots (test-honesty, TOCTOU, sibling/deploy drift, test-inversion, native-framework reinvention, resume-key instability)** → fold targeted, surface-triggered checks into the single canonical ladder in `skills/2-daily/review-code-xyz/SKILL.md` and the claim-validation table in `skills/2-daily/review-pr-xyz/SKILL.md`.
- **GH-681 vs GH-564 Catch-22 (relay reviewer needs an observed failure to raise `[Blocker]`/`[Should]`, yet cannot run concurrency/external-service/container tests in the relay worktree)** → split `Observed input:` into two strict, non-speculative forms (observed failure/artifact contradiction OR hop-by-hop unrunnable runtime hazard trace with a runnable `Clone probe:`) while preserving canonical `[Blocker]`/`[Should]` tags and `Declined — unproven generalization`.
- **Relay QA prompt drift & missed surface checks in `start-task`** → keep `relay-turn-lib.sh`, `new-relay.sh`, `utils/py/marathon_drive.py`, `skills/1-hourly/relay/SKILL.md`, `skills/1-hourly/relay-xyz/SKILL.md`, `skills/1-hourly/start-task/SKILL.md`, `relay-automation/README.md`, `relay-pkg.tar.gz`, and `test/gh681-reviewer-probe-rules.sh` synchronized.

## Table of contents

- [Preflight Bet Check](#preflight-bet-check)
- [Recon & Evidence](#recon--evidence)
- [Acceptance Map & Rejection Criteria](#acceptance-map--rejection-criteria)
- [Phase 1: Surgical Skill, Relay Prompt & Test Pin Updates](#phase-1-surgical-skill-relay-prompt--test-pin-updates)
- [Phase 2: Disposable-Clone Verification, Live GH-836 Check & Final Relay QA](#phase-2-disposable-clone-verification-live-gh-836-check--final-relay-qa)
- [Test Non-Scope (GH-831)](#test-non-scope-gh-831)
- [Rollback](#rollback)

---

## Preflight Bet Check

- **Outcome sought:** Ensure `review-code-xyz`, `review-pr-xyz`, `relay-xyz`, and `start-task` catch the six documented High-severity defect classes surfaced in an 8-PR forensic audit (`BinoidCBD/LTVera-Pandas` PRs `#1191`, `#1145`, `#1005`, `#980`, `#909`, `#838`, `#729`, `#500`), and allow relay reviewers to escalate unrunnable runtime hazards (concurrency/external-service/container bugs) with a falsifiable `Clone probe:` rather than dropping them under GH-681 or fabricating speculative generalizations.
- **Smallest viable bet:** Surgical prose updates to the 5 existing skill files, 3 relay prompt/doc files, 1 Python marathon brief (`utils/py/marathon_drive.py`), and in-place updates to `test/gh681-reviewer-probe-rules.sh` + regenerated `skills/1-hourly/relay-automation/relay-pkg.tar.gz`.
  - **Explicit non-goals:** No new skills, no new test files or `validate.sh` entries (GH-831), no new finding tag formats (keep `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]` verbatim so `utils/py/review_xyz.py` regexes are untouched), no weakening of GH-564 worktree containment, no editing of frozen Bash twins (`relay-automation/marathon-drive.sh`, GH-308), no duplicating `review-code-xyz` into `review-pr-xyz`.
- **Alternatives rejected:**
  1. *Adding a new standalone review checklist skill or duplicating checks in `review-pr-xyz`*: rejected because `review-pr-xyz/SKILL.md:21-24` explicitly declares `review-code-xyz` as the single source of truth; duplication creates maintenance drift.
  2. *Introducing a new `[Blocker — needs clone probe]` finding tag*: rejected because `utils/py/review_xyz.py:62-63` parses literal `\[Blocker\]` / `\[Should\]` tags; adding a new tag syntax would break existing parsers for zero benefit.
  3. *Relaxing GH-564 to allow full test suites or external runtimes inside the relay worktree*: rejected because worktree containment prevents residue and cross-test corruption; handing off an exact `Clone probe:` to the Producer's disposable full clone preserves containment and falsifiability.
- **Rollback / containment:** Purely reversible prompt, skill-doc, tarball, and existing-test-pin edits on a feature branch; a single `git revert` restores prior wording and `relay-pkg.tar.gz` cleanly with zero schema, ledger, or runtime-state migration.

---

## Recon & Evidence

**Base SHA verified:** `14cb8a60d` (`origin/development`).

### Prior-Art Check (`utils/py/prior_art_recon.py`)
- `#681` (CLOSED): originally added read-only reviewer probes and the `Observed input:` / `Affected scope:` / `Falsifier:` generalization rule. GH-1587 extends GH-681 without weakening it by adding the strictly bounded unrunnable-runtime-hazard form + `Clone probe:`.
- `#1428` / `#1432`, `#1465` / `#1467`, `#1503` / `#1505` (CLOSED/MERGED): addressed reviewer gate execution, unverified-approval refusal, and carrying earlier findings open across rounds. None of them address the 6 review blind spots or the GH-681/GH-564 unrunnable-hazard Catch-22.
- `#1092` (OPEN): tracks reviewer measurement authority and absence-based umbrella closure; orthogonal to GH-1587's review checklist and `Clone probe:` handoff.

### Exact Target Seams (Verified at `14cb8a60d`)
1. `skills/2-daily/review-code-xyz/SKILL.md`:
   - Lane B (`L118`): add surface-triggered TOCTOU interleaving across lock release / DB read / external I/O / cache invalidation (reproduce via small throwaway interleaving probe in disposable clone).
   - Lane C (`L119`) & Step N+1 Rollout Coexistence (`L150`): add warm-state deploy/IAM/SA upgrade transitions, sibling-endpoint guard parity, and flagging substring/mock-only tests of external dialects/runtimes (SQL/DDL/browser/CLI).
   - Lane E (`L121`, `L129-134`): expand anti-reinvention to custom layers duplicating native capabilities of the repo's installed framework/runtime (not only `utils/py/`).
   - Phase 2 Mantra 3 (`L182-193`): bound mutation falsification to **3–5 high-leverage mutations** (core fix/refusal + lock/safety guard if touched + wiring/lifespan registration if touched) + mandatory **Test-Honesty body audit** (confirm new/changed tests exercise the real seam named in their title rather than mocking it away).
   - Phase 2 Mantra 4 (`L194-196`): cross-check modified/removed/weakened existing tests for silent inversion of documented historical invariants (flag as `[Blocker]` unless backed by explicit requirement/issue change).
   - Phase 2 Feature Stress (`L210-213`): add multi-invocation stability check for time/state-derived resume keys/cursors/watermarks.
   - Phase 4 report template (`L353`): keep existing `Mutation Falsification:` bullet (record bounded mutations + test-honesty check there; no new score table).
2. `skills/2-daily/review-pr-xyz/SKILL.md`:
   - Phase 1 Claim Validation table (`L106-114`): add **Test-invariance / historical-invariant** check — inspect modified, weakened, or deleted existing tests in the PR diff to verify they do not silently invert a previously asserted invariant without explicit issue/requirement authorization; keep `review-code-xyz` as single source of truth for Phases 2–4 (`L21-24`).
3. `relay-automation/relay-turn-lib.sh`:
   - `rtl_turn_prompt` reviewer `role_note` (`L1067`): clarify that when a suspected defect requires an unrunnable runtime/concurrency/external-service check forbidden in the relay worktree, the reviewer must not silently drop it or guess — instead emit a hop-by-hop `file:line` trace with `Affected scope:`, `Falsifier:`, and an exact `Clone probe:` command/script so the Producer can fix or falsify it in a disposable full clone. Keep every existing pinned substring intact (`test/gh681-reviewer-probe-rules.sh:43-55`).
4. `relay-automation/new-relay.sh`:
   - Reviewer & Producer bullets (`L79-107`): split `Observed input:` into two strict, non-speculative forms:
     - Form 1: *Observed failure or artifact contradiction* (failing probe/gate output, or concrete `fileA:line` vs `fileB:line` contradiction such as IAM SA mismatch, inverted test, or sibling guard omission).
     - Form 2: *Unrunnable runtime hazard trace* (permitted ONLY when verification requires an external service, multi-process concurrency, or browser/container runtime forbidden in the relay worktree): hop-by-hop `file:line` trace + `Affected scope:` + `Falsifier:` + exact `Clone probe:` command/script.
   - Keep `A [Blocker] must cite an observed failure` (pinned by `test/gh681-reviewer-probe-rules.sh:80`) and clarify both valid forms; Producer must fix or falsify a valid `Clone probe:` in a disposable clone (`Declined — falsified by clone probe: <cmd → output>`), while incomplete traces or speculative asks remain `Declined — unproven generalization`.
5. `utils/py/marathon_drive.py`:
   - Reviewer step `4c` (`L3177-3184`): mirror the exact tightened GH-681 two-form `Observed input:` + `Clone probe:` + `Declined — falsified by clone probe` contract (keep `Declined — unproven generalization` intact).
6. `skills/1-hourly/relay/SKILL.md`:
   - Reviewer & Producer turn bullets (`L251-252`): mirror the tightened GH-681 two-form `Observed input:` + `Clone probe:` + `Declined — falsified by clone probe` contract.
7. `skills/1-hourly/relay-xyz/SKILL.md`:
   - Review Scope rules 5–6 (`L717-718`): mirror the tightened GH-681 probe/generalization/Clone-probe contract while preserving all strings pinned by `test/gh617-relay-xyz-commensurate-review.sh` and `test/gh681-reviewer-probe-rules.sh`.
8. `skills/1-hourly/start-task/SKILL.md`:
   - Step 6 (`L218-236`) & Step 8 (`L313-330`): instruct the packet author to include surface-triggered QA questions matching touched surfaces (concurrency/locking → TOCTOU interleaving; deploys/IAM/siblings → warm-state coexistence & guard parity; tests modified → test-honesty & historical-invariant check; time/state cursors → multi-invocation stability; new layers → native framework capability check), and instruct the Producer to execute any reviewer `Clone probe:` in a disposable full clone and record either a fix or `Declined — falsified by clone probe: <cmd → output>`.
9. `relay-automation/README.md`:
   - `relay-turn-lib.sh` table row (`L26`): update the GH-681 note concisely to reflect the `Clone probe:` handoff for unrunnable runtime hazards.
10. `test/gh681-reviewer-probe-rules.sh`:
    - Extend existing cases 1, 4, and 6 in-place (GH-831 compliant: no new test file) to assert `Clone probe:` and `Declined — falsified by clone probe` across `rtl_turn_prompt`, `new-relay.sh`, `skills/1-hourly/relay/SKILL.md`, `skills/1-hourly/relay-xyz/SKILL.md`, and `utils/py/marathon_drive.py`, plus a negative-control check that removing `Clone probe:` fails the check.
11. **Generated package:** regenerate `skills/1-hourly/relay-automation/relay-pkg.tar.gz` via `bash skills/1-hourly/relay-automation/make-pkg.sh` (verified by `test/relay-pkg-freshness.sh`).

### Confirmed Non-Edits
- `utils/py/rtl.py`: delegates `turn_prompt()` directly to `relay-automation/relay-turn-lib.sh`.
- `relay-automation/marathon-drive.sh`: GH-308 frozen Bash twin (pinned by `test/gh308-frozen-twin-guard.sh`) — must not edit.
- `utils/py/review_xyz.py`: canonical `[Blocker]`/`[Should]` regexes remain untouched and valid.

### Pinned Existing Test Suites Covering These Files
- `test/gh681-reviewer-probe-rules.sh`
- `test/relay-pkg-freshness.sh`
- `test/gh778-review-code-skill.sh`
- `test/gh617-relay-xyz-commensurate-review.sh`
- `test/gh616-start-task-commensurate-envelope.sh`
- `test/gh615-start-task-reinforce.sh`
- `test/gh609-sdlc-agent-gaps.sh`
- `test/gh397-reviewer-turn-role.sh`
- `test/gh505-relay-attest.sh`
- `test/gh268-relay-cue-and-target-checks.sh`
- `test/gh91-relay-scratch.sh`
- `test/new-relay.sh`
- `test/debug-mantra.sh`
- `test/gh308-frozen-twin-guard.sh`
- `test/gh589-xyz-mini-sync.sh`
- `test/gh798-status-skill.sh`
- `test/relay-self-sufficiency.sh` (live GH-836 check with `RELAY_SELF_SUFFICIENCY_SKIP=0`)

---

## Acceptance Map & Rejection Criteria

| Requirement | Artifact / Behavior Observed | What prevents an unchanged candidate from passing (Observed Rejection) |
|---|---|---|
| 1. 6 High-severity blind spots closed in canonical review ladder (no duplication into `review-pr-xyz`) | `skills/2-daily/review-code-xyz/SKILL.md` (Lanes B/C/E, Step N+1, Mantras 3–4, Feature Stress) & `skills/2-daily/review-pr-xyz/SKILL.md` (Phase 1 Claim Validation) | Diff inspection + `test/gh778-review-code-skill.sh` + `test/gh589-xyz-mini-sync.sh`: unchanged files lack test-honesty body audit, 3–5 bounded mutation scope, TOCTOU interleaving, warm-state deploy/sibling parity, native-framework anti-reinvention, resume-key stability, and test-inversion claim validation. |
| 2. GH-681/GH-564 Catch-22 resolved via 2-form `Observed input:` + `Clone probe:` while preserving canonical `[Blocker]`/`[Should]` tags and `Declined — unproven generalization` | `relay-automation/relay-turn-lib.sh`, `relay-automation/new-relay.sh`, `utils/py/marathon_drive.py`, `skills/1-hourly/relay/SKILL.md`, `skills/1-hourly/relay-xyz/SKILL.md`, `relay-automation/README.md` | Updated `test/gh681-reviewer-probe-rules.sh` fails on the unchanged base (missing `Clone probe:` / `Declined — falsified by clone probe` in prompt, scaffold, and all 3 mirrors) and passes after edits; `utils/py/review_xyz.py` tag regex unchanged. |
| 3. `start-task` injects surface-triggered QA questions & executes reviewer `Clone probe:` in disposable clone | `skills/1-hourly/start-task/SKILL.md` Steps 6 & 8 | Diff inspection + `test/gh609-sdlc-agent-gaps.sh`, `test/gh615-start-task-reinforce.sh`, `test/gh616-start-task-commensurate-envelope.sh`. |
| 4. Bundled tarball fresh & GH-836 live self-sufficiency + scaffold smoke verified | `skills/1-hourly/relay-automation/relay-pkg.tar.gz`, `TESTS-RESULTS/2026-11-23+GH-1587/` (`provenance.jsonl` + logs) | `test/relay-pkg-freshness.sh` rejects stale tarball; live `RELAY_SELF_SUFFICIENCY_SKIP=0 bash test/relay-self-sufficiency.sh` fails if `rtl_turn_prompt` breaks live Codex/Agy turn execution; scaffolded `new-relay.sh` smoke turn against a reconstructed unrunnable-hazard fixture verifies the new `Clone probe:` instructions work end-to-end. |
| 5. Repo constraints respected (GH-831, GH-308, PDDA, Tier-3 gate) | `git diff --stat`, `utils/pdda/pdda.sh run`, Tier-3 `validate.sh` via pre-push hook | No new `test/*.sh` or `validate.sh` entries; `relay-automation/marathon-drive.sh` untouched (`test/gh308-frozen-twin-guard.sh` green); PDDA clean. |

---

## Phase 1: Surgical Skill, Relay Prompt & Test Pin Updates

Ordered implementation steps (after Codex Plan QA approval and `roadmap update --accepted-start`):
1. Update `skills/2-daily/review-code-xyz/SKILL.md` (Lanes B, C, E; Step N+1 Rollout Coexistence; Phase 2 Mantras 3–4 & Feature Stress; Phase 4 `Mutation Falsification` bullet).
2. Update `skills/2-daily/review-pr-xyz/SKILL.md` (Phase 1 Claim Validation table: add Test-invariance / historical-invariant row; keep Phase 2–4 delegation intact).
3. Update `relay-automation/relay-turn-lib.sh` (`rtl_turn_prompt` reviewer `role_note`) and `relay-automation/new-relay.sh` (Reviewer & Producer bullets).
4. Update `utils/py/marathon_drive.py` (Reviewer step `4c`), `skills/1-hourly/relay/SKILL.md` (L251–252), `skills/1-hourly/relay-xyz/SKILL.md` (L717–718), `skills/1-hourly/start-task/SKILL.md` (Steps 6 & 8), and `relay-automation/README.md` (L26).
5. Update `test/gh681-reviewer-probe-rules.sh` in-place to pin the new `Clone probe:` / `Declined — falsified by clone probe` contract across prompt, scaffold, and mirrors (including a negative control).
6. Regenerate `skills/1-hourly/relay-automation/relay-pkg.tar.gz` with `bash skills/1-hourly/relay-automation/make-pkg.sh`.
7. Run all focused pinned test suites + `utils/pdda/pdda.sh run` and commit the implementation checkpoint.

### Phase 1 QA Gate
- All 16 focused pinned test suites pass (`exit 0`).
- `test/relay-pkg-freshness.sh` passes (`exit 0`).
- `utils/pdda/pdda.sh run` passes (`exit 0`).
- `git diff --name-only` contains only the bounded write-set (zero new test files, zero edits to frozen Bash twins).

---

## Phase 2: Disposable-Clone Verification, Live GH-836 Check & Final Relay QA

1. Create a separate disposable full clone `../XYZ-forge-gh1587-qa-review-blind-spots-2026-11-23-verify` checked out at the committed branch head with canonical origin URL `https://github.com/HiQS-Labs/XYZ-forge.git` (GH-1493).
2. In the disposable verify clone, verify clone identity before/after and run:
   - Live GH-836 check: `RELAY_SELF_SUFFICIENCY_SKIP=0 bash test/relay-self-sufficiency.sh` (must pass non-skipped).
   - GH-1088 / GH-836 scaffold smoke (main path + adjacent path): scaffold a fresh relay via `relay-automation/new-relay.sh` against a small reconstructed fixture containing an unrunnable runtime hazard (e.g., TOCTOU / missing sibling guard) and drive a real Codex reviewer turn (`CODEX_FLAGS="-s workspace-write -c approval_policy=never -m gpt-6.1-terra"`), verifying the reviewer emits `Observed input:`, `Affected scope:`, `Falsifier:`, and `Clone probe:` cleanly under the new scaffold, plus an adjacent path verifying `Declined — unproven generalization` / `test/gh681-reviewer-probe-rules.sh` negative control.
3. Record receipts and `provenance.jsonl` under `TESTS-RESULTS/2026-11-23+GH-1587/` in the task clone and commit them.
4. Run Final Codex Relay QA (`relay-xyz`) on the committed implementation, plan, acceptance map, and receipts until `Approved`.
5. Check `LESSONS-LEARNED.md` writer rules, run `bash utils/ci-local.sh --fast`, verify `bash githooks/install.sh --check`, push through the pre-push hook (which executes the single full Tier-3 `./validate.sh` run on the final approved commit per GH-1518), open the ready PR against `development`, post the idempotent issue closeout comment, and retire the published checkouts via `merge-cleanup --retire-published-pr`.

### Phase 2 QA Gate
- Live `test/relay-self-sufficiency.sh` passes (non-skipped) and is recorded in `TESTS-RESULTS/2026-11-23+GH-1587/provenance.jsonl`.
- Scaffolded `new-relay.sh` smoke turn receipt recorded in `TESTS-RESULTS/2026-11-23+GH-1587/`.
- Final Codex Relay QA verdict is `Approved` on the final head SHA.
- Pre-push hook full Tier-3 `./validate.sh` passes and PR is open against `development`.

---

## Test Non-Scope (GH-831)

Per `AGENTS.md` (*No new tests*, GH-831), this task creates **zero** new test files under `test/` and adds **zero** new entries to `validate.sh`. Verification relies strictly on editing `test/gh681-reviewer-probe-rules.sh` in-place, running the existing pinned suites, executing the live GH-836 check and `new-relay.sh` smoke run recorded under `TESTS-RESULTS/2026-11-23+GH-1587/`, and passing the pre-push Tier-3 `./validate.sh` gate.

## Rollback

Revert the PR commit(s) on `development` (`git revert <merge-sha>`). Because every change is confined to skill documentation, relay turn prompts, the packaged tarball, and in-place pin assertions, rollback is instant and lossless with no data or state migration.
