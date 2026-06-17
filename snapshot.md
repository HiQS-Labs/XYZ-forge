# 📸 Snapshot — 2026-06-17 16:11 (Wed)

**Session:** Roadmap "what's next" reconcile + model-fit (Sonnet High vs Opus) for the two open build tracks
**Project / repo:** Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm (Trinity orchestrator; canonical `ROADMAP.md`)
**Phase:** Planning/triage — both execution tracks un-started; deciding sequencing + which model does which work
**Status:** Identified next work = Part A Ph2 (`claude -p` spike + dispatcher/shims) and Part B Ph1 (R1 epoch fencing / G3). Mapped each task to Sonnet High vs Opus. No code written; advisory only.

## Git state
- **Branch:** main
- **HEAD:** 03da854 docs(front-door): express onboarding audit fixes (✅ Smooth verdict)
- **Working tree:** 1 modified, 1 untracked
- **Changed files:**
```
 M snapshot.md
?? AUDIT/XYZ-BRIEF.md
```
- **Ahead/behind remote:** in sync with origin/main

## Recent findings
- **No build-track progress since 2026-06-15** — all recent commits are docs/audit/consult/skill work (roadmap promotion, Codex QA relay, `consult` skill + briefs, front-door audit). The ROADMAP Status table remains the canonical "what's next."
- **Two open fronts, both un-started:** Part A · Phase 2 (Marathon dispatcher + headless builder; only the Gemini shim done) and Part B · Phase 1 (R1 epoch fencing / G3 stale-writer — flagged highest-priority "keystone," ❌ missing mechanism).
- **Part A Ph2 gating item = the `claude -p` headless spike** — its only output is a feasibility verdict + per-turn token/wall-clock number that sizes `--max-turns`/`--max-budget-usd`. Phases 3–5 are blocked on it.
- **Model-fit verdict:** Sonnet High is fine for the spike, all shell shims (`marathon-agent.sh`, `claude-turn.sh`), `marathon-drive.sh`, chaos *test scripts*, E2E/observability/docs. **Keep Opus** for the R1 epoch-fencing kernel diff + G2 dup-token determinism/quarantine (adversarial-correctness invariants) + the graduate/iterate/abandon synthesis. Part A Ph4 (DAG) is borderline — Sonnet against the spec, Opus to review edges.
- **Orchestrator caveat:** per CLAUDE.md, this Claude is the Trinity observer/co-pilot, not a task-claimer — some of this work may belong to peer agents (Codex/Gemini).

## Next steps
- Decide sequencing: recommended to run the bounded **`claude -p` spike first** (gates 4 downstream phases) before committing to Part B's heavier kernel work.
- If proceeding on Part B Ph1: open the **epoch-fencing decision record** before touching the event schema (schema-change-needs-decision-record rule).
- Confirm whether the spike/shims are meant for this orchestrator or a peer agent.

## Last response (verbatim)
Here's the honest split. The dividing line isn't the phase — it's **mechanical/pattern-following work** (Sonnet High is excellent) vs. **trust-critical kernel correctness reasoning** (where Opus earns its cost).

## Comfortably Sonnet High
- **The `claude -p` spike** (Part A Ph2) — it's empirical: run a turn, read the JSON, log the token/wall-clock number. Almost no reasoning depth; just careful observation. *Ideal Sonnet task.*
- **`marathon-agent.sh` + `claude-turn.sh`** (Part A Ph2) — `case` router and a shim that mirrors the existing `codex-turn.sh`/`gemini-turn.sh` against the shared `relay-turn-lib.sh`. Pure pattern-following with a concrete reference on disk.
- **`marathon-drive.sh` single-phase loop** (Part A Ph3) — more integration, but it leans on the untouched `relay-drive.sh` and a clear checklist. Sonnet High handles this with the existing scaffolding as a template.
- **Most chaos *test scripts*** (Part B Ph2) — `kill -9` + watchdog-assertion harnesses are mechanical once the mechanism exists.
- **E2E fresh-repo script, observability JSON logs, reference-deploy docs** (Part B Ph3/4) — scripting + docs, low ambiguity.

