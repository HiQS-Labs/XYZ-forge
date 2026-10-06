# GH-976 — receipt-only commits are not convergence

Manual controls (no new suite, GH-831), run from `gh976-controls.sh` in this directory against a
disposable base clone at `6d81df9f` and the candidate tree. Each case builds a fixture repo under
`$TMPDIR`, seeds a tick token, dispatches a stub that commits inside the turn and never approves,
`--round-cap 2`, resolved-items count fixed. Expected exits: 0 = expectation holds, 10 = fails.

| Case | Only change per turn | Base (6d81df9f) | Candidate |
|---|---|---|---|
| A | `relay-system/receipt.md` | extends to cap 4, `cap-progressing-extended` → **fails (10)** | `cap-stalled` at cap 2, no `Extension · System` → passes |
| B | the relay file at `notes/thread.md` | extends → **fails (10)** | `cap-stalled` at cap 2 → passes |
| C | `src/repair.py` | extends → passes | extends → passes (GH-115 HEAD arm preserved) |
| D | `relay-system/receipt.md` + `src/repair.py` | extends → passes | extends → passes |
| E | `src/repair.py`, driver sampling a non-git dir (empty SHAs) | `cap-stalled` → passes | `cap-stalled` → passes |
| F | the relay file opened through its realpath while the driver samples the repo through the `$TMPDIR` alias (`/var/…` vs `/private/var/…`) | extends → **fails (10)** | `cap-stalled` at cap 2 → passes (final QA round 1, finding 1) |
| G | `relay-system/réceipt.md` (git quotes it without `-z`) | extends → **fails (10)** | `cap-stalled` at cap 2 → passes (final QA round 1, finding 2) |

Existing suite `test/gh115-round-cap.sh`: 7 pass, 0 fail on the candidate (recorded last in
`provenance.jsonl`). Provenance records name the committed candidate revision. Fixture note: the stub retries its commit briefly because the driver refreshes
the git index concurrently (`index.lock`); without the retry case D dropped a turn on both sides.

Qualifying gate: `bash ci-local.sh` on commit `7afa8e49` (the attested final-QA head) in a disposable
clone with `XYZ_HARNESS` unset — all steps passed, record copied to `gate-evidence-7afa8e49.txt`
(self-reported local evidence, not promotion evidence, GH-509).
