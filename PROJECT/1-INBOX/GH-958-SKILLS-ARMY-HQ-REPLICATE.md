---
gh_issue: 958
source: https://github.com/HiQS-Labs/XYZ-forge/issues/958
title: "skills-army-hq: replicate a collection to a second device, migrate-from name mismatch, and status exit-code semantics"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-03
doc_type: feedback
---

# GH-958: replicate a collection to a second device (returned from XYZ-skills-army-mini#4)

**Provenance.** Opened as #506 on 2026-09-08, transferred to XYZ-skills-army-mini#4 on 2026-10-01
(#882), and transferred back as #958 on 2026-10-03 when #955 restored XYZ-forge as the Skills Army
HQ upstream. The retired #506 capture stays at
[`PROJECT/4-MISC/GH-506-SKILLS-ARMY-HQ-REPLICATE.md`](../4-MISC/GH-506-SKILLS-ARMY-HQ-REPLICATE.md).

## Asks

1. A replicate path between collections: `intake.py init --from <other-collection>` (or
   `export` + `import`) that copies `targets.json` re-homed to the local user, the prerequisites and a
   source manifest, then reports which sources resolve locally and which need `--source` overrides.
2. `--migrate-from SKILL=LOCAL_SOURCE` keys on the deployed link's basename, not the source folder's,
   so `ponytail` → `ponytail-refined` migrates without a manual `rm` + `ln -s` + `--adopt`.
3. Preserved foreign links are reported as warnings, not under `errors` / exit 2, so scripted callers
   can tell "needs review" from "broken".
4. `sync.py --status` reports an interrupted transaction as a JSON error object, not plain text.

## Acceptance

Replicating a collection is `init --from <share>`, review the resolved-sources report,
`sync --apply`, and a `--status` that exits 0 with foreign links listed as warnings.

## Merge evidence

- PR #962 merged 2026-10-04 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
