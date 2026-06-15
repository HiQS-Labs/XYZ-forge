---
title: relay-automation — Phase 2 plan (skeletons → working automated relay)
status: Draft (planning)
created: 2026-06-14
decided_in: decisions/2026-06-14-graduate-relay-automation-phase-2.md
phase-1: shipped in Run 4 (runner.sh + watchdog.sh skeletons, tick handoff-exclusive rule)
---

# relay-automation — Phase 2 plan

## Goal

Turn the Phase-1 skeletons (`runner.sh`, `watchdog.sh`) into a **working automated
relay**: a runner that actually drives one agent turn end-to-end (claim → run →
verdict → done/retry) without a human pasting, and a watchdog that actually
escalates a stuck relay to a human. Phase 1 proved the *shape* parses; Phase 2
makes it *do the thing*.

## Two use cases the same engine serves (scope decision 2026-06-14)

The runner already greps `VERDICT: PASS|FAIL|PARKED` — a *review* verdict — so the
same claim→run→verdict→act loop drives **both** turn types. Phase 2 targets both:

1. **xyz build turn** — drive a build agent's `tick take → work → done` loop (the swarm/coordination case).
2. **/relay review turn** — drive a Producer/Reviewer turn of the portable `/relay` skill end-to-end: run the turn, parse the Reviewer's verdict, advance the relay (flip `NEXT`, commit), loop until `Approved` or escalate. This is **/relay-skill automation** — making the review loop hands-free instead of human-nudged.

**Boundary (keep the layers clean):** the `/relay` *skill* stays portable and
dependency-free; the **baton pattern gets baked into the skill** as the operator
UX (one-line paste handoff), but the *tick-dependent driving* lives here in
relay-automation, never folded into the portable skill or the xyz swarm skill.

## ⚠️ Alignment with the approved proposal (canonical)

`PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md` is the **canonical phase
plan** (relay-Approved). It numbers the phases differently from this doc's
working decomposition — follow the proposal's numbering and **build order**:

| Proposal phase (canonical) | This doc's section | Status |
|---|---|---|
| Phase 1 — Turn-token core (handoff-exclusive rule) | (done in Run 4) | ✅ shipped + verified |
| **Phase 2 — Liveness & self-healing (watchdog)** | "Phase 2b — watchdog" below | **← next increment** |
| Phase 3 — Termination & verdict gating (runner verdict + artifact-scoped clean-tree gate) | "Phase 2a — runner" below | after Phase 2 |
| Phase 4 — Hands-free poll integration (+ /relay-skill automation use case) | "Phase 2c/2d" below | after Phase 3 |
| Phase 5 — Package as sibling `skill/relay-automation/` | — | last |

So: this doc is **build detail** for the proposal's Phases 2–4; the proposal's
QA checklists govern acceptance. The **next thing to build is the watchdog
(proposal Phase 2)** — not the runner. The execution-contract decision below is
cross-cutting (needed once runner work starts in proposal Phase 3). The
section headers below keep their "2a/2b/…" working labels but are sequenced per
the table above, not by letter.

## Non-goals (rabbit-hole guards)
- **Not** a multi-agent orchestrator — Phase 2 drives **one** agent's turn loop. Cross-agent coordination stays with `tick` + the relay thread.
- **Not** full reap policy — reap stays a guarded stub until its own phase (authority model is a separate decision).
- **Not** a new transport — keep local `.tick/events/`, shared tree. No network/queue.
- **No protocol changes** to `tick` itself beyond what a turn loop strictly needs.

## Current state (what's real vs stubbed)

| File | Real today | Stubbed (Phase-2 fills) |
|---|---|---|
| `runner.sh` | arg parsing, `claimability_mode` (claim/resume/poll), `ensure_clean_artifacts` (artifact-scoped clean-tree gate), `extract_verdict` (greps `VERDICT: PASS\|FAIL\|PARKED`), round-cap loop | `claim_task` (no real `tick take`/`claim`), `resume_task` (no real agent invocation), no `done`/`ping` calls, no per-round verdict→action wiring |
| `watchdog.sh` | `collect_analysis` (`tick analyze` or file), `find_parked_lines`, `extract_task_id`, round over parked lines | `escalate_to_human` (prints, no channel), `reap_task_stub` (prints, behind `--allow-reap`) |

## The one decision that gates everything: the **execution contract**

`resume_task` must "invoke the agent." In the spike, an agent is an interactive
window a human drives. Automation needs a concrete way for `runner.sh` to *run a
turn and capture its output* (so `extract_verdict` has a log). Pick one before
building 2a:

| Option | How resume_task works | Pros | Cons |
|---|---|---|---|
| **A. Headless CLI (recommended)** | shell out to a headless agent: `claude -p "<turn prompt>" > $LOG` (or `codex exec`, `gemini -p`) | truly hands-free; deterministic log to grep; testable with a fake CLI | per-agent CLI differences; auth/sandbox in non-interactive mode |
| **B. Baton + poll** | runner writes the baton + flips `NEXT`; a `/loop`-polling agent window takes the turn; runner waits for the commit + log | reuses the [baton pattern](../relay-system/baton-pattern.md); no headless auth | still needs a live polling window (not fully unattended); slower |
| **C. Hybrid** | headless for Claude turns (A), baton for non-Claude windows (B) | best coverage | most code; two contracts to maintain |

**Recommendation: A**, with the agent command injectable (`--agent-cmd`) so tests
pass a fake script that emits a canned `VERDICT:` line — keeps the runner testable
and tool-agnostic. Revisit toward C if a non-Claude agent must run unattended.

