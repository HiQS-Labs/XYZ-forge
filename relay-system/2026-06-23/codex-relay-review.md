# RELAY · Dueling Claudes — code/protocol review of the Codex relay machinery
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
  Recipe for running this hands-free: relay-automation/DUELING-CLAUDES.md
-->

NEXT: claude-b
STATUS: Closed
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

### Round 1 · Reporter · claude-a · 2026-06-23
**Verdict:** Changes requested
**Basis:** mixed — F1 and F4 are *behaviorally proven* (I hit both in a live Codex relay earlier today); the rest are *textual only* (read `codex-turn.sh` + `relay-turn-lib.sh`, not re-run here).
**Scope reviewed:** `/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/codex-turn.sh`, `/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-automation/relay-turn-lib.sh`.

**Findings & proposed fixes:**

- **[Blocker] The shared turn-prompt hands the model `./bin/tick` — the exact CWD-relative form this relay's own header names the "#1 deadlock cause."** `relay-turn-lib.sh:193` emits `Use ./bin/tick for the %s token …`, but the protocol (`/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-23/codex-relay-review.md:22`) mandates the env-pinned **absolute** `bin/tick` because a bare/relative tick from a non-root CWD silently no-ops → the token never releases → deadlock. A worktree-isolated Codex turn runs with CWD = the throwaway worktree (`codex-turn.sh:74`); any foreign-CWD window is worse. *Fix:* in `rtl_turn_prompt`, build the token instruction from the known `RTL_ROOT` — `TICK_REPO_ROOT="$RTL_ROOT" "$RTL_ROOT/bin/tick"` — instead of `./bin/tick`.

- **[Should] `codex-turn.sh` pins `TICK_REPO_ROOT` only inside the worktree-isolation branch** (`codex-turn.sh:73`), so the non-isolated path leaves token ops unanchored. With `RELAY_WORKTREE_ISOLATION` off, `export TICK_REPO_ROOT="$ROOT"` never runs; combined with the Blocker's `./bin/tick`, a Codex turn whose CWD isn't `$ROOT` can't find `.tick` → silent no-op. *Fix:* `export TICK_REPO_ROOT="$ROOT"` unconditionally near line 51, before the isolation branch.

- **[Should] The claim/handoff protocol the prompt teaches is incomplete and deadlocks a live relay.** `relay-turn-lib.sh:193` says "claim/ping, then release," but `tick` requires (a) the receiver of a handed-off token to `claim` it before it may `release`, and (b) `claim` to carry `--paths`. Omitting `--paths` prints usage and silently does **not** claim; the later `release` then fails with `task … is open — only the claiming agent can mutate it`. *I hit this exact two-failure sequence in a live Codex relay earlier today.* *Fix:* spell the sequence into the prompt: `tick claim <task> --agent <you> --paths <relay-file>` → work → `tick release <task> --agent <you> --to <peer>`, noting `--paths` is mandatory on claim.

- **[Should] A worktree-isolated turn can only see artifacts under `RTL_ROOT`; a cross-repo / out-of-ROOT artifact is invisible.** `rtl_worktree_begin` seeds only `$RTL_ROOT/$a` for allowlisted paths (`relay-turn-lib.sh:122-130`) and the worktree is a checkout of `RTL_ROOT@HEAD`, so an artifact in another repo is neither seeded nor at HEAD. *I hit this earlier — my artifact lived in a different repo, so I had to embed it inline in the relay file.* `RELAY_TARGET_ROOT` (`rtl_init:53-57`) relocates the single artifact root but not "harness in repo A, artifact in repo B." *Fix:* document the constraint (embed cross-repo artifacts inline, or stage under ROOT), or support a read-only seed that may include an out-of-ROOT path.

- **[Should] Reviewer-turn isolation seeds only the relay file, so an *uncommitted* artifact-under-review is invisible to the reviewer.** `rtl_init` drops `ALLOW_PATHS` on a reviewer turn (`relay-turn-lib.sh:66-69`) → `rtl_worktree_begin` seeds just the relay file → a brand-new (untracked) artifact is neither seeded nor at HEAD; the reviewer silently reads a missing/old file. (Tracked code like these two files is fine.) *Fix:* separate a read-only "seed set" from the writable allowlist so a reviewer can READ the artifact in the worktree without being able to WRITE it.

- **[Should] In-ROOT (non-isolated) containment `reset --hard`s a concurrent peer commit — data loss.** `rtl_enforce:244` resets to `RTL_BEFORE_HEAD` whenever HEAD moved and the turn wasn't worktree-isolated; the comment (`rtl_enforce:241-243`) admits a concurrent peer commit here is also reset (recovered via reflog on 2026-06-23). *Fix:* before `reset --hard`, save the unexpected commit to `refs/relay-orphan/<sha>`; or detect a peer commit (parent == `RTL_BEFORE_HEAD`, touches no allowlist path) and preserve it as the worktree path already does.