## Keep on Opus
- **R1 epoch fencing — the projection kernel change** (Part B Ph1). This is the one that genuinely wants Opus: monotonic-epoch semantics, replay determinism, and "stale writer *cannot* advance" is an adversarial-correctness invariant. Get the fencing logic subtly wrong and the whole "kernel you can trust unattended" claim collapses. The *chaos test* around it is Sonnet-fine; the kernel mutation is not.
- **G2 dup-token determinism + quarantine reasoning** (Part B Ph2) — "identical projection across N replays regardless of arrival order" is a real correctness proof, not a script.
- **The synthesis/recommendation calls** — graduate vs. iterate vs. abandon. Judgment, not mechanics.

## Borderline (Sonnet with a tight spec)
- **Part A Phase 4** (MARATHON.yaml DAG, state projection, cross-phase injection) — architectural, but the design is already fully specified in the roadmap. Sonnet High can implement it against that spec; I'd have Opus review the escalation/ordering edges.

**Practical pattern:** let Sonnet High do the spike, all the shell shims, and the test harnesses; reserve Opus for the **epoch-fencing kernel diff and the G2 determinism logic** — the two places where a subtle bug isn't a failing test, it's a silently-corruptible coordinator. That's also the cheapest division: the mechanical bulk is the majority of the line-count, and the Opus-worthy core is small and self-contained.

---

# 📸 Snapshot — 2026-06-17 15:49 (Wed)

**Session:** front-door onboarding audit (express level) — cold-newcomer walk of clone→working path
**Project / repo:** Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm (Project 2 — relay-automation, on `tick`)
**Phase:** Audit/review of onboarding front door; repo is shipped beta (relay Phases 1–5 + cross-model live-proven)
**Status:** Front-door audit complete — verdict ✅ Smooth. Report delivered in-chat; no files changed by the audit.

## Git state
- **Branch:** main
- **HEAD:** 824da4b Add AUDIT transcripts
- **Working tree:** 1 modified, 1 untracked
- **Changed files:**
```
 M CHANGELOG.md
?? AUDIT/XYZ-BRIEF.md
```
- **Ahead/behind remote:** in sync with origin/main

## Recent findings
- **Verdict: ✅ Smooth.** Cold newcomer with Node + git can clone → `./validate.sh` → 23/23 green in ~1–2 min, no auth required.
- **Secrets: clean.** No live-format keys in tracked tree or quick `git log -S 'sk-'` history scan. `.gitignore` correctly excludes `.tick/` + `.claude/settings.local.json`.
- **Source of truth: one front door.** Root README explicitly designates relay-automation/README.md (canonical contract) + QUICKSTART.md (device bring-up); no competing install commands. ~12 loose root `.md` files are clutter but navigated by README "Repo map".
- **"23/23" claim verified accurate, not drift:** validate.sh lists 23 tests; test/ has 24 `.sh` but the 24th (`_setup.sh`) is a sourced helper, not a test.
- **CLI tests are stubbed** (`CODEX_BIN`/`GEMINI_BIN` → fake binaries) — so `./validate.sh` needs no real codex/gemini CLI or auth. First success is self-contained.
- **Real walls (product use only):** two transitive auth walls — Codex (ChatGPT login/keychain) + Gemini (GCA auth); plus sandbox/keychain/egress gotcha (Codex fails under Claude Code Bash sandbox: keychain + chatgpt.com blocked).

## Next steps
- (Inferred) Optional quick win: add a one-line sandbox/keychain note to relay-automation/QUICKSTART.md §1 next to the autonomy check.
- (Inferred) Optional medium lift: thin the repo root by moving non-onboarding `.md` files (4X4, snapshot, SKILL-BUILD-PLAN, TODO_DEFER) into docs/ or PROJECT/.
- No action required — audit was advisory; nothing committed.

## Last response (verbatim)
Verified everything I need. The CLI tests use stubs (`CODEX_BIN`/`GEMINI_BIN` → fake binaries), so `./validate.sh` needs only Node + git — first success is self-contained. Here's the express report.

---

## Front Door audit — `xyz-3-agents-swarm` (express)

**Verdict:** ✅ **Smooth** — a cold newcomer with Node + git clones, runs `./validate.sh`, and reaches a verifiable 23/23 green in a minute or two. The full *product* (live Codex/Gemini relays) sits behind real per-CLI auth walls, but the README is honest that those are a separate, beta surface. Auditing `HEAD` here — working tree is dirty only with `CHANGELOG.md` + an untracked `AUDIT/XYZ-BRIEF.md`, neither of which affects the path.

