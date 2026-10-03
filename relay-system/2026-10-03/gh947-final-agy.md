# RELAY · GH947 optional recipe profile final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-03.
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
6. **Commit only the relay file** (`relay(gh947-optional-recipe-profile-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **GH-947-FINAL-QA.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: codex-author
- Started: 2026-10-03

### Artifact — GH-947-FINAL-QA.md
```
---
gh_issue: 947
source: https://github.com/HiQS-Labs/XYZ-forge/issues/947
title: GH947 final review packet
status: Review packet (canonical plan remains GH-947-HIQS-RECIPE-PROFILES.md)
created: 2026-10-03
doc_type: review
---

# Final Agy review of GH947

Review complete implementation ec2caeea vs origin/development 3fbed72f. Canonical plan
PROJECT/2-WORKING/GH-947-HIQS-RECIPE-PROFILES.md and issue947 requirements govern scope.
HiQS owns selection/digests; pinned consumer 452f6e4 has 341 tests/build and valid final
Agy approval. PR6 https://github.com/NeochromeTeam/hiqs-ai-resolve/pull/6 is draft over29.
Grade source/fixture delivery; published maintained recipe and live pilot remain merge
and milestone blockers. No production migration, provider call, deployment or merge.

Read full touched files: utils/py/profile_resolve.py, claude_cli.py, proc_group.py,
consult.py, claude-turn.py, and skills/1-hourly/relay-xyz/SKILL.md. No new test files or
registry entries; source uses existing process-group helper/profile problem emission and
Claude native preflight. Check explicit source precedes manual/defaults; no downgraded
fallback, unsupported providers/configs/builds fail before dispatch, exact argv and
current expiry (including time crossed during auth), retained request/lock identity,
old protocol refusal, unsupported actor before token claim, and response model metadata.
Pilot personal pro/max first-party macOS advisory only; no generic flags/managed config.
Existing literal profiles independent; no profile applied must preserve an active guard.

Evidence TESTS-RESULTS/2026-10-03+GH-947/provenance.jsonl plus logs and exact manual
control command. Source current; test clocks/stub provider are fixture-only, never runtime
flags. Actual pinned HiQS tsx from foreign and copied vendored imports tested; two guarded
calls use no new resolver; expired/invalid controls zero worker calls; controlled expiry
mutation fails then restores green. Cold/warm data are tiny fixture samples, not production
performance benchmarks. Focused profile 51, Claude subscription +turn controls, process
cleanup 43 pass. Final full ci-local gate runs ONCE after attested approval in fresh full
clone, not in this worktree. Do not run suites here. Full clone identity is checked before
and after; failure or drift remains failed/unqualified and draft stays blocked.

Operational envelope local single-user explicit advisory admission; no enterprise grants,
second resolver/catalog/writer, cache, service, actor expansion or new generic executor.
Report concrete failing input/predicate/falsifier for behavior findings; no speculative
enterprise machinery. Roundcap3. Edit only relay thread. APPEND while preserving every
existing byte and blank line; only header NEXT/STATUS/ROUND may change. Driver rejects
removed spacing above your block even if your verdict is positive.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
