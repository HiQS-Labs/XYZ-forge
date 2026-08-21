# Relay: GH-108 rating-system plan — sharpen & QA
STATUS: Open

## Task

Review `PROJECT/2-WORKING/GH-108-RATING-SYSTEM.md` — the implementation plan for the
pri/sev/appeal/effort task rating system.

**Definition of Done for this review:** the plan is internally consistent, its FROZEN operator
decisions are correctly separated from revisable implementation choices, the touchpoint map matches
the repo's real code paths (roadmap sync parser in `utils/py/releases_app.py`, exporter
`utils/timeline/export_timeline.py`, viewer `utils/timeline/RELEASES.html`, suite
`test/gh32-releases-app.sh`), the schema-migration plan is sound for the GID-keyed dump + merge
resolver, and the three "Open items for review" at the doc's end each get an explicit verdict.

**Constraints on findings:**
- FROZEN sections are operator decisions — flag a contradiction WITH them, do not relitigate them.
- This is a REVIEW turn: report findings in this relay file only; do not edit the plan doc.
- Rank findings Blocking / Optional / Out-of-scope. Cite doc lines or repo files for each.

## Protocol

Append `### Round N · Reviewer · codex` with your findings. End with
`**Verdict:** Approved` or `**Verdict:** Changes requested`.

▶ TAKE YOUR TURN (codex)
