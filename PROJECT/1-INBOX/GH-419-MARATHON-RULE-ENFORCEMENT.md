---
title: Make the three marathon process rules deterministic by extending marathon.sh's existing --plan refusal
status: Proposed (1-INBOX — not yet active)
created: 2026-09-03
owner: noelsaw1
gh_issue: 419
source: https://github.com/HiQS-Labs/XYZ-forge/issues/419
doc_type: feature
complexity: 2
risk: 2
effort: 2
phases: 2
ratings_provisional: true
non_goals:
  - Any new script, module, config file, or write path. If it needs a new file other than its test, the design is wrong.
  - A GitHub API call inside the gate. It must work offline; existence-checking is the ledger's job.
  - Enforcement inside marathon_drive.py — it is a single-phase driver; marathon-wide rules belong at the orchestrator, once.
  - Clone-creation automation. The gate validates the name; the operator still runs git clone.
  - Retiring ROADMAP.md (GH-269) or fixing the planner source (GH-418).
related:
  - GH-212 (plan-location refusal — the existing gate this extends)
  - GH-45 (linked-worktree refusal + announced override — the pattern to reuse)
  - GH-417 (marathon umbrella whose process this hardens)
  - GH-418 (planner ledger source — separate defect, same arc)
goal: >
  Turn three documented-only marathon rules — umbrella issue, full clone, derived clone folder
  name — into deterministic refusals, by adding three conditions to a refusal block that already
  exists in marathon.sh, introducing exactly one new input and no new files.
---

# GH-419: three marathon rules, one existing gate

> **1-INBOX capture**, not an active-work doc. On promotion, create the status table.

## Why this is cheap

The instinct on reading "make three process rules deterministic" is to build a preflight module.
That would be wrong here, because **the gate already exists**.

GUIDING-PRINCIPLES §"Marathon builder default & plan location (GH-212)" records that
`marathon.sh --plan` **already refuses (exit 2)** a plan resolving outside `PROJECT/2-WORKING/`,
with a documented env override and an exemption for shipped reference examples. That is a
plan-validation refusal block with exactly the shape these three rules need.

So the whole change is **three more conditions in one existing block**, plus one new YAML key.

`relay-automation/marathon.sh` carries no frozen-twin banner and has no Python twin, so no
`Frozen-twin-exception:` trailer is required.

## The one new input

```yaml
umbrella: https://github.com/HiQS-Labs/XYZ-forge/issues/417
name: gh417-remediation          # cosmetic label only — never parsed for identity
phases: [...]
```

`umbrella:` is the **single canonical source** of the marathon's identity. The folder name derives
from it alone; `name:` is never parsed for an issue number. That is the point agy's DRY finding
forced (see "Consult outcome"), and it is why two fields cannot drift.

## The three conditions — as adjudicated

| Rule | Check | Reuses |
|---|---|---|
| 1. Umbrella present | `umbrella:` matches the issue-URL shape, read from `marathon-yaml`'s **normalized output** (already wired at `marathon.sh:63`), never a text grep. **No network call. `TMP-XXXXXX` is NOT accepted** — see below. | the `check_tracking_token` posture (`releases_app.py:1675-1694`) |
| 2. Not a linked worktree | applied to the harness clone **and** `TARGET_ROOT` when supplied — a worktree is dangerous on either side | the `--git-common-dir` idiom already written twice (`validate.sh:16-53`, `driver-lock-lib.sh:20-35`) — do not write a third |
| 3. Derived name | `basename` of the **harness clone** matches the marathon-clone shape, `<n>` from rule 1 | nothing new |

**Anchor — the two rules anchor differently, and that is deliberate.** Rule 3's name check anchors
to the **harness clone `marathon.sh` runs from**, not `TARGET_ROOT`: in a `--target-root` run the
target is a real product repo (`rebalanceOS-gh144`) that will never be named `marathon-gh-…`, so
anchoring the name there would refuse every cross-repo marathon. Rule 2 applies to **both** roots,
because the linked-worktree hazard is real on either side and it is the same one-line idiom applied
twice. Never `$PWD` — a run invoked from a subdirectory must not be refused.

