# RELAY · codex-turn.sh safety review (Claude ↔ Gemini, manual)
<!-- Single source of truth. Read this WHOLE file before acting. Manual nudge (Gemini can't self-poll). -->

NEXT: Producer
STATUS: Open
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, Gemini)
The operator just said "take your turn on this file." Everything you need is **in this file**.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (Setup: `Producer=Claude-A`, `Reviewer=Gemini`) **and** the last Log block isn't already yours. If not → STOP, reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact in Setup (read the real file; cite `file:line`):
   - **Reviewer (Gemini):** review vs the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete proposed fix → set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
   - **Producer (Claude-A):** dispose each finding (Implemented/Modified/Declined+why), edit `codex-turn.sh`, summarize.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Header it `### Round N · <Role> · <you> · <date time>`.
5. **Update the header:** flip `NEXT` to the other role; set `STATUS` (`Approved` closes; else `Open`).
6. **Commit only this relay file** (you're not editing the artifact): `git commit -m "relay(codex-turn-review): Gemini r1"`, fill the hash into your Commit line, `git commit --amend --no-edit`, then `git push origin main`.
7. **Stop.** Tell the operator your one-line verdict.

## Setup
- Artifact under review: `relay-automation/codex-turn.sh` — the Option-A safety shim that drives a headless Codex relay turn (`codex exec`) behind a path-allowlist.
- Definition of Done: the shim is a **sound safety boundary for an unattended agent** — its path-allowlist genuinely contains off-lane edits, dispatch-gating is correct, it never pushes, and it has no bypass — or the Reviewer names the holes.
- Producer: **Claude-A**   ·   Reviewer: **Gemini** (third model — most independent eyes yet)
- Handoff: **manual nudge** (Gemini can't self-poll; no headless Gemini CLI wired).
- Started: 2026-06-15

## Ground rules
1. Single source of truth; different models, no shared memory.
2. Take a turn only if `NEXT` names your role and you're the bound agent; else STOP.
3. One block at the bottom, above the marker. Never edit earlier turns.
4. Bullets, not essays. Grade every finding `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`.
5. Reviewer proposes; never edits the artifact. Producer disposes + edits.
6. Commit your turn (`relay(codex-turn-review): <role> r<N>`), fill the hash.
7. Clean tree at handoff; one window at a time.

## Roles
- **Producer (Claude-A)** — author of `codex-turn.sh`; disposes findings + edits.
- **Reviewer (Gemini)** — reviews the safety boundary against the code; graded findings + verdict.

---
## Log

### Round 1 · Producer · Claude-A · 2026-06-15 16:00 PDT
**Review `relay-automation/codex-turn.sh`** — the shim that lets a headless Codex turn (`codex exec`) take a relay turn unattended. It's the newest, most safety-critical code (an autonomous agent that commits), so I want a third model's eyes on the containment.
**What it does:** dispatches only when `RELAY_AGENT == CODEX_AGENT` (else no-op); runs `codex exec "<turn prompt>" < /dev/null`; then enforces a **path allowlist** (relay file + `ALLOW_PATHS`) on the tracked tree — reverting any off-lane change and **failing (exit 6)**; stages only allowlisted paths and **commits with NO push**.
**Scrutinize (likely soft spots):**
1. **Allowlist completeness** — `git status --porcelain` parsing via `${line:3}`: does it handle **renames** (`R old -> new`), quoted paths (spaces/unicode → `"..."`), and the staged/unstaged columns correctly? Any changed path that could slip past the check?
2. **Revert safety** — tracked off-lane → `git checkout`; untracked → `rm -rf "$ROOT/${path%/}"`. Any path value where that `rm -rf` is dangerous, or fails to clean (nested dirs)?
3. **Bypass** — could Codex evade the boundary (e.g., commit inside its turn before the shim checks; edit `.git`; touch gitignored files that matter)? The prompt says "no git," but the shim must be robust if Codex ignores that.
4. **Dispatch + normalization** — `RELAY_AGENT==CODEX_AGENT` gating and the repo-relative path normalization (`${a#"$ROOT"/}`) — correct for absolute vs relative inputs?
5. **No-push** — confirm there's genuinely no push path.
**Verdict:** Approved = sound boundary, no bypass; Changes requested = a hole exists (name it + proposed fix).
**Commit:** a01eac1

### Round 1 · Reviewer · Gemini · 2026-06-15 16:30 PDT
**Findings:**
- **[Blocker] Bypass via `git commit`:** `git status` only inspects uncommitted changes. If Codex executes `git commit` during its turn, the off-lane changes are committed directly to the tree. `git status --porcelain` will show a clean tree, bypassing the check, and the shim will commit again on top.
  *Fix:* Record `BEFORE_HEAD=$(git rev-parse HEAD)` before running Codex. After Codex finishes, compare it to current `HEAD`. If they differ, execute `git reset --hard "$BEFORE_HEAD"` and fail the turn.
- **[Blocker] Path quoting bypass (spaces/special chars):** `git status --porcelain` encloses paths with spaces or special characters in double quotes (e.g., `?? "my file.txt"`). The naive `path="${line:3}"` extraction leaves the quotes intact. `in_allow` will fail to match, and the revert commands (`git checkout` and `rm -rf`) will fail to resolve the literal quoted string, leaving the off-lane files un-reverted in the working tree.
  *Fix:* Use `git status --porcelain -z` with a `while IFS= read -r -d ''` loop to parse exact, unquoted paths, handling the two-record format for renames (`R `/`C `).
- **[Should] Ignored files left modified:** `git status --porcelain` does not report modifications to ignored files (like `.env`). While the shim doesn't commit them, Codex could leave harmful modifications in the workspace.
  *Fix:* Acknowledge this limitation of the git-status boundary, or explicitly run `git clean -Xdf` (if safe for the relay state) to wipe untracked ignored files created during the turn.
- **[Pass] Allowlist normalization:** The logic `_n+=("${a#"$ROOT"/}")` correctly normalizes absolute paths (if they fall under the repo root) into relative paths that match `git status` output.
- **[Pass] No-push constraint:** The shim correctly commits with `git commit -q -m ...` without a `git push`, fulfilling the no-push requirement.

**Verdict:** Changes requested.
**Commit:** 66a256a

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
