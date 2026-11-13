# RELAY · GH-1452 plan QA: merge-cleanup plan-ahead landing forecast
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-13.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1452-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review (the PLAN, pre-implementation): `PROJECT/1-INBOX/GH-1452-MERGE-CLEANUP-PLAN-AHEAD.md`, whose `## Idea` section is the issue body for HiQS-Labs/XYZ-forge#1452 (Observed, Diagnosis, Plan, Blast radius, Acceptance, Verification, Non-goals, Risk, PRS proposal, Preflight Contract). No production code exists yet.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-13
- Operational envelope: a local, advisory conflict forecast printed by an operator CLI (`skills/2-daily/merge-cleanup`). Grade against the stated requirements and commensurate complexity; do NOT demand multi-tenant or enterprise machinery. XYZ-forge forbids new tests (AGENTS.md *No new tests*, GH-831): a request for a new test file or registry entry is itself a finding. Verification is existing suites plus retained manual checks under `TESTS-RESULTS/`.
- Source paths to validate against (read-only): `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (early checkpoint ~`:2000-2050`, `pin_selection` `:491`, `verify_selection` `:513`, dry-run decision block ~`:2229-2240`, B1 loop ~`:1500-1650`), `skills/2-daily/merge-cleanup/scripts/ledger_merge.py` (`pre_merge_ledger_gate` `:658`, `B1_EXCLUDED` ~`:543`, `LEDGER_VIEWS` `:37`), `skills/2-daily/merge-cleanup/scripts/attempt_record.py` (`MAX_REPAIRS` `:31`), `skills/2-daily/merge-cleanup/scripts/batch_record.py` (`set_landing_plan` `:310`), `skills/2-daily/merge-cleanup/scripts/toposort_prs.py`, `skills/2-daily/merge-cleanup/SKILL.md` (GH-1066 / GH-1158 sections, capability table).
- Prior review: a single-model (Codex) consult on the draft issue found 5 blockers, all dispositioned and folded into the plan before this review (issue comment 6861008436): early checkpoint is the authoritative decision point; the `forecast` flag value was dropped so the GH-1158 explicit decision stays unchanged; exact repair counts became a churn-risk band; the merge-tree continuation rule stops the cumulative fold at the first conflict; `pin_selection` stays the single atomic writer. agy did not answer (quota). Do not re-litigate those unless you have new evidence; challenge what remains.
- Definition of Done (for this plan review): the plan is grounded in the cited paths, extends the existing subsystem and writer, has falsifiable acceptance checks with real red controls, bounded blast radius and rollback, grounded PRS ratings with neutral appeal, and no unneeded machinery.

## Review instructions (Reviewer: read this before anything else)

**Step A — paraphrase first (GH-1414).** Before opening any source file or the dispositions above, read ONLY the `## Idea` section of the plan document and write, in your review block, 2-5 sentences each under **What this proposes** and **How the existing system works, per this document**, plus a short **What it's not** where a consequential expectation could be mistaken. Ground exclusions in the plan's own sections; distinguish excluded work, deferred work, unresolved choices and later authorization; label inference instead of inventing non-goals. State the input boundary ("read only the Idea section").

**Step B — source-backed validation.** Then read the cited source paths and answer, with `file:line` citations (label this part "source-backed"):

1. Are the Observed claims and every file:line citation in the plan grounded in the current tree (base `6c0c76bb5`)? Quote any that are wrong.
2. Is any requirement missing from Plan, Acceptance or Non-goals?
3. Does the plan extend the existing subsystem and writer (`toposort_prs`, `ledger_merge`, `attempt_record`, `batch_record`, the `pin_selection` writer) rather than add a parallel one? Is the single new function placed correctly?
4. What prevents an unchanged, unfixed tree from being reported as delivered, and where is the observed rejection? Does EACH Acceptance item name a real red control, and do the probes in the Preflight Contract hold on the unfixed tree?
5. Are blast radius, ordering, rollback and the manual verification cases sufficient and proportionate? Is the one-clone `git merge-tree` design (frozen base, `pull/<N>/head` fetches verified against pins, cumulative fold stopping at first conflict, `unknown` never `clean`) sound and commensurate for an advisory forecast?
6. Is writing the forecast inside `pin_selection` as one atomic snapshot safe, given the dry-run ordering and the existing lock helper? What exactly is serialized?
7. Are the PRS ratings (pri 55, sev 40, appeal 50, effort 40) grounded, and is appeal neutral?
8. Is anything over-engineered for an advisory CLI forecast? Name unneeded machinery to cut.

Output: graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix. Every `[Blocker]` or `[Should]` asking for a behaviour change needs `Observed input:`, `Affected scope:` and `Falsifier:` lines. Include the literal line `swept file: yes` or `swept file: no`. Set a VERDICT (PASS, FAIL or PARKED) and Basis. Read-only probes only (no `validate.sh`, no `test/*.sh`, no pytest).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
