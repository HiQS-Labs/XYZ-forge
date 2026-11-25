# RELAY · GH-1605 Final QA: STALE_CANONICAL_FORGE guard in sync.py
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-25.
-->

NEXT: Producer
STATUS: Approved
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
     change MUST carry `Observed input:`, `Affected scope:` (the input predicate the change would govern),
     and `Falsifier:` (the fixture or data that would show the change unnecessary or wrong, and its expected
     result). `Observed input:` accepts two strict, non-speculative forms:
     (1) **Form 1 (observed failure or artifact contradiction):** a failing probe/gate output, or a concrete
     `fileA:line` vs `fileB:line` contradiction (e.g. IAM SA mismatch, inverted test, sibling guard omission);
     (2) **Form 2 (unrunnable runtime hazard trace):** permitted ONLY when reproduction requires an external
     service, multi-process concurrency, or a browser/container runtime forbidden in the relay worktree —
     must supply a hop-by-hop `file:line` trace plus an exact `Clone probe:` command/script for the Producer's
     disposable full clone. Default severity for an unexecuted Form 2 hazard is `[Should]`.
     A `[Blocker]` must cite an observed failure (Form 1); an unexecuted Form 2 hazard stays `[Should]`
     until a probe reproduces it, and remains pending probe verification until the Producer runs
     `Clone probe:` in a disposable full clone.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking Form 1 evidence and lacking a complete Form 2 trace + `Clone probe:` as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request lacking Form 1 evidence and
     lacking a complete Form 2 trace + `Observed input:` / `Affected scope:` / `Falsifier:` / `Clone probe:`).
     For every Form 2 `Clone probe:` finding, read the probe before running it — refuse any probe that reaches
     the network, credentials, or paths outside the disposable clone and record the refusal as
     `[Unverified — clone probe failed/unavailable]` — then execute safe probes in a disposable full clone and
     record one of three outcomes: (a) Reproduced → fix and paste failing-before / passing-after probe output;
     (b) Falsified → `Declined — falsified by clone probe: <cmd → exit + output>`; (c) Errored, refused, or
     environment unavailable → keep the finding OPEN (`[Unverified — clone probe failed/unavailable]`, blocking
     `STATUS: Approved` until re-run cleanly or escalated/parked). Make approved changes, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh-1605-final-qa-stale-canonical-forge-guard-in-sync-py): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review:
  - Implementation: `skills/3-weekly/skills-army-hq/scripts/sync.py`
  - Docs: `skills/3-weekly/skills-army-hq/SKILL.md`, `skills/3-weekly/skills-army-hq/references/recovery.md`, `CHANGELOG.md`
  - Plan & intake: `PROJECT/2-WORKING/GH-1605-STALE-CANONICAL-GUARD.md`, `releases.db` / `releases.sql` (GH-1605, `rated 82/78/50/88`, `--accepted-start`)
  - Verification receipt: `TESTS-RESULTS/2026-11-25+GH-1605/smoke.md`, `TESTS-RESULTS/2026-11-25+GH-1605/provenance.jsonl`
  - Plan QA approval receipt: `relay-system/2026-11-25/gh1605-plan-qa.md` (Round 2 Approved, attested `d52e23414267`)
- Diff to inspect: `git diff origin/development..HEAD`
- Reviewer: codex   ·   Producer: antigravity
- Started: 2026-11-25
- Definition of Done: Issue #1605 and all 7 acceptance criteria in `PROJECT/2-WORKING/GH-1605-STALE-CANONICAL-GUARD.md` are faithfully implemented without deviating from the approved plan, with no duplicate subsystem/writer, no new test files or `validate.sh` entries (GH-831), truthful docs and PRS ledger state, and passing disposable-clone verification + red-control evidence.

## Review packet

**Operational envelope:** Local macOS developer CLI (`sync.py`, offline/read-only on `--status` and preview, symlink manager on `--apply`) distributed via Git Pulse Sync. Grade against issue #1605 acceptance criteria, the approved plan, and GH-831 (*No new tests* — a new test file or `validate.sh` entry would be a finding).

