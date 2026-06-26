# RELAY · Codex review — new `rabbit-hole` skill (giant-brains-claude-skills)

NEXT: Reviewer (codex)
STATUS: Closed
ROUND: 1 / 1

## ▶ TAKE YOUR TURN — read this first
You are **codex**, the **Reviewer**. Adversarially review a newly-drafted Claude Code skill
before it ships. Read-only: do **not** edit the skill or any source file — append your findings
block to THIS relay file only.

1. **Read the artifact** (the new skill, in a *sibling* repo — absolute path):
   `/Users/noelsaw/Documents/GH Repos/giant-brains-claude-skills/inbox/rabbit-hole/SKILL.md`
2. **Read the house conventions it must obey** (same sibling repo):
   - `/Users/noelsaw/Documents/GH Repos/giant-brains-claude-skills/AGENTS.md` (authoring rules:
     frontmatter on line 1, observable triggers, mandatory counter-example, ASCII punctuation,
     brevity-is-the-product, lead-with-the-verdict).
   - Two reference siblings for tone/shape/length: `take-a-step-back/SKILL.md` and
     `loose-ends/SKILL.md` in that repo. The new skill must read like these and must *clearly
     differentiate* itself from loose-ends, ponytail, and take-a-step-back.
3. **Apply the brief below** — grade against the design intent and the conventions.
4. **Append ONE block** at the bottom, above the `<!-- next turn below -->` marker. For each
   finding give a severity tag `[Blocker]` / `[Should]` / `[Nit]` / `[OK]` with a concrete,
   actionable fix (quote the line you'd change). Then a **Verdict** (ship as-is / ship with
   edits / needs rework) and a **Basis** line (what you actually read vs. inferred).
5. **Set the header** `STATUS: Closed` (single-pass review), then hand off + stop:
   `TICK_REPO_ROOT="/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm" "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick" done RELAY-rabbit-hole-review-1 --agent codex`
6. **Stop.** One-line result to the operator.

## Brief — what `rabbit-hole` is meant to do

The skill is a **user-invoked** circuit-breaker for when an AI keeps surfacing "one more thing"
on a task that was supposed to be simple — death by a thousand cuts. Confirmed design intent from
the author:

- **Triggers it targets:** (a) the AI trickling real issues out one at a time mid-task,
  (b) scope creep / gold-plating ("while I'm here..."), (c) wandering off the asked task into
  refactors/tangents. (NOT re-deciding settled choices — that was explicitly excluded.)
- **Behavior on invoke:** STOP the drip → do ONE end-to-end triage sweep → present a single
  prioritized list (buckets: Blocking / In scope, optional / Out of scope, dropped) → get a nod →
  proceed only on the agreed set, with no fresh piecemeal interruptions afterward.

## What to grade (in priority order)
1. **Does it actually solve the stated problem?** Is the "stop, triage once, proceed" mechanic
   concrete and followable by an agent, or is it vague aspiration? Is the one-interruption-budget
   discipline enforceable from the text?
2. **Trigger quality.** Are the `description` triggers observable at fire time (per AGENTS.md),
   not circular? Does the self-trigger condition risk firing too often or never?
3. **Differentiation.** Is the boundary vs loose-ends / ponytail / take-a-step-back crisp, or do
   they overlap enough to confuse routing?
4. **Counter-examples / calibration.** Is there a real "do NOT fire" case? Does it avoid the
   alarm-on-everything failure AGENTS.md warns about?
5. **House style.** Frontmatter validity, ASCII punctuation, brevity (any section that adds length
   without changing a decision is a regression), lead-with-the-verdict in the output format.
6. **The two examples.** Do they earn their place? Is Example 2 (sweep reveals task wasn't small)
   honest and useful, or padding?

## Setup
- Artifact: `inbox/rabbit-hole/SKILL.md` (untracked draft) in the giant-brains-claude-skills repo.
- DoD: codex grades items 1-6 + Verdict + Basis, sets `STATUS: Closed`, `tick done`.
- Reviewer: **codex**. Producer: operator's Claude session (applies the fixes after).
- Lock: `tick` task **RELAY-rabbit-hole-review-1**.
- Started: 2026-06-26

## Ground rules
1. Single source of truth; append one block at the bottom, never edit earlier turns.
2. Read-only on the skill repo — findings only, no fixes (the Producer applies them).
3. Tight: cite real `SKILL.md` lines / phrases; propose the exact replacement wording.
4. Evidence contract: `Basis:` — what you read directly vs. inferred.

---
## Log

<!-- next turn below -->
### Codex Review

- [Should] The draft misses the brief's explicit "get a nod, then proceed" gate, so the core circuit-breaker can still bulldoze into execution. Change `3. **Proceed.** Recommend a set (usually: all blocking, maybe one optional), state what you'll execute, and do it — without spawning fresh interruptions.` to `3. **Get the nod, then proceed.** Recommend the set worth doing, ask the user to confirm that set, then execute only the agreed items — without spawning fresh interruptions.` Also change `**Proceeding on:** [Exactly what you'll execute now unless told otherwise. Then do it — no fresh interruptions.]` to `**If you want, I'll proceed on:** [Exactly the agreed set I'd execute next.]`
- [Should] The self-trigger is close, but `explicitly-small, settled-scope task` is a layered judgment call that weakens an otherwise observable trigger. Change `Also self-trigger when you are about to interrupt an explicitly-small, settled-scope task with a third unsolicited mid-task finding.` to `Also self-trigger when you are about to raise a third unsolicited mid-task finding on a task the user explicitly framed as small ("quick", "simple", "one-line", "just").` Mirror the same wording in `you (the agent) are about to raise a third+ unsolicited finding on a task the user framed as trivial — fire on yourself instead of interrupting again`.
- [Nit] `dropped/deferred` quietly invents a fourth state after the skill just taught three buckets, which muddies the "single list, one sweep" promise. Change `The discipline that makes this work: after the triage, anything new gets *appended to the dropped/deferred list*, not raised as a new interruption.` to `The discipline that makes this work: after the triage, anything new gets appended to the out-of-scope / dropped list, not raised as a new interruption.` Then make the same vocabulary consistent in `New findings go on the deferred list silently — you don't re-open the drip.`
- [OK] The sibling boundaries are crisp and Example 2 earns its space. Keep `**ponytail** (always, minimalism) — "What's the laziest thing that works?" Rabbit-hole *uses* YAGNI as its cut criterion but is about batching and gating, not minimizing.` and the Example 2 ending `This isn't a one-line bump — it's a small migration.` because together they distinguish this skill from both "do less" and "step back before deciding" without padding.

**Verdict:** ship with edits

**Basis:** Read directly: `inbox/rabbit-hole/SKILL.md`, `AGENTS.md`, `take-a-step-back/SKILL.md`, `loose-ends/SKILL.md`, and `ponytail` via `ponytail-refined/SKILL.md`. Inferred only from those texts; I did not execute the skill.
