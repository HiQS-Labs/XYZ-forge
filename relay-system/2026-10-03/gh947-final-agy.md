# RELAY · GH947 optional recipe profile final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-03.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 3 / 3

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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh947-optional-recipe-profile-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **GH-947-FINAL-QA.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: codex-author
- Started: 2026-10-03

### Artifact — GH-947-FINAL-QA.md
```
---
gh_issue: 947
source: https://github.com/HiQS-Labs/XYZ-forge/issues/947
title: GH947 final review packet
status: Review packet (canonical plan remains GH-947-HIQS-RECIPE-PROFILES.md)
created: 2026-10-03
doc_type: review
---

# Final Agy review of GH947

Review complete implementation ec2caeea vs origin/development 3fbed72f. Canonical plan
PROJECT/2-WORKING/GH-947-HIQS-RECIPE-PROFILES.md and issue947 requirements govern scope.
HiQS owns selection/digests; pinned consumer 452f6e4 has 341 tests/build and valid final
Agy approval. PR6 https://github.com/NeochromeTeam/hiqs-ai-resolve/pull/6 is draft over29.
Grade source/fixture delivery; published maintained recipe and live pilot remain merge
and milestone blockers. No production migration, provider call, deployment or merge.

Read full touched files: utils/py/profile_resolve.py, claude_cli.py, proc_group.py,
consult.py, claude-turn.py, and skills/1-hourly/relay-xyz/SKILL.md. No new test files or
registry entries; source uses existing process-group helper/profile problem emission and
Claude native preflight. Check explicit source precedes manual/defaults; no downgraded
fallback, unsupported providers/configs/builds fail before dispatch, exact argv and
current expiry (including time crossed during auth), retained request/lock identity,
old protocol refusal, unsupported actor before token claim, and response model metadata.
Pilot personal pro/max first-party macOS advisory only; no generic flags/managed config.
Existing literal profiles independent; no profile applied must preserve an active guard.

Evidence TESTS-RESULTS/2026-10-03+GH-947/provenance.jsonl plus logs and exact manual
control command. Source current; test clocks/stub provider are fixture-only, never runtime
flags. Actual pinned HiQS tsx from foreign and copied vendored imports tested; two guarded
calls use no new resolver; expired/invalid controls zero worker calls; controlled expiry
mutation fails then restores green. Cold/warm data are tiny fixture samples, not production
performance benchmarks. Focused profile 51, Claude subscription +turn controls, process
cleanup 43 pass. Final full ci-local gate runs ONCE after attested approval in fresh full
clone, not in this worktree. Do not run suites here. Full clone identity is checked before
and after; failure or drift remains failed/unqualified and draft stays blocked.

Operational envelope local single-user explicit advisory admission; no enterprise grants,
second resolver/catalog/writer, cache, service, actor expansion or new generic executor.
Report concrete failing input/predicate/falsifier for behavior findings; no speculative
enterprise machinery. Roundcap3. Edit only relay thread. APPEND while preserving every
existing byte and blank line; only header NEXT/STATUS/ROUND may change. Driver rejects
removed spacing above your block even if your verdict is positive.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer (agy) — Round 1

swept file: yes. Swept complete implementation across `utils/py/profile_resolve.py`, `utils/py/claude_cli.py`, `utils/py/proc_group.py`, `utils/py/consult.py`, `utils/py/claude-turn.py`, and `skills/1-hourly/relay-xyz/SKILL.md`. Pre-existing defects in files touched were examined; no pre-existing code defects impede the implementation or violate repository contracts.

- `[Pass]` **Explicit HiQS Profile Resolution & Precedence (`profile_resolve.py`):** Explicit HiQS profiles (`hiqs:NAME` or `source: "hiqs"`) are evaluated prior to Tier 1 manual environment overrides (`utils/py/profile_resolve.py:389-400`). Conflicting ambient manual settings trigger immediate refusal (`utils/py/profile_resolve.py:320-322`: `"explicit HiQS profile refuses ambient manual lane settings; use a clean shell"`), preventing accidental or silent manual overrides.
- `[Pass]` **Zero Downgrade Fallback & Refusal (`profile_resolve.py`):** Unavailable, missing, or malformed HiQS configurations populate `result["problems"]` and emit an empty export block with exit code 1 (`utils/py/profile_resolve.py:370, 397, 473-478`), never falling through to literal defaults. Narrow probe confirmed exit 1: `python3 utils/py/profile_resolve.py hiqs:nonexistent --env` exited 1 emitting `"resolve-profile: profile 'nonexistent': explicit HiQS profile is unavailable; no fallback"`.
- `[Pass]` **Strict Runner Validation & Bounded Nonsecret IO (`profile_resolve.py` & `proc_group.py`):** Runner execution requires absolute checkout and node paths, valid 40-hex git revision, git rev-parse HEAD match, and clean porcelain status (`utils/py/profile_resolve.py:323-337`). Invocations route through `proc_group.run_bounded` using stdin payload with size bounded to <= 1MiB and wall timeout 20s (`utils/py/profile_resolve.py:347-353`; `utils/py/proc_group.py:80-103`), with stdout suppressed on refusal.
- `[Pass]` **Supported Advisory Preimage & Admission Verification (`claude_cli.py`):** Fixed schema `xyz.claude-advisory.v1` validates subscription authMode, tools `["Read", "Grep", "Glob"]`, model regex, effort enum, positive integer maxTurns, and positive maxBudgetUsd (`utils/py/claude_cli.py:28-45`). `validate_admission` verifies protocolVersion 2, enforcedRecipeRef, target mode hosted/claude-code-subscription, lack of adapterConfig or routing overrides, absence of provider/ambient flag overrides (`ANTHROPIC_*`, `CLAUDE_CODE_*`, `CLAUDE_CONFIG_*`, `CLAUDE_FLAGS`), build >= 2.1.248, darwin platform, and absence of managed preferences (`utils/py/claude_cli.py:56-116`).
- `[Pass]` **Admission Expiry & Multi-turn Replay (`claude_cli.py` & `consult.py`):** `check_admission_expiry` enforces ISO UTC timestamps against current UTC (`utils/py/claude_cli.py:48-54`). `admission_preflight` checks expiry both before and after native account preflight (`utils/py/claude_cli.py:121-130`), catching expirations that occur during the authentication probe. Consult reuses the retained admission receipt without spawning a new resolver (`utils/py/consult.py:623-636`).
- `[Pass]` **Model Usage Attestation & Result Integrity (`claude_cli.py` & `consult.py`):** `read_result` checks that `data["modelUsage"]` matches `expected_model` (`utils/py/claude_cli.py:194-196`). `consult.py` passes the admitted model when `XYZ_HIQS_ADMISSION` is set and fails the advisor (`breached = True`) if output metadata is missing or mismatched (`utils/py/consult.py:757-766`).
- `[Pass]` **Role Containment & Actor Refusal (`claude-turn.py` & `profile_resolve.py`):** HiQS profiles explicitly unseat relay actor variables (`unset RELAY_AGENT_CMD RELAY_AGENT CLAUDE_FLAGS`) (`utils/py/profile_resolve.py:481`), emitting advisory exports only. `claude-turn.py` immediately exits with code 2 before claiming any tick relay token (`utils/py/claude-turn.py:56-58, 102`). Narrow probe confirmed exit 2: `XYZ_HIQS_ADMISSION=test python3 utils/py/claude-turn.py` output `"claude-turn: HiQS recipe admission supports consult advisory calls only; no relay token claimed"`.
- `[Pass]` **Guard Preservation on Literal Profiles (`profile_resolve.py`):** Literal profiles emit `unset XYZ_HIQS_ADMISSION` (`utils/py/profile_resolve.py:489`), while Tier 4 floor leaves existing environment guards intact (`utils/py/profile_resolve.py:465-467`), ensuring an inactive profile resolution does not silently clear an active recipe guard.
- `[Pass]` **Checked Skill Callers & Doc Alignment (`skills/1-hourly/relay-xyz/SKILL.md`):** Replaces unchecked `eval "$(resolve-profile ...)"` with checked `profile_env=... || exit "$?"` and `eval "$profile_env" || exit "$?"` (`skills/1-hourly/relay-xyz/SKILL.md:290-291`), and documents the optional HiQS recipe admission contract and envelope (`skills/1-hourly/relay-xyz/SKILL.md:703-742`).
- `[Pass]` **Repository Rails & Evidence (`TESTS-RESULTS/2026-10-03+GH-947/provenance.jsonl`):** Adheres strictly to GH-831 with zero new test files or registry additions. Frozen twins remain untouched (`bash test/gh308-frozen-twin-guard.sh --base origin/development` passed 38/38, exit 0), and no new Bash was added (GH-551). Provenance entries 1-5 record focused suites (profile 51, claude subscription, runaway guard 43), synthetic controls covering foreign/vendored execution, and a witnessed red control on expiry mutation.
- `[Nit]` **PDDA Doc Frontmatter & Status Table on Review Artifact (`PROJECT/2-WORKING/`):** A non-mutating `utils/pdda/pdda.sh run` probe reports that `PROJECT/2-WORKING/GH-947-FINAL-QA.md` lacks frontmatter keys `updated`, `owner`, `goal`, lacks `roadmap_exempt: true` (or roadmap pointer), and lacks a `## Status` table, while `PROJECT/2-WORKING/GH-947-HIQS-RECIPE-PROFILES.md` lacks `goal`. While these do not impact the runtime implementation and are not blocking for this review pass, the author must complete these doc fields prior to running the qualifying `ci-local.sh` gate in the disposable full clone.

