# Marathon Phase p2
STATUS: Open
NEXT: codex

<!-- marathon-drive: task=MARATHON-P2-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# p2 — GH-25: sanitize-scan.sh cannot run from a linked git worktree

Release 1.4.270 "Roundup" · issue [#25] · depends on p1

## The defect

`utils/sanitize-scan.sh:80`:

```sh
[ -d "${REPO_ROOT}/.git" ] || die "${REPO_ROOT} is not a git repository."
```

In a **linked worktree** `.git` is a *file* containing `gitdir: …`, not a directory, so the test
fails and the script dies with `FATAL: <path> is not a git repository.` at exit `2`.

## Reproduce first

```bash
git worktree add /tmp/wt --detach HEAD
cd /tmp/wt && ./utils/sanitize-scan.sh --allowlist utils/sanitize-allowlist.txt; echo "exit: $?"
# FATAL: … is not a git repository.   exit: 2
```

## Scope — small on purpose

Replace the `-d` test with one that resolves all checkout shapes:

```sh
git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1 || die "…"
```

That is the whole fix. Do not restructure the script.

## Do NOT relax the failure contract

The script's header states it *"exits 2 (never 0) if it cannot verify its own tooling — so a broken
scanner can never be mistaken for a clean tree."* That behaviour is **correct and load-bearing**.
The bug is the detection test, not the fail-closed response. A "fix" that makes the script continue
when it cannot establish a repo root is a security regression, not a fix.

## Done when — all four, or it is not done

1. Passes in a normal clone.
2. Passes in a **linked worktree** (the bug).
3. Still exits **non-zero** in a genuinely non-git directory (e.g. `mktemp -d`). A guard that can no
   longer fail proves nothing — verify it still fails.
4. Still detects a planted secret. Plant a fixture matching an existing allowlist-adjacent pattern,
   confirm non-zero, remove it. Confirming only the happy path would let a broken scanner ship
   looking green.

Record the observed exit codes for all four in the turn.

## Out of scope

Anything else in the script — allowlist semantics, pattern set, performance. GH-26 is p3.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/sanitize-scan.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-P2-TURN --agent codex --paths "phases/roundup-open-issues--p2/RELAY.md,utils/sanitize-scan.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-P2-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-P2-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/roundup-open-issues--p2/RELAY.md and utils/sanitize-scan.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/sanitize-scan.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-P2-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-P2-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/roundup-open-issues--p2/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.
