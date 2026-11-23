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
  - "Do not build an LLM A/B benchmark harness for skill prose rules (operator-authorized Option 1 / GH-681 precedent: prose is pinned deterministically in existing test suites, stated plainly)"
---

# GH-1587: Close 6 Recurring High-Severity Review Blind Spots Across `review-code-xyz`, `review-pr-xyz`, and `relay-xyz`

Tracking issue: [HiQS-Labs/XYZ-forge#1587](https://github.com/HiQS-Labs/XYZ-forge/issues/1587)
Consult dispositions: [#1587 comment](https://github.com/HiQS-Labs/XYZ-forge/issues/1587#issuecomment-7116016593)
Prior Plan QA transcript (escalated on behavioral-vs-prose scope): `relay-system/2026-11-23/gh1587-plan-qa.md`

## Status

| What was just completed | What's next |
|---|---|
| Plan QA approved & attested (`relay-system/2026-11-23/gh1587-plan-qa-v3.md`), roadmap row `rmi-01M859AVNYRXE06BH6A6QH6F5E` admitted via `--accepted-start`, Phase 1 edits + `relay-pkg.tar.gz` committed (`4e6ac3e6d`, `19476291e`), and Phase 2 disposable-clone verification completed with committed receipts in `TESTS-RESULTS/2026-11-23+GH-1587/` (Layer A red-on-base & green-on-candidate, Layer B.1 live GH-836 `4 pass, 0 fail`, Layer B.2 live `new-relay.sh` Form 2 `Clone probe:` Reviewer+Producer smoke, exact 4-field clone-identity match, and `LESSONS-LEARNED.md`: `NO_ENTRY`). | Run Final Codex Relay QA (`relay-system/2026-11-23/gh1587-final-qa.md`) until `Approved` on the final head SHA, then run `ci-local.sh --fast`, push through the wired first-push Tier-3 `./validate.sh` pre-push hook, open the ready PR against `development`, update the `#1587` closeout comment, and retire both clones via `merge-cleanup --retire-published-pr`. |

## Quad Concepts

- **Six recurring High-severity PR blind spots (test-honesty, TOCTOU, sibling/deploy drift, test-inversion, native-framework reinvention, resume-key instability)** → fold targeted, surface-triggered checks into the single canonical ladder in `skills/2-daily/review-code-xyz/SKILL.md` and the claim-validation table in `skills/2-daily/review-pr-xyz/SKILL.md`.
- **GH-681 vs GH-564 Catch-22 (relay reviewer needs an observed failure to raise `[Blocker]`/`[Should]`, yet cannot run concurrency/external-service/container tests in the relay worktree)** → split `Observed input:` into two strict, non-speculative forms (Form 1 observed failure/artifact contradiction OR Form 2 hop-by-hop unrunnable runtime hazard trace with a runnable `Clone probe:` that remains pending until the Producer executes it in a disposable full clone) while preserving canonical `[Blocker]`/`[Should]` tags and `Declined — unproven generalization`.
- **Relay QA prompt drift & missed surface checks in `start-task`** → keep `relay-turn-lib.sh`, `new-relay.sh`, `utils/py/marathon_drive.py`, `skills/1-hourly/relay/SKILL.md`, `skills/1-hourly/relay-xyz/SKILL.md`, `skills/1-hourly/start-task/SKILL.md`, `relay-automation/README.md`, `relay-pkg.tar.gz`, and existing pin tests (`gh681`, `gh778`, `gh616`) synchronized.

## Table of contents

- [Preflight Bet Check](#preflight-bet-check)
- [Recon & Evidence](#recon--evidence)
- [Form 1 vs Form 2 Severity & Closure Rules (GH-681 + GH-564)](#form-1-vs-form-2-severity--closure-rules-gh-681--gh-564)
- [Acceptance Map: Admission Pins vs Live Relay Verification](#acceptance-map-admission-pins-vs-live-relay-verification)
- [Phase 1: Surgical Skill, Relay Prompt & Existing Pin Updates](#phase-1-surgical-skill-relay-prompt--existing-pin-updates)
- [Phase 2: Disposable-Clone Verification, Live GH-836 & Producer Clone-Probe Smoke, and Final QA](#phase-2-disposable-clone-verification-live-gh-836--producer-clone-probe-smoke-and-final-qa)
- [Test Non-Scope (GH-831)](#test-non-scope-gh-831)
- [Rollback](#rollback)

---

## Preflight Bet Check

- **Outcome sought:** Ensure `review-code-xyz`, `review-pr-xyz`, `relay-xyz`, and `start-task` encode the six documented High-severity defect classes surfaced in an 8-PR forensic audit (`BinoidCBD/LTVera-Pandas` PRs `#1191`, `#1145`, `#1005`, `#980`, `#909`, `#838`, `#729`, `#500`), and allow relay reviewers to escalate unrunnable runtime hazards (concurrency/external-service/container bugs) with a falsifiable `Clone probe:` rather than dropping them under GH-681 or fabricating speculative generalizations.
- **Smallest viable bet:** Surgical prose updates to the 5 existing skill files, 3 relay prompt/doc files, 1 Python marathon brief (`utils/py/marathon_drive.py`), in-place pin updates to 3 existing test suites (`test/gh681-reviewer-probe-rules.sh`, `test/gh778-review-code-skill.sh`, `test/gh616-start-task-commensurate-envelope.sh`), and regenerated `skills/1-hourly/relay-automation/relay-pkg.tar.gz`.
  - **Explicit non-goals:** No new skills, no new test files or `validate.sh` entries (GH-831), no new finding tag formats (keep `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]` verbatim so `utils/py/review_xyz.py` regexes are untouched), no weakening of GH-564 worktree containment, no editing of frozen Bash twins (`relay-automation/marathon-drive.sh`, GH-308), no duplicating `review-code-xyz` into `review-pr-xyz`, and no multi-class LLM A/B benchmark harness for skill prose (operator-authorized Option 1 following `test/gh681-reviewer-probe-rules.sh:17`).
- **Alternatives rejected:**
  1. *Adding a new standalone review checklist skill or duplicating checks in `review-pr-xyz`*: rejected because `review-pr-xyz/SKILL.md:21-24` explicitly declares `review-code-xyz` as the single source of truth; duplication creates maintenance drift.
  2. *Introducing a new `[Blocker — needs clone probe]` finding tag*: rejected because `utils/py/review_xyz.py:62-63` parses literal `\[Blocker\]` / `\[Should\]` tags; adding a new tag syntax would break existing parsers for zero benefit.
  3. *Relaxing GH-564 to allow full test suites or external runtimes inside the relay worktree*: rejected because worktree containment prevents residue and cross-test corruption; handing off an exact `Clone probe:` to the Producer's disposable full clone preserves containment and falsifiability.
  4. *Building a 6-class LLM baseline-vs-candidate A/B benchmark with clean controls*: rejected by operator (Option 1) because an LLM baseline can non-deterministically catch obvious fixtures even without new skill prose, making prose-effect A/B tests flaky and disproportionate machinery (`/ponytail`); deterministic pin suites + live GH-836 + live Form 2 `Clone probe:` Reviewer+Producer smoke match GH-681's established verification boundary.
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
    - `test/gh681-reviewer-probe-rules.sh`: extend cases 1, 4, 6 + add negative-control mutations for `Clone probe:`, `Declined — falsified by clone probe`, and the keep-open unavailable-probe rule across `rtl_turn_prompt`, `new-relay.sh`, `relay/SKILL.md`, `relay-xyz/SKILL.md`, and `marathon_drive.py`.
    - `test/gh778-review-code-skill.sh`: extend section 4 (quality gates & anti-patterns) and section 8 (negative-control mutations) in-place to pin the 6 new checks in `review-code-xyz/SKILL.md` and the test-invariance claim row in `review-pr-xyz/SKILL.md`.
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
   - **Falsified:** run `Clone probe:` in a disposable full clone, confirm the falsifier holds, and disposition `Declined — falsified by clone probe: <cmd → exit + output>`.
   - **Errored / environment unavailable:** the finding **stays OPEN** (`[Unverified — clone probe failed/unavailable]`). Neither Producer nor Reviewer may close `STATUS: Approved` on an unexecuted/errored `Clone probe:`; the relay must either re-run with a working probe or escalate/park (`STATUS: Escalated` / `VERDICT: PARKED`) for explicit operator risk acceptance.
4. **Incomplete or speculative asks:** Any behaviour-change finding lacking Form 1 evidence and lacking a complete Form 2 trace + `Affected scope:` + `Falsifier:` + `Clone probe:` remains `Declined — unproven generalization`.

---

## Acceptance Map: Admission Pins vs Live Relay Verification

**Honest verification boundary (GH-681 / Operator Option 1):** Following `test/gh681-reviewer-probe-rules.sh:17` (*"this is prose; a suite can only pin its text, not its effect — stated plainly"*), skill-prose additions in `review-code-xyz`, `review-pr-xyz`, and `start-task` are verified strictly via **Layer A deterministic red-on-base / green-on-candidate text pins** (explicitly NOT claiming deterministic LLM behavioral detection proof for prose). Live behavioral execution (**Layer B**) is reserved for the executable relay harness contract (`rtl_turn_prompt`, `new-relay.sh`, Reviewer+Producer Form 2 `Clone probe:` handoff, and GH-836 self-sufficiency):

| Requirement | Layer A: Deterministic Admission Pins (Verified RED on unchanged `14cb8a60d`, GREEN on candidate in `-verify` clone) | Layer B: Live Relay / Harness Execution (in `-verify` clone, recorded under `TESTS-RESULTS/2026-11-23+GH-1587/`) |
|---|---|---|
| 1. Six High-severity review checks in `review-code-xyz` + test-invariance claim row in `review-pr-xyz` (single source of truth) | Updated `test/gh778-review-code-skill.sh` pins all 6 clauses in `review-code-xyz/SKILL.md` + the test-invariance row in `review-pr-xyz/SKILL.md` + negative-control mutations deleting each clause. Verified RED against unchanged `14cb8a60d` copies and GREEN against candidate. *Prose-pin boundary stated plainly; no behavioral LLM claim made.* | N/A (skill prose; verified via Layer A deterministic pins + mutation controls per `test/gh681-reviewer-probe-rules.sh:17` and Operator Option 1). |
| 2. GH-681/GH-564 Form 1 + Form 2 `Clone probe:` + 3 Producer closure outcomes across prompt, scaffold, and mirrors | Updated `test/gh681-reviewer-probe-rules.sh` pins `rtl_turn_prompt`, `new-relay.sh`, `relay/SKILL.md`, `relay-xyz/SKILL.md`, `marathon_drive.py`, plus negative-control mutations removing `Clone probe:` / `Declined — falsified by clone probe` / unavailable-probe keep-open wording; verified RED on `14cb8a60d` and GREEN on candidate. | (a) Live GH-836 `RELAY_SELF_SUFFICIENCY_SKIP=0 bash test/relay-self-sufficiency.sh` (non-skipped PASS). (b) Live `new-relay.sh`-scaffolded smoke relay with **both a live Codex Reviewer turn and an actual Producer turn** on a throwaway TOCTOU fixture: Reviewer emits Form 2 (`Observed input:`, `Affected scope:`, `Falsifier:`, `Clone probe:`); Producer turn executes `Clone probe:` on (1) the working probe path (recording cmd + exit + output and `Implemented` / `Declined — falsified by clone probe`) AND (2) an intentionally errored/unavailable probe path (recording `[Unverified — clone probe failed/unavailable]`, leaving the finding OPEN, and refusing `STATUS: Approved`), plus `Declined — unproven generalization` on an incomplete trace. |
| 3. `start-task` Step 6 surface-triggered QA questions & Step 8 Producer `Clone probe:` execution | Updated `test/gh616-start-task-commensurate-envelope.sh` pins Step 6 surface-triggered QA questions and Step 8 disposable-clone `Clone probe:` execution + negative-control mutations; verified RED on `14cb8a60d` and GREEN on candidate. *Prose-pin boundary stated plainly.* | N/A (skill prose; verified via Layer A deterministic pins + mutation controls per Operator Option 1). |
| 4. Tarball freshness & repo constraints (GH-831, GH-308, PDDA, Tier-3) | `test/relay-pkg-freshness.sh`, `test/gh308-frozen-twin-guard.sh`, `utils/pdda/pdda.sh run`, `git diff --name-only` (zero new test files, zero edits to frozen Bash twins). | Full Tier-3 `./validate.sh` executed once via pre-push hook inside the standalone disposable task clone on the final approved SHA (GH-1518), with 4-field clone identity verified before and after. |

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

**Clone safety boundary & 4-field identity check (`AGENTS.md` + `WORKTREE-SAFETY.md:504-505` + GH-564 + GH-1493 + GH-1518):**
- All focused `test/*.sh` suites, red-on-base pin verification, live GH-836 `relay-self-sufficiency.sh`, and live Form 2 `Clone probe:` smoke runs execute **exclusively** inside a separate disposable full clone `../XYZ-forge-gh1587-qa-review-blind-spots-2026-11-23-verify` cloned from the task clone at the exact candidate SHA and configured with canonical `origin` URL `https://github.com/HiQS-Labs/XYZ-forge.git`.
- Before AND after every mutation-heavy verification run in `-verify`, AND before/after the final push gate in the standalone task clone, capture and compare all four `WORKTREE-SAFETY.md:504-505` identity values:
  1. `git config --get core.bare` (must remain `false`)
  2. `git remote get-url origin` (must remain `https://github.com/HiQS-Labs/XYZ-forge.git`)
  3. `git config --get user.name` and `git config --get user.email` (unchanged)
  4. `git rev-parse HEAD` (unchanged)
  Any drift invalidates that run's evidence and stops execution until repaired.
- The task clone `../XYZ-forge-gh1587-qa-review-blind-spots-2026-11-23` itself is ALSO a fresh standalone disposable full clone (never the primary clone, never a linked worktree). Per `start-task/SKILL.md:291-293` (GH-1518), before pushing we check `git ls-remote --heads origin fix/XYZ-forge-gh1587-qa-review-blind-spots-2026-11-23` and `git diff --no-renames --name-only "$(git merge-base origin/development HEAD)" HEAD | bash utils/ci-route.sh push` to verify this is a **first push** with a wired hook (`bash githooks/install.sh --check`) routing the full branch diff to Tier-3 `./validate.sh`. When first-push full-gate routing is confirmed, `ci-local.sh --fast` + `git push` executes the single full `./validate.sh` run; if the branch was already pushed earlier or the push range would not route to full Tier-3, run full `./validate.sh` once on the final approved SHA inside `-verify` and record its qualifying receipt before pushing.

Ordered Phase 2 steps (**all tracked edits are committed BEFORE Final Codex Relay QA**):
1. Create disposable full clone `../XYZ-forge-gh1587-qa-review-blind-spots-2026-11-23-verify` at the Phase 1 candidate SHA with canonical origin `https://github.com/HiQS-Labs/XYZ-forge.git`. Record 4-field pre-run clone identity.
2. **Layer A — Executable Red-on-base vs Green-on-candidate pin verification (in `-verify` clone):**
   - Because `test/gh681-reviewer-probe-rules.sh:23-26`, `test/gh778-review-code-skill.sh:6-8`, and `test/gh616-start-task-commensurate-envelope.sh:4-5,16` resolve their targets relative to their own repo root, create a temporary complete base checkout at `14cb8a60d` in `$TMPDIR/base-red-check` (`git clone --no-hardlinks` from `-verify` + `git checkout --detach 14cb8a60d`), overlay ONLY the three updated test scripts onto `$TMPDIR/base-red-check/test/`, run each suite inside `$TMPDIR/base-red-check`, and assert that each suite exits non-zero **specifically on the newly added GH-1587 pin assertions** (capturing the failing assertion lines, never accepting an unrelated error), then delete `$TMPDIR/base-red-check`.
   - Run all 16 focused pinned test suites (`gh681`, `relay-pkg-freshness`, `gh778`, `gh617`, `gh616`, `gh615`, `gh609`, `gh397`, `gh505`, `gh268`, `gh91`, `new-relay`, `debug-mantra`, `gh308`, `gh589`, `gh798`) against the candidate SHA to confirm **GREEN** (`exit 0`).
3. **Layer B.1 — Live GH-836 self-sufficiency check (in `-verify` clone):**
   - Run `RELAY_SELF_SUFFICIENCY_SKIP=0 CODEX_FLAGS="-s workspace-write -c approval_policy=never -m gpt-6.1-terra" CODEX_MODEL="gpt-6.1-terra" bash test/relay-self-sufficiency.sh` and confirm non-skipped `PASS`.
4. **Layer B.2 — Live `new-relay.sh`-scaffolded Form 2 `Clone probe:` Reviewer + Producer smoke (in `-verify` clone):**
   - Scaffold a fresh relay via `relay-automation/new-relay.sh` against a throwaway TOCTOU concurrency fixture in `$TMPDIR`.
   - Drive a live Codex Reviewer turn verifying it emits Form 2 (`Observed input:`, `Affected scope:`, `Falsifier:`, `Clone probe:`) under the new scaffold.
   - Execute an actual **Producer turn** appended to the scaffolded relay thread that runs `Clone probe:` on (a) the working probe path (recording command + exit + output and `Implemented` / `Declined — falsified by clone probe: <cmd → output>`) AND (b) an intentionally errored/unavailable probe path (recording `[Unverified — clone probe failed/unavailable]`, leaving the finding OPEN and refusing `STATUS: Approved`), plus `Declined — unproven generalization` on an incomplete trace.
   - Verify 4-field post-run clone identity in `-verify` matches pre-run identity exactly.
5. **Pre-Final-QA tracked commits (zero tracked edits after Final QA approval):**
   - Copy all verification logs, 4-field clone-identity receipts, smoke relay transcript, and `provenance.jsonl` into `TESTS-RESULTS/2026-11-23+GH-1587/` in the task clone.
   - Evaluate `LESSONS-LEARNED.md` writer rules (append an evidence-backed entry if warranted, or record explicit `NO_ENTRY` disposition in this plan doc).
   - Update this plan's `## Status` table to reflect Phase 1 & Phase 2 verification complete and awaiting Final QA / PR push.
   - Run `utils/pdda/pdda.sh run` and commit all receipts, `LESSONS-LEARNED.md` (if changed), and plan status update on `fix/XYZ-forge-gh1587-qa-review-blind-spots-2026-11-23`.
6. **Final Codex Relay QA (`relay-xyz`):**
   - Run Final Codex Relay QA on the committed final candidate (implementation, plan, acceptance map, and `TESTS-RESULTS/2026-11-23+GH-1587/` receipts) until `Approved`.
   - If Final QA raises any finding requiring a code/doc edit, apply the edit, re-run affected verification in `-verify`, commit, and re-run Final QA so the approved revision matches the exact final head SHA (never reuse stale approval after an edit).
7. **Push, PR, Closeout & Retirement (zero code/doc/plan edits after approval):**
   - Record 4-field pre-push clone identity in the task clone, verify `bash githooks/install.sh --check`, check `git ls-remote --heads origin fix/XYZ-forge-gh1587-qa-review-blind-spots-2026-11-23` and `git diff --no-renames --name-only "$(git merge-base origin/development HEAD)" HEAD | bash utils/ci-route.sh push` (confirming first-push full Tier-3 routing; if not first push or not full Tier-3, execute full `./validate.sh` once on the final approved SHA inside `-verify` first), run `bash utils/ci-local.sh --fast`, and push `fix/XYZ-forge-gh1587-qa-review-blind-spots-2026-11-23` to `origin`. Verify 4-field post-push clone identity matches pre-push identity.
   - Open ready PR against `development`, call `link_pull_request`, post the idempotent closeout comment on `#1587`, and retire both the task clone and `-verify` clone via `merge-cleanup --retire-published-pr`.

### Phase 2 QA Gate
- All 16 focused pinned test suites pass (`exit 0`) in `-verify` clone, with recorded red-on-base rejection of unchanged `14cb8a60d` files and intact 4-field clone identity before/after.
- Live `test/relay-self-sufficiency.sh` passes (non-skipped) and is recorded in `TESTS-RESULTS/2026-11-23+GH-1587/provenance.jsonl`.
- Live `new-relay.sh`-scaffolded Reviewer + Producer `Clone probe:` smoke receipt (working probe + errored/unavailable probe keep-open + unproven generalization) recorded in `TESTS-RESULTS/2026-11-23+GH-1587/`.
- All tracked edits (`TESTS-RESULTS/`, `LESSONS-LEARNED.md` decision, plan status) committed **before** Final Codex Relay QA reaches `Approved` on the final head SHA.
- Full Tier-3 `./validate.sh` passes on the final approved SHA (via verified first-push wired pre-push hook, or via fallback `-verify` clone full-gate receipt if not a first-push full route), with 4-field clone identity verified before/after, and PR is open against `development`.

---

### Phase 2 Verification Receipts (`TESTS-RESULTS/2026-11-23+GH-1587/`)

- **Layer A — Red-on-Base (`14cb8a60d`) vs Green-on-Candidate (`19476291e`):**
  - All 3 updated pin suites (`test/gh681-reviewer-probe-rules.sh`, `test/gh778-review-code-skill.sh`, `test/gh616-start-task-commensurate-envelope.sh`) exited `1` on base `14cb8a60d` specifically on the new GH-1587 pin assertions (`TESTS-RESULTS/2026-11-23+GH-1587/layer-a-red-on-base.log`) and exited `0` on candidate `19476291e` (`TESTS-RESULTS/2026-11-23+GH-1587/layer-a-focused-16-suites.log`).
  - `14/16` focused suites exited `0` on candidate `19476291e` (including `relay-pkg-freshness.sh`, `gh681`, `gh778`, `gh616`, `gh617`, `gh609`, `gh397`, `gh505`, `gh268`, `gh91`, `new-relay`, `debug-mantra`, `gh308`, `gh589`).
  - The 2 remaining unregistered suites (`test/gh615-start-task-reinforce.sh` and `test/gh798-status-skill.sh`) fail identically on unmodified base `14cb8a60d` (`TESTS-RESULTS/2026-11-23+GH-1587/layer-a-base-preexisting-drift.log`) due to prior upstream commits — GH-1518 (`e0cdff565`) for `gh615` and GH-1266 (`366e492a7`, manual heading count removal in `ARCHITECTURE.md`) for `gh798` — while every `review-code-xyz` assertion in `gh798` (`Lane E DRY`, `helper adherence check`, `parallel subsystem trap`) passes. In `test/gh778-review-code-skill.sh` (one of GH-1587's 3 edited pin suites), line 51 was reconciled to verify the GH-1266 heading plus exact disk-vs-table row count parity (`25 == 25`) so the full suite including sections 7–8 executes and passes.
- **Layer B.1 — Live GH-836 Self-Sufficiency (`TESTS-RESULTS/2026-11-23+GH-1587/layer-b1-relay-self-sufficiency.log`):**
  - `RELAY_SELF_SUFFICIENCY_SKIP=0 bash test/relay-self-sufficiency.sh` ran live (`agy`) and exited `0` (`4 pass, 0 fail`, non-skipped).
- **Layer B.2 — Live `new-relay.sh` Form 2 `Clone probe:` Reviewer + Producer Smoke (`TESTS-RESULTS/2026-11-23+GH-1587/layer-b2-smoke-relay-transcript.md`):**
  - Live Codex (`gpt-6.1-terra`) Reviewer turn emitted `[Should]`, `Observed input: Form 2, pending clone probe`, `Affected scope:`, `Falsifier:`, and a runnable two-thread Python `Clone probe:` without running concurrency inside the relay worktree.
  - Producer turn executed Codex's exact `Clone probe:` in a disposable clone workspace before fix (`exit=1`, `results=[True, True] charges=[1, 1] stock=-1`) and after atomic-reserve fix (`exit=0`, `results=[False, True] charges=[1] stock=0`), verified the `Declined — falsified by clone probe:` and `Declined — unproven generalization` closure paths, and executed an unavailable probe (`exit=127`) keeping the finding OPEN as `[Unverified — clone probe failed/unavailable]` and refusing `STATUS: Approved` (`STATUS: Open`).
- **4-Field Clone Identity (`TESTS-RESULTS/2026-11-23+GH-1587/verify-clone-identity.json`):** Exact match before and after all `-verify` runs (`core.bare=false`, canonical `origin`, `user.name`/`user.email`, `HEAD=19476291ef3e0f4a3f5ecf20b2745e4829c7fd1e`).
- **Provenance Index:** `TESTS-RESULTS/2026-11-23+GH-1587/provenance.jsonl`.

### `LESSONS-LEARNED.md` Disposition: `NO_ENTRY`

Per `LESSONS-LEARNED.md` writer & admission rules (*"Use `confounded` when several things changed at once or a single run is the only support. A lesson resting only on `confounded` rows is refused. Writing `NO_ENTRY` is a valid outcome."*):

| Changed Component | Edit Verdict | Basis |
|---|---|---|
| `skills/2-daily/review-code-xyz/SKILL.md` & `review-pr-xyz/SKILL.md` | `confounded` | Prose rules pinned deterministically (Layer A); no multi-run production review attribution yet. |
| `relay-automation/relay-turn-lib.sh`, `new-relay.sh`, `utils/py/marathon_drive.py`, `relay/SKILL.md`, `relay-xyz/SKILL.md`, `relay-pkg.tar.gz` | `confounded` | Multiple coupled prompt files updated together; verified by single live smoke run (`layer-b2-smoke-relay-transcript.md`) + live GH-836 run. |
| `skills/1-hourly/start-task/SKILL.md` | `confounded` | Prose update pinned deterministically (`gh616`); coupled with relay prompt changes in one run. |

All changed components are `confounded` under the admission rubric; therefore `LESSONS-LEARNED.md` is intentionally unchanged (**`NO_ENTRY`**).

---

## Test Non-Scope (GH-831)

Per `AGENTS.md` (*No new tests*, GH-831), this task creates **zero** new test files under `test/` and adds **zero** new entries to `validate.sh`. Verification relies strictly on editing existing pin suites (`test/gh681-reviewer-probe-rules.sh`, `test/gh778-review-code-skill.sh`, `test/gh616-start-task-commensurate-envelope.sh`) in-place, running the existing pinned suites in `-verify`, executing the live GH-836 check and `new-relay.sh` Reviewer/Producer `Clone probe:` smoke recorded under `TESTS-RESULTS/2026-11-23+GH-1587/`, and passing the pre-push Tier-3 `./validate.sh` gate.

## Rollback

Revert the PR commit(s) on `development` (`git revert <commit-sha>`, or `git revert -m 1 <merge-sha>` if landed via merge commit). Because every change is confined to skill documentation, relay turn prompts, the packaged tarball, and in-place pin assertions, rollback is instant and lossless with no data or state migration.
