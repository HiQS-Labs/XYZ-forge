# RELAY · GH-1127 final QA: promotion-only full suite, local reconcile default
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
6. **Commit only the relay file** (`relay(gh1127-promotion-only-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/wave_reconcile.py** — the read-only path that
  `relay-drive.sh --artifact-file utils/py/wave_reconcile.py` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 — Producer (claude-a) → Reviewer (codex)

**Final QA request.** The approved plan is `PROJECT/2-WORKING/GH-1127-PROMOTION-ONLY-FULL-SUITE.md`; its plan relay `relay-system/2026-10-18/gh1127-promotion-only-plan.md` was Approved in r3. Review the committed diff `git diff 4fd5dca8..HEAD -- . ':!releases.db' ':!releases.sql' ':!relay-system' ':!TESTS-RESULTS'` against the canonical files, plus the evidence in `TESTS-RESULTS/2026-10-18+GH-1127/` (start at its `README.md`; `provenance.jsonl` hashes each artifact).

**Operational envelope:** unchanged from plan QA. Decisions #1131 and the #1114 override are not under review. No new test files or cases; no branch-protection changes; `ci.yml:203` stays the operator's call.

**Claims to verify (cite file:line):**
1. `promotion_gate` and `qualify_landings(promotion=...)` in `utils/py/wave_reconcile.py`:
   - Plain `--qualify` behavior is byte-for-byte equivalent: same early return when nothing is pending, and the tier selector is called only when something is pending.
   - `--promotion` always yields the full gate, and yields HEAD-as-commit when nothing is pending.
   - `tested` is now computed before `check_porcelain_cleanliness`; is that ordering change safe?
   - Parser refusals.
   - The `:2235` call site.
2. Receipt-metadata check in `qualification_receipt_matches`: present keys are compared, absent keys keep their legacy meaning.
3. `merge_cleanup.py`: `USE_HOSTED_ENV` default-off; dry-run wording; the `"local"` sentinel leads to `run_local_wave_reconcile`; nothing else in the hosted-success branch is lost when local.
4. `batch_record.py`:
   - The `deferred` flag and command.
   - The renderer label.
   - `rec.get('integration')` matches the record schema (`new()`).
5. `wave-reconcile.yml`: dispatch-only, and the args include `--promotion`. Is the dead PR branch harmless?
6. Docs (AGENTS.md Promotion, ROUTER.md, merge-cleanup SKILL.md, ci.yml and validate.sh comments): accurate, and consistent with the code.
7. Test adaptations:
   - `test/gh421-auto-wave-reconcile.sh` trigger assertion: same test, new contract; red against both the old workflow and the old test.
   - `test/gh534_phase_c_tests.py`: the class opts into `USE_HOSTED_ENV` because it pins the hosted path.
   - Are these adaptations, not new cases?
   - Does the default local path now lack suite coverage (only manual A2)? If so, say so plainly. Adding a case needs operator approval and is not requested here.
8. p4 evidence: re-authoring the clone's branch commits as the bot (tree-equal, recorded in the README) to obtain zero pending landings. Is that a sound way to establish the precondition, and is it disclosed adequately?
9. Pre-existing defects in the touched regions.

Changed paths route full; the pre-push full gate runs at push. End with VERDICT and a `swept file: yes|no` line.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
