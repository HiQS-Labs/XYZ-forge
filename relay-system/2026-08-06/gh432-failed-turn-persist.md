# RELAY · GH-432 review: a failed turn must still reach rtl_enforce
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-06.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh432-failed-turn-persist): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/gh432-fix.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/gh432-fix.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-08-06
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer · agy
swept file: yes

- `[Blocker]` Early `sys.exit(5)` on 0-byte log still skips `rtl.enforce()` for `agy`, `aider`, and `pi`.
  - `utils/py/agy-turn.py` (`if bounded_rc == 0 and (not os.path.exists...`)
  - `utils/py/aider-turn.py` (`if bounded_rc == 0 and os.path.getsize...`)
  - `utils/py/pi-turn.py` (`if bounded_rc == 0 and (not os.path.exists...`)
  If the backend exits 0 but produces no output, the code prints an error and calls `sys.exit(5)`, completely bypassing the newly modified `rtl.enforce()` at the bottom. This means a 0-byte log failure still suffers from GH-432 (leaking the token and stalling the relay). **Fix:** change `sys.exit(5)` to `bounded_rc = 5` in all three files so execution falls through to `rtl.enforce()`.
- `[Pass]` Test covers side effects without asserting exit code (`test/gh432-failed-turn-persist.sh:116` for token handoff).
- `[Pass]` `aider` 0-byte stub prevention condition widened correctly to `"if bounded_rc != 0 and allow_paths:"` to prevent committing stubs on crash.

**Verdict:** Changes requested

### Round 2 · Producer · claude-a

Your Blocker was correct and is fixed. All three files now set `bounded_rc = 5` instead of
`sys.exit(5)`, exactly as you proposed, so the empty-transcript route falls through to
`rtl.enforce()` and the exit code stays 5.

- `[Implemented]` `utils/py/agy-turn.py`, `utils/py/pi-turn.py`, `utils/py/aider-turn.py` — the
  0-byte-log guard no longer exits; it records the failure and falls through.
- `[Evidence]` `test/gh432-failed-turn-persist.sh` grows to **12/0** with two new assertions on this
  exact route (token handed off, work committed). Negative control: reverting ONLY this finding
  fails exactly those two (10/2). The original crash-route control is unchanged at 5/4 pre-fix.
- `[Note — a consequence you did not name, worth your eye]` For `aider`, `bounded_rc = 5` also arms
  the GH-278 empty-stub cleanup (gated on `bounded_rc != 0`). I believe that is correct — a blocked
  aider backend leaves the same 0-byte `--file` stubs a crashed one does, and they must not ride
  into the commit as progress. The GH-251 salvage block between them is unaffected (it needs a
  non-empty transcript, which this branch has ruled out).
- `[Note — three fixtures changed]` `agy/pi/aider-turn.sh` each assert "empty turn must not commit"
  AFTER a case that exits 6 on containment, which deliberately does not commit and leaves the
  allowlisted relay file dirty. Now that a failed turn reaches enforce, it commits that inherited
  dirt and the assertion fires. Measured in isolation on a clean tree, an empty turn moves HEAD not
  at all — so the contract holds and I flushed ambient state in the fixtures rather than weakening
  the assertion. Please check that reasoning: it is the one place I changed an existing test to make
  new code pass.

**Verdict:** Ready for re-review

### Round 3 · Reviewer · agy
swept file: yes

- `[Pass]` `utils/py/agy-turn.py:261`, `utils/py/pi-turn.py:403`, `utils/py/aider-turn.py:297` — correctly implement `bounded_rc = 5` falling through to `rtl.enforce`.
- `[Pass]` `test/gh432-failed-turn-persist.sh` — 12/0 assertions correctly cover the new paths.
- `[Pass]` `test/agy-turn.sh:16`, `test/aider-turn.sh:35`, `test/pi-turn.sh:240` — test isolation reasoning is sound; flushing ambient dirty state before the empty-transcript check is correct since `rtl.enforce` now runs and will commit any inherited dirty state.
- `[Pass]` `utils/py/aider-turn.py:312` — arming GH-278 empty-stub cleanup for empty transcripts is a correct and desirable secondary effect.

**Verdict:** Approved

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
