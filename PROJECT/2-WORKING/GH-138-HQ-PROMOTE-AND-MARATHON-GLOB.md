---
gh_issue: 138
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/138
title: "HQ hardening: add `promote` command + fix marathon-plan detection glob (MARATHON-*.md)"
status: In progress — glob fix + promote command being implemented in the same session they were found (2026-07-05 HQ dogfood)
created: 2026-07-05
updated: 2026-07-05
owner: noel
doc_type: enhancement
goal: >
  Close two small HQ gaps surfaced dogfooding /hq for cross-repo intake (rebalance-OS#113):
  (1) add `hq promote --gh-issue N <project>` for PDDA's 1-INBOX→2-WORKING transition — the one
  lifecycle verb HQ lacked — as a preview-by-default mechanical scaffolder that produces a
  checker-valid 2-WORKING doc; (2) broaden hq-lib.sh's marathon-plan detector from the hardcoded
  MARATHON-PLAN-*.md to MARATHON-*.md so `hq queue`/`hq status` see a target repo's plan regardless
  of its local naming sub-convention (the bug that currently blocks queuing onto rebalance-OS).
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: false
non_goals:
  - No auto-rating — promote scaffolds the mechanical fields (updated, goal, status-table stub) and leaves cx/risk/eff + real Status + QA gates to the operator, exactly as park/queue already defer rating
  - Not changing park/queue/fire behavior beyond the shared marathon-glob fix
  - Not authoring a finished plan body on promote — it moves + scaffolds + loudly flags what the operator must complete
related:
  - utils/hq/hq.sh
  - utils/hq/hq-lib.sh
  - test/hq-promote.sh
  - PROJECT/PDDA.md
---

## Status

| What was just completed | What's next |
|---|---|
| **2026-07-05 — captured + scoped.** Filed [#138](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/138) from an HQ dogfood: parked rebalance-OS#113 via `/hq park` (dedupe verified), then found `hq queue` can't see rebalance-OS's `MARATHON-2026-07-04.md` because [hq-lib.sh:286](utils/hq/hq-lib.sh) globs `MARATHON-PLAN-*.md`. Confirmed the minimum enforced 2-WORKING contract (`title status created updated owner goal` + a `## Status` table with exact header + non-blank cells) so `promote` can emit a checker-valid doc. | Implement the 1-line glob broadening (`MARATHON-PLAN-*.md`→`MARATHON-*.md`); add `cmd_promote` + `hq_render_promote_frontmatter` in hq.sh/hq-lib.sh (preview-by-default, `--create` acts, refuses if no `GH-N-*.md` in 1-INBOX); add hermetic `test/hq-promote.sh` (+ a `MARATHON-<date>.md` detection regression) wired into `validate.sh`; then unblock and run `hq queue --gh-issue 113 rebalanceOS` to append #113 as a rebalance-OS marathon lane. `shellcheck` + `pdda.sh run` green before commit. |

## QA gates (Phase 1)

- [ ] **DRY:** `cmd_promote` reuses `hq_resolve` / `val` / tier helpers and mirrors `cmd_park`/`cmd_queue` structure; no copy-pasted resolution ladder.
- [ ] **SOLID / seam:** resolution + rendering stays in `hq-lib.sh`; `hq.sh` only dispatches. The marathon glob lives in exactly one place (fix once, both `status` + `queue` benefit).
- [ ] **Observability:** promote announces the exact `git mv` and frontmatter rewrite it will do; preview prints the full would-be doc; `--create` echoes the resulting path.
- [ ] **Litmus (contract):** the promoted doc passes `utils/pdda/pdda.sh frontmatter` + `utils/pdda/pdda.sh status-table` in isolation.
- [ ] **Litmus (regression):** `test/hq-promote.sh` proves a `MARATHON-<date>.md` (no `-PLAN-`) fixture is now detected; both new-command and glob cases hermetic (tmp fixture repo, no network).
- [ ] **No silent scope:** promote refuses (non-zero) when no matching 1-INBOX doc exists rather than creating an empty 2-WORKING file.