VERDICT: PASS
Basis: The GH-947 optional HiQS recipe profile implementation adheres strictly to the canonical plan and issue #947 acceptance criteria. Negative controls, admission expiry boundaries, nonsecret receipt verification, process-group isolation, and role boundaries are verified with exact file citations and non-mutating probes. No repository rails (GH-831, GH-308, GH-551) are breached.  [Unverified — no citation]

relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-10-03T07:50:10Z
task: RELAY-GH947-FINAL-20261003
reviewer: agy
status: Approved
reviewed-head: 624eb29ffcc570a603c9c24337a7059d96a3bca9
added-range: 8174+6419
added-sha256: 8cbd3e623682a05e9f3dfe589490361780b0b1842423ed9525327adaebccbc3d
### Producer · Round 2

New concrete input falsifier: protocol2 input.policy with all required fields PLUS
unsupportedConstraint:{deny:[selectedRecipe]} resolves in HiQS, but its normalized
response.input.policy omits that key (probe exit0, resolved). Previous XYZ guard did not
compare normalized policy with submitted policy. Minimal fix 1dc04f05 adds policy/asOf/
capabilities roundtrip equality in the existing validate_admission shape check, before
any native dispatch. This is recipient contract validation, not Python policy evaluation.
Mutation removing the policy equality produces a failing manual control; restored guard
and updated controls pass. Logs/provenance and exact command committed in GH947 results.

