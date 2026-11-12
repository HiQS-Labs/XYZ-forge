# RELAY · GH1436 and GH1437 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-12.
-->

NEXT: Producer
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1436-and-gh1437-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1436-CONTRACT-ENVIRONMENT.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/1-INBOX/GH-1436-CONTRACT-ENVIRONMENT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-11-12
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Review questions and input boundary

First read only PROJECT/1-INBOX/GH-1436-CONTRACT-ENVIRONMENT.md and write 2–5 sentences each under **What this proposes** and **How the existing system works, per this document**, plus **What it is not**. Label inference/uncertainty. Then read the #1437 capture and source paths named by the plan for a separately labelled source-backed assessment.

1. Does the shared helper prevent every bounded shape dereference described in #1436, including unregistered rows, without turning partial contracts into execution-ready claims?
2. Does HQ pre-write rejection meet filing-time acceptance without a parallel validator or gate?
3. Does the environment plan stop before suites and distinguish environment faults while preserving healthy/PHP behavior?
4. Are verification, blast radius, rollback and per-issue ratings proportionate and grounded?

Local CLI operational envelope. No new suites, test frameworks, or speculative schema system. Review only: write this relay, never implementation or tests. No suite execution in the relay worktree. Each behavior-change finding needs observed input, affected scope and falsifier.

## Log

### Reviewer · Round 1

swept file: yes

**What this proposes**

Per the GH-1436 document alone, this combines two bounded repairs in one PR: reject malformed contract shapes through the existing preflight owner, and stop the existing validation entry point early for unsuitable Python. It preserves partial intake contracts, keeps full execution requirements in extract_contract, and uses existing suites plus committed manual evidence. This is a plan review; the proposed behavior has not yet been implemented or demonstrated here.

**How the existing system works, per this document**

The document says planner computation reads every active capture, so one malformed target can interrupt reconciliation for an unrelated landing. It identifies earlier zone inference and unregistered-record construction as additional dereference sites, and HQ park as an existing intake writer that accepts supplied contracts without validation. It describes the current environment probe as advisory and yaml-only; these statements were document claims at this first-reading boundary.

**What it is not**

This is not a general schema framework, automatic interpreter manager, new test lane, or permission to execute issue-supplied commands. Inference: accepting a shape-valid partial intake is intentionally weaker than certifying a runnable execution contract.

**Source-backed assessment (after reading #1437 and named source paths)**

- [Pass] Shape coverage and ordering are appropriately scoped. The plan's step 1 explicitly covers “registered and unregistered planner input” before shape-dependent use, including lanes. Current source demonstrates why: _marathon_plan.py:202 dereferences unregistered contract objects, :784 dereferences lanes, :1129 calls zone inference before later checks, :1190 evaluates probe entries, and :1200 dereferences target.ref. The proposed outer/nested checks and held-row state cover these bounded paths without requiring a second validator.
- [Pass] Filing-time rejection has a concrete existing owner. The plan says “HQ park before external/file writes”; utils/hq/hq.sh:309-314 selects the fetched issue body when adopting an issue, and :361/:435 create issues before capture writes at :452. Validate the final selected request before those writes. The acceptance offers intake alternatives; extending HQ satisfies that choice without adding a PDDA gate.
- [Pass] Partial shape and execution validity are explicitly separate: the plan says “shape checks validate present fields” and “extract_contract retains its existing required-field checks.” swarm_preflight.py:100-120 requires target/repo/ref/gate and nonempty probe/artifact lists. Preserving that stronger check avoids treating the helper's success as execution authorization.
- [Pass] Environment work matches #1437 acceptance: the capture requests a distinct nonzero status before suites, interpreter/version/modules, and an exact PATH remedy; plan step 2 supplies exit 3 and chooses the explicit prefix rather than automatic selection. validate.sh:1033-1036 currently checks only yaml and continues; :1439-1441 separately skips missing pytest. Existing PHP handling at :1026-1031 remains outside the proposed behavior change.
- [Pass] Proportionate delivery and rollback: the plan's “Reversibility: Easy; revert the code commit, no data migration,” bounded blast radius, independent per-issue ratings, unchanged PHP behavior, and step 3's existing-suite/manual-evidence approach fit the two issues. No new suite or parallel gate is proposed.
- [Nit] Make the manual evidence matrix in step 3 explicitly include a shape-valid partial contract (for example {"artifacts":["README.md"]}) accepted as intake/planner data while extract_contract still exits 3 for missing required execution fields. Include the same partial/malformed cases for unregistered rows and preserve the distinction between planner “ready” classification and actual execution readiness. This clarifies verification of the plan's existing promise; it does not request a new execution-readiness policy.
- [Nit] Setup's seeded artifact path is absent. Read-only command `cat .relay-artifacts/GH-1436-CONTRACT-ENVIRONMENT.md` exited 1 with “No such file or directory”. I reviewed the complete PROJECT/1-INBOX/GH-1436-CONTRACT-ENVIRONMENT.md explicitly named in the input-boundary instructions, followed by the complete #1437 capture. Ensure the harness binds approval to that reviewed plan content.
- [Unverified — needs clone run] No validate.sh, test/*.sh, pytest, executable fixtures, or mutating probes were run. Old-code red controls, new-code green controls, healthy/PHP preservation, HQ no-write refusal and exact-head gate results remain implementation obligations, not outcomes established by this approval.

Whole-plan sweep included both captures' acceptance, ratings, non-goals, and verification sections. No additional pre-existing plan defects were found; source inspection was bounded to named owners and their relevant paths, not a whole-source-file implementation audit.

**VERDICT: PASS**

**Basis:** The plan extends existing owners, covers the known early and unregistered dereferences, preserves full preflight requirements, and proposes discriminating verification in isolation. Approval is for the plan only; the unexecuted implementation evidence remains outstanding.

Relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
