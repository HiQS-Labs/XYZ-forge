---
title: manifest ship is terminal with no retraction verb, and re-dialing doubles the row
status: Active
created: 2026-08-31
updated: 2026-08-31
owner: Noel Saw
gh_issue: 351
source: https://github.com/HiQS-Labs/XYZ-forge/issues/351
doc_type: bugfix
complexity: 2
risk: 3
effort: 2
phases: 1
ratings_provisional: false
reported_from: ltvera
non_goals:
  - Making `cut` reversible — cut is a deliberate scope decision and its terminality is correct
  - Direct-SQL repair tooling for releases.db; AGENTS.md rules that out on purpose
  - Migration 007 (`updated_at` across all tables) — a real fix for #322 finding 7, but a separate
    scope touching ~144 write sites; parked, see PARKED/PARKED.md
related:
  - PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md — same defect class, shipped in PR #350
  - BinoidCBD/LTVera-Pandas#322 — the ranking audit that surfaced this; failure mode 4, "unanchored"
goal: >
  A manifest row shipped in error can be retracted through a CLI verb that writes an auditable
  manifest_state_events row, so the ledger is corrected without hand-editing releases.db. The
  contradictory state — one issue simultaneously shipped and dialed_in in the same release — is
  unreachable.
---

# GH-351 — `manifest unship`, the retraction verb

## Status

| What was just completed | What's next |
|---|---|
| `manifest unship` ported onto `development` from PR #352 (GH-351 scope only), registered in `validate.sh`, suite `test/gh351-manifest-unship.sh` 13/0, full gate green | Merge; then close #352 as superseded by #350 + this |

## Symptom

`manifest ship` was terminal. No verb retracted it, so a row claiming work shipped that never
shipped stayed in the manifest permanently. The refusal on `cut` pointed at re-dialing as the way
forward — and re-dialing retracts nothing, it adds a **second** row beside the false one, leaving
the manifest asserting that one issue both shipped and is pending in the same release. Two rows
disagree with no marker saying which is the lie: BinoidCBD/LTVera-Pandas#322's failure mode 4
(*unanchored*) reproduced inside one table.

Reproduced against `d2fb87ba` before the fix:

```text
$ manifest cut …                 refused: rule=transition … shipped and cut are terminal for that row
$ manifest dial-in …             manifest item mfi-…ZQQAKC dialed into rel-… (state=dialed_in)
$ SELECT state, COUNT(*) …       dialed_in|1
                                 shipped|1
```

Not hypothetical: `LTVera-Pandas`'s `releases.db` carried a row claiming its #326 shipped while the
PR was unmerged, and `AGENTS.md:131-137` forbids the hand-edit that was the only remaining option.

## Provenance

The implementation comes from **PR #352**, which bundled it with a competing GH-349 parser. That
GH-349 half was rejected — a cross-model vote (agy `VOTE: A`, codex concurring) and direct
measurement found it re-introduced the blocking duplicate-key regression on this repo's own
`ROADMAP.md`, ingested markdown checkboxes and prose bullets as rows, and **silently wiped
`roadmap_items` on a 0-byte `ROADMAP.md`** because its guard refused only `if content:`. PR #350
shipped GH-349 instead. This branch carries #352's GH-351 work forward on its own, which is the
half that was always sound.

## Phase 1 — The retraction verb

`shipped -> dialed_in` joins `LEGAL_ITEM_TRANSITIONS`, and `cmd_manifest_unship` performs it as a
real state transition with an auditable event rather than a silent `UPDATE` — the retraction lands
in `manifest_state_events` beside the ship it reverses, so the ledger records that the claim was
withdrawn rather than pretending it was never made.

Un-shipping must not manufacture the contradiction it exists to remove. GH-111 dropped
`UNIQUE(release_id, issue_ref_id)`, so a live row can already sit beside the shipped one; retracting
into that would leave two `dialed_in` rows. Both exclusivity cases refuse by name
(`manifest-duplicate`, `dialed-in-elsewhere`), and the suite pins that a refusal leaves **items and
events byte-unchanged**.

`--reason` is mandatory, matching `cut`: a correction with no stated cause is how the ledger loses
the thread.

### Checklist
- [x] Add the `shipped -> dialed_in` edge to `LEGAL_ITEM_TRANSITIONS`
- [x] `cmd_manifest_unship` — mandatory reason, exclusivity refusals, event coupled in one transaction
- [x] `manifest unship` subparser and dispatch
- [x] Port `test/gh351-manifest-unship.sh` (13/0)
- [x] Register in `validate.sh`
- [x] Verify `releases check` stays clean after a retraction

### QA checklist — Phase 1
- [x] The repro is confirmed here, not assumed from the report
- [x] A regression test covers the failure path — a shipped row is retracted, and the contradictory
      double-row state is refused rather than reachable
- [x] The correction writes a `manifest_state_events` row; a silent state change would be the same
      defect wearing a different hat
- [x] The fix reuses the existing transition/event machinery rather than adding a parallel path
- [x] `_has_column` guards the `updated_at` write, so this lands cleanly with or without Migration 007

### Verification

| Suite | Result |
|---|---|
| `test/gh351-manifest-unship.sh` | 13 passed, 0 failed |
| `test/gh306-registry-bidirectional.sh` | 10 passed, 0 failed |
| `test/security-scan.sh` | 35 passed, 0 failed |
| `validate.sh --auto origin/development` | see PR |

### Lessons Learned

The bug and its escape hatch were written by the same hand: `cut`'s refusal message named re-dialing
as the path forward, and re-dialing made the ledger worse. A refusal that points somewhere should be
tested against where it points — the message was accurate about `cut` and wrong about the remedy,
and nothing checked the second half.
