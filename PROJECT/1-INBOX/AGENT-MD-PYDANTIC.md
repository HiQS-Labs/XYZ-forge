Analysis: Pydantic's "What makes a good agent harness"

Article: <https://pydantic.dev/articles/what-makes-a-good-harness> (David Sanchez, Pydantic, June 2026)

**Core hypothesis:** a good harness comes down to **timing** — get the model the right instructions/tools at the moment it needs them (**disclosure**), and catch it fast when it drifts anyway (**steering**). Concretely: defer-load capabilities/tools until the model reaches for them, and consider **code mode** (the model writes code that calls tools in a loop instead of one tool-call-per-round-trip). Lopopolo's line, quoted in the piece: the harness should surface instructions to the model at the right time; every manual "continue" is a harness failure.

### Where the article is right

- A genuinely useful unifying frame. Progressive disclosure, tool search, deferred capabilities, and code mode look like separate features until you name the shared principle — "don't load anything before it's needed." Same logic the Giant Brains skills already run on (name+description always loaded, full SKILL.md on trigger, scripts on invocation).
- The **steering** half — "every time I have to type 'continue' is a harness failure" — is the sharper claim, and it's exactly what the Gemma + `checkin.py` loop does: a second model watching for drift instead of a human. The article validates that pattern rather than introducing something new.

### Where to push back

- **Disclosure and steering aren't independent knobs — they trade off.** The less you front-load, the more the model reaches mid-run, the more chances to reach wrong, the more steering you need. They're one budget allocated between "tell it now" and "catch it later," not two separate techniques.
- **Code mode's cost is understated.** Collapsing N tool calls into one program cuts round-trips and context but loses clean per-call observability — a bug surfaces as a sandbox stack trace instead of a legible tool-call log. Risky where you need to see *which* step failed, which is most of debugging the Aider/GLM pipeline.
- **Not much is new in substance** (progressive disclosure, ReAct-style self-correction predate it). The contribution is naming it cleanly and shipping real tooling (Pydantic AI v2 capabilities, `ToolSearch`, `CodeMode`) around it.

### One thing worth stealing for AGENTS.md v2

Frame the eleven rules explicitly as **disclosure rules vs. steering rules**. The SOLID/Ponytail/Ousterhout organization is by design-philosophy lineage; the pydantic framing adds a second axis — "does this rule control what the agent sees, or how fast a drift gets caught" — which exposes gaps. Likely finding: strong disclosure rules, weaker explicit steering/drift-detection rules — the same asymmetry `checkin.py` exists to patch.

---

4. Project plan: AGENTS.md Builder (two-axis)

Goal: a builder that bakes the disclosure/steering axis in as a first-class concept. Quick wins first, then heavier lifts.

### Phase 0 — Diagnostic (today, ~1hr, no code)

1. Take the existing v2 eleven rules. Tag each: **disclosure**, **steering**, or **both**.
2. Count the split — expect a disclosure-heavy skew (the gap the frame predicts).
3. Write down any steering rule you wish existed but don't have ("stop and ask when X," "self-check against benchmark before declaring done"). Seed backlog.

_Output: a one-page tagged table. Worth doing even if nothing else gets built._

### Phase 1 — Builder as a skill (core deliverable)

4. Scaffold `agents-md-builder` off the existing funnel pattern (voice-forge / prd-creator lineage: interview → artifact).
5. Interview funnel organized on **two axes** instead of philosophy lineage:
   - Disclosure questions: what loads always vs. on-demand, what's deferred, what the agent should not see up front.
   - Steering questions: what counts as drift here, stop conditions, who/what catches a wrong turn and how fast.
6. Bake SOLID/Ponytail/Ousterhout in as the **content library** the builder draws from — but emit each rule **tagged** with its axis. Philosophy lineage becomes metadata, not top-level organization.
7. Ship a coverage check as the last funnel step: if the generated file is all disclosure and no steering (or vice versa), flag before writing. Make it non-skippable — this is the one genuinely new thing the article buys.

### Phase 2 — Audit mode (retrofit existing files)

8. Add an audit entry point: point the builder at an existing AGENTS.md, classify each rule onto the axis, report balance and gaps.
9. Reuse the agree/disagree review-triage pattern (grounded-search v5) so the audit produces actionable findings, not just a score.
10. Run against real AGENTS.md files across repos — where the skew shows up and where reusable steering rules get harvested back into the library.

### Phase 3 — Close the loop (harder, higher-value)

11. Wire the rule library to `auto-improve` so validated steering rules from one audit propagate as candidates (bounded, editor/grader separation intact).
12. Add a grounding pass (`grounded-search`) for any rule making a factual claim about tool/CLI behavior — the same Jan-2025 staleness risk that bites Gemma bites hardcoded governance rules.
13. Optional: emit tagged rules in a machine-readable block so a live harness (XYZ / Ground Control) can consume the disclosure/steering split at runtime — deferring disclosure rules, activating steering rules as check conditions.

### Sequencing notes

- Phases 0–2 are the real project; Phase 3 is where it becomes harness infrastructure. Don't start Phase 3 until an audit on your own files proves the two-axis classification is stable — if you can't reliably tag your own rules, a downstream harness can't consume the tags.
- Scope-control flag: **don't make the builder itself multi-agent.** It's interview-plus-classify; a single strong model with a strict funnel does this better than a swarm and keeps the blast radius of a bad generated AGENTS.md small.

---

## Open threads / next actions

- Decide whether to package **Phase 1** as an actual skill installer (same format as the Gemma skill) or draft the **two-axis interview funnel questions** first to pressure-test the classification before committing to a build.
- Smoke-test the exact Aider CLI flags in `variations.example.yaml` against the current Aider version before the first full 2–3hr run.
- Run Phase 0 diagnostic on the existing AGENTS.md v2 to confirm (or refute) the predicted disclosure skew.