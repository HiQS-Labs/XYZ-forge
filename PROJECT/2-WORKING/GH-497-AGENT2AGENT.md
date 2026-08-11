---
gh_issue: 497
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/497
title: "GH-497 — agent2agent compact multi-session rendezvous"
status: "2-WORKING — implementation and focused QA complete on feature/agent2agent; awaiting PR review."
created: 2026-08-11
updated: 2026-08-11
owner: noel
doc_type: feature
effort: 3
complexity: 3
risk: 2
phases: 3
ratings_provisional: false
roadmap_exempt: false
non_goals:
  - "Parallel writers, broadcast or fan-out replies, voting, or cross-machine transport."
  - "A new Tick event or messaging schema, or any relay-containment change."
  - "Replacing the existing Producer/Reviewer artifact-review relay mode."
goal: >
  Let two or more local agent sessions join one serialized file-based discussion through a compact
  numeric ID and plain-language agent numbers, reusing XYZ's relay storage and file turn routing.
---

# GH-497 — agent2agent compact multi-session rendezvous

## Status

| What was just completed | What's next |
|---|---|
| Implemented the skill/helper, exact invitation flow, 2+ roster routing, dual Claude/Codex installer, docs, and 39-case regression suite. Skill, PDDA, dashboard, Python 3.8 grammar, poll interoperability, and focused safety gates pass. | Commit and push the branch, open a PR to `development`, and report the two full-suite failures inherited unchanged from that base branch. |

**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/497

## Context

The proven Dueling Claudes prototype already lets two live sessions communicate through one relay
file, but its long paths, setup commands, and Producer/Reviewer vocabulary obscure the simple user
experience. The desired invitation is compact and immediately actionable:

```text
Join XYZ agent2agent #123456 as agent number two to discuss: "subject line here"
```

The relay is multi-party but deliberately serialized: the roster can contain `agent1` through
`agentN`, while `NEXT:` grants exactly one participant the next write. A participant may hand the
following turn to any other roster member.

## Reversibility and blast radius

**Easy** — the feature is additive: one skill, one helper, tests, and documentation. Removing those
files restores the previous behavior. The existing Tick event vocabulary, containment rules,
poller, relay drivers, and Producer/Reviewer workflow are not edited. The only shared surface is the
repository validation list that registers the new test.

## Acceptance

*Copied verbatim from [issue #497](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/497), fetched 2026-08-11. Deviations, if any, are recorded immediately below.*

- [x] Add an `agent2agent` skill with deterministic start/join behavior and concise trigger metadata.
- [x] Reuse the existing `relay-system/<date>/` storage, `NEXT:`/`STATUS:` file routing, and `poll.sh --turn-source file`; do not change Tick event shape or relay containment.
- [x] Support any declared participant count of at least two, with stable internal IDs `agent1`, `agent2`, ... and plain-language invitations.
- [x] Starting seeds turn 1 with the requested subject, routes to `agent2`, and prints the exact compact invitation form.
- [x] Joining by ID resolves exactly one discussion, fails loudly on missing/ambiguous IDs, verifies membership, and refuses out-of-turn writes.
- [x] A participant can route the next turn to any roster member; turns remain serialized.
- [x] Add deterministic tests for two-agent and 3+ agent discussions, collision avoidance, exact invitation output, discovery, out-of-turn refusal, routing, and close behavior.
- [x] Validate the skill metadata and run the repository gates.

### Acceptance deviations

None.

## Ordered implementation

1. Add the `agent2agent` skill and a standard-library Python helper for `start`, `join`, `send`, and
   `close`; use a collision-checked six-digit ID and an atomic per-discussion write lock.
2. Add deterministic regression coverage for exact invitations, seeded discussion state, 3+ agent
   routing, collisions, discovery failures, turn ownership, and terminal state.
3. Document installation/use, run the focused test, skill validator, PDDA gate, frozen-twin guard,
   and full `validate.sh`; then commit, push, and open the PR against `development`.

## QA evidence

| Gate | Result |
|---|---|
| `bash test/agent2agent.sh` | **PASS — 39/39**, including Python 3.8 grammar, exact prompt, poll interoperability, agent3/agent4 routing, collision retry, byte-preserving refusals, and dual install. |
| `python3 .../skill-creator/scripts/quick_validate.py skills/agent2agent` | **PASS — Skill is valid.** |
| `utils/pdda/pdda.sh run` | **PASS — 0 errors**; 14 pre-existing repository warnings. |
| `bash test/roadmap-dashboard.sh` | **PASS — 9/9** after regenerating the derived dashboard. |
| `bash test/mktemp-trap-guard.sh` | **PASS — 1/1**, 299 shell surfaces audited. |
| `bash test/gh308-frozen-twin-guard.sh --check --staged` | **PASS — no frozen Bash twin changed.** |
| `RELAY_SELF_SUFFICIENCY_SKIP=1 bash validate.sh` | **PASS — 179/179** after rebasing onto `origin/development@918e3f0`; exit 0. The live-agent self-sufficiency case was deliberately skipped through its documented CI switch. |
