# RELAY · GH1066 final QA: CI groups and cross-model strategy review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-14.
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
6. **Commit only the relay file** (`relay(gh1066-final-qa-ci-groups-and-cross-model-strategy-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file skills/2-daily/merge-cleanup/SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-14
- Definition of Done: approved GH1066 plan implemented as bounded caller-only guidance; manual evidence truthful; no new runtime or CI machinery.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Bounded final QA packet

Read the whole skills/2-daily/merge-cleanup/SKILL.md and PROJECT/2-WORKING/GH-1066-MERGE-CLEANUP-CI-GROUPS.md; plan QA relay-system/2026-10-14/gh1066-plan.codex.md; TESTS-RESULTS/2026-10-14+GH-1066/manual-review.md and provenance.jsonl; docs/CI-CHURN-RECOVERY-SOP.md as needed for policy. Production scope is only added CI-heavy group guidance and existing batch issue template field. No driver/runtime/CI/settings/new tests/gate runner changes. Core additions are candidate preparation/freeze, existing supported batch path with sequential fallback, and one bounded different-model-family adversarial strategy review for authorized batches3+ (not per subgroup).

Operational envelope: local developer orchestration prose; commensurate complexity. This is not a measured CI saving or executable enforcement. The initial prototype publication gate was interrupted when scope expanded, not passed. Existing codex-turn43/0 and manual7cases/2red policy variants have receipts; final full push gate runs once AFTER this approval in the separate full helper clone. Do not demand a full gate now or run tests in the relay worktree.

1. Does the implementation match the approved plan, including the whole-batch threshold, actual model identity, cap3 across resumes, per-PR QA preservation, neutral truthful missing-review/model-unknown handling and affected-plan invalidation?
2. Are CI qualification and final verification strategically placed without silently bypassing mandatory checks or changing Phase5 reconciliation, and without claiming unsupported automatic batching or duplicate final sweeps?
3. Are manual evidence/limitations and score65/25/50/85 truthful and proportionate? Any important contradiction in the whole changed skill? Does existing batch record carry required strategy/review fields without another tracking system?
4. Does any added wording introduce avoidable ceremony or stronger behavior than requested? Identify concrete input and cheapest correction; do not invent speculative infrastructure or new tests.

Only this relay thread writable. No git commands, validate/test/pytest/fixtures. Output graded findings with file:line citations, swept file: yes/no, literal VERDICT: PASS|FAIL|PARKED and Basis. Set STATUS: Approved and NEXT: — on supported approval. No self-commit; harness owns receipt. This is final round1/3; prior plan review is not a final approval.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