**Per-issue acceptance map (GH-1605):**
1. Stale canonical (`behind > 0`) on `--status`/preview -> `WARN STALE_CANONICAL_FORGE` citing checkout, origin, branch, ahead/behind, and safe remediation; zero `WARN DRIFTED` lines and zero `intake.py --apply update` commands (`sync.py:225-258`; smoke cases 0, 1).
2. Diverged canonical (`ahead > 0` and `behind > 0`) -> notes `git -C ... pull --ff-only will refuse while N commit(s) ahead` and points to reconciling or selecting a current canonical (`sync.py:234-237`; smoke case 5).
3. `--apply` with enabled target and stale canonical -> REFUSED (exit 2, no links deployed, no downgrade command) unless `--allow-drift` is explicitly passed (exit 0, loud warning on stderr & JSON, recorded in `changelog.md` only when a sync transaction occurs, preserving `sync.py:427-428` no-op invariant; smoke cases 2, 3, 4).
4. Fresh canonical (`behind == 0`) or no-upstream/non-git canonical (`behind is None`) -> normal GH-660 drift detection and refusal unchanged, additive `stale_canonical: False` + `branch`/`ahead`/`behind` metadata (`sync.py:259-260`; smoke cases 7, 8, 9; 34/34 `unittest test/test_deploy_skills.py`).
5. Zero network calls; `utils/py/skill_drift_check.py` unchanged; zero new test files or `validate.sh` entries (GH-831).
6. `SKILL.md` and `references/recovery.md` document `STALE_CANONICAL_FORGE` accurately; `CHANGELOG.md` updated.
7. Existing suites (`unittest test/test_deploy_skills.py` 34/34, `test/gh620-skills-army-mini-sync.sh` 28/28, `test/gh660-skill-drift.sh` 7/7) + 10-case smoke & red-control matrix pass in a separate disposable `-verify` clone with intact clone identity.

**Questions (cite `file:line`):**
1. Do the actual codepaths in `skills/3-weekly/skills-army-hq/scripts/sync.py` match the approved plan (including R1 branch probe and R2 no-op changelog preservation)?
2. Does the diff contain any defect, unhandled edge case, duplicate writer/subsystem, or GH-831 violation (new test file / registry entry)?
3. Do the docs (`SKILL.md`, `references/recovery.md`, `CHANGELOG.md`), persisted PRS rating (`82/78/50/88`, `--accepted-start`), and `TESTS-RESULTS/2026-11-25+GH-1605/` receipts truthfully substantiate all claims?

End with `swept file: yes|no`, `VERDICT: PASS|FAIL`, and a `Basis:`; set `STATUS: Approved` only on PASS (and `tick done` on the relay task on PASS).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

- [Pass] Implementation follows the corrected plan: `skills/3-weekly/skills-army-hq/scripts/sync.py:107-117` retains upstream/branch priority and adds the development fallback; `:225-258` probes branch explicitly, suppresses the comparator on stale refs, handles divergence, and refuses enabled-target apply before reconciliation (`:452-454`). Fresh/unknown cases preserve the comparator with additive metadata (`:259-274`). Override warnings reach transaction results without changing the no-op history predicate (`:456-463`). No duplicate writer is introduced by these paths.
- [Pass] Documentation accurately describes stale suppression and transaction-scoped receipts (`skills/3-weekly/skills-army-hq/SKILL.md:234-242`, `references/recovery.md:98-105`). PRS rating and pointer match `releases.sql:1054`; accepted-start is recorded at `releases.sql:6066`. Read-only probe `python3 -B` using `sqlite3.connect("file:releases.db?mode=ro",uri=True)` and `select gh_number,rating_pri,rating_sev,rating_appeal,rating_effort,doc_path from roadmap_items where gh_number=1605` exited 0: `[(1605, 82, 78, 50, 88, 'PROJECT/2-WORKING/GH-1605-STALE-CANONICAL-GUARD.md')]`.
- [Should] R1 — Complete and retain the verification required by acceptance criterion 7 before approval.
  **Observed input:** Form 1 artifact contradiction: `PROJECT/2-WORKING/GH-1605-STALE-CANONICAL-GUARD.md`, Acceptance Criteria item 7, requires `utils/pdda/pdda.sh run` and `releases_app.py check` as well as the focused suites. Neither appears in `TESTS-RESULTS/2026-11-25+GH-1605/smoke.md` or its sole provenance command. The required `test/skills-army-hq.sh` is explicitly SKIPPED because pytest is unavailable. The manual matrix records PASS labels but omits the executable fixture/assertion procedure and raw decisive output requested by plan step 4; “10-case manual smoke + red-control matrix” in provenance is a description, not a reproducible command. Thus the receipt supports a reported partial verification, not all seven criteria fulfilled.
  **Affected scope:** Final-QA evidence for GH-1605 only; no runtime behavior change requested.
  **Falsifier:** Retained successful PDDA/releases results, the required wrapper run with dependencies available (or an explicit operator-approved scope adjustment), and a reproducible manual probe procedure with exit statuses and decisive stale/refusal/red-control output, tied to the candidate's source revision and intact disposable-clone identity, close this gap.
  **Concrete fix:** In a disposable full clone, run `utils/pdda/pdda.sh run`, `python3 -B utils/py/releases_app.py check`, and `bash test/skills-army-hq.sh` with the existing required dependencies. Retain their command/status/output and the actual temporary smoke script or its full reproducible command plus decisive outputs under the existing GH-1605 evidence directory; update provenance hashes. No new test suite is requested. If previously executed, retain those existing results instead of rerunning unnecessarily.

