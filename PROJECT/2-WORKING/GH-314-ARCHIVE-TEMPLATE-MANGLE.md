---
gh_issue: 314
source: https://github.com/HiQS-Labs/XYZ-forge/issues/314
title: "GH-314: wave_reconcile Completed-archive line mangles ROADMAP entries without the 'GH-N · Title' shape"
status: Active
created: 2026-08-29
updated: 2026-08-29
owner: jog
doc_type: bugfix
fix_probes:
  - bash test/wave-reconcile.sh
---
## Status

| What was just completed | What's next |
|---|---|
| Promoted to active working contract via jog | Execute implementation and verify probes |

# GH-314: archive-template mangles separator-less entries

When `wave_reconcile` archives a roadmap entry to `### Completed`, the archive template
assumes the working-set shape `GH-N · Title`. Parked-intake entries have no `·` separator,
so the archived bullet comes out with nested/mismatched bold markers — observed archiving
GH-222 (PR #311, 2026-08-29): the Completed section now holds
`- **GH-222 ** ✅ **SHIPPED 2026-08-28 (PR #311)** — releases update cannot re-point a
release's tracking issue** (2026-08-24) - ...`. Cosmetic but recurring for every entry
archived from `### Queue / parked intake`.

**Fix:** normalize in the archive writer — split on the first `·` separator when present,
else synthesize the title from the remainder of the raw entry — plus a regression
assertion archiving a separator-less fixture entry in `test/wave-reconcile.sh` (its
fixture already archives a `GH-999 · Test Feature` entry; add the separator-less twin).

## Preflight contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_present", "path": "ROADMAP.md", "pattern": "\\*\\*GH-222 \\*\\* ✅" }
  ],
  "artifacts": [ "utils/py/wave_reconcile.py", "test/wave-reconcile.sh" ]
}
```

Probe semantics (documented in PROJECT/3-COMPLETED/GH-280... FINDINGS, GH-222 dogfood
finding 3): `grep_present` = the pattern describes the PRE-fix state; the verdict flips to
`landed` when it is absent. The mangled GH-222 line is present on `development` today, so
the lane starts honestly `unfixed`; when the fix normalizes both the writer and the
existing Completed line, the probe reads landed.

## Acceptance

- `bash test/wave-reconcile.sh` passes with a new regression assertion archiving a
  separator-less fixture entry — the archived line carries no nested/mismatched bold markers.
- The existing mangled GH-222 Completed line in `ROADMAP.md` is normalized
  (no `- **GH-222 ** ✅` shape remains).
- `./validate.sh` green on the lane branch.
