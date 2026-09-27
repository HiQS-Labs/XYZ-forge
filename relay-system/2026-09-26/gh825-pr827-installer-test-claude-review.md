# RELAY · PR 827 installer and test review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-26.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 2

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
6. **Commit only the relay file** (`relay(pr-827-installer-and-test-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh825-pr827-installer-test.patch** — the read-only path that
  `relay-drive.sh --artifact-file temp/gh825-pr827-installer-test.patch` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: claude   ·   Producer: codex
- Started: 2026-09-26
- Definition of Done: Independently verify the renamed `where-are-we-at` installer and the updated existing `gh798` test on PR #827 at `43120b3d73615efdddf41ef26965e39a28c2454f`. Check actual install behavior, old-name migration implications, and whether the test makes meaningful assertions. Report concrete gaps and the exact verification limit; approve only if this focused change is sound at a read-only review level.

## Review packet

Operational envelope: a local skill installer that links one skill directory into five agent skill locations. The user requested this second Claude review before merge-conflict resolution. Use Claude Code Fable 5 at high effort. The source head for this review is `43120b3d`, against PR base `31a42867`; the seeded patch covers the installer rename and test edits. Read the **full** `skills/2-daily/where-are-we-at/install.sh`, `skills/2-daily/where-are-we-at/SKILL.md`, `test/gh798-status-skill.sh`, the prior review receipt at `relay-system/2026-09-25/gh825-pr827-fable-review.md`, and any related skill installation convention necessary to answer the questions. Keep review machinery commensurate with a 59-line installer. Do not run `validate.sh`, `test/*.sh`, pytest, or executable fixtures in the relay worktree; only read-only source inspection and narrow non-mutating probes are permitted.

Questions:
1. Does `install.sh` install the renamed skill under the intended name in all five targets, preserve the GH-678 foreign-link behavior, and handle dangling links and real target collisions safely? Cite exact lines.
2. Does renaming the skill leave an existing `status` symlink pointing at a removed path, or a live old-name skill competing with Codex's native status skill? Check the actual installer and test, distinguish what they prove from migration of prior installs, and give a concrete failing path if any.
3. Does the updated `gh798` test actually guard the rename and installer behavior? Examine all assertions and negative controls in the full file. Identify vacuous, stale, or missing checks only with a concrete counterexample. Respect the user's no-new-tests instruction.
4. Does the changed installer and test require more than the Markdown/text gate before merge readiness? State exactly what remains unverified; do not run the gate here.

Give one `VERDICT: PASS`, `FAIL`, or `PARKED`, a concise Basis, `swept file: yes/no`, and graded findings with `file:line` citations. A behavior-change `[Blocker]` or `[Should]` needs `Observed input:`, `Affected scope:`, and `Falsifier:`. Write only this relay thread; do not edit implementation files or the PR.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
