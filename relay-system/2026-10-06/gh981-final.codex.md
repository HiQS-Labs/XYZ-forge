# RELAY · GH-981 optional dashboard final QA for visual review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-06.
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
6. **Commit only the relay file** (`relay(gh-981-optional-dashboard-final-qa-for-visual-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Review envelope

Review the entire optional `addons/paperclip-dashboard/` implementation, its attribution/license, approved plan/recon, evidence and diff from `85556455`. Artifact implementation is `0ae105bc`; this receipt and later gate/status receipts do not change its runtime bytes. Review both correctness and fidelity to the user: isolated folder, optional read-only add-on, visual evaluation before any merge. Read existing shared modules at their source seam. No React runtime migration, task writer, default startup, schema or connector change is authorized.

All screenshot records are synthetic. Browser keyboard focus failure was observed and repaired; Option-Tab + Return now preserves focused row. Manual HTTP boundary and source immutability passed (retained negative control). Existing focused pytest is explicitly RED: 34 passed / 5 failed at an unchanged Darwin Python `os.waitid` incompatibility; do not call it green. Tier 3 full qualification follows this QA checkpoint in a separate disposable full clone. A PASS may approve the implementation for visual/draft review only; it must not attest merge readiness or a pending gate.

Source reference is `/Users/noelsaw/Documents/GitHub/paperclip-fork` revision `90182b4f8b40d6ee217937ba61199b4abc31dee7`. Codebase-memory graph tools were unavailable; source-grounded searches/recon were used. Read paths are safe; never run pytest, validate.sh, test/*.sh or executable fixture harnesses in the reviewer worktree. Narrow non-mutating code inspection is permitted with scratch containment. Grade observed input, affected scope and falsifier for any behavior change requested. Avoid speculative production machinery for this local visual spike. Do not modify implementation or source inputs; append findings only to this review thread.

## Setup
- Artifact under review: **SUMMARY.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-10-06

### Artifact — SUMMARY.md
```
# GH-981 spike verification

The synthetic dashboard is usable for operator visual review. Optional demo/live boundaries and existing fixture/manual checks passed. Independent final QA and the required full gate follow this checkpoint; no merge readiness is claimed.

- Browser: desktop, 430 CSS-pixel compact container, dark and collapsed screenshots; filters, keyboard row selection, Escape, selectable handoff, empty/stale/partial/failure/hostile scenarios inspected through native Safari. Compact preview is not device emulation. Retained screenshots use synthetic records in a separate window, avoiding other open task tabs.
- Observed red keyboard control: selection originally moved focus to the document after a full render. The renderer now restores focus to the matching generated control; Option-Tab/Return was rechecked and retained row focus. Expiry recomputation keeps the handoff textarea present.
- HTTP manual boundary: demo snapshot GET forbidden, asset allowlist nonempty, traversal/foreign Host rejected, loopback-only bind and shared CSP/no-store headers passed. Explicit live fixture snapshot was nonempty; source files stayed byte-identical. Forced aggregator exception returned 503. The source-immutability assertion failed after deliberately changing a disposable fixture, then passed when the original bytes were restored.
- Existing `python3 -m src.flightdeck.manual_harness --check`: passed, including its negative controls and source immutability assertions.
- Existing `python3 -m pytest -q test/flightdeck`: **34 passed, 5 failed**. All failures reach unchanged `utils/py/releases_cycle.py` and its `os.waitid` call; this Darwin Python3.9.6 has no `os.waitid`. It is a pre-existing implementation/environment incompatibility, not a green focused suite. The add-on renderer and its bounded fixture path are verified separately. No gate or tests were weakened.
- PDDA frontmatter/status-table/roadmap-coverage: zero errors/warnings at checkpoint. The route classifier selects **tier 3** for the unmapped optional launcher; no mapping was added.
- Existing core Flightdeck source/UI files and dependency/startup files remain unchanged. Upstream MIT notice is byte-identical.

The one-off boundary probe lived under ignored `temp/`; it is not a new suite or gate. Its output is retained, including the deliberate failure trace. Public evidence contains no live prompt/task records. Machine-specific checkout prefixes in command logs are replaced with `$GATE_CLONE`.

Merge decision remains keep/revise/abandon after viewing. Outstanding: final peer QA, qualifying gate and PR publication/status.
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
