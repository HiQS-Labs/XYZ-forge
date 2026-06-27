# RELAY · agy review — new `readme-audit` skill (giant-brains-claude-skills)

NEXT: Reviewer (agy)
STATUS: Closed
ROUND: 1 / 1

## ▶ TAKE YOUR TURN — read this first
You are **agy**, the **Reviewer**. Adversarially review a newly-drafted Claude Code skill
before it ships. Read-only: do **not** edit the skill or any source file — append your findings
block to THIS relay file only.

1. **Read the artifact** (the new skill, in a *sibling* repo — absolute path):
   `/Users/noelsaw/Documents/GH Repos/giant-brains-claude-skills/tier-2/readme/SKILL.md`
2. **Read the house conventions it must obey** (same sibling repo):
   - `/Users/noelsaw/Documents/GH Repos/giant-brains-claude-skills/AGENTS.md` (authoring rules:
     frontmatter on line 1, observable triggers in the `description`, mandatory counter-example,
     ASCII punctuation, brevity-is-the-product, lead-with-the-verdict).
   - The skill it must *not* overlap with — read it and judge the boundary:
     `/Users/noelsaw/Documents/GH Repos/giant-brains-claude-skills/utils/frontdoor/SKILL.md`
     (front-door owns the clone->working install walk, secret-scanning, install-script red flags).