**🔑 Leaked secrets:** Clean. No live-format keys (`sk-`, `ghp_`, `AKIA`, PEM) in the tracked tree or in a quick `git log -S 'sk-'` history pass. `.gitignore` correctly excludes `.tick/` and `.claude/settings.local.json`; no `.env`/`.pem`/`.key` is tracked.

**Source of truth:** One clear front door. Root [README.md](README.md) explicitly names the canonical chain — "Start here → [relay-automation/README.md](relay-automation/README.md) (operator contract) → [relay-automation/QUICKSTART.md](relay-automation/QUICKSTART.md) (device bring-up)" — and the two sub-docs cross-link with explicit role labels ("README is canonical; QUICKSTART is only the bootstrap path"). No competing install commands. The root *does* carry ~12 loose `.md` files (CLAUDE/AGENTS/CODEX/GEMINI/4X4/RECAP/ROADMAP/snapshot…), but the README "Repo map" section navigates them, so it's clutter, not competition.

**Path walk (kernel — the default first success):**
1. Clone — `[Smooth] [Agent-soluble]`
2. `./validate.sh` — `[Smooth] [Agent-soluble]` — needs only Node + git. **Verified** the suite's `codex-turn`/`gemini-turn`/`consult` tests run against stubs (`CODEX_BIN`/`GEMINI_BIN` → fake binaries), so no real CLI or auth is required to go green.
3. First success = **23/23**. **Verified accurate, not drift**: `validate.sh` lists 23 tests; `test/` holds 24 `.sh` files, but the 24th is `_setup.sh`, a sourced helper, not a test. The README's "23/23" claim matches.

**Path walk (product — live relay automation):**
4. Install `codex` CLI + `gemini` CLI — `[Bumpy] [Partially gated]` — QUICKSTART documents the prereqs well, including a Codex *autonomy* check (`-s workspace-write` must actually write).
5. Auth each CLI independently — `[Blocked] [Human-gated]` — **two separate transitive auth walls**: Codex needs a ChatGPT login (reads the OS keychain), Gemini needs GCA auth. The product's docs can't satisfy these for you.
6. Run a real headless turn **under an AI agent's sandbox** — `[Blocked] [Partially gated]` — known wall: Codex fails under Claude Code's Bash sandbox (blocked keychain + `chatgpt.com` egress). Fix is to run it outside the agent's sandbox. *(This is your own documented operating note — worth a one-line callout in QUICKSTART so the next operator doesn't read the keychain error as the real cause.)*

**The hoops (human-gated, unavoidable):** (1) a ChatGPT account/login for Codex; (2) GCA auth for Gemini. The kernel checkpoint (`./validate.sh`) clears with neither — only the live-relay product needs them.

**Fix order:**
- *Quick wins (minutes):* Add a one-line "Running under a sandboxed agent? Codex needs the keychain + chatgpt.com egress — run it outside the sandbox" note to QUICKSTART §1, next to the autonomy check. Optionally drop a "👉 New here? Run `./validate.sh` first" line at the very top of the README so the zero-auth success path is the first thing seen.
- *Medium (an afternoon):* Thin the root — move the non-onboarding `.md` files (4X4, snapshot, SKILL-BUILD-PLAN, TODO_DEFER) into `docs/` or `PROJECT/` so the front door isn't visually buried. Add an explicit "Access you'll need: a ChatGPT login (Codex) + GCA auth (Gemini)" callout in relay-automation/README.md before operator usage.
- *Heavy:* none warranted — the structure is sound.

**Bottom line:** This is a rare repo where the front door actually works as written. The kernel onboarding is genuinely smooth and auth-free; the only real walls are the two CLI logins for the live product, which the docs are honest about. The single highest-value add is surfacing the sandbox/keychain gotcha so it doesn't masquerade as a different error.

---

# 📸 Snapshot — 2026-06-15 19:44 (Mon)

**Session:** relay-automation cross-model hardening — Gemini CLI integrated; shared safety core (`relay-turn-lib.sh`) with `codex-turn.sh` + `gemini-turn.sh` thin wrappers; MBP16 portability fixes; ROADMAP.md (commercial-viability gaps); two live Gemini-CLI relay reviews
**Project / repo:** Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm (Project 2 — relay-automation, on `tick`)
**Phase:** relay-automation Phases 1–5 SHIPPED + cross-model (Codex + Gemini headless) live-proven. Next milestone = commercial-viability hardening (ROADMAP Phase 1: R1 epoch fencing / G3 stale-writer — the keystone)
**Status:** main clean, in sync with origin @ cd16fa5. `validate.sh` 21/21 (codex-turn 24/24, gemini-turn 17/17). All relay threads closed Approved.

