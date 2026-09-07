# Recon Map — ROADMAP-DASHBOARD.md: NOT removed. Its guard's signal was repaired instead.

Commit: `2e4f8d48` · Mode: grep-only · Lanes: A–D (serial)

> **This document was rewritten on 2026-09-07 and no longer describes a removal.** The earlier
> version mapped removing `ROADMAP-DASHBOARD.md` and its machinery. That plan was adjudicated,
> escalated to untracking (Option C), reviewed, and then **rejected on evidence**. What shipped is a
> much smaller repair to the guard's input signal. The removal analysis is preserved in git history
> and in `relay-system/2026-09-07/gh474-md-views-101147/`; it is not the plan of record.

## Subject and change class

Subject: `githooks/dashboard-staleness-guard.sh` — specifically the decision path that answers
*"did the renderer silently drop a roadmap row?"*.

Change class: **local edit, one file.** Not a subsystem removal. `ROADMAP-DASHBOARD.md`,
`utils/roadmap-dashboard.sh` and `utils/leaderboard.sh` all stay exactly as they are, tracked and
committed.

## Why the removal plan was rejected

The removal (and its softer sibling, untracking) rested on the claim that every route to the
dashboard already offers `releases roadmap list` as an equal alternative, making the committed file
redundant. That claim is false, and two independent checks falsified it:

1. **`AGENTS.md:139-143` and `GUIDING-PRINCIPLES.md:77`** name the dashboard with *no* CLI
   alternative in the sentence. So the file is a live route, not a mirror.
2. **`utils/py/router_audit.py` is a hard gate** (via `test/gh353-vendored-router-audit.sh`) that
   requires `ROUTER.md` to affirmatively declare `ROADMAP-DASHBOARD.md` as the generated view and to
   route startup to it. Untracking the file means rewriting that auditor — a gate change to
   accommodate a convenience change, which is the wrong direction of travel.

Beyond those two, the removal missed live consumers in `utils/releases-merge-resolve.sh:160,178`,
`utils/py/wave_reconcile.py:728,798`, `utils/py/jog_run.py:245,285` and `utils/py/express.py:77,206`.
The rollback it advertised as cheap was therefore not cheap.

**The requirement was also mis-stated.** The real complaint (#474) was never "this file exists". It
was "the guard produces false refusals." Those are separable, and only the second one is a defect.

## The actual change

The guard asked the right question and threw away the answer.

| Line | What happens |
| --- | --- |
| `utils/roadmap-dashboard.sh:89` | the node render runs — **unconditionally, in both modes** |
| `utils/roadmap-dashboard.sh:200-203` | every unparseable line is pushed onto `droppedRows` |
| `utils/roadmap-dashboard.sh:217-220` | `roadmap-dashboard: warning: dropped N unparseable row(s): <ids>` → **stderr** |
| `utils/roadmap-dashboard.sh:251` | *only now* does the `MODE == "check"` branch compare and exit |

So `--check` already reports dropped rows by id. The guard discarded that with `>/dev/null 2>&1`
and inferred the same fact from table names in the `releases.sql` diff — a hand-maintained allowlist
that went short twice and left eight dump tables unclassified.

The fix keeps the renderer's stderr (`2>&1 >/dev/null`, order significant), refuses on the warning
while quoting it, and deletes the classifier. `utils/roadmap-dashboard.sh` is unchanged.

## The seams

| Seam | Location | Crosses | Breaks if |
| --- | --- | --- | --- |
| `--check` exit contract | `utils/roadmap-dashboard.sh:251-263` | 5 consumers | a new exit code is introduced — **avoided; the signal travels on stderr** |
| stderr capture | `githooks/dashboard-staleness-guard.sh:123` | guard ↔ renderer | stderr is redirected away again |
| table classifier | `githooks/dashboard-staleness-guard.sh:147-178` | guard ↔ ledger schema | deleted; nothing else read it |
| guard invocation | `githooks/pre-push:88-93` | every push in every clone with the hook | the guard's exit semantics change (they do not — still 0/1) |

## Contracts — the five consumers of `--check`

This is why the exit contract must not change. Every one treats non-zero as failure:

| Consumer | Line |
| --- | --- |
| the guard | `githooks/dashboard-staleness-guard.sh:123` |
| `test/gh269-roadmap-retired.sh` | `:26` |
| `test/gh280-jog-marathon-adapter.sh` | `:1021`, `:1033` |
| `test/gh57-live-merge-resolve.sh` | `:290` |
| `test/roadmap-dashboard.sh` | `:49-55` |

Introducing exit `2` for "rows dropped" would newly fail the four test consumers the first time a
fixture carried a malformed row. Reading stderr leaves all five untouched.

## Effect

- **Before:** any ledger write touching an unclassified table (`doc_lines`,
  `grandfather_entries`, `legacy_lines`, `manifest_items`, `manifest_state_events`, `releases`,
  `repos`, `schema_migrations`) hit the catch-all and produced a **false** "a parked row was
  dropped" refusal. `releases add` alone tripped it.
- **After:** the guard refuses only when the renderer actually reports a dropped row, and names it
  in the refusal so the operator knows which row to fix.
- Rollback: revert one commit. No data, no schema, no generated artifact.

## Unknowns — resolved

| Unknown | Resolution |
| --- | --- |
| Does the warning survive `git archive` into the guard's `TMP_PROJ` projection? | **Yes, proven.** `test/gh257-roadmap-ledger-fixes.sh` case 11 drives the *real* renderer through the projection with an injected malformed row and now asserts the refusal names `#256`. With the classifier deleted, that assertion can only pass via the stderr signal. |

## Current-state radius, one line

Every developer and agent pushing to this repo with the hook installed, via `githooks/pre-push`; no
data, no published artifact, and no other repo — the guard is per-clone and writes nothing.