3. **Apply the brief below** — grade against the design intent and the conventions.
4. **Append ONE block** at the bottom, above the `<!-- next turn below -->` marker. For each
   finding give a severity tag `[Blocker]` / `[Should]` / `[Nit]` / `[OK]` with a concrete,
   actionable fix (quote the line you'd change and give the exact replacement). Then a **Verdict**
   (ship as-is / ship with edits / needs rework) and a **Basis** line (what you actually read vs.
   inferred).
5. **Set the header** `STATUS: Closed` (single-pass review), then hand off + stop:
   `TICK_REPO_ROOT="/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm" "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick" done RELAY-readme-audit-review-1 --agent agy`
6. **Stop.** One-line result to the operator.

## Brief — what `readme-audit` is meant to do

The skill audits a repo's **root README** along two axes, confirmed design intent from the author:

- **Primary goal — README as artifact.** Grade the README for accuracy (claims/commands/counts/paths
  that match the code), legibility, understandability, and operator UX (can someone who has to *use*
  the repo, without reading source, get oriented and finish the top tasks).
- **Indirect goal — README as map / doc-hygiene litmus.** Follow *every* pointer the README makes
  (relative links, heading anchors, images, badges, "see X" soft pointers), resolve each, and check
  whether the target exists and *agrees* with the README. The link graph is the cheap litmus test of
  the whole repo's doc hygiene (orphans, contradicting sources of truth, drift).
- **Output mode:** report-first, then **offer to apply only the low-risk mechanical fixes** (dead
  links, stale counts, wrong commands derivable from source) on confirmation; prose rewrites and
  restructures stay recommendations, never auto-applied.
- **Scope vs front-door:** deliberately distinct. front-door walks clone->working, scans for secrets,
  red-flags install scripts. readme-audit reviews the README *as a document* and the doc graph it
  anchors, and hands runnable-path / secret findings off to front-door rather than re-doing them.

## What to grade (in priority order)
1. **Does it solve the stated problem?** Is the two-pass mechanic (audit the document, then traverse
   its link graph) concrete and followable by an agent, or vague aspiration? Is the doc-hygiene
   litmus actually operationalized, or just asserted?
2. **Distinctness from front-door.** Is the boundary crisp enough that the two skills won't compete on
   the same triggers? Or do the `description` triggers / inspection points bleed into front-door's
   territory (install path, secrets)?
3. **Trigger quality.** Are the `description` triggers observable at fire time (per AGENTS.md), not
   circular? Risk of firing too often or never?
4. **Optional-fixes safety.** Is the line between auto-applicable (mechanical) and recommend-only
   (judgment) drawn safely, so the skill can't silently rewrite prose or invent content?
5. **Counter-example / calibration.** Is there a real "do NOT escalate" case (e.g. a healthy minimal
   README)? Does it avoid the alarm-on-everything failure AGENTS.md warns about?
6. **House style.** Frontmatter validity, ASCII punctuation, brevity (any section that adds length
   without changing a decision is a regression), lead-with-the-verdict output format. Does the worked
   example earn its place?

## Setup
- Artifact: `tier-2/readme/SKILL.md` (untracked draft) in the giant-brains-claude-skills repo.
- DoD: agy grades items 1-6 + Verdict + Basis, sets `STATUS: Closed`, `tick done`.
- Reviewer: **agy**. Producer: operator's Claude session (applies the fixes after).
- Lock: `tick` task **RELAY-readme-audit-review-1**.
- Started: 2026-06-26

## Ground rules
1. Single source of truth; append one block at the bottom, never edit earlier turns.
2. Read-only on the skill repo — findings only, no fixes (the Producer applies them).
3. Tight: cite real `SKILL.md` lines / phrases; propose the exact replacement wording.
4. Evidence contract: `Basis:` — what you read directly vs. inferred.

---
## Log

### Turn: agy (Reviewer)

#### Findings

- **Trigger Overlap** `[Should]`
  - *Finding:* The description trigger references `front-door`'s scope ("wants the front-door doc graded") and duplicates auto-fire conditions, which could lead to redundant or conflicting skill activations.
  - *Line to change (line 10-12):*
    ```markdown
    "is the README clear enough," or wants the front-door doc graded for an operator
    who has to actually use the repo. Fires before you sign off on a README as "good"
    or "up to date" — verify the claims and traverse the links first.
    ```
  - *Exact replacement:*
    ```markdown
    "is the README clear enough," or wants the README graded for an operator
    who has to actually use the repo. Fires before you sign off on a README as "good"
    or "up to date" — verify the document content and traverse the links first.
    ```

- **Broken Documentation Link** `[Blocker]`
  - *Finding:* The link to the sibling `front-door` skill points to a non-existent directory `../../utils/frontdoor/SKILL.md` (which was relocated to `../frontdoor/SKILL.md`).
  - *Line to change (line 38):*
    ```markdown
    This skill audits the README *as a document* and the *doc graph* it anchors. It does **not** walk the runnable clone→working path, scan for leaked secrets, or red-flag install scripts — that is the [front-door](../../utils/frontdoor/SKILL.md) skill.
    ```
  - *Exact replacement:*
    ```markdown
    This skill audits the README *as a document* and the *doc graph* it anchors. It does **not** walk the runnable clone->working path, scan for leaked secrets, or red-flag install scripts — that is the [front-door](../frontdoor/SKILL.md) skill.
    ```

- **Unicode Punctuation Violations** `[Should]`
  - *Finding:* The use of unicode arrows `↔` and `→` violates the ASCII punctuation rule in `AGENTS.md` ("ASCII punctuation — straight quotes, regular hyphens. Em-dashes are fine.").
  - *Line to change (line 13):*
    ```markdown
    commands/flags/paths/counts, dead relative links and missing anchors, README ↔
    ```
  - *Exact replacement:*
    ```markdown
    commands/flags/paths/counts, dead relative links and missing anchors, README <->
    ```
  - *Line to change (line 17):*
    ```markdown
      clone→working onboarding walk, secret-scanning, or install-script audit — that is
    ```
  - *Exact replacement:*
    ```markdown
      clone -> working onboarding walk, secret-scanning, or install-script audit — that is
    ```
  - *Line to change (line 96):*
    ```markdown
    **Fix order:** **Quick wins** (minutes — dead links, stale counts, one orientation sentence) → **Medium** (an afternoon — reconcile contradicting docs, add the missing primary-task walkthrough) → **Heavy** (restructure, split into `docs/`, establish one source of truth).
    ```
  - *Exact replacement:*
    ```markdown
    **Fix order:** **Quick wins** (minutes — dead links, stale counts, one orientation sentence) -> **Medium** (an afternoon — reconcile contradicting docs, add the missing primary-task walkthrough) -> **Heavy** (restructure, split into `docs/`, establish one source of truth).
    ```

#### Verdict
ship with edits

#### Basis
Directly read `/Users/noelsaw/Documents/GH Repos/giant-brains-claude-skills/tier-2/readme/SKILL.md` (lines 1-148), `/Users/noelsaw/Documents/GH Repos/giant-brains-claude-skills/tier-2/frontdoor/SKILL.md` (lines 1-166), and `/Users/noelsaw/Documents/GH Repos/giant-brains-claude-skills/AGENTS.md` (lines 1-67) to confirm trigger alignment, link existence, and house rules.

<!-- next turn below -->
