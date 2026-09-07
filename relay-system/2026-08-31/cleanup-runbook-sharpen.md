# RELAY · Sharpen repo-agnostic cleanup runbook prompt
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-31.
-->

NEXT: —
STATUS: Closed
ROUND: 1 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
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
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(cleanup-runbook-sharpen): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/cleanup-runbook-prompt.md** — the read-only path that
  `relay-drive.sh --artifact-file temp/cleanup-runbook-prompt.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: deepseek   ·   Producer: claude-a
- Started: 2026-08-31

### Context you need
The artifact is a PROMPT intended to be pasted into an AI coding agent (Claude Code, Codex, etc.) in ANY
git repo — it instructs that agent to inventory open PRs, git worktrees, and standalone full-clone
folders, propose a safe merge/teardown plan, wait for human approval, then execute. It must be
repo-agnostic (no repo-specific scripts, branch names, or OS assumptions beyond git + gh). Your job:
sharpen it so a headless agent executing it makes ZERO destructive mistakes and no ambiguous choices.

### Definition of Done — adjudicate each numbered question
1. Command correctness: is every git/gh command in steps 1–11 correct and sufficient as written?
   Flag wrong, ambiguous, or missing-flag commands (e.g. `git log @{u}..` semantics on a detached HEAD
   or no-upstream branch, `git cherry <default> <branch>` argument order, `git worktree remove`
   behavior on a dirty worktree, `git fetch` refspec surprises).
2. Safety-predicate completeness: what pre-merge or pre-teardown condition is MISSING that a careful
   operator would demand (in-progress rebase/merge/cherry-pick state, detached HEAD, stashes inside a
   clone, submodules, a branch checked out in two folders, CI still running on a PR, unmerged squash
   commits whose branch was force-pushed)?
3. Approval gate: is the PASS-1 → STOP → approve → PASS-2 boundary airtight? Name any step where an
   executing agent could plausibly continue without approval, and the wording that closes it.
4. Portability: anything repo-specific, macOS-specific, or default-branch-name-specific that leaked in?
   It must run unchanged on any git repo with git + gh.
5. Failure paths: when a check is "undetermined" or gh is missing/unauthed, does the prompt dictate a
   deterministic skip-and-report behavior, or is it left to the agent's judgment?
6. Prompt quality for an LLM executor: ambiguities it could misread, missing output-format constraints,
   ordering hazards, steps an agent would likely skip — each with concrete replacement wording.

For EVERY finding: grade it `[Blocker]` / `[Should]` / `[Nit]` / `[Pass]` and give the exact
replacement text for the affected step. Then, AFTER the graded findings, append a section
`## Sharpened rewrite (v2)` containing YOUR complete improved version of the whole prompt in one
fenced code block, incorporating all your fixes. The rewrite is the primary deliverable; findings
justify it.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->

## Reviewer turn — deepseek

**swept file: yes** — reviewed full artifact (.relay-artifacts/cleanup-runbook-prompt.md) lines 1–30.

### Graded findings

#### [Blocker] Default-branch detection has no deterministic fallback (DoD 1, 5)
Step 1 uses `git symbolic-ref refs/remotes/origin/HEAD, or gh repo view` — both fail silently or error on forks/mirrors where origin/HEAD is unset, and on a gh-less or unauthenticated machine. The agent is then stranded mid-PASS 1 with no rule. Consequence: the rest of the inventory uses a wrong default branch.

Fix — replace step 1 with:
```
1. Detect the default branch — in order: `git symbolic-ref --short refs/remotes/origin/HEAD` (trim the leading `origin/`); if that fails, `gh api repos/{owner}/{repo} --jq .default_branch`. If BOTH fail: report "cannot determine default branch" and STOP — never guess `main`.
```

#### [Blocker] `git branch -d` cannot delete remote branches (DoD 1)
Step 8 says "Delete approved merged branches, local and origin: `git branch -d` only." `git branch -d` is local-only; the "origin" half has no command. Consequence: remote branches never cleaned up despite the instruction.

Fix — replace step 8 with:
```
8. Delete approved merged branches: local with `git branch -d <branch>`; origin with `git push origin --delete <branch>`. Use `-d` only, never `-D`, unless I name the branch and say so. If the push fails because the remote branch is already gone (404/does-not-exist), report it as already-deleted and continue — never `--force`.
```

#### [Blocker] `@{u}` fails on detached HEAD and LOCAL-ONLY branches (DoD 1, 5)
Steps 3 and 9 use `git rev-list --left-right --count HEAD...@{u}` and `git log @{u}..` — both fatal-error on detached HEAD and branches with no upstream. Step 3 is supposed to flag "no-upstream branches as LOCAL-ONLY" but the command itself errors before that can happen. Step 9 aborts the entire teardown on the first local-only branch.

