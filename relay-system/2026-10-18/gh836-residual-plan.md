# RELAY · GH836 residual fixture spike plan
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
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
6. **Commit only the relay file** (`relay(gh836-residual-fixture-spike-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-836-GATE-HOTSPOTS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-836-GATE-HOTSPOTS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-17
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Review packet

Review the appended Residual fixture spike section in PROJECT/2-WORKING/GH-836-GATE-HOTSPOTS.md, test/gh549-work-events.sh, and releases_app.py cmd_init, cmd_work_backfill, _scan_review_ready. Prior #838/#848 work is delivered; do not rebuild it. Operational envelope: local test fixture spike, no product/live workflow/routing changes. Commensurate complexity: three existing fixture lines, no new helper, CI case/assertion/parameter, framework or test. Grade whether using independent initialized FXD/FXI/FXR7 preserves every existing assertion, actual race and board-reconcile semantic; check slug/cursor/receipts implications and minimal fixture data. No suites in relay worktree; read-only probes allowed. Identify any concrete unmet requirement with file:line and falsifier. This new authorized residual review has cap 3; never reset or extend caps or continue old stopped batches. Only relay file writes.

## Log

### Reviewer · Round 1

VERDICT: PASS
Basis: Approve the residual local-spike plan against the concrete Review packet criteria. This approves the three fixture replacements and their bounded measurement procedure, not implementation results or release readiness.
swept file: yes

- [Pass] The full 397-line artifact was reviewed, including delivered #838/#848 work; no additional pre-existing defect requiring work in this residual spike was found. The residual section explicitly excludes rebuilding that work and limits the change to existing setup lines (`.relay-artifacts/GH-836-GATE-HOTSPOTS.md:383-391`). Replace the backfill FXD copy at `test/gh549-work-events.sh:953`, FXI at `:1152`, and FXR7 at `:1207`; the earlier, unrelated FXD host-return-code fixture at `:435` remains unchanged. No helper, parameter, assertion, routing or product change is needed.
- [Pass] Initialization supplies all migrations, a repo row, lenient enforcement and a canonical dump (`utils/py/releases_app.py:2175-2211`). Explicit `--slug XYZ-forge` preserves the current fixture slug. The stated live counts were independently measured. Read-only probe: `python3 -c 'import sqlite3; c=sqlite3.connect("file:releases.db?mode=ro",uri=True); print([(t,c.execute("SELECT count(*) FROM "+t).fetchone()[0]) for t in ("roadmap_items","work_events","op_receipts")]); print(c.execute("SELECT slug FROM repos ORDER BY id").fetchall())'`; rc 0; decisive output: `[('roadmap_items', 377), ('work_events', 835), ('op_receipts', 1987)]` and `[('XYZ-forge',)]`. This was observation only; no application verb or fixture was executed.
- [Pass] FXD already creates all five mapping rows through verbs (`test/gh549-work-events.sh:954-968`); four are eligible after Deferred is excluded. Independent FXE2/FXE3 copies, the positive exact-count assertion, transactional-guard mutation, bounded rendezvous, racer exit checks and duplicate-count red assertion remain operative (`:1050-1108`). Receipt joins and nonempty guards in legs 21d and 24 remain meaningful on fresh data (`:1042-1048`, `:1380-1408`); initialization does not require copying or pruning a receipt history. FXP/FXP2 inherit the smaller FXD and add their own receipt cases.
- [Pass] Removing the two PRISTINE_TAIL seeds is necessary when replacing their copy lines: new connector cursors start empty, while `backfill_nodispatch` advances to each fixture's actual event tail (`test/gh549-work-events.sh:163-172`). FXI and FXR7 retain connector-enabled reconcile calls and their existing interleave/terminal red controls (`:1158-1229`). Review-ready scanning resolves the configured repository independently of the ledger slug, and source-specific suppression remains in the transaction (`utils/py/releases_app.py:5272-5296`, `:5316-5378`, `:5110-5123`). The raw board adapter uses configured `repos[0]` (`utils/py/work_connectors/github_board.py:94-102`). No board-state assertion is removed or replaced by cursor arithmetic.
- [Unverified — needs clone run] Timing payoff, positive/negative race outcomes, and all existing assertion outcomes on initialized fixtures remain unmeasured this turn. The plan assigns them paired A1/B1/A2/B2 runs with fresh state, retained output, existing negative controls, committed provenance and independent final QA (`.relay-artifacts/GH-836-GATE-HOTSPOTS.md:393-397`). Execute that procedure before claiming equivalence or savings; if a preserved assertion or red control fails, stop and report it rather than weakening it. No suite, pytest, executable fixture, or git command was run here. Graph tools were unavailable; evidence is direct source inspection plus the read-only query above.

Relay closed (Approved), no further plan-review turn needed. Producer acts next to execute the authorized local spike and obtain final QA under its separate cap.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
