# Marathon Phase gh268cgb-installers
STATUS: Approved
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH268CGB-INSTALLERS-TURN builder=codex reviewer=agy round-cap=6 -->

## Phase Brief

# GH-268 Phase 1 — install.sh for: relay-automation

**Source of truth:** `PROJECT/2-WORKING/GH-268-BETA-ONBOARDING-BUILD-QUALITY-REMEDIATION.md`
→ Phase 1, "Every skill ships an install.sh". This lane covers only the files below.

## Goal
Write a complete, working, idempotent `install.sh` into EACH of these files:
- `skills/relay-automation/install.sh` — set `SKILL_NAME="relay-automation"`

## Pattern to mirror exactly
Two already-approved references in this repo: `skills/relay-xyz/install.sh` and
`skills/consult/install.sh`. Each new file must:
- start with `#!/usr/bin/env bash` and `set -euo pipefail`,
- be self-locating via `$BASH_SOURCE` (follow symlinks; no hardcoded path),
- symlink `skills/<name>/` into `~/.claude/skills/<name>` (honor `CLAUDE_SKILLS_DIR` override),
- be idempotent (no-op if the correct symlink exists; replace a stale/dangling one),
- refuse politely if the target exists as a real file/dir (not a symlink),
- print one success line.
Only `SKILL_NAME` differs between files. Write the FULL content of every listed file.

## Scope discipline
Edit ONLY the relay file and the exact install.sh paths listed above. Do NOT edit the two
reference files above or any other file — off-lane edits are reverted and fail the turn.

## Done means
Every listed file exists, is non-empty, begins with a shebang, passes `bash -n`, and references
`~/.claude/skills`. (The harness runs this exact gate after your turn.)


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): skills/relay-automation/install.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH268CGB-INSTALLERS-TURN --agent codex --paths "phases/gh268cgb-installers/RELAY.md,skills/relay-automation/install.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH268CGB-INSTALLERS-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH268CGB-INSTALLERS-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gh268cgb-installers/RELAY.md and skills/relay-automation/install.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/relay-automation/install.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH268CGB-INSTALLERS-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH268CGB-INSTALLERS-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh268cgb-installers/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · codex

- Created `skills/relay-automation/install.sh` by mirroring the approved `skills/consult/install.sh` pattern with `SKILL_NAME="relay-automation"`.
- Kept the installer self-locating and symlink-safe, honored `CLAUDE_SKILLS_DIR`, preserved idempotent repair behavior, and refused to overwrite real files or directories.
- Verified with `bash -n` and contained temporary-directory checks covering first install, idempotent rerun, dangling-link repair, real-directory refusal, and invocation through a symlink.

### Round 1 · Reviewer · agy

The implementation in `skills/relay-automation/install.sh` correctly mirrors the specified reference file `skills/consult/install.sh`. It is idempotent, safely self-locating, properly honors `CLAUDE_SKILLS_DIR`, safely skips existing real files/directories, and sets the correct `SKILL_NAME="relay-automation"`.

**Verdict:** Approved
