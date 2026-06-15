# RELAY · Phase-1 soundness & Phase-2 readiness (relay-automation)
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 5

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, Gemini)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (Setup: `Producer=Claude-A`, `Reviewer=Codex`) **and** the last Log block isn't already yours. If not → STOP, reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact in Setup (read the real files / latest `git show <last commit>` diff; cite `file:line`):
   - **Reviewer:** review vs the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`), each with a concrete proposed fix → set a **Verdict**. Do **not** edit the artifact; you only append findings here.
   - **Producer:** for every open finding log a disposition (Implemented / Modified / Declined + why), make the code change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line (`<!-- ↓↓↓ NEXT TURN ... -->`). Never edit earlier turns. Use your role's format below.
5. **Update the header:** flip `NEXT` to the other role; set `STATUS` (`Approved` closes the relay — Reviewer only; else leave `Open`); Producer bumps `ROUND` when opening a new cycle.
6. **Commit only the files you touched** (artifact + this log): `git commit -m "relay(phase2-readiness): <your-label> r<N>"`, then put the short hash in your block's `Commit:` line and `git commit --amend --no-edit`. Then `git push origin main`.
7. **Stop.** Tell the operator your one-line result (e.g. "Changes requested, 1 Blocker — Producer's turn").

### Block formats (copy the one for your role)
```
### Round N · Reviewer · <your-label> · <date time>
**Verdict:** Approved | Changes requested | Blocked
**Findings & proposals:**
- [Blocker] <finding @ file:line> — Proposed fix: <…>
- [Should] <…>
- [Nit] <…>
  (or "none — approved as-is")
**Commit:** <hash>
```
```
### Round N · Producer · <your-label> · <date time>
**Decisions on proposals:**
- [<grade>] <ref> — Implemented → <what @ file:line> | Modified → <what & why> | Declined → <why>
**Did:** <further changes>
**Re-review this:** <where to look>
**Commit:** <hash>
```

## Setup
- Artifact under review: the **Phase-1 slice Run 4 produced** — `src/claim.js`, `src/take.js`, `test/handoff-exclusive.sh` (the handoff-exclusive rule) + `relay-automation/runner.sh`, `relay-automation/watchdog.sh` (skeletons). Canonical plan: `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md`.
- Definition of Done: Reviewer confirms (a) the handoff-exclusive rule is **correct and complete** (rejects `claim`/`take` of a task whose `handoff_to` is set and ≠ caller, with **zero events** on rejection, no bypass/edge-case gaps), **and** (b) the `watchdog.sh` skeleton is a **sound base for the next build = proposal Phase 2 (Liveness & self-healing)** — or names exactly what's missing/wrong.
- Producer: **Claude-A (maintainer, window A)**   ·   Reviewer: **Codex (independent model, window C)**   <!-- IDENTITY LOCK: Producer=Claude-A, Reviewer=Codex. Each holds ONE role for the whole relay; stamp your label in every `Round N · <Role> · <agent>` header. A nudge for the other label is not yours (ground rule 2). -->
- **Reviewer switched Gemini → Codex** (operator out of Gemini credits, set before any Reviewer turn). **Independence caveat:** Codex *built* `runner.sh`/`watchdog.sh` in Run 4, so its review of the watchdog/skeleton Phase-2 base is partial self-review — weight those findings accordingly; its review of the handoff-exclusive rule (Gemini's work) is fully independent.
- Handoff: manual nudge   <!-- Reviewer is a non-Claude model → manual nudge, no hands-free poll -->
- Started: 2026-06-14

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two agents are different models (Claude + Gemini) and never share memory.
2. **Wrong-window guard — take a turn only if ALL hold, else STOP and write nothing:** (a) `NEXT` names the role you were asked to take; (b) **you are the agent bound to that role** — Setup names it (`Claude-A`=Producer, `Codex`=Reviewer) and prior `Round N · <Role> · <agent>` headers show that role authored by *you*; (c) you have **not** authored the *other* role's turns; (d) the most recent turn block is **not** your own role. On any mismatch reply `STOP — wrong window: <which check failed>. Nudge the <correct role> window.`
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top. (Only exception: right after committing, fill the hash into your own just-written turn's `Commit:` line.)
4. Stay tight. Findings are bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings with concrete suggested fixes. The Producer decides each (with the operator) and implements — logging a disposition (Implemented / Modified / Declined + reason) for every one.
6. Grade every finding: `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved** — to get proposals actioned in-thread set `Changes requested`, not `Approved`. If the max `ROUND` ends without `Approved`, set `STATUS: Escalated` and hand back to the human.
8. End your turn by committing it: `relay(phase2-readiness): <role> r<N>`, then fill the hash into your `Commit:` line. If your turn touched no tracked files, write `Commit: none (comments only)`.
9. **One window at a time, clean tree at every handoff.** Both agents share one working tree; the `NEXT` pointer is honor-system, not a lock. Never start while the other window may be editing; never flip `NEXT` with uncommitted changes — commit or stash first.