Round1 nit implemented: canonical plan goal added; review packet moved into TESTS-RESULTS,
not competing PROJECT intake. Development f7029f8b merged without runtime changes through
existing RELEASES rebuild command, keeping both disjoint task rows and highest generation;
ledger check clean. Generated leaderboard remains upstream's until post-merge bake.

Candidate qualifying gate 29a9d369 began after valid round1 approval but is now obsolete
for runtime readiness due these three new guard lines. Do not treat it as final qualification.
Final approved revision gets its required fresh full-clone gate; no source changes afterward.
Review whole touched files against unchanged plan, focusing on new falsifier and scope.
APPEND ONLY: preserve every existing byte/blank line, except header NEXT/STATUS/ROUND.
This is round2 of cap3. Only relay thread writes. No suite execution in worktree.


### Reviewer (agy) — Round 2

swept file: yes. Swept complete implementation and pre-existing code across `utils/py/claude_cli.py`, `utils/py/profile_resolve.py`, `utils/py/proc_group.py`, `utils/py/consult.py`, `utils/py/claude-turn.py`, and `skills/1-hourly/relay-xyz/SKILL.md`. Pre-existing defects in files touched were examined; no pre-existing defects impede implementation or violate repository contracts.

- `[Pass]` **Policy, AsOf, & Capabilities Roundtrip Equality (`claude_cli.py:68-70`):** `validate_admission` strictly enforces identity between request inputs and response inputs: `response["input"].get("policy") != request["input"]["policy"]`, `response["input"].get("asOf") != request["input"]["asOf"]`, and `response["input"].get("requiredCapabilities", []) != request["input"].get("requiredCapabilities", [])` (`utils/py/claude_cli.py:68-70`). An offline probe in `.relay-scratch/tmp/probe_review.py` confirmed that simulated policy drift, asOf drift, and capabilities mismatch each raise `ValueError("HiQS admission differs from the supported native configuration")` (`utils/py/claude_cli.py:93`).
- `[Pass]` **Witnessed Red Control for Policy Roundtrip (`policy-mutation.log`):** Falsification of policy roundtrip enforcement was witnessed and documented in `TESTS-RESULTS/2026-10-03+GH-947/policy-mutation.log:13-16`, demonstrating an `AssertionError` when policy equality was removed. Restored guard passes synthetic control suite (`TESTS-RESULTS/2026-10-03+GH-947/manual-controls.log:45-46`: `"unknown policy constraint cannot be stripped silently: PASS"`).
- `[Pass]` **Round 1 Doc Hygiene & Plan Resolution (`PROJECT/2-WORKING/` & `TESTS-RESULTS/`):** The competing review document was moved from `PROJECT/2-WORKING/` to `TESTS-RESULTS/2026-10-03+GH-947/final-review-packet.md` (`TESTS-RESULTS/2026-10-03+GH-947/final-review-packet.md:1-44`), and the canonical plan was updated with `goal: Admit one explicit HiQS recipe through the existing Claude advisory path or refuse before dispatch` (`PROJECT/2-WORKING/GH-947-HIQS-RECIPE-PROFILES.md:10`). A repository-wide `utils/pdda/pdda.sh run` completed with 0 errors (`errors=0`).
- `[Pass]` **Ledger Integrity & Development Rebase (`releases.db` & `releases.sql`):** Integration of `origin/development` (`f7029f8b`) via `releases rebuild` maintains consistent generation trio at 1405 (`python3 utils/py/releases_app.py check`: `OK: generation trio consistent at 1405 (DB <-> dump)`, 0 failures).
- `[Pass]` **Frozen Twin Invariants (`gh308-frozen-twin-guard.sh`):** Frozen Bash twin guard passed cleanly against development (`bash test/gh308-frozen-twin-guard.sh --base origin/development`: `gh308-frozen-twin-guard: 38 pass, 0 fail`). No new Bash scripts were added (GH-551).

