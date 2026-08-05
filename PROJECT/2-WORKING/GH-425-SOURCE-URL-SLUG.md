---
gh_issue: 425
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/425
title: "GH-425 — check_source_url compares the issue number but ignores the repo slug"
status: "Intake (2-WORKING) — captured 2026-08-05 for release 0.2.0 Litmus. BLOCKED ON A DESIGN CALL: option 1 vs 2 must be chosen before this fires. Not preflight-ready by design."
created: 2026-08-05
updated: 2026-08-05
owner: noel
doc_type: project
release: "0.2.0 Litmus"
complexity: 2
risk: 2
effort: 2
phases: 2
ratings_provisional: true
blocked_on: "Operator decision between option 1 (source: always cites the tracking issue) and option 2 (a separate origin:/upstream_issue: field). Option 3 is rejected on its face."
related:
  - "#419 — the class, in its false-negative half: a check that reports verified provenance without having checked the field that determines it."
  - "#400 / PR #420 — built the gate this fixes."
  - "#422 — its remediation, and where this was found. Its refusal-to-guess on a conflicting doc stays exactly as it is."
  - "#412 — the shape of the risk here: a lane whose definition of done depends on a decision nobody has made."
non_goals:
  - "Softening the gate. The fix tightens it; the false negative is the priority."
  - "Auto-rewriting a doc whose source: names a foreign repo. The backfill's refusal-to-guess (#422) stays exactly as it is."
  - "Changing gh_issue semantics. It remains the tracking issue in the doc's own repo."
  - "Touching the frozen Bash twins (GH-308). Python only."
goal: >
  `check_source_url` extracts the `owner/repo` slug, stores it in the result, and then never looks at
  it. That single omission produces a false positive and a false negative at once: legitimate
  cross-repo provenance is refused, and an unrelated repository's same-numbered issue is accepted as
  verified. The slug must stop being computed and discarded.
---

# GH-425 · the slug is right there in the result, and nothing consults it

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-05 as a lane of release 0.2.0 Litmus. Preflight contract authored; acceptance reads `match — 6/6 criteria copied verbatim from issue #425`. | **An operator design call between option 1 and option 2 — not a build.** Nothing fires until that is settled. Then Phase 1 (blast radius across the harness and every vendoring repo) and Phase 2 (the slug check). |

Captured 2026-08-05 as a lane of release **0.2.0 Litmus**.

**⚠ This lane is NOT fireable yet.** The issue offers three design options and explicitly says *"this
needs a call."* Firing it without that decision hands a builder a definition of done it must invent
— which is the #400 defect, and the reason the doc says so here rather than picking quietly.

## The defect

| Doc | Gate verdict | Correct verdict |
|---|---|---|
| `gh_issue: 94` + `source: .../nexmail-ltvera-connector/issues/2` | **`mismatch` → NOT-READY** | legitimate cross-repo provenance |
| `gh_issue: 94` + `source: .../SomeoneElse/unrelated-repo/issues/94` | **`ok` → READY** | wrong repository entirely |

Verified against `development` @ `faf50e0`:

```
status=ok  slug_recorded=SomeoneElse/unrelated-repo
detail=source: resolves to issue #94 (https://github.com/SomeoneElse/unrelated-repo/issues/94)
```

## Which half is worse

**The false negative.** A doc citing an unrelated repository reads READY, and the packet then tells
the builder its acceptance was *"Verified against issue #94"* while pointing at someone else's #94.
A green verdict on provenance the gate never checked — the #419 class, inside the very gate built to
enforce provenance.

The false positive fails loudly and costs an operator one decision. The false negative is silent and
reads as success.

## How it surfaced

Dogfooding #422's backfill against `LTVera-Pandas`, whose
`PROJECT/2-WORKING/v1.3.5/GH-94-NEXMAIL-CONTRACT-GAP-ANALYSIS.md` carries `gh_issue: 94` and
`source: https://github.com/BinoidCBD/nexmail-ltvera-connector/issues/2`. That is **not a typo** —
the doc is tracked by `LTVera-Pandas` #94 and originates from a different repo's issue #2. The
backfill correctly refused to rewrite it; the gate hard-fails it; and the model has no way to
express *"tracked here, originated there."*

## Acceptance

