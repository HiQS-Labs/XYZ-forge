# RELAY · Final QA GH-896 - unified task-sync implementation
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-30.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(gh896-task-sync-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh896-impl.diff** — the full GH-896 implementation diff
  (unified task-sync), seeded read-only. Complete files in-tree at this clone's HEAD:
  `skills/3-weekly/task-sync/` (core.py, adapters/{zcode,antigravity}.py, task_sync.py, SKILL.md),
  `ARCHITECTURE.md` (index row), `TESTS-RESULTS/2026-09-30+GH-896/` (probe batteries +
  provenance.jsonl), `PROJECT/2-WORKING/GH-896-UNIFIED-TASK-SYNC.md` (canonical plan; plan QA
  Approved r2), and the two QA relay threads under `relay-system/2026-09-30/`.
- Plan (requirements R1-R8, acceptance A1-A5): `PROJECT/2-WORKING/GH-896-UNIFIED-TASK-SYNC.md` in-tree.
- Prior lanes: plan-QA relay r2 VERDICT: PASS; agy QA relay r3 VERDICT: PASS (r2 found the
  timestamp-format Blocker + store-type Should, fixed in 0796930a).
- Reviewer: commandcode   ·   Producer: claude-a
- Started: 2026-09-30
- Definition of Done: _GH-896 implemented to plan: R1-R8 met, acceptance checks A1-A5 substantiated
  by committed probe evidence, no scope creep beyond the plan's smallest-affected-surface, no new
  test/ suites (GH-831), machinery commensurate with a local developer CLI._

Goal: FINAL QA of the GH-896 implementation against its canonical plan and the staged probe
evidence.

Operational envelope: local developer CLI on one macOS device grooming two local app stores; no
daemons, no multi-tenant threat model; grade against the stated requirements and commensurate
complexity. Contained read-only probes welcome (`PYTHONDONTWRITEBYTECODE=1`, scratch under
`.relay-scratch/`); quote command + rc + decisive output.

Questions (answer each; cite file:line):
1. Plan conformance: does the implementation satisfy R1-R8 as written (core owns semantics/safety
   contract; adapters own store I/O only; pin models per R1 — ZCode derive-by-window, Agy
   mirror-app-owned with --auto-pin opt-in; stamps from each row's own last-activity time; JSON
   stdout contract; per-IDE isolation; store-path overrides)?
2. Acceptance A1-A5: is the committed evidence (TESTS-RESULTS/2026-09-30+GH-896/) sufficient and
   honest — zcode parity 9/9 vs the QA'd original on identical seeded copies; agy battery 23/23
   incl. the A3 red control against the ORIGINAL script; doctor faults; live-doctor observation
   (agy red while the app runs)? Re-run anything you doubt.
3. Regression check on the r2 fixes: utc_text_to_local_dt (fromisoformat + fallback chain) and the
   non-dict electron-store guard — any new edge they break (naive local strings, empty string,
   None-ish input, subclassed JSON types)?
4. Scope & hygiene: anything in the diff outside the plan's smallest-affected surface? Stray files,
   debug code, secrets, machine-specific paths in committed files (relay threads legitimately name
   primary-checkout absolute paths as port sources — the plan-sanctioned exception)?
5. GH-831: confirm no new test/ suites, registries, or gate machinery.

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Be concrete and cite
file:line.

Write your verdict below and set STATUS to Approved if it passes (verdict line starts exactly
`VERDICT: `).

<!-- REPLACE-MARKER -->## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
