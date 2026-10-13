# RELAY · GH-911 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-01.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh911-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the implementation on this branch versus the development branch:
  - `skills/2-daily/workhorse/SKILL.md` (whole file)
  - `skills/2-daily/workhorse/stop-hook.sh` (new)
  - the `CHANGELOG.md` top entry
  - evidence in `TESTS-RESULTS/2026-10-01+GH-911/` (`SUMMARY.md`, `provenance.jsonl`, `matrix.txt`)

  The approved plan is `PROJECT/2-WORKING/GH-911-WORKHORSE-DIRECT-REENTRY.md` (plan QA:
  `relay-system/2026-10-01/gh911-plan-qa.md`, r2 PASS). Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/911
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-01
- **Operational envelope:** a skill text edit plus one ~50-line local Claude Code Stop hook for a single operator.
  Grade against the approved plan and commensurate complexity. Explicit non-goals: no governor role, progress
  fingerprints, budget counters, run schema, or new tests (GH-831). A new `test/` suite or `validate.sh`
  entry in the diff would itself be a finding.
- **Definition of Done (final QA):**
  - every plan step (1–8) is implemented as approved, with no duplicate subsystem or writer;
  - the hook's behavior matches the plan;
  - the evidence substantiates the claims, including the red control;
  - the skill text is internally consistent.

