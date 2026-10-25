# GH-1208 — `jog land` accepts the local reconcile evidence beside a hosted run

Fix commit `f5a4e42f` (one function, `utils/py/jog_run.py` `jog_land`: either/or evidence + landing marker). Base `development` @ `80e67677`.
GH-831: no new tests; everything below is the existing `test/gh280-jog-marathon-adapter.sh` or a disposable copy of it.

## Existing suite, unmodified — `gh280-unmodified-f5a4e42f.log`
223 pass / 0 fail on the fixed code (hosted-green path; the stub answers `run list` with a synthetic green run). Run in the
disposable `-verify` clone with `XYZ_HARNESS` unset.

## Disposable-copy variants (`checks-f5a4e42f/`, driver `checks.sh`, copies `variant-*.sh`, hashes in `provenance.jsonl`)
Copies of the suite placed in the clone's `test/` dir (so `$0`-relative paths resolve), never committed, deleted with the clone.
Edits in **GH1127**: the stub's `run list` answers `[]` **only** for `--workflow wave-reconcile.yml` (marathon-drive's GH-509
gate-evidence query keeps its green run — starving it parked lanes at exit 8, which was my first driver mistake); a `roadmap add`
row for GH-901 is seeded before L5 and `.pdda-mode` gets `ROADMAP_SOURCE=releases` (the fixture is legacy-ROADMAP; without
releases mode the reconciler's `roadmap sync` refused on the seeded row and rolled the whole reconcile back — visible in
`wave-fixed-gh1127.log` of the earlier run, where the `TRANSITION … --section Completed … SHIPPED 2026-08-28 (PR #42)` had
already been written). **NEITHER** = GH1127 with the L5 `wave_reconcile.py` step removed.

| Variant | jog_run.py | Suite result | L5 outcome |
|---|---|---|---|
| GH1127 | reverted (80e67677) | 172 pass / 1 fail | **refused**: `hosted wave-reconcile is not green for the landed PR head` — the live defect (red control) |
| GH1127 | fixed (f5a4e42f) | **225 pass / 0 fail**, rc=0 | **lands**; `landing.json` has `hosted_reconcile: null` and `local_reconcile = {roadmap_gid, raw_text "… SHIPPED 2026-08-28 (PR #42) …"}` (`landing-fixed-gh1127.json`); L6 replay idempotent and L7 cache-removal replay green |
| NEITHER | fixed | 172 pass / 1 fail | **refused**: `no reconciliation evidence for PR #42: hosted wave-reconcile is not green for the landed head and the GH-901 roadmap row is not SHIPPED (PR #42) — run wave_reconcile.py --pr 42 locally (GH-1127) or dispatch the hosted lane`; row untouched |

`reevaluation.txt`: the driver (`checks-driver.log`) reported two FAILs for the fixed GH1127 variant because it anchored
`^PASS: L5` while the suite indents its lines; the retained `fixed-gh1127.log` shows `PASS: L5 jog land completes cleanly`,
`PASS: L6 land replay is idempotent` and suite exit 0. Artifacts unchanged; the driver's assertion was wrong, not the check.
Earlier driver reruns (four) failed on fixture/setup causes, in order: copies run from `temp/` broke `$0`-relative helpers;
the login shell's global `XYZ_HARNESS` made marathon-drive count lane attempts in the primary (`RELAY-TURN` capped → exit 8);
pinning `XYZ_HARNESS` to the clone then accumulated the clone's own counters; emptying every `run list` starved GH-509.
None of those touched the fix; all are recorded in the issue-#1210 class of launch traps.

## Final gate
Route for the changed paths: `tier=3` (kernel/gate surface). `bash ci-local.sh` in the disposable `-gate` clone on `f5a4e42f`:
see `full-gate-f5a4e42f.log` (identity checked before/after; result filled in when the run completes).
