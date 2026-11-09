# RELAY · GH-1376 compatibility extension plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-08.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-1376-compatibility-extension-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1376-FLYWHEEL-SKILL.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1376-FLYWHEEL-SKILL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-11-08
- Definition of Done: Review the Compatibility extension section against the operator request for 10days support and explicit Daily support in this PR. Read the full plan, flywheel, skills/3-weekly/10days/SKILL.md, and the recorded Daily contract below. Operational envelope: Markdown skill routing for local Forge work; no runtime changes, new gates/tests, scheduler, actual sweep firing or deployment. Commensurate complexity only.
- Questions: (1) Does 10days retain one batch owner and its explicitly-invoked auto-fire exception without bypassing start-marathon confirmation? (2) Does bounded repair preserve red-gate halt, readiness, history, limits and safety holds? (3) Is Daily optional and observation-only, with no unsupported automatic integration claim? (4) Are smoke/QA and rollback proportionate and sufficient? (5) Is reuse of existing issue/rating/PR grounded rather than duplicate intake?
- Daily source contract, read from installed daily SKILL.md: "Read-Only Against Repositories & External Stores"; synthesis "never mutates git state, resets branches, alters worktrees, or writes to external stores"; append synthesis to temp/daily-log/YYYY-MM-DD.log. Daily is external to this source tree; do not edit a deployed copy. This is a recorded instruction contract, not a runtime integration test.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes

VERDICT: PASS
Basis: Read the complete seeded plan, complete flywheel and 10days source skills, and the recorded Daily contract in Setup. The extension is a proportionate instruction-routing change; no blocking pre-existing defect was found in the plan. Approval covers plan readiness, not implementation, live GitHub state, runtime integration or successful unattended execution.

- [Unverified — no citation] One batch owner and the firing boundary are explicit. Artifact lines 183–184 require selection AND dispatch through 10days only when explicitly invoked, while retaining start-marathon exact-plan confirmation and standalone sweeps. This matches 10days' introduction, “carries the plan through PRS rating evaluation, preflight, branch-cut, and execution in one run”, and flywheel step 3, “only after the operator confirms the exact dry-run-approved plan and order.” No second Jog dispatch is proposed.
- [Unverified — no citation] Recovery retains the failed-wave hold rather than skipping it. Artifact line 185 requires verification with existing failed/relevant checks, retained attempts/history, readiness recheck, and safety/ownership/containment/unknown-cause holds; it expressly forbids counter resets, cap/gate changes and automatic restart. The reciprocal wording change is necessary because current 10days Step 7 says “leave the branch as-is for the operator to inspect.”
- [Unverified — no citation] Daily is an optional observation source, not a dispatcher: artifact lines 174 and 183 prohibit installed-copy changes and dispatch/repair authority, and missing Daily cannot block execution. This is consistent with Setup's recorded “Read-Only Against Repositories & External Stores” contract. No automatic observer integration is claimed.
- [Pass] Scope and proof are bounded. Artifact lines 179 and 187 specify reversible Markdown edits, existing PDDA checks in a separate full clone, manual consumer scenarios, independent plan/final review and provenance; no new gate, scheduler, sweep, merge or deployment. Line 191 explicitly excludes historical QA receipts from extension coverage. Reusing the issue/branch/PR is justified as the same routing seam at line 168; live remote identity/state still belongs to execution-time reconciliation.
- [Nit] Reconcile the earlier blanket “No automatic marathon firing” statements (artifact lines 18, 95 and 136) with the named exception at line 184 during implementation. State “no new firing authority; preserve explicitly invoked 10days' existing exception” or equivalent. The specific extension already makes the intended precedence clear, so this does not block plan approval.

Verification: static source inspection only, using `nl -ba .relay-artifacts/GH-1376-FLYWHEEL-SKILL.md`, `cat skills/2-daily/flywheel/SKILL.md`, and `cat skills/3-weekly/10days/SKILL.md` plus targeted reads for truncated spans; exit status 0. Decisive spans are quoted/cited above. No executable fixtures or test gates were run. Runtime/gate claims remain [Unverified — needs clone run].

relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
