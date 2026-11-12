# RELAY · GH-1427 final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-11.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1427-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the completed implementation, i.e. the diff `git diff 0f21b761a..HEAD` on this branch (base = `origin/development` at `0f21b761a`).
  Code: `utils/py/claude-turn.py`, `utils/py/claude_cli.py`, `relay-automation/relay-turn-lib.sh`, `utils/py/marathon_drive.py`.
  Docs/package: `README.md`, `HOW-TO-USE.md`, `relay-automation/README.md`, `relay-automation/MARATHON.example.yaml`, `.gitignore`, `CHANGELOG.md`,
  `skills/1-hourly/relay-automation/relay-pkg.tar.gz`. Governance: `PROJECT/2-WORKING/GH-1427-CLAUDE-TURN-BUILDER-CEILING.md` (plan + acceptance map),
  `releases.db/.sql` (roadmap row rated 80/80/50/60, accepted-start). Evidence: `TESTS-RESULTS/2026-11-11+GH-1427/` (SUMMARY.md, provenance.jsonl, logs; the
  two `manual_*.sh` are manual-check scripts kept as receipts, following GH-1421's precedent, not registered suites). Approved plan QA: `relay-system/2026-11-11/gh1427-plan-qa.md`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-11
- Operational envelope: a local developer CLI harness. Grade against the issue acceptance and the approved plan with commensurate complexity.
  No new suites (GH-831): a new `test/` file or `validate.sh` entry in the diff is a finding; do not request one.
  You may run read-only probes under `.relay-scratch/`; do not run `test/*.sh` or `validate.sh` in the relay worktree.
- Definition of Done: each acceptance item of #1427 is satisfied and witnessed; the code matches the approved plan
  (or each deviation is justified: one deviation is known, the `modelUsage` fallback in `record_cost`, added after the live smoke showed that a real error result zeroes `usage`);
  no duplicate subsystem or writer; the evidence substantiates the claims.

Questions:
1. Per acceptance item (builder ceiling and override / reason printed + ESCALATION builder-diagnostic / log survives / cost on a failed turn / suites + evidence), is it satisfied and witnessed? Cite the receipt line.
2. `claude-turn.py`: is the `record_cost()` refactor behaviour-preserving on success, called exactly once per path, with exit codes unchanged (exit-6 precedence kept)? Is the `modelUsage` fallback correct and minimal (summed across models, used only when `usage` is zero)?
3. `relay-turn-lib.sh` `rtl_own_log_is_durable`: is it correct for the in-root default, inert for `XYZ_ARCHIVE_ROOT`/absolute logs, and does it preserve every other cleanup (custom in-repo `*_LOG`, `.relay-scratch`, containment)? Does it affect codex/agy logs acceptably? They benefit identically.
4. Role selection via `rtl.is_reviewer_turn(me)`, and the `os.environ.get(...) or default` semantics (an empty env value now means default): any regression?
5. `warn_opus_budget` and `result_error_summary`: correct, never raising?
6. Are the docs, CHANGELOG and package accurate and consistent with the code (consult keeps 0.50/12; the frozen twin is untouched)? Is the rating still grounded?
7. Anything over-built, missing or unsafe for the stated envelope?

Write your verdict; set STATUS to Approved if it passes, otherwise leave it Open with graded findings.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
