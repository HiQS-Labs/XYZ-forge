# RELAY · Phase-1 soundness & Phase-2 readiness (relay-automation)
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 5

## Setup
- Artifact under review: the **Phase-1 slice Run 4 produced** — `src/claim.js`, `src/take.js`, `test/handoff-exclusive.sh` (the handoff-exclusive rule) + `relay-automation/runner.sh`, `relay-automation/watchdog.sh` (skeletons). Canonical plan: `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md`.
- Definition of Done: Reviewer confirms (a) the handoff-exclusive rule is **correct and complete** (rejects `claim`/`take` of a task whose `handoff_to` is set and ≠ caller, with **zero events** on rejection, no bypass/edge-case gaps), **and** (b) the `watchdog.sh` skeleton is a **sound base for the next build = proposal Phase 2 (Liveness & self-healing)** — or names exactly what's missing/wrong.
- Producer: **Claude-A (maintainer, window A)**   ·   Reviewer: **Gemini (independent model, window G)**   <!-- IDENTITY LOCK: Producer=Claude-A, Reviewer=Gemini. Each holds ONE role for the whole relay; stamp your label in every `Round N · <Role> · <agent>` header. A nudge for the other label is not yours (ground rule 2). -->
- Handoff: manual nudge   <!-- Reviewer is a non-Claude model → manual nudge, no hands-free poll -->
- Started: 2026-06-14

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two agents are different models (Claude + Gemini) and never share memory.
2. **Wrong-window guard — take a turn only if ALL hold, else STOP and write nothing:** (a) `NEXT` names the role you were asked to take; (b) **you are the agent bound to that role** — Setup names it (`Claude-A`=Producer, `Gemini`=Reviewer) and prior `Round N · <Role> · <agent>` headers show that role authored by *you*; (c) you have **not** authored the *other* role's turns; (d) the most recent turn block is **not** your own role. On any mismatch reply `STOP — wrong window: <which check failed>. Nudge the <correct role> window.`
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top. (Only exception: right after committing, fill the hash into your own just-written turn's `Commit:` line.)
4. Stay tight. Findings are bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings with concrete suggested fixes. The Producer decides each (with the operator) and implements — logging a disposition (Implemented / Modified / Declined + reason) for every one.
6. Grade every finding: `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved** — to get proposals actioned in-thread set `Changes requested`, not `Approved`. If the max `ROUND` ends without `Approved`, set `STATUS: Escalated` and hand back to the human.
8. End your turn by committing it: `relay(phase2-readiness): <role> r<N>`, then fill the hash into your `Commit:` line. If your turn touched no tracked files, write `Commit: none (comments only)`.
9. **One window at a time, clean tree at every handoff.** Both agents share one working tree; the `NEXT` pointer is honor-system, not a lock. Never start while the other window may be editing; never flip `NEXT` with uncommitted changes — commit or stash first.

## Roles
- **Producer (Claude-A)** — maintainer of the artifact: presents it, decides+implements proposals (with the operator), updates.
- **Reviewer (Gemini)** — reviews against the DoD, proposes graded findings with suggested fixes, sets a verdict. Never edits the artifact.

---
## Log

### Round 1 · Producer · Claude-A · 2026-06-14 15:40 PDT
**Subject choice:** reviewing the **Phase-1 implementation + Phase-2 base soundness** (not a plan doc) — this gates the real next increment. Per the canonical proposal, Phase 1 (handoff-exclusive rule) is shipped and the next build is **Phase 2 — Liveness & self-healing (the watchdog)**. I want independent eyes on whether the shipped rule is airtight and whether `watchdog.sh` is a sound base before we build on it.

**What shipped (Run 4) & where to look:**
- **Handoff-exclusive rule, two verbs, two mechanisms:**
  - `src/claim.js:37-38` — *explicit rejection*: `if (t && t.handoff_to && t.handoff_to !== agent) return { won:false, unavailable:'reserved for another agent' }` — returns **before** any `appendEvent` ⇒ zero events.
  - `src/take.js:41` — *silent exclusion*: `if (t.handoff_to && t.handoff_to !== agent) continue;` drops the task from the candidate pool (and `:45-49` prioritizes handoffs **to** me).
  - `test/handoff-exclusive.sh` (38 lines) asserts refusal **and** `INITIAL_EVENTS == FINAL_EVENTS`. `validate.sh` = 13/13.
- **Skeletons (parse clean, `bash -n` OK):**
  - `relay-automation/runner.sh` — claimability guard (claim/resume/poll), artifact-scoped clean-tree gate (`git diff --quiet -- <artifacts>`), `extract_verdict` greps `VERDICT: PASS|FAIL|PARKED`, round cap. Real Phase-3/4 territory.
  - `relay-automation/watchdog.sh` — `collect_analysis` (`tick analyze` or file) → `find_parked_lines` (`grep -Ei '\bparked\b'`) → `escalate_to_human` (stub) → `reap_task_stub` behind `--allow-reap`.

**Review this (against the DoD):**
1. **Rule correctness/completeness** — is exclusivity airtight across *both* verbs? Probe: (a) is the `claim.js` rejection truly zero-event (no append on any path)? (b) does the check ordering (status/owner checks at `claim.js:25-33` before the handoff check at `:37`) leave any bypass? (c) positive case — `handoff_to === agent` correctly *allowed* by both verbs? (d) any interaction with `release`/`scope` that could strand or leak a reservation?
2. **Two-mechanism consistency** — claim *rejects* but take *silently excludes*. Is that divergence acceptable, or should take also surface a reason? Any observable-behavior gap (e.g., a caller that can't tell "reserved" from "no work")?
3. **Watchdog Phase-2 base** — proposal Phase 2 requires: reuse `tick analyze`'s existing parked detector (no second detector), escalate-to-human, auto-reap behind authority. Is `find_parked_lines`' bare `grep '\bparked\b'` robust, or should it parse `analyze`'s specific parked-suspects line (false-positive risk on prose)? Are the escalate/reap seams sound to build the real policy on?
4. **Anything that should block building Phase 2** on this base.

**Open questions:** (a) For Phase 2's auto-reap authority model — is a CLI `--allow-reap` flag enough, or does it need a recorded authority decision before build? (b) Should the runner's `VERDICT:` contract be specified now (it's shared by Phase 3 and the /relay-skill automation use case)?
**Commit:** 7fedc93

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