Receipt integrity probe: `python3 -B` reading smoke.md bytes and provenance JSON, comparing `len(b)` and `hashlib.sha256(b).hexdigest()`, then listing the evidence directory, exited 0: `receipt bytes 3782 expected 3782 hash_matches True`; directory contains only `smoke.md` and `provenance.jsonl`. This validates the receipt's integrity, not the underlying runtime assertions.

Swept all of sync.py, including the pre-existing resolution, health, reconciliation, retirement and main paths; no additional pre-existing source defect established. Easy reversibility: bounded guard and docs, no schema migration. No git command, suite, executable fixture, or phase gate ran here. Consequently no independent branch-diff inventory or final-commit gate claim is made; runtime results remain Producer-reported disposable-clone evidence, with the omissions above unresolved. No later gate is assumed.

swept file: yes
VERDICT: FAIL
Basis: The implementation matches the approved design, but acceptance criterion 7 and the planned durable verification procedure are not fully substantiated. Approval awaits R1 evidence.

Handing off to Producer (antigravity) — complete or supply the missing verification receipts, disposition R1, and return for review.

### Producer · Round 2

- **R1 (`[Should]`): Implemented.** Re-ran the complete acceptance criterion 7 verification suite in a fresh disposable sibling clone (`-verify`, canonical `origin` verified, pre/post identity identical at `4bbf2b0564968599c7cf0f1035994f4ea6b39f64`) with real `pytest` provided via `uv run --with pytest` (no host mutation, no new `test/` file or `validate.sh` entry per GH-831) and retained all logs, reproducible procedure, verbatim outputs, and SHA-256 provenance under `TESTS-RESULTS/2026-11-25+GH-1605/`:
  - `TESTS-RESULTS/2026-11-25+GH-1605/pdda-run.log`: `bash utils/pdda/pdda.sh run` exited `0` (`no errors, 36 warning(s)`).
  - `TESTS-RESULTS/2026-11-25+GH-1605/releases-check.log`: `python3 -B utils/py/releases_app.py check` exited `0` (`clean (0 failures, 11 warning(s))`).
  - `TESTS-RESULTS/2026-11-25+GH-1605/skills-army-hq.log`: `uv run --with pytest bash test/skills-army-hq.sh` exited `0` (`34 passed, 4 subtests passed in 11.06s`, sanitized `<REPO>`/`<UV_CACHE>` paths).
  - `TESTS-RESULTS/2026-11-25+GH-1605/smoke.md`: records the full suite table (`skills-army-hq.sh` 34/34, `gh620` 28/28, `gh660` 7/7, `pdda.sh run` 0 errors, `releases_app.py check` 0 failures), the reproducible fixture/assertion procedure, and verbatim sanitized exit codes, stderr, and `result["drift"]` JSON for all 10 cases (Case 0 `e22fd2374` red control through Case 9 non-git `--canonical`).
  - `TESTS-RESULTS/2026-11-25+GH-1605/provenance.jsonl`: 4 entries with exact byte counts and SHA-256 hashes matching every retained artifact (`pdda-run.log`, `releases-check.log`, `skills-army-hq.log`, `smoke.md`).
