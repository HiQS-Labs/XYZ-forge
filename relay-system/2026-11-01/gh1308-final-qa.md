# RELAY · GH-1308 post-merge QA fixes — final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-01.
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
6. **Commit only the relay file** (`relay(gh1308-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: the fix commit `324bd483` (diff vs `origin/development` @ `cb1bf933`): `utils/py/harness.py` (`init_from_prs` `gh_json_all`, init validation for `--adapter codex`, `tick` re-read after `_reconcile`), `skills/1-hourly/idea/SKILL.md` (`$HQ_ROOT` paths, empty-TARGET guard), `skills/2-daily/merge-cleanup/scripts/scan_clones.py` (`sibling_root`), `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (Jog-failure message), the #1273/#1280 promotions (`PROJECT/3-COMPLETED/`, `releases.db`/`releases.sql`), `CHANGELOG.md`.
- Also read: issue #1308 (the review: findings 1–8 are in scope, 9–13 are explicitly NOT; each in-scope finding states root cause, fix and verification); `PROJECT/2-WORKING/GH-1308-POSTMERGE-QA-FIXES.md`; evidence `TESTS-RESULTS/2026-11-01+GH-1308/` (`red-control-init-cb1bf933.txt`, `checks.txt`, `delivered-map.txt`, `tick-check.txt`, `idea-check.txt`, `sibling-probe-after.txt`, `suites.txt`).
- Operational envelope: eight small, local, reversible fixes from a post-merge review. Grade against #1308's stated requirement for each and commensurate complexity; do not expand scope to items 9–13. XYZ-forge forbids new test suites (GH-831); verification is red/green manual checks plus existing suites. Plan QA skipped as a simple change (reason in the plan doc). The full gate is running on `324bd483`; its result is added next round.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-01
- Definition of Done: (1) `init --from-prs` reads all merged PRs and issues and refuses a possibly truncated list; the GH-1279 Stage B canary init that failed rc=2 on `cb1bf933` now passes and the delivered map matches an all-PR recomputation; (2) `--adapter codex` with `--max-call-cost` 0 is refused, >0 accepted, the rules adapter unchanged; (3) re-ticking an unfinished tick returns the reconciled status; (4) the idea skill's tool calls resolve from a non-forge repo and an unresolved project stops before any git/ledger call; (5) `sibling_root` returns None for a parent equal to or containing a NEVER_DELETE root and is unchanged for the normal `~/Documents/GH Repos` layout; (6) the Jog-failure message is accurate; (7) #1273 and #1280 are Completed via the supported writer and `releases_app check` is clean; no behaviour outside these changes; no new suite.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
