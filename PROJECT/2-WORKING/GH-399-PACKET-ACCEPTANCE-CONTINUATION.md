---
gh_issue: 399
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/399
title: "GH-399 — the packet's acceptance block kept only each criterion's first line, so every hard-wrapped requirement reached the builder as a half-sentence"
status: "Shipped 2026-08-03 on branch gh-399-packet-acceptance-continuation. Continuations inlined, extraction bounded to ## Acceptance where one exists, cap truncation announced, lossless copy enforced as a blocking check. test/gh399-packet-acceptance-continuation.sh green; observed failing pre-fix."
created: 2026-08-03
updated: 2026-08-03
owner: noel
doc_type: fix
complexity: 2
risk: 2
effort: 2
related:
  - "#400 — companion, first cut in the same chain: the capture doc restates the issue. Shipped 2026-08-03; this reuses its indent-gated continuation logic."
  - "#308 — froze the Bash twins. The issue cites utils/swarm-preflight.sh:882, which does not execute."
non_goals:
  - "Editing utils/swarm-preflight.sh. Frozen by GH-308; the line the issue cites is the historical copy."
  - "Re-flowing or normalizing the criterion text in the packet. The builder should see the source's own wording and wrapping; folding to one line would be a second transformation to trust."
  - "Changing what the reviewer is told to grade against. The reviewer reads the same packet, so fixing the packet fixes both roles at once — no separate reviewer-side change is needed or made."
goal: >
  Make the packet's acceptance block a lossless copy of the capture doc's, and make a lossy one
  impossible to ship silently — the packet is the only statement of the job the builder reads.
---

# GH-399 · the definition of done arrived as half-sentences

## Status
| What was just completed | What's next |
|---|---|
| Continuations inlined (indent-gated), extraction bounded to `## Acceptance` where one exists, 25-item cap now announced, and a lossless-copy check that sets NOT-READY. Regression test pins capture doc → packet → **relay file**. | agy QA via `/relay-xyz`, then PR into `development`. |

## The defect

`utils/py/swarm_preflight.py` matched only lines *beginning* a `- [ ]` bullet. Capture docs are
hard-wrapped at ~80 columns, so every continuation line was discarded — silently, under a heading
that claimed the criteria were "inlined from the capture doc." Measured at **10 of 10 lanes**, 1–4
lines each.

The issue's own GH-201 evidence, now reproduced as a test fixture:

```
- [ ] An explicit `--database` path that does not exist raises a clear error instead
      of silently resolving to the canonical DB.          ← this line never reached the builder
```

What survived reads as an instruction to **preserve** the fallback the issue exists to remove.

**Correction to the issue's line reference.** It cites `utils/swarm-preflight.sh:882`. GH-308
**froze** that twin; it does not execute. The live defect was the same regex in the Python twin.

## Acceptance

*Copied from [issue #399](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/399),
fetched 2026-08-03. Four criteria are verbatim; the fourth is narrowed, and that change is declared
below so the list states what this lane actually delivers rather than what it was asked for.*

- [ ] A multi-line acceptance criterion arrives in the packet with its continuation text intact.
- [ ] Preflight fails, rather than warning, when the inlined acceptance block does not match the source.
- [ ] A regression test pins the full path — capture doc → packet → relay file — asserting the text a builder finally reads is byte-identical to the source, including a deliberately hard-wrapped multi-line criterion.
- [ ] Checkbox extraction is bounded to the `## Acceptance` section when the doc has one, and falls back to the whole document when it does not, with the packet stating which of the two it used.
- [ ] Truncation at the 25-item cap is reported rather than silent.

## Acceptance — deviations from the issue

- [changed] Checkbox extraction is bounded to the `## Acceptance` section. -> Checkbox extraction is bounded to the `## Acceptance` section when the doc has one, and falls back to the whole document when it does not, with the packet stating which of the two it used. — reason: measured while shipping #400, **32 of this repo's 33 active capture docs have no `## Acceptance` section at all** and keep their checkboxes under `## Phase N`. Bounding unconditionally would replace the acceptance block of essentially every lane with "(no '- [ ]' checklist found)", deleting the builder's definition of done to fix a leak that has never been observed. The issue itself files this as a *"latent risk … not yet observed"*, so the unconditional form trades a real regression for a hypothetical one. The leak it guards against is closed wherever a doc has the section, which is the shape #400 now requires of every issue-derived doc.

## The fix

| Criterion | How it is met |
|---|---|
| continuations intact | `collect_inline_checklist()` folds **indented** follow-on lines and emits each criterion's original source lines unchanged |
| fail, not warn, on a lossy copy | `verify_inlined_acceptance()` re-parses the **rendered** block and sets `ready=0` → NOT-READY / exit 5 if any criterion did not survive |
| full-path regression test | `test/gh399-packet-acceptance-continuation.sh` runs preflight → `packet.md` → `marathon_drive` (stubbed relay-drive) → relay file, asserting byte-identity at each hop |
| bounded extraction | bounded where the section exists; see the declared deviation |
| cap announced | a fired cap appends a blockquote naming how many were withheld and where to read them |

**Indent-gating is load-bearing, not defensive.** An ungated folder swallows a trailing `---` or the
next paragraph into the last criterion. That is not theoretical: it produced a real false positive
while dogfooding #400's checker against issue #400 itself.

**Why the check runs against the rendered block rather than the builder of it.** A comparison against
the data structure that produced the text proves nothing about the text. Re-parsing what will
actually be written catches a future cap, filter or reflow — the class of change that caused this
defect in the first place.
