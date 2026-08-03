---
gh_issue: 400
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/400
title: "GH-400 — /10days capture docs restate a GitHub issue's acceptance criteria instead of copying them; a measured case inverted one and the marathon delivered the inversion"
status: "Shipped 2026-08-03 — all 3 phases. Skill copies verbatim, preflight hard-fails on unexplained drift (Python twin), test/gh400-acceptance-fidelity.sh 20/0 in validate.sh and observed 1/19 against pre-fix code. Blast radius measured at 0 of 33 active docs before choosing the posture."
created: 2026-08-03
updated: 2026-08-03
owner: noel
doc_type: fix
complexity: 3
risk: 3
effort: 3
related:
  - "#399 — companion, second cut in the same chain: preflight drops hard-wrapped continuation lines. Its fix and this one share one extractor."
  - "#344 — /10days find-doc.sh read the wrong repo's PROJECT/ tree; same skill, same class of silent wrong-source."
  - "#351 / #369 / #348 / #342 — the 'assertion that cannot distinguish the bug from the fix' family. Phase 3 must not join it."
  - "#308 — froze the Bash twins. utils/swarm-preflight.sh is frozen; the Python twin is the one that runs."
non_goals:
  - "Fixing #399's hard-wrap truncation at the packet-inlining site. This doc's extractor must be continuation-aware to compare at all, and #399 is one line away from reusing it — but re-pointing line 844 is #399's deliverable, not this one's. Flagged, not absorbed."
  - "Making the packet inline the ISSUE's acceptance instead of the capture doc's. That would fix both issues at once and is tempting, but it changes packet semantics for every doc that has no issue, and it removes the operator's ability to scope a lane deliberately. Out of scope; revisit only if the fidelity gate proves insufficient."
  - "Editing utils/swarm-preflight.sh. Frozen by GH-308; behavior changes go in utils/py/swarm_preflight.py."
  - "Retroactively correcting the rebalance-OS GH-202 test. That repo's issue #202 is still open and stays its owner's call; this issue is about the harness that produced the wrong instruction."
goal: >
  Stop a model-authored summary from silently becoming the contract. The capture doc's acceptance
  block must be a verifiable copy of the issue's, with any deviation stated explicitly, and a
  deterministic check must refuse to emit a packet when the two have diverged without explanation.
---

# GH-400 · the summary became the contract

## Status
| What was just completed | What's next |
|---|---|
| All 3 phases shipped. Skill requires a verbatim copy; `utils/py/swarm_preflight.py` hard-fails NOT-READY on unexplained drift and records `readiness.acceptance_fidelity` on every run; `test/gh400-acceptance-fidelity.sh` **20/0** in `validate.sh`, **1 pass / 19 fail** against pre-fix code. | Operator review, then merge. #399 remains open and is now one line from reuse — its extractor exists here. |

## Verification of the report (done before any build)

Re-derived from the two source repos rather than taken on the report's word:

| Claim | Verdict | Evidence |
|---|---|---|
| `rebalance-OS` issue 202 requires the row be *"never silently dropped"* | **TRUE, verbatim** | `gh issue view 202 --repo Hypercart-Dev-Tools/rebalance-OS` — 4 criteria, quoted exactly |
| Capture doc requires asserting *"the actual current behavior (drop the row…)"* | **TRUE, verbatim** | `PROJECT/2-WORKING/GH-202-CLIO-MALFORMED-ROW-TEST.md:29-35` |
| Written by `/10days` in commit `b941299` | **TRUE** | commit message matches character-for-character |
| The delivered test asserts the drop | **TRUE, and worse than reported** | `3673257f` adds a function literally named `malformed_source_row_is_dropped`, asserting `assert_not_contains "$out" 'truncated row'` |
| Two independent runs produced it | **TRUE** | `3673257f` and `7525d047`, both 2026-07-24 |
| `/10days` Step 4 never instructs a verbatim copy | **TRUE** | `skills/10days/SKILL.md` §4 — the contract template mandates the opposite: `"criteria": "<one-line acceptance criteria>"` |
| Nothing downstream compares doc to issue | **TRUE** | neither preflight twin invokes `gh` at all |

**The inversion is real and the mechanism is unguarded.** Step 4's audit bullet checks that `artifacts`
paths exist and that the contract isn't a copy-paste guess — it says nothing about acceptance fidelity.

### Correction to the issue's own analysis

> *"Preflight already fetches the issue for freshness checks."*

**False.** Neither `utils/py/swarm_preflight.py` nor the frozen `utils/swarm-preflight.sh` invokes `gh`
in any form. Preflight's freshness is `git fetch` + fix-probes, all local-transport. The nearest thing
in the repo is `utils/pdda/pdda-gh-refresh.sh`, which fetches `number,state` only — **never a body**.

