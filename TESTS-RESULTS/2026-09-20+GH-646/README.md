# GH-646 — shared in-progress label writer: 2026-09-20 rebase + reconciler repair evidence

Branch `feat/gh646-writer-refresh` rebased from `ba1f58e8` onto origin/development `41be79e2` (26 commits;
content patch-identical to the pre-rebase tip `c049d8f5` except where development also changed the file —
auto-merged, both edits verified present); GH-646 ledger row replayed through `releases_app`, schema 009
applied with `releases migrate` per RELEASES-DB-FAQS.md. Previously approved writer head: `54b478de`.

## The four red suites and their repair (`c544629f`)
| Suite | On `9a62c4b0` (rebased, unrepaired) | On unmodified `41be79e2` | After repair |
|---|---|---|---|
| `wave-reconcile.sh` | 9/18 fail | 18/18 | **21/21** (3 new declined/unconfirmed assertions) |
| `gh280-jog-marathon-adapter.sh` | L5 doc not promoted | 216/216 | **216/216** |
| `gh496-phase2-reconciliation-views.sh` | exit 6: no such table `repos` | green | **green** |
| `gh527-issue-url-repair.sh` | §3: 5 fails | 17/17 | **17/17** |
| `gh202-wave-reconcile-issue-state.sh` | 39/40 (legacy manifest closer) | — | **40/40** |

Root cause: `_may_terminalize_issue` gated MERGED closers on a confirmed CLOSED issue, contradicting the
GH-202 offline contract (`fetch_issue_state`: None ⇒ promote; live mode dies on a gh failure). Now
`force_promote or CLOSED or (merged and not positively OPEN)`; a declined PR still needs a confirmed CLOSED
issue. Three fixtures now model what the writer verifies (`repos` table; REST `gh api` identity read;
declined PR with unconfirmed state stays in 2-WORKING).

## Red controls (witnessed)
- Only `utils/py/wave_reconcile.py` reverted to `9a62c4b0` (fixtures repaired): **13 pass / 8 fail** — every
  merged-closer promotion red, so the fixture edits do not mask the product change.
- Predicate mutated to pre-GH-646 semantics (`force_promote or not is_open`): **19 pass / 2 fail** — exactly
  the two new declined/unconfirmed assertions.
- `python3 test/gh646_status_label.py --mutant wave_terminal` (`d59c0d86`): **FAILED (failures=3)** — the
  runner reaches its assertions (before the nit fix it raised `TypeError`).

## Review
agy relay `relay-system/2026-09-20/gh646-rebase-repair-qa.md`: **PASS / Approved**, reviewed-head `ef99ac52`
(Codex over its usage limit). Two Nits applied in `d59c0d86` with the focused re-verification above.
Consult transcript for the repair plan: `consult-writer-fix.agy.md` (adjudication recorded in provenance).

`provenance.jsonl`: one row per run with log sha256; the full `validate.sh` receipt row is appended after
the gate runs in a disposable clone on the final head.
