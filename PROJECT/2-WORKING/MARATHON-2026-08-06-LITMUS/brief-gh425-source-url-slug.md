---
title: "Phase brief: GH-425 gh425-source-url-slug (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-08-06
updated: 2026-08-06
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh425-source-url-slug
  phase of MARATHON-2026-08-06-LITMUS — not itself an active-doc capture; the canonical capture doc
  is GH-425-SOURCE-URL-SLUG.md two levels up.
roadmap_exempt: true
---

# Brief — GH-425: act on the repo slug `check_source_url` already computes

## Status

| What was just completed | What's next |
|---|---|
| Contract authored and verified READY. **Design call SETTLED 2026-08-05: option 1** — `source:` always cites the tracking issue, cross-repo origins live in `related:`. | Fire as marathon phase 4 of 4, last, after gh418. |

**Parent doc:** `PROJECT/2-WORKING/GH-425-SOURCE-URL-SLUG.md`
**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/425

## Acceptance

**Read the acceptance criteria from the parent capture doc's `## Acceptance` block**, copied
verbatim from the issue. Do not work from a paraphrase — see GH-400.

**The design question is already answered — do not reopen it.** The issue presents three options
and says "not settled — this needs a call". The call was made on 2026-08-05: **option 1**. `source:`
always cites the tracking issue named in `gh_issue`; cross-repo origins are recorded in `related:`;
the convention is documented in `skills/10days/SKILL.md`. Option 3 (a marker that tells the gate to
accept a foreign slug) was rejected on its face — an escape hatch turns the gate back into a
suggestion.

## The gap (verified against `development` @ `faf50e0`)

`check_source_url` (GH-400 criterion 2, PR #420) compares only the **issue number**. It extracts the
`owner/repo` slug, stores it in the result object, and never looks at it again. One omission,
producing a false positive and a false negative at once:

| Doc | Gate verdict | Correct verdict |
|---|---|---|
| `gh_issue: 94` + `source: .../nexmail-ltvera-connector/issues/2` | **`mismatch` → NOT-READY** | legitimate cross-repo provenance |
| `gh_issue: 94` + `source: .../SomeoneElse/unrelated-repo/issues/94` | **`ok` → READY** | wrong repository entirely |

```
status=ok  slug_recorded=SomeoneElse/unrelated-repo
detail=source: resolves to issue #94 (https://github.com/SomeoneElse/unrelated-repo/issues/94)
```

The slug is right there in the result. Nothing consults it.

## Which half is worse — and therefore what to prioritise

**The false negative.** A doc citing an unrelated repository reads READY, and the packet then tells
the builder its acceptance was *"Verified against issue #94"* while pointing at someone else's #94.
That is a green verdict on provenance the gate never checked — the #419 class, inside the very gate
built to enforce provenance.

The false positive is the visible one: it fails loudly and costs an operator one decision. The false
negative is silent and reads as success. Fix tightens the gate; it does not soften it.

## How it surfaced

Dogfooding #422's backfill against a live consumer. `LTVera-Pandas` has
`PROJECT/2-WORKING/v1.3.5/GH-94-NEXMAIL-CONTRACT-GAP-ANALYSIS.md` with `gh_issue: 94` and a `source:`
pointing at `BinoidCBD/nexmail-ltvera-connector` issue #2. **That is not a typo** — the doc is
tracked by `LTVera-Pandas` #94 and originates from a different repo's issue #2. The backfill
correctly refused to rewrite it (a machine cannot tell which field is wrong), but the gate hard-fails
the doc and the model has no way to express "tracked here, originated there."

## What to build

- Validate the **slug** as well as the number: a `source:` naming a different repository is not
  accepted merely because the number matches.
- Give a doc tracked here but originated elsewhere a **documented, machine-checkable** way to record
  both facts (option 1: `related:`), such that satisfying the gate never requires deleting the
  cross-repo reference.
- The computed `slug` is either **acted on or removed**. A field computed, stored and ignored is
  precisely how this survived review.
- The remediation message must distinguish **"wrong repository"** from **"wrong issue number"**, so
  the operator knows which field to correct.
- A regression test pinning **both** directions — foreign-repo-same-number refused, documented
  cross-repo shape accepted — with its negative control observed and recorded per #419, in the
  inventory phase 1 of this marathon built.

## Blast radius — an explicit acceptance criterion, not a nicety

Measure across the harness **and every vendoring repo** before choosing the posture. This is the
lesson recorded in #422, whose own corrected fleet figure did not reconstruct on re-verification:
`LTVera-Pandas` measured 0 where 14 were claimed, and `sleuth-app` measured 1 where 0 were claimed.
A number that cannot be reproduced from what is observable is not a measurement.

## Scope

`utils/py/swarm_preflight.py` and `skills/10days/SKILL.md` (the convention). Python only — the
frozen Bash twins stay untouched (GH-308). Register `test/gh425-source-url-slug.sh` in `validate.sh`.

Do **not** auto-rewrite a doc whose `source:` names a foreign repo; #422's refusal-to-guess stays
exactly as it is. Do **not** change `gh_issue` semantics — it remains the tracking issue in the
doc's own repo.
