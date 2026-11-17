# RELAY · GH1493 final QA (published retirement per-path preservation)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-17.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh1493-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the completed diff `git diff 9331cec67..HEAD` on branch
  `fix/XYZ-forge-gh1493-retire-published-batch-2026-11-17` (PR #1516). Code:
  `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (`retire_published_checkouts`). Docs:
  `skills/1-hourly/start-task/SKILL.md`, `skills/2-daily/merge-cleanup/SKILL.md`, `CHANGELOG.md`.
  Plan: `PROJECT/2-WORKING/GH-1493-RETIRE-PUBLISHED-BATCH.md` (approved in
  `relay-system/2026-11-17/gh1493-plan-qa.md`). Evidence: `TESTS-RESULTS/2026-11-17+GH-1493/`
  (`SUMMARY.md`, manual red/green batch check, `gate/` ci-local receipt, `smoke/` PR #1516 preview runs,
  `provenance.jsonl`). Ledger: `releases.sql` row GH-1493 (`rated 50/45/50/85`, accepted start).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-17
- Operational envelope: local developer CLI called by start-task closeout on one machine. Grade
  against the stated requirements and commensurate complexity; no enterprise fail-safes.
  XYZ-forge forbids new tests (AGENTS.md *No new tests*, GH-831): a new test file or registry entry
  in the diff is a finding; the manual check is recorded as markdown input plus outputs.
- Definition of Done:
  1. One ineligible `--checkout` path prints `PRESERVED <path>: <reason>`; other paths still reach
     the unchanged inspect/refresh/teardown path; exit 1 if anything was preserved; primary-origin
     failure stays exit 2.
  2. Origin check unchanged in strength; its message names the canonical-origin helper recipe;
     start-task SKILL.md has the one helper sentence.
  3. Controls: different repository and unpublished local commit still preserved.
  4. Evidence substantiates each claim: red control on base `9331cec67`, green on candidate, smoke on
     the main path and a rerun, full gate on the code commit.

Questions:
1. Does the code at `merge_cleanup.py` `retire_published_checkouts` match the plan and DoD 1–2? Any
   path where an exception escapes the per-path `try`, or a refused path still reaches inspection?
2. Is anything weakened: symlink/absolute/protected/safe-root/overlap/origin checks, exit codes,
   classification or teardown? Compare against `git show 9331cec67:skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`.
3. What prevents an unchanged, unfixed candidate from being reported as delivered — cite the observed
   rejection in the evidence (base run output) and say whether the evidence shows it.
4. Does the smoke receipt show the unpublished-commit control reaching classification
   (`PRESERVE_UNPUSHED`) rather than an earlier refusal? Is the `-gate` ACTIVE_PROCESS → SAFE change
   between runs explained adequately?
5. Is the persisted rating consistent with the evidence? Did any duplicate subsystem, writer, or new
   test file slip in? Are the doc sentences accurate (e.g. the merge-cleanup clause lists only the
   pre-inspection refusals)?
6. Note: the origin-mismatch message also shows the helper recipe for an unrelated-repository
   checkout. Is that misleading enough to change, or acceptable?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: PASS
Basis: Ship the bounded per-path admission fix. The retained red/green, real-PR preview/rerun and code-bound macOS gate support the stated DoD. No blocking findings; one optional pre-existing documentation nit below.

swept file: yes

Reviewed the complete runtime file, including the pre-existing landing, refresh, teardown and dispatch paths, and the skill instructions around their consumers; compared the complete committed change inventory against base `9331cec67`. No pre-existing runtime defect was identified in this sweep. This is a source/evidence review, not an exhaustive audit of all imported modules or historical changelog claims.

- [Pass] **Admission and exit codes.** `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2390-2438`: primary-origin failure remains exit 2; each supplied path is validated inside its own `try`; `OSError`, `RuntimeError` and `ValueError` print `PRESERVED`, set the failure flag and `continue` before candidate admission. Only accepted paths reach inspection. Any preserved path makes the final result 1. Absolute/symlink, strict resolution, protected-directory, Git-checkout, safe-root, overlap and normalized-origin predicates retain their strength. Overlap remains against accepted candidates, as explicitly scoped by the plan. The downstream inspect/refresh/teardown loop is unchanged from base; classification and removal were not rewritten. No new subsystem, writer, test file or registry entry appears in the 17-path committed inventory.
- [Pass] **The check detects the unfixed implementation.** `TESTS-RESULTS/2026-11-17+GH-1493/manual-batch-base-9331cec67.txt` contains `Published retirement refused`, `EXIT 2`, `CALLS 0`. The candidate receipt contains three `PRESERVED` lines, `EXIT 1`, and only the eligible fourth path's `CALL inspect`, `CALL refresh`, `CALL teardown ... True`, `CALLS 3`. `manual-batch-input.md` supplies the actual ordered inputs and recorder implementation. Thus an unchanged driver or one stopping at the first refusal cannot satisfy the recorded expectation. These calls prove delegation, not physical retirement.
- [Pass] **Controls and smoke.** `TESTS-RESULTS/2026-11-17+GH-1493/manual-batch-candidate-0d1ccf8.txt` preserves `other-repo-clone` for origin mismatch. Both `smoke/run1-preview-pr1516.txt` and `smoke/run2-preview-pr1516.txt` show the clean `-verify` checkout as `PRESERVE_UNPUSHED`, naming local ref tip `3c660c3317`; it reaches classification rather than an earlier refusal. Both show the task clone's `SAFE_REMOVE_CLONE` preview. Run 1 names held PIDs `84633 (sleep), 85147 (sleep)` for `-gate`; run 2 permits its preview. `SUMMARY.md:43` explains their origin and subsequent exit adequately. This is recorded preview evidence, not a deletion claim or a fresh liveness measurement.
- [Pass] **Gate and evidence binding.** `gate/ci-local-0d1ccf8fa.txt:1-10` identifies full Darwin qualification on `0d1ccf8fa36ca51d6facb00926491b3390f3703a`, green, 407 recorded; its rows show 406 pass and one skip. `SUMMARY.md:21-28` explains the acorn skip and disposable-clone identity checks. Read-only local probes established identical runtime bytes at that gate commit, smoke commit `4355071e83c7e24a1c9e8639c3965e8010f96d27`, and reviewed checkout `824dc6e48f33a28c66be6512f4efc011177bc22e`. Commands: `PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp" python3 "$TMPDIR/read_objects.py"` (exit 0: `CHANGED 17`, only the named runtime file changed); `python3 -` (read-only AST/hash probe, exit 0: `only changed definition: ['retire_published_checkouts']`, `inspection/refresh/teardown loop AST identical to base`, all four nonempty output files' provenance SHA256 values matched, and recorded probe-source SHA256 matched both runs). Object reads verified Git object hashes without invoking Git. No suite, executable fixture, feature execution or teardown ran here.
- [Pass] **Docs, rating and helper advice.** `skills/1-hourly/start-task/SKILL.md:117-120` gives the canonical-origin helper sentence; `skills/2-daily/merge-cleanup/SKILL.md:655-660` scopes the new output to pre-inspection refusal; `CHANGELOG.md:5-12` describes the same behavior. `releases.sql:1016` stores `50/45/50/85` without override, consistent with the plan's recoverable cleanup inconvenience, neutral appeal and small implementation. `releases.sql:5685` records accepted start. The unrelated-repository origin diagnostic still explicitly names both origins and describes making a task helper (`merge_cleanup.py:2417-2422`); its generic helper advice is acceptable in this envelope and grants no eligibility bypass. No change requested.
- [Nit] **Pre-existing stale sweep sentence.** `skills/2-daily/merge-cleanup/SKILL.md:494-495` says the script “does not run any test suite” and the caller runs the sweep, while the same document's GH-1383 automated-sweep bullet and `merge_cleanup.py:3039` describe automatic execution. Optional follow-up: qualify that older sentence to distinguish script-owned automatic sweeps from caller-owned analysis/manual verdicts. This wording predates GH-1493 and does not block this retirement fix.

Limits: the graph project is the maintained primary, generation `2026-11-17T06:11:19Z`, not this candidate; coverage reported no recorded gaps for the named files, so exact local source/object reads supplied candidate evidence. Graph tracing was unavailable under the tool approval policy. `gh api repos/HiQS-Labs/XYZ-forge/compare/9331cec67...fix/XYZ-forge-gh1493-retire-published-batch-2026-11-17` could not connect (`error connecting to api.github.com`); no fresh remote-head, hosted-check, or recurrence-history claim is made. Existing retained gate evidence was inspected, not rerun; the harness performs its gate after this turn.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