## Git state
- **Branch:** main
- **HEAD:** cd16fa5 — docs(ROADMAP): merge phased/QA structure with per-gap rationale; fix frontmatter
- **Working tree:** clean
- **Ahead/behind remote:** in sync

## Recent findings
- **Gemini CLI installed + authed** (brew, 0.46.0). Headless recipe: `GOOGLE_GENAI_USE_GCA=true gemini --yolo --skip-trust -p "<prompt>"` (GCA personal Google login, no API key).
- **Shared safety core refactor:** extracted containment (path-allowlist + commit-bypass guard + no-push) into `relay-automation/relay-turn-lib.sh`; `codex-turn.sh` + new `gemini-turn.sh` are thin wrappers. Boundary lives in ONE place.
- **Reconciled** my `gemini-drive.sh` with Gemini's standalone `gemini-turn.sh` (commit fe0bd61) → one `gemini-turn.sh` (Gemini's name + shared core + fixed invocation; its `gemini exec` doesn't exist, headless is `-p`). Removed `gemini-drive.sh`.
- **3 live Gemini-CLI turns**, all containment-clean: (1) reviewed seeded sample.sh; (2)+(3) reviewed the fixes+ROADMAP. Two "stray" events (Gemini edited an off-allowlist artifact) → guard reverted + failed turn (exit 6), review survived. Containment proven on a 2nd model.
- **MBP16 field-report fixes [1][2][3]** in the shared core: [1] snapshot pre-turn dirty set → never destroy ambient WIP; [2] exempt `.tick/` intrinsically (cross-repo); [3] codex `CODEX_FLAGS` default `-s workspace-write`. Gemini review then found a **rename-hijack** in [1] → fixed (both dest+src must be pre-existing) + regression test.
- **Decision recorded:** `decisions/2026-06-15-unattended-agent-containment.md` (Decided; revisit on first real unattended run). **ROADMAP.md** created → restructured (Gemini, phased) → merged (phased + per-gap rationale), frontmatter fixed.
- **Test growth:** codex-turn 10→24, gemini-turn (new) 17, validate 20→21 files.
- **Collision lesson:** ROADMAP.md was edited concurrently by me + another Gemini session (no coordination) — exactly what tick/relay prevents; reconciled from git history (flat detail safe at d8d856e).

## Next steps
- **ROADMAP Phase 1 — R1 epoch fencing + G3 chaos test** (the sequenced keystone): add monotonic `epoch` to claim events, reject stale-epoch mutating events, build `test/chaos-stale-writer.sh`. Needs a decision record (event-schema change).
- Or chip the rest of ROADMAP Phase 2 chaos suite (G1 mid-turn kill, G2 dup-token, G4 concurrent pollers, R2 auto-reap authority, R5 quotas).
- Optional: route ROADMAP/doc edits through a RELAY-TURN token to avoid another concurrent-edit collision.

## Last response (verbatim)
No faceplant damage — merged and pushed (`cd16fa5`), tree clean.

**ROADMAP.md now has the best of both:** Gemini's phased structure + QA checklists (your `phase-qa` format), with the per-gap **Threat / Prove / Test-artifact / Leans-on / Status** rationale folded into each phase as a `>` block. Frontmatter fixed (it was missing the opening `---`). R5 retained in Phase 2. The flat original is preserved at `d8d856e` if you ever want to diff.

What landed across this turn:
- **Portability fixes [1][2][3]** from your MBP16 report — in the shared core, so Codex *and* Gemini both get them. `codex-turn` 16→24, `gemini-turn` 13→17.
- **Live Gemini CLI relay review** of the fixes + ROADMAP → it found a real **rename-hijack** in my [1] fix (now fixed + regression test) and suggested R5. Verdict Approved, thread closed.
- **A second live containment win** as a bonus: Gemini strayed and tried to edit ROADMAP.md mid-turn — the shared guard reverted it and failed the turn (exit 6), review intact.
- ROADMAP collision reconciled.