**Questions:**
1. Is each plan step 1–8 implemented as written? Cite `file:line` for anything missing or divergent.
2. `stop-hook.sh`: is input handling correct (the hook's stdin is captured before the python heredoc)? Is
   fail-open total? Does the block JSON match the documented Stop contract? Can a session be trapped?
3. Frontmatter: is the `hooks:` block valid YAML in the settings format, and does the folded `command`
   resolve correctly? Does the YAML comment inside it parse cleanly?
4. Is SKILL.md now internally consistent (recital, ladder diagram, Rung 0, Rung 4, Rung 5, Rung 6 §4–5,
   Proportional Rigor, Operating Rules)? Is the #626 orchestrator `--resume` clause unchanged in substance?
   Is the emergency-rollback restriction intact?
5. Does `TESTS-RESULTS/2026-10-01+GH-911/` substantiate the claims (red control observed, sha matches, 15/15,
   gh609 33/0)? Is its "not covered" disclosure honest?
6. Anything over-engineered, or any accidental files in the diff (`git diff origin/development --stat`)?
   Note that `LEADERBOARD.md`/`releases.*` changes come from the canonical `releases_app.py` writer.

Cite `file:line` for every disagreement. Set STATUS: Approved if it passes.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 (codex)

VERDICT: PASS

Basis: The seeded implementation implements approved steps 1–8 with the intended small hook and text changes. No observed defect requires revision. This is artifact QA, subject to the scheduled final qualifying gate; it does not attest a live Claude session or final-commit gate run.

swept file: yes

Read the whole workhorse skill, whole hook, approved plan, complete SUMMARY/runner, provenance and matrix, and CHANGELOG top entry. No additional pre-existing defect requiring change was established in these surfaces. Verify-tier graph context: no indexed project matches this worktree; nearest XYZ-forge is another checkout, generation 2026-09-01T15:54:30Z. Coverage reports missing/not-tracked evidence paths and excluded CHANGELOG; direct seeded-source reads supply the evidence. No git command, test suite, pytest or executable fixture was run. Only this relay file was edited.

- **[Pass] Steps 1–3: queue and reporting.** skills/2-daily/workhorse/SKILL.md:76-89 supplies session filename, timestamp fallback, local exclude, four states and serial loop. :270-285 makes reporting once per resolved queue and direct re-entry checklist-based. Parent attempt-record, immediate --resume and batch invariant remain explicit at :286-291, matching approved plan PROJECT/2-WORKING/GH-911-WORKHORSE-DIRECT-REENTRY.md:94-98.
- **[Pass] Step 4: hook.** skills/2-daily/workhorse/stop-hook.sh:12 captures stdin before the Python heredoc; :15-22 rejects malformed/non-object input and invalid session ids. :25-42 handles root lookup timeout/tool exceptions, project fallback and missing/unreadable/invalid-encoding files. :43-49 emits block/reason JSON for open lines, names at most five, and otherwise exits silently; :51 gives final exit zero. Recorded input/tool/session/escape cases support ordinary fail-open behavior (TESTS-RESULTS/2026-10-01+GH-911/provenance.jsonl:4-10,15); this is not an executed proof of every possible I/O failure.
- **[Pass] Frontmatter and loop safety.** SKILL.md:17-26 parses as settings-format YAML; comments do not alter the folded command. Both command and hook pass bash -n; shellcheck reports no diagnostics. Project/user/neither-path receipts are provenance.jsonl:12-14. The [Claude hooks reference](https://code.claude.com/docs/en/hooks#stop) documents block/reason output, session-long skill-hook lifetime and a default eight-continuation cap, which the operator can raise. Ignoring stop_hook_active matches the approved design, not an independent hard limit. Checklist escapes and deletion provide exits (stop-hook.sh:7,47-48; plan :162-163).
- **[Pass] Steps 5–7: consult and preservation.** SKILL.md:165-168,302-309 permits the focused Easy local-change skip while retaining required categories. The Git-ref/no-shared-side-effect example at :190-194 leaves preservation proof intact. Recital/goal :40-46 and operating rule :334 follow that queue/consult policy; the ladder summarizes those rungs. Emergency rollback restrictions remain explicit at :327. No counter, governor, schema or additional writer appears in the reviewed hook/skill.
- **[Pass] Step 8 and recorded proof.** CHANGELOG.md:3-28 is dated/newest-first and describes the approved changes. SUMMARY.md:69-75 records the disabled-predicate mutation whose block assertion must fail, then the same-input real-hook assertion. provenance.jsonl:1-2 records empty mutant output versus real block JSON. All 15 manual records are PASS/exit 0; record :16 reports gh609 33 pass/0 fail; matrix.txt:1-15 agrees. Every receipt uses ace8d80c99366e80837379b9eb6e40e257a60614, consistent with SUMMARY.md:3 and plan :23. The missing live-session/final-gate disclosure at SUMMARY.md:104-109 is honest. All evidence filenames in this bullet are under TESTS-RESULTS/2026-10-01+GH-911/.
- **[Unverified — needs clone run] Exact revision/diff and final gate.** Current source equality to the receipt SHA, unchanged substance against the actual development tree, and accidental-file/new-suite absence across the entire branch diff were not independently measured: this turn prohibits git. The harness/Producer must inspect that diff and run the qualifying gate on final committed state, as plan :157-158 already requires. No suite was rerun here; the 15/15 and 33/0 statements above assess the receipts. Live registration/firing remains a first-use observation.

Probe record: export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"; Python reading SKILL.md with yaml.safe_load, running subprocess.run(["bash", "-n", ...]), and counting JSON receipt rows → exit 0; decisive output: “folded command syntax: 0 hook syntax: 0”, “receipt rows: 16 manual: 15 PASS: 16”, one SHA as quoted above, “matrix rows: 15”. Second probe: shellcheck skills/2-daily/workhorse/stop-hook.sh plus Python assertions for stdin ordering, receipt counts/statuses, red/green output and suite count → exit 0, no shellcheck diagnostics; “static assertions: PASS; stdin capture precedes heredoc code; 15 manual PASS + 33/0 suite receipt; red stdout empty, green block JSON; one receipt SHA”. These parse/read/syntax probes do not execute the hook or fixtures.

Relay closed (Approved), no further review turn needed. Returning completion to claude-a (Producer) for final gate and publication checks; the harness owns the file-scoped commit.


### Attestation · relay-drive — 2026-10-01T22:45:23Z
task: RELAY-gh911-final-qa
reviewer: codex
status: Approved
reviewed-head: 75b3311b314752be37c634c86af2d3f827ccc3cd
added-range: 7438+5376
added-sha256: 295efaabb2ce06bd9e451199b9d76bd42d002ece311706037bd2b07b7a015368
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
