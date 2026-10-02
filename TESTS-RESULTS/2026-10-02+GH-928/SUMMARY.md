# GH-928 — Canary review round-1 fix evidence (2026-10-02)

Fix commit `090be955` on `feat/gh928-canary-gate` (PR #930), run in a fresh disposable full clone
(`~/marathon-clones/xyz-gh928-canary-fix`, macOS arm64, per the separate-full-clone rail).

## What was fixed (from the PR review)

1. **P1 — teardown `rm -rf` on an unproven caller-supplied path.** `sandbox_resolve` /
   `sandbox_deletable` now guard every dangerous use (GH-567 use-boundary rule): setup refuses
   `/` and the resolved home; teardown removes only a directory carrying this run's `logs/`
   marker, otherwise the sandbox is KEPT; each check's `cd` fails closed.
2. **P2 — containment blind to the GH-564 class + technically-false in-tree claim.**
   `tree-clean` diffs the working tree AND the clone's full local git config + `HEAD`;
   `python-ports` compiles a sandbox copy with `PYTHONDONTWRITEBYTECODE=1`.

## Results

| case | rc | result |
|---|---|---|
| canary-clean-both / python / bash | 0 | 21 passed, 0 failed (~3–4 s) |
| red-control-home-refused (`XYZ_CANARY_SANDBOX=<home>`) | 2 | refused at setup, dir untouched |
| red-control-root-refused (`XYZ_CANARY_SANDBOX=/`) | 2 | refused at setup |
| red-control-empty-falls-back (`XYZ_CANARY_SANDBOX=`) | 0 | mktemp fallback, 21 passed |
| red-control-jog-break (bogus import in `jog_run.py`) | 1 | python-ports + jog-dry-run FAIL; restore byte-identical |
| gitstate-detector | — | first draft (four telltales) FAILED its sensitivity witness; hardened to full config + HEAD; fires on unrelated write and remote repoint; restore-clean |

## Known scope limits (recorded, not hidden)

- `.git/hooks` FILES planted under `.git/hooks` are not covered; a changed `hooksPath` (a config
  key) is. The four-line fingerprint draft was replaced for exactly this reason.
- The `tree-clean` FAIL path for `.git`-state drift is code-reviewed and its detector witnessed
  standalone; it was not triggered end-to-end mid-run (would require mutating the clone while
  the canary executes).
- The pre-fix deliberate breaks of `bin/tick` (PR body, host Linux) were not repeated; the
  `jog_run.py` break was re-witnessed post-fix here.
