# RELAY · WORKTREE-SAFETY.md third-model review (GLM 5.2 via OpenRouter/Aider)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-07.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 1

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(worktree-safety-glm-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **.relay-artifacts/WORKTREE-SAFETY.md** — the read-only path that
  `relay-drive.sh --artifact-file WORKTREE-SAFETY.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: aider   ·   Producer: claude-a
- Started: 2026-07-07
- Definition of Done: This is a REVIEW-ONLY pass on WORKTREE-SAFETY.md, which was already corrected
  today via a separate Codex+agy consult. You are an INDEPENDENT third-model check. Specifically
  confirm or dispute these already-applied corrections: (1) §9 — `git branch -d`/`-D` on a branch
  checked out in another worktree FAILS (does not force-delete + leave that worktree detached), (2)
  §10 — stashes are shared globally via `refs/stash`, NOT per-worktree, (3) §4 — `git worktree move`
  shipped in Git 2.17.0, not 2.34+, (4) §6 — `git gc --prune=now`'s real risk is a concurrent-writer
  race, not "gc can't see other worktrees' refs" (modern git IS worktree-aware), (5) §11 (new) — the
  GH-177 partial-`.git`-corruption (HEAD/objects/refs/index gone, config/hooks/worktrees intact)
  detection+recovery checklist, (6) §12 (new) — footguns: dirty-worktree blocks `remove`, submodules
  block `move`, `--force` overrides safeguards, `worktree lock` for removable media, prefer
  `--porcelain` over grepping human output. Grade each as [Pass]/[Should]/[Blocker] and flag ANYTHING
  ELSE still wrong, unclear, or missing — do not just rubber-stamp the six points above.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer R1 — aider (2026-07-07)

**Verdict: Changes requested**

**Six already-applied corrections:**
- [Pass] §9 — `git branch -d`/`-D` on a worktree-occupied branch FAILS. Correctly documents that both `-d` and `-D` refuse, verified against Git 2.50.1. Real footgun (scripts treating failure as unexpected, or force-removing worktree to unblock) is well-identified.
- [Pass] §10 — Stashes are shared globally via `refs/stash`, not per-worktree. Correctly cites the three per-worktree ref namespaces (`refs/bisect`, `refs/worktree`, `refs/rewritten`) and notes `refs/stash` is not among them. Danger of popping in wrong worktree is well-explained.
- [Pass] §4 — `git worktree move` shipped in Git 2.17.0. Version is correct.
- [Pass] §6 — `git gc --prune=now` real risk is concurrent-writer race, not worktree-ref visibility. Correctly notes modern Git is worktree-aware and scans all worktrees' refs/logs before pruning. Secondary risk (stale metadata from manual `rm -rf`) is a good addition.
- [Pass] §11 — Partial `.git` corruption detection+recovery checklist. Well-structured: detection loop checks essential skeleton (`HEAD`/`objects`/`refs`/`config`), recovery steps are ordered non-destructive → destructive with verification at each step. `git init` re-run safety, `read-tree` without checkout, and scoped `checkout origin/main -- <path>` are all correct.
- [Pass] §12 — Other footguns. All five items (dirty-worktree blocks `remove`, submodules block `move`, `--force` overrides safeguards, `worktree lock` for removable media, prefer `--porcelain`) are accurate and useful.

**Additional findings:**
- [Should] §1 and §4 — `git worktree repair` is stated as "Git 2.30+" in both sections. This appears incorrect; `git worktree repair` was introduced in Git 2.24.0 (November 2019). Recommend correcting to "Git 2.24+" in both locations. (Verify exact version against Git release notes.)
- [Nit] §3 — The cleanup trap uses `git worktree remove --force`, which conflicts with §12's guidance "Never default a script to `--force`." While `--force` is reasonable in a tear-down trap (temporary worktree, exiting anyway), a brief inline comment explaining why `--force` is intentional here would resolve the apparent contradiction.
- [Nit] §3 — The unquoted `rm -rf $WORKTREE` explanation ("some shells/toolchains still mishandle that path") is vague. The primary risks (relative-path shift after `cd`, stale `.git/worktrees/` metadata) are well-covered, but the empty-variable mechanics could be stated more precisely or the hedge removed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
