# RELAY · Triangulate skill — tension gate + design QA (round 1: deepseek v4 pro via dsh/openrouter)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-28.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(triangulate-r1-deepseek): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `scratch/triangulate/TRIANGULATE-PLAN.md` — read it in the repo at that
  path (repo-relative to this clone). It is read-only for you: do NOT edit it; append findings here only.
- Reviewer: deepseek   ·   Producer: claude-a
- Started: 2026-08-28
- Definition of Done: the artifact is a **plan document** proposing a new Claude Code skill named
  `triangulate`, which combines three existing skills — `recon` (trace the real system before
  planning), `debug-mantra` (reproduce and falsify before committing), and `ponytail` (ship the
  laziest thing that works). The operator's explicit gate is: **build this only if the tension
  between the three is not inherently contradictory, and only if the result is grounded and
  practical.** Grade the plan against these six questions. Answer them directly and concretely —
  do not restate the plan back, and do not approve a section merely because it reads well.

  1. **Is the gate verdict in §1 right?** The plan claims the three lenses act on independent axes
     (system / claim / response) and therefore compose. Is there a case where they are *inherently*
     contradictory rather than merely competing for budget — a case the axis argument hides rather
     than resolves? If yes, that is a `[Blocker]` and the skill should not be built as specified.
  2. **Is the 2x2 in §2.2 the right arbitration primitive?** Reversibility x reach is one choice;
     blast-radius x cost-of-being-wrong is another. **Name a concrete, realistic engineering task
     that lands in the wrong cell** and gets the wrong evidence floor. A generic objection without a
     worked example is a `[Nit]`, not a `[Should]`.
  3. **Is the fixed order (recon -> debug-mantra -> ponytail) defensible?** Is there a real class of
     task where ponytail *should* run first — e.g. where a one-line YAGNI check ("do we need this at
     all?") is the cheapest disproof and makes the whole recon unnecessary? If so, the order rule
     needs an explicit exception clause; say exactly what it should say.
  4. **Is the anti-ceremony clause (§2.3 / "Anti-ceremony") strong enough?** Skills that always fire
     get ignored on the day they matter. Name a situation where this skill would fire and should not.
  5. **Placement:** `02-plan/` (beside recon and swe), `01-decide/` (beside blast-radius and
     take-a-step-back), or `04-build/` (beside debug-mantra and ponytail). Pick exactly one and give
     the one reason that decides it.
  6. **Does the draft SKILL.md in §3 itself violate ponytail?** Quote any line that is prose rather
     than instruction, and say what should replace or delete it. A skill that preaches minimalism in
     500 lines of essay has failed its own rule.

  Also required: verify the plan's factual claims where the artifact states them (the tension
  analysis quotes and paraphrases the three source skills — flag any mischaracterisation), and
  confirm the internal cross-reference paths in §3 are consistent with the placement you pick in
  Q5. Cite `file:line` or a quoted span for every `[Pass]`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer turn (deepseek) — r1

**swept file: yes** — read all 328 lines of `scratch/triangulate/TRIANGULATE-PLAN.md`. Verified all checkable factual claims: ponytail quotes (skills/ponytail/SKILL.md:48), debug-mantra four-step description (skills/swe/SKILL.md:80), pattern-match against xyz adaptation (skills/xyz/SKILL.md:66-79). Cross-reference paths in §3 verified consistent with 02-plan/ placement. Recon and debug-mantra existence confirmed in giant-brains repo via file listing. Pre-existing defects noted below where applicable.

**Verdict: Changes requested** — the plan is thoughtful and the gate verdict (Q1) is sound, but several `[Should]` issues weaken the design. None are blockers for the tension analysis, but building the skill as currently specified would yield a weaker result than the draft warrants. Address the 4 `[Should]` items before building.

---

#### Q1 — Gate verdict (`[Pass]`)

The axis argument (system/claim/response) holds. The three lenses are not inherently contradictory. The mild secondary tension — ponytail's mandate is "ACTIVE EVERY RESPONSE" (ponytail/SKILL.md:31) which would constrain *how* recon and debug-mantra execute, not just their output — is resolvable by the explicit ordering rule; the plan already makes the ordering explicit as the resolution mechanism. This is named as a design constraint, not an oversight. The gate verdict is correct.

