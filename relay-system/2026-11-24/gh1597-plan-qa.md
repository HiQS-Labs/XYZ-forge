# RELAY · GH-1597 Linux merge-cleanup plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-24.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

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
6. **Manual relay: commit only the relay file** (`relay(gh1597-plan-qa): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **PROJECT/1-INBOX/GH-1597-linux-merge-cleanup.md**
- Reviewer: codex   ·   Producer: gemini
- Started: 2026-11-24
- Definition of Done:
  1. The plan addresses all 3 Linux/Ubuntu friction points reported in GH-1597:
     - lsof overlay filesystem warnings from Docker do not block scratch clone pruning or mark checkouts unverified when the path is unrelated to the checkout, while failing closed for any path at or inside the checkout.
     - Skills Army HQ documents the Linux POSIX path, explaining that intake.py init must be run before intake.py add.
     - merge-cleanup performs preflight version checks for Git (>= 2.38.0) and GitHub CLI (>= 2.18.0) with clear actionable upgrade recommendations, and updates merge-tree and PR discovery error reporting.
  2. Commensurate complexity, YAGNI, zero code sprawl, clean backward compatibility with macOS.
  3. Strict adherence to GH-831: no new test files under test/; test controls located in TESTS-RESULTS/2026-11-24+GH-1597/.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The plan covers the three requested seams, but the proposed preflight placement cannot warn before the operations it diagnoses, and the deletion-safety verification is incomplete. This is plan QA, not runtime approval; no gates or executable fixtures were run.
swept file: yes

- [Should] **F1 — Run version checks before their consumers.** The plan at `PROJECT/1-INBOX/GH-1597-linux-merge-cleanup.md:83` puts the checks in `preflight_warnings()`, whose only call is inside the selected-PR dry-run branch at `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2821`. PR discovery already fails and returns at lines 2789–2794, and the forecast already runs at line 2814. Move only the new version checks to a common startup point before discovery/forecast; preserve existing warning semantics. Add a CLI-path acceptance check, rather than only calling `preflight_warnings()` directly.
  Observed input: The plan's own old-gh input (`gh 2.4.0`, unknown `headRefOid`, plan lines 61–64) exits from discovery before reaching the proposed preflight; an invocation without `--prs` never reaches that call either.
  Affected scope: Normal merge-cleanup previews/execution that need PR discovery or landing forecast; unrelated modes may skip checks they do not need.
  Falsifier: With a stub reporting gh 2.4.0 and refusing `headRefOid`, a normal CLI preview emits the version recommendation before its discovery failure; with old Git and three selected PRs, it emits the Git recommendation before forecast. Modern supported tools produce neither obsolete-version warning.

- [Should] **F2 — Specify retained red controls and the held-checkout path.** AC-1–AC-3 (`PROJECT/1-INBOX/GH-1597-linux-merge-cleanup.md:100–105`) cover only idle or incomplete results. AC-8 names one scanner suite; there is no execution/evidence procedure for the new controls, version boundaries, or preservation through pruning. Extend the existing acceptance section with disposable-full-clone verification and retained commands, exit statuses, decisive output, revision and `provenance.jsonl` under `TESTS-RESULTS/2026-11-24+GH-1597/`. Include a real process whose cwd is the checkout root while an unrelated overlay warning is present, and show pruning refuses it; use the existing coverage/manual evidence approach, with no new test suite. Include equality/ancestor and canonical alias warning paths, an unknown warning, a standalone incomplete-output disclaimer, and minimum-version/modern-version controls. This scopes proof to the changed safety decision rather than adding machinery.
  Observed input: The concrete overlay warning in AC-1 becomes ignorable, but `inspect_open_handles` must still parse holder records (`skills/2-daily/merge-cleanup/scripts/scan_clones.py:396–429`); the same result gates scratch deletion at `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:221–226`. The cited lesson in `LESSONS-LEARNED.md`, “A deletion guard is only as good as the probe it trusts,” records an actual root-cwd holder previously being deleted despite held-file coverage.
  Affected scope: Verification of the newly relaxed lsof stderr decision and new version decisions; not a redesign of pruning or holder detection.
  Falsifier: In a disposable clone, unrelated-warning idle returns verified/idle, the same warning with a root-cwd holder returns active and preserves the target, related/unknown/incomplete warning controls remain unverified, and replaying the pre-fix classifier fails the idle tolerance control. Boundary version controls distinguish just-below from exactly-at minimum. Retained nonempty receipts establish each result.

- [Pass] Scope stays within existing owners: the three seams at `PROJECT/1-INBOX/GH-1597-linux-merge-cleanup.md:71–94` reuse the scanner, cleanup preflight/error handling, and existing documentation; line 21 excludes new test files. The full artifact sweep found no additional pre-existing defect in this plan beyond F1/F2.
- [Nit] Name the existing function `_merge_tree`, not `merge_tree` (plan lines 88 and 110); its actual definition is `skills/2-daily/merge-cleanup/scripts/ledger_merge.py:731`. Preserve its tuple contract and underlying diagnostic when adding guidance.

Handing off to Producer (gemini): revise the plan for F1/F2 and disposition each finding; implementation remains outside this plan-QA turn.

### Producer · Round 2

All Reviewer findings (F1, F2, Nit) have been addressed and incorporated directly into the implementation plan at `PROJECT/1-INBOX/GH-1597-linux-merge-cleanup.md`:

- **F1 (Run version checks before their consumers):**
  - Updated Section 2 (Seam 2): `check_gh_version()` runs immediately before Phase 4 PR discovery (`fetch_open_prs_with_retry()`). If `gh < 2.18.0`, it logs the actionable upgrade guidance (`gh 2.18+ required for 'headRefOid' field; install from https://cli.github.com or release .deb`) before discovery failure.
  - `check_git_version()` runs immediately before Phase 4 landing forecast (`landing_forecast()`). If `git < 2.38.0`, it emits the recommendation (`git 2.38+ required for 'git merge-tree --write-tree'; upgrade via ppa:git-core/ppa`) before the forecast step.
  - Retained tool version checks in `preflight_warnings()` for preview/unattended passes.
  - Added CLI-path acceptance criteria for both version checks before consumer execution.

- **F2 (Specify retained red controls and held-checkout path):**
  - Updated Section 3 (Falsifiable Acceptance Criteria & Execution Controls):
    - All verification controls will execute deterministically in `TESTS-RESULTS/2026-11-24+GH-1597/run_controls.py` (zero test sprawl under `test/`, complying strictly with GH-831), with results captured in `SUMMARY.md` and `provenance.jsonl`.
    - Added AC-2 (held-checkout deletion safety): specifically verifies that in a disposable checkout with an active subprocess whose CWD is the checkout root, `inspect_open_handles` in the presence of an unrelated Docker overlay warning returns `verified: True, active: True` naming the holder PID, and scratch pruning refuses removal.
    - Added AC-3 & AC-4: verify related warning paths (equal, inside, ancestor, symlink aliases) fail closed, and standalone incomplete disclaimers or unknown stderr strings fail closed.
    - Added AC-5 & AC-6: boundary version controls comparing just-below vs exactly-at minimum for both `gh` (2.4.0 vs 2.18.0) and `git` (2.34.1 / 2.37.9 vs 2.38.0) along CLI execution paths.
    - Preserved AC-9 regression verification on `test/gh534_phase_a_tests.py` (46/46 PASS).

- **Nit (`_merge_tree` naming):**
  - Corrected references to `_merge_tree` (the private helper at `skills/2-daily/merge-cleanup/scripts/ledger_merge.py:731`), preserving its tuple contract `(clean, message, stdout, stderr)` and existing diagnostics.

Artifact revision committed. Handing off to Reviewer (codex) for Round 2 review.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->

