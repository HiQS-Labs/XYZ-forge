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
| Registered and rated GH-1587 in `releases.db` (`rmi-01M859AVNYRXE06BH6A6QH6F5E`, `rated 85/80/50/70`, neutral appeal `50`, `doc_path: PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md`) and revised this plan after Codex Plan QA Round 1 to tighten clone verification boundaries, rejection evidence, and Form 2 `Clone probe:` closure rules. | Complete Codex Plan QA Round 2 approval, verify persisted row `rmi-01M859AVNYRXE06BH6A6QH6F5E` and run `--accepted-start`, then implement Phase 1. |

## Quad Concepts

- **Six recurring High-severity PR blind spots (test-honesty, TOCTOU, sibling/deploy drift, test-inversion, native-framework reinvention, resume-key instability)** → fold targeted, surface-triggered checks into the single canonical ladder in `skills/2-daily/review-code-xyz/SKILL.md` and the claim-validation table in `skills/2-daily/review-pr-xyz/SKILL.md`.
- **GH-681 vs GH-564 Catch-22 (relay reviewer needs an observed failure to raise `[Blocker]`/`[Should]`, yet cannot run concurrency/external-service/container tests in the relay worktree)** → split `Observed input:` into two strict, non-speculative forms (Form 1 observed failure/artifact contradiction OR Form 2 hop-by-hop unrunnable runtime hazard trace with a runnable `Clone probe:` that remains pending until the Producer executes it in a disposable full clone) while preserving canonical `[Blocker]`/`[Should]` tags and `Declined — unproven generalization`.
- **Relay QA prompt drift & missed surface checks in `start-task`** → keep `relay-turn-lib.sh`, `new-relay.sh`, `utils/py/marathon_drive.py`, `skills/1-hourly/relay/SKILL.md`, `skills/1-hourly/relay-xyz/SKILL.md`, `skills/1-hourly/start-task/SKILL.md`, `relay-automation/README.md`, `relay-pkg.tar.gz`, and existing pin tests (`gh681`, `gh778`, `gh616`) synchronized.

## Table of contents