**[Pass]** §1 axis table (lines 36-40). Quoted span: `"recon | ground truth about the **system**"` through `"ponytail | size of the **response**"` — correctly characterizes the three domains. Verified: ponytail's core mandate matches "size of response" at ponytail/SKILL.md:17 ("minimal implementation") and :37-46 (the ladder).

**[Pass]** "the one real conflict, named" (§1 lines 52-57): "how much evidence to buy" is the genuine tension. The arbitration rule in §2.2 is the correct mechanism to settle it.

---

#### Q2 — 2x2 arbitration — Reversible×Crossing cell too low (`[Should]`)

The 2x2 assigns Reversible×Crossing → "recon-lite — one lane, seams only" (plan §2.2). But a crossing change (multi-repo, multi-module, multi-caller) has a *discovery cost* that is independent of the *undo cost*. 

**Concrete task that lands in the wrong cell:** Rename a utility function imported by 20 modules across 2 repos. The change is reversible (revert the rename, everything returns to its prior state). The 2x2 says "recon-lite — one lane, seams only." But the cost of missing one import site is a silent runtime failure in a completely different repo that the developer doesn't know to check. Discoverability, not undoability, sets the evidence floor here — you need at least falsification ("I think I found all import sites — grep across both repos to confirm") rather than seam-reading. "Recon-lite" (one lane, seams) is insufficient; "falsify" (debug-mantra step 3 on the "all consumers found" belief) is the minimum.

**Fix:** Move Reversible×Crossing to "falsify" (same floor as Irreversible×Contained), or add an explicit carve: "Crossing always implies at least falsify unless the crossing boundary has been fully enumerated by the operator."

---

#### Q3 — Fixed order needs a YAGNI-first exception (`[Should]`)

The plan asserts ponytail always runs last with no exception (plan §2.1, line 77: "Ponytail always runs last"). But ponytail's rung 1 ("Does this added machinery need to exist at all?" — ponytail/SKILL.md:39-40, the YAGNI check) can disprove the premise of the entire task before any recon or debug-mantra work.

**Concrete case:** A developer asks, "Should I add a caching layer to this API endpoint?" Ponytail rung 1 in 5 seconds: "50 req/min, DB read 2ms — no caching needed, no evidence floor to set, stop." That's the whole triangulate sequence resolved before it starts. The current fixed order forces recon/debug-mantra first, which is wasteful.

**Fix:** Add an exception clause before Step 3 (Ground): "Run ponytail rung 1 against the premise of the task first — 'Does this need to exist at all?' If the answer is no, say so and stop. Otherwise proceed with the fixed order."

This is the exact scenario the Definition of Done posits as a yardstick.

---

#### Q4 — Anti-ceremony clause reaches too late (`[Should]`)

The clause reads (plan §2.3): "If writing the card would take longer than making the change…" But it only guards the card-writing step (Steps 3-5). The classification step (Step 1 — two axes) and floor read (Step 2) still fire first. A trivial typo or comment fix that triggers triangulate (because the operator said "how deep should I go?") would go through classifying the decision and reading the floor before reaching the anti-ceremony exit. Concurrently, the "When NOT to fire" list (§2.5 / draft §3) already correctly says "a typo, comment, or formatting → none of the three" — but it's positioned as a post-hoc list, not a pre-step gate.

**Fix:** Two changes:
1. Lift "When NOT to fire" to the very top of the SKILL.md, as a pre-step: "If the task matches any of these, stop and route to the single skill. Do not classify."
2. Extend the anti-ceremony clause to guard the *classification* step: "If the change is smaller than this sentence, don't classify — just fix it."

---

#### Q5 — Placement: `02-plan/` (`[Pass]`)

The plan's proposed `02-plan/` is correct.

**One reason:** Triangulate sets the evidence floor *before execution begins* — it decides how deep to go before recon/mantra/ponytail fire. That is a planning-phase activity (determining the shape and depth of investigation), not a tradeoff-evaluation activity (01-decide/), not a build-phase activity (04-build/).

**[Pass]** §3 draft SKILL.md cross-reference paths all verified consistent with `02-plan/triangulate/` placement:
- `../../04-build/debug-mantra/SKILL.md` → `<root>/04-build/debug-mantra/SKILL.md` ✅
- `../../04-build/ponytail-refined/SKILL.md` → `<root>/04-build/ponytail-refined/SKILL.md` ✅
- `../recon/SKILL.md` → `<root>/02-plan/recon/SKILL.md` ✅
- `../swe/SKILL.md` → `<root>/02-plan/swe/SKILL.md` ✅
- `../spike-360/SKILL.md` → `<root>/02-plan/spike-360/SKILL.md` ✅
- `../../01-decide/blast-radius/SKILL.md` → `<root>/01-decide/blast-radius/SKILL.md` ✅

