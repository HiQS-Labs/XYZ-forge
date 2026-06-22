# RELAY · Dueling Claudes — inaugural run: a Giant Brains session reviews the DUELING-CLAUDES feature
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
  Recipe for running this hands-free: relay-automation/DUELING-CLAUDES.md
-->

NEXT: Reporter
STATUS: Open
ROUND: 1 / 5

## ▶ TAKE YOUR TURN — read this first (works for ANY agent)
The operator (or the poll loop) said "take your turn on this file." Everything you need is **in this file**.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (see Setup) **and** the last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the other window."
3. **Do your role's work:**
   - **Reporter (claude-a):** find/reproduce a bug — cite the offending code by **absolute path** (you live in another repo, so relative paths won't resolve here). Write a crisp report: what's wrong, where (`/abs/path:line`), repro steps, expected vs actual. This is a request, not a fix — you do **not** edit code. Append your block, hand off to the Maintainer.
   - **Maintainer (claude-b):** verify the reported bug against the real code, fix it with the **smallest change that works**, append your block describing the fix + a `Verification:` line. **Then STOP — show the operator your diff and do NOT commit, push, or release the token until they say "go."** This is the one human gate. After "go": commit + push, then hand off to the Reporter to confirm.
   - **Reporter (claude-a), re-review round:** confirm the fix actually resolves the bug (re-read the file / re-run the repro). If resolved → set `STATUS: Closed`. If not → `Changes requested` with a `[Blocker]`, hand back to the Maintainer.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; bump `ROUND` when the Reporter opens a new cycle; set `STATUS` (`Closed` ends the relay).
6. **Hand off the lock.** `tick release <RELAY-TASK> --agent <you> --to <other>` (or `tick done <RELAY-TASK>` on close). Then commit the files you touched: `git commit -m "relay(dueling-claudes): <you> r<N>"`, fill the hash into your `Commit:` line, `git commit --amend --no-edit`. **Maintainer: only after the operator's "go."**
7. **Stop.** Tell the operator your one-line result.

## Setup
- Artifact under review (this run): the **DUELING-CLAUDES feature** — `relay-automation/DUELING-CLAUDES.md`, this thread, and how it wires `poll.sh` + the `tick` lock. **This relay file is the shared channel.**
- Definition of Done: every `[Blocker]`/`[Should]` finding is dispositioned by the Maintainer (Implemented / Modified / Declined + why); the Reporter re-reads the changed docs and sets `STATUS: Closed` when satisfied.
- Reporter: **claude-a** (window on the OTHER repo — reads it, files reports here)
- Maintainer: **claude-b** (window on THIS repo — fixes, gated before push)
- Lock: `tick` task **RELAY-TURN** (override with a fresh `--relay-task` per run — a `done` token can't be reopened).
- Handoff: hands-free poll (all-Claude) — see relay-automation/DUELING-CLAUDES.md
- Started: 2026-06-22

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two windows never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND`.
4. Stay tight. Reports and findings are bullets, not essays.
5. **The Reporter never edits code.** It reports; the Maintainer fixes. Every code change flows through the Maintainer.
6. Grade findings: `[Blocker]` must fix · `[Should]` strong rec · `[Nit]` optional · `[Pass]` checked and sound.
7. **The Maintainer stops before commit/push every fix turn** — the operator's "go" is the gate. No `git push` without it.
8. End your turn by committing it (Maintainer: post-"go"): `relay(dueling-claudes): <role> r<N>`, fill the hash into `Commit:`.
9. **One window at a time, clean tree at every handoff.** The `NEXT` pointer + the `tick` lock serialize turns. Never flip `NEXT` with uncommitted edits in the tree — the dirty tree is also what parks the poll loop during the gate (intended).
10. **Evidence contract.** The Maintainer logs a one-line `Verification:` (what it ran / skipped / couldn't run). The Reporter's close states how it confirmed the fix (`re-ran repro` / `re-read code`).
11. **Reconcile against the file, not this log.** Before the Reporter sets `Closed` it re-reads the actual fixed code and confirms the bug is gone — not just that the Maintainer claimed it.

## Roles
- **Reporter (claude-a)** — finds/cites bugs from the other repo, files reports here, confirms fixes. Never edits this repo's code.
- **Maintainer (claude-b)** — verifies, fixes with the smallest change, stops for the operator's "go," then commits + pushes.

---
## Log

### Round 1 · Reporter · claude-a · <YYYY-MM-DD HH:MM TZ>
**Reviewing:** the DUELING-CLAUDES feature (recipe + this thread + its poll.sh/tick wiring)
**Findings:** (grade each; cite `/abs/path:line`)
- [Blocker|Should|Nit|Pass] <finding> — Proposed fix: <concrete suggestion, or "author's call">
**Verdict:** Changes requested | Approve as-is | Rethink
**Open questions:** <or "none">
**Commit:** <hash or "none (comments only)">

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
