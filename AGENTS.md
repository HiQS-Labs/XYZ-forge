# AGENTS.md

Read `ROUTER.md` first for startup order and canonical files.

Read `GUIDING-PRINCIPLES.md` for the product north stars.

Read `PROJECT/PDDA.md` when the task touches project docs, `ROADMAP.md`, or `CHANGELOG.md`.

## What this file owns

This file is the behavioral playbook for work in this repo: decision quality, reversibility, blast
radius, planning shape, and proof.

Do not restate routing, roadmap, changelog, or active-doc contracts here. Those live in
`ROUTER.md` and `PROJECT/PDDA.md`.

## Operating principles

### 1. Lead with the line that survives skimming

Your first sentence gives the verdict, current state, or call. No setup first.

### 2. Make the bet explicit before acting

State the assumption, tradeoff, and failure mode that matter before you commit to a path. If a future
reader could not say "that assumption was wrong," you have not made the real bet legible yet.

### 3. Use one reversibility scale

Consequential changes get a read on the shared scale: **Easy / Costly / One-way door**, with one line
of why. If undoing it would take more than a day of focused work, it is at least Costly. Costly
changes need a rollback path. One-way doors need explicit confirmation before proceeding.

### 4. Size the blast radius before changing shared surfaces

Before a refactor, schema change, dependency bump, coordination-kernel change, or relay-containment
change, say what ripples, what might break, and who notices. A change you cannot size is not ready.

### 5. One plan, one ordered list

When you give executable steps, put them in one numbered list in execution order. Keep verification
inline (`-> expect ...`). Do not scatter action items across prose.

### 6. Verified beats plausible

Do not claim success without the relevant test, script, or observable proof. If verification was
skipped or failed, say that plainly and include the result.

### 7. Record only consequential bets

If a change is Costly, One-way door, or assumption-heavy, record the bet in `CHANGELOG.md` per
`PROJECT/PDDA.md`. Below that threshold, skip the ritual.

### 8. Stay quiet on trivial work

Most edits are small and reversible. Do not manufacture ceremony for a rename, typo fix, or other
local change.

## Repo-specific rails

- `ROUTER.md` owns startup order, canonical files, command rails, and the issue-first SOP.
- `GUIDING-PRINCIPLES.md` owns the product/runtime priorities: local event-log coordination,
  containment, skill-first relay work, durable fixes, and verified done.
- `PROJECT/PDDA.md` owns doc lifecycle, `ROADMAP.md` pointer-ledger rules, and `CHANGELOG.md`
  governance.
- `validate.sh` is the code/runtime gate. `utils/pdda/pdda.sh run` and its targeted
  `utils/pdda/pdda.sh <check>` subcommands are the doc-hygiene gates.
- Changes to `.tick/events/`, `src/project.js`, relay containment, or event/verb shape are usually
  broader than they look. Treat them as at least Costly until proven otherwise.
- **Commit to the QUEUE; re-anchor, don't rabbit-hole (GH-45).** A wave's committed lane list *is* the
  active commitment — after each lane attempt, re-read it before acting further. A driven lane that
  fails **parks** after `LANE_MAX_ATTEMPTS` (default 2): the driver (`marathon-drive.sh` /
  `relay-drive.sh`) refuses to re-fire it (exit 8, no token), you capture the findings as an issue and
  stop. Re-firing a parked lane or going off-wave to deep-dive one item requires an explicit operator
  override (`--force`) or a replan note — never a quiet slide off the plan.

## Conflict order

1. The current user request
2. The canonical doc that owns the surface you are touching (`ROUTER.md`, `GUIDING-PRINCIPLES.md`,
   `PROJECT/PDDA.md`, or the active `PROJECT/**` doc)
3. This file
4. Skill defaults
