# RELAY · GH-898 plan QA — board_sync repo allow-list from rebalanceOS active-repos
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-30.
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
6. **Commit only the relay file** (`relay(gh898-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/1-INBOX/GH-898-BOARD-SYNC-ACTIVE-REPOS.md (plan). Source to read: utils/py/board_sync.py (resolve_selection_policy :119, plan_selection_policy :221, build_policy_preview :1113, policy-apply :1165, cmd_config), utils/py/work_connectors/github_board.py, utils/hq/hq-lib.sh. Out-of-repo evidence the plan cites (read-only): /Users/noelsaw/Documents/GH Repos/rebalanceOS/src/rebalance/ingest/db/github.py (top_active_repos), src/rebalance/paths.py (resolve_database_path).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-30
- Definition of Done: Issue #898 satisfied by the plan's 6 requirements; plan extends resolve_selection_policy (no new writer/module); no new test files (AGENTS.md GH-831); falsifiable manual checks.

**Operational envelope:** local single-operator developer CLI, ~60-line change in one file. Grade against the stated requirements and commensurate complexity; do not ask for multi-tenant threat models, locks, journals, or new test suites. Reject speculative abstraction.

**Questions (cite file:line):**
1. Are the plan's claims about board_sync.py true? Specifically: does widening policy["repos"] change only what the plan says (observation filter, planner `allowed`, collect_github_state loop)? Is anything that reads cfg["repos"][0] or policy["repos"] missed (incl. work_connectors/github_board.py)?
2. Is the pinned-first ordering sufficient to keep touch/default paths (:736, :802, :902) correct?
3. policy-apply refuses if policy != preview["policy"] (:1167). With a live-computed repo list, is the refusal behavior (re-preview) acceptable, or does it make apply flaky in a way the plan under-states?
4. Read-only immutable sqlite open of a 4.9 GB WAL database: is `file:...?immutable=1` safe against a concurrently-writing rebalanceOS launchd sync (stale/inconsistent read), and is that acceptable for an allow-list signal?
5. Failure contract (req 4): does fallback to the pinned list cover DB missing / locked / empty / schema-absent (no github_activity table)? Any case that returns an empty allow-list silently?
6. Is this the smallest change? Is a direct DB read the right coupling vs. alternatives the plan rejected, and is the org-rename alias gap (non-goal) acceptably bounded?
7. Is the verification plan falsifiable without adding tests, and does the red control detect the actual failure?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
