# RELAY · PDDA Agent (Roadmap Steward sketch) — design review
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (see Setup) **and** the last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup (READ the real files listed; cite `file:line`):
   - **Reviewer:** review vs the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete proposed fix → set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit the artifact; you only append findings to THIS relay file.
   - **Producer:** for every open finding log a disposition (Implemented / Modified / Declined + why), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line (`<!-- ↓↓↓ NEXT TURN ... -->`). Never edit earlier turns. Header it `### Round N · <Role> · <your-label> · <date time>`; a Reviewer block carries `**Verdict:**` + `**Findings & proposals:**` (graded bullets) + `**Commit:**`.
5. **Update the header:** flip `NEXT` to the other role; set `STATUS` (`Approved` closes the relay — Reviewer only; else leave `Open`).
6. **Commit only the files you touched** (this relay log): `git commit -m "relay(pdda-agent-review): <your-label> r<N>"`, then put the short hash in your block's `Commit:` line. Do **not** push.
7. **Stop.** Tell the operator your one-line result.

## Setup
- Artifact under review — Noel's **PDDA Agent — Roadmap Steward sketch**, a design doc (not code) for a bounded Claude-based steward over `ROADMAP.md` + PDDA. READ both:
  - **The artifact:** `PROJECT/PDDA-AGENT.md` (the sketch: goal, decision, scope, reversibility/blast-radius reads, the recommended operating model, tool surface, approval gates, a 4-phase rollout, open questions, sources).
  - **Context it sits on:** `PROJECT/PDDA.md` (the PDDA contract the agent is layered over — lifecycle folders, required frontmatter, the exact two-column `## Status` table, QA-gate-per-phase requirement, hardcoded-path ban, the `ROADMAP.md` pointer-only contract).
- Definition of Done — judge the sketch on:
  - **(a) Boundary clarity (its own Phase-0 QA gate):** can a reader tell *exactly* which actions are advisory vs approval-gated? Is the reversibility vocabulary (`Easy` / `Costly` / `One-way door`) applied consistently and correctly to each action it gates?
  - **(b) Internal + cross-doc consistency:** does the sketch contradict itself or `PDDA.md`? (e.g. the steward "proposing `ROADMAP.md` updates" vs `PDDA.md`'s pointer-only ROADMAP contract; the `gh_issue` open question duplicated across both docs; any tool in the surface that the approval-gate section doesn't account for.)
  - **(c) Factual accuracy of the Claude-specific claims:** the **Claude Agent SDK** claims — `query()` (one-off) vs `ClaudeSDKClient` (stateful) split, the "built-in permissions/hooks/sessions/cost-tracking/observability", and the **auth constraint** ("API-key / cloud-provider auth for SDK-based products, not `claude.ai` login"). Flag anything inaccurate, overstated, or that can't be grounded in the listed Sources. Note: these are about the **Agent SDK** (a distinct product from the Claude **API**) — check the claim is attributed to the right surface.
  - **(d) Automation-readiness / plan-rot resistance:** does the doc obey the PDDA contract it advocates (minimum frontmatter; the EXACT `## Status` header; a real, *observable* QA gate after each of the 4 phases; repo-relative paths only)? Are the 5 open questions truly blocking a stable v1, or safely deferrable — and is any of them load-bearing enough that shipping Phase 1 without it would drift?
  - **(e) Right-sizing:** is the 7-verb tool surface + 4-phase rollout proportionate to a *first* version, or is it premature scaffolding (YAGNI) for capability that advisory-mode doesn't need yet?
- Producer: Noel (author of the steward idea) — represented here by the orchestrator (claude-a)   ·   Reviewer: **Codex**
- Handoff: cli-driven (Codex)   <!-- driven by relay-automation/relay-drive.sh + codex-turn.sh -->
- Started: 2026-06-20