One worth-saying observation, gently: the collision happened because two agents (me + your other Gemini window) edited `ROADMAP.md` with **no coordination** — which is precisely the failure `tick`/relay exists to prevent. The dogfood lesson: ROADMAP edits should go through a `RELAY-TURN` token (or at least a claim) like the code does, so whoever holds it edits and the other waits. Cheap to adopt now that the machinery exists.

Nothing pending — everything's committed, `validate.sh` 21/21, `main` in sync. Want me to keep going on the ROADMAP itself (Phase 1 / R1 epoch fencing is the sequenced keystone), or pause here?

---

# 📸 Snapshot — 2026-06-14 21:06 (Sun)

**Session:** Phase-2 build of relay-automation (watchdog ‖ runner) as a 2-Codex swarm; relay r1 (Codex review) closed Approved; embedded turn-instructions into relay doc + baked into /relay skill
**Project / repo:** Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm
**Phase:** Proposal Phases 1–3 BUILT & tested (15/15); graduate decision → Revisited (concurrency missed on start-skew)
**Status:** Phase-2 build complete & pushed (`bfacc09`). Deliverables real+tested. Concurrency 39% (<50%) due to start-skew, not lane design → graduate decision flipped to Revisited. Awaiting operator pick on next thread.

## Git state
- **Branch:** main
- **HEAD:** bfacc09 — Phase-2 build (Run 5): wire watchdog-liveness + runner-loop into validate (15/15); record 39% concurrency + revisit decision
- **Working tree:** clean except 2 untracked: `snapshot.md` (personal), `test-release-leak.sh` (⚠️ stray — not created by me; likely an agent left it outside its lane — investigate/clean)
- **Ahead/behind remote:** in sync

## Recent findings
- **Phase-2 swarm built & tested.** `copilot-codex` = Watchdog lane (real JSON escalation records, `--channel stdout|file`; reap still gated stub), `codex` = Runner lane (verdict-gated turn loop, injectable `--agent-cmd`; real headless deferred). All 4 tasks done, both agents ≥2, 0 collisions/drift/parked.
- **validate.sh 15/15** — added `test/watchdog-liveness.sh` (6/6) + `test/runner-loop.sh` (6/6). Coordinator wired both into validate.sh at wrap-up.
- **Concurrency 39.2%** (88s/225s work-bounded) — **MISSED ≥50% bar**. Root cause = **start-skew** (`copilot-codex` claimed 116s after `codex`; one ran solo for first half), NOT load imbalance (lanes clean, 2 tasks each). Run 4 at 2s skew = 72%. **Key finding: simultaneous start dominates the metric, not lane design.**
- **Graduate decision → Revisited** (`decisions/2026-06-14-graduate-relay-automation-phase-2.md`): trigger fired (real balanced run <50%); refined — bet conditional on start-together discipline; not structurally broken; ≥50% claim pending a start-synchronized re-run.
- **relay phase2-readiness (earlier today): Codex Approved** the Phase-1 base; 1 Blocker fixed (watchdog grep-parked false-positive → JSON `parked_suspects[]`), test strengthened (handoff-exclusive 6/6), contracts documented.
- **Embedded `▶ TAKE YOUR TURN` block** into the relay doc AND baked into the `/relay` skill template (giant-brains repo, pushed `1412b75`) — cross-model relays now one-line ("take your turn on <file>"); base skill stays partially manual; xyz add-on automates.

## Next steps
- **Operator to pick next thread:** (1) start-synchronized re-run to confirm ≥50% & close the Revisited decision; (2) Phase 4 (hands-free poll + /relay-skill automation); (3) real reap (needs authority decision record first); (4) real headless execution-contract spike (`claude -p`/`codex exec`).
- **Clean up `test-release-leak.sh`** — stray untracked file at repo root; confirm what it is (agent artifact?) and remove or wire in.

## Last response (verbatim)
## Phase 2 build — done. Honest result.

**Deliverables: shipped and tested** ✅
- **Watchdog** (Phase 2, `copilot-codex`): real structured JSON escalation records (`--channel stdout|file`), reap still gated. `watchdog-liveness.sh` 6/6.
- **Runner** (Phase 3, `codex`): real verdict-gated turn loop with injectable `--agent-cmd` (real headless wiring deferred as planned). `runner-loop.sh` 6/6.
- **`validate.sh` 15/15**, 0 collisions, 0 drift, both agents 2 tasks, commits cleanly tagged by distinct agent ids.

