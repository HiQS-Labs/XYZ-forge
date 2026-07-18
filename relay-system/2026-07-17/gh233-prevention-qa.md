# RELAY · GH-233 wipe-prevention QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-17.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh233-prevention-qa): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **gh233-review-brief.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-17

### Artifact — gh233-review-brief.md
```
# QA review request — GH-233 repo-wipe prevention fixes

You are reviewing four changes that just landed to prevent a recurrence of the GH-177 incident, where
a sandboxed `./validate.sh` run let a broken `mktemp -d` feed a destructive `rm -rf "$TMP"` EXIT trap
that wiped the repo (including parts of `.git`) — twice. Open the real files in your worktree (paths
below are repo-relative and committed at HEAD) and review them critically.

Review for: **correctness, bypasses, and edge cases.** For each file, ask "how would a real command
slip past this guard, or how would this guard misfire and block/damage legitimate work?" Prioritise
concrete failure scenarios (a specific command string, a specific environment) over style. If a
concern is real, propose the minimal fix. If you can't find a real defect in a file, say so plainly —
do not invent nitpicks to look thorough.

## Files under review

1. **`relay-automation/hooks/gh177-sandbox-test-guard.sh`** — a PreToolUse hook that blocks EXECUTING
   `validate.sh` / `test/*.sh` under a *sandboxed* Claude Code Bash call (unsandboxed runs, `bash -n`,
   shellcheck, and mere string mentions must stay allowed). It reads the PreToolUse JSON event on
   stdin, parses `tool_input.command`, splits on `&& || ; | newline`, and per-segment decides whether
   an argv-position token is a suite script. Exit 2 = block (message to model), exit 0 = allow.
   Fail-open on any parse error.
   - Key questions: Can a real suite execution reach the tree WITHOUT tripping this (e.g. `cd test &&
     bash acorn-extract.sh`, a `$(...)`/backtick-nested invocation, `eval`, `source`/`.`,
     `env VAR=x ./validate.sh`, a symlink or `../test/foo.sh` path, `command bash validate.sh`, xargs,
     `find -exec`)? Does the fail-open on parse error create a trivial bypass? Conversely, does it
     over-block anything legitimate? Is the `dangerouslyDisableSandbox` field it reads actually the
     real field name the PreToolUse event delivers?

2. **`.claude/settings.json`** — the hook wiring. Confirm the new PreToolUse matcher block is
   well-formed JSON, uses matcher `"Bash"`, and coexists with the pre-existing `relay-xyz-guard.sh`
   block (both should run; one matcher block must not shadow the other).

3. **`AGENTS.md`** — the new worktree-isolation rail (search for "isolation" / "GH-177/GH-233"). This
   is prose policy, not code. Check it is accurate and not over-claiming: it must NOT imply
   `isolation: "worktree"` protects shared `.git` refs/objects (it does not), and it should correctly
   scope which subagents need it. Flag any statement that would mislead a future agent into a false
   sense of safety.

4. **`utils/git-bundle-snapshot.sh`** — daily rotated `git bundle --all` snapshots to
   `~/Backups/<repo>/`, keep-newest-N rotation. Check: is the rotation correct (never deletes the
   newest N, never deletes the just-written bundle)? Does `set -euo pipefail` interact badly with the
   `ls | while read` rotation or the `du` pipe? Any word-splitting / spaces-in-path bug given the repo
   lives under `.../GH Repos/...`? Is the `git bundle verify` a meaningful integrity check here? Can a
   failure mid-run leave a corrupt bundle that later gets trusted?

## What to produce

Append a normal Reviewer block to the relay thread: a short verdict line, then per-file findings with
`file:line` citations and a concrete failure scenario for each real defect, ordered most-severe first.
If a file is clean, say "no defect found" for it. Do not edit any of the four files — this is a
review-only turn; report findings in the relay thread and hand back.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
