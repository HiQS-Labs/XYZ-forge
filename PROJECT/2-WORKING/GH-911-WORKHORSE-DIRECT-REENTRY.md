---
gh_issue: 911
source: https://github.com/HiQS-Labs/XYZ-forge/issues/911
title: "GH-911: skills(workhorse): keep direct /workhorse runs going — end-of-run report, durable run checklist, Stop hook, proportional consult"
status: Active (2-WORKING — plan and final QA approved by Codex relay 2026-10-01, PR open)
created: 2026-10-01
updated: 2026-10-01
owner: noelsaw1
goal: direct /workhorse runs continue until their queue is resolved, with one end-of-run report
doc_type: feedback
effort: 2
complexity: 2
risk: 1
phases: 1
---

# GH-911 — keep direct `/workhorse` runs going

## Status

| What was just completed | What's next |
|---|---|
| Plan steps 1–8 implemented (`ace8d80c`). Disposable-clone verification: gh609 33/0, hook matrix 15/15 with red control (`TESTS-RESULTS/2026-10-01+GH-911/`). Final Codex relay QA Approved (reviewed `75b3311b`). Branch synced with `development` (merge) and pre-PR polish applied | Qualifying gate on the PR head (pre-push `ci-local.sh` + hosted CI), then review and merge. First live Claude Code run confirms the hook fires |

A directly invoked `/workhorse` (no parent orchestrator) stops after 2–3 turns while queue items remain.

## Asks