**Concurrency: 39% — below the 50% bar, and I recorded it straight.**
- Cause was **start-skew, not lane design**: `copilot-codex` claimed 116s after `codex`, so one agent ran solo for the first half. Run 4 (2s skew) → 72% on the *same* design.
- **Finding:** a balanced fixture is necessary but not sufficient for ≥50% — *simultaneous start* dominates the metric.
- This fired the graduate decision's revisit trigger → I flipped it to **Revisited** with that refinement (the bet isn't structurally broken; it's conditional on start-together discipline the original bet didn't name). Recorded in the decision's Updates, REAL-AGENT-OBSERVATIONS.md (Run 5), and RECAP.md.

Per the brief, sub-50% is a valid datapoint — **not** an in-session retry trigger, so I stopped and recorded rather than re-running.

## Where that leaves us
Proposal Phases 1–3 are now built and tested. Open threads, your call on order:
1. **Confirm the ≥50% claim** — one start-synchronized re-run (manual launch-sync or automated) to get a clean concurrency number. This is the cheapest way to close the Revisited decision.
2. **Phase 4** — hands-free poll + the /relay-skill automation (drives the loop, removes even the one-line nudge).
3. **Real reap** (watchdog) — blocked on the authority decision record we flagged; needs your policy input first.
4. **Real headless execution contract** — the `claude -p`/`codex exec` spike the runner deferred.

What's next?

---

**Session:** xyz Run 4 — executed the meta-exercise swarm (Codex+Gemini build relay-automation Phase-1), wrap-up, graduate decision, agent-feedback follow-ups, Phase-2 plan
**Project / repo:** Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm
**Phase:** Run 4 complete & graduated; Phase 2 planned (not started)
**Status:** Run 4 PASSED both acceptances (72.2% work-bounded concurrency; validate 13/13). Graduate-to-Phase-2 decision recorded. Three "next steps" done & committed locally. 3 commits ahead of origin (push held — awaiting go). Open fork: headless-auth spike to de-risk the Phase-2 execution contract.

## Git state
- **Branch:** main
- **HEAD:** 86e9592 — relay-automation: Phase 2 plan (skeletons -> working automated relay)
- **Working tree:** clean (only untracked `snapshot.md`)
- **Ahead/behind remote:** ahead 3 (Run-4 wrap-up already pushed at 99c3bff; these 3 next-step commits NOT yet pushed)

## Recent findings
- **Run 4 executed & PASSED.** Codex+Gemini ran 4 tasks in a ~3-min work-bounded window. Launch-sync held by construction (A1 & B1 claimed 2.25s apart, before any `done`). gemini=Enforcement (A1/A2), codex=Automation (B1/B2). Both ≥2 done, 0 collisions, 0 parked.
- **Concurrency: 72.2%** work-bounded (132s/182.9s) — clears ≥50%, beats Run-3's 40%. Note: `tick analyze` shows 40% because its window starts at task *creation* (includes seed→start gap); numerator (132s) matches.
- **Acceptance both green:** validate.sh **13/13** incl. new `handoff-exclusive.sh` (asserts refusal + zero events); `runner.sh`+`watchdog.sh` skeletons pass `bash -n`.
- **validate.sh sandbox gotcha:** must run with writable `$TMPDIR` (sandbox-off) — else spurious 0/13 with `EPERM mkdir`/paths→`/agent-a`.
- **Feedback relay (single round trip)** captured Codex+Gemini subjective feedback → folded into REAL-AGENT-OBSERVATIONS.md. Codex: add "initiative bound" to build prompt. Gemini: standardize test `TICK_REPO_ROOT`/`$A`.
- **Both follow-ups implemented & verified 13/13:** SKILL.md initiative bound; test/_setup.sh exports `TICK_REPO_ROOT=$A`.
- **Graduate decision recorded:** decisions/2026-06-14-graduate-relay-automation-phase-2.md (bet: balanced runs generalize; revisit if a real balanced run <50%).
- **Baton pattern** documented (relay-system/baton-pattern.md) — one-file + TARGET handoff so operator pastes one stable line.
- **Phase-2 plan** written (relay-automation/PHASE-2-PLAN.md): gating decision = execution contract; recommend headless CLI + injectable `--agent-cmd`. Build as 2a runner ‖ 2b watchdog (balanced 2-lane run = next concurrency datapoint) → 2c /loop wiring.

