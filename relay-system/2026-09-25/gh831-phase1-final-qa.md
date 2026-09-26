# RELAY · GH-831 Phase 1 final QA — no-new-tests rules
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-25.
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
