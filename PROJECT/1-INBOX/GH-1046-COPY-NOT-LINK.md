---
gh_issue: 1046
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1046
title: "skills-army-hq: state plainly that Deployed Skills holds copies (not links to the source) and show provenance per skill"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-12
doc_type: feedback
effort: 1
complexity: 1
risk: 1
phases: 1
---

# GH-1046: Deployed Skills holds copies, not links

## Ask

An agent told the operator that the Git Pulse Sync `Deployed Skills` collection links to a source
checkout, so that checkout must stay on `main`. In fact the collection holds physical copies and
only the app roots link to them. Make that obvious without filesystem inspection:

1. the collection stores a physical copy of each skill;
2. which source path and revision each copy came from (from existing receipts);
3. which app roots link to that copy;
4. consequences: the source may be any clean checkout of the merged revision and may be deleted
   after intake; updating needs `intake.py update` from a newer source.

## Acceptance

- `skills/3-weekly/skills-army-hq/SKILL.md` has a short "How deployment works" block near the top.
- `intake.py list` and `sync.py --status` print one human line per skill naming the copy path,
  source @ revision and linking targets; the `add`/`update` preview says it will COPY the source.
- stdout JSON is unchanged; no new tests, state or dependencies (GH-831).

## Recon (base d86f647, 2026-10-12)

- `scripts/intake.py` `source_record()` already writes `source`, `repository`, `commit`, `dirty`
  into each receipt (`state["skills"][name]`); `render_catalog()` already renders
  `source @ commit` and per-enabled-target `linked`/`not linked` into `catalog.md`.
- `intake.py list`, the `add`/`update` preview and `sync.py` (`--status`/preview/apply) print JSON on
  stdout; `test/test_deploy_skills.py` parses that JSON. Human notices (commit result, sync WARN)
  already go to stderr. So new human lines go to stderr and the JSON stays byte-identical.
- `README.md:68` already says the collection is "an actual copy, not a link back to the source
  checkout"; `SKILL.md`, which agents load, only says it implicitly ("Keep actual skill folders",
  "stable copies") inside a dense opening paragraph.
- Gate route: `utils/ci-route.sh` maps `skills/*/skills-army-hq/*` to the `skills-army-hq`
  subsystem (`skills-army-hq.sh` -> `test_deploy_skills.py`, `gh620-skills-army-mini-sync.sh`, ...).

## Plan

**Outcome sought:** an agent can answer "is this a copy or a link, from where, linked by whom, and
can I delete the source?" from `SKILL.md` or one command's output. **Smallest bet:** one SKILL.md
block plus stderr lines built from existing receipt data. **Not built:** new receipt fields, new
JSON keys, new flags, catalog format changes, tests (GH-831). **Alternative rejected:** a JSON
field (`"kind": "copy"`) — machine consumers don't need it, and it would change the stdout contract
for no reader. **Rollback:** revert the single commit (Easy).

1. `SKILL.md`: insert `## How deployment works` right after the H1 — 4 bullets: copy then link;
   provenance in receipts (`list`, `sync.py --status`, `catalog.md`); source is disposable (any
   clean checkout of the merged revision, need not stay on `main`, deletable after intake); updates
   are explicit (`intake.py update NAME --source <newer checkout>`, then sync; a deleted recorded
   source needs `--source`). -> expect diff confined to that block.
2. `intake.py`: add `linked_targets(root, name, config)` (enabled target ids whose entry is a
   symlink to `root/name`) and `copy_line(root, name, receipt, config)` ->
   `<name>: copy at <root/name> (from <source> @ <commit12>[, dirty]); linked from: <ids|none>`.
   `render_catalog()` reuses `linked_targets` (output unchanged).
3. `intake.py list`: after the JSON, print to stderr a one-line explainer plus `copy_line` per
   skill. -> expect stdout JSON unchanged.
4. `intake.py add|update` preview (not apply): stderr line
   `will COPY <source> @ <commit12> into <root/name>; apps link to that copy, not to the source`.
5. `sync.py --status`: after the JSON, the same stderr explainer + `copy_line` per skill
   (reusing `shared.copy_line`).
6. Verify: `bash test/skills-army-hq.sh` (focused; existing pytest parses stdout JSON so it would
   go red if stdout changed); manual check in a temp collection showing the new lines, recorded under
   `TESTS-RESULTS/2026-10-12+GH-1046/` with `provenance.jsonl`; red control: temporarily print a
   line to stdout in `list`/`--status` and watch the existing suite fail, then revert. Final gate per
   `utils/ci-route.sh` (skills-army-hq subsystem) once on the final commit, in a disposable clone.

## Rating rationale (2026-10-12)

`rated 55/40/50/85` — pri 55: operator-requested, one observed misdirection today, no deadline;
sev 40: wrong advice risks needless pinning of a checkout or confusion about deleting it, no data
loss (the copy model is the safe side); appeal 50: neutral default; effort 85: one doc block and
stderr lines from existing data. Recurrence (2026-09-28..10-12 vs prior 14 days): 1 incident (this
report); related-but-distinct #959 (link-drift reporting) and #934 (closed unmerged); trend unknown.
No operator `ovr`.
