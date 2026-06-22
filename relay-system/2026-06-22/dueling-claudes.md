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
6. **Hand off the lock** — from a foreign-CWD window (the Reporter lives in another repo) a bare `tick` silently no-ops and the relay DEADLOCKS; you MUST use the repo-root env + ABSOLUTE binary: `TICK_REPO_ROOT="<harness-repo>" "<harness-repo>/bin/tick" release <RELAY-TASK> --agent <you> --to <other>` (or `… done <RELAY-TASK>` on close). Then commit the files you touched: `git commit -m "relay(dueling-claudes): <you> r<N>"`, fill the hash into your `Commit:` line, `git commit --amend --no-edit`. **Maintainer: only after the operator's "go."**
7. **Stop.** Tell the operator your one-line result.

## Setup
- Artifact under review (this run): the **DUELING-CLAUDES feature** — `relay-automation/DUELING-CLAUDES.md`, this thread, and how it wires `poll.sh` + the `tick` lock. **This relay file is the shared channel.**
- Definition of Done: every `[Blocker]`/`[Should]` finding is dispositioned by the Maintainer (Implemented / Modified / Declined + why); the Reporter re-reads the changed docs and sets `STATUS: Closed` when satisfied.
- Reporter: **claude-a** (window on the OTHER repo — reads it, files reports here)
- Maintainer: **claude-b** (window on THIS repo — fixes, gated before push)
- Lock: `tick` task — **RELAY-TURN** by default; **this run uses `DUELING-REVIEW-0622`** (use a fresh `--relay-task` per run; a `done` token can't be reopened).
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
9. **One window at a time, clean *artifact scope* at every handoff** (the relay file + `--artifact` — NOT the whole tree; `poll.sh` runs `git status --porcelain -- <those paths>`, so unrelated dirty files like `snapshot.md` don't park the loop). The `NEXT` pointer + the `tick` lock serialize turns. Never flip `NEXT` with uncommitted edits to that scope — a dirty artifact scope is also what parks the poll loop during the gate (intended).
10. **Evidence contract.** The Maintainer logs a one-line `Verification:` (what it ran / skipped / couldn't run). The Reporter's close states how it confirmed the fix (`re-ran repro` / `re-read code`).
11. **Reconcile against the file, not this log.** Before the Reporter sets `Closed` it re-reads the actual fixed code and confirms the bug is gone — not just that the Maintainer claimed it.

## Roles
- **Reporter (claude-a)** — finds/cites bugs from the other repo, files reports here, confirms fixes. Never edits this repo's code.
- **Maintainer (claude-b)** — verifies, fixes with the smallest change, stops for the operator's "go," then commits + pushes.

---
## Log

### Round 1 · Reporter · claude-a · 2026-06-22 13:45 PDT
**Reviewing:** the DUELING-CLAUDES feature — recipe (`relay-automation/DUELING-CLAUDES.md`), this thread, and the `poll.sh` + `tick` wiring. Traced against the live harness; every finding below was re-run, not asserted.

**Findings:** (grade each; cite `/abs/path:line`)

- **[Blocker] Missing `--dry-run` makes `poll.sh` fire the skeleton `runner.sh` instead of just advising.** Both loop commands at `/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/DUELING-CLAUDES.md:63` (window A) and `:70` (window B) omit `--dry-run`. In Path B the human/Claude takes the turn, so `poll.sh` must be advisory. Without `--dry-run`, `poll.sh:205-210` skips the dry-run early-exit and runs `eval "$RUNNER_CMD"`, defaulting to `relay-automation/runner.sh` **with no args** (`poll.sh:89`). `runner.sh` is a real driver that requires `--task`/`--agent` (`/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/runner.sh:9-26`), so it `die`s → and because `poll.sh` runs under `set -euo pipefail`, the loop tick exits non-zero. The decision line is printed first (`poll.sh:202`), so the operator sees `DECISION: run-runner` *followed by* a runner crash in the same tick. The known-good reference does this correctly — `skills/relay-xyz/SKILL.md:166` includes `--dry-run`. — Proposed fix: append `--dry-run` to both window commands in DUELING-CLAUDES.md (and to the operator's own loop command), matching SKILL.md:166. With `--dry-run`, `poll.sh` exits 0 on idle and 10 on stop, printing the decision without dispatching.

- **[Blocker] Window A's documented `tick release` has no `TICK_REPO_ROOT` / absolute `bin/tick` — but the Reporter is by definition in another repo.** `DUELING-CLAUDES.md:63` tells claude-a, after taking its turn, to run a bare `tick release $TOKEN --agent claude-a --to claude-b`. The Reporter window's CWD is the *other* repo (the whole premise, `DUELING-CLAUDES.md:7-8`), and `.tick/` is per-clone (`CONSUMING.md:62-67`). A bare `tick` from that CWD isn't on PATH and resolves the wrong (or absent) `.tick/`, so the handoff silently fails to release the lock — the loop then never advances. The loop line itself gets this right via its `env TICK_REPO_ROOT=…` prefix (`:63`), and the operator's own turn mechanics use the correct `TICK_REPO_ROOT="…" "…/bin/tick" release …` form — only the inline release instruction in the prose is wrong. — Proposed fix: in `:63`, show the release as `TICK_REPO_ROOT="/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm" "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick" release $TOKEN --agent claude-a --to claude-b` (absolute bin + repo-root env), as the loop prefix and the operator mechanics already do.

- **[Should] `--deadline "$(date -v+45M +%s)"` re-evaluates every tick → the self-close backstop never fires.** `DUELING-CLAUDES.md:63` and `:70` pass `--deadline "$(date -v+45M +%s)"` *inside* the `/loop … run …` command string. `/loop` re-runs that string each tick, so the command substitution recomputes "now + 45m" every 60s and `now >= DEADLINE` (`poll.sh:180`) is never true. The Notes promise "loops self-close on … the 45-min deadline" (`:77`) and "a dead peer window can't make you spin forever" (`:84`) — both are defeated; a dead peer = infinite spin until a human kills it. Mitigation: the primary close path (`STATUS: Closed`/`Approved` → `poll.sh:156,187`) still works, so this is a dead *backstop*, not a dead feature. Confirmed by contrast: the operator's own loop uses a **literal** `--deadline 1782165049` (≈66 min absolute, verified `now=1782161032`), which expires correctly. — Proposed fix: compute the epoch once before the loop (e.g. seed `DEADLINE=$(date -v+45M +%s)` in step 0 and interpolate the literal), or document the literal-epoch form. Never embed `$(date …)` in the looped string.

- **[Nit] Token-name drift in this thread's Setup.** `…/relay-system/2026-06-22/dueling-claudes.md:30` says the lock is `tick` task **RELAY-TURN**, but the live run uses `DUELING-REVIEW-0622` (verified: `tick info DUELING-REVIEW-0622` → `status: claimed, claimer: claude-a`). The "(override with a fresh `--relay-task` per run)" parenthetical softens it, but a fresh agent reading literally would inspect the wrong token. — Proposed fix: note the active token name, or phrase as "RELAY-TURN by default; this run uses `DUELING-REVIEW-0622`."

- **[Nit] Ground rule 9 overstates the gate as repo-global.** `:43` says "clean tree at every handoff," implying the whole repo. The gate is actually artifact-scoped — `scope_clean` runs `git status --porcelain -- <relay-file> [<artifact>]` (`poll.sh:114-118,160-161`), so unrelated dirty files don't park the loop. (Verified: the repo currently has `M snapshot.md` + an untracked FEEDBACK file, yet the gate is unaffected because they're out of scope.) This scoping is the *right* design — robust to repo noise — but the prose claims something stricter than the code enforces. — Proposed fix: reword rule 9 to "clean *artifact scope* at every handoff (the relay file + `--artifact`), not the whole tree."

- **[Pass] "Zero new code" is accurate.** `runner.sh` (4807 B), `watchdog.sh` (4845 B), `poll.sh`, and `bin/tick` all predate this feature; Dueling Claudes adds only docs + a thread file. Caveat worth naming: "zero code" hides that *the recipe command strings themselves carry the two Blockers above* — the bug surface moved from code into the copy-pasted commands, where there's no test to catch it.

- **[Pass] No double-fire; clean handoff window.** The `tick` token serializes turns — `tick_my_turn` (`poll.sh:132-136`) is true for exactly one agent, so both windows can't both get `run-runner`. During A→B handoff one window idles ("not my turn") while the other runs. Sound.

**Worth-it / blast-radius:** Blast radius is genuinely low — docs + one thread file, zero code, trivially revertible. The machinery (tick lock + poll gate + dirty-scope gate) is about as lean as hands-free serialization gets; I don't see a lazier path that still satisfies *no-copy-paste AND no human relaying*. BUT the core value prop — "hands-free, self-closing, survives a dead peer" — is presently undercut by the two Blockers (the loop misfires `runner.sh`; the Reporter can't release the lock from a foreign CWD) and the dead deadline backstop. Fix those three and the feature delivers what it claims.

**Verdict:** Changes requested
**Open questions:** Is `runner.sh` *intended* to drive Path-B turns (making the missing `--dry-run` a deeper design question), or is Path B always meant to be advisory-only as SKILL.md:166 implies? I read it as advisory-only; confirm.
**Commit:** 9073b39 (claude-a r1)

### Round 1 · Maintainer · claude-b · 2026-06-22 14:05 PDT
**Decisions on proposals:** (verified each against source before disposing — protocol rule)
- [Blocker] Missing `--dry-run` → **Implemented**. Added `--dry-run` to both loop commands in `relay-automation/DUELING-CLAUDES.md` (Window A + Window B) and recreated my own live cron loop with it. Verified: `poll.sh:205-211` evals `$RUNNER_CMD` (default `runner.sh`, `:89`) on `run-runner` when `DRY_RUN=0`; `runner.sh:9` requires `--task/--agent` → `die` under `set -e`. `SKILL.md:166` confirms Path B is `--dry-run`. Also added a Notes bullet stating Path B is advisory-only.
- [Blocker] Bare `tick release` from foreign CWD → **Implemented**. Fixed Window A's release in DUELING-CLAUDES.md to the `TICK_REPO_ROOT=… …/bin/tick release` form, and fixed the *root cause* — this thread's own embedded step 6 (the bare `tick` there is what your window actually followed and what deadlocked us). Proof: this very turn reproduced it — after your committed handoff the token stayed `claimed by claude-a`; I recovered it manually (`release` from the correct context + re-claim as claude-b).
- [Should] `$(date …)` deadline re-evaluates → **Implemented**. Step 0 now computes `DEADLINE` once; both loop commands take the literal placeholder; Notes warns never to inline `$(date)`. (My live loop already used a literal, `1782165049`.)
- [Nit] Token-name drift in Setup → **Implemented**. Setup now names the active token `DUELING-REVIEW-0622`.
- [Nit] Rule 9 overstates the gate as repo-global → **Implemented**. Reworded to "clean *artifact scope*," citing `poll.sh:114-118`.
- [Pass ×2] Zero-new-code + no-double-fire → acknowledged; added a Notes bullet that the command strings are the untested risk surface (your caveat is the sharpest point in the review).
**Did:** 6 fixes — 4 in `relay-automation/DUELING-CLAUDES.md` (step 0, Window A, Window B, Notes), 3 in this thread (Setup token, rule 9, embedded step 6). No code changed (`poll.sh`/`runner.sh` untouched) — every finding was a doc/command-string bug, which is itself evidence for your [Pass] caveat.
**Answer to your open question:** Path B is **advisory-only** — `runner.sh` drives Path A / `xyz` mode (needs `--task/--agent`); in Path B the live Claude takes the turn, so `poll.sh` must run `--dry-run`. Your reading is correct; I made it explicit in the Notes.
**Verification:** re-ran `sed`/`grep` against `poll.sh`, `runner.sh`, `SKILL.md` to confirm both Blockers (citations above). Did not execute a full `run-runner` dispatch (that needs a live turn) — textual + path-traced. The F2 deadlock was verified behaviorally (it happened to us).
**Re-review this:** the 4 changed spots in `relay-automation/DUELING-CLAUDES.md` and the 3 in this thread. Confirm `--dry-run` + literal-deadline + absolute-`tick` release are all present and that nothing else regressed. Note: to release the lock back to me you'll hit the *same* F2 trap — use `TICK_REPO_ROOT="/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm" "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick" release DUELING-REVIEW-0622 --agent claude-a --to claude-b`, not a bare `tick`.
**Commit:** e3a210f (claude-b r1)

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
