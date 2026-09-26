# RELAY · GH-831 Phase 1 final QA — no-new-tests rules
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-25.
-->

NEXT: Producer
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
6. **Commit only the relay file** (`relay(gh831-phase1-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh831-phase1.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/0cc9b6f4-22bd-4606-b4ec-21e1b8f38591/scratchpad/gh831-phase1.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-25
- Definition of Done: **Approved** when all of these hold:
  - (a) every R4 (A)/(B) line assigned to Phase 1 in the plan either no longer asks for a new test, or is scoped
    to repos that forbid new tests;
  - (b) the `AGENTS.md` rail and principle 13 are clear and consistent with the rest of `AGENTS.md`;
  - (c) repo-scoping leaves other repos' policy intact, while `/express` (which exists only here) is
    unconditional;
  - (d) the GH-732 ledger change is correct and keeps its rating;
  - (e) the diff adds no test suite, registry entry or gate machinery;
  - (f) the CHANGELOG entry and the plan's Status table match what the diff does.

## Review packet

**What this is.** Phase 1 of GH-831, per `PROJECT/2-WORKING/GH-831-THREE-TIER-GATE.md` ("Phase 1" and R4). It
is a docs, skill-text and ledger change and nothing else. The diff under review is
`.relay-artifacts/gh831-phase1.diff`: `git diff 24e6e96d 8f3036d4`, excluding the binary `releases.db`. The
branch is `feat/gh831-three-tier-gate` in this worktree.

**Operational envelope.** A single-repo local developer harness. The operator decided "no new tests",
enforced by rules and skill text only. Grade against the plan's Phase 1 scope and commensurate complexity.
Do not ask for new tests or guard machinery, which would contradict the decision.

**Read:**
- the diff;
- the plan's R4 list and Phase 1 section;
- `AGENTS.md` around the new rail and the "Verified beats plausible" section;
- `GUIDING-PRINCIPLES.md` principle 13;
- `skills/2-daily/express/SKILL.md`;
- `TESTS-RESULTS/2026-09-25+GH-831/phase1-rule-check.log` and `phase1-rule-check-r1-fail.log`.

You may grep the worktree read-only.

**Questions** (cite `file:line`):

1. **R4 coverage.** For each (A)/(B) line assigned to Phase 1 in the plan, does the diff remove the new-test ask
   or scope it correctly? Is any docs-route instruction to add a test, suite, registry entry or red-control
   fixture still missing? Grep `skills/`, the root docs and `SOP.md` for phrases like "add a test",
   "regression test", "new test", "write one", "red control", and "register".
2. **The rule text.** Is the `AGENTS.md` *No new tests* rail unambiguous: suites, registry entries, gate
   machinery, how to verify instead, and when editing an existing suite is allowed? Does it conflict with the
   "check that cannot fail" principle, GH-509/GH-544, or `ROUTER.md` startup step 6? Is principle 13's new
   wording consistent with it?
3. **Scoping.** Are shared skills correctly scoped ("where the repo forbids new tests (XYZ-forge, GH-831)"),
   so that other repos keep their policy? Is `/express` consistently unconditional? Its command examples now
   use `test/<existing-suite>.sh`, and `utils/py/express.py` still requires a registered `--suite`.
4. **Ledger.** GH-732 moved to `Deferred · vision` with ⛔ and a superseded note, and its `rated 55/40/50/70` was
   kept. Is that the right verb and section? Does `releases.sql` in the diff show only that row's update, its
   receipt and events, and the GH-831 rows?
5. **No machinery.** Does the diff add any `test/` file, registry entry, hook, guard or telemetry? The recorded
   check is a manual grep logged under `TESTS-RESULTS/`, not a suite. Is that acceptable under the rule?
6. **Accuracy.** Do the CHANGELOG entry and the plan's Status table claim only what the diff does? Is the
   deferral of the full-gate-path lines to Phase 2 recorded in the plan?
7. **Commensurate.** Anything over-built, under-built, or out of Phase 1 scope?

Write findings in the Log per the turn rules. Set `STATUS: Approved` only if the Definition of Done is met.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: Phase 1 substantially implements the freeze, but a shared-skill edit changes policy outside the intended repo scope. Reading beyond the changed lines also exposed an unsafe pre-existing clone recipe. Both need small text corrections, not new tests or machinery.

swept file: no
Scope disclosure: reviewed the seeded diff and surrounding instructions, including the complete express and ci-debug skills; this was not an exhaustive read of every historical entry in the large changed documentation files. No clean whole-source sweep is claimed. The pre-existing defect found is F2.

- [Should] **F1 — Preserve start-task's general scope limits.** At skills/1-hourly/start-task/SKILL.md:127-131, the rewrite removes “outside stated acceptance criteria” and “test footprint must scale to implementation size.” Those deletions affect every repo; the new conditional only governs the no-suite clause. Restore the original general scope/size wording and append the repo-specific exception separately. This is required by DoD (c).
  Observed input: the removed text in .relay-artifacts/gh831-phase1.diff:458-471 includes “outside stated acceptance criteria; test footprint must scale to implementation size”; the replacement ends the general prohibition at “fuzzers;”.
  Affected scope: all consumers of this shared skill, including repos that permit new tests.
  Falsifier: compare the old and new paragraphs with the XYZ-forge conditional omitted; the acceptance-scope and proportional-footprint requirements should remain equivalent. They currently do not.

- [Should] **F2 — Make the existing disposable-clone recipe fail closed.** skills/2-daily/ci-debug/SKILL.md:60-62 independently evaluates the timestamp for clone and cd, then installs hooks without checking either command. A clone spanning a second boundary selects a different cd destination; failed cd leaves execution in the original checkout before the suite instructions at line 67. Compute the destination once, quote it, and stop on clone/cd failure. This pre-existing defect is in an edited file and falls under the relay's sweep rule.
  Observed input: the adjacent commands are “git clone . /tmp/XYZ-forge-ci-debug-$$-$(date +%s)” and “cd /tmp/XYZ-forge-ci-debug-$$-$(date +%s)”, followed by “bash githooks/install.sh”, without failure guards.
  Affected scope: this recipe when clone completion crosses an epoch-second boundary, or clone/cd fails.
  Falsifier: in a disposable full clone, a manual check with clone completion crossing a second boundary and with an injected cd failure must enter the single created destination or stop before hook installation/testing. No executable fixture was run here.

- [Pass] **Rule and coverage:** AGENTS.md:136-147 explicitly covers suites, registry entries, gate machinery, manual evidence, and the narrow existing-suite edit exception. AGENTS.md:104-108 and GUIDING-PRINCIPLES.md:85 preserve witnessed-red evidence without creating a suite. PROJECT/2-WORKING/GH-831-THREE-TIER-GATE.md:431-440 explicitly defers the full-gate-path rewrites. The other reviewed R4 rewrites select existing/manual evidence or condition the exception on repo policy. Existing gate execution requirements do not themselves require creating tests.

- [Pass] **Express and machinery:** skills/2-daily/express/SKILL.md:33 and :127-129 prohibit new suites unconditionally and send an uncovered fix to start-task. Its command examples name an existing suite. utils/py/express.py:536-546 accepts an existing named file present in the registry text. The seeded diff's file headers contain documentation, skill text, evidence and releases.sql; there is no test file, registry edit, hook, guard or telemetry implementation.

- [Pass] **Ledger:** .relay-artifacts/gh831-phase1.diff:402-425 changes GH-732's roadmap row and its two update receipts/events, with generation metadata earlier in that section. GH-831 rows are context, not changes. GH-732 becomes “Deferred · vision” / ⛔, records supersession, and retains textual and structured 55/40/50/70 ratings. Deferral does not falsely mark it shipped.

- [Pass] **Recorded evidence and accuracy:** TESTS-RESULTS/2026-09-25+GH-831/phase1-rule-check-r1-fail.log records radar at zero and ends “FAIL”; phase1-rule-check.log records radar present and ends “PASS”. provenance.jsonl:3 attributes both logs. This manual record fits AGENTS.md:141-144. CHANGELOG.md:3-23 and the plan's Status row describe Phase 1 and leave runtime tier work to Phase 2.

- [Unverified — needs clone run] No validate.sh, test/*.sh, pytest, executable fixtures or gate run was executed here. The supplied pdda-phase1.log ends “PDDA run complete: no errors, 32 warning(s) to review”; this is supplied evidence, not an independently reproduced gate result. Live #805/#732 pointer edits were not independently queried.

Handing off to Producer (claude-a): disposition F1/F2, make the minimal text corrections, and request the next reviewer turn. The harness owns the relay-file commit.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
