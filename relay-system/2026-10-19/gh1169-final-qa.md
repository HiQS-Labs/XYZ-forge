# RELAY · GH-1169 final QA: express vendored-host mode
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-19.
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
6. **Commit only the relay file** (`relay(gh1169-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `utils/py/express.py` and the rest of the committed implementation on this branch versus
  development at 7eeae804 (git diff 7eeae804..HEAD): `skills/2-daily/express/SKILL.md`, the evidence in
  `TESTS-RESULTS/2026-10-19+GH-1169/README.md` (logs, fixture and runner scripts, provenance), and the plan and Evidence
  table in `PROJECT/2-WORKING/GH-1169-EXPRESS-VENDORED-HOST.md`. Approved plan QA: `relay-system/2026-10-19/gh1169-plan-qa.md`.
- Operational envelope: a local developer CLI lane driven by one operator. Grade against the approved plan's changes
  1–6 and acceptance with commensurate complexity; no new suites or gate machinery (GH-831). The full gate runs once on
  the final approved commit, after this review.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-19
- Definition of Done: each acceptance item is met by the committed code and substantiated by the evidence; canonical
  (non-vendored) express is byte-identical in behaviour and recovery text; the host docs gate can fail and a red gate
  publishes nothing; code hotfixes without a registry refuse cleanly; no new suite.

### Questions for the Reviewer
1. Is every vendored-only branch gated on `VENDORED` (set once in `main()` from express's own file) so canonical Forge
   runs are unchanged? Any canonical path whose output or behaviour changed (beyond the missing-`validate.sh` refusal,
   which the plan applies to any repo)?
2. Docs lane: `HOST_DOCS_SUITE` spelling, `suite_file`/`suite_argv`, `PDDA_MODE=full` env on the run, receipt command,
   resume matching. Is the `--docs-only` binding airtight (no bypass by spelling or flag combination)?
3. Gate wiring: host hook via `git rev-parse --git-path hooks/pre-push`; "none" path only when vendored and no
   `githooks/install.sh`. Sound?
4. Tool resolution: `harness_tool` anchored on express's own file; `releases_app` and `reconcile_gated` only. Correct,
   and does it leave wave_reconcile's own repo-first contract untouched?
5. Evidence: do the logs support S1–S8 and both smokes? Are the fixture's shortcuts (local bare at a github.com-shaped
   path, gh stub, temp HOME) acceptable for what each scenario claims?
6. Diff hygiene and anything over- or under-engineered. Cite `file:line`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
