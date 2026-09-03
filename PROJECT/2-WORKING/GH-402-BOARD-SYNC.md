---
gh_issue: 402
source: https://github.com/HiQS-Labs/XYZ-forge/issues/402
title: "Board sync: auto-add issues to the Projects board when any agent starts work"
status: Active (2-WORKING — plan v5 ratified in-issue 2026-09-03, execution started)
created: 2026-09-02
updated: 2026-09-03
owner: noelsaw1
doc_type: plan
effort: 2
complexity: 2
risk: 2
phases: 4
rating: "pri/sev/appeal/effort 70/55/80/40 · calc 245"
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/58
fix_probes:
  - test -f utils/py/board_sync.py
  - test -f test/gh402-board-sync.sh
goal: >
  Execute #402's plan (issue body, revision v5 — the plan of record; this doc tracks execution
  only). This lane covers Phase 0 (token-kind mutation spike against the real board) and
  Phase 1 (utils/py/board_sync.py: scan/reconcile/touch, --dry-run default, device_config
  settings loading, kill-switch, witnessed-red suite). Phases 2 (adapters) and 3 (enrichments)
  follow in later lanes.
---

# GH-402: board sync — execution record

**Plan of record:** the live issue body at
https://github.com/HiQS-Labs/XYZ-forge/issues/402 (revision v5, QA'd by Qwen 3.8 Max relay
2026-09-02 — 10 findings accepted and folded). Do not duplicate the plan here; this doc records
what ran, what proved, and what's next.

## Phase status

- [x] Plan ratified + QA'd (issue body v5; relay `2026-09-02/gh402-board-sync-plan-qa.md`)
- [x] Phase 0 — token-kind spike: **GREEN 2026-09-02.** The gh CLI's stored OAuth token CAN
      mutate this user project: `addProjectV2ItemById` (issue #365, closed, sacrificial) →
      `updateProjectV2ItemFieldValue` Status="In progress" (read back verified) →
      `deleteProjectV2Item` (board restored). Consequence: v1 needs **no PAT** — `gh api graphql`
      is the auth layer; `token_file` stays a reserved setting for a PAT fallback.
- [x] Phase 1 — `utils/py/board_sync.py` + `test/gh402-board-sync.sh`, registered in
      `validate.sh` TESTS. Suite **18/0** (extraction ×6, S2 strength classification ×2,
      negatives ×4, empty-input refusal, kill-switch, env tier ×2, witnessed-red ×2).
      Argparse pitfall caught pre-commit: `parents=` makes flag-before-subcommand silently
      no-op → flags live on subparsers only, so that spelling is a loud usage error.
- [ ] Phase 2 — adapters (pdda wiring, git hook stubs, harness fires, sweeper) — later lane
- [ ] Phase 3 — enrichments (In review/Done, backfill with staleness filter) — later lane

## Verification log

(appended per phase as runs complete — no claim without a receipt)

| Date | What | Result |
| --- | --- | --- |
| 2026-09-02 | Fresh clone `XYZ-forge-gh402` @ `9c7bd379`, gate wired, branch `feat/gh402-board-sync` | clean |
| 2026-09-02 | Phase 0 spike: gh-token mutation round-trip (add #365 → Status read-back → delete) | GREEN — v1 needs no PAT |
| 2026-09-02 | `bash test/gh402-board-sync.sh` (after 2 red iterations: containment misapply, `--root` placement, env coercion, clone-dir fixture leak, argparse `parents=`) | **18/0** |
| 2026-09-02 | `board_sync.py scan` on this clone | strong: 2-WORKING docs; weak: 🚧 markers + cross-repo `rebalanceOS-gh144` clone (correctly unwritable) |
| 2026-09-02 | `board_sync.py touch gh-402 --write` — **first live write** | `gh-402: added + Status='In progress'` — on the board now |
