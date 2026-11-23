# RELAY · GH-1587 Plan QA v3 (Final Option 1 Confirmation — Exact ci-route push Invocation)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-23.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 2

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
     A `[Blocker]` must cite an observed failure.
     A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
     This includes earlier [Nit] findings; only a newly raised [Nit] with VERDICT: PASS on STATUS: Approved remains optional.
     This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Manual relay: commit only the relay file** (`relay(gh1587-plan-qa-v3): <role> r<N>`); no push.
   **Driven turn (relay-drive, marathon): do not run git — the harness commits the turn.** **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. (The window wording is
   for a manual relay; in a driven turn, name the next role.) The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1587-QA-REVIEW-BLIND-SPOTS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1587-QA-REVIEW-BLIND-SPOTS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-23
- Definition of Done: Final confirmation of the single remaining `[Should]` from `relay-system/2026-11-23/gh1587-plan-qa-v2.md` (where all other checks were `[Pass]` and zero `[Blocker]`s remained). Commit `8181f3bf2` replaced bare `bash utils/ci-route.sh` with the exact pre-push hook invocation (`githooks/pre-push:333-334`): `git diff --no-renames --name-only "$(git merge-base origin/development HEAD)" HEAD | bash utils/ci-route.sh push` (verified exit 0, emits `tier=3` / full route on `test/gh681-reviewer-probe-rules.sh`). Verify this closes the lone `[Should]` and approve so `--accepted-start` and Phase 1 can proceed.
- Operational Envelope: Local XYZ-forge skill docs, relay turn prompts, marathon brief, packaged tarball, and in-place existing pin suites (Operator Option 1).
- Paraphrase-First Step (GH-1414): Before reading source files, write 2–5 sentences each under `**What this proposes**`, `**How the existing system works, per this document**`, and `**What it's not**` (input boundary: plan artifact only), then provide `**Source-backed technical validation**`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). In a manual relay, end each turn by committing just this file; no push. In a driven turn the harness commits.

## Log

### Reviewer · Round 1 (codex)

**What this proposes**
The plan adds six surface-triggered review checks and a documented clone-probe handoff for hazards that cannot be reproduced in the relay worktree. It updates existing prompts, skills, and pin suites, then verifies them in a disposable clone before final QA and delivery.

**How the existing system works, per this document**
Reviewers must ground behavior-change findings in concrete evidence, while worktree containment restricts mutation-heavy tests. Existing skill and relay instructions share review responsibilities, and existing suites pin prose and exercise relay behavior.

**What it's not**
This is not a new review skill, new test suite, or relaxation of worktree containment. The deterministic prose pins are not evidence that an LLM reliably detects all six defect classes.

**Source-backed technical validation**

- [Pass] The earlier route-check finding is addressed: the plan now supplies `push` and a `--no-renames` merge-base-to-head path stream, with a fallback when first-push Tier-3 routing is not established (.relay-artifacts/GH-1587-QA-REVIEW-BLIND-SPOTS.md:184,207; githooks/pre-push:325-334). Retain the fallback and verify the actual push conditions.
- [Pass] A representative classifier probe, `printf '%s\n' test/gh681-reviewer-probe-rules.sh | bash utils/ci-route.sh push`, exited 0 and printed `route=fast` and `tier=3` with `tier_reason=test change — the routing contract's own evidence stays on the full gate`. The route and tier are distinct outputs (utils/ci-route.sh:5-12); check tier 3 rather than assuming the route field says full.
- [Pass] The earlier red-control repair remains specified as a complete base checkout overlaid with the three candidate suites and expected new assertion failures (.relay-artifacts/GH-1587-QA-REVIEW-BLIND-SPOTS.md:188-190). Preserve that targeted evidence.

swept file: yes
Pre-existing defects: no additional material defects identified in the whole-plan sweep. Actual branch-diff classification, suite execution, and live relay behavior are [Unverified — needs clone run]; this review did not run git or mutation-heavy gates.
VERDICT: PASS
Basis: The remaining route invocation now accepts the hook's event and path-list form and preserves the first-push check and fallback. Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
