# RELAY · GLM 5.2 full review: GH-118/119/120+113/114 shipped work
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-03.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(glm-5-2-full-review-gh-118-119-120-113-114-shipped-work): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **.relay-artifacts/gh-glm-full-review-diff.txt** — the read-only path that
  `relay-drive.sh --artifact-file /tmp/gh-glm-full-review-diff.txt` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: aider   ·   Producer: claude-a
- Started: 2026-07-03
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer · aider

**Verdict: Changes requested** — one [Should] (docs/validate.sh contradiction), two [Nit]s. No [Blocker]s. All code changes are correct and well-tested.

**Findings:**

- **[Should] `relay-automation/README.md` — docs contradict `validate.sh` wiring.** The new "OpenRouter model-alias lookup" section states: *"`test/model-alias.sh` is a standalone script, not yet wired into `validate.sh`'s runner."* But `validate.sh` clearly includes `"model-alias.sh"` in the `TESTS` array (the diff adds it right after `aider-turn.sh`). Fix: update the README sentence to say it IS wired into `validate.sh`, e.g. *"`test/model-alias.sh` is wired into `validate.sh` alongside the other shim tests."*

- **[Nit] `relay-automation/aider-turn.sh` header comment — variable name mismatch.** The new `--read` doc comment (line ~45) references `RELAY_ARTIFACT_FILE` but the code reads `RTL_ARTIFACT` (set by `rtl_init` from `RELAY_ARTIFACT_FILE`). Minor, but could confuse a future reader tracing the variable. Fix: say *"the artifact under review (`RTL_ARTIFACT`, absolutized from `RELAY_ARTIFACT_FILE` by `relay-turn-lib.sh`)"* or just use `RTL_ARTIFACT` in the comment.

- **[Nit] `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-04.md` — `updated` date before `created` date.** Frontmatter has `created: 2026-07-04` / `updated: 2026-07-03`. The update date is one day before the creation date. Fix: set `updated: 2026-07-04` (or whichever is accurate).

- **[Pass] GH-119 fix in `aider-turn.sh`** — correctly adds `--read` flags for review-only turns (`ALLOW_PATHS` empty). Diff-file parsing with `sed -nE` extracts changed paths from both `diff --git a/X b/X` and `+++ b/X` lines; filters out the relay file (`$_cp != "$rel_relay"`) and non-existent paths (`-f "$ROOT/$_cp"`). The `${read_args[@]+"${read_args[@]}"}` expansion is bash 3.2-safe for the empty-array case. Build/fix path (ALLOW_PATHS set) is untouched.

- **[Pass] GH-120 `resolve-model-alias.sh`** — 4-tier fuzzy matching (normalized exact → squashed → sorted-token → substring) is well-designed. Verified: "Nemotron 3 Ultra" matches "nemotron ultra 3" at tier 2 (squashed); "nemotron-ultra3" matches at tier 2; "Nemotron 3 Ultra Free" matches the free variant at tier 2 without colliding with the base alias. The free variant stays distinct because the base alias matches first in file order at a higher tier. `test/model-alias.sh` coverage is comprehensive (exact, case-insensitive, punctuation, reordered, hyphenated, free-variant, unknown→exit 1, usage→exit 2).

- **[Pass] GH-109 `consult.sh`** — `pkill -P "$kpid"` before `kill "$kpid"` correctly reaps the orphaned `sleep` grandchild. macOS/BSD-compatible. Comment explains the pattern so it won't be reverted.

- **[Pass] GH-109 `relay-xyz-guard.sh`** — `${UID}` suffix on `STATE_DIR` is the correct multi-user `/tmp` collision fix. `$UID` is set by bash itself (no subprocess).

- **[Pass] GH-110 `xyz-vendor.sh`** — `find "$STAGE_DIR" -name '.DS_Store' -delete` after the copy loop is the simplest portable approach; no rsync dependency.

- **[Pass] GH-114 test cleanup** — deleting `test/gemini-turn.sh` and swapping `gemini`→`agy` in 4 test files is correct. The agy-specific stubs in `relay-turn-timeout.sh` (handling the `whoami` auth pre-flight) are a thoughtful addition that the other shims don't need. `validate.sh` correctly drops `gemini-turn.sh` and adds `model-alias.sh`.

- **[Pass] GH-119 test in `test/aider-turn.sh`** — the `ARGS_DUMP` hook is a clean inspection mechanism that mirrors how the stub already models Aider. The test correctly asserts `READ:src/target.txt` is present, `FILE:src/target.txt` is absent, and `READ:$ARTIFACT` is present.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
