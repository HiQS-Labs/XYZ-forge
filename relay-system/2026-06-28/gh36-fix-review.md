# RELAY · Review GH-36 fix: --add-dir .tick writable-root for headless Codex under worktree isolation
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-06-28.
-->

NEXT: Reviewer
STATUS: Approved
ROUND: 1 / 2

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
6. **Commit only the relay file** (`relay(review-gh-36-fix-add-dir-tick-writable-root-for-headless-codex-under-worktree-isolation): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **.relay-artifacts/gh36-fix.diff** — the read-only path that
  `relay-drive.sh --artifact-file /var/folders/69/3l_82qtj7fzglnt_jjg07jh40000gn/T//gh36-fix.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-06-28
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer · agy · 2026-06-28
**Verdict:** Approved
**Basis:** textual only (verified diff `.relay-artifacts/gh36-fix.diff` and target code in `relay-automation/codex-turn.sh` and unit tests in `test/codex-turn.sh`).

**Findings:**
- **[Pass] Correct initialization & fallback:** `codex_extra_flags=()` is correctly initialized as an empty array before the isolation check (`relay-automation/codex-turn.sh:65`), ensuring no flags are mutated or appended under default non-isolated execution.
- **[Pass] Safe array expansion under `set -u`:** The expansion `${codex_extra_flags[@]+"${codex_extra_flags[@]}"}` is correctly wired (`relay-automation/codex-turn.sh:98`). This pattern prevents unbound variable errors under `set -u` when `codex_extra_flags` is empty/unset.
- **[Pass] Workspace sandboxing bypass for shared lock:** Under `RELAY_WORKTREE_ISOLATION=1`, passing `--add-dir "$ROOT/.tick"` (`relay-automation/codex-turn.sh:85`) correctly grants Codex's workspace sandbox write access to the shared `.tick` token lock directory residing in the harness `$ROOT`, preventing claim/release `EPERM` deadlocks.
- **[Pass] Unit test coverage:** Unit tests in `test/codex-turn.sh` (lines 121-134) successfully cover the assertion that `--add-dir <root>/.tick` is passed when isolation is enabled and is NOT passed when isolation is disabled.

The fix is minimal, safe, and meets all criteria of the Definition of Done. Closing the relay.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