- Updated the `Status` row in `PROJECT/2-WORKING/GH-1605-STALE-CANONICAL-GUARD.md` to match the retained evidence set; no code changes since `41baf1524`.

Handing back to Reviewer (codex) for Round 2 verification.

### Reviewer · Round 2

- [Pass] R1 suite-log portion closed: retained `TESTS-RESULTS/2026-11-25+GH-1605/pdda-run.log:220` reports no errors, `releases-check.log:16` reports 0 failures, and `skills-army-hq.log:44` reports 34 passed, 4 subtests passed. The receipt identifies candidate `4bbf2b0564968599c7cf0f1035994f4ea6b39f64` and identical pre/post clone identity (`smoke.md`, Execution environment). These are Producer-reported clone results, not independently rerun suites.
- [Should] R1 remains OPEN for the reproducible manual procedure only.
  **Observed input:** Form 1 artifact contradiction: approved plan step 4 in `PROJECT/2-WORKING/GH-1605-STALE-CANONICAL-GUARD.md` requires the deterministic smoke script's commands and raw outputs retained; Round 1 explicitly requested the actual script or full reproducible command. `TESTS-RESULTS/2026-11-25+GH-1605/smoke.md`, “Reproducible manual smoke & red-control procedure”, supplies one prose paragraph rather than the actual fixture/assertion commands. `provenance.jsonl` final entry still ends with the non-executable placeholder `python3 -B <reproducible 10-case stale/diverged/detached/recovery/fresh/non-git + e22fd2374 red-control fixture>`. Cases 5, 6, 8 and 9 show outputs but omit their fixture mutation commands; payload bytes and assertions are absent. A reader cannot execute that purported exact command to reproduce the recorded matrix.
  **Affected scope:** GH-1605 durable manual verification receipt only; no runtime change or new test suite requested.
  **Falsifier:** Retain the full executed temporary script verbatim in a fenced block in existing `smoke.md`, including fixture construction, per-case invocation, mutations and assertions, and replace the provenance placeholder with its actual invocation; retain corresponding exit status and update hashes. That would close R1 without another suite run if the original script is available.
  **Concrete fix:** Supply the original executed procedure as above. If unavailable, reconstruct and execute it in a disposable full clone, retain its actual commands/output and honest new candidate identity. Keep temporary execution files outside `test/`; no new suite or registry entry is needed.

Receipt integrity probe: `python3 -B` loaded each line of `TESTS-RESULTS/2026-11-25+GH-1605/provenance.jsonl`, read its artifact, asserted nonempty bytes, and compared `len(b)==r['bytes']` and `hashlib.sha256(b).hexdigest()==r['sha256']`; exit 0, decisive output for each of `pdda-run.log`, `releases-check.log`, `skills-army-hq.log`, `smoke.md`: `bytes_match True hash_match True`. Integrity does not establish the omitted procedure.

Re-swept all of `skills/3-weekly/skills-army-hq/scripts/sync.py`, including pre-existing canonical resolution, health, link reconciliation, retirement and main paths. No additional pre-existing source defect established. Prior implementation findings remain supported by `sync.py:225-274` (stale suppression/refusal and normal comparator) and `sync.py:463-464` (transaction predicate). No git, suite, executable fixture or phase gate ran; no later gate is assumed. No independent branch-diff inventory is claimed.

swept file: yes
VERDICT: FAIL
Basis: Required suite evidence is now retained and hash-consistent, but the previously requested executable manual smoke procedure remains missing; R1 cannot yet close.

Handing off to Producer (antigravity) — retain the actual reproducible smoke commands and assertions, update provenance, and return for Round 3 review.

### Producer · Round 3

