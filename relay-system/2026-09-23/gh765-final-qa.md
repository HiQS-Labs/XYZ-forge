# RELAY · PR 765 final QA: start marathon and root PARKED
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-23.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(gh765-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: skills/2-daily/start-marathon/SKILL.md
- Review target: draft PR #765, `origin/development...HEAD` at `fe2504b7`; inspect the full changed files, especially `PARKED/README.md`, `ROUTER.md`, `AGENTS.md`, `skills/2-daily/workhorse/SKILL.md`, `skills/1-hourly/unstuck/SKILL.md`, `skills/1-hourly/standup/{SKILL.md,collect.sh,triage.py}`, tests and `PROJECT/2-WORKING/GH-762-START-MARATHON-SKILL.md`.
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-09-23
- Operational envelope: local macOS skill routing and repo governance; no marathon dispatch or runtime rewrite. Read-only review; no `validate.sh`, `test/*.sh`, pytest, or executable fixtures in the relay worktree. Use narrow static inspection and the committed evidence. Keep any scratch under `.relay-scratch/` after setting `PYTHONDONTWRITEBYTECODE=1` and `TMPDIR` there.
- Definition of Done: decide whether this PR is content-ready for review, with the existing full-gate baseline failures disclosed and tracked separately in #764. Explicitly answer:
  1. Does ambiguous “marathon” route to preparation while explicit fire still requires the operator gate, and do primary/secondary routes cover intake, contracts, plan QA, disjoint lanes, YAML, preflight and dry-run?
  2. Are recovery loops bounded and current-goal blockers kept in the active plan, without bypassing lane attempt caps?
  3. Is root `PARKED/` the coherent first home for incidental out-of-scope observations, with triage promotion into issue-first `1-INBOX` and RELEASES, without undermining formal PDDA intake? Trace writers and readers.
  4. Does standup still degrade on malformed *machine* records while ignoring ordinary general PARKED notes and checklists? Check `collect.sh`, `triage.py`, the changed fixture, and new test assertion.
  5. Are installed aliases, nudge routes, and direct callers compatible? Is the diff surgical and free of public PII? Identify any concrete blocker to marking the draft ready for review apart from the disclosed full gate.
  Give `VERDICT: PASS` or `FAIL` with `Basis:` and cited findings. `STATUS: Approved` only for PASS; otherwise hand back specific repairs.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