## Ground rules
1. This file is the single source of truth. The agents are different tools (Claude and Codex) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`/`STATUS` at the top.
4. Stay tight. Findings are graded bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings with concrete suggested fixes; it appends them to THIS file only.
6. Grade every finding: `[Blocker]` must fix · `[Should]` strong rec · `[Nit]` optional · `[Pass]` checked + sound.
7. The Reviewer posts a Verdict. Relay ends on **Approved**; else the orchestrator carries the findings back to the Producer.
8. End your turn by committing it: `relay(pdda-agent-review): <role> r<N>`. No push.
9. **One actor at a time.** The `PDDA-AGENT-TURN` tick token is the lock.
10. **Evidence:** this is a *design* doc — prefer `textual` evidence with `file:line` citations into `PROJECT/PDDA-AGENT.md` / `PROJECT/PDDA.md`. Where a claim about the Agent SDK is checkable against the listed Sources, say so.

## Roles
- **Producer** — Noel (author of the steward idea), applied here by the orchestrator (claude-a).
- **Reviewer** — Codex. Reviews against the DoD, proposes graded findings, sets a verdict. Never edits the artifact.

---
## Log

### Round 1 · Producer · claude-a (on Noel's behalf) · 2026-06-20
**Did:** Reviewed and lightly edited the steward sketch `PROJECT/PDDA-AGENT.md` (Codex's original draft):
- Renamed the file `PDAA-AGENT.md` → `PDDA-AGENT.md` (the original filename transposed the acronym; everything else — the title, `PROJECT/PDDA.md`, and `PROJECT/PDDA-ACTIVITY.jsonl` — uses **PDDA**).
- Refreshed the stale `## Status` table: its "What's next" had said to go build the contract (tool surface, approval gates, phased rollout) that the **body already contains**, so I rewrote both cells to reflect the real state — sketch drafted; next action is to resolve the 5 open questions (esp. the priority-scoring signals) and get this peer review.
Otherwise the doc is Codex's: a bounded `Roadmap Steward` agent that **proposes** roadmap/bug-fix priorities but is **not** the sole authority — advisory-first, scoped auto-edits later, approval gates on consequential calls.
**Review this:** Apply the DoD in Setup. I'm most interested in: (a) is the advisory-vs-approval-gated boundary actually unambiguous? (b) does "propose `ROADMAP.md` updates" sit cleanly with `PDDA.md`'s pointer-only ROADMAP contract, or do they fight? (c) are the **Claude Agent SDK** claims accurate and attributed to the right product (Agent SDK ≠ the Claude API)? (d) which of the 5 open questions, if any, actually blocks a stable v1?
**Verification:** N/A from the producer side — this is a review request. The doc follows the PDDA contract by inspection (frontmatter, exact `## Status` table, a QA gate after each of the 4 phases, repo-relative paths); confirm or refute that.
**Open questions:** The 5 at the bottom of `PROJECT/PDDA-AGENT.md` (gh_issue requiredness; write-to-ROADMAP vs diff/PR-only; which signals control priority; whether the steward may move docs between `2-WORKING`/`4-MISC`; local tool vs broader SDK service) — flag which actually block v1.
**Commit:** (this relay scaffold; the artifact is Noel's working tree, reviewed on disk)

### Round 1 · Reviewer · codex · 2026-06-20 23:08 PDT
**Verdict:** Changes requested
**Findings & proposals:**
- [Blocker] The action boundary is not yet exact enough for the doc's own Phase 0 gate. The sketch introduces effectful verbs (`propose_roadmap_update`, `propose_phase_promotion`, `mark_bugfix_urgent`) but the approval section collapses them into broad buckets, so a reader still cannot tell which verbs are advisory-only, which may touch canonical docs, and which require human approval before any write. `PROJECT/PDDA-AGENT.md:122`, `PROJECT/PDDA-AGENT.md:137`, `PROJECT/PDDA-AGENT.md:196`. Proposed fix: replace that prose with a verb-by-verb table covering verb, allowed target, output shape (recommendation vs diff vs applied edit), reversibility, and approval gate.
- [Should] `ROADMAP.md` handling is underspecified against the pointer-only PDDA contract. The sketch says the steward will propose `ROADMAP.md` updates and later append roadmap pointers, while PDDA says `ROADMAP.md` is a pointer file and should usually not hold detailed plan content. `PROJECT/PDDA-AGENT.md:68`, `PROJECT/PDDA-AGENT.md:163`, `PROJECT/PDDA.md:193`. Proposed fix: hard-code that every roadmap action is pointer-only and diff/PR-only in v1; move "direct write to ROADMAP.md" out of the v1 path unless a later phase explicitly reopens it.
- [Should] The steward open question about moving docs between `PROJECT/2-WORKING` and `PROJECT/4-MISC` conflicts with PDDA's existing deterministic boundary. PDDA already makes stale-doc moves a deterministic script responsibility and says the LLM layer should not silently override deterministic lints. `PROJECT/PDDA-AGENT.md:243`, `PROJECT/PDDA.md:124`, `PROJECT/PDDA.md:185`. Proposed fix: state that lifecycle-folder moves remain deterministic-only; the steward may recommend a move, but not perform or approve it.
- [Should] The v1 surface is larger than the advisory-only rollout needs. Phase 1 promises recommendations plus proposed diffs, but the listed verbs already encode Phase 3 policy actions (`propose_phase_promotion`, `mark_bugfix_urgent`) before the ranking inputs are defined. `PROJECT/PDDA-AGENT.md:122`, `PROJECT/PDDA-AGENT.md:191`, `PROJECT/PDDA-AGENT.md:230`. Proposed fix: split the tool surface by phase: Phase 1 read-only plus emit-recommendation/diff, then introduce promotion and urgency verbs only in the approval-gated phase.
- [Should] Open question 1 is duplicated policy, not steward-specific policy. `gh_issue` optionality is already an open question in `PROJECT/PDDA.md`, so restating it here creates two places to resolve the same contract. `PROJECT/PDDA-AGENT.md:240`, `PROJECT/PDDA.md:301`. Proposed fix: convert this item into a dependency on the PDDA decision instead of a second local open question.
- [Pass] The Claude Agent SDK claims I checked are directionally accurate and attributed to the right surface: the listed Agent SDK overview supports "same tool loop/context management as Claude Code," built-in permissions/hooks/sessions/cost tracking/observability, and API-key or cloud-provider auth rather than `claude.ai` login; the Python reference supports the `query()` vs `ClaudeSDKClient` split. Suggested tweak only: cite the Agent SDK pages as the authority and treat the platform tool-use page as background, not proof of SDK behavior.
**Commit:** handled by harness per turn instructions

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
