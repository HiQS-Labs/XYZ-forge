---
gh_issue: 368
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/368
title: "GH-368 — marathon-plan.sh documents --check as a validate.sh drift guard, but validate.sh never runs it"
status: "Intake (2-WORKING) — captured 2026-08-05 for release 0.2.0 Litmus, not yet fired. Scoped to Option B; Option A is deliberately left to its own decision. MUST FIRE BEFORE #418 — see Sequencing."
created: 2026-08-05
updated: 2026-08-05
owner: noel
doc_type: project
release: "0.2.0 Litmus"
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: false
related:
  - "#419 — the class, in its purest form: a documented guard that reads as active while nothing runs it."
  - "#418 — COLLIDES. Its frozen-artifact check would refuse this lane's only write target. This lane must fire first; see Sequencing."
  - "#336 — its sidecar design exists to avoid a false-drift interaction with --check. That hazard is latent only because nothing runs --check; whichever of the two lands second must confirm the other's assumption holds."
  - "#315 / #319 / #348 — the same family named in the issue: the signal said protected and the protection wasn't there."
non_goals:
  - "Changing what --check does. The flag's behavior is correct; only its documented reach is wrong."
  - "Option A — wiring --check into validate.sh. Separable, and conflating them is how a one-line doc correction turns into an open-ended CI project. See the deviations section."
  - "Bundling this with #348. Both are drift-guard gaps, but that one is Bash↔Python engine parity and this one is plan-doc freshness."
goal: >
  `utils/marathon-plan.sh:67` documents `--check` as a drift guard running in `validate.sh`.
  `validate.sh` invokes it zero times. The flag works; nothing calls it. An agent or operator reading
  the file learns that plan-doc drift is caught by the suite — it is not, and a stale
  `MARATHON-PLAN-<date>.md` can diverge from what the ledger would render with the suite fully green.
---

# GH-368 · a guard that reads as active while nothing runs it

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-05 as a lane of release 0.2.0 Litmus. Defect re-verified live. Preflight contract authored and verified READY; acceptance reads `match — 6 issue criteria reconciled: 3 deviation(s) declared and accounted for` — the first attempt was **rejected** for declaring a deviation against a still-verbatim list, which is #400's C8b working. | Operator go. One phase, one line. **Fire this before #418**, whose frozen-artifact check would refuse this lane's only write target. |

Captured 2026-08-05 as a lane of release **0.2.0 Litmus**. Not fired.

**Re-verified live on 2026-08-05** against `development` @ `2c95a56`:

```
utils/marathon-plan.sh:67:# (so --check works as a drift guard in validate.sh, mirroring roadmap-dashboard.sh --check).
validate.sh: 0 invocations of marathon-plan --check
```

The claim is still there; the guard still does not exist. `utils/py/marathon_plan.py` does **not**
carry the claim — the false statement exists in exactly one place.

## Why this is worth a ticket rather than a shrug

This is the repo's recurring failure shape, not a typo: **a documented guard that reads as active
while nothing runs it.** Same family as #315 (a stale relay token let a build-nothing run report
success), #319 (the marathon gate word-split its own path and "passed" on a 0-byte file), and #348
(parity evidence that did not cover forward drift). In each, the signal said protected and the
protection wasn't there.

It is the smallest, cleanest instance of the #419 class in the tree, which is why it belongs in this
release even though the fix is one line.

## Acceptance