This matters for cost, not for validity: suggested fix 3 is not a small addition to an existing fetch,
it introduces the first `gh` body-fetch into the preflight path, and therefore has to carry its own
offline-degradation contract. Phase 2 is sized accordingly.

### A second finding, not in the report

Issue #399 cites `utils/swarm-preflight.sh:882` as "the line." That file is **frozen** (GH-308) and does
not execute by default. The live defect is `utils/py/swarm_preflight.py:844` — the same regex, in the twin
that actually runs. #399's evidence is sound; its line reference points at the historical copy.

## Why a guardrail, not a correction

The capture doc is a model-authored summary that silently becomes a contract the moment preflight inlines
it. Summarisation drops and reframes by nature — acceptable in a reading aid, not in a definition of done.
No downstream role can catch it: builder and reviewer both read the packet, which derives from the doc,
so **no undamaged copy of the requirement exists anywhere in the pipeline**. Every gate was green.

## Acceptance

*Copied verbatim from [issue #400](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/400)
(`## Suggested acceptance criteria`), fetched 2026-08-03. Deviations, if any, are recorded below this block.*

- [ ] A capture doc generated from a GitHub issue reproduces that issue's acceptance criteria verbatim, or records each deviation explicitly with a reason.
- [ ] Every generated capture doc contains the source issue URL.
- [ ] Preflight compares the capture doc's acceptance block to the issue's and fails on unexplained divergence rather than warning.
- [ ] A regression test pins the GH-202 case: an issue requiring "never silently dropped" cannot produce a capture doc asking to assert the drop.

## How criterion 3's "fails rather than warning" is read

No deviation is declared — every criterion is carried verbatim. (This section is deliberately *not*
titled "Acceptance — deviations from the issue": that heading now has a machine meaning, and a
section claiming deviations that do not exist is itself a divergence the checker rejects.) The one
scope reading worth stating:

- **Divergence detected → hard fail (NOT-READY).** Not negotiable; this is the criterion.
- **Divergence *undeterminable*** (no `gh_issue`, `gh` absent, unauthenticated, offline, or the issue has
  no `## Acceptance` section) **→ report `acceptance_verified: unknown` loudly, do not block.** An
  unreachable network is not evidence of drift, and blocking on it would make every offline preflight fail.
  This is GUIDING-PRINCIPLES §8 (honest; never mask, never invent) rather than a softening of the gate.

## What shipped

**Phase 0 — blast radius, measured before choosing the posture.** All 33 `2-WORKING` docs carrying a
`gh_issue` compared against their live issues; **33/33 fetches succeeded**, and **0** would newly read
NOT-READY. 32 of the 33 issues carry no `## Acceptance` section at all, so they report `unknown`. The hard
fail criterion 3 asks for costs nothing today — which is *why* it could be taken literally rather than
softened to a warning.

**Phase 1 — the skill contract** (`skills/10days/SKILL.md` §4). The acceptance block is reproduced
byte-for-byte (re-wrapping to ~80 columns is the only permitted change); `source:` carries the issue URL;
`remediation.criteria` is relabelled a one-line **ranking summary, explicitly not the definition of done**;
and Step 6 tells an unattended run that `exit 5 · acceptance criteria diverge` is its own Step 4 output being
rejected, with the two legitimate remedies and an explicit "do not delete the acceptance section to escape it."

**Phase 2 — the deterministic gate** (`utils/py/swarm_preflight.py`; the Bash twin stays frozen). Fetches the
issue, compares indent-folded criteria, and on unexplained divergence sets NOT-READY → **exit 5, no packet**.
`readiness.acceptance_fidelity` is recorded on **every** run including `unknown`, and the packet's acceptance
heading now tells the builder whether the list was verified or merely inlined — the first time the source of
truth has been represented in that context window at all.

**Phase 3 — the regression test** (`test/gh400-acceptance-fidelity.sh`, in `validate.sh`, hermetic via a
stubbed `gh`). **20/0 post-fix; 1 pass / 19 fail against pre-fix code**, where the GH-202 inversion emitted
`verdict: ready (exit 0)` and wrote a packet — the defect reproduced rather than argued.

## Two things found by building it

**A real false positive, caught by dogfooding.** Running the check against issue #400 itself reported the
doc as diverged: a GitHub body's trailing `---` and italic sign-off were being folded into the final
criterion. Continuation folding is now indent-gated, and case 4 pins it. Had this shipped unmeasured, the
gate's first production act would have been to reject a byte-perfect copy.

**The gate's honest half is cases 2–4, not case 1.** A checker that flags the GH-202 inversion but also
flags a faithful hard-wrapped copy is not a fidelity gate — it is noise, and noise gets switched off. This
repo has five documented instances of an assertion that could not distinguish the bug from the fix (#348,
#342, #351, #362B, #369); the pass-direction cases are what keep this from being the sixth.
