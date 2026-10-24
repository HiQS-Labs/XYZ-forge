# RELAY · GH-1201 code-audit intake final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-24.
-->

NEXT: Closed
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh1201-code-audit-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: commit `2ab26894` versus the development base; read the complete six GH-1201 through GH-1206 capture docs under PROJECT/1-INBOX, the `CHANGELOG.md` entry, and `releases.sql` diff. Inspect `releases.db` only through the read-only roadmap list and check commands; do not mutate it.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-24
- Definition of Done: intake-only change; all six docs accurately transcribe the actionable plans and use PRS `pri/sev/appeal/effort` values 1201=75/70/85/70, 1202=70/55/80/65, 1203=60/60/85/20, 1204=80/75/75/70, 1205=80/75/85/35, 1206=50/30/65/90; umbrella was sharpened after the deeper review; findings are evidence-bounded and non-goals prevent destructive cleanup; ledger rows and doc paths match; generated leaderboard/views are absent; changelog claims match actual verification. Focused evidence already observed: `npm run test:unit` 14/14, `releases_app.py check` 0 failures/10 warnings, `pdda.sh run` 0 errors/37 existing warnings. Review the complete artifacts, not only their diffs. Do not edit any artifact or run mutation-heavy suites. Return graded cited findings and a verdict; Approved only if no Blocker/Should remains.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes

- [Pass] The complete six-doc sweep found the required capture set, reciprocal umbrella links, exact ratings, bounded plans, and non-goals that exclude destructive cleanup. Citations: `PROJECT/1-INBOX/GH-1201-CODE-AUDIT.md:14-21,42-57`; `PROJECT/1-INBOX/GH-1202-DOC-COMPACTION.md:27-54`; `PROJECT/1-INBOX/GH-1203-PURE-PYTHON.md:28-51`; `PROJECT/1-INBOX/GH-1204-LEDGER-HYGIENE.md:28-52`; `PROJECT/1-INBOX/GH-1205-MODULE-DECOMPOSITION.md:29-54`; `PROJECT/1-INBOX/GH-1206-PACKAGING-DRIFT.md:27-44`. No pre-existing defect was found in the reviewed artifacts.
- [Pass] PRS persistence agrees with the captures: `releases.sql:893-898` supplies the exact six `PROJECT/1-INBOX/GH-120[1-6]-*.md` paths and ratings, while `python3 utils/py/releases_app.py roadmap list` exited 0 and returned six parked rows, GH-1201 through GH-1206, with calcs `300,270,225,300,275,235` respectively.
- [Pass] The changelog accurately limits the landing to docs plus receipted ledger rows and does not claim a full gate: `CHANGELOG.md:5-14` says “Intake only; no runtime or package implementation changed” and explicitly says no mutation-heavy full gate ran. This matches the artifact’s own verification boundaries at `PROJECT/1-INBOX/GH-1201-CODE-AUDIT.md:50-57`.
- [Pass] Narrow read-only source probes corroborated the material factual premises: `wc -l` returned `6928 utils/py/releases_app.py`, and `3677/1159/2495/2014/1891` for the five named core modules; package inspection returned `name=xyz-3-agents-swarm; main=index.js; engines=null; files=null`, with `test -e index.js` exit 1. These support `GH-1201-CODE-AUDIT.md:37-38` and `GH-1206-PACKAGING-DRIFT.md:27-29`.
- [Unverified — needs clone run] The already-recorded `releases_app.py check` evidence cannot be independently re-run here: command `python3 utils/py/releases_app.py check` exited 1 before checking, with `PermissionError: .../.git/releases-app.lock`. This sandbox limitation neither contradicts the stated result nor warrants a change; the recorded claim is precisely `CHANGELOG.md:12-14`.

VERDICT: PASS

Basis: No Blocker or Should finding remains. The intake is evidence-bounded, its SQL and live read-only roadmap projection agree, and the changelog accurately discloses the verification boundary.

relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