**There is no "primary checkout detector", and none is needed.** Rule 3 *is* the enforcement of the
full-clone rail: a checkout named `marathon-gh-<n>-<slug>` cannot also be the operator's primary
clone. This is what reconciles the three reviewers — see "Consult outcome" below.

**`TMP-XXXXXX` is disallowed for an executable marathon.** It stays valid for a ledger row parked
offline, but a TMP token has no issue number, so rule 3's name cannot be derived from it. A
marathon that cannot name its umbrella issue is not ready to run — which is what SOP §0b already
says in prose.

## Escape hatches — each one MUST be registered, or this ships the next #217

One env override per rule, **announced on stderr, never silent** (the GH-45 pattern). But an
announced override is only half the requirement, and the half this plan originally missed is the
one with an incident behind it.

**Every new override var is a new ambient-leak channel into the pre-advance gate.** That is not
hypothetical — it is **#217 verbatim**, and the leaked variable was the override this very design
copies: `MARATHON_ALLOW_PLAN_OUTSIDE_WORKING` leaked from a parent environment and **flipped a gate
verdict**, making the GH-212 refusal vacuous. `validate.sh:170`'s own annotation records the fix and
the recipe:

1. Classify the var **SCRUB** in `gate_env.py`'s `HARNESS_ENV` registry, with a measured note in the
   house style ("MEASURED. ambient → X/Y, unset → Z/0").
2. Mirror it in the driver literal.
3. Unset it defensively in `test/marathon.sh`.
4. Pin it — the existing precedent is `test/gh217-gate-env-plan-outside.sh`, 4/0.

**Acceptance therefore requires a red control per override proving an ambient setting does not reach
the gate env.** Three refusals with three unregistered bypasses would ship #217 three more times,
pre-armed.

## Phases

1. **Parser + the two conditions.** Add `umbrella` to `bin/marathon-yaml`'s top-level schema
   (`parseMarathonYaml` currently accepts only `name` and `phases` at indent 0 and otherwise throws
   `unexpected top-level line`, `bin/marathon-yaml:56-57`), then add the conditions to the existing
   refusal block. **The parser change is real work that the first draft of this plan did not
   count.**
2. **Register every override** per the #217 recipe above — `gate_env.py` SCRUB classification,
   driver-literal mirror, defensive unset in `test/marathon.sh`.
3. **Controls.** Reds — a plan with no `umbrella:`, a **misspelled sibling key** (`tracking:`,
   `umbrella_url:`) that must be refused rather than silently no-op the gate, a linked worktree, a
   wrongly-named clone, and **one ambient-leak red per override** proving the env does not reach the
   gate. Greens — a correctly-shaped marathon still runs, and a `--target-root` marathon whose
   target is a normally-named product repo still runs. Recorded in `test/baselines/`.

   Per §13 a green gate with no witnessed red is not evidence, and here the **greens** matter most:
   an over-strict name regex would refuse every real marathon while looking like a working guard.
   Accept both `marathon-gh-<n>-<slug>` and `<repo>-gh<n>-<slug>`, allow a retry suffix, and print
   the expected shape in the refusal.

## Consult outcome (2026-09-03)

Codex (`gpt-5.6-terra`) and agy both voted **REVISE**. Transcripts:
`relay-system/2026-09-03/gh419-enforcement-120203/`.

**Unanimous, and adopted:** drop the primary-checkout half of rule 2. Codex — git cannot identify a
semantically "primary" clone without adding state, and the two-root model explicitly supports
development-checkout use. agy — rule 3's name check already refuses a primary checkout implicitly,
so a detector is redundant. Two different arguments, same verdict.

**Codex's blocker, confirmed by independent read and adopted:** `bin/marathon-yaml` rejects unknown
top-level keys, so `umbrella:` would have made every compliant plan unparsable. The feature would
have shipped with a plausible-looking guard that nothing could reach.