## Roles
- **Producer (Claude-A)** — maintainer of the artifact: presents it, decides+implements proposals (with the operator), updates.
- **Reviewer (Gemini)** — reviews against the DoD, proposes graded findings with suggested fixes, sets a verdict. Never edits the artifact.

---
## Log

### Round 1 · Producer · Claude-A · 2026-06-14 15:40 PDT
**Subject choice:** reviewing the **Phase-1 implementation + Phase-2 base soundness** (not a plan doc) — this gates the real next increment. Per the canonical proposal, Phase 1 (handoff-exclusive rule) is shipped and the next build is **Phase 2 — Liveness & self-healing (the watchdog)**. I want independent eyes on whether the shipped rule is airtight and whether `watchdog.sh` is a sound base before we build on it.

**What shipped (Run 4) & where to look:**
- **Handoff-exclusive rule, two verbs, two mechanisms:**
  - `src/claim.js:37-38` — *explicit rejection*: `if (t && t.handoff_to && t.handoff_to !== agent) return { won:false, unavailable:'reserved for another agent' }` — returns **before** any `appendEvent` ⇒ zero events.
  - `src/take.js:41` — *silent exclusion*: `if (t.handoff_to && t.handoff_to !== agent) continue;` drops the task from the candidate pool (and `:45-49` prioritizes handoffs **to** me).
  - `test/handoff-exclusive.sh` (38 lines) asserts refusal **and** `INITIAL_EVENTS == FINAL_EVENTS`. `validate.sh` = 13/13.
- **Skeletons (parse clean, `bash -n` OK):**
  - `relay-automation/runner.sh` — claimability guard (claim/resume/poll), artifact-scoped clean-tree gate (`git diff --quiet -- <artifacts>`), `extract_verdict` greps `VERDICT: PASS|FAIL|PARKED`, round cap. Real Phase-3/4 territory.
  - `relay-automation/watchdog.sh` — `collect_analysis` (`tick analyze` or file) → `find_parked_lines` (`grep -Ei '\bparked\b'`) → `escalate_to_human` (stub) → `reap_task_stub` behind `--allow-reap`.

