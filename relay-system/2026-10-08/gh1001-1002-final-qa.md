# RELAY · GH-1001/1002 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-09.
-->

NEXT: Reviewer
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1001-1002-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review (implementation, final QA): the diff `git diff origin/development...HEAD` on branch `fix/gh-1001-1002-vendored-marathon`. Code: `utils/py/harness_paths.py`, `utils/py/marathon_drive.py`, `relay-automation/relay-turn-lib.sh`, `utils/py/agy-turn.py`; existing suites edited: `test/gh396-find-harness-roots.sh`, `test/gh113-headless-scratch.sh`; vendored `skills/1-hourly/relay-automation/relay-pkg.tar.gz` refreshed by make-pkg.sh.
- Approved plan (grade against it): `PROJECT/2-WORKING/GH-1001-VENDORED-HARNESS-ROOT.md` (shared plan, steps A1–A3, B1–B4) and `PROJECT/2-WORKING/GH-1002-OFFLANE-SCRATCH-CAP.md`; plan QA thread `relay-system/2026-10-08/gh1001-1002-plan-qa.md` (Approved r3, attested).
- Evidence: `TESTS-RESULTS/2026-10-08+GH-1001/` (A2/A3 probe, candidate PASS 4/4, base FAIL 4/4) and `TESTS-RESULTS/2026-10-08+GH-1002/` (gh113 candidate 27/27, base 21/27 with the six GH-1002 positives red, accept-mixed mutation 25/27 with the mixed-dir control red, restored 27/27; cap_order_check candidate 9/9, base 3 FAIL incl. parked fire 2→3 commits; prompt-text check). Focused suites in a disposable full clone at 8fa81aad: lane-attempt-cap 26/26, debug-mantra 17/17, gh342 29/29, gh280 223/223, marathon-drive 162/162, agy-turn 65/65, gh113 27/27, gh396 42/42. Full `ci-local.sh` on 4b2aa888 in a disposable full clone: exit 0, all steps passed (bash/node syntax, settings JSON, PDDA, npm ci, validate.sh suite, clone-identity invariant); identity unchanged; log `TESTS-RESULTS/2026-10-08+GH-1001/ci-local.log`, provenance in both evidence dirs. Commits after 4b2aa888 are evidence/relay files only.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-08
- Operational envelope: local developer CLI harness, single operator Mac, vendored `.xyz/` consumers. Grade against the issues' asks, the approved plan and commensurate complexity. AGENTS.md "No new tests" (GH-831): a new test file or registry entry is a finding; the two edited suites are existing suites kept truthful; the TESTS-RESULTS scripts are recorded manual checks, not registered suites — flag it if you disagree.
- Definition of Done: each issue's asks are met by the code at the cited paths; code matches the approved plan (note deliberate deviations: N1 reused the reader without renaming it because the frozen Bash twin and test/debug-mantra.sh pin that name; the B2 pre-check is placed right after the dry-run exit, before the GH-514 write-set proof, branch guard and relay render); no duplicate subsystem or writer; red controls substantiate the claims; nothing outside scope.

### Questions for the Reviewer
1. A1: is the reordered `harness_home()` correct and complete for `is_vendored()`/`repo_root()` with and without `XYZ_HARNESS`, `XYZ_VENDORED`, `XYZ_CALLER_ROOT`?
2. A2/A3: does `_preflight_check_issue_closed` now use `_gate_root` for both lookups, and is `repo_display` always bound before use?
3. B1: review `rtl_scratch_shaped`, `rtl_scratch_relocate`, `rtl_scratch_relocate_dir` and the two calls in `rtl_worktree_end`. Can a tracked path, dotfile, allowlisted path, or mixed directory be relocated or copied back? Does `rtl_check` still reject nested scratch? Is the prefix regex exactly `(tmp|temp|scratch|debug|(test|fix|repro|probe)[-_])`?
4. B2/B3: is the check-only gate truly read-only, is the single append unchanged, is the park message/receipt/debug record preserved, and is the early placement (right after the dry-run exit) safe given what runs between it and the old gate call?
5. B4: is the preamble now accurate?
6. Anything over-built, under-scoped, or a regression risk to other callers of these functions?

Cite file:line for every disagreement. Set STATUS to Approved only if the branch can open as a ready PR.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
