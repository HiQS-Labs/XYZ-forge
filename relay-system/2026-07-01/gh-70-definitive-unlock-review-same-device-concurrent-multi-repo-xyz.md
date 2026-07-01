# RELAY · GH-70 definitive-unlock review — same-device concurrent multi-repo XYZ
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-01.
-->

NEXT: Reviewer
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
6. **Commit only the relay file** (`relay(gh-70-definitive-unlock-review-same-device-concurrent-multi-repo-xyz): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: the **same-device concurrent-isolation model** as implemented, plus [PROJECT/1-INBOX/GH-70-CONCURRENT-RELAY-LOCAL-HARNESS.md](../../PROJECT/1-INBOX/GH-70-CONCURRENT-RELAY-LOCAL-HARNESS.md). Read these files to verify the claim below: `relay-automation/relay-drive.sh` + `relay-automation/marathon-drive.sh` (driver lock), `relay-automation/relay-turn-lib.sh` (worktree + `.tick` scoping), `relay-automation/xyz-vendor.sh` + `skills/relay-xyz/find-harness.sh` (vendoring + locator), `bin/tick` + `src/*.js` (coordination state), `install.sh`.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-01
- Definition of Done: a **Verdict** on THE CLAIM below (Approved = "GH-70 is the definitive/complete unlock"; Changes requested = "GH-70 is necessary but NOT sufficient — here are the residual same-device concurrency gaps it misses"), backed by graded findings that cite specific files/lines.

## THE CLAIM UNDER REVIEW (evaluate this; agree or refute with evidence)

> **Claim:** GH-70 is the *final, definitive* unlock for running multiple XYZ features (relays / marathons / swarms) across **different repos on the same machine at the same time** without them clobbering each other. Once GH-70 lands, same-device concurrent multi-repo use is fully solved.

**Supporting analysis to verify (confirm each against the code, or refute):**
1. The concurrency-critical surfaces are already per-repo / per-invocation scoped:
   - Driver lock: `$ROOT/.git/relay-driver.lock` (or `$ROOT/.relay-driver.lock` for a vendored `.xyz/`) — per harness ROOT (`relay-drive.sh` ~L31-56, `marathon-drive.sh` ~L42-63).
   - Throwaway worktrees: `mktemp -d "$TMPDIR/rtl-wt.XXXXXX"` — unique per turn (`relay-turn-lib.sh` ~L196).
   - Coordination log: `.tick/` pinned by `TICK_REPO_ROOT` — per repo.
2. Therefore **N repos, each with its OWN vendored `.xyz/` (via `xyz-vendor.sh`), run concurrently with zero clobber** — separate locks, `.tick`, worktrees. (GH-49 vendoring is the isolation enabler.)
3. The ONLY clobber trap is when repos DON'T vendor and share one centralized harness clone (or are driven via `--target-root` from one clone): they contend on that clone's single driver lock + single `.tick`. GH-70 addresses exactly this (doc + `find-harness.sh --check` warning + `install.sh --with-harness`).

**The question for you, Reviewer — the crux:** Is GH-70 (as scoped: doc the model, warn on accidental sharing, optionally `install.sh --with-harness`) genuinely SUFFICIENT to call same-device concurrent multi-repo use "definitively solved"? Or are there **residual shared-machine surfaces GH-70 does NOT cover** that could still cause cross-run interference or a false sense of isolation? Specifically probe (verify against the code, don't assume):
- Shared machine-global state written during runs: the install registry (`~/.config/xyz/registry.tsv`), any fixed-name `$TMPDIR` files/logs (vs PID/mktemp-scoped), `~/.claude/skills` symlinks, git global worktree metadata.
- The stale-lock reclaim path (PID `kill -0`): can two repos' drivers ever reclaim/collide, or reuse a PID?
- The watchdog / `tick reap` / heartbeat paths under concurrency.
- Worker-CLI level contention: two concurrent codex/agy/gemini turns sharing auth/config/rate limits/`$TMPDIR` transcript paths.
- Whether "each repo must vendor" is enforced or merely documented — and what happens on the un-vendored fallback in practice.
- Anything else that makes the "definitive" claim overstated.

Land a clear Verdict: is GH-70 the definitive unlock, or necessary-but-not-sufficient (with the concrete missing pieces)?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