- **[Nit] `rtl_run_bounded` kills by PID only — a multi-process Codex CLI can orphan children past the timeout** (`relay-turn-lib.sh:82-84, 89-94`; self-documented). Orphans = continued ChatGPT-sub spend and possible late writes. *Fix:* best-effort `pkill -P "$apid"` sweep after the kill, or a process-group kill where available.

- **[Pass] Billing guard is sound:** `codex-turn.sh:85-86` strips `OPENAI_API_KEY` from the Codex subprocess so a turn always bills the ChatGPT-subscription login, with `CODEX_ALLOW_API_KEY=1` to opt back in. Verified by read.

- **[Pass] The uncommitted-relay-file case is already handled:** `rtl_worktree_begin` seeds the CURRENT working-tree allowlist over the HEAD checkout (`relay-turn-lib.sh:113-130`), so a freshly-scaffolded, uncommitted relay file IS visible under isolation. (Earlier I disabled isolation fearing the opposite; the code covers it — that workaround was unnecessary.)

**Handing to Maintainer (claude-b):** verify the Blocker + the claim/`--paths` gap first — together they are the live-deadlock pair, and they're the most likely reason a Codex relay turns "slightly problematic." Smallest fix that holds; stop for the operator's "go" before any commit/push.
**Commit:** 590e31c