## Next steps
- **Decide:** push the 3 next-step commits to origin? (held — earlier push auth was scoped to Run-4 wrap-up only.)
- **Optionally run the 2a headless-auth spike** — confirm `claude -p`/`codex exec` run unattended here (we hit sandbox keychain+tmp walls today) BEFORE committing to execution-contract Option A.
- When Phase-2 build starts: 2a runner ‖ 2b watchdog as a balanced xyz run (doubles as the graduate-bet confirmation datapoint).

## Last response (verbatim)
All three next steps done and committed. Here's where we landed:

## Done

**1. Graduate decision recorded** — [decisions/2026-06-14-graduate-relay-automation-phase-2.md](decisions/2026-06-14-graduate-relay-automation-phase-2.md). States the bet (one balanced run generalizes), reversibility (Costly, not one-way), and a *metric* revisit trigger (next real balanced run < 50% → re-open). Link-backs added to RECAP and the observations doc.

**2. Agent-feedback follow-ups** (both verified, suite still **13/13**):
- *Codex* → [SKILL.md](skill/xyz/SKILL.md) build prompt now carries an explicit "thinnest passing change" initiative bound.
- *Gemini* → [test/_setup.sh](test/_setup.sh) exports `TICK_REPO_ROOT=$A` so new tests don't hit an unbound var.

**3. Phase 2 plan** — [relay-automation/PHASE-2-PLAN.md](relay-automation/PHASE-2-PLAN.md). Maps each stub to its fill, and surfaces the one decision that gates everything: the **execution contract** (how `runner.sh` actually invokes an agent). I recommend **headless CLI with an injectable `--agent-cmd`** (testable, tool-agnostic). Phased as 2a runner ‖ 2b watchdog (disjoint files → a natural balanced 2-lane xyz run, which doubles as the next concurrency datapoint for the graduate bet) → 2c `/loop` wiring.

3 commits sit on local `main`, **ahead of `origin/main` by 3** — I held the push since your earlier authorization was scoped to the Run-4 wrap-up.

## The one real fork before any Phase-2 building
The plan's open question #1: **does `claude -p` / `codex exec` run unattended here?** We already hit sandbox keychain + tmp walls today, so the execution contract (Option A) needs a quick spike to confirm headless auth works before committing to it.

Want me to **push these 3 commits**, and/or **run the 2a headless-auth spike** to de-risk the execution contract?

---

# 📸 Snapshot — 2026-06-14 14:17 (Sun)

**Session:** Trinity/xyz — relay automation proposal review + relay-skill wrong-window safeguard + fork to standalone repo
**Project / repo:** Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm (forked from AI-DDTK/experimental/coordination-layer)
**Phase:** Two parallel projects at a junction; deciding the meta-exercise to advance both
**Status:** Both relays closed Approved. Project 2 (relay automation) plan is approved & ready. Project 1 (xyz Run 4) is NOT plan-ready (no phased plan; load-balance approach undecided). Proposed meta-exercise: swarm builds the relay-automation slice *as* Run 4.

## Git state
- **Branch:** main
- **HEAD:** 684bd20 — relay(automation-proposal): reviewer r4 — Copilot Codex APPROVED; relay closed
- **Working tree:** clean
- **Ahead/behind remote:** in sync

## Recent findings
- **`xyz` skill** built + Gemini-relay-approved; self-extracting SKILL.md (runtime §4 + test suite §4b) verified end-to-end (extract both blocks → `validate.sh` 12/12).
- **Forked** the experiment into its own public repo `Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm` (full coordination-layer subtree + docs/ provenance). `validate.sh` 12/12, sandbox-app 26/26 in the new repo.
- **EXP-AUTOMATION proposal** (tick-backed relay automation) ran a 4-round relay vs Copilot Codex → **Approved**. R1: 2 Blockers+3 Shoulds → R2: 1 Blocker (Phase-4 guard deadlock) → R3: 1 Should (all-Claude poll limit) → R4: Approved. Two forks decided: **hard `tick` enforcement** (reject claim/take when handoff_to set & ≠ agent) and **sibling skill** (not Use-case C).
- **Relay collision** occurred (Producer command pasted to a 2nd Codex window) but converged cleanly (no divergence). → Prompted the safeguard below.
- **Wrong-window safeguard** added to the global `/relay` skill (`~/.claude/skills/relay/SKILL.md`): identity-bound turn-taking — ground rule 2 now requires (a) NEXT==role, (b) you're the agent bound to that role per Setup + `Round N · <Role> · <agent>` headers, (c) you haven't authored the other role, (d) last block isn't your own role. Headers now mandate `· <agent>`. Hands-free poll guard also checks identity.
- **Readiness audit:** Project 2 ✅ ready (phased, approved). Project 1 ⚠️ not ready — only a RECAP recommendation + 4X4 backlog; Run-4 load-balance approach unchosen (work-stealing / finer split / balanced fixture).