---

#### Q6 — Draft SKILL.md violates ponytail's own rule (`[Should]`)

Ponytail states (ponytail/SKILL.md:78-80): "If the explanation is longer than the code, delete the explanation, every paragraph defending a simplification is complexity smuggled back in as prose." The draft SKILL.md (~155 lines) contains ~10 lines of explanatory prose that should be cut:

| Lines | Text | Why it's prose | Fix |
|-------|------|----------------|-----|
| 162-172 | Entire "Why the three do not fight" section | The table is instructional, but the pre-table paragraph ("They act on different axes, so they compose") and the post-paragraph ("The only genuine conflict…") are justifications, not instructions. | Cut the prose; keep only the table. The justification is already in the plan (§1), not the skill. |
| 176-178 | "You cannot know a one-liner is sufficient until you know what it has to cover; ponytail applied first is a guess wearing minimalism as a costume." | Ponytail/SKILL.md:78-80 forbids this. | Replace with one-line instruction: "Fixed order: recon → debug-mantra → ponytail. Ponytail runs last." |
| 269-271 | "This is ponytail rung 1 applied to triangulate itself, and it is the clause that keeps this skill from becoming the ritual it was built to prevent. A skill that always fires is a skill nobody reads on the day it counts." | The second sentence is an aphorism, not an instruction. | Cut the second sentence. Keep: "This is ponytail rung 1 applied to triangulate itself." |

---

#### Factual-claim verification findings

| Claim | Location | Verdict | Evidence |
|-------|----------|---------|----------|
| "the ladder is a reflex" is ponytail's own phrasing | §1 tensions table | **[Pass]** | skills/ponytail/SKILL.md:48 — exact match |
| debug-mantra's steps: reproduce → fail path → falsify → breadcrumb | §1 secondary tensions | **[Pass]** | skills/swe/SKILL.md:80 — exact match |
| ponytail has "When NOT to be lazy" section | §1 secondary tensions | **[Pass]** | skills/ponytail/SKILL.md:99 — exact match (HEADER: `## When NOT to be lazy`) |
| recon and debug-mantra exist at `04-build/` and `02-plan/` in giant-brains | §0.2 | **[Pass]** | Verified via file listing — both present |
| recon has a "Skip recon when" list | §1 (last paragraph) | **[Unverified — no citation]** | Source recon SKILL.md not available in this workspace. Claim is consistent with the pattern (ponytail and debug-mantra both have explicit skip/calibration clauses), but the specific characterization of recon's internal rules cannot be cross-checked here. |
| debug-mantra has an internal "scale rigor to the bug" calibration | §1 secondary tensions table | **[Unverified — no citation]** | Source debug-mantra SKILL.md not available in this workspace. The pattern of calibration hatches is consistent with xyz/SKILL.md's adapted mantra and swe/SKILL.md's description, but the exact phrase cannot be checked. |

---

#### Summary of required changes

1. **[Should]** §2.2 — Reversible×Crossing cell: raise to "falsify" or add the crossing carve.
2. **[Should]** §2.1 — Add YAGNI-first exception: ponytail rung 1 before the fixed order.
3. **[Should]** §2.3 / §3 — Anti-ceremony guards the classification step too; "When NOT to fire" lifted to pre-step.
4. **[Should]** §3 — Draft SKILL.md: cut ~10 lines of explanatory prose (identified by line ranges above).

**Quick wins (answerable in one edit each):**
- Cut the aphorism sentence in Anti-ceremony (§3, line 271).
- Cut the "costume" justification sentence (§3, lines 177-178).
- Cut the "Why the three do not fight" pre-table paragraph and post-paragraph prose (§3, lines 162-172, keeping only the table).
- Move the "When NOT to fire" block before Step 1 in the draft SKILL.md.
- Add the YAGNI-first exception sentence to §2.1 and the corresponding Step 0 in the draft.

Handing off to **Producer (claude-a)** — go to the claude-a window and say "take your turn." Disposition (Implemented/Modified/Declined + why) for each finding, then the relay cycles.

**NEXT:** Producer
**STATUS:** Open
**ROUND:** 1 / 4

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
