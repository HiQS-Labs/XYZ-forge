# Marathon Phase gh425-source-url-slug
STATUS: Approved
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH425-SOURCE-URL-SLUG-TURN builder=codex reviewer=agy round-cap=7 -->

## Phase Brief

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


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/py/swarm_preflight.py,skills/10days/SKILL.md,test/gh425-source-url-slug.sh,validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick
   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick claim MARATHON-GH425-SOURCE-URL-SLUG-TURN --agent codex --paths "phases/litmus-trustworthy-gates-2026-08-06--gh425-source-url-slug/RELAY.md,utils/py/swarm_preflight.py,skills/10days/SKILL.md,test/gh425-source-url-slug.sh,validate.sh"
   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick ping MARATHON-GH425-SOURCE-URL-SLUG-TURN --agent codex
   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick release MARATHON-GH425-SOURCE-URL-SLUG-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/litmus-trustworthy-gates-2026-08-06--gh425-source-url-slug/RELAY.md and utils/py/swarm_preflight.py,skills/10days/SKILL.md,test/gh425-source-url-slug.sh,validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/swarm_preflight.py,skills/10days/SKILL.md,test/gh425-source-url-slug.sh,validate.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick release MARATHON-GH425-SOURCE-URL-SLUG-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick done MARATHON-GH425-SOURCE-URL-SLUG-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick
   Edit ONLY phases/litmus-trustworthy-gates-2026-08-06--gh425-source-url-slug/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.

### Round 1 · Builder · codex

- Implemented GH-425 in `utils/py/swarm_preflight.py`: `check_source_url` now compares the parsed
  slug with the target repository's origin as well as the issue number. It reports
  `wrong-repository` separately from a same-repository `mismatch`; remediation tells the operator
  to restore the tracking URL and retain the foreign origin under `related:`.
- Documented option 1 in `skills/10days/SKILL.md`: `source:` is always the target repo's tracking
  issue; `related:` is the existing free-text provenance context, deliberately not a new linted
  schema or foreign-slug escape hatch.
- Added and registered `test/gh425-source-url-slug.sh`. Focused verification: **6 pass / 0 fail**:
  foreign-repo/same-number refusal, no packet on refusal, correct remediation, accepted
  tracking-URL-plus-foreign-`related:` shape, and separate wrong-number diagnostic. Its disposable
  pre-fix replay removed only the slug branch and observed the historical false READY verdict.
- Blast-radius context was already settled before implementation: the parent record carries the
  recursive GH-422 fleet measurement and its one known `LTVera-Pandas` conflict; this change does
  not rewrite that foreign doc. The local scan found 213 capture-doc `source:` URLs; no `related:`
  values are newly constrained.

### Round 1 · Reviewer · agy

swept file: yes

The changes accurately implement the requirements defined in GH-425.
- `utils/py/swarm_preflight.py`: Added correct URL parsing and matching logic for the repository slug and issue number. Emits correct error classifications (`wrong-repository` and `mismatch`) with clear remediation messages pointing to the use of `related:` for foreign origins.
- `skills/10days/SKILL.md`: Documented the `source:` vs `related:` convention accurately for cross-repo provenance without creating a new linted schema.
- `test/gh425-source-url-slug.sh`: Focused and deterministic. Validates both false-positive and false-negative behavior accurately by spinning up temporary repos in `$TMPDIR`.
- `validate.sh`: Test script is correctly hooked into the gate runner.

I executed `test/gh425-source-url-slug.sh` outside the test tree in an isolated `$TMPDIR` and all assertions passed.

**Verdict:** Approved
relay closed, no further turn needed
