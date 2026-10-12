# RELAY · GH1022 Phase6 qualified Jog reader final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-11.
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
6. **Commit only the relay file** (`relay(gh1022-phase6-final): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: utils/py/releases_app.py whole file; test/gh123-lock-progress-bound.sh whole file and unchanged production token policy; PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md Phase6; phase6-jog-manual-results.json and phase6-plan relay
- Reviewer: codex · Producer: author
- Started: 2026-10-12
- Definition of Done: Final QA genuinely new qualified Jog read seam and existing Linux fixture correction; whole owning-file sweep, legacy compatibility, real UNKNOWN/read-only/ownership/drift behavior, no execution permission, no CI case/assertion/registration addition. Own normal new-scope cap3 previously authorized; this cannot reopen/reset corrective accumulation R6FAIL6/6 or imply umbrella completion.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer · Round 1

Frozen candidate c08a432d, owner app source bound in phase6-jog-manual-results.json; plan Approved atbf6f389a, attested373fc7d7. Whole-file review mandatory for final owner source. New read seam: shared _jog_rows qualifies canonical join; legacy13 fields/filter/order/missing-table preserved; inventory --all explicit, one declared root only, read-only connect optional/default writers unchanged. Canonical repo helper/header/sidecar/journal/schema/generation functions reused. Invalid/missing ownership/schema/generation or observed drift =>UNKNOWN/nonzero/no rows/no dispatch; unregistered row retained held. All declared repositories must qualify and carry canonical GIDs. Quiet actualmodule/CLI24 controls pass atcurrent source, no new CI cases. Fixture data/schema/git/negative-control writes only in isolated temp roots, no connectors/builders.

Untouched developmentff895 Ubuntu38198894599 reproduces same existing gh123 failures as prior draft9ebe. Minimal existing PYMOVE file mode a+→w+ removes LinuxO_APPEND positional-write mismatch; no new case/params/assertion/registration, no production policy/bound/time change. Mac focused suites in disposable verification clone running at53b4a79c (before only added repository grammar check atc08); Jog34/34 passed, adapter/lock pending. Current exactcandidate full normal gate and corrected Linux hosted qualification remain pending, not claimed. Read baseline committed evidence and test+unchanged writer; do not run suites/fixture executables or live commands here. Harmless in-memory read probes allowed.

Important: R6 remains FAIL6/6 with Medium S5 title grammar gap trackedGH1028, three proposed individualtestsGH1027 unapproved. Do not reopen corrective R6, reset/replace its artifact, claim its source Approved, or downgrade tracked severity. This is genuinely new planned W7 prerequisite and in-scope existing CI fixture diagnosis, expressly authorized normal cap3. W7 global census/rollover/selection, W8 construction/readiness, W9freeze/approval,W10sharedfire/phase/resume/landing,W11audit remain active. Review source, plan and claims. Report other pre-existing owner defects with concrete input/scope/falsifier/severity; no blanket owner clearance without reading whole file. No source edits, extraagents, suites, pytest, fixture programs, connectors/network/production/Git writes except this relay. Handing off to Reviewer(codex)—take the final new-scope turn.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
