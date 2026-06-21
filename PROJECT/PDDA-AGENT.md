---
title: PDDA Agent — Roadmap Steward sketch
status: Draft - Research Only
created: 2026-06-20
updated: 2026-06-20
owner: Noel
goal: >
  Define a bounded Claude-based steward agent that reads ROADMAP.md, PDDA artifacts,
  project docs, and GitHub issue intake, then proposes project and bug-fix priorities
  without becoming the sole authority over roadmap decisions.
related:
  - PROJECT/PDDA.md
  - PROJECT/AGENTS-DOCS.md
  - ROADMAP.md
---

# PDDA Agent — Roadmap Steward sketch

## Status

| What was just completed | What's next |
|---|---|
| Steward sketch drafted and tightened through a Codex review pass — verb-by-verb approval table, phase-split tool surface, roadmap actions made pointer-only/diff-only, 3 of 5 open questions resolved. | Resolve the remaining 2 open questions (priority-scoring signals is load-bearing) and fold this review into an implementation-plan draft. |

## Context

PDDA already separates deterministic checks from LLM judgment in `PROJECT/PDDA.md`, and
`ROADMAP.md` is intentionally a pointer/index rather than a plan body. That makes this repo
a reasonable fit for a Claude-based stewardship agent, because the agent does not need to
invent the document system from scratch; it can sit on top of an explicit contract.

The Claude Agent SDK also fits the operating model. Anthropic's current docs describe the
Agent SDK as a way to build production agents with the same tool loop and context handling
as Claude Code, with built-in support for permissions, hooks, sessions, cost tracking, and
observability. The Python SDK splits one-off `query()` usage from stateful `ClaudeSDKClient`
usage; the latter is the better fit for a continuous roadmap steward.

## Goal

Build a bounded `Roadmap Steward` agent that:

- reads `ROADMAP.md`, `PROJECT/**`, PDDA lint outputs, `PROJECT/PDDA-ACTIVITY.jsonl`, and GitHub issues
- produces ranked recommendations for bug-fix priority and next project phase
- explains the reasoning and expected signal for each recommendation
- proposes doc updates without silently taking ownership of strategy

## Decision

Yes, it makes sense to use the Claude Agent SDK here, but only if the agent is the
`steward` of `ROADMAP.md` + PDDA, not the sole authority.

The assumption behind that decision is load-bearing:

- the agent is allowed to rank and propose
- the agent is not allowed to silently reprioritize work from prose alone

If that assumption is wrong, the system will drift, because "which bug first?" and
"which phase next?" are not purely document-parsing problems; they are partly policy calls.

## Scope

In scope for the first version:

