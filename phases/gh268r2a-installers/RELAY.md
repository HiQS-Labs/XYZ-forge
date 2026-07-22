# Marathon Phase gh268r2a-installers
STATUS: Ready for review
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH268R2A-INSTALLERS-TURN builder=aider-qwen reviewer=codex round-cap=4 -->

## Phase Brief

# GH-268 Phase 1 — install.sh for `consult` and `open-router` (prove-first lane, 2 of 9)

**Source of truth:** `PROJECT/2-WORKING/GH-268-BETA-ONBOARDING-BUILD-QUALITY-REMEDIATION.md` → Phase 1,
item "Every skill ships an `install.sh`". This lane does ONLY 2 of the 9 installers, deliberately small.

## Goal
Add a working, idempotent `install.sh` to exactly these two skill dirs:
- `skills/consult/install.sh`
- `skills/open-router/install.sh`

## Pattern to mirror (read it first)
`skills/relay-xyz/install.sh` is the reference. Each new `install.sh` must:
- start with `#!/usr/bin/env bash` and `set -euo pipefail`,
- be self-locating (resolve its own dir via `$BASH_SOURCE`; no hardcoded machine path),
- symlink `skills/<name>/` into `~/.claude/skills/<name>`,
- be idempotent: no-op if the correct symlink already exists, replace a stale/dangling one,
- refuse politely if the target exists and is NOT a symlink,
- print a one-line success message.
Only the skill name differs between the two files. Write the FULL contents of each file — do not leave
either file empty or partial.

## Scope discipline (important)
- Edit ONLY the relay file and the two target `install.sh` paths above. Do NOT edit
  `skills/relay-xyz/install.sh` (that is the read-only reference), `validate.sh`, or any other file —
  off-lane edits are reverted and fail the turn.
- Do 1–2 files per turn max; if you only finish one, hand back and continue next turn.

## Done means
- Both files exist, are non-empty, begin with a shebang, pass `bash -n`, and reference
  `~/.claude/skills`. (The harness runs this exact gate after your turn.)


---

▶ TAKE YOUR TURN (aider-qwen — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): skills/consult/install.sh,skills/open-router/install.sh
2. Append a build block to this relay file: `### Round N · Builder · aider-qwen` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH268R2A-INSTALLERS-TURN --agent aider-qwen --paths "phases/gh268r2a-installers/RELAY.md,skills/consult/install.sh,skills/open-router/install.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH268R2A-INSTALLERS-TURN --agent aider-qwen
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH268R2A-INSTALLERS-TURN --agent aider-qwen --to codex
4. Edit ONLY these paths: phases/gh268r2a-installers/RELAY.md and skills/consult/install.sh,skills/open-router/install.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/consult/install.sh,skills/open-router/install.sh.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH268R2A-INSTALLERS-TURN --agent codex --to aider-qwen
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH268R2A-INSTALLERS-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh268r2a-installers/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · aider-qwen
- Created `skills/consult/install.sh` and `skills/open-router/install.sh` as full, non-empty installer scripts.
- Each script starts with `#!/usr/bin/env bash` and `set -euo pipefail`.
- Each script is self-locating via `$BASH_SOURCE`, with symlink-safe resolution of its own directory and no hardcoded machine path.
- Each script symlinks its skill directory into `~/.claude/skills/<skill-name>` via `$HOME/.claude/skills` by default, while allowing `CLAUDE_SKILLS_DIR` override.
- Behavior is idempotent: no-op if the correct symlink already exists, replace a stale/dangling/wrong symlink, and refuse politely if the destination exists as a non-symlink.
- Only the skill name differs between the two installer scripts.
- Updated this relay file status to ready for review and handed the next turn to `codex`.
