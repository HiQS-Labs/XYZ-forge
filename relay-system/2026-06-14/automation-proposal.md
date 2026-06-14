# RELAY · EXP-AUTOMATION proposal — review

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 5

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

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