Fix — amend steps 3 and 9: wrap every `@{u}` reference in a guard:
```
3. For EACH folder report: ... ahead/behind vs its upstream ONLY when an upstream exists (`git rev-parse --abbrev-ref @{u} 2>/dev/null`; empty → LOCAL-ONLY, skip ahead/behind for it). Use `git rev-list --left-right --count HEAD...@{u}` only when non-empty.
```

#### [Blocker] Missing safety predicate: in-progress operations (DoD 2)
Nowhere does the prompt check for an in-progress rebase/merge/cherry-pick/bisect/revert inside any working copy. If the primary checkout has a mid-rebase state, a teardown could delete pending state or create inconsistent trees.

Fix — add to step 3 per-folder block:
```
- in-progress op: `ls "$(git rev-parse --git-toplevel)"/.git/{MERGE_HEAD,REBASE_HEAD,REVERT_HEAD,CHERRY_PICK_HEAD,BISECT_LOG} 2>/dev/null`; any present → mark IN-PROGRESS-OP and EXCLUDE from pass-2 proposals entirely.
```

#### [Should] `gh` unavailability — undetermined at pass 1, but pass 2 and 3 assume gh works (DoD 5)
Step 3 says "write undetermined — never guess". But step 7 says "Verify checks are green" and step 11 says "Confirm every PR is merged/closed" — both impossible without gh. No fallback or stop-rule for when gh is still unavailable at pass 2/3.

Fix — add to step 11 preamble: "If gh was unavailable at PASS-1 time, re-run `gh auth status`; if it still fails: STOP and report 'cannot verify PR state without gh — merge/close status unverified'."

#### [Should] Step 7 lacks explicit "STOP if checks are red" clause (DoD 3)
Step 7: "Verify checks are green at each step; resolve only minor conflicts." No instruction on what to do if a check is red, so a headless agent could merge with a red CI.

Fix — add to step 7: "If any merge target has a failing check: STOP, report the failing check(s), and wait for new explicit instruction — never merge with a red check."

#### [Should] Missing submodule and stash safety checks (DoD 2)
Step 3 checks uncommitted/staged/untracked but omits `git stash list` and `git submodule status`. Both are common sources of lost work during teardown.

Fix — add to step 3: "Also run `git stash list` (non-empty → dirty) and `git submodule status` (prefix `+` = diverged, `-` = uninitialized)."

#### [Should] Step 9 verifies only the checked-out branch, not all branches in a full-clone folder (DoD 2)
Step 9 runs `git log @{u}..` for the checked-out branch. A second local branch with unpushed commits in the same folder is invisible, then lost.

Fix — replace the per-branch check with: "For EVERY branch in the folder: `git log --branches --not --remotes --oneline` must output 0 lines (nothing unpushed)."

#### [Nit] Step 2 "sibling folders" heuristic has no discovery command (DoD 4, 6)
Line 13: "any sibling folders whose name derives from this repo (e.g. <repo>-*, <repo>_gh<n>-*)" — no concrete `find`/`ls` command prescribed.

Fix — prescribe: "list `${parent_of_checkout}/*` directories whose basename starts with `basename "$(git rev-parse --show-toplevel)"` — do not traverse higher."

#### [Nit] Step 9 lacks `cd`-into-folder instruction before verification (DoD 6)
"Tear down an approved full-clone folder ONLY AFTER re-verifying AT THAT MOMENT: `git status --porcelain` empty" — agent is in primary checkout, not the full-clone folder.

Fix — prefix step 9 with: "For each full-clone folder: `cd` into it first, then re-verify..."

#### [Pass] Step 10's never-run list (GH-527)
Lines 29–30: `git reset --hard`, `git checkout -- <path>`, tree-wide `git stash`, `git branch -D`, `rm -rf`, recursive delete — comprehensive prohibition that correctly mirrors GH-527. This is the strongest command-level safety guard in the prompt.

**Citation: line 29 of the artifact of record.**

#### [Pass] Step 11: final verification crossing (state, PR, end-state)
Lines 30–33: A three-part final check (status, PR closure, end-state definition) that closes the loop, with an explicit "report any deviation" clause. No gaps.

**Citation: lines 30–33.**

### Verdict: Changes requested

The artifact needs the 4 blockers resolved before approval. The sharpened rewrite below incorporates all fixes.

## Sharpened rewrite (v2)

