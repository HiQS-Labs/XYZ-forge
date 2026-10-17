# RELAY · PR 1104 QA — Claude Code Opus 5.5 high
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-16.
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
6. **Commit only the relay file** (`relay(gh1100-opus55-high): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PR https://github.com/HiQS-Labs/XYZ-forge/pull/1104 at published head d882a3567bffe300753b0b9eade0a7cd49d13e57. Read `TESTS-RESULTS/2026-10-16+GH-1100/claude-review-source.diff.txt`, the whole changed `utils/py/jog_run.py`, material consumers in `utils/py/swarm_preflight.py`, `utils/py/harness_paths.py`, `utils/py/marathon_drive.py`, the GH-1100 plan/recon, and retained evidence SUMMARY/provenance and prior Codex reviews. The new seed commit adds only this review packet and source diff; runtime bytes are the pinned published version.
- Reviewer: claude-opus-reviewer   ·   Producer: codex-producer
- Started: 2026-10-16
- Definition of Done: Independent QA of issue #1100 and PR #1104 using Claude Code Opus 5.5, high effort. Operational envelope: operator-controlled local Jog CLI; surgical changes and commensurate machinery. The issue observed a disposable-clone Jog invocation omitting target-root because preflight root equaled target; ambient XYZ_HARNESS selected primary, causing branches/phase commits there. Requirement: always pass missing explicit target and keep tooling/phase/coordination in the selected clone while preserving existing explicit targets, .xyz layout and retry semantics. Read-only review: only this relay is writable. No git commands, no live builders, no test/*.sh, validate.sh or pytest in a worktree. Narrow non-mutating scratch probes allowed. Report actual findings, do not fix code. No new tests or registry entries are permitted.

### Review questions

1. Does the shared argv/environment policy fix the observed missing-target and ambient-primary failure end to end, including Marathon phase output and nested relay roots? Cite concrete code consumers.
2. Do run, retry-build and stored-packet gate retry receive the same root policy while preserving locks, idle limits, packet immutability and explicit target flags? Are there concrete unsupported packet shapes emitted by the current producer?
3. Are root and lexical .xyz layouts handled correctly, including old packets without optional harness_home? Distinguish explicit operator override inputs from the reported ambient XYZ_HARNESS case.
4. Is the small helper the appropriate existing owner? Flag unnecessary complexity or concrete regression risk; avoid unrequested enterprise threat models or broad refactors.
5. Do the nonempty red/target-only/green controls, real dry-run and 223-check focused evidence substantiate acceptance? Full gate passed 409/409 at 8a5041fd with one pooled PermissionError passing the built-in serial retry; do not call that clean first-pass evidence or rerun expensive checks here. The latest source head has hosted smoke success. Runtime bytes are unchanged since that full gate.
6. Are any concrete blocker/should findings left? Findings that request behavior changes must include observed input, affected scope and falsifier, with file:line citations. Otherwise approve explicitly and state evidence limits. An inability to refresh GitHub is not a code defect; use the pinned files and receipts.

Reviewer configuration: native Claude Code CLI 2.1.289, model `claude-opus-5-5`, `CLAUDE_REASONING_EFFORT=high`, subscription authentication, relay-only allowlist, default worktree isolation, one review turn under a three-round total cap.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Producer · codex-producer · 2026-10-16
**Did:** Seeded the exact PR runtime diff and existing verification records for the operator-requested additional independent Claude review. No source edits in this QA follow-up.
**Review this:** Answer the six questions above against actual source and evidence. Prior Codex approvals are context, not a substitute for your own judgment. Post graded findings and an explicit verdict in this file.
**Verification:** Existing committed red/green controls and provenance, 223/223 focused suite; normal full gate 409/409 with one built-in retry; final source/metadata head d882a356 hosted smoke succeeded. Receipt-only additions are the only proposed changes after this review.
**Commit:** Published PR target d882a3567bffe300753b0b9eade0a7cd49d13e57.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