*Copied verbatim from [issue #425](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/425)
(`## Acceptance`), fetched 2026-08-05. Deviations, if any, are recorded below this block.*

- [ ] The gate validates the repository slug as well as the issue number: a `source:` naming a different repository is not accepted merely because the number happens to match.
- [ ] A capture doc that is tracked by this repo's issue but originated in another repo has a documented, machine-checkable way to record both facts, and satisfying the gate never requires deleting the cross-repo reference.
- [ ] The `slug` value the check already computes is either acted on or removed — a field that is computed, stored, and ignored is precisely how this survived review.
- [ ] The remediation message distinguishes "wrong repository" from "wrong issue number", so the operator knows which field to correct.
- [ ] A regression test pins **both** directions: a same-number-but-foreign-repo URL is refused, and the documented cross-repo shape is accepted. Its negative control is observed and recorded, per #419.
- [ ] Blast radius is measured across the harness **and** every vendoring repo before the posture is chosen, per the lesson recorded in #422.

## Acceptance — deviations from the issue

None. Every criterion is carried verbatim.

Criterion 2 — *"a documented, machine-checkable way to record both facts"* — is the criterion the
design call below decides the shape of. It is **not** a deviation: the criterion is satisfiable by
either option, and the issue deliberately left the mechanism open.

## The design call this lane is blocked on

From the issue, unchanged:

1. **`source:` always cites the tracking issue** — the one in `gh_issue` — and cross-repo origins
   live in `related:`. Simplest, keeps the check deterministic; costs a dedicated field for origin.
2. **A separate field** (`origin:` / `upstream_issue:`) carries cross-repo provenance while `source:`
   stays strictly the tracking issue. More expressive, one more field to document and lint.
3. **Teach the gate to accept a foreign slug** when a marker says the reference is deliberate.
   **Rejected on its face** unless the marker is machine-checkable — otherwise it is an escape hatch
   that turns the gate back into a suggestion.

**Recommendation: option 1.** It needs no new field, no new lint, and no migration; `related:`
already exists and already carries cross-repo context in every capture doc in this tree. Option 2's
extra expressiveness buys one thing option 1 cannot do — distinguishing "no origin" from "origin is
this same repo" — and nothing downstream consumes that distinction today.

**The operator makes this call, not the builder.** Recorded here so the choice is visible before the
lane fires rather than discovered in a diff afterwards.

## Phases

| Phase | Deliverable | Artifacts | cx/risk/eff |
|---|---|---|---|
| 1 | Blast radius, then the posture. Measure the harness **and** every vendoring repo before choosing — the lesson #422 recorded after its own measurement was under-measured by a non-recursive glob. Record the count per repo. | (measurement only; recorded in this doc) | 1/1/1 |
| 2 | The slug check. Validate the slug alongside the number, act on the value already computed, and distinguish "wrong repository" from "wrong issue number" in the remediation message. Document the chosen convention in `skills/10days/SKILL.md`. Regression pins **both** directions with an observed negative control. | `utils/py/swarm_preflight.py`, `skills/10days/SKILL.md`, `test/gh425-source-url-slug.sh`, `validate.sh` | 2/2/2 |

## Litmus tests

- **Both directions or it does not count.** Criterion 5 is explicit. A suite pinning only the refusal
  reproduces the false positive and leaves the false negative — the worse half — unguarded.
- **The measurement must be recursive.** #422's blast radius was reported as 18 and was actually 34,
  because the script globbed one level. A repeat here would be the same defect in the issue filed
  about it.
- **`slug` must be acted on or deleted.** Criterion 3 forbids leaving it computed-and-ignored, which
  is precisely how this survived review.

## Swarm Preflight Contract

**Authored but deliberately not verified READY** — see Status. Running `swarm-preflight` against
this doc today would report ready, which would be a gate answering a question the lane has not
settled. Recorded for when the design call is made.

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "path_absent", "path": "test/gh425-source-url-slug.sh" },
    { "type": "grep_absent", "path": "utils/py/swarm_preflight.py", "pattern": "slug_match" }
  ],
  "artifacts":     [ "utils/py/swarm_preflight.py", "skills/10days/SKILL.md", "test/gh425-source-url-slug.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh425-source-url-slug.sh" ],
  "remediation":   { "source": "issue#425", "criteria": "validate the repo slug, not just the issue number — ranking summary only, NOT the definition of done (that is the verbatim ## Acceptance block above)" },
  "lanes":         { "agy_safe": [], "orchestrator_only": [] }
}
```

**Probe polarity** (probes detect the **bug**, not the fix): `path_absent` reports `landed` when the
path *exists*; `grep_absent` reports `landed` when the pattern *is found*. Verified 2026-08-05:
`slug_match` occurs **0 times** in `utils/py/swarm_preflight.py`.

## Method note

The two-row verdict table and the `status=ok slug_recorded=...` output are carried from the issue,
recorded against `faf50e0` on 2026-08-04. The `slug_match` probe marker was verified absent on
2026-08-05 against `development` @ `2c95a56`.
