# PARKED — observations outside the current task

`PARKED/` at the repository root is the visible holding area for findings an AI agent notices
while doing other work. Record the observation here without expanding the current task. A parked
note is **not** an admitted task, GitHub issue, PDDA capture, or RELEASES roadmap row. Those come
after triage. A blocker to the current task stays in its active issue/plan and cannot be hidden here.

## Record and promote

1. Check existing `PARKED/*.md`, issues, and PDDA docs for the same finding. Add a short item to a
   dated `PARKED/YYYY-MM-DD-<scope>.md` file (or an existing file for this session) with the finding,
   evidence/source, why it is outside scope, and the next check or decision. Keep private device
   details out of tracked notes. No GitHub issue or ledger write is required just to park it.
2. During triage, decide whether to drop, keep parked, or **promote** it. Promotion starts the normal
   issue-first route: create or reuse the issue, write its `PROJECT/1-INBOX/GH-*.md` capture with the
   existing writer, and add/read back the RELEASES roadmap row. Move to `2-WORKING` only when active
   under PDDA. Mark the PARKED item `Promoted: <issue/doc link>` so it remains a pointer, not a
   second plan or queue.
3. An item already promoted before this convention was clarified stays in its issue/PDDA/ledger
   home. Link it from PARKED for visibility; do not create another issue or move its canonical doc
   backward.

The RELEASES section named “Queue / parked intake” is **formal issue intake**, downstream of this
folder. The shared word “parked” does not make the two stores interchangeable.

## Standup's machine records

`/standup` also writes records under `PARKED/`. Its `- [key] tier ... — check: {...} — close: ...`
lines have a separate machine contract: `check` is read-only, `close` is never executed by standup,
and unchanged fingerprints suppress repeats. General agent notes may use ordinary Markdown,
including checklists; standup only parses records carrying its `— check:` field. See
`skills/1-hourly/standup/SKILL.md` and `test/gh77-standup-triage.sh`.

## Parked 2026-08-25 — release/ledger session

- #141 Fuzz/ATE arc (calc 285) has no release home — decide a home or cut it.
- Cargo re-scope 2026-08-25 cut #201, #182, #193, #223 from 0.9.0; each still needs a release home.
- marathon_plan.py:126 reads frozen ROADMAP.md, not releases.db — planner cannot see DB ratings.
- #215 vendored .xyz/ reconciler path defect arguably belongs in Cargo once it has a contract.
