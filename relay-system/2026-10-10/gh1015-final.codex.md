# RELAY · GH-1015 independent final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-10.
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
6. **Commit only the relay file** (`relay(gh-1015-independent-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **gh1015-final-packet.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-10-10

### Artifact — gh1015-final-packet.md
```
# Independent Codex final QA — GH-1015

Read the entire parent plan and recon map under PROJECT/2-WORKING/GH-1015-OBSERVER-PATH*, the full two changed production files relay-automation/marathon.sh and validate.sh, driver receipt path producer/writer in utils/py/marathon_drive.py, existing GH609 checker, CHANGELOG top entry, current owned ledger row, and all retained evidence/provenance under TESTS-RESULTS/2026-10-10+GH-1015. Compare against integration base 9a923f3cc131f432f2682e7a11f57d03597fb5df.

Operational envelope: local opted-in developer CLI observer; three changed production lines plus governed intake/review and retained manual artifacts. No new suite, registry entry, gate, controller, paid/live provider invocation, auto-continuation or merge. Manual-replay.py is a one-off evidence replay in TESTS-RESULTS, not a new registered test/gate. Grade actual requirements with commensurate complexity; no speculative enterprise layers. Reviewer writes only this relay, never production/evidence. Do not run suites or executable manual fixtures from the reviewer worktree; bounded read-only data/source inspection is allowed.

1. Does exact observer init abspath align with driver receipts for ordinary default and explicit physical/absolute/relative symlink targets, without changing strict attribution or qualification semantics?
2. Are missed-check sorting and GH609 comment correct, and is package exclusion evidenced?
3. Do retained nonempty candidate results support three valid and eight rejecting cases, all finite JSON sorted keys, and base/old-init/old-sort witnessed red controls? Are hashes/source revisions/identity brackets truthful?
4. Does all code/docs/ledger scope fit the approved plan and persisted 60/35/50/90 rating, neutral appeal and unknown recurrence? No unrelated machinery/new suite?
5. Is the implementation suitable for the pending classified full macOS pre-push gate, with PR readiness explicitly contingent on that gate (not falsely reported already passed)?

Append concrete findings and citations, swept file: yes/no, VERDICT PASS/FAIL/PARKED and Basis. Required behavior-change findings require Observed input/Affected scope/Falsifier. Approve if no required correction remains; acknowledge pending qualifying gate, do not equate this QA to passing tests. Follow the scaffolded status/tick/turn protocol; hand off to codex-author if needed.
```
- Definition of Done: All five questions satisfied with no unresolved required finding; qualifying full macOS gate remains mandatory before a ready PR.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
