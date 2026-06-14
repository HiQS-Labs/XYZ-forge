# RELAY · README local-transport alignment
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

## Setup
- Artifact under review: README.md
- Definition of Done: README accurately describes the CURRENT runtime — local transport (no git push/fetch per verb), `O_EXCL` lock, `--agent` authoritative, `./bin/tick` paths, the full live verb set (incl. `take`/`ping`/`info`), and 12-test suite — with no stale git-transport / auto-push / separate-clones claims. No false claims; keep the user's new title/intro.
- Producer: Claude (window A)   ·   Reviewer: <window B — Claude or, for independent eyes, Codex/Gemini>
- Handoff: manual nudge   <!-- or "hands-free poll (all-Claude)" — see skill -->
- Started: 2026-06-14

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two agents may be different tools (e.g. Claude and Codex) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top. (Only exception: right after committing, fill the hash into your own just-written turn's `Commit:` line.)
4. Stay tight. Requests and findings are bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings, each with a concrete suggested fix where possible. The Producer (the original author), with the operator, decides each proposal and implements the approved ones — logging a disposition (Implemented / Modified / Declined + reason) for every one.
6. Grade every finding:  `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved** — so to get proposals actioned in-thread the Reviewer sets `Changes requested`, not `Approved`; a `[Nit]` left on an `Approved` verdict is the author's discretion, handled out-of-band. If the max `ROUND` (3) ends without `Approved`, set `STATUS: Escalated` and hand back to the human.
8. End your turn by committing it: `relay(readme): <role> r<N>`, then fill the hash into your `Commit:` line — so the other agent can `git diff` exactly what changed. If your turn touched no tracked files (comments-only, or this log is gitignored), write `Commit: none (comments only)`.
9. **One window at a time, clean tree at every handoff.** Both agents share one working tree; the `NEXT` pointer is honor-system, not a lock. Never start a turn while the other window may still be editing, and never flip `NEXT` with uncommitted changes left in the tree — commit or stash first, so the next agent never inherits half-finished state.

## Roles
- **Producer** — the only writer of the artifact: builds it, requests review, decides and implements proposals (with the operator), updates.
- **Reviewer** — reviews against the DoD, proposes graded findings with suggested fixes, sets a verdict. Never edits the artifact.

---
## Log

### Round 1 · Producer · 2026-06-14
**Context:** README still described the pre-Run-2 git-transport model. Verified against the runtime before editing: `claim.js:7` + `scope.js:6` ("Run 2: git transport removed. Every verb is now a pure local event append"); `commitAndPush` in `src/sync.js` is **dead code** (no caller); `auto-sync.sh` was repurposed to test the `O_EXCL` lock, not pushing; `_setup.sh` shares one `TICK_REPO_ROOT` (`tick_b` aliases `tick_a`) and keeps the bare remote only for git-identity ops; binary is `./bin/tick`; `validate.sh` runs 12 tests; `take`/`ping`/`info` exist (`bin/tick`).

**Did (10 edit regions):**
- **Status:** "7 mechanical acceptance criteria" → "12 acceptance tests."
- **What it is:** rewrote the transport sentence — local append to shared `.tick/events/`, no push/fetch, `O_EXCL` lock mutex, git used only for `analyze` attribution.
- **Quickstart:** `./experiments/coordination-layer/bin/tick` → `./bin/tick` (×3).
- **Verb table:** dropped the "Pushes?" column (nothing pushes); added `take`, `ping`, `info`; fixed `claim` (lock mutex, no "deterministic tie-breaker") and `next` (read-only, not "fetches first"). Signatures taken from `bin/tick`.
- **Multi-agent setup:** retitled "separate clones" → "one shared event log"; replaced the clone-per-agent + push rationale with one shared `TICK_REPO_ROOT`; `--agent` authoritative (cross-check removed Run 2); added a **git-identity-in-shared-tree caveat** and a historical note on the old transport.
- **Integration prompt:** path → `bin/tick`; dropped "in your worktree"; made `tick take` the preferred grab (manual `next`+`claim` kept as fallback); replaced the "auto-commit and push / abort on push fail" Critical block with a local-only note.
- **Multi-agent flow:** dropped `&& git push` from the seed; "in its worktree" → shared `TICK_REPO_ROOT`.
- **Constraints:** replaced "Push retry once (fetch+rebase+retry)" with "Lock-serialised claims (`.tick/locks/`)"; "Same branch only" → "Shared event log."
- **Tests:** reworded "bare remote + two clones … end-to-end" to shared-local-root reality (remote retained only for git-identity assertions).
- **Auditing:** "per worktree" → "to your agent ID; see the shared-tree caveat."

**Review this (highest-uncertainty first):**
1. **Multi-agent setup section** — is the "one shared `TICK_REPO_ROOT`, optionally a per-agent checkout pointing at it" story accurate to how Runs 2/3 actually ran? This is the part I'm least sure of; check against RECAP.md / `_setup.sh`.
2. **`tick take` description** — I claim it "claims the task with the paths it was seeded with." Verify against `src/take.js` that take derives paths from the task.created event (I inferred this; didn't read take.js's claim call line-by-line).
3. **Integration-prompt `package.json` block** (left unchanged) — it still says "package.json is shared and outside every task's scope." That's generic advice for the *target* repo agents work on, not a claim about THIS repo (which has no root manifest). Leave as-is, or scope it? Your call.
4. Any *remaining* push/fetch/worktree/clone reference I missed, and whether the verb-table signatures match `bin/tick` exactly.

**Open questions:**
- Should the dead `commitAndPush` in `src/sync.js` be mentioned/removed, or is that out of scope for a README pass? (I left code untouched — artifact is README.md.)

**Commit:** 939eafe

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
