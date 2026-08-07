---
gh_issue: 396
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/396
title: "Accuracy Ledger: design constraints to settle before build"
status: "Proposed (1-INBOX — not yet active)"
created: 2026-08-01
updated: 2026-08-06
owner: noel
doc_type: feedback
related: GH-40, GH-50, GH-178, GH-390
effort: 3
complexity: 3
risk: 2
phases: 0
ratings_provisional: true
goal: >
  Record the four design constraints the Accuracy Ledger must satisfy before any code is written —
  ledger placement outside agent-writable paths, immutability verified against observed rather than
  declared writes, external ground truth as the gate, and the untested assumption that the advisor
  roster is uncorrelated enough for per-advisor calibration to carry signal — plus the ordering
  those constraints imply.
---

# GH-396 · Accuracy Ledger — design constraints before build

## Why now

A contributor thread on Anthropic's Mythos cryptanalysis results (July 2026) asked whether the
Accuracy Ledger needs to be designed to survive a model that routes around its own constraints.

The premise does not survive a close reading of the run: Anthropic published the researcher's actual
message (*"the models tend to think it is impossible to solve so they don't try they need a good
amount of prompting"*), and Claude rewrote the agent harness in response. A model was asked to fix
its own prompting setup and edited something it already had write access to inside a
researcher-built scaffold. That is **strategy adaptation in-lane**, not constraint evasion.

The useful output is not a defense against evasion — it is four design constraints that are free to
settle now and expensive to retrofit. Capturing them before the Ledger exists is the whole point.

Nothing here is implemented. The Ledger, the reflection pipeline, and the semantic-oracle wiring are
all **planned** — see the post-close verification review on #40 (compiled 2026-07-31, posted
2026-08-01) and #50.

## The four constraints

### 1 — Placement (settle now, costs nothing)

> The Accuracy Ledger MUST live outside every agent-writable path, enforced by the harness rather
> than requested of the agent.

Not a new principle: this is #50's pillar 2 ("Oracle — un-gameable correctness gate that lives
OUTSIDE the builder's write surface") applied one level up.

