# Major Releases

Forward-looking planning ledger for major releases — one block per release, minimal fields, blank
line between blocks. Marathon plans and other forward planning cross-reference this doc for
target release names/dates; it is not a history of what shipped (that's CHANGELOG.md — lessons
learned belong there at ship time, not duplicated here). Contract lives in PROJECT/PDDA.md ->
"RELEASES.md — release ledger". Add new fields only when a real need shows up.

## This file is OPTIONAL (GH-381)

**Read this before proposing an edit to it.**

`RELEASES.md` is an *optional planning aid*. It is not a required artifact, it is not a checklist,
and it is **not something to keep topped up**. An empty file, a stale file, or no file at all are
all perfectly valid states. The tooling agrees: `pdda.sh releases` is warn-only, never blocks, and
skips entirely when the file is absent — *"RELEASES.md not found — nothing to check."*

**Do not offer to fill this in, populate it, bring it up to date, or add the release you just
shipped.** Do not treat a sparse file as an incomplete one. If nobody is actively planning a release
arc right now, the correct amount of content here is whatever is already present — including
nothing.

Edit it only when an operator explicitly asks for release *planning*. That is the whole trigger.

## What belongs here, on the occasions it is used

**Major and meaningful releases only. Not every release number.**

A block earns its place by being worth *planning toward* — a named arc with a theme, a target date,
and a milestone. If the only thing you can write in `Description:` is a restatement of what changed,
it belongs in CHANGELOG.md and nowhere else.

`Iterations:` reserves a band of patch numbers for a release. **Reserved, deliberately not
enumerated** — versions inside a band ship freely and are recorded in CHANGELOG.md only. They never
get a block here. The band is what makes "where does 0.2.3 go?" a question with a written answer
instead of one resolved by adding a row.

**A version inside an existing band is already accounted for, so a new block for it is a
duplicate.** That is the admission rule, and it is the only one.

Why this is written down rather than assumed: the failure mode is not a wrong entry, it is a file
that stays correct at every single step while turning into the wrong thing. Add `0.2.1` because it
shipped, add `0.2.2` for symmetry, and this becomes a **de-facto pre-CHANGELOG** — a second,
hand-maintained history that is guaranteed to disagree with the real one the first time someone
updates one and not the other. Two sources of truth for the same fact is the defect; the row count
is only the symptom.

An assistant that keeps asking for this file to be filled produces exactly that outcome, one
helpful suggestion at a time. Hence the section above.

When a band is exhausted, widen it or promote the next release — do not start enumerating.

`Milestone:` is the release -> issue-set join key (GH-284 Phase 3): a GitHub MILESTONE TITLE, not a
URL and not a list of issues. `GH_URL:` can name only one thing, which cannot express a release's
scope. Ask GitHub what is in a release instead of maintaining a list here:

    gh issue list --milestone "Quicksilver" --state open --json number,title,labels

Release: 0.1.0
Iterations: 0.1.0-0.1.4
Status: Shipped
Target Date: 2026-08-01
Codename: Quicksilver
Description: Python-authoritative Tier-A twins
GH_URL: [GH 308](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/308)
Milestone: Quicksilver
Front-door reviewed: Not yet
Shakedown reviewed: Not yet
License file: Yes — AGPL-3.0-only (`LICENSE`) + dual-license option (`LICENSE-COMMERCIAL.md`), adopted 2026-07-29 post-ship