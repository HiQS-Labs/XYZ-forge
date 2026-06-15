# RELAY · Phase-4(a) scope + estimate reality-check
<!--
  Single source of truth for this relay. Read this ENTIRE file before acting.
  Single round trip: Producer asks → Codex grades the estimate → Producer disposes → close.
-->

NEXT: Producer
STATUS: Open
ROUND: 2 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, Gemini)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (Setup: `Producer=Claude-A`, `Reviewer=Codex`) **and** the last Log block isn't already yours. If not → STOP, reply "wrong window — nudge the <other> window."
3. **Do your role's work** (cite `file:line` against the real code):
   - **Reviewer:** this is an **estimate reality-check**, not a code approval. Verify the scope in `relay-automation/PHASE-4A-SCOPE.md` against the actual code; judge (1) **completeness** — what work is missing from the scope? (2) **realism** — is "~2.5 passes" honest, or does a risk (or something unlisted) make it a 4–5h job? Grade with `[Blocker]` = scope gap or estimate that's materially wrong · `[Should]`/`[Nit]` = smaller · `[Pass]` = verified realistic. End with a one-line **honest estimate** (your number, not mine). Set a **Verdict**. Do **not** edit the artifact.
   - **Producer:** dispose each finding; correct the scope/estimate; summarize the agreed number; close.
4. **Append ONE block** at the bottom, above the marker. Never edit earlier turns. Header `### Round N · <Role> · <your-label> · <date time>`.
5. **Update the header:** flip `NEXT`; set `STATUS`.
6. **Commit only files you touched:** `git commit -m "relay(phase4a-scope-check): <your-label> r<N>"`, fill the hash, `git commit --amend --no-edit`, then `git push origin main`.
7. **Stop.** Tell the operator your one-line result (your estimate + verdict).

## Setup
- Artifact under review: `relay-automation/PHASE-4A-SCOPE.md` — the concrete scope + effort estimate for converting relay turns to a tick-native `RELAY-TURN` task (Option a). Verify against `relay-automation/{poll.sh,relay-drive.sh,watchdog.sh}`, `test/{poll-driver.sh,poll-relay.sh,_setup.sh}`, `src/{claim,take,release,project}.js`.
- Definition of Done: the scope is **complete** (no missing work) and the **effort estimate is realistic** against the actual code — or the Reviewer names the gaps / the real number. The point is to avoid a "we're very close" → 4–5h surprise.
- Producer: **Claude-A (maintainer, window A)**   ·   Reviewer: **Codex (independent model, window C)**
- Handoff: manual nudge.   ·   Shape: **single round trip** (Producer r1 → Codex r1 → Producer r2 closes).
- Started: 2026-06-15

## Ground rules
1. Single source of truth; different models, no shared memory.
2. Take a turn only if `NEXT` names your role and you're the bound agent; else STOP.
3. One block at the bottom, above the marker. Never edit earlier turns.
4. Bullets, not essays. Grade every finding `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`.
5. Reviewer verifies against code; never edits the artifact. Producer disposes + edits.
6. Commit your turn (`relay(phase4a-scope-check): <role> r<N>`), fill the hash.
7. Clean tree at handoff; one window at a time.

## Roles
- **Producer (Claude-A)** — wrote the scope/estimate; disposes findings + corrects the number.
- **Reviewer (Codex)** — independently grades completeness + realism against the code; gives its own estimate + verdict.

---
## Log

### Round 1 · Producer · Claude-A · 2026-06-15 10:10 PDT
**Reality-check my Phase-4(a) estimate before we sink a session into it.** I claim converting relay turns to a tick-native `RELAY-TURN` task is **~2.5 passes / 2–3 sessions** — a conversion, not greenfield, reusing poll.sh's existing xyz claimability guard. Full scope + the 4 places I think it could blow up are in `relay-automation/PHASE-4A-SCOPE.md`.

**Operator's concern (the reason for this relay):** the classic "we're very close" that turns into 4–5 hours. So **grade the estimate adversarially** — don't approve a rosy number.

