---
title: "GH-537: skills: new skill /five — the 5-and-5 decision checksum (5 key highlights + 5 explicit non-goals)"
status: active
created: 2026-09-09
updated: 2026-09-09
owner: orchestrator (Claude Code)
goal: give the operator a skimmable checksum layer over any plan/feature/fix — exactly 5 load-bearing decisions and 5 explicit non-goals, each grounded in the artifact — so unasked-for decisions surface at approval time instead of after
gh_issue: 537
source: https://github.com/HiQS-Labs/XYZ-forge/issues/537
branch: feat/five-skill
doc_type: enhancement
effort: 2
complexity: 1
risk: 1
---

# GH-537 — `/five`: the 5-and-5 decision checksum

## Status

| What was just completed | What's next |
|---|---|
| Implemented + impl QA APPROVED round 3 2026-09-09 (round-1 FAIL: 4 Should + 1 Nit; round-2 FAIL: 2 Should + 1 Nit — all fixed) | Push through gate; open PR into development (merge held by operator) |

## Problem statement

An operator worked with an AI on moving a run-time folder. The AI asked its questions, wrote
the plan, and **made decisions the operator did not read** — the plan was long, the decisions
were buried, and the operator approved without reading. The operator's stated mistake was not
reading; the structural defect is that nothing cheap sits between "AI wrote a plan" and
"operator approved a plan." This repo already requires plans to carry explicit non-goals
(start-task step 5, AGENTS.md operating principles) — but nothing *surfaces* them at the
moment of approval, and nothing surfaces them mid-implementation when scope quietly drifts.

## Design (operator request, 2026-09-09)

A zero-install skill — markdown discipline only, no scripts, no runtime (the `/ponytail` /
`/timbre` shape) — callable at any stage: after planning, during writing, mid-implementation,
before the final report.

**Output contract: exactly 5 + 5.**

1. **Five key highlights** — the load-bearing *decisions and behaviors*: what the plan/fix
   actually does, prioritizing choices the agent made that the operator never explicitly
   asked for. Decisions, not features: "moves the runtime folder to X and leaves a symlink
   behind" is a highlight; "improves organization" is marketing and is banned.
2. **Five things it does NOT do** — non-goals a reasonable reader might otherwise assume are
   in scope. Not strawmen: adjacent work someone would plausibly expect ("does not migrate
   the old data", "does not update docs referencing the old path").

Hard rules the skill body must encode:

- **Grounded.** Every item cites where the artifact says it (plan section, `file:line`,
  commit). Five summarizes an artifact; it does not generate from vibes. Exemptions and
  precedence: "nothing else load-bearing" padding markers carry no citation; a substantive
  non-goal requires supporting text in the artifact (where the plan's scope ends). **Silence
  is not a non-goal** — an adjacent capability the artifact never mentions is reported as
  "not specified", never dressed up as an explicit "does NOT do".
- **Empty-input guard outranks the count.** No artifact (or an empty one) → say so, invent
  nothing; this guard takes precedence over the 5+5 contract. An empty input passes every
  check.
- **Exactly five and five.** Fewer real items → the remaining slots say so explicitly
  ("nothing else load-bearing found"), never filler. Padding is worse than a short list.
- **Checksum, not substitute.** Five tells the operator when to go read the plan; it never
  replaces reading it and says so in its own output.

## Non-goals (of this task)

- No scripts, no tests-as-code, no runtime — one `SKILL.md`, one ARCHITECTURE.md Skills
  Index row, and one CHANGELOG.md entry (all three named; no fourth surface).
- No global symlink deployment (operator-requested only, per GH-514 precedent).
- No changes to existing skills (`start-task`, `phase-qa`, `swe`) — five is additive and
  composes with them; wiring it into their bodies is out of scope.
- No fixing of the known ARCHITECTURE.md index drift (timbre/unstuck/workhorse/merge-cleanup
  missing) — #453 owns that; this PR adds only its own row.

## Acceptance criteria

- [x] `skills/five/SKILL.md` exists, skill-creator frontmatter conventions (folded
      block-scalar description with colons, per c4088fae).
- [x] Fires on `/five`, "five", "give me the five", "key highlights", "what does this NOT do".
- [x] 5+5 contract, grounding rule with the silence-is-not-a-non-goal clause, empty-input
      guard with precedence over the count, no-filler rule, and checksum-not-substitute
      boundary stated as hard rules.
- [x] One-line row in `ARCHITECTURE.md` → Skills Index; one CHANGELOG.md entry.
- [x] Zero new scripts of any kind (GH-551).
- [x] `utils/pdda/pdda.sh run` zero errors after promotion. (green twice: post-intake 2026-09-09 and post-implementation 2026-09-09)
- [ ] **Behavioral QA (manual, no scripts; run during final relay QA and recorded in the
      relay thread)** — the criteria above check instructions; this one checks output.
      Exercise the drafted skill's procedure on three inputs:
      (a) nonempty source text with more than five decisions, including at least one
      unrequested consequential choice, explicit exclusions, and one adjacent capability
      left unstated — expect two full five-slot cited lists, the unrequested choice
      surfaced, the unstated capability reported as "not specified" and NOT claimed as an
      explicit non-goal;
      (b) sparse input (fewer than five load-bearing items) — expect honest sparse
      markers, no filler;
      (c) empty input — expect refusal, no invention.
      Red control: one deliberately bad output (a marketing-style highlight or an
      unsupported exclusion) must FAIL this check. Record inputs, outputs, and the
      verdict in the implementation relay thread. (executed 2026-09-09: dense PASS, sparse PASS,
      empty PASS, red control rejects; transcript embedded in relay-system/2026-09-09/gh537-five-impl-qa.md)

## Rating rationale (2026-09-09; sev reworded per plan-QA round 1, F3)

rated 70/25/50/70 — pri 70: explicit operator request, currently the active ask; sev 25:
judged as pain-if-left-undone (GH-108 vocabulary), not implementation risk — the recurring
operator cost of reading full plans to catch buried decisions, plus the
approval-misunderstanding class that cost creates, is real but bounded process pain with no
runtime or data consequence; appeal 50: neutral, none supplied; effort 70: well-scoped
single-file authoring with an existing QA loop (calibrated against GH-514 keel at
70/25/50/65; five has no precedence stack or modes, slightly cheaper).
