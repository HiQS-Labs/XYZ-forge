# RELAY · Phase-4(a) scope + estimate reality-check
<!--
  Single source of truth for this relay. Read this ENTIRE file before acting.
  Single round trip: Producer asks → Codex grades the estimate → Producer disposes → close.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 2

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

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
