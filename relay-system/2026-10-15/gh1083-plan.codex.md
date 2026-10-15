# RELAY · GH1083 radar GitHub-first plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-15.
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
6. **Commit only the relay file** (`relay(gh1083-radar-github-first-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **PROJECT/2-WORKING/GH-1083-RADAR-GITHUB-FIRST.md**, source radar skill, and retained issue-source.json.
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-15
- Definition of Done: an implementable minimal instruction-only plan satisfying issue #1083 before product edits.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Producer · Plan review request

Read the canonical plan named above, all of skills/3-weekly/radar/SKILL.md and TESTS-RESULTS/2026-10-15+GH-1083/issue-source.json. No production skill edits have occurred. Review plan vs the actual issue, not just the author's summary. Scope: one skill Markdown payload, no runtime or new tests/runners/state stores. Routine governance/evidence accompanies it. Apply commensurate complexity and the ponytail lens; no enterprise machinery or speculative gates. Repo no-new-tests applies.

Questions:
1. Does the plan cover GitHub authority for work facts and live checking of doc hints across lenses, release membership, historical closure and shipped claims? Do the bounded read/manual checks distinguish a confirmed relationship from a link merely existing, unavailable from genuinely empty, and merged from open PRs?
2. Does moving explicit rgt declarations to governing GitHub issues/PRs preserve Transform-never-inferred and honest adoption measurement, including missing PROJECT or unavailable/partial GitHub?
3. Is the narrow landed/adopted CI SOP threshold exception justified and restricted to operational policy, with GitHub still owning adoption/status/version and supersession? Name any contradiction or missing acceptance check that would restore broad doc-wins authority.
4. Are ratings 70/45/50/85 (neutral appeal, unknown recurrence trend), scope, rollback, manual red controls and post-merge Skills Army pointer supported? The normal docs route must not run a full runtime suite.

Only this relay file writable. Do not edit the plan or skill. No git mutations, validate.sh, test/*.sh, pytest, fixtures or external writes. Use exact source reads; graph may be unavailable/stale in an isolated checkout. Append one reviewer block with graded, concrete findings, file:line evidence, swept file: yes/no, VERDICT: PASS|FAIL|PARKED and Basis. Behavior requests need Observed input / Affected scope / Falsifier. On approval set STATUS: Approved and NEXT: — and **done RELAY-GH1083-PLAN-20261015 --agent codex** with the env-pinned absolute tick; never merely release on approval. Otherwise release to codex-producer and set NEXT: Producer. No self-commit: the harness owns the scoped commit. Cumulative cap 3 rounds. Plan QA only; final dry run/verification is not yet performed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