## Next steps
- **Awaiting user go** on: write a 1-page Run-4 brief + lane split (fixture = the relay-automation Phase-1 slice; this makes Project 1 genuinely start-ready and picks the "balanced fixture" option by construction), then launch the bounded meta-exercise swarm.
- Flip EXP-AUTOMATION frontmatter `status:` from "Proposal — not started" → "Approved — ready (Phase 0)".
- Meta-exercise = swarm builds relay-automation Phase 1 (`tick` handoff-exclusive change + test) + runner/watchdog skeletons, as Run 4; dual acceptance (≥50% concurrency datapoint + Phase 1 ships); hard timebox; sub-50% is a valid datapoint, not a tuning rabbit hole.

## Last response (verbatim)
Cleanup done — automation relay **closed: Approved** (`684bd20`, pushed), README already clean.

Now the honest readiness audit — and it diverges from your assumption on one:

## Plan readiness (verified against the repo)

**Project 2 — Doc/Code-review Relay automation: ✅ READY.**
[PROPOSAL-AUTOMATION.md](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/blob/main/PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md) — fully phased (0–5), observable checklists + QA gates, **relay-approved by Copilot Codex (R4)**, both forks decided. Phase 0 is a clean entry point. (One cosmetic gap: frontmatter still says `status: Proposal — not started` — should flip to "Approved — ready.")

**Project 1 — Overall XYZ parallelization (Run 4): ⚠️ NOT actually plan-ready.**
There is **no phased plan doc** for it. What exists is a one-paragraph RECAP recommendation and the 4X4 backlog. Critically, the Run-4 load-balance approach is **undecided** — RECAP lists three unchosen options (work-stealing / finer split / balance-matched fixture). So Project 1 has a *direction*, not a *plan or a decision*. The xyz **skill** is approved (Gemini relay), but that's the shipped current state, not the Run-4 next step.

So: one is ready, one isn't. Good news — the meta-exercise fixes that gap for free.

## The meta way: build Project 2 *as* Project 1's Run 4

**Have the swarm build the relay-automation — and that build *is* Run 4.** This is the one move that advances both with a single bounded session, and it resolves Project 1's undecided fork by construction:

- The relay-automation's first slice (the `tick` handoff-exclusive-claim change + its test; a runner skeleton; a watchdog skeleton) is **many small, comparably-sized files** → that's a **naturally balanced fixture** = Run-4 option 3, chosen *by doing*, no separate planning rabbit hole.
- **One session, dual payoff, both cheap to measure:**
  - *Project 1 win:* `tick analyze` work-bounded concurrency — does a balanced fixture beat Run 3's 40% and clear ≥50%?
  - *Project 2 win:* Phase 1 actually ships (handoff-exclusive claims + test, `validate.sh` still green) + skeletons land.

## Rabbit-hole guards (the part you asked for)
1. **One slice only:** Project 2 **Phase 1 + skeletons** — *not* Phases 2–5. Stop there.
2. **Hard timebox** (the existing 60-min box). Box expires → stop, whatever the state.
3. **A sub-50% result is a valid datapoint, not a reason to keep tuning.** We record it and move on — no load-balance micro-optimizing in-session.
4. **Lanes pre-split by the coordinator** (me) so agents don't negotiate scope mid-run.

That keeps it to "meaningful progress on both, then stop" rather than an open-ended build.

## To start, I'd need two cheap things from you
1. Flip Project 2's frontmatter to "Approved — ready" + write a **1-page Run-4 brief** (fixture = the relay-automation slice, the balanced lane split, dual acceptance, the guards above). That brief makes Project 1 "ready" honestly.
2. Then it's a normal swarm setup (seed balanced lanes → paste run prompts → I coordinate/measure).

Want me to **write that 1-page Run-4 brief + lane split now** (so both plans are genuinely start-ready), and leave the actual swarm launch for your go? That's the lowest-rabbit-hole next step.

---