- reading roadmap and project docs
- consuming deterministic PDDA outputs as facts
- reading GitHub issue intake as an additional signal
- proposing next bug fixes and next phases
- proposing `ROADMAP.md` and project-doc updates **as diffs/PRs only**, and **pointer-only** for
  `ROADMAP.md` (the steward never adds plan-body detail to it — see PDDA's pointer-only contract)

Out of scope for the first version:

- autonomous reprioritization without approval
- silent `ROADMAP.md` rewrites
- direct writes to `ROADMAP.md` (diff/PR only in v1; no in-place mutation)
- performing lifecycle-folder moves between `PROJECT/2-WORKING` and `PROJECT/4-MISC` — those stay
  deterministic-only (`pdda-stale-working-docs.sh`); the steward may *recommend* a move, never
  perform or approve one
- project closure or deferral without review
- replacing deterministic PDDA checks with model judgment

## Reversibility

Reversibility: `Easy` if the agent starts in advisory mode and only writes proposals or PRs.

Reversibility: `Costly` if the agent directly mutates `ROADMAP.md`, reorders active work,
and closes loops without approval, because then the process starts depending on its judgment.

## Blast Radius

Blast radius is initially limited to planning and documentation quality if the agent is
proposal-only. The radius becomes much wider once it can directly reorder work, promote
phases, or rewrite canonical roadmap state.

## Recommended operating model

### 1. Make a bounded `Roadmap Steward` agent

The agent should read:

- `ROADMAP.md`
- `PROJECT/**`
- PDDA lint outputs
- `PROJECT/PDDA-ACTIVITY.jsonl`
- GitHub issues

It should emit:

- a ranked recommendation
- the reason for each recommendation
- the proposed document diff
- the expected signal and revisit point

### 2. Keep deterministic facts outside the model

The agent should consume deterministic outputs such as:

- `utils/pdda-run.sh`
- PDDA activity logs
- structured findings from shell lints

It should not re-judge those checks from scratch. A deterministic failure should enter the
agent as a fact, not as another open-ended interpretation problem.

### 3. Give the agent explicit policy tools, not broad freedom

The tool surface is introduced **by phase**, so the steward never holds a policy-action verb
before its ranking inputs and approval gates exist:

- **Phase 1 (advisory, read + propose-only):**
  - `list_open_issues`
  - `read_project_doc`
  - `read_pdda_log`
  - `read_roadmap`
  - `propose_roadmap_update` — emits a **pointer-only diff/PR**, never an in-place write
- **Phase 3 (approval-gated policy actions, added only after Phase 1 lands):**
  - `propose_phase_promotion`
  - `mark_bugfix_urgent`

The design goal is to let the agent make bounded recommendations with explicit seams, rather
than giving it a general "decide everything" capability.

### 4. Require approval for consequential calls

Each verb maps to an explicit target, output shape, reversibility, and approval gate — so a
reader can tell at a glance which calls are advisory and which can touch canonical state:

| Verb | Target | Output shape | Reversibility | Approval gate |
|---|---|---|---|---|
| `list_open_issues` / `read_*` | none (read-only) | facts into the model | `Easy` | none |
| `propose_roadmap_update` | `ROADMAP.md` (pointer-only) | **diff/PR** (never applied) | `Easy` | human merges the PR |
| `mark_bugfix_urgent` | bug-fix doc / priority | **recommendation** (not applied) | `Costly` | human approval before any reorder |
| `propose_phase_promotion` | project active ⇄ deferred | **recommendation** (not applied) | `Costly` | human approval before promotion |
| _direct mutation of canonical `ROADMAP.md`_ | `ROADMAP.md` | **not in v1** | `One-way door` | out of scope unless a later phase reopens it |

The agent can prepare the call, but every row above the read-only line requires the explicit
gate named in its last column before anything canonical changes.

### 5. Start in advisory mode

The first version should output:

- recommended next phase
- recommended next bug fix
- why
- expected signal
- by when the signal should appear

That keeps the agent useful before it becomes trusted.

### 6. Only then allow scoped auto-edits

Good first auto-write targets:

- refresh status tables (in the project docs themselves)
- open or update a local bug-fix doc from a GitHub issue

Roadmap-pointer appends stay **diff/PR-only even here** — the auto-edit lane never writes
`ROADMAP.md` in place.

Bad first auto-write target:

- full autonomous roadmap reprioritization

## Why not give it full ownership immediately

The main failure mode is that the agent will overfit to what is best documented rather than
what is actually most important. GitHub issues help because they provide a second intake
source, but they should be one signal among several, not the whole queue.

## Claude-specific constraint

Anthropic's current Agent SDK docs say to use API-key-based auth or supported cloud-provider
auth for SDK-based products, not `claude.ai` login or rate limits for third-party products
built on the SDK. That constraint matters if this moves from a local steward experiment to a
real deployed tool.

## Proposed phased rollout

### Phase 0 — Agent contract

Intent:
- define what the steward may read, write, rank, and propose

Checklist:
- [ ] define the ranking inputs
- [ ] define the approval boundaries
- [ ] define the output shape for recommendations
- [ ] define what counts as a roadmap-safe auto-edit

QA gate:
- [ ] another reader can tell exactly which actions are advisory vs approval-gated

### Phase 1 — Advisory-only steward

Intent:
- let the agent read the docs and produce recommendations, but not mutate canonical state

Checklist:
- [ ] connect the agent to roadmap, project docs, PDDA outputs, and issues
- [ ] emit ranked recommendations with reasons
- [ ] produce a proposed doc diff rather than applying it

QA gate:
- [ ] the agent can explain the top recommendation and cite the specific documents or findings it used

### Phase 2 — Scoped auto-edits

Intent:
- allow low-blast-radius document maintenance tasks

Checklist:
- [ ] enable status-table refreshes
- [ ] enable roadmap-pointer updates **as diffs/PRs** (not in-place writes)
- [ ] enable creation or update of local bug-fix docs seeded from GitHub issues

QA gate:
- [ ] all auto-edits stay within explicitly allowed document surfaces

### Phase 3 — Approval-gated prioritization actions

Intent:
- let the agent prepare consequential roadmap changes without silently applying them

Checklist:
- [ ] propose project promotion or deferral
- [ ] propose bug-fix urgency changes
- [ ] require explicit approval before canonical roadmap mutation

QA gate:
- [ ] every consequential recommendation carries a reversibility read, expected signal, and revisit trigger

## Open questions

Resolved in this revision (folded into Scope and the approval table above):
- *Write to `ROADMAP.md` directly vs diff/PR?* → **diff/PR only in v1**; direct in-place writes are out of scope.
- *May the steward move docs between `2-WORKING` / `4-MISC`?* → **No** — lifecycle moves stay deterministic-only (`pdda-stale-working-docs.sh`); the steward may only *recommend* one.
- *`gh_issue` optional vs required?* → **deferred to PDDA, not decided here.** This is a PDDA-level contract decision (it is already an open question in `PROJECT/PDDA.md`); the steward inherits whatever PDDA sets rather than being a second place to resolve it.

Still open (these genuinely gate a stable v1):
1. What exact signals should control priority: severity, dependency blocking, stale-doc risk, human request, or some weighted mix? **(Load-bearing — Phase 1 cannot rank without it.)**
2. Should this agent live as a local repo tool first, or as a broader Claude Agent SDK service outside the repo?

## Sources

The Agent SDK pages are the authority for the SDK-behavior claims above (the `query()` vs
`ClaudeSDKClient` split, the built-in permissions/hooks/sessions/cost-tracking, and the
auth constraint); the tool-use page is background on the underlying tool loop, not proof of
Agent SDK behavior.

- Claude Agent SDK overview (authority): `https://code.claude.com/docs/en/agent-sdk/overview`
- Claude Agent SDK Python reference (authority): `https://code.claude.com/docs/en/agent-sdk/python`
- Claude tool use overview (background): `https://platform.claude.com/docs/en/agents-and-tools/tool-use/overview`
