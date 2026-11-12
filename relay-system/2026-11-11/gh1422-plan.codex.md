# RELAY · GH-1422 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-11.
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
6. **Commit only the relay file** (`relay(gh-1422-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Review instructions

Before supplementary source reads, paraphrase the embedded plan under **What this proposes**,
**How the existing system works, per this document**, and **What it is not** (2–5 sentences
for the first two). Record input boundary; label inference or missing scope. Then perform
source-backed validation against AGENTS.md, ROUTER.md, SOP.md and the cited requirements.
Assess completeness, narrow scope, preserved semantics, falsifiable controls, rating evidence,
and rollback. Documentation-only envelope: no new machinery or enterprise requirements.
Write only this relay thread. Do not execute suites. Do not change implementation or plan.

## Setup
- Artifact under review: **GH-1422-AGENTS-SIZE.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-11-11

### Artifact — GH-1422-AGENTS-SIZE.md
```
---
title: Trim AGENTS.md below 32 KiB
status: Planning
created: 2026-11-11
updated: 2026-11-11
owner: Codex
goal: Keep all operative repository instructions available within Codex's default loading budget.
gh_issue: 1422
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1422
doc_type: bugfix
effort: 2
complexity: 2
risk: 2
phases: 1
---

# GH-1422 — AGENTS size

## Status

| What was just completed | What's next |
|---|---|
| Intake, isolated clone, recon and rating registered | Independent Codex plan QA before implementation |

## Requirements and observed baseline

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1422.
Base: `966290ddd8b69fcfd49a9df5e123b118befcd6e1` (`origin/development`).
`AGENTS.md` is 42,768 UTF-8 bytes. Codex automatically includes project instructions
under a combined default 32,768-byte budget, not a separate budget per nested file.
Source: https://learn.chatgpt.com/docs/agent-configuration/agents-md.
Consumer path: Codex project discovery → root AGENTS → ROUTER startup → canonical
SOP / PDDA / safety / relay documents. No runtime code change is required.

`AGENTS.md` already says it must not restate routing or roadmap contracts. Its
largest repetition is incident narrative and procedural details whose owners are
ROUTER, SOP and WORKTREE-SAFETY. Retain operative requirements in concise form;
use existing canonical links for the explanations already owned there. Preserve
existing headings where external references may depend on them. No new instruction
subsystem, script, nested AGENTS file, or configuration override is needed.

Prior-art recon for `AGENTS.md 32 KiB` found #1422, unrelated #32, no open or recently
merged matching PR, and no existing fix candidate. No prior #1422 capture or row.
Primary checkout preserved; task clone/branch slug is `agents-size`.

## Preflight bet and scope

Outcome: the root behavioral contract is completely available at default discovery.
Smallest bet: compress AGENTS in place to at most 28,000 bytes, retaining all operative
rules, exceptions, authority boundaries and exact commands necessary to apply them.
Keep critical safety and explicit required-read routing near the top. Retain existing
links to incident records; do not move unique requirements into unconditionally unread
prose. Prefer links to existing owners over copying long procedures.
Simpler alternative rejected: raising project_doc_max_bytes only fixes configured users
and fails the requested artifact-size target. Splitting into nested AGENTS still shares
the same cumulative budget. Wholesale deletion risks silently weakening the contract.
Reversibility: Easy — revert the documentation commit; no runtime/state migration.
Blast radius: agent interpretation of root instructions; canonical destinations stay intact.
Non-goals: policy changes, harness/runtime edits, new tests/gates, config changes, merge or deploy.

## Ordered implementation and verification

1. After plan approval and accepted-start, compress AGENTS section by section. Keep a
   mapping from every original section/rail to its retained text or existing canonical
   owner in the verification receipt. Preserve discoverability and meaningful anchors.
2. Verify byte count `0 < size <= 28000 < 32768`; witness red on the 42,768-byte base
   and on empty input. Record UTF-8 byte counts, content hashes and commands in
   `TESTS-RESULTS/2026-11-11+GH-1422/` with provenance.jsonl.
3. Read from ROUTER → AGENTS as the main smoke path; inventory applicable nested
   AGENTS/override/fallback instructions as the adjacent path. Calculate applicable
   root-to-directory totals and report any remaining overflow honestly. Validate
   changed Markdown link targets and anchors. Do not claim links auto-load their targets.
4. Run the existing classifier and applicable gate on the actual changed paths.
   No new tests, suites, registry entries, scanners or gate machinery. Manual byte/link
   probes are task evidence only; mutation-heavy suites, if required, run in a separate
   disposable full clone with identity checks. Retain evidence and final QA in the PR.
5. Independent final Codex review must perform an omission-diff: identify every original
   operative requirement without an equivalent retained requirement or reachable mandatory
   canonical instruction. Resolve material losses before publication. Publish to development,
   close out #1422 with truthful QA/gate state, and safely retire fully published checkouts.

## Acceptance

- [ ] Root file is nonempty and below 32,768 bytes, with target <=28,000 for headroom.
- [ ] Before/after counts and a section/requirement destination mapping are retained.
- [ ] Critical safety, authority, routing and existing operative semantics are preserved.
- [ ] Links resolve; applicable instruction-chain totals are measured and limitations stated.
- [ ] Existing docs gate and independent plan/final QA pass; no new tests or gate machinery.

## PRS rationale (2026-11-11)

Persisted/read back: rated 75/65/50/80; no operator override.
Priority 75: requested now; default loading omits repository rules across Codex sessions.
Severity 65: credible loss of workflow/safety guidance, but no attributed data-loss incident.
Appeal 50: neutral; operator supplied no numeric preference.
Cheapness 80: bounded documentation rewrite and semantic review, no runtime migration.
Recurrence windows: 2026-10-29–11-11 versus 2026-10-15–28. Narrow prior-art search
found no separate matching incident; coverage does not establish incident counts or trend.
Trend unknown; this is one demonstrated oversized artifact, not proven increasing incidents.

## Review and verification

Plan QA pending. Final QA pending. Gates pending. No implementation yet.

## Lessons Learned (For Future Agents)

Pending evidence; do not infer reliability from byte count alone.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1 · codex

VERDICT: PASS
Basis: Approve the embedded plan for implementation, not the eventual rewrite or publication. The five Acceptance bullets are the review criteria because Setup's Definition of Done is still a placeholder. No material plan defect or pre-existing defect was found in the whole embedded artifact.
swept file: yes

**What this proposes**
Compress the root AGENTS.md in place to <=28,000 UTF-8 bytes while preserving operative policy, exceptions, commands and meaningful anchors. Retain a requirement/destination map and perform independent final omission QA before publication.

**How the existing system works, per this document**
Codex discovers project instructions under a combined default 32,768-byte budget; the root file currently exceeds it. AGENTS routes agents through ROUTER to canonical SOP, PDDA and safety documents; links require explicit reading rather than automatic loading. Input boundary: the embedded planning artifact and current local policy sources, not an implemented rewrite.

**What it is not**
No policy redesign, configuration override, nested instruction subsystem, runtime edit, new suite or gate machinery, merge or deployment. Inference: publication in step 5 means a PR targeting development, consistent with SOP §4; it does not grant merge authority.

- [Pass] Baseline and central premise are supported. Probe `wc -c AGENTS.md` exited 0 with `42768 AGENTS.md`. Official documentation at https://learn.chatgpt.com/docs/agent-configuration/agents-md states that files stop being added at the combined `project_doc_max_bytes` limit, default 32 KiB. The plan's “Splitting into nested AGENTS still shares the same cumulative budget” therefore addresses the actual constraint. Retain this source and before/after measurements in the implementation receipt.
- [Pass] Preservation has an explicit falsifier beyond byte count: step 5 requires identifying “every original operative requirement without an equivalent retained requirement or reachable mandatory canonical instruction” and resolving material losses. Step 1 supplies the original-section mapping; step 3 says “Do not claim links auto-load their targets.” Together these address authority, exceptions, routing and late-file rails without silently delegating unique requirements to optional reading. Apply those checks to every original rail during final QA.
- [Pass] Verification is proportionate and bounded: step 2 requires `0 < size <= 28000 < 32768`, red controls for the oversized base and empty input, hashes and provenance; step 4 prohibits new machinery and places mutation-heavy suites in a disposable full clone with identity checks. This matches AGENTS.md §6, its “No new tests” rail, WORKTREE-SAFETY.md §12 and TESTS-RESULTS/README.md's retained-evidence purpose. Execute the planned checks against the final candidate; no implementation verification is claimed here.
- [Unverified — no citation] Scope and rollback are explicit: “Reversibility: Easy — revert the documentation commit; no runtime/state migration” and “Non-goals: policy changes, harness/runtime edits, new tests/gates, config changes, merge or deploy.” This follows GUIDING-PRINCIPLES.md “The North Star” and SOP.md §4's task-branch/PR-to-development workflow. Keep the rewrite confined to compression and necessary task evidence.
- [Unverified — no citation] Rating rationale distinguishes severity from demonstrated harm and avoids a fabricated trend: “no attributed data-loss incident” and “Trend unknown.” The numeric rating is presented as a prioritization judgment, not empirical impact. No rating change is requested.
- [Unverified — needs clone run] Existing gate results, changed-link validity, final byte size, full instruction-chain totals and omission equivalence remain pending as the plan explicitly states. No suites, executable fixtures or git commands were run in this reviewer turn. The public issue fetch failed with “Cache miss”; issue state, prior-art search and persisted rating read-back were not independently verified, so this approval does not attest those historical claims.  [Unverified — no citation]

relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-11-11T22:08:21Z
task: RELAY-gh1422-plan
reviewer: codex
status: Approved
reviewed-head: 5b6db4820f275ba293dc245f4e2413a114ee5c8e
added-range: 12204+4246
added-sha256: 4c96c483ee84f3caa4646f8343860be11452cb48ce4b81d70ce941d475bc0e00
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
