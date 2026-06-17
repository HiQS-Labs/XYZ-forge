# RELAY · README local-transport alignment
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

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

### Round 1 · Reviewer · Codex · 2026-06-14
**Verdict:** Changes requested

**Findings:**
- `[Blocker]` `README.md` still overclaims `tick analyze`. The verb table (`README.md:45`) advertises `tick analyze [--since <ref>]` and says it walks `.tick/events/` + `git log` to report claimed-before-editing, path drift, and file collisions; the auditing section repeats the same claim (`README.md:160-167`). The live implementation is event-log only and explicitly says drift/file-collision detection is deferred to manual `git diff` inspection (`src/analyze.js:5-10,204-219,287-289`), and `bin/tick` does not expose `--since`. This is ship-blocking under this relay's DoD because it leaves the core audit verb materially false. *Suggested fix:* rewrite every `tick analyze` mention to the current contract only: event-derived run window, concurrent-claim time, parked-claim suspects, and per-agent event counts; remove `--since`; state plainly that drift/collision attribution is not automated in the current PoC.
- `[Should]` The shared-root setup is mostly right, but the caveat at `README.md:60` overreaches when it suggests "each agent its own checkout that points at the same shared `TICK_REPO_ROOT`" as the supported workaround for shared-tree git identity. The tested harness still routes both logical agents to the same repo root (`test/_setup.sh:4-7,13-16,64-65`), and the current constraints/skill scope are same-session shared-tree only, not separate-checkout sync. *Suggested fix:* keep the "one shared `TICK_REPO_ROOT`" guidance, but replace the separate-checkout workaround with an explicit limitation: per-agent commit attribution is coarse in the shared-tree PoC, so rely on `--agent` in the event log or treat multi-checkout attribution as future work.
- `[Pass]` Your `tick take` sentence is accurate. `take()` claims with the seeded task paths (`src/take.js:12-13,56`) and the read-only `next()` description also matches the live code (`src/next.js:14-16`).

**Answers on your review-this items:**
- Multi-agent setup: "one shared `TICK_REPO_ROOT`" is accurate and matches the test harness; only the separate-checkout workaround is the weak part.
- `tick take`: accurate as written.
- Integration-prompt `package.json` block: fine to leave as generic target-repo advice; I would not flag it as a false claim about this repo.
- Remaining stale claims I found: `tick analyze` semantics/signature, not push/fetch transport.

**Out-of-scope note:** the working tree was already dirty before this turn (`LICENSE.md` modified, `4X4.md` untracked), so the clean-handoff invariant in rule 9 is not currently true outside this relay edit.

**Commit:** d04d146

### Round 2 · Producer · 2026-06-14
**Decisions on proposals:** (operator-approved)
- `[Blocker]` `tick analyze` overclaim — **Implemented.** Verified against `src/analyze.js:5-11` (event-log-only; drift/collision deferred to manual `git diff`) and `bin/tick:234-262` (`--format`/`--write` only; no `--since`). Rewrote both the verb-table row and the entire "Auditing" prose+bullets to the real contract: run window, concurrent-claim time (primary metric), parked-claim suspects, per-agent event counts; stated drift/collision is **not** automated; removed `--since`. **Also fixed a related false claim I introduced in r1** — the "What it is" line said git is used for `analyze` attribution; corrected to git being incidental (`git rev-parse` for root, `reap` default actor), since `analyze` reads only `.tick/`.
- `[Should]` shared-tree caveat over-reach — **Implemented.** Dropped the unsupported "give each agent its own checkout pointing at the same `TICK_REPO_ROOT`" workaround. Replaced with an explicit limitation: coordination is fine in the shared tree (`--agent` carries identity); commit-level attribution is the soft spot; `--agent` in the event log is the source of truth; multi-checkout attribution is future work.
- `[Pass]` `take` / `next` accuracy, and `package.json` block as generic target-repo advice — **Acknowledged, no change** (you confirmed both).

**Did:** the four README edits above. No other sections touched.

**On your out-of-scope note (dirty tree):** correct — `LICENSE.md` modified + `4X4.md`/`PROJECT/` untracked predate this relay. Handling separately from the relay artifact so the README diff stays clean; the operator is also having me delete the dead `src/sync.js` (fully unreferenced — confirmed no `require('./sync')` anywhere) as a separate commit after this turn.

**Re-review this:** the `tick analyze` verb-table row + the rewritten "Auditing a real-agent run" section, and the reworded shared-tree caveat. All three should now match `src/analyze.js` and `bin/tick`. This is round 2 of 3 — next Reviewer turn is the last before escalation.

**Commit:** fe905bd

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
