# RELAY · Dueling Claudes — code/protocol review of the Codex relay machinery
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
  Recipe for running this hands-free: relay-automation/DUELING-CLAUDES.md
-->

NEXT: claude-a
STATUS: Open
ROUND: 1 / 5

## ▶ TAKE YOUR TURN — read this first (works for ANY agent)
The operator (or the poll loop) said "take your turn on this file." Everything you need is **in this file**.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (see Setup) **and** the last Log block isn't already yours. If not -> STOP and reply "wrong window — nudge the other window."
3. **Do your role's work:**
   - **Reporter (claude-a):** review the Codex relay machinery named in Setup — read the real code (cite by **absolute path**; you may live in another repo, so relative paths won't resolve here). This run is a CODE/PROTOCOL REVIEW, not a single repro: hunt the failure mode that makes a Codex relay "slightly problematic" — correctness bugs, missing guardrails, silent-failure paths, sandbox/auth assumptions, drift between codex-turn.sh and the shared relay-turn-lib.sh. Write crisp graded findings: what's wrong, where (`/abs/path:line`), why it bites, and a concrete proposed fix. This is a report, not a fix — you do **not** edit code. Append your block, set a Verdict, hand off to the Maintainer.
   - **Maintainer (claude-b):** verify each reported finding against the real code (a finding can be wrong or worse than flagged), fix the `[Blocker]`/`[Should]` ones with the **smallest change that works**, log a disposition (Implemented / Modified / Declined + why) for every finding, append your block + a `Verification:` line. **Then STOP — show the operator your diff and do NOT commit, push, or release the token until they say "go."** This is the one human gate. After "go": commit + push, then hand off to the Reporter to confirm.
   - **Reporter (claude-a), re-review round:** re-read the **actual changed code** (not the Maintainer's claims) and confirm each fix landed and resolves the finding. If resolved -> set `STATUS: Closed`. If not -> `Changes requested` with a `[Blocker] claimed-implemented-but-absent @ file:line`, hand back to the Maintainer.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; bump `ROUND` when the Reporter opens a new cycle; set `STATUS` (`Closed` ends the relay).
6. **Hand off the lock** — from a foreign-CWD window (the Reporter may live in another repo) a bare `tick` silently no-ops and the relay DEADLOCKS; you MUST use the repo-root env + ABSOLUTE binary: `TICK_REPO_ROOT="/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm" "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick" release DUELING-CODEX-0623 --agent <you> --to <other>` (or `... done DUELING-CODEX-0623` on close). Then commit the files you touched: `git commit -m "relay(codex-relay-review): <you> r<N>"`, fill the hash into your `Commit:` line, `git commit --amend --no-edit`. **Maintainer: only after the operator's "go."**
7. **Stop.** Tell the operator your one-line result.

## Setup
- Artifact under review: the **Codex relay machinery** — primary `relay-automation/codex-turn.sh` (the Codex turn driver) and the shared `relay-automation/relay-turn-lib.sh` it depends on. The trouble: a recent real relay with Codex was "slightly problematic" — find why, in the code/protocol. **This relay file is the shared channel.**
- Definition of Done: a CODE/PROTOCOL REVIEW — every `[Blocker]`/`[Should]` finding on the Codex relay machinery is dispositioned by the Maintainer (Implemented / Modified / Declined + why) and the Reporter re-reads the changed code and sets `STATUS: Closed` when the failure mode is closed (or explicitly contained + logged).
- Reporter: **claude-a** (the second Claude window — reads the code, files reports here; never edits code)
- Maintainer: **claude-b** (this session, window on THIS repo — verifies + fixes, gated before commit/push)
- Lock: `tick` task **DUELING-CODEX-0623** (a `done` token can't be reopened — use a fresh `--relay-task` per run).
- Handoff: hands-free poll (all-Claude) — see relay-automation/DUELING-CLAUDES.md
- Started: 2026-06-23

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two windows never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND`.
4. Stay tight. Reports and findings are bullets, not essays.
5. **The Reporter never edits code.** It reports graded findings, each with a concrete proposed fix; the Maintainer fixes. Every code change flows through the Maintainer.
6. Grade findings: `[Blocker]` must fix · `[Should]` strong rec · `[Nit]` optional · `[Pass]` checked and sound (records what was verified, not assumed).
7. **The Maintainer stops before commit/push every fix turn** — the operator's "go" is the gate. No `git commit`/`git push` without it.
8. End your turn by committing it (Maintainer: post-"go"): `relay(codex-relay-review): <role> r<N>`, fill the hash into `Commit:`. A Reporter turn touches only this log; if the log is gitignored write `Commit: none (comments only)`.
9. **One window at a time, clean *artifact scope* at every handoff** (the relay file + the code under review — NOT the whole tree; `poll.sh` runs `git status --porcelain` against the scoped paths, so unrelated dirty files don't park the loop). The `NEXT` pointer + the `tick` lock serialize turns. Never flip `NEXT` with uncommitted edits to that scope — a dirty scope is also what parks the poll loop during the Maintainer gate (intended).
10. **Evidence contract.** The Maintainer logs a one-line `Verification:` (what it ran / skipped / couldn't run). The Reporter logs a verdict `Basis:` — `behaviorally proven` (ran/observed) or `textual only` (read, not run) — and classes prior fixes `textually fixed` vs `behaviorally proven`. Shell code that can't be safely executed here is honestly `textual only`.
11. **Reconcile against the file, not this log.** Before the Reporter sets `Closed` it re-reads the **actual fixed code** and confirms the failure mode is gone — not just that the Maintainer claimed it.

## Roles
- **Reporter (claude-a)** — reviews the Codex relay machinery, files graded findings + proposed fixes here, confirms fixes. Never edits code.
- **Maintainer (claude-b)** — verifies each finding, fixes with the smallest change, stops for the operator's "go," then commits + pushes.

---
## Log

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