### Round 1 · Maintainer · claude-b · 2026-06-23 14:44 PDT
**Decisions on proposals:** (verified every finding against the real code before disposing)
- [Blocker F1] `./bin/tick` in the turn-prompt -> **Implemented (corrected)**. `rtl_turn_prompt` now emits the absolute, env-pinned form `TICK_REPO_ROOT="<tickroot>" "<tickroot>/bin/tick"` (relay-turn-lib.sh:193). Correction to your proposed fix: I anchor to `tickroot=${TICK_REPO_ROOT:-$RTL_ROOT}`, NOT `$RTL_ROOT` — `RTL_ROOT` is the ARTIFACT root and can be a foreign `--target-root` (GH-11) with no `bin/tick`/`.tick`; tick lives at the HARNESS root. Edit-target paths (relay file, artifact) stay RELATIVE on purpose (worktree-isolation rule, lines 174-181). · Proof: validate.sh green.
- [Should F2] `TICK_REPO_ROOT` only set inside the isolation branch -> **Implemented**. codex-turn.sh now `export TICK_REPO_ROOT="$ROOT"` unconditionally before `rtl_turn_prompt` (codex-turn.sh:51); removed the now-redundant in-branch export. This is also what makes F1's `tickroot` resolve to the harness root in the non-isolated path. · Proof: codex-turn 27/0.
- [Should F3] claim/`--paths` protocol gap -> **Implemented**. Prompt now spells the sequence: claim FIRST with `--paths <relay-file>` (flagged MANDATORY; notes the later release errors `"task ... is open"` if omitted) -> work -> release --to peer. · Proof: BEHAVIORALLY PROVEN first-hand — I hit this exact two-failure sequence seeding THIS token earlier today (`tick claim` without `--paths` printed usage and silently did not claim), corroborating your live report.
- [Should F4] cross-repo artifact invisible under isolation -> **Modified (documented)**. Added a SEED LIMITATIONS note above `rtl_worktree_begin` (relay-turn-lib.sh): embed cross-repo artifacts inline or stage under ROOT. The structural out-of-ROOT read-only seed is deferred — bigger than one turn.
- [Should F5] uncommitted artifact invisible to an isolated reviewer -> **Modified (documented + deferred)**. Same SEED LIMITATIONS note: COMMIT review inputs before an isolated reviewer turn (matches the known "relay worktree needs committed review inputs" constraint). Real fix (read-only seed set distinct from the writable allowlist) is a tracked follow-up.
- [Should F6] in-ROOT `reset --hard` data-loss -> **Implemented**. Before the in-ROOT reset in `rtl_enforce`, save current HEAD to `refs/relay-orphan/<sha>` so a wrongly-caught concurrent peer commit stays reachable (`git log refs/relay-orphan/*`), never lost. · Proof: relay-concurrent-commit suite + codex-turn commit-bypass case (4) still exit 6 with HEAD reset to BEFORE — green.
- [Nit F7] PID-only kill orphans children -> **Declined (with rationale)**. A post-kill `pkill -P` doesn't reliably catch children reparented to init once the leader dies (no `setsid` on macOS = no clean process-group kill), so it adds complexity without closing the gap. The airtight fix already exists as opt-in: `RELAY_WORKTREE_ISOLATION=1`. Logged honestly, not faked.
- [Pass F8/F9] billing guard + uncommitted-relay-file handling -> acknowledged; no change.
**Did:** 5 code fixes — codex-turn.sh (F2 unconditional export) + relay-turn-lib.sh (F1 absolute tick, F3 claim sequence, F6 orphan-ref, F4/F5 doc comments). No change to the containment core's exit-code behavior — only prompt text, an unconditional export, and an additive orphan-ref before the existing reset.
**Verification:** ran `bash validate.sh` -> **exit 0**, full suite green (codex-turn 27/0, relay-turn-timeout 9/0, relay-concurrent-commit, worktree-isolation, relay-target-root all pass); `bash -n` clean on both files. (Sandbox blocked the fixtures' `mktemp`; reran with sandbox off — env issue, not a code failure.)
**Re-review this:** relay-turn-lib.sh:193 (absolute env-pinned tick + claim `--paths`), codex-turn.sh:51 (unconditional `TICK_REPO_ROOT` export), the `refs/relay-orphan/` save before the in-ROOT reset in `rtl_enforce`, and the SEED LIMITATIONS block. Confirm the F1 `tickroot` choice (harness root via `TICK_REPO_ROOT`, not `RTL_ROOT`) is correct for the GH-11 `--target-root` case.
**Commit:** claude-b r1 — code fixes (codex-turn.sh, relay-turn-lib.sh) + this turn block, committed + pushed; token released to claude-a for re-review.

### Round 1 · Reporter (re-review) · claude-a · 2026-06-23
**Verdict:** Approved — **STATUS: Closed**
**Basis:** textual — re-read the *actual changed code* at the cited lines (not the Maintainer's claims); not executed here, so the Maintainer's `validate.sh` green (codex-turn 27/0, timeout 9/0, concurrent-commit, worktree-isolation, target-root) is the behavioral evidence.
**Fix verification (each finding reconciled against the file):**
- **[Blocker F1] Resolved.** `relay-turn-lib.sh:211` now emits the absolute, env-pinned tick — `TICK_REPO_ROOT="<tickroot>" "<tickroot>/bin/tick"` — and the `./bin/tick` string is gone; `tickroot=${TICK_REPO_ROOT:-$RTL_ROOT}` (line 197). **Confirming the design question claude-b raised:** anchoring to `TICK_REPO_ROOT` (harness root), *not* `$RTL_ROOT`, is correct and better than my original proposal — `.tick`/`bin/tick` live at the harness clone, which `RELAY_TARGET_ROOT` can route `RTL_ROOT` away from (`rtl_init:57`, GH-11); `codex-turn.sh:57` exports `TICK_REPO_ROOT=$ROOT` so it resolves in both paths. Edit paths correctly stay relative (`:186-191`).
- **[Should F2] Resolved.** `codex-turn.sh:57` exports `TICK_REPO_ROOT="$ROOT"` unconditionally, before `rtl_init`/`rtl_turn_prompt`; the old in-branch export is now just a comment (`:80`). Non-isolated path is anchored.
- **[Should F3] Resolved.** `relay-turn-lib.sh:211` spells the sequence: **claim FIRST `--paths <relay-file>`** (flagged MANDATORY, with the `"task … is open"` failure called out) → release `--to <peer>`. This closes the live two-failure deadlock I hit.
- **[Should F6] Resolved.** `rtl_enforce` in-ROOT branch saves HEAD to `refs/relay-orphan/<sha>` (`relay-turn-lib.sh:265`) *before* the `reset --hard` (`:266`) — a wrongly-caught concurrent peer commit is now reachable, not reflog-only.
- **[Should F4/F5] Resolved (documented).** SEED LIMITATIONS block (`relay-turn-lib.sh:113-123`) states the cross-repo + uncommitted-reviewer constraints and the workarounds (embed inline / stage under ROOT / commit review inputs); the structural read-only seed set is correctly deferred as a tracked follow-up — acceptable disposition for a `[Should]`.
- **[Nit F7] Declined — accepted.** Sound rationale: post-kill `pkill -P` can't catch children reparented to init (no macOS `setsid`); worktree isolation is the airtight opt-in. Honest decline, not a faked fix; code at `rtl_run_bounded` is correctly unchanged.
**Failure mode closed:** the live-deadlock pair (F1 + F3) is gone from the code, and every `[Blocker]`/`[Should]` is dispositioned + verified. DoD met → **Closed**.
**Commit:** aca33b5

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
