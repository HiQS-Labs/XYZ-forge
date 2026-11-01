# Plan draft: #32 RELEASES app: SQLite-backed release ledger with CLI-only writes, generated RELEASES.md, and cross-repo UI

> draft; preflight and independent plan QA outstanding

- Request: `gh-32-412cec12b160` (tick `slot_028`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 70/50/65/35
- Capture doc: PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md (sha256 e2d71b13989104ce7ddd9dbc7a82441ecb63b352ffb046c28d5b86caf2b3a2ee)
- Issue sha256: 412cec12b1608b4b11667739bfa08a1eea34678a0aadb0e1de3eb271557b9509 (updated 2026-08-19T01:32:58Z)
- Dependencies: none

## Scope

_Source: issue#32:L26 (V1 scope)_

1. Schema + migrations, Python CLI (`utils/py/`, per GH-551 Python-only rails): `add / update / ship / list / gen / check / reconcile`
2. RELEASES.md generator with byte-stable output
3. DB ↔ dump consistency check (registered in validate.sh)
4. Cross-repo read-only UI — extend the GH-480 VSCode cockpit's Releases card to aggregate per-repo DBs via the utils/hq/ repo registry

## Acceptance criteria

_Source: PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:L430 (Acceptance Criteria (v1 = phases 0-3))_

- [ ] **Phase 0:** import grandfathers legacy violations with recorded dispositions in
      `grandfather_entries`; a structurally corrupt write is refused even in lenient; side-by-side
      generation matches the **pinned normalized rendering**, and the **consumer-equivalence
      assertions** (`pdda.sh releases` and `releases-current` via `PDDA_RELEASES_FILE`,
      `ballast-release.sh` Half A via its explicit ledger path) produce identical findings against
      the real and generated files; exit gate met per the receipts + exercised-operation matrix
      above.
- [ ] **`/releases` route migration (r4):** before the measured window starts, a focused fixture
      proves read synthesis works from normalized output AND that all four mutating routes
      (clean/plan/anchor/publish) delegate their writes to the CLI while preserving their
      preview-and-confirm UX.
- [ ] `PRAGMA foreign_keys=ON` asserted per connection; consistency check registered in `validate.sh`
      and observed failing on: a deliberate DB↔dump divergence, a stale `-wal`, a receipt-less direct
      write (business-state digest-chain mismatch), and a duplicate global ID across two fixture DBs
      (four negative controls).
- [ ] Strict-mode refusals name the violated rule; GH-28 thresholds refuse in strict / warn in
      lenient; manifest cut without a reason refused in both modes.
- [ ] Temp-ref lifecycle: offline create → `reconcile` → 7-day staleness warning (mocked clock).
- [ ] Writer lock + 

## Open questions

_missing_

## Write set

- `utils/pdda/pdda.sh` (issue#32:L10)
- `test/ballast-release.sh` (issue#32:L10)
- `releases.sql` (issue#32:L11)
- `validate.sh` (issue#32:L29)
- `relay-system/2026-08-18/gh32-releases-app-prd-review.md` (PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:L17)
- `utils/py/releases_app.py` (PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:L319)
- `utils/pdda/pdda-lib.sh` (PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:L351)

## Unresolved file names

- `MARATHON.yaml` (PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md:L389; 16 tracked files share this name)

## Contract probes

- none