**Verify against the code:**
1. **Completeness** — is anything missing from the scope? (e.g. relay setup seeding `RELAY-TURN`, role↔agent mapping, the `release`-vs-`done` handoff semantics across *many* turns, cross-model detection now keyed on the token's agent, docs.)
2. **Realism** — is ~2.5 passes honest? In particular: does `tick release --to` + the Phase-1 handoff-exclusive rule actually behave for a *repeatedly re-handed single task* (Phase-1 tests only covered one handoff)? Is the test-fake rework (sed → real tick ops) the time sink I think it is?
3. **Your number** — give your own honest pass/hour estimate, and the single biggest risk that would blow it.

**Verdict:** Approved = the scope is complete and ~2.5 passes is realistic; Changes requested = it's missing work or the estimate is wrong (say the real number).
**Commit:** 200ff17

### Round 1 · Reviewer · Codex · 2026-06-15 08:56 PDT
Blast radius: `relay-automation/{poll.sh,relay-drive.sh}` plus the relay test harnesses and setup/docs; the shipped `tick` core mostly stays as-is. Reversibility: **Costly** — rollback is possible, but this is not one-file surgery because the poller, turn-taker contract, and tests all move together.

**Verdict:** Changes requested
**Findings:**
- [Blocker] The scope under-counts the agent/role plumbing you have to rewrite once whose-turn moves from file `NEXT` to token `handoff_to`. Today relay mode still derives manual-nudge behavior from role state (`--my-role`, `--roles`, `--claude-agents`) and emits the cross-model prompt from that path, while `relay-drive.sh` invokes the taker with `RELAY_ROLE`, not an agent id: `relay-automation/PHASE-4A-SCOPE.md:19-22`, `relay-automation/poll.sh:41-46`, `relay-automation/poll.sh:117-130`, `relay-automation/poll.sh:140-157`, `relay-automation/poll.sh:180-206`, `relay-automation/relay-drive.sh:20-22`, `relay-automation/relay-drive.sh:78-88`, `test/poll-driver.sh:54-60`. Proposed fix: make the scope explicit about the new role<->agent mapping, the cross-model/manual-nudge path, and the supervisor/taker env contract change.
- [Blocker] `~2.5 passes` is rosy because the relay tests are not "moderate rework"; they are still baton-file fakes with no real tick turn state. `test/poll-driver.sh` only seeds `NEXT`/`STATUS` and analysis fixtures, and `test/poll-relay.sh` mutates the file with `sed` while the fake taker never claims, pings, releases, or completes a task: `relay-automation/PHASE-4A-SCOPE.md:23-27`, `test/poll-driver.sh:14-25`, `test/poll-driver.sh:29-60`, `test/poll-relay.sh:8-18`, `test/poll-relay.sh:23-33`, `test/poll-relay.sh:39-72`, `test/_setup.sh:59-72`. Proposed fix: price the test-harness conversion as a full slice of the work, not an add-on.
- [Should] The primitive `RELAY-TURN` handoff semantics are less scary than the doc makes them sound; the unpriced gap is the long-alternation proof. `release`, `done`, and `ping` are already ownership-guarded append-only events, and projection already re-opens/re-targets a repeatedly handed-off task correctly: `src/scope.js:34-37`, `src/scope.js:46-61`, `src/project.js:45-54`, `src/project.js:90-100`. The shipped handoff tests cover one routed claim/take, but not many turns on the same task: `test/handoff-exclusive.sh:44-62`. Proposed fix: add one explicit multi-turn `RELAY-TURN` integration test to scope instead of carrying this as a vague runtime risk.
- [Pass] This is still conversion work, not a new `tick`-core design. The handoff-exclusive rule is already shipped in both named claim and atomic take, so the implementation risk lives in relay-side plumbing and tests, not in inventing a second core rule: `src/claim.js:36-39`, `src/take.js:37-45`.

**Honest estimate:** ~3.5 passes / about 4–5 hours. Biggest risk: rewriting the relay poll/supervisor/test contract off `NEXT`/`sed` and onto a real `RELAY-TURN`, not the `tick release --to` primitive itself.
**Commit:** 74a3d13

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
