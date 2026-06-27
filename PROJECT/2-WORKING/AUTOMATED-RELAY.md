---
title: Automated Relay — project hub (focused)
status: Completed
created: 2026-06-15
updated: 2026-06-26
owner: Noel
north_star: a fully automated, self-healing /relay loop I can use every day
goal: >
  Keep one focused project hub for the automated relay effort, linking outward to the
  canonical phase plans, operational docs, and completion evidence.
---

# Automated Relay — project hub

**Why this is the focus (operator decision 2026-06-15):** between the two efforts,
the **fully automated relay** is the higher-daily-use tool, so XYZ-swarm progress
is **deferred** in favor of finishing this. This doc is the single focused tracker;
deep specs live in the linked canonical docs.

## Status

| What was just completed | What's next |
|---|---|
| **Phases 1-5** shipped and packaged on 2026-06-15; the automated relay project reached its stated definition of done. First real cross-repo **dueling-claudes** run completed 2026-06-26 (4/4 phases green) — field findings captured below. | **Next increment — commit-signal advance:** make the relay advance on the peer's fix commit (tick token optional), per [Field findings](#field-findings--first-cross-repo-dueling-run-2026-06-26) + [ROADMAP queue](../../ROADMAP.md#queue--parked-intake). |

## North star
A `/relay` Producer↔Reviewer loop that runs **hands-free** (all-Claude) or one-line-nudge
(cross-model), **recovers from stalls** (watchdog), and terminates cleanly on `Approved`.

## Status snapshot
| Phase | What | State |
|---|---|---|
| 1 | Turn-token core (handoff-exclusive `tick` rule) | ✅ shipped |
| 2 | Liveness & self-healing (`watchdog.sh`) | ✅ shipped |
| 3 | Termination & verdict gating (`runner.sh`) | ✅ shipped |
| 4 | Hands-free poll (`poll.sh`, `relay-drive.sh`) | ✅ shipped (baton model) |
| **(a)** | **Relay turns → tick-native `RELAY-TURN`** (uses Phase-1 rule + watchdog-visible) | ✅ **DONE + Codex-approved** 2026-06-15 (close-mismatch Blocker caught+fixed) |
| 5 | Package as sibling `skill/relay-automation/` | ✅ **SHIPPED** 2026-06-15 (SKILL.md + tarball + self-extract test) |

**✅ PROJECT COMPLETE (Phases 1–5).** `validate.sh` 20/20 at ship time. Automated, self-healing relay shipped + packaged; cross-model + Option-A headless proven, with the current operator contract now treating Codex and agy as co-equal Path-A workers.

`validate.sh`: **18/18** (added `watchdog-relay.sh`; `poll-driver`/`poll-relay` converted to tick-native). Phase-4 QA: 10/12 (open: live two-window E2E + race hammer-test).

## Deferred (explicitly, with triggers)
- **XYZ swarm further progress** — paused; lower daily use. Resume if parallel builds become routine.
- **Option A (headless CLI) + cross-model relay — ✅ SHIPPED 2026-06-15; current live lane = Codex + agy.** `codex-turn.sh` and `agy-turn.sh` now ship as co-equal Path-A headless workers behind the same path-allowlist / no-push boundary; the operator contract lives in `relay-automation/README.md`. Runtime differences remain explicit: Codex and agy have different auth/sandbox caveats, and the agy lane is currently cost-blind. See `relay-automation/CROSSMODEL-OPTIONA-PLAN.md`.

## In progress
- **Phase 5** plan drafted (`relay-automation/PHASE-5-PLAN.md`); **automated-relay dogfood running** (`relay-system/2026-06-15/phase5-plan-autorelay.md`) — all-Claude hands-free run reviewing the Phase-5 plan, which is also Phase-5's 5c "real run + metrics" step and the live two-Claude E2E (QA item 196).

## Canonical docs (don't duplicate — link)
- Plan: `PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md` (Phases 0–5 + QA checklists)
- Phase-2 detail: `PROJECT/2-WORKING/EXP-AUTOMATION/PHASE-2-PLAN.md`
- Phase-2 build brief: `PROJECT/2-WORKING/EXP-AUTOMATION/PHASE-2-BUILD-BRIEF.md`
- Phase-4 build: `relay-automation/PHASE-4-PLAN.md`
- (a) scope/estimate: `relay-automation/PHASE-4A-SCOPE.md`
- Operator usage: `relay-automation/README.md`
- Decisions: `decisions/` (graduate-phase-2, relay-turns-tick-native)
- Running log + narrative: `CHANGELOG.md` (end-of-iteration record; `RECAP.md` retired → `PROJECT/4-MISC/`) · observations: `REAL-AGENT-OBSERVATIONS.md`

