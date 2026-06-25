---
title: agy turn edits ROOT directly under RELAY_WORKTREE_ISOLATION=1 — worktree copy-back silently overwrites output
status: Parked — bug confirmed; fix direction identified; standalone fix track
created: 2026-06-25
updated: 2026-06-25
owner: noelsaw1
branch: main
gh_issue: 22
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/22
track: standalone bug fix (relay-turn-lib.sh / agy-turn.sh)
related:
  - relay-automation/agy-turn.sh
  - relay-automation/relay-turn-lib.sh
  - relay-automation/relay-drive.sh
  - PROJECT/2-WORKING/RELAY-CONTAINMENT-HARDENING.md
non_goals:
  - Changing the worktree isolation model for codex-turn.sh (different failure mode — exit 6 containment, not silent data loss)
  - Disabling worktree isolation by default (the safety benefit is real; fix the path, not the feature)
---

## Progress

| Most recently completed | What's next |
|---|---|
| Bug confirmed 2026-06-25 during GH-21 quality gate relay. Root cause identified: agy edits ROOT via absolute path in prompt; `rtl_worktree_end` copies stale worktree copy back over ROOT edits. Workaround: `RELAY_WORKTREE_ISOLATION=0`. | Implement Option A: rewrite relay file path to CWD-relative in `agy-turn.sh` before the `agy -p` call so the agent writes into the worktree, not ROOT. |

## Problem

When `relay-drive.sh` drives an agy turn with `RELAY_WORKTREE_ISOLATION=1` (the default for driven runs), the headless agy process edits the relay file via the **absolute path** embedded in the turn prompt. This path points to ROOT, not the throwaway worktree. At teardown, `rtl_worktree_end` copies allowlisted files from the worktree back to ROOT — but since the worktree copy was never written, the stale empty worktree version overwrites agy's ROOT edits. Output is silently discarded. Exit code is 0 (or the round-cap's exit 4) — no error surfaces.

### Symptom

```
agy-turn: worktree isolation ON (/tmp/rtl-wt.aPHBam)
agy-turn: committed agy turn (file-scoped, no push)
relay-drive: round cap (1) exceeded (STATUS: Open, token actor: none)
```

The task registers as `done` in `.tick/` but the relay file on disk has no output block.

### Root cause

`rtl_worktree_end` in `relay-turn-lib.sh` copies allowlisted files **from worktree → ROOT**. When the agent edits via the absolute path in the prompt, it writes ROOT directly. The worktree copy is untouched. Copy-back direction is wrong for this case.

### Workaround

```bash
RELAY_WORKTREE_ISOLATION=0 AGY_AGENT=agy ... relay-drive.sh ...
```

## Fix options

### Option A — prompt-layer fix (preferred)

In `agy-turn.sh`, before the `agy -p "$prompt"` call, rewrite any absolute relay file path in the prompt to its CWD-relative equivalent inside the worktree. Since the worktree is set as CWD (`cwd_wrap`), a relative path ensures the agent writes the worktree copy, not ROOT. `rtl_worktree_end` then copies the correct file back.

**What done looks like:** an `agy-turn.sh` change that rewrites the `RELAY_FILE` path in the prompt when `RELAY_WORKTREE_ISOLATION=1` is active. `rtl_worktree_end` copy-back then works as designed.

### Option B — worktree-teardown sync

In `rtl_worktree_end`, before copying worktree → ROOT, first sync allowlisted files FROM ROOT into the worktree. Any ROOT-direct edits are captured; the copy-back is then idempotent.

**Downside:** makes `rtl_worktree_end` bidirectional and more complex; harder to reason about containment.

### Option C — doc-only (interim)

Document `RELAY_WORKTREE_ISOLATION=0` as required for agy-turn.sh driven runs until the path issue is fixed. Already captured in `relay-xyz/SKILL.md` and `agy-turn.sh` header.

## Relationship to other issues

- **GH-17** — macOS case-sensitivity triggers exit 6 from the same containment path; different failure mode (tracked edit reverted vs. untracked write lost)
- **GH-13 / GH-14** — containment hardening siblings; this is a containment *interaction* bug, not a new containment gap
- **RELAY-CONTAINMENT-HARDENING.md** — closest active doc; this bug may warrant a phase addition there or a standalone fix PR

## Origin

Surfaced during the GH-21 relay quality gate doc review (2026-06-25). The first agy relay drive (task `RELAY-gh21-plan-qa-agy`) completed with `VERDICT: PASS` in the agy log but the relay file was blank on disk. A second drive with `RELAY_WORKTREE_ISOLATION=0` succeeded cleanly.
