# RELAY · GH-473 unstuck skill DeepSeek V4 Pro QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded from relay-automation/new-relay.sh on 2026-09-06.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff.**
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Any `[Pass]` or "verified" finding must carry a quoted span or `file:line` citation.
     Do not edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the bottom, directly above the marker. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If max `ROUND` ends without `Approved`, set
   `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh473-unstuck-deepseek-v4-pro): <role> r<N>`); no push.
7. End the turn with an explicit handoff, or `relay closed (Approved), no further turn needed`.

## Setup
- Artifact under review: **.relay-artifacts/SKILL.md** — seeded read-only by
  `relay-drive.sh --artifact-file skills/unstuck/SKILL.md`.
- Related contract to inspect: `skills/workhorse/SKILL.md` (handoff only) and
  `PROJECT/2-WORKING/GH-473-UNSTUCK-SKILL.md` (originating failure and decisions).
- Reviewer: DeepSeek V4 Pro (`deepseek/deepseek-v4-pro`) · Producer: claude-a
- Started: 2026-09-06
- Definition of Done:
  1. The skill interrupts an agent that is polishing machinery while the user's current goal is not
     moving, including the demonstrated review-cap/cache-fingerprint failure.
  2. It distinguishes a real goal blocker from correctness/safety work, an external dependency,
     polish, and a self-created cog without dismissing legitimate blockers.
  3. It selects one smallest goal-moving action, acts once, verifies observable movement, and exits;
     the recovery process cannot become a recursive workflow of its own.
  4. Cap exhaustion is not itself proof of blockage or completion; recent qualifying movement and
     the latest authoritative user goal govern the decision.
  5. It preserves authorization and parent-workflow governance, and does not silently delete work,
     bypass required review, launch external actions, or invent facts.
  6. The description routes precisely: `/unstuck` is a mid-execution recovery interrupt, while
     `/workhorse`, `/debug-mantra`, `/recon`, and `/finish-line` keep their existing jobs.
  7. The instructions are lean enough to help a stuck model move; remove ceremony, duplication, or
     ambiguous rules that could create another cog.

## Questions

Answer each directly, with `file:line` citations for defects and concrete replacement language.

1. Run the screenshot scenario mentally. Would these instructions make the agent launch the already
   accepted marathon, or could it still rationalize a fifth review/cog? Identify the exact escape hatch.
2. Is the `qualifying movement` test operational and hard to game? Does it correctly handle a narrow
   real fix completed during the latest round without mistaking polishing for goal movement?
3. Are the categories and Rung 3 falsification test sufficient to protect real correctness/safety
   blockers? Flag any wording that encourages reckless action or unauthorized mutation.
4. Is the boundary with workhorse and neighboring skills crisp? Should this remain a separate
   interrupt, or does any part belong back inside workhorse?
5. Find anything overengineered inside the anti-overengineering skill: repeated concepts, excessive
   output requirements, recursive consult/review behavior, or a rung that can be removed.
6. Review `agents/openai.yaml` for consistency with the skill and assess whether the trigger text is
   likely to fire on the intended requests without swallowing ordinary debugging or planning.

If the skill is sound, say so plainly and set `STATUS: Approved`. This is a review-only turn: do not
edit any file other than this relay file.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise stop.
3. One turn = one block appended at the bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). Commit just the relay file; no push.

## Log

### Coordinator — transport escalation

- The configured DeepSeek relay profile resolved to `deepseek/deepseek-v4-pro` over OpenRouter.
- Attempt 1 read the review inputs but OpenRouter returned `HTTP_404` before a valid review block or
  `VERDICT:` survived. The harness rejected the partial turn and released its claim.
- The one allowed retry returned the same `HTTP_404` immediately.
- The installed Command Code transport advertised the exact same model and was tried once without
  substituting a different model; it refused the request for insufficient account credits.
- No reviewer verdict exists, no artifact edit was accepted, and no sharpening is attributed to
  DeepSeek. The existing skill remains at commit `ed390b3`.

VERDICT: Blocked — DeepSeek V4 Pro is unavailable through both installed transports.

Handing off to the human — restore one of the two V4 Pro routes before requesting another review.

### Coordinator — route restored

- The operator reports that OpenRouter credits are restored.
- Resume with a fresh relay token because the prior token is terminal; retain `ROUND: 1 / 4`
  because neither failed transport attempt produced a valid review turn.
- Model and route remain exactly `deepseek/deepseek-v4-pro` over OpenRouter. This is not a model
  substitution.

Handing off to Reviewer — run the original six-question review and emit a validator-complete block.

### Reviewer (DeepSeek V4 Pro) — Round 1

swept-file: yes

The skill is well-structured, narrowly scoped, and the five-rung ladder correctly encodes the GH-473
recovery contract. The routing boundaries with workhorse, ponytail, and debug-mantra are explicit
and defensible. I find **no blockers**: every defect below is a `[Should]` or `[Nit]` that can be
resolved in one edit pass without changing the skill's architecture.