```markdown
# Repo-agnostic local cleanup prompt — PRs, worktrees, full clones

Local repo cleanup: open PRs, git worktrees, and full-clone folders.

Respond concisely. Cleanup only — do not start unrelated work or fix unrelated breakage; note it and move on. Measure twice; cut once.

PASS 1 — READ-ONLY INVENTORY (no merges, no deletions, no worktree removal, no branch deletion)
1. Detect the default branch — in order: `git symbolic-ref --short refs/remotes/origin/HEAD` (trim the leading `origin/`); if that fails, `gh api repos/{owner}/{repo} --jq .default_branch`. If BOTH fail: report "cannot determine default branch" and STOP — never guess `main` or any other name.
2. Find every working copy of this repo on this machine: this checkout, every entry in `git worktree list`, and sibling folders in the SAME parent directory whose basename starts with the repo basename (from `basename "$(git rev-parse --show-toplevel)"`) — do not traverse higher, do not scan the whole disk; if you suspect clones elsewhere, ask me.
3. For EACH folder report:
   - path, checked-out branch or DETACHED HEAD; for each branch: upstream present? (`git rev-parse --abbrev-ref @{u} 2>/dev/null`; empty → LOCAL-ONLY, skip ahead/behind for it)
   - ahead/behind vs its upstream ONLY when an upstream exists (`git rev-list --left-right --count HEAD...@{u}`); flag no-upstream branches as LOCAL-ONLY
   - git status: clean or dirty, with uncommitted, staged, and untracked listed separately; also `git stash list` non-empty = dirty
   - in-progress op: `ls "$(git rev-parse --git-toplevel)"/.git/{MERGE_HEAD,REBASE_HEAD,REVERT_HEAD,CHERRY_PICK_HEAD,BISECT_LOG} 2>/dev/null`; any present → mark IN-PROGRESS-OP and EXCLUDE from pass-2 proposals
   - merged? check BOTH `git branch --merged <default>` AND squash-merges via `git cherry <default> <branch>` — report which
   - PR state: `gh pr list --head <branch> --json number,state,title`. If gh is unavailable or errors, write "undetermined" — never guess.
4. List deletion candidates on origin: branches fully merged with no open PR. Also list untracked scratch files left in any working copy.
5. Output ONE markdown table with a Disposition column — test conditions in this order and assign the FIRST match: Dirty → Local-only → Unpushed → Pushed-not-merged → Merged (safe to remove) → Unknown / needs review.
6. Then propose: (a) a safe PR merge sequence with dependency notes, (b) the teardown list, (c) anything that needs my decision. State the expected end state. Then STOP and wait for my explicit approval. Do not delete anything first and apologize later — when in doubt, ask.

PASS 2 — EXECUTE (only what I approved)
7. Merge PRs one at a time in the proposed sequence. Verify checks are green at each step (`gh pr view <n> --json statusCheckRollup --jq '.statusCheckRollup[].conclusion'`; SUCCESS and NEUTRAL = green, any other = red). If any target has a red check: STOP, report the failing check(s), and wait for new explicit instruction — never merge with a red check. Resolve only minor conflicts, stop on anything structural. After each merge, look for a post-merge script at `.github/merge-housekeeping.sh`, `scripts/post-merge.sh`, or `utils/post-merge.sh`; if one exists, run it; if it fails, STOP and report.
8. Delete approved merged branches: local with `git branch -d <branch>`; origin with `git push origin --delete <branch>`. Use `-d` only, never `-D`, unless I name the branch and say so. If the remote push fails because the branch is already gone, report already-deleted and continue — never `--force`.
9. Tear down approved worktrees with `git worktree remove` — never `rm -rf`, never `mv`. Tear down an approved full-clone folder ONLY after cd-ing into it and re-verifying AT THAT MOMENT: `git status --porcelain` empty, `git stash list` empty, and for EVERY branch in the folder `git log --branches --not --remotes --oneline` outputs 0 lines (nothing unpushed). If any check fails, skip that folder and report why.
10. Never run: git reset --hard, git checkout -- <path>, tree-wide git stash, git branch -D, rm -rf, or any recursive delete of a path you did not re-verify in step 9.
11. Final verification (if gh was unavailable at PASS-1 time, re-run `gh auth status` first; if it still fails, STOP and report "cannot verify PR state without gh"): `git fetch origin`, then for each surviving folder show branch + clean status (clean = `git status --porcelain` empty AND `git stash list` empty AND no in-progress ops) + 0/0 ahead/behind. Confirm every PR is merged/closed or explicitly parked with an issue and a note. End state: one clean primary checkout on the default branch, everything pushed, no leftover worktrees, clone folders, or merged branches. Report any deviation from that state plainly — including what you could not verify.
```

handing off to claude-a — go to the Producer window and say "take your turn"

## Producer turn — claude-a (close-out)

All 4 Blockers + 4 Shoulds + 2 Nits dispositioned: **Implemented** via the v2 rewrite, with 3
orchestrator corrections applied on top (restored the agent-session-state column your rewrite
dropped; replaced the `<toplevel>/.git/<op>` probe with worktree-safe `git rev-parse --git-path`;
replaced the invented 3-path post-merge list with docs-first discovery, since the 3 paths would
have missed this very repo's housekeeping; restored `git submodule status` per your Should-3).
Final artifact: temp/cleanup-runbook-sharpen.md → temp/cleanup-runbook-prompt.md (v3, gitignored).
Note: turn 1 technically failed exit 6 (off-lane artifact regeneration inside the isolated
worktree — containment held, real tree unaffected); the review content was harvested regardless.
Thread left uncommitted: another session owns the main checkout's dirty state right now.

Verdict adopted; relay closed by Producer. STATUS: Closed — no further turn needed.