*Copied verbatim from [issue #368](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/368)
(`## Acceptance criteria`), fetched 2026-08-05. Deviations, if any, are recorded below this block.*

**If B:**
- [ ] No comment in `utils/marathon-plan.sh` or `utils/py/marathon_plan.py` claims `--check` runs in
      `validate.sh`.
- [ ] The usage text still documents `--check` as a manual drift check.
- [ ] `./validate.sh` and `utils/pdda/pdda.sh run` green.

**If A (additionally):** — *the three criteria under this heading are dropped for this lane; see
the deviations section below.*

## Acceptance — deviations from the issue

**This lane is Option B.** The issue's acceptance is conditional — *"If B"* / *"If A
(additionally)"* — so a lane must choose, and choosing is a narrowing that has to be declared rather
than assumed. The issue's own recommendation is *"B first, then A on its own merits,"* and it states
the two are separable.

The three "If B" criteria are carried verbatim and are the whole definition of done for this lane.
The three "If A" criteria are dropped, individually:

- [dropped] `validate.sh` invokes it, and the invocation is *scoped* so a not-yet-rendered plan doc on an ordinary day does not turn the suite red. — reason: Option A. It carries a real false-positive question the issue states plainly — `--check` fails whenever today's plan doc has not been re-rendered, so wiring it naively turns `validate.sh` red on an ordinary day, and *"a suite people learn to ignore protects nothing."* That is a feature decision about whether the guard is wanted, not a consequence of the docs being wrong.
- [dropped] A regression case covers both states: in-sync → pass, drifted → fail. A test that only asserts the happy path would stay green if the wiring were removed again. — reason: Option A. This criterion tests the wiring the previous one adds; with no wiring there is nothing for it to cover. It moves with Option A, not with this lane.
- [dropped] Confirm the interaction with #336's sidecar design (below) still holds. — reason: Option A. The hazard is latent *because* nothing runs `--check`; only wiring it activates the trap #336 designed around. This lane does not wire it, so there is no interaction to confirm — and it becomes Option A's first question.

**Option A remains open on #368 after this lands.** Dropping these three narrows this lane, not the
issue.

## Sequencing — this lane must fire before #418

**Its only write target is a frozen file.** `utils/marathon-plan.sh` carries the GH-308 banner
(verified 2026-08-05). #418 — a sibling lane in this same release — adds a check that sets
**NOT-READY with no packet written** for any contract artifact carrying that banner.

The tension is real but narrow:

- GH-308's banner prohibits **behavior** changes: *"Python is authoritative — do not make behavior
  changes here."* Deleting a misleading comment is not a behavior change, and `marathon-plan.sh` is a
  delegating shim — `--help` prints `utils/py/marathon_plan.py`'s usage.
- #418's criterion 3 as written does not distinguish a comment-only diff from a behavior change, and
  **should not be weakened to accommodate this lane** — a frozen check with an exception for "it's
  only a comment" needs its own decision gate to judge that, which is more machinery than this
  one-line fix is worth.

**Resolution: fire #368 first.** It costs nothing, leaves #418's check strict, and removes the
collision rather than arguing about it. Recorded identically in #418's capture doc so neither lane
can be fired in ignorance of the other.

## Phases

| Phase | Deliverable | Artifacts | cx/risk/eff |
|---|---|---|---|
| 1 | Delete the parenthetical at `utils/marathon-plan.sh:67`. The usage text at `:123` already documents `--check` correctly and completely as a manual command and is left untouched. No behavior change. | `utils/marathon-plan.sh` | 1/1/1 |

## Litmus tests

- **The usage text must survive.** Criterion 2 requires `--check` still be documented as a manual
  drift check. A fix that deletes the flag's documentation along with the false claim fails.
- **`utils/py/marathon_plan.py` must not grow the claim.** Criterion 1 covers both files; moving the
  false statement to the authoritative twin would satisfy a careless reading and be strictly worse.
- **No negative control is required here, and that is a deliberate call.** #419 scopes its contract
  to *decision gates*, and this lane deletes a comment — it adds no check and changes no verdict.
  Demanding one would be the boilerplate #419's non-goals explicitly reject.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "grep_present", "path": "utils/marathon-plan.sh", "pattern": "drift guard in validate" }
  ],
  "artifacts":     [ "utils/marathon-plan.sh" ],
  "artifacts_new": [],
  "remediation":   { "source": "issue#368", "criteria": "Option B only — delete the false claim that --check runs in validate.sh. Ranking summary only, NOT the definition of done (that is the verbatim ## Acceptance block above, minus the declared deviation)" },
  "lanes":         { "agy_safe": [], "orchestrator_only": [] }
}
```

**Probe polarity** (probes detect the **bug**, not the fix): `grep_present` reports `landed` when the
pattern is **no longer found**. The single probe is the false claim itself — present today, and it
flips to `landed` exactly when the line is deleted. One probe is the right number here; a second
would be padding on a one-line change.

**This contract names a GH-308 frozen file as its write target.** That is intentional and is the
whole of the #418 collision above. It is stated in the contract rather than left for preflight to
discover, because today preflight cannot discover it — which is #418's entire point.

## Method note

Both halves of the defect were re-verified on 2026-08-05 against `development` @ `2c95a56`: the
comment is present at `:67`, `validate.sh` contains zero matching invocations, and
`utils/py/marathon_plan.py` does not carry the claim. The FROZEN banner on `utils/marathon-plan.sh`
was verified in the same pass.