---

#### Question 1 — Screenshot scenario (review-cap/cache-fingerprint loop)

**[Unverified — no citation]** The instructions would make the agent launch, not rationalize a fifth review.

The path is traceable: Rung 1 (4a — "A cap exhausted without qualifying movement is a boundary, not
an invitation to raise the cap") blocks the cap-extension escape. Rung 3's `Required correctness or
safety` class protects the cache-fingerprint fix (a "failing check" / "explicit gate" per the table)
from being dismissed as polish, but once *that* fix is complete and the gate passes, further review
rounds fall to the `Cog` class. Rung 4 option 1 ("execute the already accepted plan") directly
selects launch over continued review. Forward-test walkthrough row 1 in the working doc
(`PROJECT/2-WORKING/GH-473-UNSTUCK-SKILL.md:76`) confirms the same trace.

No escape hatch found. The only theoretical risk — an agent misclassifying a real correctness
blocker as a cog — is mitigated by Rung 3's falsification test ("If this item were fixed now, could
the next milestone proceed?") and the table's explicit `Required correctness or safety` row.

---

#### Question 2 — Qualifying movement test

**[Should]** The test is operational but one ambiguity creates a gaming surface.

`SKILL.md:28` defines movement as "the next milestone or prevent a demonstrated correctness or
safety failure." An agent that *simulates* a correctness finding (scans for a lint warning, elevates
it to blocker, fixes it) could claim each such fix as qualifying movement and stay in the review
loop. The falsification test in Rung 3 (`SKILL.md:73`) asks "could the next milestone proceed?" but
does not require the blocker to be *pre-existing* — a manufactured finding passes that test just as
well as a real one.

**Fix:** Add a sibling question in Rung 3, immediately after the existing falsification test:

> **Was this blocker known before the current stall began?** If the blocker was only discovered by
> the activity that is itself the stall, treat it as a cog unless it meets the `Required correctness
> or safety` bar with a *demonstrated* (not hypothesized) failure.

This closes the self-manufactured-finding bootstrap without touching any other rung.

---

#### Question 3 — Correctness/safety protection

**[Pass]** The protection is sufficient. `SKILL.md:80` ("Required correctness or safety — A failing
check, violated contract, data-loss/security risk, or explicit gate — Satisfy it; never dismiss it
as a cog") is unambiguous. `SKILL.md:86-87` closes the reverse exploit: "do not relabel a real
failure as polish merely to create motion." `SKILL.md:108-110` ("never grants permission to push,
publish, delete, spend money, bypass a gate, or perform an irreversible operation") is an explicit
authorization boundary.

**[Nit]** `SKILL.md:80` says "Satisfy it; never dismiss it as a cog." The imperative "Satisfy it"
could be read as "*you* must fix it now" rather than "the blocker must be satisfied before
proceeding." This matters because the blocker may genuinely be an external dependency.

**Fix:** Change to: "Satisfy it (or name the exact external dependency); never dismiss it as a cog."

---

#### Question 4 — Boundary with workhorse and neighboring skills

**[Pass]** The boundary is crisp and belongs separate.

`SKILL.md:137-142` (Routing boundary section) maps cleanly:
- `/workhorse` — new, ambiguous problem from scratch
- `/ponytail` — implementation minimization while moving
- `/debug-mantra` — unknown failure diagnosis
- `/unstuck` — live process stalling despite an active method

`skills/workhorse/SKILL.md:202-206` ("Stalled Loop / No Goal Movement") has exactly one handoff
to `/unstuck` as a blocking interrupt, and `SKILL.md:132-134` returns to the parent ladder. Neither
skill duplicates the other's rungs.

**[Nit]** The unstuck skill's Routing boundary section (`SKILL.md:137-142`) omits `/finish-line`
(which is in the skill catalog). The finish-line skill parks scope creep for later pickup — an
agent stuck on scope expansion could need `/finish-line` but the unstuck router sends it to
workhorse instead. However, since `/unstuck`'s Rung 4 option 4 already covers "ask the operator
one crisp decision" and the Rung 4 Park instruction (`SKILL.md:98-100`) specifically says "Park
optional ideas … do not create a new artifact merely to park them," the gap is small in practice.

**Fix:** Add one line after `SKILL.md:141`:
> - Park scope creep and close a chapter with `/finish-line`.

---

#### Question 5 — Overengineering inside the anti-overengineering skill

**[Pass]** The skill is lean. 143 lines, five short rungs, one table, one receipt block. No
duplicate concepts found.

**[Should]** One rung has a redundant sub-mechanism. Rung 4's consult clause (`SKILL.md:102-106`)
specifies a fallback ("If consult is unavailable, already failed, or is itself part of the stall,
do not retry it") that restates what Rung 3 already covers — the `Cog` class already stops retrying
a failed mechanism, and the `External decision or dependency` class already covers asking the
operator when the next step is unclear. The consult clause adds a specific case-handling for the
mechanism-it-warns-about without adding protection the classification table doesn't already
provide.

**Fix (optional):** Collapse `SKILL.md:104-106` into the parent sentence: "…the coordinator breaks
the tie. Do not retry if it failed or is part of the stall — choose the simpler safe path or ask
the operator directly." This saves three lines and removes a redundant escape hatch without losing
any decision surface.

---

#### Question 6 — `agents/openai.yaml` consistency and trigger quality

**[Pass]** `skills/unstuck/agents/openai.yaml` is consistent with the SKILL.md trigger description.
The `short_description` ("Break stalled loops and restore goal movement") matches the skill's
description field and does not contradict any rung behavior.

**[Should]** The `default_prompt` (`"Use $unstuck to re-anchor the goal, stop non-essential
machinery, and choose one bounded next move."`) uses `$unstuck` which may be a variable-reference
convention but reads ambiguously — is it a literal dollar-sign, a template variable, or a skill
invocation? Compare with the trigger text in `SKILL.md:9-12` which uses `/unstuck` (slash-prefix).
The mismatch could cause a routing system that pattern-matches on `$unstuck` to miss the trigger
while one matching `/unstuck` fires correctly, or vice versa.

**Fix:** Change `$unstuck` to `/unstuck` in `openai.yaml:4` for consistency with every trigger
pattern in the rest of the codebase (SKILL.md, workhorse handoff, all other skills).

**[Pass]** The trigger text (`SKILL.md:9-12`) discriminates well: "we're stuck", "rabbit hole",
"stop overengineering", "the cogs are moving but the goal isn't", "get back to the plan" are all
high-specificity phrases that describe a stalled-live-process state. The exclusion clause ("Do not
use for a new ambiguous problem that needs the full /workhorse ladder, a still-unknown failure that
needs /debug-mantra, or ordinary implementation minimization that /ponytail already covers") is
correct negation. I cannot construct a plausible ordinary debugging or planning request that
triggers this and shouldn't.

---

#### Verdict

**Changes requested** — three `[Should]` items and two `[Nit]` items, all resolvable in one pass:

| # | Grade | Location | Issue |
|---|-------|----------|-------|
| 1 | [Should] | `SKILL.md:73` (Rung 3) | Add "was this blocker known before the stall?" sibling question to close self-manufactured-finding bootstrap |
| 2 | [Should] | `SKILL.md:102-106` (Rung 4) | Collapse redundant consult-retry fallback into parent sentence |
| 3 | [Should] | `skills/unstuck/agents/openai.yaml:4` | Change `$unstuck` → `/unstuck` for trigger-pattern consistency |
| 4 | [Nit] | `SKILL.md:80` (Rung 3 table) | "Satisfy it" → "Satisfy it (or name the exact external dependency)" |
| 5 | [Nit] | `SKILL.md:137-142` (Routing boundary) | Add `/finish-line` entry |

No blockers. The skill is sound after these fixups.

### Producer (claude-a) — Round 1 disposition

- **Modified — self-manufactured finding guard.** Added an evidence-origin question at Rung 3, but
  did not require the blocker to predate the stall: required review can legitimately discover a new
  failure. Newly found work blocks only when it demonstrates an acceptance failure, safety
  invariant, or required gate.
- **Implemented — correctness/dependency wording.** The safety row now permits naming an exact
  external dependency instead of implying the agent must fix it personally.
- **Implemented — consult compression.** Collapsed the retry fallback into the one-consult rule and
  retained the circuit breaker, direct operator question, and no-cap-extension boundary.
- **Implemented — `/finish-line` routing.** Added the missing closeout/scope-creep neighbor.
- **Declined — `$unstuck` to `/unstuck` in `agents/openai.yaml`.** Codex's authoritative
  `openai_yaml.md` contract requires `interface.default_prompt` to explicitly mention the skill as
  `$skill-name`; changing it would make the package metadata invalid. Slash syntax remains in the
  skill's cross-harness trigger text.
- **Noted — review transport validity.** DeepSeek supplied substantive findings after credits were
  restored, but used `#### Verdict` rather than the required literal `VERDICT:` and wrote
  `swept-file: yes` rather than `swept file: yes`. The harness correctly returned exit 8. This
  disposition preserves the review verbatim and asks Round 2 to emit a validator-complete block.

Basis: all five findings dispositioned against the revised skill and Codex's `openai_yaml.md`
contract; skill validation passed before this handoff.

VERDICT: FAIL — fixes are implemented but still require Reviewer verification.

Handing off to Reviewer — verify the revised artifact, adjudicate the declined metadata change, and
finish with literal `swept file: yes`, a non-empty `Basis:`, and `VERDICT: PASS`, `FAIL`, or `PARKED`.
