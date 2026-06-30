---
complexity: 2
risk: 2
effort: 2
ratings_provisional: false
gh_issue: 11
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/11
title: "relay-xyz: hard to target a repo other than the harness clone (cross-repo reviews)"
status: Complete (3-COMPLETED)
created: 2026-06-21
updated: 2026-06-30
closed: 2026-06-30
owner: Noel (operator) · Claude (producer)
doc_type: feedback
goal: >
  Make relay-xyz usable against a repo other than the harness clone — add a `--target-root` flag
  (Path A worktree base + `ALLOW_PATHS` resolution) and surface `consult.sh`'s `CONSULT_ROOT`, plus the
  low-effort doc fixes. Promoted from a GH-issue capture on execution start (Ask 1 flag landed).
---

# GH-11 — relay-xyz: cross-repo targeting

> **In-repo capture of [issue #11](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/11), promoted to `PROJECT/2-WORKING/` on execution start** (Ask 1's `--target-root` flag landed 2026-06-21). The live issue is the discussion surface; this doc is the canonical active-work record, per `PROJECT/PDDA.md` → "GitHub issue intake".

## Status

| What was just completed | What's next |
|---|---|
| **✅ ALL ASKS COMPLETE + CLOSED 2026-06-30.** Ask 1 (the `--target-root` flag + `relay-turn-lib.sh` kernel wiring, `test/relay-target-root.sh` 7/7) shipped 2026-06-21. **Asks 2–5 swept 2026-06-30** into `skills/relay-xyz/SKILL.md` — a new cross-repo subsection documents **`--target-root`** (full relay/build landing in a foreign repo; with the #51 same-repo caveat) and **`CONSULT_ROOT`** (one-shot advisory review of a foreign-repo file), with foreign-repo examples (Ask 5), the **`$TMPDIR` absolute-path warning** (Ask 3), and the find-harness-solves-the-inverse note (Ask 4). `skill-extract` + `path-integrity` green (SKILL.md is not tarball-packaged). | Done. |

## Summary

`relay-xyz` works well, but it's hard to use against **a repo other than the harness clone** — which is
the *normal* case, since the harness lives in `xyz-3-agents-swarm` while the artifact you want reviewed
lives in your own repo. `find-harness.sh` solves discovery of *the harness itself*; the gap is the
inverse: pointing the harness **at** a foreign repo.

## Asks (in priority order)

**Load-bearing (1–2):**

1. **`relay-drive.sh` (Path A) can't review an artifact in a foreign repo.** `ROOT_DIR` is pinned to
   `relay-automation/..` (the harness clone), and worktree-isolation snapshots *that* repo's `HEAD`.
   There is no `--root` / `--target-repo`, so the artifact must physically live inside the harness clone.
   **Ask:** add a `--target-root` flag (mirroring `consult.sh`'s `CONSULT_ROOT`) that sets the worktree
   base + `ALLOW_PATHS` resolution to an external repo.

2. **`consult.sh` already does cross-repo one-shot reviews, but it's buried.** It supports
   `CONSULT_ROOT=<any repo>` and is ideal for "apply a lens to a file with Codex, headless," yet
   `SKILL.md` mentions it only as a footnote and never documents `CONSULT_ROOT`. Users reach for Path A
   (which can't) and never discover consult.
   **Ask:** add a first-class "Review an artifact in a DIFFERENT repo than the harness" recipe, e.g.:
   ```bash
   CONSULT_ROOT=/path/to/your/repo \
   relay-automation/consult.sh --models codex \
     --prompt-file Q.md --out "$TMPDIR/consult"
   ```

**Low-effort doc fixes (3–5):**

3. **"Run un-sandboxed" guidance collides with `$TMPDIR`-relative paths.** When a prompt/artifact is
   authored in a sandboxed step (`$TMPDIR` = the sandbox temp dir) and the CLI then runs un-sandboxed
   (`$TMPDIR` = a different dir, e.g. `/var/folders/…`), the path doesn't resolve (`prompt file not found`).
   **Ask:** add a one-line warning — "when a prompt/artifact is authored in a sandboxed step and
   consumed un-sandboxed, pass it by absolute path, not `$TMPDIR`."

4. **Credit where due:** `find-harness.sh` resolved the harness from an unrelated repo with zero config.
   Discovery of *the harness itself* is solved; only the inverse is missing.

5. **Doc smell reinforcing the assumption:** the README/skill artifact example
   (`skills/relay-xyz/SKILL.md`) is itself a path *inside* the harness clone. Every example reviews
   something in the harness repo — nothing shows reviewing a file in the repo you launched from, which
   quietly trains users into the Path-A-can't-do-cross-repo trap.

## Notes for triage

- Asks 1 and 2 are the load-bearing work (cross-repo targeting + surfacing the tool that already does
  it). 3–5 are low-effort doc fixes.
- Adjacent docs: [RELAY-XYZ-DISCOVERY-SHAKEDOWN.md](../2-WORKING/RELAY-XYZ-DISCOVERY-SHAKEDOWN.md)
  owns the *inverse* problem (harness discovery; explicit non-goal against scope creep) and
  [AUTOMATED-RELAY.md](../2-WORKING/AUTOMATED-RELAY.md) is the Completed relay harness hub. Neither owns
  cross-repo targeting, so this is genuinely new scope rather than a competing plan.
- Reporter offered to PR the doc changes (3–5) if useful.
