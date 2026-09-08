---
title: "GH-474: the staleness guard reads the renderer's dropped-row warning instead of guessing from table names"
status: Complete
created: 2026-09-07
updated: 2026-09-07
owner: orchestrator (Claude Code)
goal: githooks/dashboard-staleness-guard.sh refuses a push only when the renderer actually reports a dropped roadmap row, and names that row — replacing the table-name allowlist that produced false refusals
gh_issue: 474
source: https://github.com/HiQS-Labs/XYZ-forge/issues/474
branch: fix/gh474-dropped-row-signal
doc_type: bugfix
effort: 1
complexity: 2
risk: 2
related:
  - "#243 — the guard itself; this repairs its input signal"
  - "#315 — the first time the table allowlist went short (jog_queue)"
  - "#257 — the malformed-row fixture that proves the signal end-to-end"
non_goals:
  - Removing, untracking, or gitignoring ROADMAP-DASHBOARD.md or LEADERBOARD.md
  - Changing utils/roadmap-dashboard.sh, including its --check exit contract
  - Retiring githooks/dashboard-staleness-guard.sh
---

# GH-474 — the guard asks the renderer instead of guessing

## Status

| What was just completed | What's next |
|---|---|
| guard reads the renderer's stderr and refuses on the dropped-row warning, naming the row; table classifier deleted; `gh243` rewritten with a real red control; `gh257` case 11 now asserts the row id through the real projection | full gate in a disposable clone, then PR |

## The defect

The guard refuses a push whose range writes the roadmap ledger without moving
`ROADMAP-DASHBOARD.md`. When regenerating produces **no diff**, one hazard remains: a row the
renderer *dropped*. A dropped row renders to nothing, so the committed artifact still matches
byte-for-byte while the ledger row is invisible in the view — drift detection alone cannot see it.

To detect that, the guard classified the `releases.sql` diff **by table name** against a
hand-maintained allowlist. That allowlist went short twice (GH-315 for `jog_queue`, then
`marathons`/`issue_refs`), and eight dump tables were still unclassified — `doc_lines`,
`grandfather_entries`, `legacy_lines`, `manifest_items`, `manifest_state_events`, `releases`,
`repos`, `schema_migrations`. Each was a latent **false refusal**; `releases add` alone tripped it.

## The finding that shrank the fix

The renderer already answers the question directly, and the guard was throwing the answer away.

| `utils/roadmap-dashboard.sh` | What happens |
| --- | --- |
| `:89` | the node render runs — **unconditionally, in both modes** |
| `:200-203` | every unparseable line is pushed onto `droppedRows` |
| `:217-220` | `roadmap-dashboard: warning: dropped N unparseable row(s): <ids>` → **stderr** |
| `:251` | *only now* does the `MODE == "check"` branch compare and exit |

So `--check` already names every dropped row. `dashboard-staleness-guard.sh:123` discarded it with
`>/dev/null 2>&1` and then inferred the same fact from table names.

**This is why the issue's original plan — give `--check` a new exit code — is not needed and not
wanted.** `--check`'s exit contract has five consumers, four of them suites that treat any non-zero
as failure (`test/gh269-roadmap-retired.sh:26`, `test/gh280-jog-marathon-adapter.sh:1021,1033`,
`test/gh57-live-merge-resolve.sh:290`, `test/roadmap-dashboard.sh:49`). Adding exit `2` would newly
fail all four the first time a fixture carried a malformed row. Reading stderr changes none of them.

## The change

One file, `githooks/dashboard-staleness-guard.sh`:

1. Keep the renderer's stderr — `2>&1 >/dev/null`, order significant — in `render_err`. The
   assignment carries the renderer's exit status, so the drift verdict is unchanged.
2. In the no-drift arm, refuse if and only if `render_err` carries the dropped-row warning, and
   **quote the warning in the refusal** so the operator knows which row to fix.
3. Delete the table classifier.

`utils/roadmap-dashboard.sh` is untouched.

## Direction of failure

The old mechanism could go short: a table nobody enumerated fell to the catch-all and produced a
false refusal. The new one cannot, because an unknown table is no longer a question the guard asks —
it reads the renderer's own report. If the renderer is silent, the row rendered.

## Proof

- `test/gh243-dashboard-staleness-guard.sh` — tests 7/7b/8/8b rewritten. **7b is the regression
  fixture**: a write touching `releases`, `repos`, `manifest_items`, `doc_lines`,
  `schema_migrations` and a deliberately invented table, all of which the old allowlist falsely
  refused, now passes. **8 is the red control**: same shape, renderer reports a dropped row →
  refuse, and the refusal must name `#256`. **8b** proves unrelated stderr chatter is not read as a
  dropped row.
- `test/gh257-roadmap-ledger-fixes.sh` case 11 — the **real** renderer, driven through the guard's
  `git archive` projection with an injected malformed row, now asserts the refusal names `#256`.
  This settles the recon's one open unknown (does the warning survive the projection?): with the
  classifier deleted, that assertion can pass only via the stderr signal.

Both suites pass.

## Rollback

Revert one commit. No data, no schema, no generated artifact, no contract change.

## What this issue is no longer

The issue previously carried a plan to remove — then untrack — `ROADMAP-DASHBOARD.md` and
`LEADERBOARD.md`. That was rejected on evidence: `AGENTS.md:139-143` and `GUIDING-PRINCIPLES.md:77`
route to the dashboard with no CLI alternative, and `utils/py/router_audit.py` is a hard gate (via
`test/gh353-vendored-router-audit.sh`) requiring `ROUTER.md` to declare the dashboard as the
generated view. Untracking meant rewriting a gate to accommodate a convenience change. See
[recon-roadmap-dashboard-removal.md](../1-INBOX/recon-roadmap-dashboard-removal.md) and
[recon-leaderboard-removal.md](../1-INBOX/recon-leaderboard-removal.md), both rewritten to the plan
of record; transcripts in `relay-system/2026-09-07/`.

The rendered **HTML** views (`LEADERBOARD.html`, `RELEASES-PREVIEW.html`) remain a separate, live
removal on `fix/gh474-retire-rendered-html` — they are pure adoption-by-presence with no guard and
no governance route.

## Architecture

The guard ↔ renderer ↔ ledger loop is now diagrammed in
[ARCHITECTURE.md](../../ARCHITECTURE.md#the-roadmap-view-pipeline-and-its-push-guard), including why
the dropped-row signal travels on stderr rather than as an exit code.