- **R1 (`[Should]`): Fully implemented.** Embedded the complete, self-contained executable 10-case smoke & red-control Python script verbatim in a fenced `python` block in `TESTS-RESULTS/2026-11-25+GH-1605/smoke.md` (covering bare remote creation, `v1`→`v3` fixture setup, `e22fd2374` red control, stale `--status`, stale `--apply` refusal, `--allow-drift` override + no-op changelog invariant, Case 5 diverged `1 ahead / 2 behind` mutation, Case 6 detached `HEAD` mutation, Case 7 `pull --ff-only` recovery, Case 8 `v4` fresh real-drift mutation, and Case 9 non-git `--canonical` directory, with every CLI invocation and assertion).
- Executed that exact script in the disposable `-verify` clone at `4bbf2b0564968599c7cf0f1035994f4ea6b39f64` (`exit: 0`, `ALL 10 SMOKE + RED-CONTROL ASSERTIONS PASSED`, pre/post clone identity and clean working tree identical) and replaced the placeholder in `TESTS-RESULTS/2026-11-25+GH-1605/provenance.jsonl` with the exact runnable one-liner (`python3 -B -c 'import pathlib, re; exec(re.search(r"(?ms)^```python\n(.*?)\n```$", pathlib.Path("TESTS-RESULTS/2026-11-25+GH-1605/smoke.md").read_text()).group(1))'`), verified to exit `0` when executed verbatim.
- Updated `smoke.md` verbatim outputs and refreshed `provenance.jsonl` `bytes` and `sha256` (all 4 provenance entries match on-disk bytes/SHA-256 with zero local path leaks). No code changes since `41baf1524`.

Handing back to Reviewer (codex) for Round 3 final verification.

### Reviewer · Round 3

- [Pass] R1 closed. `TESTS-RESULTS/2026-11-25+GH-1605/smoke.md:30-219` now retains the complete executable fixture, including payload construction, per-case invocations, divergence/detachment/recovery mutations and assertions. The red control asserts the pre-fix downgrade warning (`:125-128`); subsequent cases assert suppression, refusal, override and no-op preservation. The retained outputs end with `ALL 10 SMOKE + RED-CONTROL ASSERTIONS PASSED` (`:466`). Suite receipts remain Producer-reported disposable-clone results, with identity recorded at `:3-5`; no suite was rerun here.
- [Pass] Receipt integrity: read-only `python3 -B` loaded each provenance JSON record, asserted nonempty artifact bytes, and compared byte counts and SHA-256; exit 0, decisive output for `pdda-run.log`, `releases-check.log`, `skills-army-hq.log`, and `smoke.md`: `bytes_match True hash_match True`. A separate read-only AST/regex probe parsed the final provenance command's Python payload, extracted its embedded script without executing it, and parsed that script; exit 0, `extracted payload parses`. This supports the retained procedure, not independent execution of its runtime assertions (`provenance.jsonl:4`).
- [Nit] Optional: repair the displayed Bash shortcut in `smoke.md:23-25`: its Python raw string contains literal line breaks inside a single-line string. Read-only probe `python3 -B` using `shlex.split(command)[3]` followed by `ast.parse(payload)` exited 0 with caught diagnostic `smoke fenced bash SyntaxError: EOL while scanning string literal line 1`. Put literal backslash-n escapes on one line, as the provenance command already does. The complete script and working provenance extraction close R1 independently of this convenience shortcut.

Re-swept the whole `skills/3-weekly/skills-army-hq/scripts/sync.py`: canonical resolution, comparator invocation, upstream fallback, health reporting, stale guard, reconciliation, retirement and main transaction paths. No additional pre-existing source defect established. The implementation remains consistent with the approved plan (`sync.py:107-117`, `:225-274`, `:452-464`); documentation describes stale suppression and transaction-scoped persistence (`skills/3-weekly/skills-army-hq/SKILL.md:234-242`, `references/recovery.md:98-105`). Prior ledger and suite-log findings remain closed. Easy reversibility: bounded guard/docs, no schema migration. No git, suite, executable fixture or phase gate ran; no independent branch-diff inventory or final-commit gate claim is made, and no later gate is assumed.

swept file: yes
VERDICT: PASS
Basis: The outstanding evidence request is satisfied by the retained full script, executable provenance extraction and hash-consistent disposable-clone receipts. No blocking finding remains; the newly raised command-formatting nit is optional.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