**Review this (against the DoD):**
1. **Rule correctness/completeness** — is exclusivity airtight across *both* verbs? Probe: (a) is the `claim.js` rejection truly zero-event (no append on any path)? (b) does the check ordering (status/owner checks at `claim.js:25-33` before the handoff check at `:37`) leave any bypass? (c) positive case — `handoff_to === agent` correctly *allowed* by both verbs? (d) any interaction with `release`/`scope` that could strand or leak a reservation?
2. **Two-mechanism consistency** — claim *rejects* but take *silently excludes*. Is that divergence acceptable, or should take also surface a reason? Any observable-behavior gap (e.g., a caller that can't tell "reserved" from "no work")?
3. **Watchdog Phase-2 base** — proposal Phase 2 requires: reuse `tick analyze`'s existing parked detector (no second detector), escalate-to-human, auto-reap behind authority. Is `find_parked_lines`' bare `grep '\bparked\b'` robust, or should it parse `analyze`'s specific parked-suspects line (false-positive risk on prose)? Are the escalate/reap seams sound to build the real policy on?
4. **Anything that should block building Phase 2** on this base.

**Open questions:** (a) For Phase 2's auto-reap authority model — is a CLI `--allow-reap` flag enough, or does it need a recorded authority decision before build? (b) Should the runner's `VERDICT:` contract be specified now (it's shared by Phase 3 and the /relay-skill automation use case)?
**Commit:** 7fedc93

### Round 1 · Reviewer · Codex · 2026-06-14 17:28 PDT
**Verdict:** Changes requested
**Findings & proposals:** (I propose; I do not edit the artifact)
- [Blocker] `watchdog.sh`'s parked detector is not safe to build on: `find_parked_lines()` matches any line containing `parked` [relay-automation/watchdog.sh:44-46], but `tick analyze` prints `parked-claim suspects: none` on a healthy run [src/analyze.js:234-241]. That means the current loop can escalate a healthy run as `UNKNOWN` [relay-automation/watchdog.sh:48-56,110-117], and with `--allow-reap` it would walk the reap path on a false positive. Proposed fix: drive the watchdog from `tick analyze --format json` and iterate only `parked_suspects[]`; if you stay on human text, parse only the indented suspect lines and explicitly ignore the `none` summary.
- [Should] The handoff-exclusive core looks correct in source, but the proof is incomplete. `claim()` returns before `appendEvent()` on a wrong-agent reservation [src/claim.js:37-49], `take()` excludes wrong-agent handoffs before candidate choice and still allows `handoff_to === agent` via the prioritized handoff path [src/take.js:37-59], and `release`/`scope` do not create a bypass because both are ownership-guarded [src/scope.js:27-37] while projection clears `handoff_to` once a new claim wins [src/project.js:83-100]. The gap is test coverage: `test/handoff-exclusive.sh` proves rejected `claim` is zero-event and rejected `take` becomes `(no available task)`, but it does not prove the positive routed case or that rejected `take` is also zero-event [test/handoff-exclusive.sh:13-35]. Proposed fix: add one positive handoff test (`handoff_to == caller`) for both verbs and count events around the rejected `take` call too.
- [Should] `claim` rejecting and `take` silently excluding is an acceptable divergence, but it needs an explicit contract. The named-task verb should explain why a specific task is unavailable [src/claim.js:37-38; bin/tick:111-132], while the chooser verb can skip ineligible work and keep scanning [src/take.js:37-55; bin/tick:135-145]. Today the CLI collapses "reserved away from me" and "queue is actually empty" into the same `(no available task)` surface, which is fine for humans but weak for automation/debugging. Proposed fix: document that split now, or add a machine-readable reason on the `take` result while keeping the human output stable.
- [Should] `--allow-reap` is a useful seam, not the authority decision itself. The proposal says Phase 2 may auto-reap only per a recorded Phase-0 authority rule and must otherwise escalate [PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md:107,151-156]. The current flag gate [relay-automation/watchdog.sh:17-20,115-117] is enough for a stub, but it is not sufficient policy for wiring real `tick reap`. Proposed fix: record the authority model before the real reap implementation lands, and have the watchdog log that policy choice when it acts.
**Commit:** 002de70

### Round 2 · Producer · Claude-A · 2026-06-14 18:05 PDT
Verified all four findings against source — every one holds. The Blocker was a real bug in the shipped skeleton (good catch despite the self-review caveat). Disposed all four:

**Decisions on proposals:**
- [Blocker] watchdog false-positives on healthy output — **Implemented** → rewrote detection to drive off `tick analyze --format json` and iterate the structured `parked_suspects[]` via a node extractor (node is already a dep; bin/tick:238 confirms `--format json` emits `parked_suspects`). Dropped the `grep parked` text scan and the `UNKNOWN` path entirely. @ `relay-automation/watchdog.sh` (collect_analysis + new extract_parked_suspects + main loop; `require node`). **Verified:** healthy live `.tick` (all Run-4 tasks done) → `no parked tasks detected`; a JSON fixture with a real suspect → escalates with structured evidence; `--allow-reap` fires the reap stub only on the real suspect.
- [Should] incomplete proof — **Implemented** → added to `test/handoff-exclusive.sh`: (a) zero-event assertion around the rejected `take`, (b) positive routed **claim** (`handoff_to == bob` → bob claims TASK-007), (c) positive routed **take** (bob takes a second reserved task). `handoff-exclusive` now **6/6**, `validate.sh` **13/13**. (Bonus: writing it confirmed `take`'s handoff tie-break picks lowest id on a priority tie.)
- [Should] claim-rejects vs take-excludes contract — **Implemented (documented)** → added a **Contracts** section to `relay-automation/PHASE-2-PLAN.md` stating the divergence is intentional and both paths are zero-event; the machine-readable `take` reason is **deferred to Phase 3** (when automation needs it), human output stays stable.
- [Should] `--allow-reap` ≠ authority decision — **Implemented (recorded the gate)** → `PHASE-2-PLAN.md` Contracts now states real `tick reap` is **blocked on a decision record** defining the authority model; **escalate-only until then**; `--allow-reap` stays a stub seam. (A full decision record is premature — policy isn't decided yet — so this records the *gate*, not the policy.)

**Did:** edited `relay-automation/watchdog.sh`, `test/handoff-exclusive.sh`, `relay-automation/PHASE-2-PLAN.md`. No change to the handoff-exclusive core (you confirmed it sound).
**Re-review this:** the watchdog JSON-driven detection (correct + sound base for Phase 2?), the 3 new test assertions, and the two documented contracts. If good, **Approve** and we start building Phase 2 (watchdog) on this base.
**Commit:** 0bd204c

### Round 2 · Reviewer · Codex · 2026-06-14 20:25 PDT
**Verdict:** Approved
**Findings & proposals:** (I propose; I do not edit the artifact)
- [Nit] `relay-automation/PHASE-2-PLAN.md`'s "Current state" row still describes the old watchdog shape (`find_parked_lines`, `extract_task_id`) after the JSON-based fix [relay-automation/PHASE-2-PLAN.md:61-65 vs. relay-automation/watchdog.sh:34-62]. Proposed fix: refresh that row the next time this doc is touched.
**Commit:** a284e89

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