**The decision this forces:** `rtl_enforce` works off `git status --porcelain` and deliberately does
not touch ignored files (`relay-automation/relay-turn-lib.sh:1011-1015` — *"ignored-file safety
belongs to the agent sandbox, tracked as future"*). `.tick/` is gitignored, so a Ledger placed there
— the otherwise natural home, next to the event log — inherits **zero** protection from the
mechanism this constraint invokes. Either the Ledger lives on a tracked path, or the ignored-file
gap closes first.

### 2 — Observed, not declared, writes

> Ledger immutability MUST be verified against observed writes, not declared ones.

`oracle-guard.sh` takes two CSV path lists and asserts `ALLOW_PATHS ∩ ORACLE_PATHS = ∅` before the
loop starts. It never observes what was written. Same declared-trust-vs-actual-execution class as
#390.

**#390 does not deliver this.** Phase 1 (PR #393) is wall/CPU/RSS caps, process-group `killpg`, a
`gate-killed` escalation reason, and peak-RSS telemetry — nothing inspects what the builder wrote.
Constraint 2 remains new work after #390 lands.

Two existing observed-write mechanisms are the reuse candidates:

| Mechanism | Location | What it does |
|---|---|---|
| `rtl_enforce()` | `relay-automation/relay-turn-lib.sh:983` | Post-turn `git status --porcelain -z` vs the allowlist; off-lane writes reverted, exit 6. Subject to the ignored-file gap above. |
| `requires_test_delta()` | `relay-automation/marathon-drive.sh:584` | Asserts a declared path was actually added/modified since `PRE_PHASE_HEAD`. Already this constraint's shape, at the gate layer, on one path. |

### 3 — External ground truth

Per-source accuracy tracking needs something external to grade against. Our only equivalent is the
pre-advance gate plus `requires_test`, and both are thinner than "ground truth" implies:

- `requires_test` is **opt-in** (GH-249; `REQUIRES_TEST` empty unless `--requires-test` is passed)
  and asserts only that the declared path *changed* — not that the test is meaningful, covers the
  change, or can fail.
- The gate defaults to `bash validate.sh` in the target repo (GH-238) — the target's own suite,
  which #390 argues must be treated as the workpiece rather than trusted infrastructure.

**The Ledger cannot be more trustworthy than its oracle**, and the oracle is currently the thing
under revision by the agent being scored. #390 is necessary but not sufficient.

### 4 — Open assumption: advisor correlation (test before building)

The Ledger assumes per-advisor, per-question-type calibration carries signal. The actual roster
(`relay-automation/consult.sh:287` — `ADV_NAMES=(codex agy gemini aider)`, default
`--models codex,agy`) complicates that three ways:

- **`claude` is not an advisor** — it is a builder (`claude-turn.sh` / `CLAUDE_BIN`). A design
  assuming a Claude advisor lane is designing for a lane that does not exist.
- **`gemini` is a legacy alias for `AGY_BIN`** (`consult.sh:59`) — an "agy + gemini" panel may be
  the same binary twice. Not two advisors agreeing; one advisor counted twice. Worth checking
  against #178's A2 degraded-panel stamp.
- **`aider` is a harness, not a model** — OpenRouter-backed via `AIDER_MODEL` (GLM / Qwen in
  practice), and #147 would add an LM Studio local lane. The roster is *not* all-frontier, which
  cuts the other way and partly rescues the premise.

**Cheap test:** replay N historical relay reviews across two or more genuinely distinct advisor
lanes; measure verdict divergence. Low divergence means the premise needs rework before any build.

**Where the corpus actually is:** not `.tick/`. The event schema (`src/events.js:12-30`, `112-160`)
is `task.*` / `marathon.phase.*` / `cost.*` with `schema_version, ts, type, task, agent` plus
optional `paths / note / to_agent / reason / epoch / cost / drift` — **no verdict, status, or
finding field**. Same observation #40's 2026-06-29 comment made when it rejected the original
hand-authored fixtures. Usable corpus is the committed transcripts under `relay-system/**` and the
consult sidecars. So the test is a transcript replay, or it is blocked on new structured emission —
that choice should be explicit.

## Buildable now, no Ledger required — conflict-as-signal

On source conflict: do not pick, do not average — surface the divergence and escalate.

The existing analog escalates on the wrong thing. `utils/py/relay_drive.py:439` loops
`while round_idx < args.round_cap` (default 6 standalone, 5 under marathon-drive,
`relay-automation/marathon-drive.sh:630`); on exceeding it, `:620` prints status and token actor and
exits 4, which `utils/py/marathon_drive.py:1419` records as `cap-or-close-mismatch`. `no-progress`
(exit 3) and per-lane `LANE_MAX_ATTEMPTS` (default 2) are counts as well.

Reviewer disagreement therefore loops until a **count** runs out, and the escalation record carries
the status and the actor but not the substance of what was disputed. Routing persistent or
substantive divergence to a human gate is the same mechanism, needs no Ledger, and fits the existing
`ESCALATION.md` path — it needs a reason that describes the disagreement, not just that it recurred.

## Proposed order

1. **#390** — gate resource-guarding (Phase 1 in flight as PR #393). Prerequisite for Constraint 3;
   does not itself deliver Constraint 2.
2. **Record Constraints 1 and 2** in the Ledger design doc before any code, including the
   gitignored-path decision.
3. **Advisor-correlation divergence test** — against `relay-system/**` transcripts, or after
   structured verdict emission exists.
4. **Conflict-as-signal escalation** in the relay — independent of the above.
5. **Ledger implementation** — only after 1–3 resolve.

## Status discipline

The Ledger, the reflection pipeline, and the semantic-oracle wiring are **planned**, not shipped —
future tense in issue bodies, PR descriptions, and any external description of the project. The #40
review's central finding was closing summaries running ahead of the docs beneath them (*"solid
machinery, incomplete feature, overstated closure"*). This capture should not add to that.

## Provenance

- Issue: [#396](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/396)
- Related: [#40](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/40) ·
  [#50](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/50) ·
  [#178](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/178) ·
  [#390](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/390) · PR #393
- Source thread's external citation on cross-domain validation could not be verified and was
  dropped; the argument does not depend on it.
