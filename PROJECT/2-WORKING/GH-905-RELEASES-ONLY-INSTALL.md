---
gh_issue: 905
source: https://github.com/HiQS-Labs/XYZ-forge/issues/905
title: "Direct releases DB-only PDDA install"
status: active
created: 2026-10-01
updated: 2026-10-01
owner: XYZ Forge maintainers
doc_type: bugfix
complexity: 3
risk: 3
effort: 3
phases: 1
related:
  - "#908 — serial PDDA adopter Jog"
goal: >
  Support direct releases-mode install, truthful router and docs, and explicit projection control while preserving legacy behavior.
---

# Direct releases DB-only PDDA install

## Status

| What was just completed | What's next |
|---|---|
| Issue #908 ordered this serial Jog; preflight passed on base 57bd97af and implementation is drafted on fix/gh908-pdda-adopter-jog. | Agy and final Codex relay QA approved; full macOS ci-local passed at final post-reconciliation tip 3882935e with clone identity intact. PR #913 is open and its blocking hosted smoke gate passed at 9a32b247. Await operator merge approval. |

## Observed problem

The installer seeds retired MD ledgers, cannot select releases mode, and cannot explicitly disable generated views. Source: [issue #905](https://github.com/HiQS-Labs/XYZ-forge/issues/905).

## Plan

1. Reproduce the reported behavior at the named source path and establish a red control.
2. Make the smallest fix in the existing subsystem. #905 may touch its declared installer, router, releases, and documentation surfaces; keep the same canonical writer.
3. Run the existing covering suite and a manual acceptance matrix in a disposable full clone. Commit provenance for cited evidence. Run final review and qualifying gate before the PR.

## Acceptance

- [ ] Support direct releases-mode install, truthful router and docs, and explicit projection control while preserving legacy behavior.
- [ ] Existing legacy and releases-mode behavior outside this issue still works.
- [ ] No new suite, gate, runner, or telemetry stage (GH-831).

## Rating (2026-10-01)

PRS pri/sev/appeal/effort = 65/50/50/30; appeal neutral. Effort is cheapness. This issue is one observed adopter report; recurrence trend is unknown. The installer failure (#906) blocks core setup, while #905 crosses mode and view contracts. Reassess on new evidence.

## Decision and rollback

The database is the source of truth in releases mode. A DB-only install requires an already vendored Releases CLI and refuses a target with existing Markdown ledgers, because deleting or silently converting them could lose work. The new `projections` setting has `auto` (historical file-presence behavior), `on` (file-presence behavior), and `off` (suppress automatic refresh even when files exist). This is a Costly, cross-module contract change: installer, writer refresh, and post-merge reconcile all consume it. Roll back a disabled projection with `releases settings set projections on`; the previous files remain untouched. A legacy install without these flags keeps its prior seeds and behavior.

A fresh fixture install on 2026-10-01 produced `releases.db`/`releases.sql`, no `ROADMAP.md`/`RELEASES.md`, a router passing `router_audit.py --check`, a clean Releases check, and a `pdda.sh run` with zero errors. The fixture's missing `README.md` and pre-existing `PDDA_SYNC_TMP` doc reference still generated three unrelated warnings.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash ci-local.sh",
  "fix_probes": [
    {
      "type": "grep_absent",
      "path": "utils/pdda/pdda-install.sh",
      "pattern": "--roadmap-source",
      "note": "new supported selector absent on base"
    },
    {
      "type": "path_absent",
      "path": "utils/pdda/templates/ROUTER.releases.target.md",
      "note": "new mode-specific router template absent on base"
    }
  ],
  "artifacts": [
    "utils/pdda/pdda-install.sh",
    "utils/pdda/pdda.sh",
    "utils/pdda/templates/ROUTER.target.md",
    "utils/pdda/templates/ROUTER.releases.target.md",
    "utils/py/releases_app.py",
    "utils/py/wave_reconcile.py",
    "utils/pdda/PDDA-INSTALL.md"
  ],
  "remediation": {
    "source": "issue#905",
    "criteria": "Support direct releases-mode install, truthful router and docs, and explicit projection control while preserving legacy behavior."
  },
  "lanes": {
    "agy_safe": [
      "utils/pdda/pdda-install.sh",
      "utils/pdda/pdda.sh",
      "utils/pdda/templates/ROUTER.target.md",
      "utils/pdda/templates/ROUTER.releases.target.md",
      "utils/py/releases_app.py",
      "utils/py/wave_reconcile.py",
      "utils/pdda/PDDA-INSTALL.md"
    ],
    "orchestrator_only": []
  },
  "artifacts_new": [
    "utils/pdda/templates/ROUTER.releases.target.md"
  ]
}
```
