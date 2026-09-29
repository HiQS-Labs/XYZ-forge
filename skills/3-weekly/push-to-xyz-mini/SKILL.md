---
name: push-to-xyz-mini
description: Publish the curated XYZ mini skill subset from this XYZ-forge checkout into the local XYZ-mini repo and push it to origin, using the deterministic embedded-manifest publisher utils/py/xyz_mini_sync.py (GH-589). Trigger on "/push-to-xyz-mini", "publish to mini", "sync XYZ mini", "push the mini repo". Manual, operator-invoked; preview first, then apply and push on one confirmation.
---

# push-to-xyz-mini

Publish XYZ-forge → XYZ mini. The publisher owns every guarantee; this skill is the operator flow
around it. Read `utils/py/xyz_mini_sync.py` for the manifest (what ships) and the contract.

## Preconditions

- You are inside an XYZ-forge clone whose HEAD is what you intend to publish. Any branch is
  sanctioned — publishing from a feature branch is the documented exception path; the tool records
  `source_branch` in the child's `.xyz-forge-revision`, warns when the branch is not `development`,
  and a re-publication from `development` after the branch lands re-baselines the pin. A branch
  that predates a manifest source refuses (exit 2). The source must be clean; `--allow-dirty`
  exists but is recorded in the mini commit.
- A local checkout of `https://github.com/HiQS-Labs/XYZ-mini` exists at `../XYZ-mini` relative to
  the forge toplevel, or at `$XYZ_MINI_REPO`, on branch `main`, clean, with no unpushed non-sync commits.

## Flow

1. Preview (writes nothing):

   ```bash
   python3 utils/py/xyz_mini_sync.py
   ```

   Read the plan line (files to copy, paths to delete). A refusal (exit 2) names the exact
   reason; fix it at the source, do not work around it. Exit 4 means the secret scan fired.

2. Show the operator the plan and ask once: "publish this?"

3. On yes, apply and push in one step:

   ```bash
   python3 utils/py/xyz_mini_sync.py --push
   ```

   Exit 0 means the commit exists locally **and** `origin/main` was read back equal to it.
   Exit 3 means commit or push failed; the local commit is retained and a rerun retries the push.

4. Read back and report: `git -C ../XYZ-mini log -1 --stat` and the pushed SHA.

## Changing what ships

Edit the `MANIFEST` tuple in `utils/py/xyz_mini_sync.py` in a forge PR. Dropping an entry deletes
it from mini on the next publication (mini's `MANIFEST.txt` records what the last run wrote); adding
one ships it. Seeds (`TODO.md`) are copied once and never touched again. `adapted` entries are the
exception path for mini-owned bytes: the forge source stays tracked as the upstream of record, the
tool never replaces the child's copy, and every adapted path must be documented in `mini/ORIGIN.md`
or the run refuses (exit 2). An adapted path deleted from the child is refused — restore it from
the child's git history; a fresh child materializes it from forge bytes as the re-adaptation
starting point. Policy: `mini/ADAPTATIONS.md`. `test/gh589-xyz-mini-sync.sh` is the contract test.

## What this skill never does

Automatic runs, force pushes, history rewrites, or edits inside the mini checkout by hand.
Automation (a GitHub Action on merge to `development`) is a later step; see GH-589.
