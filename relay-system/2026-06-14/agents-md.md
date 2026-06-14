# RELAY · AGENTS.md repo-alignment fix
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Producer
STATUS: Open
ROUND: 2 / 5

## Setup
- Artifact under review: AGENTS.md
- Definition of Done: The repo-specific sections and every repo-specific reference accurately describe THIS repo (the `tick` Trinity coordination spike) — no dead links, no false claims — while the eight operating principles stay intact in substance.
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
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved** — so to get proposals actioned in-thread the Reviewer sets `Changes requested`, not `Approved`; a `[Nit]` left on an `Approved` verdict is the author's discretion, handled out-of-band. If the max `ROUND` ends without `Approved`, set `STATUS: Escalated` and hand back to the human.
8. End your turn by committing it: `relay(agents-md): <role> r<N>`, then fill the hash into your `Commit:` line — so the other agent can `git diff` exactly what changed. If your turn touched no tracked files (comments-only, or this log is gitignored), write `Commit: none (comments only)`.
9. **One window at a time, clean tree at every handoff.** Both agents share one working tree; the `NEXT` pointer is honor-system, not a lock. Never start a turn while the other window may still be editing, and never flip `NEXT` with uncommitted changes left in the tree — commit or stash first, so the next agent never inherits half-finished state.

## Roles
- **Producer** — the only writer of the artifact: builds it, requests review, decides and implements proposals (with the operator), updates.
- **Reviewer** — reviews against the DoD, proposes graded findings with suggested fixes, sets a verdict. Never edits the artifact.

---
## Log

### Round 1 · Producer · 2026-06-14
**Context:** AGENTS.md was a verbatim copy from the global `~/.claude` skills-suite repo. Principles §1–8 transfer fine, but the repo-specific sections described a different repo. Verified against the tree: no `decisions/` dir, no `record-decision/SKILL.md` (dead link), no `#authoring-conventions` anchor in README, and only one skill exists (`skill/xyz/SKILL.md`) — not a "skill suite."

**Did:**
- Rewrote `## Working in this repository` to describe the `tick` spike: `validate.sh` gate (12/12), projection-logic fragility, append-only provenance in RECAP.md, `.tick/` + verb-table sync, `package.json` out-of-scope, the single shipped skill.
- Rewrote `## The experiment, measured` to fix the "this repo" antecedent and point the revisit trigger at RECAP.md instead of "the skills it mirrors."
- Fixed the dead link in principle §7: `decisions/` + `record-decision/SKILL.md` → `RECAP.md` / `REAL-AGENT-OBSERVATIONS.md`. **This is the one edit inside §1–8** — flagged here for your ratification (the link was repo-specific and broken; the principle's substance is unchanged).

**Review this:**
- Did §7's edit preserve the principle's intent, or did pointing at RECAP.md narrow it too far? (Contest if so.)
- Are the new repo-specific claims all true and live? Spot-check: `src/project.js` exists, `validate.sh` says 12/12, the README verb table + integration snippet exist, `skill/xyz/SKILL.md` has a self-extracting test suite.
- Anything in §1–8 (besides §7) I should have left strictly verbatim but didn't — or any *other* stale cross-repo reference I missed.

**Open questions:**
- Should §7 keep a pointer to the global `record-decision` skill as the *template* (even though the records land in RECAP.md here), or is dropping it entirely correct for a repo that doesn't install it?

**Commit:** 35c2653

### Round 1 · Reviewer · Codex · 2026-06-14
**Verdict:** Changes requested

**Findings:**
- `[Should]` `AGENTS.md:52` says "`package.json` is shared and out of scope," but this tree has no repo-root `package.json`; the only one present is `sandbox-app/package.json`. Under this relay's DoD ("no false claims"), that wording is too absolute and reads like stale repo carryover. *Suggested fix:* either name `sandbox-app/package.json` explicitly if that is the intended shared file, or broaden the warning to "dependency manifests / lockfiles" so it matches the actual tree.
- `[Should]` `AGENTS.md:49` mixes the removed git-sync model with the current shared-local transport: "auto-push/local-transport contract." The runtime is explicit that git transport was removed in Run 2 (`src/claim.js`, `src/identity.js`, `src/scope.js`, `src/next.js`), so keeping `auto-push` in a repo-specific warning reintroduces a false claim about the live system. *Suggested fix:* rewrite that clause to describe only the shared-local `.tick/events/` + projection contract, or explicitly mark auto-push as historical if you want the contrast.
- `[Pass]` §7's `RECAP.md` / `REAL-AGENT-OBSERVATIONS.md` pointer preserves the principle's intent and matches this repo's own instructions. I also verified the other spot-checks you asked for: `src/project.js` exists, `validate.sh` is green at 12/12, README still contains the verb table + agent-integration snippet, and `skill/xyz/SKILL.md` starts with frontmatter and still documents the self-extracting test suite.

**Answer on the open question:** dropping the global `record-decision` pointer is correct here. This repo already names its local record sinks explicitly, and reintroducing an uninstalled global skill would put the dead-cross-repo coupling back into principle §7.

**Commit:** 95a0e26

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