## Phased breakdown

### Phase 2a — runner: real claim + execute + verdict loop
- `claim_task` → real `tick take --agent`/`tick claim` honoring the Phase-1 handoff-exclusive rule; `resume_task` → invoke `--agent-cmd` (Option A), capture stdout to `$LOG_FILE`.
- Per round: claimable→run→`tick ping`→`extract_verdict`→ on PASS `tick done` + exit 0; on FAIL retry within round cap; on PARKED stop and exit non-zero (watchdog territory).
- Artifact-scoped clean-tree gate already real — keep it as the pre-run guard.
- **Acceptance:** an integration test drives a fake agent through PASS, through FAIL-then-PASS, and through round-cap-exceeded; asserts the right `tick` events (`claimed`, `heartbeat`, `done`) and exit codes. Suite stays green (≥14 tests).

### Phase 2b — watchdog: real escalation
- `escalate_to_human` → one real channel behind a `--channel` flag (start with: write a structured escalation record to a file / stdout that an existing notifier can pick up; wire pager/chat later). Keep `reap` a guarded stub.
- Robust parked detection: parse `tick analyze`'s parked-suspects line specifically rather than a bare `grep parked` (avoid false positives on prose).
- **Acceptance:** test feeds a captured `tick analyze` with N parked tasks; asserts N escalations emitted with task ids + evidence, and that reap does **not** fire without `--allow-reap`.

### Phase 2c — `/loop` wiring (hands-free driver)
- A thin `/loop`-able entrypoint: poll `tick`, when a turn is runnable invoke `runner.sh`; when parked, invoke `watchdog.sh`. This is where the [baton pattern](../relay-system/baton-pattern.md) and the relay skill's hands-free poll connect.
- **Acceptance:** a dry-run mode that logs the decisions it *would* take over a seeded scenario, verified against expected sequence.

### Phase 2d — /relay-skill automation (drive a Producer/Reviewer loop)
- Make `runner.sh` drive a real `/relay` turn: read the relay thread, invoke the turn's agent (via the 2a execution contract), parse the Reviewer's `VERDICT:`, advance the thread (append block, flip `NEXT`, file-scoped commit), loop until `Approved` or escalate via watchdog. Verdict mapping: `Approved`→close, `Changes requested`/`Blocked`→next Producer turn, parked/no-verdict→watchdog.
- **Bake the baton into the `/relay` skill** (`~/.claude/skills/relay/SKILL.md`): document the one-line-paste handoff as a first-class hands-free option, keeping the skill itself dependency-free (the tick driver stays in relay-automation).
- **Acceptance:** an integration test runs a 2-round Producer/Reviewer relay with a fake reviewer emitting `Changes requested` then `Approved`; asserts the thread advanced correctly and closed on `Approved`. The `/relay` skill change is doc-only (no dependency added).

### Later phases (sketch, out of Phase-2 scope)
- **Phase 3:** reap policy + authority model (its own decision record).
- **Phase 4:** real escalation integrations (pager/chat/ticket).
- **Phase 5:** multi-relay supervision.

## Contracts (from relay r1 review)

- **`claim` rejects, `take` excludes — intentional, now explicit.** The named-task verb (`claim`) explains *why* a specific task is unavailable (`lost: <task> is reserved for another agent — not claimable`); the chooser verb (`take`) silently skips ineligible work and keeps scanning, surfacing only `(no available task)`. Both emit **zero events** on the non-grant path. This is fine for humans but collapses "reserved away from me" and "queue empty" into one surface — **Phase 3** adds a machine-readable reason on the `take` result (for automation/debugging) while keeping the human output stable. (Deferred per relay r1 Should.)
- **Auto-reap is gated on a recorded authority decision.** `watchdog.sh --allow-reap` is a *stub seam* only. Per the proposal (Phase 2, lines 107/151–156), real `tick reap` may fire **only** per a recorded authority rule, and must otherwise **escalate to a human**. **Before the real reap implementation lands, a decision record must define the authority model** (who/what may auto-reap, under what evidence), and the watchdog must log that policy choice when it acts. Until then: escalate-only. (relay r1 Should.)

## Risks & open questions
1. **Headless auth/sandbox** — does `claude -p` / `codex exec` run unattended in this environment? (Mirrors the keychain/tmp sandbox issues we already hit.) Validate in a 2a spike before committing.
2. **Verdict contract** — agents must emit a machine-greppable `VERDICT:` line. Needs to be in the turn prompt template (ties back to the xyz build-prompt and the relay block format).
3. **Idempotency / crash recovery** — if the runner dies mid-turn, the claim is held; the watchdog's parked detection + `tick`'s heartbeat are the safety net. Confirm the round loop is re-entrant (resume an already-claimed task).
4. **Test transport** — extend `test/_setup.sh` (now exports `TICK_REPO_ROOT=$A`) with a fake `--agent-cmd` helper.

## Suggested build approach
- This is a parallelizable build: **runner (2a)** and **watchdog (2b)** are disjoint files — a natural balanced 2-lane xyz run (and another Project-1 concurrency datapoint, which the graduate decision wants). 2c depends on both, so it's sequential after.
- Recommend a short **2a spike first** to resolve the headless-auth open question before scoping the full run.

## How this validates the graduate bet
The graduate decision rests on "balanced runs reliably clear ≥50% concurrency."
Building 2a‖2b as a balanced 2-lane run is itself the **next datapoint** for that
bet (the decision's revisit trigger watches exactly this number).
