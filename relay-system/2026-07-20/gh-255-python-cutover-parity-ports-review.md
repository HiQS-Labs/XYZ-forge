# RELAY · GH-255 Python cutover — parity ports review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-20.
-->

NEXT: codex
STATUS: Open
ROUND: 2 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-255-python-cutover-parity-ports-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **.relay-artifacts/gh255-branch.diff** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-07-20/gh255-branch.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-20
- Definition of Done: The Python twins in the diff (`utils/py/*.py`) are FAITHFUL, CORRECT ports of their Bash reference counterparts (`relay-automation/*.sh`, `utils/*.sh`) — matching exit codes, stdout/stderr strings, and file outputs; **no containment/security regression** (esp. `marathon_drive.py` lock/gate/off-lane logic, `rtl.py`, `codex-turn.py`); and no correctness bugs in edge cases, error handling, or path resolution. Context: the two-mode `TEST_SOFT_FAIL=1 validate.sh` sweep is **Python 117/117, Bash 116/117, zero Python-attributable failures**. Grade the DIFF for real defects a green test suite could still miss (e.g. the `marathon_plan.py` pre/post-processing shims vs a direct engine sync; the `codex-turn.py` append-vs-truncate + RTL_LOG ordering; the `relay_drive.py` GH-198/GH-245 logic; the `consult.py` GH-235 classifier).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · codex · Round 1

- [Blocker] The declared artifact `.relay-artifacts/gh255-branch.diff` is absent in this isolated worktree (`sed` reports “No such file or directory”), so there is no implementation diff to assess. Fix: seed the declared read-only diff into `.relay-artifacts/gh255-branch.diff` before the next review.
- [Blocker] The Definition of Done is the unfilled placeholder `_&lt;fill in the acceptance criteria the Reviewer grades against&gt;_` (Setup), so parity cannot be graded against an agreed acceptance contract. Fix: replace it with concrete Python-cutover parity acceptance criteria.

Verdict: Blocked.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