**Where they split, and the tie-break:** agy wanted `umbrella:` dropped as a DRY violation
(`GUIDING-PRINCIPLES.md:15`), deriving the number from `name:` instead — and its evidence was this
plan's own first draft, which had `umbrella: …/417` beside `name: gh406-remediation`. Real drift,
before any code. But deriving from `name:` is a *breaking constraint* on an existing field: the only
real plan in the tree is `2026-09-01-xyz-harness-quickwins`, which carries no issue number and would
be refused. **Kept `umbrella:`, made it the sole identity source, and left `name:` cosmetic** — one
canonical location, which is what the DRY principle actually asks for, at the cost of one parser
line.

## GLM 5.3 Max verification pass — three additions, and one reversal of the consult

Verified independently and adopted in full. Two of its claims contradicted the consult, and it was
right about both.

**1. The escape-hatch registration requirement — adopted as a blocker.** See "Escape hatches" above.
The consult never raised it; #217 is the incident and the recipe is already written down.

**2. Rule 2's "no precedent" framing was wrong, and it changes the adjudication.** `AGENTS.md:16`
already carries the rail: *"run mutation-heavy gates only in a separate disposable full clone."* A
marathon phase's gate **is** a `validate.sh` run, and GH-564 (parent clone contaminated twice in one
morning) and GH-195 are what the prose-only version failed to prevent. So this is an **existing rail
made deterministic**, not a new posture — which is this whole arc's thesis.

Codex and agy both voted to drop it, but both argued from "no precedent," and the precedent exists.
**Reconciliation: GLM is right about the posture; Codex is right about the mechanism.** Codex's
objection — git cannot identify a semantically "primary" clone without adding state — still stands
and is unanswered by GLM. agy supplied the way out: **rule 3's name check already enforces rule 2's
intent**, because a clone named `marathon-gh-<n>-<slug>` cannot also be the operator's primary
checkout. So the rail is enforced, no fragile detector is written, and `gh35-test-tiers.sh`'s
CONTROL stays valid because it guards `validate.sh`, not `marathon.sh`. All three reviewers are
satisfied without averaging any of them away.

**3. The naming evidence was incomplete, in the rule's favor — and it costs more than I said.**
There are **two** clone directories with **different** conventions. `~/marathon-clones/` holds
`gh271-waveA`, `gh396-phase0`, `gh405-mock-board`; `~/Documents/GH Repos/` holds
`XYZ-forge-gh365-qual` / `-qual2` / `-qual3` (ad-hoc retry suffixes), `-check`, `-pdda`,
`-longtail`, `rebalanceOS-gh144` (number at the **end**), and — the exemplar —
**`aegis-sleuth-marathon-2026-08-25`, carrying no issue number at all**, which is rule 1's gap
visible in a folder name.

Design consequence: the dominant existing habit is `<repo>-gh<n>-<purpose>`, so the rule as drafted
**renames even the well-behaved majority**. Accept both forms — `marathon-gh-<n>-<slug>` and
`<repo>-gh<n>-<slug>` — rather than force a migration whose only benefit is cosmetic. The property
worth enforcing is *"the folder names its umbrella issue and is not the primary checkout"*, not one
exact prefix.

**Cross-reference:** [#316](https://github.com/HiQS-Labs/XYZ-forge/issues/316) (GH issue as mandatory
tracking identity for Marathon and Jog, item + session level) is the same discipline and is open.
#419 covers the **plan-time shape check**; #316's **session-level** half — a marathon with a valid
`umbrella:` but no per-session identity still passes — stays uncovered and stays visible there.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "relay-automation/marathon.sh", "pattern": "umbrella" } ],
  "artifacts":   [
    "relay-automation/marathon.sh",
    "bin/marathon-yaml",
    "utils/py/gate_env.py",
    "test/marathon.sh",
    "test/gh419-marathon-rule-enforcement.sh",
    "test/baselines/GH-419-negative-control.md"
  ],
  "remediation": { "source": "issue#419", "criteria": "a marathon without a valid umbrella key, from a linked worktree, or in a wrongly-named clone is refused exit 2; the name derives from umbrella against TARGET_ROOT-else-ROOT; each refusal is overridable by one announced env var; a correctly-shaped marathon still runs" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
