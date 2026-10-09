# GH-1006 verification receipts

`baseline/` retains the original 35/17 checks and limited shell wait probe. `focused/` retains
launcher 35/35, monitor 17/17, existing driver receipt adapter 223/223 and package freshness 3/3.
The receipt adapter exercises unchanged driver contracts, not the new observer itself.

`manual/` has 38 full-launcher/data/schedule checks plus 13 supplemental controls on the exact
helper/launcher hashes in provenance. Probe sources are retained as text evidence, not registered
suites or gate machinery. Logs contain the original disposable-clone file pointers; the matching
archived log basename and run/execution ID locate their retained reports here. Temporary fixture
files are not operational product evidence. Stub approval receipts prove reader behavior; they do
not attest a real delivered product revision.

The first group-TERM probe failed with exit -13; `initial-red-*` retains that failure. The minimal
red/disproof ledger isolates the run-log reader; the opt-in logger correction restores 143. Green
signal timings and statuses are in `manual/checks.json`. Whole-window clock jumps for N=6/18,
stale/foreign/malformed whole-second heartbeats and duplicate revisions are in the supplemental
checks. Reader inputs are regular-file/size bounded. Identity brackets match; tests ran only in
a separate disposable full clone. Final classified gate and independent final QA are still owed
before a ready PR; baseline PDDA reported zero errors and 421 inherited warnings.
