# RELAY · GH-1144 plan QA: express targets the repo's integration branch
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
6. **Commit only the relay file** (`relay(gh1144-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-1144-EXPRESS-DEFAULT-BRANCH.md` (the plan; nothing is built yet).
  Requirements: issue https://github.com/HiQS-Labs/XYZ-forge/issues/1144. Source to ground against:
  `utils/py/express.py`, `utils/py/wave_reconcile.py`, `skills/2-daily/express/SKILL.md`,
  `test/gh267-express-skill.sh`, `test/wave-reconcile.sh`, `validate.sh`, `SOP.md` (express-to-development
  carve-out), `AGENTS.md` (No new tests rail; Costly surfaces).
- Operational envelope: a local developer CLI lane driven by one operator. Grade against the issue and the plan's
  acceptance with commensurate complexity; do not ask for new suites, gate machinery or multi-tenant hardening.
  The plan deliberately departs from the issue in one place (no `gh repo view` fallback; adds an
  `origin/development` fallback) — judge whether that is sound.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- Definition of Done: the plan finds every load-bearing `development` assumption on express's path (including
  wave_reconcile's direct-commit path), keeps XYZ Forge's behaviour unchanged, keeps every express invariant,
  and its checks would catch a missed literal or a split-brain run.

### Questions for the Reviewer
1. Is the site inventory complete? Any `development` assumption on express's run/land/resume/closeout path
   (express.py, wave_reconcile.py `--commit --gate`, anything they shell out to) that the plan misses?
2. Is the resolution order (`--base` → `origin/HEAD` → `development` if `origin/development` exists → refuse
   `base-unresolved`) sound? Is dropping the issue's `gh repo view` fallback acceptable, and is the
   `origin/development` fallback a guess the issue warned against, or a safe compatibility default?
3. Is a module-level `BASE` set once in `main()` acceptable here, or does any caller (tests, recovery recipe,
   imports from other utils) depend on behaviour that would diverge?
4. Is scoping wave_reconcile's `--base` to the direct-commit path (leaving PR/catch-up/hosted modes on
   `development`) correct, or does express's `--gate` run touch those modes?
5. Do the manual checks and red control actually detect a missed literal (e.g. bounds on `main` but push to
   `development`)? Is the verification compliant with GH-831 (no new suite, no registry entry)?
6. Reversibility/risk: is the plan's read right for a change on express's direct-push authority?
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
