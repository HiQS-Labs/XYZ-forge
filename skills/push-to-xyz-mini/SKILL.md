---
name: push-to-xyz-mini
description: Publish the curated XYZ mini skill subset from this XYZ-forge checkout into the local XYZ-mini repo and push it to origin, using the deterministic embedded-manifest publisher utils/py/xyz_mini_sync.py (GH-589). Trigger on "/push-to-xyz-mini", "publish to mini", "sync XYZ mini", "push the mini repo". Manual, operator-invoked; preview first, then apply and push on one confirmation.
---

# push-to-xyz-mini

Publish XYZ-forge → XYZ mini. The publisher owns every guarantee; this skill is the operator flow
around it. Read `utils/py/xyz_mini_sync.py` for the manifest (what ships) and the contract.

## Preconditions

- You are inside an XYZ-forge clone whose HEAD is what you intend to publish (usually `development`
  after a merge). The source must be clean; `--allow-dirty` exists but is recorded in the mini commit.
- A local checkout of `https://github.com/HiQS-Labs/XYZ-mini` exists at `../XYZ-mini` relative to
  the forge toplevel, or at `$XYZ_MINI_REPO`, on branch `main`, clean, with no unpushed non-sync commits.

## Flow

1. Preview (writes nothing):

   ```bash
   python3 utils/py/xyz_mini_sync.py
   ```

   Read the plan: `+` adds, `~` updates, `-` deletions, seeds kept, files scanned. A refusal
   (exit 2) names the exact reason; fix it at the source, do not work around it.

2. Show the operator the plan and ask once: "publish this?"

3. On yes, apply and push in one step:

   ```bash
   python3 utils/py/xyz_mini_sync.py --push
   ```

   Exit 0 means the commit exists locally **and** `origin/main` was read back equal to it.
   Exit 3 means apply/commit/push failed; the message says what was retained (a rerun retries a
   failed push without creating a second commit). Exit 4 means the secret tripwire fired and
   nothing was written.

4. Read back and report: `git -C ../XYZ-mini log -1 --stat` and the pushed SHA.

## After a squash merge

The publisher derives what it previously owned from the forge revision recorded in mini's
`.xyz-forge-revision`. If that SHA was squashed away and is unreachable in your clone, the run
refuses (exit 2). Pass the merge commit explicitly, once:

```bash
python3 utils/py/xyz_mini_sync.py --prior-revision <merge-sha> --push
```

## Changing what ships

Edit the `MANIFEST` tuple in `utils/py/xyz_mini_sync.py` in a forge PR. Dropping an entry deletes
it from mini on the next publication (mirror mode); adding one ships it. Seeds (`TODO.md`) are
copied once and never touched again. `test/gh589-xyz-mini-sync.sh` is the contract test.

## What this skill never does

Automatic runs, force pushes, history rewrites, or edits inside the mini checkout by hand.
Automation (a GitHub Action on merge to `development`) is a later step; see GH-589.
