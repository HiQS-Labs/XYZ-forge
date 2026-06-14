# RELAY · EXP-AUTOMATION proposal — review

NEXT: Producer
STATUS: Open
ROUND: 2 / 5

## Setup
- Artifact under review: `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md`
- Definition of Done: The plan is sound, executable, and honest — phases are correctly ordered and decoupled (dependency arrow automation → tick, never reverse), every checklist item is observable/verifiable, each QA gate is meaningful, the `tick` → relay mapping is technically correct against how `tick` actually behaves, scope/non-goals hold the right limits, and nothing is overstated vs what `tick` provides.
- Producer: Claude Code (window A)   ·   Reviewer: Gemini (window B)
- Handoff: manual nudge
- Started: 2026-06-14

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two agents may be different tools (e.g. Claude and Gemini) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top. (Only exception: right after committing, fill the hash into your own just-written turn's `Commit:` line.)
4. Stay tight. Requests and findings are bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings, each with a concrete suggested fix where possible. The Producer (the original author), with the operator, decides each proposal and implements the approved ones — logging a disposition (Implemented / Modified / Declined + reason) for every one.
6. Grade every finding:  `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved** — so to get proposals actioned in-thread the Reviewer sets `Changes requested`, not `Approved`; a `[Nit]` left on an `Approved` verdict is the author's discretion, handled out-of-band. If the max `ROUND` ends without `Approved`, set `STATUS: Escalated` and hand back to the human.
8. End your turn by committing it: `relay(automation-proposal): <role> r<N>`, then fill the hash into your `Commit:` line — so the other agent can `git diff` exactly what changed. If your turn touched no tracked files (comments-only, or this log is gitignored), write `Commit: none (comments only)`.
9. **One window at a time, clean tree at every handoff.** Both agents share one working tree; the `NEXT` pointer is honor-system, not a lock. Never start a turn while the other window may still be editing, and never flip `NEXT` with uncommitted changes left in the tree — commit or stash first, so the next agent never inherits half-finished state.

## Roles
- **Producer** — the only writer of the artifact: builds it, requests review, decides and implements proposals (with the operator), updates.
- **Reviewer** — reviews against the DoD, proposes graded findings with suggested fixes, sets a verdict. Never edits the artifact.

---
## Log

### Round 1 · Producer · 2026-06-14 13:26 PDT
**Did:** Drafted `PROPOSAL-AUTOMATION.md` — a phased plan to turn the manual relay into a self-healing, hands-free loop by reusing `tick` primitives (lock, `release --to`, `ping`, `analyze`, `reap`), modeled as a single claimable `RELAY-TURN` token. Committed at `c2d72cf`. Structure: frontmatter, status table, ToC, scope/non-goals, the turn-as-token mapping, Phases 0–5 (each with observable checklist items + a QA checklist), and a project DoD.
**Review this (against the DoD):**
1. **Technical correctness of the tick→relay mapping** — does `RELAY-TURN` as a single task actually work via `release --to` (re-open + handoff routing) for strict P↔R alternation? Is `done`/`break` the right terminal mapping? Any place the mapping assumes behavior `tick` doesn't have? (`tick` source is in `bin/tick` + `src/`.)
2. **Phase ordering & decoupling** — are the phases in the right order, and is the one-way dependency (automation → tick; protocol stays dependency-free) actually preserved across all phases?
3. **Observability of checklist items** — is every checklist item genuinely verifiable (not vague)? Flag any that can't be objectively checked done.
4. **QA gates** — is each phase's QA checklist meaningful for that phase, or boilerplate? Any phase missing a gate it needs (esp. the race/false-positive litmus tests in Phases 2 & 4)?
5. **Honesty / scope** — are the non-goals right (no push-wakeup, no verdict-judging by tick, ≤2 roles)? Anything overstated about what automation buys?
**Open questions:** (a) Is splitting Phase 2 (liveness) from Phase 3 (termination) the right cut, or should termination come first? (b) Is the round-cap + verdict-grep in the runner the right place for semantic gating, or should it be more explicit?
**Commit:** 2984d8c (relay log; proposal at c2d72cf)

### Round 1 · Reviewer · 2026-06-14 13:49 PDT
**Verdict:** Changes requested
**Findings & proposals:** (I propose; I do not edit the artifact)
- [Blocker] `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md:47-50` and `:66-69` treat enforced turn-taking and automatic stall recovery as if current `tick` already supplies them. Proposed fix: rewrite Scope + Core idea to distinguish current reuse from new guarantees. Explicitly say `release --to` is routing/handoff metadata today, while strict alternation and auto-recovery are target behaviors the runner and/or `tick` must add. Evidence: `src/claim.js:14-44` allows any agent to claim an open task; `src/next.js:39-47` and `src/take.js:44-58` only prioritize `handoff_to`.
- [Blocker] `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md:103-109` says out-of-turn action is impossible and a wrong-role window cannot claim `RELAY-TURN`, but current ownership checks only protect mutating verbs after a claim already exists. Proposed fix: make Phase 1 prove one explicit contract: either (A) runner-level discipline using `tick take`/`tick next` only, which is softer than “impossible”, or (B) a `tick` core change that rejects claims from anyone except `handoff_to` when present. Evidence: `src/scope.js:14-37` guards release/done/break/scope by current owner, not initial claim.
- [Should] `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md:125-137` understates the gap between “parked claim detectable” and “safe to auto-reap”. Proposed fix: in Phase 0 add a seam decision for auto-reap authority/policy, then in Phase 2 split acceptance into: detection works, false positives are bounded, and auto-reap is either approved as runner policy or left as human escalation. Evidence: `src/analyze.js:114-155` is an analyzer/reporting path, while `src/scope.js:65-92` labels reap as manual coordinator leverage, not current auto-recovery.
- [Should] `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md:47-50`, `:88-89`, and `:187-191` place this inside Use-case C of `skill/xyz/SKILL.md`, but current `xyz` scope excludes tightly-coupled constant handoff work. Proposed fix: make Phase 0 decide whether this broadens `xyz` on purpose or should ship as a sibling wrapper powered by `tick`. Do not present “Use-case C” as settled until that charter change is explicit. Evidence: `skill/xyz/SKILL.md:36-60` says `xyz` is for partitionable lanes and not for tightly-coupled back-and-forth handoff.
- [Should] `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md:145-148` uses `git status --porcelain` as a clean-tree gate, but in a shared checkout that is repo-global and can block handoff on unrelated dirt. Proposed fix: specify whether the gate is intentionally repo-global or artifact-scoped. If artifact-scoped, name the exact command/heuristic now so the gate is testable rather than aspirational.
- [Nit] `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md:52-56` assumes the current shared-tree local-event runtime, while other repo docs still describe an older transport model. Proposed fix: add a one-line Phase 0 preflight note naming the exact runtime generation this plan targets, so readers do not import stale README assumptions while implementing it.
**Commit:** none (comments only) — Reviewer turn only; no artifact edits

### Round 2 · Producer · 2026-06-14
**Decisions on proposals:** (user-directed)
- `[Blocker]` current-vs-target conflation in Scope/Core idea — **Implemented.** Rewrote Scope + the token-mapping table to mark every row **[today]** vs **[adds]**, and made the current limitations explicit: `claim` has no handoff check, `take` only prioritizes `handoff_to`, `analyze` reports parked claims, and `reap` is manual today.
- `[Blocker]` overstated "impossible" turn-taking before Phase 1 — **Implemented.** Phase 1 now names one explicit `tick` core change: reject `claim`/`take` when `handoff_to` is set and does not match the caller, with zero event writes on rejection. The goal and acceptance bullets now describe impossibility only *after* that change ships.
- `[Should]` parked-detection vs auto-reap authority gap — **Implemented.** Phase 0 now requires an explicit authority/policy decision, and Phase 2 is split into detection, false-positive bound, and authority-to-act gates so "detectable" no longer implies "safe to auto-reap."
- `[Should]` `xyz` charter conflict — **Implemented, plus tightened further.** The plan now treats this as a sibling artifact throughout Scope, Phase 0, Phase 5, and the DoD. I also removed `skill/xyz/SKILL.md` from `depends_on` and kept it only as a related self-extract reference pattern, so the dependency arrow stays automation → tick rather than automation → xyz.
- `[Should]` repo-global clean-tree gate — **Implemented.** Phase 3 now names the artifact-scoped command contract (`git status --porcelain -- <artifact-path> <relay-log-path>`) and its litmus: artifact dirt blocks handoff; unrelated repo dirt does not.
- `[Nit]` runtime-generation preflight — **Implemented.** Phase 0 now states this plan targets the shared-tree, local-event `.tick/events/` runtime so readers do not import stale transport assumptions from older docs.

**Additional self-consistency fix (not a separate reviewer finding):**
- Changed Phase 0's goal from "minimal/zero `tick`-core change" to "minimal `tick`-core change" because the plan now explicitly commits to one Phase 1 core rule. Leaving "zero" there would have made the phase goal falsifiably wrong.

**Answers on the open questions:**
- `(a)` Keep Phase 2 (liveness/self-healing) separate from Phase 3 (termination/verdict gating). They exercise different failure modes and different evidence: heartbeat/reap policy versus semantic stop conditions / clean-tree enforcement.
- `(b)` Keep verdict-grep + round-cap in the runner. That is the right layer because `tick` should remain coordination substrate, not parse LLM semantics or decide what "Approved" means.

**Re-review this:**
1. Scope + Core idea table for current-vs-target honesty.
2. Phase 1 for the single explicit `tick` core contract and zero-event rejection requirement.
3. Phase 5 + DoD + frontmatter for the sibling-skill/sibling-artifact story staying consistent end-to-end.

**Verification:** no tests run — doc-only turn.

**Artifact commit:** `11969db` — proposal edits referenced above already land there; this turn's commit records the relay disposition and handoff.

**Out-of-scope handoff note:** the repo is still dirty outside this artifact pair (`LICENSE.md` modified, `4X4.md` untracked), so rule 9 is not globally satisfied even though this turn's files will be committed cleanly.

**Commit:** 81e59f5

### Round 2 · Reviewer · 2026-06-14 14:05 PDT
**Verdict:** Changes requested
**Findings & proposals:** (I propose; I do not edit the artifact)
- [Blocker] `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md:191-197` makes the hands-free poll guard “I hold `RELAY-TURN` (per `tick info`) AND tree clean,” but after `tick release RELAY-TURN --to <other>` the next actor does **not** hold the token yet; it sees an **open** task routed via `handoff_to` and must wake up specifically to claim it. As written, the guard can deadlock the relay because the waiting side would never act until it already held the task. Proposed fix: rewrite Phase 4 so readiness is based on **claimability for me**, not only current ownership. For example: “`tick info RELAY-TURN` shows `handoff_to = <me>` or `claimer = <me>`, and the artifact-scoped tree is clean; if open-and-routed-to-me, claim it, else if already claimed-by-me, take the turn.” Evidence: `bin/tick`’s `info` output exposes `status`, `claimer`, and `handoff-to`; `release --to` stores routing metadata, not an automatic claim.
**Commit:** none (comments only) — Reviewer turn only; no artifact edits

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
