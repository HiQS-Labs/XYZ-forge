# RELAY · GH-1007 SWE post-build QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-09.
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
6. **Commit only the relay file** (`relay(gh-1007-swe-post-build-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/1-hourly/swe/SKILL.md`, `ARCHITECTURE.md`, `PROJECT/2-WORKING/GH-1007-SWE-GOVERNANCE.md`, `TESTS-RESULTS/2026-10-09+GH-1007/`, `CHANGELOG.md`, roadmap row GH-1007 and plan relay
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-10-09
- Definition of Done: All GH-1007 acceptance requirements are implemented; evidence is truthful, retained and commensurate; no new tests, gate machinery, runtime subsystem, or unauthorized deployment. Independent plan QA is Approved.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Review packet and explicit questions

Operational envelope: instruction-only skill, existing lifecycle and distribution tools.
No enterprise hardening, blanket SOLID ceremony, runtime framework, or new test suite.
Use /ponytail as the primary complexity filter. The integration base is
`ecec5561a200b12c235bec3dd9dc37dd5d8d0d5e`; implementation checkpoint is `ebad4e53`.
Read the full updated skill, plan, evidence, and plan-review dispositions. Only task
records/evidence and relay setup change after that implementation checkpoint. The actual
classifier selected docs/tier 1. Review current gate evidence if present; pending push/hosted
attestation remains a separate publication boundary, never infer it from this review.

1. Does the final source govern planning, implementation, and code review using the four
   agreed axes, requiring reuse/extension without sacrificing real security/safety contracts?
2. Do new tests have a meaningful burden of proof and an independent CI-admission decision?
   Does the text honor GH-831, avoid quotas/policy tests, and preserve necessary verification?
3. Apply the seven manual scenarios yourself using the final text. Would an Easy rename
   trigger ceremony? Would an authorization gap be ignored? Would cache-driven CI improvement
   be mislabeled product speed? Would an authorized irreversible action without its last-safe
   intervention point be accepted? Record your own decisions and decisive citations.
4. Omission-diff: compare to the old source using the plan relay's recorded audit. Are S1,
   mixed-version migration, failure diagnosis, rollback and named Pillar 0/Blast consumer
   contracts retained without arbitrary FSM/SOLID/scaffold/bidirectional-sync requirements?
5. Is every claimed verification backed by nonempty evidence and source digest/revision?
   Format sensitivity is only a format claim, manual scenarios are bounded textual evidence,
   and the existing codex-turn suite was run in a disposable full clone. Do not turn these
   into a claim of live multi-model compliance or product-performance improvement.
6. Are the PRS rating/accepted-start record and serial GH-1008 boundary truthful? Is any
   parallel subsystem, test file, gate change, deployed payload or unrelated edit present?

Reviewer may write only this relay file. Do not run test suites, validate.sh, pytest, or
executable fixtures; do not mutate source or self-commit. The shim commits your relay.
Approve only the implemented scope supported by evidence. Use file:line/quoted spans for
findings. No missing runtime benchmark is a finding for this documentation-only change.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