## Field findings — first cross-repo dueling run (2026-06-26)

First real **DUELING-CLAUDES** run against a foreign repo: the KISS-woo-fast-search bug-fix batch,
four gate-verifiable phases (#72/#71/#68/#70), Reporter = an xyz window, Maintainer = a Claude window
on the plugin repo, objective referee = the plugin's `bash tests/run.sh`. Outcome: **all four phases
green, gate `12 passed / 1 failed`** (the lone red is the #75 human checkpoint, expected). Thread:
[relay-system/2026-06-26/kwfs-dueling-bugfix.md](../../relay-system/2026-06-26/kwfs-dueling-bugfix.md).
Actionable items distilled into [ROADMAP.md → Queue / parked intake](../../ROADMAP.md#queue--parked-intake).

### What worked
- **Gate-as-referee made same-model dueling trustworthy.** A fix was accepted on red→green of its
  invariant, not on one Claude's opinion of another's diff — the whole reason a Claude↔Claude loop is
  defensible here despite shared blind spots.
- **Verify-first caught real Reporter planning errors.** The Maintainer found that `get_edit_url()` was
  `private static` (my #68 report assumed it was externally callable → would have been a fatal), that
  there were **two** hardcoded `post.php?post=` literals not one, and that #70's "delete the duplicate"
  was impossible (see below). The Reporter's plan was imperfect; the Maintainer's verification was the
  safety net. Good evidence the two-agent split adds value.
- **Commit-watcher = a better hands-free interface than the tick lock** (see What didn't, #1).

### What did NOT work (the real payload)
1. **The tick token is dead weight when one peer doesn't join `tick`.** The Maintainer never
   `claim`/`ping`/`release`d — it read the relay file, fixed, committed, and waited for "go", entirely
   out-of-band. So the token coordinated nothing and only drove the Reporter's poll, which sat idle as
   `parked suspect but no watchdog authority`. Every handoff back to the Reporter needed a manual
   `reap`+`claim` reconcile. → ROADMAP "commit-signal advance" + "token resilience".
2. **The single relay token went `spent/reserved — not claimable` mid-run** after a few
   `release --to peer` cycles — blocked re-claim outright and forced retiring the token. The known
   relay-turn-token-reuse limit, hit live in a multi-round relay (not just a closed→reopen attempt).
3. **A `#70`-style convergence gate pinned a *worse* code shape.** The gate statically extracts a
   literal `return array(...)` from each of three formatter methods and asserts equality — so delegating
   to one canonical method + deleting the duplicates (the issue's actual goal) **fails the gate**. The
   Maintainer kept three duplicated-but-identical literals: "converged" by the gate's measure, divergent
   in the code. A needle gate that enforces a property can block the refactor it's meant to reward.
4. **In-loop gate verification false-fails under the Bash sandbox.** Re-running `bash tests/run.sh` from
   the orchestrator under the sandbox reported "31 files with syntax errors" because PHP couldn't create
   lock files; the un-sandboxed re-run was clean (`12 passed/1 failed`). In-loop gate self-checks must
   run sandbox-off, or trust the peer's run + spot-confirm.
5. **Per-minute idle-poll churn.** The Reporter's 60s `/loop` burned a full turn each tick while the run
   was human-gated on "go". Replaced mid-run with a **2-minute commit-watcher** that only acts on a real
   fix-commit signal — far less waste. Argues for commit-signal pacing over fixed fast polling for
   human-gated relays.

### One-line takeaway
The relay **file + the peer's commits** were the real coordination surface the whole time; the tick
token added friction without value once the Maintainer declined to participate in it. The next harness
increment is a **commit-signal-driven advance** that treats the token as optional.

## Definition of done (project)
Phases 1–5 shipped, relay turns tick-native (a), `validate.sh` green, a real automated
relay run captured end-to-end, and the whole thing installable as a sibling skill.
