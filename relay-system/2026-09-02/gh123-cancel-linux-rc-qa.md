---
Goal: Adjudicate the 0.7.4 Linux-RC cancellation + re-homing on branch chore/cancel-linux-rc
Date: 2026-09-02
NEXT: agent-b
STATUS: Open
---

# Context

Operator decided on 2026-09-02 that a green **Linux** full test suite drops to priority 2, to be
revisited once XYZ is bug-free on macOS (the platform we ship to). Issue #123 was closed
`NOT_PLANNED` (deferred, not fixed) and the `0.7.4 Linux-RC` release was cancelled.

Branch under review: `chore/cancel-linux-rc`, one commit on top of `origin/development`.
Diff: `LEADERBOARD.html`, `LEADERBOARD.md`, `RELEASES-PREVIEW.html`, `releases.db`, `releases.sql`.

## What was done, and why

`0.7.4 Linux-RC` held **8** dialed-in manifest items, but only **3** were Linux work. Cutting a
release does **not** cascade to its manifest, so a bare `update --status cut` would have left 5
unrelated commitments sitting `dialed_in` against a cancelled release.

So every item was cut explicitly with a per-row reason, and the 5 non-Linux ones were re-dialed
into `0.9.0 Cargo` (`rel-01M0GKP4YGTHVTXHVV5WAP08B5`, target 2026-09-19):

| issue | GH state | disposition |
|---|---|---|
| #123 Linux canary remainder (gh358 lock contention) | closed | cut, **not** re-homed |
| #249 canary red on EUID=0 | closed | cut, **not** re-homed |
| #341 attest Linux as an unprivileged user | open | cut, **not** re-homed |
| #251 validate.sh reports pytest-absent as FAILED | open | cut from 0.7.4 → dialed into 0.9.0 |
| #255 marathon-drive refusal omits XYZ_ARCHIVE_ROOT | open | cut from 0.7.4 → dialed into 0.9.0 |
| #256 no preflight checks builder artifact reachability | open | cut from 0.7.4 → dialed into 0.9.0 |
| #275 medium-level write-ops logging | open | cut from 0.7.4 → dialed into 0.9.0 |
| #345 sleep-vs-readiness audit | open | cut from 0.7.4 → dialed into 0.9.0 |

`0.7.4` status → `cut`. `releases check` reports **clean, 0 failures** (8 pre-existing warnings:
MIG-ref staleness ×7 and 24 grandfather entries, both predating this branch).

## Read before answering

- `utils/py/releases_app.py` — the ledger CLI (`manifest cut`, `manifest dial-in`, `update`, `check`)
- `releases.sql` — the committed dump; the diff is the evidence
- The commit message on `chore/cancel-linux-rc` (`git log -1`)

Verify against the DB directly where useful:
`sqlite3 releases.db "SELECT ..."`.

# Questions

Answer each one specifically, citing `file:line` or a SQL result where you disagree.

1. **Is #345 correctly re-homed rather than shipped?** 
   Yes. 0.7.4 is a cancelled release; shipping an item against a release that never shipped misrepresents the delivery. Re-homing it to 0.9.0 as `dialed_in` is correct because the issue is still OPEN (follow-up work remains). It will be marked `shipped` against 0.9.0 when it is fully completed.

2. **Are #249 and #123 correctly left un-re-homed?** 
   Yes. They are CLOSED on GitHub, so they represent dead/abandoned work in this context. `releases_app.py` check has no rule requiring every issue to be attached to an active release (no `dangling` check exists for this), so leaving them cut from 0.7.4 without a new home is correct.

3. **Is #341 orphaned in a way that matters?** 
   `[Should]` Yes, it is orphaned. Because it is OPEN and deprioritized to P2, it should be parked in the `roadmap_items` table under the "Queue / parked intake" section. By leaving it dialed into no release and not on the roadmap, it disappears entirely from planning dashboards.

4. **Is the cut-then-redial sequence safe against the uniqueness constraint?** 
   Yes. The uniqueness constraint `idx_mfi_active_exclusive` only applies `WHERE state = 'dialed_in'`. Cutting the item from 0.7.4 changes its state to `cut`, allowing the new 0.9.0 dial-in row to be inserted safely. Creating a new `mfi-` id is the correct design here (per `releases_app.py:108-110`); it keeps the ledger append-only and the original `dialed_in_at` provenance is preserved in the cut row's history.

5. **A stray no-op `update` receipt.** 
   `[Nit]` It is harmless and should be left as honest history. The `releases check` validation enforces `before == previous after`. A contentless update simply produces a receipt where the `before` and `after` digests are identical (as seen in `op_receipts` row 390: `5ec15...4617` -> `5ec15...4617`). Scrubbing it manually would require forging the receipt chain. 

6. **Does cancelling 0.7.4 leave the release sequence coherent?** 
   Yes. `releases check` reports 0 failures; the system does not mandate having an `active` release at all times. However, semantically, `[Should]` 0.9.0 ought to be promoted to `active` to accurately reflect that it is now the current focus of development.

7. **Are the generated artifacts consistent with the DB?** 
   Yes. Because no `roadmap_items` rows were modified, `ROADMAP-DASHBOARD.md` did not need regeneration and is perfectly consistent with the DB. The generated views are not stale.

## Log
VERDICT: FAIL
Basis: Please address the `[Should]` findings (parking #341 on the roadmap and promoting 0.9.0 to active).

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (agy)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