- [Preflight Bet Check](#preflight-bet-check)
- [Recon & Evidence](#recon--evidence)
- [Form 1 vs Form 2 Severity & Closure Rules (GH-681 + GH-564)](#form-1-vs-form-2-severity--closure-rules-gh-681--gh-564)
- [Acceptance Map: Admission Pins vs Behavioral Rejection Evidence](#acceptance-map-admission-pins-vs-behavioral-rejection-evidence)
- [Phase 1: Surgical Skill, Relay Prompt & Existing Pin Updates](#phase-1-surgical-skill-relay-prompt--existing-pin-updates)
- [Phase 2: Disposable-Clone Verification, Live GH-836 & Producer Clone-Probe Smoke, and Final QA](#phase-2-disposable-clone-verification-live-gh-836--producer-clone-probe-smoke-and-final-qa)
- [Test Non-Scope (GH-831)](#test-non-scope-gh-831)
- [Rollback](#rollback)

---

## Preflight Bet Check

- **Outcome sought:** Ensure `review-code-xyz`, `review-pr-xyz`, `relay-xyz`, and `start-task` catch the six documented High-severity defect classes surfaced in an 8-PR forensic audit (`BinoidCBD/LTVera-Pandas` PRs `#1191`, `#1145`, `#1005`, `#980`, `#909`, `#838`, `#729`, `#500`), and allow relay reviewers to escalate unrunnable runtime hazards (concurrency/external-service/container bugs) with a falsifiable `Clone probe:` rather than dropping them under GH-681 or fabricating speculative generalizations.
- **Smallest viable bet:** Surgical prose updates to the 5 existing skill files, 3 relay prompt/doc files, 1 Python marathon brief (`utils/py/marathon_drive.py`), in-place pin updates to 3 existing test suites (`test/gh681-reviewer-probe-rules.sh`, `test/gh778-review-code-skill.sh`, `test/gh616-start-task-commensurate-envelope.sh`), and regenerated `skills/1-hourly/relay-automation/relay-pkg.tar.gz`.
  - **Explicit non-goals:** No new skills, no new test files or `validate.sh` entries (GH-831), no new finding tag formats (keep `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]` verbatim so `utils/py/review_xyz.py` regexes are untouched), no weakening of GH-564 worktree containment, no editing of frozen Bash twins (`relay-automation/marathon-drive.sh`, GH-308), no duplicating `review-code-xyz` into `review-pr-xyz`.
- **Alternatives rejected:**
  1. *Adding a new standalone review checklist skill or duplicating checks in `review-pr-xyz`*: rejected because `review-pr-xyz/SKILL.md:21-24` explicitly declares `review-code-xyz` as the single source of truth; duplication creates maintenance drift.
  2. *Introducing a new `[Blocker — needs clone probe]` finding tag*: rejected because `utils/py/review_xyz.py:62-63` parses literal `\[Blocker\]` / `\[Should\]` tags; adding a new tag syntax would break existing parsers for zero benefit.
  3. *Relaxing GH-564 to allow full test suites or external runtimes inside the relay worktree*: rejected because worktree containment prevents residue and cross-test corruption; handing off an exact `Clone probe:` to the Producer's disposable full clone preserves containment and falsifiability.
- **Rollback / containment:** Purely reversible prompt, skill-doc, tarball, and existing-test-pin edits on a feature branch; reverting the commit restores prior wording and `relay-pkg.tar.gz` cleanly with zero schema, ledger, or runtime-state migration.

---

## Recon & Evidence

**Base SHA verified:** `14cb8a60d` (`origin/development`).

### Persisted Roadmap Registration & Rating
- **Global ID:** `rmi-01M859AVNYRXE06BH6A6QH6F5E`
- **Issue:** `https://github.com/HiQS-Labs/XYZ-forge/issues/1587` (`gh_number: 1587`)
- **Persisted rating:** `pri=85 / sev=80 / appeal=50 (neutral) / effort=70`, `rating_ovr=null` (`rated 85/80/50/70`)
- **Section (pre-admission):** `Queue / parked intake`
- **Doc path:** `PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md`
- **Pre-write admission gate:** After Codex Plan QA reaches `Approved` and before the first Phase 1 write, re-read `python3 utils/py/releases_app.py roadmap list --json`, verify `rmi-01M859AVNYRXE06BH6A6QH6F5E` still holds `85/80/50/70` and `ovr=null`, then admit via `python3 utils/py/releases_app.py roadmap update --gid rmi-01M859AVNYRXE06BH6A6QH6F5E --accepted-start`.

### Prior-Art Check (`utils/py/prior_art_recon.py`)
- `#681` (CLOSED): originally added read-only reviewer probes and the `Observed input:` / `Affected scope:` / `Falsifier:` generalization rule. GH-1587 extends GH-681 without weakening it by adding Form 2 (`Clone probe:`) with mandatory Producer execution.
- `#1428` / `#1432`, `#1465` / `#1467`, `#1503` / `#1505` (CLOSED/MERGED): addressed reviewer gate execution, unverified-approval refusal, and carrying earlier findings open across rounds. None address the 6 review blind spots or the GH-681/GH-564 unrunnable-hazard Catch-22.
- `#1092` (OPEN): tracks reviewer measurement authority and absence-based umbrella closure; orthogonal to GH-1587.

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
   - Phase 1 Claim Validation table (`L106-114`): add **Test-invariance / historical-invariant** row — inspect modified, weakened, or deleted existing tests in the PR diff to verify they do not silently invert a previously asserted invariant without explicit issue/requirement authorization; keep `review-code-xyz` as single source of truth for Phases 2–4 (`L21-24`).
3. `relay-automation/relay-turn-lib.sh`:
   - `rtl_turn_prompt` reviewer `role_note` (`L1067`): add concise Form 2 `Clone probe:` guidance for unrunnable runtime hazards while preserving every existing pinned substring (`test/gh681-reviewer-probe-rules.sh:43-55`).
4. `relay-automation/new-relay.sh`:
   - Reviewer & Producer bullets (`L79-107`): codify Form 1 vs Form 2 `Observed input:`, severity/pending-verification status, `Clone probe:`, and all three Producer closure outcomes (reproduced, falsified, errored/unavailable keeps finding open and blocks `Approved`), while keeping `Declined — unproven generalization` and `must cite an observed failure` intact.
5. `utils/py/marathon_drive.py`:
   - Reviewer step `4c` (`L3177-3184`): mirror the exact tightened Form 1 / Form 2 + `Clone probe:` + Producer closure rules.
6. `skills/1-hourly/relay/SKILL.md`:
   - Reviewer & Producer turn bullets (`L251-252`): mirror the exact tightened Form 1 / Form 2 + `Clone probe:` + Producer closure rules.
7. `skills/1-hourly/relay-xyz/SKILL.md`:
   - Review Scope rules 5–6 (`L717-718`): mirror the tightened Form 1 / Form 2 + `Clone probe:` + Producer closure rules while preserving all strings pinned by `test/gh617-relay-xyz-commensurate-review.sh` and `test/gh681-reviewer-probe-rules.sh`.
8. `skills/1-hourly/start-task/SKILL.md`:
   - Step 6 (`L218-236`) & Step 8 (`L313-330`): instruct the packet author to include surface-triggered QA questions matching touched surfaces (concurrency/locking → TOCTOU interleaving; deploys/IAM/siblings → warm-state coexistence & guard parity; tests modified → test-honesty & historical-invariant check; time/state cursors → multi-invocation stability; new layers → native framework capability check), and instruct the Producer to execute any reviewer `Clone probe:` in a disposable full clone and record the observed outcome (fix + output, `Declined — falsified by clone probe: <cmd → output>`, or keep open if errored/unavailable).
9. `relay-automation/README.md`:
   - `relay-turn-lib.sh` table row (`L26`): update the GH-681 note concisely to reflect the Form 2 `Clone probe:` handoff.
10. Existing pin suites edited in-place (GH-831 compliant — zero new test files):
    - `test/gh681-reviewer-probe-rules.sh`: extend cases 1, 4, 6 + add negative-control mutation for `Clone probe:`, `Declined — falsified by clone probe`, and the keep-open unavailable-probe rule across `rtl_turn_prompt`, `new-relay.sh`, `relay/SKILL.md`, `relay-xyz/SKILL.md`, and `marathon_drive.py`.
    - `test/gh778-review-code-skill.sh`: extend section 4 (quality gates & anti-patterns) and section 8 (negative control mutations) in-place to pin the 6 new checks in `review-code-xyz/SKILL.md` (TOCTOU interleaving, warm-state deploy / sibling parity, native framework anti-reinvention, Test-Honesty body audit + 3–5 bounded mutations, historical-invariant test-inversion, multi-invocation resume-key stability) and the test-invariance claim row in `review-pr-xyz/SKILL.md`.
    - `test/gh616-start-task-commensurate-envelope.sh`: extend `check_start_task_commensurate_contract` and `run_mutation` in-place to pin surface-triggered QA questions and disposable-clone `Clone probe:` execution in `start-task/SKILL.md`.
11. **Generated package:** regenerate `skills/1-hourly/relay-automation/relay-pkg.tar.gz` via `bash skills/1-hourly/relay-automation/make-pkg.sh` (verified by `test/relay-pkg-freshness.sh`).

### Confirmed Non-Edits
- `utils/py/rtl.py`: delegates `turn_prompt()` directly to `relay-automation/relay-turn-lib.sh:1067` (`utils/py/rtl.py:1118-1119`).
- `relay-automation/marathon-drive.sh`: GH-308 frozen Bash twin (pinned by `test/gh308-frozen-twin-guard.sh`) — must not edit.
- `utils/py/review_xyz.py`: canonical `[Blocker]`/`[Should]` regexes (`L62-63`) remain untouched and valid.

---

## Form 1 vs Form 2 Severity & Closure Rules (GH-681 + GH-564)

Every `[Blocker]` or `[Should]` requesting a behaviour change MUST carry `Observed input:`, `Affected scope:`, and `Falsifier:`. `Observed input:` accepts exactly two strict, non-speculative forms:

1. **Form 1 — Observed failure or artifact contradiction:** a failing read-only probe/gate output, OR a concrete `fileA:line` vs `fileB:line` contradiction (for example IAM/SA identity mismatch, inverted existing test assertion, or omitted sibling endpoint guard). Qualifies for `[Blocker]` or `[Should]` directly because the defect is already observed.
2. **Form 2 — Unrunnable runtime hazard trace:** permitted **only** when reproduction requires an external service, multi-process concurrency, or a browser/container runtime forbidden in the relay worktree (GH-564). Must supply:
   - `Observed input:` hop-by-hop `file:line` trace showing the exact unguarded interleaving or runtime hazard,
   - `Affected scope:` input/runtime predicate governed by the change,
   - `Falsifier:` concrete fixture/outcome that would disprove the hazard,
   - `Clone probe:` exact runnable command or short script for the Producer's disposable full clone.
   - **Severity & pending status:** Default severity for an unexecuted Form 2 hazard is `[Should]`. A `[Blocker]` must cite an observed failure (Form 1) — it may only be raised via Form 2 when the static `file:line` trace itself proves an unconditional invariant breach, and in **either** severity a Form 2 finding remains **pending probe verification** until the Producer executes `Clone probe:` in a disposable full clone.
3. **Mandatory Producer closure outcomes for Form 2 (`Clone probe:`):**
   - **Reproduced:** fix the defect, paste the probe command + failing-before / passing-after output, and mark `Implemented`.
   - **Falsified:** run `Clone probe:` in a disposable full clone, confirm the falsifier holds, and disposition `Declined — falsified by clone probe: <cmd → exit + decisive output>`.
   - **Errored / environment unavailable:** the finding **stays OPEN** (`[Unverified — clone probe failed/unavailable]`). Neither Producer nor Reviewer may close `STATUS: Approved` on an unexecuted/errored `Clone probe:`; the relay must either re-run with a working probe or escalate/park (`STATUS: Escalated` / `VERDICT: PARKED`) for explicit operator risk acceptance.
4. **Incomplete or speculative asks:** Any behaviour-change finding lacking Form 1 evidence and lacking a complete Form 2 trace + `Affected scope:` + `Falsifier:` + `Clone probe:` remains `Declined — unproven generalization`.

---

## Acceptance Map: Admission Pins vs Behavioral Rejection Evidence

Per `test/gh681-reviewer-probe-rules.sh:17`, text pin suites establish **admission/regression pins** (they prove required instructions are present and detect accidental removal), whereas live relay turns establish **behavioral evidence** (they prove the rendered prompt/scaffold drives the intended Reviewer and Producer behavior). Both layers are kept strictly distinct below:

| Requirement | Layer A: Deterministic Admission Pins (Red on unchanged `14cb8a60d`, Green on candidate) | Layer B: Behavioral / Live Execution Evidence (in `-verify` disposable clone, recorded under `TESTS-RESULTS/2026-11-23+GH-1587/`) |
|---|---|---|
| 1. Six High-severity blind spots in `review-code-xyz` + test-inversion claim in `review-pr-xyz` (single source of truth) | Updated `test/gh778-review-code-skill.sh` checks all 6 blind-spot clauses + `review-pr-xyz` test-invariance row + negative-control mutations deleting each clause; verified RED against unchanged `14cb8a60d` copies and GREEN against candidate. | Live scaffolded Codex smoke review on a reconstructed defective Python fixture containing 3 concrete defect classes (TOCTOU lock-release race, sibling endpoint missing auth guard, and a test whose body mocks away the seam it claims to test) confirms the reviewer surfaces concrete `file:line` findings instead of false approval. |
| 2. GH-681/GH-564 Form 1 + Form 2 `Clone probe:` + Producer closure rules | Updated `test/gh681-reviewer-probe-rules.sh` checks `rtl_turn_prompt`, `new-relay.sh`, `relay/SKILL.md`, `relay-xyz/SKILL.md`, `marathon_drive.py`, plus negative-control mutations removing `Clone probe:` / `Declined — falsified by clone probe` / unavailable-probe keep-open text; verified RED against unchanged `14cb8a60d` and GREEN against candidate. | (a) Live GH-836 `RELAY_SELF_SUFFICIENCY_SKIP=0 bash test/relay-self-sufficiency.sh` (non-skipped PASS). (b) Live `new-relay.sh`-scaffolded Codex reviewer turn on the TOCTOU hazard emits `Observed input:`, `Affected scope:`, `Falsifier:`, and `Clone probe:`. (c) Producer-side smoke runs the emitted `Clone probe:` in the `-verify` clone on both a **falsified/reproduced** path AND an **errored/unavailable probe** path, verifying the finding closes only on real probe output and stays open when the probe fails/cannot run. |
| 3. `start-task` surface-triggered QA questions & Producer clone-probe handling | Updated `test/gh616-start-task-commensurate-envelope.sh` pins Step 6 surface-triggered QA questions and Step 8 disposable-clone `Clone probe:` execution + negative-control mutations; verified RED against `14cb8a60d` and GREEN against candidate. | Exercised directly in this task's own Step 8 Final QA packet (surface-triggered questions for touched prompt/skill/test files). |
| 4. Tarball freshness & repo constraints (GH-831, GH-308, PDDA, Tier-3) | `test/relay-pkg-freshness.sh`, `test/gh308-frozen-twin-guard.sh`, `utils/pdda/pdda.sh run`, `git diff --name-only` (zero new test files, zero edits to frozen Bash twins). | Full Tier-3 `./validate.sh` executed once via pre-push hook inside a standalone disposable full clone on the final approved SHA (GH-1518). |

---

## Phase 1: Surgical Skill, Relay Prompt & Existing Pin Updates

Ordered implementation steps (executed only after Codex Plan QA `Approved`, persisted row verification of `rmi-01M859AVNYRXE06BH6A6QH6F5E`, and `roadmap update --gid rmi-01M859AVNYRXE06BH6A6QH6F5E --accepted-start`):
1. Update `skills/2-daily/review-code-xyz/SKILL.md` (Lanes B, C, E; Step N+1 Rollout Coexistence; Phase 2 Mantras 3–4 & Feature Stress; Phase 4 `Mutation Falsification` bullet).
2. Update `skills/2-daily/review-pr-xyz/SKILL.md` (Phase 1 Claim Validation table: add Test-invariance / historical-invariant row; keep Phase 2–4 delegation intact).
3. Update `relay-automation/relay-turn-lib.sh` (`rtl_turn_prompt` reviewer `role_note`) and `relay-automation/new-relay.sh` (Reviewer & Producer bullets with Form 1/Form 2 + `Clone probe:` + 3 Producer closure outcomes).
4. Update `utils/py/marathon_drive.py` (Reviewer step `4c`), `skills/1-hourly/relay/SKILL.md` (L251–252), `skills/1-hourly/relay-xyz/SKILL.md` (L717–718), `skills/1-hourly/start-task/SKILL.md` (Steps 6 & 8), and `relay-automation/README.md` (L26).
5. Update `test/gh681-reviewer-probe-rules.sh`, `test/gh778-review-code-skill.sh`, and `test/gh616-start-task-commensurate-envelope.sh` in-place (GH-831 compliant: zero new test files).
6. Regenerate `skills/1-hourly/relay-automation/relay-pkg.tar.gz` with `bash skills/1-hourly/relay-automation/make-pkg.sh`.
7. Run read-only `utils/pdda/pdda.sh run` (non-mutating docs check) and commit the Phase 1 implementation checkpoint on `fix/XYZ-forge-gh1587-qa-review-blind-spots-2026-11-23`. **No `test/*.sh` or `./validate.sh` runs happen in the task clone during Phase 1.**

### Phase 1 QA Gate
- `utils/pdda/pdda.sh run` passes (`exit 0`).
- `git diff --name-only origin/development...HEAD` contains only the bounded write-set (zero new `test/*.sh` files, zero `validate.sh` additions, zero edits to frozen Bash twins).
- Implementation checkpoint is cleanly committed so Phase 2 can clone that exact SHA into the separate disposable `-verify` full clone.

---

## Phase 2: Disposable-Clone Verification, Live GH-836 & Producer Clone-Probe Smoke, and Final QA

**Clone safety boundary (AGENTS.md + GH-564 + GH-1493 + GH-1518):**
- All focused `test/*.sh` suites, red-on-base pin verification, live GH-836 `relay-self-sufficiency.sh`, and behavioral smoke runs execute **exclusively** inside a separate disposable full clone `../XYZ-forge-gh1587-qa-review-blind-spots-2026-11-23-verify` cloned from the task clone at the exact candidate SHA and configured with canonical `origin` URL `https://github.com/HiQS-Labs/XYZ-forge.git` (with clone identity verified before and after every run).
- The task clone `../XYZ-forge-gh1587-qa-review-blind-spots-2026-11-23` itself is ALSO a fresh standalone disposable full clone (never the primary clone, never a linked worktree). Per `start-task/SKILL.md:291` (GH-1518), after Final Codex QA approves the final commit, we run `bash utils/ci-local.sh --fast`, verify `bash githooks/install.sh --check`, and run `git push` from this standalone task clone so the pre-push hook executes the **single** full Tier-3 `./validate.sh` run on the final approved commit (avoiding running `./validate.sh` twice on the same SHA).

Ordered Phase 2 steps:
1. Create disposable full clone `../XYZ-forge-gh1587-qa-review-blind-spots-2026-11-23-verify` at the Phase 1 candidate SHA with canonical origin `https://github.com/HiQS-Labs/XYZ-forge.git`. Verify `git rev-parse HEAD` and `git remote get-url origin` before and after runs.
2. **Red-on-base vs Green-on-candidate pin verification (in `-verify` clone):**
   - Run the updated pin tests (`test/gh681-reviewer-probe-rules.sh`, `test/gh778-review-code-skill.sh`, `test/gh616-start-task-commensurate-envelope.sh`) against a checkout of `14cb8a60d` (or against `14cb8a60d` copies of the target files in `$TMPDIR`) to confirm **RED** rejection of unchanged files.
   - Run all 16 focused pinned test suites (`gh681`, `relay-pkg-freshness`, `gh778`, `gh617`, `gh616`, `gh615`, `gh609`, `gh397`, `gh505`, `gh268`, `gh91`, `new-relay`, `debug-mantra`, `gh308`, `gh589`, `gh798`) against the candidate SHA to confirm **GREEN** (`exit 0`).
3. **Live GH-836 self-sufficiency check (in `-verify` clone):**
   - Run `RELAY_SELF_SUFFICIENCY_SKIP=0 CODEX_FLAGS="-s workspace-write -c approval_policy=never -m gpt-6.1-terra" CODEX_MODEL="gpt-6.1-terra" bash test/relay-self-sufficiency.sh` and confirm non-skipped `PASS`.
4. **Behavioral scaffold & Producer clone-probe smoke (in `-verify` clone):**
   - **Main path (Reviewer Form 2 + Producer execution):** Scaffold a fresh relay via `relay-automation/new-relay.sh` against a small throwaway fixture in `$TMPDIR` containing a concrete TOCTOU lock-release hazard + missing sibling guard + mocked-out test body, drive a live Codex reviewer turn, verify the reviewer emits `Observed input:`, `Affected scope:`, `Falsifier:`, and `Clone probe:`, then execute the Producer clone probe against the fixture and record observed reproduction/falsification output.
   - **Adjacent path (Errored/unavailable probe keep-open + unproven generalization refusal):** Execute an intentionally failing/unavailable probe command (`exit != 0` / missing runtime) and verify the documented keep-open disposition (`[Unverified — clone probe failed/unavailable]`, approval blocked) plus `Declined — unproven generalization` on an incomplete trace.
5. Copy verification logs and write `provenance.jsonl` into `TESTS-RESULTS/2026-11-23+GH-1587/` in the task clone and commit them.
6. Run Final Codex Relay QA (`relay-xyz`) on the committed implementation, plan, acceptance map, and `TESTS-RESULTS/2026-11-23+GH-1587/` receipts until `Approved`.
7. Check `LESSONS-LEARNED.md` writer rules (append valid entry or record `NO_ENTRY`), update plan status to PR-ready, run `bash utils/ci-local.sh --fast`, verify `bash githooks/install.sh --check`, push through the pre-push Tier-3 `./validate.sh` gate, open ready PR against `development`, call `link_pull_request`, post idempotent closeout comment on `#1587`, and retire both clones via `merge-cleanup --retire-published-pr`.

### Phase 2 QA Gate
- All 16 focused pinned test suites pass (`exit 0`) in `-verify` clone, with recorded red-on-base rejection of unchanged `14cb8a60d` files.
- Live `test/relay-self-sufficiency.sh` passes (non-skipped) and is recorded in `TESTS-RESULTS/2026-11-23+GH-1587/provenance.jsonl`.
- Scaffolded `new-relay.sh` Reviewer + Producer clone-probe (reproduced/falsified AND unavailable-probe keep-open) smoke receipts recorded in `TESTS-RESULTS/2026-11-23+GH-1587/`.
- Final Codex Relay QA verdict is `Approved` on the final head SHA.
- Pre-push hook full Tier-3 `./validate.sh` passes on the final approved SHA and PR is open against `development`.

---

## Test Non-Scope (GH-831)

Per `AGENTS.md` (*No new tests*, GH-831), this task creates **zero** new test files under `test/` and adds **zero** new entries to `validate.sh`. Verification relies strictly on editing existing pin suites (`test/gh681-reviewer-probe-rules.sh`, `test/gh778-review-code-skill.sh`, `test/gh616-start-task-commensurate-envelope.sh`) in-place, running the existing pinned suites in `-verify`, executing the live GH-836 check and `new-relay.sh` + Producer smoke recorded under `TESTS-RESULTS/2026-11-23+GH-1587/`, and passing the pre-push Tier-3 `./validate.sh` gate.

## Rollback

Revert the PR commit(s) on `development` (`git revert <commit-sha>`, or `git revert -m 1 <merge-sha>` if landed via merge commit). Because every change is confined to skill documentation, relay turn prompts, the packaged tarball, and in-place pin assertions, rollback is instant and lossless with no data or state migration.
