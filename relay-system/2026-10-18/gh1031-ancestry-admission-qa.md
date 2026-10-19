# RELAY · GH-1031 QA: post-commit ancestry admission check (PR 1024)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
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
6. **Commit only the relay file** (`relay(gh1031-ancestry-admission-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/3-weekly/weekly-planner/scripts/planner_core.py` — function `reconcile_weekly`, the ancestry phase (search `retain fully preserved predecessor ancestry`). The change under review is commit 0596d535 (7 added lines, `git show 0596d535`).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- Definition of Done: GH-1031 is closed by the smallest commensurate change — the commit Git actually produced is admitted only when its ordered parents and tree match the recorded `pending_merge` intent; otherwise the operation refuses and leaves `pending_merge` set. No new tests, suites or gate machinery (GH-831). No new abstraction.

## Context

GH-1031 (issue text, verbatim summary): `reconcile_weekly` validated the native ancestry merge's intended
tree and clean state BEFORE committing, then accepted the returned HEAD and cleared `pending_merge`
without validating its full tree and ordered parent list. Two full-clone reproductions exist:
(a) an installed pre-commit hook added/staged README during the ancestry commit — the caller cleared
intent while retaining that unaccounted content; (b) a commit-result adapter produced a real
three-parent commit with the intended tree — the caller likewise completed and cleared intent.

The fix (commit 0596d535) inserts, directly after the `git commit` of the ancestry merge:

```python
parents = git(['rev-list', '--parents', '-n', '1', 'HEAD'], root).split()[1:]
if (parents != [state['pending_merge']['head'], old_head]
        or git(['rev-parse', 'HEAD^{tree}'], root) != state['pending_merge']['tree'] or dirty(root)):
    raise ValueError('unknown native ancestry result; preserve evidence')
```

This is the same predicate the interrupted-result recovery path already applies a few lines above
(search `unknown native ancestry result` — it now appears twice).

Operational envelope: local developer CLI run by one operator in a full clone; single repo; outputs
are HELD / dispatch false by design. Commensurate complexity applies: do not request journaling,
helpers, retries, or new fixtures. Measure read-only only (GH-681); anything needing a clone run is
`[Unverified — needs clone run]`.

## Questions

1. Does the inserted check close BOTH reproduced admissions, (a) hook-staged extra content and
   (b) a third parent? Cite the exact predicate term that catches each.
2. Parent order: after `git merge --no-ff --no-commit -s ours <old_head>` on top of
   `pending_merge['head']`, then `git commit`, is `[pending_merge['head'], old_head]` always the exact
   ordered parent list? Name any legitimate Git result that would differ and so be wrongly refused.
3. Refusal disposition: after the raise, `pending_merge` stays set and HEAD is the bad commit. On the
   next run, the recovery branch (`if pending_merge and HEAD != pending_merge['head']`) re-evaluates
   the same predicate and raises again. Is a hard stop that preserves evidence the correct outcome
   here, consistent with the issue's "preserve evidence" wording, or does it leave the operation
   unrecoverable in a way the issue did not intend?
4. Sibling admissions: `reconcile_weekly` makes other commits via the local `commit(...)` helper
   (`weekly: preserve predecessor captures`, `weekly: retain exact predecessor intake`). Do those
   paths have the same accept-without-looking shape? If so, is that in GH-1031's scope or a separate
   issue? (Cite lines; do not generalize without an observed input.)
5. Commensurate complexity: is the 7-line duplicated predicate the right size, or would you require
   a shared helper? Default expectation is no helper for two call sites.
6. Verification without new tests (GH-831): is "py_compile + test/gh418 + test/gh698 pass" plus a
   recorded manual re-run of reproductions (a) and (b) in a disposable full clone sufficient
   evidence to close GH-1031? State what the recorded manual check must show.

Grade each with `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`, include `swept file: yes|no`, then VERDICT
and Basis. Set `STATUS: Approved` only if no `[Blocker]` remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