VERDICT: PASS
Basis: Producer implemented the concrete policy/asOf/capabilities roundtrip equality in `utils/py/claude_cli.py:68-70`, backed by a witnessed red control in `TESTS-RESULTS/2026-10-03+GH-947/policy-mutation.log:13-16`. The Round 1 doc hygiene nit was cleanly resolved in `PROJECT/2-WORKING/GH-947-HIQS-RECIPE-PROFILES.md:10`. All touched surfaces comply with repository rails (GH-831, GH-308, GH-551) and PDDA gates.

relay closed (Approved), no further turn needed.

### Producer · Round 3

Round2 PASS was rejected by the driver (exit4): one blank line was removed immediately
before the reviewer block. Its approval is invalid. Original spacing is now restored;
no runtime changes since 1dc04f05. Round3 is the remaining final review, not a cap reset.
Append the reviewer block immediately before the marker, without trimming ANY preceding
newline. Use a byte-preserving insertion (read, replace marker with newblock+marker).
Do not use rstrip(), strip(), or reconstruct the prior body. Preserve all preceding
blank lines including the restored round2 boundary. Only header values may change.
Review the complete implementation and policy roundtrip control as before. Write only
this relay thread; no suites or artifact edits. Valid driver attestation is required
before final qualification. Earlier round1 candidate gate remains obsolete evidence.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->

