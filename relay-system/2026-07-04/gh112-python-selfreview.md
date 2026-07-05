# RELAY · GH-112 Python layer self-review (Python-mode dogfood)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-04.
-->

NEXT: Producer
STATUS: Open
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
6. **Commit only the relay file** (`relay(gh112-python-selfreview): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **.relay-artifacts/rtl.py** — the read-only path that
  `relay-drive.sh --artifact-file utils/py/rtl.py` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-04
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer — codex — Round 1 — 2026-07-04
Verdict: Changes requested

- [Blocker] `.relay-artifacts/rtl.py:44-45` exits the whole Python process from `_run_rtl()` on any non-zero shell status. That makes `before()`, `enforce()`, and the failure branch in `worktree_begin()` unreachable as written (`.relay-artifacts/rtl.py:62-76`). Concrete fix: do not call `sys.exit()` inside `_run_rtl()`; return the `CompletedProcess` and let each public method decide whether to propagate the code, raise, or map it to `None`/`False`.
- [Should] `.relay-artifacts/rtl.py:24-27,37-38` interpolates `self.xyz_root`, `self.state_file`, and `TICK_REPO_ROOT` directly into a shell script inside double quotes. A path or env value containing `"`/command substitutions/newlines can break the script or inject shell syntax. Concrete fix: shell-quote every interpolated value with `shlex.quote(...)`, or pass `TICK_REPO_ROOT` through `subprocess.run(..., env=...)` instead of embedding it in the script.
- [Nit] `.relay-artifacts/rtl.py:16-20` relies on `__del__()` for temp-file cleanup. Destructor timing is not guaranteed, and a partially initialized instance can hit `__del__` without a valid `state_file`. Concrete fix: add an explicit `close()` or context-manager path for cleanup and guard the destructor with `hasattr(self, "state_file")`.
- [Pass] `.relay-artifacts/rtl.py:26-39` preserves `RTL_*` shell state across calls, which is the right shape for a thin Python wrapper over the existing relay shell library.

Verification: source inspection only; no tests run on this reviewer turn.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
