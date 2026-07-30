# Major Releases

Forward-looking planning ledger for major releases — one block per release, minimal fields, blank
line between blocks. Marathon plans and other forward planning cross-reference this doc for
target release names/dates; it is not a history of what shipped (that's CHANGELOG.md — lessons
learned belong there at ship time, not duplicated here). Contract lives in PROJECT/PDDA.md ->
"RELEASES.md — release ledger". Add new fields only when a real need shows up.

`Milestone:` is the release -> issue-set join key (GH-284 Phase 3): a GitHub MILESTONE TITLE, not a
URL and not a list of issues. `GH_URL:` can name only one thing, which cannot express a release's
scope. Ask GitHub what is in a release instead of maintaining a list here:

    gh issue list --milestone "Quicksilver" --state open --json number,title,labels

Release: 0.1.0
Status: Draft
Target Date:
Codename: n/a
Description: EXAMPLE — replace this with your first real release, or delete this block once real entries exist below.
GH_URL:
Milestone:
Front-door reviewed:
Shakedown reviewed:
License file:

Release: TBD
Status: Draft
Target Date: 2026-08-01
Codename: Quicksilver
Description: Python-authoritative Tier-A twins
GH_URL: [GH 308](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/308)
Milestone: Quicksilver
Front-door reviewed: Not yet
Shakedown reviewed: Not yet
License file: Not yet