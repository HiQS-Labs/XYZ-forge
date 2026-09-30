# RELAY · GH-856 final gate fixture correction QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-29.
-->

NEXT: Producer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh856-gate-fixture-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `test/gh549-work-events.sh`, `PROJECT/2-WORKING/GH-856-RELAY-LOCATOR.md`, and `CHANGELOG.md`. Also inspect the full committed branch diff against origin/development for GH-856 and read the previous final approval at relay-system/2026-09-29/gh856-final-qa.md for continuity; do not reuse its approval for the revised diff. Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/856.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-29
- Definition of Done: the copied `relay-xyz` locator still satisfies issue #856 and its approved plan, and the revised GH-549 fixture tests connector bounds and lock serialization on only the fixture's own emitted events. The red controls remain load-bearing. No production connector behavior changed, no new test suite or registry entry was added, and the plan, ledger, and changelog state is truthful. The original `ci-local.sh --base origin/development` gate on `b6f9ca06` was red only in GH-549 (123/125): five legitimate #856 ledger events crossed its 500-event replay cap. Base GH-549 was 125/125; the revised fixture on the same reviewed code passed 125/125 in disposable full clones. A new full gate is reserved for this final approved revision. Review only; do not run mutation-heavy suites in this task clone.

### Review questions

1. Does seeding the three GH-549 stub cases at `PRISTINE_TAIL` preserve their intended positive and red assertions, including `--reset` and later cases that intentionally use cursor zero? Cite exact lines.
2. Is any #856 acceptance criterion undermined by the fresh diff? Check the complete branch diff and the prior final QA, and state whether files were swept.
3. Are the gate diagnosis and verification claims supported without treating the first red full gate as passing? Check the work-event counts, connector batch cap, and plan text. Keep findings limited to concrete defects in this issue's operational scope.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes — read all 1,506 lines of `test/gh549-work-events.sh`, the GH-856 plan, the changed changelog entry, and the prior final QA. No pre-existing defect in the touched fixture's GH-856 operational scope was found.

- [Pass] The three stub cases replay their own events: `PRISTINE_TAIL` and `seed_cursor_tail` are defined at `test/gh549-work-events.sh:162-166`; the bounds positive and red copies reseed at `:524` and `:587`, and the lock positive and red copies reseed at `:819` and `:853`. The bounds assertions require refusal with the cursor still at the tail and then storage of `MAXID+5` after the guard is removed (`:533-545,589-594`). The lock assertions require one child with the lock and at least two without it (`:826-864`). A read-only `bash -n test/gh549-work-events.sh` exited 0. A read-only source probe for these seed patterns exited 0 and found the bounds seeds once each and the lock red seed once.
- [Pass] Seeding does not erase intentional replay-from-zero checks: `work reconcile --reset` remains at `test/gh549-work-events.sh:500-504,937-941`; later cases explicitly delete cursors at `:557,595,777,868,885,892,932`. The connector reads only `id > last_id` with `limit=500` (`utils/py/work_connectors/__init__.py:128-139`), so starting these controls at the pristine tail keeps their own new events in the dispatched batch. Read-only `sqlite3 -readonly releases.db "SELECT 'total='||COUNT(*)||' tail='||COALESCE(MAX(id),0) FROM work_events; SELECT id,gh_number,event FROM work_events WHERE gh_number=856 ORDER BY id;"` exited 0: `total=496 tail=496`, followed by #856 event IDs `492` through `496`.
- [Pass] The plan calls the first full gate red `123/125`, the base fixture `125/125`, the revised focused clone run `125/125`, and reserves a new full gate (`PROJECT/2-WORKING/GH-856-RELAY-LOCATOR.md:28-30,75-78`). The changelog names the fixture correction (`CHANGELOG.md:3-5`), and the roadmap row retains `86/82/50/55` and `in-progress` (`releases.sql:773`). The prior locator approval remains a separate review of the earlier code (`relay-system/2026-09-29/gh856-final-qa.md`, Reviewer Round 3); current locator selection, shared helper loading, and readiness paths remain visible at `skills/1-hourly/relay-xyz/find-harness.sh:171-273,402-488`.
- [Unverified — turn constraint] No mutation-heavy suite or qualifying gate ran in this valued worktree. The exact committed `origin/development...HEAD` diff could not be independently obtained without Git: the graph change request was denied by approval policy, and read-only `gh api 'repos/HiQS-Labs/XYZ-forge/contents/test/gh549-work-events.sh?ref=c7ea57fded7a8810547cd1b6dd86d31ab73dfd5e' --jq .content` exited 1 with `error connecting to api.github.com`. A read-only `diff -u` against the separate main checkout showed only the expected fixture seeding hunks, and `cmp -s` found the production connector module identical there; that checkout is on another branch, so neither comparison attests the committed branch diff. The harness must inspect that diff and run the reserved full gate before PR readiness.

VERDICT: PASS
Basis: The seeded fixture preserves the positive, red, reset, and explicit zero-cursor controls at the observed 496-event ledger size; the documents distinguish the red first gate from the focused green rerun. No concrete GH-856 regression was found in the reviewed files. Full branch-diff attestation and the qualifying gate remain with the harness.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
