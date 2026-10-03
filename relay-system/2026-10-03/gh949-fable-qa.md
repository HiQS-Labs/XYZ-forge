# RELAY · PR 953 independent Claude Fable 5.1 high QA
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
6. **Commit only the relay file** (`relay(pr-953-independent-claude-fable-5-1-high-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **PROJECT/2-WORKING/GH-949-ATE-REMEDIATION.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-949-ATE-REMEDIATION.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: claude-fable-qa   ·   Producer: codex-producer
- Started: 2026-10-03
- Definition of Done: Independent whole-file QA of PR #953 head92a8a230c57ce65f4fdb9c1725a8429f4d9816e0: all F1–F9/K1 requirements, preserved callers/contracts, grounded before/after evidence, no unjustified new machinery.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## QA packet

User explicitly requested Claude Code Fable5.1 high via relay-xyz. Launch is pinned to claude-fable-5-1 and high effort, first-party subscription authentication. Sign this independent review as Claude Code Fable5.1 high; the earlier GPT6AstraLight label identifies a different review.

Target PR https://github.com/HiQS-Labs/XYZ-forge/pull/953 at92a8a230c57ce65f4fdb9c1725a8429f4d9816e0, base ancestry3fbed72f781d1ad060e298b798a44c32edef393d. Read canonical plan, recon-gh949-ate-remediation.md, TESTS-RESULTS/2026-10-03+GH-949/SUMMARY.md and relevant raw provenance. Review all six complete changed runtime files: utils/py/proc_group.py, utils/py/domain_oracles.py, utils/py/metamorphic_oracle.py, utils/ate/scripts/run_variations.py, skills/1-hourly/relay-xyz/find-harness.sh, test/lib/runner-envelope.sh. Trace material consumers (fuzz_engine, claude_cli, wave_reconcile, checkin/compile_issue, runner callers) by direct source as needed. Don't assume previous QA proves correctness.

Scope is a local developer CLI. Examine actual cancellation/cleanup, launch-before-admission, all timeout and idempotence observations, directory links/common and worktree Git metadata, structured failure records/UTC, unset HOME and gate selector precedence. Normal-success background children and deliberate session escape/SIGKILL are outside this contract. Zero-budget returns nonzero/no new rows but retains existing initialization; only empty grids promise no writes. Proportionality: no new executor, gate, suite, schema or speculative enterprise infrastructure.

Evidence: all original manual repaired controls and nine existing focused suites pass. Prior independent final QA identified and fixed first-versus-later rc/stdout comparison; red/green actual-process receipts retained. Full local push gate passed870s on992914e6, no bypass/identity drift. Final head differs only by docs/ledger merge and receipts; runtime identical. Hosted blocking smoke succeeded at92a8a230; promotion and advisory jobs skipped by conditions. These are supplied receipts, not assertions that you reran them.

Graph handoff: Verify tier; nearest project XYZ-forge is primary checkout, generation2026-09-01T15:54:30Z. Search claude_cli exhausted with0 results. Coverage: proc_group/domain_oracles/claude_cli/locator/envelope not_tracked; ATE excludedsubtree; metamorphic metadata matches only other checkout. Direct source is required for material claims. Prior recon documents call paths and uncertainty. Do not claim graph access if unavailable.

Review-only, relay file only writable. Do not run mutation-heavy suites, pytest, executable fixtures, model calls, installs or Git commands in the relay worktree. Narrow read-only/in-memory probes allowed under .relay-scratch per protocol; runtime fixture work must be reported as needing a separate full clone. Do not commit or push yourself; harness handles file-scoped commit. A concrete blocker needs observed input, affected scope, falsifier, exact citation and small fix direction. Record PASS/FAIL with honest evidence limits, sweep declaration, and token handoff. No merge authority. Marker stays last.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
