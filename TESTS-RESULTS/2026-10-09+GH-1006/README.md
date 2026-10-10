# GH-1006 verification receipts

`baseline/` retains the original 35/17 checks and limited shell wait probe. `focused/` retains
launcher 35/35, monitor 17/17, existing driver receipt adapter 223/223 and package freshness 3/3.
The receipt adapter exercises unchanged driver contracts, not the new observer itself.

`manual/` preserves the historical loose-module layout: 38 full-launcher/data/schedule checks plus 13 supplemental controls on the exact
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
a separate disposable full clone. Baseline PDDA reported zero errors and 421 inherited warnings.

`embedded/` supersedes the layout-specific hashes with 38+13 fresh passing controls on the current
launcher subcommand. The Python payload is byte-identical to the former helper; the final file
hash is recorded in provenance. The initial observer-presence assertion prevents vacuous lifecycle
measurements. `gate-correction/` retains the full RED run (952 seconds, refused push, intact clone
identity), GH-777 rejection, GH-492 parallel timing failure and its successful serial retry. GH-777
now passes strict live-tree and existing negative controls; launcher 35/35 and registry checks pass.
The unchanged non-Small GH-492 passes focused 16/16 and is removed from the full registry under
the standing AGENTS #802/#853 rule, with a gh306 exemption. Its source/runtime is unchanged.
Final code QA Approved round 3 supersedes the historical round 2 approval; the isolated shipped
relay exited 0 and its attestation/provenance are in `final-qa-r3/`. A passing
classified full macOS gate is still required before PR readiness.

`integration/` retains development `3c829e0d` adoption, native ledger conflict resolution/readback,
launcher35, receipt-adapter223, package3 and composed PDDA exit0 with an intact disposable-clone
identity bracket. GH-1006’s original admission and ratings survive; the native writer updates its
summary to code-QA-complete/publication-next. All five authored production files match round3
source; imported #1004 changes have their own upstream independent QA receipt. Raw upstream logs
and consult transcripts retain their original whitespace; authored-source whitespace checks pass.
