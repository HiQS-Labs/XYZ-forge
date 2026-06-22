---
gh_issue: 11
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/11
title: "relay-xyz: hard to target a repo other than the harness clone (cross-repo reviews)"
status: Active
created: 2026-06-21
updated: 2026-06-21
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
| **Ask 1 flag increment landed** — `--target-root` parse + git-repo validation + `RELAY_TARGET_ROOT` export in `relay-drive.sh` (built by agy, Codex-approved, `validate.sh` 35/35). Inert until the kernel-wiring round. | **Kernel wiring** — `relay-turn-lib.sh` consuming `RELAY_TARGET_ROOT` (worktree base + `ALLOW_PATHS` against the foreign root): Ask 1's load-bearing half. Then Codex's empty-string `[Nit]` + Asks 2–5 (surface consult + doc fixes). |

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

5. **Doc smell reinforcing the assumption:** the QUICKSTART artifact example
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