1. Rung 6 "Report & Close" fires once at end of run, not per item.
2. Durable run checklist in an ignored repo-local location replaces the scratchpad-only queue (Rung 0); the
   re-entry rule extends to direct invocations, not only `merge-cleanup`/`jog`/`marathon`/`/10days` (#626).
3. A Claude Code `Stop` hook blocks stopping while the active run checklist has open items, with a
   loop-safety escape; prefer skill-scoped wiring over global settings.
4. Rung 4 consult may be skipped for focused, Easy-to-reverse changes confined to a local task branch.
5. Rung 5 states that local task-branch edits need only the one-line Easy note.

## Rating (2026-10-01): `rated 70/45/50/70`

- **sev 45:** operator-time and workflow friction (runs need re-driving), no data loss or corruption.
- **pri 70:** operator requested it now; it blocks unattended use of a daily-tier skill.
- **appeal 50:** neutral (no operator score given).
- **effort 70:** one SKILL.md edit plus one small hook script, verified on an existing suite.
- **Recurrence:** same class as #626 (2026-09-14, "I kept having to drive it"). Window 2026-09-17..10-01: 1 (#911)
  vs 2026-09-03..09-16: 1 (#626). Flat trend, small sample.

## Non-goals

Governor/executor split, six-state decision protocol, progress fingerprints, budget counters, `.agent/`
JSON schema, new test suites (GH-831). No change to `/unstuck`, the orchestrator `--resume` contract (#626),
Rung 5's Costly/One-way-door proof, or `install.sh`. We may continue fine-tuning `/workhorse` later.

## Recon (base `9ecb344f`)

- **Stop trigger.** `skills/2-daily/workhorse/SKILL.md:242` "Report & Close — present a concise completion
  summary" sits inside Rung 6, which runs once per queue item, so every item ends in a report.
- **Re-entry scope.** `SKILL.md:250-256` gives the "intermediate checkpoint, never the end of the turn"
  rule only to runs under `merge-cleanup`/`jog`/`marathon`/`/10days`.
- **Queue home.** `SKILL.md:66` keeps the active queue "in the active session plan / scratchpad"; `:68`
  says to advance serially. Nothing outside the context window records open items.
- **Consult skip.** `SKILL.md:262-267` allows skipping Rung 4 only when an action is trivial **and** Easy.
- **Rung 5.** `SKILL.md:164` already says Easy work records a one-line classification. Local task-branch
  edits aren't named as an Easy example.
- **Harness facts** (raw docs, code.claude.com/docs/en/hooks.md + skills.md, fetched 2026-10-01):
  - Skill frontmatter accepts `hooks:` in the settings.json format. They are registered on invocation and
    stay active for the rest of the session.
  - The Stop input carries `session_id`, `cwd`, `stop_hook_active`.
  - `{"decision":"block","reason":…}` on stdout keeps Claude going.
  - Claude Code caps hook-forced continuations at 8 in a row.
  - `${CLAUDE_SKILL_DIR}` / `${CLAUDE_SESSION_ID}` are substituted in skill markdown but **not** in hook
    commands; hooks get `$CLAUDE_PROJECT_DIR`.
- **Existing subsystem check.**
  - `relay-automation/loop-stop.sh` is a CLI halt evaluator for the self-improve loop, not a Claude Code hook.
  - `utils/pdda/pdda-stop-doc-health.sh` is a non-blocking report hook.
  - Neither tracks a work queue, so neither can carry this.
  - No repo-level `.claude/settings.json` Stop hook exists.
- **Blast radius.**
  - Consumers: Claude Code (honors `hooks`), Codex/Agy (read the markdown, ignore unknown frontmatter).
  - Distribution carries the whole skill folder, so a bundled script ships with it. Direct install
    symlinks the source folder into the app (`skills/2-daily/workhorse/install.sh:48,53`). Skills Army
    copies the owning repo's folder into the Pulse collection, then app symlinks point at that copy.
    The installer's `CLAUDE_SKILLS_DIR` override is not covered by the hook's path resolution.
  - No XYZ-mini mirror.
  - `test/gh609-sdlc-agent-gaps.sh` pins Rung 5 strings that this change does not touch.

## Plan (one phase)

1. **Run checklist (Rung 0 §3–4).** Replace the scratchpad queue with
   `<repo-root>/.workhorse/${CLAUDE_SESSION_ID}.md`.
   - Fallback: a timestamp slug when not substituted, e.g. on Codex/Agy.
   - The agent adds `.workhorse/` to `.git/info/exclude` (repo-local, never committed).
   - One line per item: `- [ ]` open, `- [x]` done, `- [-]` parked (with its PARKED/issue pointer),
     `- [!]` blocked (with the exact blocker for the operator).
   - The loop advances until no `- [ ]` line remains.
2. **Rung 6 §4 → end-of-run.** Per item: tick the checklist line and continue to the next open item. The
   completion summary is produced once, when no `- [ ]` remains, and covers every item.
3. **Rung 6 §5 → direct re-entry.** Add a direct-invocation clause: the run checklist is the resume target.
   Finishing an item while `- [ ]` lines remain is an intermediate checkpoint, never the end of the turn.
   The orchestrator `--resume` clause stays as-is.
4. **Stop hook.** Add `skills/2-daily/workhorse/stop-hook.sh` (~30 lines, bash + `python3` for JSON, as the
   repo's other hooks do).
   - Read stdin → `session_id`, `cwd`; resolve the repo root via `git -C "$cwd" rev-parse --show-toplevel`
     (fallback `$CLAUDE_PROJECT_DIR`).
   - Read `.workhorse/<session_id>.md`. If any `- [ ]` line exists, print
     `{"decision":"block","reason":…}` naming up to 5 open items. The reason says to continue, or mark
     `[!]`/`[-]` with the blocker to hand back to the operator.
   - Otherwise exit 0 silently. **Fail open on every error** (missing python3/git/file, bad JSON).
   - Session scoping by filename means the hook stays inert after the run ends, and in sessions that never
     invoked workhorse.
   - Loop safety: the 8-continuation cap is built in, plus the `[!]` escape. No new counters.
   - Wire it in `SKILL.md` frontmatter:
     ```yaml
     hooks:
       Stop:
         - hooks:
             - type: command
               command: >-
                 for f in "$CLAUDE_PROJECT_DIR/.claude/skills/workhorse/stop-hook.sh"
                 "$HOME/.claude/skills/workhorse/stop-hook.sh"; do [ -f "$f" ] && exec bash "$f"; done; exit 0
     ```
     These are the project- and user-scope install paths; no `${CLAUDE_SKILL_DIR}` in hook commands.
5. **Rung 4 + Fast-Track.** Let the consult be skipped for a focused change confined to a local task
   branch/clone that is Easy to reverse. It stays mandatory for architecture, subsystem-boundary,
   persistent-state, public-contract, dependency, security/performance-material, or Costly/One-way-door
   work. Skip line: `[workhorse: focused Easy local-branch change; consult not required]`.
6. **Rung 5 one-liner.** Add one sentence to `SKILL.md:164`: an edit confined to a local task branch/clone,
   recoverable from a Git ref and with no remote/shared/published side effect, is Easy and needs only the
   one-line note.
7. **Keep the skill's own summaries consistent (relay S1).** Update the existing lines rather than adding
   a new policy:
   - Recital `SKILL.md:30`: the queue lives in the run checklist.
   - Recital `:33`: fan out per Rung 4's proportional rule.
   - Overall goal `:36`: "validated across independent models where Rung 4 requires it".
   - Operating rule `:292`: Rungs 1–6 per item, with Rung 4 per its own skip rule.
   - Keep `:285`'s emergency-rollback restriction unchanged and explicit.
8. **CHANGELOG.md** entry (newest-first, dated).

## Verification (existing suites + manual checks; no new tests, GH-831)

- `bash test/gh609-sdlc-agent-gaps.sh` stays green (workhorse contract strings untouched).
- `bash -n` and `shellcheck` (if present) on `stop-hook.sh`. YAML frontmatter parses
  (`python3 -c 'import yaml…'`), and `hooks.Stop[0].hooks[0].command` is present.
- Manual hook matrix, run in a **disposable full clone** (as are gh609 and the full gate). Commit
  `TESTS-RESULTS/2026-10-01+GH-911/SUMMARY.md` plus `provenance.jsonl` (command, sha, exit status,
  decisive output per check) in the implementation PR.
  - **Red control (relay S2):** run a scratch copy of `stop-hook.sh` with the open-item predicate disabled
    against an open `- [ ]` checklist. The assertion "stdout is block JSON naming the item" must **fail**.
  - **Green:** the real hook on the same input → assertion passes.
  - Only `[x]/[-]/[!]` lines → no output, exit 0.
  - No checklist file → exit 0.
  - Another session's id → exit 0.
  - Garbage or wrongly typed stdin → exit 0.
  - Hook command resolution:
    - project path present → it runs.
    - user-symlink path present → it runs.
    - neither present → exit 0.
  - `stop_hook_active:true` with an open item → still blocks; the cap is the harness's job.
- Full gate (`./validate.sh` / `ci-local.sh` per repo policy) exactly once on the final approved commit, in
  that disposable clone.

## Risks / rollback

- **Risk:** the hook blocks a stop the operator wanted. **Mitigation:** session-scoped file, `[!]` escape,
  8-continuation harness cap. Deleting `.workhorse/` or the file disables it instantly.
- **Rollback:** revert the commit. Easy to reverse; no persistent or shared state.
