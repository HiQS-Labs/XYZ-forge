# [SHAKEDOWN] relay-xyz — 2026-08-17 11:18 PDT

**Target:** relay-xyz (`skills/relay-xyz`)
**Target HEAD:** `e80e1fc` — Ballast 0.7.0: land #4 and #3, cut #10, write the release's exit criterion
**Env:** Darwin 24.6.0 arm64 · GNU bash 3.2.57
**Verdict:** [path bug reproduced] — the mandatory first command failed outside the repository root; the installed-root locator repaired it.

## Static audit

The pre-fix load-bearing finding was:

```text
[block] bash skills/relay-xyz/find-harness.sh --check
        path-relative; resolves against the caller's CWD
```

Both bundled scripts passed hygiene: valid bash shebangs, executable bits, and symlink-safe
`BASH_SOURCE` self-location. The grader also flags repo-relative commands later in the document.
Those commands follow the explicit precondition that resolves `HARNESS` and runs `cd "$HARNESS"`;
they are not independent discovery entry points. The report therefore does not promote those
context-free grep matches into findings.

## Live harness

Run A executed the documented command verbatim. It returned exit 127 / `No such file or directory`
in all eight scenarios: skill CWD, foreign CWD, nested CWD, a path containing spaces, project-level
install, user-level install, symlinked install, and stripped executable bit.

Run B invoked the copied locator by its quoted, anchored skill path with `XYZ_HARNESS` supplied as
the documented runtime override. It returned exit 0 in all eight scenarios, including the path with
spaces and the symlinked install. The harness printed `NOT-FOUND` despite those zero exits because it
classifies any stderr containing the phrase `not found` as a discovery failure; the locator's
readiness report legitimately uses that phrase for optional worker availability. Per shakedown's
honesty rule, the zero exit and executed locator are treated as found; the label is a harness
false-positive, not hidden.

## Proposed patch

Applied in this change:

```diff
-bash skills/relay-xyz/find-harness.sh --check
+L=""
+for candidate in "${XYZ_HARNESS:+$XYZ_HARNESS/skills/relay-xyz/find-harness.sh}" \
+                 "$HOME/.claude/skills/relay-xyz/find-harness.sh" \
+                 "$(git rev-parse --show-toplevel 2>/dev/null)/.claude/skills/relay-xyz/find-harness.sh" \
+                 "$(git rev-parse --show-toplevel 2>/dev/null)/skills/relay-xyz/find-harness.sh"; do
+  [ -n "$candidate" ] && [ -f "$candidate" ] && { L="$candidate"; break; }
+done
+[ -n "$L" ] || { echo "relay-xyz: locator not found — install the skill or set XYZ_HARNESS" >&2; exit 1; }
+bash "$L" --check
```

`test/find-harness.sh` now pins the user-install anchor and rejects the old CWD-relative first
command. Focused result after the repair: 23 passed, 0 failed.

## What I could not verify

Shakedown verifies shell-path behavior; it does not instrument Claude Code's internal skill
resolver. The matrix did not execute a paid Codex/agy relay. It also did not live-test every bundled
skill: all script-calling skills received the static audit, while the live matrix targeted
`relay-xyz`, the README's primary installed skill and the only load-bearing public entry point found
with a reproduced discovery failure.
