# RELAY · GH-1144 final QA: express targets the repo's integration branch
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
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
6. **Commit only the relay file** (`relay(gh1144-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/express.py` and the rest of the committed implementation on this branch
  versus development at 9a61625f (git diff 9a61625f..HEAD): `utils/py/wave_reconcile.py`,
  `skills/2-daily/express/SKILL.md`, `test/gh267-express-skill.sh`, the evidence in
  `TESTS-RESULTS/2026-10-18+GH-1144/README.md` (and its logs and provenance), and the plan, acceptance and
  Evidence table in `PROJECT/2-WORKING/GH-1144-EXPRESS-DEFAULT-BRANCH.md`. Approved plan QA thread:
  `relay-system/2026-10-18/gh1144-plan-qa.md`.
- Operational envelope: a local developer CLI lane driven by one operator. Grade against the approved plan's
  changes 1–7 and acceptance with commensurate complexity; no new suites, gate machinery or multi-tenant
  hardening (GH-831). The full gate (`ci-route` tier 3) runs once on the final approved commit, after this review.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- Definition of Done: every acceptance item is met by the committed code and substantiated by the evidence;
  Forge's behaviour is unchanged; no load-bearing `development` literal remains on express's path; no new suite
  or registry entry; the two gh267 edits are only what keeps it truthful.

### Questions for the Reviewer
1. Completeness: does any push, pull, checkout, reachability, log, diff or reconcile destination on express's
   run/land/resume/closeout path still use a literal instead of `BASE`? Is `wave_reconcile --base` applied to
   exactly the direct-commit path (default `development` elsewhere)?
2. `resolve_base`: correct order (`--base` → `origin/HEAD` → `gh repo view` default → refuse), candidates
   validated (`BRANCH_NAME`, no `..`, `refs/remotes/origin/<b>` exists), `gh` absence handled? Any way it
   picks a branch without evidence?
3. The `base-unresolved` refusal: before any doc, ledger or git write; telemetry consistent with other refusals?
4. `write_receipt(base=None)` and the edited recovery recipe: Forge receipts byte-identical (`direct development
   push`)? Is the step-6 recipe fix (log copied beside the printed receipt path) correct, and in scope as a
   pre-existing defect in a touched file?
5. Evidence: do the logs substantiate each claim (main-only 113/0, red controls, production reconciler A–E,
   resolution cases, recipe run, smoke)? Note the recorded deviation (red control D's message names `main`)
   and the clone-of-local-clone smoke limitation — acceptable, or does the latter need a code guard?
6. Diff hygiene: anything outside scope, accidental files, home paths in TESTS-RESULTS?
7. Flag anything over- or under-engineered. Cite `file:line`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
