# RELAY · Run-4 meta-exercise brief — review

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 5

## Setup
- Artifact under review: `PROJECT/1-INBOX/EXP-AUTOMATION/RUN-4-META-BRIEF.md`
- Definition of Done: The brief is **runnable as-is** by a fresh coordinator window — the lane split is correct against how `tick` actually routes (in-half overlap → sequential; cross-half disjoint → concurrent), the dual acceptance is objectively measurable, the rabbit-hole guards are sufficient, and the runtime-context section gives the executor everything it needs without guessing.
- Producer: **Claude-A (maintainer, window A)**   ·   Reviewer: **Claude-B (reviewer, window B)**   <!-- IDENTITY LOCK: both windows are Claude, so we bind DISTINCT labels. Each holds ONE role for the whole relay; stamp your label in every turn header. A nudge for the other label is not yours (ground rule 2). -->
- Handoff: manual nudge
- Started: 2026-06-14
- Post-relay: on **Approved**, the **Reviewer (Claude-B)** window executes the brief (it's the run coordinator). The runtime-context section of the artifact is written for that handoff.

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two agents never share memory.
2. **Wrong-window guard — take a turn only if ALL hold, else STOP and write nothing:** (a) `NEXT` names the role you were asked to take; (b) **you are the agent bound to that role** — Setup names it (`Claude-A`=Producer, `Claude-B`=Reviewer) and prior `Round N · <Role> · <agent>` headers show that role authored by *you*; (c) you have **not** authored the *other* role's turns; (d) the most recent turn block is **not** your own role. On any mismatch reply `STOP — wrong window: <which check failed>. Nudge the <correct role> window.` (Both windows are Claude — `NEXT` alone can't tell you apart; the bound label does.)
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top. (Only exception: right after committing, fill the hash into your own just-written turn's `Commit:` line.)
4. Stay tight. Requests and findings are bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings with concrete suggested fixes. The Producer decides each (with the operator) and implements — logging a disposition (Implemented / Modified / Declined + reason) for every one.
6. Grade every finding:  `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved** — to get proposals actioned in-thread set `Changes requested`, not `Approved`. If the max `ROUND` ends without `Approved`, set `STATUS: Escalated` and hand back to the human.
8. End your turn by committing it: `relay(run4-brief): <role> r<N>`, then fill the hash into your `Commit:` line. If your turn touched no tracked files, write `Commit: none (comments only)`.
9. **One window at a time, clean tree at every handoff.** Both agents share one working tree; the `NEXT` pointer is honor-system, not a lock. Never start while the other window may be editing; never flip `NEXT` with uncommitted changes — commit or stash first.

## Roles
- **Producer (Claude-A)** — the only writer of the artifact: builds it, requests review, decides+implements proposals, updates.
- **Reviewer (Claude-B)** — reviews against the DoD, proposes graded findings, sets a verdict. Never edits the artifact. **Executes the brief after Approved.**

---
## Log

### Round 1 · Producer · Claude-A · 2026-06-14 14:27 PDT
**Did:** Brief is at `PROJECT/1-INBOX/EXP-AUTOMATION/RUN-4-META-BRIEF.md` (committed `e753798`) — the Run-4 meta-exercise: two build agents construct the relay-automation Phase-1 slice in balanced disjoint lanes, and that build *is* Run 4. Just added a **Runtime context** section so a fresh coordinator window can run it. Lane split: Enforcement half (A1/A2 → `tick` handoff-exclusive rule + test, scope `src/**,test/**,validate.sh`) ‖ Automation half (B1/B2 → runner + watchdog skeletons, scope `relay-automation/**`).
**Review this (against the DoD) — you (Claude-B) will run this after approving, so review for runnability:**
1. **Lane mechanics** — is the in-half-overlap → sequential, cross-half-disjoint → concurrent model correct against `bin/tick` + `src/take.js` (incl. the Run-3 own-overlap exclusion)? Will the seed scopes actually force two separated agents, each doing its 2 tasks sequentially?
2. **Acceptance measurability** — are both bars objectively checkable at wrap-up (validate ≥13; work-bounded % from `.tick/events/`)?
3. **Executor sufficiency** — does the Runtime context section give you (the coordinator) everything to run it without guessing? Name anything missing.
4. **Guards** — do the rabbit-hole guards actually bound the session (one slice, timebox, sub-50%=datapoint)?
**Open questions:** (a) Should B1/B2 (skeletons) carry a minimal parse/lint acceptance, or is "exists + documented stubs" enough for a skeleton? (b) Build agents = Codex + Gemini, or two Claudes?
**Commit:** c6d153d (relay log; brief at e753798)

### Round 1 · Reviewer · Claude-B · 2026-06-14 15:12 PDT
**Verdict:** Changes requested
**Findings & proposals:** (I propose; I do not edit the artifact. Verified against `src/take.js`, `src/paths.js`, `src/project.js`, `validate.sh`, live tree.)

- [Should] **"Balanced by construction" has a start-skew hole that can fail an acceptance bar.** The collision-free claim is solid, but balance is *not* guaranteed by scopes. `MAX_ACTIVE_CLAIMS_PER_AGENT = 2` (`src/project.js:167`), and the own-overlap exclusion (`take.js:30-44`) only blocks *same-half* second claims — cross-half claims never overlap. `take` picks by **global** priority (A1=10, A2=8, B1=10, B2=8). So if one agent finishes A1 *before the other has claimed anything*, its next `take` prefers **B1 (10) over A2 (8)** and it crosses into the Automation half → 3-1 split (it does A1,B1,B2; the other does only A2). That's exactly Run-3's imbalance, and it breaks Project-1 acceptance **"both agents ≥ 2 done."** Half-ownership only holds when *both* first-claims (A1 **and** B1) land before either calls `done` — then overlap locks each agent in its lane for task 2. The brief asserts ownership is automatic; the code makes it contingent on near-simultaneous start. — Proposed fix: add a **launch-sync step** to Mechanics (or Rabbit-hole guards): *"Start both windows together; before either agent calls its first `tick done`, confirm `tick project` shows **both** A1 and B1 claimed (one per agent). This is what forces the balanced split — don't let one agent finish task 1 while the other is still unclaimed."*

- [Should] **Wrap-up `validate.sh` needs tmp/write access — it spuriously reports 0/12 otherwise.** Each test sources `test/_setup.sh`, which does `mktemp -d`; with no writable tmp the workdir resolves empty and every test EPERMs (I hit exactly this — `0 / 12`, paths collapsing to `/agent-a`, `/t1.out`). The coordinator runs wrap-up in this same harness. — Proposed fix: one line in Wrap-up: *"Run `validate.sh` with a writable `$TMPDIR` (outside the command sandbox if needed); a 0/12 with `EPERM mkdir` means the env blocked tmp, not a real regression."*

- [Nit] **Acceptance "parse/lint clean" for B1/B2 should name the concrete check** (also answers Open-question (a)). For shell skeletons the right, near-free bar is `bash -n`. — Proposed fix: change the Project-2 skeleton bar to *"both skeletons exist and pass `bash -n relay-automation/runner.sh && bash -n relay-automation/watchdog.sh`, with documented stubs."* "Exists + documented stubs" alone lets an unparseable file pass.

- [Nit] **"holding ≤1 active claim at a time" is imprecise.** The cap is 2; the ≤1 comes from the build-loop discipline (take→work→done→take) plus within-half overlap, not from an enforced limit. — Proposed fix: reword to *"works them sequentially (the loop holds one claim at a time; the in-half overlap blocks a 2nd same-half claim)."* Keeps the mechanism honest.

- [Nit] **Stale runtime pins.** Brief pins `main @ 9cec8bc (clean)`; live tree is `main @ a10fcdf` with untracked `snapshot.md`. `.tick/events/` is described as "empty" but the dir doesn't exist at all (so `tick init` alone is right; no archive needed). The brief already says "verify before launch" — just refreshing the values so the executor doesn't re-derive: **a10fcdf**, `relay-automation/` confirmed absent, `validate.sh` = **12 tests** confirmed (→ ≥13 target correct).

**On Open-question (b)** (Codex+Gemini vs two Claudes): operator's call, and the brief correctly defers ("confirm which two with the operator"). Doesn't affect the concurrency metric; only matters for relay independence later. No change needed.

**Net:** mechanics verified sound (no collision possible, sequential/concurrent both correct). The two [Should]s are cheap guards that protect the *measurement* — fix those and I'll approve, then run it.
**Commit:** a47b51e — Reviewer comments only; no artifact edit (relay log is tracked, committing per rule 8)

### Round 2 · Producer · Claude-A · 2026-06-14 14:37 PDT
Verified all findings against `src/take.js` + `src/project.js` — every one holds. The first Should is the real catch: I asserted balance was automatic, but `take` routes by global priority, so a head-start lets an agent cross lanes → 3-1 split → fails "both ≥2 done." Disposed all five (artifact `8aad11a`):

**Decisions on proposals:**
- [Should] Start-skew breaks the balance guarantee — **Implemented** → rewrote "Mechanics" to state balance is **contingent on launch-sync, not automatic** (global-priority `take` + cross-half non-overlap), and added **Rabbit-hole guard #6 (launch-sync):** start both windows together; before either's first `tick done`, confirm `tick project` shows both A1 *and* B1 claimed. Noted the elegant bit: Phase-1 (what this run builds) is what would make it automatic.
- [Should] `validate.sh` spurious `0/12` without writable tmp — **Implemented** → added a Wrap-up callout: an `EPERM mkdir` / paths-collapsing-to-`/agent-a` `0/12` means tmp was blocked, not a regression; re-run with a writable `$TMPDIR`. (I hit this exact failure earlier in the session — confirmed real.)
- [Nit] Skeleton bar vague (answers open-q a) — **Implemented** → Project-2 skeleton acceptance is now `bash -n runner.sh && bash -n watchdog.sh` + documented stubs.
- [Nit] "≤1 active claim" imprecise — **Implemented** → reworded to "the loop holds one claim at a time; in-half overlap blocks a 2nd same-half claim."
- [Nit] Stale pins — **Implemented** → refreshed to `a10fcdf`, `.tick/` absent (init only, no archive), `relay-automation/` absent, validate=12; fixed the seed comment too.
- Open-q (b) — Reviewer deferred to operator; agreed, no change. (Still open for you/operator: Codex+Gemini vs two Claudes as build agents.)

**Did:** Edited the brief (6 spots), committed `8aad11a`. No code (planning doc).
**Re-review this:** the launch-sync guard (#6) + the Mechanics rewrite — is the balance contingency now stated correctly and is the launch-sync check sufficient to force the split? If yes, approve and run it.
**Commit:** adbcacb (relay log; brief at 8aad11a)

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
